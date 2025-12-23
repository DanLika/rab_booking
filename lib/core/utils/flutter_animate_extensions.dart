import 'package:flutter/widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../design_tokens/animation_tokens.dart';

/// Extension methods for flutter_animate integration with AnimationTokens
///
/// These extensions provide seamless integration between flutter_animate
/// and BookBed's existing animation design tokens.
///
/// Usage:
/// ```dart
/// // Before (manual AnimationController - 50+ lines)
/// class _MyWidgetState extends State<MyWidget>
///     with SingleTickerProviderStateMixin {
///   late AnimationController _controller;
///   late Animation<double> _fadeAnimation;
///   // ... initState, dispose, build with AnimatedBuilder
/// }
///
/// // After (flutter_animate - 1 line)
/// child.animate().fadeInWithTokens()
/// ```
extension FlutterAnimateTokens on Animate {
  /// Fade in using BookBed animation tokens
  ///
  /// Default: 200ms duration with easeOut curve
  Animate fadeInWithTokens({
    Duration? duration,
    Duration? delay,
    Curve? curve,
    double begin = 0.0,
    double end = 1.0,
  }) {
    return fade(
      duration: duration ?? AnimationTokens.fadeDuration,
      delay: delay,
      curve: curve ?? AnimationTokens.fadeCurve,
      begin: begin,
      end: end,
    );
  }

  /// Fade out using BookBed animation tokens
  Animate fadeOutWithTokens({
    Duration? duration,
    Duration? delay,
    Curve? curve,
  }) {
    return fade(
      duration: duration ?? AnimationTokens.fadeDuration,
      delay: delay,
      curve: curve ?? AnimationTokens.easeIn,
      begin: 1.0,
      end: 0.0,
    );
  }

  /// Scale animation using BookBed animation tokens
  ///
  /// Default: 300ms duration with fastOutSlowIn curve
  /// Starts at 80% scale and animates to 100%
  Animate scaleWithTokens({
    Duration? duration,
    Duration? delay,
    Curve? curve,
    Offset begin = const Offset(0.8, 0.8),
    Offset end = const Offset(1.0, 1.0),
  }) {
    return scale(
      duration: duration ?? AnimationTokens.scaleDuration,
      delay: delay,
      curve: curve ?? AnimationTokens.scaleCurve,
      begin: begin,
      end: end,
    );
  }

  /// Slide up animation using BookBed animation tokens
  ///
  /// Default: 300ms duration with easeOut curve
  /// Slides from 20px below to current position
  Animate slideUpWithTokens({
    Duration? duration,
    Duration? delay,
    Curve? curve,
    double begin = 20.0,
    double end = 0.0,
  }) {
    return slideY(
      duration: duration ?? AnimationTokens.slideDuration,
      delay: delay,
      curve: curve ?? AnimationTokens.slideCurve,
      begin: begin,
      end: end,
    );
  }

  /// Combined fade + scale animation (common empty state pattern)
  ///
  /// This is the most common animation pattern in BookBed:
  /// - Fade in over 300ms with easeOut
  /// - Scale from 80% to 100% with fastOutSlowIn
  Animate emptyStateEntrance({
    Duration? fadeDuration,
    Duration? scaleDuration,
    Duration? delay,
  }) {
    return fadeInWithTokens(
      duration: fadeDuration ?? AnimationTokens.normal,
      delay: delay,
    ).scaleWithTokens(
      duration: scaleDuration ?? AnimationTokens.normal,
      delay: delay,
    );
  }

  /// Card entrance animation with optional stagger delay
  ///
  /// Usage for list items:
  /// ```dart
  /// ListView.builder(
  ///   itemBuilder: (context, index) => Card(...)
  ///     .animate()
  ///     .cardEntrance(staggerIndex: index),
  /// )
  /// ```
  Animate cardEntrance({
    int staggerIndex = 0,
    Duration staggerDelay = const Duration(milliseconds: 100),
    Duration? duration,
  }) {
    final delay = staggerDelay * staggerIndex;
    return fadeInWithTokens(
      duration: duration ?? AnimationTokens.fast,
      delay: delay,
    ).slideUpWithTokens(
      duration: duration ?? AnimationTokens.fast,
      delay: delay,
    );
  }

  /// Button press feedback animation
  ///
  /// Usage:
  /// ```dart
  /// GestureDetector(
  ///   onTapDown: (_) => setState(() => _pressed = true),
  ///   onTapUp: (_) => setState(() => _pressed = false),
  ///   child: child.animate(target: _pressed ? 1 : 0)
  ///     .buttonPress(),
  /// )
  /// ```
  Animate buttonPress({
    double scaleEnd = 0.95,
    Duration? duration,
  }) {
    return scale(
      duration: duration ?? AnimationTokens.instant,
      curve: AnimationTokens.easeOut,
      begin: const Offset(1.0, 1.0),
      end: Offset(scaleEnd, scaleEnd),
    );
  }

  /// Hover scale effect for desktop
  ///
  /// Usage:
  /// ```dart
  /// MouseRegion(
  ///   onEnter: (_) => setState(() => _hovered = true),
  ///   onExit: (_) => setState(() => _hovered = false),
  ///   child: child.animate(target: _hovered ? 1 : 0)
  ///     .hoverScale(),
  /// )
  /// ```
  Animate hoverScale({
    double scaleEnd = 1.02,
    Duration? duration,
  }) {
    return scale(
      duration: duration ?? AnimationTokens.fast,
      curve: AnimationTokens.easeOut,
      begin: const Offset(1.0, 1.0),
      end: Offset(scaleEnd, scaleEnd),
    );
  }

  /// Dialog entrance animation
  ///
  /// Scales from 90% with fade in
  Animate dialogEntrance({
    Duration? duration,
  }) {
    return fadeInWithTokens(
      duration: duration ?? AnimationTokens.fast,
    ).scale(
      duration: duration ?? AnimationTokens.fast,
      curve: AnimationTokens.fastOutSlowIn,
      begin: const Offset(0.9, 0.9),
      end: const Offset(1.0, 1.0),
    );
  }
}

/// Extension to add .animate() shorthand with default configuration
extension AnimateWidgetExtensions on Widget {
  /// Animate this widget with BookBed's default configuration
  ///
  /// This is a convenience wrapper that automatically applies
  /// the default animation settings for consistency.
  ///
  /// Usage:
  /// ```dart
  /// // Simple fade in
  /// Text('Hello').animateWithTokens().fadeInWithTokens()
  ///
  /// // Empty state pattern
  /// Column(...).animateWithTokens().emptyStateEntrance()
  ///
  /// // Staggered list
  /// Card(...).animateWithTokens().cardEntrance(staggerIndex: index)
  /// ```
  Animate animateWithTokens({
    bool autoPlay = true,
    Duration? delay,
    AnimationController? controller,
    double? target,
    Key? key,
  }) {
    return animate(
      autoPlay: autoPlay,
      delay: delay,
      controller: controller,
      target: target,
      key: key,
    );
  }
}
