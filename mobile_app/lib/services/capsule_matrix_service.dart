import '../models/clothing_item.dart';

class CapsuleCombination {
  final String id;
  final ClothingItem top;
  final ClothingItem bottom;
  final ClothingItem? shoes;
  final ClothingItem? outerwear;
  final double harmonyScore;
  final String colorRationale;
  final String styleVerdict;

  const CapsuleCombination({
    required this.id,
    required this.top,
    required this.bottom,
    this.shoes,
    this.outerwear,
    required this.harmonyScore,
    required this.colorRationale,
    required this.styleVerdict,
  });

  double get totalPrice {
    double sum = top.price + bottom.price;
    if (shoes != null) sum += shoes!.price;
    if (outerwear != null) sum += outerwear!.price;
    return sum;
  }

  double get averageCpw {
    final count = 2 + (shoes != null ? 1 : 0) + (outerwear != null ? 1 : 0);
    double sumCpw = top.costPerWear + bottom.costPerWear;
    if (shoes != null) sumCpw += shoes!.costPerWear;
    if (outerwear != null) sumCpw += outerwear!.costPerWear;
    return sumCpw / count;
  }

  List<ClothingItem> get allItems {
    final list = <ClothingItem>[top, bottom];
    if (shoes != null) list.add(shoes!);
    if (outerwear != null) list.add(outerwear!);
    return list;
  }
}

class CapsuleMatrixData {
  final List<ClothingItem> tops;
  final List<ClothingItem> bottoms;
  final List<ClothingItem> shoesList;
  final List<ClothingItem> outerwearList;
  final List<CapsuleCombination> combinations;
  final int versatilityIndex; // e.g. 96
  final double averageHarmonyScore;
  final double totalCapsuleValue;
  final int projectedSavingsPercent;

  const CapsuleMatrixData({
    required this.tops,
    required this.bottoms,
    required this.shoesList,
    required this.outerwearList,
    required this.combinations,
    required this.versatilityIndex,
    required this.averageHarmonyScore,
    required this.totalCapsuleValue,
    required this.projectedSavingsPercent,
  });

  CapsuleCombination? getCombination(int topIndex, int bottomIndex) {
    if (topIndex >= tops.length || bottomIndex >= bottoms.length) return null;
    final top = tops[topIndex];
    final bottom = bottoms[bottomIndex];
    return combinations.cast<CapsuleCombination?>().firstWhere(
          (c) => c?.top.id == top.id && c?.bottom.id == bottom.id,
          orElse: () => null,
        );
  }
}

class CapsuleMatrixService {
  /// Generates a 3x3 Micro-Capsule Matrix (3 Tops x 3 Bottoms = 9 combinations, expandable with shoes/outerwear)
  static CapsuleMatrixData generateMatrix({
    required List<ClothingItem> wardrobe,
    List<ClothingItem>? selectedTops,
    List<ClothingItem>? selectedBottoms,
    List<ClothingItem>? selectedShoes,
    List<ClothingItem>? selectedOuterwear,
  }) {
    // 1. Resolve Tops
    List<ClothingItem> tops = selectedTops ?? [];
    if (tops.isEmpty) {
      tops = wardrobe.where((i) => i.category == ClothingCategory.tops).take(3).toList();
    }

    // 2. Resolve Bottoms
    List<ClothingItem> bottoms = selectedBottoms ?? [];
    if (bottoms.isEmpty) {
      bottoms = wardrobe.where((i) => i.category == ClothingCategory.bottoms).take(3).toList();
    }

    // 3. Resolve Shoes (1-2)
    List<ClothingItem> shoes = selectedShoes ?? [];
    if (shoes.isEmpty) {
      shoes = wardrobe.where((i) => i.category == ClothingCategory.shoes).take(2).toList();
    }

    // 4. Resolve Outerwear (0-1)
    List<ClothingItem> outerwear = selectedOuterwear ?? [];
    if (outerwear.isEmpty) {
      outerwear = wardrobe.where((i) => i.category == ClothingCategory.outerwear).take(1).toList();
    }

    final combinations = <CapsuleCombination>[];
    double totalHarmony = 0.0;

    for (int t = 0; t < tops.length; t++) {
      for (int b = 0; b < bottoms.length; b++) {
        final topItem = tops[t];
        final bottomItem = bottoms[b];
        final shoeItem = shoes.isNotEmpty ? shoes[(t + b) % shoes.length] : null;
        final outItem = outerwear.isNotEmpty ? outerwear.first : null;

        final eval = _evaluatePair(topItem, bottomItem, shoeItem);
        totalHarmony += eval.harmony;

        combinations.add(
          CapsuleCombination(
            id: 'matrix_combo_${topItem.id}_${bottomItem.id}',
            top: topItem,
            bottom: bottomItem,
            shoes: shoeItem,
            outerwear: outItem,
            harmonyScore: eval.harmony,
            colorRationale: eval.colorRationale,
            styleVerdict: eval.verdict,
          ),
        );
      }
    }

    final comboCount = combinations.length;
    final avgHarmony = comboCount > 0 ? totalHarmony / comboCount : 9.0;
    final versatility = (comboCount >= 9 ? 94 + (avgHarmony > 9.4 ? 4 : 2) : (comboCount * 10)).clamp(50, 99);

    final allItems = <ClothingItem>{...tops, ...bottoms, ...shoes, ...outerwear};
    final totalValue = allItems.fold(0.0, (sum, i) => sum + i.price);

    return CapsuleMatrixData(
      tops: tops,
      bottoms: bottoms,
      shoesList: shoes,
      outerwearList: outerwear,
      combinations: combinations,
      versatilityIndex: versatility,
      averageHarmonyScore: avgHarmony,
      totalCapsuleValue: totalValue,
      projectedSavingsPercent: 65,
    );
  }

  static ({double harmony, String colorRationale, String verdict}) _evaluatePair(
    ClothingItem top,
    ClothingItem bottom,
    ClothingItem? shoes,
  ) {
    final topColor = top.color.toLowerCase();
    final botColor = bottom.color.toLowerCase();

    const neutrals = ['білий', 'бежевий', 'молочний', 'сірий', 'чорний', 'коричневий', 'синій денім'];
    final topIsNeutral = neutrals.any((n) => topColor.contains(n));
    final botIsNeutral = neutrals.any((n) => botColor.contains(n));

    double score = 9.2;
    String colorRationale;
    String verdict;

    if (topIsNeutral && botIsNeutral) {
      score += 0.6;
      colorRationale = 'Бездоганний монохром або нейтральний баланс (${top.color} + ${bottom.color}) у дусі Quiet Luxury.';
      verdict = 'Універсальний базовий смарт-образ';
    } else if (topIsNeutral || botIsNeutral) {
      score += 0.4;
      colorRationale = 'Гармонійний контраст: спокійна нейтральна база врівноважує глибину кольору (${top.color} & ${bottom.color}).';
      verdict = 'Елегантний повсякденний лук';
    } else {
      score += 0.1;
      colorRationale = 'Сміливе колор-блок поєднання для виразного акцентного виходу.';
      verdict = 'Динамічний виразний ансамбль';
    }

    if (top.fabricComposition != null && bottom.fabricComposition != null) {
      score += 0.1;
    }

    return (
      harmony: score.clamp(8.5, 9.9),
      colorRationale: colorRationale,
      verdict: verdict,
    );
  }
}
