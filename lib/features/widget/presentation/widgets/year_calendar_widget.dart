import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/models/calendar_date_status.dart';
import '../../domain/models/calendar_view_type.dart';
import '../providers/year_calendar_provider.dart';
import '../providers/calendar_view_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/widget_settings_provider.dart';
import '../../../owner_dashboard/presentation/providers/owner_properties_provider.dart';
import '../theme/responsive_helper.dart';
import '../theme/minimalist_colors.dart';
import '../../../../core/design_tokens/design_tokens.dart';
import '../../../../core/theme/custom_icons_tablericons.dart';
import 'calendar_hover_tooltip.dart';
import '../utils/snackbar_helper.dart';

class YearCalendarWidget extends ConsumerStatefulWidget {
  final String propertyId;
  final String unitId;
  final Function(DateTime? start, DateTime? end)? onRangeSelected;

  const YearCalendarWidget({
    super.key,
    required this.propertyId,
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
    // Get unit data for pricing and minNights (gap blocking)
    final unitAsync = ref.watch(unitByIdProvider(widget.propertyId, widget.unitId));
    final unit = unitAsync.valueOrNull;
    final basePrice = unit?.pricePerNight ?? 0.0;
    final weekendBasePrice = unit?.weekendBasePrice;
    final weekendDays = unit?.weekendDays;
    final minNights = unit?.minStayNights ?? 1; // Read from UnitModel, not WidgetSettings

    final calendarData = ref.watch(
      yearCalendarDataProvider((
        unitId: widget.unitId,
        year: _currentYear,
        minNights: minNights,
        basePrice: basePrice,
        weekendBasePrice: weekendBasePrice,
        weekendDays: weekendDays,
      )),
    );
    final isDarkMode = ref.watch(themeProvider);
    final colors = MinimalistColorSchemeAdapter(dark: isDarkMode);

    return Stack(
      children: [
        Column(
          children: [
            // Combined header matching month/week view layout
            _buildCombinedHeader(context, colors, isDarkMode),
            const SizedBox(height: SpacingTokens.m),
            Expanded(
              child: calendarData.when(
                data: (data) =>
                    _buildYearGridWithIntegratedSelector(data, colors),
                loading: () => const Center(child: CircularProgressIndicator()),
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
            error: (error, stack) => const SizedBox.shrink(),
          ),
      ],
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
          // Week view hidden but code kept for future use
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
            _buildCompactYearNavigation(colors),
          ],
        ),
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

  Widget _buildCompactYearNavigation(WidgetColorScheme colors) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400; // iPhone SE and similar

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
              _currentYear--;
            });
          },
        ),
        Text(
          _currentYear.toString(),
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
              _currentYear++;
            });
          },
        ),
      ],
    );
  }

  Widget _buildYearGridWithIntegratedSelector(
    Map<String, CalendarDateInfo> data,
    WidgetColorScheme colors,
  ) {
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
              child: SizedBox(
                width:
                    ConstraintTokens.monthLabelWidth +
                    (31 * cellSize), // Month label width + 31 day columns
                child: Column(
                  children: [
                    _buildHeaderRowWithYearSelector(cellSize, colors),
                    const SizedBox(height: SpacingTokens.xs),
                    ...List.generate(
                      12,
                      (monthIndex) => _buildMonthRow(
                        monthIndex + 1,
                        data,
                        cellSize,
                        colors,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderRowWithYearSelector(
    double cellSize,
    WidgetColorScheme colors,
  ) {
    // Responsive font size for headers - proportional to cell size
    final headerFontSize = (cellSize * 0.5).clamp(9.0, 13.0);
    final dayNumberFontSize = (cellSize * 0.45).clamp(8.0, 12.0);

    return Row(
      children: [
        // Static "Month" label in top-left corner
        Container(
          width: ConstraintTokens.monthLabelWidth,
          height: cellSize,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.backgroundSecondary,
            border: Border.all(color: colors.borderLight),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(BorderTokens.radiusSubtle),
            ),
          ),
          child: Text(
            'Month',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: headerFontSize,
              color: colors.textPrimary,
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
              color: colors.backgroundSecondary,
              border: Border.all(color: colors.borderLight),
              borderRadius: dayIndex == 30
                  ? const BorderRadius.only(
                      topRight: Radius.circular(BorderTokens.radiusSubtle),
                    )
                  : BorderRadius.zero,
            ),
            child: Text(
              (dayIndex + 1).toString(),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: dayNumberFontSize,
                color: colors.textSecondary,
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMonthRow(
    int month,
    Map<String, CalendarDateInfo> data,
    double cellSize,
    WidgetColorScheme colors,
  ) {
    final monthName = DateFormat.MMM().format(DateTime(_currentYear, month));
    final monthFontSize = (cellSize * 0.5).clamp(9.0, 13.0);

    return Row(
      children: [
        // Month label
        Container(
          width: ConstraintTokens.monthLabelWidth,
          height: cellSize,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.backgroundSecondary,
            border: Border.all(color: colors.borderLight),
            borderRadius: month == 12
                ? const BorderRadius.only(
                    bottomLeft: Radius.circular(BorderTokens.radiusSubtle),
                  )
                : BorderRadius.zero,
          ),
          child: Text(
            monthName,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: monthFontSize,
              color: colors.textSecondary,
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

  Widget _buildDayCell(
    int month,
    int day,
    Map<String, CalendarDateInfo> data,
    double cellSize,
    WidgetColorScheme colors,
  ) {
    // Check if this day exists in this month
    try {
      final date = DateTime(_currentYear, month, day);

      // Verify the date didn't overflow into next month
      // e.g., DateTime(2025, 2, 31) becomes March 3, not February 31
      if (date.month != month) {
        return _buildEmptyCell(cellSize, colors);
      }

      final key = _getDateKey(date);
      final dateInfo = data[key];

      if (dateInfo == null) {
        // Day doesn't exist in this month or no data
        return _buildEmptyCell(cellSize, colors);
      }

      final isInRange = _isDateInRange(date);
      final isRangeStart =
          _rangeStart != null && _isSameDay(date, _rangeStart!);
      final isRangeEnd = _rangeEnd != null && _isSameDay(date, _rangeEnd!);
      final isHovered = _hoveredDate != null && _isSameDay(date, _hoveredDate!);
      final today = DateTime.now();
      final todayNormalized = DateTime(today.year, today.month, today.day);
      final isToday = _isSameDay(date, today);
      final isPast = date.isBefore(todayNormalized);

      // Determine if this is a check-in or check-out day
      final isPartialCheckIn = dateInfo.status == DateStatus.partialCheckIn;
      final isPartialCheckOut = dateInfo.status == DateStatus.partialCheckOut;

      // Check if cell is interactive - only available dates can be selected
      // partialCheckIn, partialCheckOut, and pending are not selectable
      final isInteractive = dateInfo.status == DateStatus.available;

      // Show tooltip on all dates except disabled/past dates
      final showTooltip = dateInfo.status != DateStatus.disabled;

      return MouseRegion(
        cursor: isInteractive
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
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
          // Disable tap in calendar_only mode (when onRangeSelected is null)
          onTap: widget.onRangeSelected != null
              ? () => _onDateTapped(date, dateInfo, data, colors)
              : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: cellSize,
            height: cellSize,
            decoration: BoxDecoration(
              color: _getCellColor(
                dateInfo,
                isInRange,
                isHovered,
                isInteractive,
                colors,
              ),
              border: Border.all(
                color: isRangeStart || isRangeEnd
                    ? colors.textPrimary
                    : isToday
                    ? colors.textPrimary
                    : dateInfo.status.getBorderColor(colors),
                width: (isRangeStart || isRangeEnd || isToday)
                    ? BorderTokens.widthMedium
                    : BorderTokens.widthThin,
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
                // Day number in center
                Center(
                  child: Opacity(
                    opacity: isPast ? 0.5 : 1.0, // 50% opacity for past dates
                    child: Text(
                      day.toString(),
                      style: TextStyle(
                        fontSize: (cellSize * 0.45).clamp(8.0, 14.0),
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                ),
                // Today indicator dot
                if (isToday)
                  Positioned(
                    top: 1,
                    right: 1,
                    child: Container(
                      width: cellSize < 30 ? 3 : 4,
                      height: cellSize < 30 ? 3 : 4,
                      decoration: BoxDecoration(
                        color: colors.textPrimary,
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

  Color _getCellColor(
    CalendarDateInfo dateInfo,
    bool isInRange,
    bool isHovered,
    bool isInteractive,
    WidgetColorScheme colors,
  ) {
    if (isInRange) {
      // Match month calendar: available background + 20% black overlay
      final baseColor = colors.statusAvailableBackground;
      return Color.alphaBlend(
        colors.buttonPrimary.withOpacity(0.2),
        baseColor,
      );
    }

    if (isHovered && isInteractive) {
      // Lighten the color slightly on hover
      final baseColor = dateInfo.status.getColor(colors);
      return Color.alphaBlend(Colors.white.withOpacity(0.3), baseColor);
    }

    return dateInfo.status.getColor(colors);
  }

  Widget _buildEmptyCell(double cellSize, WidgetColorScheme colors) {
    return Container(
      width: cellSize,
      height: cellSize,
      decoration: BoxDecoration(
        color: colors.backgroundSecondary,
        border: Border.all(color: colors.borderLight),
        borderRadius: BorderTokens.circularTiny,
      ),
    );
  }

  void _onDateTapped(
    DateTime date,
    CalendarDateInfo dateInfo,
    Map<String, CalendarDateInfo> data,
    WidgetColorScheme colors,
  ) {
    final isDarkMode = ref.read(themeProvider);
    // Block past dates
    if (dateInfo.status == DateStatus.disabled) {
      SnackBarHelper.showError(
        context: context,
        message: 'Cannot select past dates.',
        isDarkMode: isDarkMode,
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
          isDarkMode: isDarkMode,
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
          isDarkMode: isDarkMode,
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
        isDarkMode: isDarkMode,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    if (isSelectingCheckOut && dateInfo.blockCheckOut) {
      SnackBarHelper.showError(
        context: context,
        message: 'Check-out is not allowed on this date.',
        isDarkMode: isDarkMode,
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
          SnackBarHelper.showError(
            context: context,
            message: 'Minimum stay is $minNights ${minNights == 1 ? 'night' : 'nights'}. You selected $selectedNights ${selectedNights == 1 ? 'night' : 'nights'}.',
            isDarkMode: isDarkMode,
            duration: const Duration(seconds: 3),
          );
          return;
        }

        // Check if this selection would create an orphan gap (gap < minNights)
        if (_wouldCreateOrphanGap(start, end, data, minNights)) {
          // Reset selection and show error
          _rangeStart = null;
          _rangeEnd = null;

          // Show error message
          SnackBarHelper.showError(
            context: context,
            message: 'This selection would leave a gap smaller than the $minNights-night minimum stay. Please choose different dates or extend your stay.',
            isDarkMode: isDarkMode,
          );
          return;
        }

        // Check if there are any booked/pending dates in the range
        if (_hasBlockedDatesInRange(start, end, data)) {
          // Reset selection and show error
          _rangeStart = null;
          _rangeEnd = null;

          // Show error message
          SnackBarHelper.showError(
            context: context,
            message: 'Cannot select dates. There are already booked dates in this range.',
            isDarkMode: isDarkMode,
            duration: const Duration(seconds: 3),
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

  /// Check if this selection would create an orphan gap (gap < minNights)
  /// An orphan gap occurs when the selection leaves a small gap before or after
  /// that is smaller than minNights, preventing future bookings
  bool _wouldCreateOrphanGap(
    DateTime start,
    DateTime end,
    Map<String, CalendarDateInfo> data,
    int minNights,
  ) {
    // Find the next booked/blocked date after the end date
    DateTime current = end.add(const Duration(days: 1));
    DateTime? nextBlockedDate;

    // Search up to 1 year ahead for the next blocked date
    final maxSearchDate = end.add(const Duration(days: 365));
    while (current.isBefore(maxSearchDate)) {
      final key = _getDateKey(current);
      final dateInfo = data[key];

      if (dateInfo != null &&
          (dateInfo.status == DateStatus.booked ||
              dateInfo.status == DateStatus.pending ||
              dateInfo.status == DateStatus.blocked ||
              dateInfo.status == DateStatus.partialCheckIn)) {
        nextBlockedDate = current;
        break;
      }
      current = current.add(const Duration(days: 1));
    }

    // If there's a blocked date after the selection, check the gap size
    if (nextBlockedDate != null) {
      final gapAfter = nextBlockedDate.difference(end).inDays - 1;
      if (gapAfter > 0 && gapAfter < minNights) {
        return true; // Would create orphan gap after selection
      }
    }

    // Find the previous booked/blocked date before the start date
    current = start.subtract(const Duration(days: 1));
    DateTime? prevBlockedDate;

    // Search up to 1 year back for the previous blocked date
    final minSearchDate = start.subtract(const Duration(days: 365));
    while (current.isAfter(minSearchDate)) {
      final key = _getDateKey(current);
      final dateInfo = data[key];

      if (dateInfo != null &&
          (dateInfo.status == DateStatus.booked ||
              dateInfo.status == DateStatus.pending ||
              dateInfo.status == DateStatus.blocked ||
              dateInfo.status == DateStatus.partialCheckOut)) {
        prevBlockedDate = current;
        break;
      }
      current = current.subtract(const Duration(days: 1));
    }

    // If there's a blocked date before the selection, check the gap size
    if (prevBlockedDate != null) {
      final gapBefore = start.difference(prevBlockedDate).inDays - 1;
      if (gapBefore > 0 && gapBefore < minNights) {
        return true; // Would create orphan gap before selection
      }
    }

    return false; // No orphan gaps would be created
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

  /// Build compact legend/info banner below calendar
  /// Shows minimum stay requirement and color legend
  Widget _buildCompactLegend(
    int minNights,
    WidgetColorScheme colors,
    bool isDarkMode,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrowScreen = screenWidth < 600;
    final isDesktop = screenWidth >= 1024;

    // Match calendar width: 650px desktop, 600px mobile/tablet
    final maxWidth = isDesktop ? 650.0 : 600.0;

    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Min stay info
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
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
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Min stay info
                  Row(
                    mainAxisSize: MainAxisSize.min,
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
                  const SizedBox(width: SpacingTokens.m),
                  // Color legend
                  _buildColorLegend(colors),
                ],
              ),
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

/// Simple painter for diagonal lines on check-in/check-out days
class _DiagonalLinePainter extends CustomPainter {
  final Color diagonalColor;
  final bool isCheckIn;

  _DiagonalLinePainter({required this.diagonalColor, required this.isCheckIn});

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
