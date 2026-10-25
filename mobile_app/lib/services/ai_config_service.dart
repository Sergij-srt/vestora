import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'secure_vault_service.dart';

enum AiEngineMode {
  byok, // Bring Your Own Key
  rewardedAd, // Scans earned via rewarded ads
  cloudPro, // Premium VIP
  localFallback, // Smart offline heuristic parser
}

class AiConfigService {
  static const String _keyApiKey = 'vestora_gemini_api_key';
  static const String _keyAdCredits = 'vestora_ai_ad_credits';
  static const String _keyPreferredModel = 'vestora_gemini_model';
  static const String _keyModelPreference = _keyPreferredModel;

  static String? _cachedApiKey;
  static int _cachedAdCredits = 3; // 3 free introductory AI scans
  static String _cachedModel = 'gemini-2.5-flash';

  /// Initializes persisted AI configuration from hardware-backed secure storage and SharedPreferences
  static Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var storedKey = (await SecureVaultService.read(_keyApiKey))?.trim();
      if (storedKey == null || storedKey.isEmpty) {
        // Fallback to legacy SharedPreferences and migrate
        storedKey = prefs.getString(_keyApiKey)?.trim();
        if (storedKey != null && storedKey.isNotEmpty) {
          await SecureVaultService.write(_keyApiKey, storedKey);
          await prefs.remove(_keyApiKey);
        }
      }
      _cachedApiKey = (storedKey != null && storedKey.isNotEmpty) ? storedKey : null;
      _cachedAdCredits = prefs.getInt(_keyAdCredits) ?? 3;
      _cachedModel = prefs.getString(_keyModelPreference) ?? 'gemini-2.5-flash';
    } catch (_) {
      _cachedApiKey = null;
      _cachedAdCredits = 3;
      _cachedModel = 'gemini-2.5-flash';
    }
  }

  /// Redacts API keys and query secrets from logs or user-facing error messages.
  static String redactSecrets(String input, [String? explicitSecret]) {
    var sanitized = input;
    if (explicitSecret != null && explicitSecret.trim().isNotEmpty) {
      sanitized = sanitized.replaceAll(explicitSecret.trim(), '[REDACTED_KEY]');
    }
    if (_cachedApiKey != null && _cachedApiKey!.isNotEmpty) {
      sanitized = sanitized.replaceAll(_cachedApiKey!, '[REDACTED_KEY]');
    }
    sanitized = sanitized.replaceAll(
      RegExp(r'AIza[0-9A-Za-z_\-]{12,}'),
      '[REDACTED_KEY]',
    );
    sanitized = sanitized.replaceAll(
      RegExp(r'([?&]key=)[^&\s]+', caseSensitive: false),
      r'$1[REDACTED_KEY]',
    );
    sanitized = sanitized.replaceAll(
      RegExp(r'(Bearer\s+)[A-Za-z0-9\-._~+/]+=*', caseSensitive: false),
      r'$1[REDACTED_TOKEN]',
    );
    sanitized = sanitized.replaceAll(
      RegExp(r'(x-goog-api-key\s*[:=]\s*)[^\s,;]+', caseSensitive: false),
      r'$1[REDACTED_KEY]',
    );
    return sanitized;
  }

  /// Returns current Gemini API key if configured
  static String? get apiKey => _cachedApiKey;

  /// Returns masked preview of API key for safe UI display
  static String? get maskedApiKey {
    final key = _cachedApiKey;
    if (key == null || key.isEmpty) return null;
    if (key.length <= 8) return '••••••••';
    return '${key.substring(0, 4)}••••••••${key.substring(key.length - 4)}';
  }

  /// Returns true if user configured a non-empty API key
  static bool get hasCustomKey => _cachedApiKey != null && _cachedApiKey!.isNotEmpty;

  /// Number of free/rewarded AI scans remaining
  static int get adCredits => _cachedAdCredits;

  /// Current model name (e.g. gemini-2.5-flash or gemini-1.5-flash)
  static String get preferredModel => _cachedModel;

  /// Determine active engine mode
  static AiEngineMode get activeMode {
    if (hasCustomKey) return AiEngineMode.byok;
    if (_cachedAdCredits > 0) return AiEngineMode.rewardedAd;
    return AiEngineMode.localFallback;
  }

  /// Label for active mode in Ukrainian
  static String get activeModeLabel {
    switch (activeMode) {
      case AiEngineMode.byok:
        return 'Власний Gemini API ключ (Необмежено)';
      case AiEngineMode.rewardedAd:
        return 'Бонусний ШІ ($_cachedAdCredits сканувань за рекламу)';
      case AiEngineMode.cloudPro:
        return 'Vestora Cloud PRO';
      case AiEngineMode.localFallback:
        return 'Локальний евристичний парсер';
    }
  }

  /// Save or remove user's Gemini API key securely
  static Future<void> setApiKey(String? key) async {
    final cleanKey = key?.trim();
    _cachedApiKey = (cleanKey != null && cleanKey.isNotEmpty) ? cleanKey : null;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_cachedApiKey != null) {
        await SecureVaultService.write(_keyApiKey, _cachedApiKey!);
      } else {
        await SecureVaultService.delete(_keyApiKey);
      }
      // Ensure legacy plain text key is removed
      await prefs.remove(_keyApiKey);
    } catch (_) {}
  }

  /// Set preferred model
  static Future<void> setPreferredModel(String model) async {
    _cachedModel = model;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyModelPreference, model);
    } catch (_) {}
  }

  /// Consume 1 scan credit if in rewardedAd mode
  static Future<bool> consumeScanCredit() async {
    if (hasCustomKey) return true; // BYOK is unlimited
    if (_cachedAdCredits > 0) {
      _cachedAdCredits--;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_keyAdCredits, _cachedAdCredits);
      } catch (_) {}
      return true;
    }
    return false;
  }

  /// Add rewarded ad credits
  static Future<int> addRewardedAdCredits([int amount = 3]) async {
    _cachedAdCredits += amount;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyAdCredits, _cachedAdCredits);
    } catch (_) {}
    return _cachedAdCredits;
  }

  /// Clears stored API keys and resets configuration (used during account deletion)
  static Future<void> clearAllData() async {
    _cachedApiKey = null;
    _cachedAdCredits = 3;
    _cachedModel = 'gemini-2.5-flash';
    try {
      await SecureVaultService.delete(_keyApiKey);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyApiKey);
      await prefs.remove(_keyAdCredits);
      await prefs.remove(_keyModelPreference);
    } catch (_) {}
  }

  /// Test whether a Gemini API key is valid with a live ping to Google AI.
  /// Sends key via `x-goog-api-key` header instead of URL query string to prevent
  /// accidental secret leakage in exception URIs or proxy access logs.
  static Future<({bool isValid, String message})> testApiKey(
    String testKey, {
    http.Client? httpClient,
  }) async {
    final cleanKey = testKey.trim();
    if (cleanKey.isEmpty) {
      return (isValid: false, message: 'Ключ порожній. Будь ласка, вставте ваш ключ.');
    }

    final client = httpClient ?? http.Client();
    try {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$_cachedModel:generateContent',
      );

      final response = await client
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'x-goog-api-key': cleanKey,
            },
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': 'Ping test. Reply with OK.'}
                  ]
                }
              ]
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return (isValid: true, message: '✅ Ключ успішно підтверджено! Gemini Vision готовий до роботи.');
      } else {
        String detail = 'Помилка HTTP ${response.statusCode}';
        try {
          final bodyJson = jsonDecode(response.body);
          if (bodyJson['error'] != null && bodyJson['error']['message'] != null) {
            detail = redactSecrets(bodyJson['error']['message'].toString(), cleanKey);
          }
        } catch (_) {}
        return (isValid: false, message: '❌ Недійсний ключ: $detail');
      }
    } catch (e) {
      final safeError = redactSecrets(e.toString(), cleanKey);
      return (isValid: false, message: '⚠️ Помилка з\'єднання з серверами Google: $safeError');
    } finally {
      if (httpClient == null) {
        client.close();
      }
    }
  }
}
