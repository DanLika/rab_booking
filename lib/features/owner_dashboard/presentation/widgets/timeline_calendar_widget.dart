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
import '../../utils/booking_overlap_detector.dart';
import '../../../../l10n/app_localizations.dart';

/// Safely convert error to string, handling null and edge cases
/// Prevents "Null check operator used on a null value" errors
String _safeErrorToString(dynamic error) {
  if (error == null) {
    return 'Unknown error';
  }
  try {
    return error.toString();
  } catch (e) {
    // If toString() itself throws, return a safe fallback
    return 'Error: Unable to display error details';
  }
}

/// BedBooking-style Timeline Calendar
/// Gantt/Timeline layout: Units vertical, Dates horizontal
/// Starts from today, horizontal scroll, pinch-to-zoom support
class TimelineCalendarWidget extends ConsumerStatefulWidget {
  final bool showSummary;
  final bool showEmptyUnits;
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
    this.showEmptyUnits = true,
    this.onCellLongPress,
    this.initialScrollToDate,
    this.onUnitNameTap,
    this.onVisibleDateRangeChanged,
    this.initialVerticalOffset,
    this.onVerticalOffsetChanged,
  });

  @override
  ConsumerState<TimelineCalendarWidget> createState() => _TimelineCalendarWidgetState();
}

class _TimelineCalendarWidgetState extends ConsumerState<TimelineCalendarWidget> {
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

  // Throttle timer for vertical scroll sync (improves Android web performance)
  Timer? _verticalScrollThrottleTimer;
  double _lastVerticalScrollOffset = 0.0;

  // Throttle timer for horizontal scroll sync (improves Android web performance)
  Timer? _horizontalScrollThrottleTimer;
  double _lastHorizontalScrollOffset = 0.0;

  // Flag to track programmatic scrolls (prevents infinite loop with onVisibleDateRangeChanged)
  // Problem #12 fix: When scrolling programmatically (from didUpdateWidget or month click),
  // we don't want to notify parent which would cause another scroll
  bool _isProgrammaticScroll = false;

  // Flag to prevent concurrent prepend operations (Problem #13 fix)
  bool _isPrepending = false;

