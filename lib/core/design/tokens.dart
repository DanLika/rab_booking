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
    this.onPrimary = Colors.white,
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

  /// Ink on [primary]-filled surfaces (buttons, selected chips, brand
  /// discs). White in both themes today — the token exists so a future
  /// brand shift changes ONE value instead of a Colors.white sweep
  /// (audit F3.3; visually neutral by construction).
  final Color onPrimary;

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

  /// Darker primary for pressed states, focus rings, gradient stop
  /// (`tokens.css --bb-primary-dark` light `#5638C7`).
  static const Color primaryDark = Color(0xFF5638C7);

  /// Lighter primary for hover surface fill, focus ring backgrounds
  /// (`tokens.css --bb-primary-light` `#B5A4F0`, same in dark).
  static const Color primaryLight = Color(0xFFB5A4F0);

  /// Dark-mode primary lift. Used as `BBColorSet.dark.primary` so that
  /// `BBColor.of(context).primary` resolves to mockup `--bb-primary` in dark
  /// (`design_handoff/source/tokens.css` `.theme-dark { --bb-primary: #8B6FFF }`).
  /// Light mode keeps [primary] `#6B4CE6`.
  static const Color primaryDarkMode = Color(0xFF8B6FFF);

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
  static const Color info = Color(0xFF4A90D9);

  // -------------------------------------------------------------------------
  // Brand + semantic — dark lifts (`tokens.css .theme-dark`, AA on black)
  // -------------------------------------------------------------------------

  static const Color secondaryDarkMode = Color(0xFFFF8080);
  static const Color tertiaryDarkMode = Color(0xFFFFC872);
  static const Color successDarkMode = Color(0xFF4FAE7F);
  static const Color warningDarkMode = Color(0xFFFFC872);
  static const Color errorDarkMode = Color(0xFFFF8080);
  static const Color infoDarkMode = Color(0xFF6BA8E8);

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
  // `--bb-surface` dark — WIDENED to #1E1E1E (audit/127 dark-depth): flat dark
  // has no shadow, so cards lift by lightness alone
  // (shell #000 → panel #141414 → card #1E1E1E → variant #2A2A2A).
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color surfaceVarDark = Color(0xFF2A2A2A);
  static const Color borderDark = Color(0xFF2D3748);

  // -------------------------------------------------------------------------
  // Text — light
  // -------------------------------------------------------------------------

  static const Color textPrimaryLight = Color(0xFF2D3748);
  static const Color textSecondaryLight = Color(0xFF4A5568);
  static const Color textTertiaryLight = Color(0xFF718096);

  /// Softened light-theme eyebrow ink — one step quieter than
  /// [textSecondaryLight] (#4A5568, CR 7.21) while staying AA (CR 5.23 on
  /// #FAFAFB shell / 5.46 on white cards). Pass 5 "type restraint": eyebrows
  /// whisper, not shout. Light-only — dark keeps [textSecondaryDark] (CR 8.17).
  static const Color eyebrowInkLight = Color(0xFF5A6B80);

  // -------------------------------------------------------------------------
  // Text — dark
  // -------------------------------------------------------------------------

  static const Color textPrimaryDark = Color(0xFFE2E8F0);
  static const Color textSecondaryDark = Color(0xFFA0AEC0);

  /// Mirrors [AppColors.textTertiaryDark] — see the WCAG note there.
  /// #718096 → #8592A5 (2026-07-17, AA fix).
  static const Color textTertiaryDark = Color(0xFF8592A5);

  // -------------------------------------------------------------------------
  // Booking status (light/dark identical — semantic, not surface)
  // -------------------------------------------------------------------------

  static const Color statusConfirmed = Color(0xFF2E7D5B);

  /// `--bb-status-pending` light — darker amber for AA contrast on tint.
  static const Color statusPending = Color(0xFFB7791F);
  static const Color statusCancelled = Color(0xFF4A5568);
  static const Color statusCompleted = Color(0xFF6B4CE6);
  static const Color statusImported = Color(0xFF4A90D9);

  // Dark lifts (`tokens.css .theme-dark --bb-status-*`)
  static const Color statusConfirmedDarkMode = Color(0xFF4FAE7F);
  static const Color statusPendingDarkMode = Color(0xFFFFC872);
  static const Color statusCancelledDarkMode = Color(0xFFA0AEC0);
  static const Color statusCompletedDarkMode = Color(0xFF8B6FFF);
  static const Color statusImportedDarkMode = Color(0xFF6BA8E8);

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
    primary: primaryDarkMode, // mockup --bb-primary dark #8B6FFF
    primaryDark: primary, // dark `--bb-primary-dark` = #6B4CE6
    primaryLight: primaryLight,
    secondary: secondaryDarkMode,
    tertiary: tertiaryDarkMode,
    success: successDarkMode,
    warning: warningDarkMode,
    error: errorDarkMode,
    info: infoDarkMode,
    bg: bgDark,
    surface: surfaceDark,
    surfaceVariant: surfaceVarDark,
    border: borderDark,
    textPrimary: textPrimaryDark,
    textSecondary: textSecondaryDark,
    textTertiary: textTertiaryDark,
    statusConfirmed: statusConfirmedDarkMode,
    statusPending: statusPendingDarkMode,
    statusCancelled: statusCancelledDarkMode,
    statusCompleted: statusCompletedDarkMode,
    statusImported: statusImportedDarkMode,
  );

  /// Resolve the active color set for the current [BuildContext].
  static BBColorSet of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }

  /// Mono-tone flip point for decorative stat/KPI icon-tile backplates
  /// (minimalist pass 3, 2026-07-10). Owner LIGHT theme collapses the
  /// polychrome amber/green/blue/purple tiles to a single **primary** tint to
  /// reduce color noise; the caller's [original] tone is preserved in DARK so
  /// the OLED chrome is untouched. Semantic status dots/pills do NOT route
  /// through here — they keep their hue.
  ///
  /// REVERSIBLE: to restore polychrome tiles, `return original;` unconditionally.
  /// To try neutral-gray instead of purple, swap the light branch to a grey.
  static Color monoKpiTone(BuildContext context, Color original) {
    return Theme.of(context).brightness == Brightness.dark ? original : primary;
  }

  /// Soft error tint for warning/conflict banners, derived from the theme's
  /// error colour so it follows dark mode.
  ///
  /// Banners here used to be built from the `Colors.red.shade50…shade800`
  /// ladder, which is a light-only palette: on the OLED dark surface it rendered
  /// a pale-pink card floating on black. Deriving the fill and the border from
  /// [BBColorSet.error] keeps a single source and works in both themes.
  ///
  /// [strength] scales the fill (border uses a stronger alpha). Text and icons
  /// on top of it should use `BBColor.of(context).error` directly.
  static Color errorSurface(BuildContext context, {double strength = 1.0}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = of(context).error;
    return base.withValues(alpha: (isDark ? 0.16 : 0.08) * strength);
  }

  /// Border companion to [errorSurface].
  static Color errorBorder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return of(context).error.withValues(alpha: isDark ? 0.55 : 0.35);
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

  // -------------------------------------------------------------------------
  // Redesign handoff additions (delegated to AppShadows; theme-aware helpers
  // resolve to dark variants where applicable).
  // -------------------------------------------------------------------------

  /// Card-elevated 3-layer ramp (`--bb-shadow-card`).
  static const List<BoxShadow> cardElevated = AppShadows.cardElevated;

  /// Purple-glow small (`--bb-shadow-purple-sm`) — active nav tiles + primary
  /// CTAs ONLY. Use [purpleGlow] for theme-aware resolution.
  static const List<BoxShadow> purpleSm = AppShadows.purpleSm;

  /// Premium console panel-shadow (light variant).
  static const List<BoxShadow> panelLight = AppShadows.panelLight;

  /// Premium console panel-shadow (dark variant).
  static const List<BoxShadow> panelDark = AppShadows.panelDark;

  /// Theme-aware purple glow (active nav, primary CTA).
  static List<BoxShadow> purpleGlow(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppShadows.purpleSmDark
        : AppShadows.purpleSm;
  }

  /// Theme-aware floating panel shadow (the `BbScaffold` panel layer).
  static List<BoxShadow> panel(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppShadows.panelDark
        : AppShadows.panelLight;
  }
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

  /// 13 / 500 — JetBrains Mono via google_fonts (handoff `--bb-font-mono`).
  /// Use for IBAN, code blocks, copyable tokens. Network-loaded on first use.
  static TextStyle mono(BuildContext context) => GoogleFonts.jetBrainsMono(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: BBColor.of(context).textPrimary,
    fontFeatures: _tabular,
  );

  /// 10.5 / 500 / 1.4 — UPPERCASE eyebrow label (`bb-eyebrow`).
  /// Pass 5 "type restraint" (minimalist light theme): softened from
  /// 11/w600/ls-0.88 → the eyebrow now whispers — lighter weight (w500),
  /// marginally smaller (10.5), looser-but-calmer tracking (0.7), and a
  /// softer light ink ([BBColor.eyebrowInkLight] #5A6B80, still AA). Dark
  /// keeps [textSecondary] (#A0AEC0, CR 8.17 — unchanged, no golden move).
  /// Pair with `.toUpperCase()` — Flutter has no native text-transform.
  static TextStyle eyebrow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GoogleFonts.inter(
      fontSize: 10.5,
      fontWeight: FontWeight.w500,
      height: 1.4,
      letterSpacing: 0.7,
      color: isDark ? BBColor.textSecondaryDark : BBColor.eyebrowInkLight,
    );
  }

  /// 48 / 800 / 1.05 — hero display (`bb-display-lg`).
  /// Premium pages only (Pregled north-star, hero sections).
  static TextStyle displayLg(BuildContext context) => GoogleFonts.inter(
    fontSize: 48,
    fontWeight: FontWeight.w800,
    height: 1.05,
    letterSpacing: -1.44, // -0.03em × 48
    color: BBColor.of(context).textPrimary,
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

// ===========================================================================
// 00b — TOKEN CONSOLIDATION ADDITIONS (Phase 1)
//
// These extend BB tokens to cover EVERY symbol referenced in
// `lib/core/design_tokens/*` (12 legacy files, 95 importers, 161 unique
// symbols). Exact old values are preserved verbatim. The codemod that
// migrates the 95 importers from `design_tokens/*` to these BB tokens is
// Phase 2 (separate PR, Jules).
//
// FROZEN-AREA NOTE: calendar (14 files) + Cjenovnik (`unit_pricing_screen.dart`)
// will retain their `design_tokens/*` imports through Phase 2 to honor the
// CLAUDE.md NIKADA NE MIJENJAJ contract on those surfaces. Token *additions*
// here are safe — only *call-site rewrites* are restricted.
// ===========================================================================

// ===========================================================================
// BBBorderWidth — was BorderTokens.width*
// ===========================================================================

class BBBorderWidth {
  BBBorderWidth._();

  /// 0 — no border
  static const double none = 0.0;

  /// 1 — default thin
  static const double thin = 1.0;

  /// 1.5 — slightly emphasized
  static const double medium = 1.5;

  /// 2 — focus rings, selected states
  static const double thick = 2.0;
}

// ===========================================================================
// BBOpacity — was OpacityTokens
// ===========================================================================

class BBOpacity {
  BBOpacity._();

  static const double transparent = 0.0;

  /// 4% — barely-visible tint
  static const double subtleOverlay = 0.04;

  /// 8% — light hover/background
  static const double lightOverlay = 0.08;

  /// 12% — disabled states
  static const double mediumOverlay = 0.12;

  /// 16% — secondary backgrounds, dividers
  static const double visible = 0.16;

  /// 30% — modal scrim
  static const double semiTransparent = 0.30;

  /// 40% — watermark badges
  static const double badgeSubtle = 0.40;

  /// 50% — loading overlay
  static const double mostlyVisible = 0.50;

  /// 70%
  static const double mostlyOpaque = 0.70;

  /// 90%
  static const double almostOpaque = 0.90;

  /// 100%
  static const double opaque = 1.0;

  // Shadow opacity helpers
  static const double shadowSubtle = 0.05;
  static const double shadowLight = 0.08;
  static const double shadowMedium = 0.10;
  static const double shadowStrong = 0.15;
  static const double shadowHeavy = 0.20;
}

// ===========================================================================
// BBIconSize — was IconSizeTokens
// ===========================================================================

class BBIconSize {
  BBIconSize._();

  static const double tiny = 8.0;
  static const double xs = 12.0;
  static const double small = 16.0;
  static const double medium = 20.0;
  static const double large = 24.0;
  static const double xl = 32.0;
  static const double xxl = 40.0;
  static const double huge = 48.0;
  static const double massive = 64.0;
  static const double gigantic = 80.0;

  // Semantic aliases (component-specific)
  static const double appBarAction = large; // 24
  static const double navigation = large; // 24
  static const double listItem = medium; // 20
  static const double input = medium; // 20
  static const double button = medium; // 20
  static const double fab = large; // 24
  static const double chip = small; // 16
  static const double avatar = xl; // 32
}

// ===========================================================================
// BBConstraint — was ConstraintTokens (NON-frozen subset only)
//
// Calendar-specific constraints (calendarCellMinHeight, calendarCellMaxHeight,
// calendarDayCellSize, calendarMonthMin/MaxWidth, modalHeaderHeight) are NOT
// re-exposed here — calendar code stays on the legacy ConstraintTokens to
// honor the FROZEN dimensions contract.
// ===========================================================================

class BBConstraint {
  BBConstraint._();

  // Max-width presets
  static const double maxWidgetWidth = 480.0;
  static const double maxFormWidth = 600.0;
  static const double maxModalWidth = 500.0;
  static const double maxCardWidth = 400.0;
  static const double maxNarrowContentWidth = 720.0;
  static const double maxWideContentWidth = 1200.0;
  static const double maxFullContentWidth = 1440.0;

  // Min-width presets
  static const double minWidgetWidth = 280.0;
  static const double minButtonWidth = 88.0;
  static const double minInputWidth = 200.0;
  static const double minCardWidth = 240.0;

  // Heights
  static const double buttonHeight = 48.0;
  static const double buttonHeightCompact = 40.0;
  static const double buttonHeightLarge = 56.0;
  static const double inputHeight = 48.0;
  static const double inputHeightCompact = 40.0;
  static const double inputHeightLarge = 56.0;
  static const double appBarHeight = 56.0;
  static const double bottomSheetPeekHeight = 100.0;
  static const double maxScrollableHeight = 600.0;

  // Aspect ratios
  static const double cardAspectRatio = 16 / 9;
  static const double squareAspectRatio = 1.0;
  static const double wideAspectRatio = 21 / 9;
  static const double portraitAspectRatio = 3 / 4;

  // Touch targets
  static const double minTouchTarget = 44.0;
  static const double recommendedTouchTarget = 48.0;
  static const double largeTouchTarget = 56.0;

  // Icon-container squares
  static const double iconContainerSmall = 32.0;
  static const double iconContainerMedium = 40.0;
  static const double iconContainerLarge = 48.0;
  static const double iconContainerXL = 64.0;

  // Section gaps (non-calendar)
  static const double maxSectionGap = 64.0;
  static const double sectionGap = 32.0;
  static const double compactSectionGap = 24.0;
}

// ===========================================================================
// Extension: BBSpace bridges (off-grid for codemod safety)
// ===========================================================================

extension BBSpaceBridges on BBSpace {
  /// 2px — used by `SpacingTokens.xxs (2)`. Off the 4px-base grid; retained
  /// to avoid silent layout shifts during codemod. Audit callers and migrate
  /// to `BBSpace.xxs (4)` where 2px is gratuitously tight.
  @Deprecated('Off-grid. Audit caller; migrate to BBSpace.xxs (4) if possible.')
  static const double xxs2 = 2.0;

  /// 6px — used by `SpacingTokens.xs2 (6)`. Off-grid.
  @Deprecated('Off-grid. Audit caller; migrate to BBSpace.xs (8) if possible.')
  static const double xs6 = 6.0;

  /// 20px — used by `SpacingTokens.m2 (20)`. Off-grid.
  @Deprecated('Off-grid. Audit caller; migrate to BBSpace.sm (16) or .md (24).')
  static const double sm20 = 20.0;

  /// 40px — used by `SpacingTokens.xl2 (40)`. Off-grid.
  @Deprecated('Off-grid. Audit caller; migrate to BBSpace.lg (32) or .xl (48).')
  static const double lg40 = 40.0;

  /// 56px — used by `SpacingTokens.xxl2 (56)`. Off-grid.
  @Deprecated(
    'Off-grid. Audit caller; migrate to BBSpace.xl (48) or .xxl (64).',
  )
  static const double xl56 = 56.0;

  /// 96px — used by `AppDimensions.spaceXXXL`. Above-scale.
  @Deprecated('Above BBSpace.xxl. Add own const if truly needed.')
  static const double xxxl96 = 96.0;
}

// ===========================================================================
// Extension: BBRadius bridges (off-scale for codemod safety)
// ===========================================================================

extension BBRadiusBridges on BBRadius {
  /// 0 — `BorderTokens.radiusSharp`
  static const double sharp = 0.0;

  /// 2 — `BorderTokens.radiusTiny`. Below BBRadius.xs (6).
  @Deprecated('Off-scale. Audit caller; consider BBRadius.xs (6).')
  static const double tiny = 2.0;

  /// 4 — `BorderTokens.radiusSubtle` + `calendarCellRadius` (FROZEN). Below
  /// BBRadius.xs (6). Used inside calendar — leave call-sites untouched.
  @Deprecated('Off-scale. Calendar-frozen. New code: use BBRadius.xs (6).')
  static const double subtle = 4.0;

  /// 8 — `BorderTokens.radiusMedium` + component aliases (button/input/card/widgetContainer in legacy).
  /// Between BBRadius.xs (6) and BBRadius.sm (12). Heavy usage (48× direct + via aliases).
  @Deprecated(
    'Off-scale. Audit visual impact; BBRadius.sm (12) is the mandate.',
  )
  static const double medium = 8.0;

  /// 16 — `BorderTokens.radiusLarge`. Between BBRadius.sm (12) and BBRadius.md (20).
  @Deprecated(
    'Off-scale. Audit caller; BBRadius.md (20) is the canonical card radius.',
  )
  static const double large = 16.0;
}

// ===========================================================================
// Extension: BBColor palette steps (Tailwind-style, exact old hex preserved)
//
// These are flat constants, NOT theme-aware. Use sparingly — prefer the
// semantic BBColorSet via `BBColor.of(context)` for surfaces and text. These
// steps exist to migrate `ColorTokens.grey/azure/coral/teal/pink/amber/
// emerald/slate/sky/*` call-sites without value drift.
// ===========================================================================

extension BBColorPalette on BBColor {
  // Greys
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFE5E7EB);
  static const Color grey300 = Color(0xFFD1D5DB);
  static const Color grey400 = Color(0xFF9CA3AF);
  static const Color grey500 = Color(0xFF6B7280);
  static const Color grey600 = Color(0xFF4B5563);
  static const Color grey700 = Color(0xFF374151);
  static const Color grey800 = Color(0xFF1F2937);
  static const Color grey900 = Color(0xFF111827);

  // Azure (purple-blue) — azure600 == BBColor.primary
  static const Color azure50 = Color(0xFFF3F0FF);
  static const Color azure100 = Color(0xFFE0D7FF);
  static const Color azure200 = Color(0xFF9B86F3); // = BBColor.primaryLight
  static const Color azure400 = Color(0xFF8164F0);
  static const Color azure500 = Color(0xFF7B5DED);
  static const Color azure600 = Color(0xFF6B4CE6); // = BBColor.primary
  static const Color azure700 = Color(0xFF5B3DD6); // = BBColor.primaryDark
  static const Color azure800 = Color(0xFF4B2DC6);
  static const Color azure900 = Color(0xFF3B1FB6);

  // Coral — coral500 == BBColor.secondary
  static const Color coral400 = Color(0xFFFF8A80);
  static const Color coral500 = Color(0xFFFF6B6B); // = BBColor.secondary
  static const Color coral600 = Color(0xFFFF5252);

  // Teal
  static const Color teal50 = Color(0xFFF0FDFA);
  static const Color teal100 = Color(0xFFCCF5E8);
  static const Color teal200 = Color(0xFFD1FAE5);
  static const Color teal400 = Color(0xFF34D399);
  static const Color teal500 = Color(0xFF14B8A6);
  static const Color teal600 = Color(0xFF0D9488);
  static const Color teal700 = Color(0xFF0F766E);
  static const Color teal900 = Color(0xFF134E4A);

  // Pink (also: error-shaped, audit caller intent)
  static const Color pink100 = Color(0xFFFFD4E5);
  static const Color pink200 = Color(0xFFFEE2E2);
  static const Color pink400 = Color(0xFFF87171);
  static const Color pink500 = Color(0xFFEC4899);
  static const Color pink600 = Color(0xFFDB2777);
  static const Color pink700 = Color(0xFFEF4444);
  static const Color pink900 = Color(0xFF7F1D1D);

  // Amber
  static const Color amber200 = Color(0xFFFDE68A);
  static const Color amber400 = Color(0xFFFBBF24);
  static const Color amber500 = Color(0xFFF59E0B);
  static const Color amber600 = Color(0xFFD97706);
  static const Color amber900 = Color(0xFF78350F);

  // Emerald
  static const Color emerald400 = Color(0xFF34D399);
  static const Color emerald500 = Color(0xFF10B981);
  static const Color emerald600 = Color(0xFF059669);
  static const Color emerald900 = Color(0xFF064E3B);

  // Slate
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate900 = Color(0xFF0F172A);

  // Sky
  static const Color sky100 = Color(0xFFE0F2FE);
  static const Color sky500 = Color(0xFF0EA5E9);
  static const Color sky900 = Color(0xFF0C4A6E);
}

