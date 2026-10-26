import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/clothing_item.dart';
import 'clothing_ocr_service.dart';
import 'ai_config_service.dart';

class GeminiVisionAnalysisResult {
  final bool isSuccess;
  final OcrCombinedResult? data;
  final String? errorMessage;
  final bool usedGemini;
  final String modelUsed;

  GeminiVisionAnalysisResult({
    required this.isSuccess,
    this.data,
    this.errorMessage,
    required this.usedGemini,
    this.modelUsed = 'gemini-2.5-flash',
  });
}

class GeminiVisionService {
  /// Analyzes clothing, label, and receipt photos using Google Gemini Vision API.
  /// Falls back to local algorithmic parser if API key is missing or call fails.
  static Future<GeminiVisionAnalysisResult> analyzePhotos({
    String? clothingPhotoUrl,
    String? labelPhotoUrl,
    String? receiptPhotoUrl,
    String? rawLabelText,
    String? rawReceiptText,
    String? overrideApiKey,
    http.Client? httpClient,
  }) async {
    final apiKey = (overrideApiKey ?? AiConfigService.apiKey)?.trim();

    // If no API key configured, use local parser
    if (apiKey == null || apiKey.isEmpty) {
      final localResult = _runLocalFallback(
        clothingPhotoUrl: clothingPhotoUrl,
        labelPhotoUrl: labelPhotoUrl,
        receiptPhotoUrl: receiptPhotoUrl,
        rawLabelText: rawLabelText,
        rawReceiptText: rawReceiptText,
      );

      final hasTextHint = (rawLabelText != null && rawLabelText.trim().isNotEmpty) ||
          (rawReceiptText != null && rawReceiptText.trim().isNotEmpty);

      return GeminiVisionAnalysisResult(
        isSuccess: true,
        data: localResult,
        usedGemini: false,
        modelUsed: hasTextHint ? 'Локальний парсер тексту' : 'Локальний режим (без ШІ)',
      );
    }

    final client = httpClient ?? http.Client();
    try {
      final parts = <Map<String, dynamic>>[];

      // 1. Prompt instructions
      final prompt = '''
You are an expert luxury fashion archivist, garments specialist, and fiscal receipt auditor.
Analyze the provided photos (clothing item, inner care label/tag, and purchase receipt).

Extract and return ONLY a valid JSON object matching this structure:
{
  "title": "string (Short descriptive Ukrainian title, e.g. 'Бежевий вовняний жакет')",
  "brand": "string (Brand name, e.g. 'Massimo Dutti', 'Zara', 'COS', 'Levi\\'s', or 'Невідомий бренд')",
  "category": "string (Must be one of: 'outerwear', 'tops', 'bottoms', 'dresses', 'shoes', 'accessories')",
  "color": "string (Dominant color in Ukrainian, e.g. 'Бежевий', 'Чорний', 'Білий')",
  "price": double (Price number as float, e.g. 4499.0. If unknown or not on receipt, estimate 0.0),
  "currency": "string (e.g. 'UAH', 'EUR', 'USD')",
  "size": "string (Size from label, e.g. 'EUR 38 / US S', 'M', 'W30/L32')",
  "fabricComposition": "string (Exact fabric percentages from tag, e.g. '100% Вовна' or '98% Бавовна, 2% Еластан')",
  "careInstructions": "string (Care instructions from symbols/text, e.g. 'Делікатне прання 30°C · Хімчистка')",
  "countryOfOrigin": "string (e.g. 'Made in Portugal', 'Made in Morocco', 'Made in Italy')",
  "season": "string (Must be one of: 'allSeason', 'summer', 'winter', 'spring', 'autumn')",
  "storeName": "string (Store name from receipt or brand, e.g. 'Massimo Dutti')",
  "aiSummary": "string (1-2 sentences in Ukrainian summarizing the item style, silhouette, and fabric quality)"
}

${rawLabelText != null && rawLabelText.isNotEmpty ? 'Label OCR text hint: $rawLabelText\n' : ''}
${rawReceiptText != null && rawReceiptText.isNotEmpty ? 'Receipt OCR text hint: $rawReceiptText\n' : ''}
''';

      parts.add({'text': prompt});

      // 2. Attach images as base64 inline data if possible
      await _appendImagePart(parts, clothingPhotoUrl, 'Photo 1 (Clothing item)', client: client);
      await _appendImagePart(parts, labelPhotoUrl, 'Photo 2 (Care tag / label)', client: client);
      await _appendImagePart(parts, receiptPhotoUrl, 'Photo 3 (Purchase receipt)', client: client);

      final modelName = AiConfigService.preferredModel;
      final requestBody = jsonEncode({
        'contents': [
          {'parts': parts}
        ],
        'generationConfig': {
          'response_mime_type': 'application/json',
          'temperature': 0.2,
        },
      });

      http.Response? response;

      // 1. On Web, attempt routing through server-side /api/ai/vision proxy to protect keys & bypass CORS
      if (kIsWeb) {
        // Option A: relative proxy URI (same-origin server in production)
        try {
          final proxyUri = Uri.parse('/api/ai/vision?model=$modelName');
          final res = await client
              .post(
                proxyUri,
                headers: {
                  'Content-Type': 'application/json',
                  'x-goog-api-key': apiKey,
                },
                body: requestBody,
              )
              .timeout(const Duration(seconds: 25));
          if (res.statusCode == 200) {
            response = res;
          }
        } catch (_) {}

        // Option B: absolute local proxy server (dev server on port 8080)
        if (response == null) {
          try {
            final proxyUri = Uri.parse('http://127.0.0.1:8080/api/ai/vision?model=$modelName');
            final res = await client
                .post(
                  proxyUri,
                  headers: {
                    'Content-Type': 'application/json',
                    'x-goog-api-key': apiKey,
                  },
                  body: requestBody,
                )
                .timeout(const Duration(seconds: 25));
            if (res.statusCode == 200) {
              response = res;
            }
          } catch (_) {}
        }
      }

      // 2. Direct upstream Gemini call (Native mobile or Web direct fallback)
      if (response == null) {
        final endpoint = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent',
        );

        response = await client
            .post(
              endpoint,
              headers: {
                'Content-Type': 'application/json',
                'x-goog-api-key': apiKey,
              },
              body: requestBody,
            )
            .timeout(const Duration(seconds: 25));
      }

      if (response.statusCode != 200) {
        if (kDebugMode) {
          debugPrint(
            'Gemini Vision API error: ${response.statusCode} - ${AiConfigService.redactSecrets(response.body, apiKey)}',
          );
        }
        // Fallback to local parser with warning
        final fallback = _runLocalFallback(
          clothingPhotoUrl: clothingPhotoUrl,
          labelPhotoUrl: labelPhotoUrl,
          receiptPhotoUrl: receiptPhotoUrl,
          rawLabelText: rawLabelText,
          rawReceiptText: rawReceiptText,
        );
        return GeminiVisionAnalysisResult(
          isSuccess: true,
          data: fallback,
          errorMessage: 'Gemini API повернув код ${response.statusCode}. Використано локальний парсер.',
          usedGemini: false,
          modelUsed: 'Local Fallback',
        );
      }

      final responseJson = jsonDecode(response.body);
      final candidates = responseJson['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        throw Exception('Gemini не надав відповіді');
      }

      final textContent = candidates[0]['content']?['parts']?[0]?['text'] as String?;
      if (textContent == null || textContent.isEmpty) {
        throw Exception('Порожня відповідь від Gemini');
      }

      // Parse JSON from model
      final cleanJsonText = _extractJsonSubstring(textContent);
      final parsed = jsonDecode(cleanJsonText) as Map<String, dynamic>;

      // Map to OcrCombinedResult
      final category = _parseCategory(parsed['category']?.toString());
      final season = _parseSeason(parsed['season']?.toString());
      final price = (parsed['price'] is num) ? (parsed['price'] as num).toDouble() : 0.0;

      final combined = OcrCombinedResult(
        title: parsed['title']?.toString() ?? 'Одяг з фото',
        brand: parsed['brand']?.toString() ?? 'Бренд не визначено',
        category: category,
        season: season,
        color: parsed['color']?.toString() ?? 'Нейтральний',
        price: price,
        currency: parsed['currency']?.toString() ?? 'UAH',
        size: parsed['size']?.toString(),
        fabricComposition: parsed['fabricComposition']?.toString(),
        careInstructions: parsed['careInstructions']?.toString(),
        countryOfOrigin: parsed['countryOfOrigin']?.toString(),
        storeName: parsed['storeName']?.toString(),
        itemPhoto: clothingPhotoUrl,
        labelPhoto: labelPhotoUrl,
        receiptPhoto: receiptPhotoUrl,
        detectedFromLabel: {
          if (parsed['brand'] != null) 'Бренд': parsed['brand'].toString(),
          if (parsed['size'] != null) 'Розмір': parsed['size'].toString(),
          if (parsed['fabricComposition'] != null) 'Склад': parsed['fabricComposition'].toString(),
          if (parsed['countryOfOrigin'] != null) 'Країна': parsed['countryOfOrigin'].toString(),
          if (parsed['careInstructions'] != null) 'Догляд': parsed['careInstructions'].toString(),
        },
        detectedFromReceipt: {
          if (parsed['storeName'] != null) 'Магазин': parsed['storeName'].toString(),
          if (price > 0) 'Ціна': '${price.toStringAsFixed(0)} ${parsed['currency'] ?? 'UAH'}',
        },
      );

      // Successfully consumed a credit if in rewarded ad mode
      await AiConfigService.consumeScanCredit();

      return GeminiVisionAnalysisResult(
        isSuccess: true,
        data: combined,
        usedGemini: true,
        modelUsed: modelName,
      );
    } catch (e) {
      final safeErr = AiConfigService.redactSecrets(e.toString(), apiKey);
      if (kDebugMode) {
        debugPrint('GeminiVisionService exception: $safeErr');
      }
      final fallback = _runLocalFallback(
        clothingPhotoUrl: clothingPhotoUrl,
        labelPhotoUrl: labelPhotoUrl,
        receiptPhotoUrl: receiptPhotoUrl,
        rawLabelText: rawLabelText,
        rawReceiptText: rawReceiptText,
      );
      return GeminiVisionAnalysisResult(
        isSuccess: true,
        data: fallback,
        errorMessage: 'Помилка Gemini API: $safeErr. Застосовано резервний парсер.',
        usedGemini: false,
        modelUsed: 'Local Fallback',
      );
    } finally {
      if (httpClient == null) {
        client.close();
      }
    }
  }

  /// Appends image to Gemini parts if valid
  static Future<void> _appendImagePart(
    List<Map<String, dynamic>> parts,
    String? photoUrl,
    String label, {
    http.Client? client,
  }) async {
    if (photoUrl == null || photoUrl.isEmpty) return;

    try {
      if (photoUrl.startsWith('http://') || photoUrl.startsWith('https://')) {
        final res = await (client != null
                ? client.get(Uri.parse(photoUrl))
                : http.get(Uri.parse(photoUrl)))
            .timeout(const Duration(seconds: 8));
        if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
          final base64Img = base64Encode(res.bodyBytes);
          final mime = _guessMimeType(photoUrl, res.headers['content-type']);
          parts.add({
            'inline_data': {
              'mime_type': mime,
              'data': base64Img,
            }
          });
          return;
        }
      } else if (photoUrl.startsWith('data:image/')) {
        final commaIdx = photoUrl.indexOf(',');
        if (commaIdx != -1) {
          final meta = photoUrl.substring(5, commaIdx);
          final mime = meta.split(';').first;
          final base64Img = photoUrl.substring(commaIdx + 1);
          parts.add({
            'inline_data': {
              'mime_type': mime,
              'data': base64Img,
            }
          });
          return;
        }
      } else if (!kIsWeb && (photoUrl.startsWith('/') || photoUrl.startsWith('file://') || RegExp(r'^[a-zA-Z]:[/\\]').hasMatch(photoUrl))) {
        final cleanPath = photoUrl.startsWith('file://') ? Uri.parse(photoUrl).toFilePath() : photoUrl;
        final file = io.File(cleanPath);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          if (bytes.isNotEmpty) {
            final base64Img = base64Encode(bytes);
            final mime = _guessMimeType(cleanPath, null);
            parts.add({
              'inline_data': {
                'mime_type': mime,
                'data': base64Img,
              }
            });
            return;
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to fetch image bytes for $photoUrl: ${AiConfigService.redactSecrets(e.toString())}');
      }
    }

    // If binary download fails or is skipped, mention photo context textually
    parts.add({'text': '$label: $photoUrl'});
  }

  static String _guessMimeType(String url, String? contentType) {
    if (contentType != null && contentType.startsWith('image/')) {
      return contentType.split(';').first.trim();
    }
    final lower = url.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  static String _extractJsonSubstring(String text) {
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start != -1 && end != -1 && end > start) {
      return text.substring(start, end + 1);
    }
    return text.trim();
  }

  static ClothingCategory _parseCategory(String? catStr) {
    switch (catStr?.toLowerCase().trim()) {
      case 'outerwear':
        return ClothingCategory.outerwear;
      case 'tops':
        return ClothingCategory.tops;
      case 'bottoms':
        return ClothingCategory.bottoms;
      case 'dresses':
        return ClothingCategory.dresses;
      case 'shoes':
        return ClothingCategory.shoes;
      case 'accessories':
        return ClothingCategory.accessories;
      default:
        return ClothingCategory.tops;
    }
  }

  static Season _parseSeason(String? sStr) {
    switch (sStr?.toLowerCase().trim()) {
      case 'summer':
        return Season.summer;
      case 'winter':
        return Season.winter;
      case 'spring':
        return Season.spring;
      case 'autumn':
        return Season.autumn;
      case 'springautumn':
      case 'demi':
        return Season.spring;
      default:
        return Season.allSeason;
    }
  }

  static OcrCombinedResult _runLocalFallback({
    String? clothingPhotoUrl,
    String? labelPhotoUrl,
    String? receiptPhotoUrl,
    String? rawLabelText,
    String? rawReceiptText,
  }) {
    ParsedLabelData? labelData;
    if (rawLabelText != null && rawLabelText.trim().isNotEmpty) {
      labelData = ClothingOcrService.parseLabelText(rawLabelText);
    }

    ParsedReceiptData? receiptData;
    if (rawReceiptText != null && rawReceiptText.trim().isNotEmpty) {
      receiptData = ClothingOcrService.parseReceiptText(rawReceiptText);
    }

    return ClothingOcrService.mergeInsights(
      labelData: labelData,
      receiptData: receiptData,
      itemPhotoUrl: clothingPhotoUrl ?? '',
      labelPhotoUrl: labelPhotoUrl,
      receiptPhotoUrl: receiptPhotoUrl,
    );
  }
}
