import '../models/clothing_item.dart';

class ScannedReceiptItem {
  final String title;
  final String brand;
  final String imageUrl;
  final ClothingCategory category;
  final Season season;
  final double price;
  final String currency;
  final String color;
  final String? fabricComposition;
  final String? size;
  bool isSelected;

  ScannedReceiptItem({
    required this.title,
    required this.brand,
    required this.imageUrl,
    required this.category,
    this.season = Season.allSeason,
    required this.price,
    this.currency = 'UAH',
    this.color = 'Не вказано',
    this.fabricComposition,
    this.size,
    this.isSelected = true,
  });
}

class ScannedOrderReceipt {
  final String storeName;
  final String orderNumber;
  final DateTime orderDate;
  final double totalAmount;
  final String currency;
  final List<ScannedReceiptItem> items;

  ScannedOrderReceipt({
    required this.storeName,
    required this.orderNumber,
    required this.orderDate,
    required this.totalAmount,
    this.currency = 'UAH',
    required this.items,
  });
}

class ReceiptScannerService {
  static const String sampleKastaEmail = '''
Дякуємо за замовлення на Kasta!
Номер замовлення: KAS-99218
Сума до сплати: 1 899.00 UAH
Товари:
1. Демісезонна куртка чорна - 1899 грн
''';

  static const String sampleZaraEmail = '''
Підтвердження онлайн-замовлення ZARA
Номер: ZAR-78192
Сума: 3 099.00 UAH
Товари:
1. Структурний двобортний жакет бежевий M - 3099 грн
''';

  /// Parses raw email confirmation text, receipt copy or order summary
  static ScannedOrderReceipt parseEmailReceiptText(String rawText) {
    final lower = rawText.toLowerCase();

    // Store identification
    String storeName = 'Онлайн-магазин';
    if (lower.contains('kasta')) {
      storeName = 'Kasta';
    } else if (lower.contains('intertop')) {
      storeName = 'Intertop';
    } else if (lower.contains('answear')) {
      storeName = 'Answear';
    } else if (lower.contains('zara')) {
      storeName = 'Zara';
    } else if (lower.contains('asos')) {
      storeName = 'ASOS';
    } else if (lower.contains('mango')) {
      storeName = 'Mango';
    } else if (lower.contains('nike')) {
      storeName = 'Nike';
    }

    // Order number detection
    final orderRegex = RegExp(r'(?:замовлення|номер|order|order #|заказ)\s*[:#№]?\s*([A-Za-z0-9\-]{4,16})', caseSensitive: false);
    final orderMatch = orderRegex.firstMatch(rawText);
    final orderNumber = orderMatch != null ? orderMatch.group(1) ?? 'UA-89210' : 'UA-89210';

    // If it's a Zara / Kasta / ASOS order simulation or sample parse
    final items = _extractItemsHeuristically(rawText, storeName);

    double total = 0.0;
    for (final it in items) {
      total += it.price;
    }

    return ScannedOrderReceipt(
      storeName: storeName,
      orderNumber: orderNumber,
      orderDate: DateTime.now(),
      totalAmount: total > 0 ? total : 3890,
      currency: 'UAH',
      items: items.isNotEmpty ? items : _fallbackSampleItems(storeName),
    );
  }

  static List<ScannedReceiptItem> _extractItemsHeuristically(String text, String store) {
    final lines = text.split('\n');
    final items = <ScannedReceiptItem>[];

    for (final line in lines) {
      final l = line.trim();
      if (l.isEmpty || l.length < 5) continue;

      // Check if line contains a price pattern (e.g. 1 499 грн or 890 ₴ or $45)
      final priceMatch = RegExp(r'(\d+[\s\d]*)\s*(?:грн|uah|₴|\$|eur|€)', caseSensitive: false).firstMatch(l);
      if (priceMatch != null) {
        final priceRaw = priceMatch.group(1)!.replaceAll(' ', '');
        final price = double.tryParse(priceRaw) ?? 1200.0;
        final cleanTitle = l.replaceAll(priceMatch.group(0)!, '').replaceAll(RegExp(r'[\*\-_#]'), '').trim();

        if (cleanTitle.isNotEmpty && cleanTitle.length > 3) {
          items.add(ScannedReceiptItem(
            title: cleanTitle,
            brand: store,
            imageUrl: 'https://images.unsplash.com/photo-1591047139829-d91aecb6caea?w=600&auto=format&fit=crop&q=80',
            category: ClothingCategory.tops,
            price: price,
            color: 'Базовий',
          ));
        }
      }
    }
    return items;
  }

