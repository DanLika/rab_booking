import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../../../core/theme/theme_extensions.dart';

/// Dashboard stat card with trend indicator
class DashboardStatsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? trend;
  final bool? isPositive;
  final VoidCallback? onTap;

  const DashboardStatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.trend,
    this.isPositive,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumCard.elevated(
      onTap: onTap,
      padding: const EdgeInsets.all(AppDimensions.spaceL),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon and trend row
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.withOpacity(color, AppColors.opacity10),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: AppDimensions.iconM,
                ),
              ),
              const Spacer(),
              if (trend != null) _buildTrendIndicator(context),
            ],
          ),

          const SizedBox(height: AppDimensions.spaceL),

          // Title
          Text(
            title,
            style: AppTypography.bodyMedium.copyWith(
              color: context.textColorSecondary,
            ),
          ),

          const SizedBox(height: AppDimensions.spaceXXS),

          // Value
          Text(
            value,
            style: AppTypography.h2.copyWith(
              fontWeight: AppTypography.weightBold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendIndicator(BuildContext context) {
    final trendColor = isPositive == true
        ? AppColors.success
        : isPositive == false
            ? AppColors.error
            : context.textColorSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceS,
        vertical: AppDimensions.spaceXXS,
      ),
      decoration: BoxDecoration(
        color: AppColors.withOpacity(trendColor, AppColors.opacity10),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive == true
                ? Icons.trending_up
                : isPositive == false
                    ? Icons.trending_down
                    : Icons.trending_flat,
            size: AppDimensions.iconS,
            color: trendColor,
          ),
          const SizedBox(width: AppDimensions.spaceXXS),
          Text(
            trend!,
            style: AppTypography.small.copyWith(
              color: trendColor,
              fontWeight: AppTypography.weightSemibold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dashboard stats grid
class DashboardStatsGrid extends StatelessWidget {
  final int totalBookings;
  final double totalRevenue;
  final double occupancyRate;
  final int activeListings;
  final String? bookingsTrend;
  final String? revenueTrend;
  final String? occupancyTrend;
  final bool? isBookingsTrendPositive;
  final bool? isRevenueTrendPositive;
  final bool? isOccupancyTrendPositive;

  const DashboardStatsGrid({
    super.key,
    required this.totalBookings,
    required this.totalRevenue,
    required this.occupancyRate,
    required this.activeListings,
    this.bookingsTrend,
    this.revenueTrend,
    this.occupancyTrend,
    this.isBookingsTrendPositive,
    this.isRevenueTrendPositive,
    this.isOccupancyTrendPositive,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;
        final columns = isWide ? 4 : 2;

        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppDimensions.spaceM,
          crossAxisSpacing: AppDimensions.spaceM,
          childAspectRatio: isWide ? 1.5 : 1.3,
          children: [
            DashboardStatsCard(
              title: 'Total Bookings',
              value: totalBookings.toString(),
              icon: Icons.book_online,
              color: AppColors.primary,
              trend: bookingsTrend,
              isPositive: isBookingsTrendPositive,
            ),
            DashboardStatsCard(
              title: 'Revenue',
              value: '€${totalRevenue.toStringAsFixed(0)}',
              icon: Icons.euro,
              color: AppColors.success,
              trend: revenueTrend,
              isPositive: isRevenueTrendPositive,
            ),
            DashboardStatsCard(
              title: 'Occupancy Rate',
              value: '${occupancyRate.toStringAsFixed(1)}%',
              icon: Icons.hotel,
              color: AppColors.warning,
              trend: occupancyTrend,
              isPositive: isOccupancyTrendPositive,
            ),
            DashboardStatsCard(
              title: 'Active Listings',
              value: activeListings.toString(),
              icon: Icons.home_work,
              color: AppColors.info,
            ),
          ],
        );
      },
    );
  }
}
