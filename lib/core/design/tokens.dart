/// BookBed canonical design tokens.
///
/// Single source of truth. Every primitive in `lib/core/widgets/bb_*.dart` and
/// every page/dialog redesign composes from this file. Hardcoded `Color(0xFF…)`,
/// raw `EdgeInsets.symmetric(horizontal: 12)`, `BorderRadius.circular(8)` calls
/// in new code = bug.
///
/// Light/dark resolution: read `BBColor.of(context)` (returns a [BBColorSet]).
/// Sizes / radii / shadows are flat constants — they don't change with theme.
///
/// **Frozen carve-outs** (per CLAUDE.md NIKADA NE MIJENJAJ):
///  - Calendar fixed dimensions stay in `timeline_dimensions.dart`
///  - Cjenovnik tab stays referential
///  - Button radius = `BBRadius.sm` = 12px (mandate)
library;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';

// ===========================================================================
// COLOR
// ===========================================================================

/// Theme-aware color set. Resolve via `BBColor.of(context)` — never reach for
/// raw `BBColor.bgLight` / `BBColor.bgDark` in widgets.
@immutable
class BBColorSet {
  const BBColorSet({
    required this.primary,
    required this.primaryDark,
    required this.primaryLight,
    required this.secondary,
    required this.tertiary,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.bg,
    required this.surface,
    required this.surfaceVariant,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.statusConfirmed,
    required this.statusPending,
    required this.statusCancelled,
    required this.statusCompleted,
    required this.statusImported,
  });

  // Brand
  final Color primary;
  final Color primaryDark;
  final Color primaryLight;
  final Color secondary;
  final Color tertiary;

  // Semantic
  final Color success;
  final Color warning;
  final Color error;
  final Color info;

  // Surfaces
  final Color bg;
  final Color surface;
  final Color surfaceVariant;
  final Color border;

  // Text
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;

  // Booking status
  final Color statusConfirmed;
  final Color statusPending;
  final Color statusCancelled;
  final Color statusCompleted;
  final Color statusImported;
}

/// Canonical BookBed colors.
class BBColor {
  BBColor._();

  // -------------------------------------------------------------------------
  // Brand (light/dark identical — brand mark doesn't shift hue across modes)
  // -------------------------------------------------------------------------

  /// Modern Purple. Primary brand action.
  static const Color primary = Color(0xFF6B4CE6);

  /// Darker primary (~12% darker) for pressed states, focus rings, gradient stop.
  static const Color primaryDark = Color(0xFF5B3DD6);

  /// Lighter primary for hover surface fill, focus ring backgrounds.
  static const Color primaryLight = Color(0xFF9B86F3);

  /// Coral. Used for destructive CTA + error states.
  static const Color secondary = Color(0xFFFF6B6B);

  /// Golden Sand. Pending status, warning, accent badges.
  static const Color tertiary = Color(0xFFFFB84D);

  // -------------------------------------------------------------------------
  // Semantic (light)
  // -------------------------------------------------------------------------

  static const Color success = Color(0xFF2E7D5B);
  static const Color warning = Color(0xFFFFB84D);
  static const Color error = Color(0xFFFF6B6B);
  static const Color info = Color(0xFF6B4CE6);

  // -------------------------------------------------------------------------
  // Surfaces — light
  // -------------------------------------------------------------------------

