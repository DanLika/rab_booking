import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/models/marketing_content_models.dart';
import '../providers/marketing_content_providers.dart';

/// Premium Testimonials Section
/// Features:
/// - Glassmorphic background
/// - Premium header with gradient icon
/// - Enhanced testimonial cards
/// - Auto-play carousel
/// - Premium navigation controls
/// - Smooth animations
class TestimonialsSectionPremium extends ConsumerStatefulWidget {
  const TestimonialsSectionPremium({
    this.title = 'What Our Guests Say',
    this.subtitle,
    this.autoPlay = true,
    this.autoPlayInterval = const Duration(seconds: 5),
    super.key,
  });

  final String title;
  final String? subtitle;
  final bool autoPlay;
  final Duration autoPlayInterval;

  @override
  ConsumerState<TestimonialsSectionPremium> createState() =>
      _TestimonialsSectionPremiumState();
}

class _TestimonialsSectionPremiumState
    extends ConsumerState<TestimonialsSectionPremium> {
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
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => _buildContent(context, defaultTestimonials),
      data: (testimonials) {
        if (testimonials.isEmpty) {
          return const SizedBox.shrink();
        }
        return _buildContent(context, testimonials);
      },
    );
  }

  Widget _buildContent(BuildContext context, List<TestimonialData> testimonials) {
    if (_testimonials != testimonials) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _testimonials = testimonials;
        });
        _initializeAutoPlay();
      });
    }

    final isMobile = context.isMobile;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(
        horizontal: isMobile ? 0 : AppDimensions.spaceXL,
        vertical: AppDimensions.spaceXL,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: Theme.of(context).brightness == Brightness.dark
              ? [
                  AppColors.surfaceVariantDark.withValues(alpha: 0.3),
                  AppColors.surfaceDark.withValues(alpha: 0.5),
                ]
              : [
                  AppColors.secondary.withValues(alpha: 0.02),
                  AppColors.surfaceLight.withValues(alpha: 0.8),
                ],
        ),
        borderRadius: BorderRadius.circular(isMobile ? 0 : AppDimensions.radiusXL),
        border: isMobile
            ? null
            : Border.all(
                color: AppColors.secondary.withValues(alpha: 0.1),
                width: 1,
              ),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? AppDimensions.spaceL : AppDimensions.spaceXL),
        child: Column(
          children: [
            // Premium header
            _buildPremiumHeader(context, isMobile, testimonials.length),

            SizedBox(
              height: isMobile ? AppDimensions.spaceXL : AppDimensions.spaceXXL,
            ),

            // Testimonials carousel
            SizedBox(
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
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile
                          ? AppDimensions.spaceS
                          : AppDimensions.spaceM,
                    ),
                    child: _PremiumTestimonialCard(
                      testimonial: testimonials[index],
                      index: index,
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: AppDimensions.spaceXL),

            // Dots indicator
            _buildDotsIndicator(testimonials.length),

            // Navigation controls (desktop only)
            if (context.isDesktop) ...[
              const SizedBox(height: AppDimensions.spaceL),
              _buildNavigationControls(),
            ],
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 800.ms, curve: Curves.easeOut)
        .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic);
  }

  Widget _buildPremiumHeader(BuildContext context, bool isMobile, int count) {
    return Column(
      children: [
        // Premium quote icon
        Container(
          padding: const EdgeInsets.all(AppDimensions.spaceM),
          decoration: BoxDecoration(
            gradient: AppColors.secondaryGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.secondary.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.format_quote,
            color: Colors.white,
            size: 32,
          ),
        ),
        const SizedBox(height: AppDimensions.spaceM),

        // Title and count
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.title,
              style: (isMobile ? AppTypography.h2 : AppTypography.h1).copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(width: AppDimensions.spaceS),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spaceS,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.secondary.withValues(alpha: 0.2),
                    AppColors.secondary.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                border: Border.all(
                  color: AppColors.secondary.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Text(
                '$count',
                style: AppTypography.caption.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),

        // Subtitle
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
            width: isActive ? 32 : 8,
            height: 8,
            decoration: BoxDecoration(
              gradient: isActive
                  ? AppColors.secondaryGradient
                  : null,
              color: isActive ? null : AppColors.borderLight,
              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: AppColors.secondary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
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
          onPressed:
              _currentPage < _testimonials.length - 1 ? _nextPage : null,
        ),
      ],
    );
  }

  double _getCarouselHeight(BuildContext context) {
    if (context.isDesktop) return 450;
    if (context.isTablet) return 470;
    return 510;
  }
}

/// Premium Testimonial Card
class _PremiumTestimonialCard extends StatelessWidget {
  final TestimonialData testimonial;
  final int index;

  const _PremiumTestimonialCard({
    required this.testimonial,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(
          color: AppColors.borderLight.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: AppShadows.elevation2,
      ),
      child: Padding(
        padding: EdgeInsets.all(
          isMobile ? AppDimensions.spaceL : AppDimensions.spaceXL,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Quote icon
            Container(
              padding: const EdgeInsets.all(AppDimensions.spaceS),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.secondary.withValues(alpha: 0.2),
                    AppColors.secondary.withValues(alpha: 0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.format_quote,
                size: AppDimensions.iconL,
                color: AppColors.secondary,
              ),
            ),

            const SizedBox(height: AppDimensions.spaceM),

            // Testimonial text
            Flexible(
              child: SingleChildScrollView(
                child: Text(
                  testimonial.quote,
                  style: isMobile
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
                ),
              ),
            ),

            const SizedBox(height: AppDimensions.spaceL),

            // Rating stars
            _buildRating(testimonial.rating),

            const SizedBox(height: AppDimensions.spaceM),

            // User info
            _buildUserInfo(context),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: index * 100))
        .fadeIn(duration: 600.ms, curve: Curves.easeOut)
        .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1));
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
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.secondaryGradient,
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
                      style: AppTypography.h2.copyWith(
                        color: Colors.white,
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
