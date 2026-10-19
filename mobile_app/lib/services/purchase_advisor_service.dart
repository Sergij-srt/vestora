import '../models/clothing_item.dart';

enum PurchaseVerdict {
  buy('ВАРТО КУПИТИ 💎', 'Чудова інвестиція! Ця річ закриває дефіцит і створить багато нових образів.', 0xFF166534, 0xFFDCFCE7),
  consider('ПОДУМАЙТЕ ДВІЧІ ⚠️', 'Річ непогана, але у вас уже є подібні альтернативи в гардеробі.', 0xFF854D0E, 0xFFFEF3C7),
  avoid('НЕ КУПУЙТЕ 🚫', 'Імпульсивна покупка! У вашій шафі вже є майже точні копії або її нема з чим носити.', 0xFF991B1B, 0xFFFEE2E2);

  final String title;
  final String description;
  final int textColor;
  final int backgroundColor;
  const PurchaseVerdict(this.title, this.description, this.textColor, this.backgroundColor);
}

class PurchaseAnalysisReport {
  final PurchaseVerdict verdict;
  final int synergyOutfitsCount;
  final List<ClothingItem> duplicateItems;
  final List<ClothingItem> matchingItems;
  final double estimatedCostPerWear;
  final String keyReason;
  final int score; // 0 to 100

  PurchaseAnalysisReport({
    required this.verdict,
    required this.synergyOutfitsCount,
    required this.duplicateItems,
    required this.matchingItems,
    required this.estimatedCostPerWear,
    required this.keyReason,
    required this.score,
  });
}

class PurchaseAdvisorService {
  /// Analyzes a candidate purchase against the user's current wardrobe
  static PurchaseAnalysisReport evaluatePurchase({
    required String title,
    required ClothingCategory category,
    required String color,
    required double price,
    required List<ClothingItem> currentWardrobe,
  }) {
    final lowerTitle = title.toLowerCase();
    final lowerColor = color.toLowerCase();

    // 1. Detect Duplicates / Similar Items
    final duplicates = currentWardrobe.where((item) {
      if (item.category != category) return false;

      // Color similarity
      final sameColor = item.color.toLowerCase() == lowerColor ||
          (lowerColor != 'не вказано' && item.color.toLowerCase().contains(lowerColor));

      // Title/Type keyword similarity
      bool keywordOverlap = false;
      final keywords = ['сорочк', 'джинс', 'блейзер', 'куртк', 'сукн', 'кросівк', 'брюк', 'худі', 'пальто', 'футболк'];
      for (final kw in keywords) {
        if (lowerTitle.contains(kw) && item.title.toLowerCase().contains(kw)) {
          keywordOverlap = true;
          break;
        }
      }

      return sameColor || keywordOverlap;
    }).toList();

    // 2. Find Complementary Items in existing wardrobe (Synergy)
    final matching = <ClothingItem>[];
    switch (category) {
      case ClothingCategory.tops:
        // Tops match with bottoms and outerwear
        matching.addAll(currentWardrobe.where((i) => i.category == ClothingCategory.bottoms || i.category == ClothingCategory.outerwear));
        break;
      case ClothingCategory.bottoms:
        // Bottoms match with tops and shoes
        matching.addAll(currentWardrobe.where((i) => i.category == ClothingCategory.tops || i.category == ClothingCategory.shoes));
        break;
      case ClothingCategory.outerwear:
        // Outerwear matches with tops and bottoms
        matching.addAll(currentWardrobe.where((i) => i.category == ClothingCategory.tops || i.category == ClothingCategory.bottoms));
        break;
      case ClothingCategory.shoes:
        // Shoes match with bottoms and dresses
        matching.addAll(currentWardrobe.where((i) => i.category == ClothingCategory.bottoms || i.category == ClothingCategory.dresses));
        break;
      case ClothingCategory.dresses:
        // Dresses match with outerwear and shoes
        matching.addAll(currentWardrobe.where((i) => i.category == ClothingCategory.outerwear || i.category == ClothingCategory.shoes));
        break;
      case ClothingCategory.bags:
      case ClothingCategory.accessories:
        // Accessories match broadly with tops and outerwear
        matching.addAll(currentWardrobe.where((i) => i.category == ClothingCategory.tops || i.category == ClothingCategory.outerwear));
        break;
    }

    // Number of possible novel combinations
    final synergyOutfitsCount = matching.isNotEmpty ? (matching.length * 1.5).round() : 0;

    // Estimated CPW assuming ~25 wears on average for a useful item
    final estimatedCpw = price > 0 ? (price / 25) : 0.0;

    // 3. Scoring & Verdict Formula
    int score = 60; // Base baseline

    // Bonus for high synergy
    if (synergyOutfitsCount >= 6) {
      score += 25;
    } else if (synergyOutfitsCount >= 3) {
      score += 15;
    } else if (synergyOutfitsCount == 0) {
      score -= 25;
    }

    // Penalty for duplicates
    if (duplicates.length >= 2) {
      score -= 40;
    } else if (duplicates.length == 1) {
      score -= 20;
    }

    // Category scarcity bonus (if user has 0 or 1 item in this category)
    final categoryCount = currentWardrobe.where((i) => i.category == category).length;
    if (categoryCount <= 1) {
      score += 20;
    }

    // Clamp score
    score = score.clamp(5, 99);

    // Determine Verdict
    PurchaseVerdict verdict;
    String reason;

    if (score >= 70 && duplicates.isEmpty) {
      verdict = PurchaseVerdict.buy;
      reason = 'Ця річ створить орієнтовно $synergyOutfitsCount нових стильних образів з вашим існуючим одягом і не повторює нічого з шафи.';
    } else if (duplicates.isNotEmpty && duplicates.length >= 2) {
      verdict = PurchaseVerdict.avoid;
      reason = 'У вашому гардеробі вже є ${duplicates.length} дуже схожих речей (${duplicates.map((e) => e.title).take(2).join(', ')}). Це типова імпульсивна покупка-дублікат.';
    } else if (score < 45) {
      verdict = PurchaseVerdict.avoid;
      reason = 'Цю річ практично нема з чим поєднувати у вашому поточному гардеробі. Вона ризикує висіти з біркою.';
    } else {
      verdict = PurchaseVerdict.consider;
      if (duplicates.isNotEmpty) {
        reason = 'У вас уже є схожа річ ("${duplicates.first.title}"). Купуйте лише якщо стара річ зносилася або ця значно якісніша.';
      } else {
        reason = 'Річ створить близько $synergyOutfitsCount комбінацій, але це помірна корисність для вашого гардероба.';
      }
    }

    return PurchaseAnalysisReport(
      verdict: verdict,
      synergyOutfitsCount: synergyOutfitsCount,
      duplicateItems: duplicates,
      matchingItems: matching.take(4).toList(),
      estimatedCostPerWear: estimatedCpw,
      keyReason: reason,
      score: score,
    );
  }
}
