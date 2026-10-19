import '../models/clothing_item.dart';

class StyleBadge {
  final String id;
  final String title;
  final String description;
  final String icon;
  final bool isUnlocked;

  const StyleBadge({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.isUnlocked,
  });
}

class WardrobeHealthReport {
  final int healthScore; // 0 to 100
  final double utilizationRate; // % of wardrobe worn
  final int activeItemsCount;
  final int dormantItemsCount;
  final String healthStatus;
  final List<String> suggestions;
  final List<StyleBadge> badges;

  WardrobeHealthReport({
    required this.healthScore,
    required this.utilizationRate,
    required this.activeItemsCount,
    required this.dormantItemsCount,
    required this.healthStatus,
    required this.suggestions,
    required this.badges,
  });
}

class GamificationService {
  /// Calculates comprehensive Wardrobe Health Score (0-100) and unlocks badges
  static WardrobeHealthReport evaluateWardrobeHealth({
    required List<ClothingItem> items,
    required int streakDays,
  }) {
    if (items.isEmpty) {
      return WardrobeHealthReport(
        healthScore: 50,
        utilizationRate: 0.0,
        activeItemsCount: 0,
        dormantItemsCount: 0,
        healthStatus: 'Гардероб порожній',
        suggestions: ['Додайте перші 5-10 речей через посилання з Zara, Kasta або ASOS.'],
        badges: _defaultBadges(streakDays, 0, 0),
      );
    }

    final activeItems = items.where((i) => i.wearCount > 0).length;
    final dormantItems = items.length - activeItems;
    final utilization = (activeItems / items.length) * 100;

    // Category balance check
    final categoriesCount = items.map((e) => e.category).toSet().length;
    final categoryBonus = (categoriesCount >= 5) ? 20 : (categoriesCount * 4);

    // CPW Efficiency
    final highEfficiencyCount = items.where((i) => i.costPerWear < 150 && i.wearCount >= 5).length;

    int score = ((utilization * 0.5) + categoryBonus + (highEfficiencyCount * 5)).round().clamp(10, 100);

    String status = 'Здоровий гардероб 🌿';
    if (score >= 85) {
      status = 'Еталонна капсула (Відмінно!) 💎';
    } else if (score >= 70) {
      status = 'Добре збалансований гардероб ✨';
    } else {
      status = 'Потребує оптимізації (Багато пасивних речей) ⚠️';
    }

    final suggestions = <String>[];
    if (dormantItems > 0) {
      suggestions.add('$dormantItems речей ще жодного разу не вдягалися. Використайте їх у завтрашньому аутфіті або продайте на Shafa.');
    }
    if (categoriesCount < 4) {
      suggestions.add('У вашій шафі представлено лише $categoriesCount категорій. Додайте аксесуари або взуття для більшої комбінаторності.');
    }
    if (utilization >= 75) {
      suggestions.add('Блискуче! Ви регулярно носите понад ${utilization.round()}% своїх речей.');
    }

    return WardrobeHealthReport(
      healthScore: score,
      utilizationRate: utilization,
      activeItemsCount: activeItems,
      dormantItemsCount: dormantItems,
      healthStatus: status,
      suggestions: suggestions,
      badges: _defaultBadges(streakDays, score, highEfficiencyCount),
    );
  }

  static List<StyleBadge> _defaultBadges(int streakDays, int healthScore, int highEffCount) {
    return [
      StyleBadge(
        id: 'streak_7',
        title: 'Тижневий стрік 🔥',
        description: '7 днів поспіль формування щоденного луку',
        icon: '🔥',
        isUnlocked: streakDays >= 7,
      ),
      StyleBadge(
        id: 'streak_30',
        title: 'Марафонець стилю 🏆',
        description: '30 днів активного свідомого володіння шафою',
        icon: '🏆',
        isUnlocked: streakDays >= 30,
      ),
      StyleBadge(
        id: 'smart_investor',
        title: 'Розумний інвестор 💎',
        description: 'Мінімум 3 речі з окупністю CPW < 100 ₴',
        icon: '💎',
        isUnlocked: highEffCount >= 3,
      ),
      StyleBadge(
        id: 'capsule_master',
        title: 'Майстер капсули 🌿',
        description: 'Індекс здоров\'я шафи понад 80 балів',
        icon: '🌿',
        isUnlocked: healthScore >= 80,
      ),
    ];
  }

  /// Generates a ready-to-copy listing for reselling dormant clothes on Shafa / OLX / Vinted
  static String generateResaleListing(ClothingItem item) {
    final suggestedPrice = (item.price * 0.6).round();

    return '''
Оголошення: ${item.title} від ${item.brand}

Бренд: ${item.brand}
Категорія: ${item.category.label}
Колір: ${item.color}
Склад тканини: ${item.fabricComposition ?? 'Якісний матеріал'}
Стан: Ідеальний (одягалася лише ${item.wearCount} разів)
Початкова ціна в магазині: ${item.price.toStringAsFixed(0)} ${item.currency}
Моя ціна для продажу: $suggestedPrice ₴ (Знижка 40%!)

Опис:
Оригінальна стильна річ із гардероба. Зберігалася акуратно. Продаю у зв'язку з оптимізацією шафи у додатку Vestora. Відправлю Новою Поштою або безпечною оплатою Shafa/OLX.
''';
  }
}
