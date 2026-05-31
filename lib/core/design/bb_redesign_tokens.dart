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
  });

  /// Outer console background (`--bb-shell-bg`). Light `#F0F1F5` / dark `#000000`.
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

  // ----- Theme presets -------------------------------------------------------

  static const BbRedesignTokens light = BbRedesignTokens(
    shellBg: Color(0xFFF0F1F5),
    panelBg: Color(0xFFFBFBFD),
    panelBorder: Color(0x0D14182D), // rgba(20,24,45,.05)
    panelShadow: AppShadows.panelLight,
    mintWidget: Color(0xFF3DD9B0),
    purpleGlow: AppShadows.purpleSm,
    heroGradient: BBGradient.hero,
    brandPrimaryGradient: BBGradient.brandPrimary,
    statusConfirmedDeep: Color(0xFF2E7D5B),
    statusPendingDeep: Color(0xFFB7791F), // AA-safe darker amber
    statusCancelledDeep: Color(0xFF4A5568),
    statusConfirmedTint: Color(0x1F2E7D5B), // rgba(46,125,91,.12)
    statusPendingTint: Color(0x2EFFB84D), // rgba(255,184,77,.18)
    statusCancelledTint: Color(0x24718096), // rgba(113,128,150,.14)
    statusCompletedTint: Color(0x1A6B4CE6), // rgba(107,76,230,.10)
    statusImportedTint: Color(0x1F4A90D9), // rgba(74,144,217,.12)
    focusRingColor: Color(0x386B4CE6), // rgba(107,76,230,.22)
    glassBg: Color(0xB8FFFFFF), // rgba(255,255,255,.72)
    glassBorder: Color(0x80FFFFFF), // rgba(255,255,255,.50)
  );

  static const BbRedesignTokens dark = BbRedesignTokens(
    shellBg: Color(0xFF000000),
    panelBg: Color(0xFF0B0B0D),
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
    );
  }
}
