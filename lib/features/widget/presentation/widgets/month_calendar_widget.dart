import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/models/calendar_date_status.dart';
import '../providers/month_calendar_provider.dart';
import '../providers/calendar_view_provider.dart';
import 'split_day_calendar_painter.dart';
import 'calendar_hover_tooltip.dart';
import 'calendar_view_switcher.dart';
import '../theme/responsive_helper.dart';
import '../../../../../core/design_tokens/design_tokens.dart';

class MonthCalendarWidget extends ConsumerStatefulWidget {
  final String unitId;
  final Function(DateTime? start, DateTime? end)? onRangeSelected;

  const MonthCalendarWidget({
    super.key,
    required this.unitId,
    this.onRangeSelected,
  });

  @override
  ConsumerState<MonthCalendarWidget> createState() => _MonthCalendarWidgetState();
}

class _MonthCalendarWidgetState extends ConsumerState<MonthCalendarWidget> {
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _hoveredDate; // For hover tooltip (desktop)
  Offset _mousePosition = Offset.zero; // Track mouse position for tooltip

  @override
  Widget build(BuildContext context) {
    final calendarData = ref.watch(monthCalendarDataProvider((widget.unitId, _currentMonth)));

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        // Deselect dates when clicking outside the calendar
        if (_rangeStart != null || _rangeEnd != null) {
          setState(() {
            _rangeStart = null;
            _rangeEnd = null;
          });
          widget.onRangeSelected?.call(null, null);
        }
      },
      child: Stack(
        children: [
          Column(
            children: [
              // Combined header for all screen sizes
              _buildCombinedHeader(context),
              const SizedBox(height: SpacingTokens.m),

              // Calendar with LayoutBuilder for proper sizing
              Expanded(
                child: calendarData.when(
                  data: (data) => _buildMonthView(data),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(
                    child: Text('Error: $error'),
                  ),
                ),
              ),
            ],
          ),
          // Hover tooltip overlay (desktop)
          if (_hoveredDate != null)
            calendarData.when(
              data: (data) => _buildHoverTooltip(data),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
        ],
      ),
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
          // Week view tab hidden but code kept for future use
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
                child: _buildCompactMonthNavigation(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactMonthNavigation() {
    final monthYear = DateFormat.yMMM().format(_currentMonth);

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
              _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
            });
          },
        ),
        Text(
          monthYear,
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
              _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
            });
          },
        ),
      ],
    );
  }

  Widget _buildMonthView(Map<String, CalendarDateInfo> data) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        final maxHeight = screenHeight * 0.75; // 75% of screen height

        // Desktop: Show 1 month + booking sidebar (>= 1024px)
        final isDesktop = screenWidth >= 1024;

        if (isDesktop) {
          return _buildDesktopLayoutWithSidebar(data, maxHeight);
        } else {
          // Tablet & Mobile: Show 1 month + booking flow below (if dates selected)
          return _buildMobileLayout(data, maxHeight);
        }
      },
    );
  }

  Widget _buildDesktopLayoutWithSidebar(Map<String, CalendarDateInfo> data, double maxHeight) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 650,
          maxHeight: maxHeight,
        ),
        child: _buildSingleMonthGrid(_currentMonth, data, maxHeight),
      ),
    );
  }

  Widget _buildMobileLayout(Map<String, CalendarDateInfo> data, double maxHeight) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: maxHeight,
        ),
        child: _buildSingleMonthGrid(_currentMonth, data, maxHeight),
      ),
    );
  }

  Widget _buildSingleMonthGrid(DateTime month, Map<String, CalendarDateInfo> data, double maxHeight) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Month name header
        _buildMonthHeader(month),
        const SizedBox(height: SpacingTokens.m),
        // Week day headers
        _buildWeekDayHeaders(),
        const SizedBox(height: SpacingTokens.s),
        // Calendar grid
        Flexible(
          child: _buildMonthGridForMonth(month, data),
        ),
      ],
    );
  }

  Widget _buildMonthHeader(DateTime month) {
    final monthName = DateFormat.yMMMM().format(month);
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: SpacingTokens.xs2 + SpacingTokens.xs,
        horizontal: SpacingTokens.m,
      ),
      decoration: BoxDecoration(
        color: ColorTokens.light.backgroundSecondary,
        borderRadius: BorderTokens.circularMedium,
        boxShadow: ShadowTokens.subtle,
      ),
      child: Text(
        monthName,
        style: TextStyle(
          fontSize: TypographyTokens.fontSizeL,
          fontWeight: TypographyTokens.bold,
          color: ColorTokens.light.textPrimary,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildWeekDayHeaders() {
    final weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Row(
      children: weekDays.map((day) {
        return Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: SpacingTokens.s),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: ColorTokens.light.backgroundTertiary,
              border: Border.all(
                color: ColorTokens.light.borderDefault,
                width: BorderTokens.widthThin,
              ),
              borderRadius: BorderTokens.circularSubtle,
            ),
            child: Text(
              day,
              style: TextStyle(
                fontWeight: TypographyTokens.bold,
                fontSize: TypographyTokens.fontSizeXS2,
                color: ColorTokens.light.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMonthGridForMonth(DateTime month, Map<String, CalendarDateInfo> data) {
    // Get first day of month
    final firstDay = DateTime(month.year, month.month, 1);

    // Get last day of month
    final lastDay = DateTime(month.year, month.month + 1, 0);

    // Calculate how many days from previous month to show
    final firstWeekday = firstDay.weekday; // 1 = Monday, 7 = Sunday
    final daysFromPrevMonth = firstWeekday - 1;

    // Calculate total cells needed (should be 4-6 weeks)
    final totalDays = lastDay.day;
    final totalCells = daysFromPrevMonth + totalDays;
    final weeksNeeded = (totalCells / 7).ceil();

    final cellGap = SpacingTokens.calendarCellGap(context);
    final isMobile = ResponsiveHelper.isMobile(context);

    // Responsive aspect ratio: mobile gets perfect squares, desktop gets slightly taller cells
    final aspectRatio = isMobile ? 1.0 : 0.95;

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: cellGap,
        crossAxisSpacing: cellGap,
        childAspectRatio: aspectRatio, // Responsive: 1.0 on mobile, 0.95 on desktop
      ),
      itemCount: weeksNeeded * 7,
      itemBuilder: (context, index) {
        final dayOffset = index - daysFromPrevMonth;

        if (dayOffset < 0 || dayOffset >= totalDays) {
          // Days from previous or next month
          return _buildEmptyCell();
        }

        final date = DateTime(month.year, month.month, dayOffset + 1);
        return _buildDayCell(date, data);
      },
    );
  }

  Widget _buildDayCell(DateTime date, Map<String, CalendarDateInfo> data) {
    final key = _getDateKey(date);
    final dateInfo = data[key];

    if (dateInfo == null) {
      return _buildEmptyCell();
    }

    final isInRange = _isDateInRange(date);
    final isRangeStart = _rangeStart != null && _isSameDay(date, _rangeStart!);
    final isRangeEnd = _rangeEnd != null && _isSameDay(date, _rangeEnd!);
    final isToday = _isSameDay(date, DateTime.now());

    // Get price text for display
    final priceText = dateInfo.formattedPrice;

    final isHovered = _hoveredDate != null && _isSameDay(date, _hoveredDate!);

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredDate = date),
      onExit: (_) => setState(() => _hoveredDate = null),
      onHover: (event) => setState(() => _mousePosition = event.position),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onDateTapped(date, dateInfo, data),
        child: Container(
          margin: const EdgeInsets.all(BorderTokens.widthThin),
          decoration: BoxDecoration(
            border: Border.all(
              color: isRangeStart || isRangeEnd
                  ? ColorTokens.light.buttonPrimary
                  : isToday
                      ? ColorTokens.light.borderStrong
                      : isHovered
                          ? ColorTokens.light.borderStrong
                          : _getBorderColorForDate(dateInfo.status),
              // Border width hierarchy: selected/today (thick) > hover/normal (medium)
              width: (isRangeStart || isRangeEnd || isToday)
                  ? BorderTokens.widthThick
                  : BorderTokens.widthMedium,
            ),
            borderRadius: BorderTokens.calendarCell,
            boxShadow: isHovered
                ? ShadowTokens.hover
                : ShadowTokens.light,
          ),
        child: Stack(
          children: [
            // Background with diagonal split and price
            ClipRRect(
              borderRadius: BorderTokens.calendarCell,
              child: CustomPaint(
                painter: SplitDayCalendarPainter(
                  // Preserve partialCheckIn/Out status even when in range
                  status: isInRange &&
                          dateInfo.status != DateStatus.partialCheckIn &&
                          dateInfo.status != DateStatus.partialCheckOut
                      ? DateStatus.available
                      : dateInfo.status,
                  borderColor: dateInfo.status.getBorderColor(),
                  priceText: priceText,
                ),
                child: const SizedBox.expand(),
              ),
            ),
            // Day number overlay
            Positioned(
              top: SpacingTokens.xs,
              left: SpacingTokens.xs,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: SpacingTokens.xs,
                  vertical: SpacingTokens.xxs,
                ),
                decoration: BoxDecoration(
                  color: ColorTokens.withOpacity(
                    ColorTokens.pureWhite,
                    OpacityTokens.almostOpaque,
                  ),
                  borderRadius: BorderTokens.circularSubtle,
                ),
                child: Text(
                  date.day.toString(),
                  style: TextStyle(
                    fontSize: TypographyTokens.fontSizeS,
                    fontWeight: TypographyTokens.semiBold,
                    color: ColorTokens.light.textPrimary,
                  ),
                ),
              ),
            ),
            // Range indicators
            if (isRangeStart || isRangeEnd)
              Positioned(
                bottom: SpacingTokens.xs,
                right: SpacingTokens.xs,
                child: Container(
                  padding: const EdgeInsets.all(SpacingTokens.xxs),
                  decoration: BoxDecoration(
                    color: ColorTokens.light.buttonPrimary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isRangeStart ? Icons.login : Icons.logout,
                    size: IconSizeTokens.xs,
                    color: ColorTokens.light.buttonPrimaryText,
                  ),
                ),
              ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildEmptyCell() {
    return Container(
      margin: const EdgeInsets.all(BorderTokens.widthThin),
      decoration: BoxDecoration(
        color: ColorTokens.light.backgroundSecondary,
        border: Border.all(
          color: ColorTokens.light.borderLight,
          width: BorderTokens.widthThin,
        ),
        borderRadius: BorderTokens.circularSubtle,
      ),
      child: const Opacity(
        opacity: OpacityTokens.mostlyVisible,
        child: SizedBox.expand(),
      ),
    );
  }

  Widget _buildHoverTooltip(Map<String, CalendarDateInfo> data) {
    if (_hoveredDate == null) return const SizedBox.shrink();

    final key = _getDateKey(_hoveredDate!);
    final dateInfo = data[key];

    if (dateInfo == null) return const SizedBox.shrink();

    // Use actual mouse position for tooltip
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Position tooltip near mouse, offset slightly to avoid cursor overlap
    // Tooltip width is ~200px, height is ~120px
    final tooltipWidth = 200.0;
    final tooltipHeight = 120.0;

    // Offset tooltip to the right and up from cursor
    double xPosition = _mousePosition.dx + 10;
    double yPosition = _mousePosition.dy - tooltipHeight - 10;

    // Keep tooltip within screen bounds
    if (xPosition + tooltipWidth > screenWidth) {
      xPosition = _mousePosition.dx - tooltipWidth - 10; // Show on left instead
    }
    if (yPosition < 20) {
      yPosition = _mousePosition.dy + 20; // Show below cursor instead
    }

    xPosition = xPosition.clamp(20, screenWidth - tooltipWidth - 20);
    yPosition = yPosition.clamp(20, screenHeight - tooltipHeight - 20);

    return CalendarHoverTooltip(
      date: _hoveredDate!,
      price: dateInfo.price,
      status: dateInfo.status,
      position: Offset(xPosition, yPosition),
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
            const SnackBar(
              content: Text('Cannot select dates. There are already booked dates in this range.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
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

  /// Get darker border color for calendar cell based on status
  Color _getBorderColorForDate(DateStatus status) {
    switch (status) {
      case DateStatus.available:
      case DateStatus.partialCheckIn:
      case DateStatus.partialCheckOut:
        return ColorTokens.light.statusAvailableBorder;
      case DateStatus.booked:
        return ColorTokens.light.statusBookedBorder;
      case DateStatus.pending:
        return ColorTokens.light.statusPendingBorder;
      case DateStatus.blocked:
      case DateStatus.disabled:
        return ColorTokens.light.borderDefault;
    }
  }
}
