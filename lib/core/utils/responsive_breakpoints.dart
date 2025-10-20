import 'package:flutter/material.dart';

/// Enhanced responsive breakpoints system
/// Supports mobile, tablet, desktop, and ultra-wide screens
class ResponsiveBreakpoints {
  ResponsiveBreakpoints._();

  // Breakpoint values (in logical pixels)
  static const double mobileSmall = 320; // Small phones
  static const double mobileMedium = 375; // Standard phones
  static const double mobileLarge = 414; // Large phones
  static const double tablet = 768; // Tablets
  static const double desktop = 1024; // Small laptops/desktops
  static const double desktopLarge = 1440; // Standard desktops
  static const double desktopXL = 1920; // Large desktops
  static const double desktop4K = 2560; // 4K screens

  /// Get current device type
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width < tablet) {
      return DeviceType.mobile;
    } else if (width < desktop) {
      return DeviceType.tablet;
    } else if (width < desktopXL) {
      return DeviceType.desktop;
    } else {
      return DeviceType.ultraWide;
    }
  }

  /// Check if device is mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < tablet;
  }

  /// Check if device is tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= tablet && width < desktop;
  }

  /// Check if device is desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktop;
  }

  /// Check if device is ultra-wide
  static bool isUltraWide(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopXL;
  }

  /// Get responsive value based on device type
  /// Example: getResponsiveValue(context, mobile: 12, tablet: 16, desktop: 20)
  static T getResponsiveValue<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
    T? ultraWide,
  }) {
    final deviceType = getDeviceType(context);

    switch (deviceType) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
      case DeviceType.ultraWide:
        return ultraWide ?? desktop ?? tablet ?? mobile;
    }
  }

  /// Get column count for grid layouts
  static int getGridColumns(BuildContext context) {
    return getResponsiveValue(
      context,
      mobile: 1,
      tablet: 2,
      desktop: 3,
      ultraWide: 4,
    );
  }

  /// Get horizontal padding based on screen size
  /// Aligned with responsive_utils.dart for consistency
  static double getHorizontalPadding(BuildContext context) {
    return getResponsiveValue(
      context,
      mobile: 16.0,
      tablet: 24.0,    // Changed from 32 to match responsive_utils
      desktop: 32.0,   // Changed from 48 to match responsive_utils
      ultraWide: 48.0, // Changed from 64 to be progressive
    );
  }

  /// Get content max width (for readability)
  static double getContentMaxWidth(BuildContext context) {
    return getResponsiveValue(
      context,
      mobile: double.infinity,
      tablet: 768.0,
      desktop: 1200.0,
      ultraWide: 1440.0,
    );
  }

  /// Get font size scale factor
  static double getFontScaleFactor(BuildContext context) {
    return getResponsiveValue(
      context,
      mobile: 1.0,
      tablet: 1.1,
      desktop: 1.15,
      ultraWide: 1.2,
    );
  }

  /// Get spacing scale factor
  static double getSpacingFactor(BuildContext context) {
    return getResponsiveValue(
      context,
      mobile: 1.0,
      tablet: 1.25,
      desktop: 1.5,
      ultraWide: 1.75,
    );
  }

  /// Check device orientation
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }
}

/// Device type enum
enum DeviceType {
  mobile,
  tablet,
  desktop,
  ultraWide,
}

/// Responsive builder widget
/// Automatically rebuilds when screen size changes
class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({
    required this.mobile,
    this.tablet,
    this.desktop,
    this.ultraWide,
    super.key,
  });

  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  final Widget? ultraWide;

  @override
  Widget build(BuildContext context) {
    final deviceType = ResponsiveBreakpoints.getDeviceType(context);

    switch (deviceType) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
      case DeviceType.ultraWide:
        return ultraWide ?? desktop ?? tablet ?? mobile;
    }
  }
}

/// Responsive value builder
/// Returns different values based on screen size
class ResponsiveValue<T> extends StatelessWidget {
  const ResponsiveValue({
    required this.mobile,
    this.tablet,
    this.desktop,
    this.ultraWide,
    required this.builder,
    super.key,
  });

  final T mobile;
  final T? tablet;
  final T? desktop;
  final T? ultraWide;
  final Widget Function(BuildContext context, T value) builder;

