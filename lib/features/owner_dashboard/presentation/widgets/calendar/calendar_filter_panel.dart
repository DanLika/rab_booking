import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/enums.dart';
import '../../../../../shared/models/property_model.dart';
import '../../../../../shared/models/unit_model.dart';
import '../../../domain/models/calendar_filter_options.dart';
import '../../providers/calendar_filters_provider.dart';
import '../../providers/owner_calendar_provider.dart';
import '../../../../../core/theme/app_colors.dart';

/// Calendar filter panel (bottom sheet)
/// Allows users to filter bookings by status, source, property, unit, etc.
class CalendarFilterPanel extends ConsumerStatefulWidget {
  const CalendarFilterPanel({super.key});

  @override
  ConsumerState<CalendarFilterPanel> createState() =>
      _CalendarFilterPanelState();
}

class _CalendarFilterPanelState extends ConsumerState<CalendarFilterPanel> {
  bool _statusExpanded = false;
  bool _sourceExpanded = false;
  bool _propertyExpanded = false;
  bool _unitExpanded = false;

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(calendarFiltersProvider);
    final theme = Theme.of(context);
    final propertiesAsync = ref.watch(ownerPropertiesCalendarProvider);
    final unitsAsync = ref.watch(allOwnerUnitsProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.filter_list, color: const Color(0xFFFFFFFF)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Filteri',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: const Color(0xFFFFFFFF),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (filters.hasActiveFilters)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${filters.activeFilterCount}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: const Color(0xFFFFFFFF)),
                ),
              ],
            ),
          ),

          // Filter sections
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status filter
                  _buildFilterSection(
                    title: 'Status',
                    isExpanded: _statusExpanded,
                    activeCount: filters.statuses.length,
                    onToggle: () {
                      setState(() {
                        _statusExpanded = !_statusExpanded;
                      });
                    },
                    child: _buildStatusFilters(filters),
                  ),

                  const SizedBox(height: 12),

                  // Source filter
                  _buildFilterSection(
                    title: 'Izvor rezervacije',
                    isExpanded: _sourceExpanded,
                    activeCount: filters.sources.length,
                    onToggle: () {
                      setState(() {
                        _sourceExpanded = !_sourceExpanded;
                      });
                    },
                    child: _buildSourceFilters(filters),
                  ),

                  const SizedBox(height: 12),

                  // Property filter
                  propertiesAsync.when(
                    data: (properties) => _buildFilterSection(
                      title: 'Objekti',
                      isExpanded: _propertyExpanded,
                      activeCount: filters.propertyIds.length,
                      onToggle: () {
                        setState(() {
                          _propertyExpanded = !_propertyExpanded;
                        });
                      },
                      child: _buildPropertyFilters(filters, properties),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),

                  const SizedBox(height: 12),

                  // Unit filter
                  unitsAsync.when(
                    data: (units) => _buildFilterSection(
                      title: 'Jedinice',
                      isExpanded: _unitExpanded,
                      activeCount: filters.unitIds.length,
                      onToggle: () {
                        setState(() {
                          _unitExpanded = !_unitExpanded;
                        });
                      },
                      child: _buildUnitFilters(filters, units),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),

          // Bottom actions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              border: Border(
                top: BorderSide(color: theme.dividerColor),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: filters.hasActiveFilters
                        ? () {
                            ref.read(calendarFiltersProvider.notifier).clearFilters();
                          }
                        : null,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Poništi sve'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: const Color(0xFFFFFFFF),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Primijeni'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build a collapsible filter section
  Widget _buildFilterSection({
    required String title,
    required bool isExpanded,
    required int activeCount,
    required VoidCallback onToggle,
    required Widget child,
  }) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (activeCount > 0)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$activeCount',
                        style: const TextStyle(
                          color: const Color(0xFFFFFFFF),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: theme.iconTheme.color,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: child,
            ),
        ],
      ),
    );
  }

  /// Build status filter checkboxes
  Widget _buildStatusFilters(filters) {
    final statuses = [
      BookingStatus.pending,
      BookingStatus.confirmed,
      BookingStatus.inProgress,
      BookingStatus.completed,
      BookingStatus.cancelled,
    ];

    return Column(
      children: statuses.map((status) {
        final isSelected = filters.statuses.contains(status.name);
        return CheckboxListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          value: isSelected,
          onChanged: (value) {
            final newStatuses = List<String>.from(filters.statuses);
            if (value == true) {
              newStatuses.add(status.name);
            } else {
              newStatuses.remove(status.name);
            }
            ref.read(calendarFiltersProvider.notifier).setStatuses(newStatuses);
          },
          title: Text(
            status.displayName,
            style: const TextStyle(fontSize: 14),
          ),
          activeColor: AppColors.primary,
        );
      }).toList(),
    );
  }

  /// Build source filter checkboxes
  Widget _buildSourceFilters(filters) {
    final sources = [
      {'value': 'manual', 'label': 'Ručno kreirano'},
      {'value': 'widget', 'label': 'Widget'},
      {'value': 'ical', 'label': 'iCal uvoz'},
      {'value': 'booking_com', 'label': 'Booking.com'},
      {'value': 'airbnb', 'label': 'Airbnb'},
    ];

    return Column(
      children: sources.map((source) {
        final isSelected = filters.sources.contains(source['value']);
        return CheckboxListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          value: isSelected,
          onChanged: (value) {
            final newSources = List<String>.from(filters.sources);
            if (value == true) {
              newSources.add(source['value']!);
            } else {
              newSources.remove(source['value']);
            }
            ref.read(calendarFiltersProvider.notifier).setSources(newSources);
          },
          title: Text(
            source['label']!,
            style: const TextStyle(fontSize: 14),
          ),
          activeColor: AppColors.primary,
        );
      }).toList(),
    );
  }

  /// Build property filter checkboxes
  Widget _buildPropertyFilters(filters, List<PropertyModel> properties) {
    return Column(
      children: properties.map((property) {
        final isSelected = filters.propertyIds.contains(property.id);
        return CheckboxListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          value: isSelected,
          onChanged: (value) {
            final newPropertyIds = List<String>.from(filters.propertyIds);
            if (value == true) {
              newPropertyIds.add(property.id);
            } else {
              newPropertyIds.remove(property.id);
            }
            ref.read(calendarFiltersProvider.notifier).setPropertyIds(newPropertyIds);
          },
          title: Text(
            property.name,
            style: const TextStyle(fontSize: 14),
          ),
          activeColor: AppColors.primary,
        );
      }).toList(),
    );
  }

  /// Build unit filter checkboxes
  Widget _buildUnitFilters(filters, List<UnitModel> units) {
    return Column(
      children: units.map((unit) {
        final isSelected = filters.unitIds.contains(unit.id);
        return CheckboxListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          value: isSelected,
          onChanged: (value) {
            final newUnitIds = List<String>.from(filters.unitIds);
            if (value == true) {
              newUnitIds.add(unit.id);
            } else {
              newUnitIds.remove(unit.id);
            }
            ref.read(calendarFiltersProvider.notifier).setUnitIds(newUnitIds);
          },
          title: Text(
            unit.name,
            style: const TextStyle(fontSize: 14),
          ),
          subtitle: Text(
            'Kapacitet: ${unit.maxGuests} osoba',
            style: const TextStyle(fontSize: 12),
          ),
          activeColor: AppColors.primary,
        );
      }).toList(),
    );
  }
}

/// Show calendar filter panel as bottom sheet
void showCalendarFilterPanel(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0x00000000),
    builder: (context) => const CalendarFilterPanel(),
  );
}
