import '../models/clothing_item.dart';

enum WeatherCondition {
  sunny('Сонячно ☀️', 'Тепло і яскраво, ідеальний день для натуральних легких тканин.'),
  rainy('Дощ 🌧️', 'Висока вологість! Уникайте замші та шовку, обирайте захисний верхній одяг та шкіряне взуття.'),
  cloudy('Хмарно ⛅', 'Помірний день, чудово підходить для багатошарових образів.'),
  coldWindy('Вітряно та прохолодно 💨', 'Потрібен вітрозахисний шар або щільний жакет.'),
  snowy('Сніг та мороз ❄️', 'Максимальний захист: вовна, кашемір, пуховик та тепле взуття.');

  final String label;
  final String advice;
  const WeatherCondition(this.label, this.advice);
}

enum Occasion {
  work('Офіс / Ділові зустрічі 💼', 'Smart Casual або діловий дрес-код: чіткі лінії, блейзер, класичні кольори.'),
  casual('Прогулянка / Кав\'ярня ☕', 'Максимальний комфорт, вільний крій, зручне взуття.'),
  dateNight('Вечір / Побачення ✨', 'Витончений акцентний силует, благородні текстури, сукня або стильний жакет.'),
  sport('Спорт / Активність 🏃', 'Дихаючі спортивні тканини, еластичність, кеди або кросівки.'),
  travel('Подорож / Дорога ✈️', 'Практичні багатошарові речі, які не мнуться.');

  final String label;
  final String description;
  const Occasion(this.label, this.description);
}

class CuratedDailyOutfit {
  final ClothingItem? outerwear;
  final ClothingItem? top;
  final ClothingItem? bottom;
  final ClothingItem? dress;
  final ClothingItem? shoes;
  final ClothingItem? accessory;
  final String weatherRationale;
  final String occasionRationale;
  final int comfortScore; // 0-100

  CuratedDailyOutfit({
    this.outerwear,
    this.top,
    this.bottom,
    this.dress,
    this.shoes,
    this.accessory,
    required this.weatherRationale,
    required this.occasionRationale,
    this.comfortScore = 95,
  });

  List<ClothingItem> get allItems {
    final list = <ClothingItem>[];
    if (outerwear != null) list.add(outerwear!);
    if (top != null) list.add(top!);
    if (bottom != null) list.add(bottom!);
    if (dress != null) list.add(dress!);
    if (shoes != null) list.add(shoes!);
    if (accessory != null) list.add(accessory!);
    return list;
  }
}

class WeatherStylistService {
  /// Generates context-aware outfit recommendation tailored to current weather and occasion
  static CuratedDailyOutfit curateOutfit({
    required List<ClothingItem> wardrobe,
    required int temperatureCelsius,
    required WeatherCondition condition,
    required Occasion occasion,
  }) {
    if (wardrobe.isEmpty) {
      return CuratedDailyOutfit(
        weatherRationale: 'Додайте спочатку декілька речей у гардероб.',
        occasionRationale: '',
      );
    }

    final isRainy = condition == WeatherCondition.rainy;
    final isCold = temperatureCelsius < 15;
    final isHot = temperatureCelsius > 22;

    // 1. Select Outerwear (if cold, windy or rainy)
    ClothingItem? selectedOuterwear;
    if (isCold || isRainy || condition == WeatherCondition.coldWindy) {
      final availableOuterwear = wardrobe.where((i) => i.category == ClothingCategory.outerwear).toList();
      if (availableOuterwear.isNotEmpty) {
        if (isRainy) {
          // Prioritize trench / waterproof
          selectedOuterwear = availableOuterwear.firstWhere(
            (i) => i.title.toLowerCase().contains('тренч') || i.title.toLowerCase().contains('куртк'),
            orElse: () => availableOuterwear.first,
          );
        } else {
          selectedOuterwear = availableOuterwear.first;
        }
      }
    }

    // 2. Select Dress vs Top + Bottom
    ClothingItem? selectedDress;
    ClothingItem? selectedTop;
    ClothingItem? selectedBottom;

    final dresses = wardrobe.where((i) => i.category == ClothingCategory.dresses).toList();
    final tops = wardrobe.where((i) => i.category == ClothingCategory.tops).toList();
    final bottoms = wardrobe.where((i) => i.category == ClothingCategory.bottoms).toList();

    if (occasion == Occasion.dateNight && dresses.isNotEmpty && !isCold) {
      selectedDress = dresses.first;
    } else {
      // Top selection
      if (tops.isNotEmpty) {
        if (isHot) {
          selectedTop = tops.firstWhere(
            (i) => (i.fabricComposition ?? '').toLowerCase().contains('льон') || i.title.toLowerCase().contains('футболк'),
            orElse: () => tops.first,
          );
        } else {
          selectedTop = tops.first;
        }
      }

      // Bottom selection
      if (bottoms.isNotEmpty) {
        selectedBottom = bottoms.first;
      }
    }

    // 3. Select Shoes
    ClothingItem? selectedShoes;
    final shoes = wardrobe.where((i) => i.category == ClothingCategory.shoes).toList();
    if (shoes.isNotEmpty) {
      if (isRainy) {
        // Avoid white canvas / sandals in rain, prefer leather/boots
        selectedShoes = shoes.firstWhere(
          (i) => !i.title.toLowerCase().contains('сандал') && !i.title.toLowerCase().contains('босоніж'),
          orElse: () => shoes.first,
        );
      } else if (occasion == Occasion.sport || occasion == Occasion.casual) {
        selectedShoes = shoes.firstWhere(
          (i) => i.title.toLowerCase().contains('кросівк') || i.title.toLowerCase().contains('кед'),
          orElse: () => shoes.first,
        );
      } else {
        selectedShoes = shoes.first;
      }
    }

    // 4. Select Accessories/Bags
    ClothingItem? selectedAccessory;
    final accessories = wardrobe.where((i) => i.category == ClothingCategory.bags || i.category == ClothingCategory.accessories).toList();
    if (accessories.isNotEmpty) {
      selectedAccessory = accessories.first;
    }

    // Explanations
    final weatherRationale = 'Температура $temperatureCelsius°C (${condition.label}). ${condition.advice}';
    final occasionRationale = 'Обрано під формат «${occasion.label}». ${occasion.description}';

    return CuratedDailyOutfit(
      outerwear: selectedOuterwear,
      top: selectedTop,
      bottom: selectedBottom,
      dress: selectedDress,
      shoes: selectedShoes,
      accessory: selectedAccessory,
      weatherRationale: weatherRationale,
      occasionRationale: occasionRationale,
      comfortScore: isRainy ? 92 : 98,
    );
  }
}
