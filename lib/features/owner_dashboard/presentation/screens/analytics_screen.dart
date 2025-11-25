import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphic/graphic.dart';
import '../../domain/models/analytics_summary.dart';
import '../providers/analytics_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../shared/widgets/error_state_widget.dart';
import '../../../../shared/widgets/common_app_bar.dart';
import '../../../../shared/widgets/custom_date_range_picker.dart';
import '../widgets/owner_app_drawer.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dateRange = ref.watch(dateRangeNotifierProvider);
    final analyticsAsync = ref.watch(
      analyticsNotifierProvider(dateRange: dateRange),
    );

    return Scaffold(
      drawer: const OwnerAppDrawer(currentRoute: 'analytics'),
      appBar: CommonAppBar(
        title: 'Analytics & Reports',
        leadingIcon: Icons.menu,
        onLeadingIconTap: (context) => Scaffold.of(context).openDrawer(),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF1A1A1A), // veryDarkGray
                    const Color(0xFF1F1F1F),
                    const Color(0xFF242424),
                    const Color(0xFF292929),
                    const Color(0xFF2D2D2D), // mediumDarkGray
                  ]
                : [
                    const Color(0xFFF0F0F0), // Lighter grey
                    const Color(0xFFF2F2F2),
                    const Color(0xFFF5F5F5),
                    const Color(0xFFF8F8F8),
                    const Color(0xFFFAFAFA), // Very light grey
                  ],
            stops: const [0.0, 0.125, 0.25, 0.375, 0.5],
          ),
        ),
        child: Column(
          children: [
            _DateRangeSelector(dateRange: dateRange),
            Expanded(
              child: analyticsAsync.when(
                data: (analytics) => _AnalyticsContent(
                  analytics: analytics,
                  dateRange: dateRange,
                ),
                loading: () => Center(
                  child: CircularProgressIndicator(
                    color: theme.colorScheme.primary,
                  ),
                ),
                error: (error, stack) => ErrorStateWidget(
                  message: 'Failed to load analytics',
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
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _FilterChip(
                    label: 'Last Week',
                    selected: dateRange.preset == 'week',
                    onSelected: () {
                      ref
                          .read(dateRangeNotifierProvider.notifier)
                          .setPreset('week');
                    },
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Last Month',
                    selected: dateRange.preset == 'month',
                    onSelected: () {
                      ref
                          .read(dateRangeNotifierProvider.notifier)
                          .setPreset('month');
                    },
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Last Quarter',
                    selected: dateRange.preset == 'quarter',
                    onSelected: () {
                      ref
                          .read(dateRangeNotifierProvider.notifier)
                          .setPreset('quarter');
                    },
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Last Year',
                    selected: dateRange.preset == 'year',
                    onSelected: () {
                      ref
                          .read(dateRangeNotifierProvider.notifier)
                          .setPreset('year');
                    },
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
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
                            .read(dateRangeNotifierProvider.notifier)
                            .setCustomRange(picked.start, picked.end);
                      }
                    },
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: const Text('Custom Range'),
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: theme.colorScheme.primary,
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      side: BorderSide(
        color: selected
            ? theme.colorScheme.primary
            : theme.colorScheme.outline.withAlpha((0.3 * 255).toInt()),
        width: selected ? 2 : 1,
      ),
      labelStyle: TextStyle(
        color: selected
            ? Colors.white  // White text on selected chip
            : theme.colorScheme.onSurface,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
      checkmarkColor: Colors.white,
    );
  }
}

class _AnalyticsContent extends StatelessWidget {
  final AnalyticsSummary analytics;
  final DateRangeFilter dateRange;

  const _AnalyticsContent({
    required this.analytics,
    required this.dateRange,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isDesktop = screenWidth > 900;

    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: context.horizontalPadding,
        vertical: isMobile ? 12 : 16,
      ),
      children: [
        // Metric Cards
        _MetricCardsGrid(
          analytics: analytics,
          dateRange: dateRange,
        ),
        SizedBox(height: isMobile ? 16 : 20), // Reduced from 24/32

        // Charts Section - Desktop: side-by-side, Mobile/Tablet: stacked
        if (isDesktop)
          _buildDesktopChartsRow()
        else
          _buildStackedCharts(isMobile),

        SizedBox(height: isMobile ? 16 : 20), // Reduced from 24/32

        // Bottom Section - Desktop: side-by-side, Mobile/Tablet: stacked
        if (isDesktop)
          _buildDesktopBottomRow()
        else
          _buildStackedBottom(isMobile),

        SizedBox(height: isMobile ? 12 : 16), // Reduced from 16/24
      ],
    );
  }

  /// Desktop layout - Charts side-by-side (Revenue + Bookings)
  Widget _buildDesktopChartsRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Revenue Chart (left)
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle(title: 'Revenue Over Time'),
              const SizedBox(height: 12),
              _RevenueChart(data: analytics.revenueHistory),
            ],
          ),
        ),
        const SizedBox(width: 16), // Spacing between charts
        // Bookings Chart (right)
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle(title: 'Bookings Over Time'),
              const SizedBox(height: 12),
              _BookingsChart(data: analytics.bookingHistory),
            ],
          ),
        ),
      ],
    );
  }

  /// Mobile/Tablet layout - Charts stacked vertically
  Widget _buildStackedCharts(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Revenue Chart
        const _SectionTitle(title: 'Revenue Over Time'),
        const SizedBox(height: 12),
        _RevenueChart(data: analytics.revenueHistory),
        SizedBox(height: isMobile ? 16 : 20),

        // Bookings Chart
        const _SectionTitle(title: 'Bookings Over Time'),
        const SizedBox(height: 12),
        _BookingsChart(data: analytics.bookingHistory),
      ],
    );
  }

  /// Desktop layout - Bottom section side-by-side (Top Properties + Widget Analytics)
  Widget _buildDesktopBottomRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Properties + Bookings by Source (left)
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle(title: 'Top Performing Properties'),
              const SizedBox(height: 12),
              _TopPropertiesList(properties: analytics.topPerformingProperties),
              const SizedBox(height: 20),
              _BookingsBySourceChart(bookingsBySource: analytics.bookingsBySource),
            ],
          ),
        ),
        const SizedBox(width: 16), // Spacing between sections
        // Widget Analytics (right)
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle(title: 'Widget Performance'),
              const SizedBox(height: 12),
              _WidgetAnalyticsCard(
                widgetBookings: analytics.widgetBookings,
                totalBookings: analytics.totalBookings,
                widgetRevenue: analytics.widgetRevenue,
                totalRevenue: analytics.totalRevenue,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Mobile/Tablet layout - Bottom section stacked vertically
  Widget _buildStackedBottom(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Properties
        const _SectionTitle(title: 'Top Performing Properties'),
        const SizedBox(height: 12),
        _TopPropertiesList(properties: analytics.topPerformingProperties),
        SizedBox(height: isMobile ? 16 : 20),

        // Widget Analytics
        const _SectionTitle(title: 'Widget Performance'),
        const SizedBox(height: 12),
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

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurface,
      ),
    );
  }
}

