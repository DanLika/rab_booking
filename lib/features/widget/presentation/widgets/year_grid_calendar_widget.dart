import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/models/calendar_date_status.dart';
import '../providers/realtime_booking_calendar_provider.dart';
import 'split_day_calendar_painter.dart';

/// Year-view grid calendar widget inspired by BedBooking
/// Shows 12 months × 31 days in a grid with diagonal splits for check-in/check-out
class YearGridCalendarWidget extends ConsumerStatefulWidget {
  final String unitId;
  final Function(DateTime? start, DateTime? end)? onRangeSelected;
  final int? initialYear;
  final int minStayNights;

  const YearGridCalendarWidget({
    super.key,
    required this.unitId,
    this.onRangeSelected,
    this.initialYear,
    this.minStayNights = 1,
  });

  @override
  ConsumerState<YearGridCalendarWidget> createState() =>
      _YearGridCalendarWidgetState();
}

class _YearGridCalendarWidgetState
    extends ConsumerState<YearGridCalendarWidget> {
  late int _currentYear;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  DateTime? _hoverDate; // For hover tooltip
  DateTime? _dragStart; // For drag-to-select
  bool _isDragging = false;

  // For tap info panel (mobile)
  DateTime? _tappedDate;
  Offset? _tapPosition;

  @override
  void initState() {
    super.initState();
    _currentYear = widget.initialYear ?? DateTime.now().year;
  }

  @override
  Widget build(BuildContext context) {
    final calendarData = ref.watch(
      realtimeYearCalendarProvider(widget.unitId, _currentYear),
    );

    return Stack(
      children: [
        Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildLegend(),
            const SizedBox(height: 16),
            Expanded(
              child: calendarData.when(
                data: (data) => _buildYearGrid(data),
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, stack) => Center(
                  child: Text(
                    'Greška pri učitavanju kalendara: $error',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ),
          ],
        ),

        // Hover tooltip (desktop)
        if (_hoverDate != null) _buildHoverTooltip(calendarData),

        // Tap info panel (mobile)
        if (_tappedDate != null && _tapPosition != null)
          _buildTapInfoPanel(calendarData),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
      ),
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
          ),
          Text(
            'Yearly view',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _currentYear,
                isDense: true,
                items: List.generate(10, (index) {
                  final year = DateTime.now().year - 2 + index;
                  return DropdownMenuItem(
                    value: year,
                    child: Text(year.toString()),
                  );
                }).toList(),
                onChanged: (year) {
                  if (year != null) {
                    setState(() {
                      _currentYear = year;
                    });
                  }
                },
              ),
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
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem('Available', const Color(0xFFC8E6C9)),
        const SizedBox(width: 24),
        _buildLegendItem('Booked', const Color(0xFFFFCDD2)),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: Colors.grey.shade300, width: 0.5),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildYearGrid(Map<DateTime, CalendarDateInfo> data) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate cell size based on available width
        // Reserve space for month labels
        final monthLabelWidth = 60.0;
        final availableWidth = constraints.maxWidth - monthLabelWidth - 20;
        final cellSize = (availableWidth / 31).clamp(18.0, 32.0);

        return SingleChildScrollView(
          child: Column(
            children: [
              // Day numbers header (1-31)
              _buildDayNumbersHeader(cellSize, monthLabelWidth),
              const SizedBox(height: 4),

              // 12 month rows
              ...List.generate(12, (monthIndex) {
                return _buildMonthRow(
                  monthIndex + 1,
                  data,
                  cellSize,
                  monthLabelWidth,
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDayNumbersHeader(double cellSize, double monthLabelWidth) {
    return Row(
      children: [
        SizedBox(width: monthLabelWidth),
        ...List.generate(31, (dayIndex) {
          final dayNumber = dayIndex + 1;
          return SizedBox(
            width: cellSize,
            height: 24,
            child: Center(
              child: Text(
                dayNumber.toString(),
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMonthRow(
    int month,
    Map<DateTime, CalendarDateInfo> data,
    double cellSize,
    double monthLabelWidth,
  ) {
    final monthName = DateFormat('MMM').format(DateTime(_currentYear, month, 1));
    final daysInMonth = DateTime(_currentYear, month + 1, 0).day;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          // Month label
          SizedBox(
            width: monthLabelWidth,
            child: Text(
              monthName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Day cells
          ...List.generate(31, (dayIndex) {
            final dayNumber = dayIndex + 1;

            if (dayNumber > daysInMonth) {
              // Gray out invalid days
              return SizedBox(
                width: cellSize,
                height: cellSize,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    border: Border.all(
                      color: Colors.grey.shade200,
                      width: 0.5,
                    ),
                  ),
                ),
              );
            }

            final date = DateTime(_currentYear, month, dayNumber);
            final dateInfo = data[date];
            final status = dateInfo?.status ?? DateStatus.available;
            final priceText = dateInfo?.formattedPrice; // Get formatted price

            // Check if date is in the past
            final today = DateTime.now();
            final todayNormalized = DateTime(today.year, today.month, today.day);
            final isPastDate = date.isBefore(todayNormalized);

            final isInRange = _rangeStart != null &&
                _rangeEnd != null &&
                date.isAfter(_rangeStart!) &&
                date.isBefore(_rangeEnd!);

            final isSelected = date == _rangeStart || date == _rangeEnd;

            // Accessibility wrapper
            return Semantics(
              label: _buildSemanticLabel(date, status, priceText, isPastDate),
              button: !isPastDate && status == DateStatus.available,
              enabled: !isPastDate && status == DateStatus.available,
              excludeSemantics: true, // Exclude child semantics
              child: MouseRegion(
                onEnter: isPastDate ? null : (_) => _handleDayHoverEnter(date),
                onExit: isPastDate ? null : (_) => _handleDayHoverExit(),
                cursor: isPastDate
                    ? SystemMouseCursors.forbidden
                    : (status == DateStatus.booked || status == DateStatus.blocked
                        ? SystemMouseCursors.forbidden
                        : SystemMouseCursors.click),
                child: GestureDetector(
                  onTapDown: isPastDate ? null : (details) => _handleDayTapDown(date, details, status),
                  onTapUp: isPastDate ? null : (_) => _handleDayTapUp(date, status),
                  onLongPressStart: isPastDate ? null : (details) => _handleDayLongPress(date, details),
                  onPanStart: isPastDate ? null : (_) => _handleDragStart(date, status),
                  onPanUpdate: isPastDate ? null : (_) => _handleDragUpdate(date),
                  onPanEnd: isPastDate ? null : (_) => _handleDragEnd(),
                  child: SizedBox(
                  width: cellSize,
                  height: cellSize,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isPastDate ? const Color(0xFFE5E7EB) : null,
                      border: Border.all(
                        color: isSelected
                            ? Colors.blue.shade700
                            : (isInRange ? Colors.blue.shade300 : Colors.grey.shade300),
                        width: isSelected ? 2 : 0.5,
                      ),
                      // Hover effect
                      boxShadow: _hoverDate == date && !isPastDate
                          ? [BoxShadow(
                              color: Colors.blue.shade200,
                              blurRadius: 4,
                              spreadRadius: 1,
                            )]
                          : null,
                    ),
                    child: isPastDate
                        ? Center(
                            child: Icon(
                              Icons.block,
                              size: cellSize * 0.5,
                              color: Colors.grey.shade400,
                            ),
                          )
                        : CustomPaint(
                            painter: SplitDayCalendarPainter(
                              status: status,
                              borderColor: Colors.grey.shade400,
                              priceText: priceText,
                            ),
                            child: const SizedBox.expand(),
                          ),
                  ),
                ),
              ),
            ),
          );
          }),
        ],
      ),
    );
  }

  // ============================================================
  // HOVER HANDLERS (Desktop)
  // ============================================================

  void _handleDayHoverEnter(DateTime date) {
    setState(() {
      _hoverDate = date;
    });
  }

  void _handleDayHoverExit() {
    setState(() {
      _hoverDate = null;
    });
  }

  // ============================================================
  // TAP HANDLERS (Mobile & Desktop)
  // ============================================================

  void _handleDayTapDown(DateTime date, TapDownDetails details, DateStatus status) {
    // Store tap position for mobile info panel
    if (Theme.of(context).platform == TargetPlatform.android ||
        Theme.of(context).platform == TargetPlatform.iOS) {
      setState(() {
        _tappedDate = date;
        _tapPosition = details.globalPosition;
      });

      // Auto-hide after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _tappedDate == date) {
          setState(() {
            _tappedDate = null;
            _tapPosition = null;
          });
        }
      });
    }
  }

  void _handleDayTapUp(DateTime date, DateStatus status) {
    _handleDayTap(date, status);
  }

  void _handleDayLongPress(DateTime date, LongPressStartDetails details) {
    // Show info panel on long press (mobile)
    setState(() {
      _tappedDate = date;
      _tapPosition = details.globalPosition;
    });
  }

  void _handleDayTap(DateTime date, DateStatus status) {
    // Don't allow selection of past dates
    final today = DateTime.now();
    final todayNormalized = DateTime(today.year, today.month, today.day);
    if (date.isBefore(todayNormalized)) {
      return;
    }

    // Don't allow selection of booked or blocked dates
    if (status == DateStatus.booked || status == DateStatus.blocked) {
      return;
    }

    setState(() {
      if (_rangeStart == null || (_rangeStart != null && _rangeEnd != null)) {
        // Start new selection
        _rangeStart = date;
        _rangeEnd = null;
      } else if (_rangeStart != null && _rangeEnd == null) {
        // Complete selection
        DateTime tempStart = _rangeStart!;
        DateTime tempEnd = date;

        if (date.isBefore(_rangeStart!)) {
          tempStart = date;
          tempEnd = _rangeStart!;
        }

        // Validate minimum stay requirement
        final nights = tempEnd.difference(tempStart).inDays;
        if (nights < widget.minStayNights) {
          // Show error message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Minimum stay is ${widget.minStayNights} ${widget.minStayNights == 1 ? 'night' : 'nights'}. You selected $nights ${nights == 1 ? 'night' : 'nights'}.',
                ),
                backgroundColor: Colors.red.shade700,
                duration: const Duration(seconds: 3),
              ),
            );
          }
          // Reset selection
          _rangeStart = null;
          _rangeEnd = null;
          return;
        }

        _rangeStart = tempStart;
        _rangeEnd = tempEnd;

        // Notify parent
        if (widget.onRangeSelected != null) {
          widget.onRangeSelected!(_rangeStart, _rangeEnd);
        }
      }
    });
  }

  // ============================================================
  // DRAG-TO-SELECT HANDLERS
  // ============================================================

  void _handleDragStart(DateTime date, DateStatus status) {
    if (status == DateStatus.booked || status == DateStatus.blocked) {
      return;
    }

    setState(() {
      _isDragging = true;
      _dragStart = date;
      _rangeStart = date;
      _rangeEnd = null;
    });
  }

  void _handleDragUpdate(DateTime date) {
    if (!_isDragging || _dragStart == null) return;

    setState(() {
      DateTime tempStart = _dragStart!;
      DateTime tempEnd = date;

      if (date.isBefore(_dragStart!)) {
        tempStart = date;
        tempEnd = _dragStart!;
      }

      _rangeStart = tempStart;
      _rangeEnd = tempEnd;
    });
  }

  void _handleDragEnd() {
    if (!_isDragging) return;

    setState(() {
      _isDragging = false;
      _dragStart = null;

      // Validate minimum stay requirement
      if (_rangeStart != null && _rangeEnd != null) {
        final nights = _rangeEnd!.difference(_rangeStart!).inDays;
        if (nights < widget.minStayNights) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Minimum stay is ${widget.minStayNights} ${widget.minStayNights == 1 ? 'night' : 'nights'}.',
                ),
                backgroundColor: Colors.red.shade700,
                duration: const Duration(seconds: 2),
              ),
            );
          }
          _rangeStart = null;
          _rangeEnd = null;
          return;
        }

        // Notify parent
        if (widget.onRangeSelected != null) {
          widget.onRangeSelected!(_rangeStart, _rangeEnd);
        }
      }
    });
  }

  // ============================================================
  // TOOLTIP & INFO PANEL BUILDERS
  // ============================================================

  Widget _buildHoverTooltip(AsyncValue<Map<DateTime, CalendarDateInfo>> calendarData) {
    if (_hoverDate == null) return const SizedBox.shrink();

    return calendarData.when(
      data: (data) {
        final dateInfo = data[_hoverDate!];
        final status = dateInfo?.status ?? DateStatus.available;
        final price = dateInfo?.price;

        return Positioned(
          left: 0,
          right: 0,
          bottom: 20,
          child: Center(
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date
                    Text(
                      DateFormat('EEEE, MMMM d, yyyy').format(_hoverDate!),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Status
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: status.getColor(),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getStatusLabel(status),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    // Price
                    if (price != null && status == DateStatus.available) ...[
                      const SizedBox(height: 8),
                      Text(
                        '€${price.toStringAsFixed(0)} per night',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  Widget _buildTapInfoPanel(AsyncValue<Map<DateTime, CalendarDateInfo>> calendarData) {
    if (_tappedDate == null || _tapPosition == null) return const SizedBox.shrink();

    return calendarData.when(
      data: (data) {
        final dateInfo = data[_tappedDate!];
        final status = dateInfo?.status ?? DateStatus.available;
        final price = dateInfo?.price;

        return Positioned(
          left: 16,
          right: 16,
          bottom: 80,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _tappedDate = null;
                _tapPosition = null;
              });
            },
            child: Material(
              elevation: 12,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200, width: 2),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Close button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('MMM d, yyyy').format(_tappedDate!),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () {
                            setState(() {
                              _tappedDate = null;
                              _tapPosition = null;
                            });
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    // Status
                    Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: status.getColor(),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _getStatusLabel(status),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    // Price
                    if (price != null && status == DateStatus.available) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.euro,
                              size: 16,
                              color: Colors.green.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${price.toStringAsFixed(0)} per night',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    // Tap to select hint
                    if (status == DateStatus.available) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Tap to select this date',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  String _getStatusLabel(DateStatus status) {
    switch (status) {
      case DateStatus.available:
        return 'Available';
      case DateStatus.booked:
        return 'Booked';
      case DateStatus.blocked:
        return 'Not Available';
      case DateStatus.partialCheckIn:
        return 'Check-in Day';
      case DateStatus.partialCheckOut:
        return 'Check-out Day';
    }
  }

  /// Build semantic label for screen readers
  String _buildSemanticLabel(
    DateTime date,
    DateStatus status,
    String? priceText,
    bool isPastDate,
  ) {
    final formatter = DateFormat('EEEE, MMMM d, yyyy');
    final dateStr = formatter.format(date);

    if (isPastDate) {
      return '$dateStr. Past date, not available.';
    }

    final statusLabel = _getStatusLabel(status);
    final priceLabel = priceText != null ? ' Price: $priceText per night.' : '';

    return '$dateStr. $statusLabel.$priceLabel';
  }
}

