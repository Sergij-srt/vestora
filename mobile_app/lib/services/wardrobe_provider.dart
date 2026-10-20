import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../models/clothing_item.dart';
import 'gamification_service.dart';

class WardrobeProvider with ChangeNotifier {
  static const _storageKey = 'smart_wardrobe_items_v2';
  static const _streakKey = 'vestora_streak_days';

  final List<ClothingItem> _items = [];
  bool _isLoading = true;
  ClothingCategory? _selectedCategory;
  String _searchQuery = '';
  int _streakDays = 14; // Demo baseline streak

  List<ClothingItem> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;
  ClothingCategory? get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  int get streakDays => _streakDays;

  WardrobeHealthReport get healthReport =>
      GamificationService.evaluateWardrobeHealth(items: _items, streakDays: _streakDays);

  WardrobeProvider() {
    _loadFromStorage();
  }

  // Filtered items based on active category & search query
  List<ClothingItem> get filteredItems {
    return _items.where((item) {
      final matchesCategory = _selectedCategory == null || item.category == _selectedCategory;
      final matchesQuery = _searchQuery.isEmpty ||
          item.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.brand.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.color.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesQuery;
    }).toList();
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

  void setCategoryFilter(ClothingCategory? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
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
    _items.clear();
    notifyListeners();
    await _saveToStorage();
  }

  Future<void> addItem(ClothingItem item) async {
    _items.insert(0, item);
    notifyListeners();
    await _saveToStorage();
  }

  Future<void> addMultipleItems(List<ClothingItem> newItems) async {
    _items.insertAll(0, newItems);
    notifyListeners();
    await _saveToStorage();
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
        wearCount: 31,
      ),
      ClothingItem(
        id: uuid.v4(),
        title: 'Шкіряні білі кросівки Club C',
        brand: 'Reebok',
        imageUrl: 'https://images.unsplash.com/photo-1549298916-b41d501d3772?w=600&auto=format&fit=crop&q=80',
        category: ClothingCategory.shoes,
        season: Season.allSeason,
        color: 'Білий',
        price: 3100,
        currency: 'UAH',
        storeName: 'Intertop',
        fabricComposition: '100% Натуральна шкіра',
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
        fabricComposition: 'Шкіра',
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
        fabricComposition: '100% Шовк',
        wearCount: 3,
      ),
    ];
  }
}
