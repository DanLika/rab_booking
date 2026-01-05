/// Opacity design tokens for consistent transparency values
///
/// Usage:
/// ```dart
/// Container(
///   color: Colors.black.withOpacity(OpacityTokens.mediumOverlay),
/// )
///
/// Opacity(
///   opacity: OpacityTokens.mostlyVisible,
///   child: Widget(),
/// )
/// ```
class OpacityTokens {
  // Prevent instantiation
  OpacityTokens._();

  // ============================================================
  // OPACITY VALUES (0.0 - 1.0)
  // ============================================================

  /// Fully transparent (0%)
  static const double transparent = 0.0;

  /// Subtle overlay - barely visible (4%)
  /// Use for: Very subtle background tints
  static const double subtleOverlay = 0.04;

  /// Light overlay - lightly visible (8%)
  /// Use for: Light background overlays, hover states
  static const double lightOverlay = 0.08;

  /// Medium overlay - clearly visible (12%)
  /// Use for: Disabled states, placeholder backgrounds
  static const double mediumOverlay = 0.12;

  /// Visible - noticeable overlay (16%)
  /// Use for: Secondary backgrounds, dividers
  static const double visible = 0.16;

  /// Semi-transparent - moderately transparent (30%)
  /// Use for: Modal backgrounds, scrim overlays
  static const double semiTransparent = 0.3;

  /// Badge subtle - for powered by badge (40%)
  /// Use for: Subtle badges, watermarks
  static const double badgeSubtle = 0.4;

  /// Mostly visible - half transparent (50%)
  /// Use for: Loading overlays, dimmed content
  static const double mostlyVisible = 0.5;

  /// Mostly opaque - slightly transparent (70%)
  /// Use for: Semi-visible content, faded elements
  static const double mostlyOpaque = 0.7;

  /// Almost opaque - barely transparent (90%)
  /// Use for: Nearly solid backgrounds with slight transparency
  static const double almostOpaque = 0.9;

  /// Fully opaque (100%)
  static const double opaque = 1.0;

  // ============================================================
  // SHADOW OPACITY (For BoxShadow color.withValues)
  // ============================================================

  /// Shadow subtle - very light shadow (5%)
  static const double shadowSubtle = 0.05;

  /// Shadow light - light shadow (8%)
  static const double shadowLight = 0.08;

  /// Shadow medium - standard shadow (10%)
  static const double shadowMedium = 0.1;

  /// Shadow strong - prominent shadow (15%)
  static const double shadowStrong = 0.15;

  /// Shadow heavy - heavy shadow (20%)
  static const double shadowHeavy = 0.2;
}
