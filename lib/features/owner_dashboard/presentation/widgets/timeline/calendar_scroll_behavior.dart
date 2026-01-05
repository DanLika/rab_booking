import 'dart:ui' show PointerDeviceKind;
import 'package:flutter/material.dart';

/// Cross-platform scroll behavior for calendar widgets
/// Normalizes scroll behavior across Android, iOS, web, and desktop
///
/// Key features:
/// - Enables mouse drag for desktop testing/usage
/// - Enables trackpad gestures on macOS/Windows
/// - Removes Android overscroll glow for consistent look
/// - Works with any ScrollPhysics (your TimelineSnapScrollPhysics)
class CalendarScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse, // Enable mouse drag for desktop
    PointerDeviceKind.trackpad, // Enable trackpad gestures
    PointerDeviceKind.stylus,
  };

  // NOTE: Do NOT override getScrollPhysics() here!
  // The widget's physics parameter (TimelineSnapScrollPhysics) must take precedence.
  // Overriding with AlwaysScrollableScrollPhysics destroys the snap behavior.

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    // Remove Android's glow indicator for consistent cross-platform look
    return child;
  }
}
