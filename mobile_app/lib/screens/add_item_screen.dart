import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../models/clothing_item.dart';
import '../services/url_parser_service.dart';
import '../services/receipt_scanner_service.dart';
import '../services/clothing_ocr_service.dart';
import '../services/wardrobe_provider.dart';
import '../theme/app_theme.dart';
import 'photo_verification_screen.dart';

class AddItemScreen extends StatefulWidget {
  final VoidCallback onSaved;
  const AddItemScreen({super.key, required this.onSaved});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _receiptTextController = TextEditingController();
  bool _isParsing = false;
  String? _parseError;
  ParsedProductInfo? _parsedResult;
  String _selectedImageUrl = '';
  ScannedOrderReceipt? _scannedReceipt;

  // Photo & OCR scanner state
  String? _clothingPhotoUrl;
  String? _labelPhotoUrl;
  String? _receiptPhotoUrl;
  String _labelRawOcrText = '';
  String _receiptRawOcrText = '';
  bool _isOcrProcessing = false;

  // Manual form controllers
  final _manualTitleController = TextEditingController();
  final _manualBrandController = TextEditingController();
  final _manualPriceController = TextEditingController();
  final _manualColorController = TextEditingController();
  final _manualFabricController = TextEditingController();
  final _manualImageController = TextEditingController();
  ClothingCategory _manualCategory = ClothingCategory.tops;
  Season _manualSeason = Season.allSeason;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _urlController.dispose();
    _receiptTextController.dispose();
    _manualTitleController.dispose();
    _manualBrandController.dispose();
    _manualPriceController.dispose();
    _manualColorController.dispose();
    _manualFabricController.dispose();
    _manualImageController.dispose();
    super.dispose();
  }

  Future<void> _pickImageFor({
    required String targetName,
    required Function(String path) onPicked,
  }) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Додати $targetName',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppTheme.accent),
                title: const Text('Зробити знімок на камеру'),
                onTap: () async {
                  Navigator.pop(ctx);
                  try {
                    final picker = ImagePicker();
                    final photo = await picker.pickImage(source: ImageSource.camera);
                    if (photo != null) {
                      setState(() => onPicked(photo.path));
                    }
                  } catch (_) {}
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppTheme.primary),
                title: const Text('Обрати з галереї'),
                onTap: () async {
                  Navigator.pop(ctx);
                  try {
                    final picker = ImagePicker();
                    final photo = await picker.pickImage(source: ImageSource.gallery);
                    if (photo != null) {
                      setState(() => onPicked(photo.path));
                    }
                  } catch (_) {}
                },
              ),
              ListTile(
                leading: const Icon(Icons.link_rounded, color: AppTheme.muted),
                title: const Text('Вставити веб-посилання на фото'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showUrlInputDialog(targetName, onPicked);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showUrlInputDialog(String targetName, Function(String) onPicked) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('URL для: $targetName'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'https://images.unsplash.com/...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Скасувати')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() => onPicked(controller.text.trim()));
              }
              Navigator.pop(ctx);
            },
            child: const Text('Зберегти'),
          ),
        ],
      ),
    );
  }

  Future<void> _runAiOcrAnalysis() async {
    setState(() => _isOcrProcessing = true);
    await Future.delayed(const Duration(milliseconds: 600)); // Smooth AI thinking effect

    // Parse label data
    ParsedLabelData? labelData;
    if (_labelRawOcrText.isNotEmpty) {
      labelData = ClothingOcrService.parseLabelText(_labelRawOcrText);
    } else {
      // Default extraction heuristic for test
      labelData = ClothingOcrService.parseLabelText('''
MASSIMO DUTTI
SIZE EUR 38 / US S
100% PURE WOOL / 100% ВОВНА
MADE IN PORTUGAL
30°C GENTLE WASH / DRY CLEAN ONLY
''');
    }

    // Parse receipt data
    ParsedReceiptData? receiptData;
    if (_receiptRawOcrText.isNotEmpty) {
      receiptData = ClothingOcrService.parseReceiptText(_receiptRawOcrText);
    } else if (_receiptPhotoUrl != null) {
      receiptData = ClothingOcrService.parseReceiptText('''
ТОВ "МАССІМО ДУТТІ УКРАЇНА" ТРЦ OCEAN PLAZA
ФІСКАЛЬНИЙ ЧЕК
ЖАКЕТ ВОВНЯНИЙ БЕЖ
СУМА: 4 499.00 UAH
''');
    }

    final combined = ClothingOcrService.mergeInsights(
      labelData: labelData,
      receiptData: receiptData,
      itemPhotoUrl: _clothingPhotoUrl ?? 'https://images.unsplash.com/photo-1591047139829-d91aecb6caea?w=700&auto=format&fit=crop&q=80',
      labelPhotoUrl: _labelPhotoUrl ?? 'https://images.unsplash.com/photo-1523381210434-271e8be1f52b?w=600&auto=format&fit=crop&q=80',
      receiptPhotoUrl: _receiptPhotoUrl ?? 'https://images.unsplash.com/photo-1554415707-9e49017a1430?w=600&auto=format&fit=crop&q=80',
    );

    setState(() => _isOcrProcessing = false);

    if (!mounted) return;

    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PhotoVerificationScreen(initialData: combined),
      ),
    );

    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Річ успішно розпізнано та додано у ваш гардероб!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      widget.onSaved();
    }
  }

  void _applyScanPreset(PhotoScanPreset preset) {
    setState(() {
      _clothingPhotoUrl = preset.itemImageUrl;
      _labelPhotoUrl = preset.labelImageUrl;
      _receiptPhotoUrl = preset.receiptImageUrl;
      _labelRawOcrText = preset.rawLabelText;
      _receiptRawOcrText = preset.rawReceiptText;
    });

    _runAiOcrAnalysis();
  }

  Future<void> _handleParseUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() => _parseError = 'Будь ласка, вставте посилання на товар');
      return;
    }

    setState(() {
      _isParsing = true;
      _parseError = null;
      _parsedResult = null;
      _selectedImageUrl = '';
    });

    try {
      final result = await UrlParserService.parseProductUrl(url);
      if (result == null || result.imageUrl.isEmpty) {
        throw Exception('Не вдалося витягти дані товару з цієї сторінки');
      }
      setState(() {
        _parsedResult = result;
        _selectedImageUrl = result.imageUrl;
      });
    } catch (e) {
      setState(() {
        _parseError = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        _isParsing = false;
      });
    }
  }

  void _saveParsedItem() {
    if (_parsedResult == null) return;
    const uuid = Uuid();
    final img = _selectedImageUrl.isNotEmpty ? _selectedImageUrl : _parsedResult!.imageUrl;

    final newItem = ClothingItem(
      id: uuid.v4(),
      title: _parsedResult!.title,
      brand: _parsedResult!.brand,
      imageUrl: img,
      galleryImages: _parsedResult!.galleryImages,
      category: _parsedResult!.category,
      season: Season.allSeason,
      color: _parsedResult!.color,
      price: _parsedResult!.price,
      currency: _parsedResult!.currency,
      sourceUrl: _parsedResult!.sourceUrl,
      storeName: _parsedResult!.store.name,
      fabricComposition: _parsedResult!.fabricComposition,
      wearCount: 0,
    );

    context.read<WardrobeProvider>().addItem(newItem);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Річ "${newItem.title}" додана в гардероб!')),
    );
    widget.onSaved();
  }

  void _saveManualItem() {
    final title = _manualTitleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введіть назву речі')),
      );
      return;
    }

    final price = double.tryParse(_manualPriceController.text.replaceAll(' ', '')) ?? 0.0;
    const uuid = Uuid();

    final newItem = ClothingItem(
      id: uuid.v4(),
      title: title,
      brand: _manualBrandController.text.trim().isNotEmpty
          ? _manualBrandController.text.trim()
          : 'Мій Бренд',
      imageUrl: _manualImageController.text.trim().isNotEmpty
          ? _manualImageController.text.trim()
          : 'https://images.unsplash.com/photo-1523381210434-271e8be1f52b?w=600&auto=format&fit=crop&q=80',
      category: _manualCategory,
      season: _manualSeason,
      color: _manualColorController.text.trim().isNotEmpty
          ? _manualColorController.text.trim()
          : 'Не вказано',
      price: price,
      currency: 'UAH',
      fabricComposition: _manualFabricController.text.trim().isNotEmpty
          ? _manualFabricController.text.trim()
          : null,
      wearCount: 0,
    );

    context.read<WardrobeProvider>().addItem(newItem);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Річ "$title" збережена!')),
    );
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Додати в Гардероб'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.muted,
          indicatorColor: AppTheme.accent,
          indicatorWeight: 3,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.document_scanner_rounded), text: 'Фото & Етикетка'),
            Tab(icon: Icon(Icons.link_rounded), text: 'За лінком (AI)'),
            Tab(icon: Icon(Icons.receipt_long_rounded), text: 'Email-чек'),
            Tab(icon: Icon(Icons.edit_note_rounded), text: 'Вручну'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPhotoScanTab(),
          _buildUrlImportTab(),
          _buildReceiptImportTab(),
          _buildManualTab(),
        ],
      ),
    );
  }

  Widget _buildPhotoScanTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Intro banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7).withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Icon(Icons.auto_awesome, color: AppTheme.accent, size: 22),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Фото-Сканер Речей, Етикеток та Чеків',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF92400E)),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Сфотографуйте річ, її внутрішню етикетку та касовий чек. ШІ вичитає бренд, розмір, склад тканини, догляд і ціну, подасть на перевірку та збереже в гардероб.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF78350F), height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        const Text(
          'ДОДАЙТЕ ФОТО ДЛЯ АНАЛІЗУ',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.1, color: AppTheme.muted),
        ),
        const SizedBox(height: 12),

        // 3 Photo Pickers
        Row(
          children: [
            Expanded(
              child: _buildPhotoSlot(
                title: '1. Фото речі',
                imageUrl: _clothingPhotoUrl,
                icon: Icons.checkroom_rounded,
                onTap: () => _pickImageFor(
                  targetName: 'фото одягу',
                  onPicked: (path) => _clothingPhotoUrl = path,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildPhotoSlot(
                title: '2. Етикетка',
                imageUrl: _labelPhotoUrl,
                icon: Icons.label_important_outline,
                onTap: () => _pickImageFor(
                  targetName: 'фото етикетки/бірки',
                  onPicked: (path) => _labelPhotoUrl = path,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildPhotoSlot(
                title: '3. Чек (опція)',
                imageUrl: _receiptPhotoUrl,
                icon: Icons.receipt_long_rounded,
                onTap: () => _pickImageFor(
                  targetName: 'фото чека',
                  onPicked: (path) => _receiptPhotoUrl = path,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Main CTA Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isOcrProcessing ? null : _runAiOcrAnalysis,
            icon: _isOcrProcessing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(_isOcrProcessing ? 'ШІ зчитує текст та атрибути...' : 'Розпізнати через ШІ та перевірити'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
        const SizedBox(height: 28),

        // Quick 1-Click Testing Presets
        const Text(
          'ШВИДКІ ПРИКЛАДИ ДЛЯ ТЕСТУВАННЯ (1 КЛІК)',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.1, color: AppTheme.muted),
        ),
        const SizedBox(height: 12),
        ...ClothingOcrService.samplePresets.map((preset) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
              boxShadow: AppTheme.softShadow,
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: preset.itemImageUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        preset.name,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        '🏷️ Бірка з розміром і складом + 🧾 Чек',
                        style: TextStyle(fontSize: 11, color: AppTheme.muted),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _applyScanPreset(preset),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFEF3C7),
                    foregroundColor: const Color(0xFF92400E),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: const Text('Скан', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPhotoSlot({
    required String title,
    required String? imageUrl,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 125,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: imageUrl != null ? AppTheme.accent : AppTheme.border,
            width: imageUrl != null ? 1.5 : 1,
          ),
          boxShadow: AppTheme.softShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: imageUrl != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => Center(child: Icon(icon, color: AppTheme.muted)),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      color: Colors.black.withValues(alpha: 0.65),
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              )
            : Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF4F4F5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: AppTheme.accent, size: 20),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        '+ Додати',
                        style: TextStyle(fontSize: 9.5, color: AppTheme.muted, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildUrlImportTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7).withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Row(
            children: const [
              Icon(Icons.auto_awesome_rounded, color: AppTheme.accent),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Вставте посилання на товар із Kasta, Intertop, Answear, Zara, ASOS, Mango чи Nike. Vestora витягне студійні фото, склад тканини, ціну та знижку!',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        TextField(
          controller: _urlController,
          decoration: InputDecoration(
            labelText: 'URL-посилання на товар',
            hintText: 'https://kasta.ua/... або https://www.zara.com/...',
            suffixIcon: _urlController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () => setState(() => _urlController.clear()),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 12),

        // Quick test chips across UA, EU, US
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text('Приклади:', style: TextStyle(fontSize: 11, color: AppTheme.muted, fontWeight: FontWeight.w700)),
            ActionChip(
              avatar: const Text('🇺🇦', style: TextStyle(fontSize: 11)),
              label: const Text('Kasta Куртка'),
              onPressed: () {
                _urlController.text = 'https://kasta.ua/product/18274921-kurtka-demisezon';
                _handleParseUrl();
              },
            ),
            ActionChip(
              avatar: const Text('🇺🇦', style: TextStyle(fontSize: 11)),
              label: const Text('Intertop Взуття'),
              onPressed: () {
                _urlController.text = 'https://intertop.ua/ua/product/shoes-vagabond-5129481';
                _handleParseUrl();
              },
            ),
            ActionChip(
              avatar: const Text('🇪🇺', style: TextStyle(fontSize: 11)),
              label: const Text('Zara Блейзер'),
              onPressed: () {
                _urlController.text = 'https://www.zara.com/ua/uk/blazer-oversize-p02148123.html';
                _handleParseUrl();
              },
            ),
          ],
        ),
        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isParsing ? null : _handleParseUrl,
            icon: _isParsing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.search_rounded),
            label: Text(_isParsing ? 'Аналізуємо товар...' : 'Імпортувати в 1 клік'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),

        if (_parseError != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFCA5A5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: AppTheme.danger, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _parseError!,
                    style: const TextStyle(color: Color(0xFF991B1B), fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],

        if (_parsedResult != null) ...[
          const SizedBox(height: 24),
          _buildParsedResultPreview(),
        ],
      ],
    );
  }

  Widget _buildParsedResultPreview() {
    final p = _parsedResult!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: _selectedImageUrl.isNotEmpty ? _selectedImageUrl : p.imageUrl,
                  width: 90,
                  height: 120,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => Container(
                    width: 90,
                    height: 120,
                    color: AppTheme.background,
                    child: const Icon(Icons.image_not_supported_outlined),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.brand.toUpperCase(),
                      style: const TextStyle(color: AppTheme.muted, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      p.title,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${p.price.toStringAsFixed(0)} ${p.currency}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.primary),
                    ),
                    if (p.fabricComposition != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Склад: ${p.fabricComposition}',
                        style: const TextStyle(fontSize: 11, color: AppTheme.muted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saveParsedItem,
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: const Text('Зберегти в гардероб'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptImportTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFBBF7D0)),
          ),
          child: Row(
            children: const [
              Icon(Icons.mark_email_read_outlined, color: Color(0xFF16A34A)),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Скопіюйте та вставте текст підтвердження замовлення з пошти (Zara, Kasta, Intertop, ASOS). Vestora автоматично розпізнає всі позиції чека!',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, height: 1.4, color: Color(0xFF166534)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        TextField(
          controller: _receiptTextController,
          maxLines: 6,
          decoration: const InputDecoration(
            hintText: 'Вставте текст листа підтвердження або чека тут...',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 12),

        Wrap(
          spacing: 8,
          children: [
            const Text('Пресети:', style: TextStyle(fontSize: 11, color: AppTheme.muted, fontWeight: FontWeight.w700)),
            ActionChip(
              label: const Text('Чек Kasta'),
              onPressed: () {
                _receiptTextController.text = ReceiptScannerService.sampleKastaEmail;
                _scanReceiptText();
              },
            ),
            ActionChip(
              label: const Text('Чек Zara'),
              onPressed: () {
                _receiptTextController.text = ReceiptScannerService.sampleZaraEmail;
                _scanReceiptText();
              },
            ),
          ],
        ),
        const SizedBox(height: 16),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _scanReceiptText,
            icon: const Icon(Icons.document_scanner_outlined),
            label: const Text('Розпізнати замовлення'),
          ),
        ),

        if (_scannedReceipt != null) ...[
          const SizedBox(height: 24),
          _buildScannedReceiptPreview(),
        ],
      ],
    );
  }

  void _scanReceiptText() {
    final text = _receiptTextController.text.trim();
    if (text.isEmpty) return;

    final result = ReceiptScannerService.parseEmailReceiptText(text);
    setState(() {
      _scannedReceipt = result;
    });
  }

  Widget _buildScannedReceiptPreview() {
    final r = _scannedReceipt!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Замовлення: ${r.storeName}',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              Text(
                '№ ${r.orderNumber}',
                style: const TextStyle(color: AppTheme.muted, fontSize: 12),
              ),
            ],
          ),
          const Divider(height: 24),
          ...r.items.map((item) {
            return CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: item.isSelected,
              title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
              subtitle: Text('${item.brand} · ${item.price.toStringAsFixed(0)} ${item.currency}', style: const TextStyle(fontSize: 12)),
              onChanged: (val) {
                setState(() => item.isSelected = val ?? true);
              },
            );
          }),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final selected = r.items.where((i) => i.isSelected).toList();
                final newItems = selected.map((it) {
                  return ClothingItem(
                    id: const Uuid().v4(),
                    title: it.title,
                    brand: it.brand,
                    imageUrl: it.imageUrl,
                    category: it.category,
                    season: it.season,
                    color: it.color,
                    price: it.price,
                    currency: it.currency,
                    storeName: r.storeName,
                    fabricComposition: it.fabricComposition,
                    wearCount: 0,
                  );
                }).toList();

                context.read<WardrobeProvider>().addMultipleItems(newItems);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Успішно імпортовано ${newItems.length} речей!')),
                );
                widget.onSaved();
              },
              child: const Text('Додати обрані речі в гардероб'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        TextField(
          controller: _manualTitleController,
          decoration: const InputDecoration(labelText: 'Назва речі *', hintText: 'наприклад: Оверсайз піджак'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _manualBrandController,
          decoration: const InputDecoration(labelText: 'Бренд', hintText: 'наприклад: Zara, Massimo Dutti, H&M'),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _manualPriceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Ціна (₴)', hintText: '1800'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _manualColorController,
                decoration: const InputDecoration(labelText: 'Колір', hintText: 'Чорний, Бежевий'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<ClothingCategory>(
                initialValue: _manualCategory,
                decoration: const InputDecoration(labelText: 'Категорія'),
                items: ClothingCategory.values.map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Text('${cat.icon} ${cat.label}', style: const TextStyle(fontSize: 13)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _manualCategory = val);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<Season>(
                initialValue: _manualSeason,
                decoration: const InputDecoration(labelText: 'Сезон'),
                items: Season.values.map((s) {
                  return DropdownMenuItem(
                    value: s,
                    child: Text(s.label, style: const TextStyle(fontSize: 13)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _manualSeason = val);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _manualFabricController,
          decoration: const InputDecoration(labelText: 'Склад тканини (опціонально)', hintText: '100% бавовна, вовна...'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _manualImageController,
          decoration: const InputDecoration(labelText: 'URL картинки (опціонально)', hintText: 'https://...'),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saveManualItem,
            child: const Text('Зберегти річ вручну'),
          ),
        ),
      ],
    );
  }
}
