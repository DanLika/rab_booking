import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../shared/models/daily_price_model.dart';
import '../../../../shared/models/unit_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../providers/price_list_provider.dart';

/// BedBooking-style Price List Calendar
/// Displays one month at a time with dropdown selector
/// Shows pricing, availability, and all BedBooking features
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

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
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

  Widget _buildHeader(bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.08 * 255).toInt()),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
          BoxShadow(
            color: Colors.black.withAlpha((0.04 * 255).toInt()),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withAlpha((0.95 * 255).toInt()),
                Colors.white.withAlpha((0.90 * 255).toInt()),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withAlpha((0.4 * 255).toInt()),
              width: 1.5,
            ),
          ),
          padding: EdgeInsets.all(isMobile ? 20 : 24),
          child: isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Month selector
                    DropdownButtonFormField<DateTime>(
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
                      items: _generateMonthList().map((month) {
                        return DropdownMenuItem(
                          value: month,
                          child: Text(DateFormat('MMMM yyyy').format(month)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedMonth = value;
                            _selectedDays.clear();
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
                            ? AppColors.authPrimary
                            : null,
                        side: _bulkEditMode
                            ? const BorderSide(
                                color: AppColors.authPrimary,
                                width: 2,
                              )
                            : null,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    // Month selector
                    Expanded(
                      child: DropdownButtonFormField<DateTime>(
                        initialValue: _selectedMonth,
                        decoration: InputDecoration(
                          labelText: 'Odaberi mjesec',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.calendar_month),
                        ),
                        items: _generateMonthList().map((month) {
                          return DropdownMenuItem(
                            value: month,
                            child: Text(DateFormat('MMMM yyyy').format(month)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedMonth = value;
                              _selectedDays.clear();
                            });
                          }
                        },
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Bulk edit mode toggle
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
                            ? AppColors.authPrimary
                            : null,
                        side: _bulkEditMode
                            ? const BorderSide(
                                color: AppColors.authPrimary,
                                width: 2,
                              )
                            : null,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
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
        color: AppColors.authPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.authPrimary, width: 2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.authPrimary,
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
                color: AppColors.authPrimary,
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
            style: TextButton.styleFrom(foregroundColor: AppColors.authPrimary),
          ),
        ],
      ),
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

    // Calculate grid height based on number of rows needed
    final totalCells = firstDayOfWeek - 1 + daysInMonth;
    final rows = (totalCells / 7).ceil();

    // Use LayoutBuilder to get screen constraints for responsive sizing
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final isMobile = availableWidth < 600;
        final isSmallMobile = availableWidth < 400;

        // Calculate cell dimensions based on available width
        final cellWidth =
            (availableWidth - 40 - (8 * 6)) / 7; // padding + spacing
        final aspectRatio = isSmallMobile ? 0.85 : (isMobile ? 1.0 : 1.2);
        final cellHeight = cellWidth / aspectRatio;
        final gridHeight =
            (rows * cellHeight) + (rows * 8) + 50; // Add spacing between rows

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha((0.08 * 255).toInt()),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
              BoxShadow(
                color: Colors.black.withAlpha((0.04 * 255).toInt()),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withAlpha((0.95 * 255).toInt()),
                    Colors.white.withAlpha((0.90 * 255).toInt()),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withAlpha((0.4 * 255).toInt()),
                  width: 1.5,
                ),
              ),
              padding: EdgeInsets.all(
                isSmallMobile ? 12 : (isMobile ? 16 : 20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Weekday headers
                  _buildWeekdayHeaders(),

                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),

                  // Calendar grid with fixed height
                  SizedBox(
                    height: gridHeight,
                    child: pricesAsync.when(
                      data: (priceMap) {
                        return GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 7,
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                                childAspectRatio:
                                    aspectRatio, // Dynamic aspect ratio
                              ),
                          itemCount: firstDayOfWeek - 1 + daysInMonth,
                          itemBuilder: (context, index) {
                            if (index < firstDayOfWeek - 1) {
                              // Empty cell before first day
                              return const SizedBox.shrink();
                            }

                            final day = index - (firstDayOfWeek - 1) + 1;
                            final date = DateTime(
                              _selectedMonth.year,
                              _selectedMonth.month,
                              day,
                            );

                            return _buildDayCell(
                              date,
                              priceMap,
                              isMobile,
                              isSmallMobile,
                            );
                          },
                        );
                      },
                      loading: () => const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.authPrimary,
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
                                color: Colors.red[700],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Greška pri učitavanju cijena',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red[700],
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
                color: Colors.grey[700],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDayCell(
    DateTime date,
    Map<DateTime, DailyPriceModel> priceMap,
    bool isMobile,
    bool isSmallMobile,
  ) {
    final isSelected = _selectedDays.contains(date);
    final isToday =
        DateTime.now().year == date.year &&
        DateTime.now().month == date.month &&
        DateTime.now().day == date.day;
    final isWeekend =
        date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;

    // Get price data from Firestore or use base price
    final dateKey = DateTime(date.year, date.month, date.day);
    final priceData = priceMap[dateKey];
    final hasPrice = priceData != null;
    final isAvailable = priceData?.available ?? true;
    final hasWeekendPrice = priceData?.weekendPrice != null;

    // IMPORTANT: Use weekend price on weekends if it's set, otherwise use base price
    final price = (hasWeekendPrice && isWeekend)
        ? priceData!.weekendPrice!
        : (priceData?.price ?? widget.unit.pricePerNight);

    final blockCheckIn = priceData?.blockCheckIn ?? false;
    final blockCheckOut = priceData?.blockCheckOut ?? false;
    final notes = priceData?.notes;
    final hasRestrictions =
        blockCheckIn ||
        blockCheckOut ||
        (priceData?.minNightsOnArrival != null);

    return InkWell(
      onTap: () {
        if (_bulkEditMode) {
          setState(() {
            if (isSelected) {
              _selectedDays.remove(date);
            } else {
              _selectedDays.add(date);
            }
          });
        } else {
          _showPriceEditDialog(date);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.authPrimary.withValues(alpha: 0.2)
              : !isAvailable
              ? Colors.grey[300] // Nedostupno - siva
              : hasWeekendPrice && isWeekend
              ? Colors.purple[50] // Vikend cijena - ljubičasta
              : hasPrice
              ? AppColors.authSecondary.withAlpha(
                  (0.1 * 255).toInt(),
                ) // Custom cijena - plava
              : hasRestrictions
              ? Colors.orange[50] // Restrikcije - narandžasta
              : null, // Base price - bela
          border: Border.all(
            color: isSelected
                ? AppColors.authPrimary
                : isToday
                ? AppColors.authPrimary.withValues(alpha: 0.5)
                : hasRestrictions
                ? Colors.orange[300]!
                : Colors.grey[300]!,
            width: isSelected || hasRestrictions ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: EdgeInsets.all(isSmallMobile ? 2 : (isMobile ? 3 : 4)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Day number
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${date.day}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: isToday
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: isSmallMobile ? 9 : (isMobile ? 10 : null),
                        color: !isAvailable ? Colors.grey[600] : null,
                      ),
                    ),
                  ),
                ),
                if (_bulkEditMode && isSelected)
                  Icon(
                    Icons.check_circle,
                    size: isSmallMobile ? 12 : (isMobile ? 14 : 16),
                    color: AppColors.authPrimary,
                  ),
              ],
            ),

            // Price
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '€${price.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: isSmallMobile ? 11 : (isMobile ? 12 : null),
                        color: !isAvailable
                            ? Colors.grey[600]
                            : hasWeekendPrice && isWeekend
                            ? Colors.purple[700]
                            : hasPrice
                            ? AppColors.authSecondary
                            : Colors.grey[700],
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Hide "base" label on very small screens to save space
                  if (!hasPrice && isAvailable && !isSmallMobile)
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'base',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: isMobile ? 7 : 8,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Status indicators - make more compact on mobile
            if (blockCheckIn || blockCheckOut || notes != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (blockCheckIn)
                    Icon(
                      Icons.login,
                      size: isSmallMobile ? 10 : (isMobile ? 11 : 12),
                      color: Colors.red[700],
                    ),
                  if (blockCheckIn && blockCheckOut)
                    SizedBox(width: isSmallMobile ? 1 : 2),
                  if (blockCheckOut)
                    Icon(
                      Icons.logout,
                      size: isSmallMobile ? 10 : (isMobile ? 11 : 12),
                      color: Colors.red[700],
                    ),
                  if ((blockCheckIn || blockCheckOut) &&
                      notes != null &&
                      notes.isNotEmpty)
                    SizedBox(width: isSmallMobile ? 1 : 2),
                  if (notes case final notesText?)
                    GestureDetector(
                      onTap: () => _showNotesDialog(context, date, notesText),
                      child: Tooltip(
                        message: notesText.length > 50
                            ? '${notesText.substring(0, 47)}...'
                            : notesText,
                        preferBelow: false,
                        child: Icon(
                          Icons.notes,
                          size: isSmallMobile ? 10 : (isMobile ? 11 : 12),
                          color: Colors.orange[700],
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
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
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppColors.authPrimary,
              foregroundColor: Colors.white,
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _showBulkAvailabilityDialog,
            icon: const Icon(Icons.block),
            label: const Text('Dostupnost'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _showBulkPriceDialog,
            icon: const Icon(Icons.euro),
            label: const Text('Postavi cijenu'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppColors.authPrimary,
              foregroundColor: Colors.white,
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _showBulkAvailabilityDialog,
            icon: const Icon(Icons.block),
            label: const Text('Dostupnost'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
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

    unawaited(showDialog(
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
            content: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: isMobile ? screenHeight * 0.65 : screenHeight * 0.7,
                maxWidth: isMobile ? screenWidth * 0.9 : 600,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Price section
                    Text(
                      'Cijene',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),

                    SizedBox(height: isMobile ? 16 : 24),

                    // Availability section
                    Text(
                      'Dostupnost',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                      onChanged: (value) => setState(() => isImportant = value),
                      contentPadding: EdgeInsets.zero,
                    ),

                    SizedBox(height: isMobile ? 16 : 24),

                    // Notes section
                    Text(
                      'Napomene',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    final messenger = ScaffoldMessenger.of(context);

                    // Delete custom price (revert to base price)
                    try {
                      final repository = ref.read(dailyPriceRepositoryProvider);
                      await repository.deletePriceForDate(
                        unitId: widget.unit.id,
                        date: date,
                      );

                      ref.invalidate(monthlyPricesProvider);

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
                    }
                  },
                  child: const Text('Obriši'),
                ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Odustani'),
              ),
              ElevatedButton(
                onPressed: () async {
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

                  try {
                    final repository = ref.read(dailyPriceRepositoryProvider);

                    // Create price model with all fields
                    final priceModel = DailyPriceModel(
                      id: existingPrice?.id ?? '',
                      unitId: widget.unit.id,
                      date: date,
                      price: price,
                      available: available,
                      blockCheckIn: blockCheckIn,
                      blockCheckOut: blockCheckOut,
                      weekendPrice: weekendPriceController.text.trim().isEmpty
                          ? null
                          : double.tryParse(weekendPriceController.text.trim()),
                      minNightsOnArrival:
                          minNightsController.text.trim().isEmpty
                          ? null
                          : int.tryParse(minNightsController.text.trim()),
                      maxNightsOnArrival:
                          maxNightsController.text.trim().isEmpty
                          ? null
                          : int.tryParse(maxNightsController.text.trim()),
                      isImportant: isImportant,
                      notes: notesController.text.trim().isEmpty
                          ? null
                          : notesController.text.trim(),
                      createdAt: existingPrice?.createdAt ?? DateTime.now(),
                      updatedAt: DateTime.now(),
                    );

                    // Save the full price model with all BedBooking fields
                    await repository.setPriceForDate(
                      unitId: widget.unit.id,
                      date: date,
                      price: price,
                      priceModel: priceModel,
                    );

                    ref.invalidate(monthlyPricesProvider);

                    if (mounted) {
                      navigator.pop();
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Cijena spremljena')),
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
                  }
                },
                child: const Text('Spremi'),
              ),
            ],
          );
        },
      ),
    ));
  }

  void _showBulkPriceDialog() {
    final priceController = TextEditingController();
    bool isProcessing = false;

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
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
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

                        setState(() => isProcessing = true);

                        try {
                          final repository = ref.read(
                            dailyPriceRepositoryProvider,
                          );

                          // Save price for each selected day
                          for (final date in _selectedDays) {
                            await repository.setPriceForDate(
                              unitId: widget.unit.id,
                              date: date,
                              price: price,
                            );
                          }

                          // Refresh the price data
                          ref.invalidate(monthlyPricesProvider);

                          if (mounted) {
                            navigator.pop();
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Uspješno ažurirano ${_selectedDays.length} cijena',
                                ),
                              ),
                            );
                            // Clear selection
                            this.setState(_selectedDays.clear);
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
    );
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

                            // Create template model with available=true
                            final modelTemplate = DailyPriceModel(
                              id: '',
                              unitId: widget.unit.id,
                              date: DateTime.now(),
                              price: widget.unit.pricePerNight,
                              createdAt: DateTime.now(),
                            );

                            // Bulk update using batch operation
                            await repository.bulkUpdatePricesWithModel(
                              unitId: widget.unit.id,
                              dates: _selectedDays.toList(),
                              modelTemplate: modelTemplate,
                            );

                            // Refresh the price data
                            ref.invalidate(monthlyPricesProvider);

                            if (mounted) {
                              navigator.pop();
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${_selectedDays.length} ${_selectedDays.length == 1 ? 'dan označen' : 'dana označeno'} kao dostupno',
                                  ),
                                ),
                              );
                              // Clear selection
                              this.setState(_selectedDays.clear);
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
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 12),
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

                            // Create template model with available=false
                            final modelTemplate = DailyPriceModel(
                              id: '',
                              unitId: widget.unit.id,
                              date: DateTime.now(),
                              price: widget.unit.pricePerNight,
                              available:
                                  false, // Block dates - set as unavailable
                              blockCheckOut: false,
                              createdAt: DateTime.now(),
                            );

                            // Bulk update using batch operation
                            await repository.bulkUpdatePricesWithModel(
                              unitId: widget.unit.id,
                              dates: _selectedDays.toList(),
                              modelTemplate: modelTemplate,
                            );

                            // Refresh the price data
                            ref.invalidate(monthlyPricesProvider);

                            if (mounted) {
                              navigator.pop();
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${_selectedDays.length} ${_selectedDays.length == 1 ? 'dan blokiran' : 'dana blokirano'}',
                                  ),
                                ),
                              );
                              // Clear selection
                              this.setState(_selectedDays.clear);
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
                    backgroundColor: Colors.red[700],
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

                            // Create template model with blockCheckIn=true
                            final modelTemplate = DailyPriceModel(
                              id: '',
                              unitId: widget.unit.id,
                              date: DateTime.now(),
                              price: widget.unit.pricePerNight,
                              blockCheckIn: true, // Block check-in
                              createdAt: DateTime.now(),
                            );

                            // Bulk update using batch operation
                            await repository.bulkUpdatePricesWithModel(
                              unitId: widget.unit.id,
                              dates: _selectedDays.toList(),
                              modelTemplate: modelTemplate,
                            );

                            // Refresh the price data
                            ref.invalidate(monthlyPricesProvider);

                            if (mounted) {
                              navigator.pop();
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Check-in blokiran za odabrane dane',
                                  ),
                                ),
                              );
                              // Clear selection
                              this.setState(_selectedDays.clear);
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

                            // Create template model with blockCheckOut=true
                            final modelTemplate = DailyPriceModel(
                              id: '',
                              unitId: widget.unit.id,
                              date: DateTime.now(),
                              price: widget.unit.pricePerNight,
                              blockCheckOut: true, // Block check-out
                              createdAt: DateTime.now(),
                            );

                            // Bulk update using batch operation
                            await repository.bulkUpdatePricesWithModel(
                              unitId: widget.unit.id,
                              dates: _selectedDays.toList(),
                              modelTemplate: modelTemplate,
                            );

                            // Refresh the price data
                            ref.invalidate(monthlyPricesProvider);

                            if (mounted) {
                              navigator.pop();
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Check-out blokiran za odabrane dane',
                                  ),
                                ),
                              );
                              // Clear selection
                              this.setState(_selectedDays.clear);
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
    final startDate = DateTime(now.year - 1, 1);
    final endDate = DateTime(now.year + 2, 12);

    DateTime current = startDate;
    while (current.isBefore(endDate) || current.isAtSameMomentAs(endDate)) {
      months.add(current);
      current = DateTime(current.year, current.month + 1);
    }

    return months;
  }
}
