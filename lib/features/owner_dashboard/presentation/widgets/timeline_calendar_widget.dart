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
import 'timeline/timeline_booking_stacker.dart';
import '../../../../l10n/app_localizations.dart';

// ============================================================================
// CONSTANTS
// ============================================================================

/// Initial days before/after today for dynamic date range
const int _kInitialDaysOffset = 15;

/// Days to prepend/append when scrolling near edge
const int _kDaysToExtend = 30;

/// Max days in past/future (1 year)
const int _kMaxDaysLimit = 365;

/// Days from edge before triggering infinite scroll
const int _kEdgeThresholdDays = 5;

/// Threshold for visible range update (avoid excessive rebuilds)
const int _kVisibleRangeUpdateThreshold = 10;

/// Scroll retry delay in milliseconds
const int _kScrollRetryDelayMs = 100;

/// Max scroll retry attempts
const int _kMaxScrollRetryAttempts = 10;

/// Initial visible window (days before + after initial date)
const int _kInitialWindowDaysBefore = 60;
const int _kInitialWindowDaysTotal = 120;

/// Responsive breakpoints for header height
const double _kMobileBreakpoint = 600.0;
const double _kTabletBreakpoint = 900.0;

/// Header heights by screen size
const double _kMobileHeaderHeight = 60.0;
const double _kTabletHeaderHeight = 70.0;
const double _kDesktopHeaderHeight = 80.0;

/// Header proportions
const double _kMonthHeaderProportion = 0.35;
const double _kDayHeaderProportion = 0.65;

/// BedBooking-style Timeline Calendar
/// Gantt/Timeline layout: Units vertical, Dates horizontal
/// Starts from today, horizontal scroll, pinch-to-zoom support
class TimelineCalendarWidget extends ConsumerStatefulWidget {
  final bool showSummary;
  final Function(DateTime date, UnitModel unit)? onCellLongPress;
  final DateTime? initialScrollToDate; // Date to scroll to on init (null = today)
  final Function(UnitModel unit)? onUnitNameTap; // Callback when unit name is tapped (to show future bookings dialog)

  const TimelineCalendarWidget({
    super.key,
    this.showSummary = false,
    this.onCellLongPress,
    this.initialScrollToDate,
    this.onUnitNameTap,
  });

  @override
  ConsumerState<TimelineCalendarWidget> createState() => _TimelineCalendarWidgetState();
}

class _TimelineCalendarWidgetState extends ConsumerState<TimelineCalendarWidget> {
  late ScrollController _horizontalScrollController;
  late ScrollController _verticalScrollController;
  late ScrollController _headerScrollController;
  late ScrollController _summaryScrollController;
  late ScrollController _unitNamesScrollController;
  late TransformationController _transformationController;

  // Scroll sync listener reference for cleanup
  late VoidCallback _scrollSyncListener;
  late VoidCallback _verticalScrollSyncListener;

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

  // Infinite scroll - dynamic date range (initially offset days before/after)
  DateTime _dynamicStartDate = DateTime.now().subtract(const Duration(days: _kInitialDaysOffset));
  DateTime _dynamicEndDate = DateTime.now().add(const Duration(days: _kInitialDaysOffset));
  bool _isInitialScrolling = true; // Prevent infinite scroll during initial scroll to today

  // Responsive dimensions based on screen size and accessibility settings
  // Using CalendarGridCalculator for consistency
  double _getDayWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final textScaleFactor = MediaQuery.textScalerOf(context).scale(1.0);

    // Get optimal visible days for screen size
    final visibleDays = CalendarGridCalculator.getOptimalVisibleDays(screenWidth);

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

