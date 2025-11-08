import 'package:flutter/material.dart';

/// Calendar grid dimension calculator
/// Handles responsive sizing for Week and Month calendar grids
class CalendarGridCalculator {
  /// Breakpoints for responsive design
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;

  /// Row header width (room name column)
  static const double mobileRowHeaderWidth = 100;
  static const double tabletRowHeaderWidth = 150;
  static const double desktopRowHeaderWidth = 200;

  /// Row height (each room row)
  static const double mobileRowHeight = 56; // Increased from 48 for better touch targets
  static const double tabletRowHeight = 60;
  static const double desktopRowHeight = 64;

  /// Day cell width (each day column)
  static const double mobileDayCellWidth = 90; // Increased from 80 for better touch targets
  static const double tabletDayCellWidth = 100;
  static const double desktopDayCellWidth = 120;

  /// Header height (date headers row)
  static const double headerHeight = 60;

  /// Minimum touch target size (for mobile accessibility)
  static const double minTouchTargetSize = 44;

  /// Get row header width based on screen width and text scale factor
  static double getRowHeaderWidth(double screenWidth, {double textScaleFactor = 1.0}) {
    double baseWidth;

    if (screenWidth < mobileBreakpoint) {
      baseWidth = mobileRowHeaderWidth;
    } else if (screenWidth < tabletBreakpoint) {
      baseWidth = tabletRowHeaderWidth;
    } else {
      baseWidth = desktopRowHeaderWidth;
    }

    // Adjust for text scaling (accessibility)
    // Clamp to avoid extreme values (Android accessibility can go up to 2.0)
    return baseWidth * textScaleFactor.clamp(0.8, 1.5);
  }

  /// Get row height based on screen width and text scale factor
  static double getRowHeight(double screenWidth, {double textScaleFactor = 1.0}) {
    double baseHeight;

    if (screenWidth < mobileBreakpoint) {
      baseHeight = mobileRowHeight;
    } else if (screenWidth < tabletBreakpoint) {
      baseHeight = tabletRowHeight;
    } else {
      baseHeight = desktopRowHeight;
    }

    // Adjust for text scaling (accessibility)
    // Ensure minimum touch target size is maintained
    final adjustedHeight = baseHeight * textScaleFactor.clamp(0.8, 1.5);
    return adjustedHeight.clamp(minTouchTargetSize, double.infinity);
  }

  /// Get day cell width based on screen width, number of days, and text scale factor
  static double getDayCellWidth(
    double screenWidth,
    int numberOfDays, {
    double textScaleFactor = 1.0,
  }) {
    double baseWidth;

    if (screenWidth < mobileBreakpoint) {
      baseWidth = mobileDayCellWidth;
    } else if (screenWidth < tabletBreakpoint) {
      baseWidth = tabletDayCellWidth;
    } else {
      baseWidth = desktopDayCellWidth;
    }

    // Adjust base width for text scaling
    baseWidth = baseWidth * textScaleFactor.clamp(0.8, 1.5);

    // For desktop, if there's extra space, distribute it across days
    if (screenWidth >= tabletBreakpoint) {
      final rowHeaderWidth = getRowHeaderWidth(screenWidth, textScaleFactor: textScaleFactor);
      final availableWidth = screenWidth - rowHeaderWidth - 32; // 32 for padding
      final calculatedWidth = availableWidth / numberOfDays;

      // Use calculated width if it's larger than base, but cap at reasonable max
      if (calculatedWidth > baseWidth) {
        return calculatedWidth.clamp(baseWidth, 200);
      }
    }

    return baseWidth;
  }

  /// Calculate total grid width for horizontal scrolling
  static double getTotalGridWidth(double screenWidth, int numberOfDays) {
    final rowHeaderWidth = getRowHeaderWidth(screenWidth);
    final dayCellWidth = getDayCellWidth(screenWidth, numberOfDays);
    return rowHeaderWidth + (dayCellWidth * numberOfDays);
  }

  /// Calculate booking block position and width
  /// Returns Rect with x, y, width, height for booking block
  static Rect calculateBookingBlockRect({
    required DateTime gridStartDate,
    required DateTime bookingStartDate,
    required DateTime bookingEndDate,
    required int rowIndex,
    required double dayCellWidth,
    required double rowHeight,
    required double rowHeaderWidth,
  }) {
    // Calculate start day offset
    final startDayOffset =
        bookingStartDate.difference(gridStartDate).inDays.toDouble();

    // Calculate number of days (booking duration)
    final numberOfDays =
        bookingEndDate.difference(bookingStartDate).inDays.toDouble();

    // X position (offset from left, including row header)
    final x = rowHeaderWidth + (startDayOffset * dayCellWidth);

    // Y position (row index)
    final y = rowIndex * rowHeight;

    // Width (number of days * cell width)
    final width = numberOfDays * dayCellWidth;

    // Height (full row height with some padding)
    final height = rowHeight - 8; // 4px padding top and bottom

    return Rect.fromLTWH(x, y, width, height);
  }

