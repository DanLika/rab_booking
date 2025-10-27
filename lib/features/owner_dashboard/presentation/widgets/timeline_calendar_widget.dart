import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../shared/models/booking_model.dart';
import '../../../../shared/models/unit_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/owner_calendar_provider.dart';
import 'booking_edit_dialog.dart';
import 'calendar_legend_widget.dart';

/// BedBooking-style Timeline Calendar
/// Gantt/Timeline layout: Units vertical, Dates horizontal
/// Starts from today, horizontal scroll, zoom functionality
class TimelineCalendarWidget extends ConsumerStatefulWidget {
  const TimelineCalendarWidget({super.key});

  @override
  ConsumerState<TimelineCalendarWidget> createState() => _TimelineCalendarWidgetState();
}

class _TimelineCalendarWidgetState extends ConsumerState<TimelineCalendarWidget> {
  late ScrollController _horizontalScrollController;
  late ScrollController _verticalScrollController;

  // Zoom level: number of visible days
  int _visibleDays = 14; // Default zoom level

  // Summary bar toggle
  bool _showSummary = false;

  // Cell width for each day
  double get _dayWidth => 80.0;

  // Unit row height
  static const double _unitRowHeight = 60.0;

  // Unit name column width
  static const double _unitColumnWidth = 150.0;

