import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import '../models/clothing_item.dart';
import '../services/url_parser_service.dart';
import '../services/receipt_scanner_service.dart';
import '../services/clothing_ocr_service.dart';
import '../services/wardrobe_provider.dart';
import '../services/ai_config_service.dart';
import '../services/gemini_vision_service.dart';
import '../widgets/controller_scope.dart';
import '../widgets/vestora_image.dart';
import '../theme/app_theme.dart';
import 'photo_verification_screen.dart';
import 'settings_ai_screen.dart';
import 'settings_hub_screen.dart';

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
  bool _isPickingPhoto = false;

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
    AiConfigService.initialize().then((_) {
      if (mounted) setState(() {});
    });
    _checkLostImageData();
  }

  Future<void> _checkLostImageData() async {
    try {
      final picker = ImagePicker();
      final response = await picker.retrieveLostData();
      if (!response.isEmpty && response.file != null && mounted) {
        final bytes = await response.file!.readAsBytes();
        if (bytes.isNotEmpty) {
          final rawMime = response.file!.mimeType;
          final mime = (rawMime != null && rawMime.trim().isNotEmpty) ? rawMime.trim() : 'image/jpeg';
          final dataUri = 'data:$mime;base64,${base64Encode(bytes)}';
          setState(() {
            _clothingPhotoUrl ??= dataUri;
          });
        }
      }
    } catch (_) {}
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
                  await _captureImage(ImageSource.camera, onPicked);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppTheme.primary),
                title: const Text('Обрати з галереї'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _captureImage(ImageSource.gallery, onPicked);
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

  Future<void> _captureImage(ImageSource source, Function(String) onPicked) async {
    setState(() => _isPickingPhoto = true);
    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 75,
      );
      if (photo != null) {
        final bytes = await photo.readAsBytes();
        if (bytes.isNotEmpty) {
          final rawMime = photo.mimeType;
          final mime = (rawMime != null && rawMime.trim().isNotEmpty) ? rawMime.trim() : 'image/jpeg';
          final dataUri = 'data:$mime;base64,${base64Encode(bytes)}';
          if (mounted) {
            setState(() => onPicked(dataUri));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('📸 Фото успішно прикріплено!'),
                duration: Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Помилка відкриття камери/галереї: $e'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPickingPhoto = false);
      }
    }
  }

  void _showUrlInputDialog(String targetName, Function(String) onPicked) {
    showDialog(
      context: context,
      builder: (ctx) => ControllerScope(
        create: () => [TextEditingController()],
        builder: (dialogCtx, ctrls) {
          final controller = ctrls[0];
          return AlertDialog(
            title: Text('URL для: $targetName'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: 'https://images.unsplash.com/...'),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Скасувати')),
              ElevatedButton(
                onPressed: () {
                  final text = controller.text.trim();
                  if (text.isNotEmpty) {
                    setState(() => onPicked(text));
                  }
                  Navigator.pop(dialogCtx);
                },
                child: const Text('Зберегти'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _runAiOcrAnalysis() async {
    // 1. Ensure at least one photo or text is provided
    final hasAnyPhoto = (_clothingPhotoUrl != null && _clothingPhotoUrl!.isNotEmpty) ||
        (_labelPhotoUrl != null && _labelPhotoUrl!.isNotEmpty) ||
        (_receiptPhotoUrl != null && _receiptPhotoUrl!.isNotEmpty);

    final hasTextPreset = _labelRawOcrText.isNotEmpty || _receiptRawOcrText.isNotEmpty;

    if (!hasAnyPhoto && !hasTextPreset) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📸 Будь ласка, зробіть або оберіть фото вашого одягу чи етикетки.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // 2. If user is scanning their own photos without an API key, guide them
    if (!hasTextPreset && !AiConfigService.hasCustomKey) {
      final choice = await _showAiKeyPromptDialog();
      if (choice == null) return; // User closed modal
      if (choice == 'manual') {
        _openManualVerificationScreen();
        return;
      }
      // If 'saved', user configured key; continue to AI vision below
    }

    setState(() => _isOcrProcessing = true);

    final result = await GeminiVisionService.analyzePhotos(
      clothingPhotoUrl: _clothingPhotoUrl,
      labelPhotoUrl: _labelPhotoUrl,
      receiptPhotoUrl: _receiptPhotoUrl,
      rawLabelText: _labelRawOcrText,
      rawReceiptText: _receiptRawOcrText,
    );

    setState(() => _isOcrProcessing = false);

    if (!mounted) return;

    if (result.isSuccess && result.data != null) {
      final saved = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => PhotoVerificationScreen(
            initialData: result.data!,
            isAiVision: result.usedGemini,
            engineName: result.modelUsed,
          ),
        ),
      );

      if (saved == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Річ успішно збережено у ваш гардероб!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        widget.onSaved();
      }
    } else if (result.errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage!),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openManualVerificationScreen() async {
    final manualData = OcrCombinedResult(
      title: 'Нова річ',
      brand: '',
      category: ClothingCategory.tops,
      season: Season.allSeason,
      color: '',
      price: 0.0,
      size: '',
      fabricComposition: '',
      storeName: '',
      careInstructions: '',
      countryOfOrigin: '',
      itemPhoto: _clothingPhotoUrl ?? '',
      labelPhoto: _labelPhotoUrl,
      receiptPhoto: _receiptPhotoUrl,
    );

    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PhotoVerificationScreen(
          initialData: manualData,
          isAiVision: false,
          engineName: 'Ручне введення',
        ),
      ),
    );

    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Річ успішно збережено у ваш гардероб!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      widget.onSaved();
    }
  }

  Future<String?> _showAiKeyPromptDialog() async {
    final keyController = TextEditingController();
    bool isTesting = false;
    String? validationError;

    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final isDark = Theme.of(ctx).brightness == Brightness.dark;
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF27272A) : const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.auto_awesome, color: AppTheme.accent, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Розпізнавання через ШІ Gemini',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Потрібен ключ Google Gemini API',
                              style: TextStyle(fontSize: 12, color: AppTheme.muted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Щоб нейромережа прочитала бренд, склад тканини (бавовна, льон тощо), розмір та інструкції прання з вашого реального фото, підключіть безкоштовний ключ Google Gemini API або заповніть дані вручну.',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : const Color(0xFF4B5563),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: keyController,
                    decoration: InputDecoration(
                      hintText: 'Вставте ваш Gemini API ключ (AIzaSy...)',
                      prefixIcon: const Icon(Icons.vpn_key_rounded, size: 18),
                      errorText: validationError,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isTesting
                          ? null
                          : () async {
                              final text = keyController.text.trim();
                              if (text.isEmpty) {
                                setModalState(() => validationError = 'Введіть або вставте ваш ключ');
                                return;
                              }
                              setModalState(() {
                                isTesting = true;
                                validationError = null;
                              });
                              final check = await AiConfigService.testApiKey(text);
                              if (!check.isValid) {
                                setModalState(() {
                                  isTesting = false;
                                  validationError = check.message;
                                });
                                return;
                              }
                              await AiConfigService.setApiKey(text);
                              if (sheetCtx.mounted) {
                                Navigator.pop(sheetCtx, 'saved');
                              }
                            },
                      icon: isTesting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.check_circle_outline),
                      label: Text(isTesting ? 'Перевірка ключа...' : 'Зберегти ключ і розпізнати фото'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: isDark ? AppTheme.darkAccent : AppTheme.primary,
                        foregroundColor: isDark ? Colors.black : Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(sheetCtx);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SettingsAiScreen()),
                            ).then((_) {
                              if (mounted) setState(() {});
                            });
                          },
                          icon: const Icon(Icons.settings_outlined, size: 16),
                          label: const Text('Налаштування ШІ', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () => Navigator.pop(sheetCtx, 'manual'),
                          icon: const Icon(Icons.edit_note_rounded, size: 18),
                          label: const Text('Заповнити вручну', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Додати в Гардероб'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: isDark ? AppTheme.darkAccent : AppTheme.accent),
            tooltip: 'Налаштування та Мій Кабінет',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsHubScreen()),
              );
              if (mounted) setState(() {});
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: isDark ? AppTheme.darkAccent : AppTheme.primary,
          unselectedLabelColor: isDark ? AppTheme.darkMuted : AppTheme.muted,
          indicatorColor: isDark ? AppTheme.darkAccent : AppTheme.accent,
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
          _buildPhotoScanTab(isDark),
          _buildUrlImportTab(isDark),
          _buildReceiptImportTab(isDark),
          _buildManualTab(),
        ],
      ),
    );
  }

  Widget _buildPhotoScanTab(bool isDark) {
    final cardColor = isDark ? AppTheme.darkCard : Colors.white;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.border;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // AI Engine Mode & BYOK Status Pill
        Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: AiConfigService.hasCustomKey
                ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFF0FDF4))
                : (AiConfigService.adCredits > 0
                    ? (isDark ? const Color(0xFF451A03) : const Color(0xFFFEF3C7))
                    : (isDark ? AppTheme.darkSurface : const Color(0xFFF4F4F5))),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AiConfigService.hasCustomKey
                  ? (isDark ? const Color(0xFF059669) : const Color(0xFFBBF7D0))
                  : (AiConfigService.adCredits > 0
                      ? (isDark ? const Color(0xFFD97706) : const Color(0xFFFDE68A))
                      : borderColor),
            ),
          ),
          child: Row(
            children: [
              Icon(
                AiConfigService.hasCustomKey
                    ? Icons.verified_user_rounded
                    : (AiConfigService.adCredits > 0
                        ? Icons.stars_rounded
                        : Icons.memory_rounded),
                color: AiConfigService.hasCustomKey
                    ? (isDark ? const Color(0xFF4ADE80) : AppTheme.success)
                    : (AiConfigService.adCredits > 0
                        ? (isDark ? AppTheme.darkAccent : AppTheme.accent)
                        : AppTheme.muted),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AiConfigService.hasCustomKey
                          ? 'Google Gemini Vision · Власний ключ'
                          : (AiConfigService.adCredits > 0
                              ? 'Gemini Vision · ${AiConfigService.adCredits} сканувань за рекламу'
                              : 'Локальний парсер · Без нейромережі'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AiConfigService.hasCustomKey
                            ? (isDark ? const Color(0xFF86EFAC) : const Color(0xFF166534))
                            : (AiConfigService.adCredits > 0
                                ? (isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E))
                                : (isDark ? Colors.white : const Color(0xFF27272A))),
                      ),
                    ),
                    Text(
                      AiConfigService.hasCustomKey
                          ? '1 500 безкоштовних Vision-запитів на добу'
                          : (AiConfigService.adCredits > 0
                              ? 'Поповнити за рекламу або ввести ключ'
                              : 'Натисніть, щоб додати безкоштовний ключ Gemini'),
                      style: TextStyle(
                        fontSize: 10.5,
                        color: AiConfigService.hasCustomKey
                            ? (isDark ? const Color(0xFF86EFAC) : AppTheme.success)
                            : (AiConfigService.adCredits > 0
                                ? (isDark ? AppTheme.darkAccent : AppTheme.accent)
                                : (isDark ? AppTheme.darkMuted : AppTheme.muted)),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsAiScreen()),
                  );
                  if (mounted) setState(() {});
                },
                child: const Text('Змінити ⚙️', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),

        // Intro banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF27272A) : const Color(0xFFFEF3C7).withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? const Color(0xFF78350F) : const Color(0xFFFDE68A)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.auto_awesome, color: isDark ? AppTheme.darkAccent : AppTheme.accent, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Фото-Сканер Речей, Етикеток та Чеків',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: isDark ? AppTheme.darkAccent : const Color(0xFF92400E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Сфотографуйте річ, її внутрішню етикетку та касовий чек. ШІ вичитає бренд, розмір, склад тканини, догляд і ціну, подасть на перевірку та збереже в гардероб.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? const Color(0xFFE4E4E7) : const Color(0xFF78350F),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SettingsAiScreen()),
                        ).then((_) {
                          if (mounted) setState(() {});
                        });
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF18181B) : Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AiConfigService.hasCustomKey
                                ? const Color(0xFF10B981)
                                : const Color(0xFFF59E0B),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              AiConfigService.hasCustomKey
                                  ? Icons.verified_rounded
                                  : Icons.vpn_key_outlined,
                              size: 14,
                              color: AiConfigService.hasCustomKey
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFD97706),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                AiConfigService.hasCustomKey
                                    ? 'Gemini Vision активний'
                                    : 'Потрібен Gemini API ключ • Натисніть для налаштування',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AiConfigService.hasCustomKey
                                      ? const Color(0xFF047857)
                                      : const Color(0xFFB45309),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        Text(
          'ДОДАЙТЕ ФОТО ДЛЯ АНАЛІЗУ',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            color: isDark ? AppTheme.darkMuted : AppTheme.muted,
          ),
        ),
        const SizedBox(height: 12),

        // 3 Photo Pickers
        Row(
          children: [
            Expanded(
              child: _buildPhotoSlot(
                isDark: isDark,
                title: '1. Фото речі',
                imageUrl: _clothingPhotoUrl,
                icon: Icons.checkroom_rounded,
                onTap: () => _pickImageFor(
                  targetName: 'фото одягу',
                  onPicked: (path) => _clothingPhotoUrl = path,
                ),
                onClear: () => setState(() => _clothingPhotoUrl = null),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildPhotoSlot(
                isDark: isDark,
                title: '2. Етикетка',
                imageUrl: _labelPhotoUrl,
                icon: Icons.label_important_outline,
                onTap: () => _pickImageFor(
                  targetName: 'фото етикетки/бірки',
                  onPicked: (path) => _labelPhotoUrl = path,
                ),
                onClear: () => setState(() => _labelPhotoUrl = null),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildPhotoSlot(
                isDark: isDark,
                title: '3. Чек (опція)',
                imageUrl: _receiptPhotoUrl,
                icon: Icons.receipt_long_rounded,
                onTap: () => _pickImageFor(
                  targetName: 'фото чека',
                  onPicked: (path) => _receiptPhotoUrl = path,
                ),
                onClear: () => setState(() => _receiptPhotoUrl = null),
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
            label: Text(
              _isOcrProcessing ? 'ШІ зчитує текст та атрибути...' : 'Розпізнати через ШІ та перевірити',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              backgroundColor: isDark ? AppTheme.darkAccent : AppTheme.primary,
              foregroundColor: isDark ? Colors.black : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
        const SizedBox(height: 28),

        // Quick 1-Click Testing Presets
        Text(
          'ШВИДКІ ПРИКЛАДИ ДЛЯ ТЕСТУВАННЯ (1 КЛІК)',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            color: isDark ? AppTheme.darkMuted : AppTheme.muted,
          ),
        ),
        const SizedBox(height: 12),
        ...ClothingOcrService.samplePresets.map((preset) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
              boxShadow: isDark ? const [] : AppTheme.softShadow,
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: VestoraImage(
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
                      Text(
                        '🏷️ Бірка з розміром і складом + 🧾 Чек',
                        style: TextStyle(fontSize: 11, color: isDark ? AppTheme.darkMuted : AppTheme.muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
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
    required bool isDark,
    required String title,
    required String? imageUrl,
    required IconData icon,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 125,
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasImage ? AppTheme.accent : (isDark ? AppTheme.darkBorder : AppTheme.border),
            width: hasImage ? 1.5 : 1,
          ),
          boxShadow: isDark ? const [] : AppTheme.softShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: hasImage
            ? Stack(
                fit: StackFit.expand,
                children: [
                  VestoraImage(
                    imageUrl: imageUrl,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => Container(
                      color: isDark ? const Color(0xFF27272A) : const Color(0xFFF3F4F6),
                      child: const Center(
                        child: Icon(Icons.broken_image_outlined, color: AppTheme.accent, size: 24),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 5,
                    left: 5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('✓ Додано', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: onClear ?? onTap,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, size: 14, color: Colors.white),
                      ),
                    ),
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
                  padding: const EdgeInsets.all(6.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.darkSurface : const Color(0xFFF4F4F5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: isDark ? AppTheme.darkAccent : AppTheme.accent, size: 20),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600),
                      ),
                      if (_isPickingPhoto)
                        const Padding(
                          padding: EdgeInsets.only(top: 4.0),
                          child: SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accent),
                          ),
                        )
                      else ...[
                        const SizedBox(height: 2),
                        Text(
                          '+ Додати',
                          style: TextStyle(fontSize: 9.5, color: isDark ? AppTheme.darkMuted : AppTheme.muted, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildUrlImportTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF27272A) : const Color(0xFFFEF3C7).withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? const Color(0xFF78350F) : const Color(0xFFFDE68A)),
          ),
          child: Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: isDark ? AppTheme.darkAccent : AppTheme.accent),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Вставте посилання на товар із Kasta, Intertop, Answear, Zara, ASOS, Mango чи Nike. Vestora витягне студійні фото, склад тканини, ціну та знижку!',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                    color: isDark ? const Color(0xFFE4E4E7) : AppTheme.primary,
                  ),
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
            Text('Приклади:', style: TextStyle(fontSize: 11, color: isDark ? AppTheme.darkMuted : AppTheme.muted, fontWeight: FontWeight.w700)),
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
              color: isDark ? const Color(0xFF450A0A) : const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? const Color(0xFFDC2626) : const Color(0xFFFCA5A5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: AppTheme.danger, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _parseError!,
                    style: TextStyle(
                      color: isDark ? const Color(0xFFFECACA) : const Color(0xFF991B1B),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        if (_parsedResult != null) ...[
          const SizedBox(height: 24),
          _buildParsedResultPreview(isDark),
        ],
      ],
    );
  }

  Widget _buildParsedResultPreview(bool isDark) {
    final p = _parsedResult!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: VestoraImage(
                  imageUrl: _selectedImageUrl.isNotEmpty ? _selectedImageUrl : p.imageUrl,
                  width: 90,
                  height: 120,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => Container(
                    width: 90,
                    height: 120,
                    color: isDark ? AppTheme.darkSurface : AppTheme.background,
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
                      style: TextStyle(color: isDark ? AppTheme.darkMuted : AppTheme.muted, fontSize: 11, fontWeight: FontWeight.w700),
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
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: isDark ? AppTheme.darkAccent : AppTheme.primary),
                    ),
                    if (p.fabricComposition != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Склад: ${p.fabricComposition}',
                        style: TextStyle(fontSize: 11, color: isDark ? AppTheme.darkMuted : AppTheme.muted),
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

  Widget _buildReceiptImportTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF064E3B) : const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? const Color(0xFF059669) : const Color(0xFFBBF7D0)),
          ),
          child: Row(
            children: [
              Icon(Icons.mark_email_read_outlined, color: isDark ? const Color(0xFF4ADE80) : AppTheme.success),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Скопіюйте та вставте текст підтвердження замовлення з пошти (Zara, Kasta, Intertop, ASOS). Vestora автоматично розпізнає всі позиції чека!',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                    color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF166534),
                  ),
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
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('Пресети:', style: TextStyle(fontSize: 11, color: isDark ? AppTheme.darkMuted : AppTheme.muted, fontWeight: FontWeight.w700)),
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
          _buildScannedReceiptPreview(isDark),
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

  Widget _buildScannedReceiptPreview(bool isDark) {
    final r = _scannedReceipt!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Замовлення: ${r.storeName}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '№ ${r.orderNumber}',
                style: TextStyle(color: isDark ? AppTheme.darkMuted : AppTheme.muted, fontSize: 12),
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
                isExpanded: true,
                initialValue: _manualCategory,
                decoration: const InputDecoration(labelText: 'Категорія'),
                items: ClothingCategory.values.map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Text(
                      '${cat.icon} ${cat.label}',
                      style: const TextStyle(fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
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
                isExpanded: true,
                initialValue: _manualSeason,
                decoration: const InputDecoration(labelText: 'Сезон'),
                items: Season.values.map((s) {
                  return DropdownMenuItem(
                    value: s,
                    child: Text(
                      s.label,
                      style: const TextStyle(fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
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
        const SizedBox(height: 16),
        // Manual Photo Picker Preview
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Фото речі (з камери або галереї)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _pickImageFor(
                targetName: 'фото одягу',
                onPicked: (path) {
                  setState(() {
                    _manualImageController.text = path;
                  });
                },
              ),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 130,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppTheme.darkCard
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _manualImageController.text.trim().isNotEmpty
                        ? AppTheme.accent
                        : (Theme.of(context).brightness == Brightness.dark
                            ? AppTheme.darkBorder
                            : AppTheme.border),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: _manualImageController.text.trim().isNotEmpty
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          VestoraImage(
                            imageUrl: _manualImageController.text.trim(),
                            fit: BoxFit.cover,
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () => setState(() => _manualImageController.clear()),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, size: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? AppTheme.darkSurface
                                    : const Color(0xFFF4F4F5),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.add_a_photo_outlined, color: AppTheme.accent, size: 24),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Натисніть, щоб зробити фото або обрати з галереї',
                              style: TextStyle(fontSize: 12, color: AppTheme.muted),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _manualImageController,
          decoration: const InputDecoration(labelText: 'URL або Base64 картинки', hintText: 'https://... або знімок вище'),
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
