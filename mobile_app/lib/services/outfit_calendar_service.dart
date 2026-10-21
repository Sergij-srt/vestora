import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/clothing_item.dart';
import 'weather_stylist_service.dart';
import 'wardrobe_provider.dart';

class PlannedDayOutfit {
  final String dateStr; // e.g. "2026-10-21"
  final DateTime date;
  final int weatherTemp;
  final WeatherCondition weatherCondition;
  final Occasion occasion;
  final String eventTitle;
  String? outerwearId;
  String? topId;
  String? bottomId;
  String? shoesId;
  bool isWorn;
  String? notes;

  PlannedDayOutfit({
    required this.dateStr,
    required this.date,
    required this.weatherTemp,
    required this.weatherCondition,
    required this.occasion,
    required this.eventTitle,
    this.outerwearId,
    this.topId,
    this.bottomId,
    this.shoesId,
    this.isWorn = false,
    this.notes,
  });

  String get dayOfWeekName {
    switch (date.weekday) {
      case DateTime.monday:
        return 'Понеділок';
      case DateTime.tuesday:
        return 'Вівторок';
      case DateTime.wednesday:
        return 'Середа';
      case DateTime.thursday:
        return 'Четвер';
      case DateTime.friday:
        return 'П\'ятниця';
      case DateTime.saturday:
        return 'Субота';
      case DateTime.sunday:
        return 'Неділя';
      default:
        return '';
    }
  }

  String get shortDayName {
    switch (date.weekday) {
      case DateTime.monday:
        return 'Пн';
      case DateTime.tuesday:
        return 'Вт';
      case DateTime.wednesday:
        return 'Ср';
      case DateTime.thursday:
        return 'Чт';
      case DateTime.friday:
        return 'Пт';
      case DateTime.saturday:
        return 'Сб';
      case DateTime.sunday:
        return 'Нд';
      default:
        return '';
    }
  }

  bool get hasOutfit =>
      outerwearId != null || topId != null || bottomId != null || shoesId != null;

  List<ClothingItem> getOutfitItems(List<ClothingItem> wardrobe) {
    final list = <ClothingItem>[];
    if (outerwearId != null) {
      final it = wardrobe.cast<ClothingItem?>().firstWhere((i) => i?.id == outerwearId, orElse: () => null);
      if (it != null) list.add(it);
    }
    if (topId != null) {
      final it = wardrobe.cast<ClothingItem?>().firstWhere((i) => i?.id == topId, orElse: () => null);
      if (it != null) list.add(it);
    }
    if (bottomId != null) {
      final it = wardrobe.cast<ClothingItem?>().firstWhere((i) => i?.id == bottomId, orElse: () => null);
      if (it != null) list.add(it);
    }
    if (shoesId != null) {
      final it = wardrobe.cast<ClothingItem?>().firstWhere((i) => i?.id == shoesId, orElse: () => null);
      if (it != null) list.add(it);
    }
    return list;
  }

  Map<String, dynamic> toJson() => {
        'dateStr': dateStr,
        'date': date.toIso8601String(),
        'weatherTemp': weatherTemp,
        'weatherCondition': weatherCondition.name,
        'occasion': occasion.name,
        'eventTitle': eventTitle,
        'outerwearId': outerwearId,
        'topId': topId,
        'bottomId': bottomId,
        'shoesId': shoesId,
        'isWorn': isWorn,
        'notes': notes,
      };

  factory PlannedDayOutfit.fromJson(Map<String, dynamic> json) {
    WeatherCondition condition;
    try {
      condition = WeatherCondition.values.byName(json['weatherCondition'] as String);
    } catch (_) {
      condition = WeatherCondition.cloudy;
    }

    Occasion occ;
    try {
      occ = Occasion.values.byName(json['occasion'] as String);
    } catch (_) {
      occ = Occasion.casual;
    }

    return PlannedDayOutfit(
      dateStr: json['dateStr'] as String,
      date: DateTime.parse(json['date'] as String),
      weatherTemp: json['weatherTemp'] as int? ?? 17,
      weatherCondition: condition,
      occasion: occ,
      eventTitle: json['eventTitle'] as String? ?? 'Образ дня',
      outerwearId: json['outerwearId'] as String?,
      topId: json['topId'] as String?,
      bottomId: json['bottomId'] as String?,
      shoesId: json['shoesId'] as String?,
      isWorn: json['isWorn'] as bool? ?? false,
      notes: json['notes'] as String?,
    );
  }

