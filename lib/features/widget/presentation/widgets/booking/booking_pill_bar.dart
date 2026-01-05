import 'package:flutter/material.dart';
import '../../theme/minimalist_colors.dart';

/// A floating pill bar container for booking flow.
///
/// Displays centered on screen with Material elevation and rounded corners.
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
  static const _elevation = 2.0;
  static const _horizontalPadding = 12.0;
  static const _topPadding = 8.0;
  static const _bottomPadding = 24.0;

  @override
  Widget build(BuildContext context) {
    final colors = MinimalistColorSchemeAdapter(dark: isDarkMode);
    final radius = BorderRadius.circular(_borderRadius);

    return Center(
      child: Material(
        elevation: _elevation,
        shadowColor: isDarkMode ? Colors.white24 : Colors.black26,
        borderRadius: radius,
        child: Container(
          constraints: BoxConstraints(maxWidth: width, maxHeight: maxHeight),
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
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
