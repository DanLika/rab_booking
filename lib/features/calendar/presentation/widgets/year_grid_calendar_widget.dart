import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/models/calendar_day.dart';
import '../providers/calendar_grid_provider.dart';

/// Year Grid Calendar Widget - Godišnji pregled kalendara
/// Format: 31 kolona (dani 1-31) x 12 redova (mjeseci Jan-Dec)
///
/// 🟢 Zelena = Available (Slobodno)
/// 🔴 Crvena = Booked (Zauzeto)
/// ⚫ Siva = Blocked (Blokirano)
class YearGridCalendarWidget extends ConsumerStatefulWidget {
  final String unitId;
  final Function(List<DateTime> selectedDates, double totalPrice)?
      onDatesSelected;
  final bool enableSelection;

  const YearGridCalendarWidget({
    super.key,
    required this.unitId,
    this.onDatesSelected,
    this.enableSelection = true,
  });

  @override
  ConsumerState<YearGridCalendarWidget> createState() =>
      _YearGridCalendarWidgetState();
}

class _YearGridCalendarWidgetState
    extends ConsumerState<YearGridCalendarWidget> {
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  final Set<DateTime> _selectedDates = {};
  int _currentYear = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header sa godinom i navigation
        _buildHeader(context),
        const SizedBox(height: 8),

        // Legend
        _buildLegend(context),
        const SizedBox(height: 16),

        // Year Grid Calendar (scrollable)
        Expanded(
          child: _buildYearGrid(context),
        ),

        // Price Summary
        if (_selectedDates.isNotEmpty && widget.enableSelection)
          _buildPriceSummary(context),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                _currentYear--;
              });
            },
            tooltip: 'Prethodna godina',
          ),
          Text(
            '$_currentYear',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() {
                _currentYear++;
              });
            },
            tooltip: 'Sljedeća godina',
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          _LegendItem(
            color: Colors.green[100]!,
            label: 'Slobodno',
          ),
          _LegendItem(
            color: Colors.red[100]!,
            label: 'Zauzeto',
          ),
          _LegendItem(
            color: Colors.grey[300]!,
            label: 'Blokirano',
          ),
        ],
      ),
    );
  }

  Widget _buildYearGrid(BuildContext context) {
    // Use yearlyCalendarProvider to load entire year at once
    final params = YearlyCalendarParams(
      unitId: widget.unitId,
      year: _currentYear,
    );
    final yearlyCalendarAsync = ref.watch(yearlyCalendarProvider(params));

    return yearlyCalendarAsync.when(
      data: (yearData) {
        if (yearData.isEmpty) {
          return const Center(child: Text('Nema podataka'));
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SingleChildScrollView(
            child: _buildGridTable(yearData),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text('Greška: $error'),
          ],
        ),
      ),
    );
  }

  Widget _buildGridTable(Map<int, List<CalendarDay>> yearData) {
    const cellWidth = 60.0;
    const cellHeight = 50.0;
    const monthLabelWidth = 80.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row: Day numbers (1-31)
        Row(
          children: [
            // Empty cell for month label column
            SizedBox(
              width: monthLabelWidth,
              height: cellHeight,
            ),
            // Day numbers 1-31
            ...List.generate(31, (index) {
              final day = index + 1;
              return Container(
                width: cellWidth,
                height: cellHeight,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  color: Colors.grey[100],
                ),
                child: Text(
                  '$day',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              );
            }),
          ],
        ),

        // Month Rows (12 rows for Jan-Dec)
        ...List.generate(12, (monthIndex) {
          final month = monthIndex + 1;
          final monthName = DateFormat('MMM', 'hr').format(
            DateTime(_currentYear, month, 1),
          );
          final monthData = yearData[month] ?? [];

          return Row(
            children: [
              // Month Label
              Container(
                width: monthLabelWidth,
                height: cellHeight,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  color: Colors.grey[100],
                ),
                child: Text(
                  monthName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),

              // Day Cells (1-31)
              ...List.generate(31, (dayIndex) {
                final day = dayIndex + 1;
                final date = DateTime(_currentYear, month, day);

                // Check if this day exists in this month
                final daysInMonth = DateTime(_currentYear, month + 1, 0).day;
                if (day > daysInMonth) {
                  // Empty cell for non-existent days
                  return Container(
                    width: cellWidth,
                    height: cellHeight,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      color: Colors.grey[50],
                    ),
                  );
                }

                // Find calendar day data
                final calendarDay = monthData.firstWhere(
                  (d) => d.date.day == day,
                  orElse: () => CalendarDay(
                    date: date,
                    status: DayStatus.available,
                    price: 0.0,
                  ),
                );

                final isSelected = _selectedDates.any(
                  (d) => d.year == date.year &&
                         d.month == date.month &&
                         d.day == date.day,
                );

                return _YearCalendarDayCell(
                  day: calendarDay,
                  isSelected: isSelected,
                  enableSelection: widget.enableSelection,
                  onTap: () => _handleDayTap(calendarDay, yearData),
                  width: cellWidth,
                  height: cellHeight,
                );
              }),
            ],
          );
        }),
      ],
    );
  }


  void _handleDayTap(
    CalendarDay day,
    Map<int, List<CalendarDay>> yearData,
  ) {
    if (!widget.enableSelection) return;
    if (day.status != DayStatus.available) return;

    setState(() {
      if (_rangeStart == null) {
        // First click - start date
        _rangeStart = day.date;
        _selectedDates.clear();
        _selectedDates.add(day.date);
      } else if (_rangeEnd == null && day.date.isAfter(_rangeStart!)) {
        // Second click - end date
        _rangeEnd = day.date;

        // Populate all dates between start and end
        _selectedDates.clear();
        DateTime current = _rangeStart!;

        while (current.isBefore(_rangeEnd!) ||
               current.isAtSameMomentAs(_rangeEnd!)) {
          // Check if date is available
          final monthData = yearData[current.month] ?? [];
          final dayData = monthData.firstWhere(
            (d) => d.date.day == current.day &&
                   d.date.month == current.month,
            orElse: () => CalendarDay(
              date: current,
              status: DayStatus.blocked,
            ),
          );

          if (dayData.status == DayStatus.available) {
            _selectedDates.add(current);
          } else {
            // If any date in range is not available, reset selection
            _selectedDates.clear();
            _rangeStart = null;
            _rangeEnd = null;

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Odabrani period sadrži nedostupne datume'),
                duration: Duration(seconds: 2),
              ),
            );
            return;
          }

          current = current.add(const Duration(days: 1));
        }

        // Calculate total price and notify parent
        final totalPrice = _calculateTotalPrice(yearData);
        widget.onDatesSelected?.call(_selectedDates.toList(), totalPrice);
      } else {
        // Third click or click before start date - reset
        _rangeStart = day.date;
        _rangeEnd = null;
        _selectedDates.clear();
        _selectedDates.add(day.date);
      }
    });
  }

  double _calculateTotalPrice(Map<int, List<CalendarDay>> yearData) {
    double total = 0.0;

    for (var date in _selectedDates) {
      final monthData = yearData[date.month] ?? [];
      final dayData = monthData.firstWhere(
        (d) => d.date.day == date.day && d.date.month == date.month,
        orElse: () => CalendarDay(
          date: date,
          status: DayStatus.available,
          price: 0.0,
        ),
      );

      total += dayData.price ?? 0.0;
    }

    return total;
  }

  Widget _buildPriceSummary(BuildContext context) {
    final nights = _selectedDates.length;
    // We need to recalculate price from current data
    final totalPrice = _calculateTotalPriceFromSelected();
    final advanceAmount = totalPrice * 0.2; // 20%

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Broj noćenja:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                '$nights ${nights == 1 ? 'noć' : nights < 5 ? 'noći' : 'noći'}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ukupna cijena:',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                '${totalPrice.toStringAsFixed(0)}€',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Avans (20%):',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              Text(
                '${advanceAmount.toStringAsFixed(0)}€',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _calculateTotalPriceFromSelected() {
    // This is a simplified version - in real implementation,
    // we should fetch the actual prices from the provider
    // For now, return 0 and let the parent handle it
    return 0.0;
  }
}

