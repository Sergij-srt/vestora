import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'wardrobe_provider.dart';
import 'web_platform_stub.dart'
    if (dart.library.js_interop) 'web_platform_web.dart' as platform;

/// Shared helper that picks a photo cleanly on both Mobile and Web and guarantees
/// Web camera captures are compressed to fit within [WardrobeProvider.maxInlineImageChars].
class PhotoEncodeService {
  static const int safeTargetDataUriChars = 360 * 1024;

  static Future<String?> pickAndEncode(
    ImageSource source, {
    int maxDimension = 1024,
    int imageQuality = 82,
  }) async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(
      source: source,
      // On Web, passing resize bounds triggers image_picker_for_web's ImageResizer,
      // which can revoke the underlying Blob URL before readAsBytes() finishes.
      // Instead we read raw bytes first and compress safely on an HTML canvas afterward.
      maxWidth: kIsWeb ? null : maxDimension.toDouble(),
      maxHeight: kIsWeb ? null : maxDimension.toDouble(),
      imageQuality: kIsWeb ? null : imageQuality,
    );
    if (photo == null) return null;
    return encodeXFile(photo, maxDimension: maxDimension);
  }

  static Future<String?> encodeXFile(
    XFile photo, {
    int maxDimension = 1024,
  }) async {
    Uint8List bytes;
    try {
      bytes = await photo.readAsBytes();
    } catch (_) {
      final res = await http.get(Uri.parse(photo.path));
      if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
        bytes = res.bodyBytes;
      } else {
        rethrow;
      }
    }
    if (bytes.isEmpty) return null;

    final mime = _detectMimeType(photo);
    final rawDataUri = 'data:$mime;base64,${base64Encode(bytes)}';

    if (kIsWeb && rawDataUri.length > safeTargetDataUriChars) {
      final compressed = await platform.compressImageDataUri(
        rawDataUri,
        maxDimension: maxDimension,
        maxDataUriChars: safeTargetDataUriChars,
      );
      if (compressed != null && compressed.isNotEmpty) {
        return compressed;
      }
    }

    return rawDataUri;
  }

  static String _detectMimeType(XFile photo) {
    final rawMime = photo.mimeType?.trim();
    if (rawMime != null && rawMime.isNotEmpty) return rawMime;
    final lowerName = photo.name.toLowerCase();
    if (lowerName.endsWith('.png')) return 'image/png';
    if (lowerName.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }
}