// ===========================================================================
// BBMotion bridges — was AnimationTokens (full duration + curve coverage)
// ===========================================================================

extension BBMotionBridges on BBMotion {
  // Duration aliases (preserve exact old values)
  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast200 = Duration(
    milliseconds: 200,
  ); // = BBMotion.base
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow500 = Duration(milliseconds: 500);
  static const Duration slower = Duration(milliseconds: 600);
  static const Duration long = Duration(milliseconds: 1000);
  static const Duration notification = Duration(seconds: 3);
  static const Duration autoDismiss = Duration(seconds: 5);

  // Curves (re-exposed)
  static const Curve linear = Curves.linear;
  static const Curve ease = Curves.ease;
  static const Curve easeIn = Curves.easeIn;
  static const Curve easeOut = Curves.easeOut;
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve fastOutSlowIn = Curves.fastOutSlowIn;
  static const Curve elasticOut = Curves.elasticOut;
  static const Curve bounceOut = Curves.bounceOut;
  static const Curve decelerate = Curves.decelerate;

  // Compound presets
  static const Duration fadeDuration = fast200;
  static const Curve fadeCurve = easeOut;
  static const Duration scaleDuration = normal;
  static const Curve scaleCurve = fastOutSlowIn;
  static const Duration slideDuration = normal;
  static const Curve slideCurve = easeOut;
  static const Duration rotationDuration = normal;
  static const Curve rotationCurve = easeInOut;
}

