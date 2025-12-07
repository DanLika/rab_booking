import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../core/constants/enums.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_shadows.dart';
import '../../../../../core/theme/gradient_extensions.dart';
import '../../../../../core/utils/input_decoration_helper.dart';
import '../../../../../core/utils/responsive_dialog_utils.dart';
import '../../../../../shared/widgets/custom_date_range_picker.dart';
import '../../../../../shared/widgets/app_filter_chip.dart';
import '../../../domain/models/calendar_filter_options.dart';
import '../../providers/calendar_filters_provider.dart';
import '../../providers/owner_calendar_provider.dart';
import '../../../utils/calendar_grid_calculator.dart';

/// Advanced calendar filters panel
/// Shows all available filters: properties, units, statuses, sources, date range, search
class CalendarFiltersPanel extends ConsumerStatefulWidget {
  const CalendarFiltersPanel({super.key});

  @override
  ConsumerState<CalendarFiltersPanel> createState() => _CalendarFiltersPanelState();
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
    final l10n = AppLocalizations.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < CalendarGridCalculator.mobileBreakpoint;
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      insetPadding: ResponsiveDialogUtils.getDialogInsetPadding(context),
      child: Container(
        width: isMobile ? screenWidth * 0.9 : 700,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        decoration: BoxDecoration(
          gradient: context.gradients.sectionBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.gradients.sectionBorder.withAlpha((0.5 * 255).toInt())),
          boxShadow: isDark ? AppShadows.elevation4Dark : AppShadows.elevation4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with gradient
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: context.gradients.brandPrimary,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha((0.2 * 255).toInt()),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.filter_list, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AutoSizeText(
                      l10n.calendarFiltersTitle,
                      style: theme.textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      minFontSize: 14,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(screenWidth < 400 ? 12 : 16),
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
              padding: EdgeInsets.symmetric(horizontal: screenWidth < 400 ? 8 : 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.dialogFooterDark : AppColors.dialogFooterLight,
                border: Border(
                  top: BorderSide(color: isDark ? AppColors.sectionDividerDark : AppColors.sectionDividerLight),
                ),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(11)),
              ),
              child: isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Apply button (full width on mobile) with brand gradient
                        Container(
                          decoration: BoxDecoration(
                            gradient: context.gradients.brandPrimary,
                            borderRadius: const BorderRadius.all(Radius.circular(8)),
                          ),
                          child: ElevatedButton.icon(
                            onPressed: _applyFilters,
                            icon: const Icon(Icons.check),
                            label: AutoSizeText(l10n.calendarFiltersApply, maxLines: 1),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Cancel and Clear row
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: AutoSizeText(l10n.calendarFiltersCancel, maxLines: 1, minFontSize: 11),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextButton.icon(
                                onPressed: _filters.hasActiveFilters
                                    ? () {
                                        setState(() {
                                          _filters = const CalendarFilterOptions();
                                          _guestSearchController.clear();
                                          _bookingIdSearchController.clear();
                                        });
                                      }
                                    : null,
                                icon: const Icon(Icons.clear_all, size: 16),
                                label: AutoSizeText(l10n.calendarFiltersClear, maxLines: 1, minFontSize: 11),
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
                          label: AutoSizeText(l10n.calendarFiltersClearAll, maxLines: 1),
                        ),

                        // Apply filters button
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: AutoSizeText(l10n.calendarFiltersCancel, maxLines: 1),
                              ),
                              const SizedBox(width: 8),
                              // Apply button with brand gradient
                              Container(
                                decoration: BoxDecoration(
                                  gradient: context.gradients.brandPrimary,
                                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                                ),
                                child: ElevatedButton.icon(
                                  onPressed: _applyFilters,
                                  icon: const Icon(Icons.check),
                                  label: AutoSizeText(l10n.calendarFiltersApply, maxLines: 1),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
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
            const _SectionHeader(icon: Icons.home_outlined, title: 'Objekti'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: properties.map((property) {
                final isSelected = _filters.propertyIds.contains(property.id);
                return AppFilterChip(
                  label: property.name,
                  selected: isSelected,
                  icon: Icons.home_outlined,
                  onSelected: () {
                    setState(() {
                      if (isSelected) {
                        _filters = _filters.copyWith(
                          propertyIds: _filters.propertyIds.where((id) => id != property.id).toList(),
                        );
                      } else {
                        _filters = _filters.copyWith(propertyIds: [..._filters.propertyIds, property.id]);
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
            : units.where((unit) => _filters.propertyIds.contains(unit.propertyId)).toList();

        if (filteredUnits.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeader(icon: Icons.meeting_room_outlined, title: 'Jedinice'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: filteredUnits.map((unit) {
                final isSelected = _filters.unitIds.contains(unit.id);
                return AppFilterChip(
                  label: unit.name,
                  selected: isSelected,
                  icon: Icons.meeting_room,
                  onSelected: () {
                    setState(() {
                      if (isSelected) {
                        _filters = _filters.copyWith(unitIds: _filters.unitIds.where((id) => id != unit.id).toList());
                      } else {
                        _filters = _filters.copyWith(unitIds: [..._filters.unitIds, unit.id]);
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
    // Only show active booking statuses (pending, confirmed, cancelled, completed)
    final activeStatuses = [
      BookingStatus.pending,
      BookingStatus.confirmed,
      BookingStatus.cancelled,
      BookingStatus.completed,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(icon: Icons.info_outline, title: 'Statusi'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: activeStatuses.map((status) {
            final statusString = status.name;
            final isSelected = _filters.statuses.contains(statusString);
            final theme = Theme.of(context);

            return FilterChip(
              selected: isSelected,
              label: Text(status.displayName),
              selectedColor: theme.colorScheme.primary,
              backgroundColor: isSelected ? theme.colorScheme.primary : context.gradients.cardBackground,
              side: BorderSide(
                color: isSelected ? theme.colorScheme.primary : context.gradients.sectionBorder,
                width: 1.5,
              ),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 14,
              ),
              checkmarkColor: Colors.white,
              avatar: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: status.color,
                  shape: BoxShape.circle,
                  border: Border.all(color: isSelected ? Colors.white : Colors.transparent, width: 2),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: isSelected ? 2 : 0,
              shadowColor: theme.colorScheme.primary.withValues(alpha: 0.3),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _filters = _filters.copyWith(statuses: [..._filters.statuses, statusString]);
                  } else {
                    _filters = _filters.copyWith(statuses: _filters.statuses.where((s) => s != statusString).toList());
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
    final theme = Theme.of(context);

    final sources = [
      ('widget', 'Widget', Icons.web, Colors.green),
      ('admin', 'Manualno', Icons.person, Colors.grey),
      ('ical', 'iCal', Icons.sync, theme.colorScheme.secondary),
      ('booking_com', 'Booking.com', Icons.public, Colors.orange),
      ('airbnb', 'Airbnb', Icons.home, Colors.red),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(icon: Icons.source_outlined, title: 'Izvori rezervacija'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: sources.map((source) {
            final (value, label, icon, color) = source;
            final isSelected = _filters.sources.contains(value);

            return FilterChip(
              selected: isSelected,
              label: Text(label),
              selectedColor: theme.colorScheme.primary,
              backgroundColor: isSelected ? theme.colorScheme.primary : context.gradients.cardBackground,
              side: BorderSide(
                color: isSelected ? theme.colorScheme.primary : context.gradients.sectionBorder,
                width: 1.5,
              ),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 14,
              ),
              checkmarkColor: Colors.white,
              avatar: Icon(icon, size: 18, color: isSelected ? Colors.white : color),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: isSelected ? 2 : 0,
              shadowColor: theme.colorScheme.primary.withValues(alpha: 0.3),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _filters = _filters.copyWith(sources: [..._filters.sources, value]);
                  } else {
                    _filters = _filters.copyWith(sources: _filters.sources.where((s) => s != value).toList());
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
        const _SectionHeader(icon: Icons.date_range_outlined, title: 'Raspon datuma'),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _showDateRangePicker,
          icon: const Icon(Icons.date_range),
          label: Text(
            _filters.startDate != null && _filters.endDate != null
                ? '${_filters.startDate!.day}.${_filters.startDate!.month}.${_filters.startDate!.year}. - ${_filters.endDate!.day}.${_filters.endDate!.month}.${_filters.endDate!.year}.'
                : 'Odaberi raspon datuma',
          ),
          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
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
              label: Text(AppLocalizations.of(context).calendarFiltersClearDate),
            ),
          ),
      ],
    );
  }

  Widget _buildGuestSearchField() {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(icon: Icons.person_search_outlined, title: l10n.calendarFiltersSearchGuest),
        const SizedBox(height: 12),
        Builder(
          builder: (ctx) => TextField(
            controller: _guestSearchController,
            decoration: InputDecorationHelper.buildDecoration(
              labelText: l10n.calendarFiltersGuestLabel,
              prefixIcon: const Icon(Icons.search),
              hintText: l10n.calendarFiltersGuestHint,
              context: ctx,
            ),
            onChanged: (value) {
              setState(() {
                _filters = _filters.copyWith(guestSearchQuery: value.isEmpty ? null : value);
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBookingIdSearchField() {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(icon: Icons.tag_outlined, title: l10n.calendarFiltersSearchBookingId),
        const SizedBox(height: 12),
        Builder(
          builder: (ctx) => TextField(
            controller: _bookingIdSearchController,
            decoration: InputDecorationHelper.buildDecoration(
              labelText: l10n.calendarFiltersBookingIdLabel,
              prefixIcon: const Icon(Icons.tag),
              hintText: l10n.calendarFiltersBookingIdHint,
              context: ctx,
            ),
            onChanged: (value) {
              setState(() {
                _filters = _filters.copyWith(bookingIdSearch: value.isEmpty ? null : value);
              });
            },
          ),
        ),
      ],
    );
  }

  Future<void> _showDateRangePicker() async {
    final picked = await showCustomDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _filters.startDate != null && _filters.endDate != null
          ? DateTimeRange(start: _filters.startDate!, end: _filters.endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _filters = _filters.copyWith(startDate: picked.start, endDate: picked.end);
      });
    }
  }

  void _applyFilters() {
    // Apply filters to provider
    ref.read(calendarFiltersProvider.notifier).setPropertyIds(_filters.propertyIds);
    ref.read(calendarFiltersProvider.notifier).setUnitIds(_filters.unitIds);
    ref.read(calendarFiltersProvider.notifier).setStatuses(_filters.statuses);
    ref.read(calendarFiltersProvider.notifier).setSources(_filters.sources);
    ref.read(calendarFiltersProvider.notifier).setDateRange(startDate: _filters.startDate, endDate: _filters.endDate);
    ref.read(calendarFiltersProvider.notifier).setGuestSearchQuery(_filters.guestSearchQuery);
    ref.read(calendarFiltersProvider.notifier).setBookingIdSearch(_filters.bookingIdSearch);

    // Close dialog
    Navigator.of(context).pop(true);
  }
}

/// Section header widget with icon and gradient accent
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            gradient: context.gradients.brandPrimary,
            borderRadius: const BorderRadius.all(Radius.circular(8)),
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: AutoSizeText(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}
