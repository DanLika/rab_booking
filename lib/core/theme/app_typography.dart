import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Application typography configuration
/// Using Playfair Display for headings and Inter for body text
class AppTypography {
  AppTypography._(); // Private constructor

  // ============================================================================
  // FONT FAMILIES
  // ============================================================================

  /// Heading font - Playfair Display (elegant serif for titles)
  static String get headingFont => GoogleFonts.playfairDisplay().fontFamily!;

  /// Body font - Inter (clean sans-serif for readability)
  static String get bodyFont => GoogleFonts.inter().fontFamily!;

  // ============================================================================
  // FONT WEIGHT SCALE (Enhanced with lighter weights for premium feel)
  // ============================================================================

  /// Thin weight (100) - For decorative large display text
  static const FontWeight weightThin = FontWeight.w100;

  /// Extra light weight (200) - For dramatic hero text, premium feel
  static const FontWeight weightExtraLight = FontWeight.w200;

  /// Light weight (300) - For subtle emphasis, elegant subheadings
  static const FontWeight weightLight = FontWeight.w300;

  /// Regular weight (400) - Default for body text
  static const FontWeight weightRegular = FontWeight.w400;

  /// Medium weight (500) - For slight emphasis
  static const FontWeight weightMedium = FontWeight.w500;

  /// Semibold weight (600) - For strong emphasis, buttons
  static const FontWeight weightSemibold = FontWeight.w600;

  /// Bold weight (700) - For headings, important text
  static const FontWeight weightBold = FontWeight.w700;

  /// Extrabold weight (800) - For maximum impact
  static const FontWeight weightExtrabold = FontWeight.w800;

  /// Black weight (900) - For ultra-bold display
  static const FontWeight weightBlack = FontWeight.w900;

  // ============================================================================
  // LETTER SPACING SCALE
  // ============================================================================

  /// Tight letter spacing (-0.5px) - For large display text
  static const double letterSpacingTight = -0.5;

  /// Slightly tight (-0.25px) - For headings
  static const double letterSpacingSlightlyTight = -0.25;

  /// Normal letter spacing (0px) - Default
  static const double letterSpacingNormal = 0.0;

  /// Relaxed letter spacing (0.15px) - For readability
  static const double letterSpacingRelaxed = 0.15;

  /// Wide letter spacing (0.5px) - For buttons, labels
  static const double letterSpacingWide = 0.5;

  /// Extra wide (1.0px) - For emphasis, small caps
  static const double letterSpacingExtraWide = 1.0;

  /// Ultra wide (1.5px) - For overline, uppercase
  static const double letterSpacingUltraWide = 1.5;

  // ============================================================================
  // LINE HEIGHT SCALE
  // ============================================================================

  /// Tight line height (1.1) - For display text
  static const double lineHeightTight = 1.1;

  /// Snug line height (1.2) - For headings
  static const double lineHeightSnug = 1.2;

  /// Normal line height (1.5) - For body text
  static const double lineHeightNormal = 1.5;

  /// Relaxed line height (1.6) - For comfortable reading
  static const double lineHeightRelaxed = 1.6;

  /// Loose line height (2.0) - For extra breathing room
  static const double lineHeightLoose = 2.0;

  // ============================================================================
  // TEXT THEME
  // ============================================================================

