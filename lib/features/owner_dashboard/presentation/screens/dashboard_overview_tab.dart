import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:graphic/graphic.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/config/router_owner.dart';
import '../../../../core/theme/gradient_extensions.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/platform_scroll_physics.dart';
import '../widgets/recent_activity_widget.dart';
import '../widgets/owner_app_drawer.dart';
import '../widgets/booking_details_dialog.dart';
import '../../../../shared/widgets/animations/skeleton_loader.dart';
import '../../../../shared/widgets/animations/animated_empty_state.dart';
import '../../../../shared/widgets/common_app_bar.dart';
import '../../../../shared/widgets/custom_date_range_picker.dart';
import '../../../../shared/widgets/app_filter_chip.dart';
import '../providers/owner_properties_provider.dart';
import '../providers/owner_bookings_provider.dart';
import '../providers/unified_dashboard_provider.dart';
import '../../domain/models/unified_dashboard_data.dart';
import '../../data/firebase/firebase_owner_bookings_repository.dart';
import '../../../../core/constants/enums.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/services/logging_service.dart';

/// Dashboard overview tab - UNIFIED
/// Shows metrics, charts, and recent activity with time period selection
class DashboardOverviewTab extends ConsumerWidget {
  const DashboardOverviewTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final propertiesAsync = ref.watch(ownerPropertiesProvider);
    final dashboardAsync = ref.watch(unifiedDashboardNotifierProvider);
    final dateRange = ref.watch(dashboardDateRangeNotifierProvider);
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
                dateRange,
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
              dateRange,
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
    DateRangeFilter dateRange,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;

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
          // Time period selector
          _DateRangeSelector(dateRange: dateRange),

