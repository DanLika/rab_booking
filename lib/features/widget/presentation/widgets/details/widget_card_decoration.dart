import 'package:flutter/material.dart';
import '../../../../../core/design/tokens.dart';
import '../../../../../core/design_tokens/design_tokens.dart';

/// Premium card decoration shared across the guest booking-details cards.
///
/// Matches the widget design handoff visual language (`widget-confirmation`
/// summary card / `widget-error` states): a generous 20px corner radius, a
/// hairline border, and a soft elevation shadow in light theme.
///
/// Dark theme renders against the pure-black widget background where drop
/// shadows are invisible, so separation comes from a slightly heavier (1.5px)
/// border instead and no shadow is emitted.
///
/// Replaces the flat 8px `BBRadiusBridges.medium` + border-only treatment that
/// every detail card used to hand-roll identically.
BoxDecoration premiumWidgetCardDecoration({
  required WidgetColorScheme colors,
  required bool isDark,
  Color? backgroundColor,
}) {
  return BoxDecoration(
    color:
        backgroundColor ?? (isDark ? Colors.black : colors.backgroundSecondary),
    borderRadius: BBRadius.mdAll, // 20px — handoff card radius
    border: Border.all(
      color: isDark ? colors.borderMedium : colors.borderDefault,
      width: isDark ? 1.5 : 1.0,
    ),
    // Soft elevation matching `0 12px 28px rgba(20, 30, 50, 0.07)` from the
    // handoff summary card. Light theme only — see doc comment above.
    boxShadow: isDark
        ? null
        : const [
            BoxShadow(
              color: Color(0x12141E32), // ~7% of #141E32 (handoff ink)
              offset: Offset(0, 12),
              blurRadius: 28,
            ),
          ],
  );
}
