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
            tooltip: 'Скинути фільтри',
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
                // Top Summary Card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF18181B), Color(0xFF27272A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ВАШ ЦИФРОВИЙ ГАРДЕРОБ',
                                style: TextStyle(
                                  color: Color(0xFFA1A1AA),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${wardrobe.totalItemsCount} речей',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'ОЦІНКА ВАРТОСТІ',
                                style: TextStyle(
                                  color: Color(0xFFA1A1AA),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${wardrobe.totalWardrobeValue.toStringAsFixed(0)} ₴',
                                style: const TextStyle(
                                  color: Color(0xFFFBBF24),
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Search Bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

                // "Should I Buy This?" Quick Advisor Banner
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PurchaseAdvisorScreen()),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(12),
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

                // Category Filter Pills
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

                const SliverToBoxAdapter(child: SizedBox(height: 12)),

                // Grid of Clothing Items
                wardrobe.filteredItems.isEmpty
                    ? SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.checkroom_outlined, size: 64, color: AppTheme.muted),
                              SizedBox(height: 12),
                              Text(
                                'Нічого не знайдено',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Спробуйте іншу категорію або додайте нову річ',
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
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: item.imageUrl,
                      width: 90,
                      height: 110,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.brand,
                          style: const TextStyle(
                            color: AppTheme.muted,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ціна: ${item.price.toStringAsFixed(0)} ${item.currency}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Cost-Per-Wear: ${item.costPerWear.toStringAsFixed(0)} ₴ / носіння',
                          style: const TextStyle(
                            color: AppTheme.accent,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle_outline_rounded),
                      label: const Text('Вдягнути сьогодні (+1)'),
                      onPressed: () {
                        context.read<WardrobeProvider>().recordWear(item.id);
                        Navigator.pop(bottomSheetContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Образ зараховано для "${item.title}"!')),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                    onPressed: () {
                      context.read<WardrobeProvider>().removeItem(item.id);
                      Navigator.pop(bottomSheetContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Річ видалено з гардероба')),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
