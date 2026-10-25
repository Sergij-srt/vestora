import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smart_wardrobe/models/clothing_item.dart';
import 'package:smart_wardrobe/screens/add_item_screen.dart';
import 'package:smart_wardrobe/screens/analytics_screen.dart';
import 'package:smart_wardrobe/screens/auth_screen.dart';
import 'package:smart_wardrobe/screens/brand_story_dialog.dart';
import 'package:smart_wardrobe/screens/capsule_matrix_screen.dart';
import 'package:smart_wardrobe/screens/closet_screen.dart';
import 'package:smart_wardrobe/screens/color_analysis_dialog.dart';
import 'package:smart_wardrobe/screens/declutter_hub_screen.dart';
import 'package:smart_wardrobe/screens/editorial_story_screen.dart';
import 'package:smart_wardrobe/screens/fabric_care_screen.dart';
import 'package:smart_wardrobe/screens/ootd_feed_screen.dart';
import 'package:smart_wardrobe/screens/outfit_builder_screen.dart';
import 'package:smart_wardrobe/screens/outfit_calendar_screen.dart';
import 'package:smart_wardrobe/screens/photo_verification_screen.dart';
import 'package:smart_wardrobe/screens/purchase_advisor_screen.dart';
import 'package:smart_wardrobe/screens/settings_ai_screen.dart';
import 'package:smart_wardrobe/screens/settings_hub_screen.dart';
import 'package:smart_wardrobe/screens/travel_capsule_screen.dart';
import 'package:smart_wardrobe/screens/virtual_fitting_screen.dart';
import 'package:smart_wardrobe/services/ai_config_service.dart';
import 'package:smart_wardrobe/services/auth_service.dart';
import 'package:smart_wardrobe/services/clothing_ocr_service.dart';
import 'package:smart_wardrobe/services/gemini_vision_service.dart';
import 'package:smart_wardrobe/services/localization_service.dart';
import 'package:smart_wardrobe/services/outfit_calendar_service.dart';
import 'package:smart_wardrobe/services/supabase_service.dart';
import 'package:smart_wardrobe/services/theme_service.dart';
import 'package:smart_wardrobe/services/user_profile_service.dart';
import 'package:smart_wardrobe/services/wardrobe_provider.dart';
import 'package:smart_wardrobe/services/weather_stylist_service.dart';
import 'package:smart_wardrobe/theme/app_theme.dart';
import 'package:smart_wardrobe/widgets/vestora_image.dart';

/// Valid 1x1 transparent PNG encoded as a data URI for deterministic pixel decoding tests.
const String _kTinyPngDataUri =
    'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';

