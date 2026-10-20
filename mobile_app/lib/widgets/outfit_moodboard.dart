import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/clothing_item.dart';
import '../theme/app_theme.dart';

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
      height: 420,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.softShadow,
      ),
      child: Stack(
        children: [
          // Subtle background grid watermark
          Positioned(
            top: 16,
            left: 20,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'VESTORA MOODBOARD',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'КАПСУЛЬНИЙ КОЛАЖ',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.muted.withValues(alpha: 0.8),
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),

          // 1. Outerwear (Top-Left Layer)
          Positioned(
            top: 55,
            left: 20,
            width: 155,
            height: 175,
            child: _buildMoodboardItem(
              item: outerwear,
              category: ClothingCategory.outerwear,
              label: 'Верхній одяг',
            ),
          ),

          // 2. Top / Shirt (Top-Right Layer)
          Positioned(
            top: 65,
            right: 20,
            width: 155,
            height: 165,
            child: _buildMoodboardItem(
              item: top,
              category: ClothingCategory.tops,
              label: 'Верх / Топ',
            ),
          ),

          // 3. Bottoms (Bottom-Left Layer)
          Positioned(
            bottom: 20,
            left: 25,
            width: 150,
            height: 170,
            child: _buildMoodboardItem(
              item: bottom,
              category: ClothingCategory.bottoms,
              label: 'Низ / Брюки',
            ),
          ),

          // 4. Shoes (Bottom-Right Layer)
          Positioned(
            bottom: 20,
            right: 20,
            width: 155,
            height: 155,
            child: _buildMoodboardItem(
              item: shoes,
              category: ClothingCategory.shoes,
              label: 'Взуття',
            ),
          ),

          // Center Aesthetic Sticker Pin
          Center(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: const Icon(Icons.auto_awesome, size: 16, color: AppTheme.accent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodboardItem({
    required ClothingItem? item,
    required ClothingCategory category,
    required String label,
  }) {
    if (item == null) {
      return InkWell(
        onTap: () => onSelectCategory?.call(category),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.border,
              style: BorderStyle.solid,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, size: 24, color: AppTheme.muted.withValues(alpha: 0.6)),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.muted),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return InkWell(
      onTap: () => onSelectCategory?.call(category),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: CachedNetworkImage(
                imageUrl: item.imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorWidget: (context, url, error) => const Center(child: Icon(Icons.broken_image, color: AppTheme.muted)),
              ),
            ),
            // Floating brand badge tag
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${item.brand.toUpperCase()} · ${item.color}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
