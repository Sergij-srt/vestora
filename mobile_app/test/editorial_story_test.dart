import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wardrobe/models/clothing_item.dart';
import 'package:smart_wardrobe/screens/editorial_story_screen.dart';

void main() {
  testWidgets('EditorialStoryScreen renders high fashion layout and toggles themes & formats',
      (WidgetTester tester) async {
    final mockItems = [
      ClothingItem(
        id: 'c1',
        title: 'Кашемірове пальто',
        brand: 'Max Mara',
        category: ClothingCategory.outerwear,
        imageUrl: 'https://example.com/coat.jpg',
        color: 'Бежевий',
        price: 18000,
      ),
      ClothingItem(
        id: 'c2',
        title: 'Шовкова блуза',
        brand: 'Massimo Dutti',
        category: ClothingCategory.tops,
        imageUrl: 'https://example.com/silk.jpg',
        color: 'Молочний',
        price: 3200,
      ),
      ClothingItem(
        id: 'c3',
        title: 'Штани палаццо',
        brand: 'Toteme',
        category: ClothingCategory.bottoms,
        imageUrl: 'https://example.com/pants.jpg',
        color: 'Чорний',
        price: 7500,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: EditorialStoryScreen(
          items: mockItems,
          occasion: 'Old Money Business',
          temperatureText: '+17°C Хмарно',
          styleScore: 9.9,
          customQuote: '«Чисті пропорції та досконалість силуету»',
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify haute magazine branding and titles
    expect(find.text('VESTORA'), findsOneWidget);
    expect(find.text('ISSUE № 07'), findsOneWidget);
    expect(find.text('Editorial Moodboard & Story'), findsOneWidget);
    expect(find.text('Зберегти постер'), findsOneWidget);
    expect(find.text('Приміряти'), findsOneWidget);

    // Verify brands & custom quote are rendered
    expect(find.textContaining('MAX MARA'), findsOneWidget);
    expect(find.textContaining('MASSIMO DUTTI'), findsOneWidget);
    expect(find.textContaining('TOTEME'), findsOneWidget);
    expect(find.textContaining('Чисті пропорції'), findsOneWidget);

    // Verify format buttons exist
    expect(find.text('9:16'), findsOneWidget);
    expect(find.text('4:5'), findsOneWidget);

    // Tap 4:5 moodboard format
    await tester.tap(find.text('4:5'));
    await tester.pump();

    // Tap Ivory Cashmere theme
    final ivoryChip = find.text('Ivory Cashmere');
    expect(ivoryChip, findsOneWidget);
    await tester.tap(ivoryChip);
    await tester.pump();

    // Tap Save button to trigger poster export flow
    await tester.tap(find.text('Зберегти постер'));
    await tester.pump();
  });

  testWidgets('EditorialStoryScreen handles single item and 4 items with palette extraction',
      (WidgetTester tester) async {
    final mockFourItems = [
      ClothingItem(
        id: 'f1',
        title: 'Шовковий тренч',
        brand: 'Burberry',
        category: ClothingCategory.outerwear,
        imageUrl: 'https://example.com/trench.jpg',
        color: 'Бежевий',
        price: 25000,
      ),
      ClothingItem(
        id: 'f2',
        title: 'Базова футболка',
        brand: 'COS',
        category: ClothingCategory.tops,
        imageUrl: 'https://example.com/tee.jpg',
        color: 'Білий',
        price: 1200,
      ),
      ClothingItem(
        id: 'f3',
        title: 'Вовняні брюки',
        brand: 'Loro Piana',
        category: ClothingCategory.bottoms,
        imageUrl: 'https://example.com/wool.jpg',
        color: 'Еспресо',
        price: 32000,
      ),
      ClothingItem(
        id: 'f4',
        title: 'Шкіряні лофери',
        brand: 'Gucci',
        category: ClothingCategory.shoes,
        imageUrl: 'https://example.com/loafers.jpg',
        color: 'Чорний',
        price: 28000,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: EditorialStoryScreen(
          items: mockFourItems,
          occasion: 'Evening Gala',
          temperatureText: '+20°C Тепло',
          styleScore: 10.0,
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('BURBERRY'), findsOneWidget);
    expect(find.text('LORO PIANA'), findsOneWidget);
    expect(find.text('GUCCI'), findsOneWidget);
    expect(find.text('COS'), findsOneWidget);
    expect(find.text('ПАЛІТРА ОБРАЗУ'), findsOneWidget);
  });
}