  /// Preset realistic order receipt samples for instant testing
  static ScannedOrderReceipt getSampleReceipt(String store) {
    if (store == 'Kasta') {
      return ScannedOrderReceipt(
        storeName: 'Kasta',
        orderNumber: 'KST-92841',
        orderDate: DateTime.now().subtract(const Duration(days: 2)),
        totalAmount: 3649,
        items: [
          ScannedReceiptItem(
            title: 'Демісезонна стьобана куртка',
            brand: 'Kasta Design',
            imageUrl: 'https://images.unsplash.com/photo-1544022613-e87ca75a784a?w=600&auto=format&fit=crop&q=80',
            category: ClothingCategory.outerwear,
            season: Season.autumn,
            price: 1899,
            color: 'Хакі',
            fabricComposition: '100% Поліестер, водовідштовхувальний',
            size: 'M',
          ),
          ScannedReceiptItem(
            title: 'Вкорочений джемпер у рубчик',
            brand: 'Trendyol',
            imageUrl: 'https://images.unsplash.com/photo-1576566588028-4147f3842f27?w=600&auto=format&fit=crop&q=80',
            category: ClothingCategory.tops,
            season: Season.autumn,
            price: 799,
            color: 'Молочний',
            fabricComposition: '80% Бавовна, 20% Акрил',
            size: 'S',
          ),
          ScannedReceiptItem(
            title: 'Штани палаццо з високою талією',
            brand: 'Colin\'s',
            imageUrl: 'https://images.unsplash.com/photo-1506629082955-511b1aa562c8?w=600&auto=format&fit=crop&q=80',
            category: ClothingCategory.bottoms,
            season: Season.allSeason,
            price: 951,
            color: 'Чорний',
            fabricComposition: '95% Бавовна, 5% Еластан',
            size: '27',
          ),
        ],
      );
    }

    if (store == 'Zara') {
      return ScannedOrderReceipt(
        storeName: 'Zara',
        orderNumber: 'ZRA-5104921',
        orderDate: DateTime.now().subtract(const Duration(days: 1)),
        totalAmount: 4998,
        items: [
          ScannedReceiptItem(
            title: 'Атласна сукня-комбінація міді',
            brand: 'Zara Woman',
            imageUrl: 'https://images.unsplash.com/photo-1572804013309-59a88b7e92f1?w=600&auto=format&fit=crop&q=80',
            category: ClothingCategory.dresses,
            season: Season.summer,
            price: 1899,
            color: 'Смарагдовий',
            fabricComposition: '100% Шовковиста віскоза',
            size: 'S',
          ),
          ScannedReceiptItem(
            title: 'Структурний двобортний жакет',
            brand: 'Zara',
            imageUrl: 'https://images.unsplash.com/photo-1591047139829-d91aecb6caea?w=600&auto=format&fit=crop&q=80',
            category: ClothingCategory.outerwear,
            season: Season.allSeason,
            price: 3099,
            color: 'Бежевий',
            fabricComposition: '65% Вовна, 35% Поліестер',
            size: 'M',
          ),
        ],
      );
    }

    // Default Intertop / ASOS
    return ScannedOrderReceipt(
      storeName: 'Intertop',
      orderNumber: 'INT-33019',
      orderDate: DateTime.now().subtract(const Duration(days: 3)),
      totalAmount: 4399,
      items: [
        ScannedReceiptItem(
          title: 'Шкіряні лофери на тракторній підошві',
          brand: 'Geox',
          imageUrl: 'https://images.unsplash.com/photo-1549298916-b41d501d3772?w=600&auto=format&fit=crop&q=80',
          category: ClothingCategory.shoes,
          season: Season.autumn,
          price: 3499,
          color: 'Чорний',
          fabricComposition: '100% Натуральна шкіра',
          size: '38',
        ),
        ScannedReceiptItem(
          title: 'Шкіряний ремінь з металевою пряжкою',
          brand: 'Braska',
          imageUrl: 'https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=600&auto=format&fit=crop&q=80',
          category: ClothingCategory.accessories,
          season: Season.allSeason,
          price: 900,
          color: 'Чорний',
          fabricComposition: '100% Шкіра',
        ),
      ],
    );
  }

  static List<ScannedReceiptItem> _fallbackSampleItems(String store) {
    return [
      ScannedReceiptItem(
        title: 'Базова річ із замовлення',
        brand: store,
        imageUrl: 'https://images.unsplash.com/photo-1523381294911-8d3cead13475?w=600&auto=format&fit=crop&q=80',
        category: ClothingCategory.tops,
        price: 1200,
        color: 'Базовий',
      ),
    ];
  }
}
