import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smart_wardrobe/main.dart';
import 'package:smart_wardrobe/models/clothing_item.dart';
import 'package:smart_wardrobe/screens/add_item_screen.dart';
import 'package:smart_wardrobe/screens/closet_screen.dart';
import 'package:smart_wardrobe/screens/outfit_builder_screen.dart';
import 'package:smart_wardrobe/services/ai_config_service.dart';
import 'package:smart_wardrobe/services/auth_service.dart';
import 'package:smart_wardrobe/services/localization_service.dart';
import 'package:smart_wardrobe/services/nav_service.dart';
import 'package:smart_wardrobe/services/outfit_calendar_service.dart';
import 'package:smart_wardrobe/services/theme_service.dart';
import 'package:smart_wardrobe/services/user_profile_service.dart';
import 'package:smart_wardrobe/services/wardrobe_provider.dart';
import 'package:smart_wardrobe/theme/app_theme.dart';
import 'package:smart_wardrobe/widgets/tools_sheet.dart';
import 'package:smart_wardrobe/widgets/vestora_image.dart';

/// Valid 1x1 PNG used as deterministic inline photo.
const String _kPng =
    'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';

ClothingItem _item(int i, {String? title, String? imageUrl}) {
  final cats = ClothingCategory.values;
  final seasons = Season.values;
  return ClothingItem(
    id: 'stress_$i',
    title: title ?? 'Річ №$i',
    brand: 'Brand ${i % 17}',
    price: 100.0 + (i % 50) * 37,
    currency: 'UAH',
    imageUrl: imageUrl ?? _kPng,
    category: cats[i % cats.length],
    season: seasons[i % seasons.length],
    color: 'Колір ${i % 9}',
    wearCount: i % 5,
  );
}

Future<WardrobeProvider> _freshWardrobe(List<ClothingItem> items) async {
  final wardrobe = WardrobeProvider();
  await wardrobe.initialized;
  await wardrobe.clearWardrobe(clearTombstones: true);
  if (items.isNotEmpty) {
    await wardrobe.addMultipleItems(items);
  }
  return wardrobe;
}

Widget _shell(WardrobeProvider wardrobe, Widget home, {double textScale = 1.0, bool dark = false}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<WardrobeProvider>.value(value: wardrobe),
      ChangeNotifierProvider<LocalizationService>.value(value: LocalizationService.instance),
      ChangeNotifierProvider<ThemeService>.value(value: ThemeService.instance),
      ChangeNotifierProvider<AuthService>.value(value: AuthService.instance),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: home,
    ),
  );
}

