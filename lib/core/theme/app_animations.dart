import 'package:flutter/animation.dart';

/// Application animation constants
/// Provides standardized durations, curves, and animation configurations
class AppAnimations {
  AppAnimations._(); // Private constructor

  // ============================================================================
  // ANIMATION DURATIONS
  // ============================================================================

  /// Instant (no animation) - 0ms
  static const Duration instant = Duration.zero;

  /// Extra fast duration - 100ms
  /// Use for: Micro-interactions, ripples, state changes
  static const Duration extraFast = Duration(milliseconds: 100);

  /// Fast duration - 150ms
  /// Use for: Quick transitions, hover effects
  static const Duration fast = Duration(milliseconds: 150);

  /// Normal duration - 200ms
  /// Use for: Standard transitions, fades
  static const Duration normal = Duration(milliseconds: 200);

  /// Medium duration - 300ms
  /// Use for: Modal openings, page transitions
  static const Duration medium = Duration(milliseconds: 300);

  /// Slow duration - 400ms
  /// Use for: Complex animations, multi-step transitions
  static const Duration slow = Duration(milliseconds: 400);

  /// Extra slow duration - 500ms
  /// Use for: Emphasized transitions, loading states
  static const Duration extraSlow = Duration(milliseconds: 500);

  /// Very slow duration - 700ms
  /// Use for: Dramatic effects, hero animations
  static const Duration verySlow = Duration(milliseconds: 700);

  /// Ultra slow duration - 1000ms
  /// Use for: Special effects, splash screens
  static const Duration ultraSlow = Duration(milliseconds: 1000);

  // ============================================================================
  // ANIMATION CURVES (Easing Functions)
  // ============================================================================

  /// Linear curve (no easing)
  /// Constant speed throughout
  static const Curve linear = Curves.linear;

  /// Ease curve (standard ease-in-out)
  /// Slow start, fast middle, slow end
  static const Curve ease = Curves.ease;

  /// Ease in curve
  /// Slow start, accelerates
  static const Curve easeIn = Curves.easeIn;

  /// Ease out curve
  /// Fast start, decelerates
  static const Curve easeOut = Curves.easeOut;

  /// Ease in-out curve
  /// Slow start and end, fast middle
  static const Curve easeInOut = Curves.easeInOut;

  /// Ease in cubic (stronger ease in)
  static const Curve easeInCubic = Curves.easeInCubic;

  /// Ease out cubic (stronger ease out)
  static const Curve easeOutCubic = Curves.easeOutCubic;

  /// Ease in-out cubic (stronger ease in-out)
  static const Curve easeInOutCubic = Curves.easeInOutCubic;

  /// Fast out, slow in (Material Design standard)
  /// Best for: Persistent UI elements
  static const Curve fastOutSlowIn = Curves.fastOutSlowIn;

  /// Linear to ease out
  /// Best for: Incoming elements
  static const Curve linearToEaseOut = Curves.linearToEaseOut;

  /// Ease in to linear
  /// Best for: Outgoing elements
  static const Curve easeInToLinear = Curves.easeInToLinear;

  // ============================================================================
  // ELASTIC & BOUNCE CURVES
  // ============================================================================

  /// Elastic in curve (rubber band effect)
  static const Curve elasticIn = Curves.elasticIn;

  /// Elastic out curve (rubber band effect)
  static const Curve elasticOut = Curves.elasticOut;

  /// Elastic in-out curve
  static const Curve elasticInOut = Curves.elasticInOut;

  /// Bounce in curve (bouncing ball effect)
  static const Curve bounceIn = Curves.bounceIn;

  /// Bounce out curve (bouncing ball effect)
  static const Curve bounceOut = Curves.bounceOut;

  /// Bounce in-out curve
  static const Curve bounceInOut = Curves.bounceInOut;

  // ============================================================================
  // CUSTOM CURVES (Premium effects)
  // ============================================================================

  /// Custom smooth curve (subtle ease in-out)
  /// Best for: Smooth, premium transitions
  static const Curve smooth = Cubic(0.4, 0.0, 0.2, 1.0);

  /// Custom snappy curve (quick, responsive)
  /// Best for: Interactive elements, buttons
  static const Curve snappy = Cubic(0.25, 0.1, 0.25, 1.0);

  /// Custom dramatic curve (emphasized movement)
  /// Best for: Hero animations, page transitions
  static const Curve dramatic = Cubic(0.68, -0.55, 0.265, 1.55);

  /// Custom gentle curve (slow, soft)
  /// Best for: Subtle animations, background elements
  static const Curve gentle = Cubic(0.33, 0.0, 0.67, 1.0);

  /// Custom sharp curve (quick acceleration)
  /// Best for: Exit animations, dismissals
  static const Curve sharp = Cubic(0.4, 0.0, 0.6, 1.0);

  // ============================================================================
  // PREDEFINED ANIMATION CONFIGS
  // ============================================================================

  /// Fade in animation config
  static const AnimationConfig fadeIn = AnimationConfig(
    duration: normal,
    curve: easeOut,
  );

  /// Fade out animation config
  static const AnimationConfig fadeOut = AnimationConfig(
    duration: normal,
    curve: easeIn,
  );

