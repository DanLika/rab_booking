import 'package:flutter/material.dart';

import '../../../core/design/tokens.dart';

/// Shimmering placeholder (handoff [BBSkeleton]).
///
/// Reduced-motion friendly — falls back to static block when
/// `MediaQuery.disableAnimations` or platform reduce-motion is set.
class BbSkeleton extends StatefulWidget {
  const BbSkeleton({super.key, this.width, this.height = 16, this.radius = 8});

  final double? width;
  final double height;
  final double radius;

  @override
  State<BbSkeleton> createState() => _BbSkeletonState();
}

class _BbSkeletonState extends State<BbSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final BBColorSet c = BBColor.of(context);
    if (BBMotion.reduced(context)) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: c.surfaceVariant,
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      );
    }
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (BuildContext _, Widget? _) {
        final double t = _ctrl.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + 2.0 * t, 0),
              end: Alignment(0.0 + 2.0 * t, 0),
              colors: <Color>[
                c.surfaceVariant,
                Color.alphaBlend(
                  Colors.white.withValues(alpha: 0.5),
                  c.surfaceVariant,
                ),
                c.surfaceVariant,
              ],
              stops: const <double>[0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}