  PlannedDayOutfit copyWith({
    String? dateStr,
    DateTime? date,
    int? weatherTemp,
    WeatherCondition? weatherCondition,
    Occasion? occasion,
    String? eventTitle,
    String? outerwearId,
    String? topId,
    String? bottomId,
    String? shoesId,
    bool? isWorn,
    String? notes,
  }) {
    return PlannedDayOutfit(
      dateStr: dateStr ?? this.dateStr,
      date: date ?? this.date,
      weatherTemp: weatherTemp ?? this.weatherTemp,
      weatherCondition: weatherCondition ?? this.weatherCondition,
      occasion: occasion ?? this.occasion,
      eventTitle: eventTitle ?? this.eventTitle,
      outerwearId: outerwearId ?? this.outerwearId,
      topId: topId ?? this.topId,
      bottomId: bottomId ?? this.bottomId,
      shoesId: shoesId ?? this.shoesId,
      isWorn: isWorn ?? this.isWorn,
      notes: notes ?? this.notes,
    );
  }
}

class OutfitCalendarService {
  static const _storageKey = 'vestora_calendar_planned_days_v1';

  static String formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static DateTime startOfWeek(DateTime date) {
    // Week starts on Monday
    return DateTime(date.year, date.month, date.day).subtract(Duration(days: date.weekday - 1));
  }

