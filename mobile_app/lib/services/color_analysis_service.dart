import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/clothing_item.dart';

class NamedColorSwatch {
  final String name;
  final Color color;

  const NamedColorSwatch({required this.name, required this.color});

  Map<String, dynamic> toJson() => {
        'name': name,
        'color': color.toARGB32(),
      };

  factory NamedColorSwatch.fromJson(Map<String, dynamic> json) => NamedColorSwatch(
        name: json['name'] as String,
        color: Color(json['color'] as int),
      );
}

enum ColorSeason {
  warmAutumn(
    'Тепла Осінь 🍂',
    'Глибокі, теплі, землисті тони з золотавим підтоном.',
    [
      NamedColorSwatch(name: 'Теракота', color: Color(0xFFC1793A)),
      NamedColorSwatch(name: 'Теплий беж', color: Color(0xFFD7C4B7)),
      NamedColorSwatch(name: 'Олива', color: Color(0xFF556B2F)),
      NamedColorSwatch(name: 'Шоколад', color: Color(0xFF78350F)),
      NamedColorSwatch(name: 'Медово-бурштиновий', color: Color(0xFFD97706)),
      NamedColorSwatch(name: 'Молочний', color: Color(0xFFFAF5EE)),
    ],
    ['бежевий', 'коричневий', 'молочний', 'карамельний', 'оливковий', 'теракотовий', 'золотистий', 'кремовий', 'беж'],
  ),
  coolWinter(
    'Контрастна Зима ❄️',
    'Чисті, насичені, контрастні та прохолодні кольори.',
    [
      NamedColorSwatch(name: 'Глибокий чорний', color: Color(0xFF18181B)),
      NamedColorSwatch(name: 'Сніжно-білий', color: Color(0xFFFFFFFF)),
      NamedColorSwatch(name: 'Смарагдовий', color: Color(0xFF047857)),
      NamedColorSwatch(name: 'Королівський синій', color: Color(0xFF1E3A8A)),
      NamedColorSwatch(name: 'Рубіновий', color: Color(0xFF991B1B)),
      NamedColorSwatch(name: 'Графіт', color: Color(0xFF4B5563)),
    ],
    ['чорний', 'білий', 'смарагдовий', 'синій', 'червоний', 'графітовий', 'бордо'],
  ),
  lightSpring(
    'Світла Весна 🌸',
    'Світлі, чисті, свіжі та сяючі теплі відтінки.',
    [
      NamedColorSwatch(name: 'Ніжний персик', color: Color(0xFFFED7AA)),
      NamedColorSwatch(name: 'Світла ваніль', color: Color(0xFFFEF3C7)),
      NamedColorSwatch(name: 'Небесно-блакитний', color: Color(0xFF7DD3FC)),
      NamedColorSwatch(name: 'Свіжа м\'ята', color: Color(0xFFBBF7D0)),
      NamedColorSwatch(name: 'Теплий корал', color: Color(0xFFFB7185)),
      NamedColorSwatch(name: 'Чистий білий', color: Color(0xFFFFFFFF)),
    ],
    ['персиковий', 'білий', 'кремовий', 'блакитний', 'м\'ятний', 'світлий', 'ванільний'],
  ),
  softSummer(
    'М\'яке Літо 🌊',
    'Приглушені, складні, попелясті та прохолодні пастелі.',
    [
      NamedColorSwatch(name: 'Димчастий денім', color: Color(0xFF3B82F6)),
      NamedColorSwatch(name: 'Попелясто-сірий', color: Color(0xFF9CA3AF)),
      NamedColorSwatch(name: 'М\'яка лаванда', color: Color(0xFFC084FC)),
      NamedColorSwatch(name: 'Пудрова троянда', color: Color(0xFFFBCFE8)),
      NamedColorSwatch(name: 'Морська хвиля', color: Color(0xFF64748B)),
      NamedColorSwatch(name: 'Перловий', color: Color(0xFFF1F5F9)),
    ],
    ['синій денім', 'сірий', 'денім', 'блакитний', 'лавандовий', 'пудровий', 'перловий'],
  );

  final String title;
  final String description;
  final List<NamedColorSwatch> swatches;
  final List<String> matchingKeywords;
  const ColorSeason(this.title, this.description, this.swatches, this.matchingKeywords);

  List<Color> get paletteSwatches => swatches.map((s) => s.color).toList();
}

class ColorPaletteGroup {
  final String id;
  final String title;
  final String description;
  final List<NamedColorSwatch> swatches;
  final List<String> matchingKeywords;
  final bool isCustom;

  ColorPaletteGroup({
    required this.id,
    required this.title,
    required this.description,
    required this.swatches,
    required this.matchingKeywords,
    this.isCustom = false,
  });

