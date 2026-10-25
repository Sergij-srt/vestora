import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/wardrobe_provider.dart';
import '../services/travel_capsule_service.dart';
import '../widgets/vestora_image.dart';
import '../theme/app_theme.dart';

class TravelCapsuleScreen extends StatefulWidget {
  const TravelCapsuleScreen({super.key});

  @override
  State<TravelCapsuleScreen> createState() => _TravelCapsuleScreenState();
}

class _TravelCapsuleScreenState extends State<TravelCapsuleScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _cityController = TextEditingController(text: 'Рим 🇮🇹');
  int _days = 4;
  TripType _tripType = TripType.cityBreak;
  LuggageType _luggageType = LuggageType.carryOn;
  int _temperature = 19;

  TravelCapsulePlan? _plan;
  late TabController _tabController;

  final List<String> _popularDestinations = [
    'Рим 🇮🇹',
    'Париж 🇫🇷',
    'Лондон 🇬🇧',
    'Варшава 🇵🇱',
    'Карпати 🇺🇦',
    'Барселона 🇪🇸',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generatePlan();
    });
  }

  @override
  void dispose() {
    _cityController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _generatePlan() {
    final wardrobe = context.read<WardrobeProvider>().items;
    final city = _cityController.text.trim().isNotEmpty ? _cityController.text.trim() : 'Європа';

    final result = TravelCapsuleService.generateTravelCapsule(
      wardrobe: wardrobe,
      city: city,
      days: _days,
      tripType: _tripType,
      luggageType: _luggageType,
      temperatureCelsius: _temperature,
    );

    setState(() {
      _plan = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.darkSurface : Colors.white;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.border;
    final isNarrow = MediaQuery.of(context).size.width < 360;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Капсула у Подорож'),
        actions: [
          if (_plan != null)
            IconButton(
              icon: const Icon(Icons.share_outlined, color: AppTheme.accent),
              tooltip: 'Поділитися планом пакування',
              onPressed: () {
                final text = '''
🧳 VESTORA TRAVEL CAPSULE · ${_plan!.destinationCity}
📅 Тривалість: ${_plan!.durationDays} днів · ${_plan!.tripType.label}
🌡️ Очікувана t°: ${_plan!.estimatedTemperature}°C
🎒 Багаж: ${_plan!.luggageType.label} (${_plan!.capsuleItems.length} речей)
✨ Унікальних образів: понад ${_plan!.combinationsCount} комбінацій

Речі у валізі:
${_plan!.capsuleItems.map((e) => '• ${e.title} (${e.brand})').join('\n')}

Створено у додатку Vestora. Подорожуйте легко та елегантно!
''';
                Clipboard.setData(ClipboardData(text: text));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('План подорожі скопійовано! Надішліть у Telegram/Нотатки.'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Color(0xFF16A34A),
                  ),
                );
              },
            ),
        ],
      ),
      body: _plan == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Top Configuration Collapsible Header
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  decoration: BoxDecoration(
                    color: cardColor,
                    border: Border(bottom: BorderSide(color: borderColor)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // City search input & days
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _cityController,
                              onSubmitted: (_) => _generatePlan(),
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.flight_takeoff_rounded, color: AppTheme.accent, size: 20),
                                hintText: 'Куди летите / їдете?',
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
                          Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF27272A) : const Color(0xFFF8F9FA),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: borderColor),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 44,
                                  height: 48,
                                  child: IconButton(
                                    icon: const Icon(Icons.remove, size: 16),
                                    tooltip: 'Зменшити кількість днів',
                                    padding: EdgeInsets.zero,
                                    onPressed: _days > 2
                                        ? () {
                                            setState(() => _days--);
                                            _generatePlan();
                                          }
                                        : null,
                                  ),
                                ),
                                Text(
                                  '$_days дн.',
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
                                ),
                                SizedBox(
                                  width: 44,
                                  height: 48,
                                  child: IconButton(
                                    icon: const Icon(Icons.add, size: 16),
                                    tooltip: 'Збільшити кількість днів',
                                    padding: EdgeInsets.zero,
                                    onPressed: _days < 14
                                        ? () {
                                            setState(() => _days++);
                                            _generatePlan();
                                          }
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Quick destination chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _popularDestinations.map((dest) {
                            final isSel = _cityController.text == dest;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _cityController.text = dest;
                                    if (dest.contains('Карпати')) _temperature = 11;
                                    if (dest.contains('Лондон')) _temperature = 14;
                                    if (dest.contains('Рим')) _temperature = 21;
                                  });
                                  _generatePlan();
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isSel
                                        ? const Color(0xFFFEF3C7)
                                        : (isDark ? const Color(0xFF27272A) : const Color(0xFFF4F4F5)),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: isSel ? AppTheme.accent : borderColor),
                                  ),
                                  child: Text(
                                    dest,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: isSel ? FontWeight.w800 : FontWeight.w500,
                                      color: isSel
                                          ? const Color(0xFF92400E)
                                          : (isDark ? const Color(0xFFD4D4D8) : AppTheme.secondary),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Trip Type & Luggage selectors
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<TripType>(
                              isExpanded: true,
                              initialValue: _tripType,
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                labelText: 'Тип поїздки',
                                labelStyle: TextStyle(fontSize: 11),
                              ),
                              items: TripType.values.map((t) {
                                return DropdownMenuItem(
                                  value: t,
                                  child: Text(t.label, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _tripType = val);
                                  _generatePlan();
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<LuggageType>(
                              isExpanded: true,
                              initialValue: _luggageType,
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                labelText: 'Валіза',
                                labelStyle: TextStyle(fontSize: 11),
                              ),
                              items: LuggageType.values.map((l) {
                                return DropdownMenuItem(
                                  value: l,
                                  child: Text(l.label, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _luggageType = val);
                                  _generatePlan();
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // AI Insight Strip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: isDark ? const Color(0xFF272011) : const Color(0xFFFFFBEB),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: AppTheme.accent, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _plan!.stylistAdvice,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF78350F),
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Tab Bar: 1. Речі у валізі | 2. Луки по днях | 3. Чек-лист
                Container(
                  color: cardColor,
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: isNarrow,
                    tabAlignment: isNarrow ? TabAlignment.start : TabAlignment.fill,
                    indicatorColor: isDark ? AppTheme.accent : AppTheme.primary,
                    labelColor: isDark ? AppTheme.accent : AppTheme.primary,
                    unselectedLabelColor: AppTheme.muted,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                    tabs: [
                      Tab(text: 'Капсула (${_plan!.capsuleItems.length})'),
                      Tab(text: 'Дні (${_plan!.dailyOutfits.length})'),
                      Tab(text: 'Чек-лист (${_plan!.checklist.where((c) => c.isChecked).length}/${_plan!.checklist.length})'),
                    ],
                  ),
                ),

                // Tab Views
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildCapsuleItemsGrid(_plan!, isDark),
                      _buildDailyOutfitsList(_plan!, isDark),
                      _buildChecklistList(_plan!, isDark),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCapsuleItemsGrid(TravelCapsulePlan plan, bool isDark) {
    if (plan.capsuleItems.isEmpty) {
      return const Center(child: Text('У вашому гардеробі поки немає речей'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: plan.capsuleItems.length,
      itemBuilder: (context, index) {
        final item = plan.capsuleItems[index];
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
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
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Text(item.category.icon, style: const TextStyle(fontSize: 11)),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.brand.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppTheme.muted),
                    ),
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.color} · ${item.size ?? 'M'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10, color: AppTheme.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDailyOutfitsList(TravelCapsulePlan plan, bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: plan.dailyOutfits.length,
      itemBuilder: (context, index) {
        final daily = plan.dailyOutfits[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.border),
            boxShadow: AppTheme.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      daily.dayTitle,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      daily.occasion,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF92400E)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                daily.stylistTip,
                style: const TextStyle(fontSize: 11.5, color: AppTheme.muted, height: 1.3),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 90,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: daily.items.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final it = daily.items[i];
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: VestoraImage(
                        imageUrl: it.imageUrl,
                        width: 75,
                        height: 90,
                        fit: BoxFit.cover,
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

  Widget _buildChecklistList(TravelCapsulePlan plan, bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: plan.checklist.length,
      itemBuilder: (context, index) {
        final item = plan.checklist[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: item.isChecked
                  ? const Color(0xFF16A34A)
                  : (isDark ? AppTheme.darkBorder : AppTheme.border),
            ),
          ),
          child: CheckboxListTile(
            value: item.isChecked,
            title: Text(
              item.title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                decoration: item.isChecked ? TextDecoration.lineThrough : null,
                color: item.isChecked
                    ? AppTheme.muted
                    : (isDark ? Colors.white : AppTheme.primary),
              ),
            ),
            subtitle: Text(
              item.category,
              style: const TextStyle(fontSize: 10.5, color: AppTheme.muted),
            ),
            activeColor: const Color(0xFF16A34A),
            onChanged: (val) {
              setState(() {
                item.isChecked = val ?? false;
              });
            },
          ),
        );
      },
    );
  }
}
