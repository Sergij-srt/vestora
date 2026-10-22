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
  static bool _initialized = false;

  AppLanguage get currentLanguage => _currentLanguage;
  Locale get currentLocale => Locale(_currentLanguage.code);

  static Future<void> initialize() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString(_keyLang);
      if (savedCode != null) {
        instance._currentLanguage = AppLanguage.fromCode(savedCode);
      }
      _initialized = true;
    } catch (_) {
      _initialized = true;
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
      'closet_title': 'ЦИФРОВИЙ ГАРДЕРОВ',
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
      'settings_personalization': 'Персоналізація та Стиль',
      'settings_appearance': 'Зовнішній вигляд (Тема)',
      'settings_theme_light': 'Світла',
      'settings_theme_dark': 'Темна',
      'settings_theme_system': 'Системна',
      'settings_language': 'Мова інтерфейсу',
      'settings_security': 'Безпека та Пароль',
      'settings_logout': 'Вийти з акаунту',
      'settings_edit_profile': 'Редагувати',
      'settings_change_pwd': 'Пароль',
      'settings_logout_confirm': 'Ви впевнені, що бажаєте вийти з акаунту?',
      'settings_stay': 'Залишитися',
      'settings_logout_action': 'Вийти',

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
      'settings_personalization': 'Personalization & Style',
      'settings_appearance': 'Appearance (Theme)',
      'settings_theme_light': 'Light',
      'settings_theme_dark': 'Dark',
      'settings_theme_system': 'System',
      'settings_language': 'Interface Language',
      'settings_security': 'Security & Password',
      'settings_logout': 'Sign Out',
      'settings_edit_profile': 'Edit',
      'settings_change_pwd': 'Password',
      'settings_logout_confirm': 'Are you sure you want to sign out?',
      'settings_stay': 'Stay',
      'settings_logout_action': 'Sign Out',

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
      'fitting_silhouette': 'Coupe & Silouhette',
      'fitting_advice': 'Conseil Styliste',

      'settings_title': 'Paramètres & Espace Personnel',
      'settings_account': 'Compte & Connexion',
      'settings_ai_engine': 'Moteur IA & Vision API',
      'settings_personalization': 'Personnalisation & Style',
      'settings_appearance': 'Apparence (Thème)',
      'settings_theme_light': 'Clair',
      'settings_theme_dark': 'Sombre',
      'settings_theme_system': 'Système',
      'settings_language': 'Langue de l\'interface',
      'settings_security': 'Sécurité & Mot de passe',
      'settings_logout': 'Se déconnecter',
      'settings_edit_profile': 'Modifier',
      'settings_change_pwd': 'Mot de passe',
      'settings_logout_confirm': 'Êtes-vous sûr de vouloir vous déconnecter?',
      'settings_stay': 'Rester',
      'settings_logout_action': 'Déconnexion',

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
      'settings_personalization': 'Personalizzazione & Stile',
      'settings_appearance': 'Aspetto (Tema)',
      'settings_theme_light': 'Chiaro',
      'settings_theme_dark': 'Scuro',
      'settings_theme_system': 'Sistema',
      'settings_language': 'Lingua dell\'interfaccia',
      'settings_security': 'Sicurezza & Password',
      'settings_logout': 'Esci dall\'account',
      'settings_edit_profile': 'Modifica',
      'settings_change_pwd': 'Password',
      'settings_logout_confirm': 'Sei sicuro di voler uscire dal tuo account?',
      'settings_stay': 'Rimani',
      'settings_logout_action': 'Esci',

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
      'settings_personalization': 'Personalización y Estilo',
      'settings_appearance': 'Apariencia (Tema)',
      'settings_theme_light': 'Claro',
      'settings_theme_dark': 'Oscuro',
      'settings_theme_system': 'Sistema',
      'settings_language': 'Idioma de la interfaz',
      'settings_security': 'Seguridad y Contraseña',
      'settings_logout': 'Cerrar sesión',
      'settings_edit_profile': 'Editar',
      'settings_change_pwd': 'Password',
      'settings_logout_confirm': '¿Seguro que deseas cerrar sesión?',
      'settings_stay': 'Permanecer',
      'settings_logout_action': 'Salir',

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
      'settings_personalization': 'Personalisierung & Stil',
      'settings_appearance': 'Erscheinungsbild (Design)',
      'settings_theme_light': 'Hell',
      'settings_theme_dark': 'Dunkel',
      'settings_theme_system': 'System',
      'settings_language': 'Sprache der Benutzeroberfläche',
      'settings_security': 'Sicherheit & Passwort',
      'settings_logout': 'Abmelden',
      'settings_edit_profile': 'Bearbeiten',
      'settings_change_pwd': 'Passwort',
      'settings_logout_confirm': 'Möchten Sie sich wirklich abmelden?',
      'settings_stay': 'Bleiben',
      'settings_logout_action': 'Abmelden',

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
