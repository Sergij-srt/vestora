import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/clothing_item.dart';
import '../services/wardrobe_provider.dart';
import '../services/weather_stylist_service.dart';
import '../services/style_check_service.dart';
import '../widgets/outfit_moodboard.dart';
import '../widgets/vestora_image.dart';
import '../theme/app_theme.dart';
import '../services/localization_service.dart';
import '../services/outfit_calendar_service.dart';
import 'outfit_calendar_screen.dart';
import 'virtual_fitting_screen.dart';
import 'capsule_matrix_screen.dart';
import 'editorial_story_screen.dart';

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
  WeatherCondition _weatherCondition = WeatherCondition.cloudy;
  Occasion _occasion = Occasion.casual;
  int _temperature = 16;
  CuratedDailyOutfit? _lastCurated;

  void _selectWeatherPreset(WeatherCondition condition, int temp) {
    setState(() {
      _weatherCondition = condition;
      _temperature = temp;
    });
    _curateWithAI();
  }

  void _selectOccasion(Occasion occasion) {
    setState(() {
      _occasion = occasion;
    });
    _curateWithAI();
  }

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

  void _openEditorialLook() {
    final items = _currentOutfitItems;
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Складіть спочатку образ для журнального експорту'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final eval = StyleCheckService.evaluateOutfit(outfitItems: items);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditorialStoryScreen(
          items: items,
          occasion: _occasion.label,
          temperatureText: '$_temperature°C ${_weatherCondition.label}',
          styleScore: eval.overallScore.toDouble(),
          customQuote: eval.actionableTip,
        ),
      ),
    );
  }

  void _scheduleCurrentOutfit() {
    final items = _currentOutfitItems;
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Складіть спочатку образ для планування'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final inTwoDays = today.add(const Duration(days: 2));

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
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
              const SizedBox(height: 16),
              const Text('Запланувати цей образ у календар', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('Оберіть день, на який закріпити даний лук:', style: TextStyle(fontSize: 12, color: AppTheme.muted)),
              const SizedBox(height: 16),

              _buildDateScheduleTile(ctx, 'Сьогодні', today, 'Сьогоднішній образ'),
              _buildDateScheduleTile(ctx, 'Завтра', tomorrow, 'Образ на завтра'),
              _buildDateScheduleTile(ctx, 'Післязавтра', inTwoDays, 'Запланований вихід'),

              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.date_range_rounded, size: 18),
                  label: const Text('Обрати іншу дату в календарі'),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: today,
                      firstDate: today.subtract(const Duration(days: 7)),
                      lastDate: today.add(const Duration(days: 60)),
                    );
                    if (picked != null) {
                      await _saveOutfitToDate(picked, 'Запланований образ');
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDateScheduleTile(BuildContext ctx, String label, DateTime date, String defaultEvent) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.calendar_today_rounded, size: 18, color: AppTheme.accent),
      ),
      title: Text('$label (${date.day}.${date.month.toString().padLeft(2, '0')})', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
      subtitle: Text('Прогноз: ${_temperature > 0 ? '+$_temperature' : '$_temperature'}°C · ${_weatherCondition.label.split(' ')[0]}', style: const TextStyle(fontSize: 11, color: AppTheme.muted)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.muted),
      onTap: () async {
        Navigator.pop(ctx);
        await _saveOutfitToDate(date, defaultEvent);
      },
    );
  }

  Future<void> _saveOutfitToDate(DateTime date, String eventTitle) async {
    final dateStr = OutfitCalendarService.formatDate(date);
    final plan = PlannedDayOutfit(
      dateStr: dateStr,
      date: date,
      weatherTemp: _temperature,
      weatherCondition: _weatherCondition,
      occasion: _occasion,
      eventTitle: eventTitle,
      outerwearId: _selectedOuterwear?.id,
      topId: _selectedTop?.id,
      bottomId: _selectedBottom?.id,
      shoesId: _selectedShoes?.id,
    );
    await OutfitCalendarService.savePlan(plan);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Образ збережено у календар на ${date.day}.${date.month.toString().padLeft(2, '0')}!'),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Відкрити',
            textColor: Colors.white,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => OutfitCalendarScreen(initialDate: date)),
              );
            },
          ),
        ),
      );
    }
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
        final sheetDark = Theme.of(ctx).brightness == Brightness.dark;
        final sheetBorder = sheetDark ? AppTheme.darkBorder : AppTheme.border;
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.88,
          ),
          child: SingleChildScrollView(
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
                      color: sheetBorder,
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

                _buildMetricBar('Гармонія кольорів', eval.colorHarmonyScore, const Color(0xFF2563EB), sheetDark),
                const SizedBox(height: 10),
                _buildMetricBar('Баланс пропорцій', eval.proportionScore, const Color(0xFF16A34A), sheetDark),

                const SizedBox(height: 16),
                Divider(color: sheetBorder),
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
                    color: sheetDark ? const Color(0xFF27272A) : const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: sheetBorder),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lightbulb_outline, size: 20, color: AppTheme.accent),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          eval.actionableTip,
                          style: TextStyle(
                            fontSize: 12,
                            color: sheetDark ? const Color(0xFFD4D4D8) : AppTheme.secondary,
                            height: 1.4,
                          ),
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
          ),
        );
      },
    );
  }

  Widget _buildMetricBar(String label, int value, Color color, bool isDark) {
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
          backgroundColor: isDark ? const Color(0xFF27272A) : AppTheme.background,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppTheme.darkSurface : Colors.white;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.border;

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
        title: Text(context.tr('stylist_title')),
        actions: [
          // 1. View mode toggle button
          IconButton(
            icon: Icon(_isMoodboardMode ? Icons.view_agenda_outlined : Icons.dashboard_outlined),
            tooltip: _isMoodboardMode ? 'Перемкнути на слоти' : 'Перемкнути на колаж',
            onPressed: () => setState(() => _isMoodboardMode = !_isMoodboardMode),
          ),
          // 2. Randomize / Shuffle outfit
          IconButton(
            icon: const Icon(Icons.shuffle_rounded),
            tooltip: context.tr('stylist_shuffle'),
            onPressed: _randomizeOutfit,
          ),
          // 3. Overflow Popup Menu for AI Tools
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            tooltip: 'Більше інструментів стиліста',
            onSelected: (val) {
              switch (val) {
                case 'tryon':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VirtualFittingScreen(
                        initialOuterwear: _selectedOuterwear,
                        initialTop: _selectedTop,
                        initialBottom: _selectedBottom,
                        initialShoes: _selectedShoes,
                      ),
                    ),
                  );
                  break;
                case 'matrix':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CapsuleMatrixScreen()),
                  );
                  break;
                case 'editorial':
                  _openEditorialLook();
                  break;
                case 'calendar':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OutfitCalendarScreen()),
                  );
                  break;
                case 'stylecheck':
                  _showStyleCheckDialog();
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
                    Flexible(child: Text('AI Примірочна (Try-On)')),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'matrix',
                child: Row(
                  children: [
                    Icon(Icons.grid_on_rounded, color: AppTheme.accent, size: 20),
                    SizedBox(width: 10),
                    Flexible(child: Text('Капсульна матриця 3х3')),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'editorial',
                child: Row(
                  children: [
                    Icon(Icons.auto_stories_outlined, color: AppTheme.accent, size: 20),
                    SizedBox(width: 10),
                    Flexible(child: Text('Експорт постера (Stories)')),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'calendar',
                child: Row(
                  children: [
                    Icon(Icons.calendar_month_outlined, color: AppTheme.accent, size: 20),
                    SizedBox(width: 10),
                    Flexible(child: Text('Календар образів')),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'stylecheck',
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, color: AppTheme.accent, size: 20),
                    SizedBox(width: 10),
                    Flexible(child: Text('Оцінка стилю (Style Check)')),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Natural Language AI Prompt & Context Bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            color: surfaceColor,
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
                          hintText: context.tr('stylist_prompt_hint'),
                          hintStyle: const TextStyle(fontSize: 12, color: AppTheme.muted),
                          prefixIcon: const Icon(Icons.auto_awesome, size: 18, color: AppTheme.accent),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF27272A) : const Color(0xFFF8F9FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: borderColor),
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

                // Interactive Weather Selector Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildWeatherPill('☀️ +22°C Сонячно', WeatherCondition.sunny, 22, isDark),
                      _buildWeatherPill('⛅ +16°C Хмарно', WeatherCondition.cloudy, 16, isDark),
                      _buildWeatherPill('🌧️ +13°C Дощ', WeatherCondition.rainy, 13, isDark),
                      _buildWeatherPill('💨 +8°C Вітряно', WeatherCondition.coldWindy, 8, isDark),
                      _buildWeatherPill('❄️ -2°C Мороз', WeatherCondition.snowy, -2, isDark),
                    ],
                  ),
                ),
                const SizedBox(height: 6),

                // Interactive Occasion Selector Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildOccasionPill('💼 Офіс', Occasion.work, isDark),
                      _buildOccasionPill('☕ Прогулянка', Occasion.casual, isDark),
                      _buildOccasionPill('✨ Побачення', Occasion.dateNight, isDark),
                      _buildOccasionPill('🏃 Спорт', Occasion.sport, isDark),
                      _buildOccasionPill('✈️ Подорож', Occasion.travel, isDark),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Quick Prompt Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildQuickPromptChip('🌧️ Дощовий офіс', isDark),
                      _buildQuickPromptChip('☕ Затишна кав\'ярня', isDark),
                      _buildQuickPromptChip('✨ Вечірнє побачення', isDark),
                      _buildQuickPromptChip('🏃 Спортивний вихід', isDark),
                    ],
                  ),
                ),

                if (_lastCurated != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF27272A) : const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
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
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark ? const Color(0xFFD4D4D8) : AppTheme.secondary,
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
          Divider(height: 1, color: borderColor),

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
                        isDark: isDark,
                        title: 'Верхній одяг',
                        item: _selectedOuterwear,
                        category: ClothingCategory.outerwear,
                        onSelect: (item) => setState(() => _selectedOuterwear = item),
                      ),
                      const SizedBox(height: 10),
                      _buildOutfitSlot(
                        isDark: isDark,
                        title: 'Верх / Топ',
                        item: _selectedTop,
                        category: ClothingCategory.tops,
                        onSelect: (item) => setState(() => _selectedTop = item),
                      ),
                      const SizedBox(height: 10),
                      _buildOutfitSlot(
                        isDark: isDark,
                        title: 'Низ / Брюки',
                        item: _selectedBottom,
                        category: ClothingCategory.bottoms,
                        onSelect: (item) => setState(() => _selectedBottom = item),
                      ),
                      const SizedBox(height: 10),
                      _buildOutfitSlot(
                        isDark: isDark,
                        title: 'Взуття',
                        item: _selectedShoes,
                        category: ClothingCategory.shoes,
                        onSelect: (item) => setState(() => _selectedShoes = item),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
          ),

          // Action Bottom Bar (2-Tier Responsive Design - No letter wrapping)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            decoration: BoxDecoration(
              color: surfaceColor,
              border: Border(top: BorderSide(color: borderColor)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tier 1: Primary Wear Button + Style Check Button
                Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: ElevatedButton.icon(
                        onPressed: _wearThisOutfit,
                        icon: const Icon(Icons.check_circle_rounded, size: 18),
                        label: Text(
                          context.tr('stylist_wear_btn'),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 4,
                      child: OutlinedButton.icon(
                        onPressed: _showStyleCheckDialog,
                        icon: const Icon(Icons.auto_awesome, size: 16, color: AppTheme.accent),
                        label: Text(
                          context.tr('stylist_style_check_btn'),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Tier 2: Secondary Quick Actions Strip
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _buildBottomActionItem(
                      isDark: isDark,
                      icon: Icons.face_retouching_natural_rounded,
                      label: context.tr('stylist_try_on'),
                      color: const Color(0xFFD97706),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => VirtualFittingScreen(
                              initialOuterwear: _selectedOuterwear,
                              initialTop: _selectedTop,
                              initialBottom: _selectedBottom,
                              initialShoes: _selectedShoes,
                            ),
                          ),
                        );
                      },
                    ),
                    _buildBottomActionItem(
                      isDark: isDark,
                      icon: Icons.auto_stories_outlined,
                      label: context.tr('stylist_poster'),
                      color: const Color(0xFF7C3AED),
                      onTap: _openEditorialLook,
                    ),
                    _buildBottomActionItem(
                      isDark: isDark,
                      icon: Icons.calendar_today_outlined,
                      label: context.tr('stylist_calendar'),
                      color: const Color(0xFF2563EB),
                      onTap: _scheduleCurrentOutfit,
                    ),
                    _buildBottomActionItem(
                      isDark: isDark,
                      icon: Icons.bookmark_add_outlined,
                      label: context.tr('stylist_bookmark'),
                      color: const Color(0xFF059669),
                      onTap: () {
                        final items = _currentOutfitItems;
                        if (items.isEmpty) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Образ збережено до улюблених капсул!'),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: Color(0xFF16A34A),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionItem({
    required bool isDark,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFFE4E4E7) : Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherPill(String label, WeatherCondition condition, int temp, bool isDark) {
    final isSelected = _weatherCondition == condition && _temperature == temp;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: () => _selectWeatherPreset(condition, temp),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFFEF3C7)
                : (isDark ? const Color(0xFF27272A) : const Color(0xFFF4F4F5)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppTheme.accent : (isDark ? AppTheme.darkBorder : AppTheme.border),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected
                  ? const Color(0xFF92400E)
                  : (isDark ? const Color(0xFFD4D4D8) : AppTheme.secondary),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOccasionPill(String label, Occasion occasion, bool isDark) {
    final isSelected = _occasion == occasion;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: () => _selectOccasion(occasion),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppTheme.accent : AppTheme.primary)
                : (isDark ? const Color(0xFF27272A) : const Color(0xFFF4F4F5)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? (isDark ? AppTheme.accent : AppTheme.primary)
                  : (isDark ? AppTheme.darkBorder : AppTheme.border),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : (isDark ? const Color(0xFFD4D4D8) : AppTheme.secondary),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickPromptChip(String text, bool isDark) {
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
            color: isDark ? const Color(0xFF27272A) : const Color(0xFFF4F4F5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.border),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppTheme.primary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOutfitSlot({
    required bool isDark,
    required String title,
    required ClothingItem? item,
    required ClothingCategory category,
    required Function(ClothingItem) onSelect,
  }) {
    final available = context.read<WardrobeProvider>().items.where((i) => i.category == category).toList();

    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.border),
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
                    child: VestoraImage(
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppTheme.muted, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${item.wearCount} носінь · ${item.costPerWear.toStringAsFixed(0)} ₴/вихід',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                            child: VestoraImage(
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
