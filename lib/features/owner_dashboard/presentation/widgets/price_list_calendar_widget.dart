import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/models/daily_price_model.dart';
import '../../../../shared/models/unit_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/gradient_extensions.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../../../../core/utils/input_decoration_helper.dart';
import '../../../../core/utils/responsive_dialog_utils.dart';
import '../../../../core/utils/responsive_spacing_helper.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../providers/price_list_provider.dart';
import '../providers/platform_connections_provider.dart';
import '../state/price_calendar_state.dart';
import 'calendar/calendar_day_cell.dart';
import 'dialogs/unblock_warning_dialog.dart';

/// BedBooking-style Price List Calendar
/// Displays one month at a time with dropdown selector
/// Shows pricing, availability, and all BedBooking features
///
/// Features:
/// - Optimistic updates for instant UI feedback
/// - Local state cache for better performance
/// - Extracted components for better maintainability
class PriceListCalendarWidget extends ConsumerStatefulWidget {
  final UnitModel unit;

  const PriceListCalendarWidget({super.key, required this.unit});

  @override
  ConsumerState<PriceListCalendarWidget> createState() =>
      _PriceListCalendarWidgetState();
}

class _PriceListCalendarWidgetState
    extends ConsumerState<PriceListCalendarWidget> {
  late DateTime _selectedMonth;
  final Set<DateTime> _selectedDays = {};
  bool _bulkEditMode = false;
  bool _isLoadingMonthChange = false;

  // Local state cache with optimistic updates
  final PriceCalendarState _localState = PriceCalendarState();

  // Cached month list to avoid regenerating on every build
  late final List<DateTime> _cachedMonthList;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
    // Generate month list once during initialization
    _cachedMonthList = _generateMonthList();

    // Listen to local state changes
    _localState.addListener(_onLocalStateChanged);
  }

  @override
  void dispose() {
    _localState.removeListener(_onLocalStateChanged);
    _localState.dispose();
    super.dispose();
  }

  void _onLocalStateChanged() {
    // Rebuild when local state changes (optimistic updates, undo/redo)
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with month selector and bulk edit toggle
          _buildHeader(isMobile),

          const SizedBox(height: 16),

          // Selected days counter (in bulk edit mode)
          if (_bulkEditMode && _selectedDays.isNotEmpty) ...[
            _buildSelectionCounter(),
            const SizedBox(height: 12),
          ],

          // Select All / Deselect All buttons (in bulk edit mode)
          if (_bulkEditMode) ...[
            _buildBulkSelectionButtons(),
            const SizedBox(height: 16),
          ],

          // Calendar grid - constrained height for GridView
          _buildCalendarGrid(),

          const SizedBox(height: 16),

          // Action buttons
          if (_bulkEditMode && _selectedDays.isNotEmpty)
            _buildBulkEditActions(isMobile),
        ],
      ),
    );
  }

  Widget _buildBulkEditActions(bool isMobile) {
    final l10n = AppLocalizations.of(context);
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: _showBulkPriceDialog,
            icon: const Icon(Icons.euro),
            label: Text(l10n.priceCalendarSetPrice),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                vertical: 15,
              ), // Same as Save button
              backgroundColor: context.primaryColor,
              foregroundColor: Colors.white,
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  12,
                ), // Consistent with inputs
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _showBulkAvailabilityDialog,
            icon: const Icon(Icons.block),
            label: Text(l10n.priceCalendarAvailability),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                vertical: 15,
              ), // Same as Save button
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  12,
                ), // Consistent with inputs
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        SizedBox(
          width: 180, // Fixed width to match Save button
          child: ElevatedButton.icon(
            onPressed: _showBulkPriceDialog,
            icon: const Icon(Icons.euro),
            label: Text(l10n.priceCalendarSetPrice),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                vertical: 15,
              ), // Same as Save button
              backgroundColor: context.primaryColor,
              foregroundColor: Colors.white,
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  12,
                ), // Consistent with inputs
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 180, // Fixed width to match Save button
          child: OutlinedButton.icon(
            onPressed: _showBulkAvailabilityDialog,
            icon: const Icon(Icons.block),
            label: Text(l10n.priceCalendarAvailability),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                vertical: 15,
              ), // Same as Save button
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  12,
                ), // Consistent with inputs
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(bool isMobile) {
    final l10n = AppLocalizations.of(context);
    final isDark = context.isDarkMode;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.getElevation(1, isDark: isDark),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            color: context.gradients.cardBackground,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: context.gradients.sectionBorder,
              width: 1.5,
            ),
          ),
          padding: EdgeInsets.all(isMobile ? 16 : 20),
          child: isMobile
              ? _buildHeaderMobile(l10n)
              : _buildHeaderDesktop(l10n),
        ),
      ),
    );
  }

  Widget _buildHeaderMobile(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Month selector
        Builder(
          builder: (context) => DropdownButtonFormField<DateTime>(
            initialValue: _selectedMonth,
            dropdownColor: InputDecorationHelper.getDropdownColor(context),
            decoration: InputDecorationHelper.buildDecoration(
              labelText: l10n.priceCalendarSelectMonth,
              prefixIcon: const Icon(Icons.calendar_month),
              isMobile: true,
              context: context,
            ),
            items: _cachedMonthList.map((month) {
              return DropdownMenuItem(
                value: month,
                child: Text(DateFormat('MMMM yyyy').format(month)),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null && value != _selectedMonth) {
                setState(() {
                  _isLoadingMonthChange = true;
                  _selectedMonth = value;
                  _selectedDays.clear();
                });
                Future.microtask(() {
                  if (mounted) {
                    setState(() => _isLoadingMonthChange = false);
                  }
                });
              }
            },
          ),
        ),
        const SizedBox(height: 12),
        // Bulk edit toggle - full width on mobile
        OutlinedButton.icon(
          onPressed: () {
            setState(() {
              _bulkEditMode = !_bulkEditMode;
              _selectedDays.clear();
            });
          },
          icon: Icon(
            _bulkEditMode ? Icons.close : Icons.edit_calendar_rounded,
            size: 20,
          ),
          label: Text(_bulkEditMode ? l10n.cancel : l10n.priceCalendarBulkEdit),
          style: OutlinedButton.styleFrom(
            foregroundColor: _bulkEditMode ? context.primaryColor : null,
            side: _bulkEditMode
                ? BorderSide(color: context.primaryColor, width: 2)
                : null,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderDesktop(AppLocalizations l10n) {
    return Row(
      children: [
        // Previous month button
        IconButton(
          onPressed: () {
            final prevMonth = DateTime(
              _selectedMonth.year,
              _selectedMonth.month - 1,
            );
            setState(() {
              _isLoadingMonthChange = true;
              _selectedMonth = prevMonth;
              _selectedDays.clear();
            });
            Future.microtask(() {
              if (mounted) {
                setState(() => _isLoadingMonthChange = false);
              }
            });
          },
          icon: const Icon(Icons.chevron_left),
          tooltip: l10n.ownerCalendarPreviousMonth,
          style: IconButton.styleFrom(
            backgroundColor: context.gradients.cardBackground,
            side: BorderSide(color: context.gradients.sectionBorder),
          ),
        ),
        const SizedBox(width: 12),
        // Month selector with dropdown
        Expanded(
          child: Builder(
            builder: (context) => DropdownButtonFormField<DateTime>(
              initialValue: _selectedMonth,
              dropdownColor: InputDecorationHelper.getDropdownColor(context),
              decoration: InputDecorationHelper.buildDecoration(
                labelText: l10n.priceCalendarSelectMonth,
                prefixIcon: const Icon(Icons.calendar_month),
                context: context,
              ),
              items: _cachedMonthList.map((month) {
                return DropdownMenuItem(
                  value: month,
                  child: Text(DateFormat('MMMM yyyy').format(month)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null && value != _selectedMonth) {
                  setState(() {
                    _isLoadingMonthChange = true;
                    _selectedMonth = value;
                    _selectedDays.clear();
                  });
                  Future.microtask(() {
                    if (mounted) {
                      setState(() => _isLoadingMonthChange = false);
                    }
                  });
                }
              },
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Next month button
        IconButton(
          onPressed: () {
            final nextMonth = DateTime(
              _selectedMonth.year,
              _selectedMonth.month + 1,
            );
            setState(() {
              _isLoadingMonthChange = true;
              _selectedMonth = nextMonth;
              _selectedDays.clear();
            });
            Future.microtask(() {
              if (mounted) {
                setState(() => _isLoadingMonthChange = false);
              }
            });
          },
          icon: const Icon(Icons.chevron_right),
          tooltip: l10n.ownerCalendarNextMonth,
          style: IconButton.styleFrom(
            backgroundColor: context.gradients.cardBackground,
            side: BorderSide(color: context.gradients.sectionBorder),
          ),
        ),
        const SizedBox(width: 20),
        // Bulk edit mode toggle
        SizedBox(
          width: 180,
          child: OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _bulkEditMode = !_bulkEditMode;
                _selectedDays.clear();
              });
            },
            icon: Icon(
              _bulkEditMode ? Icons.close : Icons.edit_calendar_rounded,
              size: 20,
            ),
            label: Text(
              _bulkEditMode ? l10n.cancel : l10n.priceCalendarBulkEdit,
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: _bulkEditMode ? context.primaryColor : null,
              side: _bulkEditMode
                  ? BorderSide(color: context.primaryColor, width: 2)
                  : null,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectionCounter() {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.primaryColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: context.primaryColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: context.primaryColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.priceCalendarDaysSelected(_selectedDays.length),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: context.primaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: () {
              setState(_selectedDays.clear);
            },
            icon: const Icon(Icons.close, size: 16),
            label: Text(l10n.priceCalendarClear),
            style: TextButton.styleFrom(
              foregroundColor: context.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulkSelectionButtons() {
    final l10n = AppLocalizations.of(context);
    final daysInMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
      0,
    ).day;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDeselectDisabled = _selectedDays.isEmpty;

    // Dropdown-style background for disabled state (matches surfaceContainerHighest)
    final disabledBgColor = isDark
        ? const Color(0xFF2D2D3A)
        : const Color(0xFFF5F5F5);
    final disabledTextColor = theme.colorScheme.onSurface.withValues(
      alpha: 0.38,
    );

    return Row(
      children: [
        // Select All button
        Expanded(
          child: Theme(
            data: theme.copyWith(
              splashColor: theme.colorScheme.primary.withValues(alpha: 0.2),
              highlightColor: theme.colorScheme.primary.withValues(alpha: 0.1),
            ),
            child: FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.select_all, size: 16, color: context.primaryColor),
                  const SizedBox(width: 6),
                  Flexible(child: Text(l10n.priceCalendarSelectAll)),
                ],
              ),
              onSelected: (_) {
                setState(() {
                  // Select all days in current month
                  _selectedDays.clear();
                  for (int day = 1; day <= daysInMonth; day++) {
                    _selectedDays.add(
                      DateTime(_selectedMonth.year, _selectedMonth.month, day),
                    );
                  }
                });
              },
              backgroundColor: context.gradients.cardBackground,
              side: BorderSide(color: context.primaryColor, width: 1.5),
              labelStyle: TextStyle(
                color: context.primaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Deselect All button - custom styling for disabled state
        Expanded(
          child: Theme(
            data: theme.copyWith(
              splashColor: theme.colorScheme.primary.withValues(alpha: 0.2),
              highlightColor: theme.colorScheme.primary.withValues(alpha: 0.1),
            ),
            child: FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.deselect,
                    size: 16,
                    color: isDeselectDisabled
                        ? disabledTextColor
                        : context.primaryColor,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      l10n.priceCalendarDeselectAll,
                      style: TextStyle(
                        color: isDeselectDisabled
                            ? disabledTextColor
                            : context.primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              onSelected: isDeselectDisabled
                  ? null
                  : (_) {
                      setState(_selectedDays.clear);
                    },
              // Use dropdown background for disabled state
              backgroundColor: isDeselectDisabled
                  ? disabledBgColor
                  : context.gradients.cardBackground,
              disabledColor: disabledBgColor,
              side: BorderSide(
                color: isDeselectDisabled
                    ? theme.colorScheme.outline.withValues(alpha: 0.3)
                    : context.primaryColor,
                width: 1.5,
              ),
              labelStyle: TextStyle(
                color: isDeselectDisabled
                    ? disabledTextColor
                    : context.primaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarGrid() {
    final daysInMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
      0,
    ).day;
    final firstDayOfWeek = DateTime(
      _selectedMonth.year,
      _selectedMonth.month,
    ).weekday;

    // Watch monthly prices from Firestore
    final pricesAsync = ref.watch(
      monthlyPricesProvider(
        MonthlyPricesParams(unitId: widget.unit.id, month: _selectedMonth),
      ),
    );

    // Use LayoutBuilder to get screen constraints for responsive sizing
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final isMobile = availableWidth < 600;
        final isSmallMobile = availableWidth < 400;

        // Calculate aspect ratio based on device size
        final aspectRatio = isSmallMobile ? 0.85 : (isMobile ? 1.0 : 1.2);

        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppShadows.getElevation(1, isDark: isDark),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
              decoration: BoxDecoration(
                color: context.gradients.cardBackground,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: context.gradients.sectionBorder,
                  width: 1.5,
                ),
              ),
              padding: EdgeInsets.all(isMobile ? 16 : 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Weekday headers
                  _buildWeekdayHeaders(),

                  const SizedBox(height: 8),
                  Divider(color: context.borderColor.withValues(alpha: 0.5)),
                  const SizedBox(height: 8),

                  // Calendar grid with dynamic height
                  _isLoadingMonthChange
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        )
                      : pricesAsync.when(
                          data: (priceMap) {
                            // Only sync server data to local cache if we don't have any cached data yet
                            // This prevents overwriting optimistic updates with stale server data
                            final existingCache = _localState.getMonthPrices(
                              _selectedMonth,
                            );
                            if (existingCache == null) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                _localState.setMonthPrices(
                                  _selectedMonth,
                                  priceMap,
                                );
                              });
                            }

                            // Use local cache for display (supports optimistic updates)
                            // Falls back to server data only if no local cache exists
                            final displayMap = existingCache ?? priceMap;

                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 7,
                                    mainAxisSpacing: 8,
                                    crossAxisSpacing: 8,
                                    childAspectRatio: aspectRatio,
                                  ),
                              itemCount: firstDayOfWeek - 1 + daysInMonth,
                              itemBuilder: (context, index) {
                                if (index < firstDayOfWeek - 1) {
                                  return const SizedBox.shrink();
                                }

                                final day = index - (firstDayOfWeek - 1) + 1;
                                final date = DateTime(
                                  _selectedMonth.year,
                                  _selectedMonth.month,
                                  day,
                                );

                                // Use extracted CalendarDayCell component
                                return CalendarDayCell(
                                  date: date,
                                  priceData:
                                      displayMap[DateTime(
                                        date.year,
                                        date.month,
                                        date.day,
                                      )],
                                  basePrice: widget.unit.pricePerNight,
                                  weekendBasePrice:
                                      widget.unit.weekendBasePrice,
                                  isSelected: _selectedDays.contains(date),
                                  isBulkEditMode: _bulkEditMode,
                                  onTap: () => _onDayCellTap(date),
                                  isMobile: isMobile,
                                  isSmallMobile: isSmallMobile,
                                  weekendDays: widget.unit.weekendDays,
                                );
                              },
                            );
                          },
                          loading: () => Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          error: (error, stack) {
                            final l10n = AppLocalizations.of(context);
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      size: 48,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.error,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      l10n.priceCalendarErrorLoadingPrices,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.error,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      error.toString(),
                                      style: const TextStyle(fontSize: 12),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
          ),
        );
      },
    ); // Close LayoutBuilder
  }

  Widget _buildWeekdayHeaders() {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final weekdays = [
      l10n.priceCalendarWeekdayMon,
      l10n.priceCalendarWeekdayTue,
      l10n.priceCalendarWeekdayWed,
      l10n.priceCalendarWeekdayThu,
      l10n.priceCalendarWeekdayFri,
      l10n.priceCalendarWeekdaySat,
      l10n.priceCalendarWeekdaySun,
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: context.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: weekdays.map((day) {
          return Expanded(
            child: Center(
              child: Text(
                day,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: context.primaryColor,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Handle day cell tap - bulk edit or single edit
  void _onDayCellTap(DateTime date) {
    if (_bulkEditMode) {
      setState(() {
        if (_selectedDays.contains(date)) {
          _selectedDays.remove(date);
        } else {
          _selectedDays.add(date);
        }
      });
    } else {
      _showPriceEditDialog(date);
    }
  }

  void _showPriceEditDialog(DateTime date) async {
    // Load existing price data for this date
    final monthlyPrices = await ref.read(
      monthlyPricesProvider(
        MonthlyPricesParams(
          unitId: widget.unit.id,
          month: DateTime(date.year, date.month),
        ),
      ).future,
    );

    final dateKey = DateTime(date.year, date.month, date.day);
    final existingPrice = monthlyPrices[dateKey];

    // Controllers for all fields
    final priceController = TextEditingController(
      text: (existingPrice?.price ?? widget.unit.pricePerNight).toStringAsFixed(
        0,
      ),
    );
    final minNightsController = TextEditingController(
      text: existingPrice?.minNightsOnArrival?.toString() ?? '',
    );
    final maxNightsController = TextEditingController(
      text: existingPrice?.maxNightsOnArrival?.toString() ?? '',
    );
    final minDaysAdvanceController = TextEditingController(
      text: existingPrice?.minDaysAdvance?.toString() ?? '',
    );
    final maxDaysAdvanceController = TextEditingController(
      text: existingPrice?.maxDaysAdvance?.toString() ?? '',
    );
    bool available = existingPrice?.available ?? true;
    bool blockCheckIn = existingPrice?.blockCheckIn ?? false;
    bool blockCheckOut = existingPrice?.blockCheckOut ?? false;

    if (!mounted) return;

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = screenWidth < 600;

    // Processing state to prevent duplicate button clicks
    bool isProcessing = false;
    DateTime? lastClickTime;
    // Track if dialog was closed to prevent setState on defunct StatefulBuilder
    bool dialogClosed = false;

    // Show dialog and dispose controllers when it closes
    unawaited(
      showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) {
            final theme = Theme.of(context);
            final isDark = theme.brightness == Brightness.dark;

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              insetPadding: ResponsiveDialogUtils.getDialogInsetPadding(
                context,
              ),
              child: Container(
                width: isMobile ? screenWidth * 0.90 : 500,
                constraints: BoxConstraints(
                  maxHeight:
                      screenHeight *
                      ResponsiveSpacingHelper.getDialogMaxHeightPercent(
                        context,
                      ),
                ),
                decoration: BoxDecoration(
                  color: context.gradients.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: context.gradients.sectionBorder.withAlpha(
                      (0.5 * 255).toInt(),
                    ),
                  ),
                  boxShadow: isDark
                      ? AppShadows.elevation4Dark
                      : AppShadows.elevation4,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Gradient Header
                    Container(
                      padding: EdgeInsets.all(isMobile ? 16 : 20),
                      decoration: BoxDecoration(
                        gradient: context.gradients.brandPrimary,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(11),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(
                                (0.2 * 255).toInt(),
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.calendar_today,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(
                                    context,
                                  ).priceCalendarEditDate,
                                  style: TextStyle(
                                    fontSize: isMobile ? 16 : 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  DateFormat(
                                    'd. MMMM yyyy.',
                                    'hr',
                                  ).format(date),
                                  style: TextStyle(
                                    fontSize: isMobile ? 12 : 14,
                                    color: Colors.white.withAlpha(
                                      (0.9 * 255).toInt(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Content
                    Flexible(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(isMobile ? 16 : 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Price section with icon header
                            Row(
                              children: [
                                Icon(
                                  Icons.euro,
                                  size: 18,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  AppLocalizations.of(
                                    context,
                                  ).priceCalendarPrice,
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: isMobile ? 8 : 12),
                            TextField(
                              controller: priceController,
                              decoration: InputDecorationHelper.buildDecoration(
                                labelText: AppLocalizations.of(
                                  context,
                                ).priceCalendarBasePricePerNight,
                                prefixIcon: const Icon(Icons.euro),
                                isMobile: isMobile,
                                context: context,
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                            ),

                            SizedBox(height: isMobile ? 16 : 24),

                            // Availability section with icon header
                            Row(
                              children: [
                                Icon(
                                  Icons.event_available,
                                  size: 18,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  AppLocalizations.of(
                                    context,
                                  ).priceCalendarAvailabilitySection,
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            SwitchListTile(
                              title: Text(
                                AppLocalizations.of(
                                  context,
                                ).priceCalendarAvailable,
                                style: TextStyle(
                                  fontSize: isMobile ? 14 : null,
                                ),
                              ),
                              value: available,
                              onChanged: (value) =>
                                  setState(() => available = value),
                              contentPadding: EdgeInsets.zero,
                            ),
                            SwitchListTile(
                              title: Text(
                                AppLocalizations.of(
                                  context,
                                ).priceCalendarBlockCheckIn,
                                style: TextStyle(
                                  fontSize: isMobile ? 14 : null,
                                ),
                              ),
                              subtitle: Text(
                                AppLocalizations.of(
                                  context,
                                ).priceCalendarBlockCheckInDesc,
                                style: TextStyle(
                                  fontSize: isMobile ? 12 : null,
                                ),
                              ),
                              value: blockCheckIn,
                              onChanged: (value) =>
                                  setState(() => blockCheckIn = value),
                              contentPadding: EdgeInsets.zero,
                            ),
                            SwitchListTile(
                              title: Text(
                                AppLocalizations.of(
                                  context,
                                ).priceCalendarBlockCheckOut,
                                style: TextStyle(
                                  fontSize: isMobile ? 14 : null,
                                ),
                              ),
                              subtitle: Text(
                                AppLocalizations.of(
                                  context,
                                ).priceCalendarBlockCheckOutDesc,
                                style: TextStyle(
                                  fontSize: isMobile ? 12 : null,
                                ),
                              ),
                              value: blockCheckOut,
                              onChanged: (value) =>
                                  setState(() => blockCheckOut = value),
                              contentPadding: EdgeInsets.zero,
                            ),

                            SizedBox(height: isMobile ? 16 : 24),

                            // Advanced options in ExpansionTile (collapsed by default)
                            Theme(
                              data: theme.copyWith(
                                dividerColor: Colors.transparent,
                              ),
                              child: ExpansionTile(
                                iconColor: theme.colorScheme.primary,
                                collapsedIconColor: theme.colorScheme.primary,
                                tilePadding: EdgeInsets.zero,
                                childrenPadding: EdgeInsets.only(
                                  top: isMobile ? 8 : 12,
                                  bottom: isMobile ? 8 : 12,
                                ),
                                leading: Icon(
                                  Icons.tune,
                                  size: 18,
                                  color: theme.colorScheme.tertiary,
                                ),
                                title: Text(
                                  AppLocalizations.of(
                                    context,
                                  ).priceCalendarAdvancedOptions,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.tertiary,
                                  ),
                                ),
                                subtitle: Text(
                                  AppLocalizations.of(
                                    context,
                                  ).priceCalendarAdvancedOptionsDesc,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                children: [
                                  // Min/Max nights row
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: minNightsController,
                                          decoration:
                                              InputDecorationHelper.buildDecoration(
                                                labelText: AppLocalizations.of(
                                                  context,
                                                ).priceCalendarMinNights,
                                                hintText: AppLocalizations.of(
                                                  context,
                                                ).priceCalendarHintExample('2'),
                                                isMobile: isMobile,
                                                context: context,
                                              ),
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                          ],
                                        ),
                                      ),
                                      SizedBox(width: isMobile ? 8 : 12),
                                      Expanded(
                                        child: TextField(
                                          controller: maxNightsController,
                                          decoration:
                                              InputDecorationHelper.buildDecoration(
                                                labelText: AppLocalizations.of(
                                                  context,
                                                ).priceCalendarMaxNights,
                                                hintText:
                                                    AppLocalizations.of(
                                                      context,
                                                    ).priceCalendarHintExample(
                                                      '14',
                                                    ),
                                                isMobile: isMobile,
                                                context: context,
                                              ),
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: isMobile ? 12 : 16),
                                  // Min/Max days advance booking row
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: minDaysAdvanceController,
                                          decoration:
                                              InputDecorationHelper.buildDecoration(
                                                labelText: AppLocalizations.of(
                                                  context,
                                                ).priceCalendarMinDaysAdvance,
                                                hintText: AppLocalizations.of(
                                                  context,
                                                ).priceCalendarHintExample('1'),
                                                isMobile: isMobile,
                                                context: context,
                                              ),
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                          ],
                                        ),
                                      ),
                                      SizedBox(width: isMobile ? 8 : 12),
                                      Expanded(
                                        child: TextField(
                                          controller: maxDaysAdvanceController,
                                          decoration:
                                              InputDecorationHelper.buildDecoration(
                                                labelText: AppLocalizations.of(
                                                  context,
                                                ).priceCalendarMaxDaysAdvance,
                                                hintText:
                                                    AppLocalizations.of(
                                                      context,
                                                    ).priceCalendarHintExample(
                                                      '365',
                                                    ),
                                                isMobile: isMobile,
                                                context: context,
                                              ),
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Actions footer
                    Container(
                      padding: EdgeInsets.all(isMobile ? 12 : 16),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: theme.dividerColor.withAlpha(
                              (0.3 * 255).toInt(),
                            ),
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (existingPrice != null)
                            TextButton(
                              onPressed: isProcessing
                                  ? null
                                  : () async {
                                      final navigator = Navigator.of(context);

                                      // Show confirmation dialog before deleting
                                      final l10nDialog = AppLocalizations.of(
                                        context,
                                      );
                                      final confirmed = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: Text(
                                            l10nDialog
                                                .priceCalendarDeleteConfirmTitle,
                                          ),
                                          content: Text(
                                            l10nDialog
                                                .priceCalendarDeleteConfirmMessage,
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(
                                                context,
                                              ).pop(false),
                                              child: Text(l10nDialog.cancel),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.of(
                                                context,
                                              ).pop(true),
                                              style: TextButton.styleFrom(
                                                foregroundColor:
                                                    AppColors.error,
                                              ),
                                              child: Text(l10nDialog.delete),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirmed != true) return;

                                      setState(() => isProcessing = true);

                                      // Delete custom price (revert to base price)
                                      try {
                                        final repository = ref.read(
                                          dailyPriceRepositoryProvider,
                                        );
                                        await repository.deletePriceForDate(
                                          unitId: widget.unit.id,
                                          date: date,
                                        );

                                        // Invalidate provider to trigger reload
                                        ref.invalidate(
                                          monthlyPricesProvider(
                                            MonthlyPricesParams(
                                              unitId: widget.unit.id,
                                              month: DateTime(
                                                date.year,
                                                date.month,
                                              ),
                                            ),
                                          ),
                                        );

                                        if (mounted) {
                                          dialogClosed = true;
                                          navigator.pop();
                                          ErrorDisplayUtils.showSuccessSnackBar(
                                            this.context,
                                            l10nDialog
                                                .priceCalendarRevertedToBasePrice,
                                          );
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          ErrorDisplayUtils.showErrorSnackBar(
                                            this.context,
                                            e,
                                          );
                                        }
                                      } finally {
                                        // Only reset processing if dialog is still open
                                        if (mounted && !dialogClosed) {
                                          setState(() => isProcessing = false);
                                        }
                                      }
                                    },
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.error,
                              ),
                              child: Text(AppLocalizations.of(context).delete),
                            ),
                          TextButton(
                            onPressed: isProcessing
                                ? null
                                : () => Navigator.of(context).pop(),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(AppLocalizations.of(context).cancel),
                          ),
                          const SizedBox(width: 12),
                          FilledButton(
                            onPressed: isProcessing
                                ? null
                                : () async {
                                    // Debounce: prevent duplicate clicks
                                    final now = DateTime.now();
                                    if (lastClickTime != null &&
                                        now
                                                .difference(lastClickTime!)
                                                .inSeconds <
                                            2) {
                                      return;
                                    }
                                    lastClickTime = now;

                                    final navigator = Navigator.of(context);

                                    // Save price data
                                    final l10nValidation = AppLocalizations.of(
                                      context,
                                    );
                                    final priceText = priceController.text
                                        .trim();
                                    if (priceText.isEmpty) {
                                      ErrorDisplayUtils.showWarningSnackBar(
                                        context,
                                        l10nValidation.priceCalendarEnterPrice,
                                      );
                                      return;
                                    }

                                    final price = double.tryParse(priceText);
                                    if (price == null || price <= 0) {
                                      ErrorDisplayUtils.showWarningSnackBar(
                                        context,
                                        l10nValidation
                                            .priceCalendarPriceMustBeGreaterThanZero,
                                      );
                                      return;
                                    }

                                    // Validate optional fields
                                    final minNightsText = minNightsController
                                        .text
                                        .trim();
                                    if (minNightsText.isNotEmpty) {
                                      final minNights = int.tryParse(
                                        minNightsText,
                                      );
                                      if (minNights == null || minNights <= 0) {
                                        ErrorDisplayUtils.showWarningSnackBar(
                                          context,
                                          l10nValidation
                                              .priceCalendarMinNightsMustBeGreaterThanZero,
                                        );
                                        return;
                                      }
                                    }

                                    final maxNightsText = maxNightsController
                                        .text
                                        .trim();
                                    if (maxNightsText.isNotEmpty) {
                                      final maxNights = int.tryParse(
                                        maxNightsText,
                                      );
                                      if (maxNights == null || maxNights <= 0) {
                                        ErrorDisplayUtils.showWarningSnackBar(
                                          context,
                                          l10nValidation
                                              .priceCalendarMaxNightsMustBeGreaterThanZero,
                                        );
                                        return;
                                      }
                                    }

                                    final minDaysAdvanceText =
                                        minDaysAdvanceController.text.trim();
                                    if (minDaysAdvanceText.isNotEmpty) {
                                      final minDaysAdvance = int.tryParse(
                                        minDaysAdvanceText,
                                      );
                                      if (minDaysAdvance == null ||
                                          minDaysAdvance < 0) {
                                        ErrorDisplayUtils.showWarningSnackBar(
                                          context,
                                          l10nValidation
                                              .priceCalendarMinDaysAdvanceMustBeZeroOrMore,
                                        );
                                        return;
                                      }
                                    }

                                    final maxDaysAdvanceText =
                                        maxDaysAdvanceController.text.trim();
                                    if (maxDaysAdvanceText.isNotEmpty) {
                                      final maxDaysAdvance = int.tryParse(
                                        maxDaysAdvanceText,
                                      );
                                      if (maxDaysAdvance == null ||
                                          maxDaysAdvance <= 0) {
                                        ErrorDisplayUtils.showWarningSnackBar(
                                          context,
                                          l10nValidation
                                              .priceCalendarMaxDaysAdvanceMustBeGreaterThanZero,
                                        );
                                        return;
                                      }
                                    }

                                    // Cross-validation: min nights must be <= max nights
                                    if (minNightsText.isNotEmpty &&
                                        maxNightsText.isNotEmpty) {
                                      final minNights = int.tryParse(
                                        minNightsText,
                                      );
                                      final maxNights = int.tryParse(
                                        maxNightsText,
                                      );
                                      if (minNights != null &&
                                          maxNights != null &&
                                          minNights > maxNights) {
                                        ErrorDisplayUtils.showWarningSnackBar(
                                          context,
                                          l10nValidation
                                              .priceCalendarMinNightsCannotExceedMax,
                                        );
                                        return;
                                      }
                                    }

                                    // Cross-validation: min days advance must be <= max days advance
                                    if (minDaysAdvanceText.isNotEmpty &&
                                        maxDaysAdvanceText.isNotEmpty) {
                                      final minDaysAdvance = int.tryParse(
                                        minDaysAdvanceText,
                                      );
                                      final maxDaysAdvance = int.tryParse(
                                        maxDaysAdvanceText,
                                      );
                                      if (minDaysAdvance != null &&
                                          maxDaysAdvance != null &&
                                          minDaysAdvance > maxDaysAdvance) {
                                        ErrorDisplayUtils.showWarningSnackBar(
                                          context,
                                          l10nValidation
                                              .priceCalendarMinAdvanceCannotExceedMax,
                                        );
                                        return;
                                      }
                                    }

                                    setState(() => isProcessing = true);

                                    try {
                                      final repository = ref.read(
                                        dailyPriceRepositoryProvider,
                                      );

                                      // Parse optional fields after validation
                                      final minNights = minNightsText.isEmpty
                                          ? null
                                          : int.tryParse(minNightsText);
                                      final maxNights = maxNightsText.isEmpty
                                          ? null
                                          : int.tryParse(maxNightsText);
                                      final minDaysAdvance =
                                          minDaysAdvanceText.isEmpty
                                          ? null
                                          : int.tryParse(minDaysAdvanceText);
                                      final maxDaysAdvance =
                                          maxDaysAdvanceText.isEmpty
                                          ? null
                                          : int.tryParse(maxDaysAdvanceText);

                                      // Create price model with all fields
                                      final priceModel = DailyPriceModel(
                                        id: existingPrice?.id ?? '',
                                        unitId: widget.unit.id,
                                        date: date,
                                        price: price,
                                        available: available,
                                        blockCheckIn: blockCheckIn,
                                        blockCheckOut: blockCheckOut,
                                        minNightsOnArrival: minNights,
                                        maxNightsOnArrival: maxNights,
                                        minDaysAdvance: minDaysAdvance,
                                        maxDaysAdvance: maxDaysAdvance,
                                        createdAt:
                                            existingPrice?.createdAt ??
                                            DateTime.now(),
                                        updatedAt: DateTime.now(),
                                      );

                                      // OPTIMISTIC UPDATE
                                      _localState.updateDateOptimistically(
                                        _selectedMonth,
                                        date,
                                        priceModel,
                                        existingPrice,
                                      );

                                      // Close dialog immediately
                                      if (mounted) {
                                        dialogClosed = true;
                                        navigator.pop();
                                        ErrorDisplayUtils.showSuccessSnackBar(
                                          context,
                                          l10nValidation
                                              .priceCalendarPriceSaved,
                                        );
                                      }

                                      // Save to server in background
                                      try {
                                        await repository.setPriceForDate(
                                          unitId: widget.unit.id,
                                          date: date,
                                          price: price,
                                          priceModel: priceModel,
                                        );

                                        // Invalidate local cache first so new server data can be synced
                                        _localState.invalidateMonth(
                                          DateTime(date.year, date.month),
                                        );

                                        // Refresh from server
                                        ref.invalidate(
                                          monthlyPricesProvider(
                                            MonthlyPricesParams(
                                              unitId: widget.unit.id,
                                              month: DateTime(
                                                date.year,
                                                date.month,
                                              ),
                                            ),
                                          ),
                                        );
                                      } catch (e) {
                                        // ROLLBACK on error
                                        if (existingPrice != null) {
                                          _localState.updateDateOptimistically(
                                            _selectedMonth,
                                            date,
                                            existingPrice,
                                            priceModel,
                                          );
                                        }

                                        if (mounted) {
                                          ErrorDisplayUtils.showErrorSnackBar(
                                            this.context,
                                            e,
                                          );
                                        }
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ErrorDisplayUtils.showErrorSnackBar(
                                          this.context,
                                          e,
                                        );
                                      }
                                    } finally {
                                      if (mounted && !dialogClosed) {
                                        setState(() => isProcessing = false);
                                      }
                                    }
                                  },
                            style: FilledButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: isProcessing
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(AppLocalizations.of(context).save),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ).then((_) {
        // Dispose controllers after dialog close animation completes (~300ms)
        // Using Future.delayed instead of addPostFrameCallback because the
        // animation takes multiple frames, not just one
        Future.delayed(const Duration(milliseconds: 350), () {
          priceController.dispose();
          minNightsController.dispose();
          maxNightsController.dispose();
          minDaysAdvanceController.dispose();
          maxDaysAdvanceController.dispose();
        });
      }),
    );
  }

  void _showBulkPriceDialog() {
    final priceController = TextEditingController();
    bool isProcessing = false;
    DateTime? lastClickTime;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final l10nDialog = AppLocalizations.of(context);
          final theme = Theme.of(context);
          final isDark = theme.brightness == Brightness.dark;
          final screenHeight = MediaQuery.of(context).size.height;
          final maxDialogHeight =
              screenHeight *
              ResponsiveSpacingHelper.getDialogMaxHeightPercent(context);

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: 400,
                maxHeight: maxDialogHeight,
              ),
              decoration: BoxDecoration(
                color: context.gradients.cardBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with gradient
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: context.gradients.brandPrimary,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.euro,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10nDialog.priceCalendarSetPriceForDays(
                              _selectedDays.length,
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Builder(
                            builder: (ctx) => TextField(
                              controller: priceController,
                              decoration: InputDecorationHelper.buildDecoration(
                                labelText:
                                    l10nDialog.priceCalendarPricePerNight,
                                prefixIcon: const Icon(Icons.euro),
                                hintText: l10nDialog.priceCalendarHintExample(
                                  '50',
                                ),
                                context: ctx,
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              autofocus: true,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.outline.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 18,
                                  color: context.primaryColor,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    l10nDialog
                                        .priceCalendarWillSetPriceForAllDates,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: context.textColorSecondary,
                                          fontSize: 13,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Footer with buttons
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2D2D3A)
                          : const Color(0xFFF5F5F7),
                      border: Border(
                        top: BorderSide(color: theme.dividerColor),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isProcessing
                                ? null
                                : () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(l10nDialog.cancel),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: context.gradients.brandPrimary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: isProcessing
                                    ? null
                                    : () async {
                                        // Debounce: prevent duplicate clicks within 2 seconds
                                        final now = DateTime.now();
                                        if (lastClickTime != null &&
                                            now
                                                    .difference(lastClickTime!)
                                                    .inSeconds <
                                                2) {
                                          return;
                                        }
                                        lastClickTime = now;
                                        final navigator = Navigator.of(context);

                                        final priceText = priceController.text
                                            .trim();
                                        if (priceText.isEmpty) {
                                          ErrorDisplayUtils.showWarningSnackBar(
                                            context,
                                            l10nDialog.priceCalendarEnterPrice,
                                          );
                                          return;
                                        }

                                        final price = double.tryParse(
                                          priceText,
                                        );
                                        if (price == null || price <= 0) {
                                          ErrorDisplayUtils.showWarningSnackBar(
                                            context,
                                            l10nDialog
                                                .priceCalendarPriceMustBeGreaterThanZero,
                                          );
                                          return;
                                        }

                                        // Show confirmation dialog before bulk update
                                        final confirmed = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: Text(
                                              l10nDialog
                                                  .priceCalendarConfirmation,
                                            ),
                                            content: Text(
                                              l10nDialog
                                                  .priceCalendarConfirmSetPrice(
                                                    price.toStringAsFixed(0),
                                                    _selectedDays.length,
                                                  ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.of(
                                                  context,
                                                ).pop(false),
                                                child: Text(l10nDialog.cancel),
                                              ),
                                              ElevatedButton(
                                                onPressed: () => Navigator.of(
                                                  context,
                                                ).pop(true),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Theme.of(
                                                    context,
                                                  ).colorScheme.primary,
                                                ),
                                                child: Text(l10nDialog.confirm),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirmed != true) return;

                                        setState(() => isProcessing = true);

                                        // Get current prices for rollback
                                        final currentPrices =
                                            <DateTime, DailyPriceModel>{};
                                        final newPrices =
                                            <DateTime, DailyPriceModel>{};
                                        final cachedMonth = _localState
                                            .getMonthPrices(_selectedMonth);

                                        for (final date in _selectedDays) {
                                          final dateKey = DateTime(
                                            date.year,
                                            date.month,
                                            date.day,
                                          );
                                          final existing =
                                              cachedMonth?[dateKey];

                                          if (existing != null) {
                                            currentPrices[dateKey] = existing;
                                            newPrices[dateKey] = existing
                                                .copyWith(price: price);
                                          } else {
                                            // Create new price entry
                                            newPrices[dateKey] =
                                                DailyPriceModel(
                                                  id: '',
                                                  unitId: widget.unit.id,
                                                  date: date,
                                                  price: price,
                                                  createdAt: DateTime.now(),
                                                  updatedAt: DateTime.now(),
                                                );
                                          }
                                        }

                                        // OPTIMISTIC UPDATE: Update UI immediately
                                        _localState.updateDatesOptimistically(
                                          _selectedMonth,
                                          _selectedDays.toList(),
                                          currentPrices,
                                          newPrices,
                                        );

                                        final count = _selectedDays.length;
                                        // Save dates before clearing for API call
                                        final datesToUpdate = _selectedDays
                                            .toList();

                                        // Close dialog and clear selection immediately
                                        if (mounted) {
                                          navigator.pop();
                                          _selectedDays.clear();
                                          this.setState(
                                            () => isProcessing = false,
                                          );
                                          ErrorDisplayUtils.showSuccessSnackBar(
                                            this.context,
                                            l10nDialog
                                                .priceCalendarUpdatedPrices(
                                                  count,
                                                ),
                                          );
                                        }

                                        // Save to server in background
                                        try {
                                          final repository = ref.read(
                                            dailyPriceRepositoryProvider,
                                          );

                                          await repository
                                              .bulkPartialUpdateWithPropertyId(
                                                propertyId:
                                                    widget.unit.propertyId,
                                                unitId: widget.unit.id,
                                                dates: datesToUpdate,
                                                partialData: {'price': price},
                                              );

                                          // Refresh from server
                                          ref.invalidate(
                                            monthlyPricesProvider(
                                              MonthlyPricesParams(
                                                unitId: widget.unit.id,
                                                month: _selectedMonth,
                                              ),
                                            ),
                                          );
                                        } catch (e) {
                                          // ROLLBACK on error
                                          _localState.rollbackUpdate(
                                            _selectedMonth,
                                            currentPrices,
                                          );

                                          if (mounted) {
                                            ErrorDisplayUtils.showErrorSnackBar(
                                              this.context,
                                              e,
                                            );
                                          }
                                        }
                                      },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  alignment: Alignment.center,
                                  child: isProcessing
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        )
                                      : Text(
                                          l10nDialog.save,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ).then((_) {
      // Dispose controller after dialog close animation completes (~300ms)
      Future.delayed(
        const Duration(milliseconds: 350),
        priceController.dispose,
      );
    });
  }

  void _showBulkAvailabilityDialog() {
    bool isProcessing = false;
    // Track if dialog was closed to prevent setState on defunct StatefulBuilder
    bool dialogClosed = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final l10nDialog = AppLocalizations.of(context);
          final theme = Theme.of(context);
          final isDark = theme.brightness == Brightness.dark;
          final screenHeight = MediaQuery.of(context).size.height;
          final maxDialogHeight =
              screenHeight *
              ResponsiveSpacingHelper.getDialogMaxHeightPercent(context);

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: 400,
                maxHeight: maxDialogHeight,
              ),
              decoration: BoxDecoration(
                color: context.gradients.cardBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with gradient
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: context.gradients.brandPrimary,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.block,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10nDialog.priceCalendarAvailabilityForDays(
                              _selectedDays.length,
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.sectionDividerDark.withValues(
                                      alpha: 0.5,
                                    )
                                  : AppColors.sectionDividerLight.withValues(
                                      alpha: 0.5,
                                    ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.sectionDividerDark
                                    : AppColors.sectionDividerLight,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 18,
                                  color: context.primaryColor,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    l10nDialog.priceCalendarSelectActionForDays(
                                      _selectedDays.length,
                                    ),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: context.textColorSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Mark as available button - outlined with green icon
                          FilterChip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isProcessing)
                                  SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: context.successColor,
                                    ),
                                  )
                                else
                                  Icon(
                                    Icons.check_circle,
                                    size: 18,
                                    color: context.successColor,
                                  ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    l10nDialog.priceCalendarMarkAsAvailable,
                                  ),
                                ),
                              ],
                            ),
                            onSelected: isProcessing
                                ? null
                                : (_) async {
                                    final navigator = Navigator.of(context);

                                    setState(() => isProcessing = true);

                                    try {
                                      // Check for platform integrations and show warning
                                      final platformConnections = await ref
                                          .read(
                                            platformConnectionsForUnitProvider(
                                              widget.unit.id,
                                            ).future,
                                          );

                                      if (platformConnections.isNotEmpty &&
                                          mounted) {
                                        final platformNames =
                                            platformConnections
                                                .map(
                                                  (c) => c.platform.displayName,
                                                )
                                                .toSet()
                                                .join(', ');

                                        final sortedDates =
                                            _selectedDays.toList()..sort();
                                        final confirmed =
                                            await UnblockWarningDialog.show(
                                              context: this.context,
                                              platformName: platformNames,
                                              startDate: sortedDates.first,
                                              endDate: sortedDates.last,
                                            );

                                        if (!confirmed) {
                                          setState(() => isProcessing = false);
                                          return;
                                        }
                                      }

                                      final repository = ref.read(
                                        dailyPriceRepositoryProvider,
                                      );

                                      // Use PARTIAL update to preserve existing data
                                      // Only update 'available' field, keep custom prices
                                      await repository
                                          .bulkPartialUpdateWithPropertyId(
                                            propertyId: widget.unit.propertyId,
                                            unitId: widget.unit.id,
                                            dates: _selectedDays.toList(),
                                            partialData: {'available': true},
                                          );

                                      // Save count before clearing for snackbar message
                                      final count = _selectedDays.length;

                                      // Invalidate provider to trigger reload with fresh data
                                      ref.invalidate(
                                        monthlyPricesProvider(
                                          MonthlyPricesParams(
                                            unitId: widget.unit.id,
                                            month: _selectedMonth,
                                          ),
                                        ),
                                      );

                                      if (mounted) {
                                        dialogClosed = true;
                                        navigator.pop();
                                        // Clear selection AFTER dialog closes
                                        _selectedDays.clear();
                                        // Trigger parent widget rebuild
                                        this.setState(() {});
                                        ErrorDisplayUtils.showSuccessSnackBar(
                                          this.context,
                                          l10nDialog
                                              .priceCalendarDaysMarkedAvailable(
                                                count,
                                              ),
                                        );
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ErrorDisplayUtils.showErrorSnackBar(
                                          this.context,
                                          e,
                                        );
                                      }
                                    } finally {
                                      // Only reset if dialog still open
                                      if (mounted && !dialogClosed) {
                                        setState(() => isProcessing = false);
                                      }
                                    }
                                  },
                            backgroundColor: context.gradients.cardBackground,
                            side: BorderSide(
                              color: isDark
                                  ? AppColors.sectionDividerDark
                                  : AppColors.sectionDividerLight,
                              width: 1.5,
                            ),
                            labelStyle: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Block dates button - outlined with red icon
                          FilterChip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isProcessing)
                                  SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: context.errorColor,
                                    ),
                                  )
                                else
                                  Icon(
                                    Icons.block,
                                    size: 18,
                                    color: context.errorColor,
                                  ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    l10nDialog.priceCalendarBlockDates,
                                  ),
                                ),
                              ],
                            ),
                            onSelected: isProcessing
                                ? null
                                : (_) async {
                                    // Capture context-dependent values before async gap
                                    final navigator = Navigator.of(context);
                                    final errorColor = context.errorColor;

                                    // Show confirmation dialog before blocking dates
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (dialogContext) => AlertDialog(
                                        title: Text(
                                          l10nDialog.priceCalendarConfirmation,
                                        ),
                                        content: Text(
                                          l10nDialog
                                              .priceCalendarConfirmBlockDays(
                                                _selectedDays.length,
                                              ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(
                                              dialogContext,
                                            ).pop(false),
                                            child: Text(l10nDialog.cancel),
                                          ),
                                          ElevatedButton(
                                            onPressed: () => Navigator.of(
                                              dialogContext,
                                            ).pop(true),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: errorColor,
                                              foregroundColor: Colors.white,
                                            ),
                                            child: Text(
                                              l10nDialog.priceCalendarBlock,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirmed != true) return;

                                    setState(() => isProcessing = true);

                                    try {
                                      final repository = ref.read(
                                        dailyPriceRepositoryProvider,
                                      );

                                      // Use PARTIAL update to preserve existing data
                                      // Only update 'available' field, keep custom prices
                                      await repository
                                          .bulkPartialUpdateWithPropertyId(
                                            propertyId: widget.unit.propertyId,
                                            unitId: widget.unit.id,
                                            dates: _selectedDays.toList(),
                                            partialData: {
                                              'available': false, // Block dates
                                            },
                                          );

                                      // Save count before clearing for snackbar message
                                      final count = _selectedDays.length;

                                      // Invalidate provider to trigger reload with fresh data
                                      ref.invalidate(
                                        monthlyPricesProvider(
                                          MonthlyPricesParams(
                                            unitId: widget.unit.id,
                                            month: _selectedMonth,
                                          ),
                                        ),
                                      );

                                      if (mounted) {
                                        dialogClosed = true;
                                        navigator.pop();
                                        // Clear selection AFTER dialog closes
                                        _selectedDays.clear();
                                        // Trigger parent widget rebuild
                                        this.setState(() {});
                                        ErrorDisplayUtils.showSuccessSnackBar(
                                          this.context,
                                          l10nDialog.priceCalendarDaysBlocked(
                                            count,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ErrorDisplayUtils.showErrorSnackBar(
                                          this.context,
                                          e,
                                        );
                                      }
                                    } finally {
                                      // Only reset if dialog still open
                                      if (mounted && !dialogClosed) {
                                        setState(() => isProcessing = true);
                                      }
                                    }
                                  },
                            backgroundColor: context.gradients.cardBackground,
                            side: BorderSide(
                              color: isDark
                                  ? AppColors.sectionDividerDark
                                  : AppColors.sectionDividerLight,
                              width: 1.5,
                            ),
                            labelStyle: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Block check-in button - outlined with amber icon
                          FilterChip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                isProcessing
                                    ? SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: context.warningColor,
                                        ),
                                      )
                                    : Icon(
                                        Icons.login,
                                        size: 18,
                                        color: context.warningColor,
                                      ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    l10nDialog.priceCalendarBlockCheckInButton,
                                  ),
                                ),
                              ],
                            ),
                            onSelected: isProcessing
                                ? null
                                : (_) async {
                                    final navigator = Navigator.of(context);

                                    setState(() => isProcessing = true);

                                    try {
                                      final repository = ref.read(
                                        dailyPriceRepositoryProvider,
                                      );

                                      // Use PARTIAL update to preserve existing data
                                      // Only update 'block_checkin' field, keep prices
                                      await repository
                                          .bulkPartialUpdateWithPropertyId(
                                            propertyId: widget.unit.propertyId,
                                            unitId: widget.unit.id,
                                            dates: _selectedDays.toList(),
                                            partialData: {
                                              'block_checkin':
                                                  true, // Block check-in
                                            },
                                          );

                                      // Invalidate provider to trigger reload with fresh data
                                      ref.invalidate(
                                        monthlyPricesProvider(
                                          MonthlyPricesParams(
                                            unitId: widget.unit.id,
                                            month: _selectedMonth,
                                          ),
                                        ),
                                      );

                                      if (mounted) {
                                        dialogClosed = true;
                                        navigator.pop();
                                        // Clear selection AFTER dialog closes
                                        _selectedDays.clear();
                                        // Trigger parent widget rebuild
                                        this.setState(() {});
                                        ErrorDisplayUtils.showSuccessSnackBar(
                                          this.context,
                                          l10nDialog
                                              .priceCalendarCheckInBlockedForDays,
                                        );
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ErrorDisplayUtils.showErrorSnackBar(
                                          this.context,
                                          e,
                                        );
                                      }
                                    } finally {
                                      // Only reset if dialog still open
                                      if (mounted && !dialogClosed) {
                                        setState(() => isProcessing = false);
                                      }
                                    }
                                  },
                            backgroundColor: context.gradients.cardBackground,
                            side: BorderSide(
                              color: isDark
                                  ? AppColors.sectionDividerDark
                                  : AppColors.sectionDividerLight,
                              width: 1.5,
                            ),
                            labelStyle: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Block check-out button - outlined with amber icon
                          FilterChip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                isProcessing
                                    ? SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: context.warningColor,
                                        ),
                                      )
                                    : Icon(
                                        Icons.logout,
                                        size: 18,
                                        color: context.warningColor,
                                      ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    l10nDialog.priceCalendarBlockCheckOutButton,
                                  ),
                                ),
                              ],
                            ),
                            onSelected: isProcessing
                                ? null
                                : (_) async {
                                    final navigator = Navigator.of(context);

                                    setState(() => isProcessing = true);

                                    try {
                                      final repository = ref.read(
                                        dailyPriceRepositoryProvider,
                                      );

                                      // Use PARTIAL update to preserve existing data
                                      // Only update 'block_checkout' field, keep prices
                                      await repository
                                          .bulkPartialUpdateWithPropertyId(
                                            propertyId: widget.unit.propertyId,
                                            unitId: widget.unit.id,
                                            dates: _selectedDays.toList(),
                                            partialData: {
                                              'block_checkout':
                                                  true, // Block check-out
                                            },
                                          );

                                      // Invalidate provider to trigger reload with fresh data
                                      ref.invalidate(
                                        monthlyPricesProvider(
                                          MonthlyPricesParams(
                                            unitId: widget.unit.id,
                                            month: _selectedMonth,
                                          ),
                                        ),
                                      );

                                      if (mounted) {
                                        dialogClosed = true;
                                        navigator.pop();
                                        // Clear selection AFTER dialog closes
                                        _selectedDays.clear();
                                        // Trigger parent widget rebuild
                                        this.setState(() {});
                                        ErrorDisplayUtils.showSuccessSnackBar(
                                          this.context,
                                          l10nDialog
                                              .priceCalendarCheckOutBlockedForDays,
                                        );
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ErrorDisplayUtils.showErrorSnackBar(
                                          this.context,
                                          e,
                                        );
                                      }
                                    } finally {
                                      // Only reset if dialog still open
                                      if (mounted && !dialogClosed) {
                                        setState(() => isProcessing = false);
                                      }
                                    }
                                  },
                            backgroundColor: context.gradients.cardBackground,
                            side: BorderSide(
                              color: isDark
                                  ? AppColors.sectionDividerDark
                                  : AppColors.sectionDividerLight,
                              width: 1.5,
                            ),
                            labelStyle: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Cancel button - same style as other buttons
                          FilterChip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.close,
                                  size: 18,
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(child: Text(l10nDialog.cancel)),
                              ],
                            ),
                            onSelected: isProcessing
                                ? null
                                : (_) => Navigator.of(context).pop(),
                            backgroundColor: context.gradients.cardBackground,
                            side: BorderSide(
                              color: isDark
                                  ? AppColors.sectionDividerDark
                                  : AppColors.sectionDividerLight,
                              width: 1.5,
                            ),
                            labelStyle: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<DateTime> _generateMonthList() {
    final List<DateTime> months = [];
    final now = DateTime.now();
    final startDate = DateTime(now.year - 1);
    final endDate = DateTime(now.year + 2, 12);

    DateTime current = startDate;
    while (current.isBefore(endDate) || current.isAtSameMomentAs(endDate)) {
      months.add(current);
      current = DateTime(current.year, current.month + 1);
    }

    return months;
  }
}
