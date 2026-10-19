import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wardrobe/models/clothing_item.dart';
import 'package:smart_wardrobe/services/style_check_service.dart';

void main() {
  group('StyleCheckService Tests', () {
    test('rewards <= 3 harmonious colors with high color score and positive highlights', () {
      final items = [
        ClothingItem(
          id: '1',
          title: 'Пальто',
          brand: 'Zara',
          category: ClothingCategory.outerwear,
          color: 'Бежевий',
          season: Season.allSeason,
          price: 3000,
          imageUrl: '',
        ),
        ClothingItem(
          id: '2',
          title: 'Сорочка',
          brand: 'Massimo Dutti',
          category: ClothingCategory.tops,
          color: 'Білий',
          season: Season.allSeason,
          price: 2000,
          imageUrl: '',
        ),
        ClothingItem(
          id: '3',
          title: 'Штани',
          brand: 'COS',
          category: ClothingCategory.bottoms,
          color: 'Чорний',
          season: Season.allSeason,
          price: 2500,
          imageUrl: '',
        ),
        ClothingItem(
          id: '4',
          title: 'Лофери',
          brand: 'Vagabond',
          category: ClothingCategory.shoes,
          color: 'Чорний',
          season: Season.allSeason,
          price: 3500,
          imageUrl: '',
        ),
      ];

      final eval = StyleCheckService.evaluateOutfit(outfitItems: items);

      expect(eval.overallScore, greaterThanOrEqualTo(8));
      expect(eval.colorHarmonyScore, equals(95));
      expect(eval.positiveHighlights.any((h) => h.contains('трьох кольорів')), isTrue);
      expect(eval.verdict.isNotEmpty, isTrue);
    });

    test('detects when > 3 colors are present and gives actionable advice', () {
      final items = [
        ClothingItem(
          id: '1',
          title: 'Куртка',
          brand: 'Zara',
          category: ClothingCategory.outerwear,
          color: 'Червоний',
          season: Season.allSeason,
          price: 2000,
          imageUrl: '',
        ),
        ClothingItem(
          id: '2',
          title: 'Топ',
          brand: 'H&M',
          category: ClothingCategory.tops,
          color: 'Зелений',
          season: Season.allSeason,
          price: 1000,
          imageUrl: '',
        ),
        ClothingItem(
          id: '3',
          title: 'Джинси',
          brand: 'Levi\'s',
          category: ClothingCategory.bottoms,
          color: 'Синій',
          season: Season.allSeason,
          price: 2500,
          imageUrl: '',
        ),
        ClothingItem(
          id: '4',
          title: 'Кеди',
          brand: 'Adidas',
          category: ClothingCategory.shoes,
          color: 'Жовтий',
          season: Season.allSeason,
          price: 3000,
          imageUrl: '',
        ),
      ];

      final eval = StyleCheckService.evaluateOutfit(outfitItems: items);

      expect(eval.colorHarmonyScore, equals(70));
      expect(eval.actionableTip.contains('3 активні кольори'), isTrue);
    });

    test('handles empty outfit without throwing', () {
      final eval = StyleCheckService.evaluateOutfit(outfitItems: []);
      expect(eval.overallScore, equals(5));
      expect(eval.verdict.contains('порожній'), isTrue);
    });
  });
}
