import 'package:flutter/material.dart';
import 'villa_jasko_colors.dart';

/// Modern multi-layer shadow system
/// Based on 2024-2025 design trends with depth and sophistication
class ModernShadows {
  ModernShadows._(); // Private constructor

  // ============================================================================
  // ELEVATION LEVELS (0-5)
  // ============================================================================

  /// Level 0 - No shadow (flat elements)
  static List<BoxShadow> get none => [];

  /// Level 1 - Subtle shadow (cards, chips, badges)
  /// Single layer: 1px blur, very light
  static List<BoxShadow> get level1 => [
        BoxShadow(
          color: VillaJaskoColors.shadowLight.withValues(alpha: 0.05),
          blurRadius: 1,
          spreadRadius: 0,
          offset: const Offset(0, 1),
        ),
      ];

  /// Level 2 - Small shadow (buttons, inputs, small cards)
  /// Two layers: subtle depth + soft glow
  static List<BoxShadow> get level2 => [
        BoxShadow(
          color: VillaJaskoColors.shadowLight.withValues(alpha: 0.08),
          blurRadius: 3,
          spreadRadius: 0,
          offset: const Offset(0, 1),
        ),
        BoxShadow(
          color: VillaJaskoColors.shadowLight.withValues(alpha: 0.04),
          blurRadius: 6,
          spreadRadius: 0,
          offset: const Offset(0, 2),
        ),
      ];

  /// Level 3 - Medium shadow (elevated cards, dropdowns, popovers)
  /// Three layers: crisp edge + medium blur + soft ambient
  static List<BoxShadow> get level3 => [
        BoxShadow(
          color: VillaJaskoColors.shadowLight.withValues(alpha: 0.10),
          blurRadius: 4,
          spreadRadius: 0,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: VillaJaskoColors.shadowLight.withValues(alpha: 0.06),
          blurRadius: 8,
          spreadRadius: 0,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: VillaJaskoColors.shadowLight.withValues(alpha: 0.04),
          blurRadius: 16,
          spreadRadius: 0,
          offset: const Offset(0, 8),
        ),
      ];

  /// Level 4 - Large shadow (modals, dialogs, floating panels)
  /// Four layers: prominent depth with soft edges
  static List<BoxShadow> get level4 => [
        BoxShadow(
          color: VillaJaskoColors.shadowMedium.withValues(alpha: 0.12),
          blurRadius: 6,
          spreadRadius: 0,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: VillaJaskoColors.shadowMedium.withValues(alpha: 0.08),
          blurRadius: 12,
          spreadRadius: 0,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: VillaJaskoColors.shadowLight.withValues(alpha: 0.06),
          blurRadius: 24,
          spreadRadius: 0,
          offset: const Offset(0, 16),
        ),
        BoxShadow(
          color: VillaJaskoColors.shadowLight.withValues(alpha: 0.04),
          blurRadius: 40,
          spreadRadius: 0,
          offset: const Offset(0, 24),
        ),
      ];

  /// Level 5 - Extra large shadow (overlays, tooltips, mega menus)
  /// Five layers: dramatic depth with ultra-soft edges
  static List<BoxShadow> get level5 => [
        BoxShadow(
          color: VillaJaskoColors.shadowStrong.withValues(alpha: 0.15),
          blurRadius: 8,
          spreadRadius: 0,
          offset: const Offset(0, 6),
        ),
        BoxShadow(
          color: VillaJaskoColors.shadowMedium.withValues(alpha: 0.10),
          blurRadius: 16,
          spreadRadius: 0,
          offset: const Offset(0, 12),
        ),
        BoxShadow(
          color: VillaJaskoColors.shadowMedium.withValues(alpha: 0.08),
          blurRadius: 32,
          spreadRadius: 0,
          offset: const Offset(0, 24),
        ),
        BoxShadow(
          color: VillaJaskoColors.shadowLight.withValues(alpha: 0.06),
          blurRadius: 48,
          spreadRadius: 0,
          offset: const Offset(0, 32),
        ),
        BoxShadow(
          color: VillaJaskoColors.shadowLight.withValues(alpha: 0.04),
          blurRadius: 64,
          spreadRadius: 0,
          offset: const Offset(0, 48),
        ),
      ];

  // ============================================================================
  // COMPONENT-SPECIFIC SHADOWS
  // ============================================================================

  /// Button shadow (default state)
  static List<BoxShadow> get button => level2;

  /// Button shadow (hover state) - More prominent
  static List<BoxShadow> get buttonHover => level3;

  /// Button shadow (pressed state) - Reduced
  static List<BoxShadow> get buttonPressed => level1;

  /// Card shadow (default)
  static List<BoxShadow> get card => level2;

  /// Card shadow (hover state) - Lifted
  static List<BoxShadow> get cardHover => level3;

