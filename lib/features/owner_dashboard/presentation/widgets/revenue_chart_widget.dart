import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../shared/widgets/widgets.dart';

/// Revenue data point
class RevenueDataPoint {
  final String label;
  final double value;
  final DateTime date;

  const RevenueDataPoint({
    required this.label,
    required this.value,
    required this.date,
  });
}

/// Revenue chart widget
class RevenueChartWidget extends StatelessWidget {
  final List<RevenueDataPoint> data;
  final String title;
  final String? subtitle;

  const RevenueChartWidget({
    super.key,
    required this.data,
    this.title = 'Revenue Overview',
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PremiumCard.elevated(
      padding: const EdgeInsets.all(AppDimensions.spaceL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.h3,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: AppDimensions.spaceXXS),
                      Text(
                        subtitle!,
                        style: AppTypography.small.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : context.textColorSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Legend
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spaceXS),
                  Text(
                    'Revenue',
                    style: AppTypography.small.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : context.textColorSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.spaceXL),

          // Chart - Responsive height
          if (data.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppDimensions.spaceXL),
                child: Column(
                  children: [
                    Icon(
                      Icons.bar_chart,
                      size: 64,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : context.textColorSecondary,
                    ),
                    const SizedBox(height: AppDimensions.spaceM),
                    Text(
                      'No revenue data available',
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : context.textColorSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                // Responsive chart height based on available width
                final chartHeight = constraints.maxWidth > 600
                    ? 250.0
                    : constraints.maxWidth > 400
                        ? 200.0
                        : 150.0;

                return SizedBox(
                  height: chartHeight,
                  child: _BarChart(data: data),
                );
              },
            ),
        ],
      ),
    );
  }
}

/// Simple bar chart
class _BarChart extends StatelessWidget {
  final List<RevenueDataPoint> data;

  const _BarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maxValue = data.map((d) => d.value).reduce(math.max);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate responsive Y-axis width based on max value
        final maxValueDigits = maxValue.toStringAsFixed(0).length;
        final yAxisWidth = math.min(60.0, math.max(40.0, maxValueDigits * 8.0));

        // Calculate available height for bars
        final barChartHeight = constraints.maxHeight - 40; // Reserve space for X-axis labels

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Y-axis labels - Responsive width
            SizedBox(
              width: yAxisWidth,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(5, (index) {
                  final value = maxValue * (4 - index) / 4;
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(
                      '€${value.toStringAsFixed(0)}',
                      style: AppTypography.small.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : context.textColorSecondary,
                        fontSize: 10,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(width: AppDimensions.spaceS),

            // Bars
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: data.asMap().entries.map((entry) {
                        final index = entry.key;
                        final point = entry.value;
                        final heightRatio = maxValue > 0 ? point.value / maxValue : 0;

                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: index == 0 ? 0 : AppDimensions.spaceXXS,
                              right: index == data.length - 1
                                  ? 0
                                  : AppDimensions.spaceXXS,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                // Dynamic height based on available space
                                Container(
                                  height: heightRatio * barChartHeight,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(AppDimensions.radiusS),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: AppDimensions.spaceS),

                  // X-axis labels
                  Row(
                    children: data.asMap().entries.map((entry) {
                      final index = entry.key;
                      final point = entry.value;

                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: index == 0 ? 0 : AppDimensions.spaceXXS,
                            right: index == data.length - 1
                                ? 0
                                : AppDimensions.spaceXXS,
                          ),
                          child: Text(
                            point.label,
                            style: AppTypography.small.copyWith(
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : context.textColorSecondary,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
