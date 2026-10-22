import 'package:flutter/foundation.dart';
import 'pwa_service_stub.dart'
    if (dart.library.js_interop) 'pwa_service_web.dart' as impl;

class PwaService {
  /// Returns true if running on the web
  static bool get isWeb => kIsWeb;

  /// Trigger the browser's PWA installation prompt
  static void triggerInstallPrompt() {
    if (kIsWeb) {
      impl.triggerPwaInstall();
    }
  }

  /// PWA feature list and benefits for UI presentation
  static const List<({String title, String desc, String icon})> pwaFeatures = [
    (
      title: 'Миттєвий запуск без браузера',
      desc: 'Працює як нативний мобільний додаток прямо з головного екрана.',
      icon: '📲',
    ),
    (
      title: '100% Офлайн-доступність',
      desc: 'Service Worker кешує речі, капсули, догляд за тканинами та історію образів.',
      icon: '⚡',
    ),
    (
      title: 'Нуль мегабайтів оновлень',
      desc: 'Завжди актуальна версія з автооновленням у фоновому режимі.',
      icon: '🔄',
    ),
    (
      title: 'Швидкі ярлики (App Shortcuts)',
      desc: 'Запуск AI Стиліста та сканера в 1 дотик з іконки додатку.',
      icon: '✨',
    ),
  ];
}
