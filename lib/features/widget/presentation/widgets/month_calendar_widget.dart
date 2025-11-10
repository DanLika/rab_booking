import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/models/calendar_date_status.dart';
import '../providers/month_calendar_provider.dart';
import '../providers/calendar_view_provider.dart';
import '../providers/theme_provider.dart';
import 'split_day_calendar_painter.dart';
import 'calendar_hover_tooltip.dart';
import 'calendar_view_switcher.dart';
import '../theme/responsive_helper.dart';
import '../../../../../core/design_tokens/design_tokens.dart';
import '../../../../core/theme/custom_icons_tablericons.dart';

class MonthCalendarWidget extends ConsumerStatefulWidget {
  final String unitId;
  final Function(DateTime? start, DateTime? end)? onRangeSelected;

  const MonthCalendarWidget({
    super.key,
    required this.unitId,
    this.onRangeSelected,
  });

  @override
  ConsumerState<MonthCalendarWidget> createState() =>
      _MonthCalendarWidgetState();
}

class _MonthCalendarWidgetState extends ConsumerState<MonthCalendarWidget> {
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _hoveredDate; // For hover tooltip (desktop)
  Offset _mousePosition = Offset.zero; // Track mouse position for tooltip

  @override
  Widget build(BuildContext context) {
    final calendarData = ref.watch(
      monthCalendarDataProvider((widget.unitId, _currentMonth)),
    );
    final isDarkMode = ref.watch(themeProvider);
    final colors = isDarkMode ? ColorTokens.dark : ColorTokens.light;

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
              _buildCombinedHeader(context, colors, isDarkMode),
              const SizedBox(height: SpacingTokens.xs),

              // Calendar with LayoutBuilder for proper sizing
              Expanded(
                child: calendarData.when(
                  data: (data) => _buildMonthView(data, colors),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(child: Text('Error: $error')),
                ),
              ),
            ],
          ),
          // Hover tooltip overlay (desktop) - highest z-index
          if (_hoveredDate != null)
            calendarData.when(
              data: (data) => _buildHoverTooltip(data, colors),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }

  Widget _buildViewSwitcher(BuildContext context, WidgetColorScheme colors) {
    final currentView = ref.watch(calendarViewProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400; // iPhone SE and similar
    final isDarkMode = ref.watch(themeProvider);

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 2 : 4),
      decoration: BoxDecoration(
        color: colors.backgroundSecondary,
        borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
        border: Border.all(color: colors.borderLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Week view tab hidden but code kept for future use
          // _buildViewTab('Week', TablerIcons.kviewWeek, CalendarViewType.week, currentView == CalendarViewType.week, isSmallScreen, colors, isDarkMode),
          _buildViewTab(
            'Month',
            TablerIcons.ktableFilled,
            CalendarViewType.month,
            currentView == CalendarViewType.month,
            isSmallScreen,
            colors,
            isDarkMode,
          ),
          SizedBox(width: isSmallScreen ? 2 : 4),
          _buildViewTab(
            'Year',
            TablerIcons.ktableOptions,
            CalendarViewType.year,
            currentView == CalendarViewType.year,
            isSmallScreen,
            colors,
            isDarkMode,
          ),
        ],
      ),
    );
  }

  Widget _buildViewTab(
    String label,
    IconData icon,
    CalendarViewType viewType,
    bool isSelected,
    bool isSmallScreen,
    WidgetColorScheme colors,
    bool isDarkMode,
  ) {
    // Dark theme: selected button has white background with black text
    // Light theme: selected button has black background with white text
    final selectedBg = isDarkMode
        ? ColorTokens.pureWhite
        : ColorTokens.pureBlack;
    final selectedText = isDarkMode
        ? ColorTokens.pureBlack
        : ColorTokens.pureWhite;

    return Semantics(
      label: '$label view',
      button: true,
      selected: isSelected,
      child: InkWell(
        onTap: () {
          ref.read(calendarViewProvider.notifier).state = viewType;
        },
        borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 8 : 12,
            vertical: isSmallScreen ? 6 : 8,
          ),
          decoration: BoxDecoration(
            color: isSelected ? selectedBg : Colors.transparent,
            borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? selectedText : colors.textPrimary,
                size: isSmallScreen ? 16 : IconSizeTokens.small,
                semanticLabel: label,
              ),
              if (!isSmallScreen) ...[
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? selectedText : colors.textPrimary,
                    fontSize: TypographyTokens.fontSizeS2,
                    fontWeight: isSelected
                        ? TypographyTokens.semiBold
                        : TypographyTokens.regular,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCombinedHeader(
    BuildContext context,
    WidgetColorScheme colors,
    bool isDarkMode,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400; // iPhone SE and similar

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.xs),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? SpacingTokens.xxs : SpacingTokens.xs,
          vertical: SpacingTokens.xxs,
        ),
        decoration: BoxDecoration(
          color: colors.backgroundSecondary,
          borderRadius: BorderTokens.circularRounded,
          boxShadow: ShadowTokens.light,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // View Switcher
            _buildViewSwitcher(context, colors),
            SizedBox(width: isSmallScreen ? 4 : SpacingTokens.xxs),

            // Theme Toggle Button
            IconButton(
              icon: Icon(
                isDarkMode ? Icons.light_mode : Icons.dark_mode,
                size: isSmallScreen ? 16 : IconSizeTokens.small,
                color: colors.textPrimary,
              ),
              onPressed: () {
                ref.read(themeProvider.notifier).state = !isDarkMode;
              },
              tooltip: isDarkMode
                  ? 'Switch to Light Mode'
                  : 'Switch to Dark Mode',
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(
                minWidth: isSmallScreen
                    ? 28
                    : ConstraintTokens.iconContainerSmall,
                minHeight: isSmallScreen
                    ? 28
                    : ConstraintTokens.iconContainerSmall,
              ),
            ),

            SizedBox(width: isSmallScreen ? 4 : SpacingTokens.xxs),

            // Compact Navigation
            _buildCompactMonthNavigation(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactMonthNavigation(WidgetColorScheme colors) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400; // iPhone SE and similar
    final monthYear = DateFormat.yMMM().format(_currentMonth);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            Icons.chevron_left,
            size: isSmallScreen ? 16 : IconSizeTokens.small,
            color: colors.textPrimary,
          ),
          padding: EdgeInsets.zero,
          constraints: BoxConstraints(
            minWidth: isSmallScreen ? 28 : ConstraintTokens.iconContainerSmall,
            minHeight: isSmallScreen ? 28 : ConstraintTokens.iconContainerSmall,
          ),
          onPressed: () {
            setState(() {
              _currentMonth = DateTime(
                _currentMonth.year,
                _currentMonth.month - 1,
              );
            });
          },
        ),
        Text(
          monthYear,
          style: TextStyle(
            fontSize: isSmallScreen
                ? TypographyTokens.fontSizeS
                : TypographyTokens.fontSizeM,
            fontWeight: TypographyTokens.bold,
            color: colors.textPrimary,
          ),
        ),
        IconButton(
          icon: Icon(
            Icons.chevron_right,
            size: isSmallScreen ? 16 : IconSizeTokens.small,
            color: colors.textPrimary,
          ),
          padding: EdgeInsets.zero,
          constraints: BoxConstraints(
            minWidth: isSmallScreen ? 28 : ConstraintTokens.iconContainerSmall,
            minHeight: isSmallScreen ? 28 : ConstraintTokens.iconContainerSmall,
          ),
          onPressed: () {
            setState(() {
              _currentMonth = DateTime(
                _currentMonth.year,
                _currentMonth.month + 1,
              );
            });
          },
        ),
      ],
    );
  }

  Widget _buildMonthView(
    Map<String, CalendarDateInfo> data,
    WidgetColorScheme colors,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        final maxHeight =
            screenHeight *
            0.85; // 85% of screen height - booking bar is now floating overlay

        // Desktop: Show 1 month + booking sidebar (>= 1024px)
        final isDesktop = screenWidth >= 1024;

        if (isDesktop) {
          return _buildDesktopLayoutWithSidebar(data, maxHeight, colors);
        } else {
          // Tablet & Mobile: Show 1 month + booking flow below (if dates selected)
          return _buildMobileLayout(data, maxHeight, colors);
        }
      },
    );
  }

  Widget _buildDesktopLayoutWithSidebar(
    Map<String, CalendarDateInfo> data,
    double maxHeight,
    WidgetColorScheme colors,
  ) {
    return Center(
      child: SizedBox(
        width: 650,
        height: maxHeight,
        child: _buildSingleMonthGrid(_currentMonth, data, maxHeight, colors),
      ),
    );
  }

  Widget _buildMobileLayout(
    Map<String, CalendarDateInfo> data,
    double maxHeight,
    WidgetColorScheme colors,
  ) {
    return Center(
      child: SizedBox(
        width: 600,
        height: maxHeight,
        child: _buildSingleMonthGrid(_currentMonth, data, maxHeight, colors),
      ),
    );
  }

  Widget _buildSingleMonthGrid(
    DateTime month,
    Map<String, CalendarDateInfo> data,
    double maxHeight,
    WidgetColorScheme colors,
  ) {
    return Column(
      children: [
        // Month name header
        _buildMonthHeader(month, colors),
        const SizedBox(height: SpacingTokens.xs),
        // Week day headers
        _buildWeekDayHeaders(colors),
        const SizedBox(height: SpacingTokens.xs),
        // Calendar grid - takes remaining space
        Expanded(
          child: SingleChildScrollView(
            child: _buildMonthGridForMonth(month, data, colors),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthHeader(DateTime month, WidgetColorScheme colors) {
    final monthName = DateFormat.yMMMM().format(month);
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: SpacingTokens.xs,
        horizontal: SpacingTokens.s,
      ),
      decoration: BoxDecoration(
        color: colors.backgroundSecondary,
        borderRadius: BorderTokens.circularMedium,
        boxShadow: ShadowTokens.subtle,
      ),
      child: Text(
        monthName,
        style: TextStyle(
          fontSize: TypographyTokens.fontSizeL,
          fontWeight: TypographyTokens.bold,
          color: colors.textPrimary,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildWeekDayHeaders(WidgetColorScheme colors) {
    final weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Row(
      children: weekDays.map((day) {
        return Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: SpacingTokens.s),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.backgroundTertiary,
              border: Border.all(color: colors.borderDefault),
              borderRadius: BorderTokens.circularSubtle,
            ),
            child: Text(
              day,
              style: TextStyle(
                fontWeight: TypographyTokens.bold,
                fontSize: TypographyTokens.fontSizeXS2,
                color: colors.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMonthGridForMonth(
    DateTime month,
    Map<String, CalendarDateInfo> data,
    WidgetColorScheme colors,
  ) {
    // Get first day of month
    final firstDay = DateTime(month.year, month.month);

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
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: cellGap,
        crossAxisSpacing: cellGap,
        childAspectRatio:
            aspectRatio, // Responsive: 1.0 on mobile, 0.95 on desktop
      ),
      itemCount: weeksNeeded * 7,
      itemBuilder: (context, index) {
        final dayOffset = index - daysFromPrevMonth;

        if (dayOffset < 0 || dayOffset >= totalDays) {
          // Days from previous or next month
          return _buildEmptyCell(colors);
        }

        final date = DateTime(month.year, month.month, dayOffset + 1);
        return _buildDayCell(date, data, colors);
      },
    );
  }

  Widget _buildDayCell(
    DateTime date,
    Map<String, CalendarDateInfo> data,
    WidgetColorScheme colors,
  ) {
    final key = _getDateKey(date);
    final dateInfo = data[key];

    if (dateInfo == null) {
      return _buildEmptyCell(colors);
    }

    final isInRange = _isDateInRange(date);
    final isRangeStart = _rangeStart != null && _isSameDay(date, _rangeStart!);
    final isRangeEnd = _rangeEnd != null && _isSameDay(date, _rangeEnd!);
    final today = DateTime.now();
    final todayNormalized = DateTime(today.year, today.month, today.day);
    final isToday = _isSameDay(date, today);
    final isPast = date.isBefore(todayNormalized);

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
                  ? colors.textPrimary
                  : isToday
                  ? colors.textPrimary
                  : isHovered
                  ? colors.borderStrong
                  : _getBorderColorForDate(dateInfo.status, colors),
              // Border width hierarchy: selected/today (thick) > hover/normal (medium)
              width: (isRangeStart || isRangeEnd || isToday)
                  ? BorderTokens.widthThick
                  : BorderTokens.widthMedium,
            ),
            borderRadius: BorderTokens.calendarCell,
            boxShadow: isHovered ? ShadowTokens.hover : ShadowTokens.light,
          ),
          child: Stack(
            children: [
              // Background with diagonal split and price
              ClipRRect(
                borderRadius: BorderTokens.calendarCell,
                child: CustomPaint(
                  painter: SplitDayCalendarPainter(
                    // Preserve partialCheckIn/Out status even when in range
                    status:
                        isInRange &&
                            dateInfo.status != DateStatus.partialCheckIn &&
                            dateInfo.status != DateStatus.partialCheckOut
                        ? DateStatus.available
                        : dateInfo.status,
                    borderColor: dateInfo.status.getBorderColor(colors),
                    priceText: priceText,
                    colors: colors,
                    isInRange: isInRange,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
              // Day number overlay - centered
              Center(
                child: Opacity(
                  opacity: isPast ? 0.5 : 1.0, // 50% opacity for past dates
                  child: Text(
                    date.day.toString(),
                    style: TextStyle(
                      fontSize: TypographyTokens.fontSizeL,
                      fontWeight: TypographyTokens.bold,
                      color: colors.textPrimary,
                      shadows: [
                        Shadow(
                          offset: const Offset(0, 1),
                          blurRadius: 2.0,
                          color: colors.backgroundPrimary.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ],
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
                      color: colors.textPrimary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isRangeStart ? Icons.login : Icons.logout,
                      size: IconSizeTokens.xs,
                      color: colors.backgroundPrimary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCell(WidgetColorScheme colors) {
    return Container(
      margin: const EdgeInsets.all(BorderTokens.widthThin),
      decoration: BoxDecoration(
        color: colors.backgroundSecondary,
        border: Border.all(color: colors.borderLight),
        borderRadius: BorderTokens.circularSubtle,
      ),
      child: const Opacity(
        opacity: OpacityTokens.mostlyVisible,
        child: SizedBox.expand(),
      ),
    );
  }

  Widget _buildHoverTooltip(
    Map<String, CalendarDateInfo> data,
    WidgetColorScheme colors,
  ) {
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

    return Positioned(
      left: xPosition,
      top: yPosition,
      child: CalendarHoverTooltip(
        date: _hoveredDate!,
        price: dateInfo.price,
        status: dateInfo.status,
        position: Offset(xPosition, yPosition),
        colors: colors,
      ),
    );
  }

  void _onDateTapped(
    DateTime date,
    CalendarDateInfo dateInfo,
    Map<String, CalendarDateInfo> data,
  ) {
    // Only allow available dates to be selected
    // partialCheckIn, partialCheckOut, and pending are blocked from selection
    if (dateInfo.status != DateStatus.available) {
      return;
    }

    setState(() {
      if (_rangeStart == null || (_rangeStart != null && _rangeEnd != null)) {
        // Start new range
        _rangeStart = date;
        _rangeEnd = null;
      } else if (_rangeStart != null && _rangeEnd == null) {
        // Complete range - validate no booked dates in between
        final DateTime start = date.isBefore(_rangeStart!)
            ? date
            : _rangeStart!;
        final DateTime end = date.isBefore(_rangeStart!) ? _rangeStart! : date;

        // Check if there are any booked/pending dates in the range
        if (_hasBlockedDatesInRange(start, end, data)) {
          // Reset selection and show error
          _rangeStart = null;
          _rangeEnd = null;

          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Cannot select dates. There are already booked dates in this range.',
              ),
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

  /// Check if there are any booked, pending, or partial dates between start and end (inclusive)
  /// Partial dates (partialCheckIn/partialCheckOut) are allowed at endpoints but not in between
  bool _hasBlockedDatesInRange(
    DateTime start,
    DateTime end,
    Map<String, CalendarDateInfo> data,
  ) {
    DateTime current = start;
    while (current.isBefore(end) || _isSameDay(current, end)) {
      final key = _getDateKey(current);
      final dateInfo = data[key];

      if (dateInfo != null) {
        // Check if this date has a blocking status
        final isBlocked =
            dateInfo.status == DateStatus.booked ||
            dateInfo.status == DateStatus.pending ||
            dateInfo.status == DateStatus.partialCheckIn ||
            dateInfo.status == DateStatus.partialCheckOut ||
            dateInfo.status == DateStatus.blocked;

        if (isBlocked) {
          // Allow partial dates only at the exact start or end points
          // This enables: check-in on a check-out day, and check-out on a check-in day
          final isEndpoint =
              _isSameDay(current, start) || _isSameDay(current, end);
          final isPartialDate =
              dateInfo.status == DateStatus.partialCheckIn ||
              dateInfo.status == DateStatus.partialCheckOut;

          if (!isEndpoint || !isPartialDate) {
            return true; // Found a blocked date that's not an allowed endpoint
          }
        }
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
  Color _getBorderColorForDate(DateStatus status, WidgetColorScheme colors) {
    switch (status) {
      case DateStatus.available:
      case DateStatus.partialCheckIn:
      case DateStatus.partialCheckOut:
        return colors.statusAvailableBorder;
      case DateStatus.booked:
        return colors.statusBookedBorder;
      case DateStatus.pending:
        return colors.statusPendingBorder;
      case DateStatus.blocked:
      case DateStatus.disabled:
        return colors.borderDefault;
      case DateStatus.pastReservation:
        return colors.statusPastReservationBorder;
    }
  }
}
