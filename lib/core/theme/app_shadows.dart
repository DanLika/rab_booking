import 'package:flutter/material.dart';

/// Application shadow and elevation system
/// Provides premium shadows with 5 elevation levels and custom effects
class AppShadows {
  AppShadows._(); // Private constructor

  // ============================================================================
  // ELEVATION SYSTEM (5 levels)
  // ============================================================================

  /// Level 0: No shadow (flat)
  static const List<BoxShadow> elevation0 = [];

  /// Level 1: Subtle shadow for cards, chips (1dp elevation)
  /// Soft shadow, minimal depth
  static const List<BoxShadow> elevation1 = [
    BoxShadow(
      color: Color(0x0D000000), // 5% black
      blurRadius: 2,
      offset: Offset(0, 1),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color(0x0A000000), // 4% black
      blurRadius: 1,
      offset: Offset(0, 1),
      spreadRadius: 0,
    ),
  ];

  /// Level 2: Medium shadow for floating buttons, dropdowns (2-4dp elevation)
  /// Noticeable shadow, moderate depth - ENHANCED for premium feel
  static const List<BoxShadow> elevation2 = [
    BoxShadow(
      color: Color(0x1F000000), // 12% black (increased from 8%)
      blurRadius: 8,             // Increased from 4
      offset: Offset(0, 4),      // Increased from 2
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color(0x14000000), // 8% black (increased from 6%)
      blurRadius: 4,             // Increased from 2
      offset: Offset(0, 2),      // Increased from 1
      spreadRadius: 0,
    ),
  ];

  /// Level 3: Strong shadow for modals, app bars (6-8dp elevation)
  /// Clear shadow, significant depth - ENHANCED for premium feel
  static const List<BoxShadow> elevation3 = [
    BoxShadow(
      color: Color(0x26000000), // 15% black (increased from 10%)
      blurRadius: 16,            // Doubled from 8
      offset: Offset(0, 8),      // Doubled from 4
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color(0x1A000000), // 10% black (increased from 8%)
      blurRadius: 8,             // Doubled from 4
      offset: Offset(0, 4),      // Doubled from 2
      spreadRadius: 0,
    ),
  ];

  /// Level 4: Deep shadow for dialogs, sheets (12-16dp elevation)
  /// Strong shadow, deep depth - ENHANCED for premium feel
  static const List<BoxShadow> elevation4 = [
    BoxShadow(
      color: Color(0x33000000), // 20% black (increased from 15%)
      blurRadius: 24,            // Increased from 16
      offset: Offset(0, 12),     // Increased from 8
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color(0x26000000), // 15% black (increased from 12%)
      blurRadius: 16,            // Doubled from 8
      offset: Offset(0, 8),      // Doubled from 4
      spreadRadius: 0,
    ),
  ];

  /// Level 5: Maximum shadow for tooltips, popovers (24dp elevation)
  /// Very strong shadow, maximum depth
  static const List<BoxShadow> elevation5 = [
    BoxShadow(
      color: Color(0x33000000), // 20% black
      blurRadius: 24,
      offset: Offset(0, 12),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color(0x29000000), // 16% black
      blurRadius: 12,
      offset: Offset(0, 6),
      spreadRadius: 0,
    ),
  ];

  // ============================================================================
  // COLORED SHADOWS (for premium effects - Mediterranean palette)
  // ============================================================================

  /// Primary colored shadow (Azure Blue glow)
  static const List<BoxShadow> primaryShadow = [
    BoxShadow(
      color: Color(0x400066FF), // 25% Azure Blue
      blurRadius: 24,
      offset: Offset(0, 8),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color(0x1A0066FF), // 10% Azure Blue (subtle outer glow)
      blurRadius: 32,
      offset: Offset(0, 12),
      spreadRadius: 0,
    ),
  ];

