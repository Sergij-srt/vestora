import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wardrobe/services/fabric_care_service.dart';

void main() {
  group('FabricCareService Tests', () {
    test('Contains rich care symbols across all primary care categories', () {
      expect(FabricCareService.symbols.length, greaterThanOrEqualTo(10));
      expect(FabricCareService.symbols.any((s) => s.category == CareSymbolCategory.wash), isTrue);
      expect(FabricCareService.symbols.any((s) => s.category == CareSymbolCategory.dry), isTrue);
      expect(FabricCareService.symbols.any((s) => s.category == CareSymbolCategory.iron), isTrue);
      expect(FabricCareService.symbols.any((s) => s.category == CareSymbolCategory.dryClean), isTrue);
    });

    test('Contains emergency stain guides with concrete actionable steps', () {
      expect(FabricCareService.stainGuides.length, greaterThanOrEqualTo(4));
      for (final guide in FabricCareService.stainGuides) {
        expect(guide.stainType, isNotEmpty);
        expect(guide.goldenRule, isNotEmpty);
        expect(guide.steps.length, greaterThanOrEqualTo(3));
      }
    });

    test('Contains comprehensive fabric longevity secrets for luxury fabrics', () {
      expect(FabricCareService.fabricGuides.length, greaterThanOrEqualTo(4));
      final cashmere = FabricCareService.fabricGuides.firstWhere((f) => f.fabricName.contains('Кашемір'));
      expect(cashmere.storageRule, contains('складеним'));
      expect(cashmere.proStylistSecret, isNotEmpty);
    });
  });
}
