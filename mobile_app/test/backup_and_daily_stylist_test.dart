import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_wardrobe/models/clothing_item.dart';
import 'package:smart_wardrobe/services/wardrobe_provider.dart';
import 'package:smart_wardrobe/services/user_profile_service.dart';
import 'package:smart_wardrobe/services/backup_service.dart';
import 'package:smart_wardrobe/services/daily_stylist_service.dart';
import 'package:smart_wardrobe/services/weather_stylist_service.dart';
import 'package:smart_wardrobe/services/virtual_fitting_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  final testItems = [
    ClothingItem(
      id: 'test-top-1',
      title: 'Біла сорочка Poplin',
      brand: 'Cos',
      category: ClothingCategory.tops,
      color: 'Білий',
      season: Season.allSeason,
      price: 2400,
      imageUrl: 'https://images.unsplash.com/photo-1598033129183-c4f50c736f10?w=600',
    ),
    ClothingItem(
      id: 'test-bot-1',
      title: 'Штани з защипами',
      brand: 'Massimo Dutti',
      category: ClothingCategory.bottoms,
      color: 'Бежевий',
      season: Season.allSeason,
      price: 3600,
      imageUrl: 'https://images.unsplash.com/photo-1594633312681-425c7b97ccd1?w=600',
    ),
    ClothingItem(
      id: 'test-shoes-1',
      title: 'Шкіряні дербі',
      brand: 'Church\'s',
      category: ClothingCategory.shoes,
      color: 'Чорний',
      season: Season.allSeason,
      price: 7500,
      imageUrl: 'https://images.unsplash.com/photo-1614252235316-8c857d38b5f4?w=600',
    ),
  ];

  group('BackupService Tests', () {
    test('generateBackupJson produces valid VESTORA_BACKUP payload', () {
      final wardrobe = WardrobeProvider();
      wardrobe.addMultipleItems(testItems);

      final profile = UserProfile(
        name: 'Софія Лісова',
        email: 'sofia@vestora.app',
        preferredStyle: 'Quiet Luxury',
        currency: 'UAH (₴)',
      );

      final jsonStr = BackupService.generateBackupJson(wardrobe: wardrobe, profile: profile);
      expect(jsonStr, contains('VESTORA_BACKUP'));
      expect(jsonStr, contains('1.0'));
      expect(jsonStr, contains('Софія Лісова'));
      expect(jsonStr, contains('Quiet Luxury'));
      expect(jsonStr, contains('Біла сорочка Poplin'));

      final validation = BackupService.validateBackup(jsonStr);
      expect(validation.isValid, isTrue);
      expect(validation.items.length, 3);
      expect(validation.preferredStyle, 'Quiet Luxury');
      expect(validation.currency, 'UAH (₴)');
    });

    test('validateBackup rejects invalid or empty strings gracefully', () {
      final emptyRes = BackupService.validateBackup('');
      expect(emptyRes.isValid, isFalse);
      expect(emptyRes.errorMessage, contains('порожній'));

      final invalidRes = BackupService.validateBackup('{"corrupted": true}');
      expect(invalidRes.isValid, isFalse);
      expect(invalidRes.errorMessage, contains('відсутній список речей'));
    });

    test('restoreBackup restores items and updates profile settings', () async {
      final exportWardrobe = WardrobeProvider();
      await exportWardrobe.addMultipleItems(testItems);

      final profile = UserProfile(
        name: 'Ольга',
        email: 'olga@test.com',
        preferredStyle: 'Old Money',
      );

      final jsonStr = BackupService.generateBackupJson(
        wardrobe: exportWardrobe,
        profile: profile,
      );

      final targetWardrobe = WardrobeProvider();
      final restoreRes = await BackupService.restoreBackup(
        wardrobe: targetWardrobe,
        rawJson: jsonStr,
        replaceAll: true,
      );

      expect(restoreRes.success, isTrue);
      expect(restoreRes.count, greaterThan(0));
      expect(targetWardrobe.items.isNotEmpty, isTrue);
    });
  });

  group('DailyStylistService Tests', () {
    test('getTodayDigest creates morning look based on wardrobe', () async {
      final digest = await DailyStylistService.getTodayDigest(
        wardrobeItems: testItems,
        location: 'Львів, Україна',
      );

      expect(digest.city, 'Львів');
      expect(digest.temperature, greaterThan(0));
      expect(digest.weatherSummary, isNotEmpty);
      expect(digest.stylistTip, isNotEmpty);
      expect(digest.outfitItems, isNotEmpty);
      expect(digest.isWorn, isFalse);
    });

    test('markWorn increments streak and marks digest as worn', () async {
      final wardrobe = WardrobeProvider();
      wardrobe.addMultipleItems(testItems);
      final initialStreak = wardrobe.streakDays;

      final digest = await DailyStylistService.getTodayDigest(
        wardrobeItems: testItems,
        location: 'Київ',
      );

      await DailyStylistService.markWorn(wardrobe, digest);
      expect(digest.isWorn, isTrue);
      expect(wardrobe.streakDays, initialStreak + 1);
    });

    test('mapWmoCodeToCondition correctly translates WMO weather codes', () {
      expect(DailyStylistService.mapWmoCodeToCondition(0, 10), WeatherCondition.sunny);
      expect(DailyStylistService.mapWmoCodeToCondition(2, 10), WeatherCondition.cloudy);
      expect(DailyStylistService.mapWmoCodeToCondition(61, 10), WeatherCondition.rainy);
      expect(DailyStylistService.mapWmoCodeToCondition(71, 10), WeatherCondition.snowy);
      expect(DailyStylistService.mapWmoCodeToCondition(1, 35), WeatherCondition.coldWindy);
    });

    test('fetchLiveWeather returns valid weather object with fallback resilience', () async {
      final weather = await DailyStylistService.fetchLiveWeather(city: 'Київ');
      expect(weather.temperature, isNotNull);
      expect(weather.condition, isNotNull);
      expect(weather.windSpeed, greaterThanOrEqualTo(0));
    });

    test('defaultFashionCities contains key global and Ukrainian cities', () {
      expect(defaultFashionCities.any((c) => c.name == 'Київ'), isTrue);
      expect(defaultFashionCities.any((c) => c.name == 'Львів'), isTrue);
      expect(defaultFashionCities.any((c) => c.name == 'Париж'), isTrue);
      expect(defaultFashionCities.any((c) => c.name == 'Мілан'), isTrue);
    });
  });

  group('Photorealistic Virtual Try-On Tests', () {
    test('generatePhotorealisticTryOn produces high-fidelity result in chosen environment', () async {
      final result = await VirtualFittingService.generatePhotorealisticTryOn(
        faceUrl: VirtualFittingService.presetFaces.first.faceUrl,
        outfitItems: testItems,
        environment: TryOnEnvironment.milanBoutique,
      );

      expect(result.generatedImageUrl, isNotEmpty);
      expect(result.environment, TryOnEnvironment.milanBoutique);
      expect(result.aestheticTheme, contains('Quiet Luxury'));
      expect(result.editorialVerdict, isNotEmpty);
      expect(result.clothingSummary, contains('Cos'));
    });

    test('TryOnEnvironment supports all 4 luxury ambiences', () {
      expect(TryOnEnvironment.values.length, 4);
      expect(TryOnEnvironment.parisianCafe.label, contains('Паризька'));
      expect(TryOnEnvironment.milanBoutique.label, contains('Міланський'));
      expect(TryOnEnvironment.vogueStudio.label, contains('Vogue'));
      expect(TryOnEnvironment.goldenHourTerrace.label, contains('Golden Hour'));
    });
  });
}
