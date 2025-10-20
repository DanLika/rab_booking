import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../providers/booking_calendar_notifier.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/theme/app_colors.dart';

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
  DateTime _secondMonthFocusedDay = DateTime(
    DateTime.now().year,
    DateTime.now().month + 1,
  );
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  Widget build(BuildContext context) {
    final calendarState = ref.watch(
      bookingCalendarNotifierProvider(widget.unitId),
    );

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

        // Calendar - Responsive (single month mobile, two months desktop)
        LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 1024;

            if (isDesktop) {
              return _buildTwoMonthView(calendarState);
            } else {
              return _buildSingleMonthView(calendarState);
            }
          },
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

  /// Build single month view (mobile/tablet)
  Widget _buildSingleMonthView(BookingCalendarState calendarState) {
    return Container(
          decoration: BoxDecoration(
            border: Border.all(color: context.borderColor),
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
            calendarStyle: const CalendarStyle(
              cellMargin: EdgeInsets.all(4),
              cellPadding: EdgeInsets.zero,
              isTodayHighlighted: false, // We handle today in custom builder
              selectedDecoration: BoxDecoration(),
              selectedTextStyle: TextStyle(),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                fontWeight: FontWeight.w600,
                color: context.textColorSecondary,
              ),
              weekendStyle: TextStyle(
                fontWeight: FontWeight.w600,
                color: context.textColorSecondary,
              ),
            ),
          ),
        );
  }

  /// Build two-month view (desktop)
  Widget _buildTwoMonthView(BookingCalendarState calendarState) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // First month
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: context.borderColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: _buildCalendarWidget(
              focusedDay: _focusedDay,
              calendarState: calendarState,
              onPageChanged: (focusedDay) {
                setState(() {
                  _focusedDay = focusedDay;
                });
              },
            ),
          ),
        ),

        const SizedBox(width: 16),

        // Second month
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: context.borderColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: _buildCalendarWidget(
              focusedDay: _secondMonthFocusedDay,
              calendarState: calendarState,
              onPageChanged: (focusedDay) {
                setState(() {
                  _secondMonthFocusedDay = focusedDay;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  /// Build calendar widget (shared between single and two-month views)
  Widget _buildCalendarWidget({
    required DateTime focusedDay,
    required BookingCalendarState calendarState,
    required Function(DateTime) onPageChanged,
  }) {
    return TableCalendar(
      firstDay: DateTime.now(),
      lastDay: DateTime.now().add(const Duration(days: 365)),
      focusedDay: focusedDay,
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
      onPageChanged: onPageChanged,
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
      calendarStyle: const CalendarStyle(
        cellMargin: EdgeInsets.all(4),
        cellPadding: EdgeInsets.zero,
        isTodayHighlighted: false, // We handle today in custom builder
        selectedDecoration: BoxDecoration(),
        selectedTextStyle: TextStyle(),
      ),
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: TextStyle(
          fontWeight: FontWeight.w600,
          color: context.textColorSecondary,
        ),
        weekendStyle: TextStyle(
          fontWeight: FontWeight.w600,
          color: context.textColorSecondary,
        ),
      ),
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

          // Check-in indicator (top half-circle with gradient)
          if (isCheckIn)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ClipPath(
                clipper: _TopHalfCircleClipper(),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topCenter,
                      radius: 1.2,
                      colors: [
                        AppColors.errorDark,
                        AppColors.error.withValues(alpha: 0.8),
                        AppColors.errorLight.withValues(alpha: 0.5),
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(8),
                    ),
                  ),
                ),
              ),
            ),

          // Check-out indicator (bottom half-circle with gradient)
          if (isCheckOut)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: ClipPath(
                clipper: _BottomHalfCircleClipper(),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.bottomCenter,
                      radius: 1.2,
                      colors: [
                        AppColors.errorDark,
                        AppColors.error.withValues(alpha: 0.8),
                        AppColors.errorLight.withValues(alpha: 0.5),
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(8),
                    ),
                  ),
                ),
              ),
            ),

          // Booked indicator (diagonal stripes)
          if (isBooked && !isCheckIn && !isCheckOut)
            Positioned.fill(
              child: CustomPaint(
                painter: _DiagonalStripesPainter(
                  color: AppColors.infoLight,
                ),
              ),
            ),

          // Day number (centered, on top of everything)
          if (isCheckIn || isCheckOut)
            Positioned.fill(
              child: Center(
                child: Text(
                  '${day.day}',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        blurRadius: 2,
                        color: Colors.black.withValues(alpha: 0.26),
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
        color: context.surfaceVariantColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          '${day.day}',
          style: const TextStyle(
            color: AppColors.textDisabled,
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
      return context.primaryColor.withValues(alpha:0.3);
    }

    if (isInRange) {
      return context.primaryColor.withValues(alpha:0.2);
    }

    if (isBooked) {
      return context.isDarkMode
          ? AppColors.infoDark.withValues(alpha: 0.2)
          : AppColors.info.withValues(alpha: 0.1);
    }

    if (isToday) {
      return context.surfaceVariantColor;
    }

    return context.surfaceColor;
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
      return context.primaryColor;
    }

    if (isBooked) {
      return context.textColorTertiary;
    }

    return context.textColor;
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _LegendItem(
          color: context.primaryColor.withValues(alpha:0.2),
          label: 'Odabrano',
        ),
        const _LegendItem(
          color: AppColors.error,
          label: 'Check-in/out',
        ),
        _LegendItem(
          color: context.isDarkMode
              ? AppColors.infoDark.withValues(alpha: 0.2)
              : AppColors.info.withValues(alpha: 0.1),
          label: 'Zauzeto',
          hasStripes: true,
        ),
        _LegendItem(
          color: context.surfaceVariantColor,
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
                    color: AppColors.infoLight,
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

/// Custom clipper for top half-circle effect
class _TopHalfCircleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final radius = size.width / 2;

    // Start at top-left corner
    path.moveTo(0, 0);

    // Draw arc from left to right (top half-circle)
    path.arcToPoint(
      Offset(size.width, 0),
      radius: Radius.circular(radius),
      clockwise: false,
    );

    // Draw down and close
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Custom clipper for bottom half-circle effect
class _BottomHalfCircleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final radius = size.width / 2;

    // Start at bottom-left corner
    path.moveTo(0, size.height);

    // Draw arc from left to right (bottom half-circle)
    path.arcToPoint(
      Offset(size.width, size.height),
      radius: Radius.circular(radius),
      clockwise: true,
    );

    // Draw up and close
    path.lineTo(size.width, 0);
    path.lineTo(0, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
