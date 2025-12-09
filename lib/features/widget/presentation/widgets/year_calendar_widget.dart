import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/models/calendar_date_status.dart';
import '../l10n/widget_translations.dart';
import '../providers/realtime_booking_calendar_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/widget_context_provider.dart';
import '../theme/responsive_helper.dart';
import '../theme/minimalist_colors.dart';
import '../../../../core/design_tokens/design_tokens.dart';
import '../../../../core/localization/error_messages.dart';
import 'calendar/calendar_date_utils.dart';
import 'calendar/calendar_compact_legend.dart';
import 'calendar/calendar_combined_header_widget.dart';
import 'calendar/calendar_date_selection_validator.dart';
import 'calendar/calendar_tooltip_builder.dart';
import 'calendar/year_calendar_painters.dart';
import '../../../../../shared/utils/ui/snackbar_helper.dart';

class YearCalendarWidget extends ConsumerStatefulWidget {
  final String propertyId;
  final String unitId;
  final Function(DateTime? start, DateTime? end)? onRangeSelected;

  const YearCalendarWidget({super.key, required this.propertyId, required this.unitId, this.onRangeSelected});

  @override
  ConsumerState<YearCalendarWidget> createState() => _YearCalendarWidgetState();
}

class _YearCalendarWidgetState extends ConsumerState<YearCalendarWidget> {
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  int _currentYear = DateTime.now().year;
  DateTime? _hoveredDate;
  Offset _mousePosition = Offset.zero;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDarkMode = ref.watch(themeProvider);
    final colors = MinimalistColorSchemeAdapter(dark: isDarkMode);
    final tr = WidgetTranslations.of(context, ref);

    // Year calendar needs minimum width to be usable - show rotate message on very narrow screens
    const minWidthForYearCalendar = 350.0;
    if (screenWidth < minWidthForYearCalendar) {
      return _buildRotateDeviceOverlay(colors, tr);
    }

    // OPTIMIZED: Get minNights from cached widgetContext (eliminates duplicate unit fetch)
    final widgetCtxAsync = ref.watch(widgetContextProvider((
      propertyId: widget.propertyId,
      unitId: widget.unitId,
    )));
    final minNights = widgetCtxAsync.valueOrNull?.unit.minStayNights ?? 1;

    // Use realtime stream provider for automatic updates when bookings change
    final calendarData = ref.watch(realtimeYearCalendarProvider(widget.propertyId, widget.unitId, _currentYear));

