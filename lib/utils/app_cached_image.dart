import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// High-performance cached image widget with disk caching, memory bounds,
/// smooth fade-in, and skeleton loading placeholder.
class AppCachedImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final int? maxDiskCacheWidth;
  final int? maxDiskCacheHeight;
  final Alignment alignment;

  const AppCachedImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.memCacheWidth = 800,
    this.memCacheHeight = 800,
    this.maxDiskCacheWidth = 1200,
    this.maxDiskCacheHeight = 1200,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final cleanUrl = imageUrl.trim();

    if (cleanUrl.isEmpty || !cleanUrl.startsWith('http')) {
      return _buildError(context);
    }

    Widget image = CachedNetworkImage(
      imageUrl: cleanUrl,
      fit: fit,
      width: width,
      height: height,
      alignment: alignment,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      maxWidthDiskCache: maxDiskCacheWidth,
      maxHeightDiskCache: maxDiskCacheHeight,
      fadeInDuration: const Duration(milliseconds: 250),
      fadeOutDuration: const Duration(milliseconds: 150),
      placeholder: (context, url) => placeholder ?? _buildSkeletonPlaceholder(context),
      errorWidget: (context, url, error) => errorWidget ?? _buildError(context),
    );

    if (borderRadius != null && borderRadius != BorderRadius.zero) {
      image = ClipRRect(
        borderRadius: borderRadius!,
        child: image,
      );
    }

    return image;
  }

  Widget _buildSkeletonPlaceholder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF0F382A) : Colors.grey.shade300;
    final highlightColor = isDark ? const Color(0xFF1E5240) : Colors.grey.shade100;

    return Skeletonizer(
      enabled: true,
      containersColor: baseColor,
      effect: ShimmerEffect(
        baseColor: baseColor,
        highlightColor: highlightColor,
        duration: const Duration(milliseconds: 1200),
      ),
      child: Bone(
        width: width ?? double.infinity,
        height: height ?? double.infinity,
        borderRadius: borderRadius ?? BorderRadius.zero,
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Widget errorContent = Container(
      width: width,
      height: height,
      color: isDark ? const Color(0xFF14241E) : Colors.grey.shade200,
      child: Center(
        child: Icon(
          Icons.broken_image_outlined,
          size: (height != null && height! < 50) ? 20 : 36,
          color: isDark ? Colors.white38 : Colors.grey.shade500,
        ),
      ),
    );

    if (borderRadius != null && borderRadius != BorderRadius.zero) {
      errorContent = ClipRRect(
        borderRadius: borderRadius!,
        child: errorContent,
      );
    }

    return errorContent;
  }
}

/// Helper for prefetching and pre-caching remote images in the background.
class AppImageCache {
  /// Pre-cache a list of image URLs proactively in memory and disk cache.
  static void precache(BuildContext context, Iterable<String?> urls) {
    for (final rawUrl in urls) {
      precacheSingle(context, rawUrl);
    }
  }

  /// Pre-cache a single image URL into memory and disk cache safely.
  static void precacheSingle(BuildContext context, String? rawUrl) {
    if (rawUrl == null) return;
    final url = rawUrl.trim();
    if (url.isEmpty || !url.startsWith('http')) return;

    try {
      precacheImage(
        CachedNetworkImageProvider(url),
        context,
        onError: (exception, stackTrace) {
          // Silently fail if device is offline or image URL is expired
        },
      );
    } catch (_) {}
  }
}
