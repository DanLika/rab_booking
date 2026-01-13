import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Utility class for image optimization and handling.
///
/// This class provides methods to:
/// - Resize images client-side before upload to save bandwidth and storage.
/// - Provide standard dimensions for thumbnails and full images.
class ImageUtils {
  // Private constructor to prevent instantiation
  ImageUtils._();

  /// Standard max width for full uploaded images (Full HD)
  static const int kMaxUploadWidth = 1920;

  /// Standard max height for full uploaded images (Full HD)
  static const int kMaxUploadHeight = 1080;

  /// Standard width for thumbnails in lists
  static const int kThumbnailWidth = 300;

  /// Standard height for thumbnails in lists
  static const int kThumbnailHeight = 300;

  /// Resizes the image [bytes] to fit within [targetWidth] and [targetHeight].
  ///
  /// This uses [ui.instantiateImageCodec] which is efficient and works on
  /// both Mobile and Web.
  ///
  /// Returns the resized image as PNG bytes (as raw JPEG encoding is not
  /// universally supported in dart:ui without plugins, but we rely on
  /// the fact that PNG is widely supported. For JPEG, we'd need plugins).
  ///
  /// Note: The [targetWidth] and [targetHeight] are constraints. The aspect
  /// ratio is preserved.
  static Future<Uint8List> resizeImage(Uint8List bytes, {int targetWidth = kMaxUploadWidth, int? targetHeight}) async {
    // 1. Decode the image to get dimensions
    final ui.Codec codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: targetWidth,
      targetHeight: targetHeight,
      allowUpscaling: false,
    );

    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    final ui.Image image = frameInfo.image;

    // 2. Encode back to bytes
    // Note: toByteData(format: ui.ImageByteFormat.png) returns PNG.
    // For photos, this might be larger than JPEG, but we don't have
    // a pure Dart JPEG encoder in the standard library.
    // Ideally we use image_picker's resize capabilities for the initial pick.
    // This is a fallback or for re-processing.
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      throw Exception('Failed to resize image');
    }

    return byteData.buffer.asUint8List();
  }

  /// Calculates the cache width for [CachedNetworkImage] based on
  /// device pixel ratio and widget size.
  ///
  /// Usage:
  /// ```dart
  /// memCacheWidth: ImageUtils.cacheSize(context, 100),
  /// ```
  static int cacheSize(BuildContext context, double widgetSize) {
    return (widgetSize * MediaQuery.of(context).devicePixelRatio).toInt();
  }
}
