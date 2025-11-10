import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../../../../../core/constants/enums.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../domain/models/calendar_filter_options.dart';
import '../../providers/calendar_filters_provider.dart';
import '../../providers/owner_calendar_provider.dart';
import '../../../utils/calendar_grid_calculator.dart';

/// Advanced calendar filters panel
/// Shows all available filters: properties, units, statuses, sources, date range, search
class CalendarFiltersPanel extends ConsumerStatefulWidget {
  const CalendarFiltersPanel({super.key});

  @override
  ConsumerState<CalendarFiltersPanel> createState() =>
      _CalendarFiltersPanelState();
}

class _CalendarFiltersPanelState extends ConsumerState<CalendarFiltersPanel> {
  late CalendarFilterOptions _filters;
  final _guestSearchController = TextEditingController();
  final _bookingIdSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filters = ref.read(calendarFiltersProvider);
    _guestSearchController.text = _filters.guestSearchQuery ?? '';
    _bookingIdSearchController.text = _filters.bookingIdSearch ?? '';
  }

  @override
  void dispose() {
    _guestSearchController.dispose();
    _bookingIdSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile =
        MediaQuery.of(context).size.width <
        CalendarGridCalculator.mobileBreakpoint;

    return Dialog(
      child: Container(
        width: isMobile ? double.infinity : 700,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.primaryColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.filter_list, color: theme.colorScheme.onPrimary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Filteri kalendara',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: theme.colorScheme.onPrimary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Property filter
                    _buildPropertyFilter(),
                    const SizedBox(height: 16),

                    // Unit filter (depends on selected properties)
                    _buildUnitFilter(),
                    const SizedBox(height: 16),

                    // Status filter
                    _buildStatusFilter(),
                    const SizedBox(height: 16),

                    // Source filter
                    _buildSourceFilter(),
                    const SizedBox(height: 16),

                    // Date range filter
                    _buildDateRangeFilter(),
                    const SizedBox(height: 16),

                    // Guest search
                    _buildGuestSearchField(),
                    const SizedBox(height: 16),

                    // Booking ID search
                    _buildBookingIdSearchField(),
                  ],
                ),
              ),
            ),

            // Footer buttons (responsive)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: theme.dividerColor)),
              ),
              child: isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Apply button (full width on mobile)
                        ElevatedButton.icon(
                          onPressed: _applyFilters,
                          icon: const Icon(Icons.check),
                          label: const AutoSizeText('Primijeni', maxLines: 1),
                        ),
                        const SizedBox(height: 8),
                        // Cancel and Clear row
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const AutoSizeText(
                                  'Otkaži',
                                  maxLines: 1,
                                  minFontSize: 11,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextButton.icon(
                                onPressed: _filters.hasActiveFilters
                                    ? () {
                                        setState(() {
                                          _filters =
                                              const CalendarFilterOptions();
                                          _guestSearchController.clear();
                                          _bookingIdSearchController.clear();
                                        });
                                      }
                                    : null,
                                icon: const Icon(Icons.clear_all, size: 16),
                                label: const AutoSizeText(
                                  'Očisti',
                                  maxLines: 1,
                                  minFontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Clear filters button
                        TextButton.icon(
                          onPressed: _filters.hasActiveFilters
                              ? () {
                                  setState(() {
                                    _filters = const CalendarFilterOptions();
                                    _guestSearchController.clear();
                                    _bookingIdSearchController.clear();
                                  });
                                }
                              : null,
                          icon: const Icon(Icons.clear_all),
                          label: const AutoSizeText('Očisti sve', maxLines: 1),
                        ),

                        // Apply filters button
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const AutoSizeText(
                                  'Otkaži',
                                  maxLines: 1,
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: _applyFilters,
                                icon: const Icon(Icons.check),
                                label: const AutoSizeText(
                                  'Primijeni',
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyFilter() {
    final propertiesAsync = ref.watch(ownerPropertiesCalendarProvider);

    return propertiesAsync.when(
      data: (properties) {
        if (properties.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Objekti',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: properties.map((property) {
                final isSelected = _filters.propertyIds.contains(property.id);
                return FilterChip(
                  selected: isSelected,
                  label: Text(property.name),
                  avatar: Icon(
                    Icons.home_outlined,
                    size: 18,
                    color: isSelected
                        ? Theme.of(context).colorScheme.onPrimary
                        : null,
                  ),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _filters = _filters.copyWith(
                          propertyIds: [..._filters.propertyIds, property.id],
                        );
                      } else {
                        _filters = _filters.copyWith(
                          propertyIds: _filters.propertyIds
                              .where((id) => id != property.id)
                              .toList(),
                        );
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => Text('Greška: $error'),
    );
  }

  Widget _buildUnitFilter() {
    final unitsAsync = ref.watch(allOwnerUnitsProvider);

    return unitsAsync.when(
      data: (units) {
        if (units.isEmpty) {
          return const SizedBox.shrink();
        }

        // Filter units by selected properties
        final filteredUnits = _filters.propertyIds.isEmpty
            ? units
            : units
                  .where(
                    (unit) => _filters.propertyIds.contains(unit.propertyId),
                  )
                  .toList();

        if (filteredUnits.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Jedinice',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: filteredUnits.map((unit) {
                final isSelected = _filters.unitIds.contains(unit.id);
                return FilterChip(
                  selected: isSelected,
                  label: Text(unit.name),
                  avatar: Icon(
                    Icons.meeting_room,
                    size: 18,
                    color: isSelected
                        ? Theme.of(context).colorScheme.onPrimary
                        : null,
                  ),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _filters = _filters.copyWith(
                          unitIds: [..._filters.unitIds, unit.id],
                        );
                      } else {
                        _filters = _filters.copyWith(
                          unitIds: _filters.unitIds
                              .where((id) => id != unit.id)
                              .toList(),
                        );
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => Text('Greška: $error'),
    );
  }

  Widget _buildStatusFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statusi',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: BookingStatus.values.map((status) {
            final statusString = status.name;
            final isSelected = _filters.statuses.contains(statusString);
            return FilterChip(
              selected: isSelected,
              label: Text(status.displayName),
              avatar: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: status.color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.onPrimary
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _filters = _filters.copyWith(
                      statuses: [..._filters.statuses, statusString],
                    );
                  } else {
                    _filters = _filters.copyWith(
                      statuses: _filters.statuses
                          .where((s) => s != statusString)
                          .toList(),
                    );
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSourceFilter() {
    const sources = [
      ('widget', 'Widget', Icons.web, Colors.green),
      ('admin', 'Manualno', Icons.person, Colors.grey),
      ('ical', 'iCal', Icons.sync, AppColors.authSecondary),
      ('booking_com', 'Booking.com', Icons.public, Colors.orange),
      ('airbnb', 'Airbnb', Icons.home, Colors.red),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Izvori rezervacija',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: sources.map((source) {
            final (value, label, icon, color) = source;
            final isSelected = _filters.sources.contains(value);
            return FilterChip(
              selected: isSelected,
              label: Text(label),
              avatar: Icon(
                icon,
                size: 18,
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : color,
              ),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _filters = _filters.copyWith(
                      sources: [..._filters.sources, value],
                    );
                  } else {
                    _filters = _filters.copyWith(
                      sources: _filters.sources
                          .where((s) => s != value)
                          .toList(),
                    );
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDateRangeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Raspon datuma',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _showDateRangePicker,
          icon: const Icon(Icons.date_range),
          label: Text(
            _filters.startDate != null && _filters.endDate != null
                ? '${_filters.startDate!.day}.${_filters.startDate!.month}.${_filters.startDate!.year}. - ${_filters.endDate!.day}.${_filters.endDate!.month}.${_filters.endDate!.year}.'
                : 'Odaberi raspon datuma',
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        if (_filters.startDate != null && _filters.endDate != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _filters = _filters.copyWith(startDate: null, endDate: null);
                });
              },
              icon: const Icon(Icons.clear, size: 16),
              label: const Text('Očisti datum'),
            ),
          ),
      ],
    );
  }

  Widget _buildGuestSearchField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pretraži gosta',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _guestSearchController,
          decoration: const InputDecoration(
            labelText: 'Ime ili email gosta',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.search),
            hintText: 'Unesite ime ili email...',
          ),
          onChanged: (value) {
            setState(() {
              _filters = _filters.copyWith(
                guestSearchQuery: value.isEmpty ? null : value,
              );
            });
          },
        ),
      ],
    );
  }

  Widget _buildBookingIdSearchField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pretraži po ID-u rezervacije',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _bookingIdSearchController,
          decoration: const InputDecoration(
            labelText: 'ID rezervacije',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.tag),
            hintText: 'Unesite ID rezervacije...',
          ),
          onChanged: (value) {
            setState(() {
              _filters = _filters.copyWith(
                bookingIdSearch: value.isEmpty ? null : value,
              );
            });
          },
        ),
      ],
    );
  }

  Future<void> _showDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _filters.startDate != null && _filters.endDate != null
          ? DateTimeRange(start: _filters.startDate!, end: _filters.endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _filters = _filters.copyWith(
          startDate: picked.start,
          endDate: picked.end,
        );
      });
    }
  }

  void _applyFilters() {
    // Apply filters to provider
    ref
        .read(calendarFiltersProvider.notifier)
        .setPropertyIds(_filters.propertyIds);
    ref.read(calendarFiltersProvider.notifier).setUnitIds(_filters.unitIds);
    ref.read(calendarFiltersProvider.notifier).setStatuses(_filters.statuses);
    ref.read(calendarFiltersProvider.notifier).setSources(_filters.sources);
    ref
        .read(calendarFiltersProvider.notifier)
        .setDateRange(startDate: _filters.startDate, endDate: _filters.endDate);
    ref
        .read(calendarFiltersProvider.notifier)
        .setGuestSearchQuery(_filters.guestSearchQuery);
    ref
        .read(calendarFiltersProvider.notifier)
        .setBookingIdSearch(_filters.bookingIdSearch);

    // Close dialog
    Navigator.of(context).pop(true);
  }
}