class _MetricCardsGrid extends StatelessWidget {
  final AnalyticsSummary analytics;
  final DateRangeFilter dateRange;

  const _MetricCardsGrid({
    required this.analytics,
    required this.dateRange,
  });

  String _getRecentPeriodLabel() {
    final totalDays = dateRange.endDate.difference(dateRange.startDate).inDays;
    if (totalDays <= 7) return 'Last 7 days';
    if (totalDays <= 30) return 'Last $totalDays days';
    return 'Last 30 days';
  }

  // Helper method to create purple shade variations (1-6, darkest to lightest)
  // Uses fixed purple shades for consistent colors in light and dark mode
  Color _getPurpleShade(BuildContext context, int level) {
    // Fixed purple shades - same in both light and dark mode
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 900;

    return Wrap(
      spacing: isMobile ? 12.0 : 16.0,
      runSpacing: isMobile ? 12.0 : 16.0,
      alignment: WrapAlignment.center,
      children: [
        _MetricCard(
          title: 'Total Revenue',
          value: '\$${analytics.totalRevenue.toStringAsFixed(2)}',
          subtitle:
              '${_getRecentPeriodLabel()}: \$${analytics.monthlyRevenue.toStringAsFixed(2)}',
          icon: Icons.euro_rounded,
          gradientColor: _getPurpleShade(context, 3), // Original purple
          isMobile: isMobile,
          isTablet: isTablet,
        ),
        _MetricCard(
          title: 'Total Bookings',
          value: '${analytics.totalBookings}',
          subtitle: '${_getRecentPeriodLabel()}: ${analytics.monthlyBookings}',
          icon: Icons.calendar_today_rounded,
          gradientColor: _getPurpleShade(context, 4), // Light purple
          isMobile: isMobile,
          isTablet: isTablet,
        ),
        _MetricCard(
          title: 'Occupancy Rate',
          value: '${analytics.occupancyRate.toStringAsFixed(1)}%',
          subtitle:
              '${analytics.activeProperties}/${analytics.totalProperties} properties active',
          icon: Icons.analytics_rounded,
          gradientColor: _getPurpleShade(context, 5), // Lighter purple
          isMobile: isMobile,
          isTablet: isTablet,
        ),
        _MetricCard(
          title: 'Avg. Nightly Rate',
          value: '\$${analytics.averageNightlyRate.toStringAsFixed(2)}',
          subtitle:
              'Cancellation: ${analytics.cancellationRate.toStringAsFixed(1)}%',
          icon: Icons.trending_up_rounded,
          gradientColor: _getPurpleShade(context, 2), // Dark purple
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

    // Use the provided color for shadow
    final primaryColor = gradientColor;

    // Create theme-aware gradient with alpha fade
    final gradient = _createThemeGradient(context, gradientColor);

    // Theme-aware text and icon colors - white on gradient
    const textColor = Colors.white;
    const iconColor = Colors.white;
    final iconBgColor = Colors.white.withAlpha((0.2 * 255).toInt());

    return Container(
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
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: textColor,
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
                  color: textColor,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                  fontSize: isMobile ? 12 : 13,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              // Subtitle
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: textColor.withAlpha((0.9 * 255).toInt()),
                  height: 1.2,
                  fontSize: isMobile ? 10 : 11,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (data.isEmpty) {
      return SizedBox(
        height: 300,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.insert_chart_outlined_rounded,
                size: 48,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Nema podataka za odabrani period',
                style: AppTypography.bodyMedium.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive chart height - INCREASED
        final screenWidth = constraints.maxWidth;
        final chartHeight = screenWidth > 900
            ? 400.0  // Desktop (was 300)
            : screenWidth > 600
                ? 350.0  // Tablet (was 250)
                : 300.0; // Mobile (was 200)

        return SizedBox(
          height: chartHeight,
          child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppShadows.getElevation(1, isDark: isDark),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: isDark
                      ? const [
                          Color(0xFF1A1A1A), // veryDarkGray
                          Color(0xFF1F1F1F),
                          Color(0xFF242424),
                          Color(0xFF292929),
                          Color(0xFF2D2D2D), // mediumDarkGray
                        ]
                      : const [
                          Color(0xFFF0F0F0), // Lighter grey
                          Color(0xFFF2F2F2),
                          Color(0xFFF5F5F5),
                          Color(0xFFF8F8F8),
                          Color(0xFFFAFAFA), // Very light grey
                        ],
                  stops: const [0.0, 0.125, 0.25, 0.375, 0.5],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 16 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section header with minimalist icon
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withAlpha((0.12 * 255).toInt()),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.show_chart,
                            color: theme.colorScheme.primary,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Prihod Kroz Vrijeme',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Mjesečni trend prihoda',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Chart
                    Expanded(
                      child: Chart(
                data: data.asMap().entries.map((e) => {
                  'index': e.key,
                  'label': e.value.label,
                  'amount': e.value.amount,
                }).toList(),
                variables: {
                  'index': Variable(
                    accessor: (Map map) => map['index'] as num,
                  ),
                  'amount': Variable(
                    accessor: (Map map) => map['amount'] as num,
                    scale: LinearScale(min: 0),
                  ),
                },
                coord: RectCoord(
                  horizontalRangeUpdater: Defaults.horizontalRangeEvent,
                ),
                marks: [
                  AreaMark(
                    shape: ShapeEncode(
                      value: BasicAreaShape(smooth: true),
                    ),
                    color: ColorEncode(
                      value: theme.colorScheme.primary.withValues(alpha: 0.15),
                    ),
                    entrance: {MarkEntrance.y},
                  ),
                  LineMark(
                    shape: ShapeEncode(
                      value: BasicLineShape(smooth: true),
                    ),
                    size: SizeEncode(value: 3),
                    color: ColorEncode(
                      value: theme.colorScheme.primary,
                    ),
                    entrance: {MarkEntrance.y},
                  ),
                  PointMark(
                    shape: ShapeEncode(value: CircleShape()),
                    size: SizeEncode(value: 8),
                    color: ColorEncode(
                      value: theme.colorScheme.primary,
                    ),
                    entrance: {MarkEntrance.opacity},
                  ),
                ],
                axes: [
                  Defaults.horizontalAxis,
                  Defaults.verticalAxis,
                ],
                selections: {
                  'touchMove': PointSelection(
                    on: {GestureType.hover},
                    devices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
                  )
                },
                tooltip: TooltipGuide(
                  backgroundColor: theme.colorScheme.surface,
                  elevation: 8,
                  textStyle: AppTypography.bodySmall.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                        ),
                        crosshair: CrosshairGuide(
                          followPointer: [false, true],
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

class _BookingsChart extends StatelessWidget {
  final List<BookingDataPoint> data;

  const _BookingsChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (data.isEmpty) {
      return SizedBox(
        height: 300,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.event_busy_rounded,
                size: 48,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Nema podataka za odabrani period',
                style: AppTypography.bodyMedium.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive chart height - INCREASED
        final screenWidth = constraints.maxWidth;
        final chartHeight = screenWidth > 900
            ? 400.0  // Desktop (was 300)
            : screenWidth > 600
                ? 350.0  // Tablet (was 250)
                : 300.0; // Mobile (was 200)

        return SizedBox(
          height: chartHeight,
          child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppShadows.getElevation(1, isDark: isDark),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: isDark
                      ? const [
                          Color(0xFF1A1A1A), // veryDarkGray
                          Color(0xFF1F1F1F),
                          Color(0xFF242424),
                          Color(0xFF292929),
                          Color(0xFF2D2D2D), // mediumDarkGray
                        ]
                      : const [
                          Color(0xFFF0F0F0), // Lighter grey
                          Color(0xFFF2F2F2),
                          Color(0xFFF5F5F5),
                          Color(0xFFF8F8F8),
                          Color(0xFFFAFAFA), // Very light grey
                        ],
                  stops: const [0.0, 0.125, 0.25, 0.375, 0.5],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 16 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section header with minimalist icon
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withAlpha((0.12 * 255).toInt()),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.event,
                            color: theme.colorScheme.primary,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Rezervacije Kroz Vrijeme',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Mjesečna aktivnost bookinga',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Chart
                    Expanded(
                      child: Chart(
                data: data.asMap().entries.map((e) => {
                  'index': e.key,
                  'label': e.value.label,
                  'count': e.value.count,
                }).toList(),
                variables: {
                  'index': Variable(
                    accessor: (Map map) => map['index'] as num,
                  ),
                  'count': Variable(
                    accessor: (Map map) => map['count'] as num,
                    scale: LinearScale(min: 0),
                  ),
                },
                coord: RectCoord(
                  horizontalRangeUpdater: Defaults.horizontalRangeEvent,
                ),
                marks: [
                  IntervalMark(
                    shape: ShapeEncode(
                      value: RectShape(borderRadius: BorderRadius.circular(8)),
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
                  ),
                ],
                axes: [
                  Defaults.horizontalAxis,
                  Defaults.verticalAxis,
                ],
                selections: {
                  'touchMove': PointSelection(
                    on: {GestureType.hover},
                    devices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
                  )
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    if (properties.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppShadows.getElevation(1, isDark: isDark),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: isDark
                    ? const [
                        Color(0xFF1A1A1A), // veryDarkGray
                        Color(0xFF1F1F1F),
                        Color(0xFF242424),
                        Color(0xFF292929),
                        Color(0xFF2D2D2D), // mediumDarkGray
                      ]
                    : const [
                        Color(0xFFF0F0F0), // Lighter grey
                        Color(0xFFF2F2F2),
                        Color(0xFFF5F5F5),
                        Color(0xFFF8F8F8),
                        Color(0xFFFAFAFA), // Very light grey
                      ],
                stops: const [0.0, 0.125, 0.25, 0.375, 0.5],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.home_work_outlined,
                      size: 48,
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Nema podataka za odabrani period',
                      style: AppTypography.bodyMedium.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
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

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.getElevation(1, isDark: isDark),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: isDark
                  ? const [
                      Color(0xFF1A1A1A), // veryDarkGray
                      Color(0xFF1F1F1F),
                      Color(0xFF242424),
                      Color(0xFF292929),
                      Color(0xFF2D2D2D), // mediumDarkGray
                    ]
                  : const [
                      Color(0xFFF0F0F0), // Lighter grey
                      Color(0xFFF2F2F2),
                      Color(0xFFF5F5F5),
                      Color(0xFFF8F8F8),
                      Color(0xFFFAFAFA), // Very light grey
                    ],
              stops: const [0.0, 0.125, 0.25, 0.375, 0.5],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section header with minimalist icon
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withAlpha((0.12 * 255).toInt()),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.home_work,
                        color: theme.colorScheme.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Top Performing Properties',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Properties ranked by revenue performance',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 20),

                // Properties list
                ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: properties.length > 3 ? 3 : properties.length, // Limit to Top 3
        separatorBuilder: (_, _) => const Divider(),
        itemBuilder: (context, index) {
          final property = properties[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), // Compact padding
            leading: CircleAvatar(
              radius: 16, // Smaller circle (default 20)
              backgroundColor: AppColors.authPrimary,
              child: Text(
                '${index + 1}',
                style: AppTypography.bodySmall.copyWith( // Smaller font
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              property.propertyName,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              '${property.bookings} bookings • ${property.occupancyRate.toStringAsFixed(1)}% occupancy',
              style: AppTypography.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
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
                    style: AppTypography.bodySmall.copyWith( // Smaller font (was bodyMedium)
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary, // Purple revenue
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final widgetBookingsPercent = totalBookings > 0
        ? (widgetBookings / totalBookings * 100).toStringAsFixed(1)
        : '0.0';
    final widgetRevenuePercent = totalRevenue > 0
        ? (widgetRevenue / totalRevenue * 100).toStringAsFixed(1)
        : '0.0';

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.getElevation(1, isDark: isDark),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: isDark
                  ? const [
                      Color(0xFF1A1A1A), // veryDarkGray
                      Color(0xFF1F1F1F),
                      Color(0xFF242424),
                      Color(0xFF292929),
                      Color(0xFF2D2D2D), // mediumDarkGray
                    ]
                  : const [
                      Color(0xFFF0F0F0), // Lighter grey
                      Color(0xFFF2F2F2),
                      Color(0xFFF5F5F5),
                      Color(0xFFF8F8F8),
                      Color(0xFFFAFAFA), // Very light grey
                    ],
              stops: const [0.0, 0.125, 0.25, 0.375, 0.5],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section header with minimalist icon
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withAlpha((0.12 * 255).toInt()),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.widgets,
                        color: theme.colorScheme.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Widget Performance',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Track bookings and revenue from embedded widget',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 20),

                // Widget Bookings Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Widget Bookings',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                '$widgetBookings',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '($widgetBookingsPercent% of total)',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
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
                  backgroundColor: theme.brightness == Brightness.dark
                      ? AppColors.borderDark
                      : AppColors.borderLight,
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
                            'Widget Revenue',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                '\$${widgetRevenue.toStringAsFixed(2)}',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '($widgetRevenuePercent% of total)',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
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
                  backgroundColor: theme.brightness == Brightness.dark
                      ? AppColors.borderDark
                      : AppColors.borderLight,
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

  // Helper method to create purple shade variations (1-6, darkest to lightest)
  // Uses fixed purple shades for consistent colors in light and dark mode
  Color _getPurpleShade(BuildContext context, int level) {
    // Fixed purple shades - same in both light and dark mode
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

  Color _getSourceColor(BuildContext context, String source, int index) {
    switch (source.toLowerCase()) {
      case 'widget':
        return _getPurpleShade(context, 3); // Original purple
      case 'admin':
        return _getPurpleShade(context, 2); // Dark purple
      case 'direct':
        return _getPurpleShade(context, 4); // Light purple
      case 'booking.com':
      case 'booking_com':
        return _getPurpleShade(context, 1); // Darkest purple
      case 'airbnb':
        return _getPurpleShade(context, 5); // Lighter purple
      default:
        return _getPurpleShade(context, 6); // Lightest purple (desaturated)
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    if (bookingsBySource.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.source_outlined,
                size: 48,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Nema podataka o izvorima',
                style: AppTypography.bodyMedium.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final sortedEntries = bookingsBySource.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final totalCount = bookingsBySource.values.fold<int>(0, (sum, count) => sum + count);

    // Limit to top 5 sources to prevent overcrowding
    final displayEntries = sortedEntries.take(5).toList();

    // Calculate "Other" count if there are more than 5 sources
    final hasOther = sortedEntries.length > 5;
    final otherCount = hasOther
        ? sortedEntries.skip(5).fold<int>(0, (sum, entry) => sum + entry.value)
        : 0;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.getElevation(1, isDark: isDark),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: isDark
                  ? const [
                      Color(0xFF1A1A1A), // veryDarkGray
                      Color(0xFF1F1F1F),
                      Color(0xFF242424),
                      Color(0xFF292929),
                      Color(0xFF2D2D2D), // mediumDarkGray
                    ]
                  : const [
                      Color(0xFFF0F0F0), // Lighter grey
                      Color(0xFFF2F2F2),
                      Color(0xFFF5F5F5),
                      Color(0xFFF8F8F8),
                      Color(0xFFFAFAFA), // Very light grey
                    ],
              stops: const [0.0, 0.125, 0.25, 0.375, 0.5],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section header with minimalist icon
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withAlpha((0.12 * 255).toInt()),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.source,
                        color: theme.colorScheme.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Bookings by Source',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Distribution of bookings across different sources',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 20),
            ...displayEntries.asMap().entries.map((entry) {
              final index = entry.key;
              final sourceEntry = entry.value;
              final source = sourceEntry.key;
              final count = sourceEntry.value;
              final percentage = totalCount > 0
                  ? (count / totalCount * 100).toStringAsFixed(1)
                  : '0.0';
              final color = _getSourceColor(context, source, index);

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
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
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
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
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
                                  'Other (${sortedEntries.length - 5} sources)',
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
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: totalCount > 0 ? otherCount / totalCount : 0,
                      backgroundColor: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
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

/// Helper function to create theme-aware gradient with alpha fade
/// Uses single color with alpha fade for consistent purple-fade pattern
Gradient _createThemeGradient(BuildContext context, Color baseColor) {
  return LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      baseColor,
      baseColor.withValues(alpha: 0.7), // 70% opacity fade
    ],
  );
}
