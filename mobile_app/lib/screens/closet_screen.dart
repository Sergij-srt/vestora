import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/clothing_item.dart';
import '../services/wardrobe_provider.dart';
import '../services/nav_service.dart';
import '../services/gamification_service.dart';
import '../services/localization_service.dart';
import '../services/daily_stylist_service.dart';
import '../services/user_profile_service.dart';
import '../theme/app_theme.dart';
import '../widgets/controller_scope.dart';
import '../widgets/vestora_image.dart';
import '../widgets/tools_sheet.dart';
import 'brand_story_dialog.dart';
import 'settings_hub_screen.dart';
import 'outfit_calendar_screen.dart';
import 'virtual_fitting_screen.dart';

class ClosetScreen extends StatelessWidget {
  const ClosetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wardrobe = context.watch<WardrobeProvider>();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => showVestoraBrandStory(context),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'VESTORA',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      fontSize: 19,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 6),
              Icon(Icons.info_outline_rounded, size: 16, color: AppTheme.accent),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined, color: AppTheme.accent),
            tooltip: 'Календар образів (Тижневий розклад)',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OutfitCalendarScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppTheme.accent),
            tooltip: 'Налаштування та Мій Кабінет',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsHubScreen()),
              );
            },
          ),
        ],
      ),
      body: wardrobe.isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // 1. Bento Dashboard Summary
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                    child: Column(
                      children: [
                        // Main Bento Card
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF18181B), Color(0xFF27272A)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: AppTheme.softShadow,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        LocalizationService.formatPrice(wardrobe.totalWardrobeValue),
                                        maxLines: 1,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${wardrobe.totalItemsCount} ${context.tr('closet_active_items')} · 🔥 ${wardrobe.streakDays} ${context.tr('closet_streak')}',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 12, height: 1.3),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Flexible(
                                child: Semantics(
                                button: true,
                                label: 'Здоров\'я гардероба ${wardrobe.healthReport.healthScore} зі 100. Натисніть, щоб дізнатися більше',
                                excludeSemantics: true,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () => _showHealthDialog(context, wardrobe),
                                  child: Container(
                                    constraints: const BoxConstraints(minHeight: 44),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.accent, // 5:1 contrast with white text (WCAG AA)
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            '${context.tr('closet_health')} ${wardrobe.healthReport.healthScore}/100',
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.info_outline_rounded, size: 14, color: Colors.white),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 1b. Morning Daily Stylist Banner
                const SliverToBoxAdapter(
                  child: DailyStylistDigestBanner(),
                ),

                // 2. Search Bar + Tools button (all secondary features live in ONE labelled place)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Builder(
                      builder: (context) {
                        final media = MediaQuery.of(context);
                        final compactTools = media.size.width < 360 || media.textScaler.scale(14) > 19;
                        return Row(
                          children: [
                            Expanded(
                              child: TextField(
                                onChanged: (val) => context.read<WardrobeProvider>().setSearchQuery(val),
                                decoration: InputDecoration(
                                  hintText: context.tr('closet_search_hint'),
                                  prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.muted),
                                  suffixIcon: wardrobe.searchQuery.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.close_rounded, size: 20),
                                          tooltip: 'Очистити пошук',
                                          onPressed: () => context.read<WardrobeProvider>().setSearchQuery(''),
                                        )
                                      : null,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (compactTools)
                              IconButton.filledTonal(
                                onPressed: () => showToolsSheet(context),
                                icon: const Icon(Icons.apps_rounded),
                                tooltip: 'Інструменти: примірочна, календар, радник покупок та інше',
                                constraints: const BoxConstraints(minWidth: 52, minHeight: 52),
                              )
                            else
                              Tooltip(
                                message: 'Примірочна, календар, радник покупок, догляд та інше',
                                child: FilledButton.tonalIcon(
                                  onPressed: () => showToolsSheet(context),
                                  icon: const Icon(Icons.apps_rounded, size: 20),
                                  label: const Text('Інструменти', maxLines: 1, overflow: TextOverflow.ellipsis),
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size(0, 52),
                                    padding: const EdgeInsets.symmetric(horizontal: 14),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),


                // 4. Category Filter Pills
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 48,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _buildCategoryPill(
                          context,
                          label: '${context.tr('closet_all')} (${wardrobe.items.length})',
                          isSelected: wardrobe.selectedCategory == null,
                          onTap: () => context.read<WardrobeProvider>().setCategoryFilter(null),
                        ),
                        ...ClothingCategory.values.map((cat) {
                          final count = wardrobe.items.where((i) => i.category == cat).length;
                          return _buildCategoryPill(
                            context,
                            label: '${cat.icon} ${cat.label} ($count)',
                            isSelected: wardrobe.selectedCategory == cat,
                            onTap: () => context.read<WardrobeProvider>().setCategoryFilter(cat),
                          );
                        }),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 6)),

                // 4b. Usability Toolbar: Items counter, Season, Sorting & Reset
                SliverToBoxAdapter(
                  child: Builder(
                    builder: (context) {
                      final isDark = Theme.of(context).brightness == Brightness.dark;
                      final borderColor = isDark ? AppTheme.darkBorder : AppTheme.border;
                      final chipBg = isDark ? const Color(0xFF27272A) : const Color(0xFFF4F4F5);
                      final chipText = isDark ? const Color(0xFFD4D4D8) : AppTheme.secondary;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              '${wardrobe.filteredItems.length} ${context.tr('closet_items_count')} ${wardrobe.items.length} ${context.tr('closet_items_suffix')}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppTheme.darkMuted : AppTheme.muted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                // Season Chip
                                InkWell(
                                  borderRadius: BorderRadius.circular(10),
                                  onTap: () => _showSeasonFilterDialog(context),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: wardrobe.selectedSeason != null ? const Color(0xFFFEF3C7) : chipBg,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: wardrobe.selectedSeason != null ? AppTheme.accent : borderColor,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.cloud_outlined,
                                          size: 13,
                                          color: wardrobe.selectedSeason != null ? const Color(0xFF92400E) : chipText,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          wardrobe.selectedSeason != null
                                              ? wardrobe.selectedSeason!.label
                                              : context.tr('closet_all_seasons'),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: wardrobe.selectedSeason != null
                                                ? const Color(0xFF92400E)
                                                : chipText,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Sort Chip
                                InkWell(
                                  borderRadius: BorderRadius.circular(10),
                                  onTap: () => _showSortDialog(context),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: wardrobe.sortOption != WardrobeSortOption.newest
                                          ? const Color(0xFFEFF6FF)
                                          : chipBg,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: wardrobe.sortOption != WardrobeSortOption.newest
                                            ? const Color(0xFF3B82F6)
                                            : borderColor,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.sort_rounded,
                                          size: 13,
                                          color: wardrobe.sortOption != WardrobeSortOption.newest
                                              ? const Color(0xFF1D4ED8)
                                              : chipText,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          wardrobe.sortOption.label.split(' ')[0],
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: wardrobe.sortOption != WardrobeSortOption.newest
                                                ? const Color(0xFF1D4ED8)
                                                : chipText,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (wardrobe.selectedCategory != null ||
                                    wardrobe.selectedSeason != null ||
                                    wardrobe.searchQuery.isNotEmpty ||
                                    wardrobe.sortOption != WardrobeSortOption.newest)
                                  IconButton(
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.all(4),
                                    icon: const Icon(Icons.close_rounded, size: 18, color: Colors.redAccent),
                                    tooltip: 'Скинути всі фільтри',
                                    onPressed: () {
                                      HapticFeedback.lightImpact();
                                      wardrobe.resetAllFilters();
                                    },
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 8)),

                // 5. Grid or Zero Dead-Ends Setup Hero Card
                wardrobe.items.isEmpty
                    ? SliverToBoxAdapter(child: _buildEmptyHero(context))
                    : wardrobe.filteredItems.isEmpty
                        ? SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 64,
                                      height: 64,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).brightness == Brightness.dark
                                            ? const Color(0xFF27272A)
                                            : const Color(0xFFF4F4F5),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Center(
                                        child: Icon(Icons.search_off_rounded, size: 32, color: AppTheme.muted),
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    const Text(
                                      'Нічого не знайдено',
                                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      wardrobe.searchQuery.isNotEmpty
                                          ? 'За запитом "${wardrobe.searchQuery}" немає збігів серед речей.'
                                          : 'Спробуйте змінити обрані категорію чи сезон.',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(color: AppTheme.muted, fontSize: 13, height: 1.3),
                                    ),
                                    const SizedBox(height: 18),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        HapticFeedback.lightImpact();
                                        wardrobe.resetAllFilters();
                                      },
                                      icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
                                      label: const Text('Скинути фільтри та показати все'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        : SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            sliver: SliverGrid(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.65,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final item = wardrobe.filteredItems[index];
                                  return _ClothingCard(item: item);
                                },
                                childCount: wardrobe.filteredItems.length,
                              ),
                            ),
                          ),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
    );
  }

  /// First-run hero: the PRIMARY action is adding the user's own first garment; demo data is clearly secondary.
  Widget _buildEmptyHero(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppTheme.darkMuted : AppTheme.muted;

    Widget step(int number, IconData icon, String title, String subtitle) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF27272A) : AppTheme.accentLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: isDark ? AppTheme.darkAccent : AppTheme.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$number. $title',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 12.5, color: muted, height: 1.3)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.border),
        boxShadow: isDark ? const [] : AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Почнімо з вашої першої речі',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Це займає хвилину. Додайте речі, які вже є в шафі, — і Vestora складатиме образи, нагадуватиме про догляд та показуватиме, що ви справді носите.',
            style: TextStyle(fontSize: 13, color: muted, height: 1.4),
          ),
          const SizedBox(height: 18),
          step(1, Icons.photo_camera_outlined, 'Сфотографуйте річ', 'Камерою або виберіть фото з галереї.'),
          step(2, Icons.label_outline_rounded, 'Додайте бірку (за бажанням)', 'З неї беруться склад, розмір і правила догляду.'),
          step(3, Icons.style_outlined, 'Складайте образи', 'Стиліст підбере комбінації під погоду та привід.'),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => AppNav.goToTab(AppNav.tabAdd),
              icon: const Icon(Icons.add_a_photo_outlined, size: 20),
              label: const Text('Додати першу річ'),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () {
                context.read<WardrobeProvider>().loadDemoCapsule();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Додано демо-речі для ознайомлення. Їх можна видалити будь-коли.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.visibility_outlined, size: 18),
              label: const Text('Лише подивитись: додати демо-речі', textAlign: TextAlign.center),
            ),
          ),
        ],
      ),
    );
  }

  /// Explains what the wardrobe health score means and what to do to improve it.
  void _showHealthDialog(BuildContext context, WardrobeProvider wardrobe) {
    final report = wardrobe.healthReport;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Здоров\'я гардероба: ${report.healthScore}/100'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(report.healthStatus, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Text(
                'Ви носите ${report.utilizationRate.toStringAsFixed(0)}% речей. '
                'Без діла лежать: ${report.dormantItemsCount} шт.',
              ),
              const SizedBox(height: 10),
              const Text(
                'Бал росте, коли ви реально користуєтесь речами та регулярно відзначаєте образи.',
                style: TextStyle(fontSize: 12.5, color: AppTheme.muted),
              ),
              if (report.suggestions.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Text('Що зробити:', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                for (final tip in report.suggestions)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('• $tip'),
                  ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Зрозуміло')),
        ],
      ),
    );
  }

  Widget _buildCategoryPill(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: isDark ? AppTheme.accent : AppTheme.primary,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : (isDark ? Colors.white : AppTheme.primary),
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        ),
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        side: BorderSide(
          color: isSelected
              ? (isDark ? AppTheme.accent : AppTheme.primary)
              : (isDark ? AppTheme.darkBorder : AppTheme.border),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  void _showSortDialog(BuildContext context) {
    final wardrobe = context.read<WardrobeProvider>();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
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
                const Text('Сортування гардеробу', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...WardrobeSortOption.values.map((opt) {
                  final isSel = wardrobe.sortOption == opt;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      isSel ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                      color: isSel ? AppTheme.accent : AppTheme.muted,
                    ),
                    title: Text(
                      opt.label,
                      style: TextStyle(
                        fontWeight: isSel ? FontWeight.w800 : FontWeight.w500,
                        color: isSel
                            ? (isDark ? Colors.white : AppTheme.primary)
                            : (isDark ? const Color(0xFFD4D4D8) : AppTheme.secondary),
                      ),
                    ),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      wardrobe.setSortOption(opt);
                      Navigator.pop(ctx);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSeasonFilterDialog(BuildContext context) {
    final wardrobe = context.read<WardrobeProvider>();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
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
                const Text('Фільтр за сезоном', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    wardrobe.selectedSeason == null ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                    color: wardrobe.selectedSeason == null ? AppTheme.accent : AppTheme.muted,
                  ),
                  title: const Text('Всі сезони (Повний гардероб)', style: TextStyle(fontWeight: FontWeight.w700)),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    wardrobe.setSeasonFilter(null);
                    Navigator.pop(ctx);
                  },
                ),
                ...Season.values.map((s) {
                  final isSel = wardrobe.selectedSeason == s;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      isSel ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                      color: isSel ? AppTheme.accent : AppTheme.muted,
                    ),
                    title: Text(
                      s.label,
                      style: TextStyle(
                        fontWeight: isSel ? FontWeight.w800 : FontWeight.w500,
                        color: isSel
                            ? (isDark ? Colors.white : AppTheme.primary)
                            : (isDark ? const Color(0xFFD4D4D8) : AppTheme.secondary),
                      ),
                    ),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      wardrobe.setSeasonFilter(s);
                      Navigator.pop(ctx);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ClothingCard extends StatelessWidget {
  final ClothingItem item;
  const _ClothingCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final placeholderBg = isDark ? const Color(0xFF27272A) : const Color(0xFFF4F4F5);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showItemDetails(context, item),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with Category & Wear Count Badges
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  VestoraImage(
                    imageUrl: item.imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    placeholder: (context, url) => Container(
                      color: placeholderBg,
                      child: const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: placeholderBg,
                      child: const Icon(Icons.broken_image_rounded, color: AppTheme.muted),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${item.wearCount}×',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: Text(item.category.icon, style: const TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ),

            // Card Details
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.brand.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          '${item.price.toStringAsFixed(0)} ${item.currency}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: isDark ? Colors.white : AppTheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '${item.costPerWear.toStringAsFixed(0)} ₴/лук',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppTheme.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showItemDetails(BuildContext context, ClothingItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        return _ItemDetailBottomSheet(item: item);
      },
    );
  }
}

class _ItemDetailBottomSheet extends StatefulWidget {
  final ClothingItem item;
  const _ItemDetailBottomSheet({required this.item});

  @override
  State<_ItemDetailBottomSheet> createState() => _ItemDetailBottomSheetState();
}

class _ItemDetailBottomSheetState extends State<_ItemDetailBottomSheet> {
  double _extraWears = 5;

  void _showImagePreview(BuildContext context, String imageUrl, String title) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.8),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              child: VestoraImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) => Container(
                  height: 250,
                  color: Colors.black26,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 200,
                  color: Colors.white,
                  child: const Center(child: Icon(Icons.broken_image, size: 40)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showResaleDialog(BuildContext context, ClothingItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final listingText = GamificationService.generateResaleListing(item);
    final suggestedPrice = (item.price * 0.6).round();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF451A03) : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.storefront_rounded, color: AppTheme.accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ШІ-Оголошення для Shafa / OLX',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'Згенеровано на основі етикетки та вартості',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark ? AppTheme.darkMuted : AppTheme.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF14532D).withValues(alpha: 0.35) : const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF166534) : const Color(0xFFBBF7D0),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.savings_outlined, color: Color(0xFF16A34A), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Рекомендована ціна продажу: $suggestedPrice ₴ (Знижка 40% від початкових ${item.price.toStringAsFixed(0)} ₴)',
                      style: TextStyle(
                        color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF166534),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              constraints: const BoxConstraints(maxHeight: 180),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF27272A) : const Color(0xFFF4F4F5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.border),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  listingText,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    color: isDark ? const Color(0xFFE4E4E7) : const Color(0xFF27272A),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: listingText));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Оголошення для "${item.title}" скопійовано в буфер обміну!'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: const Color(0xFF16A34A),
                    ),
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text('Скопіювати оголошення (1 клік)'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, ClothingItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ControllerScope(
        create: () => [
          TextEditingController(text: item.title),
          TextEditingController(text: item.brand),
          TextEditingController(text: item.price.toStringAsFixed(0)),
          TextEditingController(text: item.size ?? ''),
          TextEditingController(text: item.fabricComposition ?? ''),
          TextEditingController(text: item.color),
        ],
        builder: (ctx, ctrls) {
          final titleCtrl = ctrls[0];
          final brandCtrl = ctrls[1];
          final priceCtrl = ctrls[2];
          final sizeCtrl = ctrls[3];
          final fabricCtrl = ctrls[4];
          final colorCtrl = ctrls[5];
          return Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Редагувати річ',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Назва товару'),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: brandCtrl,
                          decoration: const InputDecoration(labelText: 'Бренд'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: priceCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Ціна (₴)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: sizeCtrl,
                          decoration: const InputDecoration(labelText: 'Розмір (EUR / US)'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: colorCtrl,
                          decoration: const InputDecoration(labelText: 'Колір'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: fabricCtrl,
                    decoration: const InputDecoration(labelText: 'Склад тканини (з етикетки)'),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final updated = item.copyWith(
                          title: titleCtrl.text.trim().isNotEmpty ? titleCtrl.text.trim() : item.title,
                          brand: brandCtrl.text.trim().isNotEmpty ? brandCtrl.text.trim() : item.brand,
                          price: double.tryParse(priceCtrl.text.trim()) ?? item.price,
                          color: colorCtrl.text.trim().isNotEmpty ? colorCtrl.text.trim() : item.color,
                          size: sizeCtrl.text.trim().isNotEmpty ? sizeCtrl.text.trim() : item.size,
                          fabricComposition: fabricCtrl.text.trim().isNotEmpty ? fabricCtrl.text.trim() : item.fabricComposition,
                        );
                        context.read<WardrobeProvider>().updateItem(updated);
                        Navigator.pop(ctx);
                        Navigator.pop(context); // Close bottom sheet
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Дані речі успішно оновлено!'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: const Text('Зберегти зміни'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSpecItem(IconData icon, String label, String value, {required bool isDark}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF27272A) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? AppTheme.darkMuted : AppTheme.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppTheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isNarrow = MediaQuery.of(context).size.width < 360;
    final item = widget.item;
    final simulatedWears = item.wearCount + _extraWears.round();
    final simulatedCPW = simulatedWears > 0 ? (item.price / simulatedWears) : item.price;
    final percentSavings = item.costPerWear > 0 ? (((item.costPerWear - simulatedCPW) / item.costPerWear) * 100) : 0;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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

            // Top Header: Image, Title, Price and Edit Button
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: VestoraImage(
                    imageUrl: item.imageUrl,
                    width: 95,
                    height: 115,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.brand.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isDark ? AppTheme.darkMuted : AppTheme.muted,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.accent),
                            tooltip: 'Редагувати',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                            onPressed: () => _showEditDialog(context, item),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            '${item.price.toStringAsFixed(0)} ${item.currency}',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: isDark ? Colors.white : AppTheme.primary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF451A03) : const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${item.wearCount} носінь',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Luxury Specification Grid (Data read from Labels & Receipts)
            Text(
              'ХАРАКТЕРИСТИКИ ТА ЕТИКЕТКА',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                color: isDark ? AppTheme.darkMuted : AppTheme.muted,
              ),
            ),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: isNarrow ? 2.0 : 2.5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              children: [
                _buildSpecItem(Icons.straighten_rounded, 'Розмір', item.size ?? 'EUR 38 / M', isDark: isDark),
                _buildSpecItem(Icons.public_rounded, 'Походження', item.countryOfOrigin ?? 'Made in Portugal', isDark: isDark),
                _buildSpecItem(Icons.texture_rounded, 'Склад тканини', item.fabricComposition ?? '100% Вовна', isDark: isDark),
                _buildSpecItem(Icons.local_laundry_service_outlined, 'Правила догляду', item.careInstructions ?? 'Делікатне прання', isDark: isDark),
                _buildSpecItem(Icons.palette_outlined, 'Колір & Сезон', '${item.color} · ${item.season.label}', isDark: isDark),
                _buildSpecItem(Icons.storefront_outlined, 'Місце покупки', item.storeName ?? item.brand, isDark: isDark),
              ],
            ),
            const SizedBox(height: 14),

            // Photos from Tag & Receipt if present
            if (item.labelPhotoUrl != null || item.receiptPhotoUrl != null) ...[
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'ФОТО-ПІДТВЕРДЖЕННЯ:',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppTheme.darkMuted : AppTheme.muted,
                    ),
                  ),
                  if (item.labelPhotoUrl != null)
                    InkWell(
                      onTap: () => _showImagePreview(context, item.labelPhotoUrl!, 'Фото етикетки'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF14532D).withValues(alpha: 0.4) : const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark ? const Color(0xFF166534) : const Color(0xFFBBF7D0),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🏷️', style: TextStyle(fontSize: 11)),
                            const SizedBox(width: 4),
                            Text(
                              'Етикетка',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF166534),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (item.receiptPhotoUrl != null)
                    InkWell(
                      onTap: () => _showImagePreview(context, item.receiptPhotoUrl!, 'Фото чека'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF3B0764).withValues(alpha: 0.4) : const Color(0xFFFAF5FF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark ? const Color(0xFF6B21A8) : const Color(0xFFE9D5FF),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🧾', style: TextStyle(fontSize: 11)),
                            const SizedBox(width: 4),
                            Text(
                              'Чек покупки',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isDark ? const Color(0xFFD8B4FE) : const Color(0xFF6B21A8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
            ],

            // Predictive Cost-Per-Wear Simulator Box
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF27272A) : const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'СИМУЛЯТОР ОКУПНОСТІ (CPW)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                            color: AppTheme.accent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '+${_extraWears.round()} виходів',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                    ],
                  ),
                  Slider(
                    value: _extraWears,
                    min: 0,
                    max: 30,
                    divisions: 30,
                    activeColor: AppTheme.accent,
                    onChanged: (v) => setState(() => _extraWears = v),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'Зараз: ${item.costPerWear.toStringAsFixed(0)} ₴ / носіння',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppTheme.darkMuted : AppTheme.muted,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Прогноз: ${simulatedCPW.toStringAsFixed(0)} ₴ (-${percentSavings.toStringAsFixed(0)}%)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF16A34A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Smart Shortcut Buttons: Try-On & Style Outfit
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      side: const BorderSide(color: Color(0xFFD4AF37)),
                      backgroundColor: isDark
                          ? const Color(0xFF451A03).withValues(alpha: 0.45)
                          : const Color(0xFFFFFBEB),
                    ),
                    icon: Icon(
                      Icons.face_retouching_natural_rounded,
                      size: 17,
                      color: isDark ? const Color(0xFFFDE68A) : const Color(0xFFB45309),
                    ),
                    label: Text(
                      'Приміряти (Virtual Try-On)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isDark ? const Color(0xFFFDE68A) : const Color(0xFFB45309),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VirtualFittingScreen(
                            initialOuterwear: item.category == ClothingCategory.outerwear ? item : null,
                            initialTop: item.category == ClothingCategory.tops ? item : null,
                            initialBottom: item.category == ClothingCategory.bottoms ? item : null,
                            initialShoes: item.category == ClothingCategory.shoes ? item : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: isNarrow ? 10 : 16, vertical: 12),
                    ),
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                    label: const Text(
                      'Вдягнути (+1)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onPressed: () {
                      context.read<WardrobeProvider>().recordWear(item.id);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Образ зараховано для "${item.title}"!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: isNarrow ? 10 : 14, vertical: 12),
                  ),
                  icon: const Icon(Icons.sell_outlined, size: 16),
                  label: const Text('Продати'),
                  onPressed: () => _showResaleDialog(context, item),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                  tooltip: 'Видалити',
                  onPressed: () {
                    // Capture everything BEFORE popping the sheet: its context dies with the route.
                    final wardrobe = context.read<WardrobeProvider>();
                    final messenger = ScaffoldMessenger.of(context);
                    final removed = item;
                    wardrobe.removeItem(removed.id);
                    Navigator.pop(context);
                    messenger
                      ..clearSnackBars()
                      ..showSnackBar(
                        SnackBar(
                          content: Text('«${removed.title}» видалено з гардероба'),
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 6),
                          action: SnackBarAction(
                            label: 'Скасувати',
                            onPressed: () => wardrobe.addItem(removed),
                          ),
                        ),
                      );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class DailyStylistDigestBanner extends StatefulWidget {
  const DailyStylistDigestBanner({super.key});

  @override
  State<DailyStylistDigestBanner> createState() => _DailyStylistDigestBannerState();
}

class _DailyStylistDigestBannerState extends State<DailyStylistDigestBanner> {
  DailyOutfitDigest? _digest;
  bool _isLoading = true;
  bool _isDismissed = false;
  bool _expanded = false; // collapsed by default so the wardrobe grid stays above the fold

  @override
  void initState() {
    super.initState();
    _loadDigest();
  }

  Future<void> _loadDigest({bool forceRefresh = false, String? overrideCity}) async {
    final wardrobe = context.read<WardrobeProvider>();
    if (wardrobe.items.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    if (forceRefresh && mounted) {
      setState(() => _isLoading = true);
    }
    final location = overrideCity ?? UserProfileService.profile.location;
    final digest = await DailyStylistService.getTodayDigest(
      wardrobeItems: wardrobe.items,
      location: location,
      forceRefresh: forceRefresh,
    );
    if (mounted) {
      setState(() {
        _digest = digest;
        _isLoading = false;
      });
    }
  }

  void _showCityPickerDialog() {
    showDialog(
      context: context,
      builder: (_) => ControllerScope(
        create: () => [TextEditingController()],
        builder: (ctx, ctrls) {
          final controller = ctrls[0];
          return AlertDialog(
            backgroundColor: const Color(0xFF1C1917),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Color(0xFFD4AF37), width: 1.2),
            ),
            title: const Row(
              children: [
                Icon(Icons.location_on_rounded, color: Color(0xFFD4AF37), size: 22),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Місто та погода',
                    style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Оберіть або введіть місто для отримання живого прогнозу погоди (Open-Meteo API):',
                    style: TextStyle(color: Color(0xFFA8A29E), fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: defaultFashionCities.map((city) {
                      final isCurrent = _digest?.city.toLowerCase() == city.name.toLowerCase();
                      return ChoiceChip(
                        label: Text(city.name),
                        selected: isCurrent,
                        selectedColor: const Color(0xFFD4AF37),
                        backgroundColor: const Color(0xFF292524),
                        labelStyle: TextStyle(
                          color: isCurrent ? Colors.black : Colors.white,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        onSelected: (_) async {
                          Navigator.pop(ctx);
                          await UserProfileService.saveProfile(location: city.name);
                          _loadDigest(forceRefresh: true, overrideCity: city.name);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Введіть інше місто (напр. Чернівці)',
                      hintStyle: const TextStyle(color: Color(0xFFA8A29E), fontSize: 13),
                      filled: true,
                      fillColor: const Color(0xFF292524),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Скасувати', style: TextStyle(color: Color(0xFFA8A29E))),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  final text = controller.text.trim();
                  Navigator.pop(ctx);
                  if (text.isNotEmpty) {
                    await UserProfileService.saveProfile(location: text);
                    _loadDigest(forceRefresh: true, overrideCity: text);
                  }
                },
                child: const Text('Застосувати', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _wearOutfit(WardrobeProvider wardrobe) async {
    if (_digest == null) return;
    await DailyStylistService.markWorn(wardrobe, _digest!);
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🔥 Ранковий лук одягнено! Ваш стрік збільшено до ${wardrobe.streakDays} днів.'),
          backgroundColor: const Color(0xFFD97706),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _triggerPush() async {
    if (_digest == null) return;
    final granted = await DailyStylistService.requestNotificationPermission();
    DailyStylistService.sendMorningPush(_digest!);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            granted
                ? '🔔 Ранкове сповіщення надіслано! Перевірте робочий стіл / панель повідомлень.'
                : '🔔 Демо-сповіщення успішно сформовано!',
          ),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openTryOn() {
    if (_digest == null || _digest!.outfitItems.isEmpty) return;
    final items = _digest!.outfitItems;
    ClothingItem? outerwear;
    ClothingItem? top;
    ClothingItem? bottom;
    ClothingItem? shoes;

    for (final it in items) {
      if (it.category == ClothingCategory.outerwear) outerwear = it;
      if (it.category == ClothingCategory.tops) top = it;
      if (it.category == ClothingCategory.bottoms) bottom = it;
      if (it.category == ClothingCategory.shoes) shoes = it;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VirtualFittingScreen(
          initialOuterwear: outerwear,
          initialTop: top,
          initialBottom: bottom,
          initialShoes: shoes,
        ),
      ),
    );
  }

  /// One-line summary of today's suggested look. Tap to expand into the full morning-stylist card.
  Widget _buildCollapsed(DailyOutfitDigest digest) {
    final media = MediaQuery.of(context);
    final thumbs = media.textScaler.scale(14) > 19 ? 0 : (media.size.width < 340 ? 1 : 3);
    final shown = digest.outfitItems.take(thumbs).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: const Color(0xFF1C1917),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: const Color(0xFFD4AF37).withValues(alpha: 0.4), width: 1.2),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => setState(() => _expanded = true),
          child: Semantics(
            button: true,
            label: 'Лук дня. ${digest.weatherSummary}. Натисніть, щоб розгорнути',
            excludeSemantics: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Color(0xFFD4AF37), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Лук дня',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          digest.isWorn ? '✓ Вже вдягнено сьогодні' : digest.weatherSummary,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Color(0xFFD6D3D1), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  for (final item in shown)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: VestoraImage(imageUrl: item.imageUrl, width: 40, height: 40, fit: BoxFit.cover),
                      ),
                    ),
                  const SizedBox(width: 6),
                  const Icon(Icons.expand_more_rounded, color: Color(0xFFD6D3D1), size: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isDismissed || _isLoading || _digest == null || _digest!.outfitItems.isEmpty) {
      return const SizedBox.shrink();
    }

    final wardrobe = context.watch<WardrobeProvider>();
    final digest = _digest!;
    if (!_expanded) return _buildCollapsed(digest);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1C1917), Color(0xFF292524)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.4), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar: Weather + Title + Actions
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _showCityPickerDialog,
                    borderRadius: BorderRadius.circular(10),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF44403C),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('⛅', style: TextStyle(fontSize: 12)),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  digest.weatherSummary,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFFFDE68A),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on_outlined, size: 12, color: Color(0xFFD4AF37)),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                digest.city,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Color(0xFFA8A29E), fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down_rounded, size: 16, color: Color(0xFFA8A29E)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, color: Color(0xFFA8A29E), size: 20),
                      tooltip: 'Оновити прогноз погоди',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                      onPressed: () => _loadDigest(forceRefresh: true),
                    ),
                    IconButton(
                      icon: const Icon(Icons.notifications_active_outlined, color: Color(0xFFFDE68A), size: 20),
                      tooltip: 'Надіслати ранкове сповіщення',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                      onPressed: _triggerPush,
                    ),
                    IconButton(
                      icon: const Icon(Icons.expand_less_rounded, color: Color(0xFFA8A29E), size: 22),
                      tooltip: 'Згорнути',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                      onPressed: () => setState(() => _expanded = false),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFFA8A29E), size: 20),
                      tooltip: 'Сховати до завтра',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                      onPressed: () => setState(() => _isDismissed = true),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Title & Advice
            const Row(
              children: [
                Icon(Icons.auto_awesome, color: Color(0xFFD4AF37), size: 15),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Ранковий AI-асистент · Лук дня',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              digest.stylistTip,
              style: const TextStyle(
                color: Color(0xFFE7E5E4),
                fontSize: 12,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),

            // Garments Row
            SizedBox(
              height: 70,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: digest.outfitItems.length,
                separatorBuilder: (_, index) => const SizedBox(width: 8),
                itemBuilder: (_, idx) {
                  final item = digest.outfitItems[idx];
                  return Container(
                    width: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFF44403C),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF57534E)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: VestoraImage(
                              imageUrl: item.imageUrl,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              color: Colors.black.withValues(alpha: 0.65),
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                item.category.label,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // Actions
            if (MediaQuery.of(context).size.width < 360)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: digest.isWorn ? const Color(0xFF16A34A) : const Color(0xFFD4AF37),
                      foregroundColor: digest.isWorn ? Colors.white : Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: Icon(
                      digest.isWorn ? Icons.check_circle_rounded : Icons.check_rounded,
                      size: 16,
                    ),
                    label: Text(
                      digest.isWorn ? 'Вдягнено (+1)' : 'Вдягнути сьогодні (+1)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                    ),
                    onPressed: digest.isWorn ? null : () => _wearOutfit(wardrobe),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFDE68A),
                      side: const BorderSide(color: Color(0xFFD4AF37)),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.face_retouching_natural_rounded, size: 16),
                    label: const Text('Примірка', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: _openTryOn,
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: digest.isWorn ? const Color(0xFF16A34A) : const Color(0xFFD4AF37),
                        foregroundColor: digest.isWorn ? Colors.white : Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: Icon(
                        digest.isWorn ? Icons.check_circle_rounded : Icons.check_rounded,
                        size: 16,
                      ),
                      label: Text(
                        digest.isWorn ? 'Вдягнено (+1)' : 'Вдягнути сьогодні (+1)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                      ),
                      onPressed: digest.isWorn ? null : () => _wearOutfit(wardrobe),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFDE68A),
                      side: const BorderSide(color: Color(0xFFD4AF37)),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.face_retouching_natural_rounded, size: 16),
                    label: const Text('Примірка', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: _openTryOn,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