List<ClothingItem> _buildSeedWardrobe() {
  return [
    ClothingItem(
      id: 'audit_outer_1',
      title: 'Двобортне вовняне пальто преміум крою з поясом',
      brand: 'Massimo Dutti Atelier',
      price: 12900,
      currency: 'UAH',
      imageUrl: _kTinyPngDataUri,
      labelPhotoUrl: _kTinyPngDataUri,
      receiptPhotoUrl: _kTinyPngDataUri,
      category: ClothingCategory.outerwear,
      season: Season.autumn,
      color: 'Карамельний беж',
      size: 'EUR 38 / M',
      fabricComposition: '80% Вовна, 20% Кашемір',
      careInstructions: 'Тільки суха хімчистка',
      countryOfOrigin: 'Made in Portugal',
      storeName: 'Massimo Dutti Gulliver',
      wearCount: 12,
    ),
    ClothingItem(
      id: 'audit_top_1',
      title: 'Шовкова сорочка вільного силуету',
      brand: 'COS',
      price: 4500,
      currency: 'UAH',
      imageUrl: _kTinyPngDataUri,
      category: ClothingCategory.tops,
      season: Season.allSeason,
      color: 'Молочний білий',
      size: 'S',
      fabricComposition: '100% Натуральний шовк',
      careInstructions: 'Ручне прання 30°C',
      wearCount: 8,
    ),
    ClothingItem(
      id: 'audit_bottom_1',
      title: 'Класичні брюки зі стрілками високої посадки',
      brand: 'Arket',
      price: 3800,
      currency: 'UAH',
      imageUrl: _kTinyPngDataUri,
      category: ClothingCategory.bottoms,
      season: Season.allSeason,
      color: 'Графітовий чорний',
      size: 'EUR 38',
      fabricComposition: '96% Вовна, 4% Еластан',
      wearCount: 0, // Dormant item to exercise DeclutterHubScreen cards
    ),
    ClothingItem(
      id: 'audit_shoes_1',
      title: 'Шкіряні лофери на масивній підошві',
      brand: 'Vagabond',
      price: 5600,
      currency: 'UAH',
      imageUrl: _kTinyPngDataUri,
      category: ClothingCategory.shoes,
      season: Season.spring,
      color: 'Чорний',
      size: 'EUR 39',
      fabricComposition: '100% Натуральна шкіра',
      wearCount: 19,
    ),
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // =========================================================================
  // AUDIT 1: SECURITY & PRIVACY
  // =========================================================================
  group('🛡️ [AUDIT 1] Security & Privacy Protections', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await AuthService.instance.signOut();
      await AiConfigService.clearAllData();
      await UserProfileService.initialize();
    });

    test('AuthService hashes passwords with salted iterative HMAC-SHA256 and never stores plaintext', () async {
      const rawSecret = 'MyUltraSecretPass!2026';
      final reg = await AuthService.instance.registerWithEmailAndPassword(
        name: 'Оксана Ковальчук',
        email: 'oksana.sec@vestora.app',
        password: rawSecret,
      );
      expect(reg.success, isTrue);
      expect(AuthService.instance.isLoggedIn, isTrue);
      expect(AuthService.instance.currentSessionToken, isNotNull);
      expect(AuthService.instance.currentSessionToken!.length, greaterThanOrEqualTo(64));

      final prefs = await SharedPreferences.getInstance();
      final rawMapStr = prefs.getString('vestora_auth_registered_users_map')!;
      expect(rawMapStr, isNot(contains(rawSecret)));

      final decoded = json.decode(rawMapStr) as Map<String, dynamic>;
      final entry = decoded['oksana.sec@vestora.app'] as Map<String, dynamic>;
      expect(entry.containsKey('password'), isFalse);
      expect(entry['passwordSalt'], isA<String>());
      expect((entry['passwordSalt'] as String).length, equals(32));
      expect(entry['passwordHash'], isA<String>());
      expect((entry['passwordHash'] as String).length, equals(64));

      // Wrong password rejected; correct password accepted
      await AuthService.instance.signOut();
      final badLogin = await AuthService.instance.signInWithEmailAndPassword(
        email: 'oksana.sec@vestora.app',
        password: 'WrongPassword999',
      );
      expect(badLogin.success, isFalse);

      final goodLogin = await AuthService.instance.signInWithEmailAndPassword(
        email: 'oksana.sec@vestora.app',
        password: rawSecret,
      );
      expect(goodLogin.success, isTrue);

      // Change password rejects wrong current password, updates hash on valid current password
      final badChange = await AuthService.instance.changePassword(
        oldPassword: 'NotMyOldPassword',
        newPassword: 'BrandNewPassword!77',
        confirmPassword: 'BrandNewPassword!77',
      );
      expect(badChange.success, isFalse);

      final okChange = await AuthService.instance.changePassword(
        oldPassword: rawSecret,
        newPassword: 'BrandNewPassword!77',
        confirmPassword: 'BrandNewPassword!77',
      );
      expect(okChange.success, isTrue);

      final updatedRaw = prefs.getString('vestora_auth_registered_users_map')!;
      expect(updatedRaw, isNot(contains('BrandNewPassword!77')));
    });

    test('Legacy plaintext password record transparently migrates to salted hash on login', () async {
      SharedPreferences.setMockInitialValues({
        'vestora_auth_registered_users_map': json.encode({
          'legacy@vestora.app': {
            'name': 'Legacy User',
            'email': 'legacy@vestora.app',
            'password': 'LegacyPlainPassword123',
          },
        }),
      });

      final res = await AuthService.instance.signInWithEmailAndPassword(
        email: 'legacy@vestora.app',
        password: 'LegacyPlainPassword123',
      );
      expect(res.success, isTrue);

      final prefs = await SharedPreferences.getInstance();
      final rawAfter = prefs.getString('vestora_auth_registered_users_map')!;
      expect(rawAfter, isNot(contains('LegacyPlainPassword123')));
      final userAfter = (json.decode(rawAfter) as Map<String, dynamic>)['legacy@vestora.app'] as Map<String, dynamic>;
      expect(userAfter.containsKey('password'), isFalse);
      expect(userAfter['passwordHash'], isNotEmpty);
      expect(userAfter['passwordSalt'], isNotEmpty);
    });

    test('Expired session token automatically invalidates session during AuthService.initialize()', () async {
      SharedPreferences.setMockInitialValues({
        'vestora_auth_is_logged_in': true,
        'vestora_auth_current_user_json': json.encode({
          'id': 'usr_expired',
          'email': 'expired@vestora.app',
          'displayName': 'Expired User',
          'method': 'email',
          'createdAt': DateTime.now().subtract(const Duration(days: 40)).toIso8601String(),
        }),
        'vestora_auth_session_token': 'a' * 64,
        'vestora_auth_session_expires_at':
            DateTime.now().toUtc().subtract(const Duration(hours: 2)).toIso8601String(),
      });

      await AuthService.initialize();
      expect(AuthService.instance.isLoggedIn, isFalse);
      expect(AuthService.instance.currentUser, isNull);
    });

    test('Gemini API calls transmit key exclusively via x-goog-api-key header and redact secrets on error', () async {
      const fakeKey = 'AIzaSyTestSecretKeyForAudit1234567890';
      Uri? capturedPingUri;
      Map<String, String>? capturedPingHeaders;

      final pingClient = MockClient((request) async {
        capturedPingUri = request.url;
        capturedPingHeaders = request.headers;
        return http.Response('{"candidates":[]}', 200);
      });

      final pingRes = await AiConfigService.testApiKey(fakeKey, httpClient: pingClient);
      expect(pingRes.isValid, isTrue);
      expect(capturedPingUri.toString(), isNot(contains(fakeKey)));
      expect(capturedPingUri!.queryParameters.containsKey('key'), isFalse);
      expect(capturedPingHeaders!['x-goog-api-key'], equals(fakeKey));

      Uri? capturedVisionUri;
      Map<String, String>? capturedVisionHeaders;
      final visionClient = MockClient((request) async {
        capturedVisionUri = request.url;
        capturedVisionHeaders = request.headers;
        return http.Response(
          json.encode({
            'error': {'message': 'Quota exceeded for key $fakeKey at ?key=$fakeKey'}
          }),
          429,
        );
      });

      final visionRes = await GeminiVisionService.analyzePhotos(
        clothingPhotoUrl: _kTinyPngDataUri,
        overrideApiKey: fakeKey,
        httpClient: visionClient,
      );
      expect(capturedVisionUri.toString(), isNot(contains(fakeKey)));
      expect(capturedVisionHeaders!['x-goog-api-key'], equals(fakeKey));
      if (visionRes.errorMessage != null) {
        expect(visionRes.errorMessage!, isNot(contains(fakeKey)));
      }
      expect(
        AiConfigService.redactSecrets('Failed https://api.example?key=$fakeKey ($fakeKey)', fakeKey),
        isNot(contains(fakeKey)),
      );

      // Verify zero Dart files anywhere in lib/ leak API keys via ?key= query parameter
      final dartFiles = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));
      for (final file in dartFiles) {
        expect(
          file.readAsStringSync(),
          isNot(contains('?key=')),
          reason: 'API key query parameter leak found in ${file.path}',
        );
      }
    });

    test('Supabase SQL schema enforces per-user folder isolation on S3 storage bucket policies', () async {
      final sqlFile = File('supabase_schema.sql').readAsStringSync();
      final runtimeSchema = SupabaseService.getSqlSchema();

      for (final schema in [sqlFile, runtimeSchema]) {
        expect(schema, contains("(storage.foldername(name))[1] = auth.uid()::text"));
        expect(schema.toUpperCase(), contains('FOR INSERT'));
        expect(schema.toUpperCase(), contains('FOR UPDATE'));
        expect(schema.toUpperCase(), contains('FOR DELETE'));
      }
    });
  });

  // =========================================================================
  // AUDIT 2: DATA INTEGRITY & CLOUD SYNC
  // =========================================================================
  group('🔄 [AUDIT 2] Data Integrity, Cloud Sync & Storage Quota Guards', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await OutfitCalendarService.clearAllPlans();
    });

    test('Lossless snake_case <-> camelCase round-trip for ClothingItem and PlannedDayOutfit', () {
      final original = _buildSeedWardrobe().first.copyWith(
        sourceUrl: 'https://massimodutti.com/coat',
        galleryImages: const ['https://cdn.vestora.app/1.jpg', 'https://cdn.vestora.app/2.jpg'],
      );

      final pgRow = SupabaseService.itemToRow(original, 'uid_123');
      expect(pgRow['user_id'], equals('uid_123'));
      expect(pgRow['image_url'], equals(original.imageUrl));
      expect(pgRow['fabric_composition'], equals(original.fabricComposition));
      expect(pgRow['care_instructions'], equals(original.careInstructions));
      expect(pgRow['country_of_origin'], equals(original.countryOfOrigin));
      expect(pgRow['wear_count'], equals(original.wearCount));
      expect(pgRow.containsKey('imageUrl'), isFalse); // Strictly snake_case for Postgres!

      final restored = SupabaseService.itemFromRow(pgRow);
      expect(restored.id, equals(original.id));
      expect(restored.title, equals(original.title));
      expect(restored.fabricComposition, equals(original.fabricComposition));
      expect(restored.careInstructions, equals(original.careInstructions));
      expect(restored.countryOfOrigin, equals(original.countryOfOrigin));
      expect(restored.storeName, equals(original.storeName));
      expect(restored.sourceUrl, equals(original.sourceUrl));
      expect(restored.wearCount, equals(original.wearCount));

      final plan = PlannedDayOutfit(
        dateStr: '2026-10-28',
        date: DateTime(2026, 10, 28),
        weatherTemp: 14,
        weatherCondition: WeatherCondition.rainy,
        occasion: Occasion.work,
        eventTitle: 'Презентація колекції',
        outerwearId: 'audit_outer_1',
        topId: 'audit_top_1',
        bottomId: 'audit_bottom_1',
        shoesId: 'audit_shoes_1',
        isWorn: true,
        notes: 'Взяти парасольку',
      );
      final planRow = SupabaseService.plannedOutfitToRow(plan, 'uid_123');
      final restoredPlan = SupabaseService.plannedOutfitFromRow(planRow)!;
      expect(restoredPlan.dateStr, equals('2026-10-28'));
      expect(restoredPlan.eventTitle, equals('Презентація колекції'));
      expect(restoredPlan.outerwearId, equals('audit_outer_1'));
      expect(restoredPlan.topId, equals('audit_top_1'));
      expect(restoredPlan.bottomId, equals('audit_bottom_1'));
      expect(restoredPlan.shoesId, equals('audit_shoes_1'));
      expect(restoredPlan.isWorn, isTrue);
    });

    test('Tombstone deletion prevents resurrected items during cloud reconciliation', () async {
      final wardrobe = WardrobeProvider();
      await wardrobe.initialized;
      await wardrobe.clearWardrobe(clearTombstones: true);

      final itemA = _buildSeedWardrobe()[0];
      final itemB = _buildSeedWardrobe()[1];
      await wardrobe.addItem(itemA);
      await wardrobe.addItem(itemB);

      // User deletes itemA locally -> recorded in tombstone set
      await wardrobe.removeItem(itemA.id);
      expect(wardrobe.deletedItemIds.contains(itemA.id), isTrue);

      // Cloud still returns both itemA and itemB (with higher wear count on itemB)
      final cloudRows = [
        SupabaseService.itemToRow(itemA, 'uid_1'),
        SupabaseService.itemToRow(itemB.copyWith(wearCount: 25), 'uid_1'),
        SupabaseService.itemToRow(_buildSeedWardrobe()[2], 'uid_1'),
      ];

      final diff = SupabaseService.reconcileCloudItems(
        localItems: wardrobe.items,
        deletedIds: wardrobe.deletedItemIds,
        cloudRows: cloudRows,
      );

      // Deleted itemA MUST NOT be resurrected; new item[2] inserted; itemB wearCount upgraded to 25
      expect(diff.itemsToInsert.map((e) => e.id), isNot(contains(itemA.id)));
      expect(diff.itemsToInsert.map((e) => e.id), contains('audit_bottom_1'));
      expect(diff.itemsWithHigherCloudWear.single.wearCount, equals(25));
    });

    test('Web localStorage 5MB quota guard strips oversized >512KB inline Base64 payloads safely', () async {
      final wardrobe = WardrobeProvider();
      await wardrobe.initialized;
      await wardrobe.clearWardrobe(clearTombstones: true);

      final hugeBase64 = 'data:image/jpeg;base64,${'A' * (600 * 1024)}'; // ~600 KB > 512 KB cap
      final oversizedItem = ClothingItem(
        id: 'oversized_b64',
        title: 'Oversized Camera Capture',
        brand: 'Zara',
        price: 1999,
        imageUrl: hugeBase64,
        labelPhotoUrl: hugeBase64,
        category: ClothingCategory.tops,
        color: 'Білий',
      );

      await wardrobe.addItem(oversizedItem);
      expect(wardrobe.quotaGuardTriggered, isTrue);

      final stored = wardrobe.items.firstWhere((i) => i.id == 'oversized_b64');
      expect(stored.imageUrl.length, lessThan(1024));
      expect(stored.labelPhotoUrl, isNull);

      final prefs = await SharedPreferences.getInstance();
      final serialized = prefs.getString('smart_wardrobe_items_v2')!;
      expect(serialized.length, lessThan(WardrobeProvider.maxStorageBudgetChars));
    });

    test('1-click AuthService.deleteAccount wipes credentials, wardrobe, calendar, profile, and API keys', () async {
      await AuthService.instance.registerWithEmailAndPassword(
        name: 'Delete Me',
        email: 'deleteme@vestora.app',
        password: 'DeletePass!123',
      );
      await AiConfigService.setApiKey('AIzaSyTemporaryUserKey999999999');
      final wardrobe = WardrobeProvider();
      await wardrobe.initialized;
      await wardrobe.addItem(_buildSeedWardrobe().first);
      await OutfitCalendarService.savePlan(
        PlannedDayOutfit(
          dateStr: '2026-11-01',
          date: DateTime(2026, 11, 1),
          weatherTemp: 12,
          weatherCondition: WeatherCondition.sunny,
          occasion: Occasion.casual,
          eventTitle: 'Test Plan',
        ),
      );

      final del = await AuthService.instance.deleteAccount(
        wardrobe: wardrobe,
        deleteCloudData: false,
      );
      expect(del.success, isTrue);
      expect(AuthService.instance.isLoggedIn, isFalse);
      expect(AiConfigService.apiKey, isNull);
      expect(wardrobe.items, isEmpty);
      expect(await OutfitCalendarService.getAllPlans(), isEmpty);
    });
  });

  // =========================================================================
  // AUDIT 3: LOCALIZATION (6 LANGUAGES) & TRANSLATION PARITY
  // =========================================================================
  group('🌍 [AUDIT 3] 6-Language Localization Parity (UK, EN, FR, IT, ES, DE)', () {
    test('All 6 languages have 100% identical key sets, non-empty values, and fixed Spanish strings', () async {
      final ukMap = LocalizationService.translationsFor(AppLanguage.uk);
      expect(ukMap.length, greaterThanOrEqualTo(60));

      for (final lang in AppLanguage.values) {
        final map = LocalizationService.translationsFor(lang);
        final missingFromLang = ukMap.keys.toSet().difference(map.keys.toSet());
        final extraInLang = map.keys.toSet().difference(ukMap.keys.toSet());

        expect(
          missingFromLang,
          isEmpty,
          reason: 'Language ${lang.code} is missing keys: $missingFromLang',
        );
        expect(
          extraInLang,
          isEmpty,
          reason: 'Language ${lang.code} has unexpected extra keys: $extraInLang',
        );

        for (final entry in map.entries) {
          expect(
            entry.value.trim(),
            isNotEmpty,
            reason: 'Empty translation for ${lang.code}.${entry.key}',
          );
        }
      }

      // Verify previously untranslated Spanish bug is fixed
      final esMap = LocalizationService.translationsFor(AppLanguage.es);
      expect(esMap['settings_change_pwd'], equals('Contraseña'));
      expect(esMap['settings_delete_account'], isNotEmpty);
    });

    test('formatPrice and currencySymbol dynamically format amounts with correct placement and thousands separators', () {
      // Currency symbols
      expect(LocalizationService.currencySymbol('UAH'), equals('₴'));
      expect(LocalizationService.currencySymbol('EUR'), equals('€'));
      expect(LocalizationService.currencySymbol('USD'), equals('\$'));
      expect(LocalizationService.currencySymbol('GBP'), equals('£'));
      expect(LocalizationService.currencySymbol('PLN'), equals('zł'));

      // Ukrainian locale: trailing symbol with space, space thousands separator
      expect(
        LocalizationService.formatPrice(4499, currencyCode: 'UAH', language: AppLanguage.uk),
        equals('4 499 ₴'),
      );
      expect(
        LocalizationService.formatPrice(1250000, currencyCode: 'UAH', language: AppLanguage.uk),
        equals('1 250 000 ₴'),
      );

      // English locale: leading symbol for $, £, €, comma thousands separator
      expect(
        LocalizationService.formatPrice(4499, currencyCode: 'USD', language: AppLanguage.en),
        equals('\$4,499'),
      );
      expect(
        LocalizationService.formatPrice(950, currencyCode: 'GBP', language: AppLanguage.en),
        equals('£950'),
      );

      // European French locale: trailing euro symbol with space, comma decimal
      expect(
        LocalizationService.formatPrice(1250.50, currencyCode: 'EUR', language: AppLanguage.fr),
        equals('1 250,50 €'),
      );
    });
  });

  // =========================================================================
  // AUDIT 4: WCAG 2.1 AA CONTRAST & MULTI-VIEWPORT RESPONSIVE UI MATRIX
  // =========================================================================
  group('📐 [AUDIT 4] WCAG AA Contrast & 19-Screen Multi-Viewport Responsive Matrix', () {
    test('Light and Dark theme palettes satisfy WCAG 2.1 AA (>= 4.5:1) contrast ratios', () {
      // Light mode pairs
      expect(AppTheme.contrastRatio(AppTheme.primary, AppTheme.surface), greaterThanOrEqualTo(4.5));
      expect(AppTheme.contrastRatio(AppTheme.primary, AppTheme.background), greaterThanOrEqualTo(4.5));
      expect(AppTheme.contrastRatio(AppTheme.muted, AppTheme.surface), greaterThanOrEqualTo(4.5));
      expect(AppTheme.contrastRatio(AppTheme.muted, AppTheme.background), greaterThanOrEqualTo(4.5));
      expect(AppTheme.contrastRatio(AppTheme.accent, Colors.white), greaterThanOrEqualTo(4.5));
      expect(AppTheme.contrastRatio(AppTheme.success, Colors.white), greaterThanOrEqualTo(4.5));
      expect(AppTheme.contrastRatio(AppTheme.danger, Colors.white), greaterThanOrEqualTo(4.5));

      // Dark mode pairs
      expect(AppTheme.contrastRatio(AppTheme.darkText, AppTheme.darkBackground), greaterThanOrEqualTo(4.5));
      expect(AppTheme.contrastRatio(AppTheme.darkText, AppTheme.darkSurface), greaterThanOrEqualTo(4.5));
      expect(AppTheme.contrastRatio(AppTheme.darkText, AppTheme.darkCard), greaterThanOrEqualTo(4.5));
      expect(AppTheme.contrastRatio(AppTheme.darkMuted, AppTheme.darkSurface), greaterThanOrEqualTo(4.5));
      expect(AppTheme.contrastRatio(AppTheme.darkMuted, AppTheme.darkCard), greaterThanOrEqualTo(4.5));
      expect(AppTheme.contrastRatio(AppTheme.darkAccent, AppTheme.darkCard), greaterThanOrEqualTo(4.5));
      expect(AppTheme.contrastRatio(Colors.black, AppTheme.darkAccent), greaterThanOrEqualTo(4.5));

      // Minimum 48x48dp accessible tap target configuration in button themes
      final lightBtnMin = AppTheme.lightTheme.elevatedButtonTheme.style?.minimumSize?.resolve({});
      final darkBtnMin = AppTheme.darkTheme.elevatedButtonTheme.style?.minimumSize?.resolve({});
      expect(lightBtnMin?.height, greaterThanOrEqualTo(48));
      expect(darkBtnMin?.height, greaterThanOrEqualTo(48));
    });

    testWidgets(
      'All 19 screens & dialogs render with ZERO RenderFlex overflows across 320px, 390px, 768px, 1440px in Light & Dark modes (German stress locale)',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({});
        await UserProfileService.initialize();
        await AiConfigService.initialize();
        await OutfitCalendarService.initialize();
        // Use German ('de') as the longest European language string stress test!
        await LocalizationService.instance.setLanguage(AppLanguage.de);

        final seedItems = _buildSeedWardrobe();
        final wardrobe = WardrobeProvider();
        await wardrobe.initialized;
        await wardrobe.clearWardrobe(clearTombstones: true);
        for (final item in seedItems) {
          await wardrobe.addItem(item);
        }

        final ocrSample = OcrCombinedResult(
          title: 'Кашеміровий кардиган преміум лінії',
          brand: 'Massimo Dutti',
          category: ClothingCategory.tops,
          season: Season.autumn,
          color: 'Бежевий',
          price: 6490,
          size: 'EUR 38 / M',
          fabricComposition: '100% Кашемір',
          careInstructions: 'Ручне прання 30°C',
          countryOfOrigin: 'Made in Italy',
          storeName: 'Massimo Dutti',
          itemPhoto: _kTinyPngDataUri,
          labelPhoto: _kTinyPngDataUri,
          receiptPhoto: _kTinyPngDataUri,
        );

        final screenBuilders = <String, Widget Function()>{
          'ClosetScreen': () => const ClosetScreen(),
          'AddItemScreen': () => AddItemScreen(onSaved: () {}),
          'AnalyticsScreen': () => const AnalyticsScreen(),
          'AuthScreen': () => const AuthScreen(),
          'CapsuleMatrixScreen': () => const CapsuleMatrixScreen(),
          'ColorAnalysisSheet': () => const Scaffold(body: ColorAnalysisSheet()),
          'DeclutterHubScreen': () => const DeclutterHubScreen(),
          'EditorialStoryScreen': () => EditorialStoryScreen(items: seedItems),
          'FabricCareScreen': () => const FabricCareScreen(),
          'OotdFeedScreen': () => const OotdFeedScreen(),
          'OutfitBuilderScreen': () => const OutfitBuilderScreen(),
          'OutfitCalendarScreen': () => const OutfitCalendarScreen(),
          'PhotoVerificationScreen': () => PhotoVerificationScreen(
                initialData: ocrSample,
                isAiVision: true,
              ),
          'PurchaseAdvisorScreen': () => const PurchaseAdvisorScreen(),
          'SettingsAiScreen': () => const SettingsAiScreen(),
          'SettingsHubScreen': () => const SettingsHubScreen(),
          'TravelCapsuleScreen': () => const TravelCapsuleScreen(),
          'VirtualFittingScreen': () => VirtualFittingScreen(
                initialOuterwear: seedItems[0],
                initialTop: seedItems[1],
                initialBottom: seedItems[2],
                initialShoes: seedItems[3],
              ),
        };

        const viewports = <String, Size>{
          '320x640_narrow': Size(320, 640),
          '390x844_mobile': Size(390, 844),
          '768x1024_tablet': Size(768, 1024),
          '1440x900_desktop': Size(1440, 900),
        };

        final layoutErrors = <String>[];
        final originalOnError = FlutterError.onError;
        FlutterError.onError = (FlutterErrorDetails details) {
          final msg = details.exceptionAsString();
          // Ignore expected offline mock HttpClient 400 image errors; capture ALL rendering/layout/lifecycle errors!
          if (!details.silent ||
              msg.contains('RenderFlex') ||
              msg.contains('overflowed') ||
              msg.contains('TextEditingController')) {
            layoutErrors.add(details.toString());
          }
        };

        final allMatrixFailures = <String>[];
        try {
          for (final isDark in [false, true]) {
            await ThemeService.instance.setThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);

            for (final vpEntry in viewports.entries) {
              tester.view.physicalSize = vpEntry.value;
              tester.view.devicePixelRatio = 1.0;

              for (final screenEntry in screenBuilders.entries) {
                layoutErrors.clear();

                await tester.pumpWidget(
                  MultiProvider(
                    providers: [
                      ChangeNotifierProvider<WardrobeProvider>.value(value: wardrobe),
                      ChangeNotifierProvider<LocalizationService>.value(
                        value: LocalizationService.instance,
                      ),
                      ChangeNotifierProvider<ThemeService>.value(
                        value: ThemeService.instance,
                      ),
                      ChangeNotifierProvider<AuthService>.value(
                        value: AuthService.instance,
                      ),
                    ],
                    child: MaterialApp(
                      debugShowCheckedModeBanner: false,
                      theme: AppTheme.lightTheme,
                      darkTheme: AppTheme.darkTheme,
                      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
                      home: screenEntry.value(),
                    ),
                  ),
                );

                await tester.pump();
                await tester.pump(const Duration(milliseconds: 250));

                final pendingEx = tester.takeException();
                if (pendingEx != null) {
                  layoutErrors.add(pendingEx.toString());
                }

                if (layoutErrors.isNotEmpty) {
                  allMatrixFailures.add(
                    '[${screenEntry.key} @ ${vpEntry.key} (isDark=$isDark)]:\n${layoutErrors.join("\n")}',
                  );
                }
              }

              // Also test BrandStoryDialog (19th file in lib/screens/) at 320px & all viewports!
              layoutErrors.clear();
              await tester.pumpWidget(
                MaterialApp(
                  theme: AppTheme.lightTheme,
                  darkTheme: AppTheme.darkTheme,
                  themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
                  home: Builder(
                    builder: (ctx) => Scaffold(
                      body: Center(
                        child: ElevatedButton(
                          onPressed: () => showVestoraBrandStory(ctx),
                          child: const Text('Open Brand Story'),
                        ),
                      ),
                    ),
                  ),
                ),
              );
              await tester.tap(find.text('Open Brand Story'));
              await tester.pump();
              await tester.pump(const Duration(milliseconds: 300));
              final brandEx = tester.takeException();
              if (brandEx != null) layoutErrors.add(brandEx.toString());
              if (layoutErrors.isNotEmpty) {
                allMatrixFailures.add(
                  '[BrandStoryDialog @ ${vpEntry.key} (isDark=$isDark)]:\n${layoutErrors.join("\n")}',
                );
              }
            }
          }

          // Unmount cleanly to trigger all State.dispose() methods and verify zero controller/timer leaks
          layoutErrors.clear();
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
          final disposeEx = tester.takeException();
          if (disposeEx != null) layoutErrors.add(disposeEx.toString());
          if (layoutErrors.isNotEmpty) {
            allMatrixFailures.add('[Dispose / Unmount]:\n${layoutErrors.join("\n")}');
          }

          expect(
            allMatrixFailures,
            isEmpty,
            reason:
                'Found ${allMatrixFailures.length} screen/viewport layout errors:\n${allMatrixFailures.join("\n====================\n")}',
          );
        } finally {
          FlutterError.onError = originalOnError;
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
          await LocalizationService.instance.setLanguage(AppLanguage.uk);
          await ThemeService.instance.setThemeMode(ThemeMode.light);
        }
      },
    );
  });

  // =========================================================================
  // AUDIT 5: MEMORY LEAKS, CONTROLLER LIFECYCLE & BOUNDED LRU IMAGE CACHE
  // =========================================================================
  group('⚡ [AUDIT 5] Memory Safety & Bounded Base64 Image LRU Cache', () {
    test('VestoraImage decodes Base64 URIs accurately and enforces 60-entry LRU upper bound', () {
      VestoraImage.clearMemoryCache();
      expect(VestoraImage.memoryCacheSize, equals(0));

      final bytes = VestoraImage.decodeDataUriCached(_kTinyPngDataUri);
      expect(bytes, isNotNull);
      expect(bytes!.length, greaterThan(10));
      expect(VestoraImage.memoryCacheSize, equals(1));

      // Malformed data URIs fail safely without throwing
      expect(VestoraImage.decodeDataUriCached('data:image/png;base64,'), isNull);
      expect(VestoraImage.decodeDataUriCached('data:image/png;base64,%%%NOT_BASE64%%%'), isNull);

      // Insert 85 distinct valid Base64 payloads -> cache must stay strictly <= 60
      for (int i = 0; i < 85; i++) {
        final payload = base64Encode(utf8.encode('image_payload_slot_$i'));
        final decoded = VestoraImage.decodeDataUriCached('data:image/png;base64,$payload');
        expect(decoded, isNotNull);
      }
      expect(VestoraImage.memoryCacheSize, equals(VestoraImage.maxMemoryCacheEntries));
      expect(VestoraImage.memoryCacheSize, lessThanOrEqualTo(60));
    });
  });

  // =========================================================================
  // AUDIT 6: APP STORE, GOOGLE PLAY & WEB PWA RELEASE READINESS
  // =========================================================================
  group('🚀 [AUDIT 6] Store Compliance, R8/ProGuard, Manifests & Web PWA', () {
    test('Android, iOS, and Web platform configurations satisfy Store & WCAG requirements', () {
      final androidManifest =
          File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
      expect(androidManifest, contains('Vestora'));
      expect(androidManifest, contains('android.permission.INTERNET'));
      expect(androidManifest, contains('android:required="false"'));
      expect(androidManifest, contains('android:scheme="io.supabase.vestora"'));
      // Google Play Photo Picker policy: must NOT request broad READ_MEDIA_IMAGES/VIDEO permissions
      expect(androidManifest, isNot(contains('android.permission.READ_MEDIA_IMAGES')));
      expect(androidManifest, isNot(contains('android.permission.READ_MEDIA_VIDEO')));

      final gradleKts = File('android/app/build.gradle.kts').readAsStringSync();
      expect(gradleKts, contains('isMinifyEnabled = true'));
      expect(gradleKts, contains('proguard-rules.pro'));
      expect(File('android/app/proguard-rules.pro').existsSync(), isTrue);

      final iosPlist = File('ios/Runner/Info.plist').readAsStringSync();
      expect(iosPlist, contains('NSCameraUsageDescription'));
      expect(iosPlist, contains('NSPhotoLibraryUsageDescription'));
      expect(iosPlist, contains('io.supabase.vestora'));

      final webIndex = File('web/index.html').readAsStringSync();
      // WCAG 2.1 AA SC 1.4.4: user-scalable=no and maximum-scale=1.0 must NOT block pinch-to-zoom
      expect(webIndex, isNot(contains('user-scalable=no')));
      expect(webIndex, isNot(contains('maximum-scale=1')));
      expect(webIndex, contains('Content-Security-Policy'));

      final serviceWorker = File('web/service_worker.js').readAsStringSync();
      expect(serviceWorker, contains('url.origin !== self.location.origin'));
      expect(serviceWorker, contains('/api/'));
      expect(serviceWorker, contains('.wasm'));
    });

    testWidgets('SettingsHubScreen exposes 1-click Account Deletion confirmation flow', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await LocalizationService.instance.setLanguage(AppLanguage.uk);
      await UserProfileService.initialize();
      await AuthService.instance.registerWithEmailAndPassword(
        name: 'Тест Видалення',
        email: 'storecheck@vestora.app',
        password: 'StorePassword123',
      );
      final wardrobe = WardrobeProvider();
      await wardrobe.initialized;

      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1.0;
      try {
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<WardrobeProvider>.value(value: wardrobe),
              ChangeNotifierProvider<LocalizationService>.value(
                value: LocalizationService.instance,
              ),
              ChangeNotifierProvider<ThemeService>.value(value: ThemeService.instance),
              ChangeNotifierProvider<AuthService>.value(value: AuthService.instance),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const SettingsHubScreen(),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        final deleteTile = find.byIcon(Icons.delete_forever_rounded);
        await tester.scrollUntilVisible(
          deleteTile,
          250,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pump();
        expect(deleteTile, findsOneWidget);

        await tester.tap(deleteTile);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));

        // Confirmation dialog appears with irreversible warning and confirm button
        expect(find.byType(AlertDialog), findsOneWidget);
        final confirmBtn = find.text(
          LocalizationService.instance.translate('settings_delete_confirm_btn'),
        );
        expect(confirmBtn, findsOneWidget);

        await tester.tap(confirmBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(AuthService.instance.isLoggedIn, isFalse);
      } finally {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      }
    });
  });
}
