import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_wardrobe/services/theme_service.dart';
import 'package:smart_wardrobe/services/localization_service.dart';
import 'package:smart_wardrobe/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemeService Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await ThemeService.initialize();
    });

    test('Default theme mode is system or light and can switch', () async {
      final theme = ThemeService.instance;
      expect(theme.themeMode, ThemeMode.light);

      await theme.setThemeMode(ThemeMode.dark);
      expect(theme.themeMode, ThemeMode.dark);

      await theme.setThemeMode(ThemeMode.system);
      expect(theme.themeMode, ThemeMode.system);
    });

    test('AppTheme defines light and dark themes with consistent luxury branding', () {
      final light = AppTheme.lightTheme;
      final dark = AppTheme.darkTheme;

      expect(light.brightness, Brightness.light);
      expect(dark.brightness, Brightness.dark);
      expect(dark.scaffoldBackgroundColor, AppTheme.darkBackground);
      expect(dark.colorScheme.primary, AppTheme.darkAccent);
    });
  });

  group('LocalizationService Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await LocalizationService.initialize();
    });

    test('Default language is Ukrainian (uk)', () {
      final loc = LocalizationService.instance;
      expect(loc.currentLanguage, AppLanguage.uk);
      expect(loc.currentLocale.languageCode, 'uk');
      expect(loc.translate('tab_wardrobe'), 'Гардероб');
      expect(loc.translate('settings_title'), 'Налаштування та Кабінет');
    });

    test('All 6 languages translate core navigation and settings keys', () async {
      final loc = LocalizationService.instance;

      // English
      await loc.setLanguage(AppLanguage.en);
      expect(loc.translate('tab_wardrobe'), 'Closet');
      expect(loc.translate('tab_stylist'), 'Stylist');
      expect(loc.translate('settings_title'), 'Settings & Account Hub');

      // French
      await loc.setLanguage(AppLanguage.fr);
      expect(loc.translate('tab_wardrobe'), 'Garde-robe');
      expect(loc.translate('tab_stylist'), 'Styliste');
      expect(loc.translate('settings_title'), 'Paramètres & Espace Personnel');

      // Italian
      await loc.setLanguage(AppLanguage.it);
      expect(loc.translate('tab_wardrobe'), 'Guardaroba');
      expect(loc.translate('tab_stylist'), 'Stilista');
      expect(loc.translate('settings_title'), 'Impostazioni & Profilo');

      // Spanish
      await loc.setLanguage(AppLanguage.es);
      expect(loc.translate('tab_wardrobe'), 'Armario');
      expect(loc.translate('tab_stylist'), 'Estilista');
      expect(loc.translate('settings_title'), 'Ajustes y Cuenta');

      // German
      await loc.setLanguage(AppLanguage.de);
      expect(loc.translate('tab_wardrobe'), 'Garderobe');
      expect(loc.translate('tab_stylist'), 'Stylist');
      expect(loc.translate('settings_title'), 'Einstellungen & Profil');

      // Back to Ukrainian
      await loc.setLanguage(AppLanguage.uk);
      expect(loc.translate('tab_wardrobe'), 'Гардероб');
    });

    test('Fallback gracefully when key is missing', () {
      final loc = LocalizationService.instance;
      expect(loc.translate('non_existent_key_123'), 'non_existent_key_123');
    });
  });
}
