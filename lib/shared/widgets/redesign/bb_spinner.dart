import 'package:flutter/material.dart';

import '../../../core/design/tokens.dart';

/// Inline spinner (handoff [Spinner]) — 2px stroke, currentColor by default.
///
/// When reduce-motion is active (MediaQuery.disableAnimations or platform
/// accessibility hint), renders a static hourglass glyph instead — the
/// CircularProgressIndicator rotation is OS-driven and ignores
/// `AlwaysStoppedAnimation` (see audit/105 §3.5).
///
/// **A11y (audit sweep F2.8):** decorative by default — without a
/// [semanticsLabel] the spinner is wrapped in [ExcludeSemantics] so it never
/// surfaces as an unlabeled progress node next to its host (a loading
/// BbButton already carries its own label). Pass [semanticsLabel] when the
/// spinner stands alone; it then announces as a live region.
class BbSpinner extends StatelessWidget {
  const BbSpinner({
    super.key,
    this.size = 18,
    this.color,
    this.strokeWidth = 2,
    this.semanticsLabel,
  });

  final double size;
  final Color? color;
  final double strokeWidth;

  /// Accessible announcement for standalone spinners (live region).
  /// `null` (default) excludes the spinner from the semantics tree.
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final resolved = color ?? BBColor.of(context).primary;

    final Widget spinner = BBMotion.reduced(context)
        ? SizedBox(
            width: size,
            height: size,
            child: Icon(Icons.hourglass_empty, size: size, color: resolved),
          )
        : SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: strokeWidth,
              valueColor: AlwaysStoppedAnimation<Color>(resolved),
            ),
          );

    if (semanticsLabel != null) {
      return Semantics(
        liveRegion: true,
        label: semanticsLabel,
        excludeSemantics: true,
        child: spinner,
      );
    }
    return ExcludeSemantics(child: spinner);
  }
}
