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
      (e) =>
          e.name.toLowerCase() == value.toLowerCase() ||
          e.label.toLowerCase() == value.toLowerCase(),
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
      (e) =>
          e.name.toLowerCase() == value.toLowerCase() ||
          e.label.toLowerCase() == value.toLowerCase(),
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
  final String? size;
  final String? countryOfOrigin;
  final String? careInstructions;
  final String? labelPhotoUrl;
  final String? receiptPhotoUrl;
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
    this.size,
    this.countryOfOrigin,
    this.careInstructions,
    this.labelPhotoUrl,
    this.receiptPhotoUrl,
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

  ClothingItem copyWith({
    String? id,
    String? title,
    String? brand,
    String? imageUrl,
    List<String>? galleryImages,
    ClothingCategory? category,
    Season? season,
    String? color,
    double? price,
    String? currency,
    String? sourceUrl,
    String? storeName,
    String? fabricComposition,
    String? size,
    String? countryOfOrigin,
    String? careInstructions,
    String? labelPhotoUrl,
    String? receiptPhotoUrl,
    DateTime? purchaseDate,
    int? wearCount,
    String? notes,
  }) {
    return ClothingItem(
      id: id ?? this.id,
      title: title ?? this.title,
      brand: brand ?? this.brand,
      imageUrl: imageUrl ?? this.imageUrl,
      galleryImages: galleryImages ?? this.galleryImages,
      category: category ?? this.category,
      season: season ?? this.season,
      color: color ?? this.color,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      storeName: storeName ?? this.storeName,
      fabricComposition: fabricComposition ?? this.fabricComposition,
      size: size ?? this.size,
      countryOfOrigin: countryOfOrigin ?? this.countryOfOrigin,
      careInstructions: careInstructions ?? this.careInstructions,
      labelPhotoUrl: labelPhotoUrl ?? this.labelPhotoUrl,
      receiptPhotoUrl: receiptPhotoUrl ?? this.receiptPhotoUrl,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      wearCount: wearCount ?? this.wearCount,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    // Avoid duplicating large inline Base64 data URIs in galleryImages
    final normalizedGallery = (imageUrl.startsWith('data:') &&
            galleryImages.length == 1 &&
            galleryImages.first == imageUrl)
        ? <String>[]
        : galleryImages;

    return {
      'id': id,
      'title': title,
      'brand': brand,
      'imageUrl': imageUrl,
      'galleryImages': normalizedGallery,
      'category': category.name,
      'season': season.name,
      'color': color,
      'price': price,
      'currency': currency,
      'sourceUrl': sourceUrl,
      'storeName': storeName,
      'fabricComposition': fabricComposition,
      'size': size,
      'countryOfOrigin': countryOfOrigin,
      'careInstructions': careInstructions,
      'labelPhotoUrl': labelPhotoUrl,
      'receiptPhotoUrl': receiptPhotoUrl,
      'purchaseDate': purchaseDate.toIso8601String(),
      'wearCount': wearCount,
      'notes': notes,
    };
  }

  /// Maps ClothingItem to PostgreSQL snake_case column format for `public.clothing_items`.
  Map<String, dynamic> toPostgresRow(String userId) {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'brand': brand,
      'category': category.name,
      'season': season.name,
      'color': color,
      'price': price,
      'currency': currency,
      'image_url': imageUrl,
      'gallery_images': galleryImages,
      'source_url': sourceUrl,
      'store_name': storeName,
      'fabric_composition': fabricComposition,
      'size': size,
      'country_of_origin': countryOfOrigin,
      'care_instructions': careInstructions,
      'label_photo_url': labelPhotoUrl,
      'receipt_photo_url': receiptPhotoUrl,
      'wear_count': wearCount,
      'purchase_date': purchaseDate.toUtc().toIso8601String(),
      'notes': notes,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  /// Parses ClothingItem from either local camelCase JSON or PostgreSQL snake_case row.
  factory ClothingItem.fromMap(Map<String, dynamic> map) {
    final resolvedImageUrl = (map['imageUrl'] ?? map['image_url'] ?? '') as String;
    final rawGallery = map['galleryImages'] ?? map['gallery_images'];
    List<String> resolvedGallery;
    if (rawGallery is List && rawGallery.isNotEmpty) {
      resolvedGallery = rawGallery.map((e) => e.toString()).toList();
    } else if (resolvedImageUrl.isNotEmpty) {
      resolvedGallery = [resolvedImageUrl];
    } else {
      resolvedGallery = [];
    }

    final rawPurchaseDate = map['purchaseDate'] ?? map['purchase_date'];
    final rawPrice = map['price'];
    double parsedPrice = 0.0;
    if (rawPrice is num) {
      parsedPrice = rawPrice.toDouble();
    } else if (rawPrice is String) {
      parsedPrice = double.tryParse(rawPrice) ?? 0.0;
    }

    final rawWearCount = map['wearCount'] ?? map['wear_count'];
    int parsedWearCount = 0;
    if (rawWearCount is int) {
      parsedWearCount = rawWearCount;
    } else if (rawWearCount is num) {
      parsedWearCount = rawWearCount.toInt();
    } else if (rawWearCount is String) {
      parsedWearCount = int.tryParse(rawWearCount) ?? 0;
    }

    return ClothingItem(
      id: (map['id'] ?? '').toString(),
      title: (map['title'] ?? 'Без назви').toString(),
      brand: (map['brand'] ?? 'Невідомий бренд').toString(),
      imageUrl: resolvedImageUrl,
      galleryImages: resolvedGallery,
      category: ClothingCategory.fromString(map['category']?.toString()),
      season: Season.fromString(map['season']?.toString()),
      color: (map['color'] ?? 'Не вказано').toString(),
      price: parsedPrice,
      currency: (map['currency'] ?? 'UAH').toString(),
      sourceUrl: (map['sourceUrl'] ?? map['source_url'])?.toString(),
      storeName: (map['storeName'] ?? map['store_name'])?.toString(),
      fabricComposition: (map['fabricComposition'] ?? map['fabric_composition'])?.toString(),
      size: map['size']?.toString(),
      countryOfOrigin: (map['countryOfOrigin'] ?? map['country_of_origin'])?.toString(),
      careInstructions: (map['careInstructions'] ?? map['care_instructions'])?.toString(),
      labelPhotoUrl: (map['labelPhotoUrl'] ?? map['label_photo_url'])?.toString(),
      receiptPhotoUrl: (map['receiptPhotoUrl'] ?? map['receipt_photo_url'])?.toString(),
      purchaseDate: rawPurchaseDate != null
          ? DateTime.tryParse(rawPurchaseDate.toString()) ?? DateTime.now()
          : DateTime.now(),
      wearCount: parsedWearCount,
      notes: map['notes']?.toString(),
    );
  }

  factory ClothingItem.fromPostgresRow(Map<String, dynamic> row) => ClothingItem.fromMap(row);

  String toJson() => json.encode(toMap());
  factory ClothingItem.fromJson(String source) => ClothingItem.fromMap(json.decode(source));
}
