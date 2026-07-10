import 'package:flutter/material.dart';
import '../../theme/minimalist_colors.dart';

/// A floating pill bar container for booking flow.
///
/// Desktop/tablet: centered floating card with Material elevation.
/// Phone (<600px): bottom sheet per handoff widget-pricing.jsx — full width,
/// anchored to the bottom, 24px top-only radius, drag-style grabber.
class BookingPillBar extends StatelessWidget {
  final double width;
  final double maxHeight;
  final bool isDarkMode;
  final double keyboardInset;
  final Widget child;

  const BookingPillBar({
    super.key,
    required this.width,
    required this.maxHeight,
    required this.isDarkMode,
    required this.keyboardInset,
    required this.child,
  });

  static const _borderRadius = 30.0;
  static const _sheetRadius = 24.0; // handoff bottom-sheet top corners
  static const _elevation = 2.0;
  static const _horizontalPadding = 12.0;
  static const _topPadding = 8.0;
  static const _bottomPadding = 24.0;

  @override
  Widget build(BuildContext context) {
    final colors = MinimalistColorSchemeAdapter(dark: isDarkMode);
    final screenWidth = MediaQuery.maybeOf(context)?.size.width ?? 1024.0;
    final isPhone = screenWidth < 600;

    final radius = isPhone
        ? const BorderRadius.vertical(top: Radius.circular(_sheetRadius))
        : BorderRadius.circular(_borderRadius);

    final card = Material(
      elevation: _elevation,
      shadowColor: isDarkMode ? Colors.white24 : Colors.black26,
      borderRadius: radius,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isPhone ? double.infinity : width,
          maxHeight: maxHeight,
        ),
        decoration: BoxDecoration(
          color: colors.backgroundPrimary,
          borderRadius: radius,
          border: Border.all(color: colors.borderLight),
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              _horizontalPadding,
              _topPadding,
              _horizontalPadding,
              _bottomPadding + keyboardInset,
            ),
            child: isPhone
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Handoff grabber: 40×4 rounded bar.
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(top: 4, bottom: 8),
                        decoration: BoxDecoration(
                          color: colors.borderLight,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      child,
                    ],
                  )
                : child,
          ),
        ),
      ),
    );

    return isPhone
        ? Align(alignment: Alignment.bottomCenter, child: card)
        : Center(child: card);
  }
}
