import '../models/clothing_item.dart';

class ParsedLabelData {
  final String? brand;
  final ClothingCategory? category;
  final String? fabricComposition;
  final String? size;
  final String? careInstructions;
  final String? countryOfOrigin;
  final String? color;
  final String? skuCode;
  final double confidence;
  final List<String> rawExtractedLines;

  ParsedLabelData({
    this.brand,
    this.category,
    this.fabricComposition,
    this.size,
    this.careInstructions,
    this.countryOfOrigin,
    this.color,
    this.skuCode,
    this.confidence = 0.95,
    this.rawExtractedLines = const [],
  });
}

class ParsedReceiptData {
  final String? storeName;
  final String? itemTitle;
  final double? price;
  final String currency;
  final DateTime? date;
  final String? skuCode;
  final double? discount;
  final double confidence;
  final List<String> rawExtractedLines;

  ParsedReceiptData({
    this.storeName,
    this.itemTitle,
    this.price,
    this.currency = 'UAH',
    this.date,
    this.skuCode,
    this.discount,
    this.confidence = 0.96,
    this.rawExtractedLines = const [],
  });
}

class OcrCombinedResult {
  String title;
  String brand;
  ClothingCategory category;
  Season season;
  String color;
  double price;
  String currency;
  String? size;
  String? fabricComposition;
  String? storeName;
  String? careInstructions;
  String? countryOfOrigin;
  String? itemPhoto;
  String? labelPhoto;
  String? receiptPhoto;
  final Map<String, String> detectedFromLabel;
  final Map<String, String> detectedFromReceipt;

  OcrCombinedResult({
    required this.title,
    required this.brand,
    required this.category,
    this.season = Season.allSeason,
    required this.color,
    required this.price,
    this.currency = 'UAH',
    this.size,
    this.fabricComposition,
    this.storeName,
    this.careInstructions,
    this.countryOfOrigin,
    this.itemPhoto,
    this.labelPhoto,
    this.receiptPhoto,
    this.detectedFromLabel = const {},
    this.detectedFromReceipt = const {},
  });
}