  List<Color> get paletteSwatches => swatches.map((s) => s.color).toList();

  ColorPaletteGroup copyWith({
    String? id,
    String? title,
    String? description,
    List<NamedColorSwatch>? swatches,
    List<String>? matchingKeywords,
    bool? isCustom,
  }) {
    return ColorPaletteGroup(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      swatches: swatches ?? List.from(this.swatches),
      matchingKeywords: matchingKeywords ?? List.from(this.matchingKeywords),
      isCustom: isCustom ?? this.isCustom,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'swatches': swatches.map((s) => s.toJson()).toList(),
        'matchingKeywords': matchingKeywords,
        'isCustom': isCustom,
      };

  factory ColorPaletteGroup.fromJson(Map<String, dynamic> json) {
    return ColorPaletteGroup(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      swatches: (json['swatches'] as List)
          .map((s) => NamedColorSwatch.fromJson(s as Map<String, dynamic>))
          .toList(),
      matchingKeywords: List<String>.from(json['matchingKeywords'] ?? []),
      isCustom: json['isCustom'] as bool? ?? true,
    );
  }

  static ColorPaletteGroup fromSeason(ColorSeason season) {
    return ColorPaletteGroup(
      id: season.name,
      title: season.title,
      description: season.description,
      swatches: season.swatches,
      matchingKeywords: season.matchingKeywords,
      isCustom: false,
    );
  }
}

class PaletteOutfitVariant {
  final String id;
  final String title;
  final String styleDescription;
  final List<ClothingItem> items;
  final double matchScore;
  final List<NamedColorSwatch> matchedSwatches;

  PaletteOutfitVariant({
    required this.id,
    required this.title,
    required this.styleDescription,
    required this.items,
    required this.matchScore,
    required this.matchedSwatches,
  });
}

class SeasonAlignmentReport {
  final ColorPaletteGroup palette;
  final double alignmentPercentage;
  final int matchingCount;
  final int totalCount;
  final List<ClothingItem> matchingItems;
  final List<ClothingItem> accentItems;
  final List<PaletteOutfitVariant> curatedOutfits;
  final String verdict;
  final String personalTip;

  SeasonAlignmentReport({
    required this.palette,
    required this.alignmentPercentage,
    required this.matchingCount,
    required this.totalCount,
    required this.matchingItems,
    required this.accentItems,
    required this.curatedOutfits,
    required this.verdict,
    required this.personalTip,
  });

  ColorSeason get season => ColorSeason.values.firstWhere(
        (s) => s.name == palette.id,
        orElse: () => ColorSeason.warmAutumn,
      );
}

class ColorAnalysisService {
  static const String _customPalettesKey = 'vestora_custom_palettes_v2';
  static List<ColorPaletteGroup>? _cachedCustomPalettes;

  /// Curated library of luxury shades for custom palette creation
  static const List<NamedColorSwatch> curatedLuxurySwatches = [
    NamedColorSwatch(name: 'Теплий беж', color: Color(0xFFD7C4B7)),
    NamedColorSwatch(name: 'Шоколадний мокко', color: Color(0xFF5A3825)),
    NamedColorSwatch(name: 'Карамель', color: Color(0xFFC68B59)),
    NamedColorSwatch(name: 'Вершковий екру', color: Color(0xFFFAF5EE)),
    NamedColorSwatch(name: 'Глибокий індиго', color: Color(0xFF1E3A8A)),
    NamedColorSwatch(name: 'Французький блакитний', color: Color(0xFF60A5FA)),
    NamedColorSwatch(name: 'Димчастий денім', color: Color(0xFF475569)),
    NamedColorSwatch(name: 'Олива / Шалфей', color: Color(0xFF556B2F)),
    NamedColorSwatch(name: 'Теракота', color: Color(0xFFC1793A)),
    NamedColorSwatch(name: 'Бордовий бургунді', color: Color(0xFF881337)),
    NamedColorSwatch(name: 'Пудрова троянда', color: Color(0xFFF472B6)),
    NamedColorSwatch(name: 'Персиковий сорбет', color: Color(0xFFFDBA74)),
    NamedColorSwatch(name: 'Глибокий чорний', color: Color(0xFF18181B)),
    NamedColorSwatch(name: 'Антрацит', color: Color(0xFF374151)),
    NamedColorSwatch(name: 'Попелясто-сірий', color: Color(0xFF9CA3AF)),
    NamedColorSwatch(name: 'Сніжно-білий', color: Color(0xFFFFFFFF)),
    NamedColorSwatch(name: 'Смарагдовий', color: Color(0xFF047857)),
    NamedColorSwatch(name: 'Медово-бурштиновий', color: Color(0xFFD97706)),
  ];