  /// Complete text theme for the app
  static TextTheme get textTheme {
    return TextTheme(
      // Display styles (H1 - largest text for hero sections) - ENHANCED for drama
      // Desktop: 72px, Tablet: 56px, Mobile: 40px (responsive handled in components)
      displayLarge: GoogleFonts.playfairDisplay(
        fontSize: 72, // Increased from 48px for more impact
        fontWeight: FontWeight.w700,
        letterSpacing: -1.0, // Tighter for large text
        height: 1.1, // Tighter leading
      ),
      // H2 - Major section headers - ENHANCED
      // Desktop: 48px, Tablet: 40px, Mobile: 32px
      displayMedium: GoogleFonts.playfairDisplay(
        fontSize: 48, // Increased from 36px
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.15,
      ),
      // H3 - Section headers - ENHANCED
      // Desktop: 32px, Tablet: 28px, Mobile: 24px
      displaySmall: GoogleFonts.playfairDisplay(
        fontSize: 32, // Increased from 24px
        fontWeight: FontWeight.w700,
        letterSpacing: -0.25,
        height: 1.2,
      ),

      // Headline styles (card titles, subsections)
      headlineLarge: GoogleFonts.playfairDisplay(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.25,
      ),
      headlineMedium: GoogleFonts.playfairDisplay(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.29,
      ),
      headlineSmall: GoogleFonts.playfairDisplay(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.33,
      ),

      // Title styles (list items, dialog titles)
      titleLarge: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.27,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        height: 1.5,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        height: 1.43,
      ),

      // Body styles (main content) - Body: 16px
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        height: 1.5,
      ),
      // Caption: 14px
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        height: 1.43,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        height: 1.33,
      ),

      // Label styles (buttons, tabs, form labels)
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        height: 1.43,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        height: 1.33,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        height: 1.45,
      ),
    );
  }

  // ============================================================================
  // SHORTCUT GETTERS (for common styles from textTheme)
  // ============================================================================

  /// H1 - Largest heading (shortcut to displayLarge)
  static TextStyle get h1 => textTheme.displayLarge!;

  /// H2 - Major section heading (shortcut to displayMedium)
  static TextStyle get h2 => textTheme.displayMedium!;

  /// H3 - Section heading (shortcut to displaySmall)
  static TextStyle get h3 => textTheme.displaySmall!;

  /// Display small text (direct access to displaySmall)
  static TextStyle get displaySmall => textTheme.displaySmall!;

  // NOTE: Legacy aliases below - these names are misleading but kept for backwards compatibility.
  // bodyMedium returns bodyLarge (16px), bodyLarge returns titleLarge (22px), bodySmall returns bodyMedium (14px)
  // Consider using textTheme directly or semantic names like `paragraph`, `sectionTitle` for new code.

  /// @Deprecated('Use textTheme.bodyLarge instead - this naming is confusing')
  /// Legacy alias: Returns 16px body text (actually textTheme.bodyLarge)
  static TextStyle get bodyMedium => textTheme.bodyLarge!;

  /// @Deprecated('Use textTheme.titleLarge instead - this naming is confusing')
  /// Legacy alias: Returns 22px title text (actually textTheme.titleLarge)
  static TextStyle get bodyLarge => textTheme.titleLarge!;

  /// @Deprecated('Use textTheme.bodyMedium instead - this naming is confusing')
  /// Legacy alias: Returns 14px body text (actually textTheme.bodyMedium)
  static TextStyle get bodySmall => textTheme.bodyMedium!;

  // ============================================================================
  // CUSTOM TEXT STYLES
  // ============================================================================

  /// Hero title style (for landing page) - ENHANCED for dramatic impact
  /// Desktop: 96px, Tablet: 72px, Mobile: 56px (responsive handled in components)
  static TextStyle get heroTitle => GoogleFonts.playfairDisplay(
    fontSize: 96, // Increased from 56px for desktop drama
    fontWeight: FontWeight.w700,
    letterSpacing: -1.5, // Tighter tracking for large text
    height: 1.0, // Tighter leading for impact
  );

  /// Hero subtitle style - Enhanced for better readability
  static TextStyle get heroSubtitle => GoogleFonts.inter(
    fontSize: 24, // Increased from 20px for better hierarchy
    fontWeight: FontWeight.w300, // Lighter weight for elegance
    letterSpacing: 0.25,
    height: 1.5,
  );

  /// Property card title
  static TextStyle get propertyCardTitle => GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.4,
  );

  /// Property card subtitle (location)
  static TextStyle get propertyCardSubtitle => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    height: 1.43,
  );

  /// Price text style
  static TextStyle get priceText => GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    height: 1.33,
  );

  /// Price label style (per night, total, etc.)
  static TextStyle get priceLabel => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    height: 1.43,
  );

  /// Button text style - 16px (semi-bold)
  static TextStyle get buttonText => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600, // Semi-bold
    letterSpacing: 0.5,
    height: 1.25,
  );

  /// Caption text (image captions, footnotes)
  static TextStyle get caption => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.33,
  );

  /// Overline text (labels, categories)
  static TextStyle get overline => GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.5,
    height: 1.6,
  ).copyWith(textBaseline: TextBaseline.alphabetic);

  // ============================================================================
  // PREMIUM TEXT STYLES (additional custom styles)
  // ============================================================================

  /// Large display text (for marketing headlines)
  static TextStyle get displayXL => GoogleFonts.playfairDisplay(
    fontSize: 64,
    fontWeight: weightExtrabold,
    letterSpacing: letterSpacingTight,
    height: lineHeightTight,
  );

  /// Subheading style (section intros, card descriptions)
  static TextStyle get subheading => GoogleFonts.inter(
    fontSize: 18,
    fontWeight: weightRegular,
    letterSpacing: letterSpacingRelaxed,
    height: lineHeightRelaxed,
  );

  /// Lead paragraph style (intro paragraphs, important text)
  static TextStyle get lead => GoogleFonts.inter(
    fontSize: 18,
    fontWeight: weightRegular,
    letterSpacing: letterSpacingNormal,
    height: lineHeightRelaxed,
  );

  /// Small text (disclaimers, fine print)
  static TextStyle get small => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: weightRegular,
    letterSpacing: letterSpacingNormal,
    height: lineHeightNormal,
  );

  /// Tiny text (timestamps, metadata)
  static TextStyle get tiny => GoogleFonts.inter(
    fontSize: 10,
    fontWeight: weightRegular,
    letterSpacing: letterSpacingNormal,
    height: lineHeightNormal,
  );

  /// Badge text style (notification badges, status badges)
  static TextStyle get badge => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: weightSemibold,
    letterSpacing: letterSpacingWide,
    height: 1.0,
  );

  /// Link text style (clickable links)
  static TextStyle get link => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: weightMedium,
    letterSpacing: letterSpacingNormal,
    height: lineHeightNormal,
    decoration: TextDecoration.underline,
  );

  /// Error text style (validation messages)
  static TextStyle get errorText => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: weightRegular,
    letterSpacing: letterSpacingNormal,
    height: lineHeightNormal,
  );

  /// Helper text style (input hints, help text)
  static TextStyle get helperText => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: weightRegular,
    letterSpacing: letterSpacingRelaxed,
    height: lineHeightNormal,
  );

  /// Label text style (form labels, small headings)
  static TextStyle get label => GoogleFonts.inter(
    fontSize: 13,
    fontWeight: weightMedium,
    letterSpacing: letterSpacingWide,
    height: lineHeightNormal,
  );

  /// Quote text style (testimonials, blockquotes) - ENHANCED with italic elegance
  /// Note: PlayfairDisplay doesn't have light weights, using Regular (400)
  static TextStyle get quote => GoogleFonts.playfairDisplay(
    fontSize: 24, // Increased from 20px for more impact
    fontWeight: weightRegular, // PlayfairDisplay min weight is 400
    letterSpacing: letterSpacingNormal,
    height: lineHeightRelaxed,
    fontStyle: FontStyle.italic,
  );

  /// Testimonial text style - Italic Playfair for emotional impact
  /// Note: PlayfairDisplay doesn't have light weights, using Regular (400)
  static TextStyle get testimonial => GoogleFonts.playfairDisplay(
    fontSize: 20,
    fontWeight: weightRegular, // PlayfairDisplay min weight is 400
    letterSpacing: 0.15,
    height: 1.7,
    fontStyle: FontStyle.italic,
  );

  /// Pull quote style - Large italic for featured quotes
  /// Note: PlayfairDisplay doesn't have light weights, using Regular (400)
  static TextStyle get pullQuote => GoogleFonts.playfairDisplay(
    fontSize: 32,
    fontWeight: weightRegular, // PlayfairDisplay min weight is 400
    letterSpacing: -0.5,
    height: 1.3,
    fontStyle: FontStyle.italic,
  );

  /// Quote attribution style - Who said the quote
  static TextStyle get quoteAttribution => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: weightMedium,
    letterSpacing: 0.5,
    height: 1.5,
    fontStyle: FontStyle.italic,
  );

  // ============================================================================
  // RESPONSIVE SCALING
  // ============================================================================

  /// Scale text theme based on screen width
  static TextTheme responsiveTextTheme(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    // Mobile (< 600)
    if (width < 600) {
      return textTheme.apply(fontSizeFactor: 0.9);
    }

    // Tablet (600-1024)
    if (width < 1024) {
      return textTheme.apply();
    }

    // Desktop (>= 1024)
    return textTheme.apply(fontSizeFactor: 1.1);
  }

  /// Get responsive hero title size (H1)
  /// Mobile: 32px, Desktop: 48px
  static double getHeroTitleSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return 32; // Mobile
    if (width < 1024) return 40; // Tablet
    return 48; // Desktop
  }

  /// Get responsive H2 size
  /// Mobile: 24px, Desktop: 36px
  static double getH2Size(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return 24; // Mobile
    if (width < 1024) return 30; // Tablet
    return 36; // Desktop
  }

  /// Get responsive H3 size
  /// Mobile: 20px, Desktop: 24px
  static double getH3Size(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return 20; // Mobile
    if (width < 1024) return 22; // Tablet
    return 24; // Desktop
  }

  /// Get responsive property card title size
  static double getPropertyTitleSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return 16; // Mobile
    if (width < 1024) return 18; // Tablet
    return 20; // Desktop
  }

  // ============================================================================
  // TEXT STYLES WITH COLOR
  // ============================================================================

  /// Get text style with specific color
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }

  /// Get text style with opacity
  static TextStyle withOpacity(TextStyle style, double opacity) {
    return style.copyWith(color: style.color?.withValues(alpha: opacity));
  }

  /// Get bold variant of text style
  static TextStyle bold(TextStyle style) {
    return style.copyWith(fontWeight: FontWeight.w700);
  }

  /// Get semibold variant
  static TextStyle semibold(TextStyle style) {
    return style.copyWith(fontWeight: FontWeight.w600);
  }

  /// Get medium variant
  static TextStyle medium(TextStyle style) {
    return style.copyWith(fontWeight: FontWeight.w500);
  }

  /// Get italic variant
  static TextStyle italic(TextStyle style) {
    return style.copyWith(fontStyle: FontStyle.italic);
  }

  /// Get underlined variant
  static TextStyle underlined(TextStyle style) {
    return style.copyWith(decoration: TextDecoration.underline);
  }
}
