import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/clothing_item.dart';
import '../services/wardrobe_provider.dart';
import '../services/weather_stylist_service.dart';
import '../services/style_check_service.dart';
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

  // Weather & Context settings
  WeatherCondition _weatherCondition = WeatherCondition.cloudy;
  Occasion _occasion = Occasion.casual;
  int _temperature = 16;
  CuratedDailyOutfit? _lastCurated;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _curateWithAI();
    });
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

              // Progress bars
              _buildMetricBar('Гармонія кольорів', eval.colorHarmonyScore, const Color(0xFF2563EB)),
              const SizedBox(height: 10),
              _buildMetricBar('Баланс пропорцій', eval.proportionScore, const Color(0xFF16A34A)),

              const SizedBox(height: 16),
              const Divider(color: AppTheme.border),
              const SizedBox(height: 12),

              // Positive highlights
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
              // Actionable tip
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
        appBar: AppBar(title: const Text('Стиліст Vestora')),
        body: const Center(
          child: Text('Додайте спочатку декілька речей у гардероб'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Стиліст Vestora'),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: AppTheme.accent),
            tooltip: 'Оцінити стиль образу (AI Check)',
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
          // Weather & Context Selector
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        setState(() {
                          if (_temperature == 16) {
                            _temperature = 22;
                          } else if (_temperature == 22) {
                            _temperature = 8;
                          } else {
                            _temperature = 16;
                          }
                        });
                        _curateWithAI();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.thermostat_rounded, size: 16, color: AppTheme.accent),
                            const SizedBox(width: 4),
                            Text('$_temperature°C', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: WeatherCondition.values.map((cond) {
                            final isSel = cond == _weatherCondition;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                label: Text(cond.label, style: TextStyle(fontSize: 11, color: isSel ? Colors.white : AppTheme.primary)),
                                selected: isSel,
                                selectedColor: AppTheme.primary,
                                backgroundColor: AppTheme.background,
                                onSelected: (sel) {
                                  if (sel) {
                                    setState(() => _weatherCondition = cond);
                                    _curateWithAI();
                                  }
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Подія:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.muted)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: Occasion.values.map((occ) {
                            final isSel = occ == _occasion;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                label: Text(occ.label, style: TextStyle(fontSize: 11, color: isSel ? Colors.white : AppTheme.primary)),
                                selected: isSel,
                                selectedColor: AppTheme.accent,
                                backgroundColor: AppTheme.background,
                                onSelected: (sel) {
                                  if (sel) {
                                    setState(() => _occasion = occ);
                                    _curateWithAI();
                                  }
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_lastCurated != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F4F5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.psychology, size: 16, color: AppTheme.primary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${_lastCurated!.weatherRationale} ${_lastCurated!.occasionRationale}',
                            style: const TextStyle(fontSize: 11, color: AppTheme.secondary),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
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

          // Outfit Canvas
          Expanded(
            child: ListView(
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
