import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../models/clothing_item.dart';
import 'gamification_service.dart';

enum WardrobeSortOption {
  newest('Найновіші спочатку 🕒'),
  mostWorn('Найчастіше ношені 🔥'),
  leastWorn('Забуті речі (Dead stock) 💤'),
  priceDesc('Ціна: від найдорожчих 💎'),
  priceAsc('Ціна: від доступних 🏷️'),
  bestCpw('Найкращий Cost-Per-Wear 📊');

  final String label;
  const WardrobeSortOption(this.label);
}

class WardrobeProvider with ChangeNotifier {
  static const _storageKey = 'smart_wardrobe_items_v2';
  static const _streakKey = 'vestora_streak_days';

  final List<ClothingItem> _items = [];
  bool _isLoading = true;
  ClothingCategory? _selectedCategory;
  Season? _selectedSeason;
  WardrobeSortOption _sortOption = WardrobeSortOption.newest;
  String _searchQuery = '';
  int _streakDays = 14; // Demo baseline streak

  List<ClothingItem> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;
  ClothingCategory? get selectedCategory => _selectedCategory;
  Season? get selectedSeason => _selectedSeason;
  WardrobeSortOption get sortOption => _sortOption;
  String get searchQuery => _searchQuery;
  int get streakDays => _streakDays;

  WardrobeHealthReport get healthReport =>
      GamificationService.evaluateWardrobeHealth(items: _items, streakDays: _streakDays);

  Future<void>? _loadFuture;

  Future<void> get initialized => _loadFuture ?? Future.value();

  WardrobeProvider() {
    _loadFuture = _loadFromStorage();
  }

  // Filtered items based on active category, season, search query, and sort option
  List<ClothingItem> get filteredItems {
    final list = _items.where((item) {
      final matchesCategory = _selectedCategory == null || item.category == _selectedCategory;
      final matchesSeason = _selectedSeason == null || item.season == _selectedSeason || item.season == Season.allSeason;
      final matchesQuery = _searchQuery.isEmpty ||
          item.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.brand.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.color.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (item.fabricComposition != null && item.fabricComposition!.toLowerCase().contains(_searchQuery.toLowerCase()));
      return matchesCategory && matchesSeason && matchesQuery;
    }).toList();

    switch (_sortOption) {
      case WardrobeSortOption.newest:
        // default storage order
        break;
      case WardrobeSortOption.mostWorn:
        list.sort((a, b) => b.wearCount.compareTo(a.wearCount));
        break;
      case WardrobeSortOption.leastWorn:
        list.sort((a, b) => a.wearCount.compareTo(b.wearCount));
        break;
      case WardrobeSortOption.priceDesc:
        list.sort((a, b) => b.price.compareTo(a.price));
        break;
      case WardrobeSortOption.priceAsc:
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case WardrobeSortOption.bestCpw:
        list.sort((a, b) => a.costPerWear.compareTo(b.costPerWear));
        break;
    }

    return list;
  }

  // Total wardrobe valuation
  double get totalWardrobeValue {
    return _items.fold(0.0, (sum, item) => sum + item.price);
  }

  // Total items count
  int get totalItemsCount => _items.length;

  // Most worn items
  List<ClothingItem> get mostWornItems {
    final list = List<ClothingItem>.from(_items);
    list.sort((a, b) => b.wearCount.compareTo(a.wearCount));
    return list.take(5).toList();
  }

  // Least worn items (Dead stock / Declutter suggestions)
  List<ClothingItem> get leastWornItems {
    final list = List<ClothingItem>.from(_items);
    list.sort((a, b) => a.wearCount.compareTo(b.wearCount));
    return list.take(5).toList();
  }

  // Color distribution for palette analysis
  Map<String, int> get colorDistribution {
    final map = <String, int>{};
    for (final it in _items) {
      final c = it.color.trim();
      if (c.isNotEmpty) {
        map[c] = (map[c] ?? 0) + 1;
      }
    }
    return map;
  }

