import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/booking_model.dart';
import '../../../../shared/models/daily_price_model.dart';
import '../../../../shared/providers/repository_providers.dart';

/// Year Grid Calendar Widget (BedBooking style)
/// Compact design: 31 columns (days 1-31) × 12 rows (months)
class YearGridCalendar extends ConsumerStatefulWidget {
  final String unitId;
  final int year;

  const YearGridCalendar({
    super.key,
    required this.unitId,
    required this.year,
  });

  @override
  ConsumerState<YearGridCalendar> createState() => _YearGridCalendarState();
}

class _YearGridCalendarState extends ConsumerState<YearGridCalendar> {
  int selectedYear = DateTime.now().year;
  DateTime? selectionStart;
  DateTime? selectionEnd;
  bool isDragging = false;

  Map<String, DailyPriceModel> dailyPrices = {};
  List<BookingModel> bookings = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    selectedYear = widget.year;
    _loadCalendarData();
  }

  Future<void> _loadCalendarData() async {
    setState(() => isLoading = true);

    try {
      final startDate = DateTime(selectedYear, 1, 1);
      final endDate = DateTime(selectedYear, 12, 31);

      // Load daily prices with fallback
      List<DailyPriceModel> prices = [];
      try {
        final priceRepo = ref.read(dailyPriceRepositoryProvider);
        prices = await priceRepo.getPricesForDateRange(
          unitId: widget.unitId,
          startDate: startDate,
          endDate: endDate,
        );
      } catch (priceError) {
        print('Error loading prices: $priceError');
        // Continue with empty prices
      }

      // Load bookings with fallback
      List<BookingModel> bookingList = [];
      try {
        final bookingRepo = ref.read(bookingRepositoryProvider);
        bookingList = await bookingRepo.getBookingsInRange(
          unitId: widget.unitId,
          startDate: startDate,
          endDate: endDate,
        );
      } catch (bookingError) {
        print('Error loading bookings: $bookingError');
        // Continue with empty bookings
      }

      setState(() {
        dailyPrices = {
          for (var price in prices)
            '${price.date.year}-${price.date.month}-${price.date.day}': price
        };
        bookings = bookingList;
        isLoading = false;
      });
    } catch (e) {
      print('General error: $e');
      setState(() {
        dailyPrices = {};
        bookings = [];
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  bool _isValidDate(int year, int month, int day) {
    try {
      DateTime(year, month, day);
      return true;
    } catch (e) {
      return false;
    }
  }

  bool _isDateBooked(DateTime date) {
    return bookings.any((booking) {
      return date.isAfter(booking.checkIn.subtract(const Duration(days: 1))) &&
          date.isBefore(booking.checkOut);
    });
  }

  bool _isCheckIn(DateTime date) {
    return bookings.any((b) => _isSameDay(b.checkIn, date));
  }

  bool _isCheckOut(DateTime date) {
    return bookings.any((b) => _isSameDay(b.checkOut, date));
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Color _getCellColor(DateTime date) {
    if (_isDateBooked(date)) {
      return const Color(0xFFFF9999); // Pink/Red for booked
    }
    return const Color(0xFF99FF99); // Green for available
  }

  void _handleCellTap(DateTime date) {
    if (_isDateBooked(date)) return;

    setState(() {
      selectionStart = date;
      selectionEnd = date;
      isDragging = false;
    });
  }

  void _handleCellDragUpdate(DateTime date) {
    if (selectionStart == null || _isDateBooked(date)) return;

    setState(() {
      selectionEnd = date;
      isDragging = true;
    });
  }

  void _handleDragEnd() {
    setState(() {
      isDragging = false;
    });
  }

  bool _isCellSelected(DateTime date) {
    if (selectionStart == null || selectionEnd == null) return false;

    final start = selectionStart!.isBefore(selectionEnd!)
        ? selectionStart!
        : selectionEnd!;
    final end = selectionStart!.isAfter(selectionEnd!)
        ? selectionStart!
        : selectionEnd!;

    return date.isAfter(start.subtract(const Duration(days: 1))) &&
        date.isBefore(end.add(const Duration(days: 1)));
  }

  double _calculateTotalPrice() {
    if (selectionStart == null || selectionEnd == null) return 0;

    final start = selectionStart!.isBefore(selectionEnd!)
        ? selectionStart!
        : selectionEnd!;
    final end = selectionStart!.isAfter(selectionEnd!)
        ? selectionStart!
        : selectionEnd!;

    double total = 0;
    DateTime current = start;

    while (current.isBefore(end.add(const Duration(days: 1)))) {
      final key = '${current.year}-${current.month}-${current.day}';
      final price = dailyPrices[key];
      if (price != null) {
        total += price.price;
      }
      current = current.add(const Duration(days: 1));
    }

    return total;
  }

  int _getNumberOfNights() {
    if (selectionStart == null || selectionEnd == null) return 0;
    return (selectionEnd!.difference(selectionStart!).inDays + 1).abs();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 8),
          _buildLegend(),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: _buildCalendarTable(),
              ),
            ),
          ),
          if (selectionStart != null) _buildPriceSummary(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          DropdownButton<int>(
            value: selectedYear,
            items: List.generate(5, (index) {
              final year = DateTime.now().year + index;
              return DropdownMenuItem(
                value: year,
                child: Text(
                  year.toString(),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              );
            }),
            onChanged: (year) {
              if (year != null) {
                setState(() {
                  selectedYear = year;
                  selectionStart = null;
                  selectionEnd = null;
                });
                _loadCalendarData();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(const Color(0xFF99FF99), 'Available'),
        const SizedBox(width: 16),
        _buildLegendItem(const Color(0xFFFF9999), 'Booked'),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: Colors.grey.shade400, width: 1),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 13)),
      ],
    );
  }

  Widget _buildCalendarTable() {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'June',
      'July', 'Aug', 'Sept', 'Oct', 'Nov', 'Dec'
    ];

    return Table(
      border: TableBorder.all(color: Colors.grey.shade300, width: 0.5),
      defaultColumnWidth: const FixedColumnWidth(32),
      children: [
        // Header row with day numbers
        TableRow(
          decoration: BoxDecoration(color: Colors.grey.shade50),
          children: [
            const SizedBox(width: 60, height: 28), // Empty corner cell
            ...List.generate(31, (i) => _buildHeaderCell('${i + 1}')),
          ],
        ),
        // Month rows
        ...List.generate(12, (monthIndex) {
          final month = monthIndex + 1;
          return TableRow(
            children: [
              _buildMonthCell(months[monthIndex]),
              ...List.generate(31, (dayIndex) {
                final day = dayIndex + 1;
                return _buildDayCell(selectedYear, month, day);
              }),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildHeaderCell(String text) {
    return Container(
      height: 28,
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  Widget _buildMonthCell(String month) {
    return Container(
      width: 60,
      height: 28,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(right: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Text(
        month,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  Widget _buildDayCell(int year, int month, int day) {
    if (!_isValidDate(year, month, day)) {
      return Container(
        height: 28,
        color: Colors.grey.shade200,
      );
    }

    final date = DateTime(year, month, day);
    final isBooked = _isDateBooked(date);
    final isSelected = _isCellSelected(date);
    final isCheckInDay = _isCheckIn(date);
    final isCheckOutDay = _isCheckOut(date);

    Color cellColor = _getCellColor(date);
    if (isSelected && !isBooked) {
      cellColor = const Color(0xFF6699FF); // Blue for selection
    }

    return GestureDetector(
      onTap: () => _handleCellTap(date),
      onPanUpdate: (details) => _handleCellDragUpdate(date),
      onPanEnd: (details) => _handleDragEnd(),
      child: MouseRegion(
        onEnter: (_) {
          if (isDragging) {
            _handleCellDragUpdate(date);
          }
        },
        child: Container(
          height: 28,
          decoration: BoxDecoration(
            color: cellColor,
            border: isSelected
                ? Border.all(color: const Color(0xFF0066FF), width: 1.5)
                : null,
          ),
          child: Stack(
            children: [
              if (isCheckInDay)
                CustomPaint(
                  size: const Size(32, 28),
                  painter: DiagonalLinePainter(isCheckIn: true),
                ),
              if (isCheckOutDay)
                CustomPaint(
                  size: const Size(32, 28),
                  painter: DiagonalLinePainter(isCheckIn: false),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceSummary() {
    final totalPrice = _calculateTotalPrice();
    final nights = _getNumberOfNights();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$nights night${nights != 1 ? 's' : ''}',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              if (selectionStart != null && selectionEnd != null)
                Text(
                  '${_formatDate(selectionStart!)} - ${_formatDate(selectionEnd!)}',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
            ],
          ),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '€${totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0066FF),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: totalPrice > 0 ? _handleReserve : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0066FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Text(
                  'Reserve',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  void _handleReserve() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reserve'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total: €${_calculateTotalPrice().toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            Text('Advance (20%): €${(_calculateTotalPrice() * 0.2).toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            Text('On arrival: €${(_calculateTotalPrice() * 0.8).toStringAsFixed(2)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}

class DiagonalLinePainter extends CustomPainter {
  final bool isCheckIn;

  DiagonalLinePainter({required this.isCheckIn});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF009900)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    if (isCheckIn) {
      canvas.drawLine(
        const Offset(0, 0),
        Offset(size.width, size.height),
        paint,
      );
    } else {
      canvas.drawLine(
        Offset(size.width, 0),
        Offset(0, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
