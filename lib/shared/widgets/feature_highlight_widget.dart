import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/enhanced_auth_provider.dart';
import 'smart_tooltip.dart';

/// A widget that highlights a feature if the user hasn't seen it yet.
///
/// It uses a "pulse" animation to draw attention and a tooltip to explain the feature.
/// Tapping the child marks the feature as seen.
class FeatureHighlightWidget extends ConsumerStatefulWidget {
  final String featureId;
  final Widget child;
  final String? tooltipMessage;
  final bool showTooltipAlways;
  final Color? highlightColor;
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
            state.userModel == null, // Treat null user as "seen" to avoid highlighting during loading
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

    // We use a Listener to detect interaction without swallowing the event
    // This ensures buttons inside still work
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
        // Show immediately if it's a highlight
        waitDuration: Duration.zero,
        child: wrappedChild,
      );
    }

    // Apply animation
    return wrappedChild
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .scale(
          begin: const Offset(1.0, 1.0),
          end: Offset(widget.scaleFactor, widget.scaleFactor),
          duration: 800.ms,
          curve: Curves.easeInOut,
        )
        .then() // Loop
        .shimmer(
          duration: 1200.ms,
          color: color.withValues(alpha: 0.3),
        );
  }
}
