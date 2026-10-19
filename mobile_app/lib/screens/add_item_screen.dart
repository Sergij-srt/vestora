import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/clothing_item.dart';
import '../services/url_parser_service.dart';
import '../services/receipt_scanner_service.dart';
import '../services/wardrobe_provider.dart';
import '../theme/app_theme.dart';

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
    _tabController = TabController(length: 3, vsync: this);
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
      season: _parsedResult!.season,
      price: _parsedResult!.price,
      currency: _parsedResult!.currency,
      color: _parsedResult!.color,
      storeName: _parsedResult!.store.name,
      fabricComposition: _parsedResult!.fabricComposition,
      sourceUrl: _parsedResult!.sourceUrl,
      wearCount: 0,
    );

    context.read<WardrobeProvider>().addItem(newItem);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Річ "${newItem.title}" збережена у Vestora!')),
    );
    widget.onSaved();
  }

  void _saveManualItem() {
    final title = _manualTitleController.text.trim();
    final brand = _manualBrandController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Вкажіть назву речі')),
      );
      return;
    }

    const uuid = Uuid();
    final price = double.tryParse(_manualPriceController.text.trim()) ?? 0.0;
    var img = _manualImageController.text.trim();
    if (img.isEmpty) {
      img = 'https://images.unsplash.com/photo-1523381294911-8d3cead13475?w=600&auto=format&fit=crop&q=80';
    }

    final newItem = ClothingItem(
      id: uuid.v4(),
      title: title,
      brand: brand.isNotEmpty ? brand : 'Власний гардероб',
      imageUrl: img,
      category: _manualCategory,
      season: _manualSeason,
      price: price,
      color: _manualColorController.text.trim().isNotEmpty
          ? _manualColorController.text.trim()
          : 'Не вказано',
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
          indicatorColor: AppTheme.primary,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.link_rounded), text: 'За лінком (AI)'),
            Tab(icon: Icon(Icons.receipt_long_rounded), text: 'Чек з пошти'),
            Tab(icon: Icon(Icons.photo_camera_back_outlined), text: 'Вручну'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUrlImportTab(),
          _buildReceiptImportTab(),
          _buildManualTab(),
        ],
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
                _urlController.text = 'https://intertop.ua/ua/product/shoes-geox-591241';
                _handleParseUrl();
              },
            ),
            ActionChip(
              avatar: const Text('🇺🇦', style: TextStyle(fontSize: 11)),
              label: const Text('Answear Сорочка'),
              onPressed: () {
                _urlController.text = 'https://answear.ua/p/sorochka-mango-man-linen-49120';
                _handleParseUrl();
              },
            ),
            ActionChip(
              avatar: const Text('🇪🇺', style: TextStyle(fontSize: 11)),
              label: const Text('Zara Сукня'),
              onPressed: () {
                _urlController.text = 'https://www.zara.com/ua/uk/satin-dress-p02157041.html';
                _handleParseUrl();
              },
            ),
            ActionChip(
              avatar: const Text('🇬🇧', style: TextStyle(fontSize: 11)),
              label: const Text('ASOS Блейзер'),
              onPressed: () {
                _urlController.text = 'https://www.asos.com/asos-design/wool-mix-blazer/prd/204561234';
                _handleParseUrl();
              },
            ),
            ActionChip(
              avatar: const Text('🇺🇸', style: TextStyle(fontSize: 11)),
              label: const Text('Nike Кросівки'),
              onPressed: () {
                _urlController.text = 'https://www.nike.com/ua/t/air-force-1-07-shoes-WrLlWX';
                _handleParseUrl();
              },
            ),
          ],
        ),
        const SizedBox(height: 20),

        ElevatedButton.icon(
          onPressed: _isParsing ? null : _handleParseUrl,
          icon: _isParsing
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.search_rounded),
          label: Text(_isParsing ? 'Отримуємо дані з магазину...' : 'Завантажити товар'),
        ),

        if (_parseError != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline_rounded, color: Colors.red.shade700),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _parseError!,
                    style: TextStyle(color: Colors.red.shade800, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Parsed Product Card Preview
        if (_parsedResult != null) ...[
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'РЕЗУЛЬТАТ РОЗПІЗНАВАННЯ',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1, color: AppTheme.muted),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(_parsedResult!.store.badgeColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_parsedResult!.store.name} (${_parsedResult!.store.country})',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main Selected Image
                CachedNetworkImage(
                  imageUrl: _selectedImageUrl.isNotEmpty ? _selectedImageUrl : _parsedResult!.imageUrl,
                  height: 260,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => Container(
                    height: 180,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.broken_image, size: 48, color: Colors.grey),
                  ),
                ),

                // Multi-Image Gallery Selector (if multiple photos found)
                if (_parsedResult!.galleryImages.length > 1) ...[
                  Container(
                    height: 70,
                    color: const Color(0xFFF4F4F5),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _parsedResult!.galleryImages.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final img = _parsedResult!.galleryImages[index];
                        final isSelected = img == _selectedImageUrl;

                        return InkWell(
                          onTap: () => setState(() => _selectedImageUrl = img),
                          child: Container(
                            width: 54,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? AppTheme.accent : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: CachedNetworkImage(
                                imageUrl: img,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _parsedResult!.brand.toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                          ),
                          Text(
                            '${_parsedResult!.category.icon} ${_parsedResult!.category.label}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _parsedResult!.title,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),

                      // Price & Discount tags
                      Row(
                        children: [
                          Text(
                            _parsedResult!.price > 0
                                ? '${_parsedResult!.price.toStringAsFixed(0)} ${_parsedResult!.currency}'
                                : 'Ціна не вказана',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.primary),
                          ),
                          if (_parsedResult!.originalPrice != null && _parsedResult!.originalPrice! > _parsedResult!.price) ...[
                            const SizedBox(width: 10),
                            Text(
                              '${_parsedResult!.originalPrice!.toStringAsFixed(0)} ${_parsedResult!.currency}',
                              style: const TextStyle(
                                fontSize: 14,
                                decoration: TextDecoration.lineThrough,
                                color: AppTheme.muted,
                              ),
                            ),
                          ],
                          if (_parsedResult!.discountPercentage != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.danger,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '-${_parsedResult!.discountPercentage}%',
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Fabric Composition Badge (if detected)
                      if (_parsedResult!.fabricComposition != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.texture_rounded, size: 14, color: AppTheme.muted),
                              const SizedBox(width: 6),
                              Text(
                                _parsedResult!.fabricComposition!,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.check_rounded),
                          label: const Text('Зберегти в Мій Гардероб'),
                          onPressed: _saveParsedItem,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildReceiptImportTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Row(
            children: const [
              Icon(Icons.email_outlined, color: Color(0xFF2563EB)),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Перешліть лист або вставте текст підтвердження замовлення (Zara, Kasta, Intertop, ASOS). Vestora автоматично витягне всі речі з кошика за 1 клік!',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, height: 1.4, color: Color(0xFF1E3A8A)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        TextField(
          controller: _receiptTextController,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: 'Текст електронного чека або замовлення',
            hintText: 'Вставте сюди вміст листа із Zara / Kasta / Intertop...',
            alignLabelWithHint: true,
            suffixIcon: _receiptTextController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () => setState(() => _receiptTextController.clear()),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 12),

        // Quick test receipt presets
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text('Приклади чеків:', style: TextStyle(fontSize: 11, color: AppTheme.muted, fontWeight: FontWeight.w700)),
            ActionChip(
              avatar: const Icon(Icons.receipt_rounded, size: 14),
              label: const Text('Замовлення Kasta (3 речі)'),
              onPressed: () {
                setState(() {
                  _scannedReceipt = ReceiptScannerService.getSampleReceipt('Kasta');
                });
              },
            ),
            ActionChip(
              avatar: const Icon(Icons.receipt_rounded, size: 14),
              label: const Text('Замовлення Zara (2 речі)'),
              onPressed: () {
                setState(() {
                  _scannedReceipt = ReceiptScannerService.getSampleReceipt('Zara');
                });
              },
            ),
            ActionChip(
              avatar: const Icon(Icons.receipt_rounded, size: 14),
              label: const Text('Замовлення Intertop (2 речі)'),
              onPressed: () {
                setState(() {
                  _scannedReceipt = ReceiptScannerService.getSampleReceipt('Intertop');
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 20),

        ElevatedButton.icon(
          onPressed: () {
            final text = _receiptTextController.text.trim();
            if (text.isEmpty) {
              setState(() {
                _scannedReceipt = ReceiptScannerService.getSampleReceipt('Kasta');
              });
            } else {
              setState(() {
                _scannedReceipt = ReceiptScannerService.parseEmailReceiptText(text);
              });
            }
          },
          icon: const Icon(Icons.document_scanner_rounded),
          label: const Text('Розпізнати замовлення'),
        ),

        // Scanned Receipt Results Card
        if (_scannedReceipt != null) ...[
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ЗНАЙДЕНО В ЗАМОВЛЕННІ (${_scannedReceipt!.items.length} РЕЧЕЙ)',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1, color: AppTheme.muted),
              ),
              Text(
                'Разом: ${_scannedReceipt!.totalAmount.toStringAsFixed(0)} ${_scannedReceipt!.currency}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(14),
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _scannedReceipt!.storeName.toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      '№ ${_scannedReceipt!.orderNumber}',
                      style: const TextStyle(color: AppTheme.muted, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),

                ..._scannedReceipt!.items.map((item) {
                  return CheckboxListTile(
                    value: item.isSelected,
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppTheme.primary,
                    onChanged: (val) {
                      setState(() {
                        item.isSelected = val ?? true;
                      });
                    },
                    secondary: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: item.imageUrl,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                    ),
                    title: Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${item.brand} · ${item.size != null ? "Розмір ${item.size} · " : ""}${item.price.toStringAsFixed(0)} ${item.currency}',
                      style: const TextStyle(fontSize: 11, color: AppTheme.muted),
                    ),
                  );
                }),

                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.cloud_download_rounded),
                    label: Text(
                      'Імпортувати вибрані речі (${_scannedReceipt!.items.where((i) => i.isSelected).length})',
                    ),
                    onPressed: () {
                      final selected = _scannedReceipt!.items.where((i) => i.isSelected).toList();
                      if (selected.isEmpty) return;

                      const uuid = Uuid();
                      final newItems = selected.map((it) {
                        return ClothingItem(
                          id: uuid.v4(),
                          title: it.title,
                          brand: it.brand,
                          imageUrl: it.imageUrl,
                          category: it.category,
                          season: it.season,
                          price: it.price,
                          currency: it.currency,
                          color: it.color,
                          storeName: _scannedReceipt!.storeName,
                          fabricComposition: it.fabricComposition,
                          wearCount: 0,
                        );
                      }).toList();

                      context.read<WardrobeProvider>().addMultipleItems(newItems);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Успішно імпортовано ${newItems.length} речей із замовлення!')),
                      );
                      widget.onSaved();
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildManualTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        TextField(
          controller: _manualTitleController,
          decoration: const InputDecoration(
            labelText: 'Назва речі *',
            hintText: 'наприклад: Чорна шкіряна куртка',
          ),
        ),
        const SizedBox(height: 14),

        TextField(
          controller: _manualBrandController,
          decoration: const InputDecoration(
            labelText: 'Бренд',
            hintText: 'наприклад: Zara, Mango, Nike, Kasta...',
          ),
        ),
        const SizedBox(height: 14),

        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _manualPriceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Ціна покупки (₴)',
                  hintText: '1500',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _manualColorController,
                decoration: const InputDecoration(
                  labelText: 'Колір',
                  hintText: 'Бежевий',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        TextField(
          controller: _manualFabricController,
          decoration: const InputDecoration(
            labelText: 'Склад тканини (опціонально)',
            hintText: '100% бавовна, вовна, льон...',
          ),
        ),
        const SizedBox(height: 14),

        DropdownButtonFormField<ClothingCategory>(
          initialValue: _manualCategory,
          decoration: const InputDecoration(labelText: 'Категорія одягу'),
          items: ClothingCategory.values.map((cat) {
            return DropdownMenuItem(
              value: cat,
              child: Text('${cat.icon} ${cat.label}'),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _manualCategory = val);
          },
        ),
        const SizedBox(height: 14),

        DropdownButtonFormField<Season>(
          initialValue: _manualSeason,
          decoration: const InputDecoration(labelText: 'Сезон'),
          items: Season.values.map((s) {
            return DropdownMenuItem(
              value: s,
              child: Text(s.label),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _manualSeason = val);
          },
        ),
        const SizedBox(height: 14),

        TextField(
          controller: _manualImageController,
          decoration: const InputDecoration(
            labelText: 'URL фотографії (опціонально)',
            hintText: 'https://...',
          ),
        ),
        const SizedBox(height: 24),

        ElevatedButton.icon(
          icon: const Icon(Icons.add_rounded),
          label: const Text('Додати в Гардероб'),
          onPressed: _saveManualItem,
        ),
      ],
    );
  }
}
