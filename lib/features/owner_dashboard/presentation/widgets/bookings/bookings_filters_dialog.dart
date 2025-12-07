import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/enums.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_shadows.dart';
import '../../../../../core/theme/gradient_extensions.dart';
import '../../../../../core/utils/input_decoration_helper.dart';
import '../../../../../core/utils/responsive_dialog_utils.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../shared/models/property_model.dart';
import '../../../../../shared/widgets/custom_date_range_picker.dart';
import '../../providers/owner_bookings_provider.dart';
import '../../providers/owner_calendar_provider.dart';

/// Advanced bookings filters dialog
/// Premium UI matching calendar filters panel design
class BookingsFiltersDialog extends ConsumerStatefulWidget {
  const BookingsFiltersDialog({super.key});

  @override
  ConsumerState<BookingsFiltersDialog> createState() => _BookingsFiltersDialogState();
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
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final propertiesAsync = ref.watch(ownerPropertiesCalendarProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      insetPadding: ResponsiveDialogUtils.getDialogInsetPadding(context),
      child: Container(
        width: isMobile ? double.infinity : 700,
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
            // Header with gradient (matching CommonAppBar)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: context.gradients.brandPrimary,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.filter_list, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AutoSizeText(
                      l10n.ownerFiltersTitle,
                      style: theme.textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      minFontSize: 14,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: l10n.ownerDetailsClose,
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
                    _buildStatusFilter(theme, l10n),
                    const SizedBox(height: 16),

                    // Property filter
                    _buildPropertyFilter(theme, propertiesAsync, l10n),
                    const SizedBox(height: 16),

                    // Date range filter
                    _buildDateRangeFilter(theme, l10n),
                  ],
                ),
              ),
            ),

            // Footer buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.dialogFooterDark : AppColors.dialogFooterLight,
                border: Border(
                  top: BorderSide(color: isDark ? AppColors.sectionDividerDark : AppColors.sectionDividerLight),
                ),
              ),
              child: isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Apply button (full width on mobile)
                        _buildApplyButton(theme, true, l10n),
                        const SizedBox(height: 8),
                        // Clear button (full width on mobile)
                        _buildClearButton(theme, true, l10n),
                      ],
                    )
                  : Row(
                      children: [
                        // Clear button (left)
                        Expanded(child: _buildClearButton(theme, false, l10n)),
                        const SizedBox(width: 16),
                        // Apply button (right) with gradient
                        Expanded(child: _buildApplyButton(theme, false, l10n)),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusFilter(ThemeData theme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section label
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withAlpha((0.12 * 255).toInt()),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.info_outline, size: 18, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Text(
              l10n.ownerFiltersStatusSection,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Status dropdown
        DropdownButtonFormField<BookingStatus?>(
          initialValue: _filters.status,
          dropdownColor: InputDecorationHelper.getDropdownColor(context),
          borderRadius: InputDecorationHelper.dropdownBorderRadius,
          decoration: InputDecorationHelper.buildDecoration(
            labelText: l10n.ownerFiltersStatusLabel,
            prefixIcon: Icon(Icons.label_outline, color: theme.colorScheme.primary),
            context: context,
          ),
          items: [
            DropdownMenuItem(child: Text(l10n.ownerFiltersAllStatuses)),
            ...BookingStatus.values
                .where(
                  (s) =>
                      s == BookingStatus.pending ||
                      s == BookingStatus.confirmed ||
                      s == BookingStatus.cancelled ||
                      s == BookingStatus.completed,
                )
                .map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(color: status.color, shape: BoxShape.circle),
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
              _filters = _filters.copyWith(status: status, clearStatus: status == null);
            });
          },
        ),
      ],
    );
  }

  Widget _buildPropertyFilter(ThemeData theme, AsyncValue<List<PropertyModel>> propertiesAsync, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section label
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withAlpha((0.12 * 255).toInt()),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.home_outlined, size: 18, color: theme.colorScheme.secondary),
            ),
            const SizedBox(width: 12),
            Text(
              l10n.ownerFiltersPropertySection,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Property dropdown
        propertiesAsync.when(
          data: (properties) {
            return DropdownButtonFormField<String?>(
              initialValue: _filters.propertyId,
              dropdownColor: InputDecorationHelper.getDropdownColor(context),
              borderRadius: InputDecorationHelper.dropdownBorderRadius,
              decoration: InputDecorationHelper.buildDecoration(
                labelText: l10n.ownerFiltersPropertyLabel,
                prefixIcon: Icon(Icons.apartment, color: theme.colorScheme.secondary),
                context: context,
              ),
              items: [
                DropdownMenuItem(child: Text(l10n.ownerFiltersAllProperties)),
                ...properties.map((property) {
                  return DropdownMenuItem(
                    value: property.id,
                    child: Text(property.name, overflow: TextOverflow.ellipsis),
                  );
                }),
              ],
              onChanged: (propertyId) {
                setState(() {
                  _filters = _filters.copyWith(propertyId: propertyId, clearProperty: propertyId == null);
                });
              },
            );
          },
          loading: () => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: context.gradients.sectionBorder.withAlpha((0.3 * 255).toInt())),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                const SizedBox(width: 12),
                Text(l10n.ownerFiltersLoadingProperties),
              ],
            ),
          ),
          error: (error, _) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.error.withAlpha((0.3 * 255).toInt())),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: theme.colorScheme.error),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('${l10n.ownerCalendarError}: $error', style: TextStyle(color: theme.colorScheme.error)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateRangeFilter(ThemeData theme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section label
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.tertiary.withAlpha((0.12 * 255).toInt()),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.date_range, size: 18, color: theme.colorScheme.tertiary),
            ),
            const SizedBox(width: 12),
            Text(
              l10n.ownerFiltersDateSection,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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

            final picked = await showCustomDateRangePicker(
              context: context,
              firstDate: DateTime(2020),
              lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
              initialDateRange: initialRange,
            );

            if (picked != null) {
              setState(() {
                _selectedStartDate = picked.start;
                _selectedEndDate = picked.end;
                _filters = _filters.copyWith(startDate: picked.start, endDate: picked.end);
              });
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: context.gradients.sectionBorder.withAlpha((0.3 * 255).toInt())),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: theme.colorScheme.tertiary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedStartDate == null || _selectedEndDate == null
                        ? l10n.ownerFiltersSelectDateRange
                        : '${_formatDate(_selectedStartDate!)} - ${_formatDate(_selectedEndDate!)}',
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
                if (_selectedStartDate != null && _selectedEndDate != null)
                  IconButton(
                    icon: Icon(Icons.close, size: 18, color: theme.colorScheme.onSurfaceVariant),
                    onPressed: () {
                      setState(() {
                        _selectedStartDate = null;
                        _selectedEndDate = null;
                        _filters = _filters.copyWith(clearStartDate: true, clearEndDate: true);
                      });
                    },
                    tooltip: l10n.ownerFiltersClear,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildApplyButton(ThemeData theme, bool isFullWidth, AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        gradient: context.gradients.brandPrimary,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
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
                  l10n.ownerFiltersApply,
                  style: theme.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClearButton(ThemeData theme, bool isFullWidth, AppLocalizations l10n) {
    return OutlinedButton.icon(
      onPressed: () {
        setState(() {
          _filters = const BookingsFilters();
          _selectedStartDate = null;
          _selectedEndDate = null;
        });
      },
      icon: const Icon(Icons.clear_all),
      label: Text(l10n.ownerFiltersClear),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        side: BorderSide(color: context.gradients.sectionBorder.withAlpha((0.3 * 255).toInt())),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}
