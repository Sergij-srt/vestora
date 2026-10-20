import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/wardrobe_provider.dart';
import 'theme/app_theme.dart';
import 'screens/closet_screen.dart';
import 'screens/add_item_screen.dart';
import 'screens/outfit_builder_screen.dart';
import 'screens/ootd_feed_screen.dart';
import 'screens/analytics_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SmartWardrobeApp());
}

class SmartWardrobeApp extends StatelessWidget {
  const SmartWardrobeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WardrobeProvider(),
      child: MaterialApp(
        title: 'Vestora · Smart Wardrobe',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const ResponsiveAppWrapper(child: MainNavigationScreen()),
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

    if (!isDesktop) {
      return child;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F3), // Neutral luxury canvas
      body: Center(
        child: Container(
          width: 440,
          margin: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(36),
            border: Border.all(color: const Color(0xFFD4D4D8), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
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
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppTheme.border, width: 1)),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFFFEF3C7),
          elevation: 0,
          onDestinationSelected: (index) {
            setState(() => _currentIndex = index);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.checkroom_outlined),
              selectedIcon: Icon(Icons.checkroom_rounded, color: AppTheme.accent),
              label: 'Гардероб',
            ),
            NavigationDestination(
              icon: Icon(Icons.style_outlined),
              selectedIcon: Icon(Icons.style_rounded, color: AppTheme.accent),
              label: 'Стиліст',
            ),
            NavigationDestination(
              icon: Icon(Icons.add_circle_outline_rounded),
              selectedIcon: Icon(Icons.add_circle_rounded, color: AppTheme.accent),
              label: 'Додати',
            ),
            NavigationDestination(
              icon: Icon(Icons.auto_awesome_outlined),
              selectedIcon: Icon(Icons.auto_awesome_rounded, color: AppTheme.accent),
              label: 'Спільнота',
            ),
            NavigationDestination(
              icon: Icon(Icons.insights_rounded),
              selectedIcon: Icon(Icons.insights_rounded, color: AppTheme.accent),
              label: 'Аналітика',
            ),
          ],
        ),
      ),
    );
  }
}
