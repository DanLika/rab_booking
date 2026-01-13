import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_colors.dart';

/// Consistent skeleton colors for light and dark themes
/// Aligned with AppColors design system for professional look
class SkeletonColors {
  // Dark theme colors - match AppColors dark theme
  static const Color darkPrimary = Color(0xFF2D2D3A); // Darker, more subtle
  static const Color darkSecondary = Color(
    0xFF35323D,
  ); // Slightly lighter for shimmer
  static const Color darkCardBackground = Color(
    0xFF1E1E28,
  ); // Match card backgrounds
  static const Color darkBorder = Color(0xFF3D3D4A); // Match section dividers
  static const Color darkHeader = Color(0xFF252330); // Subtle header background

  // Light theme colors - match AppColors light theme
  static const Color lightPrimary = Color(0xFFE8E8F0); // Softer gray
  static const Color lightSecondary = Color(
    0xFFF0F0F5,
  ); // Very light for shimmer
  static const Color lightCardBackground = Colors.white; // Pure white cards
  static const Color lightBorder = Color(0xFFE8E8F0); // Match section dividers
  static const Color lightHeader = Color(0xFFF8F8FA); // Very subtle header
}

/// Skeleton loader placeholder
/// Uses shimmer effect for loading indication
class SkeletonLoader extends StatelessWidget {
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
  static Widget propertyCardHorizontal() =>
      const PropertyCardSkeletonHorizontal();

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
  static Widget analyticsList({int itemCount = 3}) =>
      AnalyticsListSkeleton(itemCount: itemCount);

  /// Analytics progress card skeleton
  static Widget analyticsProgressCard() =>
      const AnalyticsProgressCardSkeleton();

  /// Bookings table skeleton (for table view loading state)
  static Widget bookingsTable({int rowCount = 5}) =>
      BookingsTableSkeleton(rowCount: rowCount);

  /// Notifications list skeleton (for notifications loading state)
  static Widget notificationsList({int itemCount = 6}) =>
      NotificationsListSkeleton(itemCount: itemCount);

