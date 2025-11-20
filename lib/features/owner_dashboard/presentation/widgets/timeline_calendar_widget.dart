import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/booking_model.dart';
import '../../../../shared/models/unit_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/enums.dart';
import '../providers/owner_calendar_provider.dart';
import '../providers/calendar_drag_drop_provider.dart';
import '../providers/calendar_filters_provider.dart';
import '../../utils/calendar_grid_calculator.dart';
import 'calendar/booking_inline_edit_dialog.dart';
import 'calendar/booking_drop_zone.dart';
import 'calendar/calendar_skeleton_loader.dart';
import 'calendar/calendar_error_state.dart';
import 'calendar/booking_action_menu.dart';
import 'calendar/shared/calendar_booking_actions.dart';
import 'timeline/timeline_booking_block.dart';
import 'timeline/timeline_date_header.dart';
import 'timeline/timeline_unit_name_cell.dart';
import 'timeline/timeline_summary_cell.dart';

/// BedBooking-style Timeline Calendar
/// Gantt/Timeline layout: Units vertical, Dates horizontal
/// Starts from today, horizontal scroll, pinch-to-zoom support
class TimelineCalendarWidget extends ConsumerStatefulWidget {
  final bool showSummary;
  final Function(DateTime date, UnitModel unit)? onCellLongPress;
  final DateTime?
  initialScrollToDate; // Date to scroll to on init (null = today)

  const TimelineCalendarWidget({
    super.key,
    this.showSummary = false,
    this.onCellLongPress,
    this.initialScrollToDate,
  });

  @override
  ConsumerState<TimelineCalendarWidget> createState() =>
      _TimelineCalendarWidgetState();
}

