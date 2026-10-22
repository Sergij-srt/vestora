import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/clothing_item.dart';
import 'wardrobe_provider.dart';
import 'weather_stylist_service.dart';
import 'web_platform_stub.dart'
    if (dart.library.js_interop) 'web_platform_web.dart' as platform;

class DailyOutfitDigest {
  final DateTime date;
  final String city;
  final int temperature;
  final WeatherCondition condition;
  final String weatherSummary;
  final String stylistTip;
  final List<ClothingItem> outfitItems;
  bool isWorn;

  DailyOutfitDigest({
    required this.date,
    required this.city,
    required this.temperature,
    required this.condition,
    required this.weatherSummary,
    required this.stylistTip,
    required this.outfitItems,
    this.isWorn = false,
  });

  Map<String, dynamic> toMap() => {
        'date': date.toIso8601String(),
        'city': city,
        'temperature': temperature,
        'condition': condition.name,
        'weatherSummary': weatherSummary,
        'stylistTip': stylistTip,
        'outfitItemIds': outfitItems.map((e) => e.id).toList(),
        'isWorn': isWorn,
      };
}

class DailyStylistService {
  static const String _keyDailyDigestDate = 'vestora_daily_digest_date';
  static const String _keyDailyDigestJson = 'vestora_daily_digest_cache';
  static const String _keyPushEnabled = 'vestora_morning_push_enabled';

  /// Generates or retrieves cached daily outfit digest for today
  static Future<DailyOutfitDigest> getTodayDigest({
    required List<ClothingItem> wardrobeItems,
    String? location,
  }) async {
    final now = DateTime.now();
    final todayKey = '${now.year}-${now.month}-${now.day}';
    final city = (location != null && location.trim().isNotEmpty) ? location.split(',')[0].trim() : 'Київ';

    // 1. Try to load cached digest from today
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedDate = prefs.getString(_keyDailyDigestDate);
      final cachedJson = prefs.getString(_keyDailyDigestJson);

      if (cachedDate == todayKey && cachedJson != null) {
        final decoded = json.decode(cachedJson) as Map<String, dynamic>;
        final ids = (decoded['outfitItemIds'] as List).cast<String>();
        final matchedItems = wardrobeItems.where((i) => ids.contains(i.id)).toList();

        if (matchedItems.isNotEmpty) {
          return DailyOutfitDigest(
            date: DateTime.parse(decoded['date']),
            city: decoded['city'] ?? city,
            temperature: decoded['temperature'] ?? 15,
            condition: WeatherCondition.values.firstWhere(
              (c) => c.name == decoded['condition'],
              orElse: () => WeatherCondition.cloudy,
            ),
            weatherSummary: decoded['weatherSummary'] ?? 'Помірний день',
            stylistTip: decoded['stylistTip'] ?? '',
            outfitItems: matchedItems,
            isWorn: decoded['isWorn'] ?? false,
          );
        }
      }
    } catch (_) {}

    // 2. Synthesize new daily outfit
    // Default simulated season-appropriate temperature for October/Autumn
    const temp = 14;
    const cond = WeatherCondition.cloudy;

    ClothingItem? outerwear;
    ClothingItem? top;
    ClothingItem? bottom;
    ClothingItem? shoes;

    for (final item in wardrobeItems) {
      if (item.category == ClothingCategory.outerwear && outerwear == null) {
        outerwear = item;
      } else if (item.category == ClothingCategory.tops && top == null) {
        top = item;
      } else if (item.category == ClothingCategory.bottoms && bottom == null) {
        bottom = item;
      } else if (item.category == ClothingCategory.shoes && shoes == null) {
        shoes = item;
      }
    }

    // If tops missing, pick any item
    if (top == null && wardrobeItems.isNotEmpty) top = wardrobeItems.first;
    if (bottom == null && wardrobeItems.length > 1) bottom = wardrobeItems[1];

    final outfit = [
      ?outerwear,
      ?top,
      ?bottom,
      ?shoes,
    ];

    final summary = '+$temp°C · ${cond.label}';
    final tip = _generateStylistTip(temp: temp, condition: cond, outfit: outfit);

    final digest = DailyOutfitDigest(
      date: now,
      city: city,
      temperature: temp,
      condition: cond,
      weatherSummary: summary,
      stylistTip: tip,
      outfitItems: outfit,
      isWorn: false,
    );

    // Cache to SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyDailyDigestDate, todayKey);
      await prefs.setString(_keyDailyDigestJson, json.encode(digest.toMap()));
    } catch (_) {}

    return digest;
  }

  static String _generateStylistTip({
    required int temp,
    required WeatherCondition condition,
    required List<ClothingItem> outfit,
  }) {
    if (temp <= 12) {
      return 'Прохолодний день. Радимо багатошаровий образ із верхнім одягом для комфорту та стилю.';
    } else if (temp <= 18) {
      return 'Ідеальна погода для Smart Casual: легкий блейзер або сорочка забезпечать бездоганний силует.';
    } else {
      return 'Теплий сонячний день: обирайте натуральні дихаючі тканини та світлі палітри.';
    }
  }

  /// Mark outfit as worn and increment streak
  static Future<void> markWorn(WardrobeProvider wardrobe, DailyOutfitDigest digest) async {
    if (digest.isWorn) return;
    await wardrobe.recordOutfitWear(digest.outfitItems);
    digest.isWorn = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final todayKey = '${now.year}-${now.month}-${now.day}';
      await prefs.setString(_keyDailyDigestDate, todayKey);
      await prefs.setString(_keyDailyDigestJson, json.encode(digest.toMap()));
    } catch (_) {}
  }

  /// Request browser or native notification permission
  static Future<bool> requestNotificationPermission() async {
    final status = await platform.requestNotificationPermission();
    final granted = status == 'granted';
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyPushEnabled, granted);
    } catch (_) {}
    return granted;
  }

  /// Trigger a live push notification for morning outfit
  static void sendMorningPush(DailyOutfitDigest digest) {
    final title = '👗 Vestora · Ваш лук на сьогодні готовий';
    final body = '${digest.city} ${digest.weatherSummary}: ${digest.stylistTip}';
    platform.sendWebNotification(title, body: body, icon: 'icons/Icon-192.png');
  }
}
