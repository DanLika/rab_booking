import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/models/calendar_date_status.dart';
import '../l10n/widget_translations.dart';
import '../providers/realtime_booking_calendar_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/widget_context_provider.dart';
import 'split_day_calendar_painter.dart';
import 'calendar/calendar_date_utils.dart';
import 'calendar/calendar_compact_legend.dart';
import 'calendar/calendar_combined_header_widget.dart';
import 'calendar/calendar_date_selection_validator.dart';
import 'calendar/calendar_tooltip_builder.dart';
import '../theme/responsive_helper.dart';
import '../../../../core/localization/error_messages.dart';
import '../theme/minimalist_colors.dart';
import '../../../../../core/design_tokens/design_tokens.dart';
import '../../../../../shared/utils/ui/snackbar_helper.dart';
import 'calendar/month_calendar_skeleton.dart';

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
  DateTime _currentMonth = DateTime.utc(
    DateTime.now().toUtc().year,
    DateTime.now().toUtc().month,
  );
  DateTime? _hoveredDate; // For hover tooltip (desktop)
  Offset _mousePosition = Offset.zero; // Track mouse position for tooltip
  bool _isValidating = false; // Prevent concurrent date range validations

  @override
  Widget build(BuildContext context) {
    // OPTIMIZED: Get minNights from cached widgetContext (eliminates duplicate unit fetch)
    final widgetCtxAsync = ref.watch(
      widgetContextProvider((
        propertyId: widget.propertyId,
        unitId: widget.unitId,
      )),
    );
    // Defensive null check: handle loading/error states gracefully
    final widgetCtx = widgetCtxAsync.valueOrNull;
    final minNights = widgetCtx?.unit.minStayNights ?? 1;

    // Use realtime stream provider for automatic updates when bookings change
    // OPTIMIZED: Pass minNights to eliminate redundant widgetSettings stream fetch
    final calendarData = ref.watch(
      realtimeMonthCalendarProvider(
        widget.propertyId,
        widget.unitId,
        _currentMonth.year,
        _currentMonth.month,
        minNights,
      ),
    );
    final isDarkMode = ref.watch(themeProvider);
    final colors = MinimalistColorSchemeAdapter(dark: isDarkMode);

    return Column(
      mainAxisSize:
          MainAxisSize.min, // Take only needed height for iframe embedding
      children: [
        // Combined header - explicitly outside any GestureDetector
        CalendarCombinedHeaderWidget(
          colors: colors,
          isDarkMode: isDarkMode,
          navigationWidget: _buildCompactMonthNavigation(colors),
          translations: WidgetTranslations.of(context, ref),
        ),
        // Min nights info banner - between header and calendar
        if (minNights > 1)
          CalendarCompactLegend(
            minNights: minNights,
            colors: colors,
            translations: WidgetTranslations.of(context, ref),
          ),

        // Calendar and tooltip in Stack for overlay positioning
        // Note: No Expanded - calendar takes natural height for proper inline layout
        MouseRegion(
          onHover: (event) =>
              setState(() => _mousePosition = event.localPosition),
          child: GestureDetector(
            // Swipe gesture for month navigation
            onHorizontalDragEnd: (details) {
              // Swipe right (previous month) - positive velocity
              if (details.primaryVelocity != null &&
                  details.primaryVelocity! > 0) {
                setState(() {
                  _currentMonth = _previousMonth(_currentMonth);
                  // Only clear range if BOTH dates are selected (complete selection)
                  if (_rangeStart != null && _rangeEnd != null) {
                    _rangeStart = null;
                    _rangeEnd = null;
                    widget.onRangeSelected?.call(null, null);
                  }
                });
              }
              // Swipe left (next month) - negative velocity
              else if (details.primaryVelocity != null &&
                  details.primaryVelocity! < 0) {
                setState(() {
                  _currentMonth = _nextMonth(_currentMonth);
                  // Only clear range if BOTH dates are selected (complete selection)
                  if (_rangeStart != null && _rangeEnd != null) {
                    _rangeStart = null;
                    _rangeEnd = null;
                    widget.onRangeSelected?.call(null, null);
                  }
                });
              }
            },
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
                  child: calendarData.when(
                    data: (data) => _buildMonthView(data, colors),
                    loading: () => const MonthCalendarSkeleton(),
                    error: (error, stack) =>
                        Center(child: Text(ErrorMessages.calendarError(error))),
                  ),
                ),
                // Hover tooltip overlay (desktop) - highest z-index
                if (_hoveredDate != null)
                  calendarData.when(
                    data: (data) {
                      // Defensive null check: ensure widgetCtxAsync has valid data before accessing unit
                      // Re-read from async value to ensure we have the latest state
                      final currentWidgetCtx = widgetCtxAsync.valueOrNull;
                      final fallbackPrice =
                          currentWidgetCtx?.unit.pricePerNight;
                      return CalendarTooltipBuilder.build(
                        context: context,
                        hoveredDate: _hoveredDate,
                        mousePosition: _mousePosition,
                        data: data,
                        colors: colors,
                        tooltipHeight: 120.0,
                        ignorePointer: true,
                        // Use unit's base price as fallback when no daily_price exists
                        fallbackPrice: fallbackPrice,
                      );
                    },
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

  /// Navigate to previous month with proper year boundary handling
  DateTime _previousMonth(DateTime current) {
    if (current.month == 1) {
      return DateTime.utc(current.year - 1, 12);
    } else {
      return DateTime.utc(current.year, current.month - 1);
    }
  }

  /// Navigate to next month with proper year boundary handling
  DateTime _nextMonth(DateTime current) {
    if (current.month == 12) {
      return DateTime.utc(current.year + 1);
    } else {
      return DateTime.utc(current.year, current.month + 1);
    }
  }

  Widget _buildCompactMonthNavigation(WidgetColorScheme colors) {
    final mediaQuery = MediaQuery.maybeOf(context);
    final screenWidth = mediaQuery?.size.width ?? 400.0;
    final isSmallScreen = screenWidth < 400; // iPhone SE and similar
    final isTinyScreen = screenWidth < 360; // Very small screens
    final locale = Localizations.localeOf(context);
    final monthYear = DateFormat.yMMM(locale.toString()).format(_currentMonth);

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
              _currentMonth = _previousMonth(_currentMonth);
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
        // Always show month/year - essential for user orientation
        // Use smaller font on tiny screens instead of hiding
        Text(
          monthYear,
          style: TextStyle(
            fontSize: isTinyScreen
                ? TypographyTokens.fontSizeXS
                : isSmallScreen
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
              _currentMonth = _nextMonth(_currentMonth);
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
        final mediaQuery = MediaQuery.maybeOf(context);
        final screenWidth = mediaQuery?.size.width ?? 400.0;
        final screenHeight = mediaQuery?.size.height ?? 800.0;
        final maxHeight =
            screenHeight * 0.75; // 75% of screen height for better centering

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
      child: Padding(
        // No top padding - spacing handled by CalendarCompactLegend margin (consistent with year view)
        padding: const EdgeInsets.only(
          left: SpacingTokens.l,
          right: SpacingTokens.l,
          bottom: SpacingTokens.m,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: _buildSingleMonthGrid(_currentMonth, data, maxHeight, colors),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(
    Map<String, CalendarDateInfo> data,
    double maxHeight,
    WidgetColorScheme colors,
  ) {
    return Center(
      child: Padding(
        // No top padding - spacing handled by CalendarCompactLegend margin (consistent with year view)
        padding: const EdgeInsets.only(
          left: SpacingTokens.s,
          right: SpacingTokens.s,
          bottom: SpacingTokens.s,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: _buildSingleMonthGrid(_currentMonth, data, maxHeight, colors),
        ),
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
      mainAxisSize: MainAxisSize.min, // Take only needed height
      children: [
        // Week day headers
        _buildWeekDayHeaders(colors),
        const SizedBox(height: SpacingTokens.s),
        // RepaintBoundary: Calendar grid repaints independently from headers
        // when dates are selected or hovered
        RepaintBoundary(child: _buildMonthGridForMonth(month, data, colors)),
      ],
    );
  }

  Widget _buildWeekDayHeaders(WidgetColorScheme colors) {
    final weekDays = WidgetTranslations.of(context, ref).weekdaysShort;

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
    // Get first day of month - use UTC to match CalendarDateUtils.getDateKey()
    final firstDay = DateTime.utc(month.year, month.month);

    // Get last day of month - use UTC for consistency
    final lastDay = DateTime.utc(month.year, month.month + 1, 0);

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

        // Use UTC to match CalendarDateUtils.getDateKey() and database keys
        final date = DateTime.utc(month.year, month.month, dayOffset + 1);
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

    final isInRange = CalendarDateUtils.isDateInRange(
      date,
      _rangeStart,
      _rangeEnd,
    );
    final isRangeStart =
        _rangeStart != null && CalendarDateUtils.isSameDay(date, _rangeStart!);
    final isRangeEnd =
        _rangeEnd != null && CalendarDateUtils.isSameDay(date, _rangeEnd!);
    final today = DateTime.now().toUtc();
    final todayNormalized = DateTime.utc(today.year, today.month, today.day);
    final isToday = CalendarDateUtils.isSameDay(date, today);
    final isPast = date.isBefore(todayNormalized);

    final isHovered =
        _hoveredDate != null &&
        CalendarDateUtils.isSameDay(date, _hoveredDate!);

    // Generate semantic label for screen readers (localized)
    final translations = WidgetTranslations.of(context, ref);
    final String semanticLabel = CalendarDateUtils.getSemanticLabel(
      date: date,
      status: dateInfo.status,
      isPending: dateInfo.isPendingBooking,
      isRangeStart: isRangeStart,
      isRangeEnd: isRangeEnd,
      translations: translations,
    );

    return Semantics(
      label: semanticLabel,
      button: widget.onRangeSelected != null,
      enabled:
          dateInfo.status == DateStatus.available &&
          widget.onRangeSelected != null,
      selected: isRangeStart || isRangeEnd,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hoveredDate = date),
        onExit: (_) => setState(() => _hoveredDate = null),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          // In calendar_only mode (onRangeSelected is null), show helpful message on tap
          onTap: widget.onRangeSelected != null
              ? () => _onDateTapped(date, dateInfo, data, colors)
              : () => _onViewOnlyTap(translations),
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
                  child: Text(
                    date.day.toString(),
                    style: TextStyle(
                      fontSize: TypographyTokens.fontSizeL,
                      fontWeight: TypographyTokens.bold,
                      // Past dates use secondary color for cleaner "disabled" look
                      color: isPast ? colors.textSecondary : colors.textPrimary,
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
        ), // GestureDetector
      ), // MouseRegion
    ); // Semantics
  }

  Widget _buildEmptyCell(WidgetColorScheme colors) {
    return Container(
      margin: const EdgeInsets.all(BorderTokens.widthThin),
      decoration: BoxDecoration(
        color: colors.backgroundTertiary,
        border: Border.all(color: colors.borderLight),
        borderRadius: BorderTokens.circularSubtle,
      ),
      child: const Opacity(
        opacity: OpacityTokens.mostlyVisible,
        child: SizedBox.expand(),
      ),
    );
  }

  void _onDateTapped(
    DateTime date,
    CalendarDateInfo dateInfo,
    Map<String, CalendarDateInfo> data,
    WidgetColorScheme colors,
  ) {
    final validator = CalendarDateSelectionValidator(
      context: context,
      ref: ref,
    );

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
        final DateTime start = date.isBefore(_rangeStart!)
            ? date
            : _rangeStart!;
        final DateTime end = date.isBefore(_rangeStart!) ? _rangeStart! : date;

        // Get date info for both start and end dates
        final startKey = DateFormat('yyyy-MM-dd').format(start);
        final endKey = DateFormat('yyyy-MM-dd').format(end);
        final startDateInfo = data[startKey];
        final endDateInfo = data[endKey];

        // CRITICAL: Re-validate blockCheckIn/blockCheckOut with FINAL date order
        // Pre-selection validation uses click order, but we need to check actual check-in/check-out dates
        if (startDateInfo != null && startDateInfo.blockCheckIn) {
          SnackBarHelper.showError(
            context: context,
            message: WidgetTranslations.of(context, ref).errorCheckInNotAllowed,
          );
          return;
        }
        if (endDateInfo != null && endDateInfo.blockCheckOut) {
          SnackBarHelper.showError(
            context: context,
            message: WidgetTranslations.of(
              context,
              ref,
            ).errorCheckOutNotAllowed,
          );
          return;
        }

        // OPTIMIZED: Get min/maxNights from cached widgetContext (reuses cached data)
        final unitData = ref
            .read(
              widgetContextProvider((
                propertyId: widget.propertyId,
                unitId: widget.unitId,
              )),
            )
            .valueOrNull
            ?.unit;
        final validationMinNights = unitData?.minStayNights ?? 1;
        final validationMaxNights = unitData?.maxStayNights;

        // Range validation (minNights, maxNights, minNightsOnArrival, maxNightsOnArrival)
        // Note: startDateInfo is already fetched above for blockCheckIn validation
        final rangeResult = validator.validateRange(
          start: start,
          end: end,
          minNights: validationMinNights,
          maxNights: validationMaxNights,
          checkInDateInfo: startDateInfo,
        );
        if (!rangeResult.isValid) {
          // For month calendar: keep check-in selected, just show error
          validator.showError(rangeResult);
          return;
        }

        // Month calendar specific: Use backend availability check for cross-month validation
        _validateAndSetRange(start, end, colors);
      }
    });
  }

  /// Show helpful message when user taps date in calendar_only (view-only) mode
  void _onViewOnlyTap(WidgetTranslations translations) {
    SnackBarHelper.showInfo(
      context: context,
      message: translations.calendarOnlyTapMessage,
    );
  }

  /// Bug #72 Fix: Async validation using backend availability check
  /// This ensures cross-month date ranges are properly validated
  ///
  /// RACE CONDITION PROTECTION:
  /// - Uses _isValidating guard to prevent concurrent validation requests
  /// - Scenario: User rapidly clicks multiple dates → only first validation executes
  /// - Without guard: Multiple async calls could overwrite each other's results
  Future<void> _validateAndSetRange(
    DateTime start,
    DateTime end,
    WidgetColorScheme colors,
  ) async {
    // Prevent concurrent validations (race condition protection)
    if (_isValidating) return;

    setState(() => _isValidating = true);

    try {
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
          message: WidgetTranslations.of(
            context,
            ref,
          ).errorCannotSelectBookedDates,
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
    } finally {
      // Always reset validation flag (even if error occurs)
      if (mounted) {
        setState(() => _isValidating = false);
      }
    }
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
