import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/clothing_item.dart';
import '../services/wardrobe_provider.dart';
import '../theme/app_theme.dart';
import 'purchase_advisor_screen.dart';
import 'brand_story_dialog.dart';

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
            icon: const Icon(Icons.shield_outlined, color: AppTheme.accent),
            tooltip: 'Should I Buy This? (Радник)',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PurchaseAdvisorScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Скинути фільтри або завантажити демо',
            onPressed: () {
              context.read<WardrobeProvider>().setCategoryFilter(null);
              context.read<WardrobeProvider>().setSearchQuery('');
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

                const SliverToBoxAdapter(child: SizedBox(height: 10)),

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
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.search_off_rounded, size: 54, color: AppTheme.muted),
                                  SizedBox(height: 12),
                                  Text(
                                    'Нічого не знайдено',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'Спробуйте змінити фільтри або пошуковий запит',
                                    style: TextStyle(color: AppTheme.muted, fontSize: 13),
                                  ),
                                ],
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

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final simulatedWears = item.wearCount + _extraWears.round();
    final simulatedCPW = simulatedWears > 0 ? (item.price / simulatedWears) : item.price;
    final percentSavings = item.costPerWear > 0 ? (((item.costPerWear - simulatedCPW) / item.costPerWear) * 100) : 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
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
          const SizedBox(height: 16),
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
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.brand.toUpperCase(),
                      style: const TextStyle(
                        color: AppTheme.muted,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Ціна: ${item.price.toStringAsFixed(0)} ${item.currency}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    if (item.fabricComposition != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Тканина: ${item.fabricComposition}',
                        style: const TextStyle(color: AppTheme.muted, fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

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
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: const Text('Вдягнути сьогодні (+1)'),
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
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
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
    );
  }
}
