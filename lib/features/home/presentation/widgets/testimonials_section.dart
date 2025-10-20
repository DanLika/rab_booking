import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/utils/responsive_builder.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/models/marketing_content_models.dart';
import '../providers/marketing_content_providers.dart';

/// Testimonials section for home screen
/// Features: Carousel with customer testimonials, auto-play, manual navigation
/// Data is fetched from Supabase with fallback to defaults
class TestimonialsSection extends ConsumerStatefulWidget {
  /// Section title
  final String title;

  /// Section subtitle
  final String? subtitle;

  /// Enable auto-play carousel
  final bool autoPlay;

  /// Auto-play interval
  final Duration autoPlayInterval;

  const TestimonialsSection({
    super.key,
    this.title = 'What Our Guests Say',
    this.subtitle,
    this.autoPlay = true,
    this.autoPlayInterval = const Duration(seconds: 5),
  });

  @override
  ConsumerState<TestimonialsSection> createState() => _TestimonialsSectionState();
}

class _TestimonialsSectionState extends ConsumerState<TestimonialsSection> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _autoPlayTimer;
  List<TestimonialData> _testimonials = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: 0.9,
      initialPage: 0,
    );
  }

  void _initializeAutoPlay() {
    if (widget.autoPlay && _testimonials.isNotEmpty) {
      _startAutoPlay();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _autoPlayTimer?.cancel();
    super.dispose();
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer.periodic(widget.autoPlayInterval, (timer) {
      // Check if PageController is attached before using it
      if (!_pageController.hasClients) return;

      if (_currentPage < _testimonials.length - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      } else {
        _pageController.animateToPage(
          0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _nextPage() {
    if (!_pageController.hasClients) return;
    if (_currentPage < _testimonials.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (!_pageController.hasClients) return;
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final testimonialsAsync = ref.watch(featuredTestimonialsProvider);

    return testimonialsAsync.when(
      data: (testimonials) => _buildContent(context, testimonials),
      loading: () => _buildLoading(context),
      error: (error, stack) => _buildContent(context, defaultTestimonials), // Fallback on error
    );
  }

  Widget _buildContent(BuildContext context, List<TestimonialData> testimonials) {
    if (testimonials.isEmpty) {
      return const SizedBox.shrink(); // Hide section if no testimonials
    }

    // Update state and initialize auto-play if testimonials changed
    if (_testimonials != testimonials) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _testimonials = testimonials;
        });
        _initializeAutoPlay();
      });
    }

    final effectiveTestimonials = testimonials;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: context.sectionSpacing,
      ),
      child: Column(
        children: [
          // Section header
          MaxWidthContainer(
            maxWidth: AppDimensions.containerXL,
            padding: EdgeInsets.symmetric(horizontal: context.horizontalPadding),
            child: _buildHeader(context),
          ),

          SizedBox(height: context.isMobile ? AppDimensions.spaceXL : AppDimensions.spaceXXL),

          // Testimonials carousel
          ResponsiveBuilder(
            mobile: (context, constraints) =>
                _buildMobileCarousel(effectiveTestimonials),
            tablet: (context, constraints) =>
                _buildTabletCarousel(effectiveTestimonials),
            desktop: (context, constraints) =>
                _buildDesktopCarousel(effectiveTestimonials),
          ),

          const SizedBox(height: AppDimensions.spaceXL),

          // Dots indicator
          _buildDotsIndicator(effectiveTestimonials.length),

          // Navigation controls (desktop only)
          if (context.isDesktop) ...[
            const SizedBox(height: AppDimensions.spaceL),
            _buildNavigationControls(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Text(
          widget.title,
          style: context.isMobile ? AppTypography.h2 : AppTypography.h1,
          textAlign: TextAlign.center,
        ),
        if (widget.subtitle != null) ...[
          const SizedBox(height: AppDimensions.spaceS),
          Text(
            widget.subtitle!,
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildMobileCarousel(List<TestimonialData> testimonials) {
    return SizedBox(
      height: _getCarouselHeight(context),
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        itemCount: testimonials.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceS),
            child: TestimonialCard(testimonial: testimonials[index]),
          );
        },
      ),
    );
  }

  Widget _buildTabletCarousel(List<TestimonialData> testimonials) {
    return SizedBox(
      height: _getCarouselHeight(context),
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        itemCount: testimonials.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceM),
            child: TestimonialCard(testimonial: testimonials[index]),
          );
        },
      ),
    );
  }

  Widget _buildDesktopCarousel(List<TestimonialData> testimonials) {
    return MaxWidthContainer(
      maxWidth: AppDimensions.containerXL,
      child: SizedBox(
        height: _getCarouselHeight(context),
        child: PageView.builder(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentPage = index;
            });
          },
          itemCount: testimonials.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceL),
              child: TestimonialCard(testimonial: testimonials[index]),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDotsIndicator(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == _currentPage;
        return GestureDetector(
          onTap: () {
            if (!_pageController.hasClients) return;
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceXXS),
            width: isActive ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary : AppColors.borderLight,
              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              boxShadow: isActive ? AppShadows.glowPrimary : null,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildNavigationControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        PremiumButton.outline(
          label: 'Previous',
          icon: Icons.arrow_back,
          iconPosition: IconPosition.left,
          onPressed: _currentPage > 0 ? _previousPage : null,
        ),
        const SizedBox(width: AppDimensions.spaceM),
        PremiumButton.outline(
          label: 'Next',
          icon: Icons.arrow_forward,
          iconPosition: IconPosition.right,
          onPressed: _currentPage < _testimonials.length - 1
              ? _nextPage
              : null,
        ),
      ],
    );
  }

  double _getCarouselHeight(BuildContext context) {
    if (context.isDesktop) return 470;
    if (context.isTablet) return 490;
    return 530;
  }

  Widget _buildLoading(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: context.sectionSpacing,
        horizontal: context.horizontalPadding,
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

/// Testimonial card widget
class TestimonialCard extends StatelessWidget {
  final TestimonialData testimonial;

  const TestimonialCard({
    super.key,
    required this.testimonial,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PremiumCard.elevated(
      elevation: 2,
      enableHover: false,
      child: Padding(
        padding: EdgeInsets.all(
          context.isMobile ? AppDimensions.spaceL : AppDimensions.spaceXL,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Quote icon
            Icon(
              Icons.format_quote,
              size: AppDimensions.iconXL,
              color: isDark ? AppColors.primaryLight : AppColors.primary,
            ),

            const SizedBox(height: AppDimensions.spaceM),

            // Testimonial text
            Text(
              testimonial.quote,
              style: context.isMobile
                  ? AppTypography.bodyLarge.copyWith(
                      fontStyle: FontStyle.italic,
                      height: 1.6,
                    )
                  : AppTypography.h3.copyWith(
                      fontStyle: FontStyle.italic,
                      fontWeight: AppTypography.weightRegular,
                      height: 1.6,
                    ),
              textAlign: TextAlign.center,
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: AppDimensions.spaceL),

            // Rating
            _buildRating(testimonial.rating),

            const SizedBox(height: AppDimensions.spaceM),

            // User info
            _buildUserInfo(context),
          ],
        ),
      ),
    );
  }

  Widget _buildRating(double rating) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final isFilled = index < rating.floor();
        final isHalf = !isFilled && index < rating;

        return Icon(
          isFilled
              ? Icons.star
              : isHalf
                  ? Icons.star_half
                  : Icons.star_border,
          color: AppColors.star,
          size: AppDimensions.iconM,
        );
      }),
    );
  }

  Widget _buildUserInfo(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar
        Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.primaryGradient,
            boxShadow: AppShadows.glowPrimary,
          ),
          child: ClipOval(
            child: testimonial.avatarUrl != null
                ? PremiumImage(
                    imageUrl: testimonial.avatarUrl!,
                    fit: BoxFit.cover,
                  )
                : Center(
                    child: Text(
                      testimonial.name.substring(0, 1).toUpperCase(),
                      style: AppTypography.h3.copyWith(
                        color: context.textColorInverted,
                        fontWeight: AppTypography.weightBold,
                      ),
                    ),
                  ),
          ),
        ),

        const SizedBox(width: AppDimensions.spaceM),

        // Name and location
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                testimonial.name,
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: AppTypography.weightSemibold,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              if (testimonial.location != null) ...[
                const SizedBox(height: AppDimensions.spaceXXS),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: AppDimensions.iconS,
                      color: AppColors.textSecondaryLight,
                    ),
                    const SizedBox(width: AppDimensions.spaceXXS),
                    Flexible(
                      child: Text(
                        testimonial.location!,
                        style: AppTypography.small.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
