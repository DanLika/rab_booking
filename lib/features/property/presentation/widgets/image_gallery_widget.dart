import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import '../../../../../core/theme/theme_extensions.dart';

/// Image gallery widget with lightbox view
class ImageGalleryWidget extends StatelessWidget {
  const ImageGalleryWidget({
    required this.images,
    this.coverImage,
    super.key,
  });

  final List<String> images;
  final String? coverImage;

  List<String> get _allImages {
    final allImages = <String>[];
    if (coverImage != null) {
      allImages.add(coverImage!);
    }
    allImages.addAll(images);
    // Return empty list if no images - will be handled with placeholder widget
    return allImages;
  }

  @override
  Widget build(BuildContext context) {
    // If no images, show placeholder
    if (_allImages.isEmpty) {
      return Container(
        height: 300,
        color: context.surfaceVariantColor,
        child: Center(
          child: Icon(Icons.villa, size: 80, color: context.iconColorSecondary),
        ),
      );
    }

    final isMobile = MediaQuery.of(context).size.width < 768;
    return isMobile ? _buildMobileLayout(context) : _buildDesktopLayout(context);
  }

  Widget _buildMobileLayout(BuildContext context) {
    return GestureDetector(
      onTap: () => _openFullScreenGallery(context, 0),
      child: Stack(
        children: [
          Hero(
            tag: 'property-image-${_allImages[0]}',
            child: CachedNetworkImage(
              imageUrl: _allImages[0],
              height: 300,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: context.surfaceVariantColor,
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                color: context.surfaceVariantColor,
                child: Icon(Icons.villa, size: 60, color: context.iconColorSecondary),
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: FilledButton.icon(
              onPressed: () => _openFullScreenGallery(context, 0),
              icon: const Icon(Icons.photo_library, size: 18),
              label: Text('${_allImages.length} fotografija'),
              style: FilledButton.styleFrom(
                backgroundColor: context.surfaceColor,
                foregroundColor: context.textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return SizedBox(
      height: 400,
      child: Row(
        children: [
          // Main image (left, 60%)
          Expanded(
            flex: 6,
            child: GestureDetector(
              onTap: () => _openFullScreenGallery(context, 0),
              child: Hero(
                tag: 'property-image-${_allImages[0]}',
                child: CachedNetworkImage(
                  imageUrl: _allImages[0],
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: context.surfaceVariantColor,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: context.surfaceVariantColor,
                    child: Icon(Icons.villa, size: 60, color: context.iconColorSecondary),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Thumbnail grid (right, 40%)
          Expanded(
            flex: 4,
            child: Column(
              children: [
                // Top 2 images
                Expanded(
                  child: Row(
                    children: [
                      if (_allImages.length > 1)
                        Expanded(
                          child: _buildThumbnail(context, 1),
                        ),
                      if (_allImages.length > 2) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildThumbnail(context, 2),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Bottom 2 images + "View all" overlay
                Expanded(
                  child: Row(
                    children: [
                      if (_allImages.length > 3)
                        Expanded(
                          child: _buildThumbnail(context, 3),
                        ),
                      if (_allImages.length > 4) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: Stack(
                            children: [
                              _buildThumbnail(context, 4),
                              if (_allImages.length > 5)
                                Positioned.fill(
                                  child: Material(
                                    color: Colors.black54,
                                    child: InkWell(
                                      onTap: () => _openFullScreenGallery(context, 4),
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.photo_library,
                                              color: Colors.white,
                                              size: 32,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              '+${_allImages.length - 5}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail(BuildContext context, int index) {
    return GestureDetector(
      onTap: () => _openFullScreenGallery(context, index),
      child: CachedNetworkImage(
        imageUrl: _allImages[index],
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: context.surfaceVariantColor,
        ),
        errorWidget: (context, url, error) => Container(
          color: context.surfaceVariantColor,
          child: Icon(Icons.image, color: context.iconColorSecondary),
        ),
      ),
    );
  }

  void _openFullScreenGallery(BuildContext context, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _FullScreenGallery(
          images: _allImages,
          initialIndex: initialIndex,
        ),
      ),
    );
  }
}

/// Full-screen image gallery with zoom and swipe
class _FullScreenGallery extends StatefulWidget {
  const _FullScreenGallery({
    required this.images,
    this.initialIndex = 0,
  });

  final List<String> images;
  final int initialIndex;

  @override
  State<_FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<_FullScreenGallery> {
  late PageController _pageController;
  late int _currentIndex;

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
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_currentIndex + 1} / ${widget.images.length}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: PhotoViewGallery.builder(
        pageController: _pageController,
        itemCount: widget.images.length,
        builder: (context, index) {
          return PhotoViewGalleryPageOptions(
            imageProvider: CachedNetworkImageProvider(widget.images[index]),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
            heroAttributes: PhotoViewHeroAttributes(
              tag: 'property-image-${widget.images[index]}',
            ),
          );
        },
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        scrollPhysics: const BouncingScrollPhysics(),
        backgroundDecoration: const BoxDecoration(
          color: Colors.black,
        ),
        loadingBuilder: (context, event) => const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