class _TimelineCalendarWidgetState
    extends ConsumerState<TimelineCalendarWidget> {
  late ScrollController _horizontalScrollController;
  late ScrollController _verticalScrollController;
  late ScrollController _headerScrollController;
  late ScrollController _summaryScrollController;
  late TransformationController _transformationController;

  // Scroll sync listener reference for cleanup
  late VoidCallback _scrollSyncListener;

  // Scroll sync state to prevent circular updates
  bool _isSyncingScroll = false;

  // Zoom scale (1.0 = normal, 0.5 = zoomed out, 2.0 = zoomed in)
  double _zoomScale = 1.0;
  static const double _minZoomScale = 0.5;
  static const double _maxZoomScale = 2.5;

  // Windowing for performance (render only visible days + buffer)
  int _visibleStartIndex = 0;
  int _visibleDayCount = 90; // Render 90 days at a time
  static const int _bufferDays = 30; // Extra days before/after visible area

  // Responsive dimensions based on screen size and accessibility settings
  // Using CalendarGridCalculator for consistency
  double _getDayWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final textScaleFactor = MediaQuery.textScalerOf(context).scale(1.0);

    // Get optimal visible days for screen size
    final visibleDays = CalendarGridCalculator.getOptimalVisibleDays(
      screenWidth,
    );

    // Get base width from CalendarGridCalculator
    final baseWidth = CalendarGridCalculator.getDayCellWidth(
      screenWidth,
      visibleDays,
      textScaleFactor: textScaleFactor,
    );

    // Apply zoom scale (pinch-to-zoom)
    return baseWidth * _zoomScale;
  }

  double _getUnitRowHeight(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final textScaleFactor = MediaQuery.textScalerOf(context).scale(1.0);

    return CalendarGridCalculator.getRowHeight(
      screenWidth,
      textScaleFactor: textScaleFactor,
    );
  }

  double _getUnitColumnWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final textScaleFactor = MediaQuery.textScalerOf(context).scale(1.0);

    return CalendarGridCalculator.getRowHeaderWidth(
      screenWidth,
      textScaleFactor: textScaleFactor,
    );
  }

  double _getHeaderHeight(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return CalendarGridCalculator.getHeaderHeight(screenWidth);
  }

  @override
  void initState() {
    super.initState();
    _horizontalScrollController = ScrollController();
    _verticalScrollController = ScrollController();
    _headerScrollController = ScrollController();
    _summaryScrollController = ScrollController();
    _transformationController = TransformationController();

    // Initialize visible range to show initial scroll date (or today if not provided)
    // FIXED: Use initialScrollToDate to initialize windowing (Bug #5 fix)
    final initialDate = widget.initialScrollToDate ?? DateTime.now();
    final initialDateIndex = initialDate.difference(_getStartDate()).inDays;
    _visibleStartIndex = (initialDateIndex - 60)
        .clamp(0, double.infinity)
        .toInt(); // Start 60 days before initial date
    _visibleDayCount = 120; // Show 120 days initially (60 before + 60 after)

    // Create optimized scroll sync listener
    // Uses post-frame callback and sync guard to prevent circular updates and lag
    _scrollSyncListener = () {
      // Skip if already syncing to prevent circular updates
      if (_isSyncingScroll) return;

      // Get main scroll offset
      final mainOffset = _horizontalScrollController.offset;

      // Schedule sync for end of frame to avoid lag
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        _isSyncingScroll = true;

        try {
          // Sync header scroll with higher precision (0.5px threshold)
          if (_headerScrollController.hasClients &&
              (_headerScrollController.offset - mainOffset).abs() > 0.5) {
            _headerScrollController.jumpTo(mainOffset);
          }

          // Sync summary bar scroll
          if (_summaryScrollController.hasClients &&
              (_summaryScrollController.offset - mainOffset).abs() > 0.5) {
            _summaryScrollController.jumpTo(mainOffset);
          }
        } finally {
          _isSyncingScroll = false;
        }
      });
    };

    // Add the single scroll sync listener
    _horizontalScrollController.addListener(_scrollSyncListener);

    // Add windowing listener to update visible range based on scroll position
    _horizontalScrollController.addListener(_updateVisibleRange);

    // Listen to zoom changes from InteractiveViewer
    _transformationController.addListener(_onTransformChanged);

    // Scroll to today on init with retry logic
    // FIXED: Wait for scroll controller to be ready before scrolling
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToTodayWithRetry();
    });
  }

  void _onTransformChanged() {
    final matrix = _transformationController.value;
    final newScale = matrix.getMaxScaleOnAxis();

    if ((newScale - _zoomScale).abs() > 0.01) {
      setState(() {
        _zoomScale = newScale.clamp(_minZoomScale, _maxZoomScale);
      });
    }
  }

  /// Update visible date range based on scroll position (windowing for performance)
  void _updateVisibleRange() {
    if (!_horizontalScrollController.hasClients || !mounted) return;

    final scrollOffset = _horizontalScrollController.offset;
    final dayWidth = _getDayWidth(context);

    // Calculate which day index is at the start of the viewport
    final firstVisibleDay = (scrollOffset / dayWidth).floor();

    // Calculate how many days fit in the viewport
    final screenWidth = MediaQuery.of(context).size.width;
    final unitColumnWidth = _getUnitColumnWidth(context);
    final visibleWidth = screenWidth - unitColumnWidth;
    final daysInViewport = (visibleWidth / dayWidth).ceil();

    // Add buffer before and after visible area for smooth scrolling
    final newStartIndex = (firstVisibleDay - _bufferDays)
        .clamp(0, double.infinity)
        .toInt();
    final newDayCount = daysInViewport + (2 * _bufferDays);

    // Only update state if range changed significantly (avoid excessive rebuilds)
    if ((newStartIndex - _visibleStartIndex).abs() > 10 ||
        (newDayCount - _visibleDayCount).abs() > 10) {
      setState(() {
        _visibleStartIndex = newStartIndex;
        _visibleDayCount = newDayCount;
      });
    }
  }

  @override
  void dispose() {
    // Remove listeners before disposing controllers
    _horizontalScrollController.removeListener(_scrollSyncListener);
    _horizontalScrollController.removeListener(_updateVisibleRange);
    _transformationController.removeListener(_onTransformChanged);

    // Dispose all controllers
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    _headerScrollController.dispose();
    _summaryScrollController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  /// Scroll to today with retry logic
  /// FIXED: Wait for scroll controller to have clients before scrolling
  void _scrollToTodayWithRetry({int retryCount = 0}) {
    // Max 10 retries (100ms each = 1 second total)
    if (retryCount >= 10) {
      print('[TIMELINE] Failed to scroll to today after 10 retries');
      return;
    }

    // Check if scroll controller is ready
    if (!_horizontalScrollController.hasClients) {
      // Retry after 100ms
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _scrollToTodayWithRetry(retryCount: retryCount + 1);
        }
      });
      return;
    }

    // Controller is ready - scroll to today
    print('[TIMELINE] Scrolling to today (retry count: $retryCount)');
    _scrollToToday();
  }

  void _scrollToToday() {
    // Check if scroll controller is attached to a scroll view
    if (!_horizontalScrollController.hasClients) {
      return;
    }

    // Calculate position of target date (use initialScrollToDate if provided, otherwise today)
    final targetDate = widget.initialScrollToDate ?? DateTime.now();
    final startDate = _getStartDate();
    final daysSinceStart = targetDate.difference(startDate).inDays;
    final dayWidth = _getDayWidth(context);
    final scrollPosition = daysSinceStart * dayWidth;

    print(
      '[TIMELINE] _scrollToToday: startDate=$startDate, targetDate=$targetDate, daysSinceStart=$daysSinceStart',
    );

    // Scroll to target date (centered in viewport) with smooth animation
    final maxScroll = _horizontalScrollController.position.maxScrollExtent;
    final unitColumnWidth = _getUnitColumnWidth(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final visibleWidth = screenWidth - unitColumnWidth;

    // Center target date in the visible area
    final targetScroll = (scrollPosition - (visibleWidth / 2) + (dayWidth / 2))
        .clamp(0.0, maxScroll);

    print('[TIMELINE] Scrolling to position: $targetScroll (max: $maxScroll)');

    _horizontalScrollController.animateTo(
      targetScroll,
      duration: AppDimensions.animationSlow,
      curve: Curves.easeInOut,
    );
  }

  DateTime _getStartDate() {
    // Start from 3 months before today
    return DateTime.now().subtract(const Duration(days: 90));
  }

  DateTime _getEndDate() {
    // End 12 months after today
    return DateTime.now().add(const Duration(days: 365));
  }

  List<DateTime> _getDateRange() {
    final start = _getStartDate();
    final end = _getEndDate();
    final days = end.difference(start).inDays;

    return List.generate(days, (index) {
      return start.add(Duration(days: index));
    });
  }

  /// Get only visible date range for performance (windowing)
  /// Returns subset of full date range based on scroll position
  List<DateTime> _getVisibleDateRange() {
    final fullRange = _getDateRange();
    final totalDays = fullRange.length;

    // Ensure we don't go out of bounds
    final startIndex = _visibleStartIndex.clamp(0, totalDays - 1);
    final endIndex = (startIndex + _visibleDayCount).clamp(0, totalDays);

    // Return only the visible subset
    return fullRange.sublist(startIndex, endIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Zoom info banner (showing current zoom level)
        if (_zoomScale != 1.0)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spaceS,
              vertical: AppDimensions.spaceXXS,
            ),
            color: AppColors.primary.withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _zoomScale > 1.0 ? Icons.zoom_in : Icons.zoom_out,
                  size: AppDimensions.iconS,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppDimensions.spaceXXS),
                Text(
                  'Zoom: ${(_zoomScale * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppDimensions.spaceXS),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _zoomScale = 1.0;
                      _transformationController.value = Matrix4.identity();
                    });
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.spaceXS,
                    ),
                    minimumSize: const Size(0, 28),
                  ),
                  child: const Text('Reset', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
          ),

        // Main timeline - OPTIMIZED: Consumer for units + bookings
        Expanded(
          child: Consumer(
            builder: (context, ref, child) {
              final unitsAsync = ref.watch(allOwnerUnitsProvider);
              final bookingsAsync = ref.watch(filteredCalendarBookingsProvider);

              return unitsAsync.when(
                data: (units) {
                  if (units.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppDimensions.spaceM),
                        child: Text('Nema jedinica za prikaz'),
                      ),
                    );
                  }

                  return bookingsAsync.when(
                    data: (bookingsByUnit) {
                      // Always show timeline view, even if no bookings exist
                      // (empty calendar grid is better UX than empty state)
                      final totalBookings = bookingsByUnit.values.fold<int>(
                        0,
                        (sum, list) => sum + list.length,
                      );
                      print(
                        '[TIMELINE] Building timeline with ${units.length} units and ${bookingsByUnit.length} booking groups',
                      );
                      print(
                        '[TIMELINE] Total bookings across all groups: $totalBookings',
                      );

                      // Debug each unit's bookings
                      bookingsByUnit.forEach((unitId, bookings) {
                        print(
                          '[TIMELINE] Unit $unitId has ${bookings.length} bookings',
                        );
                        for (final booking in bookings) {
                          print(
                            '[TIMELINE]   - Booking ${booking.id}: checkIn=${booking.checkIn}, checkOut=${booking.checkOut}',
                          );
                        }
                      });

                      return _buildTimelineView(units, bookingsByUnit);
                    },
                    loading: () => const CalendarSkeletonLoader(
                      unitCount: 3,
                      dayCount: 30,
                    ),
                    error: (error, stack) => CalendarErrorState(
                      errorMessage: error.toString(),
                      onRetry: () {
                        ref.invalidate(filteredCalendarBookingsProvider);
                      },
                    ),
                  );
                },
                loading: () => const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: AppDimensions.spaceM),
                      Text('Učitavanje jedinica...'),
                    ],
                  ),
                ),
                error: (error, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimensions.spaceM),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: AppColors.error,
                        ),
                        const SizedBox(height: AppDimensions.spaceM),
                        const Text(
                          'Greška pri učitavanju jedinica',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.spaceS),
                        ElevatedButton.icon(
                          onPressed: () {
                            ref.invalidate(allOwnerUnitsProvider);
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Pokušaj ponovno'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineView(
    List<UnitModel> units,
    Map<String, List<BookingModel>> bookingsByUnit,
  ) {
    // Use windowed date range for performance (only visible days + buffer)
    final dates = _getVisibleDateRange();
    final dayWidth = _getDayWidth(context);

    // Calculate offset padding to maintain correct scroll position
    final offsetWidth = _visibleStartIndex * dayWidth;

    return Card(
      child: Column(
        children: [
          // Date headers
          _buildDateHeaders(dates, offsetWidth),

          const Divider(height: 1),

          // Units and reservations with InteractiveViewer for pinch-to-zoom
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fixed unit names column
                _buildUnitNamesColumn(units),

                // Scrollable timeline grid with zoom support
                Expanded(
                  child: InteractiveViewer(
                    transformationController: _transformationController,
                    minScale: _minZoomScale,
                    panEnabled:
                        false, // Disable pan, use ScrollController instead
                    child: SingleChildScrollView(
                      controller: _horizontalScrollController,
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        controller: _verticalScrollController,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildTimelineGrid(
                              units,
                              bookingsByUnit,
                              dates,
                              offsetWidth,
                            ),
                            // Summary bar (if enabled)
                            if (widget.showSummary)
                              _buildSummaryBar(
                                bookingsByUnit,
                                dates,
                                offsetWidth,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateHeaders(List<DateTime> dates, double offsetWidth) {
    final unitColumnWidth = _getUnitColumnWidth(context);
    final headerHeight = _getHeaderHeight(context);
    final monthHeaderHeight = headerHeight * 0.35; // ~35% for month header
    final dayHeaderHeight = headerHeight * 0.65; // ~65% for day header

    return SizedBox(
      height: headerHeight,
      child: Row(
        children: [
          // Empty space for unit names column
          Container(width: unitColumnWidth, color: Theme.of(context).cardColor),

          // Scrollable headers
          Expanded(
            child: SingleChildScrollView(
              controller: _headerScrollController,
              scrollDirection: Axis.horizontal,
              physics:
                  const NeverScrollableScrollPhysics(), // Disable manual scrolling, sync only
              child: Column(
                children: [
                  // Nad-zaglavlje: Month headers
                  SizedBox(
                    height: monthHeaderHeight,
                    child: Row(
                      children: [
                        // Offset padding to maintain scroll position
                        if (offsetWidth > 0) SizedBox(width: offsetWidth),
                        ..._buildMonthHeaders(dates),
                      ],
                    ),
                  ),

                  // Pod-zaglavlje: Day headers
                  SizedBox(
                    height: dayHeaderHeight,
                    child: Row(
                      children: [
                        // Offset padding to maintain scroll position
                        if (offsetWidth > 0) SizedBox(width: offsetWidth),
                        ...dates.map(
                          (date) => TimelineDayHeader(
                            date: date,
                            dayWidth: _getDayWidth(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMonthHeaders(List<DateTime> dates) {
    final List<Widget> headers = [];
    final dayWidth = _getDayWidth(context);
    DateTime? currentMonth;
    int dayCount = 0;

    for (int i = 0; i < dates.length; i++) {
      final date = dates[i];

      if (currentMonth == null ||
          date.month != currentMonth.month ||
          date.year != currentMonth.year) {
        // New month started, add previous month header if exists
        if (currentMonth != null && dayCount > 0) {
          headers.add(
            TimelineMonthHeader(
              date: currentMonth,
              dayCount: dayCount,
              dayWidth: dayWidth,
            ),
          );
        }

        // Start new month
        currentMonth = date;
        dayCount = 1;
      } else {
        dayCount++;
      }
    }

    // Add last month header
    if (currentMonth != null && dayCount > 0) {
      headers.add(
        TimelineMonthHeader(
          date: currentMonth,
          dayCount: dayCount,
          dayWidth: dayWidth,
        ),
      );
    }

    return headers;
  }

  Widget _buildUnitNamesColumn(List<UnitModel> units) {
    final unitColumnWidth = _getUnitColumnWidth(context);
    final unitRowHeight = _getUnitRowHeight(context);
    final theme = Theme.of(context);

    return Container(
      width: unitColumnWidth,
      color: theme.cardColor.withAlpha((0.95 * 255).toInt()),
      child: Column(
        children: units
            .map(
              (unit) => TimelineUnitNameCell(
                unit: unit,
                unitRowHeight: unitRowHeight,
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildTimelineGrid(
    List<UnitModel> units,
    Map<String, List<BookingModel>> bookingsByUnit,
    List<DateTime> dates,
    double offsetWidth,
  ) {
    return Column(
      children: units.map((unit) {
        final bookings = bookingsByUnit[unit.id] ?? [];
        return _buildUnitRow(
          unit,
          bookings,
          dates,
          offsetWidth,
          bookingsByUnit,
        );
      }).toList(),
    );
  }

  Widget _buildUnitRow(
    UnitModel unit,
    List<BookingModel> bookings,
    List<DateTime> dates,
    double offsetWidth,
    Map<String, List<BookingModel>> allBookingsByUnit,
  ) {
    final unitRowHeight = _getUnitRowHeight(context);
    final theme = Theme.of(context);

    return Container(
      height: unitRowHeight,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withAlpha((0.6 * 255).toInt()),
          ),
        ),
      ),
      child: Stack(
        children: [
          // Day cells (background)
          Row(
            children: [
              // Offset padding to maintain scroll position
              if (offsetWidth > 0) SizedBox(width: offsetWidth),
              ...dates.map(_buildDayCell),
            ],
          ),

          // ENHANCED: Drop zones layer (transparent DragTarget overlay)
          ..._buildDropZones(unit, dates, offsetWidth, bookings),

          // Reservation blocks (foreground)
          ..._buildReservationBlocks(
            bookings,
            dates,
            offsetWidth,
            allBookingsByUnit,
          ),
        ],
      ),
    );
  }

  /// Build drop zones (transparent DragTarget widgets over each day cell)
  List<Widget> _buildDropZones(
    UnitModel unit,
    List<DateTime> dates,
    double offsetWidth,
    List<BookingModel> unitBookings,
  ) {
    final dayWidth = _getDayWidth(context);
    final unitRowHeight = _getUnitRowHeight(context);

    // Get all bookings for validation
    final allBookingsAsync = ref.watch(filteredCalendarBookingsProvider);

    return dates.asMap().entries.map((entry) {
      final index = entry.key;
      final date = entry.value;
      final left = offsetWidth + (index * dayWidth);

      final isPast = date.isBefore(DateTime.now());
      final isToday = _isToday(date);

      return Positioned(
        left: left,
        top: 0,
        width: dayWidth,
        height: unitRowHeight,
        child: allBookingsAsync.when(
          data: (allBookings) {
            return BookingDropZone(
              date: date,
              unit: unit,
              allBookings: allBookings,
              width: dayWidth,
              height: unitRowHeight,
              isPast: isPast,
              isToday: isToday,
              onLongPress: widget.onCellLongPress != null
                  ? () => widget.onCellLongPress!(date, unit)
                  : null,
              onBookingDropped: (booking) {
                _handleBookingDrop(booking, date, unit, allBookings);
              },
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
        ),
      );
    }).toList();
  }

  /// Handle booking drop
  Future<void> _handleBookingDrop(
    BookingModel booking,
    DateTime dropDate,
    UnitModel targetUnit,
    Map<String, List<BookingModel>> allBookings,
  ) async {
    await ref
        .read(dragDropProvider.notifier)
        .executeDrop(
          dropDate: dropDate,
          targetUnit: targetUnit,
          allBookings: allBookings,
          context: context,
        );

    // Clear drag state
    ref.read(dragDropProvider.notifier).stopDragging();
  }

  Widget _buildDayCell(DateTime date) {
    final dayWidth = _getDayWidth(context);
    final theme = Theme.of(context);
    final isToday = _isToday(date);
    final isWeekend =
        date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
    final isFirstDayOfMonth = date.day == 1;

    return Container(
      width: dayWidth,
      decoration: BoxDecoration(
        color: isToday
            ? theme.colorScheme.primary.withAlpha((0.05 * 255).toInt())
            : isWeekend
            ? theme.dividerColor.withAlpha((0.05 * 255).toInt())
            : theme.scaffoldBackgroundColor,
        border: Border(
          left: BorderSide(
            color: isFirstDayOfMonth
                ? theme.colorScheme.primary
                : theme.dividerColor.withAlpha((0.5 * 255).toInt()),
            width: isFirstDayOfMonth ? 2 : 1,
          ),
          right: BorderSide(
            color: theme.dividerColor.withAlpha((0.6 * 255).toInt()),
            width: 0.5,
          ),
          top: BorderSide(
            color: theme.dividerColor.withAlpha((0.6 * 255).toInt()),
            width: 0.5,
          ),
          bottom: BorderSide(
            color: theme.dividerColor.withAlpha((0.6 * 255).toInt()),
            width: 0.5,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildReservationBlocks(
    List<BookingModel> bookings,
    List<DateTime> dates,
    double offsetWidth,
    Map<String, List<BookingModel>> allBookingsByUnit,
  ) {
    final dayWidth = _getDayWidth(context);
    final List<Widget> blocks = [];

    print(
      '[TIMELINE RENDER] _buildReservationBlocks called with ${bookings.length} bookings, visible dates: ${dates.first} to ${dates.last}',
    );

    for (final booking in bookings) {
      // Calculate position and width
      final checkIn = booking.checkIn;
      final nights = TimelineBookingBlock.calculateNights(
        booking.checkIn,
        booking.checkOut,
      );

      // Find index of check-in date in visible range
      final startIndex = dates.indexWhere((d) => _isSameDay(d, checkIn));
      if (startIndex == -1) {
        print(
          '[TIMELINE RENDER] Skipping booking ${booking.id}: checkIn=$checkIn not in visible range',
        );
        continue; // Booking not in visible range
      }

      print(
        '[TIMELINE RENDER] Rendering booking ${booking.id}: checkIn=$checkIn, startIndex=$startIndex, nights=$nights',
      );

      // Calculate left position (including offset for windowing)
      final left = offsetWidth + (startIndex * dayWidth);

      // Calculate width (number of nights * day width)
      // FIXED: Add 1 day to include check-out day in visualization
      // If check-in is Nov 10 and check-out is Nov 12 (2 nights), we need to show 3 cells (10, 11, 12)
      final width = (nights + 1) * dayWidth;

      // Create reservation block
      blocks.add(
        Positioned(
          left: left,
          top: 8,
          child: TimelineBookingBlock(
            booking: booking,
            width: width,
            unitRowHeight: _getUnitRowHeight(context),
            allBookingsByUnit: allBookingsByUnit,
            onTap: () => _showBookingActionMenu(booking),
            onLongPress: () => _showMoveToUnitMenu(booking),
          ),
        ),
      );
    }

    return blocks;
  }

  void _showReservationDetails(BookingModel booking) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => BookingInlineEditDialog(booking: booking),
    );

    // If edited successfully, result will be true
    if (result == true && mounted) {
      // Calendar already refreshed by dialog
    }
  }

  /// Show booking action menu (short tap)
  /// Displays bottom sheet with Edit, Change Status, Delete options
  void _showBookingActionMenu(BookingModel booking) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => BookingActionBottomSheet(booking: booking),
    );

    if (!mounted || action == null) return;

    switch (action) {
      case 'edit':
        _showReservationDetails(booking);
        break;
      case 'status':
        await _showStatusChangeDialog(booking);
        break;
      case 'delete':
        await _deleteBooking(booking);
        break;
    }
  }

  /// Show move to unit menu (long press)
  /// Displays bottom sheet with list of other units
  void _showMoveToUnitMenu(BookingModel booking) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => BookingMoveToUnitMenu(booking: booking),
    );

    // Calendar will auto-refresh via provider invalidation in the menu
  }

  /// Delete booking - Using shared action
  Future<void> _deleteBooking(BookingModel booking) async {
    await CalendarBookingActions.deleteBooking(context, ref, booking);
  }

  /// Show status change dialog
  Future<void> _showStatusChangeDialog(BookingModel booking) async {
    final newStatus = await showDialog<BookingStatus>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Promijeni status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: BookingStatus.values.map((status) {
            return ListTile(
              title: Text(status.displayName),
              leading: Icon(Icons.circle, color: status.color),
              onTap: () => Navigator.of(context).pop(status),
            );
          }).toList(),
        ),
      ),
    );

    if (newStatus != null && mounted) {
      await CalendarBookingActions.changeBookingStatus(
        context,
        ref,
        booking,
        newStatus,
      );
    }
  }

  Widget _buildSummaryBar(
    Map<String, List<BookingModel>> bookingsByUnit,
    List<DateTime> dates,
    double offsetWidth,
  ) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      controller: _summaryScrollController,
      scrollDirection: Axis.horizontal,
      physics:
          const NeverScrollableScrollPhysics(), // Sync only, no manual scroll
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withAlpha(
            (0.3 * 255).toInt(),
          ),
          border: Border(
            top: BorderSide(
              color: theme.dividerColor.withAlpha((0.5 * 255).toInt()),
              width: 2,
            ),
          ),
        ),
        child: Row(
          children: [
            // Offset padding to maintain scroll position
            if (offsetWidth > 0) SizedBox(width: offsetWidth),
            ...dates.map(
              (date) => TimelineSummaryCell(
                date: date,
                bookingsByUnit: bookingsByUnit,
                dayWidth: _getDayWidth(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

}