// ===========================================================================
// BBType bridges — was TypographyTokens scalar fontSizes / lineHeights /
// letterSpacings + font weights (most callers don't actually need the
// scalars after migrating to BBType.* TextStyle factories, but bridges
// retained so the codemod can do straight rename).
// ===========================================================================

extension BBTypeBridges on BBType {
  // Font sizes (exact)
  static const double fontSizeXS = 10.0;
  static const double fontSizeXS2 = 11.0;
  static const double fontSizeS = 12.0;
  static const double fontSizeS2 = 13.0;
  static const double fontSizeM = 14.0;
  static const double fontSizeM2 = 15.0;
  static const double fontSizeL = 16.0;
  static const double fontSizeXL = 18.0;
  static const double fontSizeXXL = 20.0;
  static const double fontSizeXXXL = 24.0;
  static const double fontSizeHuge = 26.0;
  static const double poweredBySize = 9.0;

  // Line heights
  static const double lineHeightTight = 1.2;
  static const double lineHeightNormal = 1.5;
  static const double lineHeightRelaxed = 1.75;

  // Letter spacings
  static const double letterSpacingTight = -0.5;
  static const double letterSpacingNormal = 0.0;
  static const double letterSpacingWide = 0.5;

  // Font family name (kept for non-BBType use)
  static const String primaryFont = 'Inter';
  static const List<String> fontFallback = <String>[
    'Inter',
    '-apple-system',
    'BlinkMacSystemFont',
    'Segoe UI',
    'Roboto',
    'Helvetica Neue',
    'Arial',
    'sans-serif',
  ];

