import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Service for optimized image loading with caching and progressive loading
/// Enhanced with memory optimization and preloading
class ImageService {
  /// Preload images for better performance
  static Future<void> preloadImages(
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
        // Ignore preload errors
      }
    }
  }

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

  /// Upload property images to Supabase Storage
  /// Returns list of public URLs for the uploaded images
  static Future<List<String>> uploadPropertyImages(
    List<XFile> images, {
    required String propertyId,
    Function(int current, int total)? onProgress,
  }) async {
    final supabase = Supabase.instance.client;
    final uploadedUrls = <String>[];

    for (var i = 0; i < images.length; i++) {
      try {
        onProgress?.call(i + 1, images.length);

        final file = images[i];
        final bytes = await file.readAsBytes();
        final fileExt = file.name.split('.').last;
        final fileName = '${const Uuid().v4()}.$fileExt';
        final filePath = 'properties/$propertyId/$fileName';

        // Upload to Supabase Storage
        await supabase.storage.from('property-images').uploadBinary(
              filePath,
              bytes,
              fileOptions: FileOptions(
                contentType: _getContentType(fileExt),
                upsert: false,
              ),
            );

        // Get public URL
        final publicUrl = supabase.storage.from('property-images').getPublicUrl(filePath);

        uploadedUrls.add(publicUrl);
        debugPrint('✅ Uploaded image ${i + 1}/${images.length}: $fileName');
      } catch (e) {
        debugPrint('❌ Failed to upload image ${i + 1}: $e');
        rethrow;
      }
    }

    return uploadedUrls;
  }

  /// Upload a single image to Supabase Storage
  /// Returns the public URL for the uploaded image
  static Future<String> uploadSingleImage(
    XFile image, {
    required String bucket,
    required String folder,
  }) async {
    final supabase = Supabase.instance.client;

    try {
      final bytes = await image.readAsBytes();
      final fileExt = image.name.split('.').last;
      final fileName = '${const Uuid().v4()}.$fileExt';
      final filePath = '$folder/$fileName';

      // Upload to Supabase Storage
      await supabase.storage.from(bucket).uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(
              contentType: _getContentType(fileExt),
              upsert: false,
            ),
          );

      // Get public URL
      final publicUrl = supabase.storage.from(bucket).getPublicUrl(filePath);

      debugPrint('✅ Uploaded image: $fileName');
      return publicUrl;
    } catch (e) {
      debugPrint('❌ Failed to upload image: $e');
      rethrow;
    }
  }

  /// Delete image from Supabase Storage
  static Future<void> deleteImage(String imageUrl) async {
    final supabase = Supabase.instance.client;

    try {
      // Extract file path from URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;

      // Find the bucket name and file path
      // URL format: https://[project].supabase.co/storage/v1/object/public/[bucket]/[path]
      final bucketIndex = pathSegments.indexOf('public') + 1;
      if (bucketIndex < pathSegments.length) {
        final bucket = pathSegments[bucketIndex];
        final filePath = pathSegments.sublist(bucketIndex + 1).join('/');

        await supabase.storage.from(bucket).remove([filePath]);
        debugPrint('✅ Deleted image: $filePath');
      }
    } catch (e) {
      debugPrint('❌ Failed to delete image: $e');
      // Don't rethrow - deletion failures shouldn't block operations
    }
  }

  /// Delete multiple images from Supabase Storage
  static Future<void> deleteImages(List<String> imageUrls) async {
    for (final url in imageUrls) {
      await deleteImage(url);
    }
  }

  /// Get content type from file extension
  static String _getContentType(String fileExt) {
    switch (fileExt.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      default:
        return 'image/jpeg'; // Default fallback
    }
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
