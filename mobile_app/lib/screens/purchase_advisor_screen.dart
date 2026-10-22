import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/clothing_item.dart';
import '../services/wardrobe_provider.dart';
import '../services/url_parser_service.dart';
import '../services/purchase_advisor_service.dart';
import '../widgets/vestora_image.dart';
import '../theme/app_theme.dart';

class PurchaseAdvisorScreen extends StatefulWidget {
  const PurchaseAdvisorScreen({super.key});

  @override
  State<PurchaseAdvisorScreen> createState() => _PurchaseAdvisorScreenState();
}

class _PurchaseAdvisorScreenState extends State<PurchaseAdvisorScreen> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  ClothingCategory _category = ClothingCategory.tops;
  String _imageUrl = '';

  bool _isAnalyzing = false;
  String? _error;
  PurchaseAnalysisReport? _report;

  @override
  void dispose() {
    _urlController.dispose();
    _titleController.dispose();
    _brandController.dispose();
    _priceController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  Future<void> _analyzeFromUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() => _error = 'Вставте посилання на товар із Zara, ASOS, Kasta тощо');
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _error = null;
      _report = null;
    });

    try {
      final parsed = await UrlParserService.parseProductUrl(url);
      if (parsed == null || parsed.title.isEmpty) {
        throw Exception('Не вдалося розпізнати товар за цим посиланням');
      }

      setState(() {
        _titleController.text = parsed.title;
        _brandController.text = parsed.brand;
        _priceController.text = parsed.price > 0 ? parsed.price.toStringAsFixed(0) : '1500';
        _colorController.text = parsed.color;
        _category = parsed.category;
        _imageUrl = parsed.imageUrl;
      });

      _runEvaluation();
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  void _runEvaluation() {
    final wardrobe = context.read<WardrobeProvider>().items;
    final title = _titleController.text.trim().isNotEmpty ? _titleController.text.trim() : 'Нова річ';
    final price = double.tryParse(_priceController.text.trim()) ?? 1500.0;
    final color = _colorController.text.trim().isNotEmpty ? _colorController.text.trim() : 'Не вказано';

    final result = PurchaseAdvisorService.evaluatePurchase(
      title: title,
      category: _category,
      color: color,
      price: price,
      currentWardrobe: wardrobe,
    );

    setState(() {
      _report = result;
      _error = null;
    });
  }

  void _loadPreset(String title, String brand, ClothingCategory cat, String color, double price, String img) {
    setState(() {
      _titleController.text = title;
      _brandController.text = brand;
      _category = cat;
      _colorController.text = color;
      _priceController.text = price.toStringAsFixed(0);
      _imageUrl = img;
    });
    _runEvaluation();
  }

  void _addToWardrobe() {
    if (_titleController.text.trim().isEmpty) return;
    const uuid = Uuid();
    final item = ClothingItem(
      id: uuid.v4(),
      title: _titleController.text.trim(),
      brand: _brandController.text.trim().isNotEmpty ? _brandController.text.trim() : 'Онлайн покупка',
      imageUrl: _imageUrl.isNotEmpty
          ? _imageUrl
          : 'https://images.unsplash.com/photo-1591047139829-d91aecb6caea?w=600&auto=format&fit=crop&q=80',
      category: _category,
      color: _colorController.text.trim().isNotEmpty ? _colorController.text.trim() : 'Не вказано',
      price: double.tryParse(_priceController.text.trim()) ?? 0.0,
      wearCount: 0,
    );

    context.read<WardrobeProvider>().addItem(item);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Річ "${item.title}" додано до вашого гардероба!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Should I Buy This? (AI Радник)'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Intro Header Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.shield_outlined, color: Color(0xFF38BDF8), size: 28),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'АНТИ-ІМПУЛЬСИВНИЙ ЗАХИСТ',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Знайшли річ в інтернет-магазині? AI перевірить вашу шафу і скаже, чи це дублікат, чи дійсно корисна покупка.',
                        style: TextStyle(color: Colors.white, fontSize: 12.5, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // URL Input
          TextField(
            controller: _urlController,
            decoration: InputDecoration(
              labelText: 'Посилання на товар для перевірки',
              hintText: 'https://zara.com/... або kasta.ua/...',
              prefixIcon: const Icon(Icons.link_rounded),
              suffixIcon: IconButton(
                icon: const Icon(Icons.send_rounded, color: AppTheme.primary),
                onPressed: _isAnalyzing ? null : _analyzeFromUrl,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Quick Presets
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text('Тести:', style: TextStyle(fontSize: 11, color: AppTheme.muted, fontWeight: FontWeight.w700)),
              ActionChip(
                label: const Text('🔴 Дублікат (Блейзер)'),
                onPressed: () => _loadPreset(
                  'Бежевий оверсайз жакет',
                  'Zara',
                  ClothingCategory.outerwear,
                  'Бежевий',
                  2999,
                  'https://images.unsplash.com/photo-1591047139829-d91aecb6caea?w=600&auto=format&fit=crop&q=80',
                ),
              ),
              ActionChip(
                label: const Text('🟢 Свіжа ідея (Шкіряні брюки)'),
                onPressed: () => _loadPreset(
                  'Шкіряні прямі штани',
                  'Mango',
                  ClothingCategory.bottoms,
                  'Чорний',
                  2400,
                  'https://images.unsplash.com/photo-1541099649105-f69ad21f3246?w=600&auto=format&fit=crop&q=80',
                ),
              ),
            ],
          ),

          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(_error!, style: TextStyle(color: Colors.red.shade800, fontSize: 13)),
            ),
          ],

          if (_isAnalyzing) ...[
            const SizedBox(height: 24),
            const Center(
              child: Column(
                children: [
                  CircularProgressIndicator(strokeWidth: 2.5),
                  SizedBox(height: 12),
                  Text('AI аналізує сумісність з вашим гардеробом...', style: TextStyle(fontSize: 13, color: AppTheme.muted)),
                ],
              ),
            ),
          ],

          // Analysis Output Report
          if (_report != null && !_isAnalyzing) ...[
            const SizedBox(height: 20),

            // Big Verdict Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Color(_report!.verdict.backgroundColor),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Color(_report!.verdict.textColor).withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _report!.verdict.title,
                        style: TextStyle(
                          color: Color(_report!.verdict.textColor),
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_report!.score}/100',
                          style: TextStyle(
                            color: Color(_report!.verdict.textColor),
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _report!.keyReason,
                    style: TextStyle(
                      color: Color(_report!.verdict.textColor),
                      fontSize: 13.5,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Metrics Row
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    label: 'НОВИХ ОБРАЗІВ',
                    value: '+${_report!.synergyOutfitsCount}',
                    icon: Icons.auto_awesome_rounded,
                    color: AppTheme.accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricTile(
                    label: 'ДУБЛІКАТІВ У ШАФІ',
                    value: '${_report!.duplicateItems.length}',
                    icon: Icons.copy_rounded,
                    color: _report!.duplicateItems.isEmpty ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Duplicates Warning Section
            if (_report!.duplicateItems.isNotEmpty) ...[
              const Text(
                'ЗНАЙДЕНІ ДУБЛІКАТИ У ВАШІЙ ШАФІ',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: Colors.red),
              ),
              const SizedBox(height: 8),
              ..._report!.duplicateItems.map((item) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: VestoraImage(imageUrl: item.imageUrl, width: 44, height: 44, fit: BoxFit.cover),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            Text('${item.brand} · Носилася ${item.wearCount} разів', style: const TextStyle(color: AppTheme.muted, fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 12),
            ],

            // Complementary Wardrobe Matches
            if (_report!.matchingItems.isNotEmpty) ...[
              const Text(
                'З ЧИМ ЦЯ РІЧ БУДЕ ПОЄДНУВАТИСЯ',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: AppTheme.muted),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 110,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _report!.matchingItems.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final item = _report!.matchingItems[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: VestoraImage(imageUrl: item.imageUrl, width: 80, height: 80, fit: BoxFit.cover),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 80,
                          child: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Action Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add_shopping_cart_rounded),
                label: const Text('Все одно купити та додати в гардероб'),
                onPressed: _addToWardrobe,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.muted)),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }
}