  // FontWeight aliases (callers can switch to FontWeight.w*, but the names
  // light/regular/medium/semiBold/bold are heavily used).
  static const FontWeight weightLight = FontWeight.w300;
  static const FontWeight weightRegular = FontWeight.w400;
  static const FontWeight weightMedium = FontWeight.w500;
  static const FontWeight weightSemiBold = FontWeight.w600;
  static const FontWeight weightBold = FontWeight.w700;
}

// ===========================================================================
// BBShadow extension — semantic shadow aliases (was ShadowTokens.subtle/light/
// medium/strong/hover + widgetContainer = light).
// ===========================================================================

extension BBShadowAliases on BBShadow {
  /// `ShadowTokens.subtle` — 1px y, 2px blur, 4% black
  static const List<BoxShadow> subtle = <BoxShadow>[
    BoxShadow(color: Color(0x0A000000), offset: Offset(0, 1), blurRadius: 2),
  ];

  /// `ShadowTokens.medium` — 4px y, 16px blur, 12% black
  static const List<BoxShadow> mediumLegacy = <BoxShadow>[
    BoxShadow(color: Color(0x1F000000), offset: Offset(0, 4), blurRadius: 16),
  ];

  /// `ShadowTokens.strong` / `hover` — 8px y, 24px blur, 16% black
  static const List<BoxShadow> strong = <BoxShadow>[
    BoxShadow(color: Color(0x29000000), offset: Offset(0, 8), blurRadius: 24),
  ];
}

