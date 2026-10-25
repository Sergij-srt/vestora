import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage {
  uk('uk', 'Українська', '🇺🇦', 'Офіційна мова'),
  en('en', 'English', '🇬🇧', 'International'),
  fr('fr', 'Français', '🇫🇷', 'Mode & Haute Couture'),
  it('it', 'Italiano', '🇮🇹', 'Moda & Lusso'),
  es('es', 'Español', '🇪🇸', 'Moda & Estilo'),
  de('de', 'Deutsch', '🇩🇪', 'Präzision & Stil');

  final String code;
  final String label;
  final String flag;
  final String subtitle;

  const AppLanguage(this.code, this.label, this.flag, this.subtitle);

  static AppLanguage fromCode(String? code) {
    if (code == null) return AppLanguage.uk;
    return AppLanguage.values.firstWhere(
      (l) => l.code == code.toLowerCase(),
      orElse: () => AppLanguage.uk,
    );
  }
}

class LocalizationService extends ChangeNotifier {
  static final LocalizationService instance = LocalizationService._internal();
  LocalizationService._internal();

  static const String _keyLang = 'vestora_selected_language';
  AppLanguage _currentLanguage = AppLanguage.uk;

  AppLanguage get currentLanguage => _currentLanguage;
  Locale get currentLocale => Locale(_currentLanguage.code);

  /// Read-only access to the translation dictionary for a given language (used for parity audits).
  static Map<String, String> translationsFor(AppLanguage language) =>
      Map.unmodifiable(_translations[language.code] ?? const <String, String>{});

