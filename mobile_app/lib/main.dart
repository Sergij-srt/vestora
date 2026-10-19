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
        home: const MainNavigationScreen(),
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
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.border, width: 1)),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFFF4F4F5),
          onDestinationSelected: (index) {
            setState(() => _currentIndex = index);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.checkroom_outlined),
              selectedIcon: Icon(Icons.checkroom_rounded, color: AppTheme.primary),
              label: 'Гардероб',
            ),
            NavigationDestination(
              icon: Icon(Icons.style_outlined),
              selectedIcon: Icon(Icons.style_rounded, color: AppTheme.primary),
              label: 'Стиліст',
            ),
            NavigationDestination(
              icon: Icon(Icons.add_circle_outline_rounded),
              selectedIcon: Icon(Icons.add_circle_rounded, color: AppTheme.accent),
              label: 'Додати',
            ),
            NavigationDestination(
              icon: Icon(Icons.auto_awesome_outlined),
              selectedIcon: Icon(Icons.auto_awesome_rounded, color: AppTheme.primary),
              label: 'Спільнота',
            ),
            NavigationDestination(
              icon: Icon(Icons.insights_rounded),
              selectedIcon: Icon(Icons.insights_rounded, color: AppTheme.primary),
              label: 'Аналітика',
            ),
          ],
        ),
      ),
    );
  }
}
