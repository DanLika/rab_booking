import 'package:flutter/widgets.dart';
import 'responsive_breakpoints.dart';

/// Typography design tokens for consistent text styles across the widget
class TypographyTokens {
  // Font families
  static const String primaryFont = 'Inter';
  static const List<String> fontFallback = [
    'Inter',
    '-apple-system',
    'BlinkMacSystemFont',
    'Segoe UI',
    'Roboto',
    'Helvetica Neue',
    'Arial',
    'sans-serif',
  ];

  // Font weights
  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;

  // Base font sizes
  static const double fontSizeXS = 10.0;
  static const double fontSizeXS2 = 11.0;   // Between XS and S
  static const double fontSizeS = 12.0;
  static const double fontSizeS2 = 13.0;    // Between S and M
  static const double fontSizeM = 14.0;
  static const double fontSizeM2 = 15.0;    // Between M and L
  static const double fontSizeL = 16.0;
  static const double fontSizeXL = 18.0;
  static const double fontSizeXXL = 20.0;
  static const double fontSizeXXXL = 24.0;
  static const double fontSizeHuge = 26.0;  // Extra large headings

  // Line heights (as multipliers)
  static const double lineHeightTight = 1.2;
  static const double lineHeightNormal = 1.5;
  static const double lineHeightRelaxed = 1.75;

  // Letter spacing
  static const double letterSpacingTight = -0.5;
  static const double letterSpacingNormal = 0.0;
  static const double letterSpacingWide = 0.5;

  // Responsive heading size
  static double headingSize(BuildContext context) {
    return ResponsiveBreakpoints.responsive<double>(
      context,
      mobile: fontSizeXXL,
      tablet: fontSizeXXXL,
      desktop: fontSizeXXXL,
    );
  }

  // Responsive subheading size
  static double subheadingSize(BuildContext context) {
    return ResponsiveBreakpoints.responsive<double>(
      context,
      mobile: fontSizeXL,
      tablet: fontSizeXXL,
      desktop: fontSizeXXL,
    );
  }

  // Responsive body size
  static double bodySize(BuildContext context) {
    return ResponsiveBreakpoints.responsive<double>(
      context,
      mobile: fontSizeM,
      tablet: fontSizeL,
      desktop: fontSizeL,
    );
  }

  // Responsive caption size
  static double captionSize(BuildContext context) {
    return ResponsiveBreakpoints.responsive<double>(
      context,
      mobile: fontSizeS,
      tablet: fontSizeM,
      desktop: fontSizeM,
    );
  }

  // Calendar day number size
  static double calendarDaySize(BuildContext context) {
    if (ResponsiveBreakpoints.isMobile(context)) {
      return fontSizeM;
    } else {
      return fontSizeM;
    }
  }

  // Calendar price size (smaller than day number)
  static double calendarPriceSize(BuildContext context) {
    return fontSizeXS;
  }

  // Powered by badge size (very small)
  static const double poweredBySize = 9.0;

  // --- CACHED COMPILE-TIME CONSTANT TEXT STYLES ---
  // By caching the base text styles as compile-time constants (`const`),
  // we ensure they are created only once during compilation, not at runtime.
  // The `copyWith` method is then used to efficiently apply dynamic properties
  // like color. This is the most performant approach for static styles.

  static const TextStyle _heading = TextStyle(
    fontSize: fontSizeXXXL,
    fontWeight: bold,
    height: lineHeightTight,
    letterSpacing: letterSpacingTight,
  );
  static TextStyle heading({Color? color}) => _heading.copyWith(color: color);

  static const TextStyle _subheading = TextStyle(
    fontSize: fontSizeXXL,
    fontWeight: semiBold,
    height: lineHeightNormal,
    letterSpacing: letterSpacingNormal,
  );
  static TextStyle subheading({Color? color}) =>
      _subheading.copyWith(color: color);

  static const TextStyle _body = TextStyle(
    fontSize: fontSizeL,
    fontWeight: regular,
    height: lineHeightNormal,
    letterSpacing: letterSpacingNormal,
  );
  static TextStyle body({Color? color}) => _body.copyWith(color: color);

  static const TextStyle _bodyMedium = TextStyle(
    fontSize: fontSizeL,
    fontWeight: medium,
    height: lineHeightNormal,
    letterSpacing: letterSpacingNormal,
  );
  static TextStyle bodyMedium({Color? color}) =>
      _bodyMedium.copyWith(color: color);

  static const TextStyle _caption = TextStyle(
    fontSize: fontSizeM,
    fontWeight: regular,
    height: lineHeightNormal,
    letterSpacing: letterSpacingNormal,
  );
  static TextStyle caption({Color? color}) => _caption.copyWith(color: color);

  static const TextStyle _label = TextStyle(
    fontSize: fontSizeS,
    fontWeight: medium,
    height: lineHeightNormal,
    letterSpacing: letterSpacingWide,
  );
  static TextStyle label({Color? color}) => _label.copyWith(color: color);

  static const TextStyle _button = TextStyle(
    fontSize: fontSizeL,
    fontWeight: semiBold,
    height: lineHeightNormal,
    letterSpacing: letterSpacingWide,
  );
  static TextStyle button({Color? color}) => _button.copyWith(color: color);
}
