import 'package:flutter/material.dart';
import 'timeline_constants.dart';

/// Timeline dimension calculator
/// Uses FIXED dimensions for all devices to ensure consistent booking block
/// positioning. Wider screens show more days, not bigger cells.
class TimelineDimensions {
  final BuildContext context;
  final double zoomScale;

  /// Fixed cell dimensions — same on mobile, tablet, and desktop.
  /// Based on mobile 360px breakpoint values for maximum compatibility.
  static const double _fixedDayWidth = 50.0;
  static const double _fixedRowHeight = 42.0;
  static const double _fixedColumnWidth = 100.0;
  static const double _fixedHeaderHeight = 60.0;

  const TimelineDimensions({
    required this.context,
    this.zoomScale = kTimelineDefaultZoomScale,
  });

  /// Screen width from MediaQuery
  double get screenWidth {
    final mediaQuery = MediaQuery.maybeOf(context);
    if (mediaQuery == null) return 1200.0;
    final width = mediaQuery.size.width;
    if (!width.isFinite || width <= 0) return 1200.0;
    return width;
  }

  /// Whether the current theme is dark mode
  bool get isDarkMode => Theme.of(context).brightness == Brightness.dark;

  /// Day cell width (with zoom applied) — FIXED for all devices
  double get dayWidth => _fixedDayWidth * zoomScale;

  /// Unit row height — FIXED for all devices
  double get unitRowHeight => _fixedRowHeight;

  /// Unit column width (left sidebar) — FIXED for all devices
  double get unitColumnWidth => _fixedColumnWidth;

  /// Total header height (month + day headers) — FIXED for all devices
  double get headerHeight => _fixedHeaderHeight;

  /// Month header height (35% of total header)
  double get monthHeaderHeight => headerHeight * kTimelineMonthHeaderProportion;

  /// Day header height (65% of total header)
  double get dayHeaderHeight => headerHeight * kTimelineDayHeaderProportion;

  /// Visible content width (screen minus unit column)
  double get visibleContentWidth {
    final width = screenWidth;
    final column = unitColumnWidth;
    final result = width - column;
    // Ensure result is valid
    if (!result.isFinite || result <= 0) {
      return 1000.0; // Fallback to reasonable default
    }
    return result;
  }

  /// Calculate dynamic row height based on stack count
  /// Includes vertical padding for booking blocks (top + bottom)
  double getStackedRowHeight(int stackCount) {
    return (unitRowHeight * stackCount) + kTimelineStackedRowPadding;
  }

  /// Calculate number of days visible in viewport
  int get daysInViewport {
    final contentWidth = visibleContentWidth;
    final dayW = dayWidth;
    if (!contentWidth.isFinite ||
        contentWidth <= 0 ||
        !dayW.isFinite ||
        dayW <= 0) {
      return 30; // Fallback to reasonable default
    }
    return (contentWidth / dayW).ceil().clamp(
      1,
      365,
    ); // Clamp to reasonable range
  }

  /// Calculate offset width for windowing
  double getOffsetWidth(int visibleStartIndex) {
    return visibleStartIndex * dayWidth;
  }

  /// Create a copy with different zoom scale
  TimelineDimensions withZoom(double newZoomScale) {
    return TimelineDimensions(
      context: context,
      zoomScale: newZoomScale.clamp(
        kTimelineMinZoomScale,
        kTimelineMaxZoomScale,
      ),
    );
  }
}

/// Extension for easy access via BuildContext
extension TimelineDimensionsExtension on BuildContext {
  /// Get timeline dimensions with default zoom
  TimelineDimensions get timelineDimensions =>
      TimelineDimensions(context: this);

  /// Get timeline dimensions with custom zoom
  TimelineDimensions timelineDimensionsWithZoom(double zoomScale) {
    return TimelineDimensions(context: this, zoomScale: zoomScale);
  }
}
