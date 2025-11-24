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

          // Undo/Redo bar
          if (_localState.canUndo || _localState.canRedo) _buildUndoRedoBar(),

          if (_localState.canUndo || _localState.canRedo)
            const SizedBox(height: 12),

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

  Widget _buildUndoRedoBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.history, size: 18, color: context.textColorSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _localState.lastActionDescription ?? 'Historija akcija',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.textColorSecondary,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.undo, size: 20),
            onPressed: _localState.canUndo ? _localState.undo : null,
            tooltip: 'Poništi (Ctrl+Z)',
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.redo, size: 20),
            onPressed: _localState.canRedo ? _localState.redo : null,
            tooltip: 'Ponovi (Ctrl+Shift+Z)',
            color: Theme.of(context).colorScheme.primary,
          ),
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
                borderRadius: BorderRadius.circular(10), // Same as Save button
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
                borderRadius: BorderRadius.circular(10), // Same as Save button
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
                borderRadius: BorderRadius.circular(10), // Same as Save button
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
                borderRadius: BorderRadius.circular(10), // Same as Save button
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
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: isDark
                  ? const [
                      Color(0xFF1A1A1A), // veryDarkGray
                      Color(0xFF1F1F1F),
                      Color(0xFF242424),
                      Color(0xFF292929),
                      Color(0xFF2D2D2D), // mediumDarkGray
                    ]
                  : const [
                      Color(0xFFF0F0F0), // Lighter grey
                      Color(0xFFF2F2F2),
                      Color(0xFFF5F5F5),
                      Color(0xFFF8F8F8),
                      Color(0xFFFAFAFA), // Very light grey
                    ],
              stops: const [0.0, 0.125, 0.25, 0.375, 0.5],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: context.borderColor.withOpacity(0.5),
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
                          borderRadius: BorderRadius.circular(10), // Same as Save button
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
                            borderRadius: BorderRadius.circular(10), // Same as Save button
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
        color: context.primaryColor.withOpacity(0.1),
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
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: isDark
                      ? const [
                          Color(0xFF1A1A1A), // veryDarkGray
                          Color(0xFF1F1F1F),
                          Color(0xFF242424),
                          Color(0xFF292929),
                          Color(0xFF2D2D2D), // mediumDarkGray
                        ]
                      : const [
                          Color(0xFFF0F0F0), // Lighter grey
                          Color(0xFFF2F2F2),
                          Color(0xFFF5F5F5),
                          Color(0xFFF8F8F8),
                          Color(0xFFFAFAFA), // Very light grey
                        ],
                  stops: const [0.0, 0.125, 0.25, 0.375, 0.5],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: context.borderColor.withOpacity(0.5),
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
                  const Divider(),
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
    final notesController = TextEditingController(
      text: existingPrice?.notes ?? '',
    );

    bool available = existingPrice?.available ?? true;
    bool blockCheckIn = existingPrice?.blockCheckIn ?? false;
    bool blockCheckOut = existingPrice?.blockCheckOut ?? false;
    bool isImportant = existingPrice?.isImportant ?? false;

    if (!mounted) return;

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = screenWidth < 600;

    // Processing state to prevent duplicate button clicks
    bool isProcessing = false;
    DateTime? lastClickTime;

    // Show dialog and dispose controllers when it closes
    unawaited(
      showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                'Uredi datum - ${DateFormat('d.M.yyyy').format(date)}',
                style: TextStyle(fontSize: isMobile ? 16 : null),
              ),
              contentPadding: EdgeInsets.fromLTRB(
                isMobile ? 16 : 24,
                isMobile ? 12 : 20,
                isMobile ? 16 : 24,
                isMobile ? 12 : 20,
              ),
              content: SizedBox(
                height: isMobile ? screenHeight * 0.72 : screenHeight * 0.7,
                width: isMobile ? screenWidth * 0.9 : 600,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Price section
                      Text(
                        'Cijene',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: isMobile ? 14 : null,
                            ),
                      ),
                      SizedBox(height: isMobile ? 6 : 8),
                      TextField(
                        controller: priceController,
                        decoration: InputDecoration(
                          labelText: 'Osnovna cijena po noći (€)',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.euro),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 12 : 16,
                            vertical: isMobile ? 12 : 16,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                      SizedBox(height: isMobile ? 8 : 12),
                      TextField(
                        controller: weekendPriceController,
                        decoration: InputDecoration(
                          labelText: 'Vikend cijena (opciono)',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.weekend),
                          hintText: 'Npr. 120',
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 12 : 16,
                            vertical: isMobile ? 12 : 16,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),

                      SizedBox(height: isMobile ? 16 : 24),

                      // Availability section
                      Text(
                        'Dostupnost',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: isMobile ? 14 : null,
                            ),
                      ),
                      SwitchListTile(
                        title: Text(
                          'Dostupno',
                          style: TextStyle(fontSize: isMobile ? 14 : null),
                        ),
                        value: available,
                        onChanged: (value) => setState(() => available = value),
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

                      // Length of stay restrictions
                      Text(
                        'Ograničenja boravka',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: isMobile ? 14 : null,
                            ),
                      ),
                      SizedBox(height: isMobile ? 6 : 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: minNightsController,
                              decoration: InputDecoration(
                                labelText: 'Min. noći',
                                border: const OutlineInputBorder(),
                                hintText: 'npr. 2',
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: isMobile ? 12 : 16,
                                  vertical: isMobile ? 12 : 16,
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                            ),
                          ),
                          SizedBox(width: isMobile ? 8 : 12),
                          Expanded(
                            child: TextField(
                              controller: maxNightsController,
                              decoration: InputDecoration(
                                labelText: 'Max. noći',
                                border: const OutlineInputBorder(),
                                hintText: 'npr. 14',
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: isMobile ? 12 : 16,
                                  vertical: isMobile ? 12 : 16,
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: isMobile ? 16 : 24),

                      // Other options
                      SwitchListTile(
                        title: Text(
                          'Označi kao važno',
                          style: TextStyle(fontSize: isMobile ? 14 : null),
                        ),
                        subtitle: Text(
                          'Istakni ovaj datum u kalendaru',
                          style: TextStyle(fontSize: isMobile ? 12 : null),
                        ),
                        value: isImportant,
                        onChanged: (value) =>
                            setState(() => isImportant = value),
                        contentPadding: EdgeInsets.zero,
                      ),

                      SizedBox(height: isMobile ? 16 : 24),

                      // Notes section
                      Text(
                        'Napomene',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: isMobile ? 14 : null,
                            ),
                      ),
                      SizedBox(height: isMobile ? 6 : 8),
                      TextField(
                        controller: notesController,
                        decoration: InputDecoration(
                          labelText: 'Napomene za ovaj dan',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.notes),
                          hintText: 'Npr. Vjenčanje, poseban događaj...',
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 12 : 16,
                            vertical: isMobile ? 12 : 16,
                          ),
                        ),
                        maxLines: isMobile ? 2 : 3,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                if (existingPrice != null)
                  TextButton(
                    onPressed: isProcessing
                        ? null
                        : () async {
                            final navigator = Navigator.of(context);
                            final messenger = ScaffoldMessenger.of(context);

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
                                        Navigator.of(context).pop(false),
                                    child: const Text('Odustani'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
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

                              // This small delay ensures data is available when provider refetches

                              // Invalidate provider to trigger reload with fresh data
                              ref.invalidate(
                                monthlyPricesProvider(
                                  MonthlyPricesParams(
                                    unitId: widget.unit.id,
                                    month: DateTime(date.year, date.month),
                                  ),
                                ),
                              );

                              if (mounted) {
                                navigator.pop();
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Vraćeno na osnovnu cijenu'),
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
                              if (mounted) {
                                setState(() => isProcessing = false);
                              }
                            }
                          },
                    child: const Text('Obriši'),
                  ),
                TextButton(
                  onPressed: isProcessing
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Odustani'),
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

                          // Save price data
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

                          // Validate optional fields for consistency
                          final weekendPriceText = weekendPriceController.text
                              .trim();
                          if (weekendPriceText.isNotEmpty) {
                            final weekendPrice = double.tryParse(
                              weekendPriceText,
                            );
                            if (weekendPrice == null || weekendPrice <= 0) {
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

                          final minNightsText = minNightsController.text.trim();
                          if (minNightsText.isNotEmpty) {
                            final minNights = int.tryParse(minNightsText);
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

                          final maxNightsText = maxNightsController.text.trim();
                          if (maxNightsText.isNotEmpty) {
                            final maxNights = int.tryParse(maxNightsText);
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

                          setState(() => isProcessing = true);

                          try {
                            final repository = ref.read(
                              dailyPriceRepositoryProvider,
                            );

                            // Parse optional fields after validation
                            final weekendPrice = weekendPriceText.isEmpty
                                ? null
                                : double.tryParse(weekendPriceText);
                            final minNights = minNightsText.isEmpty
                                ? null
                                : int.tryParse(minNightsText);
                            final maxNights = maxNightsText.isEmpty
                                ? null
                                : int.tryParse(maxNightsText);

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
                              isImportant: isImportant,
                              notes: notesController.text.trim().isEmpty
                                  ? null
                                  : notesController.text.trim(),
                              createdAt:
                                  existingPrice?.createdAt ?? DateTime.now(),
                              updatedAt: DateTime.now(),
                            );

                            // OPTIMISTIC UPDATE: Update local cache immediately
                            final dateKey = DateTime(
                              date.year,
                              date.month,
                              date.day,
                            );
                            _localState.updateDateOptimistically(
                              _selectedMonth,
                              date,
                              priceModel,
                              existingPrice,
                            );

                            // Close dialog and show feedback immediately
                            if (mounted) {
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

                              // Refresh from server to ensure consistency
                              ref.invalidate(
                                monthlyPricesProvider(
                                  MonthlyPricesParams(
                                    unitId: widget.unit.id,
                                    month: DateTime(date.year, date.month),
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
                                    content: Text('Greška pri spremanju: $e'),
                                    backgroundColor: context.errorColor,
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
                                  content: Text('Greška validacije: $e'),
                                  backgroundColor: context.errorColor,
                                ),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setState(() => isProcessing = false);
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
        // Dispose all controllers when dialog closes to prevent memory leak
        priceController.dispose();
        weekendPriceController.dispose();
        minNightsController.dispose();
        maxNightsController.dispose();
        notesController.dispose();
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
                            dates: _selectedDays.toList(),
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
      // Dispose controller when dialog closes to prevent memory leak
      priceController.dispose();
    });
  }

  void _showBulkAvailabilityDialog() {
    bool isProcessing = false;

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
                            // Only update 'available' field, keep custom prices & notes
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
                            if (mounted) {
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
                            // Only update 'available' field, keep custom prices & notes
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
                            if (mounted) {
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
                            // Only update 'block_checkin' field, keep prices & notes
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
                            if (mounted) {
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
                            // Only update 'block_checkout' field, keep prices & notes
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
                            if (mounted) {
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

  /// Show notes dialog with proper text wrapping
  void _showNotesDialog(BuildContext context, DateTime date, String notes) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Notes - ${DateFormat('d MMM yyyy').format(date)}',
          style: const TextStyle(fontSize: 16),
        ),
        content: SingleChildScrollView(
          child: Text(notes, style: const TextStyle(fontSize: 14)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
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
