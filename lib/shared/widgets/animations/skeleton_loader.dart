import 'package:flutter/material.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_colors.dart';

/// Skeleton loader with shimmer effect
/// Replaces CircularProgressIndicator for better UX
class SkeletonLoader extends StatefulWidget {
  const SkeletonLoader({this.width, this.height, this.borderRadius = 8.0, super.key});

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

  /// Analytics page skeleton (for analytics dashboard)
  static Widget analytics() => const AnalyticsSkeleton();

  /// Analytics metric cards skeleton
  static Widget analyticsMetricCards() => const AnalyticsMetricCardsSkeleton();

  /// Analytics chart skeleton
  static Widget analyticsChart() => const AnalyticsChartSkeleton();

  /// Analytics list skeleton
  static Widget analyticsList({int itemCount = 3}) => AnalyticsListSkeleton(itemCount: itemCount);

  /// Analytics progress card skeleton
  static Widget analyticsProgressCard() => const AnalyticsProgressCardSkeleton();

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();

    _animation = Tween<double>(
      begin: -2.0,
      end: 2.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: isDark ? [Colors.grey[800]!, Colors.grey[700]!] : [Colors.grey[300]!, Colors.grey[200]!],
              stops: const [0.0, 0.3],
            ),
          ),
        );
      },
    );
  }
}

/// Property card skeleton loader
class PropertyCardSkeleton extends StatelessWidget {
  const PropertyCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusS), // 12px modern radius,
        border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[200]!),
      ),
      child: const ClipRect(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image skeleton
            SkeletonLoader(height: 160, borderRadius: 12),

            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title skeleton
                  SkeletonLoader(width: double.infinity, height: 20),
                  SizedBox(height: 8),

                  // Location skeleton
                  SkeletonLoader(width: 150, height: 16),
                  SizedBox(height: 12),

                  // Price skeleton
                  Row(
                    children: [
                      SkeletonLoader(width: 80, height: 24),
                      Spacer(),
                      SkeletonLoader(width: 60, height: 16, borderRadius: 4),
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
  const PropertyListSkeleton({this.itemCount = 3, super.key});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: (context, index) =>
          const Padding(padding: EdgeInsets.only(bottom: 16), child: PropertyCardSkeleton()),
    );
  }
}

/// Text skeleton loader - for text lines
class TextSkeleton extends StatelessWidget {
  const TextSkeleton({this.width, this.height = 14, super.key});

  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(width: width, height: height, borderRadius: 4);
  }
}

/// Circle skeleton loader - for avatars
class CircleSkeleton extends StatelessWidget {
  const CircleSkeleton({this.size = 40, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: isDark ? [Colors.grey[800]!, Colors.grey[700]!] : [Colors.grey[300]!, Colors.grey[200]!],
          stops: const [0.0, 0.3],
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusS), // 12px modern radius,
        border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[200]!),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image skeleton
          SkeletonLoader(width: 280, height: 200, borderRadius: 12),

          // Content skeleton
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title skeleton
                  SkeletonLoader(width: double.infinity, height: 20),
                  SizedBox(height: 8),

                  // Location skeleton
                  SkeletonLoader(width: 150, height: 16),
                  SizedBox(height: 12),

                  // Stats skeleton
                  Row(
                    children: [
                      SkeletonLoader(width: 60, height: 16),
                      SizedBox(width: 16),
                      SkeletonLoader(width: 60, height: 16),
                      SizedBox(width: 16),
                      SkeletonLoader(width: 60, height: 16),
                    ],
                  ),

                  Spacer(),

