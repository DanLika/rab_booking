import 'package:flutter/material.dart';
import '../../../core/constants/breakpoints.dart';

/// Calendar grid dimension calculator
/// Handles responsive sizing for Week and Month calendar grids
class CalendarGridCalculator {
  /// Breakpoints for responsive design - use centralized constants
  static const double mobileBreakpoint = Breakpoints.calendarMobile;
  static const double tabletBreakpoint = Breakpoints.calendarTablet;

  /// Row header width bounds (room name column)
  static const double minRowHeaderWidth = 100;
  static const double maxRowHeaderWidth = 250;

  /// Row header percentage of screen width
  static const double mobileRowHeaderPercent = 0.25; // 25% on mobile
  static const double tabletRowHeaderPercent = 0.20; // 20% on tablet
  static const double desktopRowHeaderPercent = 0.15; // 15% on desktop

  /// Row height (each room row) - reduced by 25% for compact view
  static const double mobileRowHeight = 42;
  static const double tabletRowHeight = 46;
  static const double desktopRowHeight = 51;

  /// Day cell width bounds (each day column) - reduced by 25% for compact view
  static const double mobileDayCellMinWidth = 49;
  static const double mobileDayCellMaxWidth = 68;
  static const double desktopDayCellMinWidth = 52;
  static const double desktopDayCellMaxWidth = 75;

  /// Header height (date headers row)
  static const double mobileHeaderHeight = 48;
  static const double tabletHeaderHeight = 54;
  static const double desktopHeaderHeight = 60;

  /// Minimum touch target size (for mobile accessibility)
  static const double minTouchTargetSize = 44;

  /// Get header height based on screen width
  static double getHeaderHeight(double screenWidth) {
    if (screenWidth < mobileBreakpoint) {
      return mobileHeaderHeight;
    } else if (screenWidth < tabletBreakpoint) {
      return tabletHeaderHeight;
    } else {
      return desktopHeaderHeight;
    }
  }

  /// Get row header width based on screen width and text scale factor
  /// Dynamically calculated as percentage of screen width with bounds
  static double getRowHeaderWidth(
    double screenWidth, {
    double textScaleFactor = 1.0,
  }) {
    double percentageWidth;

    if (screenWidth < mobileBreakpoint) {
      percentageWidth = screenWidth * mobileRowHeaderPercent;
    } else if (screenWidth < tabletBreakpoint) {
      percentageWidth = screenWidth * tabletRowHeaderPercent;
    } else {
      percentageWidth = screenWidth * desktopRowHeaderPercent;
    }

    // Apply text scale factor for accessibility
    percentageWidth = percentageWidth * textScaleFactor.clamp(0.8, 1.5);

    // Clamp to min/max bounds
    return percentageWidth.clamp(minRowHeaderWidth, maxRowHeaderWidth);
  }

  /// Get row height based on screen width and text scale factor
  static double getRowHeight(
    double screenWidth, {
    double textScaleFactor = 1.0,
  }) {
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
  /// Dynamically calculated as (availableWidth / visibleDays) with bounds
  static double getDayCellWidth(
    double screenWidth,
    int numberOfDays, {
    double textScaleFactor = 1.0,
  }) {
    // Calculate available width for day cells
    final rowHeaderWidth = getRowHeaderWidth(
      screenWidth,
      textScaleFactor: textScaleFactor,
    );
    final availableWidth = screenWidth - rowHeaderWidth - 32; // 32 for padding

    // Calculate width per day
    double calculatedWidth = availableWidth / numberOfDays;

    // Apply bounds based on screen size
    double minWidth;
    double maxWidth;

    if (screenWidth < mobileBreakpoint) {
      minWidth = mobileDayCellMinWidth;
      maxWidth = mobileDayCellMaxWidth;
    } else {
      minWidth = desktopDayCellMinWidth;
      maxWidth = desktopDayCellMaxWidth;
    }

    // Apply text scale factor for accessibility
    calculatedWidth = calculatedWidth * textScaleFactor.clamp(0.8, 1.5);

    // Clamp to bounds
    return calculatedWidth.clamp(minWidth, maxWidth);
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
    final startDayOffset = bookingStartDate
        .difference(gridStartDate)
        .inDays
        .toDouble();

    // Calculate number of days (booking duration)
    final numberOfDays = bookingEndDate
        .difference(bookingStartDate)
        .inDays
        .toDouble();

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
  static double getDateHeaderFontSize(
    double screenWidth, {
    double textScaleFactor = 1.0,
  }) {
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
  static double getRoomNameFontSize(
    double screenWidth, {
    double textScaleFactor = 1.0,
  }) {
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
  static double getRoomIconSize(
    double screenWidth, {
    double textScaleFactor = 1.0,
  }) {
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

  /// Get font size for booking guest name
  static double getBookingGuestNameFontSize(double screenWidth) {
    if (screenWidth < mobileBreakpoint) {
      return 11;
    } else if (screenWidth < tabletBreakpoint) {
      return 12;
    } else {
      return 13;
    }
  }

  /// Get font size for booking metadata (dates, icons, etc.)
  static double getBookingMetadataFontSize(double screenWidth) {
    if (screenWidth < mobileBreakpoint) {
      return 9;
    } else if (screenWidth < tabletBreakpoint) {
      return 10;
    } else {
      return 11;
    }
  }

  /// Get icon size for booking block icons
  static double getBookingIconSize(double screenWidth) {
    if (screenWidth < mobileBreakpoint) {
      return 11;
    } else if (screenWidth < tabletBreakpoint) {
      return 12;
    } else {
      return 13;
    }
  }

  /// Get padding for booking blocks (horizontal and vertical)
  static EdgeInsets getBookingPadding(double screenWidth) {
    if (screenWidth < mobileBreakpoint) {
      return const EdgeInsets.symmetric(horizontal: 4, vertical: 4);
    } else if (screenWidth < tabletBreakpoint) {
      return const EdgeInsets.symmetric(horizontal: 5, vertical: 5);
    } else {
      return const EdgeInsets.symmetric(horizontal: 6, vertical: 6);
    }
  }

  /// Get optimal number of visible days based on screen width
  /// Mobile: 6-8 days, Tablet: 10-16 days, Desktop: 20-35 days
  static int getOptimalVisibleDays(double screenWidth) {
    final rowHeaderWidth = getRowHeaderWidth(screenWidth);
    final availableWidth = screenWidth - rowHeaderWidth - 32; // 32 for padding

    if (screenWidth < mobileBreakpoint) {
      // Mobile: Calculate how many days fit using max cell width, minimum 6, maximum 8
      final fittingDays = (availableWidth / mobileDayCellMaxWidth).floor();
      return fittingDays.clamp(6, 8);
    } else if (screenWidth < tabletBreakpoint) {
      // Tablet: Calculate how many days fit, minimum 10, maximum 16
      final fittingDays = (availableWidth / desktopDayCellMaxWidth).floor();
      return fittingDays.clamp(10, 16);
    } else {
      // Desktop: Calculate how many days fit using max cell width, minimum 20, maximum 35
      final fittingDays = (availableWidth / desktopDayCellMaxWidth).floor();
      return fittingDays.clamp(20, 35);
    }
  }

  /// Get visible days range for timeline view
  /// Returns number of days to show based on screen size
  static int getTimelineVisibleDays(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return getOptimalVisibleDays(screenWidth);
  }
}

/// Screen size categories for responsive design
enum ScreenSizeCategory { mobile, tablet, desktop }

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
