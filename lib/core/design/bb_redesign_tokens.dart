// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';

import '../theme/app_shadows.dart';
import 'tokens.dart';

/// Redesign-specific surfaces + accents that diverge from existing [BBColor]
/// defaults. Wired into [AppTheme.lightTheme]/[darkTheme] via `extensions:`
/// so redesign widgets can pull handoff surfaces without recoloring the
/// unmigrated screens.
///
/// Usage:
/// ```dart
/// final rd = BbRedesignTokens.of(context);
/// Container(color: rd.shellBg);
/// ```
@immutable
class BbRedesignTokens extends ThemeExtension<BbRedesignTokens> {
  const BbRedesignTokens({
    required this.shellBg,
    required this.panelBg,
    required this.panelBorder,
    required this.panelShadow,
    required this.mintWidget,
    required this.purpleGlow,
    required this.heroGradient,
    required this.brandPrimaryGradient,
    required this.statusConfirmedDeep,
    required this.statusPendingDeep,
    required this.statusCancelledDeep,
    required this.statusConfirmedTint,
    required this.statusPendingTint,
    required this.statusCancelledTint,
    required this.statusCompletedTint,
    required this.statusImportedTint,
    required this.focusRingColor,
    required this.glassBg,
    required this.glassBorder,
    required this.softBg,
  });

  /// Outer console background (`--bb-shell-bg`). Light `#FAFAFB` (near-white,
  /// minimalist pass 1) / dark `#000000`.
  final Color shellBg;

  /// Floating panel surface (`--bb-panel-bg`). Light `#FBFBFD` / dark `#0B0B0D`.
  final Color panelBg;

  /// Panel hairline border.
  final Color panelBorder;

  /// Panel soft-layered shadow.
  final List<BoxShadow> panelShadow;

  /// Mint accent (`#3DD9B0`) — widget surface only.
  final Color mintWidget;

  /// Purple-glow small (`--bb-shadow-purple-sm`) — active nav, primary CTA.
  final List<BoxShadow> purpleGlow;

  /// Hero 3-stop purple gradient.
  final LinearGradient heroGradient;

  /// Brand primary 2-stop gradient (`--bb-gradient-primary`).
  final LinearGradient brandPrimaryGradient;

  /// AA-safe deep status hexes (per handoff status table).
  final Color statusConfirmedDeep;
  final Color statusPendingDeep;
  final Color statusCancelledDeep;

  /// Translucent status backgrounds (`--bb-status-*-bg`).
  final Color statusConfirmedTint;
  final Color statusPendingTint;
  final Color statusCancelledTint;
  final Color statusCompletedTint;
  final Color statusImportedTint;

  /// Focus ring (`--bb-focus-ring`).
  final Color focusRingColor;

  /// Glass surface (hero/auth only).
  final Color glassBg;
  final Color glassBorder;

  /// Soft auth/hero backdrop (pale lavender wash). Use as `BoxDecoration.gradient`
  /// behind glass-card auth screens; distinct from [heroGradient] which is the
  /// saturated brand purple used for sidebar active tiles and hero CTAs. See
  /// `design_handoff/screens/15-owner.png`.
  final LinearGradient softBg;

  // ----- Theme presets -------------------------------------------------------

