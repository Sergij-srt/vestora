import '../models/clothing_item.dart';

class FabricCareReminder {
  final String title;
  final String fabricType;
  final String actionTip;
  final String frequency;
  final String icon;

  FabricCareReminder({
    required this.title,
    required this.fabricType,
    required this.actionTip,
    required this.frequency,
    required this.icon,
  });
}

class DeclutterReport {
  final double totalDormantValue;
  final double estimatedResaleCash;
  final List<ClothingItem> dormantItems;
  final int waterSavedLiters;
  final double co2AvoidedKg;
  final List<FabricCareReminder> fabricCareSchedule;

  DeclutterReport({
    required this.totalDormantValue,
    required this.estimatedResaleCash,
    required this.dormantItems,
    required this.waterSavedLiters,
    required this.co2AvoidedKg,
    required this.fabricCareSchedule,
  });
}

class DeclutterService {
  /// Evaluates monetization potential of unused clothes and environmental impact
  static DeclutterReport evaluateDeclutterAndEco({
    required List<ClothingItem> wardrobe,
  }) {
    final dormant = wardrobe.where((i) => i.wearCount <= 2).toList();
    final totalDormantVal = dormant.fold(0.0, (sum, i) => sum + i.price);
    final resaleCash = totalDormantVal * 0.6;

    // Environmental metrics based on total wears
    final totalWears = wardrobe.fold(0, (sum, i) => sum + i.wearCount);
    final waterSaved = totalWears * 450; // liters of water saved vs buying new
    final co2Avoided = (totalWears * 1.8); // kg of CO2 avoided

    // Generate fabric care reminders based on detected items
    final schedule = <FabricCareReminder>[];

    final hasWool = wardrobe.any((i) => (i.fabricComposition ?? '').toLowerCase().contains('вовн') || (i.fabricComposition ?? '').toLowerCase().contains('wool'));
    if (hasWool) {
      schedule.add(FabricCareReminder(
        title: 'Освіжити вовняні речі парою',
        fabricType: 'Вовна / Wool',
        actionTip: 'Вовна самоочищується на свіжому повітрі. Досить відпарити вертикальним відпарювачем замість хімчистки.',
        frequency: 'Раз на 2-3 тижні',
        icon: '🐑',
      ));
    }

    final hasLinen = wardrobe.any((i) => (i.fabricComposition ?? '').toLowerCase().contains('льон') || (i.fabricComposition ?? '').toLowerCase().contains('linen'));
    if (hasLinen) {
      schedule.add(FabricCareReminder(
        title: 'Правильний догляд за льоном',
        fabricType: 'Льон / Linen',
        actionTip: 'Прати при 30°C у делікатному режимі. Прасувати злегка вологим для бездоганної м\'якої фактури.',
        frequency: 'Після кожного носіння',
        icon: '🌿',
      ));
    }

    final hasSilk = wardrobe.any((i) => (i.fabricComposition ?? '').toLowerCase().contains('шовк') || (i.fabricComposition ?? '').toLowerCase().contains('silk'));
    if (hasSilk) {
      schedule.add(FabricCareReminder(
        title: 'Захист шовкових волокон',
        fabricType: 'Шовк / Silk',
        actionTip: 'Тільки сухе чищення або ручне прання у прохолодній воді зі спеціальним шампунем для шовку.',
        frequency: 'Делікатний режим',
        icon: '✨',
      ));
    }

    final hasLeather = wardrobe.any((i) => (i.fabricComposition ?? '').toLowerCase().contains('шкір') || (i.fabricComposition ?? '').toLowerCase().contains('leather'));
    if (hasLeather) {
      schedule.add(FabricCareReminder(
        title: 'Живлення натуральної шкіри',
        fabricType: 'Шкіра / Leather',
        actionTip: 'Обробіть шкіряні лофери та сумку водовідштовхувальним кремом-бальзамом для захисту від дощу.',
        frequency: 'Раз на місяць',
        icon: '👞',
      ));
    }

    return DeclutterReport(
      totalDormantValue: totalDormantVal,
      estimatedResaleCash: resaleCash,
      dormantItems: dormant,
      waterSavedLiters: waterSaved,
      co2AvoidedKg: co2Avoided,
      fabricCareSchedule: schedule,
    );
  }
}
