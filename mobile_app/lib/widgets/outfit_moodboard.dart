import 'package:flutter/material.dart';
import '../models/clothing_item.dart';
import '../theme/app_theme.dart';
import 'vestora_image.dart';

class OutfitMoodboardWidget extends StatelessWidget {
  final ClothingItem? outerwear;
  final ClothingItem? top;
  final ClothingItem? bottom;
  final ClothingItem? shoes;
  final VoidCallback? onShuffle;
  final Function(ClothingCategory)? onSelectCategory;

  const OutfitMoodboardWidget({
    super.key,
    this.outerwear,
    this.top,
    this.bottom,
    this.shoes,
    this.onShuffle,
    this.onSelectCategory,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F6),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar with Luxury Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'VESTORA EDITORIAL',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'КАПСУЛЬНИЙ КОЛАЖ',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.muted,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
              if (onShuffle != null)
                IconButton(
                  icon: const Icon(Icons.shuffle_rounded, size: 20, color: AppTheme.primary),
                  tooltip: 'Shuffle',
                  onPressed: onShuffle,
                ),
            ],
          ),
          const SizedBox(height: 14),

          // 2-Column Responsive Fashion Grid
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column: Outerwear + Bottoms
              Expanded(
                child: Column(
                  children: [
                    _buildCollageCard(
                      item: outerwear,
                      category: ClothingCategory.outerwear,
                      label: 'Верхній одяг',
                      height: 165,
                    ),
                    const SizedBox(height: 12),
                    _buildCollageCard(
                      item: bottom,
                      category: ClothingCategory.bottoms,
                      label: 'Низ / Брюки',
                      height: 175,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Right Column: Top + Shoes
              Expanded(
                child: Column(
                  children: [
                    _buildCollageCard(
                      item: top,
                      category: ClothingCategory.tops,
                      label: 'Верх / Топ',
                      height: 175,
                    ),
                    const SizedBox(height: 12),
                    _buildCollageCard(
                      item: shoes,
                      category: ClothingCategory.shoes,
                      label: 'Взуття',
                      height: 165,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCollageCard({
    required ClothingItem? item,
    required ClothingCategory category,
    required String label,
    required double height,
  }) {
    if (item == null) {
      return InkWell(
        onTap: () => onSelectCategory?.call(category),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.border, style: BorderStyle.solid),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF4F4F5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add_rounded, size: 20, color: AppTheme.muted),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.muted),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return InkWell(
      onTap: () => onSelectCategory?.call(category),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            VestoraImage(
              imageUrl: item.imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              placeholder: (context, url) => Container(color: const Color(0xFFF4F4F5)),
              errorWidget: (context, url, error) => Container(
                color: const Color(0xFFF4F4F5),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(category.icon, style: const TextStyle(fontSize: 28)),
                      const SizedBox(height: 4),
                      Text(item.brand, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ),

            // Luxury Dark Acrylic Brand Tag Pill
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${item.brand.toUpperCase()} · ${item.color}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.swap_horiz_rounded, size: 12, color: Colors.white70),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