  /// Loads persisted user custom palettes
  static Future<List<ColorPaletteGroup>> loadCustomPalettes() async {
    if (_cachedCustomPalettes != null) return _cachedCustomPalettes!;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_customPalettesKey);
      if (raw != null && raw.isNotEmpty) {
        final list = (jsonDecode(raw) as List)
            .map((e) => ColorPaletteGroup.fromJson(e as Map<String, dynamic>))
            .toList();
        _cachedCustomPalettes = list;
        return list;
      }
    } catch (_) {}
    _cachedCustomPalettes = [];
    return [];
  }

  /// Saves or updates a custom palette group
  static Future<void> saveCustomPalette(ColorPaletteGroup palette) async {
    final list = await loadCustomPalettes();
    final index = list.indexWhere((p) => p.id == palette.id);
    if (index >= 0) {
      list[index] = palette;
    } else {
      list.add(palette);
    }
    _cachedCustomPalettes = list;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(list.map((e) => e.toJson()).toList());
      await prefs.setString(_customPalettesKey, raw);
    } catch (_) {}
  }

  /// Deletes a custom palette group
  static Future<void> deleteCustomPalette(String id) async {
    final list = await loadCustomPalettes();
    list.removeWhere((p) => p.id == id);
    _cachedCustomPalettes = list;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(list.map((e) => e.toJson()).toList());
      await prefs.setString(_customPalettesKey, raw);
    } catch (_) {}
  }

  /// Evaluates harmony between user's chosen palette and wardrobe, and prepares outfit variants
  static SeasonAlignmentReport evaluateAlignment({
    required List<ClothingItem> wardrobe,
    ColorSeason? season,
    ColorPaletteGroup? palette,
  }) {
    final activePalette = palette ?? ColorPaletteGroup.fromSeason(season ?? ColorSeason.warmAutumn);

    if (wardrobe.isEmpty) {
      return SeasonAlignmentReport(
        palette: activePalette,
        alignmentPercentage: 0.0,
        matchingCount: 0,
        totalCount: 0,
        matchingItems: [],
        accentItems: [],
        curatedOutfits: [],
        verdict: 'Гардероб порожній',
        personalTip: 'Додайте речі для розрахунку сумісності з вашою колірною палітрою.',
      );
    }

    final matching = <ClothingItem>[];
    final accents = <ClothingItem>[];

    // Combine matching keywords and swatch names
    final allKeywords = <String>{
      ...activePalette.matchingKeywords.map((k) => k.toLowerCase()),
      ...activePalette.swatches.map((s) => s.name.toLowerCase()),
    };

    for (final it in wardrobe) {
      final colorLower = it.color.toLowerCase();
      final titleLower = it.title.toLowerCase();

      final isMatch = allKeywords.any((kw) =>
          colorLower.contains(kw) ||
          titleLower.contains(kw) ||
          kw.contains(colorLower) && colorLower.length > 3);

      if (isMatch) {
        matching.add(it);
      } else {
        accents.add(it);
      }
    }

    final percentage = (matching.length / wardrobe.length) * 100;

    String verdict = 'Чудова сумісність!';
    final firstSwatchName = activePalette.swatches.isNotEmpty
        ? activePalette.swatches.first.name
        : 'базового відтінку';

    String tip = 'Більшість речей у вашій шафі гармонійно поєднуються з цією палітрою.';

    if (percentage >= 80) {
      verdict = 'Еталонна палітра (Quiet Luxury) 💎';
      tip = 'Ваш гардероб на ${percentage.toStringAsFixed(0)}% відповідає палітрі "${activePalette.title}". Образи виглядатимуть дорого та цілісно.';
    } else if (percentage >= 50) {
      verdict = 'Добра гармонія ✨';
      tip = 'У гардеробі є чудова основа. Одягайте речі відтінку "$firstSwatchName" ближче до обличчя для максимального сяйва.';
    } else {
      verdict = 'Багато контрастних акцентів 🎨';
      tip = 'Спробуйте додати базовий шарф, блейзер чи топ відтінку "$firstSwatchName" для пом\'якшення контрасту.';
    }

    // Curate Ready-to-Wear Outfits from the wardrobe matching this palette!
    final curatedOutfits = _curateOutfitsFromPalette(wardrobe, activePalette, matching);

    return SeasonAlignmentReport(
      palette: activePalette,
      alignmentPercentage: percentage,
      matchingCount: matching.length,
      totalCount: wardrobe.length,
      matchingItems: matching,
      accentItems: accents,
      curatedOutfits: curatedOutfits,
      verdict: verdict,
      personalTip: tip,
    );
  }

  /// Automatically prepares cohesive outfit variants from the wardrobe using the color palette
  static List<PaletteOutfitVariant> _curateOutfitsFromPalette(
    List<ClothingItem> fullWardrobe,
    ColorPaletteGroup palette,
    List<ClothingItem> matchingItems,
  ) {
    if (fullWardrobe.isEmpty) return [];

    final outfits = <PaletteOutfitVariant>[];

    // Partition matching items by category
    final tops = matchingItems.where((i) => i.category == ClothingCategory.tops).toList();
    final bottoms = matchingItems.where((i) => i.category == ClothingCategory.bottoms).toList();
    final outerwear = matchingItems.where((i) => i.category == ClothingCategory.outerwear).toList();
    final shoes = matchingItems.where((i) => i.category == ClothingCategory.shoes).toList();
    final dresses = matchingItems.where((i) => i.category == ClothingCategory.dresses).toList();
    final bags = matchingItems.where((i) => i.category == ClothingCategory.bags).toList();

    // Fallbacks from full wardrobe if matching category is empty
    final anyTops = tops.isNotEmpty ? tops : fullWardrobe.where((i) => i.category == ClothingCategory.tops).toList();
    final anyBottoms = bottoms.isNotEmpty ? bottoms : fullWardrobe.where((i) => i.category == ClothingCategory.bottoms).toList();
    final anyShoes = shoes.isNotEmpty ? shoes : fullWardrobe.where((i) => i.category == ClothingCategory.shoes).toList();
    final anyOuterwear = outerwear.isNotEmpty ? outerwear : fullWardrobe.where((i) => i.category == ClothingCategory.outerwear).toList();

    // Variant 1: Signature Smart Casual Look
    if (anyTops.isNotEmpty || anyBottoms.isNotEmpty || anyOuterwear.isNotEmpty) {
      final items = <ClothingItem>[];
      if (anyOuterwear.isNotEmpty) items.add(anyOuterwear.first);
      if (anyTops.isNotEmpty) items.add(anyTops.first);
      if (anyBottoms.isNotEmpty) items.add(anyBottoms.first);
      if (anyShoes.isNotEmpty) items.add(anyShoes.first);
      if (bags.isNotEmpty) items.add(bags.first);

      if (items.isNotEmpty) {
        final colors = items.map((e) => e.color).toSet().join(' + ');
        outfits.add(
          PaletteOutfitVariant(
            id: 'variant_casual_${palette.id}',
            title: 'Варіант 1: Повсякденна елегантність',
            styleDescription: 'Гармонійний мікс кольорів палітри: $colors.',
            items: items,
            matchScore: 9.8,
            matchedSwatches: palette.swatches.take(3).toList(),
          ),
        );
      }
    }

    // Variant 2: Minimalist Dress or Relaxed Alternative
    if (dresses.isNotEmpty) {
      final items = <ClothingItem>[];
      items.add(dresses.first);
      if (anyOuterwear.isNotEmpty) items.add(anyOuterwear.first);
      if (anyShoes.isNotEmpty) items.add(anyShoes.first);
      if (bags.isNotEmpty) items.add(bags.first);

      outfits.add(
        PaletteOutfitVariant(
          id: 'variant_dress_${palette.id}',
          title: 'Варіант 2: Акцентний силует',
          styleDescription: 'Сукня "${dresses.first.title}" у поєднанні з базовими нейтралями.',
          items: items,
          matchScore: 9.6,
          matchedSwatches: palette.swatches.take(2).toList(),
        ),
      );
    } else if (anyTops.length > 1 || anyBottoms.length > 1 || anyShoes.isNotEmpty) {
      final items = <ClothingItem>[];
      // Alternate items
      if (anyTops.length > 1) {
        items.add(anyTops[1]);
      } else if (anyTops.isNotEmpty) {
        items.add(anyTops.first);
      }
      if (anyBottoms.length > 1) {
        items.add(anyBottoms[1]);
      } else if (anyBottoms.isNotEmpty) {
        items.add(anyBottoms.first);
      }
      if (anyShoes.isNotEmpty) items.add(anyShoes.first);

      if (items.length >= 2) {
        outfits.add(
          PaletteOutfitVariant(
            id: 'variant_alt_${palette.id}',
            title: 'Варіант 2: Лаконічний мінімалізм',
            styleDescription: 'Чистий баланс відтінків без перевантаження шарами.',
            items: items,
            matchScore: 9.4,
            matchedSwatches: palette.swatches.reversed.take(2).toList(),
          ),
        );
      }
    }

    return outfits;
  }
}
