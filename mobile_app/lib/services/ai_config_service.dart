import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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

  static String? _cachedApiKey;
  static int _cachedAdCredits = 3; // 3 free introductory AI scans
  static String _cachedModel = 'gemini-2.5-flash';
  static bool _initialized = false;

  /// Initializes persisted AI configuration from SharedPreferences
  static Future<void> initialize() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedApiKey = prefs.getString(_keyApiKey)?.trim();
      _cachedAdCredits = prefs.getInt(_keyAdCredits) ?? 3;
      _cachedModel = prefs.getString(_keyModelPreference) ?? 'gemini-2.5-flash';
      _initialized = true;
    } catch (_) {
      _initialized = true;
    }
  }

  static const String _keyModelPreference = _keyPreferredModel;

  /// Returns current Gemini API key if configured
  static String? get apiKey => _cachedApiKey;

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

  /// Save or remove user's Gemini API key
  static Future<void> setApiKey(String? key) async {
    final cleanKey = key?.trim();
    _cachedApiKey = (cleanKey != null && cleanKey.isNotEmpty) ? cleanKey : null;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_cachedApiKey != null) {
        await prefs.setString(_keyApiKey, _cachedApiKey!);
      } else {
        await prefs.remove(_keyApiKey);
      }
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

  /// Test whether a Gemini API key is valid with a live ping to Google AI
  static Future<({bool isValid, String message})> testApiKey(String testKey) async {
    final cleanKey = testKey.trim();
    if (cleanKey.isEmpty) {
      return (isValid: false, message: 'Ключ порожній. Будь ласка, вставте ваш ключ.');
    }

    try {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$_cachedModel:generateContent?key=$cleanKey',
      );

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': 'Ping test. Reply with OK.'}
              ]
            }
          ]
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return (isValid: true, message: '✅ Ключ успішно підтверджено! Gemini Vision готовий до роботи.');
      } else {
        String detail = 'Помилка HTTP ${response.statusCode}';
        try {
          final bodyJson = jsonDecode(response.body);
          if (bodyJson['error'] != null && bodyJson['error']['message'] != null) {
            detail = bodyJson['error']['message'];
          }
        } catch (_) {}
        return (isValid: false, message: '❌ Недійсний ключ: $detail');
      }
    } catch (e) {
      return (isValid: false, message: '⚠️ Помилка з\'єднання з серверами Google: $e');
    }
  }
}
