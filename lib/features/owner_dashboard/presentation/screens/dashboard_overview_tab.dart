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
import '../providers/unified_dashboard_provider.dart';
import '../../domain/models/unified_dashboard_data.dart';
import '../../data/firebase/firebase_owner_bookings_repository.dart';
import '../../../../core/constants/enums.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/services/logging_service.dart';
import '../../../subscription/widgets/trial_banner.dart';

import '../widgets/dashboard_stats_cards.dart';
import '../widgets/dashboard_charts.dart';
import '../widgets/dashboard_date_selector.dart';

/// Dashboard overview tab - UNIFIED
/// Shows metrics, charts, and recent activity with time period selection
class DashboardOverviewTab extends ConsumerWidget {
  const DashboardOverviewTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final propertiesAsync = ref.watch(ownerPropertiesProvider);
    final dashboardAsync = ref.watch(unifiedDashboardNotifierProvider);
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

            return _buildDashboardContent(
              context,
              ref,
              l10n,
              theme,
              isMobile,
              dashboardAsync,
            );
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
              decoration: BoxDecoration(
                gradient: context.gradients.brandPrimary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.home_work_outlined,
                size: isMobile ? 40 : 50,
                color: Colors.white,
              ),
            ),
            SizedBox(height: isMobile ? 20 : 28),
            Text(
              l10n.ownerWelcomeTitle,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: isMobile ? 22 : 26,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.ownerWelcomeSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(
                  (0.7 * 255).toInt(),
                ),
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
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 24 : 32,
                  vertical: isMobile ? 14 : 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
    AsyncValue<UnifiedDashboardData> dashboardAsync,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(ownerPropertiesProvider);
        ref.invalidate(recentOwnerBookingsProvider);
        ref.invalidate(unifiedDashboardNotifierProvider);
        await Future.wait([
          ref.read(ownerPropertiesProvider.future),
          ref.read(recentOwnerBookingsProvider.future),
          ref.read(unifiedDashboardNotifierProvider.future),
        ]);
      },
      color: theme.colorScheme.primary,
      child: ListView(
        physics: PlatformScrollPhysics.adaptive,
        children: [
          // Trial status banner - shows only when trial is expiring or expired
          const TrialBanner(),

          // Time period selector
          const DashboardDateSelector(),

          // Stats cards section
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.horizontalPadding,
              0,
              context.horizontalPadding,
              isMobile ? 8 : 12,
            ),
            child: dashboardAsync.when(
              data: (data) => DashboardStatsCards(data: data),
              loading: SkeletonLoader.analyticsMetricCards,
              error: (e, s) => _buildErrorState(context, l10n, theme, e),
            ),
          ),

          // Charts section - only show when there are bookings
          dashboardAsync.when(
            data: (data) => DashboardChartsSection(data: data),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),

          // Recent activity section
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.horizontalPadding,
              isMobile ? 8 : 12,
              context.horizontalPadding,
              isMobile ? 16 : 20,
            ),
            child: _buildRecentActivity(context, ref),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
    Object e,
  ) {
    return Center(
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
                    theme.colorScheme.error.withValues(alpha: 0.1),
                    theme.colorScheme.error.withValues(alpha: 0.05),
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
              l10n.ownerErrorLoadingData,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              LoggingService.safeErrorToString(e),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final recentBookingsAsync = ref.watch(recentOwnerBookingsProvider);

    return recentBookingsAsync.when(
      data: (bookings) {
        final activities =
            bookings.map((b) => _convertBookingToActivity(b, l10n)).toList();

        return RecentActivityWidget(
          activities: activities,
          onViewAll: () => context.go(OwnerRoutes.bookings),
          onActivityTap: (bookingId) {
            if (bookings.isEmpty) return; // Safety check
            final ownerBooking = bookings.firstWhere(
              (b) => b.booking.id == bookingId,
              orElse: () => bookings.first,
            );
            showDialog(
              context: context,
              builder:
                  (context) => BookingDetailsDialog(ownerBooking: ownerBooking),
            );
          },
        );
      },
      loading:
          () => Center(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.spaceXL),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
      error:
          (e, s) => RecentActivityWidget(
            activities: const [],
            onViewAll: () => context.go(OwnerRoutes.bookings),
          ),
    );
  }

  ActivityItem _convertBookingToActivity(
    OwnerBooking ownerBooking,
    AppLocalizations l10n,
  ) {
    final booking = ownerBooking.booking;
    final property = ownerBooking.property;
    final unit = ownerBooking.unit;

    final (type, title) = switch (booking.status) {
      BookingStatus.pending => (
        ActivityType.booking,
        l10n.ownerNewBookingReceived,
      ),
      BookingStatus.confirmed => (
        ActivityType.confirmed,
        l10n.ownerBookingConfirmedActivity,
      ),
      BookingStatus.cancelled => (
        ActivityType.cancellation,
        l10n.ownerBookingCancelledActivity,
      ),
      BookingStatus.completed => (
        ActivityType.completed,
        l10n.ownerBookingCompleted,
      ),
    };

    return ActivityItem(
      type: type,
      title: title,
      subtitle: '${property.name} - ${unit.name}',
      timestamp: booking.createdAt,
      bookingId: booking.id,
    );
  }
}
