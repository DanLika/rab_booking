import 'package:flutter/widgets.dart';

/// Shadow design tokens for consistent elevation across the widget
class ShadowTokens {
  // Modern, subtle shadows (not too strong)

  // No shadow
  static List<BoxShadow> get none => [];

  // Subtle shadow - for slightly elevated elements
  static List<BoxShadow> get subtle => [
        const BoxShadow(
          color: Color(0x0A000000), // 4% opacity black
          offset: Offset(0, 1),
          blurRadius: 2,
          spreadRadius: 0,
        ),
      ];

  // Light shadow - for cards and containers
  static List<BoxShadow> get light => [
        const BoxShadow(
          color: Color(0x14000000), // 8% opacity black
          offset: Offset(0, 2),
          blurRadius: 8,
          spreadRadius: 0,
        ),
      ];

  // Medium shadow - for elevated cards
  static List<BoxShadow> get medium => [
        const BoxShadow(
          color: Color(0x0A000000), // 4% opacity black
          offset: Offset(0, 2),
          blurRadius: 4,
          spreadRadius: -1,
        ),
        const BoxShadow(
          color: Color(0x1F000000), // 12% opacity black
          offset: Offset(0, 4),
          blurRadius: 12,
          spreadRadius: 0,
        ),
      ];

  // Strong shadow - for modals and popovers
  static List<BoxShadow> get strong => [
        const BoxShadow(
          color: Color(0x29000000), // 16% opacity black
          offset: Offset(0, 8),
          blurRadius: 24,
          spreadRadius: 0,
        ),
      ];

  // Hover shadow - for interactive elements on hover
  static List<BoxShadow> get hover => [
        const BoxShadow(
          color: Color(0x1F000000), // 12% opacity black
          offset: Offset(0, 6),
          blurRadius: 20,
          spreadRadius: 0,
        ),
      ];

  // Calendar cell hover shadow (very subtle)
  static List<BoxShadow> get calendarCellHover => [
        const BoxShadow(
          color: Color(0x0A000000), // 4% opacity black
          offset: Offset(0, 2),
          blurRadius: 4,
          spreadRadius: 0,
        ),
      ];

  // Widget container shadow (optional outer shadow)
  static List<BoxShadow> get widgetContainer => light;
}