// ===========================================================================
// BBGradient — was GradientTokens (brand + ambient)
// ===========================================================================

class BBGradient {
  BBGradient._();

  /// Brand primary — purple top-left → lighter purple bottom-right.
  /// Used: AppBar, Drawer Header, primary CTAs.
  static const LinearGradient brandPrimary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      Color(0xFF6B4CE6), // BBColor.primary
      Color(0xFF7E5FEE),
    ],
  );

  static const Color brandPrimaryStart = Color(0xFF6B4CE6);
  static const Color brandPrimaryEnd = Color(0xFF7E5FEE);

  /// Subtle background — light mode
  static const LinearGradient subtleBackgroundLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFFFAF8F3), Color(0xFFFFFFFF)],
  );

  /// Subtle background — dark mode
  static const LinearGradient subtleBackgroundDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF1A1A1A), Color(0xFF121212)],
  );

  /// Primary accent
  static const LinearGradient primaryAccent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF6B4CE6), Color(0xFF9B86F3)],
  );

  /// Success
  static const LinearGradient success = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF10B981), Color(0xFF34D399)],
  );

  /// Warning
  static const LinearGradient warning = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFFF59E0B), Color(0xFFFBBF24)],
  );

  // -------------------------------------------------------------------------
  // Redesign handoff additions
  // -------------------------------------------------------------------------

  /// Hero — 3-stop premium purple ramp (`--bb-gradient-hero` light).
  /// Sidebar active tiles, hero cards, highlighted date chips.
  static const LinearGradient hero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      Color(0xFF6B4CE6), // primary
      Color(0xFF8B6FFF), // primary-light
      Color(0xFFA78BFF), // hero highlight
    ],
    stops: <double>[0.0, 0.6, 1.0],
  );

  /// Hero — dark variant (richer entry stop).
  static const LinearGradient heroDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF4A2BD1), Color(0xFF6B4CE6), Color(0xFF8B6FFF)],
    stops: <double>[0.0, 0.5, 1.0],
  );
}
