import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/design_tokens/animation_tokens.dart';

/// Animated checkmark with scale + bounce effect for success feedback
///
/// Usage:
/// ```dart
/// AnimatedCheckmark(
///   size: 64,
///   color: Colors.green,
/// )
/// ```
class AnimatedCheckmark extends StatefulWidget {
  /// Checkmark size (default: 64)
  final double size;

  /// Checkmark color (defaults to theme's primary)
  final Color? color;

  /// Whether to show the checkmark immediately or wait
  final bool show;

  /// Callback when animation completes
  final VoidCallback? onComplete;

  const AnimatedCheckmark({
    super.key,
    this.size = 64,
    this.color,
    this.show = true,
    this.onComplete,
  });

  @override
  State<AnimatedCheckmark> createState() => _AnimatedCheckmarkState();
}

class _AnimatedCheckmarkState extends State<AnimatedCheckmark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AnimationTokens.slower,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _checkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });

    if (widget.show) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(AnimatedCheckmark oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.show && !oldWidget.show) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = widget.color ?? theme.colorScheme.primary;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: CustomPaint(
              painter: _CheckmarkPainter(
                progress: _checkAnimation.value,
                color: effectiveColor,
                strokeWidth: widget.size * 0.08,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CheckmarkPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _CheckmarkPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Draw circle background
    final circlePaint = Paint()
      ..color = color.withAlpha((0.15 * 255).toInt())
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2,
      circlePaint,
    );

    // Draw circle border
    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 0.5;

    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2 - strokeWidth * 0.25,
      borderPaint,
    );

    // Draw checkmark
    if (progress > 0) {
      final path = Path();

      // Checkmark points (relative to center)
      final startX = size.width * 0.28;
      final startY = size.height * 0.52;
      final midX = size.width * 0.45;
      final midY = size.height * 0.68;
      final endX = size.width * 0.75;
      final endY = size.height * 0.35;

      path.moveTo(startX, startY);

      if (progress <= 0.5) {
        // First half of checkmark
        final t = progress * 2;
        path.lineTo(startX + (midX - startX) * t, startY + (midY - startY) * t);
      } else {
        // Full first part + second part
        path.lineTo(midX, midY);
        final t = (progress - 0.5) * 2;
        path.lineTo(midX + (endX - midX) * t, midY + (endY - midY) * t);
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_CheckmarkPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

/// Success overlay with checkmark and optional message
///
/// Uses flutter_animate for fade in/out with auto-dismiss.
///
/// Usage:
/// ```dart
/// SuccessOverlay(
///   message: 'Profile saved successfully!',
///   onDismiss: () => Navigator.pop(context),
/// )
/// ```
class SuccessOverlay extends StatelessWidget {
  /// Success message to display
  final String? message;

  /// Callback when overlay should be dismissed
  final VoidCallback? onDismiss;

  /// Auto-dismiss duration (default: 2 seconds)
  final Duration autoDismissAfter;

  /// Checkmark size (default: 80)
  final double checkmarkSize;

  /// Checkmark color
  final Color? checkmarkColor;

  const SuccessOverlay({
    super.key,
    this.message,
    this.onDismiss,
    this.autoDismissAfter = const Duration(seconds: 2),
    this.checkmarkSize = 80,
    this.checkmarkColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final content = Container(
      color: Colors.black.withAlpha((0.5 * 255).toInt()),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          margin: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha((0.2 * 255).toInt()),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedCheckmark(
                size: checkmarkSize,
                color: checkmarkColor ?? Colors.green,
              ),
              if (message != null) ...[
                const SizedBox(height: 24),
                Text(
                  message!,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );

    // Fade in, hold, then fade out and dismiss
    return content
        .animate()
        .fadeIn(
          duration: AnimationTokens.fast,
          curve: AnimationTokens.easeOut,
        )
        .then(delay: autoDismissAfter)
        .fadeOut(
          duration: AnimationTokens.fast,
          curve: AnimationTokens.easeIn,
        )
        .callback(callback: (_) => onDismiss?.call());
  }
}
