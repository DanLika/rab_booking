import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../shared/widgets/widgets.dart';

/// Premium image gallery with zoom and fullscreen support
/// Features: Swipe gestures, thumbnails, image counter, fullscreen mode
class PremiumImageGallery extends StatefulWidget {
  /// List of image URLs
  final List<String> images;

  /// Initial image index
  final int initialIndex;

  /// Gallery height (null for aspect ratio)
  final double? height;

  /// Aspect ratio (default 16:9)
  final double aspectRatio;

  /// Show thumbnails
  final bool showThumbnails;

  /// Show fullscreen button
  final bool showFullscreenButton;

  /// Show image counter
  final bool showCounter;

  /// Border radius
  final double? borderRadius;

  const PremiumImageGallery({
    super.key,
    required this.images,
    this.initialIndex = 0,
    this.height,
    this.aspectRatio = 16 / 9,
    this.showThumbnails = true,
    this.showFullscreenButton = true,
    this.showCounter = true,
    this.borderRadius,
  });

  @override
  State<PremiumImageGallery> createState() => _PremiumImageGalleryState();
}

class _PremiumImageGalleryState extends State<PremiumImageGallery> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _jumpToImage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _openFullscreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _FullscreenGallery(
          images: widget.images,
          initialIndex: _currentIndex,
        ),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Main gallery
        _buildMainGallery(),

        // Thumbnails
        if (widget.showThumbnails && widget.images.length > 1) ...[
          const SizedBox(height: AppDimensions.spaceM),
          _buildThumbnails(),
        ],
      ],
    );
  }

  Widget _buildMainGallery() {
    final effectiveHeight = widget.height ??
        (MediaQuery.of(context).size.width / widget.aspectRatio);

    return ClipRRect(
      borderRadius: BorderRadius.circular(
        widget.borderRadius ?? AppDimensions.radiusL,
      ),
      child: SizedBox(
        height: effectiveHeight,
        child: Stack(
          children: [
            // Image PageView
            PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: widget.images.length,
              itemBuilder: (context, index) {
                return PremiumImage(
                  imageUrl: widget.images[index],
                  fit: BoxFit.cover,
                );
              },
            ),

            // Image counter
            if (widget.showCounter && widget.images.length > 1)
              Positioned(
                top: AppDimensions.spaceM,
                right: AppDimensions.spaceM,
                child: _buildCounter(),
              ),

            // Fullscreen button
            if (widget.showFullscreenButton)
              Positioned(
                top: AppDimensions.spaceM,
                left: AppDimensions.spaceM,
                child: _buildFullscreenButton(),
              ),

            // Navigation arrows (desktop only)
            if (!context.isMobile && widget.images.length > 1) ...[
              _buildNavigationArrow(isLeft: true),
              _buildNavigationArrow(isLeft: false),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCounter() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceS,
        vertical: AppDimensions.spaceXS,
      ),
      decoration: BoxDecoration(
        color: AppColors.withOpacity(Colors.black, AppColors.opacity70),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Text(
        '${_currentIndex + 1} / ${widget.images.length}',
        style: AppTypography.small.copyWith(
          color: Colors.white,
          fontWeight: AppTypography.weightSemibold,
        ),
      ),
    );
  }

  Widget _buildFullscreenButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _openFullscreen,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.spaceS),
          decoration: BoxDecoration(
            color: AppColors.withOpacity(Colors.black, AppColors.opacity70),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.fullscreen,
            color: Colors.white,
            size: AppDimensions.iconM,
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationArrow({required bool isLeft}) {
    final canNavigate = isLeft
        ? _currentIndex > 0
        : _currentIndex < widget.images.length - 1;

    if (!canNavigate) return const SizedBox.shrink();

    return Positioned(
      left: isLeft ? AppDimensions.spaceM : null,
      right: isLeft ? null : AppDimensions.spaceM,
      top: 0,
      bottom: 0,
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (isLeft) {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              } else {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            },
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            child: Container(
              padding: const EdgeInsets.all(AppDimensions.spaceS),
              decoration: BoxDecoration(
                color: AppColors.withOpacity(Colors.black, AppColors.opacity70),
                shape: BoxShape.circle,
                boxShadow: AppShadows.elevation2,
              ),
              child: Icon(
                isLeft ? Icons.chevron_left : Icons.chevron_right,
                color: Colors.white,
                size: AppDimensions.iconL,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnails() {
    return SizedBox(
      height: context.isMobile ? 60 : 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: widget.images.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: AppDimensions.spaceS),
        itemBuilder: (context, index) {
          final isSelected = index == _currentIndex;
          return GestureDetector(
            onTap: () => _jumpToImage(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: context.isMobile ? 60 : 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  width: isSelected ? 3 : 1,
                ),
                boxShadow:
                    isSelected ? AppShadows.glowPrimary : AppShadows.elevation1,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                child: PremiumImage(
                  imageUrl: widget.images[index],
                  fit: BoxFit.cover,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: widget.height ?? 300,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariantLight,
        borderRadius: BorderRadius.circular(
          widget.borderRadius ?? AppDimensions.radiusL,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.image_not_supported_outlined,
              size: AppDimensions.iconXL * 2,
              color: AppColors.textSecondaryLight,
            ),
            const SizedBox(height: AppDimensions.spaceM),
            Text(
              'No images available',
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fullscreen gallery view
class _FullscreenGallery extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _FullscreenGallery({
    required this.images,
    required this.initialIndex,
  });

  @override
  State<_FullscreenGallery> createState() => _FullscreenGalleryState();
}

class _FullscreenGalleryState extends State<_FullscreenGallery> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Image PageView
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: widget.images.length,
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: PremiumImage(
                    imageUrl: widget.images[index],
                    fit: BoxFit.contain,
                  ),
                ),
              );
            },
          ),

          // Top bar with close button and counter
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.spaceM),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Close button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusFull),
                      child: Container(
                        padding: const EdgeInsets.all(AppDimensions.spaceS),
                        decoration: BoxDecoration(
                          color: AppColors.withOpacity(
                              Colors.black, AppColors.opacity70),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: AppDimensions.iconM,
                        ),
                      ),
                    ),
                  ),

                  // Counter
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.spaceM,
                      vertical: AppDimensions.spaceS,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.withOpacity(
                          Colors.black, AppColors.opacity70),
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusFull),
                    ),
                    child: Text(
                      '${_currentIndex + 1} / ${widget.images.length}',
                      style: AppTypography.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: AppTypography.weightSemibold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
