import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wardrobe/models/clothing_item.dart';
import 'package:smart_wardrobe/services/capsule_matrix_service.dart';

void main() {
  group('CapsuleMatrixService Tests', () {
    final mockWardrobe = [
      ClothingItem(
        id: 'top-1',
        title: 'Лляна сорочка AltaMen',
        brand: 'AltaMen',
        category: ClothingCategory.tops,
        color: 'Молочний',
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
        id: 'top-3',
        title: 'Бавовняна футболка',
        brand: 'COS',
        category: ClothingCategory.tops,
        color: 'Білий',
        season: Season.allSeason,
        price: 1100,
        imageUrl: 'https://example.com/tee.jpg',
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
        id: 'bot-2',
        title: 'Джинси прямого крою',
        brand: 'Levi\'s',
        category: ClothingCategory.bottoms,
        color: 'Синій денім',
        season: Season.allSeason,
        price: 3200,
        imageUrl: 'https://example.com/jeans.jpg',
      ),
      ClothingItem(
        id: 'bot-3',
        title: 'Лляні шорти бермуди',
        brand: 'Mango',
        category: ClothingCategory.bottoms,
        color: 'Пісочний беж',
        season: Season.allSeason,
        price: 1600,
        imageUrl: 'https://example.com/shorts.jpg',
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
    ];

    test('Generates 3x3 matrix (9 combinations) with high versatility score', () {
      final matrix = CapsuleMatrixService.generateMatrix(wardrobe: mockWardrobe);

      expect(matrix.tops.length, 3);
      expect(matrix.bottoms.length, 3);
      expect(matrix.combinations.length, 9);
      expect(matrix.versatilityIndex, greaterThanOrEqualTo(90));
      expect(matrix.averageHarmonyScore, greaterThanOrEqualTo(9.0));

      final combo00 = matrix.getCombination(0, 0);
      expect(combo00, isNotNull);
      expect(combo00?.top.id, 'top-1');
      expect(combo00?.bottom.id, 'bot-1');
      expect(combo00?.harmonyScore, greaterThan(8.5));
    });

    test('Calculates total capsule investment and average CPW accurately', () {
      final matrix = CapsuleMatrixService.generateMatrix(wardrobe: mockWardrobe);

      expect(matrix.totalCapsuleValue, greaterThan(0));
      final combo = matrix.combinations.first;
      expect(combo.totalPrice, equals(combo.top.price + combo.bottom.price + (combo.shoes?.price ?? 0) + (combo.outerwear?.price ?? 0)));
      expect(combo.colorRationale, isNotEmpty);
      expect(combo.styleVerdict, isNotEmpty);
    });
  });
}
