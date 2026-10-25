import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  static const _deletedIdsKey = 'vestora_deleted_item_ids';
  static const _wearLogsKey = 'vestora_pending_wear_logs';

  /// Safe ~1.8M UTF-16 code-unit ceiling (~3.5 MB in 2-byte UTF-16 browser `localStorage`),
  /// leaving ~1.5 MB headroom below Safari/Chromium's 5 MB quota for calendar, auth, and profile keys.
  static const int maxStorageBudgetChars = 1800 * 1024;

  /// Per-photo Base64 inline payload limit (512 KB).
  static const int maxInlineImageChars = 512 * 1024;

  static const String fallbackImagePlaceholder =
      'https://images.unsplash.com/photo-1558769132-cb1aea458c5e?w=600&auto=format&fit=crop&q=80';

  final List<ClothingItem> _items = [];
  final Set<String> _deletedItemIds = <String>{};
  final List<Map<String, dynamic>> _pendingWearLogs = <Map<String, dynamic>>[];

  SharedPreferences? _prefs;
  bool _isLoading = true;
  ClothingCategory? _selectedCategory;
  Season? _selectedSeason;
  WardrobeSortOption _sortOption = WardrobeSortOption.newest;
  String _searchQuery = '';
  int _streakDays = 14;
  bool _quotaGuardTriggered = false;
  String? _lastQuotaWarning;

  List<ClothingItem> get items => List.unmodifiable(_items);
  Set<String> get deletedItemIds => Set.unmodifiable(_deletedItemIds);
  List<Map<String, dynamic>> get pendingWearLogs => List.unmodifiable(_pendingWearLogs);
  bool get isLoading => _isLoading;
  ClothingCategory? get selectedCategory => _selectedCategory;
  Season? get selectedSeason => _selectedSeason;
  WardrobeSortOption get sortOption => _sortOption;
  String get searchQuery => _searchQuery;
  int get streakDays => _streakDays;
  bool get quotaGuardTriggered => _quotaGuardTriggered;
  String? get lastQuotaWarning => _lastQuotaWarning;

  WardrobeHealthReport get healthReport =>
      GamificationService.evaluateWardrobeHealth(items: _items, streakDays: _streakDays);

  Future<void>? _loadFuture;

  Future<void> get initialized => _loadFuture ?? Future.value();

  WardrobeProvider() {
    _loadFuture = _loadFromStorage();
  }

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  // Filtered items based on active category, season, search query, and sort option
  List<ClothingItem> get filteredItems {
    final queryLower = _searchQuery.toLowerCase();
    final list = _items.where((item) {
      final matchesCategory = _selectedCategory == null || item.category == _selectedCategory;
      final matchesSeason = _selectedSeason == null ||
          item.season == _selectedSeason ||
          item.season == Season.allSeason;
      final matchesQuery = queryLower.isEmpty ||
          item.title.toLowerCase().contains(queryLower) ||
          item.brand.toLowerCase().contains(queryLower) ||
          item.color.toLowerCase().contains(queryLower) ||
          (item.fabricComposition != null &&
              item.fabricComposition!.toLowerCase().contains(queryLower));
      return matchesCategory && matchesSeason && matchesQuery;
    }).toList();

    switch (_sortOption) {
      case WardrobeSortOption.newest:
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

  double get totalWardrobeValue => _items.fold(0.0, (sum, item) => sum + item.price);

  int get totalItemsCount => _items.length;

  List<ClothingItem> get mostWornItems {
    final list = List<ClothingItem>.from(_items);
    list.sort((a, b) => b.wearCount.compareTo(a.wearCount));
    return list.take(5).toList();
  }

  List<ClothingItem> get leastWornItems {
    final list = List<ClothingItem>.from(_items);
    list.sort((a, b) => a.wearCount.compareTo(b.wearCount));
    return list.take(5).toList();
  }

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

  double get neutralColorPercentage {
    if (_items.isEmpty) return 0.0;
    const neutrals = [
      'бежевий',
      'білий',
      'чорний',
      'сірий',
      'синій денім',
      'синій',
      'коричневий',
      'молочний',
      'кремовий',
    ];
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

  void setStreakDaysFromSync(int days) {
    if (days > _streakDays) {
      _streakDays = days;
      notifyListeners();
      _saveToStorage();
    }
  }

  /// Sanitizes an individual item's inline Base64 data URIs so a single uncompressed camera photo
  /// cannot blow up Web `localStorage` (~5 MB limit).
  ClothingItem _sanitizeItemInlinePayloads(ClothingItem item) {
    var changed = false;
    var safeImageUrl = item.imageUrl;
    var safeLabelUrl = item.labelPhotoUrl;
    var safeReceiptUrl = item.receiptPhotoUrl;
    var safeGallery = item.galleryImages;

    if (safeImageUrl.startsWith('data:') && safeImageUrl.length > maxInlineImageChars) {
      safeImageUrl = fallbackImagePlaceholder;
      changed = true;
    }

    if (safeLabelUrl != null &&
        safeLabelUrl.startsWith('data:') &&
        safeLabelUrl.length > maxInlineImageChars) {
      safeLabelUrl = null;
      changed = true;
    }

    if (safeReceiptUrl != null &&
        safeReceiptUrl.startsWith('data:') &&
        safeReceiptUrl.length > maxInlineImageChars) {
      safeReceiptUrl = null;
      changed = true;
    }

    if (safeGallery.any((g) => g.startsWith('data:') && g.length > maxInlineImageChars)) {
      safeGallery = safeGallery
          .where((g) => !(g.startsWith('data:') && g.length > maxInlineImageChars))
          .toList();
      if (safeGallery.isEmpty && safeImageUrl.isNotEmpty) {
        safeGallery = [safeImageUrl];
      }
      changed = true;
    }

    if (!changed) return item;

    _quotaGuardTriggered = true;
    _lastQuotaWarning =
        'Надвелике Base64-зображення (>512 КБ) оптимізовано для захисту локального сховища.';
    return ClothingItem(
      id: item.id,
      title: item.title,
      brand: item.brand,
      imageUrl: safeImageUrl,
      galleryImages: safeGallery,
      category: item.category,
      season: item.season,
      color: item.color,
      price: item.price,
      currency: item.currency,
      sourceUrl: item.sourceUrl,
      storeName: item.storeName,
      fabricComposition: item.fabricComposition,
      size: item.size,
      countryOfOrigin: item.countryOfOrigin,
      careInstructions: item.careInstructions,
      labelPhotoUrl: safeLabelUrl,
      receiptPhotoUrl: safeReceiptUrl,
      purchaseDate: item.purchaseDate,
      wearCount: item.wearCount,
      notes: item.notes,
    );
  }

  Future<void> loadDemoCapsule() async {
    await _loadFuture;
    _items.clear();
    _items.addAll(_sampleItems());
    _streakDays = 14;
    notifyListeners();
    await _saveToStorage();
  }

  Future<void> clearWardrobe({bool clearTombstones = false}) async {
    await _loadFuture;
    if (clearTombstones) {
      _deletedItemIds.clear();
      _pendingWearLogs.clear();
      _streakDays = 0;
      _quotaGuardTriggered = false;
      _lastQuotaWarning = null;
      _items.clear();
      notifyListeners();
      try {
        final prefs = await _getPrefs();
        await prefs.remove(_storageKey);
        await prefs.remove(_deletedIdsKey);
        await prefs.remove(_wearLogsKey);
        await prefs.remove(_streakKey);
      } catch (_) {}
      return;
    }
    for (final item in _items) {
      if (item.id.isNotEmpty) {
        _deletedItemIds.add(item.id);
      }
    }
    _items.clear();
    notifyListeners();
    await _saveToStorage();
  }

  Future<void> addItem(ClothingItem item) async {
    await _loadFuture;
    final sanitized = _sanitizeItemInlinePayloads(item);
    _deletedItemIds.remove(sanitized.id);
    _items.insert(0, sanitized);
    notifyListeners();
    await _saveToStorage();
  }

  Future<void> addMultipleItems(List<ClothingItem> newItems) async {
    await _loadFuture;
    final sanitizedList = <ClothingItem>[];
    for (final it in newItems) {
      final sanitized = _sanitizeItemInlinePayloads(it);
      _deletedItemIds.remove(sanitized.id);
      sanitizedList.add(sanitized);
    }
    _items.insertAll(0, sanitizedList);
    notifyListeners();
    await _saveToStorage();
  }

  Future<void> updateItem(ClothingItem updatedItem) async {
    await _loadFuture;
    final index = _items.indexWhere((item) => item.id == updatedItem.id);
    if (index != -1) {
      _items[index] = _sanitizeItemInlinePayloads(updatedItem);
      notifyListeners();
      await _saveToStorage();
    }
  }

  Future<void> removeItem(String id) async {
    await _loadFuture;
    _items.removeWhere((item) => item.id == id);
    if (id.isNotEmpty) {
      _deletedItemIds.add(id);
    }
    _pendingWearLogs.removeWhere((log) => log['item_id'] == id);
    notifyListeners();
    await _saveToStorage();
  }

  /// Marks deleted tombstones as synchronized with Supabase cloud so they don't grow unboundedly.
  Future<void> markTombstonesSynced(Iterable<String> syncedIds) async {
    await _loadFuture;
    _deletedItemIds.removeAll(syncedIds);
    await _saveToStorage();
  }

  /// Clears pending wear logs after successful upload to Supabase `wear_logs`.
  Future<void> markWearLogsSynced() async {
    await _loadFuture;
    _pendingWearLogs.clear();
    await _saveToStorage();
  }

  Future<void> recordWear(String id) async {
    await _loadFuture;
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      _items[index].wearCount++;
      _appendPendingWearLog(id);
      notifyListeners();
      await _saveToStorage();
    }
  }

  Future<void> recordOutfitWear(List<ClothingItem> outfit) async {
    await _loadFuture;
    for (final it in outfit) {
      final index = _items.indexWhere((item) => item.id == it.id);
      if (index != -1) {
        _items[index].wearCount++;
        _appendPendingWearLog(it.id);
      }
    }
    _streakDays++;
    notifyListeners();
    await _saveToStorage();
  }

  void _appendPendingWearLog(String itemId) {
    final today = DateTime.now().toUtc().toIso8601String().substring(0, 10);
    _pendingWearLogs.add({
      'item_id': itemId,
      'worn_on': today,
    });
    if (_pendingWearLogs.length > 500) {
      _pendingWearLogs.removeRange(0, _pendingWearLogs.length - 500);
    }
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await _getPrefs();
      _streakDays = prefs.getInt(_streakKey) ?? 14;

      final deletedList = prefs.getStringList(_deletedIdsKey);
      if (deletedList != null) {
        _deletedItemIds
          ..clear()
          ..addAll(deletedList);
      }

      final wearLogsJson = prefs.getString(_wearLogsKey);
      if (wearLogsJson != null && wearLogsJson.isNotEmpty) {
        final decodedLogs = json.decode(wearLogsJson) as List<dynamic>;
        _pendingWearLogs
          ..clear()
          ..addAll(decodedLogs.whereType<Map>().map((m) => Map<String, dynamic>.from(m)));
      }

      final String? jsonString = prefs.getString(_storageKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> decoded = json.decode(jsonString);
        _items.clear();
        for (final map in decoded) {
          _items.add(ClothingItem.fromMap(Map<String, dynamic>.from(map as Map)));
        }
      } else {
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
      final prefs = await _getPrefs();
      await prefs.setInt(_streakKey, _streakDays);
      await prefs.setStringList(_deletedIdsKey, _deletedItemIds.toList());
      if (_pendingWearLogs.isEmpty) {
        await prefs.remove(_wearLogsKey);
      } else {
        await prefs.setString(_wearLogsKey, json.encode(_pendingWearLogs));
      }

      var encoded = json.encode(_items.map((e) => e.toMap()).toList());

      // Enforce ~3.5 MB UTF-16 localStorage ceiling by shedding oldest inline Base64 data URIs if needed
      if (encoded.length > maxStorageBudgetChars) {
        _quotaGuardTriggered = true;
        _lastQuotaWarning =
            'Досягнуто безпечного ліміту локального сховища браузера (~3.5 МБ UTF-16). Великі Base64-знімки замінено на компактні посилання.';
        for (var idx = _items.length - 1;
            idx >= 0 && encoded.length > maxStorageBudgetChars;
            idx--) {
          if (_stripInlineDataUriAt(idx)) {
            encoded = json.encode(_items.map((e) => e.toMap()).toList());
          }
        }
      }

      try {
        await prefs.setString(_storageKey, encoded);
      } catch (_) {
        // Emergency QuotaExceededError recovery: strip all remaining inline data: URIs and retry
        var strippedAny = false;
        for (var idx = _items.length - 1; idx >= 0; idx--) {
          if (_stripInlineDataUriAt(idx)) {
            strippedAny = true;
          }
        }
        if (strippedAny) {
          _quotaGuardTriggered = true;
          _lastQuotaWarning =
              'Перевищено квоту сховища браузера. Вбудовані Base64-фото замінено для збереження метаданих гардероба.';
          encoded = json.encode(_items.map((e) => e.toMap()).toList());
          await prefs.setString(_storageKey, encoded);
        } else {
          rethrow;
        }
      }
    } catch (e) {
      if (kDebugMode) print('Помилка збереження: $e');
    }
  }

  bool _stripInlineDataUriAt(int idx) {
    final current = _items[idx];
    final hasInlineData = current.imageUrl.startsWith('data:') ||
        (current.labelPhotoUrl?.startsWith('data:') ?? false) ||
        (current.receiptPhotoUrl?.startsWith('data:') ?? false) ||
        current.galleryImages.any((g) => g.startsWith('data:'));
    if (!hasInlineData) return false;

    final strippedImageUrl = current.imageUrl.startsWith('data:')
        ? fallbackImagePlaceholder
        : current.imageUrl;
    final strippedGallery =
        current.galleryImages.where((g) => !g.startsWith('data:')).toList();

    _items[idx] = ClothingItem(
      id: current.id,
      title: current.title,
      brand: current.brand,
      imageUrl: strippedImageUrl,
      galleryImages: strippedGallery.isEmpty && strippedImageUrl.isNotEmpty
          ? [strippedImageUrl]
          : strippedGallery,
      category: current.category,
      season: current.season,
      color: current.color,
      price: current.price,
      currency: current.currency,
      sourceUrl: current.sourceUrl,
      storeName: current.storeName,
      fabricComposition: current.fabricComposition,
      size: current.size,
      countryOfOrigin: current.countryOfOrigin,
      careInstructions: current.careInstructions,
      labelPhotoUrl: (current.labelPhotoUrl?.startsWith('data:') ?? false)
          ? null
          : current.labelPhotoUrl,
      receiptPhotoUrl: (current.receiptPhotoUrl?.startsWith('data:') ?? false)
          ? null
          : current.receiptPhotoUrl,
      purchaseDate: current.purchaseDate,
      wearCount: current.wearCount,
      notes: current.notes,
    );
    return true;
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
