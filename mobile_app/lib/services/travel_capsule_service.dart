import '../models/clothing_item.dart';

enum TripType {
  cityBreak('Вікенд / City Break 🏙️', 'Комфортний одяг для прогулянок містом, кав\'ярень та музеїв.'),
  business('Ділова поїздка / Conference 💼', 'Smart casual та діловий стиль, презентабельний блейзер, класичне взуття.'),
  resort('Відпочинок / Теплі краї 🌴', 'Легкі тканини (льон, бавовна), шовк, зручне взуття.'),
  mountain('Гори / Активний відпочинок 🏔️', 'Теплий багатошаровий захист від вітру та холоду.');

  final String label;
  final String description;
  const TripType(this.label, this.description);
}

enum LuggageType {
  carryOn('Ручна поклажа (Carry-On) 🧳', 7, 'Максимум 7 універсальних речей, які поєднуються на 100%'),
  mediumSuitcase('Середня валіза 🧰', 11, 'До 11 речей для комфортної зміни образів'),
  fullWardrobe('Повна валіза ✈️', 15, 'До 15 речей на будь-яку несподівану погоду');

  final String label;
  final int maxClothingItems;
  final String description;
  const LuggageType(this.label, this.maxClothingItems, this.description);
}

class DailyTripOutfit {
  final int dayNumber;
  final String dayTitle;
  final String occasion;
  final List<ClothingItem> items;
  final String stylistTip;

  DailyTripOutfit({
    required this.dayNumber,
    required this.dayTitle,
    required this.occasion,
    required this.items,
    required this.stylistTip,
  });
}

class PackingChecklistItem {
  final String id;
  final String title;
  final String category;
  bool isChecked;

  PackingChecklistItem({
    required this.id,
    required this.title,
    required this.category,
    this.isChecked = false,
  });
}

class TravelCapsulePlan {
  final String destinationCity;
  final int durationDays;
  final TripType tripType;
  final LuggageType luggageType;
  final int estimatedTemperature;
  final List<ClothingItem> capsuleItems;
  final List<DailyTripOutfit> dailyOutfits;
  final List<PackingChecklistItem> checklist;
  final String stylistAdvice;
  final int combinationsCount;

  TravelCapsulePlan({
    required this.destinationCity,
    required this.durationDays,
    required this.tripType,
    required this.luggageType,
    required this.estimatedTemperature,
    required this.capsuleItems,
    required this.dailyOutfits,
    required this.checklist,
    required this.stylistAdvice,
    required this.combinationsCount,
  });
}

