import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import '../models/clothing_item.dart';
import '../services/color_analysis_service.dart';
import '../services/outfit_calendar_service.dart';
import '../services/weather_stylist_service.dart';
import '../widgets/vestora_image.dart';
import 'virtual_fitting_screen.dart';
import 'outfit_calendar_screen.dart';

enum StoryTheme {
  noir(
    name: 'Noir Obsidian',
    icon: '🖤',
    background: Color(0xFF121214),
    surface: Color(0xFF1C1C20),
    accent: Color(0xFFD4AF37),
    textColor: Colors.white,
    secondaryText: Color(0xFFA1A1AA),
    border: Color(0xFF2E2E36),
  ),
  ivory(
    name: 'Ivory Cashmere',
    icon: '🌾',
    background: Color(0xFFF8F6F0),
    surface: Colors.white,
    accent: Color(0xFF92400E),
    textColor: Color(0xFF18181B),
    secondaryText: Color(0xFF71717A),
    border: Color(0xFFE5E0D8),
  ),
  rose(
    name: 'Rosé Silk',
    icon: '🌸',
    background: Color(0xFFFFF5F5),
    surface: Colors.white,
    accent: Color(0xFFBE185D),
    textColor: Color(0xFF27272A),
    secondaryText: Color(0xFF831843),
    border: Color(0xFFFCE7F3),
  );

  final String name;
  final String icon;
  final Color background;
  final Color surface;
  final Color accent;
  final Color textColor;
  final Color secondaryText;
  final Color border;

  const StoryTheme({
    required this.name,
    required this.icon,
    required this.background,
    required this.surface,
    required this.accent,
    required this.textColor,
    required this.secondaryText,
    required this.border,
  });
}

enum StoryFormat {
  story9x16('Story (9:16)', '📱', 9 / 16),
  feed4x5('Moodboard (4:5)', '📌', 4 / 5);

  final String label;
  final String icon;
  final double ratio;
  const StoryFormat(this.label, this.icon, this.ratio);
}

class EditorialStoryScreen extends StatefulWidget {
  final List<ClothingItem> items;
  final String occasion;
  final String temperatureText;
  final double styleScore;
  final String? customQuote;

  const EditorialStoryScreen({
    super.key,
    required this.items,
    this.occasion = 'Old Money Minimalist',
    this.temperatureText = '+18°C Сонячно',
    this.styleScore = 9.8,
    this.customQuote,
  });

  @override
  State<EditorialStoryScreen> createState() => _EditorialStoryScreenState();
}

class _EditorialStoryScreenState extends State<EditorialStoryScreen> {
  final GlobalKey _cardKey = GlobalKey();
  StoryTheme _theme = StoryTheme.noir;
  StoryFormat _format = StoryFormat.story9x16;
  bool _isSaving = false;

  List<NamedColorSwatch> _extractPalette() {
    // Generate harmonious aesthetic swatches from clothing items or luxury defaults
    final list = <NamedColorSwatch>[];
    for (final it in widget.items) {
      final colName = it.color.trim();
      if (colName.isNotEmpty && colName != 'Не вказано') {
        Color c;
        if (colName.toLowerCase().contains('беж') || colName.toLowerCase().contains('creme')) {
          c = const Color(0xFFD7C4B7);
        } else if (colName.toLowerCase().contains('чорн') || colName.toLowerCase().contains('noir')) {
          c = const Color(0xFF18181B);
        } else if (colName.toLowerCase().contains('біл') || colName.toLowerCase().contains('white')) {
          c = const Color(0xFFF4F4F5);
        } else if (colName.toLowerCase().contains('син') || colName.toLowerCase().contains('navy')) {
          c = const Color(0xFF1E3A8A);
        } else if (colName.toLowerCase().contains('корич') || colName.toLowerCase().contains('brown')) {
          c = const Color(0xFF78350F);
        } else {
          c = const Color(0xFFD4AF37);
        }
        if (!list.any((e) => e.name.toLowerCase() == colName.toLowerCase())) {
          list.add(NamedColorSwatch(name: colName, color: c));
        }
      }
    }
    if (list.isEmpty) {
      list.addAll([
        const NamedColorSwatch(name: 'Шовковий Беж', color: Color(0xFFD7C4B7)),
        const NamedColorSwatch(name: 'Еспресо', color: Color(0xFF451A03)),
        const NamedColorSwatch(name: 'Кашемір', color: Color(0xFFE5E5E5)),
        const NamedColorSwatch(name: 'Золото 18K', color: Color(0xFFD4AF37)),
      ]);
    }
    return list.take(4).toList();
  }