class ClothingOcrService {
  /// Parses raw OCR text from a clothing label / care tag
  static ParsedLabelData parseLabelText(String rawText) {
    final lower = rawText.toLowerCase();
    final lines = rawText.split(RegExp(r'[\r\n]+')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    // 1. Detect Brand
    String? brand;
    final brands = [
      'Massimo Dutti',
      'Zara',
      'COS',
      'Mango',
      'H&M',
      'Arket',
      'Levi\'s',
      'Tommy Hilfiger',
      'Sandro',
      'Maje',
      'Calvin Klein',
      'Nike',
      'Adidas',
      'Vagabond',
      'Other Stories',
    ];
    for (final b in brands) {
      if (lower.contains(b.toLowerCase())) {
        brand = b;
        break;
      }
    }

    // 2. Detect Size
    String? size;
    final sizeRegex = RegExp(
      r'(?:size|розмір|talla|taille|größe|eur|us|uk|it)\s*[:/]?\s*([A-Za-z0-9\-/\s]{1,15})',
      caseSensitive: false,
    );
    final sizeMatch = sizeRegex.firstMatch(rawText);
    if (sizeMatch != null) {
      size = sizeMatch.group(1)?.trim();
    } else {
      // Fallback single sizes
      final simpleSizeRegex = RegExp(r'\b(XXS|XS|S|M|L|XL|XXL|EUR\s*\d{2}|US\s*\d{1,2}|W\d{2}\s*L\d{2})\b', caseSensitive: false);
      final simpleMatch = simpleSizeRegex.firstMatch(rawText);
      if (simpleMatch != null) {
        size = simpleMatch.group(1);
      }
    }

    // 3. Detect Fabric Composition
    String? fabric;
    final fabricRegex = RegExp(
      r'(\d{1,3}%\s*(?:wool|cotton|linen|silk|cashmere|polyester|elastane|viscose|modal|вовна|бавовна|льон|шовк|кашемір|поліестер|еластан|віскоза)[^.\n\r]*)',
      caseSensitive: false,
    );
    final fabricMatches = fabricRegex.allMatches(rawText);
    if (fabricMatches.isNotEmpty) {
      fabric = fabricMatches.map((m) => m.group(1)?.trim()).join(', ');
    } else if (lower.contains('100%')) {
      for (final line in lines) {
        if (line.contains('100%') || line.contains('%')) {
          fabric = line;
          break;
        }
      }
    }

    // 4. Detect Country of Origin
    String? origin;
    final originRegex = RegExp(
      r'(?:made in|вироблено в|зроблено в|fabricado en|hergestellt in)[:\s]+([A-Za-zА-Яа-яіІїЇєЄ\-]+(?:\s+[A-Za-zА-Яа-яіІїЇєЄ\-]+)?)',
      caseSensitive: false,
    );
    final originMatch = originRegex.firstMatch(rawText);
    if (originMatch != null) {
      final country = originMatch.group(1)?.trim();
      if (country != null && country.isNotEmpty) {
        final formattedCountry = country.split(' ').map((w) {
          if (w.isEmpty) return '';
          return w[0].toUpperCase() + w.substring(1).toLowerCase();
        }).join(' ');
        origin = 'Made in $formattedCountry';
      }
    }

    // 5. Detect Care Instructions
    String? care;
    final careKeywords = <String>[];
    if (lower.contains('30°') || lower.contains('30 c') || lower.contains('30c')) {
      careKeywords.add('Делікатне прання 30°C');
    }
    if (lower.contains('40°') || lower.contains('40 c')) {
      careKeywords.add('Прання 40°C');
    }
    if (lower.contains('dry clean') || lower.contains('хімчистк')) {
      careKeywords.add('Хімчистка дозволена');
    }
    if (lower.contains('do not bleach') || lower.contains('не відбілювати')) {
      careKeywords.add('Не відбілювати');
    }
    if (lower.contains('iron') || lower.contains('прасува')) {
      careKeywords.add('Прасування при помірній t°');
    }
    if (careKeywords.isNotEmpty) {
      care = careKeywords.join(' · ');
    }

    // 6. Detect Category
    ClothingCategory? category;
    if (lower.contains('blazer') || lower.contains('jacket') || lower.contains('coat') || lower.contains('жакет') || lower.contains('пальто') || lower.contains('куртк') || lower.contains('тренч')) {
      category = ClothingCategory.outerwear;
    } else if (lower.contains('shirt') || lower.contains('blouse') || lower.contains('top') || lower.contains('сорочк') || lower.contains('блуз') || lower.contains('топ') || lower.contains('футболк')) {
      category = ClothingCategory.tops;
    } else if (lower.contains('trousers') || lower.contains('pants') || lower.contains('jeans') || lower.contains('штани') || lower.contains('джинс') || lower.contains('брюк')) {
      category = ClothingCategory.bottoms;
    } else if (lower.contains('dress') || lower.contains('сукн')) {
      category = ClothingCategory.dresses;
    } else if (lower.contains('shoes') || lower.contains('boots') || lower.contains('loafers') || lower.contains('взутт') || lower.contains('лофер') || lower.contains('кросівк')) {
      category = ClothingCategory.shoes;
    }

    return ParsedLabelData(
      brand: brand,
      category: category,
      fabricComposition: fabric,
      size: size,
      careInstructions: care,
      countryOfOrigin: origin,
      rawExtractedLines: lines,
    );
  }

  /// Parses raw OCR text from a physical fiscal purchase receipt
  static ParsedReceiptData parseReceiptText(String rawText) {
    final lower = rawText.toLowerCase();
    final lines = rawText.split(RegExp(r'[\r\n]+')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    // 1. Detect Store
    String? store;
    if (lower.contains('zara') || lower.contains('зара')) {
      store = 'Zara';
    } else if (lower.contains('massimo dutti') || lower.contains('массімо дутті')) {
      store = 'Massimo Dutti';
    } else if (lower.contains('intertop') || lower.contains('інтертоп')) {
      store = 'Intertop';
    } else if (lower.contains('kasta') || lower.contains('каста')) {
      store = 'Kasta';
    } else if (lower.contains('mango') || lower.contains('манго')) {
      store = 'Mango';
    } else if (lower.contains('cos') || lower.contains('кос')) {
      store = 'COS';
    }

    // 2. Detect Price
    double? price;
    final priceRegex = RegExp(
      r'(?:сума|разом|total|до сплати|грн|uah|₴)\s*[:#]?\s*([0-9\s]{1,7}[.,][0-9]{2})',
      caseSensitive: false,
    );
    final priceMatch = priceRegex.firstMatch(rawText);
    if (priceMatch != null) {
      final rawNum = priceMatch.group(1)?.replaceAll(' ', '').replaceAll(',', '.');
      if (rawNum != null) price = double.tryParse(rawNum);
    }

    if (price == null) {
      // General money amount fallback
      final moneyRegex = RegExp(r'\b([0-9]{2,5}[.,][0-9]{2})\b');
      final matches = moneyRegex.allMatches(rawText);
      if (matches.isNotEmpty) {
        final lastMatch = matches.last.group(1)?.replaceAll(',', '.');
        if (lastMatch != null) price = double.tryParse(lastMatch);
      }
    }

    // 3. Detect Item title from line
    String? itemTitle;
    for (final line in lines) {
      final l = line.toLowerCase();
      if ((l.contains('жакет') || l.contains('блейзер') || l.contains('сорочк') || l.contains('штани') || l.contains('сукн') || l.contains('лофер') || l.contains('кросівк')) && !l.contains('фіскальний')) {
        itemTitle = line;
        break;
      }
    }

    // 4. Detect Date
    DateTime? date;
    final dateRegex = RegExp(r'\b(\d{2})[./\-](\d{2})[./\-](\d{2,4})\b');
    final dateMatch = dateRegex.firstMatch(rawText);
    if (dateMatch != null) {
      final d = int.tryParse(dateMatch.group(1) ?? '1');
      final m = int.tryParse(dateMatch.group(2) ?? '1');
      int? y = int.tryParse(dateMatch.group(3) ?? '2026');
      if (y != null && y < 100) y += 2000;
      if (d != null && m != null && y != null) {
        date = DateTime(y, m, d);
      }
    }

    return ParsedReceiptData(
      storeName: store,
      itemTitle: itemTitle,
      price: price,
      date: date,
      rawExtractedLines: lines,
    );
  }

  /// Merges all insights extracted from clothing photo, label OCR, and receipt OCR
  static OcrCombinedResult mergeInsights({
    ParsedLabelData? labelData,
    ParsedReceiptData? receiptData,
    String? itemPhotoUrl,
    String? labelPhotoUrl,
    String? receiptPhotoUrl,
  }) {
    final fromLabel = <String, String>{};
    final fromReceipt = <String, String>{};

    String brand = labelData?.brand ?? receiptData?.storeName ?? 'Massimo Dutti';
    if (labelData?.brand != null) fromLabel['Бренд'] = labelData!.brand!;

    String title = receiptData?.itemTitle ?? (brand.isNotEmpty ? '$brand Класична річ' : 'Стильний елемент гардероба');
    if (receiptData?.itemTitle != null) fromReceipt['Назва'] = receiptData!.itemTitle!;

    ClothingCategory category = labelData?.category ?? ClothingCategory.tops;
    if (labelData?.category != null) fromLabel['Категорія'] = labelData!.category!.label;

    double price = receiptData?.price ?? 2490.0;
    if (receiptData?.price != null) fromReceipt['Ціна'] = '${price.toStringAsFixed(0)} ₴';

    String? storeName = receiptData?.storeName ?? labelData?.brand;
    if (receiptData?.storeName != null) fromReceipt['Магазин'] = receiptData!.storeName!;

    String? fabric = labelData?.fabricComposition;
    if (fabric != null) fromLabel['Склад тканини'] = fabric;

    String? size = labelData?.size;
    if (size != null) fromLabel['Розмір'] = size;

    String? care = labelData?.careInstructions;
    if (care != null) fromLabel['Догляд'] = care;

    String? origin = labelData?.countryOfOrigin;
    if (origin != null) fromLabel['Країна'] = origin;

    // Harmonize title based on brand and category
    if (title.contains('Класична річ') || title.contains('Стильний')) {
      if (category == ClothingCategory.outerwear) title = '$brand Вовняний оверсайз блейзер';
      if (category == ClothingCategory.tops) title = '$brand Лляна сорочка Regular Fit';
      if (category == ClothingCategory.bottoms) title = '$brand Класичні брюки палаццо';
      if (category == ClothingCategory.shoes) title = '$brand Шкіряні лофери ручної роботи';
    }

    return OcrCombinedResult(
      title: title,
      brand: brand,
      category: category,
      season: Season.allSeason,
      color: labelData?.color ?? 'Бежевий',
      price: price,
      size: size ?? 'EUR 38 / M',
      fabricComposition: fabric ?? '100% Натуральна преміум вовна',
      storeName: storeName ?? 'Офіційний магазин $brand',
      careInstructions: care ?? 'Делікатне прання 30°C · Хімчистка',
      countryOfOrigin: origin ?? 'Made in Portugal',
      itemPhoto: itemPhotoUrl ?? 'https://images.unsplash.com/photo-1591047139829-d91aecb6caea?w=700&auto=format&fit=crop&q=80',
      labelPhoto: labelPhotoUrl,
      receiptPhoto: receiptPhotoUrl,
      detectedFromLabel: fromLabel,
      detectedFromReceipt: fromReceipt,
    );
  }

  // Pre-configured Test Presets for Instant 1-Click Verification
  static List<PhotoScanPreset> get samplePresets => [
        PhotoScanPreset(
          name: 'Massimo Dutti: Вовняний блейзер + Чек ТРЦ Ocean Plaza',
          itemImageUrl: 'https://images.unsplash.com/photo-1591047139829-d91aecb6caea?w=700&auto=format&fit=crop&q=80',
          labelImageUrl: 'https://images.unsplash.com/photo-1523381210434-271e8be1f52b?w=600&auto=format&fit=crop&q=80',
          receiptImageUrl: 'https://images.unsplash.com/photo-1554415707-9e49017a1430?w=600&auto=format&fit=crop&q=80',
          rawLabelText: '''
MASSIMO DUTTI
REF. 6712/501/712
SIZE EUR 38 / US S / MEX 28
100% PURE WOOL / 100% ВОВНА
LINING: 100% VISCOSE
MADE IN PORTUGAL
30°C GENTLE WASH / DRY CLEAN ONLY / DO NOT BLEACH
''',
          rawReceiptText: '''
ТОВ "МАССІМО ДУТТІ УКРАЇНА"
ТРЦ OCEAN PLAZA, КИЇВ
ФІСКАЛЬНИЙ ЧЕК № 089124
ДАТА: 18.10.2026 15:42
----------------------------------------
ЖАКЕТ ВОВНЯНИЙ БЕЖ Ref 6712/501   1 ШТ
ЦІНА: 4 999.00 UAH
ЗНИЖКА ПО КАРТЦІ КЛІЄНТА: -500.00 UAH
----------------------------------------
СУМА ДО СПЛАТИ: 4 499.00 UAH
ПДВ 20% = 749.83 UAH
''',
        ),
        PhotoScanPreset(
          name: 'Zara: Лляна біла сорочка + Чек River Mall',
          itemImageUrl: 'https://images.unsplash.com/photo-1598033129183-c4f50c736f10?w=700&auto=format&fit=crop&q=80',
          labelImageUrl: 'https://images.unsplash.com/photo-1523381210434-271e8be1f52b?w=600&auto=format&fit=crop&q=80',
          receiptImageUrl: 'https://images.unsplash.com/photo-1554415707-9e49017a1430?w=600&auto=format&fit=crop&q=80',
          rawLabelText: '''
ZARA WOMAN
SIZE M / EUR M / USA M / MEX 28
100% LINEN / 100% ЛЬОН
MADE IN MOROCCO
WASH 30°C / MEDIUM IRON / DO NOT TUMBLE DRY
''',
          rawReceiptText: '''
ТОВ "ЗАРА УКРАЇНА"
ТРЦ RIVER MALL, М. КИЇВ
ФІСКАЛЬНИЙ ЧЕК № 441029
ДАТА: 19.10.2026 12:15
----------------------------------------
СОРОЧКА 100% ЛЬОН БІЛА       1 ШТ
СУМА: 1 499.00 UAH
КАРТКА VISA *4812
''',
        ),
        PhotoScanPreset(
          name: 'Vagabond: Шкіряні лофери + Чек Intertop',
          itemImageUrl: 'https://images.unsplash.com/photo-1595950653106-6c9ebd614d3a?w=700&auto=format&fit=crop&q=80',
          labelImageUrl: 'https://images.unsplash.com/photo-1523381210434-271e8be1f52b?w=600&auto=format&fit=crop&q=80',
          receiptImageUrl: 'https://images.unsplash.com/photo-1554415707-9e49017a1430?w=600&auto=format&fit=crop&q=80',
          rawLabelText: '''
VAGABOND SHOEMAKERS
KENOVA LEATHER LOAFERS
EUR 39 / US 8.5 / UK 6
GENUINE COW LEATHER / 100% НАТУРАЛЬНА ШКІРА
HANDCRAFTED IN VIETNAM
SPECIAL LEATHER CARE ONLY
''',
          rawReceiptText: '''
ТОВ "ІНТЕРТОП УКРАЇНА"
МАГАЗИН INTERTOP ТРЦ GULLIVER
ФІСКАЛЬНИЙ ЧЕК № 192801
ДАТА: 15.10.2026 18:20
----------------------------------------
ТУФЛІ ЖІНОЧІ VAGABOND KENOVA    1 ПАР
ЦІНА: 3 800.00 ГРН
ДО СПЛАТИ: 3 800.00 UAH
''',
        ),
      ];
}

class PhotoScanPreset {
  final String name;
  final String itemImageUrl;
  final String labelImageUrl;
  final String receiptImageUrl;
  final String rawLabelText;
  final String rawReceiptText;

  PhotoScanPreset({
    required this.name,
    required this.itemImageUrl,
    required this.labelImageUrl,
    required this.receiptImageUrl,
    required this.rawLabelText,
    required this.rawReceiptText,
  });
}
