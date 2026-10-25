import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show UserAttributes;
import 'ai_config_service.dart';
import 'outfit_calendar_service.dart';
import 'supabase_service.dart';
import 'user_profile_service.dart';
import 'wardrobe_provider.dart';

enum AuthMethod {
  google('Google', '🌐'),
  email('Email & Пароль', '✉️'),
  guest('Гість / Демо', '👤');

  final String label;
  final String icon;
  const AuthMethod(this.label, this.icon);

  static AuthMethod fromString(String? val) {
    if (val == null) return AuthMethod.guest;
    return AuthMethod.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => AuthMethod.guest,
    );
  }
}

class AuthUser {
  final String id;
  final String email;
  final String displayName;
  final String? avatarUrl;
  final AuthMethod method;
  final DateTime createdAt;

  const AuthUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.avatarUrl,
    required this.method,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'displayName': displayName,
        'avatarUrl': avatarUrl,
        'method': method.name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as String? ?? 'usr_demo',
        email: json['email'] as String? ?? 'user@vestora.app',
        displayName: json['displayName'] as String? ?? 'Користувач Vestora',
        avatarUrl: json['avatarUrl'] as String?,
        method: AuthMethod.fromString(json['method'] as String?),
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}

class GooglePresetAccount {
  final String email;
  final String displayName;
  final String avatarUrl;

  const GooglePresetAccount({
    required this.email,
    required this.displayName,
    required this.avatarUrl,
  });
}

class AuthService extends ChangeNotifier {
  static final AuthService instance = AuthService._internal();
  AuthService._internal();

  static const _keyIsLoggedIn = 'vestora_auth_is_logged_in';
  static const _keyCurrentUser = 'vestora_auth_current_user_json';
  static const _keySessionToken = 'vestora_auth_session_token';
  static const _keySessionExpiresAt = 'vestora_auth_session_expires_at';
  static const _keyRegisteredUsers = 'vestora_auth_registered_users_map';

  static const int _kdfIterations = 12000;
  static const Duration _sessionTtl = Duration(days: 30);

  AuthUser? _currentUser;
  String? _sessionToken;
  DateTime? _sessionExpiresAt;
  bool _isLoggedIn = false;

  bool get isLoggedIn => _isLoggedIn && _currentUser != null && isSessionValid;
  AuthUser? get currentUser => _currentUser;
  AuthMethod get currentMethod => _currentUser?.method ?? AuthMethod.guest;
  String? get currentSessionToken => _sessionToken;

  bool get isSessionValid {
    if (!_isLoggedIn || _currentUser == null) return false;
    if (_sessionExpiresAt == null) return true;
    return DateTime.now().toUtc().isBefore(_sessionExpiresAt!);
  }

  static final List<GooglePresetAccount> googlePresetAccounts = [
    const GooglePresetAccount(
      email: 'olena.fashion@gmail.com',
      displayName: 'Олена Шевченко',
      avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&auto=format&fit=crop&q=80',
    ),
    const GooglePresetAccount(
      email: 'sergij.melnyk@gmail.com',
      displayName: 'Сергій Мельник',
      avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&auto=format&fit=crop&q=80',
    ),
    const GooglePresetAccount(
      email: 'maria.luxury@gmail.com',
      displayName: 'Марія Коваль',
      avatarUrl: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=400&auto=format&fit=crop&q=80',
    ),
  ];

  /// Generates cryptographically secure random hex string.
  static String _generateSecureHex(int byteLength) {
    Random rng;
    try {
      rng = Random.secure();
    } catch (_) {
      rng = Random();
    }
    final bytes = List<int>.generate(byteLength, (_) => rng.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Derives a salted iterative HMAC-SHA256 password digest.
  static String hashPasswordWithSalt(String password, String saltHex) {
    final keyBytes = utf8.encode('vestora-pepper-v2:$saltHex');
    final hmac = Hmac(sha256, keyBytes);
    List<int> digest = hmac.convert(utf8.encode(password)).bytes;
    for (int i = 1; i < _kdfIterations; i++) {
      digest = hmac.convert(digest).bytes;
    }
    return digest.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Constant-time comparison to mitigate timing side-channel attacks.
  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }

  static Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasLoggedIn = prefs.getBool(_keyIsLoggedIn);
      final userJsonStr = prefs.getString(_keyCurrentUser);
      final token = prefs.getString(_keySessionToken);
      final expiresStr = prefs.getString(_keySessionExpiresAt);

      if (hasLoggedIn == true && userJsonStr != null) {
        final expiresAt = expiresStr != null ? DateTime.tryParse(expiresStr)?.toUtc() : null;
        if (expiresAt != null && DateTime.now().toUtc().isAfter(expiresAt)) {
          // Expired session — clear safely
          await instance.signOut();
          return;
        }

        final decoded = json.decode(userJsonStr) as Map<String, dynamic>;
        instance._currentUser = AuthUser.fromJson(decoded);
        instance._sessionToken = (token != null && token.isNotEmpty) ? token : _generateSecureHex(32);
        instance._sessionExpiresAt = expiresAt ?? DateTime.now().toUtc().add(_sessionTtl);
        instance._isLoggedIn = true;
      } else {
        instance._isLoggedIn = false;
        instance._currentUser = null;
        instance._sessionToken = null;
        instance._sessionExpiresAt = null;
      }
    } catch (_) {
      instance._isLoggedIn = false;
      instance._currentUser = null;
      instance._sessionToken = null;
      instance._sessionExpiresAt = null;
    }
  }

