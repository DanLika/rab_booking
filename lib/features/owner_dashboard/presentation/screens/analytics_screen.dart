import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../domain/models/analytics_summary.dart';
import '../providers/analytics_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_color_extensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/error_state_widget.dart';
import '../../../../shared/widgets/common_app_bar.dart';
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
    return Container(
      padding: const EdgeInsets.all(16),
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
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
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
      selectedColor: theme.colorScheme.primaryContainer,
      backgroundColor: theme.colorScheme.surface,
      labelStyle: TextStyle(
        color: selected
            ? theme.colorScheme.onPrimaryContainer
            : theme.colorScheme.onSurface,
      ),
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

    return ListView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      children: [
        // Metric Cards
        _MetricCardsGrid(
          analytics: analytics,
          dateRange: dateRange,
        ),
        SizedBox(height: isMobile ? 24 : 32),

        // Revenue Chart
        const _SectionTitle(title: 'Revenue Over Time'),
        const SizedBox(height: 16),
        _RevenueChart(data: analytics.revenueHistory),
        SizedBox(height: isMobile ? 24 : 32),

        // Bookings Chart
        const _SectionTitle(title: 'Bookings Over Time'),
        const SizedBox(height: 16),
        _BookingsChart(data: analytics.bookingHistory),
        SizedBox(height: isMobile ? 24 : 32),

        // Top Performing Properties
        const _SectionTitle(title: 'Top Performing Properties'),
        const SizedBox(height: 16),
        _TopPropertiesList(properties: analytics.topPerformingProperties),
        SizedBox(height: isMobile ? 24 : 32),

        // Widget Analytics
        const _SectionTitle(title: 'Widget Performance'),
        const SizedBox(height: 16),
        _WidgetAnalyticsCard(
          widgetBookings: analytics.widgetBookings,
          totalBookings: analytics.totalBookings,
          widgetRevenue: analytics.widgetRevenue,
          totalRevenue: analytics.totalRevenue,
        ),
        const SizedBox(height: 16),
        _BookingsBySourceChart(bookingsBySource: analytics.bookingsBySource),
        SizedBox(height: isMobile ? 16 : 24),
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
      style: AppTypography.h2.copyWith(color: theme.colorScheme.onSurface),
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900
            ? 4
            : constraints.maxWidth > 600
            ? 2
            : 1;

        // Responsive aspect ratio based on screen width
        final aspectRatio = constraints.maxWidth > 900
            ? 1.4 // Desktop - taller cards to fit content
            : constraints.maxWidth > 600
            ? 1.2 // Tablet - taller cards
            : 1.0; // Mobile - taller cards to prevent overflow

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: aspectRatio,
          children: [
            _MetricCard(
              title: 'Total Revenue',
              value: '\$${analytics.totalRevenue.toStringAsFixed(2)}',
              subtitle:
                  '${_getRecentPeriodLabel()}: \$${analytics.monthlyRevenue.toStringAsFixed(2)}',
              icon: Icons.euro_rounded,
              gradientColors: const [AppColors.info, AppColors.infoDark],
            ),
            _MetricCard(
              title: 'Total Bookings',
              value: '${analytics.totalBookings}',
              subtitle: '${_getRecentPeriodLabel()}: ${analytics.monthlyBookings}',
              icon: Icons.calendar_today_rounded,
              gradientColors: const [AppColors.primary, AppColors.primaryDark],
            ),
            _MetricCard(
              title: 'Occupancy Rate',
              value: '${analytics.occupancyRate.toStringAsFixed(1)}%',
              subtitle:
                  '${analytics.activeProperties}/${analytics.totalProperties} properties active',
              icon: Icons.analytics_rounded,
              gradientColors: const [AppColors.primaryLight, AppColors.primary],
            ),
            _MetricCard(
              title: 'Avg. Nightly Rate',
              value: '\$${analytics.averageNightlyRate.toStringAsFixed(2)}',
              subtitle:
                  'Cancellation: ${analytics.cancellationRate.toStringAsFixed(1)}%',
              icon: Icons.trending_up_rounded,
              gradientColors: const [AppColors.textSecondary, AppColors.textDisabled],
            ),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    // Extract primary color from gradient for shadow
    final primaryColor = gradientColors.isNotEmpty
        ? gradientColors.first
        : theme.colorScheme.primary;

    // Create theme-aware gradient
    final gradient = _createThemeGradient(context, gradientColors);

    // Theme-aware text and icon colors - white on gradient
    const textColor = Colors.white;
    const iconColor = Colors.white;
    final iconBgColor = Colors.white.withAlpha((0.2 * 255).toInt());

    return Container(
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
          padding: EdgeInsets.all(isMobile ? 12 : 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon container
              Container(
                padding: EdgeInsets.all(isMobile ? 8 : 10),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: isMobile ? 20 : 22),
              ),
              SizedBox(height: isMobile ? 6 : 8),

              // Value
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    height: 1.0,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                ),
              ),
              SizedBox(height: isMobile ? 3 : 4),

              // Title
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: isMobile ? 3 : 4),

              // Subtitle
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: textColor.withAlpha((0.9 * 255).toInt()),
                  height: 1.2,
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
    if (data.isEmpty) {
      return SizedBox(
        height: 200,
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
        final chartHeight = constraints.maxWidth > 900
            ? 300.0  // Desktop
            : constraints.maxWidth > 600
                ? 250.0  // Tablet
                : 200.0; // Mobile

        return SizedBox(
          height: chartHeight,
          child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: LineChart(
            LineChartData(
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 60,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '\$${value.toStringAsFixed(0)}',
                        style: AppTypography.bodySmall,
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < data.length) {
                        return Text(
                          data[index].label,
                          style: AppTypography.bodySmall,
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                rightTitles: const AxisTitles(),
                topTitles: const AxisTitles(),
              ),
              borderData: FlBorderData(show: true),
              lineBarsData: [
                LineChartBarData(
                  spots: data.asMap().entries.map((entry) {
                    return FlSpot(entry.key.toDouble(), entry.value.amount);
                  }).toList(),
                  isCurved: true,
                  color: AppColors.success,
                  barWidth: 3,
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppColors.success.withValues(alpha: 0.2),
                  ),
                ),
              ],
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
    if (data.isEmpty) {
      return SizedBox(
        height: 200,
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
        final chartHeight = constraints.maxWidth > 900
            ? 300.0  // Desktop
            : constraints.maxWidth > 600
                ? 250.0  // Tablet
                : 200.0; // Mobile

        return SizedBox(
          height: chartHeight,
          child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: BarChart(
            BarChartData(
              gridData: const FlGridData(),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: AppTypography.bodySmall,
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < data.length) {
                        return Text(
                          data[index].label,
                          style: AppTypography.bodySmall,
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                rightTitles: const AxisTitles(),
                topTitles: const AxisTitles(),
              ),
              borderData: FlBorderData(show: true),
              barGroups: data.asMap().entries.map((entry) {
                return BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: entry.value.count.toDouble(),
                      color: AppColors.info,
                      width: 20,
                    ),
                  ],
                );
              }).toList(),
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
    if (properties.isEmpty) {
      return Card(
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
      );
    }

    return Card(
      elevation: 2,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: properties.length,
        separatorBuilder: (_, _) => const Divider(),
        itemBuilder: (context, index) {
          final property = properties[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.authPrimary,
              child: Text(
                '${index + 1}',
                style: AppTypography.bodyMedium.copyWith(
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
              width: 120,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '\$${property.revenue.toStringAsFixed(2)}',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
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
    final widgetBookingsPercent = totalBookings > 0
        ? (widgetBookings / totalBookings * 100).toStringAsFixed(1)
        : '0.0';
    final widgetRevenuePercent = totalRevenue > 0
        ? (widgetRevenue / totalRevenue * 100).toStringAsFixed(1)
        : '0.0';

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Widget Bookings Row
            Row(
              children: [
                const Icon(Icons.widgets, color: AppColors.info, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Widget Bookings',
                        style: AppTypography.bodyMedium.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            '$widgetBookings',
                            style: AppTypography.h2.copyWith(
                              color: AppColors.info,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '($widgetBookingsPercent% of total)',
                            style: AppTypography.bodySmall.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
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
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.borderDark
                  : AppColors.borderLight,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.info),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 24),

            // Widget Revenue Row
            Row(
              children: [
                const Icon(Icons.attach_money, color: AppColors.success, size: 24),
                const SizedBox(width: 12),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Widget Revenue',
                        style: AppTypography.bodyMedium.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              '\$${widgetRevenue.toStringAsFixed(2)}',
                              style: AppTypography.h2.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              '($widgetRevenuePercent% of total)',
                              style: AppTypography.bodySmall.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.borderDark
                  : AppColors.borderLight,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
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

  Color _getSourceColor(String source, int index) {
    switch (source.toLowerCase()) {
      case 'widget':
        return AppColors.info;
      case 'admin':
        return AppColors.secondary;
      case 'direct':
        return AppColors.warning;
      case 'booking.com':
      case 'booking_com':
        return const Color(0xFF003580); // Booking.com blue
      case 'airbnb':
        return const Color(0xFFFF5A5F); // Airbnb red
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bookings by Source',
              style: AppTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            ...sortedEntries.asMap().entries.map((entry) {
              final index = entry.key;
              final sourceEntry = entry.value;
              final source = sourceEntry.key;
              final count = sourceEntry.value;
              final percentage = totalCount > 0
                  ? (count / totalCount * 100).toStringAsFixed(1)
                  : '0.0';
              final color = _getSourceColor(source, index);

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
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
          ],
        ),
      ),
    );
  }
}

/// Helper function to create theme-aware gradients
/// In dark mode, darkens the colors by 30% for better contrast
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