  /// Unit Hub Master Panel skeleton
  static Widget unitHubMasterPanel() => const UnitHubMasterPanelSkeleton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? SkeletonColors.darkPrimary : SkeletonColors.lightPrimary,
      highlightColor: isDark ? SkeletonColors.darkSecondary : SkeletonColors.lightSecondary,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white, // Color doesn't matter for mask, but must be opaque
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
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
        color: isDark
            ? SkeletonColors.darkCardBackground
            : SkeletonColors.lightCardBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        border: Border.all(
          color: isDark
              ? SkeletonColors.darkBorder
              : SkeletonColors.lightBorder,
        ),
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
      itemBuilder: (context, index) => const Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: PropertyCardSkeleton(),
      ),
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
    return SkeletonLoader(
      width: size,
      height: size,
      borderRadius: size / 2,
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
        color: isDark
            ? SkeletonColors.darkCardBackground
            : SkeletonColors.lightCardBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        border: Border.all(
          color: isDark
              ? SkeletonColors.darkBorder
              : SkeletonColors.lightBorder,
        ),
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
        color: isDark
            ? SkeletonColors.darkCardBackground
            : SkeletonColors.lightCardBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        border: Border.all(
          color: isDark
              ? SkeletonColors.darkBorder
              : SkeletonColors.lightBorder,
        ),
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

    // Use consistent colors with real booking cards
    final cardBackground = isDark
        ? SkeletonColors.darkCardBackground
        : SkeletonColors.lightCardBackground;
    final borderColor = isDark
        ? SkeletonColors.darkBorder
        : SkeletonColors.lightBorder;
    final headerColor = isDark
        ? SkeletonColors.darkHeader
        : SkeletonColors.lightHeader;

    return Container(
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor.withAlpha((0.5 * 255).toInt())),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: Colors.black.withAlpha((0.3 * 255).toInt()),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withAlpha((0.08 * 255).toInt()),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
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
                color: headerColor,
                border: Border(
                  bottom: BorderSide(
                    color: borderColor.withAlpha((0.5 * 255).toInt()),
                  ),
                ),
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
                      const SkeletonLoader(
                        width: 36,
                        height: 36,
                        borderRadius: 18,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 150),
                              child: const SkeletonLoader(
                                width: double.infinity,
                                height: 16,
                              ),
                            ),
                            const SizedBox(height: 6),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 180),
                              child: const SkeletonLoader(
                                width: double.infinity,
                                height: 14,
                              ),
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
                      const SkeletonLoader(
                        width: 20,
                        height: 20,
                        borderRadius: 10,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 140),
                              child: const SkeletonLoader(
                                width: double.infinity,
                                height: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 100),
                              child: const SkeletonLoader(
                                width: double.infinity,
                                height: 12,
                              ),
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
                      Flexible(
                        child: SkeletonLoader(
                          width: double.infinity,
                          height: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Nights and guests
                  const Row(
                    children: [
                      Flexible(
                        child: SkeletonLoader(
                          width: double.infinity,
                          height: 14,
                        ),
                      ),
                      SizedBox(width: 16),
                      Flexible(
                        child: SkeletonLoader(
                          width: double.infinity,
                          height: 14,
                        ),
                      ),
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
                  const SkeletonLoader(
                    width: double.infinity,
                    height: 4,
                    borderRadius: 2,
                  ),
                ],
              ),
            ),

            SizedBox(height: isMobile ? 12 : 16),

            // Action buttons skeleton (2x2 grid)
            Padding(
              padding: EdgeInsets.fromLTRB(
                isMobile ? 12 : 16,
                0,
                isMobile ? 12 : 16,
                isMobile ? 12 : 16,
              ),
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

/// Notification card skeleton loader
class NotificationCardSkeleton extends StatelessWidget {
  const NotificationCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardBackground = isDark
        ? SkeletonColors.darkCardBackground
        : SkeletonColors.lightCardBackground;
    final borderColor = isDark
        ? SkeletonColors.darkBorder
        : SkeletonColors.lightBorder;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor.withAlpha((0.5 * 255).toInt())),
      ),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon skeleton
            SkeletonLoader(width: 40, height: 40, borderRadius: 20),
            SizedBox(width: 12),
            // Content skeleton
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title skeleton
                  SkeletonLoader(width: double.infinity, height: 16),
                  SizedBox(height: 8),
                  // Message skeleton
                  SkeletonLoader(width: double.infinity, height: 14),
                  SizedBox(height: 4),
                  SkeletonLoader(width: 200, height: 14),
                  SizedBox(height: 8),
                  // Time skeleton
                  SkeletonLoader(width: 80, height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Notifications list skeleton loader
class NotificationsListSkeleton extends StatelessWidget {
  const NotificationsListSkeleton({this.itemCount = 6, super.key});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      itemBuilder: (context, index) => const NotificationCardSkeleton(),
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
          const SkeletonLoader(width: 24, height: 24, borderRadius: 12),
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
            width: context.isMobile
                ? AppDimensions.iconL
                : AppDimensions.iconXL,
            height: context.isMobile
                ? AppDimensions.iconL
                : AppDimensions.iconXL,
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
      children: List.generate(
        4,
        (index) => _buildMetricCardSkeleton(context, isMobile, isTablet),
      ),
    );
  }

  Widget _buildMetricCardSkeleton(
    BuildContext context,
    bool isMobile,
    bool isTablet,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
          colors: isDark
              ? [SkeletonColors.darkPrimary, SkeletonColors.darkCardBackground]
              : [SkeletonColors.lightPrimary, SkeletonColors.lightSecondary],
        ),
      ),
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon skeleton
          SkeletonLoader(
            width: isMobile ? 42 : 50,
            height: isMobile ? 42 : 50,
            borderRadius: 14,
          ),
          SizedBox(height: isMobile ? 8 : 12),
          // Value skeleton
          SkeletonLoader(
            width: isMobile ? 80 : 100,
            height: isMobile ? 24 : 28,
            borderRadius: 6,
          ),
          SizedBox(height: isMobile ? 6 : 8),
          // Title skeleton
          SkeletonLoader(
            width: isMobile ? 60 : 80,
            height: isMobile ? 12 : 13,
            borderRadius: 4,
          ),
          const SizedBox(height: 4),
          // Subtitle skeleton
          SkeletonLoader(
            width: isMobile ? 50 : 70,
            height: isMobile ? 10 : 11,
            borderRadius: 4,
          ),
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
        color: isDark
            ? SkeletonColors.darkCardBackground
            : SkeletonColors.lightCardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? SkeletonColors.darkBorder
              : SkeletonColors.lightBorder,
        ),
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
                    child: SkeletonLoader(
                      height: (50 + (index * 20) % 150).toDouble(),
                      borderRadius: 4,
                    ),
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
              (index) =>
                  const SkeletonLoader(width: 30, height: 10, borderRadius: 4),
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
        color: isDark
            ? SkeletonColors.darkCardBackground
            : SkeletonColors.lightCardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? SkeletonColors.darkBorder
              : SkeletonColors.lightBorder,
        ),
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
              Expanded(
                child: SkeletonLoader(width: 140, height: 16, borderRadius: 4),
              ),
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
        color: isDark
            ? SkeletonColors.darkCardBackground
            : SkeletonColors.lightCardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? SkeletonColors.darkBorder
              : SkeletonColors.lightBorder,
        ),
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
              Expanded(
                child: SkeletonLoader(width: 160, height: 16, borderRadius: 4),
              ),
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
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 24,
        vertical: isMobile ? 12 : 16,
      ),
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

  // Fixed row height for calendar cells (works in both bounded/unbounded contexts)
  static const double _cellHeight = 60.0;
  static const double _headerHeight = 30.0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      // HYBRID LOADING FIX: Use min size to work in unbounded contexts
      mainAxisSize: MainAxisSize.min,
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
                    child: SkeletonLoader(
                      width: 40,
                      height: 40,
                      borderRadius: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppDimensions.spaceS),

        // Calendar days header skeleton
        SizedBox(
          height: _headerHeight,
          child: Row(
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
        ),

        const SizedBox(height: AppDimensions.spaceXS),

        // Calendar grid skeleton (5 weeks) - fixed heights instead of Expanded
        ...List.generate(
          5,
          (weekIndex) => SizedBox(
            height: _cellHeight,
            child: Row(
              children: List.generate(
                7,
                (dayIndex) => Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusXS,
                      ),
                      border: Border.all(
                        color: isDark
                            ? SkeletonColors.darkBorder
                            : SkeletonColors.lightBorder,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
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
      ],
    );
  }
}

/// Bookings table skeleton loader - mimics DataTable layout for bookings
/// Responsive design that works on all screen sizes
class BookingsTableSkeleton extends StatelessWidget {
  const BookingsTableSkeleton({this.rowCount = 5, super.key});

  final int rowCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    // Use consistent colors
    final cardBackground = isDark
        ? SkeletonColors.darkCardBackground
        : SkeletonColors.lightCardBackground;
    final borderColor = isDark
        ? SkeletonColors.darkBorder
        : SkeletonColors.lightBorder;
    final headerColor = isDark
        ? SkeletonColors.darkHeader
        : SkeletonColors.lightHeader;

    return Container(
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor.withAlpha((0.5 * 255).toInt())),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: Colors.black.withAlpha((0.3 * 255).toInt()),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withAlpha((0.08 * 255).toInt()),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Table header skeleton
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 16,
              vertical: isMobile ? 12 : 16,
            ),
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                // Checkbox placeholder
                const SkeletonLoader(width: 24, height: 24, borderRadius: 4),
                const SizedBox(width: 16),
                // Column headers - responsive
                if (!isMobile) ...[
                  const Expanded(
                    flex: 2,
                    child: SkeletonLoader(height: 14, borderRadius: 4),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    flex: 2,
                    child: SkeletonLoader(height: 14, borderRadius: 4),
                  ),
                  const SizedBox(width: 12),
                ],
                const Expanded(
                  child: SkeletonLoader(height: 14, borderRadius: 4),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: SkeletonLoader(height: 14, borderRadius: 4),
                ),
                const SizedBox(width: 12),
                if (!isMobile) ...[
                  const SkeletonLoader(width: 50, height: 14, borderRadius: 4),
                  const SizedBox(width: 12),
                  const SkeletonLoader(width: 50, height: 14, borderRadius: 4),
                  const SizedBox(width: 12),
                ],
                const SkeletonLoader(width: 70, height: 14, borderRadius: 4),
                const SizedBox(width: 12),
                const SkeletonLoader(width: 40, height: 14, borderRadius: 4),
              ],
            ),
          ),

          // Table rows skeleton
          ...List.generate(
            rowCount,
            (index) => _buildTableRowSkeleton(context, isDark, isMobile, index),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRowSkeleton(
    BuildContext context,
    bool isDark,
    bool isMobile,
    int index,
  ) {
    // Use consistent border colors
    final borderColor = isDark
        ? SkeletonColors.darkBorder
        : SkeletonColors.lightBorder;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 16,
        vertical: isMobile ? 10 : 14,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: borderColor.withAlpha((0.5 * 255).toInt())),
        ),
      ),
      child: Row(
        children: [
          // Checkbox placeholder
          const SkeletonLoader(width: 24, height: 24, borderRadius: 4),
          const SizedBox(width: 16),

          // Guest info (name + email)
          if (!isMobile) ...[
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLoader(
                    width: 80 + (index * 10 % 40).toDouble(),
                    height: 14,
                    borderRadius: 4,
                  ),
                  const SizedBox(height: 4),
                  SkeletonLoader(
                    width: 100 + (index * 15 % 50).toDouble(),
                    height: 12,
                    borderRadius: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Property/Unit
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLoader(
                    width: 90 + (index * 8 % 30).toDouble(),
                    height: 14,
                    borderRadius: 4,
                  ),
                  const SizedBox(height: 4),
                  SkeletonLoader(
                    width: 60 + (index * 12 % 40).toDouble(),
                    height: 12,
                    borderRadius: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
          ],

          // Check-in date
          const Expanded(child: SkeletonLoader(height: 14, borderRadius: 4)),
          const SizedBox(width: 12),

          // Check-out date
          const Expanded(child: SkeletonLoader(height: 14, borderRadius: 4)),
          const SizedBox(width: 12),

          // Nights & Guests (desktop only)
          if (!isMobile) ...[
            const SkeletonLoader(width: 30, height: 14, borderRadius: 4),
            const SizedBox(width: 12),
            const SkeletonLoader(width: 30, height: 14, borderRadius: 4),
            const SizedBox(width: 12),
          ],

          // Status badge
          SkeletonLoader(width: 70 + (index * 5 % 20).toDouble(), height: 26),
          const SizedBox(width: 12),

          // Actions menu
          const SkeletonLoader(width: 32, height: 32, borderRadius: 16),
        ],
      ),
    );
  }
}

