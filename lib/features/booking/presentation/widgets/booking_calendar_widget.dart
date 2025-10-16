import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../providers/booking_calendar_notifier.dart';

/// Advanced booking calendar widget with custom day builders
class BookingCalendarWidget extends ConsumerStatefulWidget {
  const BookingCalendarWidget({
    required this.unitId,
    this.minStayNights = 1,
    this.onDatesSelected,
    super.key,
  });

  final String unitId;
  final int minStayNights;
  final void Function(DateTime? checkIn, DateTime? checkOut)? onDatesSelected;

  @override
  ConsumerState<BookingCalendarWidget> createState() =>
      _BookingCalendarWidgetState();
}

class _BookingCalendarWidgetState
    extends ConsumerState<BookingCalendarWidget> {
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  Widget build(BuildContext context) {
    final calendarState = ref.watch(
      bookingCalendarNotifierProvider(widget.unitId),
    );

    final isMobile = MediaQuery.of(context).size.width < 768;

    return Column(
      children: [
        // Calendar header with clear button
        if (calendarState.hasSelection)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${calendarState.selectedNights} ${calendarState.selectedNights == 1 ? 'noć' : 'noći'} odabrano',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                TextButton.icon(
                  onPressed: () {
                    ref
                        .read(bookingCalendarNotifierProvider(widget.unitId)
                            .notifier)
                        .clearDates();
                    widget.onDatesSelected?.call(null, null);
                  },
                  icon: const Icon(Icons.clear),
                  label: const Text('Očisti'),
                ),
              ],
            ),
          ),

        // Calendar
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TableCalendar(
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            startingDayOfWeek: StartingDayOfWeek.monday,
            availableCalendarFormats: const {
              CalendarFormat.month: 'Mjesec',
            },
            selectedDayPredicate: (day) {
              return calendarState.isCheckInDay(day) ||
                  calendarState.isCheckOutDay(day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              // Haptic feedback
              HapticFeedback.selectionClick();

              setState(() {
                _focusedDay = focusedDay;
              });

              final notifier = ref.read(
                bookingCalendarNotifierProvider(widget.unitId).notifier,
              );

              notifier.selectDate(
                selectedDay,
                minStayNights: widget.minStayNights,
              );

              // Notify parent
              final updatedState = ref.read(
                bookingCalendarNotifierProvider(widget.unitId),
              );
              widget.onDatesSelected?.call(
                updatedState.selectedCheckIn,
                updatedState.selectedCheckOut,
              );
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            enabledDayPredicate: (day) {
              // Disable past dates
              if (day.isBefore(
                  DateTime.now().subtract(const Duration(days: 1)))) {
                return false;
              }

              // Enable all future dates (booked dates will just look different)
              return true;
            },
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                return _buildCustomDay(context, day, calendarState);
              },
              todayBuilder: (context, day, focusedDay) {
                return _buildCustomDay(context, day, calendarState,
                    isToday: true);
              },
              disabledBuilder: (context, day, focusedDay) {
                return _buildDisabledDay(context, day);
              },
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            calendarStyle: CalendarStyle(
              cellMargin: const EdgeInsets.all(4),
              cellPadding: EdgeInsets.zero,
              isTodayHighlighted: false, // We handle today in custom builder
              selectedDecoration: const BoxDecoration(),
              selectedTextStyle: const TextStyle(),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
              weekendStyle: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
        ),

        // Legend
        const SizedBox(height: 16),
        _buildLegend(),

        // Error message
        if (calendarState.error != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              calendarState.error!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCustomDay(
    BuildContext context,
    DateTime day,
    BookingCalendarState calendarState, {
    bool isToday = false,
  }) {
    final isBooked = !calendarState.isDateAvailable(day);
    final isCheckIn = calendarState.isCheckInDay(day);
    final isCheckOut = calendarState.isCheckOutDay(day);
    final isInRange = calendarState.isInSelectedRange(day);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.all(2),
      child: Stack(
        children: [
          // Base container
          Container(
            decoration: BoxDecoration(
              color: _getDayColor(
                isBooked: isBooked,
                isCheckIn: isCheckIn,
                isCheckOut: isCheckOut,
                isInRange: isInRange,
                isToday: isToday,
              ),
              borderRadius: BorderRadius.circular(8),
              border: isToday
                  ? Border.all(
                      color: Theme.of(context).primaryColor,
                      width: 2,
                    )
                  : null,
            ),
            child: Center(
              child: Text(
                '${day.day}',
                style: TextStyle(
                  color: _getTextColor(
                    isBooked: isBooked,
                    isCheckIn: isCheckIn,
                    isCheckOut: isCheckOut,
                    isInRange: isInRange,
                  ),
                  fontWeight: (isCheckIn || isCheckOut)
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ),
          ),

          // Check-in indicator (top half - red)
          if (isCheckIn)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 20,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.red.shade600,
                      Colors.red.shade400.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8),
                  ),
                ),
              ),
            ),

          // Check-out indicator (bottom half - red)
          if (isCheckOut)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 20,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.red.shade400.withOpacity(0.7),
                      Colors.red.shade600,
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(8),
                  ),
                ),
              ),
            ),

          // Booked indicator (diagonal stripes)
          if (isBooked && !isCheckIn && !isCheckOut)
            Positioned.fill(
              child: CustomPaint(
                painter: _DiagonalStripesPainter(
                  color: Colors.blue.shade200,
                ),
              ),
            ),

          // Day number (centered, on top of everything)
          if (isCheckIn || isCheckOut)
            Positioned.fill(
              child: Center(
                child: Text(
                  '${day.day}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        blurRadius: 2,
                        color: Colors.black26,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDisabledDay(BuildContext context, DateTime day) {
    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          '${day.day}',
          style: TextStyle(
            color: Colors.grey[400],
          ),
        ),
      ),
    );
  }

  Color _getDayColor({
    required bool isBooked,
    required bool isCheckIn,
    required bool isCheckOut,
    required bool isInRange,
    required bool isToday,
  }) {
    if (isCheckIn || isCheckOut) {
      return Theme.of(context).primaryColor.withOpacity(0.3);
    }

    if (isInRange) {
      return Theme.of(context).primaryColor.withOpacity(0.2);
    }

    if (isBooked) {
      return Colors.blue.shade50;
    }

    if (isToday) {
      return Colors.grey[50]!;
    }

    return Colors.white;
  }

  Color _getTextColor({
    required bool isBooked,
    required bool isCheckIn,
    required bool isCheckOut,
    required bool isInRange,
  }) {
    if (isCheckIn || isCheckOut) {
      return Colors.white;
    }

    if (isInRange) {
      return Theme.of(context).primaryColor;
    }

    if (isBooked) {
      return Colors.grey[500]!;
    }

    return Colors.grey[800]!;
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _LegendItem(
          color: Theme.of(context).primaryColor.withOpacity(0.2),
          label: 'Odabrano',
        ),
        _LegendItem(
          color: Colors.red.shade400,
          label: 'Check-in/out',
        ),
        _LegendItem(
          color: Colors.blue.shade50,
          label: 'Zauzeto',
          hasStripes: true,
        ),
        _LegendItem(
          color: Colors.grey[100]!,
          label: 'Nedostupno',
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    this.hasStripes = false,
  });

  final Color color;
  final String label;
  final bool hasStripes;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
          child: hasStripes
              ? CustomPaint(
                  painter: _DiagonalStripesPainter(
                    color: Colors.blue.shade200,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// Custom painter for diagonal stripes pattern
class _DiagonalStripesPainter extends CustomPainter {
  final Color color;

  _DiagonalStripesPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const spacing = 6.0;
    var startY = -size.width;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(0, startY),
        Offset(size.width, startY + size.width),
        paint,
      );
      startY += spacing;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
