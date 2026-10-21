import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_profile_service.dart';

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
  static const _keyRegisteredUsers = 'vestora_auth_registered_users_map';

  AuthUser? _currentUser;
  bool _isLoggedIn = false;
  static bool _initialized = false;

  bool get isLoggedIn => _isLoggedIn && _currentUser != null;
  AuthUser? get currentUser => _currentUser;
  AuthMethod get currentMethod => _currentUser?.method ?? AuthMethod.guest;

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

  static Future<void> initialize() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasLoggedIn = prefs.getBool(_keyIsLoggedIn);
      final userJsonStr = prefs.getString(_keyCurrentUser);

      if (hasLoggedIn == true && userJsonStr != null) {
        final decoded = json.decode(userJsonStr) as Map<String, dynamic>;
        instance._currentUser = AuthUser.fromJson(decoded);
        instance._isLoggedIn = true;
      } else {
        // If first launch, default to false so AuthScreen is shown, or user can sign in
        instance._isLoggedIn = false;
        instance._currentUser = null;
      }
      _initialized = true;
    } catch (_) {
      _initialized = true;
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

      // Update UserProfileService to sync across the app
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
    if (cleanEmail.isEmpty || !cleanEmail.contains('@') || !cleanEmail.contains('.')) {
      return (success: false, error: 'Введіть коректну адресу електронної пошти', user: null);
    }
    if (password.trim().length < 6) {
      return (success: false, error: 'Пароль повинен містити щонайменше 6 символів', user: null);
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final usersMap = _getStoredUsersMap(prefs);

      // Check registered users or default accounts
      String userName = 'Користувач Vestora';
      if (usersMap.containsKey(cleanEmail.toLowerCase())) {
        final userData = usersMap[cleanEmail.toLowerCase()] as Map<String, dynamic>;
        final storedPass = userData['password'] as String?;
        if (storedPass != null && storedPass != password.trim()) {
          return (success: false, error: 'Невірний пароль для вказаної пошти', user: null);
        }
        userName = userData['name'] as String? ?? cleanEmail.split('@').first;
      } else {
        // Allow seamless login for demo accounts or newly introduced accounts
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

  /// Register a new account with Name, Email and Password
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

      if (usersMap.containsKey(cleanEmail.toLowerCase())) {
        return (success: false, error: 'Акаунт з такою поштою вже зареєстровано. Увійдіть у систему.', user: null);
      }

      // Save user to local store
      usersMap[cleanEmail.toLowerCase()] = {
        'name': cleanName,
        'email': cleanEmail,
        'password': cleanPass,
        'registeredAt': DateTime.now().toIso8601String(),
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

  /// Send password reset email simulation
  Future<({bool success, String message})> sendPasswordResetEmail(String email) async {
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      return (success: false, message: 'Будь ласка, введіть коректну електронну адресу');
    }
    await Future.delayed(const Duration(milliseconds: 300));
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

  /// Sign out current user
  Future<void> signOut() async {
    _currentUser = null;
    _isLoggedIn = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsLoggedIn, false);
      await prefs.remove(_keyCurrentUser);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> _persistSession(AuthUser user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsLoggedIn, true);
      await prefs.setString(_keyCurrentUser, json.encode(user.toJson()));
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
