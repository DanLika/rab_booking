import 'package:flutter/material.dart';

/// Device type enum for responsive design
enum DeviceType {
  smallPhone,  // iPhone SE (375px)
  phone,       // Standard iPhone (390-428px)
  tablet,      // iPad (768-1024px)
  desktop,     // Mac/Desktop (1280px+)
}

/// Breakpoint definitions for different device types
class AppBreakpoints {
  // Device width breakpoints
  static const double iphoneSE = 375;      // iPhone SE, iPhone 8
  static const double iphoneStandard = 390; // iPhone 12, 13, 14
  static const double iphonePlus = 428;     // iPhone 14 Plus
  static const double ipad = 768;           // iPad, iPad Air
  static const double ipadPro = 1024;       // iPad Pro
  static const double macBook = 1280;       // MacBook and above
  static const double desktop = 1440;       // Large desktop

  /// Check if current device is a small phone (iPhone SE)
  static bool isSmallPhone(BuildContext context) {
    return MediaQuery.of(context).size.width <= iphoneSE;
  }

  /// Check if current device is any phone size
  static bool isPhone(BuildContext context) {
    return MediaQuery.of(context).size.width < ipad;
  }

  /// Check if current device is a tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= ipad && width < macBook;
  }

  /// Check if current device is desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= macBook;
  }

  /// Get the device type based on screen width
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width <= iphoneSE) return DeviceType.smallPhone;
    if (width < ipad) return DeviceType.phone;
    if (width < macBook) return DeviceType.tablet;
    return DeviceType.desktop;
  }
}

/// Adaptive spacing utility class
/// Provides device-specific spacing values for consistent, responsive layouts
class AdaptiveSpacing {
  final BuildContext context;

  AdaptiveSpacing(this.context);

  /// Horizontal padding (left + right)
  /// iPhone SE: 12, Standard Phone: 16, iPad: 24, Desktop: 40
  double get horizontalPadding {
    switch (AppBreakpoints.getDeviceType(context)) {
      case DeviceType.smallPhone:
        return 12;
      case DeviceType.phone:
        return 16;
      case DeviceType.tablet:
        return 24;
      case DeviceType.desktop:
        return 40;
    }
  }

  /// Vertical padding (top + bottom)
  /// iPhone SE: 12, Standard Phone: 16, iPad: 20, Desktop: 24
  double get verticalPadding {
    switch (AppBreakpoints.getDeviceType(context)) {
      case DeviceType.smallPhone:
        return 12;
      case DeviceType.phone:
        return 16;
      case DeviceType.tablet:
        return 20;
      case DeviceType.desktop:
        return 24;
    }
  }

  /// Section spacing (between major sections)
  /// iPhone SE: 16, Standard Phone: 24, iPad: 32, Desktop: 48
  double get sectionSpacing {
    switch (AppBreakpoints.getDeviceType(context)) {
      case DeviceType.smallPhone:
        return 16;
      case DeviceType.phone:
        return 24;
      case DeviceType.tablet:
        return 32;
      case DeviceType.desktop:
        return 48;
    }
  }

  /// Element spacing (between elements within a section)
  /// iPhone SE: 8, Standard Phone: 12, iPad: 16, Desktop: 20
  double get elementSpacing {
    switch (AppBreakpoints.getDeviceType(context)) {
      case DeviceType.smallPhone:
        return 8;
      case DeviceType.phone:
        return 12;
      case DeviceType.tablet:
        return 16;
      case DeviceType.desktop:
        return 20;
    }
  }

  /// Card padding (inside cards)
  /// iPhone SE: 12, Standard Phone: 16, iPad: 20, Desktop: 24
  double get cardPadding {
    switch (AppBreakpoints.getDeviceType(context)) {
      case DeviceType.smallPhone:
        return 12;
      case DeviceType.phone:
        return 16;
      case DeviceType.tablet:
        return 20;
      case DeviceType.desktop:
        return 24;
    }
  }

  /// Border radius for cards and containers
  /// iPhone SE: 8, Standard Phone: 12, iPad: 16, Desktop: 20
  double get borderRadius {
    switch (AppBreakpoints.getDeviceType(context)) {
      case DeviceType.smallPhone:
        return 8;
      case DeviceType.phone:
        return 12;
      case DeviceType.tablet:
        return 16;
      case DeviceType.desktop:
        return 20;
    }
  }

  /// Content max width for desktop centering
  /// Returns double.infinity for mobile/tablet, 1200 for desktop
  double get contentMaxWidth {
    switch (AppBreakpoints.getDeviceType(context)) {
      case DeviceType.desktop:
        return 1200;
      default:
        return double.infinity;
    }
  }

  /// Icon size
  /// iPhone SE: 20, Standard Phone: 22, iPad: 24, Desktop: 28
  double get iconSize {
    switch (AppBreakpoints.getDeviceType(context)) {
      case DeviceType.smallPhone:
        return 20;
      case DeviceType.phone:
        return 22;
      case DeviceType.tablet:
        return 24;
      case DeviceType.desktop:
        return 28;
    }
  }

  /// Small icon size (for compact layouts)
  /// iPhone SE: 16, Standard Phone: 18, iPad: 20, Desktop: 22
  double get smallIconSize {
    switch (AppBreakpoints.getDeviceType(context)) {
      case DeviceType.smallPhone:
        return 16;
      case DeviceType.phone:
        return 18;
      case DeviceType.tablet:
        return 20;
      case DeviceType.desktop:
        return 22;
    }
  }

