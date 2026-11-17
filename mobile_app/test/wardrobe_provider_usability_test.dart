import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_wardrobe/models/clothing_item.dart';
import 'package:smart_wardrobe/services/wardrobe_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WardrobeProvider Usability & Sorting Tests', () {
    late WardrobeProvider provider;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      provider = WardrobeProvider();
    });

    test('Loads demo capsule and performs real-time sorting correctly', () async {
      await provider.loadDemoCapsule();
      expect(provider.items.isNotEmpty, isTrue);

      // 1. Sort by price descending
      provider.setSortOption(WardrobeSortOption.priceDesc);
      var sorted = provider.filteredItems;
      for (int i = 0; i < sorted.length - 1; i++) {
        expect(sorted[i].price, greaterThanOrEqualTo(sorted[i + 1].price));
      }

      // 2. Sort by price ascending
      provider.setSortOption(WardrobeSortOption.priceAsc);
      sorted = provider.filteredItems;
      for (int i = 0; i < sorted.length - 1; i++) {
        expect(sorted[i].price, lessThanOrEqualTo(sorted[i + 1].price));
      }

      // 3. Sort by most worn
      provider.setSortOption(WardrobeSortOption.mostWorn);
      sorted = provider.filteredItems;
      for (int i = 0; i < sorted.length - 1; i++) {
        expect(sorted[i].wearCount, greaterThanOrEqualTo(sorted[i + 1].wearCount));
      }

      // 4. Sort by least worn
      provider.setSortOption(WardrobeSortOption.leastWorn);
      sorted = provider.filteredItems;
      for (int i = 0; i < sorted.length - 1; i++) {
        expect(sorted[i].wearCount, lessThanOrEqualTo(sorted[i + 1].wearCount));
      }
    });

    test('Season filter filters clothes accurately', () async {
      await provider.loadDemoCapsule();

      provider.setSeasonFilter(Season.summer);
      for (final item in provider.filteredItems) {
        expect(item.season == Season.summer || item.season == Season.allSeason, isTrue);
      }

      // Reset all filters
      provider.resetAllFilters();
      expect(provider.selectedSeason, isNull);
      expect(provider.selectedCategory, isNull);
      expect(provider.searchQuery, isEmpty);
      expect(provider.sortOption, WardrobeSortOption.newest);
      expect(provider.filteredItems.length, provider.items.length);
    });

    test('First-run wardrobe starts empty until user adds items or loads demo capsule', () async {
      await provider.initialized;
      expect(provider.items, isEmpty);
      expect(provider.streakDays, equals(0));

      await provider.loadDemoCapsule();
      expect(provider.items, isNotEmpty);
      expect(provider.streakDays, equals(14));
    });

    test('consumeLastQuotaWarning surfaces and clears storage warning once read', () async {
      final oversized = ClothingItem(
        id: 'quota_test_1',
        title: 'Big Photo',
        brand: 'Test',
        price: 500,
        category: ClothingCategory.tops,
        color: 'Чорний',
        imageUrl: 'data:image/jpeg;base64,${'A' * (600 * 1024)}',
      );
      await provider.addItem(oversized);
      final firstRead = provider.consumeLastQuotaWarning();
      expect(firstRead, isNotNull);
      expect(firstRead, contains('512'));
      expect(provider.consumeLastQuotaWarning(), isNull);
    });
  });
}
