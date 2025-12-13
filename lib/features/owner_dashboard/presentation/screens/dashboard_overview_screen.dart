import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/config/router_owner.dart';
import '../../../../core/theme/gradient_extensions.dart';
import '../../../../core/utils/platform_scroll_physics.dart';
import '../widgets/recent_activity_widget.dart';
import '../widgets/owner_app_drawer.dart';
import '../widgets/booking_details_dialog.dart';
import '../../../../shared/widgets/animations/skeleton_loader.dart';
import '../../../../shared/widgets/common_app_bar.dart';
import '../providers/owner_properties_provider.dart';
import '../providers/owner_bookings_provider.dart';
import '../providers/dashboard_stats_provider.dart';
import '../../data/firebase/firebase_owner_bookings_repository.dart';
import '../../../../core/constants/enums.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/services/logging_service.dart';

/// Dashboard Overview Screen
/// Shows quick stats and recent activity
class DashboardOverviewScreen extends ConsumerWidget {
  const DashboardOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final propertiesAsync = ref.watch(ownerPropertiesProvider);
    final statsAsync = ref.watch(dashboardStatsProvider);
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      appBar: CommonAppBar(
        title: l10n.ownerOverview,
        leadingIcon: Icons.menu,
        onLeadingIconTap: (context) => Scaffold.of(context).openDrawer(),
      ),
      drawer: const OwnerAppDrawer(currentRoute: 'overview'),
      body: Container(
        decoration: BoxDecoration(gradient: context.gradients.pageBackground),
        child: Builder(
          builder: (context) {
            // Show skeleton immediately while loading properties
            if (propertiesAsync.isLoading) {
              return _buildDashboardContent(
                context,
                ref,
                l10n,
                theme,
                isMobile,
                const AsyncValue.loading(),
              );
            }

            final properties = propertiesAsync.value ?? [];

            // If no properties, show welcome screen for new users
            if (properties.isEmpty && !propertiesAsync.hasError) {
              return _buildWelcomeScreen(context, ref, l10n, theme, isMobile);
            }

            return _buildDashboardContent(context, ref, l10n, theme, isMobile, statsAsync);
          },
        ),
      ),
    );
  }

  Widget _buildWelcomeScreen(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    ThemeData theme,
    bool isMobile,
  ) {
    return Center(
      child: SingleChildScrollView(
        physics: PlatformScrollPhysics.adaptive,
        padding: EdgeInsets.all(isMobile ? 20 : 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: isMobile ? 80 : 100,
              height: isMobile ? 80 : 100,
              decoration: BoxDecoration(gradient: context.gradients.brandPrimary, shape: BoxShape.circle),
              child: Icon(Icons.home_work_outlined, size: isMobile ? 40 : 50, color: Colors.white),
            ),
            SizedBox(height: isMobile ? 20 : 28),
            Text(
              l10n.ownerWelcomeTitle,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, fontSize: isMobile ? 22 : 26),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.ownerWelcomeSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha((0.7 * 255).toInt()),
                fontSize: isMobile ? 14 : 15,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isMobile ? 28 : 36),
            FilledButton.icon(
              onPressed: () => context.push(OwnerRoutes.propertyNew),
              icon: const Icon(Icons.add),
              label: Text(l10n.ownerAddFirstProperty),
              style: FilledButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 32, vertical: isMobile ? 14 : 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardContent(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    ThemeData theme,
    bool isMobile,
    AsyncValue<DashboardStats> statsAsync,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(ownerPropertiesProvider);
        ref.invalidate(recentOwnerBookingsProvider);
        ref.invalidate(dashboardStatsProvider);
        await Future.wait([
          ref.read(ownerPropertiesProvider.future),
          ref.read(recentOwnerBookingsProvider.future),
          ref.read(dashboardStatsProvider.future),
        ]);
      },
      color: theme.colorScheme.primary,
      child: ListView(
        physics: PlatformScrollPhysics.adaptive,
        children: [
          // Stats cards section
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.horizontalPadding,
              isMobile ? 16 : 20,
              context.horizontalPadding,
              isMobile ? 8 : 12,
            ),
            child: statsAsync.when(
              data: (stats) => _buildStatsCards(context: context, stats: stats, isMobile: isMobile, theme: theme),
              loading: SkeletonLoader.analyticsMetricCards,
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
                              theme.colorScheme.error.withAlpha((0.1 * 255).toInt()),
                              theme.colorScheme.error.withAlpha((0.05 * 255).toInt()),
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.error_outline_rounded, size: 40, color: theme.colorScheme.error),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.ownerErrorLoadingData,
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        LoggingService.safeErrorToString(e),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withAlpha((0.7 * 255).toInt()),
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
              context.horizontalPadding,
              isMobile ? 16 : 20,
              context.horizontalPadding,
              isMobile ? 16 : 20,
            ),
            child: _buildRecentActivity(context, ref, l10n),
          ),

          // Bottom spacing
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final recentBookingsAsync = ref.watch(recentOwnerBookingsProvider);

    return recentBookingsAsync.when(
      data: (bookings) {
        final activities = bookings.map((b) => _convertBookingToActivity(b, l10n)).toList();

        return RecentActivityWidget(
          activities: activities,
          onViewAll: () => context.go(OwnerRoutes.bookings),
          onActivityTap: (bookingId) {
            final ownerBooking = bookings.firstWhere((b) => b.booking.id == bookingId);
            showDialog(
              context: context,
              builder: (context) => BookingDetailsDialog(ownerBooking: ownerBooking),
            );
          },
        );
      },
      loading: () => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spaceXL),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
          ),
        ),
      ),
      error: (e, s) => RecentActivityWidget(activities: const [], onViewAll: () => context.go(OwnerRoutes.bookings)),
    );
  }

  ActivityItem _convertBookingToActivity(OwnerBooking ownerBooking, AppLocalizations l10n) {
    final booking = ownerBooking.booking;
    final property = ownerBooking.property;
    final unit = ownerBooking.unit;

    final (type, title) = switch (booking.status) {
      BookingStatus.pending => (ActivityType.booking, l10n.ownerNewBookingReceived),
      BookingStatus.confirmed => (ActivityType.confirmed, l10n.ownerBookingConfirmedActivity),
      BookingStatus.cancelled => (ActivityType.cancellation, l10n.ownerBookingCancelledActivity),
      BookingStatus.completed => (ActivityType.completed, l10n.ownerBookingCompleted),
    };

    return ActivityItem(
      type: type,
      title: title,
      subtitle: '${property.name} - ${unit.name}',
      timestamp: booking.createdAt,
      bookingId: booking.id,
    );
  }

  Color _getPurpleShade(int level) => switch (level) {
    1 => const Color(0xFF4A3A8C),
    2 => const Color(0xFF5B4BA8),
    3 => const Color(0xFF6B4CE6),
    4 => const Color(0xFF8B6FF5),
    5 => const Color(0xFFA08BFF),
    6 => const Color(0xFFB8A8FF),
    _ => const Color(0xFF6B4CE6),
  };

  Gradient _createThemeGradient(Color baseColor) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        baseColor,
        baseColor.withValues(alpha: 0.7),
      ],
    );
  }

  Widget _buildStatsCards({
    required BuildContext context,
    required DashboardStats stats,
    required bool isMobile,
    required ThemeData theme,
  }) {
    final l10n = AppLocalizations.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600 && screenWidth < 900;

    return Wrap(
      spacing: isMobile ? 10.0 : 12.0,
      runSpacing: isMobile ? 10.0 : 12.0,
      alignment: WrapAlignment.center,
      children: [
        _buildStatCard(
          context: context,
          title: l10n.ownerMonthlyRevenue,
          value: '€${stats.monthlyRevenue.toStringAsFixed(0)}',
          icon: Icons.euro_rounded,
          gradient: _createThemeGradient(_getPurpleShade(3)),
          isMobile: isMobile,
          isTablet: isTablet,
          theme: theme,
        ),
        _buildStatCard(
          context: context,
          title: l10n.ownerMonthlyBookings,
          value: '${stats.monthlyBookings}',
          icon: Icons.calendar_today_rounded,
          gradient: _createThemeGradient(_getPurpleShade(4)),
          isMobile: isMobile,
          isTablet: isTablet,
          theme: theme,
          animationDelay: 100,
        ),
        _buildStatCard(
          context: context,
          title: l10n.ownerUpcomingCheckIns,
          value: '${stats.upcomingCheckIns}',
          icon: Icons.schedule_rounded,
          gradient: _createThemeGradient(_getPurpleShade(5)),
          isMobile: isMobile,
          isTablet: isTablet,
          theme: theme,
          animationDelay: 200,
        ),
        _buildStatCard(
          context: context,
          title: l10n.ownerOccupancyRate,
          value: '${stats.occupancyRate.toStringAsFixed(1)}%',
          icon: Icons.analytics_rounded,
          gradient: _createThemeGradient(_getPurpleShade(2)),
          isMobile: isMobile,
          isTablet: isTablet,
          theme: theme,
          animationDelay: 300,
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
    required ThemeData theme,
    int animationDelay = 0,
  }) {
    final isDark = theme.brightness == Brightness.dark;

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

    final accentColor = (gradient.colors.isNotEmpty) ? gradient.colors.first : theme.colorScheme.primary;
    final cardBgColor = isDark ? const Color(0xFF1E1E28) : Colors.white;
    final borderColor = isDark ? const Color(0xFF3D3D4A) : const Color(0xFFE8E8F0);
    final valueColor = theme.colorScheme.onSurface;
    final titleColor = theme.colorScheme.onSurface.withValues(alpha: 0.8);

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + animationDelay),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(offset: Offset(0, 20 * (1 - value)), child: child),
        );
      },
      child: Container(
        width: cardWidth,
        height: isMobile ? 130 : 150,
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
          boxShadow: isDark
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 6, offset: const Offset(0, 2))]
              : [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 12 : 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 8 : 10),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentColor, size: isMobile ? 20 : 22),
              ),
              SizedBox(height: isMobile ? 6 : 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: valueColor,
                    height: 1.0,
                    letterSpacing: 0,
                    fontSize: isMobile ? 24 : 28,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: isMobile ? 4 : 6),
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: titleColor,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                  fontSize: isMobile ? 11 : 12,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
