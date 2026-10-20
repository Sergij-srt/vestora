import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wardrobe/services/clothing_ocr_service.dart';

void main() {
  group('ClothingOcrService Tests', () {
    test('extracts brand, size, fabric, and origin from raw label text', () {
      const sampleLabel = '''
MASSIMO DUTTI
REF. 6712/501/712
SIZE EUR 38 / US S
100% PURE WOOL / 100% ВОВНА
MADE IN PORTUGAL
30°C GENTLE WASH / DRY CLEAN ONLY
''';

      final result = ClothingOcrService.parseLabelText(sampleLabel);

      expect(result.brand, equals('Massimo Dutti'));
      expect(result.size, contains('38'));
      expect(result.fabricComposition, contains('100%'));
      expect(result.countryOfOrigin, contains('Portugal'));
      expect(result.careInstructions, contains('30°C'));
    });

    test('extracts store, price, and item title from raw receipt text', () {
      const sampleReceipt = '''
ТОВ "ЗАРА УКРАЇНА"
ТРЦ RIVER MALL, М. КИЇВ
ФІСКАЛЬНИЙ ЧЕК № 441029
ДАТА: 19.10.2026 12:15
----------------------------------------
СОРОЧКА 100% ЛЬОН БІЛА       1 ШТ
СУМА: 1 499.00 UAH
''';

      final result = ClothingOcrService.parseReceiptText(sampleReceipt);

      expect(result.storeName, equals('Zara'));
      expect(result.price, equals(1499.0));
      expect(result.itemTitle, contains('СОРОЧКА'));
      expect(result.date, isNotNull);
      expect(result.date!.year, equals(2026));
      expect(result.date!.month, equals(10));
      expect(result.date!.day, equals(19));
    });

    test('merges label and receipt into unified item for verification', () {
      final label = ClothingOcrService.parseLabelText('''
ZARA WOMAN
SIZE M / EUR 38
100% LINEN
MADE IN MOROCCO
WASH 30°C
''');

      final receipt = ClothingOcrService.parseReceiptText('''
ZARA УКРАЇНА
СУМА: 1 499.00 UAH
''');

      final merged = ClothingOcrService.mergeInsights(
        labelData: label,
        receiptData: receipt,
        itemPhotoUrl: 'https://example.com/item.jpg',
        labelPhotoUrl: 'https://example.com/label.jpg',
        receiptPhotoUrl: 'https://example.com/receipt.jpg',
      );

      expect(merged.brand, equals('Zara'));
      expect(merged.price, equals(1499.0));
      expect(merged.size, contains('38'));
      expect(merged.fabricComposition, contains('LINEN'));
      expect(merged.countryOfOrigin, contains('Morocco'));
      expect(merged.storeName, contains('Zara'));
      expect(merged.itemPhoto, equals('https://example.com/item.jpg'));
      expect(merged.detectedFromLabel.containsKey('Бренд'), isTrue);
      expect(merged.detectedFromReceipt.containsKey('Ціна'), isTrue);
    });

    test('sample presets are all non-empty and valid', () {
      final presets = ClothingOcrService.samplePresets;
      expect(presets.length, greaterThanOrEqualTo(3));
      for (final p in presets) {
        expect(p.name.isNotEmpty, isTrue);
        expect(p.rawLabelText.isNotEmpty, isTrue);
        expect(p.rawReceiptText.isNotEmpty, isTrue);
      }
    });
  });
}
