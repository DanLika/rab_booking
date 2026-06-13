import 'package:flutter/material.dart';
import '../../../../../core/design/tokens.dart';

/// "Powered by BookBed" footer used across guest-facing widget screens.
///
/// Mirrors the handoff `WXPoweredBy` mark: a muted 11px label with the
/// BookBed wordmark in brand purple. Colors are fixed (theme-independent)
/// so the mark reads identically on the light and pure-black widget
/// backgrounds, exactly as in the design handoff. Canonical single
/// treatment — see `.claude/rules/widget.md` (the tappable `PoweredByBadge`
/// variant survives only inside the FROZEN `booking_widget_screen`).
class WidgetPoweredBy extends StatelessWidget {
  const WidgetPoweredBy({super.key});

  @override
  Widget build(BuildContext context) {
    final TextStyle base = BBType.caption(
      context,
    ).copyWith(fontSize: 11, color: const Color(0xFF9AA0AC)); // muted

    return Text.rich(
      TextSpan(
        children: [
          const TextSpan(text: 'Powered by '),
          TextSpan(
            text: 'BookBed',
            style: base.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF6B4CE6), // brand purple
            ),
          ),
        ],
        style: base,
      ),
      textAlign: TextAlign.center,
    );
  }
}
