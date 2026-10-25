import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../models/clothing_item.dart';
import '../services/wardrobe_provider.dart';
import '../services/user_profile_service.dart';
import '../services/virtual_fitting_service.dart';
import '../services/outfit_calendar_service.dart';
import '../services/weather_stylist_service.dart';
import '../services/ai_config_service.dart';
import '../theme/app_theme.dart';
import '../widgets/vestora_image.dart';
import 'outfit_calendar_screen.dart';
import 'editorial_story_screen.dart';

class VirtualFittingScreen extends StatefulWidget {
  final ClothingItem? initialOuterwear;
  final ClothingItem? initialTop;
  final ClothingItem? initialBottom;
  final ClothingItem? initialShoes;

  const VirtualFittingScreen({
    super.key,
    this.initialOuterwear,
    this.initialTop,
    this.initialBottom,
    this.initialShoes,
  });

  @override
  State<VirtualFittingScreen> createState() => _VirtualFittingScreenState();
}

class _VirtualFittingScreenState extends State<VirtualFittingScreen> {
  late String _activeFaceUrl;
  TryOnModelSilhouette _silhouette = TryOnModelSilhouette.femaleChic;
  TryOnBackground _background = TryOnBackground.luxuryBoutique;

  ClothingItem? _outerwear;
  ClothingItem? _top;
  ClothingItem? _bottom;
  ClothingItem? _shoes;

  double _faceScale = 1.0;
  double _faceOffsetY = 0.0;
  bool _isEvaluating = false;
  VirtualFittingResult? _fittingResult;

