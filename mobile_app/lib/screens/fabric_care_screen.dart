import 'package:flutter/material.dart';
import '../services/fabric_care_service.dart';
import '../theme/app_theme.dart';

class FabricCareScreen extends StatefulWidget {
  final int initialTabIndex;

  const FabricCareScreen({super.key, this.initialTabIndex = 0});

  @override
  State<FabricCareScreen> createState() => _FabricCareScreenState();
}

class _FabricCareScreenState extends State<FabricCareScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _symbolSearchQuery = '';
  CareSymbolCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTabIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<CareSymbolItem> get _filteredSymbols {
    return FabricCareService.symbols.where((s) {
      final matchesCategory = _selectedCategory == null || s.category == _selectedCategory;
      final matchesQuery = _symbolSearchQuery.isEmpty ||
          s.title.toLowerCase().contains(_symbolSearchQuery.toLowerCase()) ||
          s.description.toLowerCase().contains(_symbolSearchQuery.toLowerCase());
      return matchesCategory && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Гід по догляду за тканинами',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.accent,
          unselectedLabelColor: AppTheme.muted,
          indicatorColor: AppTheme.accent,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(text: '🏷️ Бірки & Значки'),
            Tab(text: '🆘 Від плям'),
            Tab(text: '🌿 Тканини & Догляд'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Care Symbols Decoder
          _buildSymbolsTab(),

          // Tab 2: Stain Rescue Emergency Guide
          _buildStainRescueTab(),

          // Tab 3: Fabric Longevity Guides
          _buildFabricGuidesTab(),
        ],
      ),
    );
  }

  // TAB 1: SYMBOLS DECODER
  Widget _buildSymbolsTab() {
    final list = _filteredSymbols;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Search bar
        TextField(
          onChanged: (v) => setState(() => _symbolSearchQuery = v),
          decoration: InputDecoration(
            hintText: 'Пошук символу: прання, 30°C, прасування...',
            prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.muted),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            filled: true,
            fillColor: Colors.white,
            suffixIcon: _symbolSearchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () => setState(() => _symbolSearchQuery = ''),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 12),

        // Category filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ChoiceChip(
                label: const Text('Всі значки'),
                selected: _selectedCategory == null,
                selectedColor: AppTheme.primary,
                labelStyle: TextStyle(
                  color: _selectedCategory == null ? Colors.white : AppTheme.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
                onSelected: (_) => setState(() => _selectedCategory = null),
              ),
              const SizedBox(width: 6),
              ...CareSymbolCategory.values.map((cat) {
                final isSel = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(cat.label),
                    selected: isSel,
                    selectedColor: AppTheme.primary,
                    labelStyle: TextStyle(
                      color: isSel ? Colors.white : AppTheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                    onSelected: (_) => setState(() => _selectedCategory = cat),
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (list.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('Символів за цим запитом не знайдено', style: TextStyle(color: AppTheme.muted)),
            ),
          )
        else
          ...list.map((item) => _buildSymbolCard(item)),
      ],
    );
  }

  Widget _buildSymbolCard(CareSymbolItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(item.iconEmoji, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F4F5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.category.label.split(' ')[0],
                        style: const TextStyle(fontSize: 10, color: AppTheme.muted, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: const TextStyle(fontSize: 12.5, color: AppTheme.secondary, height: 1.35),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb_outline_rounded, size: 14, color: Color(0xFF16A34A)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item.tip,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF166534), fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // TAB 2: STAIN RESCUE
  Widget _buildStainRescueTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFECACA)),
          ),
          child: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Головне правило порятунку: ніколи не тріть пляму із силою та уникайте гарячої води до розчинення пігменту!',
                  style: TextStyle(color: Color(0xFF991B1B), fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        ...FabricCareService.stainGuides.map((guide) => _buildStainCard(guide)),
      ],
    );
  }

  Widget _buildStainCard(StainRescueGuide guide) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(guide.iconEmoji, style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      guide.stainType,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    Text(
                      guide.goldenRule,
                      style: const TextStyle(color: Color(0xFFD97706), fontSize: 11.5, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),

          ...guide.steps.map((step) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.5),
                child: Text(
                  step,
                  style: const TextStyle(fontSize: 12.5, color: AppTheme.secondary, height: 1.35),
                ),
              )),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1F2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFFE11D48)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    guide.warning,
                    style: const TextStyle(fontSize: 11, color: Color(0xFFBE123C), fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // TAB 3: FABRICS LONGEVITY
  Widget _buildFabricGuidesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: FabricCareService.fabricGuides.map((guide) => _buildFabricCard(guide)).toList(),
    );
  }

  Widget _buildFabricCard(FabricGuideItem guide) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
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
              Row(
                children: [
                  Text(guide.iconEmoji, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 10),
                  Text(
                    guide.fabricName,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  guide.luxuryRank,
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF92400E)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          _buildFabricSpecRow('🧺 Прання:', guide.washingRule),
          const SizedBox(height: 8),
          _buildFabricSpecRow('🌬️ Сушіння:', guide.dryingRule),
          const SizedBox(height: 8),
          _buildFabricSpecRow('🚪 Зберігання:', guide.storageRule),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.star_rounded, size: 16, color: AppTheme.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      text: 'Секрет стиліста: ',
                      style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.primary, fontSize: 12),
                      children: [
                        TextSpan(
                          text: guide.proStylistSecret,
                          style: const TextStyle(fontWeight: FontWeight.normal, color: AppTheme.secondary),
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
    );
  }

  Widget _buildFabricSpecRow(String label, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 95,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.muted),
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, color: AppTheme.secondary, height: 1.35),
          ),
        ),
      ],
    );
  }
}
