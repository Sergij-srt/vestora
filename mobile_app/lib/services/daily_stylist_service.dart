import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/clothing_item.dart';
import 'wardrobe_provider.dart';
import 'weather_stylist_service.dart';
import 'web_platform_stub.dart'
    if (dart.library.js_interop) 'web_platform_web.dart' as platform;

class CityCoordinates {
  final String name;
  final double lat;
  final double lon;

  const CityCoordinates(this.name, this.lat, this.lon);
}

const List<CityCoordinates> defaultFashionCities = [
  CityCoordinates('Київ', 50.4501, 30.5234),
  CityCoordinates('Львів', 49.8397, 24.0297),
  CityCoordinates('Одеса', 46.4825, 30.7233),
  CityCoordinates('Харків', 49.9935, 36.2304),
  CityCoordinates('Дніпро', 48.4647, 35.0462),
  CityCoordinates('Париж', 48.8566, 2.3522),
  CityCoordinates('Мілан', 45.4642, 9.1900),
  CityCoordinates('Варшава', 52.2297, 21.0122),
  CityCoordinates('Лондон', 51.5074, -0.1278),
  CityCoordinates('Берлін', 52.5200, 13.4050),
  CityCoordinates('Рим', 41.9028, 12.4964),
  CityCoordinates('Нью-Йорк', 40.7128, -74.0060),
];

class LiveWeatherData {
  final double temperature;
  final double apparentTemperature;
  final WeatherCondition condition;
  final int weatherCode;
  final double windSpeed;
  final bool isLive;

  const LiveWeatherData({
    required this.temperature,
    required this.apparentTemperature,
    required this.condition,
    required this.weatherCode,
    required this.windSpeed,
    required this.isLive,
  });
}

class DailyOutfitDigest {
  final DateTime date;
  final String city;
  final int temperature;
  final WeatherCondition condition;
  final String weatherSummary;
  final String stylistTip;
  final List<ClothingItem> outfitItems;
  final bool isLive;
  bool isWorn;

  DailyOutfitDigest({
    required this.date,
    required this.city,
    required this.temperature,
    required this.condition,
    required this.weatherSummary,
    required this.stylistTip,
    required this.outfitItems,
    this.isLive = false,
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
        'isLive': isLive,
        'isWorn': isWorn,
      };
}

class DailyStylistService {
  static const String _keyDailyDigestDate = 'vestora_daily_digest_date';
  static const String _keyDailyDigestJson = 'vestora_daily_digest_cache';
  static const String _keyPushEnabled = 'vestora_morning_push_enabled';

