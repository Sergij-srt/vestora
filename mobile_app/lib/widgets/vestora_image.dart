import 'dart:collection';
import 'dart:convert';
import 'dart:io' as io;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Universal high-performance image widget for Vestora.
/// - Supports `data:image/...;base64,...` inline photos on BOTH Web and Mobile via a bounded LRU `Uint8List` cache.
/// - Applies DPI-aware `cacheWidth` / `memCacheWidth` bounds on finite thumbnail dimensions to prevent GPU/RAM bloat.
/// - Exposes accessible [semanticLabel] for screen readers.
class VestoraImage extends StatelessWidget {
  static const int maxMemoryCacheEntries = 60;
  static final LinkedHashMap<String, Uint8List> _base64LruCache = LinkedHashMap<String, Uint8List>();

  static int get memoryCacheSize => _base64LruCache.length;

  static void clearMemoryCache() => _base64LruCache.clear();

  /// Decodes a `data:image/...;base64,...` URI once and caches it in a bounded LRU map.
  static Uint8List? decodeDataUriCached(String dataUri) {
    final existing = _base64LruCache.remove(dataUri);
    if (existing != null) {
      // Re-insert as most-recently-used
      _base64LruCache[dataUri] = existing;
      return existing;
    }

    final commaIndex = dataUri.indexOf(',');
    if (commaIndex == -1 || commaIndex + 1 >= dataUri.length) {
      return null;
    }

    try {
      final rawBase64 = dataUri.substring(commaIndex + 1).trim();
      final bytes = base64Decode(rawBase64);
      if (bytes.isEmpty) return null;

      if (_base64LruCache.length >= maxMemoryCacheEntries) {
        _base64LruCache.remove(_base64LruCache.keys.first);
      }
      _base64LruCache[dataUri] = bytes;
      return bytes;
    } catch (_) {
      return null;
    }
  }

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget Function(BuildContext, String)? placeholder;
  final Widget Function(BuildContext, String, dynamic)? errorWidget;
  final BorderRadius? borderRadius;
  final String? semanticLabel;

  const VestoraImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.semanticLabel,
  });

  int? _computeTargetCacheWidth(BuildContext context) {
    if (kIsWeb) return null; // Web Image.memory does not support ResizeImage cacheWidth
    final w = width;
    final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 2.0;
    if (w != null && w.isFinite && w > 0) {
      final scaled = (w * dpr).round();
      if (scaled <= 0) return null;
      return scaled.clamp(64, 1600);
    }
    if (w == double.infinity) {
      final viewportW = MediaQuery.maybeSizeOf(context)?.width ?? 600.0;
      final scaled = (viewportW * dpr).round();
      if (scaled <= 0) return null;
      return scaled.clamp(128, 1600);
    }
    return null;
  }

  int? _computeTargetCacheHeight(BuildContext context, int? resolvedCacheWidth) {
    if (kIsWeb) return null; // Web Image.memory does not support ResizeImage cacheHeight
    if (resolvedCacheWidth != null) {
      // Only set one decode dimension so Flutter preserves original aspect ratio without stretching
      return null;
    }
    final h = height;
    if (h == null || !h.isFinite || h <= 0) return null;
    final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 2.0;
    final scaled = (h * dpr).round();
    if (scaled <= 0) return null;
    return scaled.clamp(64, 1600);
  }

  Widget _buildFallbackError(BuildContext context, dynamic error) {
    if (errorWidget != null) return errorWidget!(context, imageUrl, error);
    return Container(
      width: width,
      height: height,
      color: const Color(0xFF27272A),
      child: const Center(
        child: Icon(Icons.broken_image_rounded, color: AppTheme.darkMuted, size: 24),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final targetCacheWidth = _computeTargetCacheWidth(context);
    final targetCacheHeight = _computeTargetCacheHeight(context, targetCacheWidth);
    Widget image;

    if (imageUrl.trim().isEmpty) {
      image = _buildFallbackError(context, 'Empty imageUrl');
    } else if (imageUrl.startsWith('data:image/')) {
      final bytes = decodeDataUriCached(imageUrl);
      if (bytes == null) {
        image = _buildFallbackError(context, 'Malformed data URI');
      } else {
        image = Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          gaplessPlayback: true,
          cacheWidth: targetCacheWidth,
          cacheHeight: targetCacheHeight,
          errorBuilder: (ctx, err, _) => _buildFallbackError(ctx, err),
        );
      }
    } else if (kIsWeb) {
      image = Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        cacheWidth: targetCacheWidth,
        cacheHeight: targetCacheHeight,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          if (placeholder != null) return placeholder!(context, imageUrl);
          return Container(
            width: width,
            height: height,
            color: const Color(0xFF27272A),
            child: const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accent),
              ),
            ),
          );
        },
        errorBuilder: (ctx, error, _) => _buildFallbackError(ctx, error),
      );
    } else if (imageUrl.startsWith('/') ||
        imageUrl.startsWith('file://') ||
        RegExp(r'^[a-zA-Z]:[/\\]').hasMatch(imageUrl)) {
      final cleanPath = imageUrl.startsWith('file://') ? Uri.parse(imageUrl).toFilePath() : imageUrl;
      image = Image.file(
        io.File(cleanPath),
        width: width,
        height: height,
        fit: fit,
        cacheWidth: targetCacheWidth,
        cacheHeight: targetCacheHeight,
        errorBuilder: (ctx, err, _) => _buildFallbackError(ctx, err),
      );
    } else {
      image = CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        memCacheWidth: targetCacheWidth,
        memCacheHeight: targetCacheHeight,
        placeholder: placeholder != null
            ? (ctx, url) => placeholder!(ctx, url)
            : (ctx, url) => Container(
                  width: width,
                  height: height,
                  color: const Color(0xFF27272A),
                  child: const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accent),
                    ),
                  ),
                ),
        errorWidget: (ctx, url, err) => _buildFallbackError(ctx, err),
      );
    }

    if (borderRadius != null) {
      image = ClipRRect(borderRadius: borderRadius!, child: image);
    }

    if (semanticLabel != null && semanticLabel!.isNotEmpty) {
      return Semantics(
        image: true,
        label: semanticLabel,
        excludeSemantics: true,
        child: image,
      );
    }
    return image;
  }
}

final Uint8List _kTransparentPixelPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
);

/// Helper to get the optimal ImageProvider across Web, Mobile, and inline Base64 Data URIs.
ImageProvider vestoraImageProvider(String url) {
  final clean = url.trim();
  if (clean.isEmpty) {
    return MemoryImage(_kTransparentPixelPng);
  }
  if (clean.startsWith('data:image/')) {
    final bytes = VestoraImage.decodeDataUriCached(clean);
    if (bytes != null) {
      return MemoryImage(bytes);
    }
    return MemoryImage(_kTransparentPixelPng);
  }
  if (!kIsWeb &&
      (clean.startsWith('/') ||
          clean.startsWith('file://') ||
          RegExp(r'^[a-zA-Z]:[/\\]').hasMatch(clean))) {
    final cleanPath = clean.startsWith('file://') ? Uri.parse(clean).toFilePath() : clean;
    return FileImage(io.File(cleanPath));
  }
  if (kIsWeb) {
    return NetworkImage(clean);
  }
  return CachedNetworkImageProvider(clean);
}
