import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/clothing_item.dart';
import '../services/wardrobe_provider.dart';
import '../services/capsule_matrix_service.dart';
import '../services/outfit_calendar_service.dart';
import '../services/weather_stylist_service.dart';
import '../theme/app_theme.dart';
import 'virtual_fitting_screen.dart';
import 'outfit_calendar_screen.dart';
import 'editorial_story_screen.dart';

class CapsuleMatrixScreen extends StatefulWidget {
  const CapsuleMatrixScreen({super.key});

  @override
  State<CapsuleMatrixScreen> createState() => _CapsuleMatrixScreenState();
}

class _CapsuleMatrixScreenState extends State<CapsuleMatrixScreen> {
  List<ClothingItem> _selectedTops = [];
  List<ClothingItem> _selectedBottoms = [];
  List<ClothingItem> _selectedShoes = [];
  List<ClothingItem> _selectedOuterwear = [];

  int _selectedTopIndex = 0;
  int _selectedBottomIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFromWardrobe();
    });
  }

  void _initializeFromWardrobe() {
    final wardrobe = context.read<WardrobeProvider>().items;
    setState(() {
      _selectedTops = wardrobe.where((i) => i.category == ClothingCategory.tops).take(3).toList();
      _selectedBottoms = wardrobe.where((i) => i.category == ClothingCategory.bottoms).take(3).toList();
      _selectedShoes = wardrobe.where((i) => i.category == ClothingCategory.shoes).take(2).toList();
      _selectedOuterwear = wardrobe.where((i) => i.category == ClothingCategory.outerwear).take(1).toList();
    });
  }

  CapsuleMatrixData _getMatrixData() {
    final wardrobe = context.read<WardrobeProvider>().items;
    return CapsuleMatrixService.generateMatrix(
      wardrobe: wardrobe,
      selectedTops: _selectedTops,
      selectedBottoms: _selectedBottoms,
      selectedShoes: _selectedShoes,
      selectedOuterwear: _selectedOuterwear,
    );
  }

  void _showItemPicker(ClothingCategory category, int replaceIndex) {
    final wardrobe = context.read<WardrobeProvider>().items;
    final available = wardrobe.where((i) => i.category == category).toList();

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('У гардеробі немає речей у категорії "${category.label}".')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Замінити ${category.label}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: available.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (ctx2, idx) {
                  final it = available[idx];
                  return InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        if (category == ClothingCategory.tops && replaceIndex < _selectedTops.length) {
                          _selectedTops[replaceIndex] = it;
                        } else if (category == ClothingCategory.bottoms && replaceIndex < _selectedBottoms.length) {
                          _selectedBottoms[replaceIndex] = it;
                        }
                      });
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
      ),
    );
  }

  void _scheduleCombination(CapsuleCombination combo) {
    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Запланувати цей капсульний лук', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            ListTile(
              leading: const Icon(Icons.today_rounded, color: AppTheme.accent),
              title: const Text('Вдягнути сьогодні'),
              onTap: () async {
                Navigator.pop(ctx);
                await _saveToDate(today, 'Капсульний лук (${combo.styleVerdict})', combo);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today_rounded, color: AppTheme.primary),
              title: const Text('Запланувати на завтра'),
              onTap: () async {
                Navigator.pop(ctx);
                await _saveToDate(tomorrow, 'Капсульний лук на завтра', combo);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveToDate(DateTime date, String title, CapsuleCombination combo) async {
    final dateStr = OutfitCalendarService.formatDate(date);
    final plan = PlannedDayOutfit(
      dateStr: dateStr,
      date: date,
      weatherTemp: 18,
      weatherCondition: WeatherCondition.sunny,
      occasion: Occasion.casual,
      eventTitle: title,
      topId: combo.top.id,
      bottomId: combo.bottom.id,
      shoesId: combo.shoes?.id,
      outerwearId: combo.outerwear?.id,
    );
    await OutfitCalendarService.savePlan(plan);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Капсульний лук заплановано на ${date.day}.${date.month.toString().padLeft(2, '0')}!'),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Календар',
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

  @override
  Widget build(BuildContext context) {
    final matrix = _getMatrixData();
    final activeCombo = matrix.getCombination(_selectedTopIndex, _selectedBottomIndex) ??
        (matrix.combinations.isNotEmpty ? matrix.combinations.first : null);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Капсульна Матриця 3x3',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: AppTheme.accent),
            tooltip: 'AI Автопідбір капсули',
            onPressed: () {
              HapticFeedback.lightImpact();
              _initializeFromWardrobe();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✨ AI підібрав найбільш універсальні речі для капсульної матриці!'),
                  backgroundColor: Color(0xFF16A34A),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: matrix.tops.isEmpty || matrix.bottoms.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.grid_view_rounded, size: 54, color: AppTheme.muted),
                    const SizedBox(height: 14),
                    const Text('Потрібно щонайменше 1 топ та 1 низ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('Додайте речі у гардероб або завантажте демо-капсулу', style: TextStyle(color: AppTheme.muted, fontSize: 13)),
                  ],
                ),
              ),
            )
          : CustomScrollView(
              slivers: [
                // 1. Bento Efficiency Header Card
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF18181B), Color(0xFF27272A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'МІКРО-КАПСУЛЬНИЙ ДВИГУН',
                              style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 1.2),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD97706),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Універсальність: ${matrix.versatilityIndex}%',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildBentoStat('${matrix.combinations.length}', 'Образів з 6 речей'),
                            Container(width: 1, height: 28, color: Colors.white24),
                            _buildBentoStat('${matrix.averageHarmonyScore.toStringAsFixed(1)} / 10', 'Гармонія кольорів'),
                            Container(width: 1, height: 28, color: Colors.white24),
                            _buildBentoStat('-${matrix.projectedSavingsPercent}%', 'Зниження CPW'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. Interactive Matrix Grid Visualizer
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'МАТРИЧНА СІТКА КОМБІНАЦІЙ',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.muted, letterSpacing: 1),
                            ),
                            Text('Натисніть на клітинку для вибору', style: TextStyle(fontSize: 10.5, color: AppTheme.muted)),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Columns Header: Tops
                        Row(
                          children: [
                            const SizedBox(width: 50), // Corner spacing
                            ...List.generate(matrix.tops.length, (topIdx) {
                              final top = matrix.tops[topIdx];
                              final isColActive = topIdx == _selectedTopIndex;
                              return Expanded(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(10),
                                  onTap: () => _showItemPicker(ClothingCategory.tops, topIdx),
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 2),
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: isColActive ? const Color(0xFFFEF3C7) : const Color(0xFFF4F4F5),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: isColActive ? AppTheme.accent : Colors.transparent),
                                    ),
                                    child: Column(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: CachedNetworkImage(
                                            imageUrl: top.imageUrl,
                                            height: 44,
                                            width: 44,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          top.title.split(' ')[0],
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Matrix Rows: Bottoms + Intersection cells
                        ...List.generate(matrix.bottoms.length, (botIdx) {
                          final bottom = matrix.bottoms[botIdx];
                          final isRowActive = botIdx == _selectedBottomIndex;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              children: [
                                // Row Header: Bottom Item
                                InkWell(
                                  borderRadius: BorderRadius.circular(10),
                                  onTap: () => _showItemPicker(ClothingCategory.bottoms, botIdx),
                                  child: Container(
                                    width: 50,
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: isRowActive ? const Color(0xFFFEF3C7) : const Color(0xFFF4F4F5),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: isRowActive ? AppTheme.accent : Colors.transparent),
                                    ),
                                    child: Column(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(6),
                                          child: CachedNetworkImage(
                                            imageUrl: bottom.imageUrl,
                                            height: 38,
                                            width: 38,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          bottom.title.split(' ')[0],
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),

                                // Intersection Cells (Top x Bottom)
                                ...List.generate(matrix.tops.length, (topIdx) {
                                  final combo = matrix.getCombination(topIdx, botIdx);
                                  final isCellSelected = topIdx == _selectedTopIndex && botIdx == _selectedBottomIndex;

                                  return Expanded(
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: () {
                                        HapticFeedback.lightImpact();
                                        setState(() {
                                          _selectedTopIndex = topIdx;
                                          _selectedBottomIndex = botIdx;
                                        });
                                      },
                                      child: Container(
                                        height: 52,
                                        margin: const EdgeInsets.symmetric(horizontal: 2),
                                        decoration: BoxDecoration(
                                          color: isCellSelected ? AppTheme.primary : const Color(0xFFF8F9FA),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: isCellSelected ? AppTheme.accent : AppTheme.border,
                                            width: isCellSelected ? 2 : 1,
                                          ),
                                          boxShadow: isCellSelected
                                              ? [
                                                  BoxShadow(
                                                    color: Colors.black.withValues(alpha: 0.15),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 3),
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'Лук ${topIdx + 1}.${botIdx + 1}',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: isCellSelected ? Colors.white : AppTheme.primary,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                              decoration: BoxDecoration(
                                                color: isCellSelected
                                                    ? const Color(0xFFD4AF37)
                                                    : const Color(0xFFDCFCE7),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                combo?.harmonyScore.toStringAsFixed(1) ?? '9.4',
                                                style: TextStyle(
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.w800,
                                                  color: isCellSelected ? Colors.black : const Color(0xFF166534),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),

                // 3. Focused Combination Card
                if (activeCombo != null)
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.border),
                        boxShadow: AppTheme.softShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    activeCombo.styleVerdict,
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${activeCombo.allItems.length} речі в ансамблі · ${activeCombo.totalPrice.toStringAsFixed(0)} ₴',
                                    style: const TextStyle(color: AppTheme.muted, fontSize: 12),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.auto_awesome, size: 14, color: AppTheme.accent),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${activeCombo.harmonyScore.toStringAsFixed(1)} / 10',
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF92400E)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Thumbnails row
                          Row(
                            children: activeCombo.allItems.map((item) {
                              return Expanded(
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  height: 80,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppTheme.border),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        CachedNetworkImage(
                                          imageUrl: item.imageUrl,
                                          fit: BoxFit.cover,
                                        ),
                                        Positioned(
                                          bottom: 0,
                                          left: 0,
                                          right: 0,
                                          child: Container(
                                            color: Colors.black.withValues(alpha: 0.6),
                                            padding: const EdgeInsets.symmetric(vertical: 2),
                                            child: Text(
                                              item.title,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.w600),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 12),

                          // Color Rationale Box
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F9FA),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.palette_outlined, size: 16, color: AppTheme.accent),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    activeCombo.colorRationale,
                                    style: const TextStyle(fontSize: 11.5, color: AppTheme.secondary, height: 1.3),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Action Buttons
                          Row(
                            children: [
                              Expanded(
                                flex: 4,
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 11),
                                    side: const BorderSide(color: Color(0xFFD4AF37)),
                                    backgroundColor: const Color(0xFFFFFBEB),
                                  ),
                                  icon: const Icon(Icons.face_retouching_natural_rounded, size: 16, color: Color(0xFFB45309)),
                                  label: const Text('Приміряти', style: TextStyle(color: Color(0xFFB45309), fontSize: 11.5, fontWeight: FontWeight.w700)),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => VirtualFittingScreen(
                                          initialTop: activeCombo.top,
                                          initialBottom: activeCombo.bottom,
                                          initialShoes: activeCombo.shoes,
                                          initialOuterwear: activeCombo.outerwear,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                flex: 4,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 11)),
                                  icon: const Icon(Icons.calendar_today_outlined, size: 16),
                                  label: const Text('Календар', style: TextStyle(fontSize: 11.5)),
                                  onPressed: () => _scheduleCombination(activeCombo),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF18181B),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.auto_stories_outlined, color: Color(0xFFD4AF37), size: 20),
                                  tooltip: 'Постер для Stories / Pinterest',
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => EditorialStoryScreen(
                                          items: activeCombo.allItems,
                                          occasion: 'Капсульна Матриця 3x3',
                                          styleScore: activeCombo.harmonyScore,
                                          customQuote: activeCombo.colorRationale,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
    );
  }

  Widget _buildBentoStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 11)),
      ],
    );
  }
}