/// Single day cell in year grid
class _YearCalendarDayCell extends StatelessWidget {
  final CalendarDay day;
  final bool isSelected;
  final bool enableSelection;
  final VoidCallback onTap;
  final double width;
  final double height;

  const _YearCalendarDayCell({
    required this.day,
    required this.isSelected,
    required this.enableSelection,
    required this.onTap,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    Color borderColor;

    switch (day.status) {
      case DayStatus.available:
        backgroundColor = isSelected
            ? Colors.green[300]!
            : Colors.green[100]!; // 🟢 ZELENA
        textColor = Colors.green[900]!;
        borderColor = isSelected ? Colors.green[700]! : Colors.green[300]!;
        break;
      case DayStatus.booked:
      case DayStatus.checkIn:
      case DayStatus.checkOut:
      case DayStatus.sameDayTurnover:
        backgroundColor = Colors.red[100]!; // 🔴 CRVENA
        textColor = Colors.red[900]!;
        borderColor = Colors.red[300]!;
        break;
      case DayStatus.blocked:
        backgroundColor = Colors.grey[300]!; // ⚫ SIVA
        textColor = Colors.grey[700]!;
        borderColor = Colors.grey[400]!;
        break;
    }

    final canTap = enableSelection && day.status == DayStatus.available;

    return GestureDetector(
      onTap: canTap ? onTap : null,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(
            color: borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Price (only if available)
            if (day.price != null && day.status == DayStatus.available)
              Text(
                '${day.price!.toStringAsFixed(0)}€',
                style: TextStyle(
                  fontSize: 9,
                  color: textColor.withOpacity(0.8),
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Legend item
class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: Colors.grey[400]!),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
