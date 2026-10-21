import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wardrobe/services/url_parser_service.dart';

void main() {
  group('UrlParserService Multi-Store Tests', () {
    test('Correctly identifies Ukrainian and Global stores by domain', () {
      expect(UrlParserService.detectStore('https://kasta.ua/product/123').name, 'Kasta');
      expect(UrlParserService.detectStore('https://intertop.ua/ua/product/456').name, 'Intertop');
      expect(UrlParserService.detectStore('https://altamen.com.ua/sorochki/sorochka-lon-bila').name, 'AltaMen');
      expect(UrlParserService.detectStore('https://answear.ua/p/789').name, 'Answear');
      expect(UrlParserService.detectStore('https://shafa.ua/women/shoes/101').name, 'Shafa');
      expect(UrlParserService.detectStore('https://rozetka.com.ua/shoes/p202/').name, 'Rozetka');
      expect(UrlParserService.detectStore('https://www.zara.com/ua/uk/dress-p01').name, 'Zara');
      expect(UrlParserService.detectStore('https://www.asos.com/prd/2045').name, 'ASOS');
      expect(UrlParserService.detectStore('https://www.nike.com/ua/t/air-force-1').name, 'Nike');
    });

    test('Identifies store countries correctly', () {
      expect(UrlParserService.detectStore('https://altamen.com.ua/item').country, 'UA');
      expect(UrlParserService.detectStore('https://kasta.ua/item').country, 'UA');
      expect(UrlParserService.detectStore('https://intertop.ua/item').country, 'UA');
      expect(UrlParserService.detectStore('https://www.zara.com/item').country, 'EU');
      expect(UrlParserService.detectStore('https://www.nike.com/item').country, 'US');
    });

    test('Parses Altamen linen shirt URL gracefully without throwing CORS or fetch error', () async {
      final result = await UrlParserService.parseProductUrl('https://altamen.com.ua/sorochki/sorochka-lon-bila');
      expect(result, isNotNull);
      expect(result!.title.toLowerCase(), contains('сорочка'));
      expect(result.brand.toLowerCase(), contains('alta'));
      expect(result.color, equals('Білий'));
      expect(result.fabricComposition?.toLowerCase(), contains('льон'));
    });
  });
}
