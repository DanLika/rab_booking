import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/models/calendar_date_status.dart';
import '../providers/year_calendar_provider.dart';
import '../providers/calendar_view_provider.dart';
import '../theme/responsive_helper.dart';
import '../../../../core/design_tokens/design_tokens.dart';
import 'calendar_view_switcher.dart';

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
        // Combined header matching month/week view layout
        _buildCombinedHeader(context),
        const SizedBox(height: SpacingTokens.m),
        Expanded(
          child: calendarData.when(
            data: (data) => _buildYearGridWithIntegratedSelector(data),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Text('Error: $error'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildViewSwitcher(BuildContext context) {
    final currentView = ref.watch(calendarViewProvider);

    return Container(
      decoration: BoxDecoration(
        color: ColorTokens.light.backgroundSecondary,
        borderRadius: BorderTokens.circularMedium,
      ),
      child: Row(
        children: [
          // Week view hidden but code kept for future use
          // _buildViewTab('Week', Icons.view_week, CalendarViewType.week, currentView == CalendarViewType.week),
          _buildViewTab('Month', Icons.calendar_month, CalendarViewType.month, currentView == CalendarViewType.month),
          _buildViewTab('Year', Icons.calendar_today, CalendarViewType.year, currentView == CalendarViewType.year),
        ],
      ),
    );
  }

  Widget _buildViewTab(String label, IconData icon, CalendarViewType viewType, bool isSelected) {
    return Expanded(
      child: Semantics(
        label: '$label view',
        button: true,
        selected: isSelected,
        child: InkWell(
          onTap: () {
            ref.read(calendarViewProvider.notifier).state = viewType;
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: SpacingTokens.s),
            decoration: BoxDecoration(
              color: isSelected ? ColorTokens.light.buttonPrimary : Colors.transparent,
              borderRadius: BorderTokens.circularMedium,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: isSelected ? ColorTokens.light.buttonPrimaryText : ColorTokens.light.textSecondary,
                  size: IconSizeTokens.small,
                  semanticLabel: label,
                ),
                const SizedBox(height: SpacingTokens.xxs),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? ColorTokens.light.buttonPrimaryText : ColorTokens.light.textSecondary,
                    fontSize: TypographyTokens.fontSizeS2,
                    fontWeight: isSelected ? TypographyTokens.bold : TypographyTokens.regular,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCombinedHeader(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 980),
        child: Container(
          padding: SpacingTokens.allM,
          decoration: BoxDecoration(
            color: ColorTokens.light.backgroundSecondary,
            borderRadius: BorderTokens.circularRounded,
            boxShadow: ShadowTokens.light,
          ),
          child: Row(
            children: [
              // View Switcher - 70%
              Expanded(
                flex: 7,
                child: _buildViewSwitcher(context),
              ),
              const SizedBox(width: SpacingTokens.s2),

              // Compact Navigation - 30%
              Expanded(
                flex: 3,
                child: _buildCompactYearNavigation(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactYearNavigation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left, size: IconSizeTokens.small),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: ConstraintTokens.iconContainerSmall,
            minHeight: ConstraintTokens.iconContainerSmall,
          ),
          onPressed: () {
            setState(() {
              _currentYear--;
            });
          },
        ),
        Text(
          _currentYear.toString(),
          style: const TextStyle(
            fontSize: TypographyTokens.fontSizeM,
            fontWeight: TypographyTokens.bold,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right, size: IconSizeTokens.small),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: ConstraintTokens.iconContainerSmall,
            minHeight: ConstraintTokens.iconContainerSmall,
          ),
          onPressed: () {
            setState(() {
              _currentYear++;
            });
          },
        ),
      ],
    );
  }


  Widget _buildYearGridWithIntegratedSelector(Map<String, CalendarDateInfo> data) {
    // Get responsive cell size
    final cellSize = ResponsiveHelper.getYearCellSize(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;

    return Padding(
      padding: EdgeInsets.all(isDesktop ? SpacingTokens.m : SpacingTokens.xs),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SizedBox(
            width: ConstraintTokens.monthLabelWidth + (31 * cellSize), // Month label width + 31 day columns
            child: Column(
              children: [
                _buildHeaderRowWithYearSelector(cellSize),
                const SizedBox(height: SpacingTokens.xs),
                ...List.generate(12, (monthIndex) => _buildMonthRow(monthIndex + 1, data, cellSize)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderRowWithYearSelector(double cellSize) {
    return Row(
      children: [
        // Static "Month" label in top-left corner
        Container(
          width: ConstraintTokens.monthLabelWidth,
          height: cellSize,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: ColorTokens.light.buttonPrimary,
            border: Border.all(
              color: ColorTokens.light.borderDefault,
              width: BorderTokens.widthThin,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(BorderTokens.radiusSubtle),
            ),
          ),
          child: Text(
            'Month',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: TypographyTokens.fontSizeXS2,
              color: ColorTokens.light.buttonPrimaryText,
            ),
          ),
        ),
        // Day number headers
        ...List.generate(31, (dayIndex) {
          return Container(
            width: cellSize,
            height: cellSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: ColorTokens.light.backgroundTertiary,
              border: Border.all(
                color: ColorTokens.light.borderDefault,
                width: BorderTokens.widthThin,
              ),
              borderRadius: dayIndex == 30
                  ? const BorderRadius.only(topRight: Radius.circular(BorderTokens.radiusSubtle))
                  : BorderRadius.zero,
            ),
            child: Text(
              (dayIndex + 1).toString(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: TypographyTokens.fontSizeXS2,
              ),
            ),
          );
        }),
      ],
    );
  }


  Widget _buildMonthRow(int month, Map<String, CalendarDateInfo> data, double cellSize) {
    final monthName = DateFormat.MMM().format(DateTime(_currentYear, month));

    return Row(
      children: [
        // Month label
        Container(
          width: ConstraintTokens.monthLabelWidth,
          height: cellSize,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: ColorTokens.light.backgroundTertiary,
            border: Border.all(
              color: ColorTokens.light.borderDefault,
              width: BorderTokens.widthThin,
            ),
            borderRadius: month == 12
                ? const BorderRadius.only(bottomLeft: Radius.circular(BorderTokens.radiusSubtle))
                : BorderRadius.zero,
          ),
          child: Text(
            monthName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: TypographyTokens.fontSizeXS2,
            ),
          ),
        ),
        // Day cells
        ...List.generate(31, (dayIndex) {
          final day = dayIndex + 1;
          return _buildDayCell(month, day, data, cellSize);
        }),
      ],
    );
  }

  Widget _buildDayCell(int month, int day, Map<String, CalendarDateInfo> data, double cellSize) {
    // Check if this day exists in this month
    try {
      final date = DateTime(_currentYear, month, day);
      final key = _getDateKey(date);
      final dateInfo = data[key];

      if (dateInfo == null) {
        // Day doesn't exist in this month or no data
        return _buildEmptyCell(cellSize);
      }

      final isInRange = _isDateInRange(date);
      final isRangeStart = _rangeStart != null && _isSameDay(date, _rangeStart!);
      final isRangeEnd = _rangeEnd != null && _isSameDay(date, _rangeEnd!);

      // Determine if this is a check-in or check-out day
      final isPartialCheckIn = dateInfo.status == DateStatus.partialCheckIn;
      final isPartialCheckOut = dateInfo.status == DateStatus.partialCheckOut;

      return GestureDetector(
        onTap: () => _onDateTapped(date, dateInfo, data),
        child: Container(
          width: cellSize,
          height: cellSize,
          decoration: BoxDecoration(
            color: isInRange ? ColorTokens.light.backgroundTertiary : dateInfo.status.getColor(),
            border: Border.all(
              color: isRangeStart || isRangeEnd
                  ? ColorTokens.light.borderStrong
                  : dateInfo.status.getBorderColor(),
              width: isRangeStart || isRangeEnd ? BorderTokens.widthMedium : BorderTokens.widthThin,
            ),
            borderRadius: BorderTokens.circularTiny,
            boxShadow: ColorTokens.light.shadowMinimal,
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
      return _buildEmptyCell(cellSize);
    }
  }

  Widget _buildEmptyCell(double cellSize) {
    return Container(
      width: cellSize,
      height: cellSize,
      decoration: BoxDecoration(
        color: ColorTokens.light.backgroundSecondary,
        border: Border.all(
          color: ColorTokens.light.borderLight,
          width: BorderTokens.widthThin,
        ),
        borderRadius: BorderTokens.circularTiny,
      ),
    );
  }

  void _onDateTapped(DateTime date, CalendarDateInfo dateInfo, Map<String, CalendarDateInfo> data) {
    if (dateInfo.status != DateStatus.available &&
        dateInfo.status != DateStatus.partialCheckIn &&
        dateInfo.status != DateStatus.partialCheckOut) {
      // Can't select booked, pending, blocked, or disabled dates
      return;
    }

    setState(() {
      if (_rangeStart == null || (_rangeStart != null && _rangeEnd != null)) {
        // Start new range
        _rangeStart = date;
        _rangeEnd = null;
      } else if (_rangeStart != null && _rangeEnd == null) {
        // Complete range - validate no booked dates in between
        final DateTime start = date.isBefore(_rangeStart!) ? date : _rangeStart!;
        final DateTime end = date.isBefore(_rangeStart!) ? _rangeStart! : date;

        // Check if there are any booked/pending dates in the range
        if (_hasBlockedDatesInRange(start, end, data)) {
          // Reset selection and show error
          _rangeStart = null;
          _rangeEnd = null;

          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Cannot select dates. There are already booked dates in this range.'),
              backgroundColor: ColorTokens.light.error,
              duration: const Duration(seconds: 3),
            ),
          );
          return;
        }

        // No blocked dates, set the range
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

  /// Check if there are any booked or pending dates between start and end (inclusive)
  bool _hasBlockedDatesInRange(DateTime start, DateTime end, Map<String, CalendarDateInfo> data) {
    DateTime current = start;
    while (current.isBefore(end) || _isSameDay(current, end)) {
      final key = _getDateKey(current);
      final dateInfo = data[key];

      if (dateInfo != null &&
          (dateInfo.status == DateStatus.booked ||
           dateInfo.status == DateStatus.pending)) {
        return true; // Found a blocked date
      }

      current = current.add(const Duration(days: 1));
    }
    return false; // No blocked dates found
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
