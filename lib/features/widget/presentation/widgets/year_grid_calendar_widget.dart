import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/models/calendar_date_status.dart';
import '../providers/realtime_booking_calendar_provider.dart';
import '../providers/theme_provider.dart';
import 'split_day_calendar_painter.dart';
import 'year_view_preloader.dart';
import '../../../../../core/design_tokens/design_tokens.dart';
import '../utils/snackbar_helper.dart';

/// Year-view grid calendar widget inspired by BedBooking
/// Shows 12 months × 31 days in a grid with diagonal splits for check-in/check-out
class YearGridCalendarWidget extends ConsumerStatefulWidget {
  final String unitId;
  final Function(DateTime? start, DateTime? end)? onRangeSelected;
  final int? initialYear;
  final int minStayNights;

  const YearGridCalendarWidget({
    super.key,
    required this.unitId,
    this.onRangeSelected,
    this.initialYear,
    this.minStayNights = 1,
  });

  @override
  ConsumerState<YearGridCalendarWidget> createState() =>
      _YearGridCalendarWidgetState();
}

class _YearGridCalendarWidgetState
    extends ConsumerState<YearGridCalendarWidget> {
  late int _currentYear;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  DateTime? _hoverDate; // For hover tooltip
  DateTime? _dragStart; // For drag-to-select
  bool _isDragging = false;
  Offset _mousePosition = Offset.zero; // Track mouse position for tooltip

  // For tap info panel (mobile)
  DateTime? _tappedDate;
  Offset? _tapPosition;

  @override
  void initState() {
    super.initState();
    _currentYear = widget.initialYear ?? DateTime.now().year;
  }

  @override
  Widget build(BuildContext context) {
    final calendarData = ref.watch(
      realtimeYearCalendarProvider(widget.unitId, _currentYear),
    );
    final isDarkMode = ref.watch(themeProvider);
    final colors = isDarkMode ? ColorTokens.dark : ColorTokens.light;

    return Stack(
      children: [
        Column(
          children: [
            _buildHeader(),
            const SizedBox(height: SpacingTokens.m),
            _buildLegend(),
            const SizedBox(height: SpacingTokens.m),
            Expanded(
              child: calendarData.when(
                data: (data) => _buildYearGrid(data, colors),
                loading: () => YearViewPreloader(year: _currentYear),
                error: (error, stack) => Center(
                  child: Text(
                    'Greška pri učitavanju kalendara: $error',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ),
          ],
        ),

        // Hover tooltip (desktop)
        if (_hoverDate != null) _buildHoverTooltip(calendarData, colors),

        // Tap info panel (mobile)
        if (_tappedDate != null && _tapPosition != null)
          _buildTapInfoPanel(calendarData, colors),
      ],
    );
  }

  Widget _buildHeader() {
    final isDarkMode = ref.watch(themeProvider);
    final colors = isDarkMode ? ColorTokens.dark : ColorTokens.light;

    return Container(
      padding: SpacingTokens.allM,
      decoration: BoxDecoration(
        color: colors.backgroundSecondary,
        borderRadius: BorderTokens.circularRounded,
        boxShadow: ShadowTokens.light,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left, color: colors.textPrimary),
            onPressed: () {
              setState(() {
                _currentYear--;
              });
            },
          ),
          Text(
            'Yearly view',
            style: TextStyle(
              fontSize: TypographyTokens.fontSizeL,
              fontWeight: TypographyTokens.semiBold,
              color: colors.textPrimary,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: SpacingTokens.m,
              vertical: SpacingTokens.s,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: colors.borderDefault),
              borderRadius: BorderTokens.circularSubtle,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _currentYear,
                isDense: true,
                dropdownColor: colors.backgroundSecondary,
                style: TextStyle(color: colors.textPrimary),
                items: List.generate(10, (index) {
                  final year = DateTime.now().year - 2 + index;
                  return DropdownMenuItem(
                    value: year,
                    child: Text(year.toString()),
                  );
                }).toList(),
                onChanged: (year) {
                  if (year != null) {
                    setState(() {
                      _currentYear = year;
                    });
                  }
                },
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right, color: colors.textPrimary),
            onPressed: () {
              setState(() {
                _currentYear++;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    final isDarkMode = ref.watch(themeProvider);
    final colors = isDarkMode ? ColorTokens.dark : ColorTokens.light;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;

    // Match calendar width constraint
    final maxWidth = isDesktop ? 650.0 : 600.0;

    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        padding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.s,
          vertical: SpacingTokens.xs,
        ),
        decoration: BoxDecoration(
          color: colors.backgroundSecondary,
          borderRadius: BorderTokens.circularMedium,
          border: Border.all(color: colors.borderLight),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLegendItem('Available', colors.statusAvailableBackground, colors),
            const SizedBox(width: SpacingTokens.l),
            _buildLegendItem('Booked', colors.statusBookedBackground, colors),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, WidgetColorScheme colors) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: IconSizeTokens.medium,
          height: IconSizeTokens.medium,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: colors.borderDefault),
            borderRadius: BorderTokens.circularSubtle,
          ),
        ),
        const SizedBox(width: SpacingTokens.s),
        Text(
          label,
          style: TextStyle(
            fontSize: TypographyTokens.fontSizeM,
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildYearGrid(
    Map<DateTime, CalendarDateInfo> data,
    WidgetColorScheme colors,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive cell sizing based on screen size
        final responsiveCellSize = SpacingTokens.yearCalendarCellSize(context);

        // Calculate cell size based on available width
        // Reserve space for month labels
        final monthLabelWidth = ConstraintTokens.monthLabelWidth;
        final availableWidth =
            constraints.maxWidth - monthLabelWidth - SpacingTokens.m2;
        // Use responsive size but clamp based on available width
        final cellSize = (availableWidth / 31).clamp(
          responsiveCellSize *
              OpacityTokens
                  .badgeSubtle, // Minimum 80% of responsive size (0.8 * size)
          responsiveCellSize * 1.2, // Maximum 120% of responsive size
        );

        return SingleChildScrollView(
          child: Column(
            children: [
              // Day numbers header (1-31)
              _buildDayNumbersHeader(cellSize, monthLabelWidth),
              const SizedBox(height: SpacingTokens.xs),

              // 12 month rows
              ...List.generate(12, (monthIndex) {
                return _buildMonthRow(
                  monthIndex + 1,
                  data,
                  cellSize,
                  monthLabelWidth,
                  colors,
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDayNumbersHeader(double cellSize, double monthLabelWidth) {
    final isDarkMode = ref.watch(themeProvider);
    final colors = isDarkMode ? ColorTokens.dark : ColorTokens.light;

    return Row(
      children: [
        SizedBox(width: monthLabelWidth),
        ...List.generate(31, (dayIndex) {
          final dayNumber = dayIndex + 1;
          return SizedBox(
            width: cellSize,
            height: IconSizeTokens.large,
            child: Center(
              child: Text(
                dayNumber.toString(),
                style: TextStyle(
                  fontSize: TypographyTokens.fontSizeXS2,
                  color: colors.textSecondary,
                  fontWeight: TypographyTokens.medium,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMonthRow(
    int month,
    Map<DateTime, CalendarDateInfo> data,
    double cellSize,
    double monthLabelWidth,
    WidgetColorScheme colors,
  ) {
    final monthName = DateFormat('MMM').format(DateTime(_currentYear, month));
    final daysInMonth = DateTime(_currentYear, month + 1, 0).day;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: SpacingTokens.xxs),
      child: Row(
        children: [
          // Month label
          SizedBox(
            width: monthLabelWidth,
            child: Text(
              monthName,
              style: TextStyle(
                fontSize: TypographyTokens.fontSizeM,
                fontWeight: TypographyTokens.semiBold,
                color: colors.textPrimary,
              ),
            ),
          ),

          // Day cells
          ...List.generate(31, (dayIndex) {
            final dayNumber = dayIndex + 1;

            if (dayNumber > daysInMonth) {
              // Gray out invalid days
              return SizedBox(
                width: cellSize,
                height: cellSize,
                child: Container(
                  decoration: BoxDecoration(
                    color: colors.backgroundTertiary,
                    border: Border.all(color: colors.borderLight),
                    borderRadius: BorderTokens
                        .circularTiny, // Subtle radius for softer visual
                  ),
                ),
              );
            }

            final date = DateTime(_currentYear, month, dayNumber);
            final dateInfo = data[date];
            final status = dateInfo?.status ?? DateStatus.available;
            final priceText = dateInfo?.formattedPrice; // Get formatted price

            // Check if date is in the past
            final today = DateTime.now();
            final todayNormalized = DateTime(
              today.year,
              today.month,
              today.day,
            );
            final isPastDate = date.isBefore(todayNormalized);

            final isInRange =
                _rangeStart != null &&
                _rangeEnd != null &&
                date.isAfter(_rangeStart!) &&
                date.isBefore(_rangeEnd!);

            final isSelected = date == _rangeStart || date == _rangeEnd;

            // Accessibility wrapper
            return Semantics(
              label: _buildSemanticLabel(date, status, priceText, isPastDate),
              button: !isPastDate && status == DateStatus.available,
              enabled: !isPastDate && status == DateStatus.available,
              excludeSemantics: true, // Exclude child semantics
              child: MouseRegion(
                onEnter: isPastDate ? null : (_) => _handleDayHoverEnter(date),
                onExit: isPastDate ? null : (_) => _handleDayHoverExit(),
                onHover: isPastDate
                    ? null
                    : (event) =>
                          setState(() => _mousePosition = event.position),
                cursor: isPastDate
                    ? SystemMouseCursors.forbidden
                    : (status == DateStatus.booked ||
                              status == DateStatus.blocked
                          ? SystemMouseCursors.forbidden
                          : SystemMouseCursors.click),
                child: GestureDetector(
                  onTapDown: isPastDate
                      ? null
                      : (details) => _handleDayTapDown(date, details, status),
                  onTapUp: isPastDate
                      ? null
                      : (_) => _handleDayTapUp(date, dateInfo),
                  onLongPressStart: isPastDate
                      ? null
                      : (details) => _handleDayLongPress(date, details),
                  onPanStart: isPastDate
                      ? null
                      : (_) => _handleDragStart(date, dateInfo),
                  onPanUpdate: isPastDate
                      ? null
                      : (_) => _handleDragUpdate(date),
                  onPanEnd: isPastDate ? null : (_) => _handleDragEnd(),
                  child: SizedBox(
                    width: cellSize,
                    height: cellSize,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isPastDate ? colors.backgroundTertiary : null,
                        border: Border.all(
                          color: isSelected
                              ? colors
                                    .borderFocus // Black for selection
                              : (isInRange
                                    ? colors.borderMedium
                                    : colors.borderDefault),
                          width: isSelected
                              ? BorderTokens.widthThick
                              : BorderTokens.widthMedium,
                        ),
                        borderRadius: BorderTokens
                            .circularTiny, // Subtle radius for softer visual
                        // Hover effect - subtle shadow
                        boxShadow: _hoverDate == date && !isPastDate
                            ? ShadowTokens.calendarCellHover
                            : ShadowTokens.subtle,
                      ),
                      child: isPastDate
                          ? Center(
                              child: Icon(
                                Icons.block,
                                size: cellSize * OpacityTokens.mostlyVisible,
                                color: colors.textDisabled,
                              ),
                            )
                          : CustomPaint(
                              painter: SplitDayCalendarPainter(
                                status: status,
                                borderColor: colors.borderDefault,
                                priceText: priceText,
                                colors: colors,
                              ),
                              child: const SizedBox.expand(),
                            ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ============================================================
  // HOVER HANDLERS (Desktop)
  // ============================================================

  void _handleDayHoverEnter(DateTime date) {
    setState(() {
      _hoverDate = date;
    });
  }

  void _handleDayHoverExit() {
    setState(() {
      _hoverDate = null;
    });
  }

  // ============================================================
  // TAP HANDLERS (Mobile & Desktop)
  // ============================================================

  void _handleDayTapDown(
    DateTime date,
    TapDownDetails details,
    DateStatus status,
  ) {
    // Store tap position for mobile info panel
    if (Theme.of(context).platform == TargetPlatform.android ||
        Theme.of(context).platform == TargetPlatform.iOS) {
      setState(() {
        _tappedDate = date;
        _tapPosition = details.globalPosition;
      });

      // Auto-hide after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _tappedDate == date) {
          setState(() {
            _tappedDate = null;
            _tapPosition = null;
          });
        }
      });
    }
  }

  void _handleDayTapUp(DateTime date, CalendarDateInfo? dateInfo) {
    _handleDayTap(date, dateInfo);
  }

  void _handleDayLongPress(DateTime date, LongPressStartDetails details) {
    // Show info panel on long press (mobile)
    setState(() {
      _tappedDate = date;
      _tapPosition = details.globalPosition;
    });
  }

  void _handleDayTap(DateTime date, CalendarDateInfo? dateInfo) {
    final status = dateInfo?.status ?? DateStatus.available;

    // Don't allow selection of past dates
    final today = DateTime.now();
    final todayNormalized = DateTime(today.year, today.month, today.day);
    if (date.isBefore(todayNormalized)) {
      return;
    }

    // Don't allow selection of booked or blocked dates
    if (status == DateStatus.booked || status == DateStatus.blocked) {
      return;
    }

    setState(() {
      if (_rangeStart == null || (_rangeStart != null && _rangeEnd != null)) {
        // Start new selection (this is check-in date)

        // Check if check-in is blocked on this date
        if (dateInfo?.blockCheckIn == true) {
          if (mounted) {
            final isDarkMode = ref.read(themeProvider);
            SnackBarHelper.showError(
              context: context,
              message: 'Check-in is not allowed on this date.',
              isDarkMode: isDarkMode,
              duration: AnimationTokens.notification,
            );
          }
          return;
        }

        _rangeStart = date;
        _rangeEnd = null;
      } else if (_rangeStart != null && _rangeEnd == null) {
        // Complete selection (this is check-out date)
        DateTime tempStart = _rangeStart!;
        DateTime tempEnd = date;

        if (date.isBefore(_rangeStart!)) {
          tempStart = date;
          tempEnd = _rangeStart!;
        }

        // Get check-in date info for minNightsOnArrival/maxNightsOnArrival validation
        final calendarDataAsync = ref.read(
          realtimeYearCalendarProvider(widget.unitId, _currentYear),
        );

        CalendarDateInfo? checkInDateInfo;
        calendarDataAsync.whenData((data) {
          checkInDateInfo = data[tempStart];
        });

        // Check if check-out is blocked on the end date
        CalendarDateInfo? checkOutDateInfo;
        calendarDataAsync.whenData((data) {
          checkOutDateInfo = data[tempEnd];
        });

        if (checkOutDateInfo?.blockCheckOut == true) {
          if (mounted) {
            final isDarkMode = ref.read(themeProvider);
            SnackBarHelper.showError(
              context: context,
              message: 'Check-out is not allowed on this date.',
              isDarkMode: isDarkMode,
              duration: AnimationTokens.notification,
            );
          }
          // Reset selection
          _rangeStart = null;
          _rangeEnd = null;
          return;
        }

        // Validate minimum stay requirement
        final nights = tempEnd.difference(tempStart).inDays;

        // Check minNightsOnArrival from check-in date (if set)
        final minNightsOnArrival = checkInDateInfo?.minNightsOnArrival;
        if (minNightsOnArrival != null && minNightsOnArrival > 0 && nights < minNightsOnArrival) {
          if (mounted) {
            final isDarkMode = ref.read(themeProvider);
            SnackBarHelper.showError(
              context: context,
              message: 'Minimum stay for this arrival date is $minNightsOnArrival ${minNightsOnArrival == 1 ? 'night' : 'nights'}. You selected $nights ${nights == 1 ? 'night' : 'nights'}.',
              isDarkMode: isDarkMode,
              duration: AnimationTokens.notification,
            );
          }
          // Reset selection
          _rangeStart = null;
          _rangeEnd = null;
          return;
        }

        // Check maxNightsOnArrival from check-in date (if set)
        final maxNightsOnArrival = checkInDateInfo?.maxNightsOnArrival;
        if (maxNightsOnArrival != null && maxNightsOnArrival > 0 && nights > maxNightsOnArrival) {
          if (mounted) {
            final isDarkMode = ref.read(themeProvider);
            SnackBarHelper.showError(
              context: context,
              message: 'Maximum stay for this arrival date is $maxNightsOnArrival ${maxNightsOnArrival == 1 ? 'night' : 'nights'}. You selected $nights ${nights == 1 ? 'night' : 'nights'}.',
              isDarkMode: isDarkMode,
              duration: AnimationTokens.notification,
            );
          }
          // Reset selection
          _rangeStart = null;
          _rangeEnd = null;
          return;
        }

        // Fallback to widget's minStayNights if no date-specific minNightsOnArrival
        if ((minNightsOnArrival == null || minNightsOnArrival == 0) && nights < widget.minStayNights) {
          // Show error message
          if (mounted) {
            final isDarkMode = ref.read(themeProvider);
            SnackBarHelper.showError(
              context: context,
              message: 'Minimum stay is ${widget.minStayNights} ${widget.minStayNights == 1 ? 'night' : 'nights'}. You selected $nights ${nights == 1 ? 'night' : 'nights'}.',
              isDarkMode: isDarkMode,
              duration: AnimationTokens.notification,
            );
          }
          // Reset selection
          _rangeStart = null;
          _rangeEnd = null;
          return;
        }

        _rangeStart = tempStart;
        _rangeEnd = tempEnd;

        // Notify parent
        if (widget.onRangeSelected != null) {
          widget.onRangeSelected!(_rangeStart, _rangeEnd);
        }
      }
    });
  }

  // ============================================================
  // DRAG-TO-SELECT HANDLERS
  // ============================================================

  void _handleDragStart(DateTime date, CalendarDateInfo? dateInfo) {
    final status = dateInfo?.status ?? DateStatus.available;

    if (status == DateStatus.booked || status == DateStatus.blocked) {
      return;
    }

    // Check if check-in is blocked on this date
    if (dateInfo?.blockCheckIn == true) {
      if (mounted) {
        final isDarkMode = ref.read(themeProvider);
        SnackBarHelper.showError(
          context: context,
          message: 'Check-in is not allowed on this date.',
          isDarkMode: isDarkMode,
          duration: AnimationTokens.notification,
        );
      }
      return;
    }

    setState(() {
      _isDragging = true;
      _dragStart = date;
      _rangeStart = date;
      _rangeEnd = null;
    });
  }

  void _handleDragUpdate(DateTime date) {
    if (!_isDragging || _dragStart == null) return;

    setState(() {
      DateTime tempStart = _dragStart!;
      DateTime tempEnd = date;

      if (date.isBefore(_dragStart!)) {
        tempStart = date;
        tempEnd = _dragStart!;
      }

      _rangeStart = tempStart;
      _rangeEnd = tempEnd;
    });
  }

  void _handleDragEnd() {
    if (!_isDragging) return;

    setState(() {
      _isDragging = false;
      _dragStart = null;

      // Validate minimum stay requirement
      if (_rangeStart != null && _rangeEnd != null) {
        // Get calendar data for validation
        final calendarDataAsync = ref.read(
          realtimeYearCalendarProvider(widget.unitId, _currentYear),
        );

        CalendarDateInfo? checkInDateInfo;
        CalendarDateInfo? checkOutDateInfo;
        calendarDataAsync.whenData((data) {
          checkInDateInfo = data[_rangeStart!];
          checkOutDateInfo = data[_rangeEnd!];
        });

        // Check if check-out is blocked on the end date
        if (checkOutDateInfo?.blockCheckOut == true) {
          if (mounted) {
            final isDarkMode = ref.read(themeProvider);
            SnackBarHelper.showError(
              context: context,
              message: 'Check-out is not allowed on this date.',
              isDarkMode: isDarkMode,
              duration: AnimationTokens.notification,
            );
          }
          _rangeStart = null;
          _rangeEnd = null;
          return;
        }

        final nights = _rangeEnd!.difference(_rangeStart!).inDays;

        // Check minNightsOnArrival from check-in date (if set)
        final minNightsOnArrival = checkInDateInfo?.minNightsOnArrival;
        if (minNightsOnArrival != null && minNightsOnArrival > 0 && nights < minNightsOnArrival) {
          if (mounted) {
            final isDarkMode = ref.read(themeProvider);
            SnackBarHelper.showError(
              context: context,
              message: 'Minimum stay for this arrival date is $minNightsOnArrival ${minNightsOnArrival == 1 ? 'night' : 'nights'}.',
              isDarkMode: isDarkMode,
              duration: AnimationTokens.notification,
            );
          }
          _rangeStart = null;
          _rangeEnd = null;
          return;
        }

        // Check maxNightsOnArrival from check-in date (if set)
        final maxNightsOnArrival = checkInDateInfo?.maxNightsOnArrival;
        if (maxNightsOnArrival != null && maxNightsOnArrival > 0 && nights > maxNightsOnArrival) {
          if (mounted) {
            final isDarkMode = ref.read(themeProvider);
            SnackBarHelper.showError(
              context: context,
              message: 'Maximum stay for this arrival date is $maxNightsOnArrival ${maxNightsOnArrival == 1 ? 'night' : 'nights'}.',
              isDarkMode: isDarkMode,
              duration: AnimationTokens.notification,
            );
          }
          _rangeStart = null;
          _rangeEnd = null;
          return;
        }

        // Fallback to widget's minStayNights if no date-specific minNightsOnArrival
        if ((minNightsOnArrival == null || minNightsOnArrival == 0) && nights < widget.minStayNights) {
          if (mounted) {
            final isDarkMode = ref.read(themeProvider);
            SnackBarHelper.showError(
              context: context,
              message: 'Minimum stay is ${widget.minStayNights} ${widget.minStayNights == 1 ? 'night' : 'nights'}.',
              isDarkMode: isDarkMode,
              duration: AnimationTokens.fast,
            );
          }
          _rangeStart = null;
          _rangeEnd = null;
          return;
        }

        // Notify parent
        if (widget.onRangeSelected != null) {
          widget.onRangeSelected!(_rangeStart, _rangeEnd);
        }
      }
    });
  }

  // ============================================================
  // TOOLTIP & INFO PANEL BUILDERS
  // ============================================================

  Widget _buildHoverTooltip(
    AsyncValue<Map<DateTime, CalendarDateInfo>> calendarData,
    WidgetColorScheme colors,
  ) {
    if (_hoverDate == null) return const SizedBox.shrink();

    return calendarData.when(
      data: (data) {
        final dateInfo = data[_hoverDate!];
        final status = dateInfo?.status ?? DateStatus.available;
        final price = dateInfo?.price;

        // Use actual mouse position for tooltip
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;

        // Tooltip dimensions
        final tooltipWidth = ConstraintTokens.maxCardWidth * 0.55;
        final tooltipHeight = ConstraintTokens.calendarCellMinHeight * 2;

        // Position tooltip near mouse, offset slightly to avoid cursor overlap
        double xPosition = _mousePosition.dx + SpacingTokens.s2;
        double yPosition = _mousePosition.dy - tooltipHeight - SpacingTokens.s2;

        // Keep tooltip within screen bounds
        if (xPosition + tooltipWidth > screenWidth) {
          xPosition =
              _mousePosition.dx -
              tooltipWidth -
              SpacingTokens.s2; // Show on left instead
        }
        if (yPosition < SpacingTokens.m2) {
          yPosition =
              _mousePosition.dy + SpacingTokens.m2; // Show below cursor instead
        }

        xPosition = xPosition.clamp(
          SpacingTokens.m2,
          screenWidth - tooltipWidth - SpacingTokens.m2,
        );
        yPosition = yPosition.clamp(
          SpacingTokens.m2,
          screenHeight - tooltipHeight - SpacingTokens.m2,
        );

        return Positioned(
          left: xPosition,
          top: yPosition,
          child: Material(
            elevation: 4.0,
            borderRadius: BorderTokens.circularRounded,
            child: Container(
              width: tooltipWidth,
              padding: const EdgeInsets.symmetric(
                horizontal: SpacingTokens.m,
                vertical: SpacingTokens.s2,
              ),
              decoration: BoxDecoration(
                color: colors.backgroundPrimary,
                borderRadius: BorderTokens.circularRounded,
                border: Border.all(color: colors.borderDefault),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date
                  Text(
                    DateFormat('EEEE, MMMM d, yyyy').format(_hoverDate!),
                    style: TextStyle(
                      fontWeight: TypographyTokens.bold,
                      fontSize: TypographyTokens.fontSizeM,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: SpacingTokens.s),
                  // Status
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: IconSizeTokens.xs,
                        height: IconSizeTokens.xs,
                        decoration: BoxDecoration(
                          color: status.getColor(colors),
                          shape: BoxShape.circle,
                          border: Border.all(color: colors.borderDefault),
                        ),
                      ),
                      const SizedBox(width: SpacingTokens.s),
                      Text(
                        _getStatusLabel(status),
                        style: TextStyle(
                          fontSize: TypographyTokens.fontSizeS2,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  // Price
                  if (price != null && status == DateStatus.available) ...[
                    const SizedBox(height: SpacingTokens.s),
                    Text(
                      '€${price.toStringAsFixed(0)} per night',
                      style: TextStyle(
                        fontSize: TypographyTokens.fontSizeM,
                        fontWeight: TypographyTokens.semiBold,
                        color: colors.success,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  Widget _buildTapInfoPanel(
    AsyncValue<Map<DateTime, CalendarDateInfo>> calendarData,
    WidgetColorScheme colors,
  ) {
    if (_tappedDate == null || _tapPosition == null) {
      return const SizedBox.shrink();
    }

    return calendarData.when(
      data: (data) {
        final dateInfo = data[_tappedDate!];
        final status = dateInfo?.status ?? DateStatus.available;
        final price = dateInfo?.price;

        return Positioned(
          left: SpacingTokens.m,
          right: SpacingTokens.m,
          bottom: SpacingTokens.xxl + SpacingTokens.m,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _tappedDate = null;
                _tapPosition = null;
              });
            },
            child: Material(
              elevation: 8.0,
              borderRadius: BorderTokens.circularRounded,
              child: Container(
                padding: const EdgeInsets.all(SpacingTokens.m2),
                decoration: BoxDecoration(
                  color: colors.backgroundPrimary,
                  borderRadius: BorderTokens.circularRounded,
                  border: Border.all(color: colors.borderDefault),
                  boxShadow: colors.shadowMedium,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Close button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('MMM d, yyyy').format(_tappedDate!),
                          style: TextStyle(
                            fontWeight: TypographyTokens.bold,
                            fontSize: TypographyTokens.fontSizeL,
                            color: colors.textPrimary,
                          ),
                        ),
                        SizedBox(
                          width: 48,
                          height: 48,
                          child: IconButton(
                            icon: Icon(
                              Icons.close,
                              size: IconSizeTokens.medium,
                              color: colors.textPrimary,
                            ),
                            onPressed: () {
                              setState(() {
                                _tappedDate = null;
                                _tapPosition = null;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    Divider(
                      height: SpacingTokens.m,
                      color: colors.borderDefault,
                    ),
                    // Status
                    Row(
                      children: [
                        Container(
                          width: IconSizeTokens.small,
                          height: IconSizeTokens.small,
                          decoration: BoxDecoration(
                            color: status.getColor(colors),
                            shape: BoxShape.circle,
                            border: Border.all(color: colors.borderDefault),
                          ),
                        ),
                        const SizedBox(width: SpacingTokens.s2),
                        Text(
                          _getStatusLabel(status),
                          style: TextStyle(
                            fontSize: TypographyTokens.fontSizeM2,
                            fontWeight: TypographyTokens.medium,
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    // Price
                    if (price != null && status == DateStatus.available) ...[
                      const SizedBox(height: SpacingTokens.s2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: SpacingTokens.s2,
                          vertical: SpacingTokens.s,
                        ),
                        decoration: BoxDecoration(
                          color: colors.statusAvailableBackground,
                          borderRadius: BorderTokens.circularSmall,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.euro,
                              size: IconSizeTokens.small,
                              color: colors.success,
                            ),
                            const SizedBox(width: SpacingTokens.xs),
                            Text(
                              '${price.toStringAsFixed(0)} per night',
                              style: TextStyle(
                                fontSize: TypographyTokens.fontSizeM2,
                                fontWeight: TypographyTokens.bold,
                                color: colors.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    // Tap to select hint
                    if (status == DateStatus.available) ...[
                      const SizedBox(height: SpacingTokens.s2),
                      Text(
                        'Tap to select this date',
                        style: TextStyle(
                          fontSize: TypographyTokens.fontSizeS,
                          color: colors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  String _getStatusLabel(DateStatus status) {
    switch (status) {
      case DateStatus.available:
        return 'Available';
      case DateStatus.booked:
        return 'Booked';
      case DateStatus.pending:
        return 'Pending';
      case DateStatus.blocked:
        return 'Not Available';
      case DateStatus.disabled:
        return 'Disabled';
      case DateStatus.partialCheckIn:
        return 'Check-in Day';
      case DateStatus.partialCheckOut:
        return 'Check-out Day';
      case DateStatus.partialBoth:
        return 'Turnover Day';
      case DateStatus.pastReservation:
        return 'Past Reservation';
    }
  }

  /// Build semantic label for screen readers
  String _buildSemanticLabel(
    DateTime date,
    DateStatus status,
    String? priceText,
    bool isPastDate,
  ) {
    final formatter = DateFormat('EEEE, MMMM d, yyyy');
    final dateStr = formatter.format(date);

    if (isPastDate) {
      return '$dateStr. Past date, not available.';
    }

    final statusLabel = _getStatusLabel(status);
    final priceLabel = priceText != null ? ' Price: $priceText per night.' : '';

    return '$dateStr. $statusLabel.$priceLabel';
  }
}
