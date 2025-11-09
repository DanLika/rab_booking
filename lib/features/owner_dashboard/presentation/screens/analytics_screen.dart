import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../domain/models/analytics_summary.dart';
import '../providers/analytics_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/error_state_widget.dart';
import '../../../../shared/widgets/common_app_bar.dart';
import '../widgets/owner_app_drawer.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      body: Column(
        children: [
          _DateRangeSelector(dateRange: dateRange),
          Expanded(
            child: analyticsAsync.when(
              data: (analytics) => _AnalyticsContent(analytics: analytics),
              loading: () => const Center(child: CircularProgressIndicator()),
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
      color: AppColors.surface,
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'Last Week',
                    selected: dateRange.preset == 'week',
                    onSelected: () {
                      ref.read(dateRangeNotifierProvider.notifier).setPreset('week');
                    },
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Last Month',
                    selected: dateRange.preset == 'month',
                    onSelected: () {
                      ref.read(dateRangeNotifierProvider.notifier).setPreset('month');
                    },
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Last Quarter',
                    selected: dateRange.preset == 'quarter',
                    onSelected: () {
                      ref.read(dateRangeNotifierProvider.notifier).setPreset('quarter');
                    },
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Last Year',
                    selected: dateRange.preset == 'year',
                    onSelected: () {
                      ref.read(dateRangeNotifierProvider.notifier).setPreset('year');
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
                        ref.read(dateRangeNotifierProvider.notifier).setCustomRange(
                          picked.start,
                          picked.end,
                        );
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
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: AppColors.authPrimary,
      labelStyle: TextStyle(
        color: selected ? const Color(0xFFFFFFFF) : AppColors.textPrimary,
      ),
    );
  }
}

class _AnalyticsContent extends StatelessWidget {
  final AnalyticsSummary analytics;

  const _AnalyticsContent({required this.analytics});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Metric Cards
          _MetricCardsGrid(analytics: analytics),
          const SizedBox(height: 32),

          // Revenue Chart
          const _SectionTitle(title: 'Revenue Over Time'),
          const SizedBox(height: 16),
          _RevenueChart(data: analytics.revenueHistory),
          const SizedBox(height: 32),

          // Bookings Chart
          const _SectionTitle(title: 'Bookings Over Time'),
          const SizedBox(height: 16),
          _BookingsChart(data: analytics.bookingHistory),
          const SizedBox(height: 32),

          // Top Performing Properties
          const _SectionTitle(title: 'Top Performing Properties'),
          const SizedBox(height: 16),
          _TopPropertiesList(properties: analytics.topPerformingProperties),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTypography.h2.copyWith(color: AppColors.textPrimary),
    );
  }
}

class _MetricCardsGrid extends StatelessWidget {
  final AnalyticsSummary analytics;

  const _MetricCardsGrid({required this.analytics});

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
            ? 1.8  // Desktop - wider cards
            : constraints.maxWidth > 600
                ? 1.6  // Tablet - medium cards
                : 1.3; // Mobile - taller cards for more content

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
              subtitle: 'Monthly: \$${analytics.monthlyRevenue.toStringAsFixed(2)}',
              icon: Icons.attach_money,
              color: AppColors.success,
            ),
            _MetricCard(
              title: 'Total Bookings',
              value: '${analytics.totalBookings}',
              subtitle: 'Monthly: ${analytics.monthlyBookings}',
              icon: Icons.book,
              color: AppColors.info,
            ),
            _MetricCard(
              title: 'Occupancy Rate',
              value: '${analytics.occupancyRate.toStringAsFixed(1)}%',
              subtitle: '${analytics.activeProperties}/${analytics.totalProperties} properties active',
              icon: Icons.home,
              color: AppColors.warning,
            ),
            _MetricCard(
              title: 'Avg. Nightly Rate',
              value: '\$${analytics.averageNightlyRate.toStringAsFixed(2)}',
              subtitle: 'Cancellation: ${analytics.cancellationRate.toStringAsFixed(1)}%',
              icon: Icons.night_shelter,
              color: AppColors.secondary,
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
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Text(
              value,
              style: AppTypography.h2.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
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
    if (data.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No data available')),
      );
    }

    return SizedBox(
      height: 300,
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: true),
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
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: true),
              lineBarsData: [
                LineChartBarData(
                  spots: data.asMap().entries.map((entry) {
                    return FlSpot(
                      entry.key.toDouble(),
                      entry.value.amount,
                    );
                  }).toList(),
                  isCurved: true,
                  color: AppColors.success,
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
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
  }
}

class _BookingsChart extends StatelessWidget {
  final List<BookingDataPoint> data;

  const _BookingsChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No data available')),
      );
    }

    return SizedBox(
      height: 300,
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: BarChart(
            BarChartData(
              gridData: const FlGridData(show: true),
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
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
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
  }
}

class _TopPropertiesList extends StatelessWidget {
  final List<PropertyPerformance> properties;

  const _TopPropertiesList({required this.properties});

  @override
  Widget build(BuildContext context) {
    if (properties.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No data available'),
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
                  color: const Color(0xFFFFFFFF),
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
              style: AppTypography.bodySmall,
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${property.revenue.toStringAsFixed(2)}',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, size: 14, color: AppColors.star),
                    const SizedBox(width: 2),
                    Text(
                      property.rating.toStringAsFixed(1),
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
