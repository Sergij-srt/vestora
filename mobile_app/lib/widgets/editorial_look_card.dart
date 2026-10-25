import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/clothing_item.dart';
import 'vestora_image.dart';

void showEditorialLookDialog(
  BuildContext context, {
  required List<ClothingItem> items,
  required String occasion,
  required String temperatureText,
  required double styleScore,
}) {
  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: EditorialLookCard(
        items: items,
        occasion: occasion,
        temperatureText: temperatureText,
        styleScore: styleScore,
      ),
    ),
  );
}

class EditorialLookCard extends StatelessWidget {
  final List<ClothingItem> items;
  final String occasion;
  final String temperatureText;
  final double styleScore;

  const EditorialLookCard({
    super.key,
    required this.items,
    required this.occasion,
    required this.temperatureText,
    required this.styleScore,
  });

  @override
  Widget build(BuildContext context) {
    final totalPrice = items.fold(0.0, (sum, i) => sum + i.price);

    return Container(
      width: 400,
      decoration: BoxDecoration(
        color: const Color(0xFF121214), // Midnight Obsidian
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF3F3F46), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Magazine Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF27272A))),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Flexible(
                      child: Text(
                        'VESTORA',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Закрити',
                      icon: const Icon(Icons.close, color: Color(0xFFA1A1AA), size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'DAILY EDITORIAL · $temperatureText',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFD4D4D8),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        occasion.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          color: Color(0xFFFDE68A),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Visual Look Grid (2-column magazine spread)
          Container(
            height: 260,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Left Column: First 1 or 2 items
                Expanded(
                  flex: 3,
                  child: items.isNotEmpty
                      ? _buildImageTile(items[0], isLarge: true)
                      : const SizedBox(),
                ),
                const SizedBox(width: 8),
                // Right Column: Remaining items
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      if (items.length > 1)
                        Expanded(child: _buildImageTile(items[1])),
                      if (items.length > 2) ...[
                        const SizedBox(height: 8),
                        Expanded(child: _buildImageTile(items[2])),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Style Score & Details Seal
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E24),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF3F3F46)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFB45309),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'STYLE CHECK RATIO',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 9, fontWeight: FontWeight.w700),
                              ),
                              Text(
                                '${styleScore.toStringAsFixed(1)} / 10 · Бездоганно',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'ВАРТІСТЬ ЛУКУ',
                        style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 9, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${totalPrice.toStringAsFixed(0)} ₴',
                        style: const TextStyle(color: Color(0xFFFDE68A), fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Tagged Brands Strip
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: items.map((it) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF27272A),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${it.brand} · ${it.title}',
                    style: const TextStyle(color: Color(0xFFE4E4E7), fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                );
              }).toList(),
            ),
          ),

          // Footer Action: Copy / Share
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF18181B),
              border: Border(top: BorderSide(color: Color(0xFF27272A))),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  final text = '''
✨ VESTORA EDITORIAL LOOK · $temperatureText
📍 Привід: $occasion
💎 Оцінка стиліста: ${styleScore.toStringAsFixed(1)}/10

Елементи луку:
${items.map((e) => '• ${e.title} від ${e.brand} (${e.price.toStringAsFixed(0)} ₴)').join('\n')}

Сукупна вартість: ${totalPrice.toStringAsFixed(0)} ₴
Створено у розумному гардеробі Vestora.
''';
                  Clipboard.setData(ClipboardData(text: text));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Журнальний лук скопійовано! Вставте в Instagram Stories або Telegram.'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Color(0xFF16A34A),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD97706),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.share_rounded, size: 18),
                label: const Text('Поділитися для Instagram / Stories', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageTile(ClothingItem item, {bool isLarge = false}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF27272A),
        borderRadius: BorderRadius.circular(14),
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
            placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.white30),
          ),
          Positioned(
            bottom: 6,
            left: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                item.brand.toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.w800, letterSpacing: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