  static Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString(_keyLang);
      instance._currentLanguage = AppLanguage.fromCode(savedCode);
    } catch (_) {
      instance._currentLanguage = AppLanguage.uk;
    }
  }

  Future<void> setLanguage(AppLanguage language) async {
    if (_currentLanguage == language) return;
    _currentLanguage = language;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLang, language.code);
    } catch (_) {}
  }

  String translate(String key) {
    final langMap = _translations[_currentLanguage.code] ?? _translations['uk']!;
    return langMap[key] ?? _translations['en']?[key] ?? _translations['uk']?[key] ?? key;
  }

  /// Returns standard currency symbol for a given 3-letter currency code.
  static String currencySymbol([String? currencyCode]) {
    final currency = (currencyCode ?? 'UAH').toUpperCase().trim();
    return switch (currency) {
      'UAH' || 'ГРН' => '₴',
      'EUR' => '€',
      'USD' => '\$',
      'GBP' => '£',
      'PLN' => 'zł',
      'CHF' => 'CHF',
      _ => currency,
    };
  }

  /// Formats price amount with localized thousands separator and currency symbol placement.
  /// Examples:
  /// - UK/DE/FR/IT: "4 499 ₴", "1 250 €"
  /// - EN: "$4,499", "£1,250", "4,499 ₴"
  static String formatPrice(
    double price, {
    String? currencyCode,
    AppLanguage? language,
  }) {
    final lang = language ?? instance._currentLanguage;
    final symbol = currencySymbol(currencyCode);
    final isWhole = price == price.roundToDouble();

    final formattedNumber = _formatNumberWithSeparators(
      price,
      isWhole: isWhole,
      useComma: lang == AppLanguage.en,
    );

    if (lang == AppLanguage.en && (symbol == '\$' || symbol == '£' || symbol == '€')) {
      return '$symbol$formattedNumber';
    }

    return '$formattedNumber $symbol';
  }

  static String _formatNumberWithSeparators(
    double number, {
    required bool isWhole,
    required bool useComma,
  }) {
    final parts = (isWhole ? number.toInt().toString() : number.toStringAsFixed(2)).split('.');
    final integerPart = parts[0];
    final decimalPart = parts.length > 1 ? parts[1] : null;

    final separator = useComma ? ',' : ' ';
    final buffer = StringBuffer();
    final len = integerPart.length;

    for (int i = 0; i < len; i++) {
      if (i > 0 && (len - i) % 3 == 0) {
        buffer.write(separator);
      }
      buffer.write(integerPart[i]);
    }

    if (decimalPart != null) {
      buffer.write(useComma ? '.' : ',');
      buffer.write(decimalPart);
    }

    return buffer.toString();
  }

  static final Map<String, Map<String, String>> _translations = {
    // 1. Ukrainian (Default)
    'uk': {
      // Bottom Navigation
      'tab_wardrobe': 'Гардероб',
      'tab_stylist': 'Стиліст',
      'tab_add': 'Додати',
      'tab_community': 'Спільнота',
      'tab_analytics': 'Аналітика',

      // Wardrobe / Closet
      'closet_title': 'ЦИФРОВИЙ ГАРДЕРОБ',
      'closet_active_items': 'активних одиниць',
      'closet_streak': 'днів стрік',
      'closet_health': "Здоров'я:",
      'closet_search_hint': 'Пошук за назвою, брендом, кольором...',
      'closet_purchase_banner': 'Плануєте покупку? AI перевірить шафу на дублікати →',
      'closet_all': 'Все',
      'closet_all_seasons': 'Всі сезони',
      'closet_newest': 'Найновіші',
      'closet_items_count': 'з',
      'closet_items_suffix': 'речей',

      // Stylist / Outfit Builder
      'stylist_title': 'AI Стиліст Vestora',
      'stylist_prompt_hint': 'Запитайте ШІ: "Ділова зустріч у дощ"...',
      'stylist_editorial_badge': 'VESTORA EDITORIAL',
      'stylist_moodboard_sub': 'КАПСУЛЬНИЙ КОЛАЖ',
      'stylist_wear_btn': 'Вдягнути образ (+1)',
      'stylist_style_check_btn': 'Style Check',
      'stylist_try_on': 'Приміряти',
      'stylist_poster': 'Постер',
      'stylist_calendar': 'Календар',
      'stylist_bookmark': 'В обрані',
      'stylist_shuffle': 'Згенерувати випадковий образ',
      'stylist_matrix_tool': 'Капсульна матриця 3х3',
      'stylist_editorial_tool': 'Експорт постера (Stories)',

      // Virtual Fitting
      'fitting_title': 'AI Примірочна · Virtual Try-On',
      'fitting_harmony_title': 'AI Дзеркало · Аналіз гармонії',
      'fitting_harmony_score': 'Гармонія образу',
      'fitting_undertone': 'Підтон',
      'fitting_silhouette': 'Посадка',
      'fitting_advice': 'Порада',

      // Settings
      'settings_title': 'Налаштування та Кабінет',
      'settings_account': 'Акаунт та Авторизація',
      'settings_ai_engine': 'Штучний Інтелект & Vision API',
      'settings_cloud_sync': 'Хмарна База Даних (Supabase PostgreSQL)',
      'settings_backup_hub': 'Резервне Копіювання та Перенесення (.vestora)',
      'settings_export_btn': 'Експорт у файл',
      'settings_import_btn': 'Імпорт бекапу',
      'settings_personalization': 'Персоналізація та Стиль',
      'settings_notifications': 'Сповіщення та Розсилки',
      'settings_notifications_sub': 'Ранковий AI-стиліст, нагадування про стрік та догляд',
      'settings_appearance': 'Зовнішній вигляд (Тема)',
      'settings_theme_light': 'Світла',
      'settings_theme_dark': 'Темна',
      'settings_theme_system': 'Системна',
      'settings_language': 'Мова інтерфейсу',
      'settings_security': 'Безпека та Пароль',
      'settings_legal_section': 'Конфіденційність, Ліцензії та Управління Даними',
      'settings_privacy_policy': 'Політика конфіденційності та GDPR',
      'settings_privacy_sub': 'Локальне зберігання Local-First · Контроль хмарних даних',
      'settings_licenses': 'Ліцензії відкритого ПЗ (Open Source)',
      'settings_licenses_sub': 'Перелік пакетів Flutter, Dart та сторонніх бібліотек',
      'settings_delete_account': 'Видалити акаунт та всі дані',
      'settings_delete_account_sub': 'Незворотне очищення профілю, гардероба та хмарної бази',
      'settings_delete_confirm_title': 'Остаточне видалення акаунта',
      'settings_delete_confirm_body':
          'Ця дія назавжди видалить ваш обліковий запис, усі речі гардероба, заплановані образи, API-ключі та синхронізовані дані у хмарі Supabase. Відновити дані буде неможливо.',
      'settings_delete_cancel': 'Скасувати',
      'settings_delete_confirm_btn': 'Видалити назавжди',
      'settings_delete_success': 'Акаунт та всі персональні дані остаточно видалено.',
      'settings_logout': 'Вийти з акаунту',
      'settings_edit_profile': 'Редагувати',
      'settings_change_pwd': 'Пароль',
      'settings_logout_confirm': 'Ви впевнені, що бажаєте вийти з акаунту?',
      'settings_stay': 'Залишитися',
      'settings_logout_action': 'Вийти',
      'settings_logout_note': 'Для подальшого доступу потрібно буде увійти через Google або ввести Email та пароль.',
      'settings_privacy_body':
          '• Local-First архітектура: речі гардероба, капсули та налаштування зберігаються локально на вашому пристрої.\n\n'
          '• Хмарна ізоляція (Supabase RLS): при добровільному підключенні хмари ваші фото та таблиці захищені політиками Row Level Security (auth.uid()).\n\n'
          '• Захист секретів: паролі хешуються алгоритмом HMAC-SHA256 (12 000 раундів із сіллю), а ключі Gemini API передаються через захищений заголовок x-goog-api-key.\n\n'
          '• Право на забуття (GDPR / App Store / Google Play): ви можете експортувати всі дані у форматі .vestora або миттєво видалити акаунт і всі дані в 1 клік.',
      'settings_edit_profile_title': 'Редагування профілю',
      'settings_field_name': 'ІМ\'Я',
      'settings_field_location': 'ЛОКАЦІЯ',
      'settings_profile_saved': 'Профіль успішно оновлено!',
      'settings_change_pwd_title': 'Зміна паролю',
      'settings_pwd_current': 'ПОТОЧНИЙ ПАРОЛЬ',
      'settings_pwd_new': 'НОВИЙ ПАРОЛЬ (мін. 6 символів)',
      'settings_pwd_confirm': 'ПІДТВЕРДЖЕННЯ НОВОГО ПАРОЛЮ',
      'settings_pwd_update_btn': 'Оновити пароль',
      'settings_style_label': 'ОСНОВНИЙ СТИЛЬ ГАРДЕРОБУ',
      'settings_currency_label': 'ВАЛЮТА ВИТРАТ ТА ОКУПНОСТІ (CPW)',
      'settings_size_label': 'СИСТЕМА РОЗМІРІВ',
      'settings_apply_btn': 'Застосувати налаштування',
      'settings_notif_morning': 'Ранковий лук о 08:00',
      'settings_notif_morning_sub': 'Готова капсула під погоду за вікном кожного ранку',
      'settings_notif_streak': 'Нагадування стріку о 20:00',
      'settings_notif_streak_sub': 'Не дайте згоріти вашому прогресу носіння гардероба',
      'settings_notif_eco': 'Тижневий еко-звіт та CPW',
      'settings_notif_eco_sub': 'Підсумок вартості виходів та рекомендації щодо розхламлення',
      'settings_notif_saved': 'Параметри сповіщень збережено!',
      'settings_pwa_section': 'ДОДАТОК ТА ОФЛАЙН-РЕЖИМ (PWA)',
      'settings_pwa_install': 'Встановити як додаток (PWA)',
      'settings_pwa_install_sub': 'Миттєвий запуск з робочого столу смартфона чи ПК',
      'settings_pwa_offline': 'Офлайн-доступ та Service Worker',
      'settings_pwa_offline_sub': 'Гардероб, комбінації та кольоротип працюють без інтернету',
      'settings_offline_body':
          'У Vestora налаштовано Service Worker із захищеним App Shell:\n\n'
          '✅ Весь гардероб і фото речей зберігаються локально на пристрої.\n'
          '✅ Капсульна матриця 3х3 та поєднання кольорів працюють без зв\'язку.\n'
          '✅ Енциклопедія догляду за тканинами та бірки доступні в авіарежимі.',
      'settings_sync_now': 'Синхронізувати зараз (Хмара ⇄ Локально)',
      'settings_sync_now_sub': 'Реплікація гардероба, профілю, календаря та логів носіння з PostgreSQL',
      'settings_sql_schema': 'SQL-схема для Supabase Dashboard',
      'settings_sql_schema_sub': 'Готовий DDL-скрипт з RLS-політиками та ізоляцією папок S3',
      'settings_reset_cache': 'Скинути фільтри та оновити кеш',
      'settings_reset_cache_sub': 'Очистити збережені тимчасові файли та завантажити демо-капсулу',

      // Common
      'common_cancel': 'Скасувати',
      'common_save': 'Зберегти',
      'common_close': 'Закрити',

      // Auth
      'auth_login_tab': 'Вхід у кабінет',
      'auth_register_tab': 'Реєстрація',
      'auth_google_btn': 'Продовжити через Google',
      'auth_email_label': 'ЕЛЕКТРОННА ПОШТА (EMAIL)',
      'auth_password_label': 'ПАРОЛЬ',
      'auth_forgot_pwd': 'Забули пароль?',
      'auth_signin_btn': 'Увійти з Email та паролем',
      'auth_signup_btn': 'Створити акаунт',
      'auth_guest_btn': 'Продовжити як гість (Демо-режим)',
      'auth_encryption': '256-бітне шифрування даних · Vestora Security',

      // Tools
      'tool_fabric_care': 'Гід по догляду за тканинами',
      'tool_travel_capsule': 'Капсула у подорож',
      'tool_declutter': 'Розхламлення & Еко-Хаб',
      'tool_color_analysis': 'Мій кольоротип',
      'tool_purchase_advisor': 'Радник покупок',
    },

    // 2. English
    'en': {
      'tab_wardrobe': 'Closet',
      'tab_stylist': 'Stylist',
      'tab_add': 'Add',
      'tab_community': 'Community',
      'tab_analytics': 'Analytics',

      'closet_title': 'DIGITAL CLOSET',
      'closet_active_items': 'active pieces',
      'closet_streak': 'day streak',
      'closet_health': 'Health:',
      'closet_search_hint': 'Search by name, brand, color...',
      'closet_purchase_banner': 'Planning a purchase? AI checks your closet for duplicates →',
      'closet_all': 'All',
      'closet_all_seasons': 'All Seasons',
      'closet_newest': 'Newest',
      'closet_items_count': 'of',
      'closet_items_suffix': 'items',

      'stylist_title': 'AI Stylist Vestora',
      'stylist_prompt_hint': 'Ask AI: "Business meeting on a rainy day"...',
      'stylist_editorial_badge': 'VESTORA EDITORIAL',
      'stylist_moodboard_sub': 'CAPSULE COLLAGE',
      'stylist_wear_btn': 'Wear Outfit (+1)',
      'stylist_style_check_btn': 'Style Check',
      'stylist_try_on': 'Try-On',
      'stylist_poster': 'Poster',
      'stylist_calendar': 'Calendar',
      'stylist_bookmark': 'Favorite',
      'stylist_shuffle': 'Generate Random Outfit',
      'stylist_matrix_tool': '3x3 Capsule Matrix',
      'stylist_editorial_tool': 'Export Story Poster',

      'fitting_title': 'AI Virtual Try-On Mirror',
      'fitting_harmony_title': 'AI Mirror · Harmony Analysis',
      'fitting_harmony_score': 'Outfit Harmony',
      'fitting_undertone': 'Undertone',
      'fitting_silhouette': 'Fit & Cut',
      'fitting_advice': 'Stylist Tip',

      'settings_title': 'Settings & Account Hub',
      'settings_account': 'Account & Authentication',
      'settings_ai_engine': 'AI Engine & Vision API',
      'settings_cloud_sync': 'Cloud Database (Supabase PostgreSQL)',
      'settings_backup_hub': 'Backup & Data Portability (.vestora)',
      'settings_export_btn': 'Export File',
      'settings_import_btn': 'Import Backup',
      'settings_personalization': 'Personalization & Style',
      'settings_notifications': 'Notifications & Digests',
      'settings_notifications_sub': 'Morning AI stylist, streak reminders & garment care',
      'settings_appearance': 'Appearance (Theme)',
      'settings_theme_light': 'Light',
      'settings_theme_dark': 'Dark',
      'settings_theme_system': 'System',
      'settings_language': 'Interface Language',
      'settings_security': 'Security & Password',
      'settings_legal_section': 'Privacy, Licenses & Data Control',
      'settings_privacy_policy': 'Privacy Policy & GDPR',
      'settings_privacy_sub': 'Local-First architecture · Full cloud data ownership',
      'settings_licenses': 'Open-Source Software Licenses',
      'settings_licenses_sub': 'Attributions for Flutter, Dart & third-party packages',
      'settings_delete_account': 'Delete Account & All Data',
      'settings_delete_account_sub': 'Permanently erase profile, wardrobe & cloud records',
      'settings_delete_confirm_title': 'Permanent Account Deletion',
      'settings_delete_confirm_body':
          'This will permanently delete your account, all wardrobe items, planned outfits, API keys, and synced Supabase cloud records. This action cannot be undone.',
      'settings_delete_cancel': 'Cancel',
      'settings_delete_confirm_btn': 'Delete Permanently',
      'settings_delete_success': 'Your account and all personal data have been permanently deleted.',
      'settings_logout': 'Sign Out',
      'settings_edit_profile': 'Edit',
      'settings_change_pwd': 'Password',
      'settings_logout_confirm': 'Are you sure you want to sign out?',
      'settings_stay': 'Stay',
      'settings_logout_action': 'Sign Out',
      'settings_logout_note': 'To sign back in, use Google Sign-In or enter your Email and password.',
      'settings_privacy_body':
          '• Local-First Architecture: wardrobe items, capsules, and preferences stay locally on your device by default.\n\n'
          '• Cloud Isolation (Supabase RLS): when optional cloud sync is enabled, photos and tables are isolated by Row Level Security (auth.uid()).\n\n'
          '• Secret Protection: passwords use salted 12,000-round HMAC-SHA256, and Gemini API keys are sent via the x-goog-api-key header rather than URL query parameters.\n\n'
          '• Right to Erasure (GDPR / App Store / Google Play): export all data as .vestora or permanently delete your account and cloud data in 1 click.',
      'settings_edit_profile_title': 'Edit Profile',
      'settings_field_name': 'NAME',
      'settings_field_location': 'LOCATION',
      'settings_profile_saved': 'Profile updated successfully!',
      'settings_change_pwd_title': 'Change Password',
      'settings_pwd_current': 'CURRENT PASSWORD',
      'settings_pwd_new': 'NEW PASSWORD (min. 6 chars)',
      'settings_pwd_confirm': 'CONFIRM NEW PASSWORD',
      'settings_pwd_update_btn': 'Update Password',
      'settings_style_label': 'PRIMARY WARDROBE STYLE',
      'settings_currency_label': 'COST PER WEAR CURRENCY (CPW)',
      'settings_size_label': 'SIZE SYSTEM',
      'settings_apply_btn': 'Apply Preferences',
      'settings_notif_morning': 'Morning Look at 08:00',
      'settings_notif_morning_sub': 'Weather-ready daily capsule every morning',
      'settings_notif_streak': 'Streak Reminder at 20:00',
      'settings_notif_streak_sub': 'Keep your daily wardrobe styling streak alive',
      'settings_notif_eco': 'Weekly Eco & CPW Digest',
      'settings_notif_eco_sub': 'Cost-per-wear insights and smart declutter tips',
      'settings_notif_saved': 'Notification preferences saved!',
      'settings_pwa_section': 'INSTALL & OFFLINE MODE (PWA)',
      'settings_pwa_install': 'Install App (PWA)',
      'settings_pwa_install_sub': 'Instant home-screen launch on phone or desktop',
      'settings_pwa_offline': 'Offline Access & Service Worker',
      'settings_pwa_offline_sub': 'Closet, outfits, and color palettes work offline',
      'settings_offline_body':
          'Vestora uses a protected App Shell Service Worker:\n\n'
          '✅ Your entire wardrobe and item photos are stored locally on your device.\n'
          '✅ 3x3 Capsule Matrix and seasonal color palettes work offline.\n'
          '✅ Fabric care symbols and stain guides remain available in airplane mode.',
      'settings_sync_now': 'Sync Now (Cloud ⇄ Local)',
      'settings_sync_now_sub': 'Replicate closet, profile, calendar, and wear logs with PostgreSQL',
      'settings_sql_schema': 'SQL Schema for Supabase Dashboard',
      'settings_sql_schema_sub': 'Ready-to-run DDL script with RLS policies and S3 folder isolation',
      'settings_reset_cache': 'Reset Filters & Refresh Cache',
      'settings_reset_cache_sub': 'Clear temporary state and reload demo capsule',

      'common_cancel': 'Cancel',
      'common_save': 'Save',
      'common_close': 'Close',

      'auth_login_tab': 'Sign In',
      'auth_register_tab': 'Register',
      'auth_google_btn': 'Continue with Google',
      'auth_email_label': 'EMAIL ADDRESS',
      'auth_password_label': 'PASSWORD',
      'auth_forgot_pwd': 'Forgot password?',
      'auth_signin_btn': 'Sign In with Email',
      'auth_signup_btn': 'Create Account',
      'auth_guest_btn': 'Continue as Guest (Demo)',
      'auth_encryption': '256-bit Bank-Grade Encryption · Vestora Security',

      'tool_fabric_care': 'Fabric Care Guide',
      'tool_travel_capsule': 'Travel Capsule Generator',
      'tool_declutter': 'Declutter & Eco Hub',
      'tool_color_analysis': 'Seasonal Color Analysis',
      'tool_purchase_advisor': 'Smart Purchase Advisor',
    },

    // 3. French (Mode & Haute Couture)
    'fr': {
      'tab_wardrobe': 'Garde-robe',
      'tab_stylist': 'Styliste',
      'tab_add': 'Ajouter',
      'tab_community': 'Communauté',
      'tab_analytics': 'Analyses',

      'closet_title': 'VESTIAIRE DIGITAL',
      'closet_active_items': 'pièces actives',
      'closet_streak': 'jours consécutifs',
      'closet_health': 'Santé:',
      'closet_search_hint': 'Recherche par nom, marque, couleur...',
      'closet_purchase_banner': 'Envie d\'acheter? L\'IA vérifie les doublons dans votre dressing →',
      'closet_all': 'Tout',
      'closet_all_seasons': 'Toutes saisons',
      'closet_newest': 'Plus récents',
      'closet_items_count': 'sur',
      'closet_items_suffix': 'pièces',

      'stylist_title': 'Styliste IA Vestora',
      'stylist_prompt_hint': 'Demandez à l\'IA: "Rendez-vous sous la pluie"...',
      'stylist_editorial_badge': 'VESTORA ÉDITORIAL',
      'stylist_moodboard_sub': 'COLLAGE CAPSULE',
      'stylist_wear_btn': 'Porter cette tenue (+1)',
      'stylist_style_check_btn': 'Style Check',
      'stylist_try_on': 'Essayer',
      'stylist_poster': 'Affiche',
      'stylist_calendar': 'Calendrier',
      'stylist_bookmark': 'Favoris',
      'stylist_shuffle': 'Générer une tenue aléatoire',
      'stylist_matrix_tool': 'Matrice Capsule 3x3',
      'stylist_editorial_tool': 'Exporter en Story Vogue',

      'fitting_title': 'Cabine d\'Essayage Virtuelle IA',
      'fitting_harmony_title': 'Miroir IA · Analyse d\'harmonie',
      'fitting_harmony_score': 'Harmonie de tenue',
      'fitting_undertone': 'Sous-ton',
      'fitting_silhouette': 'Coupe & Silhouette',
      'fitting_advice': 'Conseil Styliste',

      'settings_title': 'Paramètres & Espace Personnel',
      'settings_account': 'Compte & Connexion',
      'settings_ai_engine': 'Moteur IA & Vision API',
      'settings_cloud_sync': 'Base Cloud (Supabase PostgreSQL)',
      'settings_backup_hub': 'Sauvegarde & Portabilité (.vestora)',
      'settings_export_btn': 'Exporter fichier',
      'settings_import_btn': 'Importer sauvegarde',
      'settings_personalization': 'Personnalisation & Style',
      'settings_notifications': 'Notifications & Alertes',
      'settings_notifications_sub': 'Styliste IA du matin, série quotidienne & soin textile',
      'settings_appearance': 'Apparence (Thème)',
      'settings_theme_light': 'Clair',
      'settings_theme_dark': 'Sombre',
      'settings_theme_system': 'Système',
      'settings_language': 'Langue de l\'interface',
      'settings_security': 'Sécurité & Mot de passe',
      'settings_legal_section': 'Confidentialité, Licences & Données',
      'settings_privacy_policy': 'Politique de confidentialité & RGPD',
      'settings_privacy_sub': 'Architecture Local-First · Contrôle total des données',
      'settings_licenses': 'Licences Open Source',
      'settings_licenses_sub': 'Bibliothèques Flutter, Dart et composants tiers',
      'settings_delete_account': 'Supprimer le compte et les données',
      'settings_delete_account_sub': 'Suppression définitive du profil, dressing et cloud',
      'settings_delete_confirm_title': 'Suppression définitive du compte',
      'settings_delete_confirm_body':
          'Cette action supprimera définitivement votre compte, vos vêtements, vos tenues planifiées, vos clés API et vos données cloud Supabase. Action irréversible.',
      'settings_delete_cancel': 'Annuler',
      'settings_delete_confirm_btn': 'Supprimer définitivement',
      'settings_delete_success': 'Votre compte et toutes vos données ont été supprimés.',
      'settings_logout': 'Se déconnecter',
      'settings_edit_profile': 'Modifier',
      'settings_change_pwd': 'Mot de passe',
      'settings_logout_confirm': 'Êtes-vous sûr de vouloir vous déconnecter?',
      'settings_stay': 'Rester',
      'settings_logout_action': 'Déconnexion',
      'settings_logout_note': 'Pour vous reconnecter, utilisez Google ou votre e-mail et mot de passe.',
      'settings_privacy_body':
          '• Architecture Local-First : vos vêtements, capsules et préférences restent stockés localement sur votre appareil.\n\n'
          '• Isolation Cloud (Supabase RLS) : vos photos et tables sont protégées par Row Level Security (auth.uid()).\n\n'
          '• Protection des secrets : hachage HMAC-SHA256 salé (12 000 tours) et clés Gemini transmises via l\'en-tête x-goog-api-key.\n\n'
          '• Droit à l\'oubli (RGPD / App Store / Google Play) : exportez vos données (.vestora) ou supprimez votre compte en 1 clic.',
      'settings_edit_profile_title': 'Modifier le profil',
      'settings_field_name': 'NOM',
      'settings_field_location': 'LOCALISATION',
      'settings_profile_saved': 'Profil mis à jour avec succès !',
      'settings_change_pwd_title': 'Changer le mot de passe',
      'settings_pwd_current': 'MOT DE PASSE ACTUEL',
      'settings_pwd_new': 'NOUVEAU MOT DE PASSE (min. 6 caract.)',
      'settings_pwd_confirm': 'CONFIRMER LE MOT DE PASSE',
      'settings_pwd_update_btn': 'Mettre à jour',
      'settings_style_label': 'STYLE PRINCIPAL DU DRESSING',
      'settings_currency_label': 'DEVISE COÛT PAR PORT (CPW)',
      'settings_size_label': 'SYSTÈME DE TAILLES',
      'settings_apply_btn': 'Appliquer les préférences',
      'settings_notif_morning': 'Look du matin à 08:00',
      'settings_notif_morning_sub': 'Capsule quotidienne adaptée à la météo chaque matin',
      'settings_notif_streak': 'Rappel de série à 20:00',
      'settings_notif_streak_sub': 'Maintenez votre série quotidienne de style',
      'settings_notif_eco': 'Bilan Éco & CPW hebdomadaire',
      'settings_notif_eco_sub': 'Analyse du coût par port et conseils de tri',
      'settings_notif_saved': 'Préférences de notification enregistrées !',
      'settings_pwa_section': 'APPLICATION & MODE HORS-LIGNE (PWA)',
      'settings_pwa_install': 'Installer l\'application (PWA)',
      'settings_pwa_install_sub': 'Accès instantané depuis l\'écran d\'accueil',
      'settings_pwa_offline': 'Accès Hors-ligne & Service Worker',
      'settings_pwa_offline_sub': 'Dressing, tenues et colorimétrie disponibles sans réseau',
      'settings_offline_body':
          'Vestora intègre un Service Worker avec App Shell protégé :\n\n'
          '✅ Votre garde-robe et vos photos sont conservées localement.\n'
          '✅ La matrice capsule 3x3 et la colorimétrie fonctionnent hors-ligne.\n'
          '✅ Le guide d\'entretien des textiles reste accessible en mode avion.',
      'settings_sync_now': 'Synchroniser maintenant (Cloud ⇄ Local)',
      'settings_sync_now_sub': 'Réplication du dressing, profil, calendrier et ports avec PostgreSQL',
      'settings_sql_schema': 'Schéma SQL pour Supabase Dashboard',
      'settings_sql_schema_sub': 'Script DDL prêt à l\'emploi avec politiques RLS et isolation S3',
      'settings_reset_cache': 'Réinitialiser les filtres et le cache',
      'settings_reset_cache_sub': 'Nettoyer les fichiers temporaires et recharger la capsule démo',

      'common_cancel': 'Annuler',
      'common_save': 'Enregistrer',
      'common_close': 'Fermer',

      'auth_login_tab': 'Connexion',
      'auth_register_tab': 'Inscription',
      'auth_google_btn': 'Continuer avec Google',
      'auth_email_label': 'ADRESSE E-MAIL',
      'auth_password_label': 'MOT DE PASSE',
      'auth_forgot_pwd': 'Mot de passe oublié?',
      'auth_signin_btn': 'Se connecter par Email',
      'auth_signup_btn': 'Créer un compte',
      'auth_guest_btn': 'Continuer en mode Invité (Démo)',
      'auth_encryption': 'Chiffrement 256 bits certifié · Vestora Security',

      'tool_fabric_care': 'Guide d\'Entretien des Textiles',
      'tool_travel_capsule': 'Générateur Valise Capsule',
      'tool_declutter': 'Désencombrement & Éco-Hub',
      'tool_color_analysis': 'Colorimétrie Saisonnière',
      'tool_purchase_advisor': 'Conseiller Shopping Intelligent',
    },

    // 4. Italian (Moda & Lusso)
    'it': {
      'tab_wardrobe': 'Guardaroba',
      'tab_stylist': 'Stilista',
      'tab_add': 'Aggiungi',
      'tab_community': 'Community',
      'tab_analytics': 'Analitica',

      'closet_title': 'GUARDAROBA DIGITALE',
      'closet_active_items': 'capi attivi',
      'closet_streak': 'giorni di serie',
      'closet_health': 'Salute:',
      'closet_search_hint': 'Cerca per nome, marca, colore...',
      'closet_purchase_banner': 'Pianifichi un acquisto? L\'AI controlla duplicati nel tuo armadio →',
      'closet_all': 'Tutti',
      'closet_all_seasons': 'Tutte le stagioni',
      'closet_newest': 'I più recenti',
      'closet_items_count': 'su',
      'closet_items_suffix': 'capi',

      'stylist_title': 'AI Stilista Vestora',
      'stylist_prompt_hint': 'Chiedi all\'AI: "Riunione di lavoro sotto la pioggia"...',
      'stylist_editorial_badge': 'VESTORA EDITORIALE',
      'stylist_moodboard_sub': 'COLLAGE CAPSULA',
      'stylist_wear_btn': 'Indossa questo outfit (+1)',
      'stylist_style_check_btn': 'Style Check',
      'stylist_try_on': 'Prova',
      'stylist_poster': 'Poster',
      'stylist_calendar': 'Calendario',
      'stylist_bookmark': 'Preferiti',
      'stylist_shuffle': 'Genera outfit casuale',
      'stylist_matrix_tool': 'Matrice Capsula 3x3',
      'stylist_editorial_tool': 'Esporta Poster Story',

      'fitting_title': 'Camerino Virtuale con AI',
      'fitting_harmony_title': 'Specchio AI · Analisi Armonia',
      'fitting_harmony_score': 'Armonia Outfit',
      'fitting_undertone': 'Sottotono',
      'fitting_silhouette': 'Vestibilità & Taglio',
      'fitting_advice': 'Consiglio dello Stilista',

      'settings_title': 'Impostazioni & Profilo',
      'settings_account': 'Account & Autenticazione',
      'settings_ai_engine': 'Motore AI & Vision API',
      'settings_cloud_sync': 'Database Cloud (Supabase PostgreSQL)',
      'settings_backup_hub': 'Backup & Portabilità Dati (.vestora)',
      'settings_export_btn': 'Esporta file',
      'settings_import_btn': 'Importa backup',
      'settings_personalization': 'Personalizzazione & Stile',
      'settings_notifications': 'Notifiche & Avvisi',
      'settings_notifications_sub': 'Stilista AI mattutino, serie giornaliera & cura capi',
      'settings_appearance': 'Aspetto (Tema)',
      'settings_theme_light': 'Chiaro',
      'settings_theme_dark': 'Scuro',
      'settings_theme_system': 'Sistema',
      'settings_language': 'Lingua dell\'interfaccia',
      'settings_security': 'Sicurezza & Password',
      'settings_legal_section': 'Privacy, Licenze & Controllo Dati',
      'settings_privacy_policy': 'Informativa Privacy & GDPR',
      'settings_privacy_sub': 'Architettura Local-First · Pieno controllo dei dati',
      'settings_licenses': 'Licenze Software Open Source',
      'settings_licenses_sub': 'Librerie Flutter, Dart e pacchetti di terze parti',
      'settings_delete_account': 'Elimina account e tutti i dati',
      'settings_delete_account_sub': 'Cancellazione definitiva di profilo, guardaroba e cloud',
      'settings_delete_confirm_title': 'Eliminazione definitiva dell\'account',
      'settings_delete_confirm_body':
          'Questa azione eliminerà definitivamente il tuo account, tutti i capi, gli outfit pianificati, le chiavi API e i dati cloud Supabase. L\'operazione è irreversibile.',
      'settings_delete_cancel': 'Annulla',
      'settings_delete_confirm_btn': 'Elimina definitivamente',
      'settings_delete_success': 'Il tuo account e tutti i dati personali sono stati eliminati.',
      'settings_logout': 'Esci dall\'account',
      'settings_edit_profile': 'Modifica',
      'settings_change_pwd': 'Password',
      'settings_logout_confirm': 'Sei sicuro di voler uscire dal tuo account?',
      'settings_stay': 'Rimani',
      'settings_logout_action': 'Esci',
      'settings_logout_note': 'Per accedere di nuovo, usa Google o inserisci Email e password.',
      'settings_privacy_body':
          '• Architettura Local-First: capi, capsule e preferenze restano salvati localmente sul tuo dispositivo.\n\n'
          '• Isolamento Cloud (Supabase RLS): foto e tabelle sono protette da Row Level Security (auth.uid()).\n\n'
          '• Protezione dei segreti: password con hash HMAC-SHA256 salato (12.000 iterazioni) e chiavi Gemini nell\'header x-goog-api-key.\n\n'
          '• Diritto all\'oblio (GDPR / App Store / Google Play): esporta tutti i dati (.vestora) o elimina account e cloud in 1 clic.',
      'settings_edit_profile_title': 'Modifica profilo',
      'settings_field_name': 'NOME',
      'settings_field_location': 'POSIZIONE',
      'settings_profile_saved': 'Profilo aggiornato con successo!',
      'settings_change_pwd_title': 'Cambia password',
      'settings_pwd_current': 'PASSWORD ATTUALE',
      'settings_pwd_new': 'NUOVA PASSWORD (min. 6 caratteri)',
      'settings_pwd_confirm': 'CONFERMA NUOVA PASSWORD',
      'settings_pwd_update_btn': 'Aggiorna password',
      'settings_style_label': 'STILE PRINCIPALE DEL GUARDAROBA',
      'settings_currency_label': 'VALUTA COSTO PER UTILIZZO (CPW)',
      'settings_size_label': 'SISTEMA DI TAGLIE',
      'settings_apply_btn': 'Applica impostazioni',
      'settings_notif_morning': 'Look del mattino alle 08:00',
      'settings_notif_morning_sub': 'Capsula quotidiana basata sul meteo ogni mattina',
      'settings_notif_streak': 'Promemoria serie alle 20:00',
      'settings_notif_streak_sub': 'Mantieni attiva la tua serie giornaliera di stile',
      'settings_notif_eco': 'Report settimanale Eco & CPW',
      'settings_notif_eco_sub': 'Riepilogo costo per utilizzo e consigli decluttering',
      'settings_notif_saved': 'Impostazioni notifiche salvate!',
      'settings_pwa_section': 'APP E MODALITÀ OFFLINE (PWA)',
      'settings_pwa_install': 'Installa come App (PWA)',
      'settings_pwa_install_sub': 'Avvio rapido dalla schermata Home su smartphone o PC',
      'settings_pwa_offline': 'Accesso Offline & Service Worker',
      'settings_pwa_offline_sub': 'Guardaroba, abbinamenti e armocromia funzionano senza rete',
      'settings_offline_body':
          'Vestora utilizza un Service Worker con App Shell protetto:\n\n'
          '✅ Tutto il guardaroba e le foto sono salvati localmente sul dispositivo.\n'
          '✅ Matrice capsula 3x3 e palette colori funzionano offline.\n'
          '✅ La guida alla cura dei tessuti è disponibile in modalità aereo.',
      'settings_sync_now': 'Sincronizza ora (Cloud ⇄ Locale)',
      'settings_sync_now_sub': 'Replica guardaroba, profilo, calendario e utilizzi con PostgreSQL',
      'settings_sql_schema': 'Schema SQL per Supabase Dashboard',
      'settings_sql_schema_sub': 'Script DDL pronto con policy RLS e isolamento cartelle S3',
      'settings_reset_cache': 'Ripristina filtri e aggiorna cache',
      'settings_reset_cache_sub': 'Pulisci i dati temporanei e ricarica la capsula demo',

      'common_cancel': 'Annulla',
      'common_save': 'Salva',
      'common_close': 'Chiudi',

      'auth_login_tab': 'Accedi',
      'auth_register_tab': 'Registrati',
      'auth_google_btn': 'Continua con Google',
      'auth_email_label': 'INDIRIZZO EMAIL',
      'auth_password_label': 'PASSWORD',
      'auth_forgot_pwd': 'Password dimenticata?',
      'auth_signin_btn': 'Accedi con Email',
      'auth_signup_btn': 'Crea Account',
      'auth_guest_btn': 'Continua come Ospite (Demo)',
      'auth_encryption': 'Crittografia a 256 bit · Vestora Security',

      'tool_fabric_care': 'Guida Cura dei Tessuti',
      'tool_travel_capsule': 'Generatore Valigia Capsula',
      'tool_declutter': 'Decluttering & Eco-Hub',
      'tool_color_analysis': 'Armocromia Stagionale',
      'tool_purchase_advisor': 'Consulente Acquisti Smart',
    },

    // 5. Spanish (Moda & Estilo)
    'es': {
      'tab_wardrobe': 'Armario',
      'tab_stylist': 'Estilista',
      'tab_add': 'Añadir',
      'tab_community': 'Comunidad',
      'tab_analytics': 'Estadísticas',

      'closet_title': 'ARMARIO DIGITAL',
      'closet_active_items': 'prendas activas',
      'closet_streak': 'días de racha',
      'closet_health': 'Salud:',
      'closet_search_hint': 'Buscar por nombre, marca, color...',
      'closet_purchase_banner': '¿Planeas comprar? La IA revisa duplicados en tu armario →',
      'closet_all': 'Todo',
      'closet_all_seasons': 'Todas las estaciones',
      'closet_newest': 'Más recientes',
      'closet_items_count': 'de',
      'closet_items_suffix': 'prendas',

      'stylist_title': 'Estilista IA Vestora',
      'stylist_prompt_hint': 'Pregunta a la IA: "Reunión de negocios con lluvia"...',
      'stylist_editorial_badge': 'VESTORA EDITORIAL',
      'stylist_moodboard_sub': 'COLLAGE CÁPSULA',
      'stylist_wear_btn': 'Llevar este look (+1)',
      'stylist_style_check_btn': 'Style Check',
      'stylist_try_on': 'Probar',
      'stylist_poster': 'Póster',
      'stylist_calendar': 'Calendario',
      'stylist_bookmark': 'Favorito',
      'stylist_shuffle': 'Generar look aleatorio',
      'stylist_matrix_tool': 'Matriz Cápsula 3x3',
      'stylist_editorial_tool': 'Exportar Story de Revista',

      'fitting_title': 'Probador Virtual con IA',
      'fitting_harmony_title': 'Espejo IA · Análisis de Armonía',
      'fitting_harmony_score': 'Armonía del Look',
      'fitting_undertone': 'Subtono',
      'fitting_silhouette': 'Corte & Ajuste',
      'fitting_advice': 'Consejo del Estilista',

      'settings_title': 'Ajustes y Cuenta',
      'settings_account': 'Cuenta y Autenticación',
      'settings_ai_engine': 'Motor de IA & Vision API',
      'settings_cloud_sync': 'Base en la Nube (Supabase PostgreSQL)',
      'settings_backup_hub': 'Copia de Seguridad y Portabilidad (.vestora)',
      'settings_export_btn': 'Exportar archivo',
      'settings_import_btn': 'Importar copia',
      'settings_personalization': 'Personalización y Estilo',
      'settings_notifications': 'Notificaciones y Boletines',
      'settings_notifications_sub': 'Estilista IA matutino, rachas y cuidado textil',
      'settings_appearance': 'Apariencia (Tema)',
      'settings_theme_light': 'Claro',
      'settings_theme_dark': 'Oscuro',
      'settings_theme_system': 'Sistema',
      'settings_language': 'Idioma de la interfaz',
      'settings_security': 'Seguridad y Contraseña',
      'settings_legal_section': 'Privacidad, Licencias y Control de Datos',
      'settings_privacy_policy': 'Política de Privacidad y RGPD',
      'settings_privacy_sub': 'Arquitectura Local-First · Control total de tus datos',
      'settings_licenses': 'Licencias de Código Abierto',
      'settings_licenses_sub': 'Paquetes de Flutter, Dart y bibliotecas de terceros',
      'settings_delete_account': 'Eliminar cuenta y todos los datos',
      'settings_delete_account_sub': 'Borrado permanente de perfil, armario y nube',
      'settings_delete_confirm_title': 'Eliminación permanente de la cuenta',
      'settings_delete_confirm_body':
          'Esta acción eliminará permanentemente tu cuenta, prendas, conjuntos planificados, claves API y datos en la nube Supabase. Esta operación no se puede deshacer.',
      'settings_delete_cancel': 'Cancelar',
      'settings_delete_confirm_btn': 'Eliminar permanentemente',
      'settings_delete_success': 'Tu cuenta y todos tus datos personales han sido eliminados.',
      'settings_logout': 'Cerrar sesión',
      'settings_edit_profile': 'Editar',
      'settings_change_pwd': 'Contraseña',
      'settings_logout_confirm': '¿Seguro que deseas cerrar sesión?',
      'settings_stay': 'Permanecer',
      'settings_logout_action': 'Salir',
      'settings_logout_note': 'Para volver a entrar, inicia sesión con Google o con tu Email y contraseña.',
      'settings_privacy_body':
          '• Arquitectura Local-First: tus prendas, cápsulas y ajustes se guardan localmente en tu dispositivo.\n\n'
          '• Aislamiento en la Nube (Supabase RLS): tus fotos y tablas están protegidas con Row Level Security (auth.uid()).\n\n'
          '• Protección de secretos: contraseñas con HMAC-SHA256 con sal (12.000 rondas) y claves Gemini en la cabecera x-goog-api-key.\n\n'
          '• Derecho al olvido (RGPD / App Store / Google Play): exporta tus datos (.vestora) o elimina tu cuenta y nube en 1 clic.',
      'settings_edit_profile_title': 'Editar perfil',
      'settings_field_name': 'NOMBRE',
      'settings_field_location': 'UBICACIÓN',
      'settings_profile_saved': '¡Perfil actualizado correctamente!',
      'settings_change_pwd_title': 'Cambiar contraseña',
      'settings_pwd_current': 'CONTRASEÑA ACTUAL',
      'settings_pwd_new': 'NUEVA CONTRASEÑA (mín. 6 caracteres)',
      'settings_pwd_confirm': 'CONFIRMAR NUEVA CONTRASEÑA',
      'settings_pwd_update_btn': 'Actualizar contraseña',
      'settings_style_label': 'ESTILO PRINCIPAL DEL ARMARIO',
      'settings_currency_label': 'MONEDA DE COSTE POR USO (CPW)',
      'settings_size_label': 'SISTEMA DE TALLAS',
      'settings_apply_btn': 'Aplicar preferencias',
      'settings_notif_morning': 'Look matutino a las 08:00',
      'settings_notif_morning_sub': 'Cápsula diaria adaptada al clima cada mañana',
      'settings_notif_streak': 'Recordatorio de racha a las 20:00',
      'settings_notif_streak_sub': 'Mantén activa tu racha diaria de estilo',
      'settings_notif_eco': 'Resumen semanal Eco y CPW',
      'settings_notif_eco_sub': 'Informe de coste por uso y consejos de orden',
      'settings_notif_saved': '¡Preferencias de notificación guardadas!',
      'settings_pwa_section': 'APLICACIÓN Y MODO SIN CONEXIÓN (PWA)',
      'settings_pwa_install': 'Instalar como App (PWA)',
      'settings_pwa_install_sub': 'Inicio instantáneo desde la pantalla de inicio',
      'settings_pwa_offline': 'Acceso Sin Conexión y Service Worker',
      'settings_pwa_offline_sub': 'Armario, combinaciones y colorimetría funcionan sin internet',
      'settings_offline_body':
          'Vestora cuenta con un Service Worker con App Shell protegido:\n\n'
          '✅ Todo tu armario y fotos se almacenan localmente en el dispositivo.\n'
          '✅ La matriz cápsula 3x3 y la colorimetría funcionan sin conexión.\n'
          '✅ La guía de cuidado textil está disponible en modo avión.',
      'settings_sync_now': 'Sincronizar ahora (Nube ⇄ Local)',
      'settings_sync_now_sub': 'Replicar armario, perfil, calendario y usos con PostgreSQL',
      'settings_sql_schema': 'Esquema SQL para Supabase Dashboard',
      'settings_sql_schema_sub': 'Script DDL listo con políticas RLS y aislamiento S3',
      'settings_reset_cache': 'Restablecer filtros y caché',
      'settings_reset_cache_sub': 'Limpiar datos temporales y recargar la cápsula demo',

      'common_cancel': 'Cancelar',
      'common_save': 'Guardar',
      'common_close': 'Cerrar',

      'auth_login_tab': 'Iniciar Sesión',
      'auth_register_tab': 'Registrarse',
      'auth_google_btn': 'Continuar con Google',
      'auth_email_label': 'CORREO ELECTRÓNICO',
      'auth_password_label': 'CONTRASEÑA',
      'auth_forgot_pwd': '¿Olvidaste tu contraseña?',
      'auth_signin_btn': 'Acceder con Email',
      'auth_signup_btn': 'Crear Cuenta',
      'auth_guest_btn': 'Continuar como Invitado (Demo)',
      'auth_encryption': 'Cifrado bancario de 256 bits · Vestora Security',

      'tool_fabric_care': 'Guía de Cuidado de Prendas',
      'tool_travel_capsule': 'Cápsula de Viaje Inteligente',
      'tool_declutter': 'Depuración y Eco-Hub',
      'tool_color_analysis': 'Colorimetría Estacional',
      'tool_purchase_advisor': 'Asesor de Compras Inteligente',
    },

    // 6. German (Präzision & Stil)
    'de': {
      'tab_wardrobe': 'Garderobe',
      'tab_stylist': 'Stylist',
      'tab_add': 'Hinzufügen',
      'tab_community': 'Community',
      'tab_analytics': 'Analysen',

      'closet_title': 'DIGITALER KLEIDERSCHRANK',
      'closet_active_items': 'aktive Kleidungsstücke',
      'closet_streak': 'Tage Serie',
      'closet_health': 'Zustand:',
      'closet_search_hint': 'Suche nach Name, Marke, Farbe...',
      'closet_purchase_banner': 'Planen Sie einen Kauf? KI prüft auf Duplikate →',
      'closet_all': 'Alle',
      'closet_all_seasons': 'Alle Jahreszeiten',
      'closet_newest': 'Neueste',
      'closet_items_count': 'von',
      'closet_items_suffix': 'Artikeln',

      'stylist_title': 'KI Stylist Vestora',
      'stylist_prompt_hint': 'Fragen Sie die KI: "Geschäftstreffen an einem Regentag"...',
      'stylist_editorial_badge': 'VESTORA EDITORIAL',
      'stylist_moodboard_sub': 'KAPSEL-COLLAGE',
      'stylist_wear_btn': 'Dieses Outfit tragen (+1)',
      'stylist_style_check_btn': 'Style Check',
      'stylist_try_on': 'Anprobieren',
      'stylist_poster': 'Poster',
      'stylist_calendar': 'Kalender',
      'stylist_bookmark': 'Favoriten',
      'stylist_shuffle': 'Zufälliges Outfit erstellen',
      'stylist_matrix_tool': '3x3 Kapsel-Matrix',
      'stylist_editorial_tool': 'Story-Poster exportieren',

      'fitting_title': 'KI Virtuelle Umkleidekabine',
      'fitting_harmony_title': 'KI-Spiegel · Harmonie-Analyse',
      'fitting_harmony_score': 'Outfit-Harmonie',
      'fitting_undertone': 'Unterton',
      'fitting_silhouette': 'Passform & Schnitt',
      'fitting_advice': 'Stylisten-Tipp',

      'settings_title': 'Einstellungen & Profil',
      'settings_account': 'Konto & Anmeldung',
      'settings_ai_engine': 'KI-Engine & Vision API',
      'settings_cloud_sync': 'Cloud-Datenbank (Supabase PostgreSQL)',
      'settings_backup_hub': 'Sicherung & Datenportabilität (.vestora)',
      'settings_export_btn': 'Datei exportieren',
      'settings_import_btn': 'Backup importieren',
      'settings_personalization': 'Personalisierung & Stil',
      'settings_notifications': 'Benachrichtigungen & Digest',
      'settings_notifications_sub': 'Morgendlicher KI-Stylist, Serien & Textilpflege',
      'settings_appearance': 'Erscheinungsbild (Design)',
      'settings_theme_light': 'Hell',
      'settings_theme_dark': 'Dunkel',
      'settings_theme_system': 'System',
      'settings_language': 'Sprache der Benutzeroberfläche',
      'settings_security': 'Sicherheit & Passwort',
      'settings_legal_section': 'Datenschutz, Lizenzen & Datenkontrolle',
      'settings_privacy_policy': 'Datenschutzerklärung & DSGVO',
      'settings_privacy_sub': 'Local-First Architektur · Volle Datenhoheit',
      'settings_licenses': 'Open-Source-Softwarelizenzen',
      'settings_licenses_sub': 'Flutter-, Dart- und Drittanbieter-Bibliotheken',
      'settings_delete_account': 'Konto und alle Daten löschen',
      'settings_delete_account_sub': 'Profil, Garderobe und Cloud-Daten endgültig löschen',
      'settings_delete_confirm_title': 'Endgültige Kontolöschung',
      'settings_delete_confirm_body':
          'Dadurch werden Ihr Konto, alle Kleidungsstücke, geplanten Outfits, API-Schlüssel und synchronisierten Supabase-Cloud-Daten dauerhaft gelöscht. Dies kann nicht rückgängig gemacht werden.',
      'settings_delete_cancel': 'Abbrechen',
      'settings_delete_confirm_btn': 'Endgültig löschen',
      'settings_delete_success': 'Ihr Konto und alle persönlichen Daten wurden dauerhaft gelöscht.',
      'settings_logout': 'Abmelden',
      'settings_edit_profile': 'Bearbeiten',
      'settings_change_pwd': 'Passwort',
      'settings_logout_confirm': 'Möchten Sie sich wirklich abmelden?',
      'settings_stay': 'Bleiben',
      'settings_logout_action': 'Abmelden',
      'settings_logout_note': 'Melden Sie sich erneut über Google oder mit E-Mail und Passwort an.',
      'settings_privacy_body':
          '• Local-First-Architektur: Garderobe, Kapseln und Einstellungen bleiben standardmäßig lokal auf Ihrem Gerät.\n\n'
          '• Cloud-Isolierung (Supabase RLS): Fotos und Tabellen sind durch Row Level Security (auth.uid()) geschützt.\n\n'
          '• Geheimnisschutz: Passwörter mit gesalzenem HMAC-SHA256 (12.000 Runden) und Gemini-API-Schlüssel im Header x-goog-api-key.\n\n'
          '• Recht auf Löschung (DSGVO / App Store / Google Play): Exportieren Sie alle Daten (.vestora) oder löschen Sie Konto & Cloud mit 1 Klick.',
      'settings_edit_profile_title': 'Profil bearbeiten',
      'settings_field_name': 'NAME',
      'settings_field_location': 'STANDORT',
      'settings_profile_saved': 'Profil erfolgreich aktualisiert!',
      'settings_change_pwd_title': 'Passwort ändern',
      'settings_pwd_current': 'AKTUELLES PASSWORT',
      'settings_pwd_new': 'NEUES PASSWORT (mind. 6 Zeichen)',
      'settings_pwd_confirm': 'NEUES PASSWORT BESTÄTIGEN',
      'settings_pwd_update_btn': 'Passwort aktualisieren',
      'settings_style_label': 'HAUPTSTIL DER GARDEROBE',
      'settings_currency_label': 'WÄHRUNG FÜR TRAGEKOSTEN (CPW)',
      'settings_size_label': 'GRÖSSENSYSTEM',
      'settings_apply_btn': 'Einstellungen übernehmen',
      'settings_notif_morning': 'Morgen-Look um 08:00',
      'settings_notif_morning_sub': 'Wettergerechte Tageskapsel jeden Morgen',
      'settings_notif_streak': 'Serien-Erinnerung um 20:00',
      'settings_notif_streak_sub': 'Halten Sie Ihre tägliche Styling-Serie aktiv',
      'settings_notif_eco': 'Wöchentlicher Eco- & CPW-Bericht',
      'settings_notif_eco_sub': 'Tragekosten-Übersicht und Aussortier-Tipps',
      'settings_notif_saved': 'Benachrichtigungseinstellungen gespeichert!',
      'settings_pwa_section': 'APP & OFFLINE-MODUS (PWA)',
      'settings_pwa_install': 'Als App installieren (PWA)',
      'settings_pwa_install_sub': 'Sofortstart vom Startbildschirm auf Smartphone oder PC',
      'settings_pwa_offline': 'Offline-Zugriff & Service Worker',
      'settings_pwa_offline_sub': 'Garderobe, Outfits und Farbtyp funktionieren ohne Internet',
      'settings_offline_body':
          'Vestora nutzt einen Service Worker mit geschützter App Shell:\n\n'
          '✅ Ihre gesamte Garderobe und Fotos werden lokal gespeichert.\n'
          '✅ 3x3 Kapsel-Matrix und Farbpaletten funktionieren offline.\n'
          '✅ Das Textilpflege-Lexikon ist im Flugmodus verfügbar.',
      'settings_sync_now': 'Jetzt synchronisieren (Cloud ⇄ Lokal)',
      'settings_sync_now_sub': 'Garderobe, Profil, Kalender und Trage-Logs mit PostgreSQL abgleichen',
      'settings_sql_schema': 'SQL-Schema für Supabase Dashboard',
      'settings_sql_schema_sub': 'Fertiges DDL-Skript mit RLS-Richtlinien und S3-Ordnerisolierung',
      'settings_reset_cache': 'Filter zurücksetzen & Cache aktualisieren',
      'settings_reset_cache_sub': 'Temporäre Daten löschen und Demo-Kapsel neu laden',

      'common_cancel': 'Abbrechen',
      'common_save': 'Speichern',
      'common_close': 'Schließen',

      'auth_login_tab': 'Anmelden',
      'auth_register_tab': 'Registrieren',
      'auth_google_btn': 'Mit Google fortfahren',
      'auth_email_label': 'E-MAIL-ADRESSE',
      'auth_password_label': 'PASSWORT',
      'auth_forgot_pwd': 'Passwort vergessen?',
      'auth_signin_btn': 'Mit E-Mail anmelden',
      'auth_signup_btn': 'Konto erstellen',
      'auth_guest_btn': 'Als Gast fortfahren (Demo)',
      'auth_encryption': '256-Bit Bankenverschlüsselung · Vestora Security',

      'tool_fabric_care': 'Textilpflege-Lexikon',
      'tool_travel_capsule': 'Reise-Kapselgenerator',
      'tool_declutter': 'Aussortieren & Eco-Hub',
      'tool_color_analysis': 'Saisonale Farbtypberatung',
      'tool_purchase_advisor': 'Smarter Einkaufsberater',
    },
  };
}

extension LocalizationExtension on BuildContext {
  String tr(String key) => LocalizationService.instance.translate(key);
  AppLanguage get currentLanguage => LocalizationService.instance.currentLanguage;
}
