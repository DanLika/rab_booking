import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:graphic/graphic.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/config/router_owner.dart';
import '../../../../core/design/bb_redesign_tokens.dart';
import '../../../../core/design/tokens.dart';
import '../../../../core/theme/gradient_extensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/platform_scroll_physics.dart';
import '../widgets/recent_activity_widget.dart';
import '../widgets/owner_app_drawer.dart';
import '../widgets/booking_details_dialog_v2.dart';
import '../../../../shared/widgets/animations/skeleton_loader.dart';
import '../../../../shared/widgets/animations/animated_empty_state.dart';
import '../../../../shared/widgets/common_app_bar.dart';
import '../../../../shared/widgets/app_filter_chip.dart';
import '../../../../shared/widgets/redesign.dart';
import '../providers/owner_properties_provider.dart';
import '../providers/owner_bookings_provider.dart';
import '../providers/unified_dashboard_provider.dart';
import '../../domain/models/unified_dashboard_data.dart';
import '../../data/firebase/firebase_owner_bookings_repository.dart';
import '../../../../core/constants/enums.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/services/logging_service.dart';
import '../../../subscription/widgets/trial_banner.dart';
import '../../../../core/providers/enhanced_auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

    // Get user name for personalized welcome
    final authState = ref.watch(enhancedAuthProvider);
    final user = FirebaseAuth.instance.currentUser;
    final userName =
        authState.userModel?.firstName ?? user?.displayName?.split(' ').first;

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

            // Handle network/Firestore errors gracefully
            if (propertiesAsync.hasError) {
              final error = propertiesAsync.error;
              final isNetworkError =
                  error.toString().contains('UNAVAILABLE') ||
                  error.toString().contains('Unable to resolve host');

              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isNetworkError
                            ? Icons.wifi_off_rounded
                            : Icons.error_outline_rounded,
                        size: 64,
                        color: theme.colorScheme.error.withValues(alpha: 0.7),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isNetworkError
                            ? l10n.errorNetworkFailed
                            : l10n.errorLoadingData,
                        style: theme.textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isNetworkError
                            ? l10n.pleaseCheckConnection
                            : l10n.tryAgainLater,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: () {
                          ref.invalidate(ownerPropertiesProvider);
                        },
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text(l10n.retry),
                      ),
                    ],
                  ),
                ),
              );
            }

            final properties = propertiesAsync.value ?? [];

            // If no properties, show welcome screen for new users
            if (properties.isEmpty && !propertiesAsync.hasError) {
              return _buildWelcomeScreen(
                context,
                l10n,
                theme,
                isMobile,
                userName,
              );
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
    AppLocalizations l10n,
    ThemeData theme,
    bool isMobile,
    String? userName,
  ) {
    return SingleChildScrollView(
      physics: PlatformScrollPhysics.adaptive,
      padding: EdgeInsets.fromLTRB(
        isMobile ? 20 : 32,
        isMobile ? 20 : 32,
        isMobile ? 20 : 32,
        40,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Welcome Header with personalized greeting
          _WelcomeHeader(userName: userName, l10n: l10n, theme: theme),
          SizedBox(height: isMobile ? 32 : 48),

          // 2. Quick Start Action Cards
          Text(
            l10n.dashboardQuickStart,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              // On desktop, show in a row. On mobile, stack.
              if (!isMobile) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _ActionStepCard(
                        title: l10n.ownerAddFirstProperty,
                        subtitle: l10n.dashboardActionPropertySubtitle,
                        icon: Icons.add_home_work_rounded,
                        gradient: context.gradients.brandPrimary,
                        onTap: () => context.push(OwnerRoutes.propertyNew),
                        isPrimary: true,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _ActionStepCard(
                        title: l10n.ownerDrawerImportBookings,
                        subtitle: l10n.dashboardActionImportSubtitle,
                        icon: Icons.sync_rounded,
                        gradient: context.gradients.sectionBackground,
                        onTap: () => context.push(OwnerRoutes.icalImport),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _ActionStepCard(
                        title: l10n.ownerDrawerStripePayments,
                        subtitle: l10n.dashboardActionPaymentsSubtitle,
                        icon: Icons.payments_rounded,
                        gradient: context.gradients.brandPrimary,
                        onTap: () =>
                            context.push(OwnerRoutes.stripeIntegration),
                      ),
                    ),
                  ],
                );
              }

              // On mobile, stack cards vertically
              return Column(
                children: [
                  _ActionStepCard(
                    title: l10n.ownerAddFirstProperty,
                    subtitle: l10n.dashboardActionPropertySubtitle,
                    icon: Icons.add_home_work_rounded,
                    gradient: context.gradients.brandPrimary,
                    onTap: () => context.push(OwnerRoutes.propertyNew),
                    isPrimary: true,
                  ),
                  const SizedBox(height: 12),
                  _ActionStepCard(
                    title: l10n.ownerDrawerImportBookings,
                    subtitle: l10n.dashboardActionImportSubtitle,
                    icon: Icons.sync_rounded,
                    gradient: context.gradients.sectionBackground,
                    onTap: () => context.push(OwnerRoutes.icalImport),
                  ),
                  const SizedBox(height: 12),
                  _ActionStepCard(
                    title: l10n.ownerDrawerStripePayments,
                    subtitle: l10n.dashboardActionPaymentsSubtitle,
                    icon: Icons.payments_rounded,
                    gradient: context.gradients.brandPrimary,
                    onTap: () => context.push(OwnerRoutes.stripeIntegration),
                  ),
                ],
              );
            },
          ),

          SizedBox(height: isMobile ? 40 : 60),

          // 3. Mock Dashboard Preview
          _buildDashboardPreview(context, l10n, theme),
        ],
      ),
    );
  }

  /// Build mock dashboard preview for new users
  Widget _buildDashboardPreview(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    final mockData = _getMockDashboardData();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.dashboardFuturePreview.toUpperCase(),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Stack(
          children: [
            // The blurred dashboard content
            Opacity(
              opacity: 0.5,
              child: IgnorePointer(
                child: Column(
                  children: [
                    _buildStatsCards(context: context, data: mockData),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 300,
                      child: _RevenueChart(data: mockData.revenueHistory),
                    ),
                  ],
                ),
              ),
            ),
            // Gradient Fade Overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      theme.scaffoldBackgroundColor.withValues(alpha: 0.0),
                      theme.scaffoldBackgroundColor.withValues(alpha: 0.8),
                    ],
                    stops: const [0.0, 0.8],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Generate mock data for dashboard preview
  UnifiedDashboardData _getMockDashboardData() {
    final now = DateTime.now();
    return UnifiedDashboardData(
      revenue: 12500,
      bookings: 45,
      upcomingCheckIns: 3,
      occupancyRate: 85.5,
      revenueHistory: List.generate(7, (i) {
        return RevenueDataPoint(
          date: now.subtract(Duration(days: 6 - i)),
          amount: [800.0, 1200.0, 950.0, 1500.0, 1800.0, 2200.0, 2500.0][i],
          label: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][i],
        );
      }),
      bookingHistory: List.generate(7, (i) {
        return BookingDataPoint(
          date: now.subtract(Duration(days: 6 - i)),
          count: [2, 3, 2, 5, 4, 6, 8][i],
          label: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][i],
        );
      }),
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
    final rd = BbRedesignTokens.of(context);

    // Greeting userName (same derivation as build())
    final authState = ref.watch(enhancedAuthProvider);
    final fbUser = FirebaseAuth.instance.currentUser;
    final userName =
        authState.userModel?.firstName ?? fbUser?.displayName?.split(' ').first;

    // Outer padding: shell-bg gutter around the floating panel (handoff inset).
    // Mobile keeps edge-to-edge; tablet+desktop add gutter for the panel.
    final EdgeInsets gutterPadding = isMobile
        ? const EdgeInsets.fromLTRB(8, 4, 8, 16)
        : EdgeInsets.fromLTRB(16, 4, isDesktop ? 28 : 18, 24);

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
        padding: EdgeInsets.zero,
        children: [
          // Trial status banner - shows only when trial is expiring or expired
          const TrialBanner(),

          // Floating console panel (handoff `--bb-panel-bg` + radius 24 + 3-layer shadow).
          // Wraps the populated dashboard body without touching the parent Scaffold.
          Padding(
            padding: gutterPadding,
            child: Container(
              decoration: BoxDecoration(
                color: rd.panelBg,
                borderRadius: BorderRadius.circular(
                  isMobile ? BBRadius.lg : 28,
                ),
                border: Border.all(color: rd.panelBorder),
                boxShadow: rd.panelShadow,
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  isMobile ? 16 : (isDesktop ? 32 : 24),
                  isMobile ? 16 : 22,
                  isMobile ? 16 : (isDesktop ? 32 : 24),
                  isMobile ? 20 : 28,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Greeting (eyebrow date + headline)
                    _PregledGreetingHeader(
                      userName: userName,
                      isMobile: isMobile,
                    ),
                    SizedBox(height: isMobile ? 14 : 18),

                    // Time period selector
                    _DateRangeSelector(dateRange: dateRange),
                    SizedBox(height: isMobile ? 8 : 12),

                    // Hero revenue command + occupancy radial + AI insight
                    // (handoff `pregled-premium.jsx` PVRevenueCommand / PVOccupancy
                    // / PVAIInsight — audit/114 P1 Pregled mobile). Always
                    // renders — at €0 / 0% the surfaces become a calm empty
                    // baseline rather than disappearing, matching handoff which
                    // has no empty-state branch.
                    dashboardAsync.when(
                      data: (data) => Padding(
                        padding: EdgeInsets.only(bottom: isMobile ? 12 : 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _PregledHeroCommand(
                              data: data,
                              dateRange: dateRange,
                              isMobile: isMobile,
                            ),
                            SizedBox(height: isMobile ? 12 : 16),
                            _PregledOccupancyRadial(
                              data: data,
                              isMobile: isMobile,
                            ),
                            SizedBox(height: isMobile ? 12 : 16),
                            _PregledAiInsight(isMobile: isMobile),
                          ],
                        ),
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                    ),

                    // KPI cards section
                    const BbSectionHeader(
                      // HR-only owner surface — handoff eyebrow copy.
                      title: 'Ključni pokazatelji',
                      level: BbSectionHeaderLevel.h3,
                    ),
                    dashboardAsync.when(
                      data: (data) =>
                          _buildStatsCards(context: context, data: data),
                      loading: SkeletonLoader.analyticsMetricCards,
                      error: (e, s) =>
                          _buildErrorState(context, l10n, theme, e),
                    ),

                    // Charts section - only show when there are bookings
                    dashboardAsync.when(
                      data: (data) {
                        if (data.bookings == 0) return const SizedBox.shrink();
                        return Padding(
                          padding: EdgeInsets.only(top: isMobile ? 16 : 20),
                          child: isDesktop
                              ? _buildDesktopChartsRow(data, l10n)
                              : _buildStackedCharts(data, isMobile, l10n),
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                    ),

                    // Revenue-by-channel (handoff PVChannels) — placeholder
                    // surface, real provider wiring tracked in audit/114.
                    // Always renders (handoff has no empty-state branch).
                    dashboardAsync.when(
                      data: (data) => Padding(
                        padding: EdgeInsets.only(top: isMobile ? 16 : 20),
                        child: _PregledChannelMix(
                          data: data,
                          isMobile: isMobile,
                        ),
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                    ),

                    SizedBox(height: isMobile ? 16 : 20),

                    // Recent activity section
                    BbSectionHeader(
                      title: l10n.ownerRecentActivities,
                      actionLabel: l10n.ownerViewAll,
                      onActionTap: () => context.go(OwnerRoutes.bookings),
                    ),
                    _buildRecentActivity(context, ref),
                  ],
                ),
              ),
            ),
          ),
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

  /// Desktop layout - Charts side-by-side
  Widget _buildDesktopChartsRow(
    UnifiedDashboardData data,
    AppLocalizations l10n,
  ) {
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
    final recentBookingsAsync = ref.watch(recentOwnerBookingsProvider);
    final c = BBColor.of(context);

    return recentBookingsAsync.when(
      data: (bookings) {
        if (bookings.isEmpty) {
          // Keep the existing widget for the empty-state visual; it already
          // renders a friendly empty animation per ui-ux.md guidance.
          return RecentActivityWidget(
            activities: const [],
            onViewAll: () => context.go(OwnerRoutes.bookings),
          );
        }
        // Inline rows on a single BbCard surface — handoff arrivals layout
        // (avatar + name + property/unit + status badge).
        return BbCard(
          padded: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: List.generate(bookings.length, (i) {
              final b = bookings[i];
              return _PregledArrivalsRow(
                ownerBooking: b,
                isFirst: i == 0,
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => BookingDetailsDialogV2(ownerBooking: b),
                  );
                },
              );
            }),
          ),
        );
      },
      loading: () => Padding(
        padding: const EdgeInsets.all(AppDimensions.spaceXL),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(c.primary),
          ),
        ),
      ),
      error: (e, s) => RecentActivityWidget(
        activities: const [],
        onViewAll: () => context.go(OwnerRoutes.bookings),
      ),
    );
  }

  Widget _buildStatsCards({
    required BuildContext context,
    required UnifiedDashboardData data,
  }) {
    final l10n = AppLocalizations.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final c = BBColor.of(context);

    // Sparkline series sourced from existing provider data — never fabricated.
    final List<double> revenueSpark = data.revenueHistory
        .map((p) => p.amount)
        .toList(growable: false);
    final List<double> bookingsSpark = data.bookingHistory
        .map((p) => p.count.toDouble())
        .toList(growable: false);

    final revenueCard = _PregledKpiCard(
      icon: 'payments',
      label: l10n.ownerDashboardRevenue,
      value: '€${data.revenue.toStringAsFixed(0)}',
      tone: c.primary,
      sparkData: revenueSpark,
      isMobile: isMobile,
    );

    final bookingsCard = _PregledKpiCard(
      icon: 'receipt_long',
      label: l10n.ownerDashboardBookings,
      value: '${data.bookings}',
      tone: c.info,
      sparkData: bookingsSpark,
      isMobile: isMobile,
    );

    // KPI tiles 3+4 ride proxy series until UnifiedDashboardData carries
    // dedicated history fields. Check-ins ≈ bookings rhythm; occupancy ≈
    // revenue rhythm. Better than empty sparkline (handoff shows all 4 cards
    // with a sparkline). Proxies are derived series, not invented data.
    final checkInsCard = _PregledKpiCard(
      icon: 'flight_takeoff',
      label: l10n.ownerUpcomingCheckIns,
      value: '${data.upcomingCheckIns}',
      tone: c.success,
      sparkData: bookingsSpark,
      isMobile: isMobile,
    );

    final occupancyCard = _PregledKpiCard(
      icon: 'donut_small',
      label: l10n.ownerOccupancyRate,
      value: '${data.occupancyRate.toStringAsFixed(0)}%',
      tone: c.tertiary,
      sparkData: revenueSpark,
      isMobile: isMobile,
    );

    // Layout: explicit 2x2 on mobile; auto-grid on tablet+desktop. We keep
    // explicit IntrinsicHeight rows so cards align even with varying content.
    if (isMobile) {
      return Column(
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: revenueCard),
                const SizedBox(width: 10),
                Expanded(child: bookingsCard),
              ],
            ),
          ),
          const SizedBox(height: 10),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: checkInsCard),
                const SizedBox(width: 10),
                Expanded(child: occupancyCard),
              ],
            ),
          ),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, cs) {
        // Always 4 columns on >900px; 2 columns on tablet 600-900.
        final isWide = cs.maxWidth >= 900;
        final cols = isWide ? 4 : 2;
        final spacing = 12.0;
        final w = (cs.maxWidth - (cols - 1) * spacing) / cols;
        final children = [
          revenueCard,
          bookingsCard,
          checkInsCard,
          occupancyCard,
        ];
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: children
              .map((card) => SizedBox(width: w, child: card))
              .toList(),
        );
      },
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
      // F-63-04: Wrap allows chips to flow to a second line under large-text
      // accessibility (system font_scale=2.0). Replaces horizontal scroll which
      // hid the last 2-3 chips off-screen at 200% scale (audit/63).
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          AppFilterChip(
            label: l10n.ownerAnalyticsLast7Days,
            selected: dateRange.preset == 'last7',
            onSelected: () {
              ref
                  .read(dashboardDateRangeNotifierProvider.notifier)
                  .setPreset('last7');
            },
          ),
          AppFilterChip(
            label: l10n.ownerAnalyticsLast30Days,
            selected: dateRange.preset == 'last30',
            onSelected: () {
              ref
                  .read(dashboardDateRangeNotifierProvider.notifier)
                  .setPreset('last30');
            },
          ),
          AppFilterChip(
            label: l10n.ownerAnalyticsLast90Days,
            selected: dateRange.preset == 'last90',
            onSelected: () {
              ref
                  .read(dashboardDateRangeNotifierProvider.notifier)
                  .setPreset('last90');
            },
          ),
          AppFilterChip(
            label: l10n.ownerAnalyticsLast365Days,
            selected: dateRange.preset == 'last365',
            onSelected: () {
              ref
                  .read(dashboardDateRangeNotifierProvider.notifier)
                  .setPreset('last365');
            },
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
      return _buildEmptyState(
        context,
        l10n,
        theme,
        Icons.insert_chart_outlined_rounded,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isLandscape =
            MediaQuery.of(context).orientation == Orientation.landscape;

        // RESPONSIVE: Adjust height for landscape mobile to avoid taking up full screen
        final double chartHeight;
        if (screenWidth > 900) {
          chartHeight = 300.0;
        } else if (screenWidth > 600) {
          chartHeight = 260.0;
        } else {
          // Mobile - use smaller height in landscape
          chartHeight = isLandscape ? 180.0 : 220.0;
        }

        return SizedBox(
          height: chartHeight,
          child: BbCard(
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
                    data: data
                        .asMap()
                        .entries
                        .map(
                          (e) => {
                            'index': e.key,
                            'label': e.value.label,
                            'amount': e.value.amount,
                          },
                        )
                        .toList(),
                    variables: {
                      'index': Variable(
                        accessor: (Map map) => map['index'] as num,
                      ),
                      'amount': Variable(
                        accessor: (Map map) => map['amount'] as num,
                        scale: LinearScale(min: 0),
                      ),
                      'label': Variable(
                        accessor: (Map map) => map['label'] as String,
                      ),
                    },
                    coord:
                        RectCoord(), // Removed horizontalRangeUpdater to disable zoom
                    marks: [
                      AreaMark(
                        shape: ShapeEncode(value: BasicAreaShape(smooth: true)),
                        color: ColorEncode(
                          value: theme.colorScheme.primary.withValues(
                            alpha: 0.15,
                          ),
                        ),
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
                        label: LabelEncode(
                          encoder: (tuple) {
                            final amount = tuple['amount'] as num;
                            return Label(
                              '€${amount.toStringAsFixed(0)}',
                              LabelStyle(
                                textStyle: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                                offset: const Offset(0, -12),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
                    selections: {
                      'touchMove': PointSelection(
                        on: {GestureType.hover},
                        devices: {
                          PointerDeviceKind.touch,
                          PointerDeviceKind.mouse,
                        },
                      ),
                    },
                    tooltip: TooltipGuide(
                      backgroundColor: theme.colorScheme.surface,
                      elevation: 8,
                      textStyle: AppTypography.bodySmall.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    crosshair: CrosshairGuide(followPointer: [false, true]),
                  ),
                ),
              ],
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
        final isLandscape =
            MediaQuery.of(context).orientation == Orientation.landscape;

        // RESPONSIVE: Adjust height for landscape mobile
        final double chartHeight;
        if (screenWidth > 900) {
          chartHeight = 300.0;
        } else if (screenWidth > 600) {
          chartHeight = 260.0;
        } else {
          // Mobile - use smaller height in landscape
          chartHeight = isLandscape ? 180.0 : 220.0;
        }

        return SizedBox(
          height: chartHeight,
          child: BbCard(
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
                    data: data
                        .asMap()
                        .entries
                        .map(
                          (e) => {
                            'index': e.key,
                            'label': e.value.label,
                            'count': e.value.count,
                          },
                        )
                        .toList(),
                    variables: {
                      'index': Variable(
                        accessor: (Map map) => map['index'] as num,
                      ),
                      'count': Variable(
                        accessor: (Map map) => map['count'] as num,
                        scale: LinearScale(min: 0),
                      ),
                      'label': Variable(
                        accessor: (Map map) => map['label'] as String,
                      ),
                    },
                    coord:
                        RectCoord(), // Removed horizontalRangeUpdater to disable zoom
                    marks: [
                      IntervalMark(
                        shape: ShapeEncode(
                          value: RectShape(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
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
                        label: LabelEncode(
                          encoder: (tuple) {
                            final count = tuple['count'] as num;
                            // Only show label if count > 0, otherwise show empty label
                            return Label(
                              count > 0 ? count.toString() : '',
                              LabelStyle(
                                textStyle: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                                offset: const Offset(0, -8),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
                    selections: {
                      'touchMove': PointSelection(
                        on: {GestureType.hover},
                        devices: {
                          PointerDeviceKind.touch,
                          PointerDeviceKind.mouse,
                        },
                      ),
                    },
                    tooltip: TooltipGuide(
                      backgroundColor: theme.colorScheme.surface,
                      elevation: 8,
                      textStyle: AppTypography.bodySmall.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ],
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
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
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

/// Welcome header with personalized greeting
class _WelcomeHeader extends StatelessWidget {
  final String? userName;
  final AppLocalizations l10n;
  final ThemeData theme;

  const _WelcomeHeader({
    required this.userName,
    required this.l10n,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: theme.brightness == Brightness.dark
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.primary.withValues(alpha: 0.7),
                        ],
                      )
                    : null,
                color: theme.brightness == Brightness.dark
                    ? null
                    : theme.colorScheme.primary,
                shape: BoxShape.circle,
                boxShadow: theme.brightness == Brightness.dark
                    ? [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.3,
                          ),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: const Icon(
                Icons.waving_hand_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Flexible(
              child: Text(
                userName != null
                    ? l10n.dashboardWelcomeUser(userName!)
                    : l10n.ownerWelcomeTitle,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          l10n.ownerWelcomeSubtitle,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

/// Action step card for quick start actions
class _ActionStepCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final LinearGradient gradient;
  final VoidCallback onTap;
  final bool isPrimary;

  const _ActionStepCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: isPrimary && isDark
            ? [
                BoxShadow(
                  color: gradient.colors.first.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Card(
        elevation: isPrimary ? (isDark ? 0 : 4) : 0,
        color: isPrimary
            ? null
            : (isDark
                  ? theme.colorScheme.surfaceContainerHigh.withValues(
                      alpha: 0.5,
                    )
                  : theme.colorScheme.surfaceContainerLow),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: isPrimary
              ? BorderSide.none
              : BorderSide(
                  color: isDark
                      ? theme.colorScheme.outlineVariant.withValues(alpha: 0.2)
                      : theme.colorScheme.outlineVariant,
                ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: isPrimary ? BoxDecoration(gradient: gradient) : null,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isPrimary
                        ? Colors.white.withValues(alpha: 0.2)
                        : (isDark
                              ? theme.colorScheme.primary.withValues(alpha: 0.1)
                              : theme.colorScheme.surface),
                    borderRadius: BorderRadius.circular(14),
                    border: isPrimary
                        ? Border.all(color: Colors.white.withValues(alpha: 0.2))
                        : null,
                  ),
                  child: Icon(
                    icon,
                    color: isPrimary ? Colors.white : theme.colorScheme.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isPrimary
                        ? Colors.white
                        : theme.colorScheme.onSurface,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isPrimary
                        ? Colors.white.withValues(alpha: 0.9)
                        : theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text(
                      l10n.dashboardGetStarted,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isPrimary
                            ? Colors.white
                            : theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: isPrimary
                          ? Colors.white
                          : theme.colorScheme.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Redesign helpers — Pregled refactor (Phase 2)
// =============================================================================

/// Eyebrow date + headline greeting (handoff PregledPremium header).
class _PregledGreetingHeader extends StatelessWidget {
  final String? userName;
  final bool isMobile;

  const _PregledGreetingHeader({
    required this.userName,
    required this.isMobile,
  });

  String _greetingForHour(int hour) {
    if (hour < 11) return 'Dobro jutro';
    if (hour < 18) return 'Dobar dan';
    return 'Dobra večer';
  }

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    final now = DateTime.now();
    final locale = Localizations.localeOf(context).toString();
    // Date eyebrow ("Subota · 30. svibnja 2026" on HR locale).
    // Falls back to default-locale format if the locale data is missing
    // (e.g. test envs without initializeDateFormatting).
    String eyebrow;
    try {
      eyebrow = DateFormat('EEEE · d. MMMM y', locale).format(now);
    } catch (_) {
      eyebrow = DateFormat('EEEE · d. MMMM y').format(now);
    }
    eyebrow = eyebrow.replaceFirstMapped(
      RegExp(r'^(\w)'),
      (m) => m.group(1)!.toUpperCase(),
    );
    final greet = _greetingForHour(now.hour);
    final headline = userName != null ? '$greet, $userName' : greet;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: BBType.eyebrow(context).copyWith(color: c.primary),
        ),
        const SizedBox(height: 6),
        Text(
          headline,
          style: (isMobile ? BBType.h1(context) : BBType.display(context))
              .copyWith(letterSpacing: -0.6, fontWeight: FontWeight.w800),
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        ),
      ],
    );
  }
}

/// KPI card on BbCard surface with tinted icon tile + tabular value + sparkline.
class _PregledKpiCard extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final Color tone;
  final List<double> sparkData;
  final bool isMobile;

  const _PregledKpiCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.tone,
    required this.sparkData,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    final iconBoxSize = isMobile ? 32.0 : 36.0;
    final iconSize = isMobile ? 18.0 : 20.0;
    final valueStyle =
        (isMobile ? BBType.h1Num(context) : BBType.h2Num(context)).copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
          color: c.textPrimary,
          fontSize: isMobile ? 24 : 28,
          height: 1.0,
        );

    return BbCard(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      hoverable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: iconBoxSize,
            height: iconBoxSize,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: BbIcon(name: icon, size: iconSize, color: tone),
          ),
          SizedBox(height: isMobile ? 12 : 14),
          Text(
            label.toUpperCase(),
            style: BBType.caption(context).copyWith(
              color: c.textTertiary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(value, style: valueStyle),
                ),
              ),
              if (sparkData.length >= 2) ...[
                const SizedBox(width: 8),
                BbSparkline(
                  data: sparkData,
                  width: isMobile ? 56 : 84,
                  height: isMobile ? 26 : 32,
                  color: tone,
                  fillColor: tone.withValues(alpha: 0.14),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Arrival row — guest avatar + name/unit + status badge (handoff PVArrivals row).
class _PregledArrivalsRow extends StatelessWidget {
  final OwnerBooking ownerBooking;
  final bool isFirst;
  final VoidCallback onTap;

  const _PregledArrivalsRow({
    required this.ownerBooking,
    required this.isFirst,
    required this.onTap,
  });

  BbBookingStatus _mapStatus(BookingStatus s) {
    switch (s) {
      case BookingStatus.pending:
        return BbBookingStatus.pending;
      case BookingStatus.confirmed:
        return BbBookingStatus.confirmed;
      case BookingStatus.cancelled:
        return BbBookingStatus.cancelled;
      case BookingStatus.completed:
        return BbBookingStatus.completed;
    }
  }

  BbAvatarTone _toneForStatus(BookingStatus s) {
    switch (s) {
      case BookingStatus.confirmed:
        return BbAvatarTone.success;
      case BookingStatus.pending:
        return BbAvatarTone.tertiary;
      case BookingStatus.cancelled:
        return BbAvatarTone.neutral;
      case BookingStatus.completed:
        return BbAvatarTone.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    final isMobile = MediaQuery.of(context).size.width < 600;
    final booking = ownerBooking.booking;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 14 : 20,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          border: Border(
            top: isFirst ? BorderSide.none : BorderSide(color: c.border),
          ),
        ),
        child: Row(
          children: [
            // Next-guest hero date chip (handoff PV_ARRIVALS[next:true]).
            // First row gets gradient-hero + purple shadow + white text;
            // others get surface-variant + tertiary text.
            _ArrivalsDateChip(date: booking.checkIn, highlighted: isFirst),
            SizedBox(width: isMobile ? 10 : 14),
            BbAvatar(
              name: ownerBooking.guestName,
              size: BbAvatarSize.sm,
              tone: _toneForStatus(booking.status),
            ),
            SizedBox(width: isMobile ? 10 : 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    ownerBooking.guestName,
                    style: BBType.label(context).copyWith(
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${ownerBooking.property.name} · ${ownerBooking.unit.name}',
                    style: BBType.caption(
                      context,
                    ).copyWith(color: c.textTertiary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            BbStatusBadge(
              status: _mapStatus(booking.status),
              size: BbStatusBadgeSize.sm,
            ),
          ],
        ),
      ),
    );
  }
}

/// 48-wide date chip for the upcoming-arrivals row (handoff PV_ARRIVALS).
///
/// Highlighted (first/next arrival) → gradient-hero + purple-glow shadow +
/// white text. Resting → surface-variant + tertiary text. Day + date number,
/// HR weekday abbreviation.
class _ArrivalsDateChip extends StatelessWidget {
  final DateTime date;
  final bool highlighted;

  const _ArrivalsDateChip({required this.date, required this.highlighted});

  // HR weekday abbreviations indexed by DateTime.weekday (1..7).
  static const List<String> _hrDays = <String>[
    'Pon',
    'Uto',
    'Sri',
    'Čet',
    'Pet',
    'Sub',
    'Ned',
  ];

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    final String day = _hrDays[(date.weekday - 1).clamp(0, 6)];
    final Color labelColor = highlighted
        ? Colors.white.withValues(alpha: 0.82)
        : c.textTertiary;
    final Color numColor = highlighted ? Colors.white : c.textPrimary;
    return Container(
      width: 48,
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        gradient: highlighted ? BBGradient.hero : null,
        color: highlighted ? null : c.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
        boxShadow: highlighted ? BBShadow.purpleGlow(context) : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            day,
            style: BBType.caption(context).copyWith(
              color: labelColor,
              fontWeight: FontWeight.w600,
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
          Text(
            '${date.day}',
            style: BBType.bodyNum(context).copyWith(
              color: numColor,
              fontWeight: FontWeight.w700,
              fontSize: 14,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Hero "north-star" revenue command card (handoff PVRevenueCommand).
///
/// Renders the dominant revenue figure for the selected period with a
/// delta-vs-prior chip and a wide area sparkline. Delta is derived from the
/// existing `revenueHistory` series (no new provider): the second half of the
/// series is compared to the first half, so the chip is only meaningful when
/// the series has at least 4 points.
class _PregledHeroCommand extends StatelessWidget {
  final UnifiedDashboardData data;
  final DateRangeFilter dateRange;
  final bool isMobile;

  const _PregledHeroCommand({
    required this.data,
    required this.dateRange,
    required this.isMobile,
  });

  String _periodLabel(AppLocalizations l10n) {
    switch (dateRange.preset) {
      case 'last7':
        return l10n.ownerAnalyticsLast7Days;
      case 'last30':
        return l10n.ownerAnalyticsLast30Days;
      case 'last90':
        return l10n.ownerAnalyticsLast90Days;
      case 'last365':
        return l10n.ownerAnalyticsLast365Days;
      default:
        return '';
    }
  }

  ({double pct, double prevSum}) _deltaVsPrior() {
    final h = data.revenueHistory;
    if (h.length < 4) return (pct: 0, prevSum: 0);
    final mid = h.length ~/ 2;
    double prev = 0, curr = 0;
    for (int i = 0; i < mid; i++) {
      prev += h[i].amount;
    }
    for (int i = mid; i < h.length; i++) {
      curr += h[i].amount;
    }
    if (prev <= 0) return (pct: 0, prevSum: 0);
    final pct = (curr - prev) / prev * 100;
    return (pct: pct, prevSum: prev);
  }

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    final l10n = AppLocalizations.of(context);
    final spark = data.revenueHistory
        .map((p) => p.amount)
        .toList(growable: false);
    final hasSpark = spark.length >= 2;
    final d = _deltaVsPrior();
    final hasDelta = d.prevSum > 0;
    final positive = d.pct >= 0;
    final deltaColor = positive ? c.success : c.error;
    final deltaIcon = positive ? 'trending_up' : 'trending_down';
    final deltaLabel =
        '${positive ? '+' : ''}${d.pct.toStringAsFixed(1).replaceAll('.', ',')}%';

    return BbCard(
      padding: EdgeInsets.all(isMobile ? 18 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            // HR-only owner surface; handoff eyebrow copy.
            'Ukupna zarada · ${_periodLabel(l10n).toLowerCase()}',
            style: BBType.eyebrow(context).copyWith(color: c.textTertiary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: isMobile ? 10 : 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    '€${data.revenue.toStringAsFixed(0)}',
                    style: BBType.displayNum(context).copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.2,
                      height: 1.0,
                      color: c.textPrimary,
                      fontSize: isMobile ? 38 : 52,
                    ),
                  ),
                ),
              ),
              if (hasDelta) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: deltaColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      BbIcon(name: deltaIcon, size: 14, color: deltaColor),
                      const SizedBox(width: 3),
                      Text(
                        deltaLabel,
                        style: BBType.caption(context).copyWith(
                          color: deltaColor,
                          fontWeight: FontWeight.w700,
                          fontFeatures: const <FontFeature>[
                            FontFeature.tabularFigures(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          if (hasSpark) ...[
            SizedBox(height: isMobile ? 14 : 18),
            LayoutBuilder(
              builder: (ctx, cs) => BbSparkline(
                data: spark,
                width: cs.maxWidth,
                height: isMobile ? 80 : 108,
                color: c.primary,
                fillColor: c.primary.withValues(alpha: 0.16),
                strokeWidth: 2.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Occupancy radial gauge (handoff PVOccupancy / PVRadial).
///
/// Replaces the flat percentage tile with a custom-painted arc on a BbCard.
/// The arc is purely presentational; the value comes from the existing
/// `data.occupancyRate` field.
class _PregledOccupancyRadial extends StatelessWidget {
  final UnifiedDashboardData data;
  final bool isMobile;

  const _PregledOccupancyRadial({required this.data, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    final l10n = AppLocalizations.of(context);
    final occupancy = data.occupancyRate.clamp(0.0, 100.0);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final size = isMobile ? 120.0 : 144.0;

    return BbCard(
      padding: EdgeInsets.all(isMobile ? 18 : 22),
      child: Row(
        children: [
          SizedBox(
            width: size,
            height: size,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: occupancy),
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 1200),
              curve: Curves.easeOutCubic,
              builder: (ctx, animated, _) => CustomPaint(
                painter: _OccupancyRadialPainter(
                  value: animated,
                  trackColor: c.bg,
                  gradientStart: c.primary,
                  gradientEnd: c.primaryLight,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${animated.toStringAsFixed(0)}%',
                        style: BBType.h1Num(context).copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                          height: 1.0,
                          color: c.textPrimary,
                          fontSize: isMobile ? 26 : 30,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: isMobile ? 16 : 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.ownerOccupancyRate.toUpperCase(),
                  style: BBType.eyebrow(
                    context,
                  ).copyWith(color: c.textTertiary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  // HR-only owner surface; mirrors handoff caption.
                  'Razdoblje · ${data.bookings} rezervacija',
                  style: BBType.caption(
                    context,
                  ).copyWith(color: c.textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: isMobile ? 10 : 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: c.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      BbIcon(name: 'donut_small', size: 14, color: c.primary),
                      const SizedBox(width: 4),
                      Text(
                        // HR-only owner surface.
                        '${data.upcomingCheckIns} dolazaka uskoro',
                        style: BBType.caption(context).copyWith(
                          color: c.primary,
                          fontWeight: FontWeight.w600,
                          fontFeatures: const <FontFeature>[
                            FontFeature.tabularFigures(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OccupancyRadialPainter extends CustomPainter {
  _OccupancyRadialPainter({
    required this.value,
    required this.trackColor,
    required this.gradientStart,
    required this.gradientEnd,
  });

  final double value; // 0-100
  final Color trackColor;
  final Color gradientStart;
  final Color gradientEnd;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.10;
    final radius = (size.shortestSide - stroke) / 2;
    final center = Offset(size.width / 2, size.height / 2);

    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);

    final arc = Paint()
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: math.pi * 1.5,
        colors: [gradientStart, gradientEnd],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final sweep = (value / 100.0) * math.pi * 2;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(covariant _OccupancyRadialPainter old) =>
      old.value != value ||
      old.trackColor != trackColor ||
      old.gradientStart != gradientStart ||
      old.gradientEnd != gradientEnd;
}

/// AI insight banner (handoff PVAIInsight).
///
/// Lavender-tinted container with sparkles icon, eyebrow tag, body copy and
/// a primary CTA. Behind a feature flag because no BookBed AI provider yet
/// exists; the copy here is the handoff example for visual fidelity only.
class _PregledAiInsight extends StatelessWidget {
  final bool isMobile;

  const _PregledAiInsight({required this.isMobile});

  static const bool _enabled = bool.fromEnvironment('PREGLED_AI_INSIGHT');

  @override
  Widget build(BuildContext context) {
    if (!_enabled && !kDebugMode) return const SizedBox.shrink();

    final c = BBColor.of(context);
    final tileSize = isMobile ? 42.0 : 46.0;

    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        // Premium tri-stop banner gradient (handoff `tokens.css` line 217):
        // purple → light purple → mint. 105° axis ≈ topLeft→bottomRight.
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            c.primary.withValues(alpha: 0.10),
            c.primaryLight.withValues(alpha: 0.05),
            const Color(0xFF3DD9B0).withValues(alpha: 0.07),
          ],
          stops: const <double>[0.0, 0.45, 1.0],
        ),
        borderRadius: BorderRadius.circular(BBRadius.md),
        border: Border.all(color: c.primary.withValues(alpha: 0.18)),
        boxShadow: BBShadow.cardElevated,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: tileSize,
            height: tileSize,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [c.primary, c.primaryLight],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: c.primary.withValues(alpha: 0.30),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const BbIcon(
              name: 'auto_awesome',
              size: 22,
              color: Colors.white,
            ),
          ),
          SizedBox(width: isMobile ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: c.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        // Brand label, kept untranslated per handoff.
                        'BookBed AI',
                        style: BBType.caption(context).copyWith(
                          color: c.primary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      // HR-only owner surface.
                      'Uvid tjedna',
                      style: BBType.caption(
                        context,
                      ).copyWith(color: c.textTertiary),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  // HR-only owner surface; placeholder copy mirroring handoff
                  // until a BookBed AI provider lands.
                  'Vikend-termini sljedećeg mjeseca su gotovo popunjeni. Razmotrite blago povećanje cijene za nove rezervacije.',
                  style: BBType.body(context).copyWith(
                    color: c.textPrimary,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Revenue-by-channel breakdown card (handoff PVChannels).
///
/// Stacked horizontal bar + per-channel rows. Source breakdown is not yet on
/// `UnifiedDashboardData`; until the provider is extended the card renders
/// proportions derived from `data.bookings` only, behind a feature flag.
class _PregledChannelMix extends StatelessWidget {
  final UnifiedDashboardData data;
  final bool isMobile;

  const _PregledChannelMix({required this.data, required this.isMobile});

  static const bool _enabled = bool.fromEnvironment('PREGLED_CHANNEL_MIX');

  List<_ChannelEntry> _placeholderEntries(BBColorSet c) {
    final total = math.max(data.revenue, 1);
    // Placeholder mix mirroring handoff PVChannels proportions.
    return [
      _ChannelEntry(
        // HR-only owner surface.
        label: 'Direktno',
        pct: 69,
        amount: total * 0.69,
        color: c.primary,
      ),
      _ChannelEntry(
        label: 'Booking.com',
        pct: 22,
        amount: total * 0.22,
        color: c.info,
      ),
      _ChannelEntry(
        label: 'Airbnb',
        pct: 9,
        amount: total * 0.09,
        color: c.error,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (!_enabled && !kDebugMode) return const SizedBox.shrink();

    final c = BBColor.of(context);
    final entries = _placeholderEntries(c);

    return BbCard(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: isMobile ? 30 : 34,
                height: isMobile ? 30 : 34,
                decoration: BoxDecoration(
                  color: c.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: BbIcon(name: 'donut_small', size: 18, color: c.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      // HR-only owner surface.
                      'Zarada po kanalu',
                      style: BBType.h3(context).copyWith(
                        color: c.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      // HR-only owner surface.
                      'Udio izvora rezervacija',
                      style: BBType.caption(
                        context,
                      ).copyWith(color: c.textTertiary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 14 : 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  for (final e in entries)
                    Expanded(
                      flex: e.pct,
                      child: Container(
                        color: e.color,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(height: isMobile ? 14 : 18),
          Column(
            children: [
              for (int i = 0; i < entries.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: entries[i].color,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        entries[i].label,
                        style: BBType.label(context).copyWith(
                          color: c.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '€${entries[i].amount.toStringAsFixed(0)}',
                      style: BBType.bodyNum(context).copyWith(
                        color: c.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 36,
                      child: Text(
                        '${entries[i].pct}%',
                        textAlign: TextAlign.right,
                        style: BBType.caption(context).copyWith(
                          color: c.textTertiary,
                          fontFeatures: const <FontFeature>[
                            FontFeature.tabularFigures(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ChannelEntry {
  final String label;
  final int pct;
  final double amount;
  final Color color;

  const _ChannelEntry({
    required this.label,
    required this.pct,
    required this.amount,
    required this.color,
  });
}
