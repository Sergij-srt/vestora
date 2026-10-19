import 'dart:convert';

enum ClothingCategory {
  tops('Верх / Топи', '👕'),
  bottoms('Низ / Брюки', '👖'),
  dresses('Сукні / Комбінезони', '👗'),
  outerwear('Верхній одяг', '🧥'),
  shoes('Взуття', '👟'),
  bags('Сумки', '👜'),
  accessories('Аксесуари', '🕶️');

  final String label;
  final String icon;
  const ClothingCategory(this.label, this.icon);

  static ClothingCategory fromString(String? value) {
    if (value == null) return ClothingCategory.tops;
    return ClothingCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase() || e.label.toLowerCase() == value.toLowerCase(),
      orElse: () => ClothingCategory.tops,
    );
  }
}

enum Season {
  allSeason('Всесезонний'),
  spring('Весна'),
  summer('Літо'),
  autumn('Осінь'),
  winter('Зима');

  final String label;
  const Season(this.label);

  static Season fromString(String? value) {
    if (value == null) return Season.allSeason;
    return Season.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => Season.allSeason,
    );
  }
}

class ClothingItem {
  final String id;
  final String title;
  final String brand;
  final String imageUrl;
  final List<String> galleryImages;
  final ClothingCategory category;
  final Season season;
  final String color;
  final double price;
  final String currency;
  final String? sourceUrl;
  final String? storeName;
  final String? fabricComposition;
  final DateTime purchaseDate;
  int wearCount;
  final String? notes;

  ClothingItem({
    required this.id,
    required this.title,
    required this.brand,
    required this.imageUrl,
    List<String>? galleryImages,
    required this.category,
    this.season = Season.allSeason,
    this.color = 'Не вказано',
    this.price = 0.0,
    this.currency = 'UAH',
    this.sourceUrl,
    this.storeName,
    this.fabricComposition,
    DateTime? purchaseDate,
    this.wearCount = 0,
    this.notes,
  })  : galleryImages = galleryImages ?? (imageUrl.isNotEmpty ? [imageUrl] : []),
        purchaseDate = purchaseDate ?? DateTime.now();

  // Cost-per-wear calculation
  double get costPerWear {
    if (wearCount == 0) return price;
    return price / wearCount;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'brand': brand,
      'imageUrl': imageUrl,
      'galleryImages': galleryImages,
      'category': category.name,
      'season': season.name,
      'color': color,
      'price': price,
      'currency': currency,
      'sourceUrl': sourceUrl,
      'storeName': storeName,
      'fabricComposition': fabricComposition,
      'purchaseDate': purchaseDate.toIso8601String(),
      'wearCount': wearCount,
      'notes': notes,
    };
  }

  factory ClothingItem.fromMap(Map<String, dynamic> map) {
    return ClothingItem(
      id: map['id'] ?? '',
      title: map['title'] ?? 'Без назви',
      brand: map['brand'] ?? 'Невідомий бренд',
      imageUrl: map['imageUrl'] ?? '',
      galleryImages: map['galleryImages'] != null
          ? List<String>.from(map['galleryImages'])
          : (map['imageUrl'] != null ? [map['imageUrl']] : []),
      category: ClothingCategory.fromString(map['category']),
      season: Season.fromString(map['season']),
      color: map['color'] ?? 'Не вказано',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] ?? 'UAH',
      sourceUrl: map['sourceUrl'],
      storeName: map['storeName'],
      fabricComposition: map['fabricComposition'],
      purchaseDate: map['purchaseDate'] != null
          ? DateTime.tryParse(map['purchaseDate']) ?? DateTime.now()
          : DateTime.now(),
      wearCount: map['wearCount'] ?? 0,
      notes: map['notes'],
    );
  }

  String toJson() => json.encode(toMap());
  factory ClothingItem.fromJson(String source) => ClothingItem.fromMap(json.decode(source));
}