          // Stats cards section
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.horizontalPadding,
              0,
              context.horizontalPadding,
              isMobile ? 8 : 12,
            ),
            child: dashboardAsync.when(
              data: (data) => _buildStatsCards(context: context, data: data),
              loading: SkeletonLoader.analyticsMetricCards,
              error: (e, s) => _buildErrorState(context, l10n, theme, e),
            ),
          ),

          // Charts section - only show when there are bookings
          dashboardAsync.when(
            data: (data) => data.bookings == 0
                ? const SizedBox.shrink()
                : Padding(
                    padding: EdgeInsets.fromLTRB(
                      context.horizontalPadding,
                      isMobile ? 12 : 16,
                      context.horizontalPadding,
                      isMobile ? 12 : 16,
                    ),
                    child: isDesktop
                        ? _buildDesktopChartsRow(data, l10n)
                        : _buildStackedCharts(data, isMobile, l10n),
                  ),
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
                    theme.colorScheme.error.withAlpha((0.1 * 255).toInt()),
                    theme.colorScheme.error.withAlpha((0.05 * 255).toInt()),
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
                color: theme.colorScheme.onSurface.withAlpha((0.7 * 255).toInt()),
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

  /// Desktop layout - Charts side-by-side
  Widget _buildDesktopChartsRow(UnifiedDashboardData data, AppLocalizations l10n) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _RevenueChart(data: data.revenueHistory)),
        const SizedBox(width: 16),
        Expanded(child: _BookingsChart(data: data.bookingHistory)),
      ],
    );
  }

  /// Mobile/Tablet layout - Charts stacked
  Widget _buildStackedCharts(
    UnifiedDashboardData data,
    bool isMobile,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RevenueChart(data: data.revenueHistory),
        SizedBox(height: isMobile ? 16 : 20),
        _BookingsChart(data: data.bookingHistory),
      ],
    );
  }

  Widget _buildRecentActivity(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final recentBookingsAsync = ref.watch(recentOwnerBookingsProvider);

    return recentBookingsAsync.when(
      data: (bookings) {
        final activities = bookings
            .map((b) => _convertBookingToActivity(b, l10n))
            .toList();

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
              builder: (context) => BookingDetailsDialog(
                ownerBooking: ownerBooking,
              ),
            );
          },
        );
      },
      loading: () => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spaceXL),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ),
      error: (e, s) => RecentActivityWidget(
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

  Color _getPurpleShade(BuildContext context, int level) => switch (level) {
    1 => const Color(0xFF4A3A8C),
    2 => const Color(0xFF5B4BA8),
    3 => const Color(0xFF6B4CE6),
    4 => const Color(0xFF8B6FF5),
    5 => const Color(0xFFA08BFF),
    6 => const Color(0xFFB8A8FF),
    _ => const Color(0xFF6B4CE6),
  };

  Gradient _createThemeGradient(BuildContext context, Color baseColor) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [baseColor, baseColor.withValues(alpha: 0.7)],
    );
  }

  Widget _buildStatsCards({
    required BuildContext context,
    required UnifiedDashboardData data,
  }) {
    final l10n = AppLocalizations.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 900;

    return Wrap(
      spacing: isMobile ? 10.0 : 12.0,
      runSpacing: isMobile ? 10.0 : 12.0,
      alignment: WrapAlignment.center,
      children: [
        _buildStatCard(
          context: context,
          title: l10n.ownerDashboardRevenue,
          value: '€${data.revenue.toStringAsFixed(0)}',
          icon: Icons.euro_rounded,
          gradient: _createThemeGradient(context, _getPurpleShade(context, 3)),
          isMobile: isMobile,
          isTablet: isTablet,
        ),
        _buildStatCard(
          context: context,
          title: l10n.ownerDashboardBookings,
          value: '${data.bookings}',
          icon: Icons.calendar_today_rounded,
          gradient: _createThemeGradient(context, _getPurpleShade(context, 4)),
          isMobile: isMobile,
          isTablet: isTablet,
          animationDelay: 100,
        ),
        _buildStatCard(
          context: context,
          title: l10n.ownerUpcomingCheckIns,
          value: '${data.upcomingCheckIns}',
          icon: Icons.schedule_rounded,
          gradient: _createThemeGradient(context, _getPurpleShade(context, 5)),
          isMobile: isMobile,
          isTablet: isTablet,
          animationDelay: 200,
        ),
        _buildStatCard(
          context: context,
          title: l10n.ownerOccupancyRate,
          value: '${data.occupancyRate.toStringAsFixed(1)}%',
          icon: Icons.analytics_rounded,
          gradient: _createThemeGradient(context, _getPurpleShade(context, 2)),
          isMobile: isMobile,
          isTablet: isTablet,
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
    int animationDelay = 0,
  }) {
    final theme = Theme.of(context);
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

    final accentColor = gradient.colors.isNotEmpty
        ? gradient.colors.first
        : Theme.of(context).colorScheme.primary;
    final cardBgColor = isDark ? const Color(0xFF1E1E28) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF3D3D4A)
        : const Color(0xFFE8E8F0);
    final valueColor = theme.colorScheme.onSurface;
    final titleColor = theme.colorScheme.onSurface.withValues(alpha: 0.8);

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
        height: isMobile ? 130 : 150,
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
          boxShadow: isDark
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
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

/// Time period selector widget
class _DateRangeSelector extends ConsumerWidget {
  final DateRangeFilter dateRange;

  const _DateRangeSelector({required this.dateRange});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.horizontalPadding,
        vertical: isMobile ? 12 : 16,
      ),
      color: Colors.transparent,
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: PlatformScrollPhysics.adaptive,
              child: Row(
                children: [
                  AppFilterChip(
                    label: l10n.ownerAnalyticsLastWeek,
                    selected: dateRange.preset == 'week',
                    onSelected: () {
                      ref
                          .read(dashboardDateRangeNotifierProvider.notifier)
                          .setPreset('week');
                    },
                  ),
                  const SizedBox(width: 8),
                  AppFilterChip(
                    label: l10n.ownerDashboardThisMonth,
                    selected: dateRange.preset == 'month',
                    onSelected: () {
                      ref
                          .read(dashboardDateRangeNotifierProvider.notifier)
                          .setPreset('month');
                    },
                  ),
                  const SizedBox(width: 8),
                  AppFilterChip(
                    label: l10n.ownerAnalyticsLastQuarter,
                    selected: dateRange.preset == 'quarter',
                    onSelected: () {
                      ref
                          .read(dashboardDateRangeNotifierProvider.notifier)
                          .setPreset('quarter');
                    },
                  ),
                  const SizedBox(width: 8),
                  AppFilterChip(
                    label: l10n.ownerAnalyticsLastYear,
                    selected: dateRange.preset == 'year',
                    onSelected: () {
                      ref
                          .read(dashboardDateRangeNotifierProvider.notifier)
                          .setPreset('year');
                    },
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 40,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showCustomDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                          initialDateRange: DateTimeRange(
                            start: dateRange.startDate,
                            end: dateRange.endDate,
                          ),
                        );
                        if (picked != null) {
                          ref
                              .read(dashboardDateRangeNotifierProvider.notifier)
                              .setCustomRange(picked.start, picked.end);
                        }
                      },
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(l10n.ownerAnalyticsCustomRange),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        side: BorderSide(
                          color: context.gradients.sectionBorder,
                          width: 1.5,
                        ),
                      ),
                    ),
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

/// Revenue Chart widget
class _RevenueChart extends StatelessWidget {
  final List<RevenueDataPoint> data;

  const _RevenueChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (data.isEmpty) {
      return _buildEmptyState(context, l10n, theme, Icons.insert_chart_outlined_rounded);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final chartHeight = screenWidth > 900 ? 300.0 : screenWidth > 600 ? 260.0 : 220.0;

        return SizedBox(
          height: chartHeight,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppShadows.getElevation(1, isDark: theme.brightness == Brightness.dark),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  color: context.gradients.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? 12 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildChartHeader(
                        context,
                        theme,
                        Icons.show_chart,
                        l10n.ownerAnalyticsRevenueTitle,
                        l10n.ownerAnalyticsRevenueSubtitle,
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: Chart(
                          data: data.asMap().entries.map((e) => {
                            'index': e.key,
                            'label': e.value.label,
                            'amount': e.value.amount,
                          }).toList(),
                          variables: {
                            'index': Variable(accessor: (Map map) => map['index'] as num),
                            'amount': Variable(
                              accessor: (Map map) => map['amount'] as num,
                              scale: LinearScale(min: 0),
                            ),
                          },
                          coord: RectCoord(horizontalRangeUpdater: Defaults.horizontalRangeEvent),
                          marks: [
                            AreaMark(
                              shape: ShapeEncode(value: BasicAreaShape(smooth: true)),
                              color: ColorEncode(value: theme.colorScheme.primary.withValues(alpha: 0.15)),
                              entrance: {MarkEntrance.y},
                            ),
                            LineMark(
                              shape: ShapeEncode(value: BasicLineShape(smooth: true)),
                              size: SizeEncode(value: 3),
                              color: ColorEncode(value: theme.colorScheme.primary),
                              entrance: {MarkEntrance.y},
                            ),
                            PointMark(
                              shape: ShapeEncode(value: CircleShape()),
                              size: SizeEncode(value: 8),
                              color: ColorEncode(value: theme.colorScheme.primary),
                              entrance: {MarkEntrance.opacity},
                            ),
                          ],
                          axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
                          selections: {
                            'touchMove': PointSelection(
                              on: {GestureType.hover},
                              devices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
                            ),
                          },
                          tooltip: TooltipGuide(
                            backgroundColor: theme.colorScheme.surface,
                            elevation: 8,
                            textStyle: AppTypography.bodySmall.copyWith(color: theme.colorScheme.onSurface),
                          ),
                          crosshair: CrosshairGuide(followPointer: [false, true]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Bookings Chart widget
class _BookingsChart extends StatelessWidget {
  final List<BookingDataPoint> data;

  const _BookingsChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (data.isEmpty) {
      return _buildEmptyState(context, l10n, theme, Icons.event_busy_rounded);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final chartHeight = screenWidth > 900 ? 300.0 : screenWidth > 600 ? 260.0 : 220.0;

        return SizedBox(
          height: chartHeight,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppShadows.getElevation(1, isDark: theme.brightness == Brightness.dark),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  color: context.gradients.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? 12 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildChartHeader(
                        context,
                        theme,
                        Icons.event,
                        l10n.ownerAnalyticsBookingsTitle,
                        l10n.ownerAnalyticsBookingsSubtitle,
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: Chart(
                          data: data.asMap().entries.map((e) => {
                            'index': e.key,
                            'label': e.value.label,
                            'count': e.value.count,
                          }).toList(),
                          variables: {
                            'index': Variable(accessor: (Map map) => map['index'] as num),
                            'count': Variable(
                              accessor: (Map map) => map['count'] as num,
                              scale: LinearScale(min: 0),
                            ),
                          },
                          coord: RectCoord(horizontalRangeUpdater: Defaults.horizontalRangeEvent),
                          marks: [
                            IntervalMark(
                              shape: ShapeEncode(value: RectShape(borderRadius: BorderRadius.circular(8))),
                              elevation: ElevationEncode(value: 2),
                              gradient: GradientEncode(
                                value: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    theme.colorScheme.primary,
                                    theme.colorScheme.primary.withValues(alpha: 0.7),
                                  ],
                                ),
                              ),
                              entrance: {MarkEntrance.y},
                            ),
                          ],
                          axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
                          selections: {
                            'touchMove': PointSelection(
                              on: {GestureType.hover},
                              devices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
                            ),
                          },
                          tooltip: TooltipGuide(
                            backgroundColor: theme.colorScheme.surface,
                            elevation: 8,
                            textStyle: AppTypography.bodySmall.copyWith(color: theme.colorScheme.onSurface),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Helper for chart header
Widget _buildChartHeader(
  BuildContext context,
  ThemeData theme,
  IconData icon,
  String title,
  String subtitle,
) {
  return Row(
    children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: theme.colorScheme.primary, size: 16),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

/// Helper for empty chart state with animation
Widget _buildEmptyState(
  BuildContext context,
  AppLocalizations l10n,
  ThemeData theme,
  IconData icon,
) {
  return SizedBox(
    height: 200,
    child: Center(
      child: AnimatedEmptyState(
        icon: icon,
        title: l10n.ownerAnalyticsNoData,
        iconSize: 40,
        iconColor: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
      ),
    ),
  );
}
