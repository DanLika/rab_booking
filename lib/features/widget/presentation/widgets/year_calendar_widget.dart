import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/models/calendar_date_status.dart';
import '../providers/year_calendar_provider.dart';
import '../providers/calendar_view_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/responsive_helper.dart';
import '../../../../core/design_tokens/design_tokens.dart';
import 'calendar_view_switcher.dart';
import 'calendar_hover_tooltip.dart';

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
  DateTime? _hoveredDate; // For hover tooltip (desktop)
  Offset _mousePosition = Offset.zero; // Track mouse position for tooltip

  @override
  Widget build(BuildContext context) {
    final calendarData = ref.watch(yearCalendarDataProvider((widget.unitId, _currentYear)));
    final isDarkMode = ref.watch(themeProvider);
    final colors = isDarkMode ? ColorTokens.dark : ColorTokens.light;

    return Stack(
      children: [
        Column(
          children: [
            // Combined header matching month/week view layout
            _buildCombinedHeader(context, colors, isDarkMode),
            const SizedBox(height: SpacingTokens.m),
            Expanded(
              child: calendarData.when(
                data: (data) => _buildYearGridWithIntegratedSelector(data, colors),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Text('Error: $error'),
                ),
              ),
            ),
          ],
        ),
        // Hover tooltip overlay (desktop) - highest z-index
        if (_hoveredDate != null)
          Positioned.fill(
            child: IgnorePointer(
              ignoring: false,
              child: calendarData.when(
                data: (data) => _buildHoverTooltip(data, colors),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildViewSwitcher(BuildContext context, WidgetColorScheme colors) {
    final currentView = ref.watch(calendarViewProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400; // iPhone SE and similar

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 2 : 4),
      decoration: BoxDecoration(
        color: colors.backgroundSecondary,
        borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
        border: Border.all(
          color: colors.borderLight,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Week view hidden but code kept for future use
          // _buildViewTab('Week', Icons.view_week, CalendarViewType.week, currentView == CalendarViewType.week, isSmallScreen, colors),
          _buildViewTab('Month', Icons.calendar_month, CalendarViewType.month, currentView == CalendarViewType.month, isSmallScreen, colors),
          SizedBox(width: isSmallScreen ? 2 : 4),
          _buildViewTab('Year', Icons.calendar_today, CalendarViewType.year, currentView == CalendarViewType.year, isSmallScreen, colors),
        ],
      ),
    );
  }

  Widget _buildViewTab(String label, IconData icon, CalendarViewType viewType, bool isSelected, bool isSmallScreen, WidgetColorScheme colors) {
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
            color: isSelected ? colors.buttonPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? colors.buttonPrimaryText : colors.textSecondary,
                size: isSmallScreen ? 16 : IconSizeTokens.small,
                semanticLabel: label,
              ),
              if (!isSmallScreen) ...[
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? colors.buttonPrimaryText : colors.textSecondary,
                    fontSize: TypographyTokens.fontSizeS2,
                    fontWeight: isSelected ? TypographyTokens.semiBold : TypographyTokens.regular,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCombinedHeader(BuildContext context, WidgetColorScheme colors, bool isDarkMode) {
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
              ),
              onPressed: () {
                ref.read(themeProvider.notifier).state = !isDarkMode;
              },
              tooltip: isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(
                minWidth: isSmallScreen ? 28 : ConstraintTokens.iconContainerSmall,
                minHeight: isSmallScreen ? 28 : ConstraintTokens.iconContainerSmall,
              ),
            ),

            SizedBox(width: isSmallScreen ? 4 : SpacingTokens.xxs),

            // Compact Navigation
            _buildCompactYearNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildRangeSelectionInfo(WidgetColorScheme colors) {
    if (_rangeStart == null || _rangeEnd == null) return const SizedBox.shrink();

    final nights = _rangeEnd!.difference(_rangeStart!).inDays;
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 980),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: SpacingTokens.m,
            vertical: SpacingTokens.s,
          ),
          decoration: BoxDecoration(
            color: colors.buttonPrimary.withValues(alpha: 0.1),
            borderRadius: BorderTokens.circularMedium,
            border: Border.all(
              color: colors.buttonPrimary.withValues(alpha: 0.3),
              width: BorderTokens.widthThin,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_month,
                size: IconSizeTokens.small,
                color: colors.buttonPrimary,
              ),
              const SizedBox(width: SpacingTokens.xs),
              Text(
                '${dateFormat.format(_rangeStart!)} - ${dateFormat.format(_rangeEnd!)}',
                style: TextStyle(
                  fontSize: TypographyTokens.fontSizeS2,
                  fontWeight: TypographyTokens.semiBold,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(width: SpacingTokens.s),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: SpacingTokens.xs,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: colors.buttonPrimary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$nights ${nights == 1 ? 'night' : 'nights'}',
                  style: TextStyle(
                    fontSize: TypographyTokens.fontSizeXS2,
                    fontWeight: TypographyTokens.bold,
                    color: colors.buttonPrimaryText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorLegend(BuildContext context, WidgetColorScheme colors) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    // Most common statuses to show in legend
    final legendItems = [
      DateStatus.available,
      DateStatus.booked,
      DateStatus.pending,
      DateStatus.partialCheckIn,
    ];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 980),
        child: Container(
          padding: EdgeInsets.all(isMobile ? SpacingTokens.s : SpacingTokens.m),
          decoration: BoxDecoration(
            color: colors.backgroundSecondary,
            borderRadius: BorderTokens.circularMedium,
            border: Border.all(
              color: colors.borderLight,
              width: BorderTokens.widthThin,
            ),
          ),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: isMobile ? SpacingTokens.s : SpacingTokens.m,
            runSpacing: SpacingTokens.xs,
            children: legendItems.map((status) => _buildLegendItem(status, colors)).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(DateStatus status, WidgetColorScheme colors) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: status.getColor(colors),
            border: Border.all(
              color: status.getBorderColor(colors),
              width: BorderTokens.widthThin,
            ),
            borderRadius: BorderTokens.circularTiny,
          ),
          child: status == DateStatus.partialCheckIn
              ? CustomPaint(
                  painter: _DiagonalLinePainter(
                    diagonalColor: status.getDiagonalColor(colors),
                    isCheckIn: true,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 6),
        Text(
          status.getDisplayName(),
          style: TextStyle(
            fontSize: TypographyTokens.fontSizeXS2,
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildHoverTooltip(Map<String, CalendarDateInfo> data, WidgetColorScheme colors) {
    if (_hoveredDate == null) return const SizedBox.shrink();

    final key = _getDateKey(_hoveredDate!);
    final dateInfo = data[key];

    if (dateInfo == null) return const SizedBox.shrink();

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    const tooltipWidth = 200.0;
    const tooltipHeight = 150.0;

    // Position tooltip near mouse cursor
    double xPosition = _mousePosition.dx + 10;
    double yPosition = _mousePosition.dy - tooltipHeight - 10;

    // Adjust if tooltip goes off screen
    if (xPosition + tooltipWidth > screenWidth) {
      xPosition = _mousePosition.dx - tooltipWidth - 10;
    }
    if (yPosition < 20) {
      yPosition = _mousePosition.dy + 20;
    }

    xPosition = xPosition.clamp(20, screenWidth - tooltipWidth - 20);
    yPosition = yPosition.clamp(20, screenHeight - tooltipHeight - 20);

    return CalendarHoverTooltip(
      date: _hoveredDate!,
      price: dateInfo.price,
      status: dateInfo.status,
      position: Offset(xPosition, yPosition),
      colors: colors,
    );
  }

  Widget _buildCompactYearNavigation() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400; // iPhone SE and similar

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.chevron_left, size: isSmallScreen ? 16 : IconSizeTokens.small),
          padding: EdgeInsets.zero,
          constraints: BoxConstraints(
            minWidth: isSmallScreen ? 28 : ConstraintTokens.iconContainerSmall,
            minHeight: isSmallScreen ? 28 : ConstraintTokens.iconContainerSmall,
          ),
          onPressed: () {
            setState(() {
              _currentYear--;
            });
          },
        ),
        Text(
          _currentYear.toString(),
          style: TextStyle(
            fontSize: isSmallScreen ? TypographyTokens.fontSizeS : TypographyTokens.fontSizeM,
            fontWeight: TypographyTokens.bold,
          ),
        ),
        IconButton(
          icon: Icon(Icons.chevron_right, size: isSmallScreen ? 16 : IconSizeTokens.small),
          padding: EdgeInsets.zero,
          constraints: BoxConstraints(
            minWidth: isSmallScreen ? 28 : ConstraintTokens.iconContainerSmall,
            minHeight: isSmallScreen ? 28 : ConstraintTokens.iconContainerSmall,
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


  Widget _buildYearGridWithIntegratedSelector(Map<String, CalendarDateInfo> data, WidgetColorScheme colors) {
    // Get responsive cell size
    final cellSize = ResponsiveHelper.getYearCellSize(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;

    return Padding(
      padding: EdgeInsets.all(isDesktop ? SpacingTokens.m : SpacingTokens.xs),
      child: Stack(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SizedBox(
                width: ConstraintTokens.monthLabelWidth + (31 * cellSize), // Month label width + 31 day columns
                child: Column(
                  children: [
                    _buildHeaderRowWithYearSelector(cellSize, colors),
                    const SizedBox(height: SpacingTokens.xs),
                    ...List.generate(12, (monthIndex) => _buildMonthRow(monthIndex + 1, data, cellSize, colors)),
                  ],
                ),
              ),
            ),
          ),
          // Left fade gradient indicator
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 30,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      colors.backgroundPrimary,
                      colors.backgroundPrimary.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Right fade gradient indicator
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 30,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      colors.backgroundPrimary.withValues(alpha: 0),
                      colors.backgroundPrimary,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderRowWithYearSelector(double cellSize, WidgetColorScheme colors) {
    return Row(
      children: [
        // Static "Month" label in top-left corner
        Container(
          width: ConstraintTokens.monthLabelWidth,
          height: cellSize,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.buttonPrimary,
            border: Border.all(
              color: colors.borderDefault,
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
              color: colors.buttonPrimaryText,
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
              color: colors.backgroundTertiary,
              border: Border.all(
                color: colors.borderDefault,
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


  Widget _buildMonthRow(int month, Map<String, CalendarDateInfo> data, double cellSize, WidgetColorScheme colors) {
    final monthName = DateFormat.MMM().format(DateTime(_currentYear, month));

    return Row(
      children: [
        // Month label
        Container(
          width: ConstraintTokens.monthLabelWidth,
          height: cellSize,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.backgroundTertiary,
            border: Border.all(
              color: colors.borderDefault,
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
          return _buildDayCell(month, day, data, cellSize, colors);
        }),
      ],
    );
  }

  Widget _buildDayCell(int month, int day, Map<String, CalendarDateInfo> data, double cellSize, WidgetColorScheme colors) {
    // Check if this day exists in this month
    try {
      final date = DateTime(_currentYear, month, day);
      final key = _getDateKey(date);
      final dateInfo = data[key];

      if (dateInfo == null) {
        // Day doesn't exist in this month or no data
        return _buildEmptyCell(cellSize, colors);
      }

      final isInRange = _isDateInRange(date);
      final isRangeStart = _rangeStart != null && _isSameDay(date, _rangeStart!);
      final isRangeEnd = _rangeEnd != null && _isSameDay(date, _rangeEnd!);
      final isHovered = _hoveredDate != null && _isSameDay(date, _hoveredDate!);
      final isToday = _isSameDay(date, DateTime.now());

      // Determine if this is a check-in or check-out day
      final isPartialCheckIn = dateInfo.status == DateStatus.partialCheckIn;
      final isPartialCheckOut = dateInfo.status == DateStatus.partialCheckOut;

      // Check if cell is interactive
      final isInteractive = dateInfo.status == DateStatus.available ||
          dateInfo.status == DateStatus.partialCheckIn ||
          dateInfo.status == DateStatus.partialCheckOut;

      // Show tooltip on all dates except disabled/past dates
      final showTooltip = dateInfo.status != DateStatus.disabled;

      return MouseRegion(
        cursor: isInteractive ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) {
          if (showTooltip) {
            setState(() {
              _hoveredDate = date;
            });
          }
        },
        onHover: (event) {
          if (showTooltip) {
            setState(() {
              _mousePosition = event.position;
            });
          }
        },
        onExit: (_) {
          setState(() {
            _hoveredDate = null;
          });
        },
        child: GestureDetector(
          onTap: () => _onDateTapped(date, dateInfo, data, colors),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: cellSize,
            height: cellSize,
            decoration: BoxDecoration(
              color: _getCellColor(dateInfo, isInRange, isHovered, isInteractive, colors),
              border: Border.all(
                color: isRangeStart || isRangeEnd
                    ? colors.borderStrong
                    : isToday
                        ? colors.buttonPrimary
                        : dateInfo.status.getBorderColor(colors),
                width: (isRangeStart || isRangeEnd || isToday) ? BorderTokens.widthMedium : BorderTokens.widthThin,
              ),
              borderRadius: BorderTokens.circularTiny,
              boxShadow: isHovered && isInteractive
                  ? ShadowTokens.light
                  : colors.shadowMinimal,
            ),
            child: Stack(
              children: [
                // Diagonal pattern for partial check-in/out
                if (isPartialCheckIn || isPartialCheckOut)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _DiagonalLinePainter(
                        diagonalColor: dateInfo.status.getDiagonalColor(colors),
                        isCheckIn: isPartialCheckIn,
                      ),
                    ),
                  ),
                // Today indicator dot
                if (isToday)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.buttonPrimary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      // Invalid date (e.g., Feb 30)
      return _buildEmptyCell(cellSize, colors);
    }
  }

  Color _getCellColor(CalendarDateInfo dateInfo, bool isInRange, bool isHovered, bool isInteractive, WidgetColorScheme colors) {
    if (isInRange) {
      // Enhanced visual for selected range with tinted overlay
      return Color.alphaBlend(
        colors.buttonPrimary.withValues(alpha: 0.15),
        colors.backgroundTertiary,
      );
    }

    if (isHovered && isInteractive) {
      // Lighten the color slightly on hover
      final baseColor = dateInfo.status.getColor(colors);
      return Color.alphaBlend(
        Colors.white.withValues(alpha: 0.3),
        baseColor,
      );
    }

    return dateInfo.status.getColor(colors);
  }

  Widget _buildEmptyCell(double cellSize, WidgetColorScheme colors) {
    return Container(
      width: cellSize,
      height: cellSize,
      decoration: BoxDecoration(
        color: colors.backgroundSecondary,
        border: Border.all(
          color: colors.borderLight,
          width: BorderTokens.widthThin,
        ),
        borderRadius: BorderTokens.circularTiny,
      ),
    );
  }

  void _onDateTapped(DateTime date, CalendarDateInfo dateInfo, Map<String, CalendarDateInfo> data, WidgetColorScheme colors) {
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
              backgroundColor: colors.error,
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
