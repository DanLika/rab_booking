import 'package:flutter/material.dart';

/// Responsive calendar layout helper
/// Determines which layout to use based on screen size and orientation
class ResponsiveCalendarLayout {
  /// Breakpoints (same as CalendarGridCalculator)
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;

  /// Get responsive layout mode based on context
  static CalendarLayoutMode getLayoutMode(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final orientation = MediaQuery.of(context).orientation;

    if (width < mobileBreakpoint) {
      return orientation == Orientation.portrait
          ? CalendarLayoutMode.mobilePortrait
          : CalendarLayoutMode.mobileLandscape;
    } else if (width < tabletBreakpoint) {
      return CalendarLayoutMode.tablet;
    } else {
      return CalendarLayoutMode.desktop;
    }
  }

  /// Check if device is mobile (iOS or Android)
  static bool isMobileDevice(BuildContext context) {
    final platform = Theme.of(context).platform;
    return platform == TargetPlatform.iOS || platform == TargetPlatform.android;
  }

  /// Check if device is web
  static bool isWeb(BuildContext context) {
    return Theme.of(context).platform == TargetPlatform.macOS ||
        Theme.of(context).platform == TargetPlatform.linux ||
        Theme.of(context).platform == TargetPlatform.windows;
  }

  /// Get recommended booking list view mode (card or table)
  static BookingListViewMode getRecommendedBookingListView(
    BuildContext context,
  ) {
    final mode = getLayoutMode(context);

    switch (mode) {
      case CalendarLayoutMode.mobilePortrait:
      case CalendarLayoutMode.mobileLandscape:
        return BookingListViewMode.card; // Mobile always cards
      case CalendarLayoutMode.tablet:
        return BookingListViewMode.card; // Tablet uses cards
      case CalendarLayoutMode.desktop:
        return BookingListViewMode.table; // Desktop uses table
    }
  }

  /// Check if calendar should enable horizontal scroll
  static bool shouldEnableHorizontalScroll(BuildContext context) {
    final mode = getLayoutMode(context);
    return mode == CalendarLayoutMode.mobilePortrait ||
        mode == CalendarLayoutMode.mobileLandscape;
  }

  /// Check if calendar should enable pinch-to-zoom
  static bool shouldEnablePinchZoom(BuildContext context) {
    return isMobileDevice(context);
  }

  /// Get recommended number of visible days for week view
  static int getVisibleDaysForWeek(BuildContext context) {
    final mode = getLayoutMode(context);

    switch (mode) {
      case CalendarLayoutMode.mobilePortrait:
        return 5; // Show 5 days on mobile portrait
      case CalendarLayoutMode.mobileLandscape:
        return 7; // Show full week on mobile landscape
      case CalendarLayoutMode.tablet:
      case CalendarLayoutMode.desktop:
        return 7; // Always show full week on larger screens
    }
  }

  /// Get sidebar width for filters/legend
  static double getSidebarWidth(BuildContext context) {
    final mode = getLayoutMode(context);

    switch (mode) {
      case CalendarLayoutMode.mobilePortrait:
      case CalendarLayoutMode.mobileLandscape:
        return 0; // No sidebar on mobile (use bottom sheet instead)
      case CalendarLayoutMode.tablet:
        return 280;
      case CalendarLayoutMode.desktop:
        return 320;
    }
  }

  /// Check if filters should be displayed in drawer/bottom sheet
  static bool shouldUseDrawerForFilters(BuildContext context) {
    final mode = getLayoutMode(context);
    return mode == CalendarLayoutMode.mobilePortrait ||
        mode == CalendarLayoutMode.mobileLandscape;
  }

  /// Get app bar height
  static double getAppBarHeight(BuildContext context) {
    return kToolbarHeight;
  }

  /// Get bottom navigation bar height (if applicable)
  static double getBottomNavHeight(BuildContext context) {
    return isMobileDevice(context) ? 56 : 0;
  }

  /// Calculate available calendar height
  static double getAvailableCalendarHeight(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final padding = MediaQuery.of(context).padding;
    final appBarHeight = getAppBarHeight(context);
    final bottomNavHeight = getBottomNavHeight(context);

    return screenHeight -
        appBarHeight -
        bottomNavHeight -
        padding.top -
        padding.bottom;
  }

  /// Get dialog width for booking dialogs
  static double getDialogWidth(BuildContext context) {
    final mode = getLayoutMode(context);

    switch (mode) {
      case CalendarLayoutMode.mobilePortrait:
      case CalendarLayoutMode.mobileLandscape:
        return MediaQuery.of(context).size.width * 0.9; // 90% of screen width
      case CalendarLayoutMode.tablet:
        return 500;
      case CalendarLayoutMode.desktop:
        return 600;
    }
  }

  /// Get maximum dialog height
  static double getMaxDialogHeight(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return screenHeight * 0.85; // 85% of screen height
  }

  /// Check if booking details should use full-screen dialog
  static bool shouldUseFullscreenDialog(BuildContext context) {
    final mode = getLayoutMode(context);
    return mode == CalendarLayoutMode.mobilePortrait;
  }

  /// Get grid horizontal padding
  static double getGridHorizontalPadding(BuildContext context) {
    final mode = getLayoutMode(context);

    switch (mode) {
      case CalendarLayoutMode.mobilePortrait:
      case CalendarLayoutMode.mobileLandscape:
        return 8;
      case CalendarLayoutMode.tablet:
        return 16;
      case CalendarLayoutMode.desktop:
        return 24;
    }
  }

  /// Get grid vertical padding
  static double getGridVerticalPadding(BuildContext context) {
    final mode = getLayoutMode(context);

    switch (mode) {
      case CalendarLayoutMode.mobilePortrait:
      case CalendarLayoutMode.mobileLandscape:
        return 8;
      case CalendarLayoutMode.tablet:
        return 12;
      case CalendarLayoutMode.desktop:
        return 16;
    }
  }
}

/// Calendar layout modes
enum CalendarLayoutMode {
  mobilePortrait,
  mobileLandscape,
  tablet,
  desktop,
}

/// Booking list view modes
enum BookingListViewMode {
  card,
  table,
}

extension CalendarLayoutModeX on CalendarLayoutMode {
  bool get isMobile =>
      this == CalendarLayoutMode.mobilePortrait ||
      this == CalendarLayoutMode.mobileLandscape;

  bool get isTablet => this == CalendarLayoutMode.tablet;

  bool get isDesktop => this == CalendarLayoutMode.desktop;

  bool get isPortrait => this == CalendarLayoutMode.mobilePortrait;

  bool get isLandscape => this == CalendarLayoutMode.mobileLandscape;
}
