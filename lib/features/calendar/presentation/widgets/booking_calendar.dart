import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../domain/models/calendar_day.dart';
import '../providers/calendar_provider.dart';
import 'split_day_painter.dart';
import 'package:intl/intl.dart';

/// Main booking calendar widget with real-time updates
class BookingCalendar extends ConsumerStatefulWidget {
  final String unitId;
  final bool allowSelection;
  final Function(DateTime? checkIn, DateTime? checkOut)? onDateRangeSelected;
  final bool showLegend;

  const BookingCalendar({
    super.key,
    required this.unitId,
    this.allowSelection = true,
    this.onDateRangeSelected,
    this.showLegend = true,
  });

  @override
  ConsumerState<BookingCalendar> createState() => _BookingCalendarState();
}

class _BookingCalendarState extends ConsumerState<BookingCalendar> {
  late DateTime _focusedDay;
  DateTime? _selectedCheckIn;
  DateTime? _selectedCheckOut;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final calendarDataAsync = ref.watch(
      calendarDataProvider(
        unitId: widget.unitId,
        month: _focusedDay,
      ),
    );

    final selectedRange = ref.watch(selectedDateRangeProvider);

    return Column(
      children: [
        // Calendar widget
        calendarDataAsync.when(
          data: (calendarDays) {
            return _buildCalendar(context, calendarDays);
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load calendar',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),

        // Legend
        if (widget.showLegend) _buildLegend(context),

        // Selected date range info
        if (selectedRange.checkIn != null || selectedRange.checkOut != null)
          _buildSelectedInfo(context, selectedRange),
      ],
    );
  }

  Widget _buildCalendar(BuildContext context, List<CalendarDay> calendarDays) {
    // Create map for quick lookup
    final dayStatusMap = {
      for (var day in calendarDays)
        DateTime(day.date.year, day.date.month, day.date.day): day
    };

    return TableCalendar(
      firstDay: DateTime.now(),
      lastDay: DateTime.now().add(const Duration(days: 365)),
      focusedDay: _focusedDay,
      calendarFormat: CalendarFormat.month,
      startingDayOfWeek: StartingDayOfWeek.monday,
      availableCalendarFormats: const {
        CalendarFormat.month: 'Month',
      },

      // Styling
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        titleTextStyle: Theme.of(context).textTheme.titleLarge!,
        leftChevronIcon: const Icon(Icons.chevron_left, size: 28),
        rightChevronIcon: const Icon(Icons.chevron_right, size: 28),
      ),

      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
              fontWeight: FontWeight.w600,
            ),
        weekendStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.red[700],
            ),
      ),

      calendarStyle: const CalendarStyle(
        // Hide default decorations - we use custom painter
        defaultDecoration: BoxDecoration(),
        selectedDecoration: BoxDecoration(),
        todayDecoration: BoxDecoration(),
        weekendDecoration: BoxDecoration(),
        outsideDecoration: BoxDecoration(),
      ),

      // Custom cell builder - using our SplitDayCell
      calendarBuilders: CalendarBuilders(
        defaultBuilder: (context, date, focusedDay) {
          return _buildDayCell(date, dayStatusMap);
        },
        selectedBuilder: (context, date, focusedDay) {
          return _buildDayCell(date, dayStatusMap, isSelected: true);
        },
        todayBuilder: (context, date, focusedDay) {
          return _buildDayCell(date, dayStatusMap, isToday: true);
        },
        outsideBuilder: (context, date, focusedDay) {
          return Container(); // Hide days from other months
        },
      ),

      // Selection logic
      selectedDayPredicate: (day) {
        if (_selectedCheckIn != null && _selectedCheckOut != null) {
          return day.isAfter(_selectedCheckIn!.subtract(const Duration(days: 1))) &&
              day.isBefore(_selectedCheckOut!.add(const Duration(days: 1)));
        }
        return isSameDay(_selectedCheckIn, day);
      },

      onDaySelected: widget.allowSelection
          ? (selectedDay, focusedDay) {
              _handleDaySelected(selectedDay, dayStatusMap);
            }
          : null,

      onPageChanged: (focusedDay) {
        setState(() {
          _focusedDay = focusedDay;
        });
      },
    );
  }

  Widget _buildDayCell(
    DateTime date,
    Map<DateTime, CalendarDay> dayStatusMap, {
    bool isSelected = false,
    bool isToday = false,
  }) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final calendarDay = dayStatusMap[normalizedDate];

    if (calendarDay == null) {
      // Default to available if no data
      return SplitDayCell(
        date: date,
        status: DayStatus.available,
        isSelected: isSelected,
        isToday: isToday,
      );
    }

    return SplitDayCell(
      date: date,
      status: calendarDay.status,
      isSelected: isSelected,
      isToday: isToday,
      checkInTime: calendarDay.checkInTime != null
          ? DateFormat('HH:mm').format(calendarDay.checkInTime!)
          : null,
      checkOutTime: calendarDay.checkOutTime != null
          ? DateFormat('HH:mm').format(calendarDay.checkOutTime!)
          : null,
    );
  }

  void _handleDaySelected(
    DateTime selectedDay,
    Map<DateTime, CalendarDay> dayStatusMap,
  ) {
    final normalizedDate = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
    final calendarDay = dayStatusMap[normalizedDate];

    // Don't allow selecting blocked, booked, or same-day turnover days
    if (calendarDay?.status == DayStatus.blocked ||
        calendarDay?.status == DayStatus.booked ||
        calendarDay?.status == DayStatus.sameDayTurnover) {
      return;
    }

    setState(() {
      if (_selectedCheckIn == null) {
        // First selection - check-in date
        _selectedCheckIn = selectedDay;
        _selectedCheckOut = null;
      } else if (_selectedCheckOut == null) {
        // Second selection - check-out date
        if (selectedDay.isAfter(_selectedCheckIn!)) {
          _selectedCheckOut = selectedDay;
        } else {
          // If selected date is before check-in, start over
          _selectedCheckIn = selectedDay;
          _selectedCheckOut = null;
        }
      } else {
        // Already have both dates, start over
        _selectedCheckIn = selectedDay;
        _selectedCheckOut = null;
      }
    });

    // Update provider
    ref.read(selectedDateRangeProvider.notifier).setRange(
          _selectedCheckIn,
          _selectedCheckOut,
        );

    // Callback
    widget.onDateRangeSelected?.call(_selectedCheckIn, _selectedCheckOut);
  }

  Widget _buildLegend(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Legend',
            style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _LegendItem(
                color: const Color(0xFF9CA3AF),
                label: 'Available',
              ),
              _LegendItem(
                color: const Color(0xFF64748B),
                label: 'Booked',
              ),
              _LegendItem(
                color: const Color(0xFFEF4444),
                label: 'Check-in/out',
                isTriangle: true,
              ),
              _LegendItem(
                color: const Color(0xFFEF4444),
                label: 'Same-day turnover',
                isTwoTriangles: true,
              ),
              _LegendItem(
                color: const Color(0xFF4B5563),
                label: 'Blocked',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedInfo(
    BuildContext context,
    ({DateTime? checkIn, DateTime? checkOut}) selectedRange,
  ) {
    final checkIn = selectedRange.checkIn;
    final checkOut = selectedRange.checkOut;

    if (checkIn == null) return const SizedBox.shrink();

    final nights = checkOut != null
        ? checkOut.difference(checkIn).inDays
        : 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  checkOut == null
                      ? 'Check-in: ${DateFormat('MMM d, yyyy').format(checkIn)}'
                      : '$nights night${nights != 1 ? 's' : ''}',
                  style: Theme.of(context).textTheme.titleSmall!.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (checkOut != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${DateFormat('MMM d').format(checkIn)} - ${DateFormat('MMM d, yyyy').format(checkOut)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              setState(() {
                _selectedCheckIn = null;
                _selectedCheckOut = null;
              });
              ref.read(selectedDateRangeProvider.notifier).clear();
              widget.onDateRangeSelected?.call(null, null);
            },
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool isTriangle;
  final bool isTwoTriangles;

  const _LegendItem({
    required this.color,
    required this.label,
    this.isTriangle = false,
    this.isTwoTriangles = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: (isTriangle || isTwoTriangles) ? Colors.grey[300] : color,
            borderRadius: BorderRadius.circular(4),
          ),
          child: isTriangle
              ? CustomPaint(
                  painter: _TrianglePainter(color),
                )
              : isTwoTriangles
                  ? CustomPaint(
                      painter: _TwoTrianglesPainter(color),
                    )
                  : null,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;

  _TrianglePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width, size.height)
      ..lineTo(size.width, 0)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Painter for same-day turnover legend (two triangles)
class _TwoTrianglesPainter extends CustomPainter {
  final Color color;

  _TwoTrianglesPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Top-left triangle (check-out)
    final checkOutPath = Path()
      ..moveTo(0, 0)                    // Top-left corner
      ..lineTo(size.width / 2, 0)       // Middle-top
      ..lineTo(0, size.height / 2)      // Middle-left
      ..close();
    canvas.drawPath(checkOutPath, paint);

    // Bottom-right triangle (check-in)
    final checkInPath = Path()
      ..moveTo(size.width, size.height)          // Bottom-right corner
      ..lineTo(size.width, size.height / 2)      // Middle-right
      ..lineTo(size.width / 2, size.height)      // Middle-bottom
      ..close();
    canvas.drawPath(checkInPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