  @override
  Widget build(BuildContext context) {
    final value = ResponsiveBreakpoints.getResponsiveValue(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
      ultraWide: ultraWide,
    );

    return builder(context, value);
  }
}

/// Responsive grid system
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    required this.children,
    this.mobileColumns = 1,
    this.tabletColumns = 2,
    this.desktopColumns = 3,
    this.ultraWideColumns = 4,
    this.spacing = 16.0,
    this.runSpacing,
    super.key,
  });

  final List<Widget> children;
  final int mobileColumns;
  final int tabletColumns;
  final int desktopColumns;
  final int ultraWideColumns;
  final double spacing;
  final double? runSpacing;

  @override
  Widget build(BuildContext context) {
    final columns = ResponsiveBreakpoints.getResponsiveValue(
      context,
      mobile: mobileColumns,
      tablet: tabletColumns,
      desktop: desktopColumns,
      ultraWide: ultraWideColumns,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing ?? spacing,
          children: children.map((child) {
            return SizedBox(
              width: itemWidth,
              child: child,
            );
          }).toList(),
        );
      },
    );
  }
}

/// Responsive padding
class ResponsivePadding extends StatelessWidget {
  const ResponsivePadding({
    required this.child,
    this.mobile = 16.0,
    this.tablet = 32.0,
    this.desktop = 48.0,
    this.ultraWide = 64.0,
    super.key,
  });

  final Widget child;
  final double mobile;
  final double tablet;
  final double desktop;
  final double ultraWide;

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveBreakpoints.getResponsiveValue(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
      ultraWide: ultraWide,
    );

    return Padding(
      padding: EdgeInsets.all(padding),
      child: child,
    );
  }
}

/// Responsive container with max width
/// Centers content on large screens for better readability
class ResponsiveContainer extends StatelessWidget {
  const ResponsiveContainer({
    required this.child,
    this.maxWidth,
    this.padding,
    super.key,
  });

  final Widget child;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final effectiveMaxWidth = maxWidth ?? ResponsiveBreakpoints.getContentMaxWidth(context);

    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
        padding: padding,
        child: child,
      ),
    );
  }
}

/// Extension on BuildContext for easy access to responsive utilities
extension ResponsiveContextExtension on BuildContext {
  DeviceType get deviceType => ResponsiveBreakpoints.getDeviceType(this);

  bool get isMobileDevice => ResponsiveBreakpoints.isMobile(this);
  bool get isTabletDevice => ResponsiveBreakpoints.isTablet(this);
  bool get isDesktopDevice => ResponsiveBreakpoints.isDesktop(this);
  bool get isUltraWideDevice => ResponsiveBreakpoints.isUltraWide(this);

  bool get isPortraitOrientation => ResponsiveBreakpoints.isPortrait(this);
  bool get isLandscapeOrientation => ResponsiveBreakpoints.isLandscape(this);

  int get gridColumns => ResponsiveBreakpoints.getGridColumns(this);
  double get horizontalPadding => ResponsiveBreakpoints.getHorizontalPadding(this);
  double get contentMaxWidth => ResponsiveBreakpoints.getContentMaxWidth(this);
  double get fontScaleFactor => ResponsiveBreakpoints.getFontScaleFactor(this);
  double get spacingFactor => ResponsiveBreakpoints.getSpacingFactor(this);

  /// Get responsive spacing between elements (aligned with responsive_utils.dart)
  /// Mobile: 8px, Tablet: 12px, Desktop: 16px, Ultra-wide: 20px
  double get spacing => responsive<double>(
    mobile: 8.0,
    tablet: 12.0,
    desktop: 16.0,
    ultraWide: 20.0,
  );

  /// Get responsive section spacing (aligned with responsive_utils.dart)
  /// Mobile: 24px, Tablet: 32px, Desktop: 48px, Ultra-wide: 64px
  double get sectionSpacing => responsive<double>(
    mobile: 24.0,
    tablet: 32.0,
    desktop: 48.0,
    ultraWide: 64.0,
  );

  T responsive<T>({
    required T mobile,
    T? tablet,
    T? desktop,
    T? ultraWide,
  }) {
    return ResponsiveBreakpoints.getResponsiveValue(
      this,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
      ultraWide: ultraWide,
    );
  }
}
