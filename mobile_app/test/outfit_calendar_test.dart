import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_wardrobe/models/clothing_item.dart';
import 'package:smart_wardrobe/services/weather_stylist_service.dart';
import 'package:smart_wardrobe/services/outfit_calendar_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OutfitCalendarService Tests', () {
    late List<ClothingItem> mockWardrobe;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      mockWardrobe = [
        ClothingItem(
          id: 'top-1',
          title: 'Лляна сорочка AltaMen',
          brand: 'AltaMen',
          category: ClothingCategory.tops,
          color: 'Білий',
          season: Season.allSeason,
          price: 1850,
          imageUrl: 'https://example.com/shirt.jpg',
        ),
        ClothingItem(
          id: 'top-2',
          title: 'Шовкова блуза',
          brand: 'Massimo Dutti',
          category: ClothingCategory.tops,
          color: 'Бежевий',
          season: Season.allSeason,
          price: 2600,
          imageUrl: 'https://example.com/silk.jpg',
        ),
        ClothingItem(
          id: 'bot-1',
          title: 'Вовняні брюки палаццо',
          brand: 'Zara',
          category: ClothingCategory.bottoms,
          color: 'Сірий',
          season: Season.allSeason,
          price: 2100,
          imageUrl: 'https://example.com/pants.jpg',
        ),
        ClothingItem(
          id: 'shoe-1',
          title: 'Шкіряні лофери',
          brand: 'Vagabond',
          category: ClothingCategory.shoes,
          color: 'Чорний',
          season: Season.allSeason,
          price: 3400,
          imageUrl: 'https://example.com/shoes.jpg',
        ),
        ClothingItem(
          id: 'out-1',
          title: 'Класичний тренч',
          brand: 'Mango',
          category: ClothingCategory.outerwear,
          color: 'Бежевий',
          season: Season.allSeason,
          price: 4200,
          imageUrl: 'https://example.com/trench.jpg',
        ),
      ];
    });

    test('PlannedDayOutfit serialization and getters', () {
      final date = DateTime(2026, 10, 19); // Monday
      final plan = PlannedDayOutfit(
        dateStr: '2026-10-19',
        date: date,
        weatherTemp: 17,
        weatherCondition: WeatherCondition.cloudy,
        occasion: Occasion.work,
        eventTitle: 'Діловий понеділок',
        outerwearId: 'out-1',
        topId: 'top-1',
        bottomId: 'bot-1',
        shoesId: 'shoe-1',
      );

      expect(plan.dayOfWeekName, 'Понеділок');
      expect(plan.shortDayName, 'Пн');
      expect(plan.hasOutfit, isTrue);

      final items = plan.getOutfitItems(mockWardrobe);
      expect(items.length, 4);

      final json = plan.toJson();
      final fromJson = PlannedDayOutfit.fromJson(json);

      expect(fromJson.dateStr, '2026-10-19');
      expect(fromJson.weatherTemp, 17);
      expect(fromJson.weatherCondition, WeatherCondition.cloudy);
      expect(fromJson.occasion, Occasion.work);
      expect(fromJson.topId, 'top-1');
      expect(fromJson.isWorn, isFalse);
    });

    test('getWeekPlan returns 7 days starting from Monday', () async {
      final date = DateTime(2026, 10, 21); // Wednesday
      final week = await OutfitCalendarService.getWeekPlan(
        referenceDate: date,
        wardrobe: mockWardrobe,
      );

      expect(week.length, 7);
      expect(week[0].shortDayName, 'Пн');
      expect(week[6].shortDayName, 'Нд');
      // Curated outfits exist
      expect(week[0].hasOutfit, isTrue);
    });

    test('generateAiWeekPlan persists 7 days and rotates items', () async {
      final date = DateTime(2026, 10, 19);
      final generated = await OutfitCalendarService.generateAiWeekPlan(
        referenceDate: date,
        wardrobe: mockWardrobe,
      );

      expect(generated.length, 7);
      for (final day in generated) {
        expect(day.hasOutfit, isTrue);
      }

      // Check that plans were persisted in SharedPreferences
      final saved = await OutfitCalendarService.getAllPlans();
      expect(saved.length, greaterThanOrEqualTo(7));
      expect(saved.containsKey('2026-10-19'), isTrue);
    });

    test('savePlan and removePlan updates store correctly', () async {
      final date = DateTime(2026, 10, 25);
      final plan = PlannedDayOutfit(
        dateStr: '2026-10-25',
        date: date,
        weatherTemp: 22,
        weatherCondition: WeatherCondition.sunny,
        occasion: Occasion.casual,
        eventTitle: 'Бранч на терасі',
        topId: 'top-2',
      );

      await OutfitCalendarService.savePlan(plan);
      var all = await OutfitCalendarService.getAllPlans();
      expect(all['2026-10-25']?.eventTitle, 'Бранч на терасі');

      await OutfitCalendarService.removePlan('2026-10-25');
      all = await OutfitCalendarService.getAllPlans();
      expect(all.containsKey('2026-10-25'), isFalse);
    });
  });
}
