import 'package:flutter/material.dart';
import '../../../../shared/widgets/animations/animated_content_switcher.dart';
import '../../../../shared/widgets/animations/skeleton_loader.dart';
import 'calendar_view_switcher.dart';

/// Lazy-loading wrapper for CalendarViewSwitcher.
///
/// Shows a skeleton loader immediately on first render, then loads the
/// actual calendar after a short delay. This improves perceived performance
/// by showing visual feedback instantly while heavy calendar components load.
///
/// ## Usage
/// ```dart
/// LazyCalendarContainer(
///   propertyId: 'abc123',
///   unitId: 'xyz789',
///   onRangeSelected: (start, end) => ...,
/// )
/// ```
///
/// ## How it works
/// 1. First frame: Shows CalendarSkeleton immediately
/// 2. After 100ms: Triggers rebuild with real CalendarViewSwitcher
/// 3. Calendar data loads via realtime stream providers
///
/// This approach separates "show something" from "load data",
/// giving users instant visual feedback while Flutter loads heavy widgets.
class LazyCalendarContainer extends StatefulWidget {
  final String propertyId;
  final String unitId;
  final Function(DateTime? start, DateTime? end)? onRangeSelected;
  final bool forceMonthView;

  const LazyCalendarContainer({
    super.key,
    required this.propertyId,
    required this.unitId,
    this.onRangeSelected,
    this.forceMonthView = false,
  });

  @override
  State<LazyCalendarContainer> createState() => _LazyCalendarContainerState();
}

class _LazyCalendarContainerState extends State<LazyCalendarContainer> {
  bool _isCalendarReady = false;

  @override
  void initState() {
    super.initState();
    // Delay calendar loading to let skeleton render first
    // This allows the UI shell to paint immediately
    _scheduleCalendarLoad();
  }

  @override
  void didUpdateWidget(LazyCalendarContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // HYBRID LOADING: Re-check when IDs change from empty to valid
    if (!_isCalendarReady &&
        (widget.propertyId != oldWidget.propertyId ||
            widget.unitId != oldWidget.unitId)) {
      _scheduleCalendarLoad();
    }
  }

  void _scheduleCalendarLoad() {
    // Only load calendar when we have valid IDs
    // This prevents Firestore queries with empty IDs
    if (widget.propertyId.isEmpty || widget.unitId.isEmpty) {
      return; // Stay in skeleton mode until IDs are available
    }

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted && widget.propertyId.isNotEmpty && widget.unitId.isNotEmpty) {
        setState(() => _isCalendarReady = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isReady = _isCalendarReady &&
        widget.propertyId.isNotEmpty &&
        widget.unitId.isNotEmpty;

    // Animated crossfade between skeleton and calendar
    return AnimatedContentSwitcher(
      showContent: isReady,
      skeleton: const CalendarSkeleton(),
      content: isReady
          ? CalendarViewSwitcher(
              propertyId: widget.propertyId,
              unitId: widget.unitId,
              onRangeSelected: widget.onRangeSelected,
              forceMonthView: widget.forceMonthView,
            )
          : const SizedBox.shrink(),
    );
  }
}
