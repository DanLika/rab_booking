import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/navigation_helpers.dart';
import '../providers/search_form_provider.dart';
import '../state/search_form_state.dart';
import 'guest_selector_sheet.dart';

/// Premium search bar widget
class SearchBarWidget extends ConsumerWidget {
  const SearchBarWidget({
    this.isFloating = true,
    super.key,
  });

  final bool isFloating;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(searchFormNotifierProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Container(
      constraints: const BoxConstraints(maxWidth: 1200),
      padding: const EdgeInsets.all(16),
      decoration: isFloating
          ? BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            )
          : null,
      child: isMobile
          ? _buildMobileLayout(context, ref, formState)
          : _buildDesktopLayout(context, ref, formState),
    );
  }

  /// Mobile layout (stacked vertically)
  Widget _buildMobileLayout(
    BuildContext context,
    WidgetRef ref,
    SearchFormState formState,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _LocationField(formState: formState),
        const SizedBox(height: 12),
        _DatesField(formState: formState),
        const SizedBox(height: 12),
        _GuestsField(formState: formState),
        const SizedBox(height: 16),
        _SearchButton(formState: formState),
      ],
    );
  }

  /// Desktop layout (horizontal)
  Widget _buildDesktopLayout(
    BuildContext context,
    WidgetRef ref,
    SearchFormState formState,
  ) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: _LocationField(formState: formState),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: _DatesField(formState: formState),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _GuestsField(formState: formState),
        ),
        const SizedBox(width: 12),
        _SearchButton(formState: formState, isCompact: true),
      ],
    );
  }
}

/// Location field
class _LocationField extends ConsumerWidget {
  const _LocationField({required this.formState});

  final SearchFormState formState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _SearchField(
      icon: Icons.location_on_outlined,
      label: 'Lokacija',
      value: formState.location,
      onTap: () => _showLocationPicker(context, ref),
    );
  }

  Future<void> _showLocationPicker(BuildContext context, WidgetRef ref) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => _LocationPickerSheet(
        currentLocation: formState.location,
      ),
    );

    if (selected != null) {
      ref.read(searchFormNotifierProvider.notifier).updateLocation(selected);
    }
  }
}

/// Dates field
class _DatesField extends ConsumerWidget {
  const _DatesField({required this.formState});

  final SearchFormState formState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _SearchField(
      icon: Icons.calendar_today_outlined,
      label: 'Datumi',
      value: formState.datesDisplay,
      onTap: () => _showDatePicker(context, ref),
    );
  }

  Future<void> _showDatePicker(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final dateRange = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: formState.checkInDate != null &&
              formState.checkOutDate != null
          ? DateTimeRange(
              start: formState.checkInDate!,
              end: formState.checkOutDate!,
            )
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (dateRange != null) {
      ref
          .read(searchFormNotifierProvider.notifier)
          .updateDateRange(dateRange.start, dateRange.end);
    }
  }
}

/// Guests field
class _GuestsField extends ConsumerWidget {
  const _GuestsField({required this.formState});

  final SearchFormState formState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _SearchField(
      icon: Icons.person_outline,
      label: 'Gosti',
      value: formState.guestsDisplay,
      onTap: () => GuestSelectorSheet.show(context),
    );
  }
}

/// Generic search field
class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Theme.of(context).primaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          fontSize: 11,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Search button
class _SearchButton extends ConsumerWidget {
  const _SearchButton({
    required this.formState,
    this.isCompact = false,
  });

  final SearchFormState formState;
  final bool isCompact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FilledButton(
      onPressed: formState.isValid ? () => _handleSearch(context, ref) : null,
      style: FilledButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 24 : 32,
          vertical: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        mainAxisSize: isCompact ? MainAxisSize.min : MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search),
          if (!isCompact) ...[
            const SizedBox(width: 8),
            const Text('Pretraži'),
          ],
        ],
      ),
    );
  }

  void _handleSearch(BuildContext context, WidgetRef ref) {
    // Navigate to search results with parameters
    context.goToSearch(
      location: formState.location,
      maxGuests: formState.totalGuests,
      checkIn: formState.checkInDate?.toIso8601String().split('T')[0],
      checkOut: formState.checkOutDate?.toIso8601String().split('T')[0],
    );
  }
}

/// Location picker bottom sheet
class _LocationPickerSheet extends StatelessWidget {
  const _LocationPickerSheet({required this.currentLocation});

  final String currentLocation;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              'Odaberite lokaciju',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            // Location list
            ...rabLocations.map((location) {
              final isSelected = location == currentLocation;
              return ListTile(
                leading: Icon(
                  Icons.location_on,
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.grey,
                ),
                title: Text(location),
                trailing: isSelected
                    ? Icon(Icons.check, color: Theme.of(context).primaryColor)
                    : null,
                selected: isSelected,
                onTap: () => Navigator.of(context).pop(location),
              );
            }),
          ],
        ),
      ),
    );
  }
}
