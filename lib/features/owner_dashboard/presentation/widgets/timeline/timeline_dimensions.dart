import 'package:flutter/material.dart';
import '../../../utils/calendar_grid_calculator.dart';
import 'timeline_constants.dart';

/// Timeline dimension calculator
/// Provides responsive dimension calculations for the timeline calendar
/// Uses CalendarGridCalculator for consistency across calendar views
class TimelineDimensions {
  final BuildContext context;
  final double zoomScale;

  const TimelineDimensions({
    required this.context,
    this.zoomScale = kTimelineDefaultZoomScale,
  });

  /// Screen width from MediaQuery
  double get screenWidth {
    final mediaQuery = MediaQuery.maybeOf(context);
    if (mediaQuery == null) {
      // Fallback to a reasonable default if MediaQuery is not available
      return 1200.0;
    }
    final width = mediaQuery.size.width;
    // Ensure width is finite and positive
    if (!width.isFinite || width <= 0) {
      return 1200.0; // Fallback to reasonable default
    }
    return width;
  }

  /// Text scale factor for accessibility
  double get textScaleFactor {
    final mediaQuery = MediaQuery.maybeOf(context);
    if (mediaQuery == null) {
      return 1.0; // Default scale factor
    }
    return mediaQuery.textScaler.scale(1.0);
  }

  /// Whether the current theme is dark mode
  bool get isDarkMode => Theme.of(context).brightness == Brightness.dark;

  /// Day cell width (with zoom applied)
  double get dayWidth {
    final width = screenWidth;
    // Ensure we have a valid width before calculating
    if (!width.isFinite || width <= 0) {
      return 50.0 * zoomScale; // Fallback to reasonable default
    }

    final visibleDays = CalendarGridCalculator.getOptimalVisibleDays(width);
    final baseWidth = CalendarGridCalculator.getDayCellWidth(
      width,
      visibleDays,
      textScaleFactor: textScaleFactor,
    );

    // Ensure baseWidth is valid
    if (!baseWidth.isFinite || baseWidth <= 0) {
      return 50.0 * zoomScale; // Fallback to reasonable default
    }

    final result = baseWidth * zoomScale;
    // Ensure result is valid
    if (!result.isFinite || result <= 0) {
      return 50.0 * zoomScale; // Fallback to reasonable default
    }
    return result;
  }

  /// Unit row height (base height without stacking)
  double get unitRowHeight {
    final width = screenWidth;
    if (!width.isFinite || width <= 0) {
      return 60.0; // Fallback to reasonable default
    }
    final height = CalendarGridCalculator.getRowHeight(
      width,
      textScaleFactor: textScaleFactor,
    );
    // Ensure height is valid
    if (!height.isFinite || height <= 0) {
      return 60.0; // Fallback to reasonable default
    }
    return height;
  }

  /// Unit column width (left sidebar)
  double get unitColumnWidth {
    final width = screenWidth;
    if (!width.isFinite || width <= 0) {
      return 200.0; // Fallback to reasonable default
    }
    final columnWidth = CalendarGridCalculator.getRowHeaderWidth(
      width,
      textScaleFactor: textScaleFactor,
    );
    // Ensure columnWidth is valid
    if (!columnWidth.isFinite || columnWidth <= 0) {
      return 200.0; // Fallback to reasonable default
    }
    return columnWidth;
  }

  /// Total header height (month + day headers)
  double get headerHeight {
    if (screenWidth < kTimelineMobileBreakpoint) {
      return kTimelineMobileHeaderHeight;
    } else if (screenWidth < kTimelineTabletBreakpoint) {
      return kTimelineTabletHeaderHeight;
    } else {
      return kTimelineDesktopHeaderHeight;
    }
  }

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
    final baseHeight = unitRowHeight;
    final result = (baseHeight * stackCount) + kTimelineStackedRowPadding;
    // Ensure result is valid
    if (!result.isFinite || result <= 0) {
      return 60.0 * stackCount + kTimelineStackedRowPadding; // Fallback
    }
    return result;
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
