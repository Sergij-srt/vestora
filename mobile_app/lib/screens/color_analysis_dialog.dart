import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../services/wardrobe_provider.dart';
import '../services/color_analysis_service.dart';
import '../widgets/controller_scope.dart';
import '../widgets/vestora_image.dart';
import '../theme/app_theme.dart';

void showColorAnalysisDialog(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => const ColorAnalysisSheet(),
  );
}

class ColorAnalysisSheet extends StatefulWidget {
  const ColorAnalysisSheet({super.key});

  @override
  State<ColorAnalysisSheet> createState() => _ColorAnalysisSheetState();
}

class _ColorAnalysisSheetState extends State<ColorAnalysisSheet> {
  late ColorPaletteGroup _activePalette;
  List<ColorPaletteGroup> _customPalettes = [];

  @override
  void initState() {
    super.initState();
    _activePalette = ColorPaletteGroup.fromSeason(ColorSeason.warmAutumn);
    _loadCustomPalettes();
  }

  Future<void> _loadCustomPalettes() async {
    final list = await ColorAnalysisService.loadCustomPalettes();
    if (mounted) {
      setState(() {
        _customPalettes = list;
      });
    }
  }

  void _openCreateOrEditPaletteDialog({ColorPaletteGroup? existing}) {
    final isEditing = existing != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark ? AppTheme.darkMuted : AppTheme.muted;
    final accentColor = isDark ? AppTheme.darkAccent : AppTheme.accent;
    final currentSwatches = List<NamedColorSwatch>.from(
      existing?.swatches ?? [
        const NamedColorSwatch(name: 'Теплий беж', color: Color(0xFFD7C4B7)),
        const NamedColorSwatch(name: 'Шоколад', color: Color(0xFF78350F)),
        const NamedColorSwatch(name: 'Молочний', color: Color(0xFFFAF5EE)),
      ],
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return ControllerScope(
          create: () => [
            TextEditingController(text: existing?.title ?? ''),
            TextEditingController(text: existing?.description ?? ''),
          ],
          builder: (scopeCtx, controllers) {
            final titleController = controllers[0];
            final descController = controllers[1];
            return StatefulBuilder(
              builder: (dialogCtx, setModalState) {
                return Padding(
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 16,
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
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.darkBorder : AppTheme.border,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(Icons.palette_outlined, color: accentColor),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isEditing ? 'Редагувати колірну групу' : 'Створити власну колірну палітру',
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Palette Name
                        Text('НАЗВА ГРУПИ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: mutedColor)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: titleController,
                          decoration: const InputDecoration(
                            hintText: 'напр. Моя Капсула Офіс або Old Money Navy',
                            prefixIcon: Icon(Icons.label_important_outline, size: 20),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Palette Description
                        Text('ОПИС / НАСТРІЙ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: mutedColor)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: descController,
                          decoration: const InputDecoration(
                            hintText: 'напр. Стримані преміальні відтінки для ділових зустрічей',
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Current Selected Swatches
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('ВІДТІНКИ У ПАЛІТРІ:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: mutedColor)),
                            Text('${currentSwatches.length} кольорів', style: TextStyle(fontSize: 11, color: mutedColor)),
                          ],
                        ),
                        const SizedBox(height: 10),

                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: currentSwatches.map((swatch) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isDark ? AppTheme.darkCard : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.border),
                                boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 4)],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 18,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      color: swatch.color,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.black12),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(swatch.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                  const SizedBox(width: 6),
                                  InkWell(
                                    onTap: () {
                                      if (currentSwatches.length > 1) {
                                        setModalState(() => currentSwatches.remove(swatch));
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Палітра повинна містити хоча б 1 колір.')),
                                        );
                                      }
                                    },
                                    child: Icon(Icons.close_rounded, size: 16, color: mutedColor),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 18),

                        // Quick-Pick Library
                        Text(
                          'ШВИДКИЙ ВИБІР З БІБЛІОТЕКИ ВІДТІНКІВ:',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: accentColor),
                        ),
                        const SizedBox(height: 8),

                        SizedBox(
                          height: 86,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: ColorAnalysisService.curatedLuxurySwatches.length,
                            separatorBuilder: (_, _) => const SizedBox(width: 8),
                            itemBuilder: (ctx, i) {
                              final item = ColorAnalysisService.curatedLuxurySwatches[i];
                              final isAdded = currentSwatches.any((s) => s.name == item.name);
                              return InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  if (!isAdded) {
                                    setModalState(() => currentSwatches.add(item));
                                  } else {
                                    setModalState(() => currentSwatches.removeWhere((s) => s.name == item.name));
                                  }
                                },
                                child: Container(
                                  width: 78,
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: isAdded
                                        ? (isDark ? const Color(0xFF1E3A8A) : const Color(0xFFEFF6FF))
                                        : (isDark ? AppTheme.darkCard : Colors.white),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: isAdded ? const Color(0xFF3B82F6) : (isDark ? AppTheme.darkBorder : AppTheme.border), width: isAdded ? 1.5 : 1),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: item.color,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.black12),
                                        ),
                                        child: isAdded
                                            ? const Icon(Icons.check, size: 14, color: Colors.white)
                                            : null,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item.name,
                                        maxLines: 2,
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: isAdded ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 22),

                        // Save CTA
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.check_rounded),
                            label: Text(isEditing ? 'Оновити колірну групу' : 'Зберегти палітру та створити образи'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: isDark ? AppTheme.darkAccent : AppTheme.primary,
                              foregroundColor: isDark ? Colors.black : Colors.white,
                            ),
                            onPressed: () async {
                              final name = titleController.text.trim();
                              if (name.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Введіть назву колірної групи')),
                                );
                                return;
                              }

                              final newGroup = ColorPaletteGroup(
                                id: existing?.id ?? const Uuid().v4(),
                                title: name,
                                description: descController.text.trim().isNotEmpty
                                    ? descController.text.trim()
                                    : 'Персональна авторська палітра.',
                                swatches: currentSwatches,
                                matchingKeywords: currentSwatches.map((s) => s.name.toLowerCase()).toList(),
                                isCustom: true,
                              );

                              await ColorAnalysisService.saveCustomPalette(newGroup);
                              if (dialogCtx.mounted) {
                                Navigator.pop(dialogCtx);
                              }
                              await _loadCustomPalettes();
                              if (mounted) {
                                setState(() {
                                  _activePalette = newGroup;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('🎉 Колірну групу "$name" створено! Образи підібрано.'),
                                    backgroundColor: AppTheme.success,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _wearCuratedOutfit(PaletteOutfitVariant outfit) {
    context.read<WardrobeProvider>().recordOutfitWear(outfit.items);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✨ Образ "${outfit.title}" одягнено на сьогодні! Зараховано до стріку.'),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wardrobe = context.watch<WardrobeProvider>().items;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.darkCard : Colors.white;
    final subtleCard = isDark ? AppTheme.darkBackground : const Color(0xFFF8F9FA);
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.border;
    final report = ColorAnalysisService.evaluateAlignment(
      wardrobe: wardrobe,
      palette: _activePalette,
    );

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Dialog Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.palette_rounded, color: AppTheme.accent),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Персональний Кольоротип',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'ШІ-Аналіз та підбір готових образів за кольорами',
                        style: TextStyle(fontSize: 11.5, color: AppTheme.muted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Закрити',
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Palette Horizontal Selector (Presets + Custom Groups + Create New Button)
            Wrap(
              spacing: 8,
              runSpacing: 6,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text(
                  'ОБЕРІТЬ ПАЛІТРУ АБО СТВОРІТЬ СВОЮ:',
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppTheme.muted, letterSpacing: 0.8),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _openCreateOrEditPaletteDialog(),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_circle_outline_rounded, size: 14, color: AppTheme.accent),
                        SizedBox(width: 4),
                        Text(
                          '+ Нова група',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.accent),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // 4 Seasonal Presets
                  ...ColorSeason.values.map((season) {
                    final isSel = !_activePalette.isCustom && _activePalette.id == season.name;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(season.title),
                        selected: isSel,
                        selectedColor: isDark ? AppTheme.darkAccent : AppTheme.primary,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                          color: isSel
                              ? (isDark ? Colors.black : Colors.white)
                              : (isDark ? Colors.white : AppTheme.primary),
                        ),
                        backgroundColor: isDark ? AppTheme.darkCard : const Color(0xFFF4F4F5),
                        onSelected: (_) => setState(() {
                          _activePalette = ColorPaletteGroup.fromSeason(season);
                        }),
                      ),
                    );
                  }),

                  // User Custom Palettes
                  ..._customPalettes.map((custom) {
                    final isSel = _activePalette.isCustom && _activePalette.id == custom.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        avatar: const Text('✨', style: TextStyle(fontSize: 11)),
                        label: Text(custom.title),
                        selected: isSel,
                        selectedColor: const Color(0xFF4F46E5),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                          color: isSel ? Colors.white : const Color(0xFF4F46E5),
                        ),
                        backgroundColor: const Color(0xFFEEF2FF),
                        onSelected: (_) => setState(() {
                          _activePalette = custom;
                        }),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Active Palette Swatches Card + Change Colors Button
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: subtleCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Wrap(
                        spacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            _activePalette.isCustom ? 'ВАША АВТОРСЬКА ПАЛІТРА:' : 'ВАША ПРИРОДНА ПАЛІТРА:',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.accent),
                          ),
                          Text(
                            _activePalette.title,
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                            icon: Icon(Icons.tune_rounded, size: 14, color: isDark ? AppTheme.darkAccent : AppTheme.primary),
                            label: Text(
                              'Змінити кольори',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppTheme.darkAccent : AppTheme.primary,
                              ),
                            ),
                            onPressed: () => _openCreateOrEditPaletteDialog(
                              existing: _activePalette.isCustom ? _activePalette : _activePalette.copyWith(isCustom: true, title: 'Моя ${_activePalette.title}'),
                            ),
                          ),
                          if (_activePalette.isCustom)
                            IconButton(
                              tooltip: 'Видалити групу',
                              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                              onPressed: () async {
                                await ColorAnalysisService.deleteCustomPalette(_activePalette.id);
                                await _loadCustomPalettes();
                                setState(() {
                                  _activePalette = ColorPaletteGroup.fromSeason(ColorSeason.warmAutumn);
                                });
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _activePalette.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? const Color(0xFFD4D4D8) : AppTheme.secondary,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Swatches Row with Swatch Names
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _activePalette.swatches.map((swatch) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Column(
                            children: [
                              Container(
                                width: 44,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: swatch.color,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.black12),
                                  boxShadow: const [
                                    BoxShadow(color: Color(0x11000000), blurRadius: 4, offset: Offset(0, 2)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              SizedBox(
                                width: 48,
                                child: Text(
                                  swatch.name,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 9, color: AppTheme.muted, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Wardrobe Alignment Score Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF18181B), Color(0xFF27272A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Flexible(
                        child: Text(
                          'СУМІСНІСТЬ ГАРДЕРОБА',
                          style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 1),
                        ),
                      ),
                      Text(
                        '${report.matchingCount} з ${report.totalCount} речей',
                        style: const TextStyle(color: Color(0xFFFDE68A), fontWeight: FontWeight.w700, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        '${report.alignmentPercentage.toStringAsFixed(0)}%',
                        style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              report.verdict,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: report.alignmentPercentage / 100.0,
                              backgroundColor: const Color(0xFF3F3F46),
                              valueColor: const AlwaysStoppedAnimation(Color(0xFFD97706)),
                              minHeight: 5,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    report.personalTip,
                    style: const TextStyle(color: Color(0xFFE4E4E7), fontSize: 11.5, height: 1.35),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // System-Prepared Variants of Clothes using Color Palette
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '👗 ГОТОВІ ОБРАЗИ З ШАФИ ЗА ЦІЄЮ ПАЛІТРОЮ:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppTheme.primary,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${report.curatedOutfits.length} варіанти',
                  style: const TextStyle(fontSize: 11, color: AppTheme.muted, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (report.curatedOutfits.isEmpty)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: subtleCard,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'Додайте більше речей у гардероб, щоб ШІ склав повні комбінації за цією палітрою.',
                  style: TextStyle(fontSize: 12, color: AppTheme.muted),
                ),
              )
            else
              ...report.curatedOutfits.map((variant) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: borderColor),
                    boxShadow: isDark ? const [] : AppTheme.softShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              variant.title,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFA7F3D0)),
                            ),
                            child: Text(
                              '💎 ${variant.matchScore}/10',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        variant.styleDescription,
                        style: const TextStyle(fontSize: 11.5, color: AppTheme.muted),
                      ),
                      const SizedBox(height: 12),

                      // Outfit Items Carousel / Row
                      SizedBox(
                        height: 105,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: variant.items.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (context, i) {
                            final it = variant.items[i];
                            return Container(
                              width: 85,
                              decoration: BoxDecoration(
                                color: subtleCard,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: borderColor),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: VestoraImage(
                                      imageUrl: it.imageUrl,
                                      width: 85,
                                      height: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          it.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          it.color,
                                          maxLines: 1,
                                          style: const TextStyle(fontSize: 8.5, color: AppTheme.accent, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Wear Outfit Action CTA
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _wearCuratedOutfit(variant),
                          icon: const Icon(Icons.checkroom_rounded, size: 16),
                          label: const Text('Одягнути цей готовий образ', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),

            const SizedBox(height: 14),

            // Matching Items from Closet
            Text(
              'УСІ ВІДПОВІДНІ РЕЧІ З ШАФИ (${report.matchingItems.length})',
              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppTheme.muted, letterSpacing: 0.8),
            ),
            const SizedBox(height: 10),
            if (report.matchingItems.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('У цій палітрі поки немає речей у вашій шафі.', style: TextStyle(fontSize: 12, color: AppTheme.muted)),
              )
            else
              SizedBox(
                height: 110,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: report.matchingItems.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    final it = report.matchingItems[i];
                    return Container(
                      width: 85,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: VestoraImage(
                              imageUrl: it.imageUrl,
                              width: 85,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(4),
                            child: Text(
                              it.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Застосувати палітру для гардероба'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
