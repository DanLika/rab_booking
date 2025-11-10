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
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          Flexible(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Chip(
                    label: Text('${filters.activeFilterCount} filters'),
                    onDeleted: () {
                      ref.read(calendarFiltersProvider.notifier).clearFilters();
                    },
                  ),
                ],
              ),
            ),
          ),
          TextButton.icon(
            icon: const Icon(Icons.clear_all, size: 18),
            label: const Text('Clear all'),
            onPressed: () {
              ref.read(calendarFiltersProvider.notifier).clearFilters();
            },
          ),
        ],
      ),
    );
  }
}