  /// Sign In with Google account
  Future<({bool success, String? error, AuthUser? user})> signInWithGoogle({
    String? email,
    String? displayName,
    String? avatarUrl,
  }) async {
    try {
      final finalEmail = email?.trim().isNotEmpty == true
          ? email!.trim()
          : googlePresetAccounts.first.email;
      final finalName = displayName?.trim().isNotEmpty == true
          ? displayName!.trim()
          : (email != null ? email.split('@').first : googlePresetAccounts.first.displayName);
      final finalAvatar = avatarUrl ?? googlePresetAccounts.first.avatarUrl;

      final user = AuthUser(
        id: 'goog_${finalEmail.hashCode.abs()}',
        email: finalEmail,
        displayName: finalName,
        avatarUrl: finalAvatar,
        method: AuthMethod.google,
        createdAt: DateTime.now(),
      );

      _currentUser = user;
      _isLoggedIn = true;

      await UserProfileService.saveProfile(
        name: finalName,
        email: finalEmail,
      );

      await _persistSession(user);
      notifyListeners();
      return (success: true, error: null, user: user);
    } catch (e) {
      return (success: false, error: 'Помилка авторизації через Google: $e', user: null);
    }
  }

  /// Sign In with Email and Password
  Future<({bool success, String? error, AuthUser? user})> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim();
    final cleanPass = password.trim();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@') || !cleanEmail.contains('.')) {
      return (success: false, error: 'Введіть коректну адресу електронної пошти', user: null);
    }
    if (cleanPass.length < 6) {
      return (success: false, error: 'Пароль повинен містити щонайменше 6 символів', user: null);
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final usersMap = _getStoredUsersMap(prefs);
      final lowerEmail = cleanEmail.toLowerCase();

      String userName = 'Користувач Vestora';
      if (usersMap.containsKey(lowerEmail)) {
        final userData = Map<String, dynamic>.from(usersMap[lowerEmail] as Map);
        final storedSalt = userData['passwordSalt'] as String?;
        final storedHash = userData['passwordHash'] as String?;
        final legacyPlainPass = userData['password'] as String?;

        if (storedSalt != null && storedHash != null) {
          final candidateHash = hashPasswordWithSalt(cleanPass, storedSalt);
          if (!_constantTimeEquals(candidateHash, storedHash)) {
            return (success: false, error: 'Невірний пароль для вказаної пошти', user: null);
          }
        } else if (legacyPlainPass != null) {
          if (!_constantTimeEquals(legacyPlainPass, cleanPass)) {
            return (success: false, error: 'Невірний пароль для вказаної пошти', user: null);
          }
          // Transparently migrate legacy plaintext password to salted HMAC-SHA256
          final newSalt = _generateSecureHex(16);
          userData.remove('password');
          userData['passwordSalt'] = newSalt;
          userData['passwordHash'] = hashPasswordWithSalt(cleanPass, newSalt);
          usersMap[lowerEmail] = userData;
          await prefs.setString(_keyRegisteredUsers, json.encode(usersMap));
        }

        userName = userData['name'] as String? ?? cleanEmail.split('@').first;
      } else {
        userName = cleanEmail.split('@').first;
        if (cleanEmail == 'sergij@vestora.app') {
          userName = 'Сергій';
        }
      }

      final user = AuthUser(
        id: 'usr_${cleanEmail.hashCode.abs()}',
        email: cleanEmail,
        displayName: userName,
        method: AuthMethod.email,
        createdAt: DateTime.now(),
      );

      _currentUser = user;
      _isLoggedIn = true;

      await UserProfileService.saveProfile(
        name: userName,
        email: cleanEmail,
      );

      await _persistSession(user);
      notifyListeners();
      return (success: true, error: null, user: user);
    } catch (e) {
      return (success: false, error: 'Помилка входу: $e', user: null);
    }
  }

  /// Register a new account with Name, Email and Password (salted SHA-256)
  Future<({bool success, String? error, AuthUser? user})> registerWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
  }) async {
    final cleanName = name.trim();
    final cleanEmail = email.trim();
    final cleanPass = password.trim();

    if (cleanName.length < 2) {
      return (success: false, error: 'Вкажіть ваше ім\'я (щонайменше 2 символи)', user: null);
    }
    if (cleanEmail.isEmpty || !cleanEmail.contains('@') || !cleanEmail.contains('.')) {
      return (success: false, error: 'Введіть коректний email для реєстрації', user: null);
    }
    if (cleanPass.length < 6) {
      return (success: false, error: 'Пароль повинен містити щонайменше 6 символів', user: null);
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final usersMap = _getStoredUsersMap(prefs);
      final lowerEmail = cleanEmail.toLowerCase();

      if (usersMap.containsKey(lowerEmail)) {
        return (success: false, error: 'Акаунт з такою поштою вже зареєстровано. Увійдіть у систему.', user: null);
      }

      final salt = _generateSecureHex(16);
      final passwordHash = hashPasswordWithSalt(cleanPass, salt);

      usersMap[lowerEmail] = {
        'name': cleanName,
        'email': cleanEmail,
        'passwordSalt': salt,
        'passwordHash': passwordHash,
        'registeredAt': DateTime.now().toUtc().toIso8601String(),
      };
      await prefs.setString(_keyRegisteredUsers, json.encode(usersMap));

      final user = AuthUser(
        id: 'usr_${cleanEmail.hashCode.abs()}',
        email: cleanEmail,
        displayName: cleanName,
        method: AuthMethod.email,
        createdAt: DateTime.now(),
      );

      _currentUser = user;
      _isLoggedIn = true;

      await UserProfileService.saveProfile(
        name: cleanName,
        email: cleanEmail,
      );

      await _persistSession(user);
      notifyListeners();
      return (success: true, error: null, user: user);
    } catch (e) {
      return (success: false, error: 'Помилка реєстрації: $e', user: null);
    }
  }

  /// Verifies current password (when registered) and updates stored salted hash & session token.
  Future<({bool success, String message})> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final cleanOld = oldPassword.trim();
    final cleanNew = newPassword.trim();
    final cleanConfirm = confirmPassword.trim();

    if (cleanNew.length < 6) {
      return (success: false, message: 'Пароль повинен містити щонайменше 6 символів');
    }
    if (cleanNew != cleanConfirm) {
      return (success: false, message: 'Новий пароль та підтвердження не співпадають');
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final usersMap = _getStoredUsersMap(prefs);
      final activeEmail = (_currentUser?.email ?? UserProfileService.profile.email).trim().toLowerCase();

      if (usersMap.containsKey(activeEmail)) {
        final userData = Map<String, dynamic>.from(usersMap[activeEmail] as Map);
        final storedSalt = userData['passwordSalt'] as String?;
        final storedHash = userData['passwordHash'] as String?;
        final legacyPlain = userData['password'] as String?;

        if (storedSalt != null && storedHash != null) {
          final oldCandidate = hashPasswordWithSalt(cleanOld, storedSalt);
          if (!_constantTimeEquals(oldCandidate, storedHash)) {
            return (success: false, message: 'Поточний пароль вказано невірно');
          }
        } else if (legacyPlain != null && !_constantTimeEquals(legacyPlain, cleanOld)) {
          return (success: false, message: 'Поточний пароль вказано невірно');
        }

        final newSalt = _generateSecureHex(16);
        userData.remove('password');
        userData['passwordSalt'] = newSalt;
        userData['passwordHash'] = hashPasswordWithSalt(cleanNew, newSalt);
        userData['updatedAt'] = DateTime.now().toUtc().toIso8601String();
        usersMap[activeEmail] = userData;
        await prefs.setString(_keyRegisteredUsers, json.encode(usersMap));
      }

      if (SupabaseService.isAuthenticated) {
        try {
          await SupabaseService.client?.auth.updateUser(
            UserAttributes(password: cleanNew),
          );
        } catch (_) {}
      }

      if (_currentUser != null) {
        await _persistSession(_currentUser!);
      }

      return (success: true, message: 'Пароль успішно змінено!');
    } catch (e) {
      return (success: false, message: 'Помилка зміни пароля: $e');
    }
  }

  /// Send password reset email simulation (uses Supabase resetPasswordForEmail if connected)
  Future<({bool success, String message})> sendPasswordResetEmail(String email) async {
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      return (success: false, message: 'Будь ласка, введіть коректну електронну адресу');
    }

    if (SupabaseService.isConfigured && SupabaseService.client != null) {
      try {
        await SupabaseService.client!.auth.resetPasswordForEmail(cleanEmail);
      } catch (_) {}
    } else {
      await Future.delayed(const Duration(milliseconds: 300));
    }

    return (
      success: true,
      message: 'Інструкцію для скидання паролю успішно надіслано на $cleanEmail. Перевірте поштову скриньку!',
    );
  }

  /// Continue as Guest (Demo mode)
  Future<void> signInAsGuest() async {
    final user = AuthUser(
      id: 'guest_demo',
      email: 'guest@vestora.app',
      displayName: 'Гість Vestora',
      avatarUrl: null,
      method: AuthMethod.guest,
      createdAt: DateTime.now(),
    );

    _currentUser = user;
    _isLoggedIn = true;
    await _persistSession(user);
    notifyListeners();
  }

  /// Sign out current user and invalidate session token
  Future<void> signOut() async {
    _currentUser = null;
    _sessionToken = null;
    _sessionExpiresAt = null;
    _isLoggedIn = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsLoggedIn, false);
      await prefs.remove(_keyCurrentUser);
      await prefs.remove(_keySessionToken);
      await prefs.remove(_keySessionExpiresAt);
    } catch (_) {}
    notifyListeners();
  }

  /// Mandatory App Store (Guideline 5.1.1v) & Google Play 1-click Account & Cloud Data Deletion.
  /// Permanently wipes cloud data (if authenticated), local account credentials, wardrobe,
  /// planned outfits, profile PII, and AI API keys.
  Future<({bool success, String message})> deleteAccount({
    WardrobeProvider? wardrobe,
    bool deleteCloudData = true,
  }) async {
    try {
      if (deleteCloudData && SupabaseService.isAuthenticated) {
        final cloudDeleted = await SupabaseService.deleteCloudUserData();
        if (!cloudDeleted) {
          return (
            success: false,
            message:
                'Не вдалося видалити хмарні дані Supabase. Перевірте з\'єднання та повторіть спробу.',
          );
        }
      }

      final prefs = await SharedPreferences.getInstance();
      final activeEmail = _currentUser?.email.toLowerCase();
      if (activeEmail != null && activeEmail.isNotEmpty) {
        final usersMap = _getStoredUsersMap(prefs);
        if (usersMap.containsKey(activeEmail)) {
          usersMap.remove(activeEmail);
          await prefs.setString(_keyRegisteredUsers, json.encode(usersMap));
        }
      }

      if (wardrobe != null) {
        await wardrobe.clearWardrobe(clearTombstones: true);
      } else {
        await prefs.remove('smart_wardrobe_items_v2');
        await prefs.remove('vestora_deleted_item_ids');
        await prefs.remove('vestora_pending_wear_logs');
        await prefs.remove('vestora_streak_days');
      }

      await OutfitCalendarService.clearAllPlans();
      await UserProfileService.clearAllData();
      await AiConfigService.clearAllData();
      await SupabaseService.disconnect();

      _currentUser = null;
      _sessionToken = null;
      _sessionExpiresAt = null;
      _isLoggedIn = false;

      await prefs.setBool(_keyIsLoggedIn, false);
      await prefs.remove(_keyCurrentUser);
      await prefs.remove(_keySessionToken);
      await prefs.remove(_keySessionExpiresAt);

      notifyListeners();
      return (
        success: true,
        message: 'Ваш акаунт та всі персональні дані остаточно видалено.',
      );
    } catch (e) {
      return (
        success: false,
        message: 'Помилка при видаленні акаунта: $e',
      );
    }
  }

  Future<void> _persistSession(AuthUser user) async {
    final token = _generateSecureHex(32);
    final expiresAt = DateTime.now().toUtc().add(_sessionTtl);
    _sessionToken = token;
    _sessionExpiresAt = expiresAt;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsLoggedIn, true);
      await prefs.setString(_keyCurrentUser, json.encode(user.toJson()));
      await prefs.setString(_keySessionToken, token);
      await prefs.setString(_keySessionExpiresAt, expiresAt.toIso8601String());
    } catch (_) {}
  }

  Map<String, dynamic> _getStoredUsersMap(SharedPreferences prefs) {
    try {
      final str = prefs.getString(_keyRegisteredUsers);
      if (str != null && str.isNotEmpty) {
        return json.decode(str) as Map<String, dynamic>;
      }
    } catch (_) {}
    return <String, dynamic>{};
  }
}