  // Percentage of timeless neutrals (Quiet Luxury metric)
  double get neutralColorPercentage {
    if (_items.isEmpty) return 0.0;
    const neutrals = ['бежевий', 'білий', 'чорний', 'сірий', 'синій денім', 'синій', 'коричневий', 'молочний', 'кремовий'];
    final neutralCount = _items.where((i) {
      final c = i.color.toLowerCase();
      return neutrals.any((n) => c.contains(n));
    }).length;
    return (neutralCount / _items.length) * 100;
  }

  void setCategoryFilter(ClothingCategory? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSeasonFilter(Season? season) {
    _selectedSeason = season;
    notifyListeners();
  }

  void setSortOption(WardrobeSortOption option) {
    _sortOption = option;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void resetAllFilters() {
    _selectedCategory = null;
    _selectedSeason = null;
    _searchQuery = '';
    _sortOption = WardrobeSortOption.newest;
    notifyListeners();
  }

  Future<void> loadDemoCapsule() async {
    _items.clear();
    _items.addAll(_sampleItems());
    _streakDays = 14;
    notifyListeners();
    await _saveToStorage();
  }

  Future<void> clearWardrobe() async {
    await _loadFuture;
    _items.clear();
    notifyListeners();
    await _saveToStorage();
  }

  Future<void> addItem(ClothingItem item) async {
    await _loadFuture;
    _items.insert(0, item);
    notifyListeners();
    await _saveToStorage();
  }

  Future<void> addMultipleItems(List<ClothingItem> newItems) async {
    await _loadFuture;
    _items.insertAll(0, newItems);
    notifyListeners();
    await _saveToStorage();
  }

  Future<void> updateItem(ClothingItem updatedItem) async {
    final index = _items.indexWhere((item) => item.id == updatedItem.id);
    if (index != -1) {
      _items[index] = updatedItem;
      notifyListeners();
      await _saveToStorage();
    }
  }

  Future<void> removeItem(String id) async {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
    await _saveToStorage();
  }

  Future<void> recordWear(String id) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      _items[index].wearCount++;
      notifyListeners();
      await _saveToStorage();
    }
  }

