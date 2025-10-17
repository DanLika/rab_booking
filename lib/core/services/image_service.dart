import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Service for optimized image loading with caching and progressive loading
class ImageService {
  /// Display an optimized cached network image with shimmer placeholder
  static Widget optimizedImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
  }) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        // Memory cache optimization - resize in memory
        memCacheWidth: width?.toInt(),
        memCacheHeight: height?.toInt(),
        // Shimmer placeholder for better UX
        placeholder: (context, url) => Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            width: width,
            height: height,
            color: Colors.white,
          ),
        ),
        // Error widget
        errorWidget: (context, url, error) => Container(
          width: width,
          height: height,
          color: Colors.grey[200],
          child: const Icon(
            Icons.broken_image,
            color: Colors.grey,
            size: 48,
          ),
        ),
        // Smooth fade-in animation
        fadeInDuration: const Duration(milliseconds: 300),
        fadeOutDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  /// Get thumbnail URL for Supabase Storage with transformations
  /// Supabase Storage supports URL-based transformations
  static String getThumbnailUrl(
    String originalUrl, {
    int width = 300,
    int quality = 80,
  }) {
    // Check if URL is from Supabase Storage
    if (originalUrl.contains('supabase')) {
      // Supabase Storage transformation parameters
      // Format: ?width=300&quality=80
      final uri = Uri.parse(originalUrl);
      final newParams = Map<String, dynamic>.from(uri.queryParameters);
      newParams['width'] = width.toString();
      newParams['quality'] = quality.toString();

      return uri.replace(queryParameters: newParams).toString();
    }

    // For other CDNs, return original URL
    return originalUrl;
  }

  /// Get optimized URL for list views (smaller thumbnails)
  static String getListThumbnail(String originalUrl) {
    return getThumbnailUrl(originalUrl, width: 400, quality: 75);
  }

  /// Get optimized URL for detail views (larger images)
  static String getDetailImage(String originalUrl) {
    return getThumbnailUrl(originalUrl, width: 1200, quality: 85);
  }

  /// Precache multiple images for better performance
  /// Useful before navigating to image-heavy screens
  static Future<void> precacheImages(
    BuildContext context,
    List<String> imageUrls,
  ) async {
    for (final url in imageUrls) {
      try {
        await precacheImage(
          CachedNetworkImageProvider(url),
          context,
        );
      } catch (e) {
        // Silently fail - precaching is not critical
        debugPrint('Failed to precache image: $url');
      }
    }
  }

  /// Optimized image for property cards in list views
  static Widget propertyCardImage({
    required String imageUrl,
    double height = 200,
  }) {
    return optimizedImage(
      imageUrl: getListThumbnail(imageUrl),
      width: double.infinity,
      height: height,
      fit: BoxFit.cover,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
    );
  }

  /// Optimized image for property detail screens
  static Widget propertyDetailImage({
    required String imageUrl,
    double? height,
  }) {
    return optimizedImage(
      imageUrl: getDetailImage(imageUrl),
      width: double.infinity,
      height: height,
      fit: BoxFit.cover,
    );
  }

  /// Hero image with optimized loading
  /// Used for smooth transitions between list and detail views
  static Widget heroImage({
    required String tag,
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
  }) {
    return Hero(
      tag: tag,
      child: optimizedImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        borderRadius: borderRadius,
      ),
    );
  }

  /// Avatar image with circular clip
  static Widget avatarImage({
    required String imageUrl,
    double size = 40,
  }) {
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        memCacheWidth: size.toInt(),
        memCacheHeight: size.toInt(),
        placeholder: (context, url) => Container(
          width: size,
          height: size,
          color: Colors.grey[300],
          child: Icon(
            Icons.person,
            size: size * 0.6,
            color: Colors.grey[600],
          ),
        ),
        errorWidget: (context, url, error) => Container(
          width: size,
          height: size,
          color: Colors.grey[300],
          child: Icon(
            Icons.person,
            size: size * 0.6,
            color: Colors.grey[600],
          ),
        ),
      ),
    );
  }

  /// Clear image cache - useful for troubleshooting or when storage is low
  static Future<void> clearCache() async {
    await CachedNetworkImage.evictFromCache('');
  }

  /// Clear specific image from cache
  static Future<void> clearImageFromCache(String imageUrl) async {
    await CachedNetworkImage.evictFromCache(imageUrl);
  }
}
