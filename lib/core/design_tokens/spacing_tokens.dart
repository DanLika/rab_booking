import 'package:flutter/widgets.dart';
import 'responsive_breakpoints.dart';

/// Spacing design tokens for consistent spacing across the widget
class SpacingTokens {
  // Base spacing values
  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double xs2 = 6.0;  // Between xs and s
  static const double s = 8.0;
  static const double s2 = 12.0; // Between s and m
  static const double m = 16.0;
  static const double m2 = 20.0; // Between m and l
  static const double l = 24.0;
  static const double xl = 32.0;
  static const double xl2 = 40.0;  // Between xl and xxl
  static const double xxl = 48.0;
  static const double xxl2 = 56.0; // Between xxl and xxxl
  static const double xxxl = 64.0;

  // Responsive spacing for widget container
  static double widgetPadding(BuildContext context) {
    return ResponsiveBreakpoints.responsive<double>(
      context,
      mobile: m,
      tablet: l,
      desktop: l,
    );
  }

  // Responsive spacing for calendar margins
  static double calendarMargin(BuildContext context) {
    return ResponsiveBreakpoints.responsive<double>(
      context,
      mobile: m,
      tablet: l,
      desktop: l,
    );
  }

  // Spacing between calendar and other elements
  static double calendarGap(BuildContext context) {
    return ResponsiveBreakpoints.responsive<double>(
      context,
      mobile: m,
      tablet: l,
      desktop: l,
    );
  }

  // Spacing between sections (calendar, form, summary)
  static double sectionGap(BuildContext context) {
    return ResponsiveBreakpoints.responsive<double>(
      context,
      mobile: l,
      tablet: xl,
      desktop: xl,
    );
  }

  // Calendar cell spacing/gap
  static double calendarCellGap(BuildContext context) {
    return ResponsiveBreakpoints.responsive<double>(
      context,
      mobile: xs,
      tablet: s,
      desktop: s,
    );
  }

  // Responsive calendar cell size for month view
  static double monthCalendarCellSize(BuildContext context) {
    final width = ResponsiveBreakpoints.getWidth(context);

    if (ResponsiveBreakpoints.isMobile(context)) {
      // Mobile: optimal size (currently good)
      return (width - (m * 2) - (calendarCellGap(context) * 6)) / 7;
    } else if (ResponsiveBreakpoints.isTablet(context)) {
      // Tablet: medium cells
      return 56.0;
    } else {
      // Desktop: smaller cells (was too big)
      return 48.0;
    }
  }

  // Responsive calendar cell size for year view
  static double yearCalendarCellSize(BuildContext context) {
    if (ResponsiveBreakpoints.isMobile(context)) {
      // Mobile: bigger cells (was too small)
      return 32.0;
    } else if (ResponsiveBreakpoints.isTablet(context)) {
      // Tablet: medium cells
      return 28.0;
    } else {
      // Desktop: optimal size (currently good)
      return 24.0;
    }
  }

  // Card padding
  static double cardPadding(BuildContext context) {
    return ResponsiveBreakpoints.responsive<double>(
      context,
      mobile: m,
      tablet: l,
      desktop: l,
    );
  }

  // Form field spacing
  static const double formFieldGap = m;

  // Button padding
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: l,
    vertical: m,
  );

  // Consistent EdgeInsets helpers
  static EdgeInsets allXS = const EdgeInsets.all(xs);
  static EdgeInsets allS = const EdgeInsets.all(s);
  static EdgeInsets allM = const EdgeInsets.all(m);
  static EdgeInsets allL = const EdgeInsets.all(l);
  static EdgeInsets allXL = const EdgeInsets.all(xl);

  static EdgeInsets horizontalM = const EdgeInsets.symmetric(horizontal: m);
  static EdgeInsets horizontalL = const EdgeInsets.symmetric(horizontal: l);
  static EdgeInsets verticalM = const EdgeInsets.symmetric(vertical: m);
  static EdgeInsets verticalL = const EdgeInsets.symmetric(vertical: l);
}
