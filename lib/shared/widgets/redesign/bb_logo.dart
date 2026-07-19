import 'package:flutter/material.dart';

import '../../../core/design/tokens.dart';

/// BookBed brand "b" mark (handoff [Logo]).
/// Uses `assets/images/logo.png` if present; otherwise paints a stylized "b"
/// glyph on a brand-primary tile so the logo never appears broken.
class BbLogo extends StatelessWidget {
  const BbLogo({super.key, this.size = 32, this.useGradient = true});

  final double size;
  final bool useGradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: useGradient ? BBGradient.brandPrimary : null,
        color: useGradient ? null : BBColor.of(context).primary,
        borderRadius: BorderRadius.circular(size * 0.25),
      ),
      alignment: Alignment.center,
      child: Text(
        'b',
        style: TextStyle(
          color: BBColor.of(context).onPrimary,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.6,
          height: 1,
          letterSpacing: -0.02,
        ),
      ),
    );
  }
}