                  // Price skeleton
                  Row(
                    children: [
                      SkeletonLoader(width: 80, height: 24),
                      Spacer(),
                      SkeletonLoader(width: 60, height: 16, borderRadius: 4),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusS), // 12px modern radius,
        border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[200]!),
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

/// Booking card skeleton loader - improved to match real card layout
class BookingCardSkeleton extends StatelessWidget {
  const BookingCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[200]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              padding: EdgeInsets.all(isMobile ? 12 : 16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800]!.withAlpha((0.3 * 255).toInt()) : Colors.grey[100]!,
                border: Border(bottom: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[200]!)),
              ),
              child: const Row(
                children: [
                  // Status badge skeleton
                  SkeletonLoader(width: 100, height: 34),
                  Spacer(),
                  // Booking ID skeleton
                  SkeletonLoader(width: 80, height: 16),
                ],
              ),
            ),

            // Card Body
            Padding(
              padding: EdgeInsets.all(isMobile ? 12 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Guest info
                  Row(
                    children: [
                      // Avatar skeleton
                      const SkeletonLoader(width: 36, height: 36, borderRadius: 18),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 150),
                              child: const SkeletonLoader(width: double.infinity, height: 16),
                            ),
                            const SizedBox(height: 6),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 180),
                              child: const SkeletonLoader(width: double.infinity, height: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isMobile ? 12 : 16),

                  // Property/Unit info
                  Row(
                    children: [
                      const SkeletonLoader(width: 20, height: 20, borderRadius: 10),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 140),
                              child: const SkeletonLoader(width: double.infinity, height: 14),
                            ),
                            const SizedBox(height: 4),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 100),
                              child: const SkeletonLoader(width: double.infinity, height: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isMobile ? 12 : 16),

                  // Date range
                  const Row(
                    children: [
                      SkeletonLoader(width: 20, height: 20, borderRadius: 10),
                      SizedBox(width: 8),
                      Flexible(child: SkeletonLoader(width: double.infinity, height: 14)),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Nights and guests
                  const Row(
                    children: [
                      Flexible(child: SkeletonLoader(width: double.infinity, height: 14)),
                      SizedBox(width: 16),
                      Flexible(child: SkeletonLoader(width: double.infinity, height: 14)),
                    ],
                  ),
                  SizedBox(height: isMobile ? 12 : 16),

                  // Payment info
                  Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SkeletonLoader(width: 60, height: 12),
                            SizedBox(height: 4),
                            SkeletonLoader(width: 80, height: 20),
                          ],
                        ),
                      ),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SkeletonLoader(width: 60, height: 12),
                            SizedBox(height: 4),
                            SkeletonLoader(width: 70, height: 18),
                          ],
                        ),
                      ),
                      if (!isMobile)
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SkeletonLoader(width: 70, height: 12),
                              SizedBox(height: 4),
                              SkeletonLoader(width: 70, height: 18),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Payment progress bar
                  const SkeletonLoader(width: double.infinity, height: 4, borderRadius: 2),
                ],
              ),
            ),

            SizedBox(height: isMobile ? 12 : 16),

            // Action buttons skeleton (2x2 grid)
            Padding(
              padding: EdgeInsets.fromLTRB(isMobile ? 12 : 16, 0, isMobile ? 12 : 16, isMobile ? 12 : 16),
              child: const Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: SkeletonLoader(height: 40)),
                      SizedBox(width: 8),
                      Expanded(child: SkeletonLoader(height: 40)),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: SkeletonLoader(height: 40)),
                      SizedBox(width: 8),
                      Expanded(child: SkeletonLoader(height: 40)),
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

/// Grid skeleton loader
class SkeletonGrid extends StatelessWidget {
  const SkeletonGrid({this.itemCount = 6, this.crossAxisCount = 2, super.key});

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
  const ListItemSkeleton({this.hasLeading = true, this.hasTrailing = false, super.key});

  final bool hasLeading;
  final bool hasTrailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (hasLeading) ...[const CircleSkeleton(size: 48), const SizedBox(width: 12)],
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
        if (hasTrailing) ...[const SizedBox(width: 12), const SkeletonLoader(width: 24, height: 24, borderRadius: 12)],
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
      padding: EdgeInsets.all(context.isMobile ? AppDimensions.spaceM : AppDimensions.spaceL),
      decoration: BoxDecoration(
        color: AppColors.withOpacity(AppColors.surfaceLight, 0.5),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.withOpacity(AppColors.borderLight, 0.3)),
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
          SkeletonLoader(width: 60, height: context.isMobile ? 32 : 48, borderRadius: AppDimensions.spaceXXS),
          const SizedBox(height: AppDimensions.spaceXXS),

