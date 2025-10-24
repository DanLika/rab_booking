import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/models/calendar_day.dart';
import '../providers/calendar_grid_provider.dart';

/// Grid Calendar Widget - Glavni kalendar sa kvadratićima
/// 🟢 Zelena = Available
/// 🔴 Crvena = Booked
/// ⚫ Siva = Blocked
class GridCalendarWidget extends ConsumerStatefulWidget {
  final String unitId;
  final Function(List<DateTime> selectedDates, double totalPrice)?
      onDatesSelected;
  final bool enableSelection; // Za owner view - disable selection

  const GridCalendarWidget({
    super.key,
    required this.unitId,
    this.onDatesSelected,
    this.enableSelection = true,
  });

  @override
  ConsumerState<GridCalendarWidget> createState() =>
      _GridCalendarWidgetState();
}

class _GridCalendarWidgetState extends ConsumerState<GridCalendarWidget> {
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  final Set<DateTime> _selectedDates = {};

  @override
  Widget build(BuildContext context) {
    final params = CalendarGridParams(
      unitId: widget.unitId,
      initialMonth: DateTime.now(),
    );
    final notifier = ref.watch(calendarGridNotifierProvider(params).notifier);
    final calendarAsync = ref.watch(calendarGridNotifierProvider(params));

    return Column(
      children: [
        // Header sa mjesecom i navigation
        _buildHeader(context, notifier),

        const SizedBox(height: 8),

        // Legend
        _buildLegend(context),

        const SizedBox(height: 16),

        // Calendar Grid
        Expanded(
          child: calendarAsync.when(
            data: (days) {
              if (days.isEmpty) {
                return const Center(child: Text('Nema podataka'));
              }

              return _buildCalendarGrid(days);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text('Greška: $error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => notifier.refresh(),
                    child: const Text('Pokušaj ponovo'),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Price Summary (ako su dani selektovani)
        if (_selectedDates.isNotEmpty && widget.enableSelection)
          _buildPriceSummary(context, calendarAsync.value),
      ],
    );
  }

  Widget _buildHeader(
      BuildContext context, CalendarGridNotifier notifier) {
    final month = notifier.currentMonth;
    final monthName = DateFormat('MMMM yyyy', 'hr').format(month);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => notifier.goToPreviousMonth(),
            tooltip: 'Prethodni mjesec',
          ),
          Text(
            monthName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => notifier.goToNextMonth(),
            tooltip: 'Sljedeći mjesec',
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

  Widget _buildCalendarGrid(List<CalendarDay> days) {
    // Get first day of month to determine offset
    final firstDay = days.first.date;
    final weekdayOffset = firstDay.weekday - 1; // Monday = 0

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Weekday headers
          _buildWeekdayHeaders(),

          const SizedBox(height: 8),

          // Calendar grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7, // 7 days per week
              childAspectRatio: 1,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: weekdayOffset + days.length,
            itemBuilder: (context, index) {
              // Empty cells before first day of month
              if (index < weekdayOffset) {
                return const SizedBox();
              }

              final dayIndex = index - weekdayOffset;
              if (dayIndex >= days.length) {
                return const SizedBox();
              }

              final day = days[dayIndex];
              final isSelected = _selectedDates.contains(day.date);

              return _CalendarDayCell(
                day: day,
                isSelected: isSelected,
                enableSelection: widget.enableSelection,
                onTap: () => _handleDayTap(day, days),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayHeaders() {
    const weekdays = ['Pon', 'Uto', 'Sri', 'Čet', 'Pet', 'Sub', 'Ned'];

    return Row(
      children: weekdays.map((day) {
        return Expanded(
          child: Center(
            child: Text(
              day,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _handleDayTap(CalendarDay day, List<CalendarDay> allDays) {
    if (!widget.enableSelection) return;
    if (day.status != DayStatus.available) return;

    setState(() {
      if (_rangeStart == null) {
        // Prvi klik - start date
        _rangeStart = day.date;
        _selectedDates.clear();
        _selectedDates.add(day.date);
      } else if (_rangeEnd == null && day.date.isAfter(_rangeStart!)) {
        // Drugi klik - end date
        _rangeEnd = day.date;

        // Populate all dates between start and end
        _selectedDates.clear();
        DateTime current = _rangeStart!;
        while (
            current.isBefore(_rangeEnd!) || current.isAtSameMomentAs(_rangeEnd!)) {
          // Check if date is available
          final dayData = allDays.firstWhere(
            (d) => d.date.isAtSameMomentAs(current),
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
        final totalPrice = _calculateTotalPrice(allDays);
        widget.onDatesSelected?.call(_selectedDates.toList(), totalPrice);
      } else {
        // Treći klik ili klik prije start date - reset
        _rangeStart = day.date;
        _rangeEnd = null;
        _selectedDates.clear();
        _selectedDates.add(day.date);
      }
    });
  }

  double _calculateTotalPrice(List<CalendarDay> allDays) {
    double total = 0.0;

    for (var date in _selectedDates) {
      final dayData = allDays.firstWhere(
        (d) => d.date.isAtSameMomentAs(date),
      );

      total += dayData.price ?? 0.0;
    }

    return total;
  }

  Widget _buildPriceSummary(
      BuildContext context, List<CalendarDay>? allDays) {
    if (allDays == null) return const SizedBox();

    final nights = _selectedDates.length;
    final totalPrice = _calculateTotalPrice(allDays);
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
}

/// Single day cell u kalendaru
class _CalendarDayCell extends StatelessWidget {
  final CalendarDay day;
  final bool isSelected;
  final bool enableSelection;
  final VoidCallback onTap;

  const _CalendarDayCell({
    required this.day,
    required this.isSelected,
    required this.enableSelection,
    required this.onTap,
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
        // MVP: Treat all booking states as booked (red)
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
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(
            color: borderColor,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Dan
            Text(
              '${day.date.day}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: textColor,
              ),
            ),

            // Cijena (samo ako je dostupno)
            if (day.price != null && day.status == DayStatus.available)
              Text(
                '${day.price!.toStringAsFixed(0)}€',
                style: TextStyle(
                  fontSize: 10,
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
