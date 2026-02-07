import 'dart:async' show Timer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/router_owner.dart';
import '../../../../shared/models/booking_model.dart';
import '../../../../shared/models/unit_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../providers/owner_calendar_provider.dart';
import '../providers/calendar_drag_drop_provider.dart';
import '../providers/calendar_filters_provider.dart';
import 'calendar/booking_inline_edit_dialog.dart';
import 'calendar/booking_drop_zone.dart';
import 'booking_actions/booking_approve_dialog.dart';
import 'booking_actions/booking_reject_dialog.dart';
import 'booking_actions/booking_cancel_dialog.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../core/utils/error_display_utils.dart';
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
import 'timeline/timeline_snap_scroll_physics.dart';
import 'timeline/calendar_scroll_behavior.dart';
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

  /// Problem #19 fix: Force scroll even if date hasn't changed
  /// Used by Today button to always scroll to today regardless of current view
  /// Incremented each time Today is clicked to force didUpdateWidget to trigger scroll
  final int forceScrollKey;

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
    this.forceScrollKey = 0,
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

  // CRITICAL FIX: Flag to force using _visibleStartIndex even when hasClients=true
  // When jumping far (e.g., from January to October), we need the 90-day window to be
  // built around the TARGET date, not the current scroll position. This flag tells
  // _calculateVisibleStartIndex() to use our pre-set _visibleStartIndex value.
  bool _forceVisibleStartIndex = false;

  // TELEPORT FIX: Store target start index during TELEPORT operation.
  // This value persists through ALL rebuilds during TELEPORT, ensuring the
  // correct date range is used even if _forceVisibleStartIndex is consumed
  // or _isProgrammaticScroll timing is off. Reset to null when TELEPORT completes.
  int? _teleportTargetStartIndex;

  // Fixed date range (simplified - no more dynamic PREPEND/APPEND)
  // This eliminates the scroll compensation race condition that caused erratic scrolling
  late DateTime _fixedStartDate;
  late DateTime _fixedEndDate;
  bool _isInitialScrolling = true;

  double _lastVerticalScrollOffset = 0.0;
  double _lastHorizontalScrollOffset = 0.0;

  // Flag to track programmatic scrolls (prevents infinite loop with onVisibleDateRangeChanged)
  // Problem #12 fix: When scrolling programmatically (from didUpdateWidget or month click),
  // we don't want to notify parent which would cause another scroll
  bool _isProgrammaticScroll = false;

  // Bug #4 fix: Timer for resetting _isProgrammaticScroll flag (cancelable in dispose)
  Timer? _programmaticScrollResetTimer;

  // Flag to prevent overlapping scroll animations (Problem #4 fix)
  // When true, new scroll requests are ignored until current animation completes
  bool _isScrollAnimating = false;

  // Problem #3 fix: Memoization for _getVisibleDateRange()
  // Cache the visible date range to avoid recalculating on every scroll
  List<DateTime>? _cachedVisibleDateRange;
  int _cachedVisibleStartIndex = -1;

  // Problem #7 fix: Memoization for _buildTimelineView()
  // Cache the build result to avoid rebuilding with identical data
  int? _lastBuildDataHash;
  Widget? _cachedTimelineContent;

  // OPTIMIZATION: Cache full date range to avoid generating 1460 DateTime objects repeatedly
  List<DateTime>? _cachedFullDateRange;

  // REMOVED: _isPrepending, _lastPrependTime, _isAppending, _lastAppendTime
  // These were part of the complex PREPEND/APPEND system that caused scroll issues
  // With fixed date range, we no longer need these flags

  @override
  void initState() {
    super.initState();
    // IMPORTANT: _initializeDateRange() must be called FIRST because it creates
    // _horizontalScrollController with the correct initialScrollOffset
    _initializeDateRange();
    _initializeControllers();
    _setupScrollListeners();
    _scheduleInitialScroll();
  }

  @override
  void didUpdateWidget(TimelineCalendarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // FEEDBACK LOOP FIX: Only scroll when user EXPLICITLY requests it via toolbar
    // Previously: scrolled whenever initialScrollToDate changed (including from scroll updates)
    // Problem: _updateVisibleRange → parent updates date → didUpdateWidget → scroll → loop!
    //
    // Now: ONLY scroll when forceScrollKey changes (user clicked toolbar button)
    // The date display in toolbar is still updated via onVisibleDateRangeChanged,
    // but that no longer triggers a scroll back here.
    final forceScrollKeyChanged =
        widget.forceScrollKey != oldWidget.forceScrollKey;

    if (forceScrollKeyChanged) {
      final targetDate = widget.initialScrollToDate ?? DateTime.now();

      // Problem #5 additional fix: Check if target is already visible before scrolling
      // This prevents unnecessary scroll animations when clicking Today button
      // but already viewing today's date
      bool shouldSkipScroll = false;
      if (_horizontalScrollController.hasClients) {
        try {
          final dimensions = context.timelineDimensionsWithZoom(_zoomScale);
          final daysSinceStart = targetDate.difference(_fixedStartDate).inDays;
          final targetScrollPos = daysSinceStart * dimensions.dayWidth;
          final currentScroll = _horizontalScrollController.offset;
          final visibleWidth = dimensions.visibleContentWidth;

          // Calculate centered target position
          final centeredTarget =
              (targetScrollPos - (visibleWidth / 2) + (dimensions.dayWidth / 2))
                  .clamp(
                    0.0,
                    _horizontalScrollController.position.maxScrollExtent,
                  );

          // Skip if target is already within 1/2 of visible width from current position
          // INCREASED from 1/4 to 1/2 to prevent feedback loop with _updateVisibleRange
          // EXCEPTION: Never skip when forceScrollKey changed (user explicitly requested scroll)
          final scrollDifference = (centeredTarget - currentScroll).abs();
          final skipThreshold = visibleWidth / 2;

          // FIX: Date picker precision - don't skip when user explicitly selected a date
          // forceScrollKeyChanged means user clicked toolbar button (Today, arrows, date picker)
          if (scrollDifference < skipThreshold && !forceScrollKeyChanged) {
            shouldSkipScroll = true;
          }
        } catch (e) {
          // If calculation fails, proceed with scroll
          shouldSkipScroll = false;
        }
      }

      // RACE CONDITION FIX: Skip if animation is already in progress
      // When user clicks next/prev rapidly, _scrollToMonth triggers animation,
      // then onVisibleDateRangeChanged updates parent, which triggers didUpdateWidget
      // with the OLD target date. Without this check, we'd scroll back to the old target.
      if (_isScrollAnimating) {
        shouldSkipScroll = true;
      }

      if (!shouldSkipScroll) {
        // Problem #12 fix: Set flag to prevent infinite loop
        // When we scroll, onVisibleDateRangeChanged would update parent, which would
        // change initialScrollToDate again, causing another scroll
        _isProgrammaticScroll = true;
        // forceScroll=true when user explicitly selected date via toolbar (forceScrollKey changed)
        _scrollToDate(targetDate, forceScroll: forceScrollKeyChanged);
      }
    }
  }

  void _initializeControllers() {
    // NOTE: _horizontalScrollController is initialized in _initializeDateRange()
    // with the correct initialScrollOffset to show today's date immediately
    _verticalScrollController = ScrollController();
    // Header controller must have the same initial offset to stay in sync
    _headerScrollController = ScrollController(
      initialScrollOffset: _horizontalScrollController.initialScrollOffset,
    );
    _unitNamesScrollController = ScrollController();
    _transformationController = TransformationController();
  }

  void _initializeDateRange() {
    // OPTIMIZED: Start with 1 year range instead of 4 years
    // This significantly improves scroll performance on mobile devices
    // Range is extended dynamically when user approaches edges
    final today = DateTime.now();

    // Initial range: 6 months before and 6 months after today (1 year total)
    // Much smaller scroll extent = smoother scrolling
    // DST FIX: Use UTC to avoid off-by-one errors when DST changes between
    // summer (UTC+2) and winter (UTC+1) cause Duration.inDays to miscalculate
    _fixedStartDate = DateTime.utc(today.year, today.month - 6, today.day);
    _fixedEndDate = DateTime.utc(today.year, today.month + 6, today.day);

    final totalDays = _fixedEndDate.difference(_fixedStartDate).inDays;
    final initialDate = widget.initialScrollToDate ?? today;
    final daysSinceStart = initialDate.difference(_fixedStartDate).inDays;

    // CRITICAL FIX: Set _visibleStartIndex to center around initial date
    // This ensures the windowed content includes today's date from the start
    // Window size is ~90 days, we want initial date roughly in the middle
    const windowBefore = 30; // Show 30 days before the target date
    _visibleStartIndex = (daysSinceStart - windowBefore).clamp(
      0,
      totalDays - kTimelineInitialWindowDaysTotal,
    );
    _visibleDayCount = kTimelineInitialWindowDaysTotal;

    // Calculate initial scroll offset to show the target date centered
    // dayWidth is approximately 60px at default zoom
    const approximateDayWidth = 60.0;
    final offsetWidth = _visibleStartIndex * approximateDayWidth;
    // Position within the window (days from window start to target date)
    final daysIntoWindow = daysSinceStart - _visibleStartIndex;
    // Center the target date in the viewport (assume ~1000px viewport)
    const approximateViewportWidth = 1000.0;
    final scrollToTargetInWindow = daysIntoWindow * approximateDayWidth;
    final initialScrollOffset =
        (offsetWidth + scrollToTargetInWindow - (approximateViewportWidth / 2))
            .clamp(0.0, double.maxFinite);

    // Initialize horizontal scroll controller with correct initial offset
    // This ensures the user sees today's date immediately without waiting for scroll
    _horizontalScrollController = ScrollController(
      initialScrollOffset: initialScrollOffset,
    );
  }

  void _setupScrollListeners() {
    // Horizontal scroll sync (main -> header)
    // FIXED: Removed throttling - instant sync is critical for header alignment
    // The previous 16ms throttle caused visible lag between grid and header
    _scrollSyncListener = () {
      if (_isSyncingScroll || !_horizontalScrollController.hasClients) return;

      final mainOffset = _horizontalScrollController.offset;
      // Always sync immediately - header must stay aligned with grid
      _performHorizontalScrollSync(mainOffset);
    };
    _horizontalScrollController.addListener(_scrollSyncListener);

    // Vertical scroll sync (main -> unit names)
    // NOTE: Removed throttling as it caused laggy/uneven sidebar sync on web
    _verticalScrollSyncListener = () {
      if (_isSyncingScroll || !_verticalScrollController.hasClients) return;

      final mainOffset = _verticalScrollController.offset;

      // Immediate sync for smooth feel on all platforms
      _performVerticalScrollSync(mainOffset);
      widget.onVerticalOffsetChanged?.call(mainOffset);
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

  /// Perform horizontal scroll sync (header follows main grid)
  /// CRITICAL: This must be instant (no throttling) for smooth header alignment
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
        _zoomScale = newScale.clamp(
          kTimelineMinZoomScale,
          kTimelineMaxZoomScale,
        );
      });
    }
  }

  // Frame-based throttle state for visible date reporting
  DateTime? _pendingVisibleStartDate;
  bool _visibleRangeFrameScheduled = false;

  void _updateVisibleRange() {
    if (!_horizontalScrollController.hasClients || !mounted) return;

    final dimensions = context.timelineDimensionsWithZoom(_zoomScale);
    final scrollOffset = _horizontalScrollController.offset;
    final dayWidth = dimensions.dayWidth;

    final totalDays = _fixedEndDate.difference(_fixedStartDate).inDays;
    if (totalDays <= 0) return;

    // round() instead of floor(): toolbar updates when day is >=50% visible,
    // not when 1px appears at the left edge. Fixes backward-scroll offset.
    final firstVisibleDay = (scrollOffset / dayWidth).round();
    final daysInViewport = dimensions.daysInViewport;

    // === SECTION 1: Report visible date to parent (ALWAYS, except TELEPORT) ===
    // During TELEPORT, scroll position is invalid (old position + new content).
    // During normal animation (Next/Prev), position IS valid — toolbar should track.
    if (widget.onVisibleDateRangeChanged != null &&
        !_isInitialScrolling &&
        _teleportTargetStartIndex == null) {
      final visibleStartDate = _fixedStartDate.add(
        Duration(days: firstVisibleDay.clamp(0, totalDays - 1)),
      );
      _pendingVisibleStartDate = visibleStartDate;
      if (!_visibleRangeFrameScheduled) {
        _visibleRangeFrameScheduled = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _visibleRangeFrameScheduled = false;
          if (mounted && _pendingVisibleStartDate != null) {
            widget.onVisibleDateRangeChanged!(_pendingVisibleStartDate!);
            _pendingVisibleStartDate = null;
          }
        });
      }
    }

    // === SECTION 2: Window management (skip during programmatic scroll) ===
    if (_isProgrammaticScroll || _forceVisibleStartIndex) return;
    if (_teleportTargetStartIndex != null) return;

    final newStartIndex = (firstVisibleDay - kTimelineBufferDays).clamp(
      0,
      totalDays - 1,
    );
    final maxDayCount = totalDays - newStartIndex;
    final newDayCount = (daysInViewport + (2 * kTimelineBufferDays)).clamp(
      1,
      maxDayCount,
    );

    final threshold = _isScrollAnimating
        ? kTimelineVisibleRangeUpdateThreshold * 3
        : kTimelineVisibleRangeUpdateThreshold;

    if ((newStartIndex - _visibleStartIndex).abs() > threshold ||
        (newDayCount - _visibleDayCount).abs() > threshold) {
      _cachedVisibleDateRange = null;
      _cachedVisibleStartIndex = -1;
      _cachedTimelineContent = null;
      _lastBuildDataHash = null;

      setState(() {
        _visibleStartIndex = newStartIndex;
        _visibleDayCount = newDayCount;
      });
    }

    // Auto-extend range forward when approaching the end.
    // Safe because content is appended (scroll position unchanged).
    // Backward extension is NOT done — it would shift all positions.
    final lastVisibleDay = firstVisibleDay + daysInViewport;
    const extensionBuffer = 30; // Extend when within 30 days of edge
    if (lastVisibleDay > totalDays - extensionBuffer) {
      _fixedEndDate = _fixedEndDate.add(const Duration(days: 180));
      _cachedFullDateRange = null;
      _cachedVisibleDateRange = null;
      _cachedVisibleStartIndex = -1;
      _cachedTimelineContent = null;
      _lastBuildDataHash = null;
    }
  }

  /// Wait for layout completion and then finalize initial scroll setup.
  ///
  /// SIMPLIFIED: With initialScrollOffset, the view is already positioned correctly.
  /// This method just waits for layout to complete and then:
  /// 1. Sets _isInitialScrolling = false
  /// 2. Restores vertical scroll position if provided
  /// 3. Optionally fine-tunes horizontal position if needed
  void _scrollToTodayWithRetry({int retryCount = 0}) {
    const maxRetries =
        10; // Reduced from 15 since initialScrollOffset handles positioning
    if (retryCount >= maxRetries) {
      // Timeout - just complete setup without scrolling
      _isInitialScrolling = false;
      _restoreVerticalScrollPosition();
      return;
    }

    // Check if layout is complete: hasClients AND maxScrollExtent > 0
    final hasClients = _horizontalScrollController.hasClients;
    double maxScrollExtent = 0;
    if (hasClients) {
      try {
        maxScrollExtent = _horizontalScrollController.position.maxScrollExtent;
      } catch (e) {
        maxScrollExtent = 0; // Position not attached yet
      }
    }

    if (!hasClients || maxScrollExtent <= 0) {
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) _scrollToTodayWithRetry(retryCount: retryCount + 1);
      });
      return;
    }

    _scrollToToday();
  }

  void _scrollToToday() {
    _scrollToDate(
      widget.initialScrollToDate ?? DateTime.now(),
      isInitialScroll: true,
    );
  }

  /// Unified scroll-to-date method used by:
  /// - _scrollToToday() for initial scroll
  /// - didUpdateWidget() for toolbar navigation
  /// - Any future date navigation needs
  ///
  /// SIMPLIFIED: With fixed date range, no more dynamic extension needed
  void _scrollToDate(
    DateTime targetDate, {
    bool isInitialScroll = false,
    bool forceScroll = false,
    int retryCount = 0,
  }) {
    // FIXED: Instead of skipping when animation is in progress, cancel it and start new one
    // This ensures toolbar navigation buttons work with single click
    // Previous behavior: Skip scroll if _isScrollAnimating -> caused 2-click issue
    // New behavior: Cancel current animation and start new one immediately
    if (_isScrollAnimating && !isInitialScroll) {
      // Cancel current animation by jumping to current position
      // This stops the animation immediately without side effects
      _horizontalScrollController.jumpTo(_horizontalScrollController.offset);
      _isScrollAnimating = false;
    }

    // FIX: Instead of aborting when no clients, retry after short delay
    // This handles race condition when widget rebuilds during scroll request
    if (!_horizontalScrollController.hasClients) {
      const maxRetries = 5;
      if (retryCount < maxRetries) {
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted) {
            _scrollToDate(
              targetDate,
              isInitialScroll: isInitialScroll,
              forceScroll: forceScroll,
              retryCount: retryCount + 1,
            );
          }
        });
      }
      return;
    }

    final dimensions = context.timelineDimensionsWithZoom(_zoomScale);

    // FIX: Normalize to UTC to match _fixedStartDate (prevents timezone-related day miscalculation)
    final clampedTarget = DateTime.utc(
      targetDate.year,
      targetDate.month,
      targetDate.day,
    );

    // FIX: EXTEND range if target is outside, don't clamp!
    // This allows scrolling to any date selected by user
    bool rangeExtended = false;
    if (clampedTarget.isBefore(_fixedStartDate)) {
      _fixedStartDate = DateTime.utc(clampedTarget.year, clampedTarget.month);
      rangeExtended = true;
    } else if (clampedTarget.isAfter(_fixedEndDate)) {
      // Extend to end of target month + 1 month buffer
      _fixedEndDate = DateTime.utc(clampedTarget.year, clampedTarget.month + 2);
      rangeExtended = true;
    }

    // TELEPORT FIX: If range was extended, rebuild and jumpTo (no recursive call)
    if (rangeExtended) {
      // CRITICAL: Cancel previous timer FIRST to prevent race condition
      // A previous timer might fire between setState and postFrameCallback,
      // resetting _teleportTargetStartIndex to null before we can use it.
      _programmaticScrollResetTimer?.cancel();
      _isProgrammaticScroll = true;

      // Invalidate ALL caches
      _cachedFullDateRange = null;
      _cachedVisibleDateRange = null;
      _cachedVisibleStartIndex = -1;
      _cachedTimelineContent = null;
      _lastBuildDataHash = null;

      // Set _visibleStartIndex to target date's position
      final targetDaysSinceStart = clampedTarget
          .difference(_fixedStartDate)
          .inDays;
      const windowBefore = 30;
      _visibleStartIndex = (targetDaysSinceStart - windowBefore).clamp(
        0,
        999999,
      );
      _forceVisibleStartIndex = true;
      // TELEPORT FIX: Store target index - persists through ALL rebuilds during TELEPORT
      _teleportTargetStartIndex = _visibleStartIndex;

      // Calculate scroll position within the NEW window
      // BUG FIX: Must include offsetWidth in scroll calculation!
      // Content = [SizedBox(offsetWidth)] + [day cells]
      // offsetWidth represents the spacer for days before the visible window
      // Without adding offsetWidth, scroll lands in the spacer, not the day cells
      final offsetWidth = _visibleStartIndex * dimensions.dayWidth;
      final newWindowTargetDay = windowBefore;
      final scrollInNewWindow =
          offsetWidth +
          (newWindowTargetDay * dimensions.dayWidth) -
          (dimensions.visibleContentWidth * 0.25);
      final teleportScrollPosition = scrollInNewWindow.clamp(
        0.0,
        double.maxFinite,
      );

      // Trigger rebuild, then jumpTo (NO recursive _scrollToDate call!)
      setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _horizontalScrollController.hasClients) {
          _horizontalScrollController.jumpTo(teleportScrollPosition);

          _programmaticScrollResetTimer?.cancel();
          _programmaticScrollResetTimer = Timer(
            const Duration(milliseconds: 500),
            () {
              if (mounted) {
                _isProgrammaticScroll = false;
                _teleportTargetStartIndex = null; // TELEPORT complete - reset
              }
            },
          );
        }
      });
      return;
    }

    final daysSinceStart = clampedTarget.difference(_fixedStartDate).inDays;

    // TELEPORT FIX: For far jumps (target outside visible window), don't animate.
    // Instead: rebuild window around target, then jumpTo the correct position.
    // This avoids race conditions from recursive _scrollToDate calls.
    final visibleRange = _getVisibleDateRange();
    final visibleStart = visibleRange.isNotEmpty ? visibleRange.first : null;
    final visibleEnd = visibleRange.isNotEmpty ? visibleRange.last : null;

    // Check if target is significantly outside visible range (with 5-day buffer for safety)
    final targetOutsideWindow =
        visibleStart != null &&
        visibleEnd != null &&
        (clampedTarget.isBefore(
              visibleStart.subtract(const Duration(days: 5)),
            ) ||
            clampedTarget.isAfter(visibleEnd.add(const Duration(days: 5))));

    if (targetOutsideWindow && forceScroll) {
      // CRITICAL: Cancel previous timer FIRST to prevent race condition
      // A previous timer might fire between setState and postFrameCallback,
      // resetting _teleportTargetStartIndex to null before we can use it.
      _programmaticScrollResetTimer?.cancel();

      // Set programmatic scroll flag
      _isProgrammaticScroll = true;

      // Invalidate caches
      _cachedVisibleDateRange = null;
      _cachedVisibleStartIndex = -1;
      _cachedTimelineContent = null;
      _lastBuildDataHash = null;

      // Set _visibleStartIndex so window is built around target
      // Target will be ~30 days into the new window
      const windowBefore = 30;
      _visibleStartIndex = (daysSinceStart - windowBefore).clamp(0, 999999);
      _forceVisibleStartIndex = true;
      // TELEPORT FIX: Store target index - persists through ALL rebuilds during TELEPORT
      _teleportTargetStartIndex = _visibleStartIndex;

      // Calculate scroll position within the NEW window
      // Target is at day 30 of new window, we want it at ~25% from left edge
      // BUG FIX: Must include offsetWidth in scroll calculation!
      // Content = [SizedBox(offsetWidth)] + [day cells]
      // offsetWidth represents the spacer for days before the visible window
      // Without adding offsetWidth, scroll lands in the spacer, not the day cells
      final offsetWidth = _visibleStartIndex * dimensions.dayWidth;
      final newWindowTargetDay =
          windowBefore; // Target is 30 days into new window
      final scrollInNewWindow =
          offsetWidth +
          (newWindowTargetDay * dimensions.dayWidth) -
          (dimensions.visibleContentWidth * 0.25);
      final teleportScrollPosition = scrollInNewWindow.clamp(
        0.0,
        double.maxFinite,
      );

      // Trigger rebuild, then jumpTo (NO recursive _scrollToDate call!)
      setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _horizontalScrollController.hasClients) {
          // Use jumpTo - instant, no animation, no race conditions
          _horizontalScrollController.jumpTo(teleportScrollPosition);

          // Reset flags after short delay
          _programmaticScrollResetTimer?.cancel();
          _programmaticScrollResetTimer = Timer(
            const Duration(milliseconds: 500),
            () {
              if (mounted) {
                _isProgrammaticScroll = false;
                _teleportTargetStartIndex = null; // TELEPORT complete - reset
              }
            },
          );
        }
      });
      return;
    }
    final scrollPosition = daysSinceStart * dimensions.dayWidth;

    final maxScroll = _horizontalScrollController.position.maxScrollExtent;
    final currentScroll = _horizontalScrollController.offset;
    final visibleWidth = dimensions.visibleContentWidth;

    // PRECISION FIX: Position target date at ~25% from left edge instead of center (50%)
    // Why: Centering formula (scrollPosition - visibleWidth/2) often hits maxScroll
    // when target date is near the end of the windowed range (90 days), causing the
    // date to appear off-center or even off-screen.
    //
    // Old formula: scrollPosition - visibleWidth/2 + dayWidth/2 (center - ~150px offset)
    // New formula: scrollPosition - visibleWidth*0.25 (25% from left - ~75px offset)
    //
    // Benefits:
    // - Less likely to hit maxScroll (smaller offset = more headroom)
    // - Target date is clearly visible near left side
    // - User has context of dates before the target
    // - More predictable positioning across all date ranges
    final targetScroll = (scrollPosition - (visibleWidth * 0.25)).clamp(
      0.0,
      maxScroll,
    );

    // Problem #5 fix: Skip scroll if target is already visible
    // REDUCED THRESHOLD: Changed from visibleWidth/2 to dayWidth*2 for more responsive scrolling
    // Old behavior: Skip if within ~150px (3 days) - too coarse for date picker precision
    // New behavior: Skip only if within ~100px (2 days) - still prevents feedback loop
    // EXCEPTION: forceScroll=true bypasses this (for explicit user date selection via toolbar)
    final scrollDifference = (targetScroll - currentScroll).abs();
    final skipThreshold = dimensions.dayWidth * 2;
    if (scrollDifference < skipThreshold && !isInitialScroll && !forceScroll) {
      return;
    }

    // Set flags before starting scroll
    _isProgrammaticScroll = true;
    _isScrollAnimating = true;

    // CRITICAL FIX: Use jumpTo for initial scroll to show today date IMMEDIATELY
    // animateTo takes time and the widget rebuilds before animation completes,
    // causing _getVisibleDateRange() to use currentScroll (0.0) instead of target
    // Result: user sees start of range (2023-12) instead of today (2025-12)
    if (isInitialScroll) {
      _horizontalScrollController.jumpTo(targetScroll);

      // Immediately complete setup
      _isScrollAnimating = false;
      _isInitialScrolling = false;
      _restoreVerticalScrollPosition();

      // Reset programmatic scroll flag after a short delay
      _programmaticScrollResetTimer?.cancel();
      _programmaticScrollResetTimer = Timer(
        const Duration(milliseconds: 500),
        () {
          if (mounted) {
            _isProgrammaticScroll = false;
          }
        },
      );

      return;
    }

    // For programmatic scrolls (toolbar navigation), use smooth animation
    _horizontalScrollController
        .animateTo(
          targetScroll,
          duration: AppDimensions.animationSlow,
          curve: Curves.easeInOut,
        )
        .then((_) {
          if (mounted) {
            // Restore vertical scroll position if provided (preserves position on toolbar navigation)
            _restoreVerticalScrollPosition();
          }
        })
        .catchError((error) {
          return null;
        })
        .whenComplete(() {
          // Reset animation flag
          _isScrollAnimating = false;
          if (mounted) {
            _programmaticScrollResetTimer?.cancel();
            _programmaticScrollResetTimer = Timer(
              const Duration(milliseconds: 300),
              () {
                if (mounted) {
                  _isProgrammaticScroll = false;
                }
              },
            );
          }
        });
  }

  /// Scroll to a specific month when month header is tapped
  /// SIMPLIFIED: With fixed date range, no more dynamic extension needed
  void _scrollToMonth(DateTime month) {
    if (!_horizontalScrollController.hasClients) {
      return;
    }

    _isProgrammaticScroll = true;
    _isScrollAnimating = true;

    // Target is first day of the month (UTC to match _fixedStartDate)
    final targetDate = DateTime.utc(month.year, month.month);

    // FIX: EXTEND range if target is outside, don't clamp!
    // This allows user to navigate to any month via date picker
    bool rangeExtended = false;
    if (targetDate.isBefore(_fixedStartDate)) {
      _fixedStartDate = DateTime.utc(targetDate.year, targetDate.month);
      rangeExtended = true;
    } else if (targetDate.isAfter(_fixedEndDate)) {
      // Extend to end of target month + 1 month buffer
      _fixedEndDate = DateTime.utc(targetDate.year, targetDate.month + 2);
      rangeExtended = true;
    }

    // If range was extended, we need to trigger a rebuild to update the grid
    if (rangeExtended) {
      // CRITICAL FIX #4: Set _isProgrammaticScroll IMMEDIATELY to prevent feedback loop
      // Without this, _updateVisibleRange() reports current scroll position to parent,
      // parent updates _currentRange to that position, and didUpdateWidget overrides our target
      _isProgrammaticScroll = true;

      // CRITICAL FIX: Invalidate ALL caches so rebuild creates new grid with correct dimensions
      // Without this, cached build returns old (shorter) grid and maxScrollExtent is wrong
      _cachedFullDateRange = null;
      _cachedVisibleDateRange = null;
      _cachedVisibleStartIndex = -1;
      _cachedTimelineContent = null;
      _lastBuildDataHash = null;

      // CRITICAL FIX #2: Set _visibleStartIndex to target date's position BEFORE rebuild
      // Without this, _calculateVisibleStartIndex() uses CURRENT scroll position to build
      // the 90-day window, which is still at the old position (e.g., January when jumping to October)
      final targetDaysSinceStart = targetDate
          .difference(_fixedStartDate)
          .inDays;
      const windowBefore = 30; // Match the value in _calculateVisibleStartIndex
      _visibleStartIndex = (targetDaysSinceStart - windowBefore).clamp(
        0,
        999999,
      );

      // CRITICAL FIX #3: Set flag to force using _visibleStartIndex during rebuild
      // Without this, _calculateVisibleStartIndex() ignores _visibleStartIndex when hasClients=true
      _forceVisibleStartIndex = true;

      // Use setState to trigger rebuild, then scroll in post-frame callback
      setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _scrollToMonth(month);
        }
      });
      return;
    }

    final dimensions = context.timelineDimensionsWithZoom(_zoomScale);
    final daysSinceStart = targetDate.difference(_fixedStartDate).inDays;
    final scrollPosition = daysSinceStart * dimensions.dayWidth;
    final maxScroll = _horizontalScrollController.position.maxScrollExtent;

    // Scroll to show the month at the left edge of the viewport
    final targetScroll = scrollPosition.clamp(0.0, maxScroll);

    _horizontalScrollController
        .animateTo(
          targetScroll,
          duration: AppDimensions.animationSlow,
          curve: Curves.easeInOut,
        )
        .then((_) {
          if (mounted) {
            widget.onVisibleDateRangeChanged?.call(targetDate);
          }
        })
        .catchError((error) {
          return null;
        })
        .whenComplete(() {
          _isScrollAnimating = false;
          if (mounted) {
            _programmaticScrollResetTimer?.cancel();
            _programmaticScrollResetTimer = Timer(
              const Duration(milliseconds: 150),
              () {
                if (mounted) {
                  _isProgrammaticScroll = false;
                }
              },
            );
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
    if (!_horizontalScrollController.hasClients ||
        !_verticalScrollController.hasClients) {
      // Wait for controllers to be ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) scrollToConflict(unitId, conflictDate);
      });
      return;
    }

    final dimensions = context.timelineDimensionsWithZoom(_zoomScale);

    // Scroll horizontally to conflict date
    final daysSinceStart = conflictDate.difference(_fixedStartDate).inDays;
    final horizontalScrollPosition = daysSinceStart * dimensions.dayWidth;
    final maxHorizontalScroll =
        _horizontalScrollController.position.maxScrollExtent;
    final visibleWidth = dimensions.visibleContentWidth;
    final targetHorizontalScroll =
        (horizontalScrollPosition -
                (visibleWidth / 2) +
                (dimensions.dayWidth / 2))
            .clamp(0.0, maxHorizontalScroll);

    // Scroll vertically to unit
    // Get units list to find unit index
    final unitsAsync = ref.read(filteredUnitsProvider);
    if (unitsAsync.isLoading || unitsAsync.value == null) return;

    final units = unitsAsync.value!;
    final unitIndex = units.indexWhere((unit) => unit.id == unitId);
    if (unitIndex < 0) {
      return; // Unit not found
    }

    // Calculate vertical scroll position (each unit row is ~60px tall)
    const unitRowHeight = 60.0;
    final verticalScrollPosition = unitIndex * unitRowHeight;
    final maxVerticalScroll =
        _verticalScrollController.position.maxScrollExtent;
    final visibleHeight =
        MediaQuery.of(context).size.height * 0.7; // Approximate visible height
    final targetVerticalScroll =
        (verticalScrollPosition - (visibleHeight / 2) + (unitRowHeight / 2))
            .clamp(0.0, maxVerticalScroll);

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
    // OPTIMIZATION: Return cached list if available (avoids generating 1460 DateTime objects)
    if (_cachedFullDateRange != null) {
      return _cachedFullDateRange!;
    }

    // SIMPLIFIED: Fixed range is always valid - just return full range
    final days = _fixedEndDate.difference(_fixedStartDate).inDays;
    if (days <= 0) {
      // Fallback in case of invalid initialization
      _initializeDateRange();
      final retryDays = _fixedEndDate.difference(_fixedStartDate).inDays;
      _cachedFullDateRange = List.generate(
        retryDays > 0 ? retryDays : 1460,
        (i) => _fixedStartDate.add(Duration(days: i)),
      );
      return _cachedFullDateRange!;
    }
    _cachedFullDateRange = List.generate(
      days,
      (i) => _fixedStartDate.add(Duration(days: i)),
    );
    return _cachedFullDateRange!;
  }

  /// Get visible date range for rendering (windowed for performance)
  /// Returns dates around current scroll position plus buffer
  ///
  /// KEY INSIGHT: The issue was that booking positions were calculated relative
  /// to the windowed dates list, not the full date range. Fixed by passing
  /// _fixedStartDate to grid so it can calculate absolute positions.
  ///
  /// Problem #3 fix: Memoized to avoid recalculating on every scroll
  List<DateTime> _getVisibleDateRange() {
    final currentStartIndex = _calculateVisibleStartIndex();

    // Return cached value if start index hasn't changed significantly (within 5 days)
    // This prevents excessive rebuilds during smooth scrolling
    if (_cachedVisibleDateRange != null &&
        (_cachedVisibleStartIndex - currentStartIndex).abs() < 5) {
      return _cachedVisibleDateRange!;
    }

    final fullRange = _getDateRange();
    final totalDays = fullRange.length;

    if (totalDays == 0) {
      final now = DateTime.now();
      final fallback = List.generate(
        60,
        (i) => now.subtract(const Duration(days: 30)).add(Duration(days: i)),
      );
      _cachedVisibleDateRange = fallback;
      _cachedVisibleStartIndex = 0;
      return fallback;
    }

    // Window: 30 days before + 60 days after center = 90 days total
    // This is enough for smooth scrolling without rendering 1461 days
    const windowAfter = 60;
    final endIndex = (currentStartIndex + windowAfter + 30).clamp(
      currentStartIndex + 1,
      totalDays,
    );

    final result = fullRange.sublist(currentStartIndex, endIndex);

    // Cache the result
    _cachedVisibleDateRange = result;
    _cachedVisibleStartIndex = currentStartIndex;

    return result;
  }

  /// Calculate visible start index (extracted for memoization)
  int _calculateVisibleStartIndex() {
    final totalDays = _getDateRange().length;

    if (totalDays == 0) return 0;

    // TELEPORT FIX (PRIMARY): If _teleportTargetStartIndex is set, use it unconditionally.
    // This value is set during TELEPORT and persists through ALL rebuilds until
    // TELEPORT completes. This is the most reliable way to ensure correct date range.
    if (_teleportTargetStartIndex != null) {
      final targetIndex = _teleportTargetStartIndex!;
      return targetIndex.clamp(0, totalDays - 1);
    }

    // CRITICAL FIX: When _forceVisibleStartIndex is true, use _visibleStartIndex
    // regardless of whether controller has clients. This is needed when jumping
    // far (e.g., from January to October) - we must build the 90-day window
    // around the TARGET date, not the current scroll position.
    if (_forceVisibleStartIndex) {
      // Reset flag after use - it's a one-time override
      _forceVisibleStartIndex = false;
      return _visibleStartIndex.clamp(0, totalDays - 1);
    }

    // TELEPORT FIX (SECONDARY): During programmatic scroll, keep using _visibleStartIndex
    // to prevent the window from jumping back to old position.
    if (_isProgrammaticScroll) {
      return _visibleStartIndex.clamp(0, totalDays - 1);
    }

    // If controller doesn't have clients yet, use the pre-calculated _visibleStartIndex
    // This ensures the first render uses the correct date range (centered around today)
    if (!_horizontalScrollController.hasClients) {
      return _visibleStartIndex.clamp(0, totalDays - 1);
    }

    // Once controller has clients, calculate based on scroll position
    final dimensions = context.timelineDimensionsWithZoom(_zoomScale);
    final scrollOffset = _horizontalScrollController.offset;
    final centerIndex = (scrollOffset / dimensions.dayWidth).floor();

    const windowBefore = 30;
    return (centerIndex - windowBefore).clamp(0, totalDays - 1);
  }

  /// Get the start index of visible range (for offset calculation)
  /// Uses cached value from _getVisibleDateRange() when available
  int _getVisibleStartIndex() {
    // If we have a cached value from recent _getVisibleDateRange() call, use it
    if (_cachedVisibleStartIndex >= 0) {
      return _cachedVisibleStartIndex;
    }
    // Otherwise calculate fresh
    return _calculateVisibleStartIndex();
  }

  @override
  void dispose() {
    // Cancel timer to prevent callbacks after dispose
    _programmaticScrollResetTimer?.cancel();

    // Reset flags
    _isProgrammaticScroll = false;

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

  Widget _buildEmptyUnitsState(WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Check if owner has ANY units (not just filtered)
    final allUnitsAsync = ref.watch(allOwnerUnitsProvider);
    final hasAnyUnits =
        allUnitsAsync.whenOrNull(data: (units) => units.isNotEmpty) ?? false;

    // If owner has no units at all, redirect to Units page
    if (!hasAnyUnits && !allUnitsAsync.isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spaceL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.meeting_room_outlined,
                  size: 50,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: AppDimensions.spaceM),
              Text(
                l10n.ownerCalendarNoUnits,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.spaceS),
              Text(
                l10n.unitHubNoUnitsInProperty,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.7)
                      : Colors.black.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.spaceL),
              FilledButton.icon(
                onPressed: () => context.go(OwnerRoutes.propertyNew),
                icon: const Icon(Icons.add, size: 20),
                label: Text(l10n.ownerAddFirstProperty),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Owner has units but they are filtered out - show clear filters option
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

  Widget _buildTimelineView(
    List<UnitModel> units,
    Map<String, List<BookingModel>> bookingsByUnit,
  ) {
    // FILTER: Optionally hide units without bookings based on toggle
    // SORT: Ascending order (A-Z) for consistent UX with End Drawer
    final visibleUnits =
        (widget.showEmptyUnits
              ? units
              : units.where((unit) {
                  final bookings = bookingsByUnit[unit.id] ?? [];
                  return bookings.isNotEmpty;
                }).toList())
          ..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );

    final dimensions = context.timelineDimensionsWithZoom(_zoomScale);
    // Use windowed date range for performance (only render ~90 days instead of 1461)
    // The key fix is to calculate booking positions relative to _fixedStartDate,
    // not relative to the windowed dates list
    final dates = _getVisibleDateRange();
    final visibleStartIndex = _getVisibleStartIndex();

    // Problem #7 fix: Memoize build result based on data hash
    // This prevents rebuilding when data hasn't actually changed
    final totalBookings = bookingsByUnit.values.fold<int>(
      0,
      (sum, list) => sum + list.length,
    );
    final dataHash = Object.hash(
      visibleUnits.length,
      totalBookings,
      dates.length,
      dates.isNotEmpty ? dates.first.day : 0,
      dates.isNotEmpty ? dates.first.month : 0,
      (visibleStartIndex * dimensions.dayWidth).round(),
      _zoomScale,
      widget.showSummary, // Include so cache invalidates when summary toggled
    );

    if (_lastBuildDataHash == dataHash && _cachedTimelineContent != null) {
      return _cachedTimelineContent!;
    }

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
      // Use retry dates with offset
      final retryOffset = _getVisibleStartIndex() * dimensions.dayWidth;
      return _buildTimelineContent(
        visibleUnits,
        bookingsByUnit,
        retryDates,
        retryOffset,
        dimensions,
      );
    }

    // Calculate offset for windowed rendering
    // This positions the visible window correctly in the scrollable area
    final offsetWidth = visibleStartIndex * dimensions.dayWidth;

    // Ensure dayWidth is valid
    if (!dimensions.dayWidth.isFinite || dimensions.dayWidth <= 0) {
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

    final result = _buildTimelineContent(
      visibleUnits,
      bookingsByUnit,
      dates,
      offsetWidth,
      dimensions,
    );

    // Cache the result for future calls with same data
    _lastBuildDataHash = dataHash;
    _cachedTimelineContent = result;

    return result;
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
                RepaintBoundary(
                  child: TimelineUnitColumnWidget(
                    units: units,
                    bookingsByUnit: bookingsByUnit,
                    scrollController: _unitNamesScrollController,
                    dimensions: dimensions,
                    onUnitNameTap: widget.onUnitNameTap,
                    onScrollNotification: _handleUnitColumnScroll,
                    showSummarySpacing: widget.showSummary,
                  ),
                ),

                // Scrollable timeline grid with direction lock
                Expanded(
                  child: ScrollConfiguration(
                    // Cross-platform scroll behavior:
                    // - Enables mouse/trackpad drag on desktop
                    // - Removes Android overscroll glow
                    // - Normalizes behavior across all platforms
                    behavior: CalendarScrollBehavior(),
                    child: SingleChildScrollView(
                      controller: _horizontalScrollController,
                      scrollDirection: Axis.horizontal,
                      primary: false,
                      // Custom snap-to-day physics handles ALL scrolling:
                      // - Weak swipes snap to nearest day (no bounce-back)
                      // - Strong swipes snap in velocity direction
                      // - Critically damped spring (no oscillation)
                      physics: TimelineSnapScrollPhysics(
                        dayWidth: dimensions.dayWidth,
                      ),
                      child: SingleChildScrollView(
                        controller: _verticalScrollController,
                        primary: false,
                        child: Column(
                          // FIXED: Restored mainAxisSize.min from working version
                          // This was removed during performance optimization, causing grid to disappear
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            RepaintBoundary(
                              child: TimelineGridWidget(
                                units: units,
                                bookingsByUnit: bookingsByUnit,
                                dates: dates,
                                offsetWidth: offsetWidth,
                                fixedStartDate: _fixedStartDate,
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
                            ),
                            // AnimatedSize ensures smooth appearance/disappearance of summary bar
                            // This prevents the delay issue where summary wouldn't appear
                            // until user scrolled or performed another action
                            AnimatedSize(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeInOut,
                              child: widget.showSummary
                                  ? TimelineSummaryBarWidget(
                                      bookingsByUnit: bookingsByUnit,
                                      dates: dates,
                                      offsetWidth: offsetWidth,
                                      dimensions: dimensions,
                                    )
                                  : const SizedBox.shrink(),
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
      builder: (ctx) => BookingActionBottomSheet(
        booking: booking,
        hasConflict: hasConflict,
        conflictingBookings: conflictingBookings,
      ),
    );

    if (!mounted || action == null) return;

    final l10n = AppLocalizations.of(context);

    switch (action) {
      case 'edit':
        await showDialog<bool>(
          context: context,
          builder: (context) => BookingInlineEditDialog(booking: booking),
        );
      case 'approve':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => const BookingApproveDialog(),
        );
        if (confirmed == true && mounted) {
          try {
            final repository = ref.read(ownerBookingsRepositoryProvider);
            await repository.approveBooking(booking.id);
            if (mounted) {
              ErrorDisplayUtils.showSuccessSnackBar(
                context,
                l10n.ownerBookingsApproved,
              );
              // Invalidate calendar providers to refresh data
              ref.invalidate(timelineCalendarBookingsProvider);
            }
          } catch (e) {
            if (mounted) {
              ErrorDisplayUtils.showErrorSnackBar(
                context,
                e,
                userMessage: l10n.ownerBookingsApproveError,
              );
            }
          }
        }
      case 'reject':
        final reason = await showDialog<String?>(
          context: context,
          builder: (dialogContext) => const BookingRejectDialog(),
        );
        if (reason != null && mounted) {
          try {
            final repository = ref.read(ownerBookingsRepositoryProvider);
            await repository.rejectBooking(
              booking.id,
              reason: reason.isEmpty ? null : reason,
            );
            if (mounted) {
              ErrorDisplayUtils.showWarningSnackBar(
                context,
                l10n.ownerBookingsRejected,
              );
              ref.invalidate(timelineCalendarBookingsProvider);
            }
          } catch (e) {
            if (mounted) {
              ErrorDisplayUtils.showErrorSnackBar(
                context,
                e,
                userMessage: l10n.ownerBookingsRejectError,
              );
            }
          }
        }
      case 'cancel':
        final result = await showDialog<Map<String, dynamic>?>(
          context: context,
          builder: (dialogContext) => const BookingCancelDialog(),
        );
        if (result != null && mounted) {
          try {
            final repository = ref.read(ownerBookingsRepositoryProvider);
            await repository.cancelBooking(
              booking.id,
              result['reason'] as String,
              sendEmail: result['sendEmail'] as bool,
            );
            if (mounted) {
              ErrorDisplayUtils.showWarningSnackBar(
                context,
                l10n.ownerBookingsCancelled,
              );
              ref.invalidate(timelineCalendarBookingsProvider);
            }
          } catch (e) {
            if (mounted) {
              ErrorDisplayUtils.showErrorSnackBar(
                context,
                e,
                userMessage: l10n.ownerBookingsCancelError,
              );
            }
          }
        }
      case 'delete':
        await CalendarBookingActions.deleteBooking(context, ref, booking);
    }
  }

  void _showMoveToUnitMenu(BookingModel booking) async {
    // Store parent context before showing bottom sheet
    // (bottom sheet context becomes invalid after closing)
    final parentContext = context;
    final targetDate = await showModalBottomSheet<DateTime?>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) =>
          BookingMoveToUnitMenu(booking: booking, parentContext: parentContext),
    );

    // If booking was successfully moved, scroll to its new location
    if (targetDate != null && mounted) {
      // Small delay to allow provider refresh to complete
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        _scrollToDate(targetDate, forceScroll: true);
      }
    }
  }
}