          // Label skeleton
          const SkeletonLoader(width: 80, height: 16, borderRadius: 4),
          const SizedBox(height: AppDimensions.spaceXS),

          // Arrow skeleton (optional)
          const SkeletonLoader(width: 16, height: 16),
        ],
      ),
    );
  }
}

/// Analytics metric cards skeleton loader - mimics AnalyticsScreen metric cards
class AnalyticsMetricCardsSkeleton extends StatelessWidget {
  const AnalyticsMetricCardsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 900;
    final spacing = isMobile ? 12.0 : 16.0;

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      alignment: WrapAlignment.center,
      children: List.generate(4, (index) => _buildMetricCardSkeleton(context, isMobile, isTablet)),
    );
  }

  Widget _buildMetricCardSkeleton(BuildContext context, bool isMobile, bool isTablet) {
    final screenWidth = MediaQuery.of(context).size.width;
    final spacing = isMobile ? 12.0 : 16.0;

    double cardWidth;
    if (isMobile) {
      cardWidth = (screenWidth - (spacing * 3 + 32)) / 2;
    } else if (isTablet) {
      cardWidth = (screenWidth - (spacing * 4 + 48)) / 3;
    } else {
      cardWidth = 280.0;
    }

    return Container(
      width: cardWidth,
      height: isMobile ? 160 : 180,
      constraints: const BoxConstraints(maxWidth: 320),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.grey.withValues(alpha: 0.3), Colors.grey.withValues(alpha: 0.2)],
        ),
      ),
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon skeleton
          SkeletonLoader(width: isMobile ? 42 : 50, height: isMobile ? 42 : 50, borderRadius: 14),
          SizedBox(height: isMobile ? 8 : 12),
          // Value skeleton
          SkeletonLoader(width: isMobile ? 80 : 100, height: isMobile ? 24 : 28, borderRadius: 6),
          SizedBox(height: isMobile ? 6 : 8),
          // Title skeleton
          SkeletonLoader(width: isMobile ? 60 : 80, height: isMobile ? 12 : 13, borderRadius: 4),
          const SizedBox(height: 4),
          // Subtitle skeleton
          SkeletonLoader(width: isMobile ? 50 : 70, height: isMobile ? 10 : 11, borderRadius: 4),
        ],
      ),
    );
  }
}

/// Analytics chart skeleton loader - mimics revenue/bookings chart cards
class AnalyticsChartSkeleton extends StatelessWidget {
  const AnalyticsChartSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    final chartHeight = screenWidth > 900
        ? 400.0
        : screenWidth > 600
        ? 350.0
        : 300.0;

    return Container(
      height: chartHeight,
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[200]!),
      ),
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          const Row(
            children: [
              SkeletonLoader(width: 34, height: 34),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLoader(width: 120, height: 16, borderRadius: 4),
                    SizedBox(height: 4),
                    SkeletonLoader(width: 180, height: 12, borderRadius: 4),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Chart area skeleton
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(
                isMobile ? 5 : 8,
                (index) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: SkeletonLoader(height: (50 + (index * 20) % 150).toDouble(), borderRadius: 4),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // X-axis labels skeleton
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              isMobile ? 5 : 8,
              (index) => const SkeletonLoader(width: 30, height: 10, borderRadius: 4),
            ),
          ),
        ],
      ),
    );
  }
}

