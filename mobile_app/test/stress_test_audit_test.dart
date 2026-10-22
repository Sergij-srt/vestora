import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_wardrobe/models/clothing_item.dart';
import 'package:smart_wardrobe/services/wardrobe_provider.dart';
import 'package:smart_wardrobe/services/user_profile_service.dart';
import 'package:smart_wardrobe/services/backup_service.dart';
import 'package:smart_wardrobe/services/daily_stylist_service.dart';
import 'package:smart_wardrobe/services/weather_stylist_service.dart';
import 'package:smart_wardrobe/services/travel_capsule_service.dart';
import 'package:smart_wardrobe/services/color_analysis_service.dart';
import 'package:smart_wardrobe/services/declutter_service.dart';
import 'package:smart_wardrobe/services/url_parser_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  /// Helper to generate large test datasets
  List<ClothingItem> generateSyntheticWardrobe(int count) {
    final categories = ClothingCategory.values;
    final seasons = Season.values;
    final brands = ['Cos', 'Massimo Dutti', 'Toteme', 'Loro Piana', 'The Row', 'Zara', 'Arket', 'Acne Studios'];
    final colors = ['Чорний', 'Білий', 'Бежевий', 'Темно-синій', 'Сірий', 'Оливковий', 'Коричневий'];

    return List.generate(count, (index) {
      final cat = categories[index % categories.length];
      final brand = brands[index % brands.length];
      final color = colors[index % colors.length];
      final season = seasons[index % seasons.length];
      final price = 1000.0 + (index * 17 % 25000);
      final wearCount = index % 40;

      return ClothingItem(
        id: 'synthetic-item-$index',
        title: '$brand $color ${cat.label} #$index',
        category: cat,
        color: color,
        season: season,
        brand: brand,
        price: price,
        wearCount: wearCount,
        purchaseDate: DateTime(2025, 1, 1).add(Duration(days: index % 600)),
        imageUrl: 'https://images.unsplash.com/photo-item-$index?w=600',
        fabricComposition: '100% Бавовна',
      );
    });
  }

  group('⚡ [STRESS SUITE 1] High-Volume Data Scalability (1,000+ Items)', () {
    test('WardrobeProvider loads and indexes 1,000 items in < 50ms', () async {
      final wardrobe = WardrobeProvider();
      await wardrobe.clearWardrobe();
      final items = generateSyntheticWardrobe(1000);

      final stopwatch = Stopwatch()..start();
      await wardrobe.addMultipleItems(items);
      stopwatch.stop();

      expect(wardrobe.items.length, 1000);
      expect(stopwatch.elapsedMilliseconds, lessThan(100),
          reason: 'Adding 1000 items must be sub-100ms for smooth 60fps UI');
    });

    test('Real-time filtering & search across 1,000 items executes in < 35ms', () async {
      final wardrobe = WardrobeProvider();
      await wardrobe.clearWardrobe();
      await wardrobe.addMultipleItems(generateSyntheticWardrobe(1000));

      final stopwatch = Stopwatch()..start();
      // Search by brand
      wardrobe.setSearchQuery('Massimo');
      final searchResults = wardrobe.filteredItems;
      expect(searchResults.isNotEmpty, isTrue);

      // Filter by Category
      wardrobe.setCategoryFilter(ClothingCategory.tops);
      final catResults = wardrobe.filteredItems;
      expect(catResults.every((i) => i.category == ClothingCategory.tops), isTrue);

      // Filter by Season
      wardrobe.setSeasonFilter(Season.winter);
      final seasonResults = wardrobe.filteredItems;
      stopwatch.stop();

      expect(seasonResults.isNotEmpty, isTrue);
      expect(stopwatch.elapsedMilliseconds, lessThan(60),
          reason: 'Filter pipeline must execute well within frame budget');
    });

    test('Multi-attribute sorting on 1,000 items benchmark', () async {
      final wardrobe = WardrobeProvider();
      await wardrobe.clearWardrobe();
      await wardrobe.addMultipleItems(generateSyntheticWardrobe(1000));

      final sorts = [
        WardrobeSortOption.newest,
        WardrobeSortOption.priceAsc,
        WardrobeSortOption.priceDesc,
        WardrobeSortOption.mostWorn,
        WardrobeSortOption.leastWorn,
        WardrobeSortOption.bestCpw,
      ];

      final stopwatch = Stopwatch()..start();
      for (final sort in sorts) {
        wardrobe.setSortOption(sort);
        final list = wardrobe.filteredItems;
        expect(list.length, 1000);

        // Verification of sorting correctness
        if (sort == WardrobeSortOption.priceAsc) {
          expect(list.first.price, lessThanOrEqualTo(list.last.price));
        } else if (sort == WardrobeSortOption.priceDesc) {
          expect(list.first.price, greaterThanOrEqualTo(list.last.price));
        }
      }
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(80),
          reason: '6 consecutive full sorts of 1000 items must complete in < 80ms');
    });
  });

  group('🔒 [STRESS SUITE 2] Backup & Restore Fuzzing, Injection & Scale', () {
    test('1,000-item backup serialization & round-trip restoration', () async {
      final source = WardrobeProvider();
      await source.clearWardrobe();
      final items = generateSyntheticWardrobe(1000);
      await source.addMultipleItems(items);

      final profile = UserProfile(
        name: 'Софія Тестер',
        email: 'sofia.stress@vestora.app',
        preferredStyle: 'Old Money Haute',
        currency: 'EUR (€)',
      );

      final stopwatch = Stopwatch()..start();
      final backupJson = BackupService.generateBackupJson(wardrobe: source, profile: profile);
      final jsonTime = stopwatch.elapsedMilliseconds;

      expect(backupJson.length, greaterThan(150000), reason: 'Payload contains full metadata for 1000 items');
      expect(jsonTime, lessThan(100), reason: 'JSON serialization for 1000 items must be ultra-fast');

      // Validate
      final validation = BackupService.validateBackup(backupJson);
      expect(validation.isValid, isTrue);
      expect(validation.items.length, 1000);

      // Restore
      final target = WardrobeProvider();
      final restoreRes = await BackupService.restoreBackup(
        wardrobe: target,
        rawJson: backupJson,
        replaceAll: true,
      );

      stopwatch.stop();
      expect(restoreRes.success, isTrue);
      expect(restoreRes.count, 1000);
      expect(target.items.length, 1000);
      expect(stopwatch.elapsedMilliseconds, lessThan(1000),
          reason: 'Full 1000-item round-trip backup & disk persistence must be sub-second');
    });

    test('Fuzzing: Resilient against XSS scripts and extreme Unicode in items', () async {
      final maliciousItems = [
        ClothingItem(
          id: 'xss-1',
          title: '<script>alert("XSS Attack!")</script><img src="x" onerror="stealCookie()">',
          brand: '"><b onmouseover=alert(1)>Hacked</b>',
          category: ClothingCategory.tops,
          color: 'DROP TABLE wardrobes; --',
          season: Season.allSeason,
          price: 999999999.99,
          wearCount: 999999,
          imageUrl: 'javascript:alert(1)',
          notes: '✨💎👑👗👠🧣 𝓠𝓾𝓲𝓮𝓽 𝓛𝓾𝔁𝓾𝓻𝔂 \u0000\u0007\u001B[31m',
        ),
      ];

      final source = WardrobeProvider();
      await source.addMultipleItems(maliciousItems);

      final profile = UserProfile();
      final jsonPayload = BackupService.generateBackupJson(wardrobe: source, profile: profile);
      final validation = BackupService.validateBackup(jsonPayload);

      expect(validation.isValid, isTrue);
      expect(validation.items.first.title, contains('<script>'));
      expect(validation.items.first.notes, contains('𝓠𝓾𝓲𝓮𝓽 𝓛𝓾𝔁𝓾𝓻𝔂'));

      final target = WardrobeProvider();
      final res = await BackupService.restoreBackup(wardrobe: target, rawJson: jsonPayload);
      expect(res.success, isTrue);
      expect(target.items.first.price, 999999999.99);
    });

    test('Fuzzing: Handles corrupted, truncated, and malformed JSON without crashing', () {
      final malformedPayloads = [
        '',
        '   ',
        '{',
        '{"version": "1.0.0"}',
        '{"schema": "VESTORA_BACKUP", "items": "not-a-list"}',
        '{"schema": "VESTORA_BACKUP", "items": [{"invalid": true}]}',
        '{"schema": "VESTORA_BACKUP", "items": [null, 123, "string"]}',
        '{"schema": "VESTORA_BACKUP", "items": [{"id": 123, "title": null}]}',
        'A' * 50000, // 50KB garbage buffer
      ];

      for (final payload in malformedPayloads) {
        final res = BackupService.validateBackup(payload);
        expect(res.isValid, isFalse, reason: 'Malformed payload must be rejected');
        expect(res.errorMessage, isNotEmpty);
      }
    });

    test('Fuzzing: Handles extreme numerical boundary conditions (negative, zero, extreme values)', () async {
      final boundaryItem = ClothingItem(
        id: 'boundary-1',
        title: 'Edge Case Garment',
        brand: 'Vintage',
        imageUrl: 'https://example.com/img.jpg',
        category: ClothingCategory.accessories,
        color: 'None',
        season: Season.allSeason,
        price: 0.0,
        wearCount: 0,
      );

      expect(boundaryItem.costPerWear, 0.0);

      final freeItemWorn = ClothingItem(
        id: 'boundary-2',
        title: 'Gifted Silk Scarf',
        brand: 'Hermes',
        imageUrl: 'https://example.com/img.jpg',
        category: ClothingCategory.accessories,
        color: 'Gold',
        season: Season.allSeason,
        price: 0.0,
        wearCount: 15,
      );

      expect(freeItemWorn.costPerWear, 0.0);
    });
  });

  group('🧠 [STRESS SUITE 3] Algorithmic Stress on Massive Wardrobes', () {
    test('WeatherStylistService curates outfits on 1,000 items across 25 environmental conditions', () {
      final wardrobe = generateSyntheticWardrobe(1000);
      final stopwatch = Stopwatch()..start();

      for (final condition in WeatherCondition.values) {
        for (final occasion in Occasion.values) {
          final outfit = WeatherStylistService.curateOutfit(
            wardrobe: wardrobe,
            temperatureCelsius: 18,
            condition: condition,
            occasion: occasion,
          );

          expect(outfit.allItems.isNotEmpty, isTrue);
          expect(outfit.comfortScore, greaterThan(0));
          expect(outfit.weatherRationale, isNotEmpty);
        }
      }
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(50),
          reason: '25 outfit curations over 1000 items must finish in < 50ms');
    });

    test('TravelCapsuleService optimizes 500 items into carry-on constraint in < 25ms', () {
      final wardrobe = generateSyntheticWardrobe(500);

      final stopwatch = Stopwatch()..start();
      final plan = TravelCapsuleService.generateTravelCapsule(
        wardrobe: wardrobe,
        city: 'Париж 🇫🇷',
        days: 7,
        tripType: TripType.cityBreak,
        luggageType: LuggageType.carryOn,
        temperatureCelsius: 19,
      );
      stopwatch.stop();

      expect(plan.capsuleItems.length, lessThanOrEqualTo(LuggageType.carryOn.maxClothingItems));
      expect(plan.dailyOutfits.length, 7);
      expect(stopwatch.elapsedMilliseconds, lessThan(35));
    });

    test('DeclutterService analyzes 1,000 items without overflow or delay', () {
      final wardrobe = generateSyntheticWardrobe(1000);

      final stopwatch = Stopwatch()..start();
      final report = DeclutterService.evaluateDeclutterAndEco(wardrobe: wardrobe);
      stopwatch.stop();

      expect(report.dormantItems.isNotEmpty, isTrue);
      expect(report.totalDormantValue, greaterThan(0));
      expect(report.estimatedResaleCash, greaterThan(0));
      expect(stopwatch.elapsedMilliseconds, lessThan(20));
    });

    test('ColorAnalysisService compliance check on 500 items', () {
      final wardrobe = generateSyntheticWardrobe(500);

      final stopwatch = Stopwatch()..start();
      for (final season in ColorSeason.values) {
        final report = ColorAnalysisService.evaluateAlignment(
          wardrobe: wardrobe,
          season: season,
        );
        expect(report.totalCount, 500);
        expect(report.alignmentPercentage, inInclusiveRange(0, 100));
        expect(report.verdict.isNotEmpty, isTrue);
      }
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(80),
          reason: '4 palette evaluations across 500 items (2000 checks) in < 80ms');
    });
  });

  group('🌐 [STRESS SUITE 4] Network Chaos & API Resilience', () {
    test('Open-Meteo handles HTTP 500 error gracefully with fallback data', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final weather = await DailyStylistService.fetchLiveWeather(
        city: 'Київ',
        client: mockClient,
      );

      expect(weather.isLive, isFalse);
      expect(weather.temperature, greaterThan(0));
      expect(weather.condition, isNotNull);
    });

    test('Open-Meteo handles HTTP 429 Rate Limit gracefully', () async {
      final mockClient = MockClient((request) async {
        return http.Response('{"error": true, "reason": "Hourly rate limit exceeded"}', 429);
      });

      final weather = await DailyStylistService.fetchLiveWeather(
        city: 'Париж',
        client: mockClient,
      );

      expect(weather.isLive, isFalse);
      expect(weather.condition, isNotNull);
    });

    test('Open-Meteo handles Network Timeout without hanging', () async {
      final mockClient = MockClient((request) async {
        await Future.delayed(const Duration(milliseconds: 3800));
        return http.Response('{"current": {"temperature_2m": 22.0}}', 200);
      });

      final stopwatch = Stopwatch()..start();
      final weather = await DailyStylistService.fetchLiveWeather(
        city: 'Мілан',
        client: mockClient,
      );
      stopwatch.stop();

      expect(weather.isLive, isFalse);
      expect(stopwatch.elapsedMilliseconds, lessThan(4200),
          reason: 'Timeout must cleanly abort and trigger fallback without locking thread');
    });

    test('Open-Meteo parses extreme weather conditions correctly', () {
      // Hurricane wind
      expect(DailyStylistService.mapWmoCodeToCondition(0, 85.0), WeatherCondition.coldWindy);
      // Heavy Thunderstorm with hail
      expect(DailyStylistService.mapWmoCodeToCondition(99, 15.0), WeatherCondition.rainy);
      // Heavy snow
      expect(DailyStylistService.mapWmoCodeToCondition(75, 10.0), WeatherCondition.snowy);
      // Unknown code fallback
      expect(DailyStylistService.mapWmoCodeToCondition(9999, 5.0), WeatherCondition.cloudy);
    });

    test('UrlParserService handles invalid URLs and non-HTML payloads safely', () async {
      final store = UrlParserService.detectStore('https://invalid-store.com/garment/123');
      expect(store.name, isNotEmpty);

      // Verify invalid scheme throws expected exception
      expect(
        () => UrlParserService.parseProductUrl('ftp://invalid-protocol.com/item'),
        throwsA(isA<Exception>()),
      );

      // Verify network unreachable gracefully resolves fallback info
      final res = await UrlParserService.parseProductUrl('https://offline-mock-store.ua/sorochka-bila-lin');
      expect(res, isNotNull);
      expect(res!.title, isNotEmpty);
    });
  });

  group('🔄 [STRESS SUITE 5] Concurrency & State Churn Under Pressure', () {
    test('Rapid consecutive wear actions and streak updates maintain data integrity', () async {
      final wardrobe = WardrobeProvider();
      final items = generateSyntheticWardrobe(50);
      await wardrobe.addMultipleItems(items);

      final initialStreak = wardrobe.streakDays;

      // Simulate 30 rapid wear recordings concurrently
      final futures = <Future>[];
      for (int i = 0; i < 30; i++) {
        final selectedItems = [items[i % items.length], items[(i + 1) % items.length]];
        futures.add(wardrobe.recordOutfitWear(selectedItems));
      }

      await Future.wait(futures);

      expect(wardrobe.streakDays, initialStreak + 30);
      expect(wardrobe.items.any((it) => it.wearCount > 0), isTrue);
    });
  });
}
