import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/clothing_item.dart';
import '../services/wardrobe_provider.dart';
import '../services/weather_stylist_service.dart';
import '../services/style_check_service.dart';
import '../widgets/outfit_moodboard.dart';
import '../theme/app_theme.dart';

class OutfitBuilderScreen extends StatefulWidget {
  const OutfitBuilderScreen({super.key});

  @override
  State<OutfitBuilderScreen> createState() => _OutfitBuilderScreenState();
}

class _OutfitBuilderScreenState extends State<OutfitBuilderScreen> {
  ClothingItem? _selectedOuterwear;
  ClothingItem? _selectedTop;
  ClothingItem? _selectedBottom;
  ClothingItem? _selectedShoes;

  // Modern UI & View toggles
  bool _isMoodboardMode = true;
  final TextEditingController _promptController = TextEditingController();

  // Weather & Context settings
  final WeatherCondition _weatherCondition = WeatherCondition.cloudy;
  final Occasion _occasion = Occasion.casual;
  final int _temperature = 16;
  CuratedDailyOutfit? _lastCurated;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _curateWithAI();
    });
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  List<ClothingItem> get _currentOutfitItems {
    final list = <ClothingItem>[];
    if (_selectedOuterwear != null) list.add(_selectedOuterwear!);
    if (_selectedTop != null) list.add(_selectedTop!);
    if (_selectedBottom != null) list.add(_selectedBottom!);
    if (_selectedShoes != null) list.add(_selectedShoes!);
    return list;
  }

  void _curateWithAI() {
    final wardrobe = context.read<WardrobeProvider>();
    if (wardrobe.items.isEmpty) return;

    final curated = WeatherStylistService.curateOutfit(
      wardrobe: wardrobe.items,
      temperatureCelsius: _temperature,
      condition: _weatherCondition,
      occasion: _occasion,
    );

    setState(() {
      _lastCurated = curated;
      _selectedOuterwear = curated.outerwear;
      _selectedTop = curated.top;
      _selectedBottom = curated.bottom;
      _selectedShoes = curated.shoes;
    });
  }

  void _curateWithNaturalPrompt(String prompt) {
    if (prompt.trim().isEmpty) return;
    final wardrobe = context.read<WardrobeProvider>();
    if (wardrobe.items.isEmpty) return;

    final curated = WeatherStylistService.curateByNaturalPrompt(
      prompt: prompt,
      wardrobe: wardrobe.items,
    );

    setState(() {
      _lastCurated = curated;
      _selectedOuterwear = curated.outerwear;
      _selectedTop = curated.top;
      _selectedBottom = curated.bottom;
      _selectedShoes = curated.shoes;
    });

    FocusScope.of(context).unfocus();
  }

  void _randomizeOutfit() {
    final wardrobe = context.read<WardrobeProvider>();
    final random = Random();

    T? pickRandom<T>(List<T> list) {
      if (list.isEmpty) return null;
      return list[random.nextInt(list.length)];
    }

    final outerwears = wardrobe.items.where((i) => i.category == ClothingCategory.outerwear).toList();
    final tops = wardrobe.items.where((i) => i.category == ClothingCategory.tops).toList();
    final bottoms = wardrobe.items.where((i) => i.category == ClothingCategory.bottoms).toList();
    final shoes = wardrobe.items.where((i) => i.category == ClothingCategory.shoes).toList();

    setState(() {
      _selectedOuterwear = pickRandom(outerwears);
      _selectedTop = pickRandom(tops);
      _selectedBottom = pickRandom(bottoms);
      _selectedShoes = pickRandom(shoes);
      _lastCurated = null;
    });
  }

  void _wearThisOutfit() {
    final wardrobe = context.read<WardrobeProvider>();
    final currentOutfit = _currentOutfitItems;

    if (currentOutfit.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Оберіть хоча б одну річ для образу'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    wardrobe.recordOutfitWear(currentOutfit);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('🔥', style: TextStyle(fontSize: 32)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Стрік збільшено до ${wardrobe.streakDays} днів!',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Оновлено дані для ${currentOutfit.length} речей. Коефіцієнт Cost-Per-Wear успішно оптимізовано.',
                style: const TextStyle(color: AppTheme.muted, fontSize: 13, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Чудово'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showStyleCheckDialog() {
    final items = _currentOutfitItems;
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Складіть спочатку образ для оцінки'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final eval = StyleCheckService.evaluateOutfit(outfitItems: items);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
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
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.auto_awesome, color: AppTheme.accent, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Дзеркало ШІ · Style Check',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          eval.verdict,
                          style: const TextStyle(fontSize: 12, color: AppTheme.accent, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      '${eval.overallScore}/10',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _buildMetricBar('Гармонія кольорів', eval.colorHarmonyScore, const Color(0xFF2563EB)),
              const SizedBox(height: 10),
              _buildMetricBar('Баланс пропорцій', eval.proportionScore, const Color(0xFF16A34A)),

              const SizedBox(height: 16),
              const Divider(color: AppTheme.border),
              const SizedBox(height: 12),

              ...eval.positiveHighlights.map((hl) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_outline, color: Color(0xFF16A34A), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(hl, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                  )),

              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_outline, size: 20, color: AppTheme.accent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        eval.actionableTip,
                        style: const TextStyle(fontSize: 12, color: AppTheme.secondary, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Зрозуміло'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricBar(String label, int value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            Text('$value%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: value / 100.0,
          backgroundColor: AppTheme.background,
          valueColor: AlwaysStoppedAnimation(color),
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final wardrobe = context.watch<WardrobeProvider>();

    if (wardrobe.items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('AI Стиліст Vestora')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.style_outlined, size: 64, color: AppTheme.muted),
                const SizedBox(height: 16),
                const Text(
                  'Додайте спочатку декілька речей у гардероб',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Або завантажте готову демо-капсулу на головному екрані',
                  style: TextStyle(fontSize: 13, color: AppTheme.muted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    context.read<WardrobeProvider>().loadDemoCapsule();
                  },
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Завантажити демо-капсулу'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Стиліст Vestora'),
        actions: [
          // View mode toggle button
          IconButton(
            icon: Icon(_isMoodboardMode ? Icons.view_agenda_outlined : Icons.dashboard_outlined),
            tooltip: _isMoodboardMode ? 'Перемкнути на слоти' : 'Перемкнути на колаж',
            onPressed: () => setState(() => _isMoodboardMode = !_isMoodboardMode),
          ),
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: AppTheme.accent),
            tooltip: 'Оцінити стиль образу (Style Check)',
            onPressed: _showStyleCheckDialog,
          ),
          IconButton(
            icon: const Icon(Icons.shuffle_rounded),
            tooltip: 'Згенерувати випадковий образ',
            onPressed: _randomizeOutfit,
          ),
        ],
      ),
      body: Column(
        children: [
          // Natural Language AI Prompt & Context Bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            color: Colors.white,
            child: Column(
              children: [
                // Natural Language Search Bar
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _promptController,
                        onSubmitted: _curateWithNaturalPrompt,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Запитайте ШІ: "Ділова зустріч у дощ"...',
                          hintStyle: const TextStyle(fontSize: 12, color: AppTheme.muted),
                          prefixIcon: const Icon(Icons.auto_awesome, size: 18, color: AppTheme.accent),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          filled: true,
                          fillColor: const Color(0xFFF8F9FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.border),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _curateWithNaturalPrompt(_promptController.text),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Icon(Icons.send_rounded, size: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Quick Prompt Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildQuickPromptChip('🌧️ Дощовий офіс'),
                      _buildQuickPromptChip('☕ Затишна кав\'ярня'),
                      _buildQuickPromptChip('✨ Вечірнє побачення'),
                      _buildQuickPromptChip('🏃 Спортивний вихід'),
                    ],
                  ),
                ),

                if (_lastCurated != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(Icons.auto_awesome, size: 15, color: AppTheme.accent),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${_lastCurated!.weatherRationale} ${_lastCurated!.occasionRationale}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppTheme.secondary,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.border),

          // Main View: Moodboard Canvas or Classical Slots
          Expanded(
            child: _isMoodboardMode
                ? ListView(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    children: [
                      OutfitMoodboardWidget(
                        outerwear: _selectedOuterwear,
                        top: _selectedTop,
                        bottom: _selectedBottom,
                        shoes: _selectedShoes,
                        onShuffle: _randomizeOutfit,
                        onSelectCategory: (cat) {
                          final available = wardrobe.items.where((i) => i.category == cat).toList();
                          _showCategoryPicker(cat, available, (item) {
                            setState(() {
                              if (cat == ClothingCategory.outerwear) _selectedOuterwear = item;
                              if (cat == ClothingCategory.tops) _selectedTop = item;
                              if (cat == ClothingCategory.bottoms) _selectedBottom = item;
                              if (cat == ClothingCategory.shoes) _selectedShoes = item;
                            });
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'Натисніть на будь-яку річ у колажі, щоб замінити її на іншу з гардероба.',
                          style: TextStyle(fontSize: 11, color: AppTheme.muted.withValues(alpha: 0.9)),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    children: [
                      _buildOutfitSlot(
                        title: 'Верхній одяг',
                        item: _selectedOuterwear,
                        category: ClothingCategory.outerwear,
                        onSelect: (item) => setState(() => _selectedOuterwear = item),
                      ),
                      const SizedBox(height: 10),
                      _buildOutfitSlot(
                        title: 'Верх / Топ',
                        item: _selectedTop,
                        category: ClothingCategory.tops,
                        onSelect: (item) => setState(() => _selectedTop = item),
                      ),
                      const SizedBox(height: 10),
                      _buildOutfitSlot(
                        title: 'Низ / Брюки',
                        item: _selectedBottom,
                        category: ClothingCategory.bottoms,
                        onSelect: (item) => setState(() => _selectedBottom = item),
                      ),
                      const SizedBox(height: 10),
                      _buildOutfitSlot(
                        title: 'Взуття',
                        item: _selectedShoes,
                        category: ClothingCategory.shoes,
                        onSelect: (item) => setState(() => _selectedShoes = item),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
          ),

          // Action Bottom Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppTheme.border)),
            ),
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _showStyleCheckDialog,
                  icon: const Icon(Icons.auto_awesome, size: 18, color: AppTheme.accent),
                  label: const Text('Style Check'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _wearThisOutfit,
                    icon: const Icon(Icons.check_circle_rounded),
                    label: const Text('Вдягнути цей образ'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickPromptChip(String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () {
          _promptController.text = text;
          _curateWithNaturalPrompt(text);
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F4F5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.border),
          ),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.primary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOutfitSlot({
    required String title,
    required ClothingItem? item,
    required ClothingCategory category,
    required Function(ClothingItem) onSelect,
  }) {
    final available = context.read<WardrobeProvider>().items.where((i) => i.category == category).toList();

    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: item == null
          ? Center(
              child: TextButton.icon(
                onPressed: () => _showCategoryPicker(category, available, onSelect),
                icon: const Icon(Icons.add_circle_outline_rounded),
                label: Text('Обрати $title'),
              ),
            )
          : InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _showCategoryPicker(category, available, onSelect),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                    child: CachedNetworkImage(
                      imageUrl: item.imageUrl,
                      width: 110,
                      height: 110,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title.toUpperCase(),
                          style: const TextStyle(fontSize: 10, color: AppTheme.muted, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                        Text(
                          item.brand,
                          style: const TextStyle(color: AppTheme.muted, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${item.wearCount} носінь · ${item.costPerWear.toStringAsFixed(0)} ₴/вихід',
                          style: const TextStyle(fontSize: 11, color: AppTheme.accent, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(right: 14),
                    child: Icon(Icons.swap_vert_rounded, color: AppTheme.muted),
                  ),
                ],
              ),
            ),
    );
  }

  void _showCategoryPicker(
    ClothingCategory category,
    List<ClothingItem> items,
    Function(ClothingItem) onSelect,
  ) {
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('У категорії "${category.label}" ще немає речей.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Оберіть ${category.label}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 150,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 12),
                  itemBuilder: (_, index) {
                    final it = items[index];
                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        onSelect(it);
                        Navigator.pop(ctx);
                      },
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: it.imageUrl,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            width: 100,
                            child: Text(
                              it.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
