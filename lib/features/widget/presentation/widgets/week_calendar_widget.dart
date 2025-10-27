import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/models/calendar_date_status.dart';
import '../providers/week_calendar_provider.dart';
import 'split_day_calendar_painter.dart';

class WeekCalendarWidget extends ConsumerStatefulWidget {
  final String unitId;
  final Function(DateTime? start, DateTime? end)? onRangeSelected;

  const WeekCalendarWidget({
    super.key,
    required this.unitId,
    this.onRangeSelected,
  });

  @override
  ConsumerState<WeekCalendarWidget> createState() => _WeekCalendarWidgetState();
}

class _WeekCalendarWidgetState extends ConsumerState<WeekCalendarWidget> {
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  DateTime _currentWeekStart = _getWeekStart(DateTime.now());

  static DateTime _getWeekStart(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  @override
  Widget build(BuildContext context) {
    final calendarData = ref.watch(weekCalendarDataProvider((widget.unitId, _currentWeekStart)));

    return Column(
      children: [
        _buildWeekNavigation(),
        const SizedBox(height: 16),
        _buildLegend(),
        const SizedBox(height: 16),
        Expanded(
          child: calendarData.when(
            data: (data) => _buildWeekView(data),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Text('Error: $error'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeekNavigation() {
    final weekEnd = _currentWeekStart.add(const Duration(days: 6));
    final weekLabel = _currentWeekStart.month == weekEnd.month
        ? '${DateFormat.MMMd().format(_currentWeekStart)} - ${DateFormat.d().format(weekEnd)}, ${DateFormat.y().format(_currentWeekStart)}'
        : '${DateFormat.MMMd().format(_currentWeekStart)} - ${DateFormat.yMMMd().format(weekEnd)}';

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                _currentWeekStart = _currentWeekStart.subtract(const Duration(days: 7));
              });
            },
          ),
          Text(
            weekLabel,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() {
                _currentWeekStart = _currentWeekStart.add(const Duration(days: 7));
              });
            },
          ),
        ],
      ),
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
        _buildLegendItem('Blocked', DateStatus.blocked),
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
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildWeekView(Map<String, CalendarDateInfo> data) {
    return Column(
      children: [
        _buildWeekHeader(),
        const SizedBox(height: 8),
        Expanded(
          child: _buildWeekDays(data),
        ),
      ],
    );
  }

  Widget _buildWeekHeader() {
    final weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Row(
      children: weekDays.map((day) {
        return Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Text(
              day,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWeekDays(Map<String, CalendarDateInfo> data) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(7, (index) {
        final date = _currentWeekStart.add(Duration(days: index));
        return Expanded(
          child: _buildDayColumn(date, data),
        );
      }),
    );
  }

  Widget _buildDayColumn(DateTime date, Map<String, CalendarDateInfo> data) {
    final key = _getDateKey(date);
    final dateInfo = data[key];

    if (dateInfo == null) {
      return _buildEmptyDay();
    }

    final isInRange = _isDateInRange(date);
    final isRangeStart = _rangeStart != null && _isSameDay(date, _rangeStart!);
    final isRangeEnd = _rangeEnd != null && _isSameDay(date, _rangeEnd!);
    final isToday = _isSameDay(date, DateTime.now());

    // Get price text for display
    final priceText = dateInfo.formattedPrice;

    return GestureDetector(
      onTap: () => _onDateTapped(date, dateInfo),
      child: Container(
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          border: Border.all(
            color: isRangeStart || isRangeEnd
                ? Colors.blue.shade700
                : isToday
                    ? Colors.orange.shade700
                    : Colors.grey.shade300,
            width: isRangeStart || isRangeEnd || isToday ? 2 : 0.5,
          ),
        ),
        child: Stack(
          children: [
            // Background with diagonal split and price
            CustomPaint(
              painter: SplitDayCalendarPainter(
                status: isInRange ? DateStatus.available : dateInfo.status,
                borderColor: dateInfo.status.getBorderColor(),
                priceText: priceText,
              ),
              child: const SizedBox.expand(),
            ),
            // Day number and labels overlay
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    date.day.toString(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                if (isRangeStart)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue[700],
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: const Text(
                      'Check-in',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                if (isRangeEnd)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue[700],
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: const Text(
                      'Check-out',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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

  Widget _buildEmptyDay() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border.all(color: Colors.grey[300]!),
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