  /// Check if booking is visible in current grid date range
  static bool isBookingVisible({
    required DateTime gridStartDate,
    required DateTime gridEndDate,
    required DateTime bookingStartDate,
    required DateTime bookingEndDate,
  }) {
    // Booking is visible if it overlaps with grid date range
    return bookingStartDate.isBefore(gridEndDate) &&
        bookingEndDate.isAfter(gridStartDate);
  }

  /// Calculate month view dimensions
  /// Month view shows 28-31 days, needs different calculations
  static double getMonthGridWidth(double screenWidth, int daysInMonth) {
    final rowHeaderWidth = getRowHeaderWidth(screenWidth);
    final dayCellWidth = getDayCellWidth(screenWidth, daysInMonth);
    return rowHeaderWidth + (dayCellWidth * daysInMonth);
  }

  /// Calculate week view dimensions
  /// Week view shows exactly 7 days (Monday-Sunday)
  static double getWeekGridWidth(double screenWidth) {
    final rowHeaderWidth = getRowHeaderWidth(screenWidth);
    final dayCellWidth = getDayCellWidth(screenWidth, 7);
    return rowHeaderWidth + (dayCellWidth * 7);
  }

  /// Get screen size category
  static ScreenSizeCategory getScreenSizeCategory(double screenWidth) {
    if (screenWidth < mobileBreakpoint) {
      return ScreenSizeCategory.mobile;
    } else if (screenWidth < tabletBreakpoint) {
      return ScreenSizeCategory.tablet;
    } else {
      return ScreenSizeCategory.desktop;
    }
  }

  /// Get font size for date headers with accessibility scaling
  static double getDateHeaderFontSize(double screenWidth, {double textScaleFactor = 1.0}) {
    double baseFontSize;

    if (screenWidth < mobileBreakpoint) {
      baseFontSize = 12;
    } else if (screenWidth < tabletBreakpoint) {
      baseFontSize = 14;
    } else {
      baseFontSize = 16;
    }

    // MediaQuery.textScaleFactor is already applied by Flutter to Text widgets
    // But we can return the base size knowing Flutter will apply the scaling
    // If manual scaling is needed (e.g., for custom painters), apply it here
    return baseFontSize;
  }

  /// Get font size for room names with accessibility scaling
  static double getRoomNameFontSize(double screenWidth, {double textScaleFactor = 1.0}) {
    double baseFontSize;

    if (screenWidth < mobileBreakpoint) {
      baseFontSize = 13;
    } else if (screenWidth < tabletBreakpoint) {
      baseFontSize = 14;
    } else {
      baseFontSize = 15;
    }

    // Flutter automatically applies textScaleFactor to Text widgets
    return baseFontSize;
  }

  /// Get icon size for room capacity indicators with accessibility scaling
  static double getRoomIconSize(double screenWidth, {double textScaleFactor = 1.0}) {
    double baseIconSize;

    if (screenWidth < mobileBreakpoint) {
      baseIconSize = 16;
    } else if (screenWidth < tabletBreakpoint) {
      baseIconSize = 18;
    } else {
      baseIconSize = 20;
    }

    // Icons should scale slightly with text for accessibility
    return baseIconSize * textScaleFactor.clamp(0.9, 1.2);
  }
}

/// Screen size categories for responsive design
enum ScreenSizeCategory {
  mobile,
  tablet,
  desktop,
}

extension ScreenSizeCategoryX on ScreenSizeCategory {
  bool get isMobile => this == ScreenSizeCategory.mobile;
  bool get isTablet => this == ScreenSizeCategory.tablet;
  bool get isDesktop => this == ScreenSizeCategory.desktop;

  /// Get horizontal padding for calendar grid
  double get horizontalPadding {
    switch (this) {
      case ScreenSizeCategory.mobile:
        return 8;
      case ScreenSizeCategory.tablet:
        return 16;
      case ScreenSizeCategory.desktop:
        return 24;
    }
  }

  /// Get vertical padding for calendar grid
  double get verticalPadding {
    switch (this) {
      case ScreenSizeCategory.mobile:
        return 8;
      case ScreenSizeCategory.tablet:
        return 12;
      case ScreenSizeCategory.desktop:
        return 16;
    }
  }
}