/// Unit List Skeleton (single unit tile)
class UnitListTileSkeleton extends StatelessWidget {
  const UnitListTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? SkeletonColors.darkCardBackground : SkeletonColors.lightCardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? SkeletonColors.darkBorder : SkeletonColors.lightBorder),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           // Top row: Name + Badge + Actions
           Row(
             children: [
               Expanded(child: SkeletonLoader(height: 16, borderRadius: 4)),
               SizedBox(width: 8),
               SkeletonLoader(width: 60, height: 20, borderRadius: 6), // Badge
               SizedBox(width: 8),
               SkeletonLoader(width: 24, height: 24, borderRadius: 4), // Icon
               SizedBox(width: 4),
               SkeletonLoader(width: 24, height: 24, borderRadius: 4), // Icon
             ],
           ),
           SizedBox(height: 8),
           // Property name
           SkeletonLoader(width: 100, height: 12, borderRadius: 4),
           SizedBox(height: 8),
           // Details
           Row(
             children: [
               SkeletonLoader(width: 16, height: 16, borderRadius: 8),
               SizedBox(width: 4),
               SkeletonLoader(width: 20, height: 12, borderRadius: 4),
               SizedBox(width: 16),
               SkeletonLoader(width: 16, height: 16, borderRadius: 8),
               SizedBox(width: 4),
               SkeletonLoader(width: 40, height: 12, borderRadius: 4),
             ]
           )
        ]
      )
    );
  }
}

/// Unit Hub Master Panel Skeleton (Properties list with Units)
class UnitHubMasterPanelSkeleton extends StatelessWidget {
  const UnitHubMasterPanelSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3, // Show 3 property sections
      itemBuilder: (context, index) => const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: PropertySectionSkeleton(),
      ),
    );
  }
}

/// Property Section Skeleton (Property Header + List of Units)
class PropertySectionSkeleton extends StatelessWidget {
  const PropertySectionSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? SkeletonColors.darkCardBackground : SkeletonColors.lightCardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? SkeletonColors.darkBorder : SkeletonColors.lightBorder,
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          // Property Header
          const Row(
            children: [
              SkeletonLoader(width: 36, height: 36, borderRadius: 8),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLoader(width: 120, height: 16),
                    SizedBox(height: 4),
                    SkeletonLoader(width: 80, height: 12),
                  ],
                ),
              ),
              SizedBox(width: 12),
              SkeletonLoader(width: 80, height: 28, borderRadius: 6),
            ],
          ),
          const SizedBox(height: 16),
          // Units List
          ...List.generate(2, (_) => const UnitListTileSkeleton()),
        ],
      ),
    );
  }
}
