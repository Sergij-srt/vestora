import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wardrobe/models/clothing_item.dart';
import 'package:smart_wardrobe/services/travel_capsule_service.dart';
import 'package:smart_wardrobe/services/color_analysis_service.dart';
import 'package:smart_wardrobe/services/declutter_service.dart';

void main() {
  group('Advanced Market-Leading Features Tests', () {
    final sampleWardrobe = [
      ClothingItem(
        id: '1',
        title: 'Класичний вовняний блейзер',
        brand: 'Massimo Dutti',
        category: ClothingCategory.outerwear,
        color: 'Бежевий',
        season: Season.allSeason,
        price: 4900,
        imageUrl: '',
        fabricComposition: '100% Вовна',
        wearCount: 14,
      ),
      ClothingItem(
        id: '2',
        title: 'Біла лляна сорочка',
        brand: 'Zara',
        category: ClothingCategory.tops,
        color: 'Білий',
        season: Season.summer,
        price: 1499,
        imageUrl: '',
        fabricComposition: '100% Льон',
        wearCount: 22,
      ),
      ClothingItem(
        id: '3',
        title: 'Джинси прямого крою Straight Leg',
        brand: 'COS',
        category: ClothingCategory.bottoms,
        color: 'Синій денім',
        season: Season.allSeason,
        price: 3200,
        imageUrl: '',
        fabricComposition: '100% Органічна бавовна',
        wearCount: 31,
      ),
      ClothingItem(
        id: '4',
        title: 'Шкіряні білі кросівки Club C',
        brand: 'Reebok',
        category: ClothingCategory.shoes,
        color: 'Білий',
        season: Season.allSeason,
        price: 3100,
        imageUrl: '',
        fabricComposition: '100% Шкіра',
        wearCount: 45,
      ),
      ClothingItem(
        id: '5',
        title: 'Шовкова міді-сукня',
        brand: 'Mango',
        category: ClothingCategory.dresses,
        color: 'Смарагдовий',
        season: Season.summer,
        price: 2400,
        imageUrl: '',
        fabricComposition: '100% Шовк',
        wearCount: 1, // Dormant
      ),
    ];

    test('TravelCapsuleService curates carry-on capsule within item limits and generates daily looks', () {
      final plan = TravelCapsuleService.generateTravelCapsule(
        wardrobe: sampleWardrobe,
        city: 'Рим 🇮🇹',
        days: 4,
        tripType: TripType.cityBreak,
        luggageType: LuggageType.carryOn,
        temperatureCelsius: 19,
      );

      expect(plan.destinationCity, equals('Рим 🇮🇹'));
      expect(plan.durationDays, equals(4));
      expect(plan.capsuleItems.length, lessThanOrEqualTo(LuggageType.carryOn.maxClothingItems));
      expect(plan.dailyOutfits.length, equals(4));
      expect(plan.checklist.isNotEmpty, isTrue);
      expect(plan.combinationsCount, greaterThan(0));
    });

    test('ColorAnalysisService correctly evaluates closet compliance for seasonal palettes', () {
      final report = ColorAnalysisService.evaluateAlignment(
        wardrobe: sampleWardrobe,
        season: ColorSeason.warmAutumn,
      );

      expect(report.totalCount, equals(sampleWardrobe.length));
      expect(report.matchingCount, greaterThanOrEqualTo(1)); // Beige blazer
      expect(report.alignmentPercentage, greaterThan(0));
      expect(report.verdict.isNotEmpty, isTrue);
      expect(report.personalTip.isNotEmpty, isTrue);
    });

    test('DeclutterService identifies dormant clothes, calculates 60% resale cash and fabric care', () {
      final report = DeclutterService.evaluateDeclutterAndEco(wardrobe: sampleWardrobe);

      expect(report.dormantItems.length, equals(1)); // Mango dress (wearCount = 1)
      expect(report.dormantItems.first.title, contains('Шовкова'));
      expect(report.totalDormantValue, equals(2400.0));
      expect(report.estimatedResaleCash, equals(1440.0)); // 60% of 2400
      expect(report.waterSavedLiters, greaterThan(1000));
      expect(report.co2AvoidedKg, greaterThan(10));
      // Schedule should detect wool, linen, silk, leather
      expect(report.fabricCareSchedule.any((s) => s.fabricType.contains('Шовк')), isTrue);
      expect(report.fabricCareSchedule.any((s) => s.fabricType.contains('Вовна')), isTrue);
    });
  });
}
