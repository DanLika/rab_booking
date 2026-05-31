import 'package:flutter/material.dart';

import '../../../core/design/tokens.dart';

/// Inline spinner (handoff [Spinner]) — 2px stroke, currentColor by default.
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
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? BBColor.of(context).primary,
        ),
      ),
    );
  }
}