  static const Color bgLight = Color(0xFFFAFAFA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVarLight = Color(0xFFF5F5F5);
  static const Color borderLight = Color(0xFFE2E8F0);

  // -------------------------------------------------------------------------
  // Surfaces — dark
  // -------------------------------------------------------------------------

  static const Color bgDark = Color(0xFF000000);
  static const Color surfaceDark = Color(0xFF121212);
  static const Color surfaceVarDark = Color(0xFF1E1E1E);
  static const Color borderDark = Color(0xFF2D3748);

  // -------------------------------------------------------------------------
  // Text — light
  // -------------------------------------------------------------------------

  static const Color textPrimaryLight = Color(0xFF2D3748);
  static const Color textSecondaryLight = Color(0xFF4A5568);
  static const Color textTertiaryLight = Color(0xFF718096);

  // -------------------------------------------------------------------------
  // Text — dark
  // -------------------------------------------------------------------------

  static const Color textPrimaryDark = Color(0xFFE2E8F0);
  static const Color textSecondaryDark = Color(0xFFA0AEC0);
  static const Color textTertiaryDark = Color(0xFF718096);

  // -------------------------------------------------------------------------
  // Booking status (light/dark identical — semantic, not surface)
  // -------------------------------------------------------------------------

  static const Color statusConfirmed = Color(0xFF2E7D5B);
  static const Color statusPending = Color(0xFFFFB84D);
  static const Color statusCancelled = Color(0xFF718096);
  static const Color statusCompleted = Color(0xFF6B4CE6);
  static const Color statusImported = Color(0xFF4A90D9);

  // -------------------------------------------------------------------------
  // Theme-aware sets (resolved via [of])
  // -------------------------------------------------------------------------

  static const BBColorSet light = BBColorSet(
    primary: primary,
    primaryDark: primaryDark,
    primaryLight: primaryLight,
    secondary: secondary,
    tertiary: tertiary,
    success: success,
    warning: warning,
    error: error,
    info: info,
    bg: bgLight,
    surface: surfaceLight,
    surfaceVariant: surfaceVarLight,
    border: borderLight,
    textPrimary: textPrimaryLight,
    textSecondary: textSecondaryLight,
    textTertiary: textTertiaryLight,
    statusConfirmed: statusConfirmed,
    statusPending: statusPending,
    statusCancelled: statusCancelled,
    statusCompleted: statusCompleted,
    statusImported: statusImported,
  );

  static const BBColorSet dark = BBColorSet(
    primary: primary,
    primaryDark: primaryDark,
    primaryLight: primaryLight,
    secondary: secondary,
    tertiary: tertiary,
    success: success,
    warning: warning,
    error: error,
    info: info,
    bg: bgDark,
    surface: surfaceDark,
    surfaceVariant: surfaceVarDark,
    border: borderDark,
    textPrimary: textPrimaryDark,
    textSecondary: textSecondaryDark,
    textTertiary: textTertiaryDark,
    statusConfirmed: statusConfirmed,
    statusPending: statusPending,
    statusCancelled: statusCancelled,
    statusCompleted: statusCompleted,
    statusImported: statusImported,
  );

  /// Resolve the active color set for the current [BuildContext].
  static BBColorSet of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }

  // -------------------------------------------------------------------------
  // Legacy aliases (existing call-sites; keep referential)
  // -------------------------------------------------------------------------

  static const Color bgLightAlias = AppColors.backgroundLight;
  static const Color textLight = AppColors.textPrimaryLight;
}

// ===========================================================================
// SPACE — 8px grid, NO 12 (use sm=16 or one-off via BBSpace.gap if rare)
// ===========================================================================

class BBSpace {
  BBSpace._();

  /// 4px — micro gaps inside chips, badges
  static const double xxs = 4.0;

  /// 8px — between icon + label, inline gaps
  static const double xs = 8.0;

  /// 16px — default content padding, between fields
  static const double sm = 16.0;

  /// 24px — section gaps inside a card
  static const double md = 24.0;

  /// 32px — between cards
  static const double lg = 32.0;

  /// 48px — page-level padding bottoms
  static const double xl = 48.0;

  /// 64px — section breaks on desktop
  static const double xxl = 64.0;

  // -------------------------------------------------------------------------
  // Deprecated transitional values — DELETE after codemod
  // -------------------------------------------------------------------------

  @Deprecated('Use BBSpace.sm (16) or refactor layout. See audit/80 mapping.')
  static const double xs2 = 12.0;
}

// ===========================================================================
// RADIUS
// ===========================================================================

class BBRadius {
  BBRadius._();

  /// 6px — tiny chips, indicator pills
  static const double xs = 6.0;

  /// 12px — buttons, inputs, chips (MANDATE per CLAUDE.md)
  static const double sm = 12.0;

  /// 20px — cards
  static const double md = 20.0;

  /// 24px — modals, sheets
  static const double lg = 24.0;

  /// 32px — hero
  static const double xl = 32.0;

  /// 999 — circular (avatars, pills, FABs)
  static const double full = 999.0;

