import 'package:flutter/material.dart';

import '../../../core/design/tokens.dart';

/// BookBed brand "b" mark (handoff [Logo]) — a stylized glyph on a
/// brand-primary tile. (The old docstring promised an
/// `assets/images/logo.png` fallback that was never implemented.)
///
/// [useGradient] defaults to FALSE since audit F3.5 — the diagonal
/// brand gradient on chrome violates the 2026-06-16 flat-chrome decision.
/// Pass true only for sanctioned hero/marketing surfaces.
class BbLogo extends StatelessWidget {
  const BbLogo({super.key, this.size = 32, this.useGradient = false});

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
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.6,
          height: 1,
          letterSpacing: -0.02,
        ),
      ),
    );
  }
}
