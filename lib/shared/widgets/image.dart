import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_effects.dart';
import '../../core/theme/app_animations.dart';
import '../../core/constants/app_dimensions.dart';

/// Premium image component with loading and error states
/// Features: Shimmer loading, error fallback, caching, aspect ratio support
class PremiumImage extends StatelessWidget {
  /// Image URL
  final String? imageUrl;

  /// Image asset path (for local images)
  final String? assetPath;

  /// Width constraint
  final double? width;

  /// Height constraint
  final double? height;

  /// Box fit
  final BoxFit fit;

  /// Border radius
  final double? borderRadius;

  /// Aspect ratio
  final double? aspectRatio;

  /// Error placeholder widget
  final Widget? errorWidget;

  /// Loading placeholder widget
  final Widget? loadingWidget;

  /// Enable shimmer loading effect
  final bool enableShimmer;

  /// Enable image overlay
  final bool enableOverlay;

  /// Overlay gradient
  final Gradient? overlayGradient;

  const PremiumImage({
    super.key,
    this.imageUrl,
    this.assetPath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.aspectRatio,
    this.errorWidget,
    this.loadingWidget,
    this.enableShimmer = true,
    this.enableOverlay = false,
    this.overlayGradient,
  }) : assert(
         imageUrl != null || assetPath != null,
         'Either imageUrl or assetPath must be provided',
       );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveBorderRadius = borderRadius ?? AppDimensions.radiusM;

    Widget imageWidget;

    if (assetPath != null) {
      // Local asset image
      imageWidget = Image.asset(
        assetPath!,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) =>
            _buildErrorWidget(isDark, effectiveBorderRadius),
      );
    } else {
      // Network image with caching
      imageWidget = CachedNetworkImage(
        imageUrl: imageUrl!,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) =>
            loadingWidget ??
            (enableShimmer
                ? _buildShimmerLoading(isDark, effectiveBorderRadius)
                : _buildLoadingWidget(isDark, effectiveBorderRadius)),
        errorWidget: (context, url, error) =>
            errorWidget ?? _buildErrorWidget(isDark, effectiveBorderRadius),
      );
    }

    // Wrap with aspect ratio if specified
    if (aspectRatio != null) {
      imageWidget = AspectRatio(aspectRatio: aspectRatio!, child: imageWidget);
    }

    // Add overlay if enabled
    if (enableOverlay) {
      imageWidget = Stack(
        fit: StackFit.expand,
        children: [
          imageWidget,
          Container(
            decoration: BoxDecoration(
              gradient: overlayGradient ?? AppColors.overlayGradient,
            ),
          ),
        ],
      );
    }

    // Wrap with border radius
    return ClipRRect(
      borderRadius: BorderRadius.circular(effectiveBorderRadius),
      child: SizedBox(width: width, height: height, child: imageWidget),
    );
  }

  Widget _buildShimmerLoading(bool isDark, double borderRadius) {
    return AnimatedContainer(
      duration: AppAnimations.shimmer.duration,
      decoration: BoxDecoration(
        gradient: isDark
            ? AppEffects.shimmerGradientDark
            : AppEffects.shimmerGradientLight,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }

  Widget _buildLoadingWidget(bool isDark, double borderRadius) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceVariantDark
            : AppColors.surfaceVariantLight,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.authPrimary),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(bool isDark, double borderRadius) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceVariantDark
            : AppColors.surfaceVariantLight,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Center(
        child: Icon(
          Icons.broken_image_outlined,
          size: AppDimensions.iconL,
          color: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
        ),
      ),
    );
  }
}

/// Premium image gallery widget
class PremiumImageGallery extends StatefulWidget {
  /// List of image URLs
  final List<String> imageUrls;

  /// Aspect ratio for images
  final double aspectRatio;

  /// Enable page indicator
  final bool showIndicator;

  /// Border radius
  final double? borderRadius;

  /// Auto play interval (null to disable)
  final Duration? autoPlayInterval;

  const PremiumImageGallery({
    super.key,
    required this.imageUrls,
    this.aspectRatio = 16 / 9,
    this.showIndicator = true,
    this.borderRadius,
    this.autoPlayInterval,
  });

  @override
  State<PremiumImageGallery> createState() => _PremiumImageGalleryState();
}

class _PremiumImageGalleryState extends State<PremiumImageGallery> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // Auto play if enabled
    if (widget.autoPlayInterval != null) {
      Future.delayed(widget.autoPlayInterval!, _autoPlay);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _autoPlay() {
    if (!mounted) return;

    final nextPage = (_currentPage + 1) % widget.imageUrls.length;
    _pageController.animateToPage(
      nextPage,
      duration: AppAnimations.slow,
      curve: AppAnimations.smooth,
    );

    if (widget.autoPlayInterval != null) {
      Future.delayed(widget.autoPlayInterval!, _autoPlay);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        AspectRatio(
          aspectRatio: widget.aspectRatio,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: widget.imageUrls.length,
            itemBuilder: (context, index) {
              return PremiumImage(
                imageUrl: widget.imageUrls[index],
                borderRadius: widget.borderRadius,
              );
            },
          ),
        ),
        if (widget.showIndicator && widget.imageUrls.length > 1)
          Positioned(
            bottom: AppDimensions.spaceS,
            child: _buildPageIndicator(),
          ),
      ],
    );
  }

  Widget _buildPageIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceS,
        vertical: AppDimensions.spaceXXS,
      ),
      decoration: BoxDecoration(
        color: AppColors.withOpacity(Colors.black, AppColors.opacity60),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          widget.imageUrls.length,
          (index) => AnimatedContainer(
            duration: AppAnimations.fast,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: index == _currentPage ? 20 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: index == _currentPage
                  ? Colors.white
                  : AppColors.withOpacity(Colors.white, AppColors.opacity40),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ),
    );
  }
}
