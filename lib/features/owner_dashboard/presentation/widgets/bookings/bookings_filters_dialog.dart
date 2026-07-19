import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/enums.dart';
import '../../../../../core/constants/booking_status_extensions.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_shadows.dart';
import '../../../../../core/theme/gradient_extensions.dart';
import '../../../../../core/utils/input_decoration_helper.dart';
import '../../../../../core/utils/responsive_dialog_utils.dart';
import '../../../../../core/utils/responsive_spacing_helper.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../shared/models/property_model.dart';
import '../../../../../shared/widgets/custom_date_range_picker.dart';
import '../../../../../shared/widgets/redesign.dart';
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
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final propertiesAsync = ref.watch(ownerPropertiesCalendarProvider);
    final headerPadding = ResponsiveDialogUtils.getHeaderPadding(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      insetPadding: ResponsiveDialogUtils.getDialogInsetPadding(context),
      child: Container(
        width: isMobile ? screenWidth * 0.9 : 700,
        constraints: BoxConstraints(
          maxHeight:
              MediaQuery.of(context).size.height *
              ResponsiveSpacingHelper.getDialogMaxHeightPercent(context),
        ),
        decoration: BoxDecoration(
          gradient: context.gradients.sectionBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: context.gradients.sectionBorder.withAlpha(
              (0.5 * 255).toInt(),
            ),
          ),
          boxShadow: isDark ? AppShadows.elevation4Dark : AppShadows.elevation4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Dialog header — theme-aware shell strip. Previously a brand
            // purple `gradient` rendered a "hero on a dialog" which read as
            // heavier than the design's dialogs (`design_handoff/source/dialogs.jsx`
            // PV_PANEL_BG header).
            Container(
              height: ResponsiveDialogUtils.kHeaderHeight,
              padding: EdgeInsets.symmetric(horizontal: headerPadding),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: theme.dividerColor.withValues(alpha: 0.4),
                  ),
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(11),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.filter_list,
                    color: theme.colorScheme.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AutoSizeText(
                      l10n.ownerFiltersTitle,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      minFontSize: 14,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: theme.colorScheme.onSurface),
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
                color: isDark
                    ? AppColors.dialogFooterDark
                    : AppColors.dialogFooterLight,
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? AppColors.sectionDividerDark
                        : AppColors.sectionDividerLight,
                  ),
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
                color: theme.colorScheme.primary.withAlpha(
                  (0.12 * 255).toInt(),
                ),
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
              l10n.ownerFiltersStatusSection,
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
          dropdownColor: InputDecorationHelper.getDropdownColor(context),
          borderRadius: InputDecorationHelper.dropdownBorderRadius,
          decoration: InputDecorationHelper.buildDecoration(
            labelText: l10n.ownerFiltersStatusLabel,
            prefixIcon: Icon(
              Icons.label_outline,
              color: theme.colorScheme.primary,
            ),
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
                          decoration: BoxDecoration(
                            color: status.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(status.displayNameLocalized(context)),
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
    AppLocalizations l10n,
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
                color: theme.colorScheme.secondary.withAlpha(
                  (0.12 * 255).toInt(),
                ),
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
              l10n.ownerFiltersPropertySection,
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
              dropdownColor: InputDecorationHelper.getDropdownColor(context),
              borderRadius: InputDecorationHelper.dropdownBorderRadius,
              decoration: InputDecorationHelper.buildDecoration(
                labelText: l10n.ownerFiltersPropertyLabel,
                prefixIcon: Icon(
                  Icons.apartment,
                  color: theme.colorScheme.secondary,
                ),
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
                color: context.gradients.sectionBorder.withAlpha(
                  (0.3 * 255).toInt(),
                ),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Text(l10n.ownerFiltersLoadingProperties),
              ],
            ),
          ),
          error: (error, _) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: theme.colorScheme.error.withAlpha((0.3 * 255).toInt()),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: theme.colorScheme.error),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${l10n.ownerCalendarError}: $error',
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
                color: theme.colorScheme.tertiary.withAlpha(
                  (0.12 * 255).toInt(),
                ),
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
              l10n.ownerFiltersDateSection,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Date range picker button - styled to match dropdown fields
        InkWell(
          onTap: () async {
            final DateTimeRange? initialRange =
                (_selectedStartDate != null && _selectedEndDate != null)
                ? DateTimeRange(
                    start: _selectedStartDate!,
                    end: _selectedEndDate!,
                  )
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
                _filters = _filters.copyWith(
                  startDate: picked.start,
                  endDate: picked.end,
                );
              });
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              color: context.gradients.inputFillColor,
              border: Border.all(color: context.gradients.sectionBorder),
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
                    tooltip: l10n.ownerFiltersClear,
                    // BoxConstraints() collapsed the tap target to the 18px
                    // glyph (audit F4.11) — restore the 48px default floor.
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildApplyButton(
    ThemeData theme,
    bool isFullWidth,
    AppLocalizations l10n,
  ) {
    return BbButton(
      label: l10n.ownerFiltersApply,
      iconLeft: 'check',
      size: BbButtonSize.lg,
      fullWidth: isFullWidth,
      onPressed: () {
        final notifier = ref.read(bookingsFiltersNotifierProvider.notifier);
        notifier.setStatus(_filters.status);
        notifier.setProperty(_filters.propertyId);
        notifier.setDateRange(_filters.startDate, _filters.endDate);
        Navigator.of(context).pop();
      },
    );
  }

  Widget _buildClearButton(
    ThemeData theme,
    bool isFullWidth,
    AppLocalizations l10n,
  ) {
    return BbButton(
      label: l10n.ownerFiltersClear,
      iconLeft: 'clear_all',
      variant: BbButtonVariant.secondary,
      size: BbButtonSize.lg,
      fullWidth: isFullWidth,
      onPressed: () {
        setState(() {
          _filters = const BookingsFilters();
          _selectedStartDate = null;
          _selectedEndDate = null;
        });
        final notifier = ref.read(bookingsFiltersNotifierProvider.notifier);
        notifier.clearFilters();
        // Close like Apply does — clearing is a terminal action, leaving
        // the dialog open read as a no-op (audit F4.11).
        Navigator.of(context).pop();
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}
