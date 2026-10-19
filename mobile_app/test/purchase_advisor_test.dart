import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wardrobe/models/clothing_item.dart';
import 'package:smart_wardrobe/services/purchase_advisor_service.dart';

void main() {
  group('PurchaseAdvisorService tests', () {
    final sampleWardrobe = [
      ClothingItem(
        id: '1',
        title: 'Класичний оверсайз блейзер',
        brand: 'Massimo Dutti',
        imageUrl: 'https://example.com/blazer.jpg',
        category: ClothingCategory.outerwear,
        color: 'Бежевий',
        price: 4900,
      ),
      ClothingItem(
        id: '2',
        title: 'Біла лляна сорочка',
        brand: 'Zara',
        imageUrl: 'https://example.com/shirt.jpg',
        category: ClothingCategory.tops,
        color: 'Білий',
        price: 1500,
      ),
      ClothingItem(
        id: '3',
        title: 'Джинси прямого крою Straight Leg',
        brand: 'COS',
        imageUrl: 'https://example.com/jeans.jpg',
        category: ClothingCategory.bottoms,
        color: 'Синій денім',
        price: 3200,
      ),
      ClothingItem(
        id: '4',
        title: 'Шкіряні білі кросівки Club C',
        brand: 'Reebok',
        imageUrl: 'https://example.com/sneakers.jpg',
        category: ClothingCategory.shoes,
        color: 'Білий',
        price: 3100,
      ),
    ];

    test('Identifies duplicate blazer and recommends avoid or consider', () {
      final report = PurchaseAdvisorService.evaluatePurchase(
        title: 'Бежевий блейзер Zara',
        category: ClothingCategory.outerwear,
        color: 'Бежевий',
        price: 2800,
        currentWardrobe: sampleWardrobe,
      );

      expect(report.duplicateItems.isNotEmpty, true);
      expect(report.duplicateItems.first.title, contains('блейзер'));
      expect(report.verdict, anyOf(PurchaseVerdict.avoid, PurchaseVerdict.consider));
    });

    test('Recommends buy for novel item with high synergy and no duplicates', () {
      final report = PurchaseAdvisorService.evaluatePurchase(
        title: 'Шовкова міді спідниця',
        category: ClothingCategory.bottoms,
        color: 'Чорний',
        price: 1800,
        currentWardrobe: sampleWardrobe,
      );

      expect(report.duplicateItems.isEmpty, true);
      expect(report.synergyOutfitsCount, greaterThan(0));
      expect(report.verdict, PurchaseVerdict.buy);
    });
  });
}
