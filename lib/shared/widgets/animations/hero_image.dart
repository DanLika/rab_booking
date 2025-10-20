import 'package:flutter/material.dart';
import '../../../core/constants/app_dimensions.dart';

/// Hero animated image widget for shared element transitions
/// Wraps image with Hero widget for smooth transitions between screens
class HeroImage extends StatelessWidget {
  /// Unique hero tag (use property ID or image URL)
  final String tag;

  /// Image URL
  final String? imageUrl;

  /// Image fit
  final BoxFit fit;

  /// Border radius
  final double? borderRadius;

  /// Width constraint
  final double? width;

  /// Height constraint
  final double? height;

  /// Placeholder widget while loading
  final Widget? placeholder;

  /// Error widget if image fails to load
  final Widget? errorWidget;

  const HeroImage({
    super.key,
    required this.tag,
    this.imageUrl,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: tag,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          borderRadius ?? AppDimensions.radiusM,
        ),
        child: imageUrl != null
            ? Image.network(
                imageUrl!,
                fit: fit,
                width: width,
                height: height,
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                  if (wasSynchronouslyLoaded) {
                    return child;
                  }
                  return AnimatedOpacity(
                    opacity: frame == null ? 0 : 1,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    child: child,
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) {
                    return child;
                  }
                  return placeholder ??
                      Container(
                        width: width,
                        height: height,
                        color: Colors.grey[200],
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                },
                errorBuilder: (context, error, stackTrace) {
                  return errorWidget ??
                      Container(
                        width: width,
                        height: height,
                        color: Colors.grey[200],
                        child: const Icon(Icons.broken_image, size: 48),
                      );
                },
              )
            : Container(
                width: width,
                height: height,
                color: Colors.grey[200],
                child: const Icon(Icons.image, size: 48),
              ),
      ),
    );
  }
}

/// Hero animated text widget
class HeroText extends StatelessWidget {
  final String tag;
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const HeroText({
    super.key,
    required this.tag,
    required this.text,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: tag,
      child: Material(
        color: Colors.transparent,
        child: Text(
          text,
          style: style,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
        ),
      ),
    );
  }
}

/// Hero animated card widget
class HeroCard extends StatelessWidget {
  final String tag;
  final Widget child;
  final double? borderRadius;
  final Color? color;
  final List<BoxShadow>? boxShadow;

  const HeroCard({
    super.key,
    required this.tag,
    required this.child,
    this.borderRadius,
    this.color,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: tag,
      child: Material(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(
          borderRadius ?? AppDimensions.radiusM,
        ),
        elevation: 0,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              borderRadius ?? AppDimensions.radiusM,
            ),
            boxShadow: boxShadow,
          ),
          child: child,
        ),
      ),
    );
  }
}
