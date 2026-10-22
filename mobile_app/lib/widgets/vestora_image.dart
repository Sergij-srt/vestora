import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';

/// Universal high-performance image widget for Vestora.
/// On Web: utilizes browser native `Image.network` to avoid IndexedDB / CanvasKit cache corruption.
/// On Mobile: utilizes `CachedNetworkImage` for disk persistence.
class VestoraImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget Function(BuildContext, String)? placeholder;
  final Widget Function(BuildContext, String, dynamic)? errorWidget;
  final BorderRadius? borderRadius;

  const VestoraImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    Widget image;

    if (kIsWeb) {
      image = Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
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
        errorBuilder: (context, error, stackTrace) {
          if (errorWidget != null) return errorWidget!(context, imageUrl, error);
          return Container(
            width: width,
            height: height,
            color: const Color(0xFF27272A),
            child: const Center(
              child: Icon(Icons.broken_image_rounded, color: AppTheme.muted, size: 24),
            ),
          );
        },
      );
    } else {
      image = CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
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
        errorWidget: errorWidget != null
            ? (ctx, url, err) => errorWidget!(ctx, url, err)
            : (ctx, url, err) => Container(
                  width: width,
                  height: height,
                  color: const Color(0xFF27272A),
                  child: const Center(
                    child: Icon(Icons.broken_image_rounded, color: AppTheme.muted, size: 24),
                  ),
                ),
      );
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: image);
    }
    return image;
  }
}

/// Helper to get the optimal ImageProvider across Web and Mobile
ImageProvider vestoraImageProvider(String url) {
  if (kIsWeb) {
    return NetworkImage(url);
  }
  return CachedNetworkImageProvider(url);
}
