import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/bb_redesign_tokens.dart';
import '../../../../core/design/tokens.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/redesign.dart';
import '../../data/admin_users_repository.dart';
import 'admin_shell_screen.dart';

const double _mobileBreakpoint = 800.0;
const double _tabletBreakpoint = 1100.0;

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final signupsAsync = ref.watch(recentSignupsProvider);
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < _mobileBreakpoint;
    final isTablet = width >= _mobileBreakpoint && width < _tabletBreakpoint;
    final palette = _DashboardPalette.of(context, ref);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BbSectionHeader(title: 'Dashboard Overview'),
            const SizedBox(height: 4),
            Text(
              'Welcome back! Here is what\'s happening with your platform.',
              style: BBType.body(
                context,
              ).copyWith(color: palette.textSecondary),
            ),
            const SizedBox(height: 32),
            statsAsync.when(
              data: (stats) {
                final totalOwners = stats['totalOwners'] ?? 0;
                final trialUsers = stats['trialUsers'] ?? 0;
                final premiumUsers = stats['premiumUsers'] ?? 0;
                final lifetimeUsers = stats['lifetimeUsers'] ?? 0;

                final statsItems = <_StatItem>[
                  _StatItem(
                    title: 'Total Owners',
                    value: totalOwners.toString(),
                    icon: Icons.people,
                    color: AppColors.info,
                  ),
                  _StatItem(
                    title: 'Trial Users',
                    value: trialUsers.toString(),
                    icon: Icons.timer,
                    color: AppColors.warning,
                  ),
                  _StatItem(
                    title: 'Premium Users',
                    value: premiumUsers.toString(),
                    icon: Icons.star,
                    color: AppColors.success,
                  ),
                  _StatItem(
                    title: 'Lifetime Licenses',
                    value: lifetimeUsers.toString(),
                    icon: Icons.verified,
                    color: AppColors.primary,
                  ),
                ];

                final availableWidth = width - 48;
                final columns = (isMobile || isTablet) ? 2 : 4;
                final totalSpacing = (columns - 1) * 16.0;
                final itemWidth = (availableWidth - totalSpacing) / columns;

                final paidUsers = premiumUsers + lifetimeUsers;
                final conversionRate = totalOwners > 0
                    ? (paidUsers / totalOwners * 100)
                    : 0.0;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: statsItems
                          .map(
                            (item) => SizedBox(
                              width: itemWidth < 140 ? 140 : itemWidth,
                              child: _StatsCard(
                                item: item,
                                palette: palette,
                                // admin-shell.jsx AdmKpi `compact` mode:
                                // padding 14 + value 24 (vs default 20 / 30)
                                // on tablet/mobile breakpoints.
                                compact: isMobile || isTablet,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                    const BbSectionHeader(
                      title: 'Analytics',
                      // admin-shell.jsx uses per-card `.bb-h3` (18/600) for
                      // sub-section headers, not the page-level `.bb-h2`.
                      level: BbSectionHeaderLevel.h3,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        SizedBox(
                          width: isMobile ? availableWidth : 280,
                          child: _AnalyticsCard(
                            title: 'Conversion Rate',
                            subtitle: 'Trial to Paid',
                            value: '${conversionRate.toStringAsFixed(1)}%',
                            detail: '$paidUsers of $totalOwners owners',
                            icon: Icons.trending_up,
                            color: const Color(0xFF4A90D9),
                            palette: palette,
                          ),
                        ),
                        signupsAsync.when(
                          data: (signups) => SizedBox(
                            width: isMobile ? availableWidth : 280,
                            child: _AnalyticsCard(
                              title: 'New Signups',
                              subtitle: 'Last 7 days',
                              value: signups['last7Days']?.toString() ?? '0',
                              detail:
                                  '${signups['last30Days'] ?? 0} in last 30 days',
                              icon: Icons.person_add,
                              color: AppColors.primary,
                              palette: palette,
                            ),
                          ),
                          loading: () => SizedBox(
                            width: isMobile ? availableWidth : 280,
                            height: 140,
                            child: const Center(child: BbSpinner()),
                          ),
                          error: (_, _) => const SizedBox.shrink(),
                        ),
                        SizedBox(
                          width: isMobile ? availableWidth : 280,
                          child: _DistributionCard(
                            totalOwners: totalOwners,
                            trialUsers: trialUsers,
                            premiumUsers: premiumUsers,
                            lifetimeUsers: lifetimeUsers,
                            palette: palette,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
              loading: () => const _StatsLoading(),
              error: (err, _) => _StatsError(
                error: err.toString(),
                onRetry: () => ref.invalidate(dashboardStatsProvider),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Resolves text-tier colors that read correctly in both admin-light and
/// admin-dark shell modes. Admin shell wraps its child in a [Theme] whose
/// `colorScheme` follows the `adminDarkModeProvider` toggle. In dark mode we
/// pull from canonical [BbAdminDarkTokens]; in light mode we fall back to the
/// shell-provided MD3 `onSurface`/`onSurfaceVariant`.
class _DashboardPalette {
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final bool isDark;

  const _DashboardPalette({
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.isDark,
  });

  static _DashboardPalette of(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(adminDarkModeProvider);
    if (isDark) {
      final t = BbAdminDarkTokens.of(context);
      return _DashboardPalette(
        textPrimary: t.textPrimary,
        textSecondary: t.textSecondary,
        textTertiary: t.textTertiary,
        isDark: true,
      );
    }
    // Light branch reads canonical BookBed text colours instead of the
    // admin shell's MD3 ColorScheme. The shell's `ThemeData.light(...)` does
    // not override `onSurface`, leaving it at the MD3 default `~#1C1B1F`,
    // whereas `tokens.css :root --bb-text-primary` (the canonical design
    // colour) resolves to `#2D3748` (`BBColor.textPrimaryLight`). This is a
    // SYSTEMIC admin-light-theme drift; the local fix here keeps the
    // dashboard on slate without modifying the shared shell theme. A
    // separate PR should set `colorScheme.onSurface/.onSurfaceVariant` in
    // `admin_shell_screen.dart:64-71` so all admin LIGHT screens pick up
    // canonical text colours.
    final c = BBColor.of(context);
    return _DashboardPalette(
      textPrimary: c.textPrimary,
      textSecondary: c.textSecondary,
      textTertiary: c.textTertiary,
      isDark: false,
    );
  }
}

class _StatItem {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  _StatItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}

/// KPI tile — mirrors `design_handoff/source/admin-shell.jsx:165-177` `AdmKpi`.
///
/// Top-down: 36 × 36 icon tile (no delta-pill; absent pending data wiring)
/// → uppercase eyebrow label → big tabular value → (sub line absent pending
/// data wiring).
///
/// Delta-pill and sub-line omitted because `admin_users_repository
/// .getDashboardStats()` returns counts only (no time-series for deltas, no
/// context strings). Adding them would require backend / repository changes
/// and is tracked as a product follow-up in this PR's body. The chrome is
/// shaped so adding them later is additive only.
class _StatsCard extends StatelessWidget {
  final _StatItem item;
  final _DashboardPalette palette;
  final bool compact;

  const _StatsCard({
    required this.item,
    required this.palette,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    // AdmKpi compact override: tile padding 14, value font 24 (vs default
    // 20 / 30) on tablet/mobile.
    final EdgeInsets cardPadding = EdgeInsets.all(compact ? 14 : 20);
    // Value typography per design: 30 / 800 / -0.02em (desktop), 24 / 800 /
    // -0.02em (compact). Inter-Black (w800) is NOT bundled locally; admin
    // web runtime-fetches missing weights from Google Fonts CDN
    // (`GoogleFonts.config.allowRuntimeFetching` defaults to `true` on
    // admin entries, unlike owner/widget which disable it).
    final double valueSize = compact ? 24 : 30;
    final double valueLetterSpacing = compact ? -0.48 : -0.6;

    return BbCard(
      padding: cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              // color-mix(in srgb, <color> 14%, transparent) — 14 % opacity
              // tint of the metric color over transparent.
              color: item.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, color: item.color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            // .bb-caption base (12) overridden to 10 px UPPERCASE
            // 600 / +0.05em tertiary — design-canonical eyebrow.
            item.title.toUpperCase(),
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5, // 0.05em × 10
              height: 1.5,
              color: palette.textTertiary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.value,
            style: BBType.h1Num(context).copyWith(
              fontSize: valueSize,
              fontWeight: FontWeight.w800,
              letterSpacing: valueLetterSpacing,
              height: 1.0,
              color: palette.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String value;
  final String detail;
  final IconData icon;
  final Color color;
  final _DashboardPalette palette;

  const _AnalyticsCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.detail,
    required this.icon,
    required this.color,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return BbCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: BBType.body(context).copyWith(
                        color: palette.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: BBType.caption(
                        context,
                      ).copyWith(color: palette.textTertiary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: BBType.h1Num(context).copyWith(
              color: palette.textPrimary,
              fontWeight: FontWeight.bold,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            detail,
            style: BBType.caption(
              context,
            ).copyWith(color: palette.textTertiary),
          ),
        ],
      ),
    );
  }
}

class _DistributionCard extends StatelessWidget {
  final int totalOwners;
  final int trialUsers;
  final int premiumUsers;
  final int lifetimeUsers;
  final _DashboardPalette palette;

  const _DistributionCard({
    required this.totalOwners,
    required this.trialUsers,
    required this.premiumUsers,
    required this.lifetimeUsers,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return BbCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.pie_chart,
                  color: AppColors.info,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Account Distribution',
                style: BBType.body(context).copyWith(
                  color: palette.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (totalOwners > 0)
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 8,
                child: Row(
                  children: [
                    if (trialUsers > 0)
                      Expanded(
                        flex: trialUsers,
                        child: Container(color: AppColors.warning),
                      ),
                    if (premiumUsers > 0)
                      Expanded(
                        flex: premiumUsers,
                        child: Container(color: AppColors.success),
                      ),
                    if (lifetimeUsers > 0)
                      Expanded(
                        flex: lifetimeUsers,
                        child: Container(color: AppColors.primary),
                      ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          _DistLegendRow(
            color: AppColors.warning,
            label: 'Trial',
            count: trialUsers,
            total: totalOwners,
            palette: palette,
          ),
          const SizedBox(height: 4),
          _DistLegendRow(
            color: AppColors.success,
            label: 'Premium',
            count: premiumUsers,
            total: totalOwners,
            palette: palette,
          ),
          const SizedBox(height: 4),
          _DistLegendRow(
            color: AppColors.primary,
            label: 'Lifetime',
            count: lifetimeUsers,
            total: totalOwners,
            palette: palette,
          ),
        ],
      ),
    );
  }
}

class _DistLegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final int count;
  final int total;
  final _DashboardPalette palette;

  const _DistLegendRow({
    required this.color,
    required this.label,
    required this.count,
    required this.total,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (count / total * 100).toStringAsFixed(0) : '0';
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: BBType.caption(context).copyWith(color: palette.textSecondary),
        ),
        const Spacer(),
        Text(
          '$count ($pct%)',
          style: BBType.caption(
            context,
          ).copyWith(color: palette.textPrimary, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _StatsLoading extends StatelessWidget {
  const _StatsLoading();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: List.generate(
        4,
        (index) => const SizedBox(
          width: 240,
          height: 140,
          child: BbSkeleton(width: 240, height: 140),
        ),
      ),
    );
  }
}

class _StatsError extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _StatsError({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 420,
        child: BbCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                'Error loading stats',
                style: BBType.h2(context).copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                style: BBType.caption(context),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              BbButton(label: 'Retry', iconLeft: 'refresh', onPressed: onRetry),
            ],
          ),
        ),
      ),
    );
  }
}
