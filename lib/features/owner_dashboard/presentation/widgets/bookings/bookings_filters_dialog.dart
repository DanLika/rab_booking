import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/enums.dart';
import '../../../../../shared/models/property_model.dart';
import '../../providers/owner_bookings_provider.dart';
import '../../providers/owner_calendar_provider.dart';

/// Advanced bookings filters dialog
/// Premium UI matching calendar filters panel design
class BookingsFiltersDialog extends ConsumerStatefulWidget {
  const BookingsFiltersDialog({super.key});

  @override
  ConsumerState<BookingsFiltersDialog> createState() =>
      _BookingsFiltersDialogState();
}

class _BookingsFiltersDialogState extends ConsumerState<BookingsFiltersDialog> {
  late BookingsFilters _filters;
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;

  @override
  void initState() {
    super.initState();
    _filters = ref.read(bookingsFiltersNotifierProvider);
    _selectedStartDate = _filters.startDate;
    _selectedEndDate = _filters.endDate;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final propertiesAsync = ref.watch(ownerPropertiesCalendarProvider);

    return Dialog(
      child: Container(
        width: isMobile ? double.infinity : 700,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with gradient (matching CommonAppBar)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.filter_list, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Filteri rezervacija',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Zatvori',
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
                    // Status filter
                    _buildStatusFilter(theme),
                    const SizedBox(height: 16),

                    // Property filter
                    _buildPropertyFilter(theme, propertiesAsync),
                    const SizedBox(height: 16),

                    // Date range filter
                    _buildDateRangeFilter(theme),
                  ],
                ),
              ),
            ),

            // Footer buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Apply button (full width on mobile)
                        _buildApplyButton(theme, true),
                        const SizedBox(height: 8),
                        // Clear button (full width on mobile)
                        _buildClearButton(theme, true),
                      ],
                    )
                  : Row(
                      children: [
                        // Clear button (left)
                        Expanded(child: _buildClearButton(theme, false)),
                        const SizedBox(width: 16),
                        // Apply button (right) with gradient
                        Expanded(child: _buildApplyButton(theme, false)),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusFilter(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section label
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.info_outline,
                size: 18,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Status rezervacije',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Status dropdown
        DropdownButtonFormField<BookingStatus?>(
          initialValue: _filters.status,
          decoration: InputDecoration(
            labelText: 'Filtriraj po statusu',
            prefixIcon: Icon(
              Icons.label_outline,
              color: theme.colorScheme.primary,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          items: [
            const DropdownMenuItem(
              child: Text('Svi statusi'),
            ),
            ...BookingStatus.values
                .where((s) =>
                    s == BookingStatus.pending ||
                    s == BookingStatus.confirmed ||
                    s == BookingStatus.cancelled ||
                    s == BookingStatus.completed)
                .map((status) {
              return DropdownMenuItem(
                value: status,
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: status.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(status.displayName),
                  ],
                ),
              );
            }),
          ],
          onChanged: (status) {
            setState(() {
              _filters = _filters.copyWith(
                status: status,
                clearStatus: status == null,
              );
            });
          },
        ),
      ],
    );
  }

  Widget _buildPropertyFilter(
    ThemeData theme,
    AsyncValue<List<PropertyModel>> propertiesAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section label
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.home_outlined,
                size: 18,
                color: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Nekretnina',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Property dropdown
        propertiesAsync.when(
          data: (properties) {
            return DropdownButtonFormField<String?>(
              initialValue: _filters.propertyId,
              decoration: InputDecoration(
                labelText: 'Filtriraj po nekretnini',
                prefixIcon: Icon(
                  Icons.apartment,
                  color: theme.colorScheme.secondary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              items: [
                const DropdownMenuItem(
                  child: Text('Sve nekretnine'),
                ),
                ...properties.map((property) {
                  return DropdownMenuItem(
                    value: property.id,
                    child: Text(
                      property.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }),
              ],
              onChanged: (propertyId) {
                setState(() {
                  _filters = _filters.copyWith(
                    propertyId: propertyId,
                    clearProperty: propertyId == null,
                  );
                });
              },
            );
          },
          loading: () => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Učitavam nekretnine...'),
              ],
            ),
          ),
          error: (error, _) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: theme.colorScheme.error.withValues(alpha: 0.3),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: theme.colorScheme.error),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Greška: $error',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateRangeFilter(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section label
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.tertiary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.date_range,
                size: 18,
                color: theme.colorScheme.tertiary,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Vremenski period',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Date range picker button
        InkWell(
          onTap: () async {
            final DateTimeRange? initialRange = (_selectedStartDate != null && _selectedEndDate != null)
                ? DateTimeRange(start: _selectedStartDate!, end: _selectedEndDate!)
                : null;

            final picked = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2020),
              lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
              initialDateRange: initialRange,
              builder: (context, child) {
                return Theme(
                  data: theme.copyWith(
                    colorScheme: theme.colorScheme.copyWith(
                      primary: theme.colorScheme.primary,
                    ),
                  ),
                  child: child!,
                );
              },
            );

            if (picked != null) {
              setState(() {
                _selectedStartDate = picked.start;
                _selectedEndDate = picked.end;
                _filters = _filters.copyWith(
                  startDate: picked.start,
                  endDate: picked.end,
                );
              });
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: theme.colorScheme.tertiary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedStartDate == null || _selectedEndDate == null
                        ? 'Odaberi vremenski period'
                        : '${_formatDate(_selectedStartDate!)} - ${_formatDate(_selectedEndDate!)}',
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
                if (_selectedStartDate != null && _selectedEndDate != null)
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    onPressed: () {
                      setState(() {
                        _selectedStartDate = null;
                        _selectedEndDate = null;
                        _filters = _filters.copyWith(
                          clearStartDate: true,
                          clearEndDate: true,
                        );
                      });
                    },
                    tooltip: 'Obriši',
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildApplyButton(ThemeData theme, bool isFullWidth) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Apply filters using individual setters
            final notifier = ref.read(bookingsFiltersNotifierProvider.notifier);

            // Apply each filter individually
            notifier.setStatus(_filters.status);
            notifier.setProperty(_filters.propertyId);
            notifier.setDateRange(_filters.startDate, _filters.endDate);

            Navigator.of(context).pop();
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
              children: [
                const Icon(Icons.check, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Primijeni filtere',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClearButton(ThemeData theme, bool isFullWidth) {
    return OutlinedButton.icon(
      onPressed: () {
        setState(() {
          _filters = const BookingsFilters();
          _selectedStartDate = null;
          _selectedEndDate = null;
        });
      },
      icon: const Icon(Icons.clear_all),
      label: const Text('Očisti filtere'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}
