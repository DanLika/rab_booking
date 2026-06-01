import 'package:flutter/material.dart';

import '../../../core/design/tokens.dart';

/// Inline spinner (handoff [Spinner]) — 2px stroke, currentColor by default.
///
/// When reduce-motion is active (MediaQuery.disableAnimations or platform
/// accessibility hint), renders a static hourglass glyph instead — the
/// CircularProgressIndicator rotation is OS-driven and ignores
/// `AlwaysStoppedAnimation` (see audit/105 §3.5).
class BbSpinner extends StatelessWidget {
  const BbSpinner({
    super.key,
    this.size = 18,
    this.color,
    this.strokeWidth = 2,
  });

  final double size;
  final Color? color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final resolved = color ?? BBColor.of(context).primary;

    if (BBMotion.reduced(context)) {
      return SizedBox(
        width: size,
        height: size,
        child: Icon(Icons.hourglass_empty, size: size, color: resolved),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(resolved),
      ),
    );
  }
}