/// Analytics list skeleton loader - mimics top properties list
class AnalyticsListSkeleton extends StatelessWidget {
  const AnalyticsListSkeleton({this.itemCount = 3, super.key});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[200]!),
      ),
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Row(
            children: [
              SkeletonLoader(width: 34, height: 34),
              SizedBox(width: 12),
              Expanded(child: SkeletonLoader(width: 140, height: 16, borderRadius: 4)),
            ],
          ),
          const SizedBox(height: 8),
          const SkeletonLoader(width: 200, height: 12, borderRadius: 4),
          const SizedBox(height: 20),
          // List items
          ...List.generate(
            itemCount,
            (index) => const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  CircleSkeleton(size: 32),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonLoader(width: 120, height: 14, borderRadius: 4),
                        SizedBox(height: 4),
                        SkeletonLoader(width: 180, height: 12, borderRadius: 4),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      SkeletonLoader(width: 60, height: 14, borderRadius: 4),
                      SizedBox(height: 4),
                      SkeletonLoader(width: 40, height: 12, borderRadius: 4),
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

/// Analytics progress card skeleton - mimics widget analytics card with progress bars
class AnalyticsProgressCardSkeleton extends StatelessWidget {
  const AnalyticsProgressCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[200]!),
      ),
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              SkeletonLoader(width: 34, height: 34),
              SizedBox(width: 12),
              Expanded(child: SkeletonLoader(width: 160, height: 16, borderRadius: 4)),
            ],
          ),
          SizedBox(height: 8),
          SkeletonLoader(width: 220, height: 12, borderRadius: 4),
          SizedBox(height: 20),
          // First metric
          SkeletonLoader(width: 100, height: 14, borderRadius: 4),
          SizedBox(height: 8),
          Row(
            children: [
              SkeletonLoader(width: 60, height: 24, borderRadius: 4),
              SizedBox(width: 8),
              SkeletonLoader(width: 80, height: 12, borderRadius: 4),
            ],
          ),
          SizedBox(height: 8),
          SkeletonLoader(width: double.infinity, height: 8, borderRadius: 4),
          SizedBox(height: 20),
          // Second metric
          SkeletonLoader(width: 100, height: 14, borderRadius: 4),
          SizedBox(height: 8),
          Row(
            children: [
              SkeletonLoader(width: 80, height: 24, borderRadius: 4),
              SizedBox(width: 8),
              SkeletonLoader(width: 80, height: 12, borderRadius: 4),
            ],
          ),
          SizedBox(height: 8),
          SkeletonLoader(width: double.infinity, height: 8, borderRadius: 4),
        ],
      ),
    );
  }
}

/// Full analytics page skeleton - combines all analytics skeletons
class AnalyticsSkeleton extends StatelessWidget {
  const AnalyticsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isDesktop = screenWidth > 900;

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: isMobile ? 12 : 16),
      children: [
        // Metric cards
        const AnalyticsMetricCardsSkeleton(),
        SizedBox(height: isMobile ? 16 : 20),

        // Charts section
        if (isDesktop)
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: AnalyticsChartSkeleton()),
              SizedBox(width: 16),
              Expanded(child: AnalyticsChartSkeleton()),
            ],
          )
        else ...[
          const AnalyticsChartSkeleton(),
          SizedBox(height: isMobile ? 16 : 20),
          const AnalyticsChartSkeleton(),
        ],

        SizedBox(height: isMobile ? 16 : 20),

        // Bottom section
        if (isDesktop)
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    AnalyticsListSkeleton(),
                    SizedBox(height: 20),
                    AnalyticsProgressCardSkeleton(),
                  ],
                ),
              ),
              SizedBox(width: 16),
              Expanded(child: AnalyticsProgressCardSkeleton()),
            ],
          )
        else ...[
          const AnalyticsListSkeleton(),
          SizedBox(height: isMobile ? 16 : 20),
          const AnalyticsProgressCardSkeleton(),
          SizedBox(height: isMobile ? 16 : 20),
          const AnalyticsProgressCardSkeleton(),
        ],

        SizedBox(height: isMobile ? 12 : 16),
      ],
    );
  }
}

/// Calendar skeleton loader - mimics timeline/month calendar layout
class CalendarSkeleton extends StatelessWidget {
  const CalendarSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                          border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Day number
                            const Padding(
                              padding: EdgeInsets.all(4),
                              child: SkeletonLoader(width: 20, height: 14, borderRadius: 4),
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
