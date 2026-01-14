import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/enhanced_auth_provider.dart';
import 'smart_tooltip.dart';

/// A widget that highlights a feature if the user hasn't seen it yet.
///
/// Uses a "pulse" animation to draw attention and optionally shows a tooltip.
/// When the user interacts with the child widget, the feature is marked as seen
/// and the highlight animation stops.
///
/// Example usage:
/// ```dart
/// FeatureHighlightWidget(
///   featureId: 'calendar_sync_button',
///   tooltipMessage: 'Sync your calendar with external platforms',
///   child: IconButton(
///     icon: Icon(Icons.sync),
///     onPressed: () => _syncCalendar(),
///   ),
/// )
/// ```
class FeatureHighlightWidget extends ConsumerStatefulWidget {
  /// Unique identifier for this feature (stored in Firestore)
  final String featureId;

  /// The widget to highlight
  final Widget child;

  /// Optional tooltip message to show
  final String? tooltipMessage;

  /// If true, shows tooltip even after feature is marked as seen
  final bool showTooltipAlways;

  /// Custom highlight color (defaults to primary color)
  final Color? highlightColor;

  /// Scale factor for pulse animation (1.05 = 5% larger)
  final double scaleFactor;

  const FeatureHighlightWidget({
    super.key,
    required this.featureId,
    required this.child,
    this.tooltipMessage,
    this.showTooltipAlways = false,
    this.highlightColor,
    this.scaleFactor = 1.05,
  });

  @override
  ConsumerState<FeatureHighlightWidget> createState() =>
      _FeatureHighlightWidgetState();
}

class _FeatureHighlightWidgetState
    extends ConsumerState<FeatureHighlightWidget> {
  @override
  Widget build(BuildContext context) {
    // Select only the specific feature flag to prevent unnecessary rebuilds
    final isSeen = ref.watch(
      enhancedAuthProvider.select(
        (state) =>
            state.userModel?.featureFlags[widget.featureId] == true ||
            state.userModel ==
                null, // Treat null user as "seen" to avoid highlighting during loading
      ),
    );

    // If feature is already seen (or user not loaded), just return the child
    if (isSeen) {
      if (widget.tooltipMessage != null && widget.showTooltipAlways) {
        return SmartTooltip(
          message: widget.tooltipMessage!,
          child: widget.child,
        );
      }
      return widget.child;
    }

    final theme = Theme.of(context);
    final color = widget.highlightColor ?? theme.colorScheme.primary;

    // Use Listener to detect interaction without swallowing the event
    // This ensures buttons inside still work normally
    Widget wrappedChild = Listener(
      onPointerDown: (_) {
        ref
            .read(enhancedAuthProvider.notifier)
            .markFeatureAsSeen(widget.featureId);
      },
      child: widget.child,
    );

    if (widget.tooltipMessage != null) {
      wrappedChild = SmartTooltip(
        message: widget.tooltipMessage!,
        // Show immediately since it's a highlight
        waitDuration: Duration.zero,
        child: wrappedChild,
      );
    }

    // Apply pulse + shimmer animation using flutter_animate
    return wrappedChild
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .scale(
          begin: const Offset(1.0, 1.0),
          end: Offset(widget.scaleFactor, widget.scaleFactor),
          duration: 800.ms,
          curve: Curves.easeInOut,
        )
        .then(delay: Duration.zero) // Run shimmer in parallel
        .shimmer(duration: 1200.ms, color: color.withValues(alpha: 0.3));
  }
}
