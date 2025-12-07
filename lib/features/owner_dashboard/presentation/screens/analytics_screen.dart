import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphic/graphic.dart';
import '../../domain/models/analytics_summary.dart';
import '../providers/analytics_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/gradient_extensions.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/error_state_widget.dart';
import '../../../../shared/widgets/common_app_bar.dart';
import '../../../../shared/widgets/custom_date_range_picker.dart';
import '../../../../shared/widgets/animations/skeleton_loader.dart';
import '../widgets/owner_app_drawer.dart';

/// Helper function to create purple shade variations (1-6, darkest to lightest).
/// Uses fixed purple shades for consistent colors in light and dark mode.
Color _getPurpleShade(int level) {
  switch (level) {
    case 1: // Darkest purple
      return const Color(0xFF4A3A8C); // Dark violet
    case 2: // Dark purple
      return const Color(0xFF5B4BA8); // Medium violet
    case 3: // Original purple (primary-like)
      return const Color(0xFF6B4CE6); // Standard purple
    case 4: // Light purple
      return const Color(0xFF8B6FF5); // Light purple
    case 5: // Lighter purple
      return const Color(0xFFA08BFF); // Very light purple
    case 6: // Lightest purple (more desaturated)
      return const Color(0xFFB8A8FF); // Pastel purple
    default:
      return const Color(0xFF6B4CE6); // Default to standard purple
  }
}

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final dateRange = ref.watch(dateRangeNotifierProvider);
    final analyticsAsync = ref.watch(analyticsNotifierProvider(dateRange: dateRange));

    return Scaffold(
      drawer: const OwnerAppDrawer(currentRoute: 'analytics'),
      appBar: CommonAppBar(
        title: l10n.ownerAnalyticsTitle,
        leadingIcon: Icons.menu,
        onLeadingIconTap: (context) => Scaffold.of(context).openDrawer(),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: context.gradients.pageBackground),
        child: Column(
          children: [
            _DateRangeSelector(dateRange: dateRange),
            Expanded(
              child: analyticsAsync.when(
                data: (analytics) => _AnalyticsContent(analytics: analytics, dateRange: dateRange),
                loading: SkeletonLoader.analytics,
                error: (error, stack) => ErrorStateWidget(
                  message: l10n.ownerAnalyticsLoadError,
                  onRetry: () {
                    ref.invalidate(analyticsNotifierProvider);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateRangeSelector extends ConsumerWidget {
  final DateRangeFilter dateRange;

  const _DateRangeSelector({required this.dateRange});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: context.horizontalPadding, vertical: isMobile ? 12 : 16),
      color: Colors.transparent,
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _FilterChip(
                    label: l10n.ownerAnalyticsLastWeek,
                    selected: dateRange.preset == 'week',
                    onSelected: () {
                      ref.read(dateRangeNotifierProvider.notifier).setPreset('week');
                    },
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: l10n.ownerAnalyticsLastMonth,
                    selected: dateRange.preset == 'month',
                    onSelected: () {
                      ref.read(dateRangeNotifierProvider.notifier).setPreset('month');
                    },
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: l10n.ownerAnalyticsLastQuarter,
                    selected: dateRange.preset == 'quarter',
                    onSelected: () {
                      ref.read(dateRangeNotifierProvider.notifier).setPreset('quarter');
                    },
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: l10n.ownerAnalyticsLastYear,
                    selected: dateRange.preset == 'year',
                    onSelected: () {
                      ref.read(dateRangeNotifierProvider.notifier).setPreset('year');
                    },
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showCustomDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                        initialDateRange: DateTimeRange(start: dateRange.startDate, end: dateRange.endDate),
                      );
                      if (picked != null) {
                        ref.read(dateRangeNotifierProvider.notifier).setCustomRange(picked.start, picked.end);
                      }
                    },
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(l10n.ownerAnalyticsCustomRange),
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

class _FilterChip extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({required this.label, required this.selected, required this.onSelected});

  @override
  State<_FilterChip> createState() => _FilterChipState();
}

class _FilterChipState extends State<_FilterChip> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Colors based on state
    final bgColor = widget.selected
        ? theme.colorScheme.primary
        : _isHovered
        ? theme.colorScheme.primary.withValues(alpha: 0.08)
        : context.gradients.cardBackground;

    final borderColor = widget.selected
        ? theme.colorScheme.primary
        : _isHovered
        ? theme.colorScheme.primary.withValues(alpha: 0.4)
        : context.gradients.sectionBorder;

    final textColor = widget.selected ? Colors.white : theme.colorScheme.onSurface;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: FilterChip(
          label: Text(widget.label),
          selected: widget.selected,
          onSelected: (_) => widget.onSelected(),
          selectedColor: bgColor,
          backgroundColor: bgColor,
          side: BorderSide(color: borderColor, width: 1.5),
          labelStyle: TextStyle(
            color: textColor,
            fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
          ),
          checkmarkColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: widget.selected ? 2 : 0,
          shadowColor: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}

class _AnalyticsContent extends StatelessWidget {
  final AnalyticsSummary analytics;
  final DateRangeFilter dateRange;

  const _AnalyticsContent({required this.analytics, required this.dateRange});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isDesktop = screenWidth > 900;

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: context.horizontalPadding, vertical: isMobile ? 12 : 16),
      children: [
        // Metric Cards
        _MetricCardsGrid(analytics: analytics, dateRange: dateRange),
        SizedBox(height: isMobile ? 16 : 20), // Reduced from 24/32
        // Charts Section - Desktop: side-by-side, Mobile/Tablet: stacked
        if (isDesktop) _buildDesktopChartsRow(l10n) else _buildStackedCharts(isMobile, l10n),

        SizedBox(height: isMobile ? 16 : 20), // Reduced from 24/32
        // Bottom Section - Desktop: side-by-side, Mobile/Tablet: stacked
        if (isDesktop) _buildDesktopBottomRow(l10n) else _buildStackedBottom(isMobile, l10n),

        SizedBox(height: isMobile ? 12 : 16), // Reduced from 16/24
      ],
    );
  }

  /// Desktop layout - Charts side-by-side (Revenue + Bookings)
  Widget _buildDesktopChartsRow(AppLocalizations l10n) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Revenue Chart (left) - header je unutar kartice
        Expanded(child: _RevenueChart(data: analytics.revenueHistory)),
        const SizedBox(width: 16), // Spacing between charts
        // Bookings Chart (right) - header je unutar kartice
        Expanded(child: _BookingsChart(data: analytics.bookingHistory)),
      ],
    );
  }

  /// Mobile/Tablet layout - Charts stacked vertically
  Widget _buildStackedCharts(bool isMobile, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Revenue Chart - header je unutar kartice
        _RevenueChart(data: analytics.revenueHistory),
        SizedBox(height: isMobile ? 16 : 20),

        // Bookings Chart - header je unutar kartice
        _BookingsChart(data: analytics.bookingHistory),
      ],
    );
  }

  /// Desktop layout - Bottom section side-by-side (Top Properties + Widget Analytics)
  Widget _buildDesktopBottomRow(AppLocalizations l10n) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Properties + Bookings by Source (left) - headeri su unutar kartica
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TopPropertiesList(properties: analytics.topPerformingProperties),
              const SizedBox(height: 20),
              _BookingsBySourceChart(bookingsBySource: analytics.bookingsBySource),
            ],
          ),
        ),
        const SizedBox(width: 16), // Spacing between sections
        // Widget Analytics (right) - header je unutar kartice
        Expanded(
          child: _WidgetAnalyticsCard(
            widgetBookings: analytics.widgetBookings,
            totalBookings: analytics.totalBookings,
            widgetRevenue: analytics.widgetRevenue,
            totalRevenue: analytics.totalRevenue,
          ),
        ),
      ],
    );
  }

  /// Mobile/Tablet layout - Bottom section stacked vertically
  Widget _buildStackedBottom(bool isMobile, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Properties - header je unutar kartice
        _TopPropertiesList(properties: analytics.topPerformingProperties),
        SizedBox(height: isMobile ? 16 : 20),

        // Widget Analytics - header je unutar kartice
        _WidgetAnalyticsCard(
          widgetBookings: analytics.widgetBookings,
          totalBookings: analytics.totalBookings,
          widgetRevenue: analytics.widgetRevenue,
          totalRevenue: analytics.totalRevenue,
        ),
        const SizedBox(height: 12),
        _BookingsBySourceChart(bookingsBySource: analytics.bookingsBySource),
      ],
    );
  }
}

