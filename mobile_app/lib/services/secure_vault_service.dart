import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Hardware-backed secure storage service for sensitive tokens, API keys, and credentials.
///
/// Uses Android Keystore (EncryptedSharedPreferences) on Android,
/// Keychain Services (first_unlock accessibility) on iOS / macOS,
/// and safe encrypted storage with memory fallback on Web and test environments.
class SecureVaultService {
  static FlutterSecureStorage? _customStorage;
  static final Map<String, String> _memoryFallback = {};

  static bool get _isTestEnvironment {
    try {
      return !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }

  static FlutterSecureStorage get _storage =>
      _customStorage ??= const FlutterSecureStorage(
        aOptions: AndroidOptions(resetOnError: true),
        iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
        mOptions: MacOsOptions(accessibility: KeychainAccessibility.first_unlock),
        webOptions: WebOptions(
          dbName: 'vestora_secure_vault',
          publicKey: 'vestora_vault_key',
        ),
      );

  /// For unit testing: inject custom or mock secure storage
  @visibleForTesting
  static void setMockStorage(FlutterSecureStorage? storage) {
    _customStorage = storage;
    _memoryFallback.clear();
  }

  /// Writes a secret key-value pair to hardware-backed secure storage
  static Future<void> write(String key, String value) async {
    _memoryFallback[key] = value;
    if (_isTestEnvironment) return;

    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      if (kDebugMode && !e.toString().contains('MissingPluginException')) {
        debugPrint('SecureVault write warning (memory fallback active): $e');
      }
    }
  }

  /// Reads a secret from hardware-backed secure storage
  static Future<String?> read(String key) async {
    if (_isTestEnvironment) return _memoryFallback[key];

    try {
      final value = await _storage.read(key: key);
      if (value != null && value.isNotEmpty) {
        _memoryFallback[key] = value;
        return value;
      }
    } catch (e) {
      if (kDebugMode && !e.toString().contains('MissingPluginException')) {
        debugPrint('SecureVault read warning (checking memory fallback): $e');
      }
    }
    return _memoryFallback[key];
  }

  /// Deletes a secret from hardware-backed secure storage
  static Future<void> delete(String key) async {
    _memoryFallback.remove(key);
    if (_isTestEnvironment) return;

    try {
      await _storage.delete(key: key);
    } catch (_) {}
  }

  /// Checks if a key exists in secure storage
  static Future<bool> containsKey(String key) async {
    if (_memoryFallback.containsKey(key)) return true;
    if (_isTestEnvironment) return false;

    try {
      return await _storage.containsKey(key: key);
    } catch (_) {
      return _memoryFallback.containsKey(key);
    }
  }

  /// Clears all keys in secure storage
  static Future<void> clearAll() async {
    _memoryFallback.clear();
    if (_isTestEnvironment) return;

    try {
      await _storage.deleteAll();
    } catch (_) {}
  }

  /// Transparently migrates legacy unencrypted secrets from SharedPreferences
  /// to hardware-backed SecureVaultService, then wipes them from SharedPreferences.
  static Future<void> migrateFromSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. Gemini API key
      const geminiKey = 'vestora_gemini_api_key';
      final legacyGemini = prefs.getString(geminiKey)?.trim();
      if (legacyGemini != null && legacyGemini.isNotEmpty) {
        final existing = await read(geminiKey);
        if (existing == null || existing.isEmpty) {
          await write(geminiKey, legacyGemini);
        }
        await prefs.remove(geminiKey);
      }

      // 2. Supabase credentials
      const supaUrlKey = 'vestora_supabase_url';
      const supaAnonKey = 'vestora_supabase_anon_key';
      final legacySupaUrl = prefs.getString(supaUrlKey)?.trim();
      final legacySupaKey = prefs.getString(supaAnonKey)?.trim();

      if (legacySupaUrl != null && legacySupaUrl.isNotEmpty) {
        final existing = await read(supaUrlKey);
        if (existing == null || existing.isEmpty) {
          await write(supaUrlKey, legacySupaUrl);
        }
        await prefs.remove(supaUrlKey);
      }

      if (legacySupaKey != null && legacySupaKey.isNotEmpty) {
        final existing = await read(supaAnonKey);
        if (existing == null || existing.isEmpty) {
          await write(supaAnonKey, legacySupaKey);
        }
        await prefs.remove(supaAnonKey);
      }

      // 3. Auth session token
      const sessionTokenKey = 'vestora_auth_session_token';
      final legacySession = prefs.getString(sessionTokenKey)?.trim();
      if (legacySession != null && legacySession.isNotEmpty) {
        final existing = await read(sessionTokenKey);
        if (existing == null || existing.isEmpty) {
          await write(sessionTokenKey, legacySession);
        }
        await prefs.remove(sessionTokenKey);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SecureVault migration notice: $e');
      }
    }
  }
}
