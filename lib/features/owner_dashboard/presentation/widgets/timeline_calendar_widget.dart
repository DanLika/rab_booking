import 'dart:async' show Timer;
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/booking_model.dart';
import '../../../../shared/models/unit_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/enums.dart';
import '../providers/owner_calendar_provider.dart';
import '../providers/calendar_drag_drop_provider.dart';
import '../providers/calendar_filters_provider.dart';
import 'calendar/booking_inline_edit_dialog.dart';
import 'calendar/booking_status_change_dialog.dart';
import 'calendar/booking_drop_zone.dart';
import 'calendar/calendar_skeleton_loader.dart';
import 'calendar/calendar_error_state.dart';
import 'calendar/booking_action_menu.dart';
import 'calendar/shared/calendar_booking_actions.dart';
import 'timeline/timeline_constants.dart';
import 'timeline/timeline_dimensions.dart';
import 'timeline/timeline_date_headers_widget.dart';
import 'timeline/timeline_unit_column_widget.dart';
import 'timeline/timeline_grid_widget.dart';
import 'timeline/timeline_summary_bar_widget.dart';
import 'timeline/timeline_booking_block.dart';
import '../../../../l10n/app_localizations.dart';

/// BedBooking-style Timeline Calendar
/// Gantt/Timeline layout: Units vertical, Dates horizontal
/// Starts from today, horizontal scroll, pinch-to-zoom support
class TimelineCalendarWidget extends ConsumerStatefulWidget {
  final bool showSummary;
  final Function(DateTime date, UnitModel unit)? onCellLongPress;
  final DateTime? initialScrollToDate;
  final Function(UnitModel unit)? onUnitNameTap;
  final Function(DateTime startDate)? onVisibleDateRangeChanged;

  /// Initial vertical scroll offset to restore after rebuild
  /// Used to preserve scroll position when navigating with toolbar arrows
  final double? initialVerticalOffset;

  /// Callback to report current vertical scroll offset
  /// Used by parent to save position before navigation
  final Function(double offset)? onVerticalOffsetChanged;

  const TimelineCalendarWidget({
    super.key,
    this.showSummary = false,
    this.onCellLongPress,
    this.initialScrollToDate,
    this.onUnitNameTap,
    this.onVisibleDateRangeChanged,
    this.initialVerticalOffset,
    this.onVerticalOffsetChanged,
  });

  @override
  ConsumerState<TimelineCalendarWidget> createState() =>
      _TimelineCalendarWidgetState();
}

