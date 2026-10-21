import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../models/clothing_item.dart';
import '../services/wardrobe_provider.dart';
import '../services/user_profile_service.dart';
import '../services/virtual_fitting_service.dart';
import '../services/outfit_calendar_service.dart';
import '../services/weather_stylist_service.dart';
import '../theme/app_theme.dart';
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
                        final photo = await picker.pickImage(source: ImageSource.camera);
                        if (photo != null) {
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
                        final photo = await picker.pickImage(source: ImageSource.gallery);
                        if (photo != null) {
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
                            backgroundImage: CachedNetworkImageProvider(face.faceUrl),
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
                PopupMenuButton<TryOnModelSilhouette>(
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
                      children: [
                        Text(_silhouette.label.split(' ')[0], style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Text(
                          _silhouette.label.split(' ')[1],
                          style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600),
                        ),
                        const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 18),
                      ],
                    ),
                  ),
                ),

                // Background selector popup
                PopupMenuButton<TryOnBackground>(
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
                      children: [
                        Text(_background.label.split(' ')[0], style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Text(
                          _background.label.split(' ')[1],
                          style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600),
                        ),
                        const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 18),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Central Visual Fitting Mirror
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Ambience Backdrop
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.25,
                    child: CachedNetworkImage(
                      imageUrl: _background.imageUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                // Luxury Mirror Frame
                Container(
                  width: 320,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.6), width: 2), // Gold mirror bezel
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
                            padding: const EdgeInsets.fromLTRB(24, 75, 24, 20),
                            child: Column(
                              children: [
                                // Upper Body Layer (Outerwear or Top)
                                Expanded(
                                  flex: 5,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Top
                                      if (_top != null)
                                        Container(
                                          margin: const EdgeInsets.symmetric(horizontal: 20),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(16),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.3),
                                                blurRadius: 10,
                                              ),
                                            ],
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(16),
                                            child: CachedNetworkImage(
                                              imageUrl: _top!.imageUrl,
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                            ),
                                          ),
                                        )
                                      else
                                        _buildEmptySlotPill('Додати верх / топ', ClothingCategory.tops),

                                      // Outerwear Layer over Top
                                      if (_outerwear != null)
                                        Container(
                                          margin: const EdgeInsets.symmetric(horizontal: 8),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(18),
                                            border: Border.all(color: Colors.white30, width: 1),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.4),
                                                blurRadius: 14,
                                              ),
                                            ],
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(18),
                                            child: CachedNetworkImage(
                                              imageUrl: _outerwear!.imageUrl,
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),

                                // Bottom Layer (Pants, Skirt)
                                Expanded(
                                  flex: 6,
                                  child: _bottom != null
                                      ? Container(
                                          margin: const EdgeInsets.symmetric(horizontal: 24),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(16),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.3),
                                                blurRadius: 10,
                                              ),
                                            ],
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(16),
                                            child: CachedNetworkImage(
                                              imageUrl: _bottom!.imageUrl,
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                            ),
                                          ),
                                        )
                                      : _buildEmptySlotPill('Додати брюки / низ', ClothingCategory.bottoms),
                                ),
                                const SizedBox(height: 6),

                                // Shoes Layer
                                Expanded(
                                  flex: 2,
                                  child: _shoes != null
                                      ? Container(
                                          margin: const EdgeInsets.symmetric(horizontal: 40),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.3),
                                                blurRadius: 8,
                                              ),
                                            ],
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: CachedNetworkImage(
                                              imageUrl: _shoes!.imageUrl,
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                            ),
                                          ),
                                        )
                                      : _buildEmptySlotPill('Взуття', ClothingCategory.shoes),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // The User's Face / Portrait Overlay at Head position
                        Positioned(
                          top: 14 + _faceOffsetY,
                          child: GestureDetector(
                            onTap: _showFaceSelectionSheet,
                            child: Transform.scale(
                              scale: _faceScale,
                              child: Container(
                                width: 72,
                                height: 86,
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
                                  child: CachedNetworkImage(
                                    imageUrl: _activeFaceUrl,
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
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with Stylist feedback
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.auto_awesome, color: AppTheme.accent, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'AI Дзеркало · Аналіз гармонії',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                      ],
                    ),
                    if (_isEvaluating)
                      const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                    else
                      Text(
                        _fittingResult?.usedGemini == true ? 'Gemini 2.5 Flash 🧠' : 'AI Fashion Stylist ✨',
                        style: const TextStyle(fontSize: 11, color: AppTheme.muted, fontWeight: FontWeight.w600),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                if (_fittingResult != null) ...[
                  Text(
                    '🎨 Підтон: ${_fittingResult!.skinToneHarmony}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.secondary, height: 1.3),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '📐 Посадка: ${_fittingResult!.necklineFit}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.secondary, height: 1.3),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '💡 Порада: ${_fittingResult!.stylistTip}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF92400E), fontWeight: FontWeight.w600, height: 1.3),
                  ),
                ],
                const SizedBox(height: 12),

                // Bottom Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.check_circle_rounded, size: 18),
                        label: const Text('Вдягнути (+1)'),
                        onPressed: _currentOutfit.isNotEmpty ? _wearFittedOutfit : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      ),
                      icon: const Icon(Icons.calendar_today_outlined, size: 16, color: AppTheme.accent),
                      label: const Text('Календар'),
                      onPressed: _currentOutfit.isNotEmpty ? _scheduleFittedOutfit : null,
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                        side: const BorderSide(color: Color(0xFFD4AF37)),
                      ),
                      icon: const Icon(Icons.auto_stories_outlined, size: 16, color: Color(0xFFD4AF37)),
                      label: const Text('Постер', style: TextStyle(color: Color(0xFFD4AF37))),
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
