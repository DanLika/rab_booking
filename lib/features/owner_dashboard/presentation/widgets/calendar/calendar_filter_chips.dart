import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/models/calendar_filter_options.dart';
import '../../providers/calendar_filters_provider.dart';
import '../../../../../l10n/app_localizations.dart';

/// Calendar Filter Chips Widget
/// Displays active filters and allows clearing them
class CalendarFilterChips extends ConsumerWidget {
  const CalendarFilterChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(calendarFiltersProvider);

    // Only show if there are active filters
    if (!filters.hasActiveFilters) {
      return const SizedBox.shrink();
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 36),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.primaryContainer.withAlpha((0.3 * 255).toInt()),
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          // Active filter count badge (compact)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.filter_list,
                  size: 12,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${filters.activeFilterCount}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              return Text(
                filters.activeFilterCount == 1
                    ? l10n.ownerFilterActiveFilter
                    : l10n.ownerFilterActiveFilters,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
              );
            },
          ),
          const Spacer(),
          // Clear all - simple red text link
          Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              return GestureDetector(
                onTap: () {
                  ref.read(calendarFiltersProvider.notifier).clearFilters();
                  // CRITICAL: Force refresh of calendar data after clearing filters
                  // Without this, cached data from filtered state persists
                  ref.invalidate(filteredUnitsProvider);
                  ref.invalidate(filteredCalendarBookingsProvider);
                  ref.invalidate(timelineCalendarBookingsProvider);
                },
                child: Text(
                  l10n.ownerFilterClearAll,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
