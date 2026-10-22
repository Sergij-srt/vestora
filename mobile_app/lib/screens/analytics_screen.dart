import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/wardrobe_provider.dart';
import '../services/gamification_service.dart';
import '../models/clothing_item.dart';
import '../widgets/vestora_image.dart';
import '../theme/app_theme.dart';
import 'declutter_hub_screen.dart';
import 'color_analysis_dialog.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wardrobe = context.watch<WardrobeProvider>();
    final health = wardrobe.healthReport;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Аналітика Гардероба'),
        actions: [
          IconButton(
            icon: const Icon(Icons.recycling_rounded, color: AppTheme.accent),
            tooltip: 'Розхламлення & Еко-Хаб',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DeclutterHubScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.palette_outlined, color: AppTheme.accent),
            tooltip: 'Персональний кольоротип',
            onPressed: () => showColorAnalysisDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, color: AppTheme.accent),
            tooltip: 'Поділитися звітом гардероба',
            onPressed: () {
              final topItem = wardrobe.mostWornItems.isNotEmpty ? wardrobe.mostWornItems.first : null;
              final reportText = '''
VESTORA · Звіт про Гардероб ✨
🔥 Стрік активності: ${wardrobe.streakDays} днів
🌿 Індекс здоров'я шафи: ${health.healthScore}/100 (${health.healthStatus})
💎 Сукупна вартість: ${wardrobe.totalWardrobeValue.toStringAsFixed(0)} ₴ (${wardrobe.totalItemsCount} речей)
🎯 Найкраща окупність: ${topItem != null ? '${topItem.title} (${topItem.costPerWear.toStringAsFixed(0)} ₴/вихід)' : 'Немає'}
🎨 Базова капсула: ${wardrobe.neutralColorPercentage.toStringAsFixed(0)}% нейтральних позачасових кольорів

Створено у розумному гардеробі Vestora.
''';
              Clipboard.setData(ClipboardData(text: reportText));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Звіт про гардероб скопійовано! Поділіться ним з друзями.'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Color(0xFF16A34A),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Wardrobe Health Score Card (0-100)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E1E24), Color(0xFF121214)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'ІНДЕКС ЗДОРОВ\'Я ШАФИ',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: Color(0xFFD4D4D8),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF27272A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Text('🔥', style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 4),
                          Text(
                            '${wardrobe.streakDays} днів стрік',
                            style: const TextStyle(
                              color: Color(0xFFFDE68A),
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: CircularProgressIndicator(
                            value: health.healthScore / 100.0,
                            strokeWidth: 8,
                            backgroundColor: const Color(0xFF27272A),
                            valueColor: AlwaysStoppedAnimation(
                              health.healthScore >= 80
                                  ? const Color(0xFF16A34A)
                                  : health.healthScore >= 60
                                      ? AppTheme.accent
                                      : const Color(0xFFDC2626),
                            ),
                          ),
                        ),
                        Text(
                          '${health.healthScore}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            health.healthStatus,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Активних речей: ${health.activeItemsCount} з ${wardrobe.totalItemsCount} (${health.utilizationRate.toStringAsFixed(0)}% шафи)',
                            style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 12),
                          ),
                          Text(
                            'Пасивних речей: ${health.dormantItemsCount} шт.',
                            style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (health.suggestions.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF27272A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.tips_and_updates_outlined, color: AppTheme.accent, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            health.suggestions.first,
                            style: const TextStyle(color: Color(0xFFE4E4E7), fontSize: 11.5, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Total Valuation Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'СУКУПНА ВАРТІСТЬ ШАФИ',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: AppTheme.muted,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${wardrobe.totalWardrobeValue.toStringAsFixed(0)} ₴',
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${wardrobe.totalItemsCount} одиниць',
                        style: const TextStyle(
                          color: Color(0xFF166534),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Badges / Gamification Milestones
          const Text(
            'ДОСЯГНЕННЯ ТА БЕЙДЖІ СТИЛЮ',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: AppTheme.muted,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: health.badges.length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final badge = health.badges[index];
                return Container(
                  width: 140,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: badge.isUnlocked ? Colors.white : const Color(0xFFF4F4F5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: badge.isUnlocked ? AppTheme.accent.withValues(alpha: 0.6) : AppTheme.border,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(badge.icon, style: const TextStyle(fontSize: 24)),
                          Icon(
                            badge.isUnlocked ? Icons.check_circle : Icons.lock_outline,
                            size: 16,
                            color: badge.isUnlocked ? const Color(0xFF16A34A) : AppTheme.muted,
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            badge.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: badge.isUnlocked ? AppTheme.primary : AppTheme.muted,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            badge.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 10, color: AppTheme.muted, height: 1.2),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // Section 1: Best CPW (Most value gained)
          const Text(
            'ТОП-3 НАЙКРАЩІ ІНВЕСТИЦІЇ (COST-PER-WEAR)',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: AppTheme.muted,
            ),
          ),
          const SizedBox(height: 10),
          ...wardrobe.mostWornItems.take(3).map((item) {
            return _buildItemRow(
              item: item,
              badgeText: '${item.costPerWear.toStringAsFixed(0)} ₴ / носіння',
              badgeColor: const Color(0xFFDCFCE7),
              badgeTextColor: const Color(0xFF166534),
            );
          }),
          const SizedBox(height: 20),

          // Section 2: Declutter / Forgotten Items with Resale Generator
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.inventory_2_outlined, color: AppTheme.accent),
                    SizedBox(width: 8),
                    Text(
                      'КАНДИДАТИ НА РЕСЕЙЛ (НЕНОШЕНІ)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF92400E)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Ці речі одягалися найменше. Натисніть "Продати", щоб згенерувати готове оголошення для Shafa, OLX або Vinted.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF78350F)),
                ),
                const SizedBox(height: 12),
                ...wardrobe.leastWornItems.take(2).map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: VestoraImage(
                            imageUrl: item.imageUrl,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              Text('${item.wearCount} носінь · ${item.price.toStringAsFixed(0)} ₴',
                                  style: const TextStyle(fontSize: 11, color: AppTheme.muted)),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            final listingText = GamificationService.generateResaleListing(item);
                            Clipboard.setData(ClipboardData(text: listingText));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Оголошення для "${item.title}" скопійовано! Вставте на Shafa або OLX.'),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 4),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          child: const Text('Продати', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section 3: Categories Breakdown
          const Text(
            'СКЛАД ГАРДЕРОБА ЗА КАТЕГОРІЯМИ',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: AppTheme.muted,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              children: ClothingCategory.values.map((cat) {
                final count = wardrobe.items.where((i) => i.category == cat).length;
                final percentage = wardrobe.totalItemsCount > 0 ? (count / wardrobe.totalItemsCount) : 0.0;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      SizedBox(width: 24, child: Text(cat.icon)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(cat.label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500)),
                                Text('$count шт.', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: percentage,
                              backgroundColor: AppTheme.background,
                              valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
                              minHeight: 4,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // Section 4: Color Palette & Capsule Harmony
          const Text(
            'КОЛІРНА ПАЛІТРА ТА КАПСУЛЬНА ГАРМОНІЯ',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: AppTheme.muted,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Позачасова база (Quiet Luxury):',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${wardrobe.neutralColorPercentage.toStringAsFixed(0)}% шафи',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF92400E)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: wardrobe.colorDistribution.entries.map((entry) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F4F5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _getColorFromName(entry.key),
                              border: Border.all(color: Colors.black26),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${entry.key} (${entry.value})',
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.palette_outlined, color: Color(0xFF16A34A), size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Гармонія палітри відмінна: кольори легко поєднуються за правилом трьох відтінків.',
                          style: TextStyle(fontSize: 11.5, color: Color(0xFF166534), height: 1.35),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Color _getColorFromName(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('беж') || lower.contains('крем')) return const Color(0xFFE5D3B3);
    if (lower.contains('біл')) return Colors.white;
    if (lower.contains('чорн')) return const Color(0xFF18181B);
    if (lower.contains('денім') || lower.contains('синій')) return const Color(0xFF2563EB);
    if (lower.contains('смарагд') || lower.contains('зелен')) return const Color(0xFF047857);
    if (lower.contains('сір')) return const Color(0xFF9CA3AF);
    if (lower.contains('коричн')) return const Color(0xFF78350F);
    if (lower.contains('червон') || lower.contains('бордо')) return const Color(0xFF991B1B);
    return const Color(0xFFD4D4D8);
  }

  Widget _buildItemRow({
    required ClothingItem item,
    required String badgeText,
    required Color badgeColor,
    required Color badgeTextColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: VestoraImage(
              imageUrl: item.imageUrl,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.brand.toUpperCase(),
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.muted),
                ),
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                color: badgeTextColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