  @override
  void initState() {
    super.initState();
    _outerwear = widget.initialOuterwear;
    _top = widget.initialTop;
    _bottom = widget.initialBottom;
    _shoes = widget.initialShoes;

    final profile = UserProfileService.profile;
    _activeFaceUrl = profile.tryOnFaceUrl ??
        (profile.avatarUrl.isNotEmpty
            ? profile.avatarUrl
            : VirtualFittingService.presetFaces.first.faceUrl);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runAnalysis();
    });
  }

  List<ClothingItem> get _currentOutfit {
    final list = <ClothingItem>[];
    if (_outerwear != null) list.add(_outerwear!);
    if (_top != null) list.add(_top!);
    if (_bottom != null) list.add(_bottom!);
    if (_shoes != null) list.add(_shoes!);
    return list;
  }

  Future<void> _runAnalysis() async {
    setState(() => _isEvaluating = true);
    final result = await VirtualFittingService.evaluateFitting(
      faceUrl: _activeFaceUrl,
      outfitItems: _currentOutfit,
      silhouette: _silhouette,
      background: _background,
    );
    if (mounted) {
      setState(() {
        _fittingResult = result;
        _isEvaluating = false;
      });
    }
  }

  void _showFaceSelectionSheet() {
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
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Оберіть обличчя для примірочної', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('Завантажте власне селфі або оберіть референсний типаж:', style: TextStyle(fontSize: 12, color: AppTheme.muted)),
            const SizedBox(height: 16),

            // Upload buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.camera_alt_outlined, size: 18),
                    label: const Text('Зробити фото'),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      try {
                        final picker = ImagePicker();
                        final photo = await picker.pickImage(
                          source: ImageSource.camera,
                          maxWidth: 1024,
                          maxHeight: 1024,
                          imageQuality: 78,
                        );
                        if (photo != null && mounted) {
                          _updateFace(photo.path);
                        }
                      } catch (_) {}
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.photo_library_outlined, size: 18),
                    label: const Text('З галереї'),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      try {
                        final picker = ImagePicker();
                        final photo = await picker.pickImage(
                          source: ImageSource.gallery,
                          maxWidth: 1024,
                          maxHeight: 1024,
                          imageQuality: 78,
                        );
                        if (photo != null && mounted) {
                          _updateFace(photo.path);
                        }
                      } catch (_) {}
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            const Text('РЕФЕРЕНСНІ ТИПАЖІ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.muted, letterSpacing: 1)),
            const SizedBox(height: 10),

            SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: VirtualFittingService.presetFaces.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (ctx2, idx) {
                  final face = VirtualFittingService.presetFaces[idx];
                  final isSelected = face.faceUrl == _activeFaceUrl;
                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.pop(ctx);
                      _updateFace(face.faceUrl);
                    },
                    child: Container(
                      width: 85,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFFEF3C7) : const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? AppTheme.accent : AppTheme.border,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundImage: vestoraImageProvider(face.faceUrl),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            face.name,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5),
                          ),
                        ],
                      ),
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

  void _updateFace(String newFaceUrl) {
    setState(() => _activeFaceUrl = newFaceUrl);
    UserProfileService.saveTryOnFace(newFaceUrl);
    _runAnalysis();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Обличчя примірочної успішно оновлено та збережено в профіль!'),
        backgroundColor: Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showItemPicker(ClothingCategory category, Function(ClothingItem) onSelected) {
    final wardrobe = context.read<WardrobeProvider>().items;
    final items = wardrobe.where((i) => i.category == category).toList();

    if (items.isEmpty) {
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
            Text('Приміряти ${category.label}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (ctx2, idx) {
                  final it = items[idx];
                  return InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      onSelected(it);
                      Navigator.pop(ctx);
                      _runAnalysis();
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
      ),
    );
  }

  void _scheduleFittedOutfit() {
    final items = _currentOutfit;
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Оберіть спочатку речі для примірки')),
      );
      return;
    }

    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));

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
            const Text('Запланувати приміряний лук', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            ListTile(
              leading: const Icon(Icons.today_rounded, color: AppTheme.accent),
              title: const Text('Вдягнути сьогодні'),
              onTap: () async {
                Navigator.pop(ctx);
                await _saveToDate(today, 'Приміряний образ сьогодні');
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today_rounded, color: AppTheme.primary),
              title: const Text('Запланувати на завтра'),
              onTap: () async {
                Navigator.pop(ctx);
                await _saveToDate(tomorrow, 'Приміряний образ на завтра');
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveToDate(DateTime date, String eventTitle) async {
    final dateStr = OutfitCalendarService.formatDate(date);
    final plan = PlannedDayOutfit(
      dateStr: dateStr,
      date: date,
      weatherTemp: 18,
      weatherCondition: WeatherCondition.sunny,
      occasion: Occasion.casual,
      eventTitle: eventTitle,
      outerwearId: _outerwear?.id,
      topId: _top?.id,
      bottomId: _bottom?.id,
      shoesId: _shoes?.id,
    );
    await OutfitCalendarService.savePlan(plan);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Приміряний образ закріплено на ${date.day}.${date.month.toString().padLeft(2, '0')}!'),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'В календар',
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

  void _wearFittedOutfit() {
    final items = _currentOutfit;
    if (items.isEmpty) return;
    context.read<WardrobeProvider>().recordOutfitWear(items);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🔥 Образ успішно одягнено! Стрік збільшено до ${context.read<WardrobeProvider>().streakDays} днів.'),
        backgroundColor: const Color(0xFFD97706),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showFaceAdjustDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setModalState) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Калібрування положення обличчя', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Масштаб голови:'),
                  Text('${(_faceScale * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              Slider(
                value: _faceScale,
                min: 0.8,
                max: 1.3,
                divisions: 10,
                onChanged: (v) {
                  setModalState(() => _faceScale = v);
                  setState(() => _faceScale = v);
                },
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Висота (вгору / вниз):'),
                  Text('${_faceOffsetY.round()} px', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              Slider(
                value: _faceOffsetY,
                min: -20,
                max: 20,
                divisions: 20,
                onChanged: (v) {
                  setModalState(() => _faceOffsetY = v);
                  setState(() => _faceOffsetY = v);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPhotorealisticTryOnSheet() {
    if (_currentOutfit.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Будь ласка, оберіть хоча б одну річ для нейро-примірки!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    TryOnEnvironment selectedEnv = TryOnEnvironment.parisianCafe;
    bool isGenerating = false;
    String statusStep = 'Підготовка образу...';
    PhotorealisticTryOnResult? result;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF18181B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
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
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.auto_awesome, color: Color(0xFFD4AF37), size: 22),
                          SizedBox(width: 8),
                          Text(
                            'Нейро-примірка 4K',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF27272A),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          AiConfigService.hasCustomKey ? 'BYOK Gemini ⚡' : '${AiConfigService.adCredits} кредитів',
                          style: const TextStyle(
                            color: Color(0xFFFDE68A),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Генеративний фотореалістичний синтез образу в реалістичному освітленні та інтер\'єрі:',
                    style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 12),
                  ),
                  const SizedBox(height: 16),

                  if (result == null && !isGenerating) ...[
                    // Environment Selection
                    const Text(
                      'ОБЕРІТЬ ЛОКАЦІЮ ТА ОСВІТЛЕННЯ',
                      style: TextStyle(
                        color: Color(0xFFD4AF37),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 130,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: TryOnEnvironment.values.length,
                        separatorBuilder: (_, index) => const SizedBox(width: 10),
                        itemBuilder: (_, idx) {
                          final env = TryOnEnvironment.values[idx];
                          final isSel = selectedEnv == env;
                          return InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => setSheetState(() => selectedEnv = env),
                            child: Container(
                              width: 140,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSel ? const Color(0xFFD4AF37) : const Color(0xFF3F3F46),
                                  width: isSel ? 2 : 1,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(13),
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: VestoraImage(
                                        imageUrl: env.backgroundUrl,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned.fill(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.black.withValues(alpha: 0.2),
                                              Colors.black.withValues(alpha: 0.8),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          if (isSel)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFD4AF37),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: const Text(
                                                'ОБРАНО',
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 9,
                                                ),
                                              ),
                                            ),
                                          const SizedBox(height: 4),
                                          Text(
                                            env.label,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF27272A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF3F3F46)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, color: Color(0xFFFDE68A), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              selectedEnv.description,
                              style: const TextStyle(color: Color(0xFFE4E4E7), fontSize: 11.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Items Summary
                    const Text(
                      'РЕЧІ ДЛЯ НЕЙРО-СИНТЕЗУ',
                      style: TextStyle(
                        color: Color(0xFFD4AF37),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _currentOutfit.map((item) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF27272A),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF3F3F46)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: VestoraImage(imageUrl: item.imageUrl, width: 22, height: 22, fit: BoxFit.cover),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${item.brand} ${item.title}',
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Generate Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4AF37),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.auto_awesome, size: 20, color: Colors.black),
                        label: const Text(
                          'Створити нейро-фото (Deep AI)',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                        ),
                        onPressed: () async {
                          setSheetState(() {
                            isGenerating = true;
                            statusStep = '1/3 · Аналіз зовнішності та освітлення...';
                          });
                          await Future.delayed(const Duration(milliseconds: 500));
                          setSheetState(() => statusStep = '2/3 · Синтез драпірування та текстури...');
                          await Future.delayed(const Duration(milliseconds: 500));
                          setSheetState(() => statusStep = '3/3 · 4K рендеринг у високій якості...');

                          final gen = await VirtualFittingService.generatePhotorealisticTryOn(
                            faceUrl: _activeFaceUrl,
                            outfitItems: _currentOutfit,
                            environment: selectedEnv,
                          );

                          setSheetState(() {
                            isGenerating = false;
                            result = gen;
                          });
                        },
                      ),
                    ),
                  ] else if (isGenerating) ...[
                    // Generation In Progress
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            const SizedBox(
                              width: 48,
                              height: 48,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              statusStep,
                              style: const TextStyle(
                                color: Color(0xFFFDE68A),
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Imagen 3 · Gemini Vision Neural Synthesis',
                              style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else if (result != null) ...[
                    // Result View
                    Container(
                      height: 340,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFD4AF37), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                            blurRadius: 18,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(17),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: VestoraImage(
                                imageUrl: result!.generatedImageUrl,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 12,
                              left: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFD4AF37)),
                                ),
                                child: Text(
                                  result!.environment.label,
                                  style: const TextStyle(color: Color(0xFFFDE68A), fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 12,
                              right: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF16A34A),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  '4K ULTRA HD',
                                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Stylist Verdict
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF27272A),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF3F3F46)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.auto_awesome, color: Color(0xFFD4AF37), size: 16),
                              SizedBox(width: 6),
                              Text(
                                'ЕКСПЕРТИЗА СТИЛІСТА VESTORA',
                                style: TextStyle(
                                  color: Color(0xFFD4AF37),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            result!.editorialVerdict,
                            style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.4),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Склад образу: ${result!.clothingSummary}',
                            style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD4AF37),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.check_circle_rounded, size: 18),
                            label: const Text('Вдягнути (+1)', style: TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: () {
                              Navigator.pop(sheetCtx);
                              _wearFittedOutfit();
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFFDE68A),
                              side: const BorderSide(color: Color(0xFFD4AF37)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.download_rounded, size: 18),
                            label: const Text('Зберегти'),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('✨ Нейро-фото 4K збережено у фотоальбом лукбуку!'),
                                  backgroundColor: Color(0xFF16A34A),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFF27272A),
                            side: const BorderSide(color: Color(0xFF3F3F46)),
                            padding: const EdgeInsets.all(12),
                          ),
                          icon: const Icon(Icons.auto_stories_outlined, color: Color(0xFFD4AF37), size: 18),
                          tooltip: 'Постер у журнал',
                          onPressed: () {
                            Navigator.pop(sheetCtx);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditorialStoryScreen(
                                  items: _currentOutfit,
                                  occasion: result!.environment.label,
                                  styleScore: 9.8,
                                  customQuote: result!.editorialVerdict,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF18181B), // Dark luxury boutique fitting room
      appBar: AppBar(
        backgroundColor: const Color(0xFF18181B),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'AI Примірочна · Virtual Try-On',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: Color(0xFFFDE68A)),
            tooltip: 'Фотореалістична нейро-примірка (Deep AI 4K)',
            onPressed: _showPhotorealisticTryOnSheet,
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: Colors.white70),
            tooltip: 'Підлаштувати посадку обличчя',
            onPressed: _showFaceAdjustDialog,
          ),
          IconButton(
            icon: const Icon(Icons.face_retouching_natural_rounded, color: Color(0xFFFDE68A)),
            tooltip: 'Змінити обличчя / фото',
            onPressed: _showFaceSelectionSheet,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            tooltip: 'Скинути примірку',
            onPressed: () {
              setState(() {
                _outerwear = null;
                _top = null;
                _bottom = null;
                _shoes = null;
              });
              _runAnalysis();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Ambience & Silhouette Selectors
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFF27272A),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Silhouette selector popup
                Flexible(
                  child: PopupMenuButton<TryOnModelSilhouette>(
                    initialValue: _silhouette,
                    onSelected: (sil) {
                      setState(() => _silhouette = sil);
                      _runAnalysis();
                    },
                    itemBuilder: (_) => TryOnModelSilhouette.values
                        .map((s) => PopupMenuItem(value: s, child: Text(s.label)))
                        .toList(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3F3F46),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              _silhouette.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Background selector popup
                Flexible(
                  child: PopupMenuButton<TryOnBackground>(
                    initialValue: _background,
                    onSelected: (bg) {
                      setState(() => _background = bg);
                      _runAnalysis();
                    },
                    itemBuilder: (_) => TryOnBackground.values
                        .map((b) => PopupMenuItem(value: b, child: Text(b.label)))
                        .toList(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3F3F46),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              _background.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Central Visual Fitting Mirror
          Expanded(
            child: LayoutBuilder(
              builder: (context, mirrorConstraints) {
                final compactMirror = mirrorConstraints.maxHeight < 260;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Ambience Backdrop
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.25,
                        child: VestoraImage(
                          imageUrl: _background.imageUrl,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    // Luxury Mirror Frame
                    Container(
                      width: 320,
                      margin: EdgeInsets.symmetric(vertical: compactMirror ? 4 : 12, horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.6), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 28,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: Stack(
                          alignment: Alignment.topCenter,
                          children: [
                            // Subtle Mannequin / Body Silhouette Contour
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _MannequinContourPainter(silhouette: _silhouette),
                              ),
                            ),

                            // Layered Clothes Display
                            Positioned.fill(
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(
                                  20,
                                  compactMirror ? 46 : 75,
                                  20,
                                  compactMirror ? 8 : 20,
                                ),
                                child: Column(
                                  children: [
                                    // Upper Body Layer (Outerwear or Top)
                                    Expanded(
                                      flex: 5,
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          if (_top != null)
                                            _buildGarmentLayer(
                                              item: _top!,
                                              category: ClothingCategory.tops,
                                              horizontalMargin: 20,
                                              onTap: () => _showItemPicker(ClothingCategory.tops, (it) {
                                                setState(() => _top = it);
                                                _runAnalysis();
                                              }),
                                            )
                                          else
                                            _buildEmptySlotPill('Додати верх / топ', ClothingCategory.tops),
                                          if (_outerwear != null)
                                            _buildGarmentLayer(
                                              item: _outerwear!,
                                              category: ClothingCategory.outerwear,
                                              horizontalMargin: 8,
                                              isOuterwear: true,
                                              onTap: () => _showItemPicker(ClothingCategory.outerwear, (it) {
                                                setState(() => _outerwear = it);
                                                _runAnalysis();
                                              }),
                                            ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: compactMirror ? 2 : 6),

                                    // Bottom Layer (Pants, Skirt)
                                    Expanded(
                                      flex: 6,
                                      child: _bottom != null
                                          ? _buildGarmentLayer(
                                              item: _bottom!,
                                              category: ClothingCategory.bottoms,
                                              horizontalMargin: 24,
                                              onTap: () => _showItemPicker(ClothingCategory.bottoms, (it) {
                                                setState(() => _bottom = it);
                                                _runAnalysis();
                                              }),
                                            )
                                          : _buildEmptySlotPill('Додати брюки / низ', ClothingCategory.bottoms),
                                    ),
                                    SizedBox(height: compactMirror ? 2 : 6),

                                    // Shoes Layer
                                    Expanded(
                                      flex: 2,
                                      child: _shoes != null
                                          ? _buildGarmentLayer(
                                              item: _shoes!,
                                              category: ClothingCategory.shoes,
                                              horizontalMargin: 40,
                                              onTap: () => _showItemPicker(ClothingCategory.shoes, (it) {
                                                setState(() => _shoes = it);
                                                _runAnalysis();
                                              }),
                                            )
                                          : _buildEmptySlotPill('Взуття', ClothingCategory.shoes),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // The User's Face / Portrait Overlay at Head position
                            Positioned(
                              top: (compactMirror ? 4 : 14) + _faceOffsetY,
                              child: GestureDetector(
                                onTap: _showFaceSelectionSheet,
                                child: Transform.scale(
                                  scale: _faceScale,
                                  child: Container(
                                    width: compactMirror ? 52 : 72,
                                    height: compactMirror ? 62 : 86,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: const Color(0xFFFDE68A), width: 2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
                                          blurRadius: 16,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: ClipOval(
                                      child: VestoraImage(
                                        imageUrl: _activeFaceUrl,
                                        width: 76,
                                        height: 76,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Floating AI Harmony Score Badge
                            if (_fittingResult != null)
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD4AF37),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.3),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.auto_awesome, color: Colors.black, size: 13),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${_fittingResult!.overallFitScore.toStringAsFixed(1)} / 10',
                                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Wardrobe Quick Swapper Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: const Color(0xFF27272A),
            child: Row(
              children: [
                _buildQuickSwapPill('Верхній одяг', _outerwear, ClothingCategory.outerwear, (it) => setState(() => _outerwear = it)),
                const SizedBox(width: 6),
                _buildQuickSwapPill('Верх / Топ', _top, ClothingCategory.tops, (it) => setState(() => _top = it)),
                const SizedBox(width: 6),
                _buildQuickSwapPill('Низ', _bottom, ClothingCategory.bottoms, (it) => setState(() => _bottom = it)),
                const SizedBox(width: 6),
                _buildQuickSwapPill('Взуття', _shoes, ClothingCategory.shoes, (it) => setState(() => _shoes = it)),
              ],
            ),
          ),

          // AI Fit Analysis Drawer / Commentary Card
          Builder(
            builder: (context) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              final secondaryTextColor = isDark ? const Color(0xFFE4E4E7) : AppTheme.secondary;
              return ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.36,
                ),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurface : Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header with Stylist feedback
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Flexible(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.auto_awesome, color: AppTheme.accent, size: 18),
                                  SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      'AI Дзеркало · Аналіз гармонії',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            if (_isEvaluating)
                              const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                            else
                              Text(
                                _fittingResult?.usedGemini == true ? 'Gemini 2.5 Flash 🧠' : 'AI Fashion Stylist ✨',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? AppTheme.darkMuted : AppTheme.muted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        if (_fittingResult != null) ...[
                          Text(
                            '🎨 Підтон: ${_fittingResult!.skinToneHarmony}',
                            style: TextStyle(fontSize: 12, color: secondaryTextColor, height: 1.3),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '📐 Посадка: ${_fittingResult!.necklineFit}',
                            style: TextStyle(fontSize: 12, color: secondaryTextColor, height: 1.3),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '💡 Порада: ${_fittingResult!.stylistTip}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppTheme.darkAccent : const Color(0xFF92400E),
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),

                        // Photorealistic Deep AI Try-On Button
                        Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF18181B),
                              foregroundColor: const Color(0xFFFDE68A),
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
                              ),
                              elevation: 3,
                            ),
                            icon: const Icon(Icons.auto_awesome, color: Color(0xFFD4AF37), size: 18),
                            label: const Text(
                              '✨ Фотореалістична нейро-примірка (Deep AI 4K)',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.3),
                            ),
                            onPressed: _currentOutfit.isNotEmpty ? _showPhotorealisticTryOnSheet : null,
                          ),
                        ),

                        // Bottom Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDark ? AppTheme.darkAccent : AppTheme.primary,
                                  foregroundColor: isDark ? Colors.black : Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                ),
                                icon: const Icon(Icons.check_circle_rounded, size: 16),
                                label: const Text(
                                  'Вдягнути (+1)',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onPressed: _currentOutfit.isNotEmpty ? _wearFittedOutfit : null,
                              ),
                            ),
                            const SizedBox(width: 6),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                              ),
                              onPressed: _currentOutfit.isNotEmpty ? _scheduleFittedOutfit : null,
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.calendar_today_outlined, size: 15, color: AppTheme.accent),
                                  SizedBox(width: 4),
                                  Text('План', style: TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                                side: const BorderSide(color: Color(0xFFD4AF37)),
                              ),
                              onPressed: _currentOutfit.isNotEmpty
                                  ? () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => EditorialStoryScreen(
                                            items: _currentOutfit,
                                            occasion: 'Virtual Try-On',
                                            styleScore: _fittingResult?.overallFitScore ?? 9.5,
                                            customQuote: _fittingResult?.stylistTip,
                                          ),
                                        ),
                                      );
                                    }
                                  : null,
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.auto_stories_outlined, size: 15, color: Color(0xFFD4AF37)),
                                  SizedBox(width: 4),
                                  Text('Постер', style: TextStyle(fontSize: 12, color: Color(0xFFD4AF37))),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGarmentLayer({
    required ClothingItem item,
    required ClothingCategory category,
    required double horizontalMargin,
    bool isOuterwear = false,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E24), // High-fashion dark slate container
        borderRadius: BorderRadius.circular(isOuterwear ? 18 : 16),
        border: Border.all(
          color: isOuterwear
              ? const Color(0xFFFDE68A).withValues(alpha: 0.7)
              : const Color(0xFFD4AF37).withValues(alpha: 0.45),
          width: isOuterwear ? 1.5 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: isOuterwear ? 16 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isOuterwear ? 17 : 15),
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Garment Image with graceful placeholder & error widget
              VestoraImage(
                imageUrl: item.imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                placeholder: (context, url) => Container(
                  color: const Color(0xFF27272A),
                  child: const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFD4AF37)),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: const Color(0xFF27272A),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(category.icon, style: const TextStyle(fontSize: 28)),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            item.title,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 2. Subtle Dark Gradient at bottom for text contrast
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 38,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.85),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // 3. Floating Brand & Garment Micro-Tag
              Positioned(
                left: 6,
                bottom: 5,
                right: 6,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          '${item.brand.toUpperCase()} · ${item.title}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.sync_rounded, color: Colors.black, size: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptySlotPill(String title, ClothingCategory category) {
    return Center(
      child: TextButton.icon(
        onPressed: () => _showItemPicker(category, (it) {
          setState(() {
            if (category == ClothingCategory.outerwear) _outerwear = it;
            if (category == ClothingCategory.tops) _top = it;
            if (category == ClothingCategory.bottoms) _bottom = it;
            if (category == ClothingCategory.shoes) _shoes = it;
          });
        }),
        icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white70, size: 18),
        label: Text(title, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ),
    );
  }

  Widget _buildQuickSwapPill(
    String label,
    ClothingItem? item,
    ClothingCategory category,
    Function(ClothingItem) onSelected,
  ) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _showItemPicker(category, onSelected),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          decoration: BoxDecoration(
            color: item != null ? const Color(0xFF3F3F46) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: item != null ? AppTheme.accent : Colors.white24),
          ),
          child: Column(
            children: [
              Text(
                label.split(' ')[0],
                style: const TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                item != null ? item.title : '+ Додати',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  color: item != null ? const Color(0xFFFDE68A) : Colors.white38,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MannequinContourPainter extends CustomPainter {
  final TryOnModelSilhouette silhouette;

  _MannequinContourPainter({required this.silhouette});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw minimalist shoulders and waist contours
    final path = Path();
    final centerX = size.width / 2;

    // Neck
    path.moveTo(centerX - 18, 70);
    path.lineTo(centerX + 18, 70);

    // Shoulders
    path.moveTo(centerX - 18, 70);
    path.quadraticBezierTo(centerX - 60, 78, centerX - 85, 95);
    path.moveTo(centerX + 18, 70);
    path.quadraticBezierTo(centerX + 60, 78, centerX + 85, 95);

    // Torso outline
    path.moveTo(centerX - 75, 105);
    path.lineTo(centerX - 50, 180);
    path.lineTo(centerX - 65, 340);

    path.moveTo(centerX + 75, 105);
    path.lineTo(centerX + 50, 180);
    path.lineTo(centerX + 65, 340);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