  /// Secondary colored shadow (Coral Red glow)
  static const List<BoxShadow> secondaryShadow = [
    BoxShadow(
      color: Color(0x40FF6B6B), // 25% Coral Red
      blurRadius: 24,
      offset: Offset(0, 8),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color(0x1AFF6B6B), // 10% Coral Red (subtle outer glow)
      blurRadius: 32,
      offset: Offset(0, 12),
      spreadRadius: 0,
    ),
  ];

  /// Tertiary colored shadow (Golden Sand glow)
  static const List<BoxShadow> tertiaryShadow = [
    BoxShadow(
      color: Color(0x40FFB84D), // 25% Golden Sand
      blurRadius: 24,
      offset: Offset(0, 8),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color(0x1AFFB84D), // 10% Golden Sand (subtle outer glow)
      blurRadius: 32,
      offset: Offset(0, 12),
      spreadRadius: 0,
    ),
  ];

  /// Success colored shadow (green glow)
  static const List<BoxShadow> successShadow = [
    BoxShadow(
      color: Color(0x3310B981), // 20% success green
      blurRadius: 16,
      offset: Offset(0, 4),
      spreadRadius: 0,
    ),
  ];

  /// Error colored shadow (red glow)
  static const List<BoxShadow> errorShadow = [
    BoxShadow(
      color: Color(0x33EF4444), // 20% error red
      blurRadius: 16,
      offset: Offset(0, 4),
      spreadRadius: 0,
    ),
  ];

  // ============================================================================
  // SPECIAL EFFECT SHADOWS
  // ============================================================================

  /// Soft inner shadow (for pressed/inset effects) - ENHANCED for premium feel
  static const List<BoxShadow> innerShadow = [
    BoxShadow(
      color: Color(0x1A000000), // 10% black (inner shadow)
      blurRadius: 4,
      offset: Offset(2, 2),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color(0x1AFFFFFF), // 10% white (inner highlight)
      blurRadius: 4,
      offset: Offset(-2, -2),
      spreadRadius: 0,
    ),
  ];

  /// Glow effect (soft, large spread)
  static const List<BoxShadow> glow = [
    BoxShadow(
      color: Color(0x33FFFFFF), // 20% white
      blurRadius: 20,
      offset: Offset(0, 0),
      spreadRadius: 4,
    ),
  ];

  /// Glow effect with primary color (Azure Blue)
  static const List<BoxShadow> glowPrimary = [
    BoxShadow(
      color: Color(0x4D0066FF), // 30% Azure Blue
      blurRadius: 32,
      offset: Offset(0, 0),
      spreadRadius: 4,
    ),
    BoxShadow(
      color: Color(0x260066FF), // 15% Azure Blue (outer glow)
      blurRadius: 48,
      offset: Offset(0, 0),
      spreadRadius: 8,
    ),
  ];

  /// Glow effect with secondary color (Coral Red)
  static const List<BoxShadow> glowSecondary = [
    BoxShadow(
      color: Color(0x4DFF6B6B), // 30% Coral Red
      blurRadius: 32,
      offset: Offset(0, 0),
      spreadRadius: 4,
    ),
    BoxShadow(
      color: Color(0x26FF6B6B), // 15% Coral Red (outer glow)
      blurRadius: 48,
      offset: Offset(0, 0),
      spreadRadius: 8,
    ),
  ];

  /// Glow effect with tertiary color (Golden Sand)
  static const List<BoxShadow> glowTertiary = [
    BoxShadow(
      color: Color(0x4DFFB84D), // 30% Golden Sand
      blurRadius: 32,
      offset: Offset(0, 0),
      spreadRadius: 4,
    ),
    BoxShadow(
      color: Color(0x26FFB84D), // 15% Golden Sand (outer glow)
      blurRadius: 48,
      offset: Offset(0, 0),
      spreadRadius: 8,
    ),
  ];

