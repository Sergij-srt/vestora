import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../screens/purchase_advisor_screen.dart';
import '../screens/travel_capsule_screen.dart';
import '../screens/color_analysis_dialog.dart';
import '../screens/declutter_hub_screen.dart';
import '../screens/outfit_calendar_screen.dart';
import '../screens/virtual_fitting_screen.dart';
import '../screens/capsule_matrix_screen.dart';
import '../screens/fabric_care_screen.dart';

class _ToolEntry {
  final IconData icon;
  final String title;
  final String description;
  final void Function(BuildContext context) open;
  const _ToolEntry(this.icon, this.title, this.description, this.open);
}

class _ToolGroup {
  final String title;
  final List<_ToolEntry> tools;
  const _ToolGroup(this.title, this.tools);
}

void _push(BuildContext context, Widget screen) {
  Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
}

final List<_ToolGroup> _toolGroups = [
  _ToolGroup('ОБРАЗИ', [
    _ToolEntry(
      Icons.calendar_month_outlined,
      'Календар образів',
      'Плануйте, що вдягнути, наперед на тиждень.',
      (c) => _push(c, const OutfitCalendarScreen()),
    ),
    _ToolEntry(
      Icons.face_retouching_natural_rounded,
      'AI Примірочна',
      'Віртуально приміряйте речі та образи.',
      (c) => _push(c, const VirtualFittingScreen()),
    ),
    _ToolEntry(
      Icons.grid_on_rounded,
      'Капсульна матриця 3×3',
      'Із 3 верхів і 3 низів — 9 готових комбінацій.',
      (c) => _push(c, const CapsuleMatrixScreen()),
    ),
    _ToolEntry(
      Icons.flight_takeoff_rounded,
      'Капсула у подорож',
      'Мінімальний набір речей для поїздки з урахуванням погоди.',
      (c) => _push(c, const TravelCapsuleScreen()),
    ),
  ]),
  _ToolGroup('ПОКУПКИ', [
    _ToolEntry(
      Icons.shield_outlined,
      'Радник покупок',
      'Перевірте, чи не дублює нова річ те, що вже є в шафі.',
      (c) => _push(c, const PurchaseAdvisorScreen()),
    ),
  ]),
  _ToolGroup('ДОГЛЯД І ПОРЯДОК', [
    _ToolEntry(
      Icons.dry_cleaning_outlined,
      'Догляд за тканинами',
      'Як прати й зберігати речі за складом і бірками.',
      (c) => _push(c, const FabricCareScreen()),
    ),
    _ToolEntry(
      Icons.recycling_rounded,
      'Розхламлення та еко',
      'Речі, які ви давно не носите, і скільки можна виручити за них.',
      (c) => _push(c, const DeclutterHubScreen()),
    ),
    _ToolEntry(
      Icons.palette_outlined,
      'Мій кольоротип',
      'Які кольори вам личать і як з ними поєднується ваш гардероб.',
      (c) => showColorAnalysisDialog(c),
    ),
  ]),
];

/// Opens the "Vestora Tools" sheet: every secondary feature in ONE discoverable place, grouped by
/// the job the user wants to get done, each with a one-line explanation of what it does.
Future<void> showToolsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetCtx) {
      final isDark = Theme.of(sheetCtx).brightness == Brightness.dark;
      final muted = isDark ? AppTheme.darkMuted : AppTheme.muted;
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.78,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (ctx, scrollController) {
          return ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkBorder : AppTheme.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Інструменти Vestora',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'Усе, що допомагає вдягатися краще та купувати розумніше.',
                style: TextStyle(fontSize: 13, color: muted, height: 1.3),
              ),
              for (final group in _toolGroups) ...[
                const SizedBox(height: 18),
                Text(
                  group.title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: muted,
                  ),
                ),
                const SizedBox(height: 6),
                for (final tool in group.tools)
                  Semantics(
                    button: true,
                    label: '${tool.title}. ${tool.description}',
                    excludeSemantics: true,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      minVerticalPadding: 10,
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF27272A) : AppTheme.accentLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          tool.icon,
                          color: isDark ? AppTheme.darkAccent : AppTheme.accent,
                          size: 22,
                        ),
                      ),
                      title: Text(
                        tool.title,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      subtitle: Text(
                        tool.description,
                        style: TextStyle(fontSize: 12.5, color: muted, height: 1.3),
                      ),
                      trailing: Icon(Icons.chevron_right_rounded, color: muted),
                      onTap: () {
                        // Use the caller's context for navigation so the pushed route survives the sheet pop.
                        Navigator.pop(sheetCtx);
                        tool.open(context);
                      },
                    ),
                  ),
              ],
            ],
          );
        },
      );
    },
  );
}
