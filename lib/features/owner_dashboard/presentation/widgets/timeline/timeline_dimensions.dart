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
  double get screenWidth => MediaQuery.of(context).size.width;

  /// Text scale factor for accessibility
  double get textScaleFactor => MediaQuery.textScalerOf(context).scale(1.0);

  /// Whether the current theme is dark mode
  bool get isDarkMode => Theme.of(context).brightness == Brightness.dark;

  /// Day cell width (with zoom applied)
  double get dayWidth {
    final visibleDays = CalendarGridCalculator.getOptimalVisibleDays(
      screenWidth,
    );
    final baseWidth = CalendarGridCalculator.getDayCellWidth(
      screenWidth,
      visibleDays,
      textScaleFactor: textScaleFactor,
    );
    return baseWidth * zoomScale;
  }

  /// Unit row height (base height without stacking)
  double get unitRowHeight {
    return CalendarGridCalculator.getRowHeight(
      screenWidth,
      textScaleFactor: textScaleFactor,
    );
  }

  /// Unit column width (left sidebar)
  double get unitColumnWidth {
    return CalendarGridCalculator.getRowHeaderWidth(
      screenWidth,
      textScaleFactor: textScaleFactor,
    );
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
  double get visibleContentWidth => screenWidth - unitColumnWidth;

  /// Calculate dynamic row height based on stack count
  /// Includes vertical padding for booking blocks (top + bottom)
  double getStackedRowHeight(int stackCount) {
    return (unitRowHeight * stackCount) + kTimelineStackedRowPadding;
  }

  /// Calculate number of days visible in viewport
  int get daysInViewport => (visibleContentWidth / dayWidth).ceil();

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
