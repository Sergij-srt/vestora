import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wardrobe/models/clothing_item.dart';
import 'package:smart_wardrobe/services/weather_stylist_service.dart';

void main() {
  group('WeatherStylistService Tests', () {
    final sampleWardrobe = [
      ClothingItem(
        id: '1',
        title: 'Класичний Бежевий Тренч',
        brand: 'Mango',
        category: ClothingCategory.outerwear,
        color: 'Бежевий',
        season: Season.allSeason,
        price: 3200,
        imageUrl: 'https://example.com/trench.jpg',
      ),
      ClothingItem(
        id: '2',
        title: 'Шерстяне Пальто Оверсайз',
        brand: 'Zara',
        category: ClothingCategory.outerwear,
        color: 'Чорний',
        season: Season.winter,
        price: 4500,
        imageUrl: 'https://example.com/coat.jpg',
      ),
      ClothingItem(
        id: '3',
        title: 'Шовкова Сорочка',
        brand: 'Massimo Dutti',
        category: ClothingCategory.tops,
        color: 'Білий',
        season: Season.allSeason,
        price: 2400,
        imageUrl: 'https://example.com/shirt.jpg',
      ),
      ClothingItem(
        id: '4',
        title: 'Класичні Брюки Палаццо',
        brand: 'Zara',
        category: ClothingCategory.bottoms,
        color: 'Сірий',
        season: Season.allSeason,
        price: 1800,
        imageUrl: 'https://example.com/pants.jpg',
      ),
      ClothingItem(
        id: '5',
        title: 'Шкіряні Лофери',
        brand: 'Vagabond',
        category: ClothingCategory.shoes,
        color: 'Чорний',
        season: Season.allSeason,
        price: 3500,
        imageUrl: 'https://example.com/shoes.jpg',
      ),
    ];

    test('curates rainy day outfit prioritizing trench outerwear', () {
      final outfit = WeatherStylistService.curateOutfit(
        wardrobe: sampleWardrobe,
        temperatureCelsius: 14,
        condition: WeatherCondition.rainy,
        occasion: Occasion.work,
      );

      expect(outfit.outerwear, isNotNull);
      expect(outfit.outerwear!.title.toLowerCase().contains('тренч'), isTrue);
      expect(outfit.weatherRationale.isNotEmpty, isTrue);
      expect(outfit.occasionRationale.isNotEmpty, isTrue);
    });

    test('omits heavy outerwear in warm sunny weather', () {
      final outfit = WeatherStylistService.curateOutfit(
        wardrobe: sampleWardrobe,
        temperatureCelsius: 24,
        condition: WeatherCondition.sunny,
        occasion: Occasion.casual,
      );

      expect(outfit.outerwear, isNull);
      expect(outfit.top, isNotNull);
      expect(outfit.bottom, isNotNull);
    });

    test('handles empty wardrobe gracefully', () {
      final outfit = WeatherStylistService.curateOutfit(
        wardrobe: [],
        temperatureCelsius: 18,
        condition: WeatherCondition.cloudy,
        occasion: Occasion.casual,
      );

      expect(outfit.allItems.isEmpty, isTrue);
      expect(outfit.weatherRationale.contains('Додайте'), isTrue);
    });
  });
}