  /// Load all saved planned days from storage
  static Future<Map<String, PlannedDayOutfit>> getAllPlans() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_storageKey);
      if (str == null || str.isEmpty) return {};
      final Map<String, dynamic> decoded = json.decode(str);
      final result = <String, PlannedDayOutfit>{};
      decoded.forEach((key, val) {
        if (val is Map<String, dynamic>) {
          result[key] = PlannedDayOutfit.fromJson(val);
        }
      });
      return result;
    } catch (_) {
      return {};
    }
  }

  /// Save or update a single planned day
  static Future<void> savePlan(PlannedDayOutfit plan) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final all = await getAllPlans();
      all[plan.dateStr] = plan;
      final encoded = json.encode(all.map((k, v) => MapEntry(k, v.toJson())));
      await prefs.setString(_storageKey, encoded);
    } catch (_) {}
  }

  /// Remove a planned day
  static Future<void> removePlan(String dateStr) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final all = await getAllPlans();
      if (all.containsKey(dateStr)) {
        all.remove(dateStr);
        final encoded = json.encode(all.map((k, v) => MapEntry(k, v.toJson())));
        await prefs.setString(_storageKey, encoded);
      }
    } catch (_) {}
  }

  /// Get the 7 days of the reference week with loaded plans or realistic presets
  static Future<List<PlannedDayOutfit>> getWeekPlan({
    required DateTime referenceDate,
    required List<ClothingItem> wardrobe,
  }) async {
    final monday = startOfWeek(referenceDate);
    final savedPlans = await getAllPlans();

    final weekDays = <PlannedDayOutfit>[];

    // Weekly default rhythms for realistic Ukrainian / European autumn-spring weather
    final weeklyContexts = [
      (17, WeatherCondition.cloudy, Occasion.work, 'Діловий старт тижня · Офіс'),
      (15, WeatherCondition.rainy, Occasion.work, 'Робочі зустрічі під дощем'),
      (18, WeatherCondition.sunny, Occasion.casual, 'Кава & Коворкінг · Smart Casual'),
      (19, WeatherCondition.cloudy, Occasion.work, 'Презентація & Переговори'),
      (16, WeatherCondition.sunny, Occasion.dateNight, 'П\'ятничний вечір & Коктейль'),
      (20, WeatherCondition.sunny, Occasion.casual, 'Прогулянка містом & Бранч'),
      (18, WeatherCondition.cloudy, Occasion.casual, 'Затишний відпочинок & Парк'),
    ];

    for (int i = 0; i < 7; i++) {
      final dayDate = monday.add(Duration(days: i));
      final dateKey = formatDate(dayDate);

      if (savedPlans.containsKey(dateKey)) {
        weekDays.add(savedPlans[dateKey]!);
      } else {
        final ctx = weeklyContexts[i];
        final dayPlan = PlannedDayOutfit(
          dateStr: dateKey,
          date: dayDate,
          weatherTemp: ctx.$1,
          weatherCondition: ctx.$2,
          occasion: ctx.$3,
          eventTitle: ctx.$4,
        );

        // Pre-curate if wardrobe is available
        if (wardrobe.isNotEmpty) {
          final curated = WeatherStylistService.curateOutfit(
            wardrobe: wardrobe,
            temperatureCelsius: ctx.$1,
            condition: ctx.$2,
            occasion: ctx.$3,
          );
          dayPlan.outerwearId = curated.outerwear?.id;
          dayPlan.topId = curated.top?.id;
          dayPlan.bottomId = curated.bottom?.id;
          dayPlan.shoesId = curated.shoes?.id;
        }

        weekDays.add(dayPlan);
      }
    }

    return weekDays;
  }

  /// Generate a cohesive AI-curated 7-day capsule rotation, avoiding repeating tops on consecutive days
  static Future<List<PlannedDayOutfit>> generateAiWeekPlan({
    required DateTime referenceDate,
    required List<ClothingItem> wardrobe,
  }) async {
    final monday = startOfWeek(referenceDate);
    final weeklyContexts = [
      (17, WeatherCondition.cloudy, Occasion.work, 'Діловий старт тижня · Офіс'),
      (15, WeatherCondition.rainy, Occasion.work, 'Робочі зустрічі під дощем'),
      (18, WeatherCondition.sunny, Occasion.casual, 'Кава & Коворкінг · Smart Casual'),
      (19, WeatherCondition.cloudy, Occasion.work, 'Презентація & Переговори'),
      (16, WeatherCondition.sunny, Occasion.dateNight, 'П\'ятничний вечір & Коктейль'),
      (20, WeatherCondition.sunny, Occasion.casual, 'Прогулянка містом & Бранч'),
      (18, WeatherCondition.cloudy, Occasion.casual, 'Затишний відпочинок & Парк'),
    ];

    final weekDays = <PlannedDayOutfit>[];
    String? lastTopId;
    String? lastOuterwearId;

    for (int i = 0; i < 7; i++) {
      final dayDate = monday.add(Duration(days: i));
      final dateKey = formatDate(dayDate);
      final ctx = weeklyContexts[i];

      // Filter wardrobe slightly to prefer different tops than yesterday for dynamic variety
      List<ClothingItem> dayWardrobe = List.from(wardrobe);
      if (lastTopId != null && dayWardrobe.where((item) => item.category == ClothingCategory.tops).length > 1) {
        dayWardrobe = dayWardrobe.where((item) => item.id != lastTopId).toList();
      }

      final curated = WeatherStylistService.curateOutfit(
        wardrobe: dayWardrobe.isNotEmpty ? dayWardrobe : wardrobe,
        temperatureCelsius: ctx.$1,
        condition: ctx.$2,
        occasion: ctx.$3,
      );

      final plan = PlannedDayOutfit(
        dateStr: dateKey,
        date: dayDate,
        weatherTemp: ctx.$1,
        weatherCondition: ctx.$2,
        occasion: ctx.$3,
        eventTitle: ctx.$4,
        outerwearId: curated.outerwear?.id ?? lastOuterwearId,
        topId: curated.top?.id,
        bottomId: curated.bottom?.id,
        shoesId: curated.shoes?.id,
        isWorn: false,
      );

      lastTopId = plan.topId;
      if (plan.outerwearId != null) {
        lastOuterwearId = plan.outerwearId;
      }

      weekDays.add(plan);
      await savePlan(plan);
    }

    return weekDays;
  }

  /// Mark a specific day's outfit as worn, recording it into WardrobeProvider
  static Future<void> markDayWorn({
    required PlannedDayOutfit day,
    required WardrobeProvider wardrobeProvider,
  }) async {
    day.isWorn = true;
    await savePlan(day);

    final items = day.getOutfitItems(wardrobeProvider.items);
    if (items.isNotEmpty) {
      await wardrobeProvider.recordOutfitWear(items);
    }
  }
}