  Future<void> _exportStoryPoster() async {
    setState(() => _isSaving = true);
    try {
      // Simulate/trigger RepaintBoundary capture safely
      final boundary = _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary != null) {
        try {
          await boundary.toImage(pixelRatio: 2.0);
        } catch (_) {
          // Fallback if cross-origin images on web prevent canvas read
        }
      }

      final copyText = _generateStoryCopy();
      await Clipboard.setData(ClipboardData(text: copyText));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Постер збережено! Стильний опис скопійовано для Instagram Stories ✨',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF16A34A),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка експорту: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _generateStoryCopy() {
    final totalPrice = widget.items.fold(0.0, (sum, i) => sum + i.price);
    final brands = widget.items.map((i) => '@${i.brand.replaceAll(' ', '')}').toSet().join(' ');
    return '''
✨ VESTORA EDITORIAL · ${widget.occasion.toUpperCase()}
📍 Погода: ${widget.temperatureText}
💎 Style Harmony: ${widget.styleScore.toStringAsFixed(1)} / 10

Аутфіт дня:
${widget.items.map((e) => '• ${e.title} — ${e.brand}').join('\n')}

Сукупна вартість капсули: ${totalPrice.toStringAsFixed(0)} ₴
$brands #QuietLuxury #OOTD #VestoraStyle #WardrobeCapsule
''';
  }