  /// Neumorphic shadow (raised effect)
  static const List<BoxShadow> neumorphicRaised = [
    BoxShadow(
      color: Color(0x1AFFFFFF), // 10% white (light)
      blurRadius: 8,
      offset: Offset(-4, -4),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color(0x1A000000), // 10% black (shadow)
      blurRadius: 8,
      offset: Offset(4, 4),
      spreadRadius: 0,
    ),
  ];

  /// Neumorphic shadow (pressed/inset effect)
  static const List<BoxShadow> neumorphicPressed = [
    BoxShadow(
      color: Color(0x1A000000), // 10% black (inner shadow)
      blurRadius: 6,
      offset: Offset(2, 2),
      spreadRadius: -2,
    ),
    BoxShadow(
      color: Color(0x0DFFFFFF), // 5% white (inner highlight)
      blurRadius: 6,
      offset: Offset(-2, -2),
      spreadRadius: -2,
    ),
  ];

  // ============================================================================
  // DARK MODE SHADOWS
  // ============================================================================

  /// Dark mode elevation 1 (lighter shadows for dark backgrounds)
  static const List<BoxShadow> elevation1Dark = [
    BoxShadow(
      color: Color(0x33000000), // 20% black
      blurRadius: 4,
      offset: Offset(0, 2),
      spreadRadius: 0,
    ),
  ];

  /// Dark mode elevation 2
  static const List<BoxShadow> elevation2Dark = [
    BoxShadow(
      color: Color(0x40000000), // 25% black
      blurRadius: 8,
      offset: Offset(0, 4),
      spreadRadius: 0,
    ),
  ];

  /// Dark mode elevation 3
  static const List<BoxShadow> elevation3Dark = [
    BoxShadow(
      color: Color(0x4D000000), // 30% black
      blurRadius: 12,
      offset: Offset(0, 6),
      spreadRadius: 0,
    ),
  ];

  /// Dark mode elevation 4
  static const List<BoxShadow> elevation4Dark = [
    BoxShadow(
      color: Color(0x59000000), // 35% black
      blurRadius: 16,
      offset: Offset(0, 8),
      spreadRadius: 0,
    ),
  ];

  /// Dark mode elevation 5
  static const List<BoxShadow> elevation5Dark = [
    BoxShadow(
      color: Color(0x66000000), // 40% black
      blurRadius: 24,
      offset: Offset(0, 12),
      spreadRadius: 0,
    ),
  ];

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Get elevation shadow based on level (0-5)
  static List<BoxShadow> getElevation(int level, {bool isDark = false}) {
    if (isDark) {
      switch (level) {
        case 0:
          return elevation0;
        case 1:
          return elevation1Dark;
        case 2:
          return elevation2Dark;
        case 3:
          return elevation3Dark;
        case 4:
          return elevation4Dark;
        case 5:
          return elevation5Dark;
        default:
          return elevation2Dark;
      }
    } else {
      switch (level) {
        case 0:
          return elevation0;
        case 1:
          return elevation1;
        case 2:
          return elevation2;
        case 3:
          return elevation3;
        case 4:
          return elevation4;
        case 5:
          return elevation5;
        default:
          return elevation2;
      }
    }
  }

  /// Get colored shadow based on color name
  static List<BoxShadow> getColoredShadow(String color) {
    switch (color.toLowerCase()) {
      case 'primary':
        return primaryShadow;
      case 'secondary':
        return secondaryShadow;
      case 'tertiary':
        return tertiaryShadow;
      case 'success':
        return successShadow;
      case 'error':
        return errorShadow;
      default:
        return elevation2;
    }
  }

  /// Create custom shadow with specified parameters
  static List<BoxShadow> custom({
    required Color color,
    double blurRadius = 8.0,
    Offset offset = const Offset(0, 4),
    double spreadRadius = 0,
  }) {
    return [
      BoxShadow(
        color: color,
        blurRadius: blurRadius,
        offset: offset,
        spreadRadius: spreadRadius,
      ),
    ];
  }
}
