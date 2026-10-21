import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/clothing_item.dart';
import '../services/wardrobe_provider.dart';
import '../services/gamification_service.dart';
import '../theme/app_theme.dart';
import 'purchase_advisor_screen.dart';
import 'brand_story_dialog.dart';
import 'travel_capsule_screen.dart';
import 'color_analysis_dialog.dart';
import 'declutter_hub_screen.dart';
import 'settings_hub_screen.dart';
import 'outfit_calendar_screen.dart';
import 'virtual_fitting_screen.dart';
import 'capsule_matrix_screen.dart';
import 'fabric_care_screen.dart';

class ClosetScreen extends StatelessWidget {
  const ClosetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wardrobe = context.watch<WardrobeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => showVestoraBrandStory(context),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'VESTORA',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  fontSize: 19,
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            tooltip: 'Більше інструментів',
            onSelected: (value) {
              switch (value) {
                case 'tryon':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const VirtualFittingScreen()),
                  );
                  break;
                case 'matrix':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CapsuleMatrixScreen()),
                  );
                  break;
                case 'care':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FabricCareScreen()),
                  );
                  break;
                case 'travel':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TravelCapsuleScreen()),
                  );
                  break;
                case 'palette':
                  showColorAnalysisDialog(context);
                  break;
                case 'advisor':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PurchaseAdvisorScreen()),
                  );
                  break;
                case 'reset':
                  context.read<WardrobeProvider>().setCategoryFilter(null);
                  context.read<WardrobeProvider>().setSearchQuery('');
                  break;
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'tryon',
                child: Row(
                  children: [
                    Icon(Icons.face_retouching_natural_rounded, color: AppTheme.accent, size: 20),
                    SizedBox(width: 10),
                    Text('AI Примірочна (Try-On)'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'matrix',
                child: Row(
                  children: [
                    Icon(Icons.grid_on_rounded, color: AppTheme.accent, size: 20),
                    SizedBox(width: 10),
                    Text('Капсульна Матриця 3x3'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'care',
                child: Row(
                  children: [
                    Icon(Icons.dry_cleaning_outlined, color: AppTheme.accent, size: 20),
                    SizedBox(width: 10),
                    Text('Догляд за тканинами'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'travel',
                child: Row(
                  children: [
                    Icon(Icons.flight_takeoff_rounded, color: AppTheme.accent, size: 20),
                    SizedBox(width: 10),
                    Text('Капсула у подорож'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'palette',
                child: Row(
                  children: [
                    Icon(Icons.palette_outlined, color: AppTheme.accent, size: 20),
                    SizedBox(width: 10),
                    Text('Мій кольоротип'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'advisor',
                child: Row(
                  children: [
                    Icon(Icons.shield_outlined, color: AppTheme.accent, size: 20),
                    SizedBox(width: 10),
                    Text('Радник покупок'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.refresh_rounded, size: 20),
                    SizedBox(width: 10),
                    Text('Скинути фільтри'),
                  ],
                ),
              ),
            ],
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
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF18181B), Color(0xFF27272A)],
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
                                  const Text(
                                    'ЦИФРОВИЙ ГАРДЕРОБ',
                                    style: TextStyle(
                                      color: Color(0xFFA1A1AA),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF3F3F46),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        const Text('🔥', style: TextStyle(fontSize: 12)),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${wardrobe.streakDays} днів',
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
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${wardrobe.totalWardrobeValue.toStringAsFixed(0)} ₴',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 26,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${wardrobe.totalItemsCount} активних одиниць',
                                        style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD97706),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      'Здоров\'я: ${wardrobe.healthReport.healthScore}/100',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 11.5,
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
                ),

                // 2. Search Bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: TextField(
                      onChanged: (val) => context.read<WardrobeProvider>().setSearchQuery(val),
                      decoration: InputDecoration(
                        hintText: 'Пошук за назвою, брендом, кольором...',
                        prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.muted),
                        suffixIcon: wardrobe.searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded, size: 20),
                                onPressed: () => context.read<WardrobeProvider>().setSearchQuery(''),
                              )
                            : null,
                      ),
                    ),
                  ),
                ),

                // 3. "Should I Buy This?" Quick Advisor Banner
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PurchaseAdvisorScreen()),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.shield_outlined, color: Color(0xFF16A34A), size: 20),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Плануєте покупку? AI перевірить шафу на дублікати →',
                                style: TextStyle(
                                  color: Color(0xFF166534),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded, color: Color(0xFF16A34A), size: 18),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // 3b. Smart Assistant Quick Pills (Travel Capsule, Color Season, Declutter Hub)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 38,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _buildAssistPill(
                          label: '🪞 AI Примірочна',
                          color: const Color(0xFFFEF3C7),
                          textColor: const Color(0xFF92400E),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const VirtualFittingScreen()),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildAssistPill(
                          label: '🔲 Матриця 3x3',
                          color: const Color(0xFFF3E8FF),
                          textColor: const Color(0xFF6B21A8),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CapsuleMatrixScreen()),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildAssistPill(
                          label: '🏷️ Догляд & Бірки',
                          color: const Color(0xFFCCFBF1),
                          textColor: const Color(0xFF0F766E),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const FabricCareScreen()),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildAssistPill(
                          label: '📅 Календар образів',
                          color: const Color(0xFFEFF6FF),
                          textColor: const Color(0xFF1D4ED8),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const OutfitCalendarScreen()),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildAssistPill(
                          label: '🧳 Капсула у подорож',
                          color: const Color(0xFFFEF3C7),
                          textColor: const Color(0xFF92400E),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const TravelCapsuleScreen()),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildAssistPill(
                          label: '🎨 Мій кольоротип',
                          color: const Color(0xFFF3E8FF),
                          textColor: const Color(0xFF6B21A8),
                          onTap: () => showColorAnalysisDialog(context),
                        ),
                        const SizedBox(width: 8),
                        _buildAssistPill(
                          label: '♻️ Розхламлення & Еко',
                          color: const Color(0xFFDCFCE7),
                          textColor: const Color(0xFF166534),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const DeclutterHubScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 6)),

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
                          label: 'Все (${wardrobe.items.length})',
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
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${wardrobe.filteredItems.length} з ${wardrobe.items.length} речей',
                          style: const TextStyle(fontSize: 12, color: AppTheme.muted, fontWeight: FontWeight.w600),
                        ),
                        Row(
                          children: [
                            // Season Chip
                            InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () => _showSeasonFilterDialog(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                decoration: BoxDecoration(
                                  color: wardrobe.selectedSeason != null ? const Color(0xFFFEF3C7) : const Color(0xFFF4F4F5),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: wardrobe.selectedSeason != null ? AppTheme.accent : AppTheme.border),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.cloud_outlined, size: 13, color: AppTheme.secondary),
                                    const SizedBox(width: 4),
                                    Text(
                                      wardrobe.selectedSeason != null ? wardrobe.selectedSeason!.label : 'Всі сезони',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: wardrobe.selectedSeason != null ? const Color(0xFF92400E) : AppTheme.secondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            // Sort Chip
                            InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () => _showSortDialog(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                decoration: BoxDecoration(
                                  color: wardrobe.sortOption != WardrobeSortOption.newest ? const Color(0xFFEFF6FF) : const Color(0xFFF4F4F5),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: wardrobe.sortOption != WardrobeSortOption.newest ? const Color(0xFF3B82F6) : AppTheme.border),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.sort_rounded, size: 13, color: AppTheme.secondary),
                                    const SizedBox(width: 4),
                                    Text(
                                      wardrobe.sortOption.label.split(' ')[0],
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: wardrobe.sortOption != WardrobeSortOption.newest ? const Color(0xFF1D4ED8) : AppTheme.secondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (wardrobe.selectedCategory != null ||
                                wardrobe.selectedSeason != null ||
                                wardrobe.searchQuery.isNotEmpty ||
                                wardrobe.sortOption != WardrobeSortOption.newest) ...[
                              const SizedBox(width: 4),
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
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 8)),

                // 5. Grid or Zero Dead-Ends Setup Hero Card
                wardrobe.items.isEmpty
                    ? SliverToBoxAdapter(
                        child: Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppTheme.border),
                            boxShadow: AppTheme.softShadow,
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFEF3C7),
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Icon(Icons.checkroom_rounded, size: 32, color: AppTheme.accent),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Ваш гардероб поки що порожній',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Спробуйте магію Vestora миттєво: завантажте готову дизайнерську демо-капсулу (Zara, Massimo Dutti, COS) або додайте власні речі за посиланням.',
                                style: TextStyle(fontSize: 13, color: AppTheme.muted, height: 1.4),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    context.read<WardrobeProvider>().loadDemoCapsule();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Готову дизайнерську капсулу завантажено!'),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.auto_awesome, size: 18),
                                  label: const Text('Завантажити готову капсулу (1 клік)'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
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
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFF4F4F5),
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

  Widget _buildAssistPill({
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(color: textColor, fontWeight: FontWeight.w700, fontSize: 11.5),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryPill(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: AppTheme.primary,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppTheme.primary,
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        ),
        backgroundColor: Colors.white,
        side: BorderSide(
          color: isSelected ? AppTheme.primary : AppTheme.border,
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
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2)),
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
                    color: isSel ? AppTheme.primary : AppTheme.secondary,
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
  }

  void _showSeasonFilterDialog(BuildContext context) {
    final wardrobe = context.read<WardrobeProvider>();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2)),
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
                    color: isSel ? AppTheme.primary : AppTheme.secondary,
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
  }
}

