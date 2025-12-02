import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/models/calendar_date_status.dart';
import '../providers/month_calendar_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/widget_settings_provider.dart';
import '../providers/realtime_booking_calendar_provider.dart';
import '../../../owner_dashboard/presentation/providers/owner_properties_provider.dart';
import 'split_day_calendar_painter.dart';
import 'calendar_hover_tooltip.dart';
import 'calendar/calendar_date_utils.dart';
import 'calendar/calendar_view_switcher_widget.dart';
import 'calendar/calendar_compact_legend.dart';
import '../theme/responsive_helper.dart';
import '../theme/minimalist_colors.dart';
import '../../../../../core/design_tokens/design_tokens.dart';
import '../../../../../shared/utils/ui/snackbar_helper.dart';

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
    // Get unit data for pricing and minNights (gap blocking)
    final unitAsync = ref.watch(unitByIdProvider(widget.propertyId, widget.unitId));
    final unit = unitAsync.valueOrNull;
    final basePrice = unit?.pricePerNight ?? 0.0;
    final weekendBasePrice = unit?.weekendBasePrice;
    final weekendDays = unit?.weekendDays;
    final minNights = unit?.minStayNights ?? 1; // Read from UnitModel, not WidgetSettings

    final calendarData = ref.watch(
      monthCalendarDataProvider((
        unitId: widget.unitId,
        monthStart: _currentMonth,
        minNights: minNights,
        basePrice: basePrice,
        weekendBasePrice: weekendBasePrice,
        weekendDays: weekendDays,
      )),
    );
    final isDarkMode = ref.watch(themeProvider);
    final colors = MinimalistColorSchemeAdapter(dark: isDarkMode);

    return Column(
      children: [
        // Combined header - explicitly outside any GestureDetector
        _buildCombinedHeader(context, colors, isDarkMode),
        const SizedBox(height: SpacingTokens.xs),

        // Calendar and tooltip in Stack for overlay positioning
        Expanded(
          child: MouseRegion(
            onHover: (event) => setState(() => _mousePosition = event.localPosition),
            child: Stack(
              children: [
                // Calendar with GestureDetector for deselection
                GestureDetector(
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
                  child: Column(
                    children: [
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
                        CalendarCompactLegend(minNights: minNights, colors: colors),
                    ],
                  ),
                ),
                // Hover tooltip overlay (desktop) - highest z-index
                if (_hoveredDate != null)
                  calendarData.when(
                    data: (data) => _buildHoverTooltip(data, colors),
                    loading: () => const SizedBox.shrink(),
                    error: (_, stackTrace) => const SizedBox.shrink(),
                  ),
              ],
            ),
          ),
        ),
      ],
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
            CalendarViewSwitcherWidget(colors: colors, isDarkMode: isDarkMode),
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
              // Only clear range if BOTH dates are selected (complete selection)
              // Preserve _rangeStart if user is still selecting checkOut
              // This allows cross-month date range selection
              if (_rangeStart != null && _rangeEnd != null) {
                _rangeStart = null;
                _rangeEnd = null;
                // Notify parent that range was cleared
                widget.onRangeSelected?.call(null, null);
              }
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
              // Only clear range if BOTH dates are selected (complete selection)
              // Preserve _rangeStart if user is still selecting checkOut
              // This allows cross-month date range selection
              if (_rangeStart != null && _rangeEnd != null) {
                _rangeStart = null;
                _rangeEnd = null;
                // Notify parent that range was cleared
                widget.onRangeSelected?.call(null, null);
              }
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
    final key = CalendarDateUtils.getDateKey(date);
    final dateInfo = data[key];

    if (dateInfo == null) {
      return _buildEmptyCell(colors);
    }

    final isInRange = CalendarDateUtils.isDateInRange(date, _rangeStart, _rangeEnd);
    final isRangeStart = _rangeStart != null && CalendarDateUtils.isSameDay(date, _rangeStart!);
    final isRangeEnd = _rangeEnd != null && CalendarDateUtils.isSameDay(date, _rangeEnd!);
    final today = DateTime.now();
    final todayNormalized = DateTime(today.year, today.month, today.day);
    final isToday = CalendarDateUtils.isSameDay(date, today);
    final isPast = date.isBefore(todayNormalized);

    final isHovered = _hoveredDate != null && CalendarDateUtils.isSameDay(date, _hoveredDate!);

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredDate = date),
      onExit: (_) => setState(() => _hoveredDate = null),
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
              // Background with diagonal split
              ClipRRect(
                borderRadius: BorderTokens.calendarCell,
                child: CustomPaint(
                  painter: SplitDayCalendarPainter(
                    // Preserve partialCheckIn/Out/Both status even when in range
                    status:
                        isInRange &&
                            dateInfo.status != DateStatus.partialCheckIn &&
                            dateInfo.status != DateStatus.partialCheckOut &&
                            dateInfo.status != DateStatus.partialBoth
                        ? DateStatus.available
                        : dateInfo.status,
                    borderColor: dateInfo.status.getBorderColor(colors),
                    colors: colors,
                    isInRange: isInRange,
                    isPendingBooking: dateInfo.isPendingBooking,
                    isCheckOutPending: dateInfo.isCheckOutPending,
                    isCheckInPending: dateInfo.isCheckInPending,
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

    final key = CalendarDateUtils.getDateKey(_hoveredDate!);
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

    // For pending bookings, show "Pending" status instead of "Booked"
    final effectiveStatus = dateInfo.isPendingBooking ? DateStatus.pending : dateInfo.status;

    return Positioned(
      left: xPosition,
      top: yPosition,
      child: IgnorePointer(
        child: CalendarHoverTooltip(
          date: _hoveredDate!,
          price: dateInfo.price,
          status: effectiveStatus,
          position: Offset(xPosition, yPosition),
          colors: colors,
        ),
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
      SnackBarHelper.showError(
        context: context,
        message: 'Cannot select past dates.',
        duration: const Duration(seconds: 3),
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
        SnackBarHelper.showError(
          context: context,
          message: 'This date requires booking at least ${dateInfo.minDaysAdvance} days in advance.',
            duration: const Duration(seconds: 3),
        );
        return;
      }

      // Check maxDaysAdvance
      if (dateInfo.maxDaysAdvance != null &&
          daysInAdvance > dateInfo.maxDaysAdvance!) {
        SnackBarHelper.showError(
          context: context,
          message: 'This date can only be booked up to ${dateInfo.maxDaysAdvance} days in advance.',
            duration: const Duration(seconds: 3),
        );
        return;
      }
    }

    // Check blockCheckIn/blockCheckOut restrictions
    if (isSelectingCheckIn && dateInfo.blockCheckIn) {
      SnackBarHelper.showError(
        context: context,
        message: 'Check-in is not allowed on this date.',
        duration: const Duration(seconds: 3),
      );
      return;
    }

    if (isSelectingCheckOut && dateInfo.blockCheckOut) {
      SnackBarHelper.showError(
        context: context,
        message: 'Check-out is not allowed on this date.',
        duration: const Duration(seconds: 3),
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

    if (isSelectingCheckIn && !canSelectForCheckIn) {
      SnackBarHelper.showError(
        context: context,
        message: 'This date is not available for check-in. Please select an available date.',
        duration: const Duration(seconds: 3),
      );
      return;
    }

    if (isSelectingCheckOut && !canSelectForCheckOut) {
      SnackBarHelper.showError(
        context: context,
        message: 'This date is not available for check-out. Please select an available date.',
        duration: const Duration(seconds: 3),
      );
      return;
    }

    setState(() {
      if (_rangeStart == null || (_rangeStart != null && _rangeEnd != null)) {
        // Start new range
        _rangeStart = date;
        _rangeEnd = null;
      } else if (_rangeStart != null && _rangeEnd == null) {
        // Cannot select same date as check-in and check-out
        if (CalendarDateUtils.isSameDay(date, _rangeStart!)) {
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

        // Check minNights validation (global from widget settings)
        final selectedNights = end.difference(start).inDays;
        if (selectedNights < minNights) {
          // Reset selection and show error
          _rangeStart = null;
          _rangeEnd = null;

          // Show error message
          SnackBarHelper.showError(
            context: context,
            message: 'Minimum stay is $minNights ${minNights == 1 ? 'night' : 'nights'}. You selected $selectedNights ${selectedNights == 1 ? 'night' : 'nights'}.',
                duration: const Duration(seconds: 3),
          );
          return;
        }

        // Check minNightsOnArrival/maxNightsOnArrival from daily_prices
        // Get the check-in date info from calendar data
        final startKey = DateFormat('yyyy-MM-dd').format(start);
        final checkInDateInfo = data[startKey];

        if (checkInDateInfo != null) {
          // Validate minNightsOnArrival (per-date minimum stay requirement)
          if (checkInDateInfo.minNightsOnArrival != null &&
              selectedNights < checkInDateInfo.minNightsOnArrival!) {
            // Keep check-in selected, don't set checkout - show snackbar
            SnackBarHelper.showError(
              context: context,
              message: 'Minimum ${checkInDateInfo.minNightsOnArrival} nights required for this check-in date. You selected $selectedNights ${selectedNights == 1 ? 'night' : 'nights'}.',
                  );
            return; // Keep _rangeStart, don't set _rangeEnd
          }

          // Validate maxNightsOnArrival (per-date maximum stay limit)
          if (checkInDateInfo.maxNightsOnArrival != null &&
              selectedNights > checkInDateInfo.maxNightsOnArrival!) {
            // Keep check-in selected, don't set checkout - show snackbar
            SnackBarHelper.showError(
              context: context,
              message: 'Maximum ${checkInDateInfo.maxNightsOnArrival} nights allowed for this check-in date. You selected $selectedNights ${selectedNights == 1 ? 'night' : 'nights'}.',
                  );
            return; // Keep _rangeStart, don't set _rangeEnd
          }
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

      SnackBarHelper.showError(
        context: context,
        message: 'Cannot select dates. There are already booked dates in this range.',
        duration: const Duration(seconds: 3),
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

}