  /// Slide in from bottom config
  static const AnimationConfig slideInUp = AnimationConfig(
    duration: medium,
    curve: fastOutSlowIn,
  );

  /// Slide in from top config
  static const AnimationConfig slideInDown = AnimationConfig(
    duration: medium,
    curve: fastOutSlowIn,
  );

  /// Slide in from left config
  static const AnimationConfig slideInLeft = AnimationConfig(
    duration: medium,
    curve: fastOutSlowIn,
  );

  /// Slide in from right config
  static const AnimationConfig slideInRight = AnimationConfig(
    duration: medium,
    curve: fastOutSlowIn,
  );

  /// Scale up animation config
  static const AnimationConfig scaleUp = AnimationConfig(
    duration: normal,
    curve: easeOutCubic,
  );

  /// Scale down animation config
  static const AnimationConfig scaleDown = AnimationConfig(
    duration: fast,
    curve: easeInCubic,
  );

  /// Rotate animation config
  static const AnimationConfig rotate = AnimationConfig(
    duration: medium,
    curve: easeInOut,
  );

  /// Bounce animation config
  static const AnimationConfig bounce = AnimationConfig(
    duration: slow,
    curve: bounceOut,
  );

  /// Elastic animation config
  static const AnimationConfig elastic = AnimationConfig(
    duration: extraSlow,
    curve: elasticOut,
  );

  // ============================================================================
  // PAGE TRANSITION CONFIGS
  // ============================================================================

  /// Page fade transition
  static const AnimationConfig pageFade = AnimationConfig(
    duration: medium,
    curve: easeInOut,
  );

  /// Page slide transition
  static const AnimationConfig pageSlide = AnimationConfig(
    duration: medium,
    curve: fastOutSlowIn,
  );

  /// Page scale transition
  static const AnimationConfig pageScale = AnimationConfig(
    duration: medium,
    curve: smooth,
  );

  /// Modal/dialog animation
  static const AnimationConfig modal = AnimationConfig(
    duration: medium,
    curve: fastOutSlowIn,
  );

  /// Bottom sheet animation
  static const AnimationConfig bottomSheet = AnimationConfig(
    duration: slow,
    curve: fastOutSlowIn,
  );

  /// Drawer animation
  static const AnimationConfig drawer = AnimationConfig(
    duration: medium,
    curve: fastOutSlowIn,
  );

  // ============================================================================
  // MICRO-INTERACTION CONFIGS
  // ============================================================================

  /// Button press animation
  static const AnimationConfig buttonPress = AnimationConfig(
    duration: extraFast,
    curve: easeOut,
  );

  /// Ripple animation
  static const AnimationConfig ripple = AnimationConfig(
    duration: normal,
    curve: easeOut,
  );

  /// Hover animation
  static const AnimationConfig hover = AnimationConfig(
    duration: fast,
    curve: easeOut,
  );

  /// Focus animation
  static const AnimationConfig focus = AnimationConfig(
    duration: fast,
    curve: easeOut,
  );

  /// Loading animation
  static const AnimationConfig loading = AnimationConfig(
    duration: ultraSlow,
    curve: linear,
  );

  /// Shimmer animation
  static const AnimationConfig shimmer = AnimationConfig(
    duration: Duration(milliseconds: 1500),
    curve: linear,
  );

  /// Pulse animation
  static const AnimationConfig pulse = AnimationConfig(
    duration: ultraSlow,
    curve: easeInOut,
  );

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Get duration by name
  static Duration getDuration(String name) {
    switch (name.toLowerCase()) {
      case 'instant':
        return instant;
      case 'extra_fast':
      case 'extrafast':
        return extraFast;
      case 'fast':
        return fast;
      case 'normal':
        return normal;
      case 'medium':
        return medium;
      case 'slow':
        return slow;
      case 'extra_slow':
      case 'extraslow':
        return extraSlow;
      case 'very_slow':
      case 'veryslow':
        return verySlow;
      case 'ultra_slow':
      case 'ultraslow':
        return ultraSlow;
      default:
        return normal;
    }
  }

  /// Get curve by name
  static Curve getCurve(String name) {
    switch (name.toLowerCase()) {
      case 'linear':
        return linear;
      case 'ease':
        return ease;
      case 'ease_in':
      case 'easein':
        return easeIn;
      case 'ease_out':
      case 'easeout':
        return easeOut;
      case 'ease_in_out':
      case 'easeinout':
        return easeInOut;
      case 'fast_out_slow_in':
      case 'fastoutslownin':
        return fastOutSlowIn;
      case 'bounce':
        return bounceOut;
      case 'elastic':
        return elasticOut;
      case 'smooth':
        return smooth;
      case 'snappy':
        return snappy;
      case 'dramatic':
        return dramatic;
      case 'gentle':
        return gentle;
      case 'sharp':
        return sharp;
      default:
        return easeInOut;
    }
  }
}

/// Animation configuration class
/// Combines duration and curve into a single config object
class AnimationConfig {
  final Duration duration;
  final Curve curve;

  const AnimationConfig({
    required this.duration,
    required this.curve,
  });

  /// Create a copy with modified values
  AnimationConfig copyWith({
    Duration? duration,
    Curve? curve,
  }) {
    return AnimationConfig(
      duration: duration ?? this.duration,
      curve: curve ?? this.curve,
    );
  }
}