  @override
  void initState() {
    super.initState();
    _horizontalScrollController = ScrollController();
    _verticalScrollController = ScrollController();

    // Scroll to today on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToToday();
    });
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  void _scrollToToday() {
    // Calculate position of today
    final now = DateTime.now();
    final startDate = _getStartDate();
    final daysSinceStart = now.difference(startDate).inDays;
    final scrollPosition = daysSinceStart * _dayWidth;

    // Scroll to today (centered if possible)
    final maxScroll = _horizontalScrollController.position.maxScrollExtent;
    final targetScroll = (scrollPosition - (MediaQuery.of(context).size.width / 2)).clamp(0.0, maxScroll);

    _horizontalScrollController.jumpTo(targetScroll);
  }

  DateTime _getStartDate() {
    // Start from 3 months before today
    return DateTime.now().subtract(const Duration(days: 90));
  }

  DateTime _getEndDate() {
    // End 12 months after today
    return DateTime.now().add(const Duration(days: 365));
  }

  List<DateTime> _getDateRange() {
    final start = _getStartDate();
    final end = _getEndDate();
    final days = end.difference(start).inDays;

    return List.generate(days, (index) {
      return start.add(Duration(days: index));
    });
  }

  @override
  Widget build(BuildContext context) {
    final unitsAsync = ref.watch(allOwnerUnitsProvider);
    final bookingsAsync = ref.watch(calendarBookingsProvider);

    return Column(
      children: [
        // Zoom controls
        _buildZoomControls(),

        const SizedBox(height: 8),

        // Legend
        const CalendarLegendWidget(
          showStatusColors: true,
          showPriceColors: false,
          showIcons: true,
          isCompact: true,
        ),

        const SizedBox(height: 8),

        // Main timeline
        Expanded(
          child: unitsAsync.when(
            data: (units) {
              if (units.isEmpty) {
                return const Center(
                  child: Text('Nema jedinica za prikaz'),
                );
              }

              return bookingsAsync.when(
                data: (bookingsByUnit) {
                  return _buildTimelineView(units, bookingsByUnit);
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Text('Greška: $error'),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Text('Greška: $error'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildZoomControls() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Text('Zoom:'),
            const SizedBox(width: 16),
            IconButton(
              icon: const Icon(Icons.zoom_out),
              onPressed: _visibleDays < 30 ? () {
                setState(() {
                  _visibleDays += 7;
                });
              } : null,
              tooltip: 'Zoom out',
            ),
            Text('$_visibleDays dana'),
            IconButton(
              icon: const Icon(Icons.zoom_in),
              onPressed: _visibleDays > 7 ? () {
                setState(() {
                  _visibleDays -= 7;
                });
              } : null,
              tooltip: 'Zoom in',
            ),
            const Spacer(),
            // Summary toggle
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Summary:'),
                const SizedBox(width: 8),
                Switch(
                  value: _showSummary,
                  onChanged: (value) {
                    setState(() {
                      _showSummary = value;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.today),
              label: const Text('Danas'),
              onPressed: _scrollToToday,
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.calendar_month),
              label: const Text('Izaberi datum'),
              onPressed: _showDatePickerDialog,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineView(List<dynamic> units, Map<String, List<BookingModel>> bookingsByUnit) {
    final dates = _getDateRange();

    return Card(
      child: Column(
        children: [
          // Date headers
          _buildDateHeaders(dates),

          const Divider(height: 1),

          // Units and reservations
          Expanded(
            child: Row(
              children: [
                // Fixed unit names column
                _buildUnitNamesColumn(units),

                // Scrollable timeline grid
                Expanded(
                  child: SingleChildScrollView(
                    controller: _horizontalScrollController,
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      controller: _verticalScrollController,
                      child: Column(
                        children: [
                          _buildTimelineGrid(units, bookingsByUnit, dates),
                          // Summary bar (if enabled)
                          if (_showSummary)
                            _buildSummaryBar(bookingsByUnit, dates),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateHeaders(List<DateTime> dates) {
    return SizedBox(
      height: 80,
      child: Row(
        children: [
          // Empty space for unit names column
          Container(
            width: _unitColumnWidth,
            color: Colors.grey[200],
          ),

          // Scrollable headers
          Expanded(
            child: SingleChildScrollView(
              controller: _horizontalScrollController,
              scrollDirection: Axis.horizontal,
              child: Column(
                children: [
                  // Nad-zaglavlje: Month headers
                  SizedBox(
                    height: 30,
                    child: Row(
                      children: _buildMonthHeaders(dates),
                    ),
                  ),

                  // Pod-zaglavlje: Day headers
                  SizedBox(
                    height: 50,
                    child: Row(
                      children: dates.map((date) {
                        return _buildDayHeader(date);
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMonthHeaders(List<DateTime> dates) {
    final List<Widget> headers = [];
    DateTime? currentMonth;
    int dayCount = 0;

    for (int i = 0; i < dates.length; i++) {
      final date = dates[i];

      if (currentMonth == null ||
          date.month != currentMonth.month ||
          date.year != currentMonth.year) {
        // New month started, add previous month header if exists
        if (currentMonth != null && dayCount > 0) {
          headers.add(_buildMonthHeaderCell(currentMonth, dayCount));
        }

        // Start new month
        currentMonth = date;
        dayCount = 1;
      } else {
        dayCount++;
      }
    }

    // Add last month header
    if (currentMonth != null && dayCount > 0) {
      headers.add(_buildMonthHeaderCell(currentMonth, dayCount));
    }

    return headers;
  }

  Widget _buildMonthHeaderCell(DateTime date, int dayCount) {
    return Container(
      width: _dayWidth * dayCount,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!, width: 1),
          right: BorderSide(color: Colors.grey[400]!, width: 1),
        ),
      ),
      child: Center(
        child: Text(
          DateFormat('MMMM yyyy').format(date),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildDayHeader(DateTime date) {
    final isToday = _isToday(date);
    final isWeekend = date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
    final isFirstDayOfMonth = date.day == 1;

    return Container(
      width: _dayWidth,
      decoration: BoxDecoration(
        color: isToday
            ? AppColors.primary.withOpacity(0.1)
            : isWeekend
                ? Colors.grey[50]
                : Colors.white,
        border: Border(
          left: BorderSide(
            color: isFirstDayOfMonth ? AppColors.primary : Colors.grey[300]!,
            width: isFirstDayOfMonth ? 2 : 1,
          ),
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Day of week
          Text(
            DateFormat('EEE').format(date),
            style: TextStyle(
              fontSize: 10,
              color: isWeekend ? AppColors.primary : Colors.grey[600],
              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
            ),
          ),

          const SizedBox(height: 2),

          // Day number
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isToday ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${date.day}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: isToday ? FontWeight.bold : FontWeight.w600,
                color: isToday ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitNamesColumn(List<dynamic> units) {
    return Container(
      width: _unitColumnWidth,
      color: Colors.grey[100],
      child: Column(
        children: units.map((unit) {
          return _buildUnitNameCell(unit);
        }).toList(),
      ),
    );
  }

  Widget _buildUnitNameCell(dynamic unit) {
    return Container(
      height: _unitRowHeight,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            unit.name,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            '${unit.guestsCapacity} gostiju',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineGrid(
    List<dynamic> units,
    Map<String, List<BookingModel>> bookingsByUnit,
    List<DateTime> dates,
  ) {
    return Column(
      children: units.map((unit) {
        final bookings = bookingsByUnit[unit.id] ?? [];
        return _buildUnitRow(unit, bookings, dates);
      }).toList(),
    );
  }

  Widget _buildUnitRow(dynamic unit, List<BookingModel> bookings, List<DateTime> dates) {
    return Container(
      height: _unitRowHeight,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Stack(
        children: [
          // Day cells (background)
          Row(
            children: dates.map((date) {
              return _buildDayCell(date);
            }).toList(),
          ),

          // Reservation blocks (foreground)
          ..._buildReservationBlocks(bookings, dates),
        ],
      ),
    );
  }

  Widget _buildDayCell(DateTime date) {
    final isToday = _isToday(date);
    final isWeekend = date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
    final isFirstDayOfMonth = date.day == 1;

    return Container(
      width: _dayWidth,
      decoration: BoxDecoration(
        color: isToday
            ? AppColors.primary.withOpacity(0.05)
            : isWeekend
                ? Colors.grey[50]
                : Colors.white,
        border: Border(
          left: BorderSide(
            color: isFirstDayOfMonth ? AppColors.primary : Colors.grey[200]!,
            width: isFirstDayOfMonth ? 2 : 1,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildReservationBlocks(List<BookingModel> bookings, List<DateTime> dates) {
    final blocks = <Widget>[];

    for (final booking in bookings) {
      // Calculate position and width
      final checkIn = booking.checkIn;
      final checkOut = booking.checkOut;
      final nights = booking.checkOut.difference(booking.checkIn).inDays;

      // Find index of check-in date
      final startIndex = dates.indexWhere((d) => _isSameDay(d, checkIn));
      if (startIndex == -1) continue; // Booking not in visible range

      // Calculate left position
      final left = startIndex * _dayWidth;

      // Calculate width (number of nights * day width)
      final width = nights * _dayWidth;

      // Create reservation block
      blocks.add(
        Positioned(
          left: left,
          top: 8,
          child: _buildReservationBlock(booking, width),
        ),
      );
    }

    return blocks;
  }

  Widget _buildReservationBlock(BookingModel booking, double width) {
    final isIcalBooking = booking.source == 'ical' ||
                          booking.source == 'airbnb' ||
                          booking.source == 'booking_com';

    return GestureDetector(
      onTap: () => _showReservationDetails(booking),
      child: Stack(
        children: [
          // Main reservation block
          Container(
            width: width - 4,
            height: _unitRowHeight - 16,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: booking.status.color,
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  booking.guestName ?? 'Gost',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${booking.guestCount} gost${booking.guestCount > 1 ? 'a' : ''} • ${booking.checkOut.difference(booking.checkIn).inDays} noć${booking.checkOut.difference(booking.checkIn).inDays > 1 ? 'i' : ''}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Check-in indicator (POČETAK rezervacije - leva strana)
          // Trougao dolje-desno u svom 20x20 kvadratu
          Positioned(
            left: 0,
            top: 0,
            child: CustomPaint(
              size: const Size(20, 20),
              painter: _CheckInIndicatorPainter(),
            ),
          ),

          // Check-out indicator (KRAJ rezervacije - desna strana)
          // Trougao gore-levo u svom 20x20 kvadratu
          Positioned(
            right: 0,
            bottom: 0,
            child: CustomPaint(
              size: const Size(20, 20),
              painter: _CheckOutIndicatorPainter(),
            ),
          ),

          // iCal sync badge (top right)
          if (isIcalBooking)
            Positioned(
              right: 6,
              top: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: Colors.grey.shade400),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sync, size: 10, color: Colors.blue[700]),
                    const SizedBox(width: 2),
                    Text(
                      'iCal',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showReservationDetails(BookingModel booking) {
    showDialog(
      context: context,
      builder: (context) => BookingEditDialog(booking: booking),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceRow(String source) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getSourceIcon(source),
            size: 16,
            color: Colors.blue[700],
          ),
          const SizedBox(width: 8),
          Text(
            'Izvor: ${_getSourceLabel(source)}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.blue[700],
            ),
          ),
        ],
      ),
    );
  }

  String _getSourceLabel(String source) {
    switch (source) {
      case 'ical':
        return 'iCal Sync';
      case 'airbnb':
        return 'Airbnb';
      case 'booking_com':
        return 'Booking.com';
      case 'widget':
        return 'Widget';
      case 'admin':
        return 'Manualno';
      default:
        return source;
    }
  }

  IconData _getSourceIcon(String source) {
    switch (source) {
      case 'ical':
      case 'airbnb':
      case 'booking_com':
        return Icons.sync;
      case 'widget':
        return Icons.public;
      case 'admin':
        return Icons.person;
      default:
        return Icons.help_outline;
    }
  }

  Widget _buildSummaryBar(Map<String, List<BookingModel>> bookingsByUnit, List<DateTime> dates) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          top: BorderSide(color: Colors.grey[400]!, width: 2),
        ),
      ),
      child: Row(
        children: dates.map((date) {
          return _buildSummaryCell(date, bookingsByUnit);
        }).toList(),
      ),
    );
  }

  Widget _buildSummaryCell(DateTime date, Map<String, List<BookingModel>> bookingsByUnit) {
    // Calculate statistics for this date
    int totalGuests = 0;
    int checkIns = 0;
    int checkOuts = 0;

    // Iterate through all bookings
    for (final bookings in bookingsByUnit.values) {
      for (final booking in bookings) {
        // Count guests currently in property (checkIn <= date < checkOut)
        if (!booking.checkIn.isAfter(date) && booking.checkOut.isAfter(date)) {
          totalGuests += booking.guestCount;
        }

        // Count check-ins (checkIn == date)
        if (_isSameDay(booking.checkIn, date)) {
          checkIns++;
        }

        // Count check-outs (checkOut == date)
        if (_isSameDay(booking.checkOut, date)) {
          checkOuts++;
        }
      }
    }

    // Calculate meals (2 meals per guest per day)
    int meals = totalGuests * 2;

    final isToday = _isToday(date);
    final isWeekend = date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;

    return Container(
      width: _dayWidth,
      decoration: BoxDecoration(
        color: isToday
            ? AppColors.primary.withOpacity(0.1)
            : isWeekend
                ? Colors.grey[100]
                : Colors.white,
        border: Border(
          left: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Guests
          _buildSummaryItem(
            Icons.people,
            totalGuests.toString(),
            Colors.blue,
            'Gosti',
          ),
          // Meals
          _buildSummaryItem(
            Icons.restaurant,
            meals.toString(),
            Colors.orange,
            'Obroci',
          ),
          // Check-ins
          _buildSummaryItem(
            Icons.login,
            checkIns.toString(),
            Colors.green,
            'Dolasci',
          ),
          // Check-outs
          _buildSummaryItem(
            Icons.logout,
            checkOuts.toString(),
            Colors.red,
            'Odlasci',
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(IconData icon, String value, Color color, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
           date.month == now.month &&
           date.day == now.day;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _showDatePickerDialog() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: _getStartDate(),
      lastDate: _getEndDate(),
      helpText: 'Izaberite datum',
      cancelText: 'Otkaži',
      confirmText: 'Potvrdi',
      locale: const Locale('hr', 'HR'),
    );

    if (selectedDate != null) {
      _scrollToDate(selectedDate);
    }
  }

  void _scrollToDate(DateTime date) {
    final startDate = _getStartDate();
    final daysSinceStart = date.difference(startDate).inDays;
    final scrollPosition = daysSinceStart * _dayWidth;

    final maxScroll = _horizontalScrollController.position.maxScrollExtent;
    final targetScroll = (scrollPosition - (MediaQuery.of(context).size.width / 2))
        .clamp(0.0, maxScroll);

    _horizontalScrollController.animateTo(
      targetScroll,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }
}

/// Custom painter za CHECK-IN indikator (donji desni ugao - gost DOLAZI)
class _CheckInIndicatorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.95)
      ..style = PaintingStyle.fill;

    // Trougao u donjem desnom uglu
    final path = Path()
      ..moveTo(size.width, size.height)  // Donji desni ugao (start)
      ..lineTo(0, size.height)           // Donja ivica (levo)
      ..lineTo(size.width, 0)            // Desna ivica (gore) - dijagonala
      ..close();                         // Zatvori trougao

    canvas.drawPath(path, paint);

    // Border oko trougla
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter za CHECK-OUT indikator (gornji levi ugao - gost ODLAZI)
class _CheckOutIndicatorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.95)
      ..style = PaintingStyle.fill;

    // Trougao u gornjem levom uglu
    final path = Path()
      ..moveTo(0, 0)                    // Gornji levi ugao (start)
      ..lineTo(size.width, 0)           // Gornja ivica (desno)
      ..lineTo(0, size.height)          // Leva ivica (dole) - dijagonala
      ..close();                        // Zatvori trougao

    canvas.drawPath(path, paint);

    // Border oko trougla
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
