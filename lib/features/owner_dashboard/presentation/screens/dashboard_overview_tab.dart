import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:graphic/graphic.dart';
import 'package:intl/intl.dart';
import '../../../../core/config/router_owner.dart';
import '../../../../core/design/bb_redesign_tokens.dart';
import '../../../../core/design/responsive.dart';
import '../../../../core/design/tokens.dart';
import '../../../../core/theme/gradient_extensions.dart';
import '../../../../core/utils/platform_scroll_physics.dart';
import '../widgets/owner_app_drawer.dart';
import '../../../../shared/widgets/animations/skeleton_loader.dart';
import '../../../../shared/widgets/common_app_bar.dart';
import '../../../../shared/widgets/redesign.dart';
import '../providers/owner_properties_provider.dart';
import '../providers/unified_dashboard_provider.dart';
import '../../domain/models/unified_dashboard_data.dart';
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
        showTitle: false, // in-body header carries title (audit/126 §2A)
      ),
      drawer: const OwnerAppDrawer(currentRoute: 'overview'),
      body: Container(
        decoration: BoxDecoration(gradient: context.gradients.pageBackground),
        // Content clamp — center + cap width on tablet/desktop web.
        child: BBContentMaxWidth(
          maxWidth: 1100,
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
                    padding: const EdgeInsets.all(BBSpace.md),
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
                        const SizedBox(height: BBSpace.sm),
                        Text(
                          isNetworkError
                              ? l10n.errorNetworkFailed
                              : l10n.errorLoadingData,
                          style: theme.textTheme.titleLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: BBSpace.xs),
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
                        const SizedBox(height: BBSpace.md),
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
          SizedBox(height: isMobile ? BBSpace.lg : BBSpace.xl),

          // 2. Quick Start Action Cards
          Text(
            l10n.dashboardQuickStart,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: BBSpace.sm),
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
                        onTap: () => context.push(OwnerRoutes.propertyNew),
                        isPrimary: true,
                      ),
                    ),
                    const SizedBox(width: BBSpace.sm),
                    Expanded(
                      child: _ActionStepCard(
                        title: l10n.ownerDrawerImportBookings,
                        subtitle: l10n.dashboardActionImportSubtitle,
                        icon: Icons.sync_rounded,
                        onTap: () => context.push(OwnerRoutes.icalImport),
                      ),
                    ),
                    const SizedBox(width: BBSpace.sm),
                    Expanded(
                      child: _ActionStepCard(
                        title: l10n.ownerDrawerStripePayments,
                        subtitle: l10n.dashboardActionPaymentsSubtitle,
                        icon: Icons.payments_rounded,
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
                    onTap: () => context.push(OwnerRoutes.propertyNew),
                    isPrimary: true,
                  ),
                  const SizedBox(height: _kGap12),
                  _ActionStepCard(
                    title: l10n.ownerDrawerImportBookings,
                    subtitle: l10n.dashboardActionImportSubtitle,
                    icon: Icons.sync_rounded,
                    onTap: () => context.push(OwnerRoutes.icalImport),
                  ),
                  const SizedBox(height: _kGap12),
                  _ActionStepCard(
                    title: l10n.ownerDrawerStripePayments,
                    subtitle: l10n.dashboardActionPaymentsSubtitle,
                    icon: Icons.payments_rounded,
                    onTap: () => context.push(OwnerRoutes.stripeIntegration),
                  ),
                ],
              );
            },
          ),

          SizedBox(height: isMobile ? _kGap40 : _kGap60),

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
          padding: const EdgeInsets.symmetric(
            horizontal: BBSpace.sm,
            vertical: BBSpace.xs,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(BBRadius.full),
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
              const SizedBox(width: BBSpace.xs),
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
        const SizedBox(height: BBSpace.lg),
        Stack(
          children: [
            // The blurred dashboard content
            Opacity(
              opacity: 0.5,
              child: IgnorePointer(
                child: Column(
                  children: [
                    _buildStatsCards(context: context, data: mockData),
                    const SizedBox(height: BBSpace.md),
                    _RevenueAreaChart(
                      data: mockData.revenueHistory,
                      height: 300,
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
      distinctGuests: 38,
      revenueBySource: {'direct': 8625, 'booking_com': 2750, 'airbnb': 1125},
      depositsCollected: 768,
      depositsOutstanding: 3072,
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
        ? const EdgeInsets.fromLTRB(
            BBSpace.xs,
            BBSpace.xxs,
            BBSpace.xs,
            BBSpace.sm,
          )
        : EdgeInsets.fromLTRB(
            BBSpace.sm,
            BBSpace.xxs,
            isDesktop ? _kGap28 : _kGap18,
            _kGap28,
          );

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(ownerPropertiesProvider);
        ref.invalidate(unifiedDashboardNotifierProvider);
        await Future.wait([
          ref.read(ownerPropertiesProvider.future),
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
                  isMobile ? BBRadius.lg : _kPanelRadius,
                ),
                border: Border.all(color: rd.panelBorder),
                boxShadow: rd.panelShadow,
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  isMobile ? BBSpace.sm : (isDesktop ? BBSpace.lg : BBSpace.md),
                  isMobile ? BBSpace.sm : (isDesktop ? _kGap28 : _kGap22),
                  isMobile ? BBSpace.sm : (isDesktop ? BBSpace.lg : BBSpace.md),
                  isMobile ? _kGap20 : (isDesktop ? _kGap36 : _kGap28),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _pregledPanelChildren(
                    context,
                    l10n,
                    theme,
                    isMobile,
                    isDesktop,
                    dashboardAsync,
                    dateRange,
                    userName,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Panel body sections (header + hero + KPI + lower), shared by the live
  /// dashboard and [buildPanelForTest]; takes already-resolved [dashboardAsync].
  List<Widget> _pregledPanelChildren(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
    bool isMobile,
    bool isDesktop,
    AsyncValue<UnifiedDashboardData> dashboardAsync,
    DateRangeFilter dateRange,
    String? userName, {
    DateTime? now,
  }) {
    return [
      // Header (handoff PVHeader): greeting left, period pill +
      // "Nova rezervacija" CTA right on ≥600px; stacked with a
      // centered selector on mobile (handoff mobile spec).
      if (isMobile) ...[
        _PregledGreetingHeader(
          userName: userName,
          isMobile: isMobile,
          nowOverride: now,
        ),
        const SizedBox(height: _kGap14),
        Center(child: _DateRangeSelector(dateRange: dateRange)),
        const SizedBox(height: _kGap12),
      ] else ...[
        Row(
          children: [
            Expanded(
              child: _PregledGreetingHeader(
                userName: userName,
                isMobile: isMobile,
                nowOverride: now,
              ),
            ),
            const SizedBox(width: BBSpace.sm),
            _DateRangeSelector(dateRange: dateRange),
            const SizedBox(width: _kGap12),
            const _NewBookingCta(),
          ],
        ),
        const SizedBox(height: _kGap20),
      ],

      // Hero revenue command + occupancy radial + AI insight
      // (handoff `pregled-premium.jsx` PVRevenueCommand / PVOccupancy
      // / PVAIInsight — audit/114 P1 Pregled mobile). Always
      // renders — at €0 / 0% the surfaces become a calm empty
      // baseline rather than disappearing, matching handoff which
      // has no empty-state branch.
      dashboardAsync.when(
        data: (data) {
          final hero = _PregledHeroCommand(
            data: data,
            dateRange: dateRange,
            isMobile: isMobile,
          );
          final radial = _PregledOccupancyRadial(
            data: data,
            isMobile: isMobile,
          );
          final deposits = _PregledDepositsCard(data: data, isMobile: isMobile);
          return Padding(
            padding: EdgeInsets.only(bottom: isMobile ? _kGap12 : _kGap20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PregledAiInsight(isMobile: isMobile),
                SizedBox(height: isMobile ? _kGap12 : _kGap20),
                // Handoff desktop grid: revenue command 2fr left,
                // radial + deposits rail 1fr right; stacked on
                // mobile/tablet.
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handoff hero grid ratio 1.85fr : 1fr.
                      Expanded(flex: 37, child: hero),
                      const SizedBox(width: _kGap20),
                      Expanded(
                        flex: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            radial,
                            const SizedBox(height: _kGap20),
                            deposits,
                          ],
                        ),
                      ),
                    ],
                  )
                else ...[
                  hero,
                  SizedBox(height: isMobile ? _kGap12 : BBSpace.sm),
                  radial,
                  SizedBox(height: isMobile ? _kGap12 : BBSpace.sm),
                  deposits,
                ],
              ],
            ),
          );
        },
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
        data: (data) => _buildStatsCards(context: context, data: data),
        loading: SkeletonLoader.analyticsMetricCards,
        error: (e, s) => _buildErrorState(context, l10n, theme, e),
      ),

      // Lower half (handoff DETALJI): "Nadolazeći dolasci" left
      // + "Zarada po kanalu" right on desktop; stacked otherwise.
      // Channel mix hides itself while the period has no priced
      // revenue; arrivals always renders (calm empty baseline).
      dashboardAsync.when(
        data: (data) {
          final arrivals = _PregledArrivalsCard(
            arrivals: data.upcomingArrivals,
            isMobile: isMobile,
          );
          final channels = _PregledChannelMix(data: data, isMobile: isMobile);
          final showChannels =
              data.revenueBySource.values.fold<double>(0, (a, b) => a + b) > 0;
          return Padding(
            padding: EdgeInsets.only(top: isMobile ? BBSpace.sm : _kGap20),
            child: isDesktop && showChannels
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handoff DETALJI grid ratio 1.4fr : 1fr.
                      Expanded(flex: 7, child: arrivals),
                      const SizedBox(width: _kGap20),
                      Expanded(flex: 5, child: channels),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      arrivals,
                      if (showChannels) ...[
                        SizedBox(height: isMobile ? BBSpace.sm : _kGap20),
                        channels,
                      ],
                    ],
                  ),
          );
        },
        loading: () => const SizedBox.shrink(),
        error: (_, _) => const SizedBox.shrink(),
      ),
    ];
  }

  /// Renders the populated dashboard panel for widget tests — the live
  /// sections (no Scaffold/drawer/providers) so the headless render matches the
  /// on-screen dashboard. Pass resolved [data]/[dateRange]; [isMobile] gates the
  /// same layout switches as the live screen.
  @visibleForTesting
  Widget buildPanelForTest(
    BuildContext context, {
    required UnifiedDashboardData data,
    required DateRangeFilter dateRange,
    required bool isMobile,
    String? userName,
    DateTime? now,
  }) {
    final rd = BbRedesignTokens.of(context);
    final isDesktop = MediaQuery.sizeOf(context).width > 900;
    return Container(
      decoration: BoxDecoration(
        color: rd.panelBg,
        borderRadius: BorderRadius.circular(
          isMobile ? BBRadius.lg : _kPanelRadius,
        ),
        border: Border.all(color: rd.panelBorder),
        boxShadow: rd.panelShadow,
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          isMobile ? BBSpace.sm : (isDesktop ? BBSpace.lg : BBSpace.md),
          isMobile ? BBSpace.sm : (isDesktop ? _kGap28 : _kGap22),
          isMobile ? BBSpace.sm : (isDesktop ? BBSpace.lg : BBSpace.md),
          isMobile ? _kGap20 : (isDesktop ? _kGap36 : _kGap28),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _pregledPanelChildren(
            context,
            AppLocalizations.of(context),
            Theme.of(context),
            isMobile,
            isDesktop,
            AsyncValue.data(data),
            dateRange,
            userName,
            now: now,
          ),
        ),
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
        padding: const EdgeInsets.all(BBSpace.md),
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
            const SizedBox(height: BBSpace.sm),
            Text(
              l10n.ownerErrorLoadingData,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: BBSpace.xs),
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

    // KPI strip per handoff `01-owner.png` KLJUČNI POKAZATELJI: REZERVACIJE
    // (receipt_long/purple) → PROSJEČNA CIJENA (payments/blue) → NOVI GOSTI
    // (person_add/green) → PROSJEČNA OCJENA (star/amber). UKUPNA ZARADA lives
    // in the hero; POPUNJENOST in the radial card — neither repeats here.
    final bookingsCard = _PregledKpiCard(
      icon: 'receipt_long',
      label: l10n.ownerDashboardBookings,
      value: '${data.bookings}',
      tone: c.primary,
      sparkData: bookingsSpark,
      isMobile: isMobile,
    );

    final avgNightlyPrice = data.bookings > 0
        ? data.revenue / data.bookings
        : 0.0;
    final avgPriceCard = _PregledKpiCard(
      icon: 'payments',
      label: l10n.ownerAnalyticsAvgNightlyRate,
      value: data.bookings > 0 ? '€${avgNightlyPrice.toStringAsFixed(0)}' : '—',
      tone: c.info,
      sparkData: revenueSpark,
      isMobile: isMobile,
    );

    // NOVI GOSTI rides the bookings proxy series until UnifiedDashboardData
    // carries a dedicated guest history (guests ≈ bookings rhythm; derived
    // series, not invented data).
    final newGuestsCard = _PregledKpiCard(
      icon: 'person_add',
      label: l10n.ownerDashboardNewGuests,
      value: '${data.distinctGuests}',
      tone: c.success,
      sparkData: bookingsSpark,
      isMobile: isMobile,
    );

    // PROSJEČNA OCJENA — reviews data does not exist yet (product gap, see
    // audit/120); tile renders the handoff slot honestly with an em dash and
    // no sparkline until a reviews provider lands.
    final avgRatingCard = _PregledKpiCard(
      icon: 'star',
      label: l10n.ownerDashboardAvgRating,
      value: '—',
      tone: c.tertiary,
      sparkData: const [],
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
                Expanded(child: bookingsCard),
                const SizedBox(width: _kGap10),
                Expanded(child: avgPriceCard),
              ],
            ),
          ),
          const SizedBox(height: _kGap10),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: newGuestsCard),
                const SizedBox(width: _kGap10),
                Expanded(child: avgRatingCard),
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
        final spacing = BBSpace.sm;
        final w = (cs.maxWidth - (cols - 1) * spacing) / cols;
        final children = [
          bookingsCard,
          avgPriceCard,
          newGuestsCard,
          avgRatingCard,
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

/// Time period selector — pill segmented control matching
/// `design_handoff/source/pregled-premium.jsx` `PVPeriod`.
class _DateRangeSelector extends ConsumerWidget {
  final DateRangeFilter dateRange;

  const _DateRangeSelector({required this.dateRange});

  static const _segments = <({String label, String preset})>[
    (label: '7 dana', preset: 'last7'),
    (label: '30 dana', preset: 'last30'),
    (label: '90 dana', preset: 'last90'),
    (label: 'Godina', preset: 'last365'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = BBColor.of(context);

    return Container(
      padding: const EdgeInsets.all(BBSpace.xxs),
      decoration: BoxDecoration(
        color: c.surfaceVariant,
        borderRadius: BorderRadius.circular(BBRadius.full),
        border: Border.all(color: c.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _segments
            .map(
              (s) => _PeriodSegment(
                label: s.label,
                selected: dateRange.preset == s.preset,
                onTap: () => ref
                    .read(dashboardDateRangeNotifierProvider.notifier)
                    .setPreset(s.preset),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _PeriodSegment extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PeriodSegment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(BBRadius.full),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(
              horizontal: _kGap14,
              vertical: BBSpace.xs,
            ),
            decoration: BoxDecoration(
              // Handoff PVPeriod active state: surface chip + shadow-sm on
              // the surface-variant track (not a primary fill).
              color: selected ? c.surface : Colors.transparent,
              borderRadius: BorderRadius.circular(BBRadius.full),
              boxShadow: selected ? BBShadow.sm : null,
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? c.textPrimary : c.textSecondary,
                fontSize: _kFont13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                letterSpacing: -0.1,
                height: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "Nova rezervacija" header CTA (handoff PVHeader): gradient-hero pill with
/// add icon; routes to Rezervacije where the create dialog lives.
class _NewBookingCta extends StatelessWidget {
  const _NewBookingCta();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Nova rezervacija',
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: BBGradient.hero,
          borderRadius: BorderRadius.circular(_kRad10),
          boxShadow: BBShadow.purpleGlow(context),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.go(OwnerRoutes.bookings),
            borderRadius: BorderRadius.circular(_kRad10),
            child: const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: _kGap14,
                vertical: BBSpace.xs,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, size: 18, color: Colors.white),
                  SizedBox(width: _kGap6),
                  Text(
                    'Nova rezervacija',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: _kFont13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.1,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
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
              padding: const EdgeInsets.all(_kGap12),
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
            const SizedBox(width: BBSpace.sm),
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
        const SizedBox(height: BBSpace.sm),
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
  final VoidCallback onTap;
  final bool isPrimary;

  const _ActionStepCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 0,
      color: isPrimary
          ? theme.colorScheme.primary.withValues(alpha: 0.04)
          : (isDark
                ? theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.5)
                : theme.colorScheme.surfaceContainerLow),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BBRadius.md),
        side: BorderSide(
          color: isPrimary
              ? theme.colorScheme.primary.withValues(alpha: 0.35)
              : (isDark
                    ? theme.colorScheme.outlineVariant.withValues(alpha: 0.2)
                    : theme.colorScheme.outlineVariant),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(BBSpace.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(_kGap12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(_kRad14),
                ),
                child: Icon(icon, color: theme.colorScheme.primary, size: 26),
              ),
              const SizedBox(height: _kGap20),
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                  fontSize: _kFont20,
                ),
              ),
              const SizedBox(height: _kGap6),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: _kGap20),
              Row(
                children: [
                  Text(
                    l10n.dashboardGetStarted,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: _kFont15,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: _kGap6),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
            ],
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

  /// Test-only clock pin. Production passes nothing → live [DateTime.now].
  final DateTime? nowOverride;

  const _PregledGreetingHeader({
    required this.userName,
    required this.isMobile,
    this.nowOverride,
  });

  String _greetingForHour(int hour) {
    if (hour < 11) return 'Dobro jutro';
    if (hour < 18) return 'Dobar dan';
    return 'Dobra večer';
  }

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    final now = nowOverride ?? DateTime.now();
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
        const SizedBox(height: _kGap6),
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
          fontSize: isMobile ? _kKpiValueMobile : _kKpiValueDesktop,
          height: 1.0,
        );

    // Delta chip derived from the sparkline series (first → last). Real derived
    // data — no fabrication (handoff PVKpiCard delta). Hidden when the series is
    // too short or starts at zero (e.g. the avg-rating tile has no series yet).
    final hasTrend = sparkData.length >= 2 && sparkData.first > 0;
    final trendPct = hasTrend
        ? (sparkData.last - sparkData.first) / sparkData.first * 100
        : 0.0;
    final trendUp = trendPct >= 0;
    final trendColor = trendUp ? c.success : c.error;

    return BbCard(
      padding: EdgeInsets.all(isMobile ? _kGap14 : _kGap20),
      hoverable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: iconBoxSize,
                height: iconBoxSize,
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(_kRad10),
                ),
                alignment: Alignment.center,
                child: BbIcon(name: icon, size: iconSize, color: tone),
              ),
              const Spacer(),
              if (hasTrend)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    BbIcon(
                      name: trendUp ? 'trending_up' : 'trending_down',
                      size: 14,
                      color: trendColor,
                    ),
                    const SizedBox(width: BBSpace.xxs),
                    Text(
                      '${trendUp ? '+' : '−'}${trendPct.abs().toStringAsFixed(0)}%',
                      style: BBType.caption(context).copyWith(
                        color: trendColor,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          SizedBox(height: isMobile ? _kGap12 : _kGap14),
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
          const SizedBox(height: BBSpace.xxs),
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
                const SizedBox(width: BBSpace.xs),
                BbSparkline(
                  data: sparkData,
                  width: isMobile ? 56 : 96,
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

/// "Nadolazeći dolasci" card (handoff PVArrivals): in-card header with title,
/// "Sljedećih 14 dana" caption and a Kalendar action, then arrival rows.
/// Always renders — an empty period shows a calm caption (handoff has no
/// empty-state branch).
class _PregledArrivalsCard extends StatelessWidget {
  final List<UpcomingArrival> arrivals;
  final bool isMobile;

  const _PregledArrivalsCard({required this.arrivals, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    final pad = isMobile ? _kGap14 : BBSpace.md;

    return BbCard(
      padded: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              pad,
              pad,
              pad,
              isMobile ? _kGap10 : _kGap14,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        // HR-only owner surface — handoff copy.
                        'Nadolazeći dolasci',
                        style: BBType.h3(context).copyWith(
                          color: c.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: _kGap2),
                      Text(
                        'Sljedećih 14 dana',
                        style: BBType.caption(
                          context,
                        ).copyWith(color: c.textTertiary),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => context.go(OwnerRoutes.calendarTimeline),
                  style: TextButton.styleFrom(
                    foregroundColor: c.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: _kGap10,
                      vertical: _kGap6,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Kalendar',
                    style: BBType.label(
                      context,
                    ).copyWith(color: c.primary, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          if (arrivals.isEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(pad, BBSpace.xxs, pad, pad),
              child: Text(
                'Nema dolazaka u sljedećih 14 dana.',
                style: BBType.caption(context).copyWith(color: c.textTertiary),
              ),
            )
          else
            ...List.generate(arrivals.length, (i) {
              final a = arrivals[i];
              return _PregledArrivalsRow(
                arrival: a,
                isFirst: i == 0,
                onTap: a.bookingId.isEmpty
                    ? null
                    : () => context.push(
                        OwnerRoutes.bookingDetail.replaceFirst(
                          ':bookingId',
                          a.bookingId,
                        ),
                      ),
              );
            }),
        ],
      ),
    );
  }
}

/// Arrival row — date chip + guest avatar + stay info + status badge
/// (handoff PVArrivals row). Upcoming window only carries confirmed/pending.
class _PregledArrivalsRow extends StatelessWidget {
  final UpcomingArrival arrival;
  final bool isFirst;
  final VoidCallback? onTap;

  const _PregledArrivalsRow({
    required this.arrival,
    required this.isFirst,
    required this.onTap,
  });

  bool get _isPending => arrival.status == 'pending';

  // HR pluralization for nights: 1 noć / N noći.
  String _nightsLabel(int n) => (n % 10 == 1 && n % 100 != 11) ? 'noć' : 'noći';

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    final isMobile = MediaQuery.of(context).size.width < 600;
    final stay = <String>[
      if (arrival.propertyName.isNotEmpty) arrival.propertyName,
      if (arrival.unitName.isNotEmpty) arrival.unitName,
      if (arrival.nights > 0)
        '${arrival.nights} ${_nightsLabel(arrival.nights)}',
    ].join(' · ');

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? _kGap14 : BBSpace.md,
          vertical: _kGap12,
        ),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: c.border)),
        ),
        child: Row(
          children: [
            // Next-guest hero date chip (handoff PV_ARRIVALS[next:true]).
            // First row gets gradient-hero + purple shadow + white text;
            // others get surface-variant + tertiary text.
            _ArrivalsDateChip(date: arrival.checkIn, highlighted: isFirst),
            SizedBox(width: isMobile ? _kGap10 : _kGap14),
            BbAvatar(
              name: arrival.guestName,
              size: BbAvatarSize.sm,
              tone: _isPending ? BbAvatarTone.tertiary : BbAvatarTone.success,
            ),
            SizedBox(width: isMobile ? _kGap10 : _kGap14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    arrival.guestName,
                    style: BBType.label(context).copyWith(
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: _kGap2),
                  Text(
                    stay,
                    style: BBType.caption(
                      context,
                    ).copyWith(color: c.textTertiary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: BBSpace.xs),
            BbStatusBadge(
              status: _isPending
                  ? BbBookingStatus.pending
                  : BbBookingStatus.confirmed,
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
      padding: const EdgeInsets.symmetric(vertical: BBSpace.xxs),
      decoration: BoxDecoration(
        gradient: highlighted ? BBGradient.hero : null,
        color: highlighted ? null : c.surfaceVariant,
        borderRadius: BorderRadius.circular(_kRad10),
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
              fontSize: _kChipDayFont,
              letterSpacing: 0.5,
            ),
          ),
          Text(
            '${date.day}',
            style: BBType.bodyNum(context).copyWith(
              color: numColor,
              fontWeight: FontWeight.w700,
              fontSize: _kChipDateFont,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pregled hand-tuned sizing (audit/124). Off the 8px BBSpace grid, named here
// so no raw spacing literals remain while the exact premium rhythm is preserved. ──
const double _kGap1 = 1;
const double _kGap2 = 2;
const double _kGap6 = 6;
const double _kGap10 = 10;
const double _kGap12 = 12;
const double _kGap14 = 14;
const double _kGap18 = 18;
const double _kGap20 = 20;
const double _kGap22 = 22;
const double _kGap28 = 28;
const double _kGap36 = 36;
const double _kGap40 = 40;
const double _kGap60 = 60;
const double _kRad3 = 3;
const double _kRad4 = 4;
const double _kRad8 = 8;
const double _kRad10 = 10;
const double _kRad14 = 14;
const double _kPanelRadius = 28;
const double _kKpiValueMobile = 24;
const double _kKpiValueDesktop = 30;
const double _kOccValueMobile = 30;
const double _kOccValueDesktop = 34;
const double _kDepositValue = 28;
const double _kChipDayFont = 10;
const double _kChipDateFont = 14;
const double _kFont13 = 13;
const double _kFont15 = 15;
const double _kFont20 = 20;
const double _kHeroPadMobile = 20;
const double _kHeroPadDesktop = 28;
const double _kHeroNumMobile = 40;
const double _kHeroNumDesktop = 56;
const double _kHeroChartMobile = 150;
const double _kHeroChartDesktop = 190;

/// Single-series labeled revenue chart for the hero (handoff PVRevenueCommand
/// chart slot). Replaces the prior sparkline with a real €-axis + date x-axis.
/// The x dimension is a [LinearScale] over the point index with a `formatter`
/// that maps each tick back to the grouped date label plus a small `tickCount`,
/// so the dates read cleanly (~5 labels) instead of the raw 0,1,2 the old chart
/// rendered. Previous-period ghost line + legend are intentionally deferred
/// (no prior-period series in [UnifiedDashboardData] yet).
class _RevenueAreaChart extends StatelessWidget {
  final List<RevenueDataPoint> data;
  final double height;

  const _RevenueAreaChart({required this.data, required this.height});

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    final n = data.length;
    final rows = data
        .asMap()
        .entries
        .map((e) => {'index': e.key, 'amount': e.value.amount})
        .toList(growable: false);
    String fmtX(num v) {
      final i = v.round();
      return (i >= 0 && i < n) ? data[i].label : '';
    }

    return SizedBox(
      height: height,
      child: Chart(
        data: rows,
        variables: {
          'index': Variable(
            accessor: (Map map) => map['index'] as num,
            scale: LinearScale(
              min: 0,
              max: (n - 1).toDouble(),
              tickCount: n <= 6 ? n : 5,
              formatter: fmtX,
            ),
          ),
          'amount': Variable(
            accessor: (Map map) => map['amount'] as num,
            scale: LinearScale(min: 0),
          ),
        },
        marks: [
          AreaMark(
            shape: ShapeEncode(value: BasicAreaShape(smooth: true)),
            color: ColorEncode(value: c.primary.withValues(alpha: 0.15)),
            entrance: {MarkEntrance.y},
          ),
          LineMark(
            shape: ShapeEncode(value: BasicLineShape(smooth: true)),
            size: SizeEncode(value: 3),
            color: ColorEncode(value: c.primary),
            entrance: {MarkEntrance.y},
          ),
        ],
        axes: [Defaults.horizontalAxis, Defaults.verticalAxis],
        selections: {
          'touch': PointSelection(
            on: {GestureType.hover},
            devices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
          ),
        },
        tooltip: TooltipGuide(
          backgroundColor: c.surface,
          elevation: 8,
          textStyle: BBType.caption(context).copyWith(color: c.textPrimary),
        ),
        crosshair: CrosshairGuide(followPointer: const [false, true]),
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

  ({double pct, double prevSum, double diff}) _deltaVsPrior() {
    final h = data.revenueHistory;
    if (h.length < 4) return (pct: 0, prevSum: 0, diff: 0);
    final mid = h.length ~/ 2;
    double prev = 0, curr = 0;
    for (int i = 0; i < mid; i++) {
      prev += h[i].amount;
    }
    for (int i = mid; i < h.length; i++) {
      curr += h[i].amount;
    }
    if (prev <= 0) return (pct: 0, prevSum: 0, diff: 0);
    final pct = (curr - prev) / prev * 100;
    return (pct: pct, prevSum: prev, diff: curr - prev);
  }

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    final l10n = AppLocalizations.of(context);
    final hasHistory = data.revenueHistory.length >= 2;
    final d = _deltaVsPrior();
    final hasDelta = d.prevSum > 0;
    final positive = d.pct >= 0;
    final deltaColor = positive ? c.success : c.error;
    final deltaIcon = positive ? 'trending_up' : 'trending_down';
    final deltaLabel =
        '${positive ? '+' : ''}${d.pct.toStringAsFixed(1).replaceAll('.', ',')}%';

    return BbCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BBRadius.mdAll,
        child: Stack(
          children: [
            // Radial gradient wash behind the headline number (handoff
            // PVRevenueCommand `radial-gradient(60% 60% at 30% 35%, …)`).
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(-0.4, -0.3),
                      radius: 1.0,
                      colors: [
                        c.primary.withValues(alpha: 0.13),
                        c.primaryLight.withValues(alpha: 0.05),
                        Colors.transparent,
                      ],
                      stops: const <double>[0.0, 0.45, 0.72],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(
                isMobile ? _kHeroPadMobile : _kHeroPadDesktop,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    // HR-only owner surface; handoff eyebrow copy.
                    // `BBType.eyebrow` styles letter-spacing only — Flutter has
                    // no CSS text-transform, so casing is applied here.
                    'Ukupna zarada · ${_periodLabel(l10n)}'.toUpperCase(),
                    style: BBType.eyebrow(
                      context,
                    ).copyWith(color: c.textTertiary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: isMobile ? _kGap10 : _kGap12),
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
                              letterSpacing: -2.0,
                              height: 1.0,
                              color: c.textPrimary,
                              fontSize: isMobile
                                  ? _kHeroNumMobile
                                  : _kHeroNumDesktop,
                            ),
                          ),
                        ),
                      ),
                      if (hasDelta) ...[
                        const SizedBox(width: _kGap10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: BBSpace.xs,
                            vertical: BBSpace.xxs,
                          ),
                          decoration: BoxDecoration(
                            color: deltaColor.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(BBRadius.full),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              BbIcon(
                                name: deltaIcon,
                                size: 14,
                                color: deltaColor,
                              ),
                              const SizedBox(width: BBSpace.xxs),
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
                  if (hasDelta) ...[
                    const SizedBox(height: _kGap6),
                    Text(
                      // Handoff comparison caption: previous half-period sum
                      // and the absolute delta against it.
                      '€${d.prevSum.toStringAsFixed(0)} u prethodnom razdoblju'
                      ' · ${d.diff >= 0 ? '+' : '−'}€${d.diff.abs().toStringAsFixed(0)}',
                      style: BBType.caption(
                        context,
                      ).copyWith(color: c.textTertiary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (hasHistory) ...[
                    SizedBox(height: isMobile ? _kGap14 : _kGap18),
                    _RevenueAreaChart(
                      data: data.revenueHistory,
                      height: isMobile ? _kHeroChartMobile : _kHeroChartDesktop,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
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
    // Handoff PVRadial size 168 / stroke 16 (painter stroke = 0.10·size ≈ 16).
    final size = isMobile ? 140.0 : 168.0;

    return BbCard(
      padding: EdgeInsets.all(isMobile ? _kGap18 : BBSpace.md),
      // Handoff PVOccupancy: eyebrow top-left, gauge + status centered beneath.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.ownerOccupancyRate.toUpperCase(),
            style: BBType.eyebrow(context).copyWith(color: c.textTertiary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: isMobile ? _kGap14 : _kGap18),
          Center(
            child: SizedBox(
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
                            fontSize: isMobile
                                ? _kOccValueMobile
                                : _kOccValueDesktop,
                          ),
                        ),
                        const SizedBox(height: BBSpace.xxs),
                        Text(
                          // HR-only owner surface; handoff radial sublabel slot.
                          '${data.bookings} rezervacija',
                          style: BBType.caption(
                            context,
                          ).copyWith(color: c.textTertiary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: isMobile ? _kGap14 : _kGap18),
          // Real upcoming check-ins replaces the handoff "+8 pp vs prošli
          // mjesec" delta, which is deferred (no prior-period occupancy yet).
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: BBSpace.xs,
                vertical: BBSpace.xxs,
              ),
              decoration: BoxDecoration(
                color: c.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(BBRadius.full),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  BbIcon(name: 'donut_small', size: 14, color: c.primary),
                  const SizedBox(width: BBSpace.xxs),
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
      padding: EdgeInsets.all(isMobile ? _kGap14 : _kGap18),
      decoration: BoxDecoration(
        // FLAT surface (wash retired 2026-06-16): the purple→mint banner
        // gradient is gone; the AI identity now lives only in the purple icon
        // tile + label. Neutral surface-variant fill; border + shadow define it.
        color: c.surfaceVariant,
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
              borderRadius: BorderRadius.circular(BBRadius.sm),
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
          SizedBox(width: isMobile ? _kGap12 : BBSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: BBSpace.xs,
                        vertical: _kGap2,
                      ),
                      decoration: BoxDecoration(
                        color: c.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(BBRadius.xs),
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
                    const SizedBox(width: BBSpace.xs),
                    Text(
                      // HR-only owner surface.
                      'Uvid tjedna',
                      style: BBType.caption(
                        context,
                      ).copyWith(color: c.textTertiary),
                    ),
                  ],
                ),
                const SizedBox(height: _kGap6),
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
                const SizedBox(height: _kGap12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        foregroundColor: c.textSecondary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: _kGap12,
                          vertical: _kGap6,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Odbaci',
                        style: BBType.label(context).copyWith(
                          color: c.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: BBSpace.xs),
                    FilledButton(
                      onPressed: () {},
                      style: FilledButton.styleFrom(
                        backgroundColor: c.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: _kGap14,
                          vertical: BBSpace.xs,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(_kRad8),
                        ),
                      ),
                      child: Text(
                        'Primjeni',
                        style: BBType.label(context).copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
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

  // Real per-source revenue from UnifiedDashboardData.revenueBySource
  // (handoff PVChannels). Bucket order/colors fixed; zero buckets dropped.
  List<_ChannelEntry> _entries(BBColorSet c) {
    final src = data.revenueBySource;
    final total = src.values.fold<double>(0, (a, b) => a + b);
    if (total <= 0) return const [];

    // HR-only owner surface labels.
    final buckets = <({String key, String label, Color color})>[
      (key: 'direct', label: 'Direktno', color: c.primary),
      (key: 'booking_com', label: 'Booking.com', color: c.info),
      (key: 'airbnb', label: 'Airbnb', color: c.error),
      (key: 'other', label: 'Ostalo', color: c.tertiary),
    ];

    return [
      for (final b in buckets)
        if ((src[b.key] ?? 0) > 0)
          _ChannelEntry(
            label: b.label,
            // Min flex 1 so thin-but-real slices stay visible in the bar.
            pct: math.max(1, (src[b.key]! / total * 100).round()),
            amount: src[b.key]!,
            color: b.color,
          ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    final entries = _entries(c);
    if (entries.isEmpty) return const SizedBox.shrink();

    return BbCard(
      padding: EdgeInsets.all(isMobile ? BBSpace.sm : BBSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: title left, plain donut icon right (handoff PVChannels —
          // no tinted icon box).
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                    const SizedBox(height: _kGap2),
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
              const SizedBox(width: BBSpace.xs),
              BbIcon(name: 'donut_small', color: c.textTertiary),
            ],
          ),
          SizedBox(height: isMobile ? _kGap14 : _kGap18),
          // Stacked share bar — 2px gaps + rounded segment ends (handoff).
          ClipRRect(
            borderRadius: BorderRadius.circular(BBRadius.full),
            child: SizedBox(
              height: _kGap12,
              child: Row(
                children: [
                  for (final e in entries)
                    Expanded(
                      flex: e.pct,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: _kGap1),
                        decoration: BoxDecoration(
                          color: e.color,
                          borderRadius: BorderRadius.circular(_kRad4),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(height: isMobile ? _kGap14 : _kGap18),
          Column(
            children: [
              for (int i = 0; i < entries.length; i++) ...[
                if (i > 0) const SizedBox(height: BBSpace.sm),
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: entries[i].color,
                        borderRadius: BorderRadius.circular(_kRad3),
                      ),
                    ),
                    const SizedBox(width: _kGap10),
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
                    const SizedBox(width: BBSpace.xs),
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
                // Per-channel breakdown bar (handoff PVChannels rows):
                // surface-variant track + channel-color fill.
                const SizedBox(height: _kGap6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(BBRadius.full),
                  child: SizedBox(
                    height: _kGap6,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: ColoredBox(color: c.surfaceVariant),
                        ),
                        Positioned.fill(
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: (entries[i].pct / 100).clamp(0.0, 1.0),
                            child: ColoredBox(color: entries[i].color),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Deposits card (handoff `owner-01-pregled.png` NAPLAĆENI DEPOZITI):
/// collected `paid_amount` headline + outstanding-at-arrival row with a
/// collected/(collected+outstanding) progress bar. Always renders — €0 is
/// the calm empty baseline, same as the hero (handoff has no empty branch).
class _PregledDepositsCard extends StatelessWidget {
  final UnifiedDashboardData data;
  final bool isMobile;

  const _PregledDepositsCard({required this.data, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    final collected = data.depositsCollected;
    final outstanding = data.depositsOutstanding;
    final expected = collected + outstanding;
    final share = expected > 0 ? (collected / expected).clamp(0.0, 1.0) : 0.0;

    return BbCard(
      padding: EdgeInsets.all(isMobile ? BBSpace.sm : BBSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handoff PVDeposit: plain eyebrow, no icon box.
          Text(
            // HR-only owner surface — handoff eyebrow copy.
            'NAPLAĆENI DEPOZITI',
            style: BBType.caption(context).copyWith(
              color: c.textTertiary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: isMobile ? _kGap10 : _kGap12),
          // Collected figure + inline "/ €expected očekivano" (handoff).
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  '€${collected.toStringAsFixed(0)}',
                  style: BBType.h1Num(context).copyWith(
                    color: c.textPrimary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    fontSize: _kDepositValue,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: BBSpace.xs),
              Flexible(
                child: Text(
                  '/ €${expected.toStringAsFixed(0)} očekivano',
                  style: BBType.caption(
                    context,
                  ).copyWith(color: c.textTertiary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? _kGap12 : _kGap14),
          ClipRRect(
            borderRadius: BorderRadius.circular(BBRadius.full),
            child: SizedBox(
              height: BBSpace.xs,
              child: Stack(
                children: [
                  // Handoff: surface-variant track + success gradient fill
                  // (#2E7D5B → #4FAE7F, same hexes both themes).
                  Positioned.fill(child: ColoredBox(color: c.surfaceVariant)),
                  Positioned.fill(
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: share,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [BBColor.success, BBColor.successDarkMode],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: BBSpace.xs),
          Row(
            children: [
              Expanded(
                child: Text(
                  // HR-only owner surface (accurate "collected" wording kept
                  // over the handoff's "Polog"; layout matches).
                  'Naplaćeno (${(share * 100).round()}%)',
                  style: BBType.caption(
                    context,
                  ).copyWith(color: c.textTertiary),
                ),
              ),
              Text(
                '€${outstanding.toStringAsFixed(0)} na dolasku',
                style: BBType.caption(context).copyWith(
                  color: c.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
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
