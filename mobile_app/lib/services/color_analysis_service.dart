import 'package:flutter/material.dart';
import '../models/clothing_item.dart';

enum ColorSeason {
  warmAutumn(
    'Тепла Осінь 🍂',
    'Глибокі, теплі, землисті тони з золотавим підтоном.',
    [
      Color(0xFFC1793A), // Теракота
      Color(0xFFD7C4B7), // Теплий беж
      Color(0xFF556B2F), // Олива
      Color(0xFF78350F), // Шоколад
      Color(0xFFD97706), // Медово-бурштиновий
      Color(0xFFFAF5EE), // Молочний
    ],
    ['бежевий', 'коричневий', 'молочний', 'карамельний', 'оливковий', 'теракотовий', 'золотистий', 'кремовий'],
  ),
  coolWinter(
    'Контрастна Зима ❄️',
    'Чисті, насичені, контрастні та прохолодні кольори.',
    [
      Color(0xFF18181B), // Глибокий чорний
      Color(0xFFFFFFFF), // Сніжно-білий
      Color(0xFF047857), // Смарагдовий
      Color(0xFF1E3A8A), // Королівський синій
      Color(0xFF991B1B), // Рубіновий
      Color(0xFF4B5563), // Графіт
    ],
    ['чорний', 'білий', 'смарагдовий', 'синій', 'червоний', 'графітовий', 'бордо'],
  ),
  lightSpring(
    'Світла Весна 🌸',
    'Світлі, чисті, свіжі та сяючі теплі відтінки.',
    [
      Color(0xFFFED7AA), // Персиковий
      Color(0xFFFEF3C7), // Світло-ванільний
      Color(0xFF7DD3FC), // Небесно-блакитний
      Color(0xFFBBF7D0), // Світла м'ята
      Color(0xFFFB7185), // Теплий корал
      Color(0xFFFFFFFF), // Білий
    ],
    ['персиковий', 'білий', 'кремовий', 'блакитний', 'м\'ятний', 'світлий'],
  ),
  softSummer(
    'М\'яке Літо 🌊',
    'Приглушені, складні, попелясті та прохолодні пастелі.',
    [
      Color(0xFF3B82F6), // Димчастий денім
      Color(0xFF9CA3AF), // Попелясто-сірий
      Color(0xFFC084FC), // М'яка лаванда
      Color(0xFFFBCFE8), // Пудрова троянда
      Color(0xFF64748B), // Морська хвиля
      Color(0xFFF1F5F9), // Перловий
    ],
    ['синій денім', 'сірий', 'денім', 'блакитний', 'лавандовий', 'пудровий'],
  );

  final String title;
  final String description;
  final List<Color> paletteSwatches;
  final List<String> matchingKeywords;
  const ColorSeason(this.title, this.description, this.paletteSwatches, this.matchingKeywords);
}

class SeasonAlignmentReport {
  final ColorSeason season;
  final double alignmentPercentage;
  final int matchingCount;
  final int totalCount;
  final List<ClothingItem> matchingItems;
  final List<ClothingItem> accentItems;
  final String verdict;
  final String personalTip;

  SeasonAlignmentReport({
    required this.season,
    required this.alignmentPercentage,
    required this.matchingCount,
    required this.totalCount,
    required this.matchingItems,
    required this.accentItems,
    required this.verdict,
    required this.personalTip,
  });
}

class ColorAnalysisService {
  /// Evaluates harmony between user's chosen seasonal color palette and their wardrobe items
  static SeasonAlignmentReport evaluateAlignment({
    required List<ClothingItem> wardrobe,
    required ColorSeason season,
  }) {
    if (wardrobe.isEmpty) {
      return SeasonAlignmentReport(
        season: season,
        alignmentPercentage: 0.0,
        matchingCount: 0,
        totalCount: 0,
        matchingItems: [],
        accentItems: [],
        verdict: 'Гардероб порожній',
        personalTip: 'Додайте речі для розрахунку сумісності з вашим кольоротипом.',
      );
    }

    final matching = <ClothingItem>[];
    final accents = <ClothingItem>[];

    for (final it in wardrobe) {
      final colorLower = it.color.toLowerCase();
      final isMatch = season.matchingKeywords.any((kw) => colorLower.contains(kw));
      if (isMatch) {
        matching.add(it);
      } else {
        accents.add(it);
      }
    }

    final percentage = (matching.length / wardrobe.length) * 100;

    String verdict = 'Чудова сумісність!';
    String tip = 'Більшість речей у вашій шафі підкреслюють ваш природний контраст.';

    if (percentage >= 80) {
      verdict = 'Еталонна палітра (Quiet Luxury) 💎';
      tip = 'Ваш гардероб на ${percentage.toStringAsFixed(0)}% відповідає вашому кольоротипу. Обличчя виглядатиме свіжим навіть без макіяжу.';
    } else if (percentage >= 60) {
      verdict = 'Добра гармонія ✨';
      tip = 'У гардеробі є речі як основної палітри, так і контрастні елементи. Одягайте кольори своєї палітри ближче до обличчя (сорочки, шарфи).';
    } else {
      verdict = 'Багато контрастних акцентів 🎨';
      tip = 'Спробуйте додати базовий шарф, блейзер чи топ кольору "${season.paletteSwatches.first}" для пом\'якшення контрасту.';
    }

    return SeasonAlignmentReport(
      season: season,
      alignmentPercentage: percentage,
      matchingCount: matching.length,
      totalCount: wardrobe.length,
      matchingItems: matching,
      accentItems: accents,
      verdict: verdict,
      personalTip: tip,
    );
  }
}
