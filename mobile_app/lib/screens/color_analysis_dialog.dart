import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/wardrobe_provider.dart';
import '../services/color_analysis_service.dart';
import '../theme/app_theme.dart';

void showColorAnalysisDialog(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
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
  ColorSeason _selectedSeason = ColorSeason.warmAutumn;

  @override
  Widget build(BuildContext context) {
    final wardrobe = context.watch<WardrobeProvider>().items;
    final report = ColorAnalysisService.evaluateAlignment(
      wardrobe: wardrobe,
      season: _selectedSeason,
    );

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
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
                        'ШІ-Аналіз гармонії зовнішності та гардероба',
                        style: TextStyle(fontSize: 11.5, color: AppTheme.muted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Season Selection Chips
            const Text(
              'ОБЕРІТЬ ВАШ СЕЗОННИЙ КОЛЬОРОТИП:',
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppTheme.muted, letterSpacing: 0.8),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ColorSeason.values.map((season) {
                  final isSel = season == _selectedSeason;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(season.title),
                      selected: isSel,
                      selectedColor: AppTheme.primary,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                        color: isSel ? Colors.white : AppTheme.primary,
                      ),
                      backgroundColor: const Color(0xFFF4F4F5),
                      onSelected: (_) => setState(() => _selectedSeason = season),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),

            // Optimal Color Swatches
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'ВАША ПРИРОДНА ПАЛІТРА:',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.accent),
                      ),
                      Text(
                        _selectedSeason.title,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedSeason.description,
                    style: const TextStyle(fontSize: 12, color: AppTheme.secondary, height: 1.35),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: _selectedSeason.paletteSwatches.map((color) {
                      return Container(
                        width: 44,
                        height: 34,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.black12),
                          boxShadow: const [
                            BoxShadow(color: Color(0x11000000), blurRadius: 4, offset: Offset(0, 2)),
                          ],
                        ),
                      );
                    }).toList(),
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
                      const Text(
                        'СУМІСНІСТЬ ГАРДЕРОБА',
                        style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 1),
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
                            const SizedBox(height: 2),
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
            const SizedBox(height: 18),

            // Matching Items from Closet
            Text(
              'ІДЕАЛЬНО ПІДКРЕСЛЮЮТЬ ВАС (${report.matchingItems.length})',
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
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: report.matchingItems.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    final it = report.matchingItems[i];
                    return Container(
                      width: 90,
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
                            child: CachedNetworkImage(
                              imageUrl: it.imageUrl,
                              width: 90,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(4),
                            child: Text(
                              it.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
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
                child: const Text('Застосувати кольоротип'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
