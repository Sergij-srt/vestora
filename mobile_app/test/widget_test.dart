import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wardrobe/main.dart';

void main() {
  testWidgets('SmartWardrobe app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SmartWardrobeApp());

    // Verify that the brand title appears
    expect(find.text('VESTORA'), findsOneWidget);
  });
}
