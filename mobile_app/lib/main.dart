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
import 'services/secure_vault_service.dart';
import 'services/nav_service.dart';
import 'theme/app_theme.dart';
import 'screens/closet_screen.dart';
import 'screens/add_item_screen.dart';
import 'screens/outfit_builder_screen.dart';
import 'screens/ootd_feed_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/auth_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SecureVaultService.migrateFromSharedPreferences();
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

  /// Tabs that were opened at least once. Visited tabs stay alive inside the [IndexedStack] so that
  /// switching tabs never throws away user work (e.g. 3 freshly taken photos on the Add tab).
  final Set<int> _visitedTabs = <int>{0};

  /// Bumped after a successful save so the Add tab starts from a clean form next time.
  int _addFormGeneration = 0;

  @override
  void initState() {
    super.initState();
    AppNav.tabRequest.addListener(_handleTabRequest);
  }

  @override
  void dispose() {
    AppNav.tabRequest.removeListener(_handleTabRequest);
    super.dispose();
  }

  void _handleTabRequest() {
    final requested = AppNav.tabRequest.value;
    if (requested == null) return;
    AppNav.tabRequest.value = null;
    if (requested >= 0 && requested <= 4 && mounted) {
      _selectTab(requested);
    }
  }

  void _selectTab(int index) {
    setState(() {
      _currentIndex = index;
      _visitedTabs.add(index);
    });
  }

  Widget _buildTab(int index) {
    if (!_visitedTabs.contains(index)) return const SizedBox.shrink();
    switch (index) {
      case 0:
        return const ClosetScreen();
      case 1:
        return const OutfitBuilderScreen();
      case 2:
        return AddItemScreen(
          key: ValueKey<int>(_addFormGeneration),
          onSaved: () {
            setState(() {
              _addFormGeneration++; // fresh form next time
              _currentIndex = AppNav.tabCloset; // reveal the saved item
              _visitedTabs.add(AppNav.tabCloset);
            });
          },
        );
      case 3:
        return const OotdFeedScreen();
      default:
        return const AnalyticsScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationService>();
    final theme = context.watch<ThemeService>();
    final isDark = theme.isDarkMode(context);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: List<Widget>.generate(5, _buildTab),
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
          onDestinationSelected: _selectTab,
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
              icon: const Icon(Icons.groups_outlined),
              selectedIcon: Icon(
                Icons.groups_rounded,
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