    return CalendarGridCalculator.getRowHeight(screenWidth, textScaleFactor: textScaleFactor);
  }

  double _getUnitColumnWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final textScaleFactor = MediaQuery.textScalerOf(context).scale(1.0);

    return CalendarGridCalculator.getRowHeaderWidth(screenWidth, textScaleFactor: textScaleFactor);
  }

  double _getHeaderHeight(BuildContext context) {
    // Responsive header height based on screen width
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < _kMobileBreakpoint) {
      return _kMobileHeaderHeight;
    } else if (screenWidth < _kTabletBreakpoint) {
      return _kTabletHeaderHeight;
    } else {
      return _kDesktopHeaderHeight;
    }
  }

  @override
  void initState() {
    super.initState();
    _horizontalScrollController = ScrollController();
    _verticalScrollController = ScrollController();
    _headerScrollController = ScrollController();
    _summaryScrollController = ScrollController();
    _unitNamesScrollController = ScrollController();
    _transformationController = TransformationController();

    // Initialize visible range to show initial scroll date (or today if not provided)
    // FIXED: Use initialScrollToDate to initialize windowing (Bug #5 fix)
    final initialDate = widget.initialScrollToDate ?? DateTime.now();
    final initialDateIndex = initialDate.difference(_getStartDate()).inDays;
    _visibleStartIndex = (initialDateIndex - _kInitialWindowDaysBefore).clamp(0, double.infinity).toInt();
    _visibleDayCount = _kInitialWindowDaysTotal;

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
          if (_headerScrollController.hasClients && (_headerScrollController.offset - mainOffset).abs() > 0.5) {
            _headerScrollController.jumpTo(mainOffset);
          }

          // Sync summary bar scroll
          if (_summaryScrollController.hasClients && (_summaryScrollController.offset - mainOffset).abs() > 0.5) {
            _summaryScrollController.jumpTo(mainOffset);
          }
        } finally {
          _isSyncingScroll = false;
        }
      });
    };

    // Add the single scroll sync listener
    _horizontalScrollController.addListener(_scrollSyncListener);

    // Create vertical scroll sync listener for unit names column
    _verticalScrollSyncListener = () {
      if (_isSyncingScroll) return;

      final mainOffset = _verticalScrollController.offset;

      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        _isSyncingScroll = true;

        try {
          // Sync unit names scroll with main vertical scroll
          if (_unitNamesScrollController.hasClients && (_unitNamesScrollController.offset - mainOffset).abs() > 0.5) {
            _unitNamesScrollController.jumpTo(mainOffset);
          }
        } finally {
          _isSyncingScroll = false;
        }
      });
    };

    // Add vertical scroll sync listener
    _verticalScrollController.addListener(_verticalScrollSyncListener);

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
    final newStartIndex = (firstVisibleDay - _bufferDays).clamp(0, double.infinity).toInt();
    final newDayCount = daysInViewport + (2 * _bufferDays);

    // Only update state if range changed significantly (avoid excessive rebuilds)
    if ((newStartIndex - _visibleStartIndex).abs() > _kVisibleRangeUpdateThreshold ||
        (newDayCount - _visibleDayCount).abs() > _kVisibleRangeUpdateThreshold) {
      setState(() {
        _visibleStartIndex = newStartIndex;
        _visibleDayCount = newDayCount;
      });
    }

    // Infinite scroll: Add more days when near edge
    // Skip edge detection during initial scroll to today to prevent unwanted date range expansion
    if (!_isInitialScrolling) {
      final edgeThreshold = dayWidth * _kEdgeThresholdDays;
      final maxScroll = _horizontalScrollController.position.maxScrollExtent;

      // Near start edge? Prepend days (max 1 year in past)
      if (scrollOffset < edgeThreshold &&
          _dynamicStartDate.isAfter(DateTime.now().subtract(const Duration(days: _kMaxDaysLimit)))) {
        setState(() {
          _dynamicStartDate = _dynamicStartDate.subtract(const Duration(days: _kDaysToExtend));
        });
      }

      // Near end edge? Append days (max 1 year in future)
      if (scrollOffset > maxScroll - edgeThreshold &&
          _dynamicEndDate.isBefore(DateTime.now().add(const Duration(days: _kMaxDaysLimit)))) {
        setState(() {
          _dynamicEndDate = _dynamicEndDate.add(const Duration(days: _kDaysToExtend));
        });
      }
    }
  }

  @override
  void dispose() {
    // Remove listeners before disposing controllers
    _horizontalScrollController.removeListener(_scrollSyncListener);
    _horizontalScrollController.removeListener(_updateVisibleRange);
    _verticalScrollController.removeListener(_verticalScrollSyncListener);
    _transformationController.removeListener(_onTransformChanged);

    // Dispose all controllers
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    _headerScrollController.dispose();
    _summaryScrollController.dispose();
    _unitNamesScrollController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  /// Scroll to today with retry logic
  /// FIXED: Wait for scroll controller to have clients before scrolling
  void _scrollToTodayWithRetry({int retryCount = 0}) {
    if (retryCount >= _kMaxScrollRetryAttempts) {
      return;
    }

    // Check if scroll controller is ready
    if (!_horizontalScrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: _kScrollRetryDelayMs), () {
        if (mounted) {
          _scrollToTodayWithRetry(retryCount: retryCount + 1);
        }
      });
      return;
    }

    // Controller is ready - scroll to today
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

    // Scroll to target date (centered in viewport) with smooth animation
    final maxScroll = _horizontalScrollController.position.maxScrollExtent;
    final unitColumnWidth = _getUnitColumnWidth(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final visibleWidth = screenWidth - unitColumnWidth;

    // Center target date in the visible area
    final targetScroll = (scrollPosition - (visibleWidth / 2) + (dayWidth / 2)).clamp(0.0, maxScroll);

    _horizontalScrollController
        .animateTo(targetScroll, duration: AppDimensions.animationSlow, curve: Curves.easeInOut)
        .then((_) {
          // Reset flag after scroll animation completes to allow infinite scroll for user scrolling
          if (mounted) {
            setState(() {
              _isInitialScrolling = false;
            });
          }
        });
  }

  DateTime _getStartDate() {
    // Use dynamic start date for infinite scroll
    return _dynamicStartDate;
  }

  DateTime _getEndDate() {
    // Use dynamic end date for infinite scroll
    return _dynamicEndDate;
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
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceS, vertical: AppDimensions.spaceXXS),
            color: AppColors.primary.withValues(alpha: 0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _zoomScale > 1.0 ? Icons.zoom_in : Icons.zoom_out,
                  size: AppDimensions.iconS,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppDimensions.spaceXXS),
                Builder(
                  builder: (context) {
                    final l10n = AppLocalizations.of(context);
                    return Text(
                      l10n.ownerCalendarZoom((_zoomScale * 100).toInt()),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                    );
                  },
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
                    padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceXS),
                    minimumSize: const Size(0, 28),
                  ),
                  child: Builder(
                    builder: (context) {
                      final l10n = AppLocalizations.of(context);
                      return Text(l10n.ownerCalendarReset, style: const TextStyle(fontSize: 11));
                    },
                  ),
                ),
              ],
            ),
          ),

        // Main timeline - OPTIMIZED: Consumer for units + bookings
        Expanded(
          child: Consumer(
            builder: (context, ref, child) {
              final unitsAsync = ref.watch(allOwnerUnitsProvider);
              final bookingsAsync = ref.watch(timelineCalendarBookingsProvider);

              return unitsAsync.when(
                data: (units) {
                  if (units.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppDimensions.spaceM),
                        child: Builder(
                          builder: (context) {
                            final l10n = AppLocalizations.of(context);
                            return Text(l10n.ownerCalendarNoUnits);
                          },
                        ),
                      ),
                    );
                  }

                  return bookingsAsync.when(
                    data: (bookingsByUnit) {
                      // Always show timeline view, even if no bookings exist
                      // (empty calendar grid is better UX than empty state)
                      return _buildTimelineView(units, bookingsByUnit);
                    },
                    loading: () => const CalendarSkeletonLoader(unitCount: 3, dayCount: 30),
                    error: (error, stack) => CalendarErrorState(
                      errorMessage: error.toString(),
                      onRetry: () {
                        ref.invalidate(filteredCalendarBookingsProvider);
                      },
                    ),
                  );
                },
                loading: () => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: AppDimensions.spaceM),
                      Builder(
                        builder: (context) {
                          final l10n = AppLocalizations.of(context);
                          return Text(l10n.ownerCalendarLoadingUnits);
                        },
                      ),
                    ],
                  ),
                ),
                error: (error, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimensions.spaceM),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                        const SizedBox(height: AppDimensions.spaceM),
                        Builder(
                          builder: (context) {
                            final l10n = AppLocalizations.of(context);
                            return Text(
                              l10n.ownerCalendarErrorLoadingUnits,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            );
                          },
                        ),
                        const SizedBox(height: AppDimensions.spaceS),
                        Builder(
                          builder: (context) {
                            final l10n = AppLocalizations.of(context);
                            return ElevatedButton.icon(
                              onPressed: () {
                                ref.invalidate(allOwnerUnitsProvider);
                              },
                              icon: const Icon(Icons.refresh),
                              label: Text(l10n.ownerCalendarTryAgain),
                            );
                          },
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

  Widget _buildTimelineView(List<UnitModel> units, Map<String, List<BookingModel>> bookingsByUnit) {
    // Use windowed date range for performance (only visible days + buffer)
    final dates = _getVisibleDateRange();
    final dayWidth = _getDayWidth(context);

    // Calculate offset padding to maintain correct scroll position
    final offsetWidth = _visibleStartIndex * dayWidth;

    return Card(
      margin: EdgeInsets.zero,
      color: Colors.transparent, // Transparent to show parent gradient
      elevation: 0, // Remove shadow
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
                // Fixed unit names column (with dynamic heights)
                _buildUnitNamesColumn(units, bookingsByUnit),

                // Scrollable timeline grid with zoom support
                Expanded(
                  child: InteractiveViewer(
                    transformationController: _transformationController,
                    minScale: _minZoomScale,
                    panEnabled: false, // Disable pan, use ScrollController instead
                    child: SingleChildScrollView(
                      controller: _horizontalScrollController,
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        controller: _verticalScrollController,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildTimelineGrid(units, bookingsByUnit, dates, offsetWidth),
                            // Summary bar (if enabled)
                            if (widget.showSummary) _buildSummaryBar(bookingsByUnit, dates, offsetWidth),
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
    final monthHeaderHeight = headerHeight * _kMonthHeaderProportion;
    final dayHeaderHeight = headerHeight * _kDayHeaderProportion;

    return SizedBox(
      height: headerHeight,
      child: Row(
        children: [
          // Empty space for unit names column
          Container(
            width: unitColumnWidth,
            color: Colors.transparent, // Transparent to show gradient
          ),

          // Scrollable headers
          Expanded(
            child: SingleChildScrollView(
              controller: _headerScrollController,
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(), // Disable manual scrolling, sync only
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
                            screenWidth: MediaQuery.of(context).size.width,
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

      if (currentMonth == null || date.month != currentMonth.month || date.year != currentMonth.year) {
        // New month started, add previous month header if exists
        if (currentMonth != null && dayCount > 0) {
          headers.add(
            TimelineMonthHeader(
              date: currentMonth,
              dayCount: dayCount,
              dayWidth: dayWidth,
              screenWidth: MediaQuery.of(context).size.width,
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
          screenWidth: MediaQuery.of(context).size.width,
        ),
      );
    }

    return headers;
  }

  Widget _buildUnitNamesColumn(List<UnitModel> units, Map<String, List<BookingModel>> bookingsByUnit) {
    final unitColumnWidth = _getUnitColumnWidth(context);
    final baseRowHeight = _getUnitRowHeight(context);

    return SizedBox(
      width: unitColumnWidth,
      child: SingleChildScrollView(
        controller: _unitNamesScrollController,
        physics: const NeverScrollableScrollPhysics(), // Disable manual scroll, sync only
        child: Column(
          children: units.map((unit) {
            // Calculate dynamic height for this unit based on booking stacks
            final bookings = bookingsByUnit[unit.id] ?? [];
            final maxStackCount = TimelineBookingStacker.calculateMaxStackCount(bookings);
            final dynamicHeight = baseRowHeight * maxStackCount;

            return TimelineUnitNameCell(
              unit: unit,
              unitRowHeight: dynamicHeight,
              onTap: widget.onUnitNameTap != null ? () => widget.onUnitNameTap!(unit) : null,
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTimelineGrid(
    List<UnitModel> units,
    Map<String, List<BookingModel>> bookingsByUnit,
    List<DateTime> dates,
    double offsetWidth,
  ) {
    return Container(
      color: Colors.transparent, // Transparent to show parent gradient
      child: Column(
        children: units.map((unit) {
          final bookings = bookingsByUnit[unit.id] ?? [];
          return _buildUnitRow(unit, bookings, dates, offsetWidth, bookingsByUnit);
        }).toList(),
      ),
    );
  }

  Widget _buildUnitRow(
    UnitModel unit,
    List<BookingModel> bookings,
    List<DateTime> dates,
    double offsetWidth,
    Map<String, List<BookingModel>> allBookingsByUnit,
  ) {
    final baseRowHeight = _getUnitRowHeight(context);
    final theme = Theme.of(context);

    // Calculate stack levels for overlapping bookings
    final stackLevels = TimelineBookingStacker.assignStackLevels(bookings);
    final maxStackCount = TimelineBookingStacker.calculateMaxStackCount(bookings);

    // Dynamic height: base height × number of stacks
    final unitRowHeight = baseRowHeight * maxStackCount;

    return Container(
      height: unitRowHeight,
      decoration: BoxDecoration(
        color: Colors.transparent, // Transparent to show parent gradient
        border: Border(bottom: BorderSide(color: theme.dividerColor.withAlpha((0.6 * 255).toInt()))),
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
          ..._buildReservationBlocks(bookings, dates, offsetWidth, allBookingsByUnit, stackLevels, baseRowHeight),
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
              onLongPress: widget.onCellLongPress != null ? () => widget.onCellLongPress!(date, unit) : null,
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
        .executeDrop(dropDate: dropDate, targetUnit: targetUnit, allBookings: allBookings, context: context);

    // Clear drag state
    ref.read(dragDropProvider.notifier).stopDragging();
  }

  Widget _buildDayCell(DateTime date) {
    final dayWidth = _getDayWidth(context);
    final theme = Theme.of(context);
    final isToday = _isToday(date);
    final isWeekend = date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
    final isFirstDayOfMonth = date.day == 1;

    return Container(
      width: dayWidth,
      decoration: BoxDecoration(
        color: isToday
            ? theme.colorScheme.primary.withAlpha((0.05 * 255).toInt())
            : isWeekend
            ? theme.dividerColor.withAlpha((0.05 * 255).toInt())
            : Colors.transparent, // Transparent to show parent gradient
        border: Border(
          left: BorderSide(
            color: isFirstDayOfMonth ? theme.colorScheme.primary : theme.dividerColor.withAlpha((0.5 * 255).toInt()),
            width: isFirstDayOfMonth ? 2 : 1,
          ),
          right: BorderSide(color: theme.dividerColor.withAlpha((0.6 * 255).toInt()), width: 0.5),
          top: BorderSide(color: theme.dividerColor.withAlpha((0.6 * 255).toInt()), width: 0.5),
          bottom: BorderSide(color: theme.dividerColor.withAlpha((0.6 * 255).toInt()), width: 0.5),
        ),
      ),
    );
  }

  List<Widget> _buildReservationBlocks(
    List<BookingModel> bookings,
    List<DateTime> dates,
    double offsetWidth,
    Map<String, List<BookingModel>> allBookingsByUnit,
    Map<String, int> stackLevels,
    double baseRowHeight,
  ) {
    final dayWidth = _getDayWidth(context);
    final List<Widget> blocks = [];

    // NOTE: Cancelled bookings are filtered out at provider level
    // Only active bookings (confirmed, pending, completed) are rendered
    for (final booking in bookings) {
      // Calculate position and width
      final checkIn = booking.checkIn;
      final nights = TimelineBookingBlock.calculateNights(booking.checkIn, booking.checkOut);

      // Find index of check-in date in visible range
      final startIndex = dates.indexWhere((d) => _isSameDay(d, checkIn));
      if (startIndex == -1) {
        continue; // Booking not in visible range
      }

      // Calculate left position (including offset for windowing)
      final left = offsetWidth + (startIndex * dayWidth);

      // Calculate width (number of nights * day width + 10px extension)
      // IMPORTANT: Do NOT include check-out day in visualization
      // Check-out happens at 3pm, so that day is available for next booking
      // If check-in is Nov 10 and check-out is Nov 12 (2 nights), we show only 2 cells (10, 11)
      // Added +10px to extend booking block slightly for better visibility
      final width = (nights * dayWidth) + 10;

      // Get stack level for vertical positioning
      final stackLevel = stackLevels[booking.id] ?? 0;
      final topPosition = 8 + (stackLevel * baseRowHeight); // Stack vertically

      // Create reservation block
      blocks.add(
        Positioned(
          left: left,
          top: topPosition,
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
    // Dialog handles its own refresh via provider invalidation
    await showDialog<bool>(
      context: context,
      builder: (context) => BookingInlineEditDialog(booking: booking),
    );
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
    final l10n = AppLocalizations.of(context);
    final newStatus = await showDialog<BookingStatus>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.ownerCalendarChangeStatus),
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
      await CalendarBookingActions.changeBookingStatus(context, ref, booking, newStatus);
    }
  }

  Widget _buildSummaryBar(Map<String, List<BookingModel>> bookingsByUnit, List<DateTime> dates, double offsetWidth) {
    final theme = Theme.of(context);

    // FIXED: Removed nested SingleChildScrollView - summary now scrolls with main timeline
    // No need for separate scroll controller and sync logic
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha((0.3 * 255).toInt()),
        border: Border(top: BorderSide(color: theme.dividerColor.withAlpha((0.5 * 255).toInt()), width: 2)),
      ),
      child: Row(
        children: [
          // Offset padding to maintain scroll position
          if (offsetWidth > 0) SizedBox(width: offsetWidth),
          ...dates.map(
            (date) => TimelineSummaryCell(date: date, bookingsByUnit: bookingsByUnit, dayWidth: _getDayWidth(context)),
          ),
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
