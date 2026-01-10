import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:graphic/graphic.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/gradient_extensions.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/animations/animated_empty_state.dart';
import '../../domain/models/unified_dashboard_data.dart';

class DashboardChartsSection extends StatelessWidget {
  final UnifiedDashboardData data;

  const DashboardChartsSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;
    final isMobile = screenWidth < 600;

    if (data.bookings == 0) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isDesktop ? 32 : (isMobile ? 16 : 24),
        isMobile ? 12 : 16,
        isDesktop ? 32 : (isMobile ? 16 : 24),
        isMobile ? 12 : 16,
      ),
      child: isDesktop
          ? _buildDesktopChartsRow(data, l10n)
          : _buildStackedCharts(data, isMobile, l10n),
    );
  }

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
        final chartHeight = screenWidth > 900
            ? 300.0
            : screenWidth > 600
                ? 260.0
                : 220.0;

        return SizedBox(
          height: chartHeight,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppShadows.getElevation(
                1,
                isDark: theme.brightness == Brightness.dark,
              ),
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
                          coord: RectCoord(),
                          marks: [
                            AreaMark(
                              shape: ShapeEncode(
                                value: BasicAreaShape(smooth: true),
                              ),
                              color: ColorEncode(
                                value: theme.colorScheme.primary.withValues(
                                  alpha: 0.15,
                                ),
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
                              label: LabelEncode(
                                encoder: (tuple) {
                                  final amount = tuple['amount'] as num;
                                  return Label(
                                    '€${amount.toStringAsFixed(0)}',
                                    LabelStyle(
                                      textStyle: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: theme.colorScheme.onSurface
                                            .withValues(alpha: 0.7),
                                      ),
                                      offset: const Offset(0, -12),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                          axes: [
                            Defaults.horizontalAxis,
                            Defaults.verticalAxis,
                          ],
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
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (data.isEmpty) {
      return _buildEmptyState(context, l10n, theme, Icons.event_busy_rounded);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final chartHeight = screenWidth > 900
            ? 300.0
            : screenWidth > 600
                ? 260.0
                : 220.0;

        return SizedBox(
          height: chartHeight,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppShadows.getElevation(
                1,
                isDark: theme.brightness == Brightness.dark,
              ),
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
                          coord: RectCoord(),
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
                                    theme.colorScheme.primary.withValues(
                                      alpha: 0.7,
                                    ),
                                  ],
                                ),
                              ),
                              entrance: {MarkEntrance.y},
                              label: LabelEncode(
                                encoder: (tuple) {
                                  final count = tuple['count'] as num;
                                  return Label(
                                    count > 0 ? count.toString() : '',
                                    LabelStyle(
                                      textStyle: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.onSurface
                                            .withValues(alpha: 0.7),
                                      ),
                                      offset: const Offset(0, -8),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                          axes: [
                            Defaults.horizontalAxis,
                            Defaults.verticalAxis,
                          ],
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
              ),
            ),
          ),
        );
      },
    );
  }
}

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
