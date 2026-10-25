import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/wardrobe_provider.dart';
import '../services/declutter_service.dart';
import '../services/gamification_service.dart';
import '../widgets/vestora_image.dart';
import '../theme/app_theme.dart';

class DeclutterHubScreen extends StatelessWidget {
  const DeclutterHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wardrobe = context.watch<WardrobeProvider>();
    final report = DeclutterService.evaluateDeclutterAndEco(wardrobe: wardrobe.items);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.darkSurface : Colors.white;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.border;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Розхламлення & Еко-Хаб'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Locked Cash Hero Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E1E24), Color(0xFF121214)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppTheme.softShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Flexible(
                      child: Text(
                        'СПЛЯЧИЙ КАПІТАЛ У ШАФІ',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Color(0xFFA1A1AA),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF27272A),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${report.dormantItems.length} неношених речей',
                        style: const TextStyle(color: Color(0xFFFDE68A), fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${report.totalDormantValue.toStringAsFixed(0)} ₴',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Заблоковано в гардеробі',
                            style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Можна отримати:',
                            style: TextStyle(color: Color(0xFF86EFAC), fontSize: 10, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            '+${report.estimatedResaleCash.toStringAsFixed(0)} ₴',
                            style: const TextStyle(color: Color(0xFF4ADE80), fontSize: 18, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // 2. Eco Impact Metrics Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.35) : const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? const Color(0xFF047857) : const Color(0xFFBBF7D0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF18181B) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('💧', style: TextStyle(fontSize: 20)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${report.waterSavedLiters} л',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF166534),
                              ),
                            ),
                            Text(
                              'Збережено води',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? const Color(0xFFBBF7D0) : const Color(0xFF15803D),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 36, color: isDark ? const Color(0xFF047857) : const Color(0xFFBBF7D0)),
                const SizedBox(width: 10),
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF18181B) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('🌿', style: TextStyle(fontSize: 20)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${report.co2AvoidedKg.toStringAsFixed(1)} кг',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF166534),
                              ),
                            ),
                            Text(
                              'Уникнено CO2',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? const Color(0xFFBBF7D0) : const Color(0xFF15803D),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3. Dormant Items to Sell
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Text(
                  'КАНДИДАТИ НА РЕСЕЙЛ (НЕНОШЕНІ)',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.muted, letterSpacing: 0.8),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${report.dormantItems.length} шт.',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.accent),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (report.dormantItems.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: const Center(
                child: Text('Чудово! У вашій шафі немає "мертвого вантажу" — всі речі активно носяться 💎'),
              ),
            )
          else
            ...report.dormantItems.map((item) {
              final resalePrice = (item.price * 0.6).round();
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: VestoraImage(
                        imageUrl: item.imageUrl,
                        width: 54,
                        height: 54,
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
                            style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppTheme.muted),
                          ),
                          Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Лише ${item.wearCount} носінь · ${item.price.toStringAsFixed(0)} ₴',
                            style: const TextStyle(fontSize: 11, color: AppTheme.muted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        final listing = GamificationService.generateResaleListing(item);
                        Clipboard.setData(ClipboardData(text: listing));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Оголошення для "${item.title}" скопійовано за ціною $resalePrice ₴!'),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: const Color(0xFF16A34A),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      icon: const Icon(Icons.copy_rounded, size: 14),
                      label: Text('$resalePrice ₴', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 20),

          // 4. Fabric Care & Longevity Schedule
          const Text(
            'РОЗУМНИЙ ДОГЛЯД ТА ДОВГОВІЧНІСТЬ ТКАНИН',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.muted, letterSpacing: 0.8),
          ),
          const SizedBox(height: 10),
          ...report.fabricCareSchedule.map((reminder) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(reminder.icon, style: const TextStyle(fontSize: 26)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                reminder.title,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                reminder.frequency,
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF92400E)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          reminder.actionTip,
                          style: const TextStyle(fontSize: 11.5, color: AppTheme.muted, height: 1.35),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
