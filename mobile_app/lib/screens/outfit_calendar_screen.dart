import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/clothing_item.dart';
import '../services/wardrobe_provider.dart';
import '../services/weather_stylist_service.dart';
import '../services/outfit_calendar_service.dart';
import '../widgets/controller_scope.dart';
import '../widgets/vestora_image.dart';
import '../theme/app_theme.dart';

class OutfitCalendarScreen extends StatefulWidget {
  final DateTime? initialDate;

  const OutfitCalendarScreen({super.key, this.initialDate});

  @override
  State<OutfitCalendarScreen> createState() => _OutfitCalendarScreenState();
}

class _OutfitCalendarScreenState extends State<OutfitCalendarScreen> {
  late DateTime _selectedDate;
  late DateTime _startOfWeekDate;
  List<PlannedDayOutfit> _weekDays = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final now = widget.initialDate ?? DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _startOfWeekDate = OutfitCalendarService.startOfWeek(_selectedDate);
    _loadWeek();
  }

  Future<void> _loadWeek() async {
    setState(() => _isLoading = true);
    final wardrobe = context.read<WardrobeProvider>().items;
    final days = await OutfitCalendarService.getWeekPlan(
      referenceDate: _startOfWeekDate,
      wardrobe: wardrobe,
    );
    if (mounted) {
      setState(() {
        _weekDays = days;
        _isLoading = false;
      });
    }
  }

  PlannedDayOutfit get _selectedPlan {
    final key = OutfitCalendarService.formatDate(_selectedDate);
    final found = _weekDays.cast<PlannedDayOutfit?>().firstWhere(
          (d) => d?.dateStr == key,
          orElse: () => null,
        );
    if (found != null) return found;

    return PlannedDayOutfit(
      dateStr: key,
      date: _selectedDate,
      weatherTemp: 17,
      weatherCondition: WeatherCondition.cloudy,
      occasion: Occasion.casual,
      eventTitle: 'Вільний день',
    );
  }

  void _changeWeek(int deltaWeeks) {
    setState(() {
      _startOfWeekDate = _startOfWeekDate.add(Duration(days: deltaWeeks * 7));
      _selectedDate = _startOfWeekDate;
    });
    _loadWeek();
  }

  Future<void> _generateAiWeeklyPlan() async {
    final wardrobe = context.read<WardrobeProvider>().items;
    if (wardrobe.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Спочатку додайте речі у гардероб або завантажте демо')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final days = await OutfitCalendarService.generateAiWeekPlan(
      referenceDate: _startOfWeekDate,
      wardrobe: wardrobe,
    );

    if (mounted) {
      setState(() {
        _weekDays = days;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✨ AI-план на весь тиждень успішно згенеровано з урахуванням погоди!'),
          backgroundColor: Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _markSelectedDayAsWorn() async {
    final wardrobe = context.read<WardrobeProvider>();
    final plan = _selectedPlan;
    if (!plan.hasOutfit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Складіть спочатку образ для цього дня')),
      );
      return;
    }

    await OutfitCalendarService.markDayWorn(
      day: plan,
      wardrobeProvider: wardrobe,
    );

    setState(() {});

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🔥 Образ зараховано! Стрік збільшено до ${wardrobe.streakDays} днів.'),
          backgroundColor: const Color(0xFFD97706),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showItemPicker(ClothingCategory category, Function(ClothingItem) onSelected) {
    final wardrobe = context.read<WardrobeProvider>().items;
    final items = wardrobe.where((i) => i.category == category).toList();

    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('У категорії "${category.label}" немає речей.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Оберіть ${category.label}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 140,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (_, index) {
                  final it = items[index];
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      onSelected(it);
                      Navigator.pop(ctx);
                    },
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: VestoraImage(
                            imageUrl: it.imageUrl,
                            width: 90,
                            height: 90,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: 90,
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
      ),
    );
  }

  void _showEditEventModal() {
    final plan = _selectedPlan;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark ? AppTheme.darkMuted : AppTheme.muted;
    final accentColor = isDark ? AppTheme.darkAccent : AppTheme.accent;
    Occasion selectedOcc = plan.occasion;
    WeatherCondition selectedCond = plan.weatherCondition;
    int temp = plan.weatherTemp;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => ControllerScope(
        create: () => [TextEditingController(text: plan.eventTitle)],
        builder: (ctx, ctrls) {
          final titleCtrl = ctrls[0];
          return StatefulBuilder(
            builder: (dialogCtx, setModalState) => Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 18,
                bottom: MediaQuery.of(dialogCtx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
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
                    const Text('Налаштування події та погоди', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 14),

                    Text('ПОДІЯ ДНЯ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: mutedColor)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Наприклад: Зустріч з клієнтом у кав\'ярні',
                        prefixIcon: Icon(Icons.event_outlined, size: 20),
                      ),
                    ),
                    const SizedBox(height: 14),

                    Text('ДРЕС-КОД / КОНТЕКСТ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: mutedColor)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: Occasion.values.map((occ) {
                        final isSel = occ == selectedOcc;
                        return ChoiceChip(
                          label: Text(occ.label.split(' ')[0]),
                          selected: isSel,
                          selectedColor: isDark ? AppTheme.darkAccent : AppTheme.primary,
                          labelStyle: TextStyle(
                            color: isSel
                                ? (isDark ? Colors.black : Colors.white)
                                : (isDark ? Colors.white : AppTheme.primary),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          onSelected: (_) => setModalState(() => selectedOcc = occ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('ПРОГНОЗ ПОГОДИ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: mutedColor)),
                        Text('${temp > 0 ? '+$temp' : '$temp'}°C', style: TextStyle(fontWeight: FontWeight.bold, color: accentColor)),
                      ],
                    ),
                    Slider(
                      value: temp.toDouble(),
                      min: -10,
                      max: 35,
                      divisions: 45,
                      activeColor: accentColor,
                      onChanged: (v) => setModalState(() => temp = v.round()),
                    ),
                    const SizedBox(height: 14),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final updated = plan.copyWith(
                            eventTitle: titleCtrl.text.trim().isNotEmpty ? titleCtrl.text.trim() : plan.eventTitle,
                            occasion: selectedOcc,
                            weatherCondition: selectedCond,
                            weatherTemp: temp,
                          );
                          Navigator.pop(dialogCtx);
                          await OutfitCalendarService.savePlan(updated);
                          if (mounted) {
                            _loadWeek();
                          }
                        },
                        child: const Text('Зберегти зміни'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wardrobe = context.watch<WardrobeProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.darkCard : Colors.white;
    final barColor = isDark ? AppTheme.darkSurface : Colors.white;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.border;
    final plan = _selectedPlan;
    final outfitItems = plan.getOutfitItems(wardrobe.items);

    final endOfWeekDate = _startOfWeekDate.add(const Duration(days: 6));
    final weekTitle = '${_startOfWeekDate.day}.${_startOfWeekDate.month.toString().padLeft(2, '0')} — ${endOfWeekDate.day}.${endOfWeekDate.month.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Календар образів',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.auto_awesome, color: isDark ? AppTheme.darkAccent : AppTheme.accent),
            tooltip: 'Згенерувати AI-план на тиждень',
            onPressed: _generateAiWeeklyPlan,
          ),
          IconButton(
            icon: const Icon(Icons.today_rounded),
            tooltip: 'Повернутися до сьогодні',
            onPressed: () {
              final now = DateTime.now();
              setState(() {
                _selectedDate = DateTime(now.year, now.month, now.day);
                _startOfWeekDate = OutfitCalendarService.startOfWeek(_selectedDate);
              });
              _loadWeek();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // Week Switcher Bar
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    color: barColor,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          tooltip: 'Попередній тиждень',
                          icon: const Icon(Icons.chevron_left_rounded),
                          onPressed: () => _changeWeek(-1),
                        ),
                        Flexible(
                          child: Column(
                            children: [
                              Text(
                                weekTitle,
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                              ),
                              Text(
                                'Тижневий план гардеробу',
                                style: TextStyle(fontSize: 11, color: isDark ? AppTheme.darkMuted : AppTheme.muted),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Наступний тиждень',
                          icon: const Icon(Icons.chevron_right_rounded),
                          onPressed: () => _changeWeek(1),
                        ),
                      ],
                    ),
                  ),
                ),

                // 7-Day Interactive Day Strip
                SliverToBoxAdapter(
                  child: Container(
                    height: 105,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    color: barColor,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _weekDays.length,
                      itemBuilder: (ctx, idx) {
                        final day = _weekDays[idx];
                        final isSelected = day.date.year == _selectedDate.year &&
                            day.date.month == _selectedDate.month &&
                            day.date.day == _selectedDate.day;

                        final now = DateTime.now();
                        final isToday = day.date.year == now.year &&
                            day.date.month == now.month &&
                            day.date.day == now.day;

                        return InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            setState(() => _selectedDate = day.date);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 58,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (isDark ? AppTheme.darkAccent : AppTheme.primary)
                                  : (isToday
                                      ? (isDark ? const Color(0xFF451A03) : const Color(0xFFFEF3C7))
                                      : (isDark ? AppTheme.darkCard : const Color(0xFFF8F9FA))),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.accent
                                    : (isToday ? const Color(0xFFFDE68A) : borderColor),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  day.shortDayName,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? (isDark ? Colors.black87 : Colors.white70)
                                        : (isDark ? AppTheme.darkMuted : AppTheme.muted),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${day.date.day}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: isSelected
                                        ? (isDark ? Colors.black : Colors.white)
                                        : (isDark ? Colors.white : AppTheme.primary),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${day.weatherTemp}°',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? (isDark ? Colors.black87 : const Color(0xFFFDE68A))
                                        : (isDark ? const Color(0xFFD4D4D8) : AppTheme.secondary),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                if (day.isWorn)
                                  const Icon(Icons.check_circle_rounded, size: 12, color: AppTheme.success)
                                else if (day.hasOutfit)
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: const BoxDecoration(
                                      color: AppTheme.accent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                SliverToBoxAdapter(child: Divider(height: 1, color: borderColor)),

                // Selected Day Focus Card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderColor),
                        boxShadow: isDark ? const [] : AppTheme.softShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header: Date & Status
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${plan.dayOfWeekName}, ${plan.date.day} ${_getMonthName(plan.date.month)}',
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                                    ),
                                    const SizedBox(height: 2),
                                    Wrap(
                                      spacing: 4,
                                      runSpacing: 2,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      children: [
                                        Text(
                                          plan.eventTitle,
                                          style: TextStyle(color: isDark ? AppTheme.darkMuted : AppTheme.muted, fontSize: 12.5),
                                        ),
                                        if (outfitItems.isNotEmpty)
                                          Text(
                                            '· ${outfitItems.length} речі (${outfitItems.fold(0.0, (s, i) => s + i.price).toStringAsFixed(0)} ₴)',
                                            style: TextStyle(
                                              color: isDark ? AppTheme.darkAccent : AppTheme.accent,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 11.5,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.edit_outlined, size: 20, color: isDark ? AppTheme.darkAccent : AppTheme.accent),
                                tooltip: 'Редагувати подію та погоду',
                                onPressed: _showEditEventModal,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Weather & Occasion Badges
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0FDF4),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFBBF7D0)),
                                ),
                                child: Text(
                                  '${plan.weatherTemp > 0 ? '+${plan.weatherTemp}' : plan.weatherTemp}°C · ${plan.weatherCondition.label.split(' ')[0]}',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF166534)),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFFDE68A)),
                                ),
                                child: Text(
                                  plan.occasion.label.split(' ')[0],
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF92400E)),
                                ),
                              ),
                              if (plan.isWorn)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check_circle_rounded, size: 14, color: AppTheme.success),
                                      SizedBox(width: 4),
                                      Text(
                                        'Вдягнено',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF166534)),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // Visual Outfit Slots
                          Text(
                            'СКЛАД ОБРАЗУ',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: isDark ? AppTheme.darkMuted : AppTheme.muted, letterSpacing: 1),
                          ),
                          const SizedBox(height: 10),

                          Row(
                            children: [
                              _buildSlotCard(
                                isDark,
                                'Верхній одяг',
                                plan.outerwearId,
                                ClothingCategory.outerwear,
                                (it) => setState(() => plan.outerwearId = it.id),
                              ),
                              const SizedBox(width: 8),
                              _buildSlotCard(
                                isDark,
                                'Верх / Топ',
                                plan.topId,
                                ClothingCategory.tops,
                                (it) => setState(() => plan.topId = it.id),
                              ),
                              const SizedBox(width: 8),
                              _buildSlotCard(
                                isDark,
                                'Низ / Брюки',
                                plan.bottomId,
                                ClothingCategory.bottoms,
                                (it) => setState(() => plan.bottomId = it.id),
                              ),
                              const SizedBox(width: 8),
                              _buildSlotCard(
                                isDark,
                                'Взуття',
                                plan.shoesId,
                                ClothingCategory.shoes,
                                (it) => setState(() => plan.shoesId = it.id),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // Action Buttons for this day
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: plan.isWorn
                                        ? AppTheme.success
                                        : (isDark ? AppTheme.darkAccent : AppTheme.primary),
                                    foregroundColor: plan.isWorn
                                        ? Colors.white
                                        : (isDark ? Colors.black : Colors.white),
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                  ),
                                  icon: Icon(plan.isWorn ? Icons.check_circle_rounded : Icons.flare_rounded, size: 18),
                                  label: Text(
                                    plan.isWorn ? 'Вдягнено сьогодні' : 'Вдягнути сьогодні (+1)',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onPressed: plan.isWorn ? null : _markSelectedDayAsWorn,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                fit: FlexFit.loose,
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                                  ),
                                  icon: Icon(Icons.auto_awesome, size: 16, color: isDark ? AppTheme.darkAccent : AppTheme.accent),
                                  label: const Text(
                                    'AI-підбір',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onPressed: () {
                                  final curated = WeatherStylistService.curateOutfit(
                                    wardrobe: wardrobe.items,
                                    temperatureCelsius: plan.weatherTemp,
                                    condition: plan.weatherCondition,
                                    occasion: plan.occasion,
                                  );
                                  setState(() {
                                    plan.outerwearId = curated.outerwear?.id;
                                    plan.topId = curated.top?.id;
                                    plan.bottomId = curated.bottom?.id;
                                    plan.shoesId = curated.shoes?.id;
                                  });
                                  OutfitCalendarService.savePlan(plan);
                                },
                              ),
                            ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Weekly Health & Versatility Bento Card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.insights_rounded, size: 18, color: isDark ? AppTheme.darkAccent : AppTheme.accent),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'ЕФЕКТИВНІСТЬ ТИЖНЯ',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1,
                                    color: isDark ? AppTheme.darkAccent : AppTheme.accent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatItem(
                                  isDark,
                                  'Заплановано',
                                  '${_weekDays.where((d) => d.hasOutfit).length}/7 днів',
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: _buildStatItem(
                                  isDark,
                                  'Вдягнено',
                                  '${_weekDays.where((d) => d.isWorn).length} виходів',
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: _buildStatItem(
                                  isDark,
                                  'Стрік',
                                  '${wardrobe.streakDays} днів 🔥',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
    );
  }

  Widget _buildStatItem(bool isDark, String label, String value) {
    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(color: isDark ? AppTheme.darkMuted : AppTheme.muted, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildSlotCard(
    bool isDark,
    String slotName,
    String? itemId,
    ClothingCategory category,
    Function(ClothingItem) onSelected,
  ) {
    final wardrobe = context.watch<WardrobeProvider>().items;
    final item = itemId != null
        ? wardrobe.cast<ClothingItem?>().firstWhere((i) => i?.id == itemId, orElse: () => null)
        : null;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showItemPicker(category, (it) {
          onSelected(it);
          OutfitCalendarService.savePlan(_selectedPlan);
        }),
        child: Container(
          height: 110,
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : const Color(0xFFF4F4F5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.border),
          ),
          child: item == null
              ? Padding(
                  padding: const EdgeInsets.all(4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle_outline_rounded, size: 22, color: isDark ? AppTheme.darkMuted : AppTheme.muted),
                      const SizedBox(height: 4),
                      Text(
                        slotName,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 9.5, color: isDark ? AppTheme.darkMuted : AppTheme.muted, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      VestoraImage(
                        imageUrl: item.imageUrl,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                          color: Colors.black.withValues(alpha: 0.65),
                          child: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const names = [
      'січня', 'лютого', 'березня', 'квітня', 'травня', 'червня',
      'липня', 'серпня', 'вересня', 'жовтня', 'листопада', 'грудня',
    ];
    return names[month - 1];
  }
}
