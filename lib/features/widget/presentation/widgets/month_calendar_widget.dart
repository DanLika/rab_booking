import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/models/calendar_date_status.dart';
import '../../domain/models/calendar_view_type.dart';
import '../providers/month_calendar_provider.dart';
import '../providers/calendar_view_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/widget_settings_provider.dart';
import '../providers/realtime_booking_calendar_provider.dart';
import 'split_day_calendar_painter.dart';
import 'calendar_hover_tooltip.dart';
import '../theme/responsive_helper.dart';
import '../theme/minimalist_colors.dart';
import '../../../../../core/design_tokens/design_tokens.dart';
import '../../../../core/theme/custom_icons_tablericons.dart';

class MonthCalendarWidget extends ConsumerStatefulWidget {
  final String propertyId;
  final String unitId;
  final Function(DateTime? start, DateTime? end)? onRangeSelected;

  const MonthCalendarWidget({
    super.key,
    required this.propertyId,
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
    // Get minNights from widget settings for gap blocking
    final widgetSettings = ref.watch(
      widgetSettingsProvider((widget.propertyId, widget.unitId)),
    );
    final minNights = widgetSettings.value?.minNights ?? 1;

    final calendarData = ref.watch(
      monthCalendarDataProvider((widget.unitId, _currentMonth, minNights)),
    );
    final isDarkMode = ref.watch(themeProvider);
    final colors = MinimalistColorSchemeAdapter(dark: isDarkMode);

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
              // Compact legend/info banner below calendar
              if (minNights > 1)
                _buildCompactLegend(minNights, colors, isDarkMode),
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
              // Bug #70 Fix: Clear range selection when navigating months
              // to prevent cross-month range corruption
              _rangeStart = null;
              _rangeEnd = null;
            });
            // Notify parent that range was cleared
            widget.onRangeSelected?.call(null, null);
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
              // Bug #70 Fix: Clear range selection when navigating months
              // to prevent cross-month range corruption
              _rangeStart = null;
              _rangeEnd = null;
            });
            // Notify parent that range was cleared
            widget.onRangeSelected?.call(null, null);
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
        // Disable tap in calendar_only mode (when onRangeSelected is null)
        onTap: widget.onRangeSelected != null
            ? () => _onDateTapped(date, dateInfo, data, colors)
            : null,
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
    WidgetColorScheme colors,
  ) {
    // Block past dates
    if (dateInfo.status == DateStatus.disabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cannot select past dates.',
            style: TextStyle(color: colors.textPrimary),
          ),
          backgroundColor: colors.statusBookedBackground,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    // Determine if this is check-in or check-out selection
    final isSelectingCheckIn =
        _rangeStart == null || (_rangeStart != null && _rangeEnd != null);
    final isSelectingCheckOut = _rangeStart != null && _rangeEnd == null;

    // Check advance booking window (only for check-in selection)
    if (isSelectingCheckIn) {
      final today = DateTime.now();
      final todayNormalized = DateTime(today.year, today.month, today.day);
      final daysInAdvance = date.difference(todayNormalized).inDays;

      // Check minDaysAdvance
      if (dateInfo.minDaysAdvance != null &&
          daysInAdvance < dateInfo.minDaysAdvance!) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'This date requires booking at least ${dateInfo.minDaysAdvance} days in advance.',
              style: TextStyle(color: colors.textPrimary),
            ),
            backgroundColor: colors.statusBookedBackground,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      // Check maxDaysAdvance
      if (dateInfo.maxDaysAdvance != null &&
          daysInAdvance > dateInfo.maxDaysAdvance!) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'This date can only be booked up to ${dateInfo.maxDaysAdvance} days in advance.',
              style: TextStyle(color: colors.textPrimary),
            ),
            backgroundColor: colors.statusBookedBackground,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }
    }

    // Check blockCheckIn/blockCheckOut restrictions
    if (isSelectingCheckIn && dateInfo.blockCheckIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Check-in is not allowed on this date.',
            style: TextStyle(color: colors.textPrimary),
          ),
          backgroundColor: colors.statusBookedBackground,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    if (isSelectingCheckOut && dateInfo.blockCheckOut) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Check-out is not allowed on this date.',
            style: TextStyle(color: colors.textPrimary),
          ),
          backgroundColor: colors.statusBookedBackground,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    // For check-in: allow available and partialCheckOut (checkout day of previous booking)
    // For check-out: allow available and partialCheckIn (checkin day of next booking)
    final canSelectForCheckIn =
        dateInfo.status == DateStatus.available ||
        dateInfo.status == DateStatus.partialCheckOut;
    final canSelectForCheckOut =
        dateInfo.status == DateStatus.available ||
        dateInfo.status == DateStatus.partialCheckIn;

    if ((isSelectingCheckIn && !canSelectForCheckIn) ||
        (isSelectingCheckOut && !canSelectForCheckOut)) {
      return;
    }

    setState(() {
      if (_rangeStart == null || (_rangeStart != null && _rangeEnd != null)) {
        // Start new range
        _rangeStart = date;
        _rangeEnd = null;
      } else if (_rangeStart != null && _rangeEnd == null) {
        // Cannot select same date as check-in and check-out
        if (_isSameDay(date, _rangeStart!)) {
          return; // Do nothing if clicking on the same date
        }

        // Complete range - validate no booked dates in between
        final DateTime start = date.isBefore(_rangeStart!)
            ? date
            : _rangeStart!;
        final DateTime end = date.isBefore(_rangeStart!) ? _rangeStart! : date;

        // Get minNights from widget settings (default to 1 if not set)
        final minNights =
            ref
                .read(
                  widgetSettingsProvider((widget.propertyId, widget.unitId)),
                )
                .value
                ?.minNights ??
            1;

        // Check minNights validation
        final selectedNights = end.difference(start).inDays;
        if (selectedNights < minNights) {
          // Reset selection and show error
          _rangeStart = null;
          _rangeEnd = null;

          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Minimum stay is $minNights ${minNights == 1 ? 'night' : 'nights'}. You selected $selectedNights ${selectedNights == 1 ? 'night' : 'nights'}.',
                style: TextStyle(color: colors.textPrimary),
              ),
              backgroundColor: colors.statusBookedBackground,
              duration: const Duration(seconds: 3),
            ),
          );
          return;
        }

        // Bug #72 Fix: Use backend availability check for cross-month validation
        // Local data map only contains current month - cannot validate dates in other months
        _validateAndSetRange(start, end, colors);
      }
    });
  }

  /// Bug #72 Fix: Async validation using backend availability check
  /// This ensures cross-month date ranges are properly validated
  Future<void> _validateAndSetRange(
    DateTime start,
    DateTime end,
    WidgetColorScheme colors,
  ) async {
    // Check availability using backend (works across all months)
    final isAvailable = await ref.read(
      checkDateAvailabilityProvider(
        unitId: widget.unitId,
        checkIn: start,
        checkOut: end,
      ).future,
    );

    if (!mounted) return;

    if (!isAvailable) {
      // Reset selection and show error
      setState(() {
        _rangeStart = null;
        _rangeEnd = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cannot select dates. There are already booked dates in this range.',
            style: TextStyle(color: colors.textPrimary),
          ),
          backgroundColor: colors.statusBookedBackground,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    // Availability confirmed, set the range
    setState(() {
      if (end.isBefore(start)) {
        _rangeStart = end;
        _rangeEnd = start;
      } else {
        _rangeStart = start;
        _rangeEnd = end;
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

  /// Get darker border color for calendar cell based on status
  Color _getBorderColorForDate(DateStatus status, WidgetColorScheme colors) {
    switch (status) {
      case DateStatus.available:
      case DateStatus.partialCheckIn:
      case DateStatus.partialCheckOut:
        return colors.statusAvailableBorder;
      case DateStatus.booked:
      case DateStatus.partialBoth:
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

  /// Build compact legend/info banner below calendar
  /// Shows minimum stay requirement and color legend
  Widget _buildCompactLegend(
    int minNights,
    WidgetColorScheme colors,
    bool isDarkMode,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrowScreen = screenWidth < 600;

    return Container(
      margin: const EdgeInsets.only(
        top: SpacingTokens.s,
        bottom: SpacingTokens.xs,
        left: SpacingTokens.xs,
        right: SpacingTokens.xs,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.s,
        vertical: SpacingTokens.xs,
      ),
      decoration: BoxDecoration(
        color: colors.backgroundSecondary,
        borderRadius: BorderTokens.circularMedium,
        border: Border.all(color: colors.borderLight),
      ),
      child: isNarrowScreen
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Min stay info
                Row(
                  children: [
                    Icon(
                      Icons.bed_outlined,
                      size: 14,
                      color: colors.textSecondary,
                    ),
                    const SizedBox(width: SpacingTokens.xxs),
                    Text(
                      'Min. stay: $minNights ${minNights == 1 ? 'night' : 'nights'}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: SpacingTokens.xxs),
                // Color legend
                _buildColorLegend(colors),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Min stay info
                Row(
                  children: [
                    Icon(
                      Icons.bed_outlined,
                      size: 14,
                      color: colors.textSecondary,
                    ),
                    const SizedBox(width: SpacingTokens.xxs),
                    Text(
                      'Min. stay: $minNights ${minNights == 1 ? 'night' : 'nights'}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
                // Color legend
                _buildColorLegend(colors),
              ],
            ),
    );
  }

  /// Build compact color legend with dots
  Widget _buildColorLegend(WidgetColorScheme colors) {
    return Wrap(
      spacing: SpacingTokens.xs,
      runSpacing: 4,
      children: [
        _buildLegendItem('Available', colors.statusAvailableBackground, colors),
        _buildLegendItem('Booked', colors.statusBookedBackground, colors),
        _buildLegendItem('Pending', colors.statusPendingBackground, colors),
        _buildLegendItem('Unavailable', colors.backgroundTertiary, colors),
      ],
    );
  }

  /// Build a single legend item with colored dot
  Widget _buildLegendItem(
    String label,
    Color dotColor,
    WidgetColorScheme colors,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
            border: Border.all(color: colors.borderDefault, width: 0.5),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: colors.textSecondary),
        ),
      ],
    );
  }
}
