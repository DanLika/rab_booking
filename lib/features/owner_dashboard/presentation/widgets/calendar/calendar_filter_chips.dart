import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/models/calendar_filter_options.dart';
import '../../providers/calendar_filters_provider.dart';

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
      constraints: const BoxConstraints(maxHeight: 56),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withAlpha((0.3 * 255).toInt()),
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          // Active filter count badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.filter_list,
                  size: 14,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${filters.activeFilterCount}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            filters.activeFilterCount == 1 ? 'aktivan filter' : 'aktivna filtera',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          // Clear all button (elevated for visibility)
          ElevatedButton.icon(
            icon: const Icon(Icons.clear_all, size: 18),
            label: const Text('Očisti sve'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: const Size(0, 36),
            ),
            onPressed: () {
              ref.read(calendarFiltersProvider.notifier).clearFilters();
            },
          ),
        ],
      ),
    );
  }
}
