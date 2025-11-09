import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/config/router_owner.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_color_extensions.dart';
import '../widgets/recent_activity_widget.dart';
import '../widgets/owner_app_drawer.dart';
import '../widgets/booking_details_dialog.dart';
import '../../../../shared/widgets/common_app_bar.dart';
import '../providers/owner_properties_provider.dart';
import '../providers/owner_bookings_provider.dart';
import '../providers/dashboard_stats_provider.dart';
import '../../data/firebase/firebase_owner_bookings_repository.dart';
import '../../../../core/constants/enums.dart';

/// Dashboard overview tab
/// Shows basic overview information and recent activity
class DashboardOverviewTab extends ConsumerWidget {
  const DashboardOverviewTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      appBar: CommonAppBar(
        title: 'Pregled',
        leadingIcon: Icons.menu,
        onLeadingIconTap: (context) => Scaffold.of(context).openDrawer(),
      ),
      drawer: const OwnerAppDrawer(currentRoute: 'overview'),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    theme.colorScheme.veryDarkGray,
                    theme.colorScheme.mediumDarkGray,
                  ]
                : [theme.colorScheme.veryLightGray, Colors.white],
            stops: const [0.0, 0.3],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(ownerPropertiesProvider);
            ref.invalidate(recentOwnerBookingsProvider);
            ref.invalidate(dashboardStatsProvider);
            // Wait for providers to reload
            await Future.wait([
              ref.read(ownerPropertiesProvider.future),
              ref.read(recentOwnerBookingsProvider.future),
              ref.read(dashboardStatsProvider.future),
            ]);
          },
          color: AppColors.primary,
          child: ListView(
            children: [
              // Stats cards section
              Padding(
                padding: EdgeInsets.fromLTRB(
                  isMobile ? 16 : 24,
                  isMobile ? 16 : 20,
                  isMobile ? 16 : 24,
                  isMobile ? 8 : 12,
                ),
                child: statsAsync.when(
                  data: (stats) =>
                      _buildStatsCards(context: context, stats: stats),
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  error: (e, s) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  theme.colorScheme.error.withAlpha(
                                    (0.1 * 255).toInt(),
                                  ),
                                  theme.colorScheme.error.withAlpha(
                                    (0.05 * 255).toInt(),
                                  ),
                                ],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.error_outline_rounded,
                              size: 40,
                              color: theme.colorScheme.error,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Greška prilikom učitavanja podataka',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            e.toString(),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withAlpha(
                                (0.7 * 255).toInt(),
                              ),
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Recent activity section
              Padding(
                padding: EdgeInsets.fromLTRB(
                  isMobile ? 16 : 24,
                  isMobile ? 16 : 20,
                  isMobile ? 16 : 24,
                  isMobile ? 16 : 20,
                ),
                child: _buildRecentActivity(context, ref),
              ),

              // Bottom spacing
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context, WidgetRef ref) {
    final recentBookingsAsync = ref.watch(recentOwnerBookingsProvider);

    return recentBookingsAsync.when(
      data: (bookings) {
        final activities = bookings.map((ownerBooking) {
          return _convertBookingToActivity(ownerBooking);
        }).toList();

        return RecentActivityWidget(
          activities: activities,
          onViewAll: () => context.go(OwnerRoutes.bookings),
          onActivityTap: (bookingId) {
            // Find booking and show details dialog
            final ownerBooking = bookings.firstWhere(
              (b) => b.booking.id == bookingId,
            );
            showDialog(
              context: context,
              builder: (context) =>
                  BookingDetailsDialog(ownerBooking: ownerBooking),
            );
          },
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(AppDimensions.spaceXL),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ),
      error: (e, s) => RecentActivityWidget(
        activities: const [],
        onViewAll: () => context.go(OwnerRoutes.bookings),
      ),
    );
  }

  ActivityItem _convertBookingToActivity(OwnerBooking ownerBooking) {
    final booking = ownerBooking.booking;
    final property = ownerBooking.property;
    final unit = ownerBooking.unit;

    // Determine activity type and details based on booking status
    ActivityType type;
    String title;
    String subtitle;

    switch (booking.status) {
      case BookingStatus.pending:
        type = ActivityType.booking;
        title = 'Nova rezervacija primljena';
        subtitle = '${property.name} - ${unit.name}';
        break;
      case BookingStatus.confirmed:
        type = ActivityType.payment;
        title = 'Rezervacija potvrđena';
        subtitle = '${property.name} - ${unit.name}';
        break;
      case BookingStatus.checkedIn:
        type = ActivityType.booking;
        title = 'Gost check-in';
        subtitle = '${property.name} - ${unit.name}';
        break;
      case BookingStatus.checkedOut:
        type = ActivityType.booking;
        title = 'Gost check-out';
        subtitle = '${property.name} - ${unit.name}';
        break;
      case BookingStatus.cancelled:
        type = ActivityType.cancellation;
        title = 'Rezervacija otkazana';
        subtitle = '${property.name} - ${unit.name}';
        break;
      case BookingStatus.inProgress:
        type = ActivityType.booking;
        title = 'Gost boravi';
        subtitle = '${property.name} - ${unit.name}';
        break;
      case BookingStatus.completed:
        type = ActivityType.booking;
        title = 'Rezervacija završena';
        subtitle = '${property.name} - ${unit.name}';
        break;
      case BookingStatus.blocked:
        type = ActivityType.cancellation;
        title = 'Datum blokiran';
        subtitle = '${property.name} - ${unit.name}';
        break;
    }

    return ActivityItem(
      type: type,
      title: title,
      subtitle: subtitle,
      timestamp: booking.createdAt,
      bookingId: booking.id,
    );
  }

  // Helper method to create theme-aware gradient
  Gradient _createThemeGradient(BuildContext context, List<Color> lightColors) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isDark) {
      // In dark mode, use slightly darker versions but keep full opacity
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: lightColors.map((color) {
          // Darken the color but keep full opacity
          final hsl = HSLColor.fromColor(color);
          return hsl
              .withLightness((hsl.lightness * 0.7).clamp(0.0, 1.0))
              .toColor();
        }).toList(),
      );
    } else {
      // In light mode, use the original colors
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: lightColors,
      );
    }
  }

  Widget _buildStatsCards({
    required BuildContext context,
    required DashboardStats stats,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 900;

    return Wrap(
      spacing: isMobile ? 12.0 : 16.0,
      runSpacing: isMobile ? 12.0 : 16.0,
      alignment: WrapAlignment.center,
      children: [
        _buildStatCard(
          context: context,
          title: 'Zarada ovaj mjesec',
          value: '€${stats.monthlyRevenue.toStringAsFixed(0)}',
          icon: Icons.euro_rounded,
          gradient: _createThemeGradient(context, [
            AppColors.info,
            AppColors.infoDark,
          ]),
          isMobile: isMobile,
          isTablet: isTablet,
          animationDelay: 0,
        ),
        _buildStatCard(
          context: context,
          title: 'Zarada ove godine',
          value: '€${stats.yearlyRevenue.toStringAsFixed(0)}',
          icon: Icons.trending_up_rounded,
          gradient: _createThemeGradient(context, [
            AppColors.primary,
            AppColors.primaryDark,
          ]),
          isMobile: isMobile,
          isTablet: isTablet,
          animationDelay: 100,
        ),
        _buildStatCard(
          context: context,
          title: 'Rezervacije ovaj mjesec',
          value: '${stats.monthlyBookings}',
          icon: Icons.calendar_today_rounded,
          gradient: _createThemeGradient(context, [
            AppColors.primaryLight,
            AppColors.primary,
          ]),
          isMobile: isMobile,
          isTablet: isTablet,
          animationDelay: 200,
        ),
        _buildStatCard(
          context: context,
          title: 'Nadolazeći check-in',
          value: '${stats.upcomingCheckIns}',
          icon: Icons.schedule_rounded,
          gradient: _createThemeGradient(context, [
            AppColors.activityPayment,
            AppColors.infoDark,
          ]),
          isMobile: isMobile,
          isTablet: isTablet,
          animationDelay: 300,
        ),
        _buildStatCard(
          context: context,
          title: 'Aktivne nekretnine',
          value: '${stats.activeProperties}',
          icon: Icons.villa_rounded,
          gradient: _createThemeGradient(context, [
            AppColors.textSecondary,
            AppColors.textDisabled,
          ]),
          isMobile: isMobile,
          isTablet: isTablet,
          animationDelay: 400,
        ),
        _buildStatCard(
          context: context,
          title: 'Popunjenost',
          value: '${stats.occupancyRate.toStringAsFixed(1)}%',
          icon: Icons.analytics_rounded,
          gradient: _createThemeGradient(context, [
            AppColors.textDisabled,
            AppColors.textSecondary,
          ]),
          isMobile: isMobile,
          isTablet: isTablet,
          animationDelay: 500,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Gradient gradient,
    required bool isMobile,
    required bool isTablet,
    int animationDelay = 0,
  }) {
    final theme = Theme.of(context);

    // Calculate responsive width
    final screenWidth = MediaQuery.of(context).size.width;
    final spacing = isMobile ? 12.0 : 16.0;

    double cardWidth;
    if (isMobile) {
      // Mobile: 2 cards per row
      cardWidth =
          (screenWidth - (spacing * 3 + 32)) / 2; // 32 = left/right padding
    } else if (isTablet) {
      // Tablet: 3 cards per row
      cardWidth = (screenWidth - (spacing * 4 + 48)) / 3;
    } else {
      // Desktop: fixed width
      cardWidth = 280.0;
    }

    // Extract primary color from gradient for shadow
    final primaryColor = (gradient.colors.isNotEmpty)
        ? gradient.colors.first
        : AppColors.primary;

    // Theme-aware text and icon colors - full opacity
    final textColor = Colors.white;
    final iconColor = Colors.white;
    final iconBgColor = Colors.white.withAlpha((0.2 * 255).toInt());

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + animationDelay),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        width: cardWidth,
        height: isMobile ? 160 : 180,
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withAlpha((0.12 * 255).toInt()),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(20),
            ),
            padding: EdgeInsets.all(isMobile ? 14 : 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon container
                Container(
                  padding: EdgeInsets.all(isMobile ? 10 : 12),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: iconColor, size: isMobile ? 22 : 26),
                ),
                SizedBox(height: isMobile ? 8 : 12),

                // Value
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      height: 1.0,
                      letterSpacing: -1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: isMobile ? 6 : 8),

                // Title
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
