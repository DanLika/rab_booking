import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// "Powered by BookBed" footer used across guest-facing widget screens.
///
/// Mirrors the handoff `WXPoweredBy` mark: a muted 11px label with the
/// BookBed wordmark in brand purple. Colors are fixed (theme-independent)
/// so the mark reads identically on the light and pure-black widget
/// backgrounds, exactly as in the design handoff.
class WidgetPoweredBy extends StatelessWidget {
  const WidgetPoweredBy({super.key});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          const TextSpan(text: 'Powered by '),
          TextSpan(
            text: 'BookBed',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF6B4CE6), // brand purple
            ),
          ),
        ],
        style: GoogleFonts.inter(
          fontSize: 11,
          color: const Color(0xFF9AA0AC), // muted
        ),
      ),
      textAlign: TextAlign.center,
    );
  }
}
