import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/wardrobe_provider.dart';
import 'services/ai_config_service.dart';
import 'services/user_profile_service.dart';
import 'services/auth_service.dart';
import 'services/theme_service.dart';
import 'services/localization_service.dart';
import 'services/supabase_service.dart';
import 'services/outfit_calendar_service.dart';
import 'theme/app_theme.dart';
import 'screens/closet_screen.dart';
import 'screens/add_item_screen.dart';
import 'screens/outfit_builder_screen.dart';
import 'screens/ootd_feed_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/auth_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.initialize();
  await AiConfigService.initialize();
  await UserProfileService.initialize();
  await ThemeService.initialize();
  await LocalizationService.initialize();
  await OutfitCalendarService.initialize();
  await SupabaseService.initialize();
  runApp(const SmartWardrobeApp());
}

class SmartWardrobeApp extends StatelessWidget {
  const SmartWardrobeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WardrobeProvider()),
        ChangeNotifierProvider.value(value: AuthService.instance),
        ChangeNotifierProvider.value(value: ThemeService.instance),
        ChangeNotifierProvider.value(value: LocalizationService.instance),
      ],
      child: Consumer3<AuthService, ThemeService, LocalizationService>(
        builder: (context, auth, theme, loc, _) {
          return MaterialApp(
            title: 'Vestora · Smart Wardrobe',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: theme.themeMode,
            locale: loc.currentLocale,
            home: ResponsiveAppWrapper(
              child: auth.isLoggedIn
                  ? const MainNavigationScreen()
                  : const AuthScreen(),
            ),
          );
        },
      ),
    );
  }
}

/// Provides a luxury centered mobile preview on desktop/tablet while filling 100% on phones
class ResponsiveAppWrapper extends StatelessWidget {
  final Widget child;
  const ResponsiveAppWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 520;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!isDesktop) {
      return child;
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF09090B) : const Color(0xFFF0F0F3),
      body: Center(
        child: Container(
          width: 440,
          margin: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkBackground : Colors.white,
            borderRadius: BorderRadius.circular(36),
            border: Border.all(
              color: isDark ? AppTheme.darkBorder : const Color(0xFFD4D4D8),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
                blurRadius: 36,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: child,
        ),
      ),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationService>();
    final theme = context.watch<ThemeService>();
    final isDark = theme.isDarkMode(context);

    final screens = [
      const ClosetScreen(),
      const OutfitBuilderScreen(),
      AddItemScreen(onSaved: () {
        setState(() => _currentIndex = 0); // Switch to closet upon saving
      }),
      const OotdFeedScreen(),
      const AnalyticsScreen(),
    ];

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        child: KeyedSubtree(
          key: ValueKey<int>(_currentIndex),
          child: screens[_currentIndex],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? AppTheme.darkBorder : AppTheme.border,
              width: 1,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
          indicatorColor: isDark ? const Color(0xFF2E2E38) : const Color(0xFFFEF3C7),
          elevation: 0,
          onDestinationSelected: (index) {
            setState(() => _currentIndex = index);
          },
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.checkroom_outlined),
              selectedIcon: Icon(
                Icons.checkroom_rounded,
                color: isDark ? AppTheme.darkAccent : AppTheme.accent,
              ),
              label: loc.translate('tab_wardrobe'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.style_outlined),
              selectedIcon: Icon(
                Icons.style_rounded,
                color: isDark ? AppTheme.darkAccent : AppTheme.accent,
              ),
              label: loc.translate('tab_stylist'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.add_circle_outline_rounded),
              selectedIcon: Icon(
                Icons.add_circle_rounded,
                color: isDark ? AppTheme.darkAccent : AppTheme.accent,
              ),
              label: loc.translate('tab_add'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.auto_awesome_outlined),
              selectedIcon: Icon(
                Icons.auto_awesome_rounded,
                color: isDark ? AppTheme.darkAccent : AppTheme.accent,
              ),
              label: loc.translate('tab_community'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.insights_rounded),
              selectedIcon: Icon(
                Icons.insights_rounded,
                color: isDark ? AppTheme.darkAccent : AppTheme.accent,
              ),
              label: loc.translate('tab_analytics'),
            ),
          ],
        ),
      ),
    );
  }
}
