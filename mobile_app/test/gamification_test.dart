import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wardrobe/models/clothing_item.dart';
import 'package:smart_wardrobe/services/gamification_service.dart';

void main() {
  group('GamificationService Tests', () {
    final sampleItems = [
      ClothingItem(
        id: '1',
        title: 'Блейзер Оверсайз',
        brand: 'Zara',
        category: ClothingCategory.outerwear,
        color: 'Чорний',
        season: Season.allSeason,
        price: 2500,
        imageUrl: '',
        wearCount: 10,
        fabricComposition: '60% вовна, 40% поліестер',
      ),
      ClothingItem(
        id: '2',
        title: 'Шовкова Блуза',
        brand: 'Massimo Dutti',
        category: ClothingCategory.tops,
        color: 'Молочний',
        season: Season.allSeason,
        price: 2200,
        imageUrl: '',
        wearCount: 0, // Dormant
      ),
      ClothingItem(
        id: '3',
        title: 'Штани Прямі',
        brand: 'Mango',
        category: ClothingCategory.bottoms,
        color: 'Бежевий',
        season: Season.allSeason,
        price: 1800,
        imageUrl: '',
        wearCount: 6,
      ),
      ClothingItem(
        id: '4',
        title: 'Шкіряні Лофери',
        brand: 'Vagabond',
        category: ClothingCategory.shoes,
        color: 'Чорний',
        season: Season.allSeason,
        price: 3200,
        imageUrl: '',
        wearCount: 8,
      ),
    ];

    test('calculates correct utilization and dormant count', () {
      final report = GamificationService.evaluateWardrobeHealth(
        items: sampleItems,
        streakDays: 14,
      );

      expect(report.activeItemsCount, equals(3));
      expect(report.dormantItemsCount, equals(1));
      expect(report.utilizationRate, equals(75.0));
      expect(report.healthScore, greaterThanOrEqualTo(50));
      expect(report.suggestions.isNotEmpty, isTrue);
    });

    test('unlocks 7-day streak badge when streak >= 7', () {
      final report = GamificationService.evaluateWardrobeHealth(
        items: sampleItems,
        streakDays: 7,
      );

      final streakBadge = report.badges.firstWhere((b) => b.id == 'streak_7');
      expect(streakBadge.isUnlocked, isTrue);

      final marathonBadge = report.badges.firstWhere((b) => b.id == 'streak_30');
      expect(marathonBadge.isUnlocked, isFalse);
    });

    test('generates complete resale listing with 40% discount', () {
      final item = sampleItems[0];
      final listing = GamificationService.generateResaleListing(item);

      expect(listing.contains('Zara'), isTrue);
      expect(listing.contains('Блейзер Оверсайз'), isTrue);
      expect(listing.contains('60% вовна'), isTrue);
      expect(listing.contains('1500 ₴'), isTrue); // 2500 * 0.6 = 1500
      expect(listing.contains('Vestora'), isTrue);
      expect(listing.contains('Shafa'), isTrue);
    });
  });
}