  /// Maps WMO Weather Interpretation Codes to Vestora WeatherCondition
  static WeatherCondition mapWmoCodeToCondition(int code, double windSpeed) {
    if (windSpeed > 32.0) {
      return WeatherCondition.coldWindy;
    }
    if (code == 0) {
      return WeatherCondition.sunny;
    }
    if (code >= 1 && code <= 3) {
      return WeatherCondition.cloudy;
    }
    if (code == 45 || code == 48) {
      return WeatherCondition.cloudy;
    }
    // Drizzle, Rain, Showers, Thunderstorms
    if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82) || (code >= 95 && code <= 99)) {
      return WeatherCondition.rainy;
    }
    // Snow & Freezing
    if ((code >= 71 && code <= 77) || (code >= 85 && code <= 86)) {
      return WeatherCondition.snowy;
    }
    return WeatherCondition.cloudy;
  }

  /// Fetches real-time weather from Open-Meteo free API without API keys
  static Future<LiveWeatherData> fetchLiveWeather({
    String city = 'Київ',
    http.Client? client,
  }) async {
    final matched = defaultFashionCities.firstWhere(
      (c) => c.name.toLowerCase() == city.toLowerCase() ||
             city.toLowerCase().contains(c.name.toLowerCase()),
      orElse: () => const CityCoordinates('Київ', 50.4501, 30.5234),
    );

    final httpClient = client ?? http.Client();
    try {
      final uri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?'
        'latitude=${matched.lat}&longitude=${matched.lon}&'
        'current=temperature_2m,apparent_temperature,precipitation,weather_code,wind_speed_10m'
      );

      final response = await httpClient.get(
        uri,
        headers: {'User-Agent': 'VestoraApp/1.0'},
      ).timeout(const Duration(milliseconds: 3500));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final current = data['current'] as Map<String, dynamic>?;
        if (current != null) {
          final temp = (current['temperature_2m'] as num).toDouble();
          final apparent = (current['apparent_temperature'] as num?)?.toDouble() ?? temp;
          final code = (current['weather_code'] as num?)?.toInt() ?? 0;
          final wind = (current['wind_speed_10m'] as num?)?.toDouble() ?? 10.0;
          final condition = mapWmoCodeToCondition(code, wind);

          return LiveWeatherData(
            temperature: temp,
            apparentTemperature: apparent,
            condition: condition,
            weatherCode: code,
            windSpeed: wind,
            isLive: true,
          );
        }
      }
    } catch (_) {
      // Graceful offline fallback
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }

    return const LiveWeatherData(
      temperature: 14.0,
      apparentTemperature: 13.0,
      condition: WeatherCondition.cloudy,
      weatherCode: 2,
      windSpeed: 10.0,
      isLive: false,
    );
  }

  /// Generates or retrieves cached daily outfit digest for today
  static Future<DailyOutfitDigest> getTodayDigest({
    required List<ClothingItem> wardrobeItems,
    String? location,
    bool forceRefresh = false,
    http.Client? client,
  }) async {
    final now = DateTime.now();
    final todayKey = '${now.year}-${now.month}-${now.day}';
    final city = (location != null && location.trim().isNotEmpty) ? location.split(',')[0].trim() : 'Київ';

    // 1. Try to load cached digest from today if not force-refreshing
    if (!forceRefresh) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final cachedDate = prefs.getString(_keyDailyDigestDate);
        final cachedJson = prefs.getString(_keyDailyDigestJson);

        if (cachedDate == todayKey && cachedJson != null) {
          final decoded = json.decode(cachedJson) as Map<String, dynamic>;
          final cachedCity = decoded['city'] as String?;
          if (cachedCity == null || cachedCity.toLowerCase() == city.toLowerCase()) {
            final ids = (decoded['outfitItemIds'] as List).cast<String>();
            final matchedItems = wardrobeItems.where((i) => ids.contains(i.id)).toList();

            if (matchedItems.isNotEmpty) {
              return DailyOutfitDigest(
                date: DateTime.parse(decoded['date']),
                city: decoded['city'] ?? city,
                temperature: decoded['temperature'] ?? 14,
                condition: WeatherCondition.values.firstWhere(
                  (c) => c.name == decoded['condition'],
                  orElse: () => WeatherCondition.cloudy,
                ),
                weatherSummary: decoded['weatherSummary'] ?? 'Помірний день',
                stylistTip: decoded['stylistTip'] ?? '',
                outfitItems: matchedItems,
                isLive: decoded['isLive'] ?? false,
                isWorn: decoded['isWorn'] ?? false,
              );
            }
          }
        }
      } catch (_) {}
    }

    // 2. Fetch Live Weather via Open-Meteo
    final live = await fetchLiveWeather(city: city, client: client);
    final temp = live.temperature.round();
    final cond = live.condition;

    // 3. Synthesize weather-tailored outfit
    final curated = WeatherStylistService.curateOutfit(
      wardrobe: wardrobeItems,
      temperatureCelsius: temp,
      condition: cond,
      occasion: Occasion.casual,
    );

    List<ClothingItem> outfit = curated.allItems;
    if (outfit.isEmpty && wardrobeItems.isNotEmpty) {
      outfit = [wardrobeItems.first];
      if (wardrobeItems.length > 1) outfit.add(wardrobeItems[1]);
    }

    final sign = temp > 0 ? '+$temp' : '$temp';
    final liveSuffix = live.isLive ? ' · Live' : '';
    final summary = '$sign°C · ${cond.label}$liveSuffix';
    final tip = _generateStylistTip(temp: temp, condition: cond, outfit: outfit);

    final digest = DailyOutfitDigest(
      date: now,
      city: city,
      temperature: temp,
      condition: cond,
      weatherSummary: summary,
      stylistTip: tip,
      outfitItems: outfit,
      isLive: live.isLive,
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
    if (condition == WeatherCondition.rainy) {
      return 'Опади за вікном: обирайте водовідштовхувальний верхній одяг та шкіряне взуття, уникайте світлої замші.';
    } else if (temp <= 10) {
      return 'Холодна погода: вовняне пальто або щільний трикотаж збережуть тепло без втрати елегантності.';
    } else if (temp <= 18) {
      return 'Ідеальна погода для Smart Casual: легкий блейзер або тренч забезпечать бездоганний силует.';
    } else {
      return 'Теплий день: обирайте натуральні дихаючі тканини (льон, бавовну) та комфортне взуття.';
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
