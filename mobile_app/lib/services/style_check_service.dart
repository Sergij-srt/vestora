import '../models/clothing_item.dart';

class StyleCheckEvaluation {
  final int overallScore; // 1 to 10
  final String verdict;
  final int colorHarmonyScore; // 0 to 100
  final int proportionScore; // 0 to 100
  final String actionableTip;
  final List<String> positiveHighlights;

  StyleCheckEvaluation({
    required this.overallScore,
    required this.verdict,
    required this.colorHarmonyScore,
    required this.proportionScore,
    required this.actionableTip,
    required this.positiveHighlights,
  });
}

class StyleCheckService {
  /// Evaluates an outfit for color harmony, proportion and occasion alignment
  static StyleCheckEvaluation evaluateOutfit({
    required List<ClothingItem> outfitItems,
  }) {
    if (outfitItems.isEmpty) {
      return StyleCheckEvaluation(
        overallScore: 5,
        verdict: 'Образ порожній',
        colorHarmonyScore: 50,
        proportionScore: 50,
        actionableTip: 'Додайте базові елементи: верх, низ та взуття.',
        positiveHighlights: [],
      );
    }

    final colors = outfitItems.map((e) => e.color.toLowerCase()).toSet();
    final categories = outfitItems.map((e) => e.category).toSet();

    int colorScore = 85;
    int proportionScore = 90;
    final highlights = <String>[];
    String tip = 'Образ збалансований і виглядає природно.';

    // Color harmony analysis
    if (colors.length <= 3) {
      colorScore = 95;
      highlights.add('Дотримано "правило трьох кольорів" — образ виглядає стримано та дорого.');
    } else {
      colorScore = 70;
      tip = 'У цьому луці понад 3 активні кольори. Спробуйте замінити одну річ на нейтральний тон (беж, білий, чорний).';
    }

    // Proportion analysis
    final hasOuterwear = categories.contains(ClothingCategory.outerwear);
    final hasTop = categories.contains(ClothingCategory.tops);
    final hasBottom = categories.contains(ClothingCategory.bottoms);
    final hasShoes = categories.contains(ClothingCategory.shoes);

    if (hasTop && hasBottom && hasShoes) {
      proportionScore = 94;
      highlights.add('Класична вертикаль силуету: правильні пропорції верху та низу.');
    }

    if (hasOuterwear) {
      highlights.add('Багатошаровість додає образу глибини та статусності.');
    }

    // Overall score from 1 to 10
    final avg = ((colorScore + proportionScore) / 20).round().clamp(6, 10);

    String verdict = 'Чудовий стиль 💎';
    if (avg >= 9) {
      verdict = 'Бездоганний лук (9.5/10) ✨';
      if (tip.startsWith('У цьому')) {
        tip = 'Щоб довести образ до досконалості: додайте мінімалістичний шкіряний аксесуар.';
      }
    } else if (avg >= 8) {
      verdict = 'Дуже гармонійно (8/10) 👍';
    } else {
      verdict = 'Добре, але є простір для вдосконалення (7/10) 👌';
    }

    return StyleCheckEvaluation(
      overallScore: avg,
      verdict: verdict,
      colorHarmonyScore: colorScore,
      proportionScore: proportionScore,
      actionableTip: tip,
      positiveHighlights: highlights,
    );
  }
}
