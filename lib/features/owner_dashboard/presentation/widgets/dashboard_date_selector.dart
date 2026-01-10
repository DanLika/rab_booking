import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/platform_scroll_physics.dart';
import '../../../../shared/widgets/app_filter_chip.dart';
import '../providers/unified_dashboard_provider.dart';

class DashboardDateSelector extends ConsumerWidget {
  const DashboardDateSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final dateRange = ref.watch(dashboardDateRangeNotifierProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.horizontalPadding,
        vertical: isMobile ? 12 : 16,
      ),
      color: Colors.transparent,
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: PlatformScrollPhysics.adaptive,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
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
              const SizedBox(width: 8),
              AppFilterChip(
                label: l10n.ownerAnalyticsLast30Days,
                selected: dateRange.preset == 'last30',
                onSelected: () {
                  ref
                      .read(dashboardDateRangeNotifierProvider.notifier)
                      .setPreset('last30');
                },
              ),
              const SizedBox(width: 8),
              AppFilterChip(
                label: l10n.ownerAnalyticsLast90Days,
                selected: dateRange.preset == 'last90',
                onSelected: () {
                  ref
                      .read(dashboardDateRangeNotifierProvider.notifier)
                      .setPreset('last90');
                },
              ),
              const SizedBox(width: 8),
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
        ),
      ),
    );
  }
}