class _MetricCardsGrid extends StatelessWidget {
  final AnalyticsSummary analytics;
  final DateRangeFilter dateRange;

  const _MetricCardsGrid({required this.analytics, required this.dateRange});

  String _getRecentPeriodLabel(AppLocalizations l10n) {
    final totalDays = dateRange.endDate.difference(dateRange.startDate).inDays;
    if (totalDays <= 7) return l10n.ownerAnalyticsLast7Days;
    if (totalDays <= 30) return l10n.ownerAnalyticsLastDays(totalDays);
    return l10n.ownerAnalyticsLast30Days;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 900;

    return Wrap(
      spacing: isMobile ? 12.0 : 16.0,
      runSpacing: isMobile ? 12.0 : 16.0,
      alignment: WrapAlignment.center,
      children: [
        _MetricCard(
          title: l10n.ownerAnalyticsTotalRevenue,
          value: '\$${analytics.totalRevenue.toStringAsFixed(2)}',
          subtitle: '${_getRecentPeriodLabel(l10n)}: \$${analytics.monthlyRevenue.toStringAsFixed(2)}',
          icon: Icons.euro_rounded,
          gradientColor: _getPurpleShade(3), // Original purple
          isMobile: isMobile,
          isTablet: isTablet,
        ),
        _MetricCard(
          title: l10n.ownerAnalyticsTotalBookings,
          value: '${analytics.totalBookings}',
          subtitle: '${_getRecentPeriodLabel(l10n)}: ${analytics.monthlyBookings}',
          icon: Icons.calendar_today_rounded,
          gradientColor: _getPurpleShade(4), // Light purple
          isMobile: isMobile,
          isTablet: isTablet,
        ),
        _MetricCard(
          title: l10n.ownerAnalyticsOccupancyRate,
          value: '${analytics.occupancyRate.toStringAsFixed(1)}%',
          subtitle: l10n.ownerAnalyticsPropertiesActive(analytics.activeProperties, analytics.totalProperties),
          icon: Icons.analytics_rounded,
          gradientColor: _getPurpleShade(5), // Lighter purple
          isMobile: isMobile,
          isTablet: isTablet,
        ),
        _MetricCard(
          title: l10n.ownerAnalyticsAvgNightlyRate,
          value: '\$${analytics.averageNightlyRate.toStringAsFixed(2)}',
          subtitle: l10n.ownerAnalyticsCancellation(analytics.cancellationRate.toStringAsFixed(1)),
          icon: Icons.trending_up_rounded,
          gradientColor: _getPurpleShade(2), // Dark purple
          isMobile: isMobile,
          isTablet: isTablet,
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color gradientColor;
  final bool isMobile;
  final bool isTablet;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.gradientColor,
    required this.isMobile,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final spacing = isMobile ? 12.0 : 16.0;

    // Calculate responsive width (same as Dashboard)
    double cardWidth;
    if (isMobile) {
      // Mobile: 2 cards per row
      cardWidth = (screenWidth - (spacing * 3 + 32)) / 2; // 32 = left/right padding
    } else if (isTablet) {
      // Tablet: 3 cards per row
      cardWidth = (screenWidth - (spacing * 4 + 48)) / 3;
    } else {
      // Desktop: fixed width
      cardWidth = 280.0;
    }

    // Neutralna pozadina umjesto šarenih gradijenata
    final cardBgColor = isDark ? const Color(0xFF1E1E28) : Colors.white;
    final borderColor = isDark ? AppColors.sectionDividerDark : AppColors.sectionDividerLight;

    // Accent boja samo za ikonu
    final accentColor = gradientColor;

    // Tekst boje - prilagođene temi
    final valueColor = theme.colorScheme.onSurface;
    final titleColor = theme.colorScheme.onSurface.withValues(alpha: 0.8);
    final subtitleColor = theme.colorScheme.onSurface.withValues(alpha: 0.6);

    return Container(
      width: cardWidth,
      height: isMobile ? 160 : 180,
      constraints: const BoxConstraints(maxWidth: 320),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: isDark ? AppShadows.elevation2Dark : AppShadows.elevation2,
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 14 : 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon container - jedini element s bojom
            Container(
              padding: EdgeInsets.all(isMobile ? 10 : 12),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accentColor, size: isMobile ? 22 : 26),
            ),
            SizedBox(height: isMobile ? 8 : 12),

            // Value - velika vrijednost
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
                maxLines: 1,
              ),
            ),
            SizedBox(height: isMobile ? 6 : 8),

            // Title
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: titleColor,
                fontWeight: FontWeight.w500,
                height: 1.3,
                fontSize: isMobile ? 12 : 13,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            // Subtitle - max 2 lines
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: subtitleColor,
                height: 1.2,
                fontSize: isMobile ? 10 : 11,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _RevenueChart extends StatelessWidget {
  final List<RevenueDataPoint> data;

  const _RevenueChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (data.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.insert_chart_outlined_rounded,
                size: 40,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.ownerAnalyticsNoData,
                style: AppTypography.bodyMedium.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive chart height - optimized for less scrolling
        final screenWidth = constraints.maxWidth;
        final chartHeight = screenWidth > 900
            ? 300.0 // Desktop
            : screenWidth > 600
            ? 260.0 // Tablet
            : 220.0; // Mobile

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
                  border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.4), width: 1.5),
                ),
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? 12 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section header - compact
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.show_chart, color: theme.colorScheme.primary, size: 16),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.ownerAnalyticsRevenueTitle,
                                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  l10n.ownerAnalyticsRevenueSubtitle,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Chart
                      Expanded(
                        child: Chart(
                          data: data
                              .asMap()
                              .entries
                              .map((e) => {'index': e.key, 'label': e.value.label, 'amount': e.value.amount})
                              .toList(),
                          variables: {
                            'index': Variable(accessor: (Map map) => map['index'] as num),
                            'amount': Variable(accessor: (Map map) => map['amount'] as num, scale: LinearScale(min: 0)),
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

class _BookingsChart extends StatelessWidget {
  final List<BookingDataPoint> data;

  const _BookingsChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (data.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.event_busy_rounded,
                size: 40,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.ownerAnalyticsNoData,
                style: AppTypography.bodyMedium.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive chart height - optimized for less scrolling
        final screenWidth = constraints.maxWidth;
        final chartHeight = screenWidth > 900
            ? 300.0 // Desktop
            : screenWidth > 600
            ? 260.0 // Tablet
            : 220.0; // Mobile

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
                  border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.4), width: 1.5),
                ),
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? 12 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section header - compact
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.event, color: theme.colorScheme.primary, size: 16),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.ownerAnalyticsBookingsTitle,
                                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  l10n.ownerAnalyticsBookingsSubtitle,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Chart
                      Expanded(
                        child: Chart(
                          data: data
                              .asMap()
                              .entries
                              .map((e) => {'index': e.key, 'label': e.value.label, 'count': e.value.count})
                              .toList(),
                          variables: {
                            'index': Variable(accessor: (Map map) => map['index'] as num),
                            'count': Variable(accessor: (Map map) => map['count'] as num, scale: LinearScale(min: 0)),
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
                                  colors: [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.7)],
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

class _TopPropertiesList extends StatelessWidget {
  final List<PropertyPerformance> properties;

  const _TopPropertiesList({required this.properties});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    if (properties.isEmpty) {
      return Container(
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
              border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.4), width: 1.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.home_work_outlined,
                      size: 40,
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.ownerAnalyticsNoData,
                      style: AppTypography.bodyMedium.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
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
            border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.4), width: 1.5),
          ),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section header - compact
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.home_work, color: theme.colorScheme.primary, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.ownerAnalyticsTopProperties,
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            l10n.ownerAnalyticsPropertiesSubtitle,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Properties list
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: properties.length > 3 ? 3 : properties.length, // Limit to Top 3
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final property = properties[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), // Compact padding
                      leading: CircleAvatar(
                        radius: 16, // Smaller circle (default 20)
                        backgroundColor: AppColors.authPrimary,
                        child: Text(
                          '${index + 1}',
                          style: AppTypography.bodySmall.copyWith(
                            // Smaller font
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        property.propertyName,
                        style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${property.bookings} ${l10n.ownerAnalyticsBookings} • ${property.occupancyRate.toStringAsFixed(1)}% ${l10n.ownerAnalyticsOccupancy}',
                        style: AppTypography.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: SizedBox(
                        width: 100, // Compact width (was 120)
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '\$${property.revenue.toStringAsFixed(2)}',
                              style: AppTypography.bodySmall.copyWith(
                                // Smaller font (was bodyMedium)
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary, // Purple revenue
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            // Prikaži rating samo ako postoji (> 0)
                            if (property.rating > 0) ...[
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star, size: 14, color: AppColors.star),
                                  const SizedBox(width: 2),
                                  Text(
                                    property.rating.toStringAsFixed(1),
                                    style: AppTypography.bodySmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget Analytics Card - Shows widget performance metrics
class _WidgetAnalyticsCard extends StatelessWidget {
  final int widgetBookings;
  final int totalBookings;
  final double widgetRevenue;
  final double totalRevenue;

  const _WidgetAnalyticsCard({
    required this.widgetBookings,
    required this.totalBookings,
    required this.widgetRevenue,
    required this.totalRevenue,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final widgetBookingsPercent = totalBookings > 0 ? (widgetBookings / totalBookings * 100).toStringAsFixed(1) : '0.0';
    final widgetRevenuePercent = totalRevenue > 0 ? (widgetRevenue / totalRevenue * 100).toStringAsFixed(1) : '0.0';

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
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
            border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.4), width: 1.5),
          ),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section header - compact
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.widgets, color: theme.colorScheme.primary, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.ownerAnalyticsWidgetPerformance,
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            l10n.ownerAnalyticsWidgetSubtitle,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Widget Bookings Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.ownerAnalyticsWidgetBookings,
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                '$widgetBookings',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 28,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Text(
                                l10n.ownerAnalyticsOfTotal(widgetBookingsPercent),
                                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Progress bar for bookings
                LinearProgressIndicator(
                  value: totalBookings > 0 ? widgetBookings / totalBookings : 0,
                  backgroundColor: theme.brightness == Brightness.dark ? AppColors.borderDark : AppColors.borderLight,
                  valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 20),

                // Widget Revenue Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.ownerAnalyticsWidgetRevenue,
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                '\$${widgetRevenue.toStringAsFixed(2)}',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 28,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Text(
                                l10n.ownerAnalyticsOfTotal(widgetRevenuePercent),
                                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Progress bar for revenue
                LinearProgressIndicator(
                  value: totalRevenue > 0 ? widgetRevenue / totalRevenue : 0,
                  backgroundColor: theme.brightness == Brightness.dark ? AppColors.borderDark : AppColors.borderLight,
                  valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bookings By Source Chart - Shows distribution of bookings by source
class _BookingsBySourceChart extends StatelessWidget {
  final Map<String, int> bookingsBySource;

  const _BookingsBySourceChart({required this.bookingsBySource});

  String _getSourceDisplayName(String source) {
    switch (source.toLowerCase()) {
      case 'widget':
        return 'Widget';
      case 'admin':
        return 'Admin';
      case 'direct':
        return 'Direct';
      case 'api':
        return 'API';
      case 'booking.com':
      case 'booking_com':
        return 'Booking.com';
      case 'airbnb':
        return 'Airbnb';
      case 'ical':
        return 'iCal Sync';
      default:
        return source;
    }
  }

  Color _getSourceColor(String source) {
    switch (source.toLowerCase()) {
      case 'widget':
        return _getPurpleShade(3); // Original purple
      case 'admin':
        return _getPurpleShade(2); // Dark purple
      case 'direct':
        return _getPurpleShade(4); // Light purple
      case 'booking.com':
      case 'booking_com':
        return _getPurpleShade(1); // Darkest purple
      case 'airbnb':
        return _getPurpleShade(5); // Lighter purple
      default:
        return _getPurpleShade(6); // Lightest purple (desaturated)
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    if (bookingsBySource.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.source_outlined, size: 48, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              Text(
                l10n.ownerAnalyticsNoSourceData,
                style: AppTypography.bodyMedium.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    final sortedEntries = bookingsBySource.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    final totalCount = bookingsBySource.values.fold<int>(0, (sum, count) => sum + count);

    // Limit to top 5 sources to prevent overcrowding
    final displayEntries = sortedEntries.take(5).toList();

    // Calculate "Other" count if there are more than 5 sources
    final hasOther = sortedEntries.length > 5;
    final otherCount = hasOther ? sortedEntries.skip(5).fold<int>(0, (sum, entry) => sum + entry.value) : 0;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.getElevation(1, isDark: theme.brightness == Brightness.dark),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: context.gradients.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.4), width: 1.5),
          ),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section header - compact
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.source, color: theme.colorScheme.primary, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.ownerAnalyticsBookingsBySource,
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            l10n.ownerAnalyticsSourceSubtitle,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...displayEntries.map((sourceEntry) {
                  final source = sourceEntry.key;
                  final count = sourceEntry.value;
                  final percentage = totalCount > 0 ? (count / totalCount * 100).toStringAsFixed(1) : '0.0';
                  final color = _getSourceColor(source);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12), // Compact spacing (was 16)
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      _getSourceDisplayName(source),
                                      style: AppTypography.bodyMedium,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '$count ($percentage%)',
                              style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: totalCount > 0 ? count / totalCount : 0,
                          backgroundColor: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  );
                }),

                // Add "Other" category if there are more than 5 sources
                if (hasOther) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      l10n.ownerAnalyticsOther(sortedEntries.length - 5),
                                      style: AppTypography.bodyMedium,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '$otherCount (${totalCount > 0 ? (otherCount / totalCount * 100).toStringAsFixed(1) : "0.0"}%)',
                              style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: totalCount > 0 ? otherCount / totalCount : 0,
                          backgroundColor: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                          valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.onSurfaceVariant),
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
