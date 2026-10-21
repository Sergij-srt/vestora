import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_wardrobe/services/ai_config_service.dart';
import 'package:smart_wardrobe/services/gemini_vision_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AiConfigService & BYOK Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await AiConfigService.initialize();
    });

    test('Initializes with default 3 ad credits and local fallback mode when no key is set', () {
      expect(AiConfigService.hasCustomKey, isFalse);
      expect(AiConfigService.adCredits, equals(3));
      expect(AiConfigService.activeMode, equals(AiEngineMode.rewardedAd));
    });

    test('Switches to BYOK mode when custom Gemini API key is saved', () async {
      await AiConfigService.setApiKey('AIzaSyFakeTestKey12345');
      expect(AiConfigService.hasCustomKey, isTrue);
      expect(AiConfigService.apiKey, equals('AIzaSyFakeTestKey12345'));
      expect(AiConfigService.activeMode, equals(AiEngineMode.byok));
      expect(AiConfigService.activeModeLabel, contains('Власний Gemini API ключ'));

      // Removing key reverts back
      await AiConfigService.setApiKey(null);
      expect(AiConfigService.hasCustomKey, isFalse);
    });

    test('Consumes ad credits until 0 then drops to local fallback mode', () async {
      await AiConfigService.setApiKey(null);
      expect(AiConfigService.adCredits, equals(3));

      expect(await AiConfigService.consumeScanCredit(), isTrue);
      expect(AiConfigService.adCredits, equals(2));

      expect(await AiConfigService.consumeScanCredit(), isTrue);
      expect(await AiConfigService.consumeScanCredit(), isTrue);
      expect(AiConfigService.adCredits, equals(0));

      // Fourth consume fails because no credits left
      expect(await AiConfigService.consumeScanCredit(), isFalse);
      expect(AiConfigService.activeMode, equals(AiEngineMode.localFallback));
      expect(AiConfigService.activeModeLabel, contains('Локальний'));
    });

    test('Adding rewarded ad credits increases scan balance', () async {
      await AiConfigService.setApiKey(null);
      final newTotal = await AiConfigService.addRewardedAdCredits(3);
      expect(newTotal, greaterThanOrEqualTo(3));
      expect(AiConfigService.activeMode, equals(AiEngineMode.rewardedAd));
    });

    test('Rejects empty or blank API key in testApiKey', () async {
      final emptyResult = await AiConfigService.testApiKey('');
      expect(emptyResult.isValid, isFalse);
      expect(emptyResult.message, contains('порожній'));

      final spaceResult = await AiConfigService.testApiKey('   ');
      expect(spaceResult.isValid, isFalse);
    });
  });

  group('GeminiVisionService Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await AiConfigService.initialize();
      await AiConfigService.setApiKey(null); // Force local fallback
    });

    test('Gracefully runs local fallback parser when no API key is set', () async {
      final result = await GeminiVisionService.analyzePhotos(
        clothingPhotoUrl: 'https://images.unsplash.com/photo-1591047139829-d91aecb6caea',
        rawLabelText: '''
MASSIMO DUTTI
SIZE EUR 38 / US S
100% PURE WOOL / 100% ВОВНА
MADE IN PORTUGAL
30°C GENTLE WASH
''',
        rawReceiptText: '''
ТОВ "МАССІМО ДУТТІ УКРАЇНА"
ФІСКАЛЬНИЙ ЧЕК
ЖАКЕТ ВОВНЯНИЙ БЕЖ
СУМА: 4 499.00 UAH
''',
      );

      expect(result.isSuccess, isTrue);
      expect(result.usedGemini, isFalse);
      expect(result.data, isNotNull);
      expect(result.data!.brand, equals('Massimo Dutti'));
      expect(result.data!.price, equals(4499.0));
      expect(result.data!.size, contains('EUR 38'));
      expect(result.data!.fabricComposition, contains('100%'));
      expect(result.data!.countryOfOrigin, equals('Made in Portugal'));
    });
  });
}
