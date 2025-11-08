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

  // Common text styles
  static TextStyle heading({Color? color}) => TextStyle(
        fontSize: fontSizeXXXL,
        fontWeight: bold,
        height: lineHeightTight,
        letterSpacing: letterSpacingTight,
        color: color,
      );

  static TextStyle subheading({Color? color}) => TextStyle(
        fontSize: fontSizeXXL,
        fontWeight: semiBold,
        height: lineHeightNormal,
        letterSpacing: letterSpacingNormal,
        color: color,
      );

  static TextStyle body({Color? color}) => TextStyle(
        fontSize: fontSizeL,
        fontWeight: regular,
        height: lineHeightNormal,
        letterSpacing: letterSpacingNormal,
        color: color,
      );

  static TextStyle bodyMedium({Color? color}) => TextStyle(
        fontSize: fontSizeL,
        fontWeight: medium,
        height: lineHeightNormal,
        letterSpacing: letterSpacingNormal,
        color: color,
      );

  static TextStyle caption({Color? color}) => TextStyle(
        fontSize: fontSizeM,
        fontWeight: regular,
        height: lineHeightNormal,
        letterSpacing: letterSpacingNormal,
        color: color,
      );

  static TextStyle label({Color? color}) => TextStyle(
        fontSize: fontSizeS,
        fontWeight: medium,
        height: lineHeightNormal,
        letterSpacing: letterSpacingWide,
        color: color,
      );

  static TextStyle button({Color? color}) => TextStyle(
        fontSize: fontSizeL,
        fontWeight: semiBold,
        height: lineHeightNormal,
        letterSpacing: letterSpacingWide,
        color: color,
      );
}