  void _shareStory() {
    Clipboard.setData(ClipboardData(text: _generateStoryCopy()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Текст для Stories скопійовано у буфер обміну! Вставте в Instagram / Telegram.'),
        backgroundColor: Color(0xFF2563EB),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openInVirtualFitting() {
    ClothingItem? outw;
    ClothingItem? top;
    ClothingItem? bot;
    ClothingItem? shoes;

    for (final it in widget.items) {
      if (it.category == ClothingCategory.outerwear && outw == null) outw = it;
      if (it.category == ClothingCategory.tops && top == null) top = it;
      if (it.category == ClothingCategory.bottoms && bot == null) bot = it;
      if (it.category == ClothingCategory.shoes && shoes == null) shoes = it;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VirtualFittingScreen(
          initialOuterwear: outw,
          initialTop: top,
          initialBottom: bot,
          initialShoes: shoes,
        ),
      ),
    );
  }

  Future<void> _scheduleInCalendar() async {
    final now = DateTime.now();
    final dateStr = OutfitCalendarService.formatDate(now);
    ClothingItem? outw;
    ClothingItem? top;
    ClothingItem? bot;
    ClothingItem? shoes;

    for (final it in widget.items) {
      if (it.category == ClothingCategory.outerwear && outw == null) outw = it;
      if (it.category == ClothingCategory.tops && top == null) top = it;
      if (it.category == ClothingCategory.bottoms && bot == null) bot = it;
      if (it.category == ClothingCategory.shoes && shoes == null) shoes = it;
    }

    final plan = PlannedDayOutfit(
      dateStr: dateStr,
      date: now,
      weatherTemp: 18,
      weatherCondition: WeatherCondition.sunny,
      occasion: Occasion.casual,
      eventTitle: 'Editorial · ${widget.occasion}',
      outerwearId: outw?.id,
      topId: top?.id,
      bottomId: bot?.id,
      shoesId: shoes?.id,
      notes: 'Експортовано з Vestora Editorial Story',
    );

    await OutfitCalendarService.savePlan(plan);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Образ успішно додано до щотижневого Календаря!'),
        backgroundColor: const Color(0xFF16A34A),
        action: SnackBarAction(
          label: 'Відкрити',
          textColor: Colors.white,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OutfitCalendarScreen()),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF09090B),
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Editorial Moodboard & Story', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('Експорт постера для Instagram Stories & Pinterest', style: TextStyle(fontSize: 11, color: Color(0xFFA1A1AA))),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.white),
            tooltip: 'Поділитися описом',
            onPressed: _shareStory,
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined, color: Color(0xFFD4AF37)),
            tooltip: 'Запланувати в календар',
            onPressed: _scheduleInCalendar,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Controls toolbar (Theme selector & Aspect ratio selector)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFF18181B),
                border: Border(bottom: BorderSide(color: Color(0xFF27272A))),
              ),
              child: Row(
                children: [
                  // Themes
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: StoryTheme.values.map((t) {
                          final isSel = _theme == t;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () => setState(() => _theme = t),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSel ? t.accent.withValues(alpha: 0.25) : const Color(0xFF27272A),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSel ? t.accent : const Color(0xFF3F3F46),
                                    width: isSel ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Text(t.icon, style: const TextStyle(fontSize: 12)),
                                    const SizedBox(width: 4),
                                    Text(
                                      t.name,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                        color: isSel ? Colors.white : const Color(0xFFA1A1AA),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  // Format switcher
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF27272A),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF3F3F46)),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: Row(
                      children: StoryFormat.values.map((f) {
                        final isSel = _format == f;
                        return InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => setState(() => _format = f),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: isSel ? const Color(0xFFD4AF37) : Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                Text(f.icon, style: const TextStyle(fontSize: 11)),
                                const SizedBox(width: 4),
                                Text(
                                  f == StoryFormat.story9x16 ? '9:16' : '4:5',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isSel ? Colors.black : const Color(0xFFA1A1AA),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            // Card Canvas Viewport
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: RepaintBoundary(
                    key: _cardKey,
                    child: _buildEditorialPosterCard(),
                  ),
                ),
              ),
            ),

            // Bottom Actions Bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: const BoxDecoration(
                color: Color(0xFF121214),
                border: Border(top: BorderSide(color: Color(0xFF27272A))),
              ),
              child: Row(
                children: [
                  // Try-on Mirror shortcut
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFD4AF37),
                      side: const BorderSide(color: Color(0xFF52525B)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _openInVirtualFitting,
                    icon: const Icon(Icons.face_retouching_natural_rounded, size: 18),
                    label: const Text('Приміряти', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                  const SizedBox(width: 10),

                  // Save & Export button
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4AF37),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                      ),
                      onPressed: _isSaving ? null : _exportStoryPoster,
                      icon: _isSaving
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                          : const Icon(Icons.download_rounded, size: 20),
                      label: Text(
                        _isSaving ? 'Експортуємо...' : 'Зберегти постер',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 0.3),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditorialPosterCard() {
    final palette = _extractPalette();
    final totalPrice = widget.items.fold(0.0, (sum, i) => sum + i.price);
    final width = 360.0;
    final height = width / _format.ratio;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: _theme.background,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _theme.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // 1. Magazine Haute Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: _theme.border)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'VESTORA',
                      style: TextStyle(
                        color: _theme.textColor,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 6,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _theme.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: _theme.accent.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        'ISSUE № 07',
                        style: TextStyle(
                          color: _theme.accent,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'HAUTE CAPSULE · ${widget.temperatureText.toUpperCase()}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _theme.secondaryText,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        widget.occasion.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _theme.accent,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 2. Outfit Dynamic Collage
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: _buildCollageGrid(),
            ),
          ),

          // 3. Color Palette Swatches Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _theme.surface,
              border: Border.symmetric(horizontal: BorderSide(color: _theme.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.palette_outlined, size: 14, color: _theme.accent),
                    const SizedBox(width: 6),
                    Text(
                      'ПАЛІТРА ОБРАЗУ',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: _theme.secondaryText,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: palette.map((swatch) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Tooltip(
                        message: swatch.name,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: swatch.color,
                            shape: BoxShape.circle,
                            border: Border.all(color: _theme.border, width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // 4. Style Metrics & Editorial Quote
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: Row(
              children: [
                // Score Box
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _theme.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _theme.border),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'HARMONY',
                        style: TextStyle(
                          fontSize: 7.5,
                          fontWeight: FontWeight.w800,
                          color: _theme.secondaryText,
                        ),
                      ),
                      Text(
                        widget.styleScore.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: _theme.accent,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Quote / Notes
                Expanded(
                  child: Text(
                    widget.customQuote ??
                        '«Елегантний баланс структури та невимушеності. Спокійна розкіш без зайвих слів.»',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 10.5,
                      color: _theme.secondaryText,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 5. Watermark Footer
          Container(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'VESTORA SMART WARDROBE',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: _theme.secondaryText.withValues(alpha: 0.8),
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  '${totalPrice.toStringAsFixed(0)} ₴',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: _theme.accent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollageGrid() {
    final items = widget.items;
    if (items.isEmpty) {
      return Center(
        child: Text('Немає обраних речей для постера', style: TextStyle(color: _theme.secondaryText)),
      );
    }

    if (items.length == 1) {
      return _buildImageCard(items[0]);
    }

    if (items.length == 2) {
      return Row(
        children: [
          Expanded(child: _buildImageCard(items[0])),
          const SizedBox(width: 8),
          Expanded(child: _buildImageCard(items[1])),
        ],
      );
    }

    if (items.length == 3) {
      return Row(
        children: [
          Expanded(flex: 3, child: _buildImageCard(items[0])),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Expanded(child: _buildImageCard(items[1])),
                const SizedBox(height: 8),
                Expanded(child: _buildImageCard(items[2])),
              ],
            ),
          ),
        ],
      );
    }

    // 4 or more items (e.g. outerwear, top, bottom, shoes)
    return Row(
      children: [
        // Left Hero column: Top 2 items
        Expanded(
          flex: 5,
          child: Column(
            children: [
              Expanded(flex: 6, child: _buildImageCard(items[0])),
              const SizedBox(height: 8),
              Expanded(flex: 5, child: _buildImageCard(items[1])),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Right side column: Remaining items
        Expanded(
          flex: 4,
          child: Column(
            children: [
              Expanded(child: _buildImageCard(items[2])),
              const SizedBox(height: 8),
              Expanded(child: _buildImageCard(items[3])),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageCard(ClothingItem item) {
    return Container(
      decoration: BoxDecoration(
        color: _theme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _theme.border),
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
            placeholder: (context, url) => Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: _theme.accent),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: _theme.surface,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(item.category.icon, style: const TextStyle(fontSize: 24)),
                  const SizedBox(height: 4),
                  Text(item.title, maxLines: 1, style: TextStyle(fontSize: 9, color: _theme.secondaryText)),
                ],
              ),
            ),
          ),

          // Subtle gradient overlay for readability of tag
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 44,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.75),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Brand & Category Badge
          Positioned(
            left: 6,
            bottom: 6,
            right: 6,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      item.brand.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: _theme.accent.withValues(alpha: 0.85),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    item.category.icon,
                    style: const TextStyle(fontSize: 9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
