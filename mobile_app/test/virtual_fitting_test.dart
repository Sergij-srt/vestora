import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wardrobe/models/clothing_item.dart';
import 'package:smart_wardrobe/services/virtual_fitting_service.dart';

void main() {
  group('VirtualFittingService Tests', () {
    final mockItems = [
      ClothingItem(
        id: 'top-1',
        title: 'Лляна сорочка AltaMen',
        brand: 'AltaMen',
        category: ClothingCategory.tops,
        color: 'Молочний',
        season: Season.allSeason,
        price: 1850,
        imageUrl: 'https://example.com/shirt.jpg',
        fabricComposition: '100% Льон',
      ),
      ClothingItem(
        id: 'bot-1',
        title: 'Класичні брюки палаццо',
        brand: 'Zara',
        category: ClothingCategory.bottoms,
        color: 'Сірий',
        season: Season.allSeason,
        price: 2100,
        imageUrl: 'https://example.com/pants.jpg',
        fabricComposition: '100% Вовна',
      ),
      ClothingItem(
        id: 'shoe-1',
        title: 'Шкіряні лофери',
        brand: 'Vagabond',
        category: ClothingCategory.shoes,
        color: 'Чорний',
        season: Season.allSeason,
        price: 3400,
        imageUrl: 'https://example.com/shoes.jpg',
      ),
    ];

    test('Provides curated preset face models and backgrounds', () {
      expect(VirtualFittingService.presetFaces.length, greaterThanOrEqualTo(4));
      expect(VirtualFittingService.presetFaces.first.name, 'Олена');
      expect(TryOnBackground.values.length, 3);
      expect(TryOnModelSilhouette.values.length, 3);
    });

    test('Evaluates fitting with heuristic engine accurately', () async {
      final result = await VirtualFittingService.evaluateFitting(
        faceUrl: VirtualFittingService.presetFaces.first.faceUrl,
        outfitItems: mockItems,
        silhouette: TryOnModelSilhouette.femaleChic,
        background: TryOnBackground.luxuryBoutique,
      );

      expect(result.overallFitScore, greaterThanOrEqualTo(9.0));
      expect(result.skinToneHarmony, isNotEmpty);
      expect(result.necklineFit, isNotEmpty);
      expect(result.silhouetteBalance, isNotEmpty);
      expect(result.stylistTip, isNotEmpty);
      expect(result.usedGemini, isFalse);
    });

    test('Handles empty wardrobe items gracefully in fitting', () async {
      final result = await VirtualFittingService.evaluateFitting(
        faceUrl: VirtualFittingService.presetFaces.first.faceUrl,
        outfitItems: [],
        silhouette: TryOnModelSilhouette.maleTailored,
        background: TryOnBackground.studioMinimal,
      );

      expect(result.overallFitScore, 8.5);
      expect(result.stylistTip, contains('Додайте топ або сорочку'));
    });
  });
}
