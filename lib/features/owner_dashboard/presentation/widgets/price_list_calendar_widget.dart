import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../shared/models/daily_price_model.dart';
import '../../../../shared/models/unit_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/gradient_extensions.dart';
import '../../../../core/utils/input_decoration_helper.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../providers/price_list_provider.dart';
import '../state/price_calendar_state.dart';
import 'calendar/calendar_day_cell.dart';

/// BedBooking-style Price List Calendar
/// Displays one month at a time with dropdown selector
/// Shows pricing, availability, and all BedBooking features
///
/// Now with:
/// - Optimistic updates for instant UI feedback
/// - Local state cache for better performance
/// - Undo/Redo functionality
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

  // Local state cache with optimistic updates and undo/redo
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
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: _showBulkPriceDialog,
            icon: const Icon(Icons.euro),
            label: const Text('Postavi cijenu'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15), // Same as Save button
              backgroundColor: context.primaryColor,
              foregroundColor: Colors.white,
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12), // Consistent with inputs
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _showBulkAvailabilityDialog,
            icon: const Icon(Icons.block),
            label: const Text('Dostupnost'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15), // Same as Save button
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12), // Consistent with inputs
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
            label: const Text('Postavi cijenu'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15), // Same as Save button
              backgroundColor: context.primaryColor,
              foregroundColor: Colors.white,
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12), // Consistent with inputs
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
            label: const Text('Dostupnost'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15), // Same as Save button
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12), // Consistent with inputs
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(bool isMobile) {
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
            gradient: context.gradients.sectionBackground,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: context.gradients.sectionBorder,
              width: 1.5,
            ),
          ),
          padding: EdgeInsets.all(isMobile ? 16 : 20),
          child: isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Month selector
                    DropdownButtonFormField<DateTime>(
                      // Safe: _selectedMonth is initialized in initState() before first build
                      initialValue: _selectedMonth,
                      decoration: InputDecoration(
                        labelText: 'Odaberi mjesec',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.calendar_month),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
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
                          // Reset loading state after month data loads
                          Future.microtask(() {
                            if (mounted) {
                              setState(() => _isLoadingMonthChange = false);
                            }
                          });
                        }
                      },
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
                        _bulkEditMode
                            ? Icons.check_box
                            : Icons.check_box_outline_blank,
                      ),
                      label: Text(_bulkEditMode ? 'Odustani' : 'Bulk Edit'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _bulkEditMode
                            ? context.primaryColor
                            : null,
                        side: _bulkEditMode
                            ? BorderSide(color: context.primaryColor, width: 2)
                            : null,
                        padding: const EdgeInsets.symmetric(vertical: 15), // Same as Save button
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12), // Consistent with inputs
                        ),
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Month selector
                    SizedBox(
                      width: 250, // Increased by 100px for better readability
                      child: DropdownButtonFormField<DateTime>(
                        // Safe: _selectedMonth is initialized in initState() before first build
                        initialValue: _selectedMonth,
                        decoration: InputDecoration(
                          labelText: 'Odaberi mjesec',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.calendar_month),
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
                            // Reset loading state after month data loads
                            Future.microtask(() {
                              if (mounted) {
                                setState(() => _isLoadingMonthChange = false);
                              }
                            });
                          }
                        },
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Bulk edit mode toggle
                    SizedBox(
                      width: 180, // Same width as Save button
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _bulkEditMode = !_bulkEditMode;
                            _selectedDays.clear();
                          });
                        },
                        icon: Icon(
                          _bulkEditMode
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                        ),
                        label: Text(_bulkEditMode ? 'Odustani' : 'Bulk Edit'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _bulkEditMode
                              ? context.primaryColor
                              : null,
                          side: _bulkEditMode
                              ? BorderSide(color: context.primaryColor, width: 2)
                              : null,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 20, // Match dropdown height
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12), // Consistent with inputs
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildSelectionCounter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.primaryColor, width: 2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.primaryColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${_selectedDays.length} ${_selectedDays.length == 1 ? 'dan' : 'dana'} odabrano',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: () {
              setState(_selectedDays.clear);
            },
            icon: const Icon(Icons.close, size: 18),
            label: const Text('Očisti'),
            style: TextButton.styleFrom(foregroundColor: context.primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildBulkSelectionButtons() {
    final daysInMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
      0,
    ).day;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
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
            icon: const Icon(Icons.select_all, size: 18),
            label: const Text('Selektuj sve dane'),
            style: OutlinedButton.styleFrom(
              foregroundColor: context.primaryColor,
              side: BorderSide(color: context.primaryColor, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _selectedDays.isEmpty
                ? null
                : () {
                    setState(_selectedDays.clear);
                  },
            icon: const Icon(Icons.deselect, size: 18),
            label: const Text('Deselektuj sve'),
            style: OutlinedButton.styleFrom(
              foregroundColor: context.textColorSecondary,
              side: BorderSide(color: context.borderColor, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
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
                gradient: context.gradients.sectionBackground,
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
                  Divider(
                    color: context.borderColor.withValues(alpha: 0.5),
                  ),
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
                            // Update local cache with server data
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _localState.setMonthPrices(
                                _selectedMonth,
                                priceMap,
                              );
                            });

                            // Use local cache for display (supports optimistic updates)
                            final displayMap =
                                _localState.getMonthPrices(_selectedMonth) ??
                                priceMap;

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
                                  isSelected: _selectedDays.contains(date),
                                  isBulkEditMode: _bulkEditMode,
                                  onTap: () => _onDayCellTap(date),
                                  isMobile: isMobile,
                                  isSmallMobile: isSmallMobile,
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
                          error: (error, stack) => Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    size: 48,
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Greška pri učitavanju cijena',
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
                          ),
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
    const weekdays = ['Pon', 'Uto', 'Sri', 'Čet', 'Pet', 'Sub', 'Ned'];

    return Row(
      children: weekdays.map((day) {
        return Expanded(
          child: Center(
            child: Text(
              day,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.textColorSecondary,
              ),
            ),
          ),
        );
      }).toList(),
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
    final weekendPriceController = TextEditingController(
      text: existingPrice?.weekendPrice?.toStringAsFixed(0) ?? '',
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
              child: Container(
                width: isMobile ? screenWidth * 0.95 : 500,
                constraints: BoxConstraints(
                  maxHeight: isMobile ? screenHeight * 0.85 : screenHeight * 0.8,
                ),
                decoration: BoxDecoration(
                  gradient: context.gradients.sectionBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: context.gradients.sectionBorder
                        .withAlpha((0.5 * 255).toInt()),
                  ),
                  boxShadow:
                      isDark ? AppShadows.elevation4Dark : AppShadows.elevation4,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Gradient Header
                    Container(
                      padding: EdgeInsets.all(isMobile ? 16 : 20),
                      decoration: BoxDecoration(
                        gradient: context.gradients.brandPrimary,
                        borderRadius:
                            const BorderRadius.vertical(top: Radius.circular(11)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha((0.2 * 255).toInt()),
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
                                  'Uredi datum',
                                  style: TextStyle(
                                    fontSize: isMobile ? 16 : 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  DateFormat('d. MMMM yyyy.', 'hr').format(date),
                                  style: TextStyle(
                                    fontSize: isMobile ? 12 : 14,
                                    color: Colors.white.withAlpha((0.9 * 255).toInt()),
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
                                  'CIJENA',
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
                                labelText: 'Osnovna cijena po noći (€)',
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
                                  'DOSTUPNOST',
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
                                'Dostupno',
                                style: TextStyle(fontSize: isMobile ? 14 : null),
                              ),
                              value: available,
                              onChanged: (value) =>
                                  setState(() => available = value),
                              contentPadding: EdgeInsets.zero,
                            ),
                            SwitchListTile(
                              title: Text(
                                'Blokiraj prijavu (check-in)',
                                style: TextStyle(fontSize: isMobile ? 14 : null),
                              ),
                              subtitle: Text(
                                'Gosti ne mogu započeti rezervaciju',
                                style: TextStyle(fontSize: isMobile ? 12 : null),
                              ),
                              value: blockCheckIn,
                              onChanged: (value) =>
                                  setState(() => blockCheckIn = value),
                              contentPadding: EdgeInsets.zero,
                            ),
                            SwitchListTile(
                              title: Text(
                                'Blokiraj odjavu (check-out)',
                                style: TextStyle(fontSize: isMobile ? 14 : null),
                              ),
                              subtitle: Text(
                                'Gosti ne mogu završiti rezervaciju',
                                style: TextStyle(fontSize: isMobile ? 12 : null),
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
                                  'Napredne opcije',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.tertiary,
                                  ),
                                ),
                                subtitle: Text(
                                  'Vikend cijena, min/max noći, unaprijed',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                children: [
                                  // Weekend price
                                  TextField(
                                    controller: weekendPriceController,
                                    decoration:
                                        InputDecorationHelper.buildDecoration(
                                      labelText: 'Vikend cijena (€)',
                                      hintText: 'Npr. 120',
                                      prefixIcon: const Icon(Icons.weekend),
                                      isMobile: isMobile,
                                      context: context,
                                    ),
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                  ),
                                  SizedBox(height: isMobile ? 12 : 16),
                                  // Min/Max nights row
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: minNightsController,
                                          decoration: InputDecorationHelper
                                              .buildDecoration(
                                            labelText: 'Min. noći',
                                            hintText: 'npr. 2',
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
                                          decoration: InputDecorationHelper
                                              .buildDecoration(
                                            labelText: 'Max. noći',
                                            hintText: 'npr. 14',
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
                                          decoration: InputDecorationHelper
                                              .buildDecoration(
                                            labelText: 'Min. dana unaprijed',
                                            hintText: 'npr. 1',
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
                                          decoration: InputDecorationHelper
                                              .buildDecoration(
                                            labelText: 'Max. dana unaprijed',
                                            hintText: 'npr. 365',
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
                            color: theme.dividerColor.withAlpha((0.3 * 255).toInt()),
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
                                      final messenger =
                                          ScaffoldMessenger.of(context);

                                      // Show confirmation dialog before deleting
                                      final confirmed = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Potvrda brisanja'),
                                          content: const Text(
                                            'Da li ste sigurni da želite obrisati custom cijenu? '
                                            'Datum će biti vraćen na osnovnu cijenu.',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(context)
                                                      .pop(false),
                                              child: const Text('Odustani'),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(context)
                                                      .pop(true),
                                              style: TextButton.styleFrom(
                                                foregroundColor: AppColors.error,
                                              ),
                                              child: const Text('Obriši'),
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
                                                  date.year, date.month),
                                            ),
                                          ),
                                        );

                                        if (mounted) {
                                          dialogClosed = true;
                                          navigator.pop();
                                          messenger.showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Vraćeno na osnovnu cijenu'),
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          messenger.showSnackBar(
                                            SnackBar(
                                              content: Text('Greška: $e'),
                                              backgroundColor: AppColors.error,
                                            ),
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
                              child: const Text('Obriši'),
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
                            child: const Text('Odustani'),
                          ),
                          const SizedBox(width: 12),
                          FilledButton(
                            onPressed: isProcessing
                                ? null
                                : () async {
                                    // Debounce: prevent duplicate clicks
                                    final now = DateTime.now();
                                    if (lastClickTime != null &&
                                        now.difference(lastClickTime!)
                                                .inSeconds <
                                            2) {
                                      return;
                                    }
                                    lastClickTime = now;

                                    final messenger =
                                        ScaffoldMessenger.of(context);
                                    final navigator = Navigator.of(context);

                                    // Save price data
                                    final priceText =
                                        priceController.text.trim();
                                    if (priceText.isEmpty) {
                                      messenger.showSnackBar(
                                        const SnackBar(
                                            content: Text('Unesite cijenu')),
                                      );
                                      return;
                                    }

                                    final price = double.tryParse(priceText);
                                    if (price == null || price <= 0) {
                                      messenger.showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Cijena mora biti veća od 0'),
                                        ),
                                      );
                                      return;
                                    }

                                    // Validate optional fields
                                    final weekendPriceText =
                                        weekendPriceController.text.trim();
                                    if (weekendPriceText.isNotEmpty) {
                                      final weekendPrice =
                                          double.tryParse(weekendPriceText);
                                      if (weekendPrice == null ||
                                          weekendPrice <= 0) {
                                        messenger.showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Vikend cijena mora biti veća od 0',
                                            ),
                                          ),
                                        );
                                        return;
                                      }
                                    }

                                    final minNightsText =
                                        minNightsController.text.trim();
                                    if (minNightsText.isNotEmpty) {
                                      final minNights =
                                          int.tryParse(minNightsText);
                                      if (minNights == null || minNights <= 0) {
                                        messenger.showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Min. noći mora biti veće od 0',
                                            ),
                                          ),
                                        );
                                        return;
                                      }
                                    }

                                    final maxNightsText =
                                        maxNightsController.text.trim();
                                    if (maxNightsText.isNotEmpty) {
                                      final maxNights =
                                          int.tryParse(maxNightsText);
                                      if (maxNights == null || maxNights <= 0) {
                                        messenger.showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Max. noći mora biti veće od 0',
                                            ),
                                          ),
                                        );
                                        return;
                                      }
                                    }

                                    final minDaysAdvanceText =
                                        minDaysAdvanceController.text.trim();
                                    if (minDaysAdvanceText.isNotEmpty) {
                                      final minDaysAdvance =
                                          int.tryParse(minDaysAdvanceText);
                                      if (minDaysAdvance == null ||
                                          minDaysAdvance < 0) {
                                        messenger.showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Min. dana unaprijed mora biti 0 ili više',
                                            ),
                                          ),
                                        );
                                        return;
                                      }
                                    }

                                    final maxDaysAdvanceText =
                                        maxDaysAdvanceController.text.trim();
                                    if (maxDaysAdvanceText.isNotEmpty) {
                                      final maxDaysAdvance =
                                          int.tryParse(maxDaysAdvanceText);
                                      if (maxDaysAdvance == null ||
                                          maxDaysAdvance <= 0) {
                                        messenger.showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Max. dana unaprijed mora biti veće od 0',
                                            ),
                                          ),
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
                                      final weekendPrice =
                                          weekendPriceText.isEmpty
                                              ? null
                                              : double.tryParse(
                                                  weekendPriceText);
                                      final minNights = minNightsText.isEmpty
                                          ? null
                                          : int.tryParse(minNightsText);
                                      final maxNights = maxNightsText.isEmpty
                                          ? null
                                          : int.tryParse(maxNightsText);
                                      final minDaysAdvance =
                                          minDaysAdvanceText.isEmpty
                                              ? null
                                              : int.tryParse(
                                                  minDaysAdvanceText);
                                      final maxDaysAdvance =
                                          maxDaysAdvanceText.isEmpty
                                              ? null
                                              : int.tryParse(
                                                  maxDaysAdvanceText);

                                      // Create price model with all fields
                                      final priceModel = DailyPriceModel(
                                        id: existingPrice?.id ?? '',
                                        unitId: widget.unit.id,
                                        date: date,
                                        price: price,
                                        available: available,
                                        blockCheckIn: blockCheckIn,
                                        blockCheckOut: blockCheckOut,
                                        weekendPrice: weekendPrice,
                                        minNightsOnArrival: minNights,
                                        maxNightsOnArrival: maxNights,
                                        minDaysAdvance: minDaysAdvance,
                                        maxDaysAdvance: maxDaysAdvance,
                                        createdAt: existingPrice?.createdAt ??
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
                                        messenger.showSnackBar(
                                          const SnackBar(
                                            content: Text('Cijena spremljena'),
                                            duration: Duration(seconds: 2),
                                          ),
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

                                        // Refresh from server
                                        ref.invalidate(
                                          monthlyPricesProvider(
                                            MonthlyPricesParams(
                                              unitId: widget.unit.id,
                                              month: DateTime(
                                                  date.year, date.month),
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
                                          messenger.showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  'Greška pri spremanju: $e'),
                                              backgroundColor:
                                                  context.errorColor,
                                              action: SnackBarAction(
                                                label: 'Poništi',
                                                onPressed: _localState.undo,
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        messenger.showSnackBar(
                                          SnackBar(
                                            content:
                                                Text('Greška validacije: $e'),
                                            backgroundColor: context.errorColor,
                                          ),
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
                                : const Text('Spremi'),
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
          weekendPriceController.dispose();
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
          return AlertDialog(
            title: Text('Postavi cijenu za ${_selectedDays.length} dana'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(
                    labelText: 'Cijena po noći (€)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.euro),
                    hintText: 'Npr. 50',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 16),
                Text(
                  'Postavit će se cijena za sve odabrane datume',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.textColorSecondary,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isProcessing
                    ? null
                    : () => Navigator.of(context).pop(),
                child: const Text('Otkaži'),
              ),
              ElevatedButton(
                onPressed: isProcessing
                    ? null
                    : () async {
                        // Debounce: prevent duplicate clicks within 2 seconds
                        final now = DateTime.now();
                        if (lastClickTime != null &&
                            now.difference(lastClickTime!).inSeconds < 2) {
                          return;
                        }
                        lastClickTime = now;
                        final messenger = ScaffoldMessenger.of(context);
                        final navigator = Navigator.of(context);

                        final priceText = priceController.text.trim();
                        if (priceText.isEmpty) {
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Unesite cijenu')),
                          );
                          return;
                        }

                        final price = double.tryParse(priceText);
                        if (price == null || price <= 0) {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Cijena mora biti veća od 0'),
                            ),
                          );
                          return;
                        }

                        // Show confirmation dialog before bulk update
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Potvrda'),
                            content: Text(
                              'Jeste li sigurni da želite postaviti cijenu €${price.toStringAsFixed(0)} za ${_selectedDays.length} ${_selectedDays.length == 1 ? 'dan' : 'dana'}?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text('Otkaži'),
                              ),
                              ElevatedButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.primary,
                                ),
                                child: const Text('Potvrdi'),
                              ),
                            ],
                          ),
                        );

                        if (confirmed != true) return;

                        setState(() => isProcessing = true);

                        // Get current prices for rollback
                        final currentPrices = <DateTime, DailyPriceModel>{};
                        final newPrices = <DateTime, DailyPriceModel>{};
                        final cachedMonth = _localState.getMonthPrices(
                          _selectedMonth,
                        );

                        for (final date in _selectedDays) {
                          final dateKey = DateTime(
                            date.year,
                            date.month,
                            date.day,
                          );
                          final existing = cachedMonth?[dateKey];

                          if (existing != null) {
                            currentPrices[dateKey] = existing;
                            newPrices[dateKey] = existing.copyWith(
                              price: price,
                            );
                          } else {
                            // Create new price entry
                            newPrices[dateKey] = DailyPriceModel(
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
                        final datesToUpdate = _selectedDays.toList();

                        // Close dialog and clear selection immediately
                        if (mounted) {
                          navigator.pop();
                          _selectedDays.clear();
                          this.setState(() => isProcessing = false);
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('Ažurirano $count cijena'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }

                        // Save to server in background
                        try {
                          final repository = ref.read(
                            dailyPriceRepositoryProvider,
                          );

                          await repository.bulkPartialUpdate(
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
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('Greška: $e'),
                                backgroundColor: AppColors.error,
                                action: SnackBarAction(
                                  label: 'Poništi',
                                  onPressed: _localState.undo,
                                ),
                              ),
                            );
                          }
                        }
                      },
                child: isProcessing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Spremi'),
              ),
            ],
          );
        },
      ),
    ).then((_) {
      // Dispose controller after dialog close animation completes (~300ms)
      Future.delayed(const Duration(milliseconds: 350), priceController.dispose);
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
          return AlertDialog(
            title: Text('Dostupnost za ${_selectedDays.length} dana'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Odaberite akciju za ${_selectedDays.length} ${_selectedDays.length == 1 ? 'dan' : 'dana'}:',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: isProcessing
                      ? null
                      : () async {
                          final navigator = Navigator.of(context);
                          final messenger = ScaffoldMessenger.of(context);

                          setState(() => isProcessing = true);

                          try {
                            final repository = ref.read(
                              dailyPriceRepositoryProvider,
                            );

                            // Use PARTIAL update to preserve existing data
                            // Only update 'available' field, keep custom prices
                            await repository.bulkPartialUpdate(
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
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '$count ${count == 1 ? 'dan označen' : 'dana označeno'} kao dostupno',
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('Greška: $e'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          } finally {
                            // Only reset if dialog still open
                            if (mounted && !dialogClosed) {
                              setState(() => isProcessing = false);
                            }
                          }
                        },
                  icon: isProcessing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle),
                  label: const Text('Označi kao dostupno'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.successColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: isProcessing
                      ? null
                      : () async {
                          // Show confirmation dialog before blocking dates
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Potvrda'),
                              content: Text(
                                'Jeste li sigurni da želite blokirati ${_selectedDays.length} ${_selectedDays.length == 1 ? 'dan' : 'dana'}?\n\n'
                                'Ovi datumi će biti označeni kao nedostupni.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text('Otkaži'),
                                ),
                                ElevatedButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: context.errorColor,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Blokiraj'),
                                ),
                              ],
                            ),
                          );

                          if (confirmed != true) return;

                          final navigator = Navigator.of(context);
                          final messenger = ScaffoldMessenger.of(context);

                          setState(() => isProcessing = true);

                          try {
                            final repository = ref.read(
                              dailyPriceRepositoryProvider,
                            );

                            // Use PARTIAL update to preserve existing data
                            // Only update 'available' field, keep custom prices
                            await repository.bulkPartialUpdate(
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
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '$count ${count == 1 ? 'dan blokiran' : 'dana blokirano'}',
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('Greška: $e'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          } finally {
                            // Only reset if dialog still open
                            if (mounted && !dialogClosed) {
                              setState(() => isProcessing = false);
                            }
                          }
                        },
                  icon: isProcessing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.block),
                  label: const Text('Blokiraj datume'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.errorColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: isProcessing
                      ? null
                      : () async {
                          final navigator = Navigator.of(context);
                          final messenger = ScaffoldMessenger.of(context);

                          setState(() => isProcessing = true);

                          try {
                            final repository = ref.read(
                              dailyPriceRepositoryProvider,
                            );

                            // Use PARTIAL update to preserve existing data
                            // Only update 'block_checkin' field, keep prices
                            await repository.bulkPartialUpdate(
                              unitId: widget.unit.id,
                              dates: _selectedDays.toList(),
                              partialData: {
                                'block_checkin': true, // Block check-in
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
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Check-in blokiran za odabrane dane',
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('Greška: $e'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          } finally {
                            // Only reset if dialog still open
                            if (mounted && !dialogClosed) {
                              setState(() => isProcessing = false);
                            }
                          }
                        },
                  icon: const Icon(Icons.login),
                  label: const Text('Blokiraj check-in'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: isProcessing
                      ? null
                      : () async {
                          final navigator = Navigator.of(context);
                          final messenger = ScaffoldMessenger.of(context);

                          setState(() => isProcessing = true);

                          try {
                            final repository = ref.read(
                              dailyPriceRepositoryProvider,
                            );

                            // Use PARTIAL update to preserve existing data
                            // Only update 'block_checkout' field, keep prices
                            await repository.bulkPartialUpdate(
                              unitId: widget.unit.id,
                              dates: _selectedDays.toList(),
                              partialData: {
                                'block_checkout': true, // Block check-out
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
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Check-out blokiran za odabrane dane',
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('Greška: $e'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          } finally {
                            // Only reset if dialog still open
                            if (mounted && !dialogClosed) {
                              setState(() => isProcessing = false);
                            }
                          }
                        },
                  icon: const Icon(Icons.logout),
                  label: const Text('Blokiraj check-out'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isProcessing
                    ? null
                    : () => Navigator.of(context).pop(),
                child: const Text('Zatvori'),
              ),
            ],
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