  static const BbRedesignTokens light = BbRedesignTokens(
    shellBg: Color(0xFFFAFAFB), // minimalist pass 1: near-white shell
    panelBg: Color(0xFFFBFBFD),
    panelBorder: Color(0x0D14182D), // rgba(20,24,45,.05)
    panelShadow: AppShadows.panelLight,
    mintWidget: Color(0xFF3DD9B0),
    purpleGlow: AppShadows.purpleSm,
    heroGradient: BBGradient.hero,
    brandPrimaryGradient: BBGradient.brandPrimary,
    statusConfirmedDeep: Color(0xFF2A7354), // computed AA min on tint (F3.2)
    statusPendingDeep: Color(0xFFA05E14), // computed AA min on tint (F3.2)
    statusCancelledDeep: Color(0xFF4A5568),
    statusConfirmedTint: Color(0x1F2E7D5B), // rgba(46,125,91,.12)
    statusPendingTint: Color(0x2EFFB84D), // rgba(255,184,77,.18)
    statusCancelledTint: Color(0x24718096), // rgba(113,128,150,.14)
    statusCompletedTint: Color(0x1A6B4CE6), // rgba(107,76,230,.10)
    statusImportedTint: Color(0x1F4A90D9), // rgba(74,144,217,.12)
    focusRingColor: Color(0x386B4CE6), // rgba(107,76,230,.22)
    glassBg: Color(0xB8FFFFFF), // rgba(255,255,255,.72)
    glassBorder: Color(0x80FFFFFF), // rgba(255,255,255,.50)
    softBg: LinearGradient(
      // Pale lavender wash for auth/hero screens — handoff screens/15-owner.png
      colors: <Color>[Color(0xFFFAFAFA), Color(0xFFF4F1FF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  static const BbRedesignTokens dark = BbRedesignTokens(
    shellBg: Color(0xFF000000),
    // audit/127 dark-depth: #0B0B0D→#141414. Δ from #000 shell was only 11
    // (panel dead on the gutter with no shadow); #141414 = Δ20, panel lifts.
    panelBg: Color(0xFF141414),
    panelBorder: Color(0x0FFFFFFF), // rgba(255,255,255,.06)
    panelShadow: AppShadows.panelDark,
    mintWidget: Color(0xFF3DD9B0),
    purpleGlow: AppShadows.purpleSmDark,
    heroGradient: BBGradient.heroDark,
    brandPrimaryGradient: BBGradient.brandPrimary,
    statusConfirmedDeep: Color(0xFF4FAE7F),
    statusPendingDeep: Color(0xFFFFC872),
    statusCancelledDeep: Color(0xFFA0AEC0),
    statusConfirmedTint: Color(0x2E4FAE7F), // rgba(79,174,127,.18)
    statusPendingTint: Color(0x38FFC872), // rgba(255,200,114,.22)
    statusCancelledTint: Color(0x29A0AEC0), // rgba(160,174,192,.16)
    statusCompletedTint: Color(0x298B6FFF), // rgba(139,111,255,.16)
    statusImportedTint: Color(0x2E6BA8E8), // rgba(107,168,232,.18)
    focusRingColor: Color(0x528B6FFF), // rgba(139,111,255,.32)
    glassBg: Color(0x991E1E1E), // rgba(30,30,30,.60)
    glassBorder: Color(0x14FFFFFF), // rgba(255,255,255,.08)
    softBg: LinearGradient(
      // OLED-friendly near-black with subtle purple tint
      colors: <Color>[Color(0xFF0B0813), Color(0xFF14101F)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  /// Resolve via the current theme; falls back to [light] if not wired in.
  static BbRedesignTokens of(BuildContext context) {
    return Theme.of(context).extension<BbRedesignTokens>() ?? light;
  }

  @override
  BbRedesignTokens copyWith({
    Color? shellBg,
    Color? panelBg,
    Color? panelBorder,
    List<BoxShadow>? panelShadow,
    Color? mintWidget,
    List<BoxShadow>? purpleGlow,
    LinearGradient? heroGradient,
    LinearGradient? brandPrimaryGradient,
    Color? statusConfirmedDeep,
    Color? statusPendingDeep,
    Color? statusCancelledDeep,
    Color? statusConfirmedTint,
    Color? statusPendingTint,
    Color? statusCancelledTint,
    Color? statusCompletedTint,
    Color? statusImportedTint,
    Color? focusRingColor,
    Color? glassBg,
    Color? glassBorder,
    LinearGradient? softBg,
  }) {
    return BbRedesignTokens(
      shellBg: shellBg ?? this.shellBg,
      panelBg: panelBg ?? this.panelBg,
      panelBorder: panelBorder ?? this.panelBorder,
      panelShadow: panelShadow ?? this.panelShadow,
      mintWidget: mintWidget ?? this.mintWidget,
      purpleGlow: purpleGlow ?? this.purpleGlow,
      heroGradient: heroGradient ?? this.heroGradient,
      brandPrimaryGradient: brandPrimaryGradient ?? this.brandPrimaryGradient,
      statusConfirmedDeep: statusConfirmedDeep ?? this.statusConfirmedDeep,
      statusPendingDeep: statusPendingDeep ?? this.statusPendingDeep,
      statusCancelledDeep: statusCancelledDeep ?? this.statusCancelledDeep,
      statusConfirmedTint: statusConfirmedTint ?? this.statusConfirmedTint,
      statusPendingTint: statusPendingTint ?? this.statusPendingTint,
      statusCancelledTint: statusCancelledTint ?? this.statusCancelledTint,
      statusCompletedTint: statusCompletedTint ?? this.statusCompletedTint,
      statusImportedTint: statusImportedTint ?? this.statusImportedTint,
      focusRingColor: focusRingColor ?? this.focusRingColor,
      glassBg: glassBg ?? this.glassBg,
      glassBorder: glassBorder ?? this.glassBorder,
      softBg: softBg ?? this.softBg,
    );
  }

  @override
  BbRedesignTokens lerp(ThemeExtension<BbRedesignTokens>? other, double t) {
    if (other is! BbRedesignTokens) return this;
    return BbRedesignTokens(
      shellBg: Color.lerp(shellBg, other.shellBg, t) ?? shellBg,
      panelBg: Color.lerp(panelBg, other.panelBg, t) ?? panelBg,
      panelBorder: Color.lerp(panelBorder, other.panelBorder, t) ?? panelBorder,
      panelShadow: t < 0.5 ? panelShadow : other.panelShadow,
      mintWidget: Color.lerp(mintWidget, other.mintWidget, t) ?? mintWidget,
      purpleGlow: t < 0.5 ? purpleGlow : other.purpleGlow,
      heroGradient:
          LinearGradient.lerp(heroGradient, other.heroGradient, t) ??
          heroGradient,
      brandPrimaryGradient:
          LinearGradient.lerp(
            brandPrimaryGradient,
            other.brandPrimaryGradient,
            t,
          ) ??
          brandPrimaryGradient,
      statusConfirmedDeep:
          Color.lerp(statusConfirmedDeep, other.statusConfirmedDeep, t) ??
          statusConfirmedDeep,
      statusPendingDeep:
          Color.lerp(statusPendingDeep, other.statusPendingDeep, t) ??
          statusPendingDeep,
      statusCancelledDeep:
          Color.lerp(statusCancelledDeep, other.statusCancelledDeep, t) ??
          statusCancelledDeep,
      statusConfirmedTint:
          Color.lerp(statusConfirmedTint, other.statusConfirmedTint, t) ??
          statusConfirmedTint,
      statusPendingTint:
          Color.lerp(statusPendingTint, other.statusPendingTint, t) ??
          statusPendingTint,
      statusCancelledTint:
          Color.lerp(statusCancelledTint, other.statusCancelledTint, t) ??
          statusCancelledTint,
      statusCompletedTint:
          Color.lerp(statusCompletedTint, other.statusCompletedTint, t) ??
          statusCompletedTint,
      statusImportedTint:
          Color.lerp(statusImportedTint, other.statusImportedTint, t) ??
          statusImportedTint,
      focusRingColor:
          Color.lerp(focusRingColor, other.focusRingColor, t) ?? focusRingColor,
      glassBg: Color.lerp(glassBg, other.glassBg, t) ?? glassBg,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t) ?? glassBorder,
      softBg: LinearGradient.lerp(softBg, other.softBg, t) ?? softBg,
    );
  }
}

/// Admin-console dark deep-purple surfaces (`#1E1A33` family per
/// `design_handoff/README.md` §148 + `design_handoff/source/admin-shell.jsx`).
///
/// Admin chrome is a hybrid: dark deep-purple sidebar over a light body. This
/// extension carries only the **dark surface** tokens (sidebar, rail, profile
/// row, ADMIN tag, active nav glow). The light topbar + content surfaces still
/// resolve via the standard light [ThemeData] / [BbRedesignTokens.light].
///
/// **NOT wired into [AppTheme.darkTheme]** — owner dark mode keeps
/// [BbRedesignTokens.dark]. Admin shells consume this directly via
/// [BbAdminDarkTokens.preset] or via [BbAdminDarkTokens.of] when the admin
/// shell wraps a subtree in its own [Theme] that registers this extension.
@immutable
class BbAdminDarkTokens extends ThemeExtension<BbAdminDarkTokens> {
  const BbAdminDarkTokens({
    required this.shellBg,
    required this.panelBg,
    required this.divider,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.navTileIdleBg,
    required this.navTileActiveBg,
    required this.navTileActiveBorder,
    required this.navIconActiveGradient,
    required this.navActiveGlow,
    required this.adminBadgeBg,
    required this.adminBadgeFg,
    required this.profileSecondaryText,
  });

  /// Deep-purple console surface (`ADM_SB_BG = '#1E1A33'`). Used by sidebar +
  /// rail. Also the canonical "shell" surface for any future fully-dark admin
  /// subscreens.
  final Color shellBg;

  /// Slightly elevated dark surface for cards / panels that sit on [shellBg]
  /// in a fully-dark admin subscreen. Mirrors the shell↔panel layering in
  /// [BbRedesignTokens]. Derived as shellBg lifted ~+5% white toward purple.
  final Color panelBg;

  /// Hairline divider on dark (`ADM_SB_BORDER = 'rgba(255,255,255,0.08)'`).
  final Color divider;

  /// Primary on-dark text (`#FFFFFF`). Active nav label, sidebar brand title.
  final Color textPrimary;

  /// Idle on-dark text (`ADM_SB_TXT = 'rgba(255,255,255,0.72)'`). Idle nav
  /// label, profile name.
  final Color textSecondary;

  /// Tertiary on-dark text (`rgba(255,255,255,0.40)`). Nav-group uppercase
  /// labels.
  final Color textTertiary;

  /// Nav tile idle fill (`rgba(255,255,255,0.06)` full / `0.05` rail).
  final Color navTileIdleBg;

  /// Nav tile active fill (`rgba(255,255,255,0.08)`).
  final Color navTileActiveBg;

  /// Nav tile active border (`rgba(255,255,255,0.10)`).
  final Color navTileActiveBorder;

  /// Active nav icon-tile gradient (`var(--bb-gradient-hero)` — reuses the
  /// owner brand hero gradient on a dark surface).
  final LinearGradient navIconActiveGradient;

  /// Purple glow under active nav tile
  /// (`0 4px 12px / 0 6px 14px rgba(139,111,255,0.40)`).
  final List<BoxShadow> navActiveGlow;

  /// ADMIN tag pill fill (`rgba(139,111,255,0.28)`).
  final Color adminBadgeBg;

  /// ADMIN tag pill text (`#C9BBFF`).
  final Color adminBadgeFg;

  /// Secondary profile-row text (`rgba(255,255,255,0.5)`). Email, role.
  final Color profileSecondaryText;

  // ----- Preset --------------------------------------------------------------

  /// Canonical admin dark surface set. Hex values transcribed verbatim from
  /// `design_handoff/source/admin-shell.jsx`.
  static const BbAdminDarkTokens preset = BbAdminDarkTokens(
    shellBg: Color(0xFF1E1A33),
    panelBg: Color(0xFF2A2342), // shellBg lifted ~+5% white (elevated panel)
    divider: Color(0x14FFFFFF), // rgba(255,255,255,0.08)
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xB8FFFFFF), // rgba(255,255,255,0.72)
    // white@0.50 = computed minimum clearing 4.5:1 composited over every
    // admin surface (#2A2342 worst case 4.81:1; the old 0.40 measured
    // 3.62:1 — audit F3.4, #951 class: admin was never covered).
    textTertiary: Color(0x80FFFFFF), // rgba(255,255,255,0.50)
    navTileIdleBg: Color(0x0FFFFFFF), // rgba(255,255,255,0.06)
    navTileActiveBg: Color(0x14FFFFFF), // rgba(255,255,255,0.08)
    navTileActiveBorder: Color(0x1AFFFFFF), // rgba(255,255,255,0.10)
    navIconActiveGradient: BBGradient.hero,
    navActiveGlow: <BoxShadow>[
      BoxShadow(
        color: Color(0x668B6FFF), // rgba(139,111,255,0.40)
        blurRadius: 12,
        offset: Offset(0, 4),
      ),
    ],
    adminBadgeBg: Color(0x478B6FFF), // rgba(139,111,255,0.28)
    adminBadgeFg: Color(0xFFC9BBFF),
    profileSecondaryText: Color(0x80FFFFFF), // rgba(255,255,255,0.5)
  );

  /// Resolve via the current theme; falls back to [preset] when no admin
  /// theme is wired (the common case — admin shell is the only consumer).
  static BbAdminDarkTokens of(BuildContext context) {
    return Theme.of(context).extension<BbAdminDarkTokens>() ?? preset;
  }

  @override
  BbAdminDarkTokens copyWith({
    Color? shellBg,
    Color? panelBg,
    Color? divider,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? navTileIdleBg,
    Color? navTileActiveBg,
    Color? navTileActiveBorder,
    LinearGradient? navIconActiveGradient,
    List<BoxShadow>? navActiveGlow,
    Color? adminBadgeBg,
    Color? adminBadgeFg,
    Color? profileSecondaryText,
  }) {
    return BbAdminDarkTokens(
      shellBg: shellBg ?? this.shellBg,
      panelBg: panelBg ?? this.panelBg,
      divider: divider ?? this.divider,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      navTileIdleBg: navTileIdleBg ?? this.navTileIdleBg,
      navTileActiveBg: navTileActiveBg ?? this.navTileActiveBg,
      navTileActiveBorder: navTileActiveBorder ?? this.navTileActiveBorder,
      navIconActiveGradient:
          navIconActiveGradient ?? this.navIconActiveGradient,
      navActiveGlow: navActiveGlow ?? this.navActiveGlow,
      adminBadgeBg: adminBadgeBg ?? this.adminBadgeBg,
      adminBadgeFg: adminBadgeFg ?? this.adminBadgeFg,
      profileSecondaryText: profileSecondaryText ?? this.profileSecondaryText,
    );
  }

  @override
  BbAdminDarkTokens lerp(ThemeExtension<BbAdminDarkTokens>? other, double t) {
    if (other is! BbAdminDarkTokens) return this;
    return BbAdminDarkTokens(
      shellBg: Color.lerp(shellBg, other.shellBg, t) ?? shellBg,
      panelBg: Color.lerp(panelBg, other.panelBg, t) ?? panelBg,
      divider: Color.lerp(divider, other.divider, t) ?? divider,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t) ?? textPrimary,
      textSecondary:
          Color.lerp(textSecondary, other.textSecondary, t) ?? textSecondary,
      textTertiary:
          Color.lerp(textTertiary, other.textTertiary, t) ?? textTertiary,
      navTileIdleBg:
          Color.lerp(navTileIdleBg, other.navTileIdleBg, t) ?? navTileIdleBg,
      navTileActiveBg:
          Color.lerp(navTileActiveBg, other.navTileActiveBg, t) ??
          navTileActiveBg,
      navTileActiveBorder:
          Color.lerp(navTileActiveBorder, other.navTileActiveBorder, t) ??
          navTileActiveBorder,
      navIconActiveGradient:
          LinearGradient.lerp(
            navIconActiveGradient,
            other.navIconActiveGradient,
            t,
          ) ??
          navIconActiveGradient,
      navActiveGlow: t < 0.5 ? navActiveGlow : other.navActiveGlow,
      adminBadgeBg:
          Color.lerp(adminBadgeBg, other.adminBadgeBg, t) ?? adminBadgeBg,
      adminBadgeFg:
          Color.lerp(adminBadgeFg, other.adminBadgeFg, t) ?? adminBadgeFg,
      profileSecondaryText:
          Color.lerp(profileSecondaryText, other.profileSecondaryText, t) ??
          profileSecondaryText,
    );
  }
}