class TravelCapsuleService {
  /// Curates an optimal travel micro-capsule tailored to destination, days and suitcase size
  static TravelCapsulePlan generateTravelCapsule({
    required List<ClothingItem> wardrobe,
    required String city,
    required int days,
    required TripType tripType,
    required LuggageType luggageType,
    required int temperatureCelsius,
  }) {
    if (wardrobe.isEmpty) {
      return TravelCapsulePlan(
        destinationCity: city,
        durationDays: days,
        tripType: tripType,
        luggageType: luggageType,
        estimatedTemperature: temperatureCelsius,
        capsuleItems: [],
        dailyOutfits: [],
        checklist: [],
        stylistAdvice: 'Додайте спочатку речі до вашого цифрового гардероба.',
        combinationsCount: 0,
      );
    }

    final selectedItems = <ClothingItem>[];
    final maxItems = luggageType.maxClothingItems;

    // 1. Prioritize versatile core categories
    final outerwears = wardrobe.where((i) => i.category == ClothingCategory.outerwear).toList();
    final tops = wardrobe.where((i) => i.category == ClothingCategory.tops).toList();
    final bottoms = wardrobe.where((i) => i.category == ClothingCategory.bottoms).toList();
    final shoes = wardrobe.where((i) => i.category == ClothingCategory.shoes).toList();
    final bags = wardrobe.where((i) => i.category == ClothingCategory.bags).toList();
    final dresses = wardrobe.where((i) => i.category == ClothingCategory.dresses).toList();

    // 1 Outerwear (if cold or windy or business)
    if (temperatureCelsius < 20 && outerwears.isNotEmpty && selectedItems.length < maxItems) {
      selectedItems.add(outerwears.first);
    }

    // Bottoms (1-2 pairs)
    if (bottoms.isNotEmpty && selectedItems.length < maxItems) {
      selectedItems.add(bottoms.first);
      if (days >= 4 && bottoms.length > 1 && selectedItems.length < maxItems) {
        selectedItems.add(bottoms[1]);
      }
    }

    // Tops (2-4 tops)
    final topsToTake = (days <= 3 ? 2 : 3).clamp(1, tops.length);
    for (int i = 0; i < topsToTake && selectedItems.length < maxItems; i++) {
      if (i < tops.length) selectedItems.add(tops[i]);
    }

    // Dress if business or city break
    if ((tripType == TripType.business || tripType == TripType.cityBreak) && dresses.isNotEmpty && selectedItems.length < maxItems) {
      selectedItems.add(dresses.first);
    }

    // Shoes (1-2 pairs: comfortable walking + smart)
    if (shoes.isNotEmpty && selectedItems.length < maxItems) {
      selectedItems.add(shoes.first);
      if (days >= 4 && shoes.length > 1 && selectedItems.length < maxItems) {
        selectedItems.add(shoes[1]);
      }
    }

    // Bag (1 bag)
    if (bags.isNotEmpty && selectedItems.length < maxItems) {
      selectedItems.add(bags.first);
    }

    // Fill remaining quota with tops or accessories
    for (final it in wardrobe) {
      if (selectedItems.length >= maxItems) break;
      if (!selectedItems.contains(it)) {
        selectedItems.add(it);
      }
    }

    // 2. Generate Day-by-Day outfits
    final dailyOutfits = <DailyTripOutfit>[];
    for (int day = 1; day <= days; day++) {
      final top = tops.isNotEmpty ? tops[(day - 1) % tops.length] : null;
      final bottom = bottoms.isNotEmpty ? bottoms[(day - 1) % bottoms.length] : null;
      final shoe = shoes.isNotEmpty ? shoes[(day - 1) % shoes.length] : null;
      final outer = selectedItems.where((i) => i.category == ClothingCategory.outerwear).firstOrNull;

      final outfitItems = <ClothingItem>[];
      if (outer != null && (day == 1 || temperatureCelsius < 18)) outfitItems.add(outer);
      if (top != null) outfitItems.add(top);
      if (bottom != null) outfitItems.add(bottom);
      if (shoe != null) outfitItems.add(shoe);

      String tip = 'Зручний образ для дня $day';
      if (day == 1) {
        tip = 'Travel Day: багатошаровий та комфортний силует для дороги/літака.';
      } else if (day == days) {
        tip = 'День повернення: найзатишніший мікс речей із капсули.';
      } else if (tripType == TripType.business) {
        tip = 'Діловий день: структурований блейзер підкреслює впевненість.';
      } else {
        tip = 'Ідеально для прогулянок та фотосесій у $city.';
      }

      dailyOutfits.add(DailyTripOutfit(
        dayNumber: day,
        dayTitle: 'День $day · $city',
        occasion: day == 1 ? 'Дорога / Прибуття ✈️' : tripType.label,
        items: outfitItems,
        stylistTip: tip,
      ));
    }

    // 3. Generate Packing Checklist
    final checklist = <PackingChecklistItem>[];
    int checkId = 1;

    for (final it in selectedItems) {
      checklist.add(PackingChecklistItem(
        id: 'item_${checkId++}',
        title: '${it.category.icon} ${it.title} (${it.brand})',
        category: 'Одяг та взуття',
      ));
    }

    checklist.add(PackingChecklistItem(id: 'c_${checkId++}', title: 'Паспорт, квитки та страховка', category: 'Документи'));
    checklist.add(PackingChecklistItem(id: 'c_${checkId++}', title: 'Зарядні пристрої та PowerBank', category: 'Техніка'));
    checklist.add(PackingChecklistItem(id: 'c_${checkId++}', title: 'Міні-відпарювач або спрей проти складок', category: 'Догляд за одягом'));
    checklist.add(PackingChecklistItem(id: 'c_${checkId++}', title: 'Сонцезахисні окуляри та базовий догляд', category: 'Аксесуари'));

    final combinations = (selectedItems.where((i) => i.category == ClothingCategory.tops).length) *
        (selectedItems.where((i) => i.category == ClothingCategory.bottoms).length.clamp(1, 10));

    final advice = 'Для поїздки в $city на $days днів зібрано капсулу з ${selectedItems.length} речей. '
        'Вони створюють понад $combinations унікальних комбінацій без зайвої ваги у валізі.';

    return TravelCapsulePlan(
      destinationCity: city,
      durationDays: days,
      tripType: tripType,
      luggageType: luggageType,
      estimatedTemperature: temperatureCelsius,
      capsuleItems: selectedItems,
      dailyOutfits: dailyOutfits,
      checklist: checklist,
      stylistAdvice: advice,
      combinationsCount: combinations > 0 ? combinations : 6,
    );
  }
}