  /// Button height
  /// iPhone SE: 44, Standard Phone: 48, iPad: 52, Desktop: 56
  double get buttonHeight {
    switch (AppBreakpoints.getDeviceType(context)) {
      case DeviceType.smallPhone:
        return 44;
      case DeviceType.phone:
        return 48;
      case DeviceType.tablet:
        return 52;
      case DeviceType.desktop:
        return 56;
    }
  }

  /// Get responsive value with device-specific overrides
  double responsive({
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    switch (AppBreakpoints.getDeviceType(context)) {
      case DeviceType.smallPhone:
      case DeviceType.phone:
        return mobile;
      case DeviceType.tablet:
        return tablet ?? mobile * 1.5;
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile * 2;
    }
  }

  /// Get responsive integer value
  int responsiveInt({
    required int mobile,
    int? tablet,
    int? desktop,
  }) {
    switch (AppBreakpoints.getDeviceType(context)) {
      case DeviceType.smallPhone:
      case DeviceType.phone:
        return mobile;
      case DeviceType.tablet:
        return tablet ?? (mobile * 1.5).round();
      case DeviceType.desktop:
        return desktop ?? tablet ?? (mobile * 2);
    }
  }
}

/// Extension for easy access to AdaptiveSpacing
extension AdaptiveSpacingExtension on BuildContext {
  AdaptiveSpacing get spacing => AdaptiveSpacing(this);
}

/// Adaptive typography utility class
/// Provides device-specific text styles for consistent typography across devices
class AdaptiveTypography {
  final BuildContext context;

  AdaptiveTypography(this.context);

  /// Title text style (large headings)
  /// iPhone SE: 22, Standard Phone: 24, iPad: 28, Desktop: 32
  TextStyle get title {
    final fontSize = context.spacing.responsive(
      mobile: 22,
      tablet: 28,
      desktop: 32,
    );
    return TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
      height: 1.2,
    );
  }

  /// Subtitle text style (section headings)
  /// iPhone SE: 18, Standard Phone: 19, iPad: 20, Desktop: 22
  TextStyle get subtitle {
    final fontSize = context.spacing.responsive(
      mobile: 18,
      tablet: 20,
      desktop: 22,
    );
    return TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      height: 1.3,
    );
  }

  /// Body text style (main content)
  /// iPhone SE: 14, Standard Phone: 15, iPad: 15, Desktop: 16
  TextStyle get body {
    final fontSize = context.spacing.responsive(
      mobile: 14,
      tablet: 15,
      desktop: 16,
    );
    return TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.normal,
      height: 1.5,
    );
  }

  /// Caption text style (small descriptions)
  /// iPhone SE: 12, Standard Phone: 12, iPad: 13, Desktop: 14
  TextStyle get caption {
    final fontSize = context.spacing.responsive(
      mobile: 12,
      tablet: 13,
      desktop: 14,
    );
    return TextStyle(
      fontSize: fontSize,
      color: Colors.grey.shade600,
      height: 1.4,
    );
  }

  /// Small text style (very small text)
  /// iPhone SE: 11, Standard Phone: 11, iPad: 12, Desktop: 13
  TextStyle get small {
    final fontSize = context.spacing.responsive(
      mobile: 11,
      tablet: 12,
      desktop: 13,
    );
    return TextStyle(
      fontSize: fontSize,
      color: Colors.grey.shade600,
      height: 1.3,
    );
  }

  /// Button text style
  /// iPhone SE: 15, Standard Phone: 16, iPad: 17, Desktop: 18
  TextStyle get button {
    final fontSize = context.spacing.responsive(
      mobile: 15,
      tablet: 17,
      desktop: 18,
    );
    return TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      height: 1.2,
    );
  }
}

/// Extension for easy access to AdaptiveTypography
extension AdaptiveTypographyExtension on BuildContext {
  AdaptiveTypography get typography => AdaptiveTypography(this);
}

/// Common adaptive widgets

/// Adaptive container with automatic padding
class AdaptiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? color;
  final Decoration? decoration;

  const AdaptiveContainer({
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.decoration,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ??
          EdgeInsets.symmetric(
            horizontal: context.spacing.horizontalPadding,
            vertical: context.spacing.verticalPadding,
          ),
      margin: margin,
      color: decoration == null ? color : null,
      decoration: decoration,
      child: child,
    );
  }
}

/// Adaptive card with automatic styling
class AdaptiveCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  final EdgeInsets? padding;
  final VoidCallback? onTap;

  const AdaptiveCard({
    required this.child,
    this.color,
    this.padding,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final card = Card(
      elevation: context.spacing.responsive(mobile: 1, tablet: 2, desktop: 3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.spacing.borderRadius),
      ),
      color: color,
      child: Padding(
        padding: padding ?? EdgeInsets.all(context.spacing.cardPadding),
        child: child,
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(context.spacing.borderRadius),
        child: card,
      );
    }

    return card;
  }
}

/// Adaptive section spacing
class SectionDivider extends StatelessWidget {
  const SectionDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: context.spacing.sectionSpacing);
  }
}

/// Adaptive element spacing
class ElementDivider extends StatelessWidget {
  const ElementDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: context.spacing.elementSpacing);
  }
}