class _TimelineCalendarWidgetState
    extends ConsumerState<TimelineCalendarWidget> {
  // Scroll controllers
  late ScrollController _horizontalScrollController;
  late ScrollController _verticalScrollController;
  late ScrollController _headerScrollController;
  late ScrollController _unitNamesScrollController;
  late TransformationController _transformationController;

  // Scroll sync state
  late VoidCallback _scrollSyncListener;
  late VoidCallback _verticalScrollSyncListener;
  bool _isSyncingScroll = false;

  // Zoom state
  double _zoomScale = kTimelineDefaultZoomScale;

  // Windowing state
  int _visibleStartIndex = 0;
  int _visibleDayCount = kTimelineDefaultVisibleDayCount;

  // Dynamic date range for infinite scroll
  late DateTime _dynamicStartDate;
  late DateTime _dynamicEndDate;
  bool _isInitialScrolling = true;

  // Debounce timer for visible range updates (improves web performance)
  Timer? _visibleRangeDebounceTimer;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeDateRange();
    _setupScrollListeners();
    _scheduleInitialScroll();
  }

  void _initializeControllers() {
    _horizontalScrollController = ScrollController();
    _verticalScrollController = ScrollController();
    _headerScrollController = ScrollController();
    _unitNamesScrollController = ScrollController();
    _transformationController = TransformationController();
  }

  void _initializeDateRange() {
    final initialDate = widget.initialScrollToDate ?? DateTime.now();
    _dynamicStartDate = initialDate.subtract(
      const Duration(days: kTimelineInitialDaysOffset),
    );
    _dynamicEndDate = initialDate.add(
      const Duration(days: kTimelineInitialDaysOffset),
    );

    final initialDateIndex = initialDate.difference(_dynamicStartDate).inDays;
    _visibleStartIndex = (initialDateIndex - kTimelineInitialWindowDaysBefore)
        .clamp(0, double.infinity)
        .toInt();
    _visibleDayCount = kTimelineInitialWindowDaysTotal;
  }

  void _setupScrollListeners() {
    // Horizontal scroll sync (main -> header)
    _scrollSyncListener = () {
      if (_isSyncingScroll || !_horizontalScrollController.hasClients) return;

      _isSyncingScroll = true;
      try {
        final mainOffset = _horizontalScrollController.offset;
        if (_headerScrollController.hasClients) {
          _headerScrollController.jumpTo(mainOffset);
        }
      } finally {
        _isSyncingScroll = false;
      }
    };
    _horizontalScrollController.addListener(_scrollSyncListener);

    // Vertical scroll sync (main -> unit names)
    _verticalScrollSyncListener = () {
      if (_isSyncingScroll || !_verticalScrollController.hasClients) return;

      _isSyncingScroll = true;
      try {
        final mainOffset = _verticalScrollController.offset;
        if (_unitNamesScrollController.hasClients) {
          final maxExtent = _unitNamesScrollController.position.maxScrollExtent;
          final clampedOffset = mainOffset.clamp(0.0, maxExtent);
          if ((_unitNamesScrollController.offset - clampedOffset).abs() > 0.5) {
            _unitNamesScrollController.jumpTo(clampedOffset);
          }
        }
        // Report vertical offset changes to parent for preservation
        widget.onVerticalOffsetChanged?.call(mainOffset);
      } finally {
        _isSyncingScroll = false;
      }
    };
    _verticalScrollController.addListener(_verticalScrollSyncListener);

    // Windowing and infinite scroll listener
    _horizontalScrollController.addListener(_updateVisibleRange);

    // Zoom listener
    _transformationController.addListener(_onTransformChanged);
  }

  void _scheduleInitialScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToTodayWithRetry();
    });
  }

  void _onTransformChanged() {
    final matrix = _transformationController.value;
    final newScale = matrix.getMaxScaleOnAxis();

    if ((newScale - _zoomScale).abs() > 0.01) {
      setState(() {
        _zoomScale = newScale.clamp(
          kTimelineMinZoomScale,
          kTimelineMaxZoomScale,
        );
      });
    }
  }

  void _updateVisibleRange() {
    if (!_horizontalScrollController.hasClients || !mounted) return;

    final dimensions = context.timelineDimensionsWithZoom(_zoomScale);
    final scrollOffset = _horizontalScrollController.offset;
    final dayWidth = dimensions.dayWidth;

    final firstVisibleDay = (scrollOffset / dayWidth).floor();
    final daysInViewport = dimensions.daysInViewport;

    final newStartIndex = (firstVisibleDay - kTimelineBufferDays)
        .clamp(0, double.infinity)
        .toInt();
    final newDayCount = daysInViewport + (2 * kTimelineBufferDays);

    // Only update if range changed significantly
    if ((newStartIndex - _visibleStartIndex).abs() >
            kTimelineVisibleRangeUpdateThreshold ||
        (newDayCount - _visibleDayCount).abs() >
            kTimelineVisibleRangeUpdateThreshold) {
      setState(() {
        _visibleStartIndex = newStartIndex;
        _visibleDayCount = newDayCount;
      });
    }

    // Infinite scroll edge detection
    if (!_isInitialScrolling) {
      _handleInfiniteScroll(scrollOffset, dayWidth);
    }

    // Notify parent of visible date change (debounced on web for performance)
    if (widget.onVisibleDateRangeChanged != null && !_isInitialScrolling) {
      final visibleStartDate = _dynamicStartDate.add(
        Duration(days: firstVisibleDay),
      );

      if (kIsWeb) {
        // Debounce on web to reduce setState calls in parent during scroll
        _visibleRangeDebounceTimer?.cancel();
        _visibleRangeDebounceTimer = Timer(
          const Duration(milliseconds: 100),
          () {
            if (mounted) {
              widget.onVisibleDateRangeChanged!(visibleStartDate);
            }
          },
        );
      } else {
        // Instant feedback on native platforms
        widget.onVisibleDateRangeChanged!(visibleStartDate);
      }
    }
  }

  void _handleInfiniteScroll(double scrollOffset, double dayWidth) {
    final edgeThreshold = dayWidth * kTimelineEdgeThresholdDays;
    final maxScroll = _horizontalScrollController.position.maxScrollExtent;

    // Near start edge? Prepend days
    if (scrollOffset < edgeThreshold &&
        _dynamicStartDate.isAfter(
          DateTime.now().subtract(const Duration(days: kTimelineMaxDaysLimit)),
        )) {
      setState(() {
        _dynamicStartDate = _dynamicStartDate.subtract(
          const Duration(days: kTimelineDaysToExtend),
        );
      });
    }

    // Near end edge? Append days
    if (scrollOffset > maxScroll - edgeThreshold &&
        _dynamicEndDate.isBefore(
          DateTime.now().add(const Duration(days: kTimelineMaxDaysLimit)),
        )) {
      setState(() {
        _dynamicEndDate = _dynamicEndDate.add(
          const Duration(days: kTimelineDaysToExtend),
        );
      });
    }
  }

  void _scrollToTodayWithRetry({int retryCount = 0}) {
    if (retryCount >= kTimelineMaxScrollRetryAttempts) return;

    if (!_horizontalScrollController.hasClients) {
      Future.delayed(
        const Duration(milliseconds: kTimelineScrollRetryDelayMs),
        () {
          if (mounted) _scrollToTodayWithRetry(retryCount: retryCount + 1);
        },
      );
      return;
    }

    _scrollToToday();
  }

  void _scrollToToday() {
    if (!_horizontalScrollController.hasClients) return;

    final dimensions = context.timelineDimensionsWithZoom(_zoomScale);
    final targetDate = widget.initialScrollToDate ?? DateTime.now();
    final daysSinceStart = targetDate.difference(_dynamicStartDate).inDays;
    final scrollPosition = daysSinceStart * dimensions.dayWidth;

    final maxScroll = _horizontalScrollController.position.maxScrollExtent;
    final visibleWidth = dimensions.visibleContentWidth;

    final targetScroll =
        (scrollPosition - (visibleWidth / 2) + (dimensions.dayWidth / 2)).clamp(
          0.0,
          maxScroll,
        );

    _horizontalScrollController
        .animateTo(
          targetScroll,
          duration: AppDimensions.animationSlow,
          curve: Curves.easeInOut,
        )
        .then((_) {
          if (mounted) {
            setState(() => _isInitialScrolling = false);
            // Restore vertical scroll position if provided (preserves position on toolbar navigation)
            _restoreVerticalScrollPosition();
          }
        });
  }

  /// Restore vertical scroll position from parent-provided offset
  /// Called after initial horizontal scroll completes to preserve scroll position
  /// when user navigates with toolbar arrows (which trigger widget rebuild)
  void _restoreVerticalScrollPosition() {
    if (widget.initialVerticalOffset == null) return;
    if (!_verticalScrollController.hasClients) return;

    final targetOffset = widget.initialVerticalOffset!;
    final maxOffset = _verticalScrollController.position.maxScrollExtent;
    final clampedOffset = targetOffset.clamp(0.0, maxOffset);

    // Use jumpTo for instant restore (no animation needed)
    _verticalScrollController.jumpTo(clampedOffset);

    // Also sync unit names column
    if (_unitNamesScrollController.hasClients) {
      final unitMaxOffset = _unitNamesScrollController.position.maxScrollExtent;
      final unitClampedOffset = clampedOffset.clamp(0.0, unitMaxOffset);
      _unitNamesScrollController.jumpTo(unitClampedOffset);
    }
  }

  List<DateTime> _getDateRange() {
    final days = _dynamicEndDate.difference(_dynamicStartDate).inDays;
    return List.generate(days, (i) => _dynamicStartDate.add(Duration(days: i)));
  }

  List<DateTime> _getVisibleDateRange() {
    final fullRange = _getDateRange();
    final totalDays = fullRange.length;
    final startIndex = _visibleStartIndex.clamp(0, totalDays - 1);
    final endIndex = (startIndex + _visibleDayCount).clamp(0, totalDays);
    return fullRange.sublist(startIndex, endIndex);
  }

  @override
  void dispose() {
    _visibleRangeDebounceTimer?.cancel();
    _horizontalScrollController.removeListener(_scrollSyncListener);
    _horizontalScrollController.removeListener(_updateVisibleRange);
    _verticalScrollController.removeListener(_verticalScrollSyncListener);
    _transformationController.removeListener(_onTransformChanged);

    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    _headerScrollController.dispose();
    _unitNamesScrollController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Zoom info banner
        if (_zoomScale != kTimelineDefaultZoomScale) _buildZoomBanner(),

        // Main timeline
        Expanded(
          child: Consumer(
            builder: (context, ref, child) {
              // Use filteredUnitsProvider to respect property/unit filters
              final unitsAsync = ref.watch(filteredUnitsProvider);
              final bookingsAsync = ref.watch(timelineCalendarBookingsProvider);

              // Show skeleton immediately while ANY data is loading
              // This prevents the UI freeze/blocking feeling
              final isLoading = unitsAsync.isLoading || bookingsAsync.isLoading;
              final hasError = unitsAsync.hasError || bookingsAsync.hasError;

              if (isLoading) {
                return const CalendarSkeletonLoader();
              }

              if (hasError) {
                final error = unitsAsync.error ?? bookingsAsync.error;
                return CalendarErrorState(
                  errorMessage: error.toString(),
                  onRetry: () {
                    ref.invalidate(allOwnerUnitsProvider);
                    ref.invalidate(calendarBookingsProvider);
                  },
                );
              }

              final units = unitsAsync.value ?? [];
              final bookingsByUnit = bookingsAsync.value ?? {};

              if (units.isEmpty) return _buildEmptyUnitsState();

              return _buildTimelineView(units, bookingsByUnit);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildZoomBanner() {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceS,
        vertical: AppDimensions.spaceXXS,
      ),
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
          Text(
            l10n.ownerCalendarZoom((_zoomScale * 100).toInt()),
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
                _zoomScale = kTimelineDefaultZoomScale;
                _transformationController.value = Matrix4.identity();
              });
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spaceXS,
              ),
              minimumSize: const Size(0, 28),
            ),
            child: Text(
              l10n.ownerCalendarReset,
              style: const TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyUnitsState() {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spaceM),
        child: Text(l10n.ownerCalendarNoUnits),
      ),
    );
  }

  Widget _buildTimelineView(
    List<UnitModel> units,
    Map<String, List<BookingModel>> bookingsByUnit,
  ) {
    final dimensions = context.timelineDimensionsWithZoom(_zoomScale);
    final dates = _getVisibleDateRange();
    final offsetWidth = dimensions.getOffsetWidth(_visibleStartIndex);

    return Card(
      margin: EdgeInsets.zero,
      color: Colors.transparent,
      elevation: 0,
      child: Column(
        children: [
          // Date headers
          TimelineDateHeadersWidget(
            dates: dates,
            offsetWidth: offsetWidth,
            scrollController: _headerScrollController,
            dimensions: dimensions,
          ),

          const Divider(height: 1),

          // Units and reservations
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fixed unit names column
                TimelineUnitColumnWidget(
                  units: units,
                  bookingsByUnit: bookingsByUnit,
                  scrollController: _unitNamesScrollController,
                  dimensions: dimensions,
                  onUnitNameTap: widget.onUnitNameTap,
                  onScrollNotification: _handleUnitColumnScroll,
                  showSummarySpacing: widget.showSummary,
                ),

                // Scrollable timeline grid
                Expanded(
                  child: ScrollConfiguration(
                    // Enable mouse/trackpad drag scrolling for web
                    behavior: ScrollConfiguration.of(context).copyWith(
                      dragDevices: {
                        PointerDeviceKind.touch,
                        PointerDeviceKind.mouse,
                        PointerDeviceKind.trackpad,
                      },
                    ),
                    child: InteractiveViewer(
                      transformationController: _transformationController,
                      minScale: kTimelineMinZoomScale,
                      panEnabled: false,
                      child: SingleChildScrollView(
                        controller: _horizontalScrollController,
                        scrollDirection: Axis.horizontal,
                        // Use ClampingScrollPhysics on web for better performance
                        // BouncingScrollPhysics causes extra rendering frames on web
                        physics: kIsWeb
                            ? const ClampingScrollPhysics(
                                parent: AlwaysScrollableScrollPhysics(),
                              )
                            : const BouncingScrollPhysics(
                                parent: AlwaysScrollableScrollPhysics(),
                              ),
                        child: SingleChildScrollView(
                          controller: _verticalScrollController,
                          physics: kIsWeb
                              ? const ClampingScrollPhysics(
                                  parent: AlwaysScrollableScrollPhysics(),
                                )
                              : const BouncingScrollPhysics(
                                  parent: AlwaysScrollableScrollPhysics(),
                                ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TimelineGridWidget(
                                units: units,
                                bookingsByUnit: bookingsByUnit,
                                dates: dates,
                                offsetWidth: offsetWidth,
                                dimensions: dimensions,
                                onBookingTap: _showBookingActionMenu,
                                onBookingLongPress: _showMoveToUnitMenu,
                                dropZoneBuilder: (unit, date, index) =>
                                    _buildDropZone(
                                      unit,
                                      date,
                                      offsetWidth,
                                      index,
                                      bookingsByUnit,
                                    ),
                              ),
                              if (widget.showSummary)
                                TimelineSummaryBarWidget(
                                  bookingsByUnit: bookingsByUnit,
                                  dates: dates,
                                  offsetWidth: offsetWidth,
                                  dimensions: dimensions,
                                ),
                            ],
                          ),
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

  void _handleUnitColumnScroll(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification && !_isSyncingScroll) {
      _isSyncingScroll = true;
      try {
        if (_verticalScrollController.hasClients) {
          final maxExtent = _verticalScrollController.position.maxScrollExtent;
          final clampedOffset = _unitNamesScrollController.offset.clamp(
            0.0,
            maxExtent,
          );
          if ((_verticalScrollController.offset - clampedOffset).abs() > 0.5) {
            _verticalScrollController.jumpTo(clampedOffset);
          }
        }
      } finally {
        _isSyncingScroll = false;
      }
    }
  }

  Widget _buildDropZone(
    UnitModel unit,
    DateTime date,
    double offsetWidth,
    int index,
    Map<String, List<BookingModel>> bookingsByUnit,
  ) {
    final dimensions = context.timelineDimensionsWithZoom(_zoomScale);
    final isPast = date.isBefore(DateTime.now());
    final isToday = DateUtils.isSameDay(date, DateTime.now());

    final allBookingsAsync = ref.watch(filteredCalendarBookingsProvider);

    return allBookingsAsync.when(
      data: (allBookings) => BookingDropZone(
        date: date,
        unit: unit,
        allBookings: allBookings,
        width: dimensions.dayWidth,
        height: dimensions.unitRowHeight,
        isPast: isPast,
        isToday: isToday,
        onLongPress: widget.onCellLongPress != null
            ? () => widget.onCellLongPress!(date, unit)
            : null,
        onBookingDropped: (booking) =>
            _handleBookingDrop(booking, date, unit, allBookings),
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

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
    ref.read(dragDropProvider.notifier).stopDragging();
  }

  void _showBookingActionMenu(BookingModel booking) async {
    // Get bookings data to detect conflicts
    final bookingsAsync = ref.read(timelineCalendarBookingsProvider);
    final bookingsByUnit = bookingsAsync.value ?? {};

    // Detect conflicting bookings
    final conflictingBookings = TimelineBookingBlock.getConflictingBookings(
      booking,
      bookingsByUnit,
    );
    final hasConflict = conflictingBookings.isNotEmpty;

    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => BookingActionBottomSheet(
        booking: booking,
        hasConflict: hasConflict,
        conflictingBookings: conflictingBookings,
      ),
    );

    if (!mounted || action == null) return;

    switch (action) {
      case 'edit':
        await showDialog<bool>(
          context: context,
          builder: (context) => BookingInlineEditDialog(booking: booking),
        );
      case 'status':
        final newStatus = await showDialog<BookingStatus>(
          context: context,
          builder: (context) => BookingStatusChangeDialog(booking: booking),
        );
        if (newStatus != null && mounted) {
          await CalendarBookingActions.changeBookingStatus(
            context,
            ref,
            booking,
            newStatus,
          );
        }
      case 'delete':
        await CalendarBookingActions.deleteBooking(context, ref, booking);
    }
  }

  void _showMoveToUnitMenu(BookingModel booking) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => BookingMoveToUnitMenu(booking: booking),
    );
  }
}
