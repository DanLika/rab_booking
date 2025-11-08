import 'package:flutter/animation.dart';

/// Animation design tokens for consistent timing and easing
///
/// Usage:
/// ```dart
/// AnimatedContainer(
///   duration: AnimationTokens.fast,
///   curve: AnimationTokens.easeOut,
/// )
///
/// AnimatedOpacity(
///   duration: AnimationTokens.normal,
///   curve: AnimationTokens.easeInOut,
/// )
/// ```
class AnimationTokens {
  // Prevent instantiation
  AnimationTokens._();

  // ============================================================
  // DURATION TOKENS
  // ============================================================

  /// Instant - 100ms
  /// Use for: Immediate feedback, button presses
  static const Duration instant = Duration(milliseconds: 100);

  /// Fast - 200ms
  /// Use for: Quick transitions, hover effects, tooltips
  static const Duration fast = Duration(milliseconds: 200);

  /// Normal - 300ms (default)
  /// Use for: Standard transitions, modals, dialogs
  static const Duration normal = Duration(milliseconds: 300);

  /// Slow - 500ms
  /// Use for: Page transitions, complex animations
  static const Duration slow = Duration(milliseconds: 500);

  /// Slower - 600ms
  /// Use for: Entrance animations, attention-grabbing effects
  static const Duration slower = Duration(milliseconds: 600);

  /// Long - 1000ms (1 second)
  /// Use for: Loading animations, progress indicators
  static const Duration long = Duration(milliseconds: 1000);

  /// Notification - 3 seconds
  /// Use for: Toast messages, snackbars
  static const Duration notification = Duration(seconds: 3);

  /// Auto-dismiss - 5 seconds
  /// Use for: Auto-dismissing notifications
  static const Duration autoDismiss = Duration(seconds: 5);

  // ============================================================
  // EASING CURVES
  // ============================================================

  /// Linear - No easing
  /// Use for: Loading spinners, progress bars
  static const Curve linear = Curves.linear;

  /// Ease - Slight acceleration at start and deceleration at end
  /// Use for: General purpose animations
  static const Curve ease = Curves.ease;

  /// Ease In - Slow start, fast finish
  /// Use for: Exit animations
  static const Curve easeIn = Curves.easeIn;

  /// Ease Out - Fast start, slow finish
  /// Use for: Entrance animations (recommended for most UI)
  static const Curve easeOut = Curves.easeOut;

  /// Ease In Out - Slow start and finish
  /// Use for: Smooth transitions between states
  static const Curve easeInOut = Curves.easeInOut;

  /// Fast Out Slow In - Material Design standard
  /// Use for: Material Design transitions
  static const Curve fastOutSlowIn = Curves.fastOutSlowIn;

  /// Elastic Out - Bouncy effect at end
  /// Use for: Playful animations, success feedback
  static const Curve elasticOut = Curves.elasticOut;

  /// Bounce Out - Bouncing effect
  /// Use for: Attention-grabbing animations
  static const Curve bounceOut = Curves.bounceOut;

  /// Decelerate - Fast start, gradual slow down
  /// Use for: Natural-feeling movements
  static const Curve decelerate = Curves.decelerate;

  // ============================================================
  // COMMON ANIMATION CONFIGURATIONS
  // ============================================================

  /// Fade transition configuration
  static const Duration fadeDuration = fast;
  static const Curve fadeCurve = easeOut;

  /// Scale transition configuration
  static const Duration scaleDuration = normal;
  static const Curve scaleCurve = fastOutSlowIn;

  /// Slide transition configuration
  static const Duration slideDuration = normal;
  static const Curve slideCurve = easeOut;

  /// Rotation transition configuration
  static const Duration rotationDuration = normal;
  static const Curve rotationCurve = easeInOut;
}