/// Runs [body] while collecting every framework error (overflows, build exceptions, lifecycle bugs).
Future<List<String>> _collectErrors(WidgetTester tester, Future<void> Function() body) async {
  final errors = <String>[];
  final original = FlutterError.onError;
  FlutterError.onError = (details) {
    final msg = details.exceptionAsString();
    if (!details.silent || msg.contains('RenderFlex') || msg.contains('overflowed')) {
      errors.add(details.toString());
    }
  };
  try {
    await body();
    final pending = tester.takeException();
    if (pending != null) errors.add(pending.toString());
  } finally {
    FlutterError.onError = original;
  }
  return errors;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await UserProfileService.initialize();
    await AiConfigService.initialize();
    await OutfitCalendarService.initialize();
    await LocalizationService.instance.setLanguage(AppLanguage.uk);
    await ThemeService.instance.setThemeMode(ThemeMode.light);
    AppNav.tabRequest.value = null;
  });

  group('🔥 [STRESS 1] Data volume & hostile data', () {
    test('1 500 items: search / filter / sort churn stays responsive and consistent', () async {
      final wardrobe = await _freshWardrobe(List.generate(1500, _item));
      expect(wardrobe.items.length, 1500);

      final sw = Stopwatch()..start();
      for (var i = 0; i < 60; i++) {
        wardrobe.setSearchQuery(i.isEven ? 'Річ №1' : 'brand 3');
        wardrobe.setCategoryFilter(ClothingCategory.values[i % ClothingCategory.values.length]);
        wardrobe.setSeasonFilter(i % 3 == 0 ? null : Season.values[i % Season.values.length]);
        wardrobe.setSortOption(WardrobeSortOption.values[i % WardrobeSortOption.values.length]);
        // Touch the computed list every iteration, like a rebuild would.
        expect(wardrobe.filteredItems.length, lessThanOrEqualTo(1500));
      }
      wardrobe.resetAllFilters();
      sw.stop();

      expect(wardrobe.filteredItems.length, 1500);
      expect(sw.elapsedMilliseconds, lessThan(8000), reason: 'filter churn took ${sw.elapsedMilliseconds}ms');
    });

    test('Concurrent add/remove/undo storm keeps count consistent and never throws', () async {
      final wardrobe = await _freshWardrobe(const []);
      final futures = <Future<void>>[];
      for (var i = 0; i < 120; i++) {
        futures.add(wardrobe.addItem(_item(i)));
      }
      await Future.wait(futures);
      expect(wardrobe.items.length, 120);

      final removed = <ClothingItem>[];
      final rm = <Future<void>>[];
      for (var i = 0; i < 60; i++) {
        removed.add(wardrobe.items.firstWhere((e) => e.id == 'stress_$i'));
        rm.add(wardrobe.removeItem('stress_$i'));
      }
      await Future.wait(rm);
      expect(wardrobe.items.length, 60);

      // "Undo" every deletion (what the Скасувати SnackBar action does).
      await Future.wait(removed.map(wardrobe.addItem));
      expect(wardrobe.items.length, 120);
      expect(wardrobe.items.map((e) => e.id).toSet().length, 120, reason: 'no duplicate ids after undo');
    });

    test('Image pipeline tolerates hostile data URIs (no mime, whitespace, missing padding, junk)', () {
      VestoraImage.clearMemoryCache();
      final b64 = _kPng.split(',').last;
      final spaced = '${b64.substring(0, 20)}\n  ${b64.substring(20)}';
      final unpadded = b64.replaceAll('=', '');

      expect(VestoraImage.decodeDataUriCached('data:;base64,$b64'), isNotNull);
      expect(VestoraImage.decodeDataUriCached('data:image/jpeg;base64,$spaced'), isNotNull);
      expect(VestoraImage.decodeDataUriCached('data:image/png;base64,$unpadded'), isNotNull);
      expect(VestoraImage.decodeDataUriCached('data:image/png;base64,'), isNull);
      expect(VestoraImage.decodeDataUriCached('data:image/png;base64,@@@###'), isNull);
      expect(VestoraImage.decodeDataUriCached('not a uri at all'), isNull);
      expect(VestoraImage.decodeDataUriCached(''), isNull);
    });

    testWidgets('ClosetScreen survives empty titles, 4 000-char titles and corrupt photos', (tester) async {
      final wardrobe = await _freshWardrobe([
        _item(1, title: ''),
        _item(2, title: 'Ж' * 4000),
        _item(3, imageUrl: 'data:image/png;base64,@@@###'),
        _item(4, imageUrl: ''),
        _item(5, imageUrl: 'data:;base64,${_kPng.split(',').last}'),
        _item(6, title: '😀' * 300),
      ]);
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final errors = await _collectErrors(tester, () async {
        await tester.pumpWidget(_shell(wardrobe, const ClosetScreen()));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -900));
        await tester.pump(const Duration(milliseconds: 300));
      });
      expect(errors, isEmpty, reason: errors.join('\n'));
    });
  });

  group('🔥 [STRESS 2] Accessibility: 320px + 200% text, empty & full states, light & dark', () {
    testWidgets('Core screens never overflow at 320x568 with 2.0x text scale', (tester) async {
      final full = await _freshWardrobe(List.generate(12, _item));
      final empty = await _freshWardrobe(const []);
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final scenarios = <String, (WardrobeProvider, Widget Function())>{
        'Closet (full)': (full, () => const ClosetScreen()),
        'Closet (EMPTY first-run)': (empty, () => const ClosetScreen()),
        'Stylist (EMPTY)': (empty, () => const OutfitBuilderScreen()),
        'Stylist (full)': (full, () => const OutfitBuilderScreen()),
        'AddItem': (full, () => AddItemScreen(onSaved: () {})),
      };

      final failures = <String>[];
      for (final dark in [false, true]) {
        for (final scale in [1.0, 2.0]) {
          for (final e in scenarios.entries) {
            final errors = await _collectErrors(tester, () async {
              await tester.pumpWidget(_shell(e.value.$1, e.value.$2(), textScale: scale, dark: dark));
              await tester.pump(const Duration(milliseconds: 300));
            });
            if (errors.isNotEmpty) {
              failures.add('[${e.key} scale=$scale dark=$dark] ${errors.first}');
            }
          }
        }
      }
      expect(failures, isEmpty, reason: failures.join('\n---\n'));
    });

    testWidgets('Closet: real garments are visible on the FIRST screen of a 390x844 phone (no wall of widgets)',
        (tester) async {
      final wardrobe = await _freshWardrobe(List.generate(12, _item));
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_shell(wardrobe, const ClosetScreen()));
      await tester.pump(const Duration(milliseconds: 600));

      final titles = find.textContaining('Річ №');
      expect(titles, findsWidgets);
      var topMost = double.infinity;
      for (final e in titles.evaluate()) {
        final dy = tester.getTopLeft(find.byWidget(e.widget)).dy;
        if (dy < topMost) topMost = dy;
      }
      // 844 screen − 80 bottom navigation bar: the first card title must be reachable without scrolling.
      expect(topMost, lessThan(764), reason: 'first garment title sits at y=$topMost');
    });

    testWidgets('AddItem: every tab renders at 320px / 2.0x text without overflow', (tester) async {
      final wardrobe = await _freshWardrobe(List.generate(3, _item));
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final errors = await _collectErrors(tester, () async {
        await tester.pumpWidget(_shell(wardrobe, AddItemScreen(onSaved: () {}), textScale: 2.0));
        await tester.pump(const Duration(milliseconds: 300));
        final tabController = tester.widget<TabBar>(find.byType(TabBar)).controller!;
        for (final i in [1, 2, 3, 0]) {
          tabController.animateTo(i, duration: Duration.zero);
          await tester.pump(const Duration(milliseconds: 400));
        }
      });
      expect(errors, isEmpty, reason: errors.join('\n'));
    });

    testWidgets('Tools sheet: readable, scrollable, large tap targets at 320px / 2.0x text', (tester) async {
      final wardrobe = await _freshWardrobe(List.generate(3, _item));
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final errors = await _collectErrors(tester, () async {
        await tester.pumpWidget(_shell(
          wardrobe,
          Builder(
            builder: (ctx) => Scaffold(
              body: Center(
                child: ElevatedButton(onPressed: () => showToolsSheet(ctx), child: const Text('open')),
              ),
            ),
          ),
          textScale: 2.0,
        ));
        await tester.tap(find.text('open'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.text('Інструменти Vestora'), findsOneWidget);
        // Ahem test font makes 2x text extreme, so the list is scrolled to reach the first tool (proves it scrolls).
        await tester.scrollUntilVisible(
          find.text('Календар образів'),
          200,
          scrollable: find.descendant(of: find.byType(DraggableScrollableSheet), matching: find.byType(Scrollable)).first,
        );
        expect(find.text('Календар образів'), findsOneWidget);
        final tile = tester.getSize(find.byType(ListTile).first);
        expect(tile.height, greaterThanOrEqualTo(48));
      });
      expect(errors, isEmpty, reason: errors.join('\n'));
    });
  });

  group('🔥 [STRESS 3] Navigation shell: rapid tab mashing, state preservation, cross-screen jumps', () {
    testWidgets('Mashing all 5 tabs 40× never throws; Add tab keeps state; AppNav jumps work', (tester) async {
      final wardrobe = await _freshWardrobe(List.generate(8, _item));
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final errors = await _collectErrors(tester, () async {
        await tester.pumpWidget(_shell(wardrobe, const MainNavigationScreen()));
        await tester.pump(const Duration(milliseconds: 300));

        final labels = ['Гардероб', 'Стиліст', 'Додати', 'Спільнота', 'Аналітика'];
        for (var i = 0; i < 40; i++) {
          await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text(labels[(i * 3) % 5])));
          await tester.pump(const Duration(milliseconds: 60));
        }

        // Add tab is built once and kept alive when leaving it (user must not lose fresh photos).
        await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Додати')));
        await tester.pump(const Duration(milliseconds: 200));
        final addState = tester.state(find.byType(AddItemScreen));
        await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Гардероб')));
        await tester.pump(const Duration(milliseconds: 200));
        await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Додати')));
        await tester.pump(const Duration(milliseconds: 200));
        expect(identical(addState, tester.state(find.byType(AddItemScreen))), isTrue,
            reason: 'Add tab state must survive tab switches');

        // Cross-screen jump used by empty states.
        AppNav.goToTab(AppNav.tabAnalytics);
        await tester.pump(const Duration(milliseconds: 200));
        expect(AppNav.tabRequest.value, isNull, reason: 'request must be consumed');
        final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
        expect(bar.selectedIndex, AppNav.tabAnalytics);
      });
      expect(errors, isEmpty, reason: errors.join('\n'));
    });

    testWidgets('First-run: empty wardrobe primary CTA sends the user to the Add tab (not demo data)', (tester) async {
      final wardrobe = await _freshWardrobe(const []);
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_shell(wardrobe, const MainNavigationScreen()));
      await tester.pump(const Duration(milliseconds: 300));

      final cta = find.text('Додати першу річ');
      expect(cta, findsOneWidget);
      await tester.ensureVisible(cta); await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(cta);
      await tester.pump(const Duration(milliseconds: 300));

      expect(wardrobe.items, isEmpty, reason: 'primary CTA must never inject demo data');
      expect(tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex, AppNav.tabAdd);
    });

    testWidgets('Add flow without AI key never dead-ends: primary button continues, no modal wall', (tester) async {
      await AiConfigService.clearAllData();
      final wardrobe = await _freshWardrobe(const []);
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_shell(wardrobe, AddItemScreen(onSaved: () {})));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Далі: заповнити дані та зберегти'), findsOneWidget);
      expect(find.text('Розпізнати через ШІ та перевірити'), findsNothing);
      // With no photo, we get friendly guidance rather than a crash or a key prompt.
      await tester.ensureVisible(find.text('Далі: заповнити дані та зберегти')); await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.text('Далі: заповнити дані та зберегти'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('Спершу сфотографуйте'), findsOneWidget);
      expect(find.textContaining('API ключ'), findsNothing);
    });
  });

  group('🔥 [STRESS 4] Destructive-action safety', () {
    testWidgets('Deleting an item offers Скасувати and fully restores it', (tester) async {
      final wardrobe = await _freshWardrobe([_item(1, title: 'Тестова куртка')]);
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_shell(wardrobe, const ClosetScreen()));
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Тестова куртка').first);
      await tester.pump(const Duration(milliseconds: 400));
      final del = find.byTooltip('Видалити');
      await tester.ensureVisible(del); await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(del);
      await tester.pump(const Duration(milliseconds: 400));
      expect(wardrobe.items, isEmpty);

      expect(find.text('Скасувати'), findsOneWidget);
      // Invoke the SnackBar action callback directly (hit-testing a floating SnackBar is flaky under the Ahem test font).
      tester.widget<SnackBarAction>(find.byType(SnackBarAction)).onPressed();
      await tester.pump(const Duration(milliseconds: 300));
      expect(wardrobe.items.length, 1);
      expect(wardrobe.items.first.title, 'Тестова куртка');
    });
  });
}
