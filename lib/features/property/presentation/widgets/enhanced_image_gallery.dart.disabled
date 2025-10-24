import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/utils/adaptive_spacing.dart';
import '../../../../core/utils/responsive_breakpoints.dart';
import '../../../../shared/widgets/animations/skeleton_loader.dart';

/// Enhanced image gallery with Hero animations and thumbnails
///
/// Features:
/// - Hero animation for main image
/// - Interactive thumbnail grid
/// - Full-screen image viewer
/// - Responsive layout
/// - Smooth transitions
class EnhancedImageGallery extends StatefulWidget {
  const EnhancedImageGallery({
    required this.images,
    this.initialIndex = 0,
    this.heroTag,
    this.onBackPressed,
    this.onFavoritePressed,
    this.isFavorite = false,
    this.borderRadius = 25.0,
    super.key,
  });

  final List<String> images;
  final int initialIndex;
  final String? heroTag;
  final VoidCallback? onBackPressed;
  final VoidCallback? onFavoritePressed;
  final bool isFavorite;
  final double borderRadius;

  @override
  State<EnhancedImageGallery> createState() => _EnhancedImageGalleryState();
}

class _EnhancedImageGalleryState extends State<EnhancedImageGallery> {
  late int _currentIndex;
  late PageController _pageController;

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

  String get _currentImage {
    if (widget.images.isEmpty) return '';
    return widget.images[_currentIndex];
  }

  void _onThumbnailTap(int index) {
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
  }

  void _openFullScreen() {
    Navigator.of(context).push(
      PageRoute(
        builder: (context) => _FullScreenImageViewer(
          images: widget.images,
          initialIndex: _currentIndex,
          heroTag: widget.heroTag ?? _currentImage,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return _buildEmptyState(context);
    }

    final isMobile = context.isMobile;
    final isTablet = context.isTablet;

    return Container(
      height: isMobile ? 400 : (isTablet ? 480 : 520),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
      child: Stack(
        children: [
          // Main image with PageView for swipe
          _buildMainImage(context),

          // Overlay controls
          _buildOverlayControls(context),

          // Thumbnail grid (only on tablet/desktop)
          if (!isMobile) _buildThumbnailGrid(context),
        ],
      ),
    );
  }

  Widget _buildMainImage(BuildContext context) {
    return GestureDetector(
      onTap: _openFullScreen,
      child: Hero(
        tag: widget.heroTag ?? _currentImage,
        transitionOnUserGestures: true,
        child: PageView.builder(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          itemCount: widget.images.length,
          itemBuilder: (context, index) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              child: CachedNetworkImage(
                imageUrl: widget.images[index],
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                fadeInDuration: const Duration(milliseconds: 300),
                fadeOutDuration: const Duration(milliseconds: 300),
                placeholder: (context, url) => SkeletonLoader(
                  width: double.infinity,
                  height: double.infinity,
                  borderRadius: widget.borderRadius,
                ),
                errorWidget: (context, url, error) => Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.broken_image_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildOverlayControls(BuildContext context) {
    return Positioned.fill(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top controls (back & favorite)
          Padding(
            padding: EdgeInsets.all(context.spacing.medium),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back button
                if (widget.onBackPressed != null)
                  _buildCircleButton(
                    context: context,
                    icon: Icons.chevron_left,
                    onPressed: widget.onBackPressed!,
                    backgroundColor: Colors.white,
                    iconColor: Theme.of(context).colorScheme.onSurface,
                  ),

                const Spacer(),

                // Favorite button
                if (widget.onFavoritePressed != null)
                  _buildCircleButton(
                    context: context,
                    icon: widget.isFavorite ? Icons.favorite : Icons.favorite_border,
                    onPressed: widget.onFavoritePressed!,
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    iconColor: widget.isFavorite
                        ? Colors.red
                        : Theme.of(context).colorScheme.onSecondary,
                  ),
              ],
            ),
          ),

          // Bottom: Image counter
          if (widget.images.length > 1)
            Padding(
              padding: EdgeInsets.all(context.spacing.medium),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.spacing.medium,
                      vertical: context.spacing.small,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_currentIndex + 1} / ${widget.images.length}',
                      style: context.typography.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildThumbnailGrid(BuildContext context) {
    return Positioned(
      bottom: context.spacing.large,
      right: context.spacing.large,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: 400,
          maxWidth: 80,
        ),
        child: SingleChildScrollView(
          child: Wrap(
            spacing: context.spacing.small,
            runSpacing: context.spacing.small,
            direction: Axis.vertical,
            children: List.generate(
              widget.images.length,
              (index) => _buildThumbnail(context, index),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(BuildContext context, int index) {
    final isSelected = index == _currentIndex;

    return GestureDetector(
      onTap: () => _onThumbnailTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.white,
            width: isSelected ? 3 : 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: CachedNetworkImage(
            imageUrl: widget.images[index],
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            fadeInDuration: const Duration(milliseconds: 100),
            fadeOutDuration: const Duration(milliseconds: 100),
            placeholder: (context, url) => SkeletonLoader(
              width: 60,
              height: 60,
              borderRadius: 10,
            ),
            errorWidget: (context, url, error) => Container(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Icon(
                Icons.image_not_supported,
                size: 24,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCircleButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onPressed,
    required Color backgroundColor,
    required Color iconColor,
  }) {
    return Material(
      color: backgroundColor,
      shape: const CircleBorder(),
      elevation: 4,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          width: 50,
          height: 50,
          alignment: Alignment.center,
          child: Icon(
            icon,
            color: iconColor,
            size: 28,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: context.spacing.medium),
            Text(
              'No images available',
              style: context.typography.bodyLarge.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen image viewer with swipe and zoom
class _FullScreenImageViewer extends StatefulWidget {
  const _FullScreenImageViewer({
    required this.images,
    required this.initialIndex,
    required this.heroTag,
  });

  final List<String> images;
  final int initialIndex;
  final String heroTag;

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;
  late TransformationController _transformationController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _transformationController = TransformationController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Image viewer with zoom
          Center(
            child: Hero(
              tag: widget.heroTag,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentIndex = index),
                itemCount: widget.images.length,
                itemBuilder: (context, index) {
                  return InteractiveViewer(
                    transformationController: _transformationController,
                    minScale: 1.0,
                    maxScale: 4.0,
                    child: Center(
                      child: CachedNetworkImage(
                        imageUrl: widget.images[index],
                        fit: BoxFit.contain,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        ),
                        errorWidget: (context, url, error) => const Icon(
                          Icons.broken_image,
                          color: Colors.white,
                          size: 64,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Close button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 32),
                    onPressed: () => Navigator.of(context).pop(),
                  ),

                  // Image counter
                  if (widget.images.length > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_currentIndex + 1} / ${widget.images.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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