  // Convenience BorderRadius constants
  static const BorderRadius xsAll = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius fullAll = BorderRadius.all(Radius.circular(full));
}

// ===========================================================================
// SHADOW
// ===========================================================================

class BBShadow {
  BBShadow._();

  /// Flat — no shadow
  static const List<BoxShadow> none = <BoxShadow>[];

  /// Light — resting cards, chips
  static const List<BoxShadow> sm = <BoxShadow>[
    BoxShadow(
      color: Color(0x0D000000), // 5% black
      offset: Offset(0, 1),
      blurRadius: 2,
    ),
  ];

  /// Medium — hoverable cards, popovers
  static const List<BoxShadow> md = <BoxShadow>[
    BoxShadow(
      color: Color(0x14000000), // 8% black
      offset: Offset(0, 4),
      blurRadius: 12,
    ),
  ];

  /// Large — modals, hero
  static const List<BoxShadow> lg = <BoxShadow>[
    BoxShadow(
      color: Color(0x1F000000), // 12% black
      offset: Offset(0, 12),
      blurRadius: 24,
    ),
  ];

  /// Brand purple shadow — primary button resting state
  static const List<BoxShadow> purple = <BoxShadow>[
    BoxShadow(
      color: Color(0x406B4CE6), // ~25% brand purple
      offset: Offset(0, 8),
      blurRadius: 24,
    ),
  ];

  // Dark variants (~1.5× opacity for visibility against dark surfaces)
  static const List<BoxShadow> smDark = <BoxShadow>[
    BoxShadow(color: Color(0x14000000), offset: Offset(0, 1), blurRadius: 2),
  ];

  static const List<BoxShadow> mdDark = <BoxShadow>[
    BoxShadow(color: Color(0x1F000000), offset: Offset(0, 4), blurRadius: 12),
  ];

  static const List<BoxShadow> lgDark = <BoxShadow>[
    BoxShadow(color: Color(0x33000000), offset: Offset(0, 12), blurRadius: 24),
  ];

  /// Theme-aware: resolve the right shadow for resting cards.
  static List<BoxShadow> resting(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? smDark : sm;
  }

  /// Theme-aware: resolve the right shadow for hover/pop.
  static List<BoxShadow> elevated(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? mdDark : md;
  }

  /// Theme-aware: resolve the right shadow for modal/hero.
  static List<BoxShadow> modal(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? lgDark : lg;
  }

  // -------------------------------------------------------------------------
  // Legacy elevations (existing call-sites). Prefer [resting]/[elevated]/[modal]
  // for new code.
  // -------------------------------------------------------------------------

  static const List<BoxShadow> e1 = AppShadows.elevation1;
  static const List<BoxShadow> e2 = AppShadows.elevation2;
  static const List<BoxShadow> e3 = AppShadows.elevation3;
  static const List<BoxShadow> e4 = AppShadows.elevation4;
  static const List<BoxShadow> e5 = AppShadows.elevation5;
}

// ===========================================================================
// TYPE — Inter via google_fonts (already bundled in assets/google_fonts/)
// ===========================================================================

/// Tabular figures feature for monospaced digits — required on all numeric
/// labels (prices, dates, counts) so columns of numbers align visually.
const List<FontFeature> _tabular = <FontFeature>[FontFeature.tabularFigures()];

class BBType {
  BBType._();

