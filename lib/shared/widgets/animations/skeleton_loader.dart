import 'package:flutter/material.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_colors.dart';

/// Skeleton loader with shimmer effect
/// Replaces CircularProgressIndicator for better UX
class SkeletonLoader extends StatefulWidget {
  const SkeletonLoader({
    this.width,
    this.height,
    this.borderRadius = 8.0,
    super.key,
  });

  final double? width;
  final double? height;
  final double borderRadius;

  /// Property card skeleton (vertical)
  static Widget propertyCard() => const PropertyCardSkeleton();

  /// Property card skeleton (horizontal)
  static Widget propertyCardHorizontal() => const PropertyCardSkeletonHorizontal();

  /// Stats cards skeleton (for profile page)
  static Widget statsCards() => const StatsCardsSkeleton();

  /// Calendar skeleton (for timeline/month/week calendar views)
  static Widget calendar() => const CalendarSkeleton();

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _animation = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.grey[300]!,
                Colors.grey[200]!,
                Colors.grey[300]!,
              ],
              stops: const [0.0, 0.5, 1.0],
              transform: _SlideGradientTransform(_animation.value),
            ),
          ),
        );
      },
    );
  }
}

/// Custom gradient transform for shimmer effect
class _SlideGradientTransform extends GradientTransform {
  const _SlideGradientTransform(this.percent);

  final double percent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * percent, 0.0, 0.0);
  }
}

/// Property card skeleton loader
class PropertyCardSkeleton extends StatelessWidget {
  const PropertyCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusS), // 12px modern radius,
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: const ClipRect(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
          // Image skeleton
          SkeletonLoader(
            height: 160,
            borderRadius: 12,
          ),

          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title skeleton
                SkeletonLoader(
                  width: double.infinity,
                  height: 20,
                ),
                SizedBox(height: 8),

                // Location skeleton
                SkeletonLoader(
                  width: 150,
                  height: 16,
                ),
                SizedBox(height: 12),

                // Price skeleton
                Row(
                  children: [
                    SkeletonLoader(
                      width: 80,
                      height: 24,
                    ),
                    Spacer(),
                    SkeletonLoader(
                      width: 60,
                      height: 16,
                      borderRadius: 4,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }
}

/// List skeleton loader - shows multiple property cards
class PropertyListSkeleton extends StatelessWidget {
  const PropertyListSkeleton({
    this.itemCount = 3,
    super.key,
  });

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        itemCount,
        (index) => const Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: PropertyCardSkeleton(),
        ),
      ),
    );
  }
}

/// Text skeleton loader - for text lines
class TextSkeleton extends StatelessWidget {
  const TextSkeleton({
    this.width,
    this.height = 14,
    super.key,
  });

  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      width: width,
      height: height,
      borderRadius: 4,
    );
  }
}

/// Circle skeleton loader - for avatars
class CircleSkeleton extends StatelessWidget {
  const CircleSkeleton({
    this.size = 40,
    super.key,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Colors.grey[300]!,
            Colors.grey[200]!,
            Colors.grey[300]!,
          ],
        ),
      ),
    );
  }
}

/// Horizontal property card skeleton loader
class PropertyCardSkeletonHorizontal extends StatelessWidget {
  const PropertyCardSkeletonHorizontal({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusS), // 12px modern radius,
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image skeleton
          SkeletonLoader(
            width: 280,
            height: 200,
            borderRadius: 12,
          ),

          // Content skeleton
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title skeleton
                  SkeletonLoader(
                    width: double.infinity,
                    height: 20,
                  ),
                  SizedBox(height: 8),

                  // Location skeleton
                  SkeletonLoader(
                    width: 150,
                    height: 16,
                  ),
                  SizedBox(height: 12),

                  // Stats skeleton
                  Row(
                    children: [
                      SkeletonLoader(
                        width: 60,
                        height: 16,
                      ),
                      SizedBox(width: 16),
                      SkeletonLoader(
                        width: 60,
                        height: 16,
                      ),
                      SizedBox(width: 16),
                      SkeletonLoader(
                        width: 60,
                        height: 16,
                      ),
                    ],
                  ),

                  Spacer(),

                  // Price skeleton
                  Row(
                    children: [
                      SkeletonLoader(
                        width: 80,
                        height: 24,
                      ),
                      Spacer(),
                      SkeletonLoader(
                        width: 60,
                        height: 16,
                        borderRadius: 4,
                      ),
                    ],
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

/// Review card skeleton loader
class ReviewCardSkeleton extends StatelessWidget {
  const ReviewCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusS), // 12px modern radius,
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info
          Row(
            children: [
              CircleSkeleton(size: 48),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLoader(width: 120, height: 16),
                    SizedBox(height: 6),
                    SkeletonLoader(width: 80, height: 14),
                  ],
                ),
              ),
              SkeletonLoader(width: 60, height: 14),
            ],
          ),
          SizedBox(height: 16),

          // Review text
          SkeletonLoader(width: double.infinity, height: 14),
          SizedBox(height: 8),
          SkeletonLoader(width: double.infinity, height: 14),
          SizedBox(height: 8),
          SkeletonLoader(width: 250, height: 14),
        ],
      ),
    );
  }
}

/// Booking card skeleton loader
class BookingCardSkeleton extends StatelessWidget {
  const BookingCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceS),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM), // 20px modern radius (matches real card)
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Property info
          Row(
            children: [
              SkeletonLoader(
                width: 100,
                height: 100,
                borderRadius: 12,
              ),
              SizedBox(width: AppDimensions.spaceS),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLoader(width: double.infinity, height: 16),
                    SizedBox(height: AppDimensions.spaceXS),
                    SkeletonLoader(width: 150, height: 14),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppDimensions.spaceS),

          // Booking details
          SkeletonLoader(width: 180, height: 14),
          SizedBox(height: AppDimensions.spaceXS),
          SkeletonLoader(width: 140, height: 14),
          SizedBox(height: AppDimensions.spaceXS),
          SkeletonLoader(width: 100, height: 14),
          SizedBox(height: AppDimensions.spaceS),

          // Status badge
          SkeletonLoader(
            width: 100,
            height: 32,
            borderRadius: 16,
          ),
        ],
      ),
    );
  }
}

