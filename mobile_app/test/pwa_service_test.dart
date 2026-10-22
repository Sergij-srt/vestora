import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wardrobe/services/pwa_service.dart';

void main() {
  group('PwaService Unit Tests', () {
    test('PwaService exposes rich feature list for installation banner', () {
      final features = PwaService.pwaFeatures;
      expect(features.length, 4);

      expect(features[0].title, contains('Миттєвий запуск'));
      expect(features[0].icon, '📲');

      expect(features[1].title, contains('Офлайн'));
      expect(features[1].icon, '⚡');

      expect(features[2].title, contains('оновлень'));
      expect(features[3].title, contains('ярлики'));
    });

    test('PwaService triggerInstallPrompt runs safely on non-web without throwing', () {
      expect(() => PwaService.triggerInstallPrompt(), returnsNormally);
    });

    test('PwaService isWeb correctly reflects current runtime platform', () {
      // In flutter_test VM environment, isWeb is false
      expect(PwaService.isWeb, isFalse);
    });
  });
}
