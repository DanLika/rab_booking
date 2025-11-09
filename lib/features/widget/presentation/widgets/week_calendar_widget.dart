import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/models/calendar_date_status.dart';
import '../providers/week_calendar_provider.dart';
import '../providers/calendar_view_provider.dart';
import '../providers/theme_provider.dart';
import 'split_day_calendar_painter.dart';
import '../theme/responsive_helper.dart';
import 'calendar_hover_tooltip.dart';
import 'calendar_view_switcher.dart';
import '../../../../shared/widgets/animations/skeleton_loader.dart';
import '../../../../../core/design_tokens/design_tokens.dart';

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
  DateTime? _hoveredDate; // For hover tooltip (desktop)
  Offset _mousePosition = Offset.zero; // Track mouse position for tooltip

  static DateTime _getWeekStart(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  @override
  Widget build(BuildContext context) {
    final calendarData = ref.watch(weekCalendarDataProvider((widget.unitId, _currentWeekStart)));
    final isDarkMode = ref.watch(themeProvider);
    final colors = isDarkMode ? ColorTokens.dark : ColorTokens.light;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        // Clear selection when clicking outside calendar
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
              // Unified combined header for all screen sizes
              _buildCombinedHeader(context),
              const SizedBox(height: SpacingTokens.m),
              Expanded(
                child: calendarData.when(
                  data: (data) => _buildWeekView(data, colors),
                  loading: () => _buildWeekSkeleton(),
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
          _buildViewTab('Week', Icons.view_week, CalendarViewType.week, currentView == CalendarViewType.week),
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
        constraints: const BoxConstraints(maxWidth: ConstraintTokens.maxWideContentWidth * 0.82),
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
                child: _buildCompactWeekNavigation(),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildCompactWeekNavigation() {
    final weekEndDate = _currentWeekStart.add(const Duration(days: 6));
    final isSameMonth = _currentWeekStart.month == weekEndDate.month;

    // Format: "Oct 27 - Nov 2" or "Oct 27-30" (if same month)
    final weekStart = DateFormat.MMMd().format(_currentWeekStart);
    final weekEnd = isSameMonth
        ? DateFormat.d().format(weekEndDate)
        : DateFormat.MMMd().format(weekEndDate);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left, size: IconSizeTokens.small),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: ConstraintTokens.iconContainerSmall, minHeight: ConstraintTokens.iconContainerSmall),
          tooltip: 'Previous week',
          onPressed: () {
            setState(() {
              _currentWeekStart = _currentWeekStart.subtract(const Duration(days: 7));
            });
          },
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$weekStart - $weekEnd',
              style: TextStyle(
                fontSize: TypographyTokens.fontSizeM,
                fontWeight: TypographyTokens.bold,
                color: ColorTokens.light.textPrimary,
              ),
            ),
            Text(
              DateFormat.y().format(_currentWeekStart),
              style: TextStyle(
                fontSize: TypographyTokens.fontSizeXS2,
                fontWeight: TypographyTokens.medium,
                color: ColorTokens.light.textSecondary,
              ),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right, size: IconSizeTokens.small),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: ConstraintTokens.iconContainerSmall, minHeight: ConstraintTokens.iconContainerSmall),
          tooltip: 'Next week',
          onPressed: () {
            setState(() {
              _currentWeekStart = _currentWeekStart.add(const Duration(days: 7));
            });
          },
        ),
      ],
    );
  }


  Widget _buildLegend(WidgetColorScheme colors) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final legendPadding = isMobile ? SpacingTokens.xs2 : SpacingTokens.s;
    final spacing = isMobile ? SpacingTokens.s2 : SpacingTokens.m2;

    return Container(
      padding: EdgeInsets.symmetric(vertical: legendPadding, horizontal: isMobile ? SpacingTokens.s : SpacingTokens.m),
      decoration: BoxDecoration(
        color: ColorTokens.light.backgroundSecondary,
        borderRadius: BorderTokens.circularMedium,
      ),
      child: Wrap(
        spacing: spacing,
        runSpacing: isMobile ? SpacingTokens.xs2 : SpacingTokens.s,
        alignment: WrapAlignment.center,
        children: [
          _buildLegendItem('Available', DateStatus.available, colors),
          _buildLegendItem('Booked', DateStatus.booked, colors),
          _buildLegendItem('Check-in', DateStatus.partialCheckIn, colors),
          _buildLegendItem('Check-out', DateStatus.partialCheckOut, colors),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, DateStatus status, WidgetColorScheme colors) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final boxSize = isMobile ? IconSizeTokens.large : IconSizeTokens.xl;
    final fontSize = isMobile ? TypographyTokens.fontSizeXS2 : TypographyTokens.fontSizeS2;
    final spaceBetween = isMobile ? SpacingTokens.xs2 : SpacingTokens.s;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: boxSize,
          height: boxSize,
          decoration: BoxDecoration(
            color: status.getColor(colors),
            border: Border.all(
              color: status.getBorderColor(colors),
              width: BorderTokens.widthMedium,
            ),
            borderRadius: BorderTokens.circularTiny,
          ),
          child: status == DateStatus.partialCheckIn || status == DateStatus.partialCheckOut
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(BorderTokens.radiusSharp + 1),
                  child: CustomPaint(
                    painter: SplitDayCalendarPainter(
                      status: status,
                      borderColor: status.getBorderColor(colors),
                      colors: colors,
                    ),
                  ),
                )
              : null,
        ),
        SizedBox(width: spaceBetween),
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: TypographyTokens.semiBold,
            color: ColorTokens.light.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildWeekSkeleton() {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: ConstraintTokens.maxWideContentWidth * 0.82),
        child: Column(
          children: [
            _buildWeekHeader(),
            const SizedBox(height: SpacingTokens.s),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: List.generate(
                  7,
                  (index) {
                    final widgets = <Widget>[];
                    widgets.add(
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.all(BorderTokens.widthThin),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: ColorTokens.light.borderDefault,
                              width: BorderTokens.widthThin / 2,
                            ),
                          ),
                          child: const SkeletonLoader(),
                        ),
                      ),
                    );
                    if (index < 6) {
                      widgets.add(
                        Container(
                          width: BorderTokens.widthMedium,
                          color: ColorTokens.light.borderStrong,
                        ),
                      );
                    }
                    return widgets;
                  },
                ).expand((element) => element).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekView(Map<String, CalendarDateInfo> data, WidgetColorScheme colors) {
    // Dynamic max height based on screen size (40% of screen height)
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = screenHeight * OpacityTokens.semiTransparent + (screenHeight * 0.1);

    // Constrain week view to max 980px on desktop to prevent excessive width
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: ConstraintTokens.maxWideContentWidth * 0.82),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: maxHeight,
            minHeight: ConstraintTokens.bottomSheetPeekHeight * 2, // Ensure minimum usable height
          ),
          child: Column(
            children: [
              _buildWeekHeader(),
              const SizedBox(height: SpacingTokens.s),
              _buildLegend(colors),
              const SizedBox(height: SpacingTokens.s),
              Expanded(
                child: _buildWeekDays(data, colors),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeekHeader() {
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
                color: ColorTokens.light.borderStrong,
                width: BorderTokens.widthMedium,
              ),
            ),
            child: Text(
              day,
              style: TextStyle(
                fontWeight: TypographyTokens.bold,
                fontSize: TypographyTokens.fontSizeM,
                color: ColorTokens.light.textPrimary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWeekDays(Map<String, CalendarDateInfo> data, WidgetColorScheme colors) {
    // Build day columns with vertical separators between them
    final dayWidgets = <Widget>[];

    for (int index = 0; index < 7; index++) {
      final date = _currentWeekStart.add(Duration(days: index));

      // Add day column
      dayWidgets.add(
        Expanded(
          child: _buildDayColumn(date, data, colors),
        ),
      );

      // Add separator after each day except the last one
      if (index < 6) {
        dayWidgets.add(
          Container(
            width: BorderTokens.widthMedium,
            color: ColorTokens.light.borderStrong,
          ),
        );
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: dayWidgets,
    );
  }

  Widget _buildDayColumn(DateTime date, Map<String, CalendarDateInfo> data, WidgetColorScheme colors) {
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

    final isHovered = _hoveredDate != null && _isSameDay(date, _hoveredDate!);

    final dateLabel = DateFormat('EEEE, MMMM d').format(date);
    final statusDescription = dateInfo.status.getDisplayName();
    final priceDescription = dateInfo.price != null ? 'Price: ${dateInfo.formattedPrice}' : '';
    final accessibilityLabel = '$dateLabel. $statusDescription. $priceDescription';

    return Semantics(
      label: accessibilityLabel,
      button: true,
      enabled: dateInfo.status == DateStatus.available ||
              dateInfo.status == DateStatus.partialCheckIn ||
              dateInfo.status == DateStatus.partialCheckOut,
      child: MouseRegion(
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
                  ? ColorTokens.light.borderFocus // Black for selection
                  : isToday
                      ? ColorTokens.light.borderStrong // Medium grey for today
                      : isHovered
                          ? ColorTokens.light.borderStrong // Medium grey on hover
                          : ColorTokens.light.borderDefault, // Light grey default
              width: isRangeStart || isRangeEnd || isToday || isHovered ? BorderTokens.widthThick : BorderTokens.widthThin / 2,
            ),
          ),
        child: Stack(
          children: [
            // Background with diagonal split and price
            CustomPaint(
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
            // Day number and labels overlay
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.xs2, vertical: SpacingTokens.xxs),
                  decoration: BoxDecoration(
                    color: isToday
                        ? ColorTokens.withOpacity(ColorTokens.light.buttonPrimary, OpacityTokens.almostOpaque)
                        : ColorTokens.withOpacity(ColorTokens.light.backgroundPrimary, OpacityTokens.mostlyVisible + 0.35),
                    borderRadius: BorderTokens.circularTiny,
                    border: isToday
                        ? Border.all(
                            color: ColorTokens.light.buttonPrimary,
                            width: BorderTokens.widthThick,
                          )
                        : null,
                  ),
                  child: Text(
                    date.day.toString(),
                    style: TextStyle(
                      fontSize: TypographyTokens.fontSizeM2 + 5,
                      fontWeight: isToday ? TypographyTokens.bold : TypographyTokens.semiBold,
                      color: isToday
                          ? ColorTokens.light.textOnPrimary
                          : ColorTokens.light.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: SpacingTokens.xs),
                if (isRangeStart)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.xs, vertical: SpacingTokens.xxs),
                    decoration: BoxDecoration(
                      color: ColorTokens.withOpacity(ColorTokens.light.backgroundPrimary, OpacityTokens.almostOpaque),
                      border: Border.all(
                        color: ColorTokens.light.borderFocus,
                        width: BorderTokens.widthMedium,
                      ),
                      borderRadius: BorderTokens.circularTiny,
                    ),
                    child: Text(
                      'Check-in',
                      style: TextStyle(
                        fontSize: TypographyTokens.poweredBySize,
                        fontWeight: TypographyTokens.bold,
                        color: ColorTokens.light.textPrimary,
                      ),
                    ),
                  ),
                if (isRangeEnd)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.xs, vertical: SpacingTokens.xxs),
                    decoration: BoxDecoration(
                      color: ColorTokens.withOpacity(ColorTokens.light.backgroundPrimary, OpacityTokens.almostOpaque),
                      border: Border.all(
                        color: ColorTokens.light.borderFocus,
                        width: BorderTokens.widthMedium,
                      ),
                      borderRadius: BorderTokens.circularTiny,
                    ),
                    child: Text(
                      'Check-out',
                      style: TextStyle(
                        fontSize: TypographyTokens.poweredBySize,
                        fontWeight: TypographyTokens.bold,
                        color: ColorTokens.light.textPrimary,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        ),
      ),
      ),
    );
  }

  Widget _buildEmptyDay() {
    return Container(
      decoration: BoxDecoration(
        color: ColorTokens.light.backgroundSecondary,
        border: Border.all(
          color: ColorTokens.light.borderLight,
          width: BorderTokens.widthThin / 2,
        ),
      ),
      child: Opacity(
        opacity: OpacityTokens.mostlyVisible,
        child: Container(),
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
    final tooltipWidth = ConstraintTokens.maxCardWidth / 2;
    final tooltipHeight = ConstraintTokens.calendarCellMinHeight * 2;

    // Offset tooltip to the right and up from cursor
    double xPosition = _mousePosition.dx + SpacingTokens.s2;
    double yPosition = _mousePosition.dy - tooltipHeight - SpacingTokens.s2;

    // Keep tooltip within screen bounds
    if (xPosition + tooltipWidth > screenWidth) {
      xPosition = _mousePosition.dx - tooltipWidth - SpacingTokens.s2; // Show on left instead
    }
    if (yPosition < SpacingTokens.m2) {
      yPosition = _mousePosition.dy + SpacingTokens.m2; // Show below cursor instead
    }

    xPosition = xPosition.clamp(SpacingTokens.m2, screenWidth - tooltipWidth - SpacingTokens.m2);
    yPosition = yPosition.clamp(SpacingTokens.m2, screenHeight - tooltipHeight - SpacingTokens.m2);

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
            SnackBar(
              content: const Text('Cannot select dates. There are already booked dates in this range.'),
              backgroundColor: ColorTokens.light.error,
              duration: AnimationTokens.notification,
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
