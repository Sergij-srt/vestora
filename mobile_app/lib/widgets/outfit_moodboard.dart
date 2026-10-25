import 'package:flutter/material.dart';
import '../models/clothing_item.dart';
import '../services/localization_service.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : const Color(0xFFF4F4F6),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.border),
        boxShadow: isDark ? AppTheme.darkSoftShadow : AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar with Luxury Badge (320px overflow-safe)
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkAccent : AppTheme.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        context.tr('stylist_editorial_badge'),
                        style: TextStyle(
                          color: isDark ? Colors.black : Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                    Text(
                      context.tr('stylist_moodboard_sub'),
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppTheme.darkMuted : AppTheme.muted,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
              if (onShuffle != null)
                IconButton(
                  icon: Icon(
                    Icons.shuffle_rounded,
                    size: 20,
                    color: isDark ? AppTheme.darkText : AppTheme.primary,
                  ),
                  tooltip: context.tr('stylist_shuffle'),
                  onPressed: onShuffle,
                ),
            ],
          ),
          const SizedBox(height: 14),

          // 2-Column Responsive Fashion Grid
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    _buildCollageCard(
                      context: context,
                      isDark: isDark,
                      item: outerwear,
                      category: ClothingCategory.outerwear,
                      label: 'Верхній одяг',
                      height: 165,
                    ),
                    const SizedBox(height: 12),
                    _buildCollageCard(
                      context: context,
                      isDark: isDark,
                      item: bottom,
                      category: ClothingCategory.bottoms,
                      label: 'Низ / Брюки',
                      height: 175,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    _buildCollageCard(
                      context: context,
                      isDark: isDark,
                      item: top,
                      category: ClothingCategory.tops,
                      label: 'Верх / Топ',
                      height: 175,
                    ),
                    const SizedBox(height: 12),
                    _buildCollageCard(
                      context: context,
                      isDark: isDark,
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
    required BuildContext context,
    required bool isDark,
    required ClothingItem? item,
    required ClothingCategory category,
    required String label,
    required double height,
  }) {
    final cardSurface = isDark ? AppTheme.darkCard : Colors.white;
    final emptyCircleBg = isDark ? AppTheme.darkSurface : const Color(0xFFF4F4F5);
    final mutedText = isDark ? AppTheme.darkMuted : AppTheme.muted;

    if (item == null) {
      return Semantics(
        button: true,
        label: 'Обрати $label',
        child: InkWell(
          onTap: () => onSelectCategory?.call(category),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            height: height,
            width: double.infinity,
            decoration: BoxDecoration(
              color: cardSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? AppTheme.darkBorder : AppTheme.border,
                style: BorderStyle.solid,
              ),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: emptyCircleBg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.add_rounded, size: 20, color: mutedText),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: mutedText),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Semantics(
      button: true,
      label: '${item.brand} ${item.title}',
      child: InkWell(
        onTap: () => onSelectCategory?.call(category),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: cardSurface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
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
                width: 240,
                height: height,
                semanticLabel: item.title,
                placeholder: (context, url) => Container(color: emptyCircleBg),
                errorWidget: (context, url, error) => Container(
                  color: emptyCircleBg,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(category.icon, style: const TextStyle(fontSize: 28)),
                        const SizedBox(height: 4),
                        Text(
                          item.brand,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.76),
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
      ),
    );
  }
}
