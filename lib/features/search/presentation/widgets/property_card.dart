import 'package:flutter/material.dart';
import '../../../../shared/models/property_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_animations.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../shared/widgets/widgets.dart';

/// Premium property card with image carousel and hover effects
/// Features: Vertical/horizontal layouts, favorites, quick stats, hover animations
class PremiumPropertyCard extends StatefulWidget {
  const PremiumPropertyCard({
    required this.property,
    required this.onTap,
    this.onFavoriteToggle,
    super.key,
  }) : _isHorizontal = false;

  /// Horizontal card variant for list view
  const PremiumPropertyCard.horizontal({
    required this.property,
    required this.onTap,
    this.onFavoriteToggle,
    super.key,
  }) : _isHorizontal = true;

  final PropertyModel property;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteToggle;
  final bool _isHorizontal;

  @override
  State<PremiumPropertyCard> createState() => _PremiumPropertyCardState();
}

class _PremiumPropertyCardState extends State<PremiumPropertyCard> {
  bool _isHovered = false;
  bool _isFavorite = false;
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: AppAnimations.fast,
        curve: AppAnimations.smooth,
        transform: _isHovered ? Matrix4.translationValues(0, -4, 0) : Matrix4.identity(),
        child: PremiumCard.elevated(
          elevation: _isHovered ? 4 : 2,
          onTap: widget.onTap,
          child: widget._isHorizontal
              ? _buildHorizontalLayout(isDark)
              : _buildVerticalLayout(isDark),
        ),
      ),
    );
  }

  Widget _buildVerticalLayout(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Image carousel
        _buildImageCarousel(),

        // Content
        Padding(
          padding: const EdgeInsets.all(AppDimensions.spaceM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title and rating
              _buildTitleRow(),

              const SizedBox(height: AppDimensions.spaceXS),

              // Location
              _buildLocation(),

              const SizedBox(height: AppDimensions.spaceM),

              // Quick stats
              _buildQuickStats(),

              const SizedBox(height: AppDimensions.spaceM),

              // Price
              _buildPrice(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalLayout(bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image carousel (fixed width)
        SizedBox(
          width: 280,
          height: 200,
          child: _buildImageCarousel(),
        ),

        // Content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.spaceL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title and rating
                _buildTitleRow(),

                const SizedBox(height: AppDimensions.spaceS),

                // Location
                _buildLocation(),

                const SizedBox(height: AppDimensions.spaceM),

                // Quick stats
                _buildQuickStats(),

                const Spacer(),

                // Price
                _buildPrice(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageCarousel() {
    final images = widget.property.images;
    final hasMultipleImages = images.length > 1;

    return Stack(
      children: [
        // Image PageView
        ClipRRect(
          borderRadius: widget._isHorizontal
              ? const BorderRadius.horizontal(left: Radius.circular(AppDimensions.radiusL))
              : const BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusL)),
          child: AspectRatio(
            aspectRatio: widget._isHorizontal ? 1.4 : 1.5,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentImageIndex = index);
              },
              itemCount: images.length,
              itemBuilder: (context, index) {
                return PremiumImage(
                  imageUrl: images[index],
                  fit: BoxFit.cover,
                );
              },
            ),
          ),
        ),

        // Favorite button
        Positioned(
          top: AppDimensions.spaceS,
          right: AppDimensions.spaceS,
          child: _buildFavoriteButton(),
        ),

        // Navigation arrows (desktop only, on hover)
        if (hasMultipleImages && _isHovered) ...[
          // Previous button
          if (_currentImageIndex > 0)
            Positioned(
              left: AppDimensions.spaceS,
              top: 0,
              bottom: 0,
              child: Center(
                child: _buildNavigationButton(
                  icon: Icons.chevron_left,
                  onPressed: () {
                    _pageController.previousPage(
                      duration: AppAnimations.medium,
                      curve: AppAnimations.smooth,
                    );
                  },
                ),
              ),
            ),

          // Next button
          if (_currentImageIndex < images.length - 1)
            Positioned(
              right: AppDimensions.spaceS,
              top: 0,
              bottom: 0,
              child: Center(
                child: _buildNavigationButton(
                  icon: Icons.chevron_right,
                  onPressed: () {
                    _pageController.nextPage(
                      duration: AppAnimations.medium,
                      curve: AppAnimations.smooth,
                    );
                  },
                ),
              ),
            ),
        ],

        // Image indicators
        if (hasMultipleImages)
          Positioned(
            bottom: AppDimensions.spaceS,
            left: 0,
            right: 0,
            child: _buildImageIndicators(images.length),
          ),
      ],
    );
  }

  Widget _buildFavoriteButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() => _isFavorite = !_isFavorite);
          widget.onFavoriteToggle?.call();
        },
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        child: AnimatedContainer(
          duration: AppAnimations.fast,
          padding: const EdgeInsets.all(AppDimensions.spaceS),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            shape: BoxShape.circle,
            boxShadow: AppShadows.elevation2,
          ),
          child: AnimatedSwitcher(
            duration: AppAnimations.fast,
            transitionBuilder: (child, animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            child: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              key: ValueKey(_isFavorite),
              color: _isFavorite ? context.errorColor : context.textColorSecondary,
              size: AppDimensions.iconM,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.spaceXS),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            shape: BoxShape.circle,
            boxShadow: AppShadows.elevation2,
          ),
          child: Icon(
            icon,
            color: context.textColor,
            size: AppDimensions.iconM,
          ),
        ),
      ),
    );
  }

  Widget _buildImageIndicators(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == _currentImageIndex;
        return AnimatedContainer(
          duration: AppAnimations.fast,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: isActive ? 20 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: isActive
                ? Colors.white
                : Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            boxShadow: isActive ? AppShadows.elevation1 : null,
          ),
        );
      }),
    );
  }

  Widget _buildTitleRow() {
    return Row(
      children: [
        Expanded(
          child: Text(
            widget.property.name,
            style: AppTypography.h3.copyWith(
              fontWeight: AppTypography.weightBold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppDimensions.spaceS),
        _buildRating(),
      ],
    );
  }

  Widget _buildRating() {
    if (widget.property.rating == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceS,
        vertical: AppDimensions.spaceXXS,
      ),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        boxShadow: AppShadows.glowPrimary,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.star,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            widget.property.rating.toStringAsFixed(1),
            style: AppTypography.small.copyWith(
              color: Colors.white,
              fontWeight: AppTypography.weightBold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocation() {
    return Row(
      children: [
        Icon(
          Icons.location_on_outlined,
          size: 16,
          color: context.textColorSecondary,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            widget.property.location,
            style: AppTypography.bodyMedium.copyWith(
              color: context.textColorSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    return Wrap(
      spacing: AppDimensions.spaceM,
      runSpacing: AppDimensions.spaceXS,
      children: [
        if (widget.property.bedrooms != null && widget.property.bedrooms! > 0)
          _buildStat(
            icon: Icons.bed_outlined,
            label: '${widget.property.bedrooms} ${widget.property.bedrooms == 1 ? 'soba' : 'sobe'}',
          ),
        if (widget.property.bathrooms != null && widget.property.bathrooms! > 0)
          _buildStat(
            icon: Icons.bathtub_outlined,
            label: '${widget.property.bathrooms} ${widget.property.bathrooms == 1 ? 'kupaonica' : 'kupaonice'}',
          ),
        if (widget.property.maxGuests != null && widget.property.maxGuests! > 0)
          _buildStat(
            icon: Icons.people_outline,
            label: '${widget.property.maxGuests} ${widget.property.maxGuests == 1 ? 'gost' : 'gostiju'}',
          ),
      ],
    );
  }

  Widget _buildStat({
    required IconData icon,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: context.textColorSecondary,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: context.textColorSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildPrice() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: RichText(
            text: TextSpan(
              style: AppTypography.bodyMedium,
              children: [
                TextSpan(
                  text: '€${widget.property.pricePerNight}',
                  style: AppTypography.h3.copyWith(
                    fontWeight: AppTypography.weightBold,
                    color: context.primaryColor,
                  ),
                ),
                TextSpan(
                  text: ' / noć',
                  style: AppTypography.bodyMedium.copyWith(
                    color: context.textColorSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (widget.property.reviewCount > 0)
          Text(
            '(${widget.property.reviewCount} ${widget.property.reviewCount == 1 ? 'recenzija' : 'recenzije'})',
            style: AppTypography.small.copyWith(
              color: context.textColorSecondary,
            ),
          ),
      ],
    );
  }
}