/// Grid skeleton loader
class SkeletonGrid extends StatelessWidget {
  const SkeletonGrid({
    this.itemCount = 6,
    this.crossAxisCount = 2,
    super.key,
  });

  final int itemCount;
  final int crossAxisCount;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) => const PropertyCardSkeleton(),
    );
  }
}

/// List item skeleton loader (for lists with leading/trailing widgets)
class ListItemSkeleton extends StatelessWidget {
  const ListItemSkeleton({
    this.hasLeading = true,
    this.hasTrailing = false,
    super.key,
  });

  final bool hasLeading;
  final bool hasTrailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (hasLeading) ...[
          const CircleSkeleton(size: 48),
          const SizedBox(width: 12),
        ],
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonLoader(width: double.infinity, height: 16),
              SizedBox(height: 8),
              SkeletonLoader(width: 200, height: 14),
            ],
          ),
        ),
        if (hasTrailing) ...[
          const SizedBox(width: 12),
          const SkeletonLoader(
            width: 24,
            height: 24,
            borderRadius: 12,
          ),
        ],
      ],
    );
  }
}

/// Stats cards skeleton loader - mimics PremiumStatsCards layout
class StatsCardsSkeleton extends StatelessWidget {
  const StatsCardsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return context.isMobile
        ? Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildStatCardSkeleton(context)),
                  const SizedBox(width: AppDimensions.spaceM),
                  Expanded(child: _buildStatCardSkeleton(context)),
                ],
              ),
              const SizedBox(height: AppDimensions.spaceM),
              Row(
                children: [
                  Expanded(child: _buildStatCardSkeleton(context)),
                  const SizedBox(width: AppDimensions.spaceM),
                  Expanded(child: _buildStatCardSkeleton(context)),
                ],
              ),
            ],
          )
        : Row(
            children: [
              Expanded(child: _buildStatCardSkeleton(context)),
              const SizedBox(width: AppDimensions.spaceM),
              Expanded(child: _buildStatCardSkeleton(context)),
              const SizedBox(width: AppDimensions.spaceM),
              Expanded(child: _buildStatCardSkeleton(context)),
              const SizedBox(width: AppDimensions.spaceM),
              Expanded(child: _buildStatCardSkeleton(context)),
            ],
          );
  }

  Widget _buildStatCardSkeleton(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(
        context.isMobile ? AppDimensions.spaceM : AppDimensions.spaceL,
      ),
      decoration: BoxDecoration(
        color: AppColors.withOpacity(AppColors.surfaceLight, 0.5),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: AppColors.withOpacity(AppColors.borderLight, 0.3),
        ),
      ),
      child: Column(
        children: [
          // Icon skeleton
          SkeletonLoader(
            width: context.isMobile ? AppDimensions.iconL : AppDimensions.iconXL,
            height: context.isMobile ? AppDimensions.iconL : AppDimensions.iconXL,
            borderRadius: AppDimensions.radiusS,
          ),
          const SizedBox(height: AppDimensions.spaceS),

          // Value skeleton (large number)
          SkeletonLoader(
            width: 60,
            height: context.isMobile ? 32 : 48,
            borderRadius: AppDimensions.spaceXXS,
          ),
          const SizedBox(height: AppDimensions.spaceXXS),

          // Label skeleton
          const SkeletonLoader(
            width: 80,
            height: 16,
            borderRadius: 4,
          ),
          const SizedBox(height: AppDimensions.spaceXS),

          // Arrow skeleton (optional)
          const SkeletonLoader(
            width: 16,
            height: 16,
            borderRadius: 8,
          ),
        ],
      ),
    );
  }
}

/// Calendar skeleton loader - mimics timeline/month calendar layout
class CalendarSkeleton extends StatelessWidget {
  const CalendarSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Calendar header (toolbar) skeleton
        Container(
          padding: const EdgeInsets.all(AppDimensions.spaceS),
          child: Row(
            children: [
              const SkeletonLoader(width: 120, height: 40, borderRadius: 20),
              const Spacer(),
              Row(
                children: List.generate(
                  3,
                  (index) => const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: SkeletonLoader(width: 40, height: 40, borderRadius: 20),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppDimensions.spaceS),

        // Calendar days header skeleton
        Row(
          children: List.generate(
            7,
            (index) => Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                alignment: Alignment.center,
                child: const SkeletonLoader(width: 40, height: 14),
              ),
            ),
          ),
        ),

        const SizedBox(height: AppDimensions.spaceXS),

        // Calendar grid skeleton (5 weeks)
        Expanded(
          child: Column(
            children: List.generate(
              5,
              (weekIndex) => Expanded(
                child: Row(
                  children: List.generate(
                    7,
                    (dayIndex) => Expanded(
                      child: Container(
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppDimensions.radiusXS),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Day number
                            const Padding(
                              padding: EdgeInsets.all(4),
                              child: SkeletonLoader(
                                width: 20,
                                height: 14,
                                borderRadius: 4,
                              ),
                            ),
                            // Booking indicator skeleton (optional)
                            if (weekIndex < 3 && dayIndex % 2 == 0)
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4),
                                child: SkeletonLoader(
                                  width: double.infinity,
                                  height: 20,
                                  borderRadius: AppDimensions.radiusXS,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