  // Timestamp of last prepend to debounce (Problem #13 fix)
  DateTime? _lastPrependTime;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeDateRange();
    _setupScrollListeners();
    _scheduleInitialScroll();
  }

  @override
  void didUpdateWidget(TimelineCalendarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // CRITICAL FIX: React to initialScrollToDate prop changes from toolbar
    // When user clicks toolbar arrows or changes month, parent updates initialScrollToDate
    // Without this, widget only uses initialScrollToDate in initState() and ignores changes
    if (widget.initialScrollToDate != oldWidget.initialScrollToDate &&
        widget.initialScrollToDate != null) {
      // Problem #12 fix: Set flag to prevent infinite loop
      // When we scroll, onVisibleDateRangeChanged would update parent, which would
      // change initialScrollToDate again, causing another scroll
      _isProgrammaticScroll = true;
      _scrollToDate(widget.initialScrollToDate!);
    }
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
    _dynamicStartDate = initialDate.subtract(const Duration(days: kTimelineInitialDaysOffset));
    _dynamicEndDate = initialDate.add(const Duration(days: kTimelineInitialDaysOffset));

    final initialDateIndex = initialDate.difference(_dynamicStartDate).inDays;
    _visibleStartIndex = (initialDateIndex - kTimelineInitialWindowDaysBefore).clamp(0, double.infinity).toInt();
    _visibleDayCount = kTimelineInitialWindowDaysTotal;
  }

  void _setupScrollListeners() {
    // Horizontal scroll sync (main -> header)
    // OPTIMIZED: Throttled on web for better Android web performance
    _scrollSyncListener = () {
      if (_isSyncingScroll || !_horizontalScrollController.hasClients) return;

      final mainOffset = _horizontalScrollController.offset;

      if (kIsWeb) {
        // Throttle horizontal scroll sync on web (Android web performance fix)
        _horizontalScrollThrottleTimer?.cancel();
        _horizontalScrollThrottleTimer = Timer(
          const Duration(milliseconds: 16), // ~60fps throttling
          () {
            if (!mounted || _isSyncingScroll) return;
            _performHorizontalScrollSync(mainOffset);
          },
        );
      } else {
        // Native platforms: immediate sync for smooth feel
        _performHorizontalScrollSync(mainOffset);
      }
    };
    _horizontalScrollController.addListener(_scrollSyncListener);

    // Vertical scroll sync (main -> unit names)
    // OPTIMIZED: Throttled on web for better Android web performance
    _verticalScrollSyncListener = () {
      if (_isSyncingScroll || !_verticalScrollController.hasClients) return;

      final mainOffset = _verticalScrollController.offset;

      if (kIsWeb) {
        // Throttle vertical scroll sync on web (Android web performance fix)
        _verticalScrollThrottleTimer?.cancel();
        _verticalScrollThrottleTimer = Timer(
          const Duration(milliseconds: 16), // ~60fps throttling
          () {
            if (!mounted || _isSyncingScroll) return;
            _performVerticalScrollSync(mainOffset);
          },
        );
        // Always report offset changes (no throttling for parent callback)
        widget.onVerticalOffsetChanged?.call(mainOffset);
      } else {
        // Native platforms: immediate sync for smooth feel
        _performVerticalScrollSync(mainOffset);
        widget.onVerticalOffsetChanged?.call(mainOffset);
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

  /// Perform horizontal scroll sync (extracted for throttling)
  void _performHorizontalScrollSync(double mainOffset) {
    if (_isSyncingScroll || !_horizontalScrollController.hasClients) return;

    // Skip if offset hasn't changed significantly (reduces unnecessary work)
    if ((mainOffset - _lastHorizontalScrollOffset).abs() < 0.5) return;
    _lastHorizontalScrollOffset = mainOffset;

    _isSyncingScroll = true;
    try {
      if (_headerScrollController.hasClients) {
        _headerScrollController.jumpTo(mainOffset);
      }
    } finally {
      _isSyncingScroll = false;
    }
  }

  /// Perform vertical scroll sync (extracted for throttling)
  void _performVerticalScrollSync(double mainOffset) {
    if (_isSyncingScroll || !_verticalScrollController.hasClients) return;

    // Skip if offset hasn't changed significantly (reduces unnecessary work)
    if ((mainOffset - _lastVerticalScrollOffset).abs() < 0.5) return;
    _lastVerticalScrollOffset = mainOffset;

    _isSyncingScroll = true;
    try {
      if (_unitNamesScrollController.hasClients) {
        final maxExtent = _unitNamesScrollController.position.maxScrollExtent;
        final clampedOffset = mainOffset.clamp(0.0, maxExtent);
        if ((_unitNamesScrollController.offset - clampedOffset).abs() > 0.5) {
          _unitNamesScrollController.jumpTo(clampedOffset);
        }
      }
    } finally {
      _isSyncingScroll = false;
    }
  }

  void _onTransformChanged() {
    final matrix = _transformationController.value;
    final newScale = matrix.getMaxScaleOnAxis();

    if ((newScale - _zoomScale).abs() > 0.01) {
      setState(() {
        _zoomScale = newScale.clamp(kTimelineMinZoomScale, kTimelineMaxZoomScale);
      });
    }
  }

  void _updateVisibleRange() {
    if (!_horizontalScrollController.hasClients || !mounted) return;

    final dimensions = context.timelineDimensionsWithZoom(_zoomScale);
    final scrollOffset = _horizontalScrollController.offset;
    final dayWidth = dimensions.dayWidth;

    // Calculate total available days
    final totalDays = _dynamicEndDate.difference(_dynamicStartDate).inDays;
    if (totalDays <= 0) return; // Invalid state, skip update

    final firstVisibleDay = (scrollOffset / dayWidth).floor();
    final daysInViewport = dimensions.daysInViewport;

    // Clamp newStartIndex to valid range [0, totalDays - 1]
    final newStartIndex = (firstVisibleDay - kTimelineBufferDays).clamp(0, totalDays - 1);
    // Clamp newDayCount to not exceed available days from startIndex
    final maxDayCount = totalDays - newStartIndex;
    final newDayCount = (daysInViewport + (2 * kTimelineBufferDays)).clamp(1, maxDayCount);

    // Only update if range changed significantly
    if ((newStartIndex - _visibleStartIndex).abs() > kTimelineVisibleRangeUpdateThreshold ||
        (newDayCount - _visibleDayCount).abs() > kTimelineVisibleRangeUpdateThreshold) {
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
    // Problem #12 fix: Skip notification during programmatic scroll to prevent infinite loop
    if (widget.onVisibleDateRangeChanged != null && !_isInitialScrolling && !_isProgrammaticScroll) {
      final visibleStartDate = _dynamicStartDate.add(Duration(days: firstVisibleDay));

      if (kIsWeb) {
        // Debounce on web to reduce setState calls in parent during scroll
        _visibleRangeDebounceTimer?.cancel();
        _visibleRangeDebounceTimer = Timer(const Duration(milliseconds: 100), () {
          if (mounted) {
            widget.onVisibleDateRangeChanged!(visibleStartDate);
          }
        });
      } else {
        // Instant feedback on native platforms
        widget.onVisibleDateRangeChanged!(visibleStartDate);
      }
    }
  }

  void _handleInfiniteScroll(double scrollOffset, double dayWidth) {
    final edgeThreshold = dayWidth * kTimelineEdgeThresholdDays;
    final maxScroll = _horizontalScrollController.position.maxScrollExtent;

    // Problem #13 fix: Add debounce and guard against concurrent prepends
    final now = DateTime.now();
    final canPrepend = !_isPrepending &&
        (_lastPrependTime == null || now.difference(_lastPrependTime!).inMilliseconds > 500);

    // Near start edge? Prepend days with scroll position compensation
    // Problem #13 fix: Only prepend if scroll offset > 0 (not already at absolute start)
    // and if not already prepending, and if debounce period has passed
    if (scrollOffset < edgeThreshold &&
        scrollOffset > 0 && // Prevent loop when at position 0
        canPrepend &&
        _dynamicStartDate.isAfter(DateTime.now().subtract(const Duration(days: kTimelineMaxDaysLimit)))) {
      // Set flags to prevent concurrent prepends
      _isPrepending = true;
      _lastPrependTime = now;

      // Save current scroll offset before modifying date range
      final currentOffset = _horizontalScrollController.offset;
      final scrollCompensation = kTimelineDaysToExtend * dayWidth;

      setState(() {
        _dynamicStartDate = _dynamicStartDate.subtract(const Duration(days: kTimelineDaysToExtend));
      });

      // Compensate scroll position after setState completes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _horizontalScrollController.hasClients) {
          final newOffset = currentOffset + scrollCompensation;
          final maxExtent = _horizontalScrollController.position.maxScrollExtent;
          _horizontalScrollController.jumpTo(newOffset.clamp(0.0, maxExtent));
        }
        // Reset prepending flag after compensation is done
        _isPrepending = false;
      });
    }

    // Near end edge? Append days (no compensation needed for append)
    // Problem #14 fix: Changed limit check to use _dynamicStartDate as reference
    // This allows scrolling to any date within 2 years of the start date,
    // not just 1 year from today. Allows January 2026 from December 2025.
    if (scrollOffset > maxScroll - edgeThreshold &&
        _dynamicEndDate.isBefore(_dynamicStartDate.add(const Duration(days: kTimelineMaxDaysLimit * 2)))) {
      setState(() {
        _dynamicEndDate = _dynamicEndDate.add(const Duration(days: kTimelineDaysToExtend));
      });
    }
  }

  void _scrollToTodayWithRetry({int retryCount = 0}) {
    if (retryCount >= kTimelineMaxScrollRetryAttempts) return;

    if (!_horizontalScrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: kTimelineScrollRetryDelayMs), () {
        if (mounted) _scrollToTodayWithRetry(retryCount: retryCount + 1);
      });
      return;
    }

    _scrollToToday();
  }

  void _scrollToToday() {
    _scrollToDate(widget.initialScrollToDate ?? DateTime.now(), isInitialScroll: true);
  }

  /// Unified scroll-to-date method used by:
  /// - _scrollToToday() for initial scroll
  /// - didUpdateWidget() for toolbar navigation
  /// - Any future date navigation needs
  void _scrollToDate(DateTime targetDate, {bool isInitialScroll = false}) {
    if (!_horizontalScrollController.hasClients) return;

    final dimensions = context.timelineDimensionsWithZoom(_zoomScale);

    // Check if target date is within current range, extend if needed
    if (targetDate.isBefore(_dynamicStartDate)) {
      final daysToExtend = _dynamicStartDate.difference(targetDate).inDays + kTimelineBufferDays;
      setState(() {
        _dynamicStartDate = _dynamicStartDate.subtract(Duration(days: daysToExtend));
      });
      // Wait for rebuild then scroll
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollToDate(targetDate, isInitialScroll: isInitialScroll);
      });
      return;
    }

    if (targetDate.isAfter(_dynamicEndDate)) {
      final daysToExtend = targetDate.difference(_dynamicEndDate).inDays + kTimelineBufferDays;
      setState(() {
        _dynamicEndDate = _dynamicEndDate.add(Duration(days: daysToExtend));
      });
      // Wait for rebuild then scroll
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollToDate(targetDate, isInitialScroll: isInitialScroll);
      });
      return;
    }

    final daysSinceStart = targetDate.difference(_dynamicStartDate).inDays;
    final scrollPosition = daysSinceStart * dimensions.dayWidth;

    final maxScroll = _horizontalScrollController.position.maxScrollExtent;
    final visibleWidth = dimensions.visibleContentWidth;

    final targetScroll = (scrollPosition - (visibleWidth / 2) + (dimensions.dayWidth / 2)).clamp(0.0, maxScroll);

    _horizontalScrollController
        .animateTo(targetScroll, duration: AppDimensions.animationSlow, curve: Curves.easeInOut)
        .then((_) {
          if (mounted) {
            if (isInitialScroll) {
              setState(() => _isInitialScrolling = false);
            }
            // Restore vertical scroll position if provided (preserves position on toolbar navigation)
            _restoreVerticalScrollPosition();
            // Problem #12 fix: Reset programmatic scroll flag after scroll completes
            // Use a small delay to ensure the scroll position has settled
            // before allowing onVisibleDateRangeChanged to fire again
            Future.delayed(const Duration(milliseconds: 150), () {
              if (mounted) {
                _isProgrammaticScroll = false;
              }
            });
          }
        });
  }

  /// Scroll to a specific month when month header is tapped
  void _scrollToMonth(DateTime month) {
    if (!_horizontalScrollController.hasClients) return;

    // Problem #12 fix: Set flag to prevent infinite loop when month header clicked
    _isProgrammaticScroll = true;

    // Target is first day of the month
    final targetDate = DateTime(month.year, month.month);

    final dimensions = context.timelineDimensionsWithZoom(_zoomScale);

    // Check if target date is within current range, extend if needed
    if (targetDate.isBefore(_dynamicStartDate)) {
      final daysToExtend = _dynamicStartDate.difference(targetDate).inDays + kTimelineBufferDays;
      setState(() {
        _dynamicStartDate = _dynamicStartDate.subtract(Duration(days: daysToExtend));
      });
      // Wait for rebuild then scroll
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollToMonth(month);
      });
      return;
    }

    if (targetDate.isAfter(_dynamicEndDate)) {
      final daysToExtend = targetDate.difference(_dynamicEndDate).inDays + kTimelineBufferDays;
      setState(() {
        _dynamicEndDate = _dynamicEndDate.add(Duration(days: daysToExtend));
      });
      // Wait for rebuild then scroll
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollToMonth(month);
      });
      return;
    }

    final daysSinceStart = targetDate.difference(_dynamicStartDate).inDays;
    final scrollPosition = daysSinceStart * dimensions.dayWidth;

    final maxScroll = _horizontalScrollController.position.maxScrollExtent;

    // Scroll to show the month at the left edge of the viewport
    final targetScroll = scrollPosition.clamp(0.0, maxScroll);

    _horizontalScrollController
        .animateTo(targetScroll, duration: AppDimensions.animationSlow, curve: Curves.easeInOut)
        .then((_) {
          if (mounted) {
            // Problem #12 fix: Reset programmatic scroll flag after scroll completes
            // Use a small delay to ensure the scroll position has settled
            Future.delayed(const Duration(milliseconds: 150), () {
              if (mounted) {
                _isProgrammaticScroll = false;
              }
            });
            // Notify parent of visible date change
            widget.onVisibleDateRangeChanged?.call(targetDate);
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

  /// Scroll to a specific conflict location (date and unit)
  /// Public method that can be called from parent widget via GlobalKey
  void scrollToConflict(String unitId, DateTime conflictDate) {
    if (!_horizontalScrollController.hasClients || !_verticalScrollController.hasClients) {
      // Wait for controllers to be ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) scrollToConflict(unitId, conflictDate);
      });
      return;
    }

    final dimensions = context.timelineDimensionsWithZoom(_zoomScale);

    // Scroll horizontally to conflict date
    final daysSinceStart = conflictDate.difference(_dynamicStartDate).inDays;
    final horizontalScrollPosition = daysSinceStart * dimensions.dayWidth;
    final maxHorizontalScroll = _horizontalScrollController.position.maxScrollExtent;
    final visibleWidth = dimensions.visibleContentWidth;
    final targetHorizontalScroll = (horizontalScrollPosition - (visibleWidth / 2) + (dimensions.dayWidth / 2)).clamp(
      0.0,
      maxHorizontalScroll,
    );

    // Scroll vertically to unit
    // Get units list to find unit index
    final unitsAsync = ref.read(filteredUnitsProvider);
    if (unitsAsync.isLoading || unitsAsync.value == null) return;

    final units = unitsAsync.value!;
    final unitIndex = units.indexWhere((unit) => unit.id == unitId);
    if (unitIndex < 0) return; // Unit not found

    // Calculate vertical scroll position (each unit row is ~60px tall)
    const unitRowHeight = 60.0;
    final verticalScrollPosition = unitIndex * unitRowHeight;
    final maxVerticalScroll = _verticalScrollController.position.maxScrollExtent;
    final visibleHeight = MediaQuery.of(context).size.height * 0.7; // Approximate visible height
    final targetVerticalScroll = (verticalScrollPosition - (visibleHeight / 2) + (unitRowHeight / 2)).clamp(
      0.0,
      maxVerticalScroll,
    );

    // Perform scrolls
    _horizontalScrollController.animateTo(
      targetHorizontalScroll,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );

    _verticalScrollController.animateTo(
      targetVerticalScroll,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );

    // Sync unit names scroll
    if (_unitNamesScrollController.hasClients) {
      final unitMaxOffset = _unitNamesScrollController.position.maxScrollExtent;
      final unitClampedOffset = targetVerticalScroll.clamp(0.0, unitMaxOffset);
      _unitNamesScrollController.animateTo(
        unitClampedOffset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  List<DateTime> _getDateRange() {
    // Ensure dates are valid
    if (_dynamicStartDate.isAfter(_dynamicEndDate)) {
      // Invalid range, reinitialize
      _initializeDateRange();
    }
    final days = _dynamicEndDate.difference(_dynamicStartDate).inDays;
    // Ensure we have at least 1 day
    if (days <= 0) {
      // Invalid range, reinitialize
      _initializeDateRange();
      final retryDays = _dynamicEndDate.difference(_dynamicStartDate).inDays;
      if (retryDays <= 0) {
        // Still invalid, return a default range
        final now = DateTime.now();
        return List.generate(60, (i) => now.add(Duration(days: i - 30)));
      }
      return List.generate(retryDays, (i) => _dynamicStartDate.add(Duration(days: i)));
    }
    return List.generate(days, (i) => _dynamicStartDate.add(Duration(days: i)));
  }

  List<DateTime> _getVisibleDateRange() {
    final fullRange = _getDateRange();
    final totalDays = fullRange.length;

    // Ensure we have dates
    if (totalDays == 0) {
      // Return a default range if empty
      final now = DateTime.now();
      return List.generate(30, (i) => now.add(Duration(days: i)));
    }

    // Ensure indices are valid
    final startIndex = _visibleStartIndex.clamp(0, totalDays - 1);
    final endIndex = (startIndex + _visibleDayCount).clamp(startIndex + 1, totalDays);

    // Ensure endIndex > startIndex
    if (endIndex <= startIndex) {
      final defaultEndIndex = (startIndex + 30).clamp(startIndex + 1, totalDays);
      return fullRange.sublist(startIndex, defaultEndIndex);
    }

    return fullRange.sublist(startIndex, endIndex);
  }

  @override
  void dispose() {
    _visibleRangeDebounceTimer?.cancel();
    _verticalScrollThrottleTimer?.cancel();
    _horizontalScrollThrottleTimer?.cancel();
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
                  errorMessage: _safeErrorToString(error),
                  onRetry: () {
                    ref.invalidate(allOwnerUnitsProvider);
                    ref.invalidate(calendarBookingsProvider);
                  },
                );
              }

              final units = unitsAsync.value ?? [];
              final bookingsByUnit = bookingsAsync.value ?? {};

              if (units.isEmpty) return _buildEmptyUnitsState(ref);

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
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceS, vertical: AppDimensions.spaceXXS),
      color: AppColors.primary.withValues(alpha: 0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_zoomScale > 1.0 ? Icons.zoom_in : Icons.zoom_out, size: AppDimensions.iconS, color: AppColors.primary),
          const SizedBox(width: AppDimensions.spaceXXS),
          Text(
            l10n.ownerCalendarZoom((_zoomScale * 100).toInt()),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
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
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceXS),
              minimumSize: const Size(0, 28),
            ),
            child: Text(l10n.ownerCalendarReset, style: const TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyUnitsState(WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spaceM),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.ownerCalendarNoUnits, textAlign: TextAlign.center),
            const SizedBox(height: AppDimensions.spaceS),
            Wrap(
              spacing: AppDimensions.spaceS,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    ref.read(calendarFiltersProvider.notifier).clearFilters();
                    ref.invalidate(allOwnerUnitsProvider);
                    ref.invalidate(calendarBookingsProvider);
                  },
                  icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                  label: Text(l10n.calendarFiltersClear),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    ref.invalidate(allOwnerUnitsProvider);
                    ref.invalidate(calendarBookingsProvider);
                  },
                  icon: const Icon(Icons.refresh, size: 18),
                  label: Text(l10n.calendarErrorRetry),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineView(List<UnitModel> units, Map<String, List<BookingModel>> bookingsByUnit) {
    // FILTER: Optionally hide units without bookings based on toggle
    final visibleUnits = widget.showEmptyUnits
        ? units
        : units.where((unit) {
            final bookings = bookingsByUnit[unit.id] ?? [];
            return bookings.isNotEmpty;
          }).toList();

    final dimensions = context.timelineDimensionsWithZoom(_zoomScale);
    final dates = _getVisibleDateRange();

    // Defensive check: ensure dates list is not empty
    if (dates.isEmpty) {
      // If dates are empty, try to regenerate the date range
      _initializeDateRange();
      final retryDates = _getVisibleDateRange();
      if (retryDates.isEmpty) {
        // Still empty, return error widget
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Unable to generate date range for timeline. Please refresh the page.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        );
      }
      // Use retry dates
      final offsetWidth = dimensions.getOffsetWidth(_visibleStartIndex);
      return _buildTimelineContent(visibleUnits, bookingsByUnit, retryDates, offsetWidth, dimensions);
    }

    final offsetWidth = dimensions.getOffsetWidth(_visibleStartIndex);

    // Ensure offsetWidth and dayWidth are valid
    if (!offsetWidth.isFinite || !dimensions.dayWidth.isFinite || dimensions.dayWidth <= 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Invalid timeline dimensions. Please refresh the page.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }

    // NOTE: Grid should ALWAYS render when units exist, even if bookingsByUnit is empty
    // Empty bookings is a valid state (e.g., new property with no reservations)
    // User needs the grid to navigate dates, see unit rows, and add new bookings
    return _buildTimelineContent(visibleUnits, bookingsByUnit, dates, offsetWidth, dimensions);
  }

  Widget _buildTimelineContent(
    List<UnitModel> units,
    Map<String, List<BookingModel>> bookingsByUnit,
    List<DateTime> dates,
    double offsetWidth,
    TimelineDimensions dimensions,
  ) {
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
            onMonthTap: _scrollToMonth,
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
                      dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse, PointerDeviceKind.trackpad},
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
                            ? const ClampingScrollPhysics(parent: AlwaysScrollableScrollPhysics())
                            : const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                        child: SingleChildScrollView(
                          controller: _verticalScrollController,
                          // OPTIMIZED: Android web performance - use ClampingScrollPhysics
                          // and reduce scroll friction for smoother scrolling
                          physics: kIsWeb
                              ? const ClampingScrollPhysics(parent: AlwaysScrollableScrollPhysics())
                              : const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                          child: Column(
                            // FIXED: Restored mainAxisSize.min from working version
                            // This was removed during performance optimization, causing grid to disappear
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
                                    _buildDropZone(unit, date, offsetWidth, index, bookingsByUnit),
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
          final clampedOffset = _unitNamesScrollController.offset.clamp(0.0, maxExtent);
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
        onLongPress: widget.onCellLongPress != null ? () => widget.onCellLongPress!(date, unit) : null,
        onBookingDropped: (booking) => _handleBookingDrop(booking, date, unit, allBookings),
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
        .executeDrop(dropDate: dropDate, targetUnit: targetUnit, allBookings: allBookings, context: context);
    ref.read(dragDropProvider.notifier).stopDragging();
  }

  void _showBookingActionMenu(BookingModel booking) async {
    // Get bookings data to detect conflicts
    final bookingsAsync = ref.read(timelineCalendarBookingsProvider);
    final bookingsByUnit = bookingsAsync.value ?? {};

    // Detect conflicting bookings
    final conflictingBookings = BookingOverlapDetector.getConflictingBookings(
      unitId: booking.unitId,
      newCheckIn: booking.checkIn,
      newCheckOut: booking.checkOut,
      bookingIdToExclude: booking.id,
      allBookings: bookingsByUnit,
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
          await CalendarBookingActions.changeBookingStatus(context, ref, booking, newStatus);
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