  /// 32 / 700 / 1.2 — large hero, page heroes only
  static TextStyle display(BuildContext context) => GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: BBColor.of(context).textPrimary,
  );

  /// 24 / 700 / 1.2 — page H1
  static TextStyle h1(BuildContext context) => GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: BBColor.of(context).textPrimary,
  );

  /// 20 / 600 / 1.2 — section H2
  static TextStyle h2(BuildContext context) => GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: BBColor.of(context).textPrimary,
  );

  /// 18 / 600 / 1.2 — sub-section H3
  static TextStyle h3(BuildContext context) => GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: BBColor.of(context).textPrimary,
  );

  /// 16 / 400 / 1.5 — large body
  static TextStyle bodyLg(BuildContext context) => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: BBColor.of(context).textPrimary,
  );

  /// 14 / 400 / 1.5 — default body
  static TextStyle body(BuildContext context) => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: BBColor.of(context).textPrimary,
  );

  /// 12 / 400 / 1.5 — caption, helper text
  static TextStyle caption(BuildContext context) => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: BBColor.of(context).textSecondary,
  );

  /// 13 / 500 / 1.5 — label (form labels, button text)
  static TextStyle label(BuildContext context) => GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: BBColor.of(context).textPrimary,
  );

  /// 13 / 500 / 1.5 — monospace-style ("mono" via tabular figures, not a
  /// separate font; keeps bundle size flat)
  static TextStyle mono(BuildContext context) => GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: BBColor.of(context).textPrimary,
    fontFeatures: _tabular,
  );

  // -------------------------------------------------------------------------
  // Numeric variants — same as base but with tabular figures (digits align in
  // columns). Use for prices, dates, counts, anywhere digits stack vertically.
  // -------------------------------------------------------------------------

  static TextStyle bodyNum(BuildContext context) =>
      body(context).copyWith(fontFeatures: _tabular);

  static TextStyle bodyLgNum(BuildContext context) =>
      bodyLg(context).copyWith(fontFeatures: _tabular);

  static TextStyle h2Num(BuildContext context) =>
      h2(context).copyWith(fontFeatures: _tabular);

  static TextStyle h1Num(BuildContext context) =>
      h1(context).copyWith(fontFeatures: _tabular);

  static TextStyle displayNum(BuildContext context) =>
      display(context).copyWith(fontFeatures: _tabular);

  // -------------------------------------------------------------------------
  // Deprecated transitional scalar fontSizes — DELETE after codemod
  // -------------------------------------------------------------------------

  @Deprecated('Use BBType.caption(context). See audit/80 mapping.')
  static const double xs = 10;
  @Deprecated('Use BBType.caption(context).')
  static const double sm = 12;
  @Deprecated('Use BBType.body(context).')
  static const double md = 14;
  @Deprecated('Use BBType.bodyLg(context).')
  static const double lg = 16;
  @Deprecated('Use BBType.h3(context).')
  static const double xl = 18;
  @Deprecated('Use BBType.h2(context).')
  static const double xxl = 22;
  @Deprecated('Use BBType.h1(context).')
  static const double display1 = 24;
  @Deprecated('Use BBType.display(context) + copyWith fontSize: 28.')
  static const double display2 = 28;
  @Deprecated('Use BBType.display(context).')
  static const double display3 = 32;
}

// ===========================================================================
// MOTION — reduced-motion aware
// ===========================================================================

class BBMotion {
  BBMotion._();

  /// 120ms — micro feedback (chip select, button press)
  static const Duration fast = Duration(milliseconds: 120);

  /// 200ms — base transition (default for most things)
  static const Duration base = Duration(milliseconds: 200);

  /// 320ms — emphasized (route transitions, sheet open/close)
  static const Duration slow = Duration(milliseconds: 320);

  /// Canonical curve — friendly, decelerated, never bouncy.
  static const Curve curve = Curves.easeOutCubic;

  /// True when the platform reports `MediaQuery.disableAnimations` OR
  /// `SchedulerBinding.instance.platformDispatcher.accessibilityFeatures.reduceMotion`.
  /// All animation tokens collapse to `Duration.zero` when this is true.
  static bool reduced(BuildContext context) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      return true;
    }
    return SchedulerBinding
        .instance
        .platformDispatcher
        .accessibilityFeatures
        .reduceMotion;
  }

  /// Returns `Duration.zero` if reduced-motion, else [d].
  static Duration adapt(BuildContext context, Duration d) {
    return reduced(context) ? Duration.zero : d;
  }
}

// ===========================================================================
// BREAKPOINT
// ===========================================================================

/// Width breakpoints. Sourced from existing AppDimensions for parity and to
/// avoid duplicate truth-of-source.
class BBBreakpoint {
  BBBreakpoint._();

  /// `< 600` — phone portrait
  static const double mobile = 600;

  /// `600–1023` — tablet portrait, large phone landscape
  static const double tablet = 1024;

  /// `1024–1439` — small laptop / desktop
  static const double desktop = 1440;

  /// `>= 1440` — wide / ultra-wide
  static const double wide = 1440;
}
