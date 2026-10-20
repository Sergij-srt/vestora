import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:uuid/uuid.dart';
import '../models/clothing_item.dart';
import '../services/wardrobe_provider.dart';
import '../services/clothing_ocr_service.dart';
import '../theme/app_theme.dart';

class PhotoVerificationScreen extends StatefulWidget {
  final OcrCombinedResult initialData;

  const PhotoVerificationScreen({
    super.key,
    required this.initialData,
  });

  @override
  State<PhotoVerificationScreen> createState() => _PhotoVerificationScreenState();
}

class _PhotoVerificationScreenState extends State<PhotoVerificationScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _brandController;
  late final TextEditingController _colorController;
  late final TextEditingController _sizeController;
  late final TextEditingController _fabricController;
  late final TextEditingController _careController;
  late final TextEditingController _originController;
  late final TextEditingController _priceController;
  late final TextEditingController _storeController;

  late ClothingCategory _category;
  late Season _season;

  @override
  void initState() {
    super.initState();
    final d = widget.initialData;
    _titleController = TextEditingController(text: d.title);
    _brandController = TextEditingController(text: d.brand);
    _colorController = TextEditingController(text: d.color);
    _sizeController = TextEditingController(text: d.size ?? '');
    _fabricController = TextEditingController(text: d.fabricComposition ?? '');
    _careController = TextEditingController(text: d.careInstructions ?? '');
    _originController = TextEditingController(text: d.countryOfOrigin ?? '');
    _priceController = TextEditingController(text: d.price.toStringAsFixed(0));
    _storeController = TextEditingController(text: d.storeName ?? '');

    _category = d.category;
    _season = d.season;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _brandController.dispose();
    _colorController.dispose();
    _sizeController.dispose();
    _fabricController.dispose();
    _careController.dispose();
    _originController.dispose();
    _priceController.dispose();
    _storeController.dispose();
    super.dispose();
  }

  void _saveToWardrobe() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введіть назву речі')),
      );
      return;
    }

    final price = double.tryParse(_priceController.text.replaceAll(' ', '')) ?? 0.0;
    final item = ClothingItem(
      id: const Uuid().v4(),
      title: _titleController.text.trim(),
      brand: _brandController.text.trim().isEmpty ? 'Невідомий бренд' : _brandController.text.trim(),
      imageUrl: widget.initialData.itemPhoto ?? '',
      category: _category,
      season: _season,
      color: _colorController.text.trim(),
      price: price,
      currency: 'UAH',
      storeName: _storeController.text.trim(),
      fabricComposition: _fabricController.text.trim(),
      size: _sizeController.text.trim(),
      careInstructions: _careController.text.trim(),
      countryOfOrigin: _originController.text.trim(),
      labelPhotoUrl: widget.initialData.labelPhoto,
      receiptPhotoUrl: widget.initialData.receiptPhoto,
      purchaseDate: DateTime.now(),
      wearCount: 1, // Ready to wear
    );

    context.read<WardrobeProvider>().addItem(item);

    Navigator.pop(context, true); // Return success
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.initialData;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Перевірка розпізнаних даних'),
        actions: [
          TextButton(
            onPressed: _saveToWardrobe,
            child: const Text('Зберегти', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Photo Previews Carousel / Row
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.border),
              boxShadow: AppTheme.softShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ЗЧИТАНІ ФОТОМАТЕРІАЛИ',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: AppTheme.muted,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 130,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      // Photo 1: Clothing Item
                      _buildPhotoCard(
                        title: 'Фото речі',
                        imageUrl: d.itemPhoto,
                        badgeColor: AppTheme.primary,
                        icon: Icons.checkroom_rounded,
                      ),
                      const SizedBox(width: 12),
                      // Photo 2: Label / Care Tag
                      if (d.labelPhoto != null) ...[
                        _buildPhotoCard(
                          title: 'Етикетка / Бірка',
                          imageUrl: d.labelPhoto,
                          badgeColor: const Color(0xFF2563EB),
                          icon: Icons.label_important_outline,
                        ),
                        const SizedBox(width: 12),
                      ],
                      // Photo 3: Receipt
                      if (d.receiptPhoto != null) ...[
                        _buildPhotoCard(
                          title: 'Чек покупки',
                          imageUrl: d.receiptPhoto,
                          badgeColor: const Color(0xFF16A34A),
                          icon: Icons.receipt_long_rounded,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. AI Confidence Badges
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.auto_awesome, color: AppTheme.accent, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'ШІ автоматично розпізнав атрибути',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF92400E)),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Бренд, розмір, склад тканини вичитано з бірки; ціну, дату та магазин витягнуто з чека. Будь ласка, перевірте дані нижче.',
                        style: TextStyle(fontSize: 11.5, color: Color(0xFF78350F), height: 1.35),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3. Form Fields
          _buildSectionHeader('ОСНОВНА ІНФОРМАЦІЯ'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _titleController,
            label: 'Назва товару',
            icon: Icons.edit_outlined,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _brandController,
                  label: 'Бренд',
                  icon: Icons.verified_outlined,
                  helperTag: '🏷️ з етикетки',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _colorController,
                  label: 'Колір',
                  icon: Icons.palette_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDropdownCategory(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdownSeason(),
              ),
            ],
          ),
          const SizedBox(height: 20),

          _buildSectionHeader('ДАНІ З ЕТИКЕТКИ ТА БІРКИ'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _sizeController,
                  label: 'Розмір',
                  icon: Icons.straighten_outlined,
                  helperTag: '🏷️ з етикетки',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _originController,
                  label: 'Країна виробництва',
                  icon: Icons.flag_outlined,
                  helperTag: '🏷️ з бірки',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _fabricController,
            label: 'Склад тканини (волокна)',
            icon: Icons.texture_rounded,
            helperTag: '🏷️ з етикетки',
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _careController,
            label: 'Рекомендації по догляду',
            icon: Icons.local_laundry_service_outlined,
            helperTag: '🏷️ з етикетки',
          ),
          const SizedBox(height: 20),

          _buildSectionHeader('ФІНАНСОВІ ДАНІ З ЧЕКА'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _priceController,
                  label: 'Ціна покупки (₴)',
                  icon: Icons.payments_outlined,
                  keyboardType: TextInputType.number,
                  helperTag: '🧾 з чека',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _storeController,
                  label: 'Магазин / Локація',
                  icon: Icons.storefront_outlined,
                  helperTag: '🧾 з чека',
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Submit CTA
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saveToWardrobe,
              icon: const Icon(Icons.check_circle_rounded),
              label: const Text('Підтвердити та додати в гардероб'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildPhotoCard({
    required String title,
    required String? imageUrl,
    required Color badgeColor,
    required IconData icon,
  }) {
    return Container(
      width: 110,
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl != null && imageUrl.isNotEmpty)
            CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => Center(child: Icon(icon, color: AppTheme.muted)),
            )
          else
            Center(child: Icon(icon, color: AppTheme.muted, size: 28)),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              color: Colors.black.withValues(alpha: 0.7),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.1,
        color: AppTheme.muted,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? helperTag,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (helperTag != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4, left: 4),
            child: Text(
              helperTag,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.accent),
            ),
          ),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon, size: 18, color: AppTheme.muted),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownCategory() {
    return DropdownButtonFormField<ClothingCategory>(
      initialValue: _category,
      decoration: const InputDecoration(
        labelText: 'Категорія',
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      items: ClothingCategory.values.map((cat) {
        return DropdownMenuItem(
          value: cat,
          child: Text('${cat.icon} ${cat.label}', style: const TextStyle(fontSize: 13)),
        );
      }).toList(),
      onChanged: (val) {
        if (val != null) setState(() => _category = val);
      },
    );
  }

  Widget _buildDropdownSeason() {
    return DropdownButtonFormField<Season>(
      initialValue: _season,
      decoration: const InputDecoration(
        labelText: 'Сезон',
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      items: Season.values.map((s) {
        return DropdownMenuItem(
          value: s,
          child: Text(s.label, style: const TextStyle(fontSize: 13)),
        );
      }).toList(),
      onChanged: (val) {
        if (val != null) setState(() => _season = val);
      },
    );
  }
}
