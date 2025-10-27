import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/models/calendar_date_status.dart';
import '../providers/year_calendar_provider.dart';

class YearCalendarWidget extends ConsumerStatefulWidget {
  final String unitId;
  final Function(DateTime? start, DateTime? end)? onRangeSelected;

  const YearCalendarWidget({
    super.key,
    required this.unitId,
    this.onRangeSelected,
  });

  @override
  ConsumerState<YearCalendarWidget> createState() => _YearCalendarWidgetState();
}

class _YearCalendarWidgetState extends ConsumerState<YearCalendarWidget> {
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  int _currentYear = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    final calendarData = ref.watch(yearCalendarDataProvider((widget.unitId, _currentYear)));

    return Column(
      children: [
        _buildYearSelector(),
        const SizedBox(height: 16),
        _buildLegend(),
        const SizedBox(height: 16),
        Expanded(
          child: calendarData.when(
            data: (data) => _buildYearGrid(data),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Text('Error: $error'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildYearSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () {
            setState(() {
              _currentYear--;
            });
          },
        ),
        SelectableText(
          _currentYear.toString(),
          style: const TextStyle(
            fontSize: 20,
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
        ),
      ],
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        _buildLegendItem('Available', DateStatus.available),
        _buildLegendItem('Booked', DateStatus.booked),
      ],
    );
  }

  Widget _buildLegendItem(String label, DateStatus status) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: status.getColor(),
            border: Border.all(color: status.getBorderColor()),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        SelectableText(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }


  Widget _buildYearGrid(Map<String, CalendarDateInfo> data) {
    // 32 columns: 1 for month label + 31 for days
    // 13 rows: 1 for day headers + 12 for months
    const columns = 32;
    const rows = 13;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SizedBox(
          width: columns * 28.0, // 28px per column
          child: Column(
            children: [
              _buildHeaderRow(),
              ...List.generate(12, (monthIndex) => _buildMonthRow(monthIndex + 1, data)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderRow() {
    return Row(
      children: [
        // Empty cell for month label column
        Container(
          width: 50,
          height: 28,
          alignment: Alignment.center,
          color: Colors.grey[200],
        ),
        // Day number headers
        ...List.generate(31, (dayIndex) {
          return Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              border: Border.all(color: Colors.grey[300]!, width: 0.5),
            ),
            child: Text(
              (dayIndex + 1).toString(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMonthRow(int month, Map<String, CalendarDateInfo> data) {
    final monthName = DateFormat.MMM().format(DateTime(_currentYear, month));

    return Row(
      children: [
        // Month label
        Container(
          width: 50,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            border: Border.all(color: Colors.grey[300]!, width: 0.5),
          ),
          child: Text(
            monthName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ),
        // Day cells
        ...List.generate(31, (dayIndex) {
          final day = dayIndex + 1;
          return _buildDayCell(month, day, data);
        }),
      ],
    );
  }

  Widget _buildDayCell(int month, int day, Map<String, CalendarDateInfo> data) {
    // Check if this day exists in this month
    try {
      final date = DateTime(_currentYear, month, day);
      final key = _getDateKey(date);
      final dateInfo = data[key];

      if (dateInfo == null) {
        // Day doesn't exist in this month or no data
        return _buildEmptyCell();
      }

      final isInRange = _isDateInRange(date);
      final isRangeStart = _rangeStart != null && _isSameDay(date, _rangeStart!);
      final isRangeEnd = _rangeEnd != null && _isSameDay(date, _rangeEnd!);

      // Determine if this is a check-in or check-out day
      final isPartialCheckIn = dateInfo.status == DateStatus.partialCheckIn;
      final isPartialCheckOut = dateInfo.status == DateStatus.partialCheckOut;

      return GestureDetector(
        onTap: () => _onDateTapped(date, dateInfo),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isInRange ? Colors.blue[100]! : dateInfo.status.getColor(),
            border: Border.all(
              color: isRangeStart || isRangeEnd
                  ? Colors.blue[700]!
                  : dateInfo.status.getBorderColor(),
              width: isRangeStart || isRangeEnd ? 2.0 : 0.5,
            ),
          ),
          child: (isPartialCheckIn || isPartialCheckOut)
              ? CustomPaint(
                  painter: _DiagonalLinePainter(
                    diagonalColor: dateInfo.status.getDiagonalColor(),
                    isCheckIn: isPartialCheckIn,
                  ),
                )
              : null,
        ),
      );
    } catch (e) {
      // Invalid date (e.g., Feb 30)
      return _buildEmptyCell();
    }
  }

  Widget _buildEmptyCell() {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border.all(color: Colors.grey[300]!, width: 0.5),
      ),
    );
  }

  void _onDateTapped(DateTime date, CalendarDateInfo dateInfo) {
    if (dateInfo.status != DateStatus.available) {
      // Can't select booked or blocked dates
      return;
    }

    setState(() {
      if (_rangeStart == null || (_rangeStart != null && _rangeEnd != null)) {
        // Start new range
        _rangeStart = date;
        _rangeEnd = null;
      } else if (_rangeStart != null && _rangeEnd == null) {
        // Complete range
        if (date.isBefore(_rangeStart!)) {
          _rangeEnd = _rangeStart;
          _rangeStart = date;
        } else {
          _rangeEnd = date;
        }
      }
    });

    widget.onRangeSelected?.call(_rangeStart, _rangeEnd);
  }

  bool _isDateInRange(DateTime date) {
    if (_rangeStart == null || _rangeEnd == null) return false;
    return (date.isAfter(_rangeStart!) || _isSameDay(date, _rangeStart!)) &&
        (date.isBefore(_rangeEnd!) || _isSameDay(date, _rangeEnd!));
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _getDateKey(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }
}

/// Simple painter for diagonal lines on check-in/check-out days
class _DiagonalLinePainter extends CustomPainter {
  final Color diagonalColor;
  final bool isCheckIn;

  _DiagonalLinePainter({
    required this.diagonalColor,
    required this.isCheckIn,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    paint.color = diagonalColor;

    if (isCheckIn) {
      // Check-in: diagonal from bottom-left to top-right (green to pink)
      final path = Path()
        ..moveTo(0, size.height) // Bottom-left
        ..lineTo(size.width, 0) // Top-right
        ..lineTo(size.width, size.height) // Bottom-right
        ..close();
      canvas.drawPath(path, paint);
    } else {
      // Check-out: diagonal from top-left to bottom-right (pink to green)
      final path = Path()
        ..moveTo(0, 0) // Top-left
        ..lineTo(size.width, size.height) // Bottom-right
        ..lineTo(0, size.height) // Bottom-left
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_DiagonalLinePainter oldDelegate) {
    return oldDelegate.diagonalColor != diagonalColor ||
        oldDelegate.isCheckIn != isCheckIn;
  }
}