  /// Input field shadow (focus state)
  static List<BoxShadow> get inputFocus => [
        BoxShadow(
          color: VillaJaskoColors.primary.withValues(alpha: 0.15),
          blurRadius: 8,
          spreadRadius: 0,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: VillaJaskoColors.primary.withValues(alpha: 0.08),
          blurRadius: 16,
          spreadRadius: 0,
          offset: const Offset(0, 4),
        ),
      ];

  /// Dropdown/popover shadow
  static List<BoxShadow> get dropdown => level3;

  /// Modal/dialog shadow
  static List<BoxShadow> get modal => level4;

  /// Tooltip shadow
  static List<BoxShadow> get tooltip => level3;

  /// Calendar cell shadow (hover state)
  static List<BoxShadow> get calendarCellHover => [
        BoxShadow(
          color: VillaJaskoColors.primary.withValues(alpha: 0.10),
          blurRadius: 6,
          spreadRadius: 0,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: VillaJaskoColors.primary.withValues(alpha: 0.05),
          blurRadius: 12,
          spreadRadius: 0,
          offset: const Offset(0, 4),
        ),
      ];

  /// Calendar cell shadow (selected state)
  static List<BoxShadow> get calendarCellSelected => [
        BoxShadow(
          color: VillaJaskoColors.primary.withValues(alpha: 0.20),
          blurRadius: 8,
          spreadRadius: 0,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: VillaJaskoColors.primary.withValues(alpha: 0.10),
          blurRadius: 16,
          spreadRadius: 0,
          offset: const Offset(0, 4),
        ),
      ];

  /// Floating action button shadow
  static List<BoxShadow> get fab => level3;

  /// Floating action button shadow (hover)
  static List<BoxShadow> get fabHover => level4;

  // ============================================================================
  // COLORED SHADOWS (for brand elements)
  // ============================================================================

  /// Primary teal shadow (for primary buttons, CTAs)
  static List<BoxShadow> get primaryShadow => [
        BoxShadow(
          color: VillaJaskoColors.primary.withValues(alpha: 0.25),
          blurRadius: 8,
          spreadRadius: 0,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: VillaJaskoColors.primary.withValues(alpha: 0.15),
          blurRadius: 16,
          spreadRadius: 0,
          offset: const Offset(0, 8),
        ),
      ];

  /// Success shadow (for success messages, confirmations)
  static List<BoxShadow> get successShadow => [
        BoxShadow(
          color: VillaJaskoColors.success.withValues(alpha: 0.20),
          blurRadius: 8,
          spreadRadius: 0,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: VillaJaskoColors.success.withValues(alpha: 0.10),
          blurRadius: 16,
          spreadRadius: 0,
          offset: const Offset(0, 8),
        ),
      ];

  /// Error shadow (for error messages, alerts)
  static List<BoxShadow> get errorShadow => [
        BoxShadow(
          color: VillaJaskoColors.error.withValues(alpha: 0.20),
          blurRadius: 8,
          spreadRadius: 0,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: VillaJaskoColors.error.withValues(alpha: 0.10),
          blurRadius: 16,
          spreadRadius: 0,
          offset: const Offset(0, 8),
        ),
      ];

  // ============================================================================
  // INNER SHADOWS (for pressed states, inset elements)
  // ============================================================================

  /// Inner shadow (for pressed buttons, inset panels)
  /// Note: Flutter doesn't support inset shadows directly in BoxShadow
  /// Use this with a custom painter or shader if needed
  static List<BoxShadow> get innerShadow => [
        BoxShadow(
          color: VillaJaskoColors.shadowMedium.withValues(alpha: 0.10),
          blurRadius: 4,
          spreadRadius: -2,
          offset: const Offset(0, 2),
        ),
      ];

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Get shadow by elevation level (0-5)
  static List<BoxShadow> getByLevel(int level) {
    switch (level) {
      case 0:
        return none;
      case 1:
        return level1;
      case 2:
        return level2;
      case 3:
        return level3;
      case 4:
        return level4;
      case 5:
        return level5;
      default:
        return level2; // Default to level2
    }
  }

  /// Create custom shadow with specific parameters
  static List<BoxShadow> custom({
    required Color color,
    required double blurRadius,
    double spreadRadius = 0,
    Offset offset = Offset.zero,
  }) {
    return [
      BoxShadow(
        color: color,
        blurRadius: blurRadius,
        spreadRadius: spreadRadius,
        offset: offset,
      ),
    ];
  }

  /// Apply shadow to BoxDecoration
  static BoxDecoration applyToDecoration({
    required List<BoxShadow> shadows,
    Color? color,
    BorderRadius? borderRadius,
    Border? border,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: borderRadius,
      border: border,
      boxShadow: shadows,
    );
  }
}