  Future<void> recordOutfitWear(List<ClothingItem> outfit) async {
    for (final it in outfit) {
      final index = _items.indexWhere((item) => item.id == it.id);
      if (index != -1) {
        _items[index].wearCount++;
      }
    }
    _streakDays++;
    notifyListeners();
    await _saveToStorage();
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _streakDays = prefs.getInt(_streakKey) ?? 14;

      final String? jsonString = prefs.getString(_storageKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> decoded = json.decode(jsonString);
        _items.clear();
        for (final map in decoded) {
          _items.add(ClothingItem.fromMap(map));
        }
      } else {
        // Pre-populate with realistic starter items
        _items.addAll(_sampleItems());
        await _saveToStorage();
      }
    } catch (e) {
      if (kDebugMode) print('Помилка завантаження гардероба: $e');
      if (_items.isEmpty) {
        _items.addAll(_sampleItems());
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_streakKey, _streakDays);
      final list = _items.map((e) => e.toMap()).toList();
      await prefs.setString(_storageKey, json.encode(list));
    } catch (e) {
      if (kDebugMode) print('Помилка збереження: $e');
    }
  }

  static List<ClothingItem> _sampleItems() {
    const uuid = Uuid();
    return [
      ClothingItem(
        id: uuid.v4(),
        title: 'Класичний оверсайз блейзер',
        brand: 'Massimo Dutti',
        imageUrl: 'https://images.unsplash.com/photo-1591047139829-d91aecb6caea?w=600&auto=format&fit=crop&q=80',
        category: ClothingCategory.outerwear,
        season: Season.allSeason,
        color: 'Бежевий',
        price: 4900,
        currency: 'UAH',
        storeName: 'Massimo Dutti',
        fabricComposition: '100% Натуральна вовна',
        size: 'EUR 38 / US S',
        countryOfOrigin: 'Made in Portugal',
        careInstructions: 'Хімчистка дозволена · Не прати у воді',
        labelPhotoUrl: 'https://images.unsplash.com/photo-1591047139829-d91aecb6caea?w=400',
        wearCount: 14,
      ),
      ClothingItem(
        id: uuid.v4(),
        title: 'Біла лляна сорочка',
        brand: 'Zara',
        imageUrl: 'https://images.unsplash.com/photo-1598033129183-c4f50c736f10?w=600&auto=format&fit=crop&q=80',
        category: ClothingCategory.tops,
        season: Season.summer,
        color: 'Білий',
        price: 1499,
        currency: 'UAH',
        storeName: 'Zara',
        fabricComposition: '100% Льон',
        size: 'EUR 38 / M',
        countryOfOrigin: 'Made in Morocco',
        careInstructions: 'Делікатне прання 30°C · Прасування при помірній t°',
        labelPhotoUrl: 'https://images.unsplash.com/photo-1598033129183-c4f50c736f10?w=400',
        wearCount: 22,
      ),
      ClothingItem(
        id: uuid.v4(),
        title: 'Джинси прямого крою Straight Leg',
        brand: 'COS',
        imageUrl: 'https://images.unsplash.com/photo-1541099649105-f69ad21f3246?w=600&auto=format&fit=crop&q=80',
        category: ClothingCategory.bottoms,
        season: Season.allSeason,
        color: 'Синій денім',
        price: 3200,
        currency: 'UAH',
        storeName: 'COS',
        fabricComposition: '100% Органічна бавовна',
        size: 'W30 / L32',
        countryOfOrigin: 'Made in Turkey',
        careInstructions: 'Прання 40°C з вивороту · Не відбілювати',
        wearCount: 31,
      ),
      ClothingItem(
        id: uuid.v4(),
        title: 'Шкіряні білі кросівки Club C',
        brand: 'Reebok',
        imageUrl: 'https://images.unsplash.com/photo-1595950653106-6c9ebd614d3a?w=600&auto=format&fit=crop&q=80',
        category: ClothingCategory.shoes,
        season: Season.allSeason,
        color: 'Білий',
        price: 3100,
        currency: 'UAH',
        storeName: 'Intertop',
        fabricComposition: '100% Натуральна шкіра',
        size: 'EUR 39 / US 7',
        countryOfOrigin: 'Made in Vietnam',
        careInstructions: 'Чищення вологою серветкою · Водовідштовхувальний спрей',
        wearCount: 45,
      ),
      ClothingItem(
        id: uuid.v4(),
        title: 'Мінімалістична шкіряна сумка Crossbody',
        brand: 'Arket',
        imageUrl: 'https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=600&auto=format&fit=crop&q=80',
        category: ClothingCategory.bags,
        season: Season.allSeason,
        color: 'Чорний',
        price: 2800,
        currency: 'UAH',
        storeName: 'Arket',
        fabricComposition: '100% Шкіра рослинного дублення',
        size: 'One Size (22×16 см)',
        countryOfOrigin: 'Made in Italy',
        careInstructions: 'Кондиціонер для шкіри · Зберігати у пильовику',
        wearCount: 19,
      ),
      ClothingItem(
        id: uuid.v4(),
        title: 'Шовкова міді-сукня',
        brand: 'Mango',
        imageUrl: 'https://images.unsplash.com/photo-1572804013309-59a88b7e92f1?w=600&auto=format&fit=crop&q=80',
        category: ClothingCategory.dresses,
        season: Season.summer,
        color: 'Смарагдовий',
        price: 2400,
        currency: 'UAH',
        storeName: 'Mango',
        fabricComposition: '100% Натуральний шовк Mulberry',
        size: 'EUR 36 / S',
        countryOfOrigin: 'Made in Spain',
        careInstructions: 'Сухе чищення (Dry Clean Only) · Не віджимати',
        wearCount: 3,
      ),
    ];
  }
}