class _ClothingCard extends StatelessWidget {
  final ClothingItem item;
  const _ClothingCard({required this.item});

  @override
  Widget build(BuildContext context) {
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
                  CachedNetworkImage(
                    imageUrl: item.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: const Color(0xFFF4F4F5),
                      child: const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: const Color(0xFFF4F4F5),
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
                      Text(
                        '${item.price.toStringAsFixed(0)} ${item.currency}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppTheme.primary,
                        ),
                      ),
                      Text(
                        '${item.costPerWear.toStringAsFixed(0)} ₴/лук',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.accent,
                          fontWeight: FontWeight.w600,
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
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
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
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
              child: CachedNetworkImage(
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
    final listingText = GamificationService.generateResaleListing(item);
    final suggestedPrice = (item.price * 0.6).round();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.storefront_rounded, color: AppTheme.accent),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ШІ-Оголошення для Shafa / OLX',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'Згенеровано на основі етикетки та вартості',
                        style: TextStyle(fontSize: 11.5, color: AppTheme.muted),
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
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.savings_outlined, color: Color(0xFF16A34A), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Рекомендована ціна продажу: $suggestedPrice ₴ (Знижка 40% від початкових ${item.price.toStringAsFixed(0)} ₴)',
                      style: const TextStyle(
                        color: Color(0xFF166534),
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
                color: const Color(0xFFF4F4F5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  listingText,
                  style: const TextStyle(fontSize: 12, height: 1.45, color: Color(0xFF27272A)),
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
    final titleCtrl = TextEditingController(text: item.title);
    final brandCtrl = TextEditingController(text: item.brand);
    final priceCtrl = TextEditingController(text: item.price.toStringAsFixed(0));
    final sizeCtrl = TextEditingController(text: item.size ?? '');
    final fabricCtrl = TextEditingController(text: item.fabricComposition ?? '');
    final colorCtrl = TextEditingController(text: item.color);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Редагувати річ',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
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
                    final updated = ClothingItem(
                      id: item.id,
                      title: titleCtrl.text.trim().isNotEmpty ? titleCtrl.text.trim() : item.title,
                      brand: brandCtrl.text.trim().isNotEmpty ? brandCtrl.text.trim() : item.brand,
                      price: double.tryParse(priceCtrl.text.trim()) ?? item.price,
                      currency: item.currency,
                      imageUrl: item.imageUrl,
                      category: item.category,
                      season: item.season,
                      color: colorCtrl.text.trim().isNotEmpty ? colorCtrl.text.trim() : item.color,
                      size: sizeCtrl.text.trim().isNotEmpty ? sizeCtrl.text.trim() : item.size,
                      fabricComposition: fabricCtrl.text.trim().isNotEmpty ? fabricCtrl.text.trim() : item.fabricComposition,
                      countryOfOrigin: item.countryOfOrigin,
                      careInstructions: item.careInstructions,
                      storeName: item.storeName,
                      labelPhotoUrl: item.labelPhotoUrl,
                      receiptPhotoUrl: item.receiptPhotoUrl,
                      wearCount: item.wearCount,
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
      ),
    );
  }

  Widget _buildSpecItem(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
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
                  style: const TextStyle(fontSize: 10, color: AppTheme.muted, fontWeight: FontWeight.w600),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
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
                  color: AppTheme.border,
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
                  child: CachedNetworkImage(
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
                              style: const TextStyle(
                                color: AppTheme.muted,
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
                            constraints: const BoxConstraints(),
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
                      Row(
                        children: [
                          Text(
                            '${item.price.toStringAsFixed(0)} ${item.currency}',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.primary),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${item.wearCount} носінь',
                              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF92400E)),
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
            const Text(
              'ХАРАКТЕРИСТИКИ ТА ЕТИКЕТКА',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                color: AppTheme.muted,
              ),
            ),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              children: [
                _buildSpecItem(Icons.straighten_rounded, 'Розмір', item.size ?? 'EUR 38 / M'),
                _buildSpecItem(Icons.public_rounded, 'Походження', item.countryOfOrigin ?? 'Made in Portugal'),
                _buildSpecItem(Icons.texture_rounded, 'Склад тканини', item.fabricComposition ?? '100% Вовна'),
                _buildSpecItem(Icons.local_laundry_service_outlined, 'Правила догляду', item.careInstructions ?? 'Делікатне прання'),
                _buildSpecItem(Icons.palette_outlined, 'Колір & Сезон', '${item.color} · ${item.season.label}'),
                _buildSpecItem(Icons.storefront_outlined, 'Місце покупки', item.storeName ?? item.brand),
              ],
            ),
            const SizedBox(height: 14),

            // Photos from Tag & Receipt if present
            if (item.labelPhotoUrl != null || item.receiptPhotoUrl != null) ...[
              Row(
                children: [
                  const Text(
                    'ФОТО-ПІДТВЕРДЖЕННЯ: ',
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppTheme.muted),
                  ),
                  const Spacer(),
                  if (item.labelPhotoUrl != null)
                    InkWell(
                      onTap: () => _showImagePreview(context, item.labelPhotoUrl!, 'Фото етикетки'),
                      child: Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: const Row(
                          children: [
                            Text('🏷️', style: TextStyle(fontSize: 11)),
                            SizedBox(width: 4),
                            Text('Етикетка', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF166534))),
                          ],
                        ),
                      ),
                    ),
                  if (item.receiptPhotoUrl != null)
                    InkWell(
                      onTap: () => _showImagePreview(context, item.receiptPhotoUrl!, 'Фото чека'),
                      child: Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAF5FF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE9D5FF)),
                        ),
                        child: const Row(
                          children: [
                            Text('🧾', style: TextStyle(fontSize: 11)),
                            SizedBox(width: 4),
                            Text('Чек покупки', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF6B21A8))),
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
                color: const Color(0xFFF8F9FA),
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
                        'СИМУЛЯТОР ОКУПНОСТІ (CPW)',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                          color: AppTheme.accent,
                        ),
                      ),
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
                      Text(
                        'Зараз: ${item.costPerWear.toStringAsFixed(0)} ₴ / носіння',
                        style: const TextStyle(fontSize: 11, color: AppTheme.muted),
                      ),
                      Text(
                        'Прогноз: ${simulatedCPW.toStringAsFixed(0)} ₴ (-${percentSavings.toStringAsFixed(0)}%)',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF16A34A)),
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
                      backgroundColor: const Color(0xFFFFFBEB),
                    ),
                    icon: const Icon(Icons.face_retouching_natural_rounded, size: 17, color: Color(0xFFB45309)),
                    label: const Text('Приміряти (Virtual Try-On)', style: TextStyle(color: Color(0xFFB45309), fontSize: 12, fontWeight: FontWeight.w700)),
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
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                    label: const Text('Вдягнути (+1)'),
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
                  icon: const Icon(Icons.sell_outlined, size: 16),
                  label: const Text('Продати'),
                  onPressed: () => _showResaleDialog(context, item),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                  tooltip: 'Видалити',
                  onPressed: () {
                    context.read<WardrobeProvider>().removeItem(item.id);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Річ видалено з гардероба'),
                        behavior: SnackBarBehavior.floating,
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