    return Stack(
      children: [
        GestureDetector(
          // Swipe gesture for year navigation
          onHorizontalDragEnd: (details) {
            // Swipe right (previous year) - positive velocity
            if (details.primaryVelocity != null && details.primaryVelocity! > 0) {
              setState(() {
                _currentYear--;
              });
            }
            // Swipe left (next year) - negative velocity
            else if (details.primaryVelocity != null && details.primaryVelocity! < 0) {
              setState(() {
                _currentYear++;
              });
            }
          },
          child: Column(
            children: [
              // Combined header matching month/week view layout
              CalendarCombinedHeaderWidget(
                colors: colors,
                isDarkMode: isDarkMode,
                navigationWidget: _buildCompactYearNavigation(colors),
                translations: WidgetTranslations.of(context, ref),
              ),
              // Min nights info banner - between header and calendar
              if (minNights > 1)
                CalendarCompactLegend(
                  minNights: minNights,
                  colors: colors,
                  translations: WidgetTranslations.of(context, ref),
                ),
              Expanded(
                child: calendarData.when(
                  data: (data) => _buildYearGridWithIntegratedSelector(data, colors),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(child: Text(ErrorMessages.calendarError(error))),
                ),
              ),
            ],
          ),
        ),
        // Hover tooltip overlay (desktop) - highest z-index
        if (_hoveredDate != null)
          calendarData.when(
            data: (data) => CalendarTooltipBuilder.build(
              context: context,
              hoveredDate: _hoveredDate,
              mousePosition: _mousePosition,
              data: data,
              colors: colors,
            ),
            loading: () => const SizedBox.shrink(),
            error: (error, stack) => const SizedBox.shrink(),
          ),
      ],
    );
  }

  /// Shows a friendly message asking user to rotate device to landscape
  Widget _buildRotateDeviceOverlay(WidgetColorScheme colors, WidgetTranslations tr) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.screen_rotation_outlined, size: 64, color: colors.textSecondary),
            const SizedBox(height: SpacingTokens.l),
            Text(
              tr.rotateYourDevice,
              style: TextStyle(
                fontSize: TypographyTokens.fontSizeL,
                fontWeight: TypographyTokens.semiBold,
                color: colors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: SpacingTokens.s),
            Text(
              tr.rotateForBestExperience,
              style: TextStyle(fontSize: TypographyTokens.fontSizeS, color: colors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
          icon: Icon(Icons.chevron_left, size: isSmallScreen ? 16 : IconSizeTokens.small, color: colors.textPrimary),
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
        const SizedBox(width: SpacingTokens.xxs),
        Text(
          _currentYear.toString(),
          style: TextStyle(
            fontSize: isSmallScreen ? TypographyTokens.fontSizeS : TypographyTokens.fontSizeM,
            fontWeight: TypographyTokens.bold,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(width: SpacingTokens.xxs),
        IconButton(
          icon: Icon(Icons.chevron_right, size: isSmallScreen ? 16 : IconSizeTokens.small, color: colors.textPrimary),
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

    return Center(
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? SpacingTokens.l : SpacingTokens.m),
        child: Stack(
          children: [
            // Year calendar grid - part of page flow (no internal scroll)
            SizedBox(
              width: ConstraintTokens.monthLabelWidth + (31 * cellSize), // Month label width + 31 day columns
              child: Column(
                children: [
                  _buildHeaderRowWithYearSelector(cellSize, colors),
                  const SizedBox(height: SpacingTokens.s),
                  ...List.generate(12, (monthIndex) => _buildMonthRow(monthIndex + 1, data, cellSize, colors)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderRowWithYearSelector(double cellSize, WidgetColorScheme colors) {
    // Responsive font size for headers - proportional to cell size
    final headerFontSize = (cellSize * 0.5).clamp(9.0, 13.0);
    final dayNumberFontSize = (cellSize * 0.45).clamp(8.0, 12.0);

    return Row(
      children: [
        // Static "Month" label in top-left corner (localized)
        Container(
          width: ConstraintTokens.monthLabelWidth,
          height: cellSize,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.backgroundTertiary,
            border: Border.all(color: colors.borderLight),
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(BorderTokens.radiusSubtle)),
          ),
          child: Text(
            WidgetTranslations.of(context, ref).monthView,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: headerFontSize, color: colors.textPrimary),
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
              border: Border.all(color: colors.borderLight),
              borderRadius: dayIndex == 30
                  ? const BorderRadius.only(topRight: Radius.circular(BorderTokens.radiusSubtle))
                  : BorderRadius.zero,
            ),
            child: Text(
              (dayIndex + 1).toString(),
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: dayNumberFontSize, color: colors.textSecondary),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMonthRow(int month, Map<String, CalendarDateInfo> data, double cellSize, WidgetColorScheme colors) {
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
            color: colors.backgroundTertiary,
            border: Border.all(color: colors.borderLight),
            borderRadius: month == 12
                ? const BorderRadius.only(bottomLeft: Radius.circular(BorderTokens.radiusSubtle))
                : BorderRadius.zero,
          ),
          child: Text(
            monthName,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: monthFontSize, color: colors.textSecondary),
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

  /// Generate semantic label for screen readers (localized) - year view
  String _getSemanticLabelForDateYear(
    DateTime date,
    DateStatus status,
    bool isPending,
    bool isRangeStart,
    bool isRangeEnd,
    WidgetTranslations translations,
  ) {
    // Status description (localized)
    final statusStr = status == DateStatus.available
        ? translations.semanticAvailable
        : status == DateStatus.booked
        ? translations.semanticBooked
        : status == DateStatus.partialCheckIn
        ? translations.semanticCheckIn
        : status == DateStatus.partialCheckOut
        ? translations.semanticCheckOut
        : status == DateStatus.partialBoth
        ? translations.semanticTurnover
        : status == DateStatus.blocked
        ? translations.semanticBlocked
        : status == DateStatus.disabled
        ? translations.semanticUnavailable
        : translations.semanticPastReservation;

    final pendingStr = isPending ? ', ${translations.semanticPendingApproval}' : '';

    // Range indicators (localized)
    final rangeStr = isRangeStart
        ? ', ${translations.semanticCheckInDate}'
        : isRangeEnd
        ? ', ${translations.semanticCheckOutDate}'
        : '';

    // Format date (localized)
    final dateStr = translations.formatDateForSemantic(date);

    return '$dateStr, $statusStr$pendingStr$rangeStr';
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

      final key = CalendarDateUtils.getDateKey(date);
      final dateInfo = data[key];

      if (dateInfo == null) {
        // Day doesn't exist in this month or no data
        return _buildEmptyCell(cellSize, colors);
      }

      final isInRange = CalendarDateUtils.isDateInRange(date, _rangeStart, _rangeEnd);
      final isRangeStart = _rangeStart != null && CalendarDateUtils.isSameDay(date, _rangeStart!);
      final isRangeEnd = _rangeEnd != null && CalendarDateUtils.isSameDay(date, _rangeEnd!);
      final isHovered = _hoveredDate != null && CalendarDateUtils.isSameDay(date, _hoveredDate!);
      final today = DateTime.now();
      final todayNormalized = DateTime(today.year, today.month, today.day);
      final isToday = CalendarDateUtils.isSameDay(date, today);
      final isPast = date.isBefore(todayNormalized);

      // Determine if this is a check-in or check-out day
      final isPartialCheckIn = dateInfo.status == DateStatus.partialCheckIn;
      final isPartialCheckOut = dateInfo.status == DateStatus.partialCheckOut;
      final isPartialBoth = dateInfo.status == DateStatus.partialBoth;

      // Check if cell is interactive - only available dates can be selected
      // partialCheckIn, partialCheckOut, and pending are not selectable
      final isInteractive = dateInfo.status == DateStatus.available;

      // Show tooltip on all dates except disabled/past dates
      final showTooltip = dateInfo.status != DateStatus.disabled;

      // Generate semantic label for screen readers (localized)
      final translations = WidgetTranslations.of(context, ref);
      final String semanticLabel = _getSemanticLabelForDateYear(
        date,
        dateInfo.status,
        dateInfo.isPendingBooking,
        isRangeStart,
        isRangeEnd,
        translations,
      );

      return Semantics(
        label: semanticLabel,
        button: widget.onRangeSelected != null,
        enabled: isInteractive && widget.onRangeSelected != null,
        selected: isRangeStart || isRangeEnd,
        child: MouseRegion(
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
            // Disable tap in calendar_only mode (when onRangeSelected is null)
            onTap: widget.onRangeSelected != null ? () => _onDateTapped(date, dateInfo, data, colors) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: cellSize,
              height: cellSize,
              clipBehavior: Clip.antiAlias, // Clip pattern painters to cell bounds
              decoration: BoxDecoration(
                color: _getCellColor(dateInfo, isInRange, isHovered, isInteractive, colors),
                border: Border.all(
                  color: isRangeStart || isRangeEnd
                      ? colors.textPrimary
                      : isToday
                      ? colors.textPrimary
                      : dateInfo.status.getBorderColor(colors),
                  width: (isRangeStart || isRangeEnd || isToday) ? BorderTokens.widthMedium : BorderTokens.widthThin,
                ),
                borderRadius: BorderTokens.circularTiny,
                boxShadow: isHovered && isInteractive ? ShadowTokens.light : colors.shadowMinimal,
              ),
              child: Stack(
                children: [
                  // Diagonal pattern for partial check-in/out
                  if (isPartialCheckIn || isPartialCheckOut)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: DiagonalLinePainter(
                          diagonalColor: dateInfo.isPendingBooking
                              ? colors.statusPendingBackground
                              : dateInfo.status.getDiagonalColor(colors),
                          isCheckIn: isPartialCheckIn,
                          isPending: dateInfo.isPendingBooking,
                          patternLineColor: dateInfo.isPendingBooking
                              ? DateStatus.pending.getPatternLineColor(colors)
                              : null,
                        ),
                      ),
                    ),
                  // Split triangles for partialBoth (turnover day)
                  if (isPartialBoth)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: PartialBothPainter(
                          checkoutColor: dateInfo.isCheckOutPending
                              ? colors.statusPendingBackground
                              : colors.statusBookedBackground,
                          checkinColor: dateInfo.isCheckInPending
                              ? colors.statusPendingBackground
                              : colors.statusBookedBackground,
                          isCheckOutPending: dateInfo.isCheckOutPending,
                          isCheckInPending: dateInfo.isCheckInPending,
                          patternLineColor: DateStatus.pending.getPatternLineColor(colors),
                        ),
                      ),
                    ),
                  // Pending pattern overlay for full booked days (not partial, not partialBoth)
                  if (dateInfo.isPendingBooking &&
                      !isPartialCheckIn &&
                      !isPartialCheckOut &&
                      !isPartialBoth &&
                      dateInfo.status == DateStatus.booked)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: PendingPatternPainter(lineColor: DateStatus.pending.getPatternLineColor(colors)),
                      ),
                    ),
                  // Day number in center
                  Center(
                    child: Text(
                      day.toString(),
                      style: TextStyle(
                        fontSize: (cellSize * 0.45).clamp(8.0, 14.0),
                        fontWeight: FontWeight.w600,
                        // Past dates use secondary color for cleaner "disabled" look
                        color: isPast ? colors.textSecondary : colors.textPrimary,
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
                        decoration: BoxDecoration(color: colors.textPrimary, shape: BoxShape.circle),
                      ),
                    ),
                ],
              ),
            ), // AnimatedContainer
          ), // GestureDetector
        ), // MouseRegion
      ); // Semantics
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
      return Color.alphaBlend(colors.buttonPrimary.withValues(alpha: 0.2), baseColor);
    }

    // partialBoth is drawn with _PartialBothPainter, so return transparent
    if (dateInfo.status == DateStatus.partialBoth) {
      return Colors.transparent;
    }

    // Pending bookings use yellow background (for full booked days, not partial)
    if (dateInfo.isPendingBooking && dateInfo.status == DateStatus.booked) {
      if (isHovered && isInteractive) {
        return Color.alphaBlend(Colors.white.withValues(alpha: 0.3), colors.statusPendingBackground);
      }
      return colors.statusPendingBackground;
    }

    if (isHovered && isInteractive) {
      // Lighten the color slightly on hover
      final baseColor = dateInfo.status.getColor(colors);
      return Color.alphaBlend(Colors.white.withValues(alpha: 0.3), baseColor);
    }

    return dateInfo.status.getColor(colors);
  }

  Widget _buildEmptyCell(double cellSize, WidgetColorScheme colors) {
    return Container(
      width: cellSize,
      height: cellSize,
      decoration: BoxDecoration(
        color: colors.backgroundTertiary,
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
    final validator = CalendarDateSelectionValidator(context: context, ref: ref);

    // Pre-selection validation (past date, advance booking, restrictions)
    final preResult = validator.validatePreSelection(
      date: date,
      dateInfo: dateInfo,
      rangeStart: _rangeStart,
      rangeEnd: _rangeEnd,
    );
    if (!preResult.isValid) {
      validator.showError(preResult);
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
          return;
        }

        // Determine start/end order
        final DateTime start = date.isBefore(_rangeStart!) ? date : _rangeStart!;
        final DateTime end = date.isBefore(_rangeStart!) ? _rangeStart! : date;

        // OPTIMIZED: Get minNights from cached widgetContext (reuses cached data)
        final validationMinNights = ref.read(widgetContextProvider((
          propertyId: widget.propertyId,
          unitId: widget.unitId,
        ))).valueOrNull?.unit.minStayNights ?? 1;

        // Get check-in date info for validation
        final checkInDateInfo = data[CalendarDateUtils.getDateKey(start)];

        // Range validation (minNights, minNightsOnArrival, maxNightsOnArrival)
        final rangeResult = validator.validateRange(
          start: start,
          end: end,
          minNights: validationMinNights,
          checkInDateInfo: checkInDateInfo,
        );
        if (!rangeResult.isValid) {
          _rangeStart = null;
          _rangeEnd = null;
          validator.showError(rangeResult);
          return;
        }

        // Year calendar specific: Check orphan gap
        if (_wouldCreateOrphanGap(start, end, data, validationMinNights)) {
          _rangeStart = null;
          _rangeEnd = null;
          SnackBarHelper.showError(
            context: context,
            message: WidgetTranslations.of(context, ref).errorOrphanGap(validationMinNights),
          );
          return;
        }

        // Year calendar specific: Check blocked dates in range
        if (_hasBlockedDatesInRange(start, end, data)) {
          _rangeStart = null;
          _rangeEnd = null;
          SnackBarHelper.showError(
            context: context,
            message: WidgetTranslations.of(context, ref).errorCannotSelectBookedDates,
            duration: const Duration(seconds: 3),
          );
          return;
        }

        // Set the range
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
  bool _hasBlockedDatesInRange(DateTime start, DateTime end, Map<String, CalendarDateInfo> data) {
    DateTime current = start;
    while (current.isBefore(end) || CalendarDateUtils.isSameDay(current, end)) {
      final key = CalendarDateUtils.getDateKey(current);
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
          final isEndpoint = CalendarDateUtils.isSameDay(current, start) || CalendarDateUtils.isSameDay(current, end);
          final isPartialDate =
              dateInfo.status == DateStatus.partialCheckIn || dateInfo.status == DateStatus.partialCheckOut;

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
  bool _wouldCreateOrphanGap(DateTime start, DateTime end, Map<String, CalendarDateInfo> data, int minNights) {
    // Find the next booked/blocked date after the end date
    DateTime current = end.add(const Duration(days: 1));
    DateTime? nextBlockedDate;

    // Search up to 1 year ahead for the next blocked date
    final maxSearchDate = end.add(const Duration(days: 365));
    while (current.isBefore(maxSearchDate)) {
      final key = CalendarDateUtils.getDateKey(current);
      final dateInfo = data[key];

      if (dateInfo != null &&
          (dateInfo.status == DateStatus.booked ||
              dateInfo.status == DateStatus.pending ||
              dateInfo.status == DateStatus.blocked ||
              dateInfo.status == DateStatus.partialCheckIn ||
              dateInfo.status == DateStatus.partialBoth)) {
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
      final key = CalendarDateUtils.getDateKey(current);
      final dateInfo = data[key];

      if (dateInfo != null &&
          (dateInfo.status == DateStatus.booked ||
              dateInfo.status == DateStatus.pending ||
              dateInfo.status == DateStatus.blocked ||
              dateInfo.status == DateStatus.partialCheckOut ||
              dateInfo.status == DateStatus.partialBoth)) {
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
}
