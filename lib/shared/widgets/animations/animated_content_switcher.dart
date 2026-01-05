import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design_tokens/animation_tokens.dart';

/// Animated content switcher with crossfade transition
///
/// Use this for skeleton → content transitions:
/// ```dart
/// AnimatedContentSwitcher(
///   showContent: !isLoading,
///   skeleton: MySkeletonLoader(),
///   content: MyContent(),
/// )
/// ```
class AnimatedContentSwitcher extends StatelessWidget {
  /// Whether to show content (true) or skeleton (false)
  final bool showContent;

  /// Skeleton/loading widget
  final Widget skeleton;

  /// Content widget
  final Widget content;

  /// Animation duration (default: normal - 300ms)
  final Duration duration;

  /// Animation curve (default: easeInOut)
  final Curve curve;

  const AnimatedContentSwitcher({
    super.key,
    required this.showContent,
    required this.skeleton,
    required this.content,
    this.duration = AnimationTokens.normal,
    this.curve = AnimationTokens.easeInOut,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: curve,
      switchOutCurve: curve,
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: showContent
          ? KeyedSubtree(key: const ValueKey('content'), child: content)
          : KeyedSubtree(key: const ValueKey('skeleton'), child: skeleton),
    );
  }
}

/// Animated async value builder with automatic skeleton → content transition
///
/// Usage:
/// ```dart
/// AnimatedAsyncBuilder<List<Booking>>(
///   asyncValue: bookingsAsync,
///   skeleton: BookingsSkeleton(),
///   builder: (data) => BookingsList(bookings: data),
/// )
/// ```
class AnimatedAsyncBuilder<T> extends StatelessWidget {
  /// The async value to watch
  final AsyncValue<T> asyncValue;

  /// Skeleton widget shown during loading
  final Widget skeleton;

  /// Builder for content when data is available
  final Widget Function(T data) builder;

  /// Optional error widget builder
  final Widget Function(Object error, StackTrace stack)? errorBuilder;

  /// Animation duration (default: normal - 300ms)
  final Duration duration;

  const AnimatedAsyncBuilder({
    super.key,
    required this.asyncValue,
    required this.skeleton,
    required this.builder,
    this.errorBuilder,
    this.duration = AnimationTokens.normal,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: asyncValue.when(
        loading: () =>
            KeyedSubtree(key: const ValueKey('loading'), child: skeleton),
        error: (error, stack) => KeyedSubtree(
          key: const ValueKey('error'),
          child:
              errorBuilder?.call(error, stack) ??
              Center(
                child: Text(
                  'Error: ${error.toString()}',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
        ),
        data: (data) =>
            KeyedSubtree(key: const ValueKey('data'), child: builder(data)),
      ),
    );
  }
}
