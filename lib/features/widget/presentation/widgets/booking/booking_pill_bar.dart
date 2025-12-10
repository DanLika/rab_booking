import 'package:flutter/material.dart';
import '../../theme/minimalist_colors.dart';

/// A floating pill bar container for booking flow.
///
/// Displays centered on screen with Material elevation and rounded corners.
/// No drag functionality - users can close via the X button or clicking outside.
///
/// Extracted from booking_widget_screen.dart _buildFloatingPillBar method.
///
/// Usage:
/// ```dart
/// BookingPillBar(
///   width: 350,
///   maxHeight: 282,
///   isDarkMode: isDarkMode,
///   keyboardInset: MediaQuery.of(context).viewInsets.bottom,
///   child: PillBarContent(...),
/// )
/// ```
class BookingPillBar extends StatelessWidget {
  /// Width of the pill bar
  final double width;

  /// Maximum height of the pill bar
  final double maxHeight;

  /// Whether dark mode is active
  final bool isDarkMode;

  /// Keyboard inset to add to bottom padding
  final double keyboardInset;

  /// Child content widget (typically PillBarContent)
  final Widget child;

  const BookingPillBar({
    super.key,
    required this.width,
    required this.maxHeight,
    required this.isDarkMode,
    required this.keyboardInset,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colors = MinimalistColorSchemeAdapter(dark: isDarkMode);

    return Center(
      child: Material(
        elevation: 2,
        shadowColor: isDarkMode ? Colors.white24 : Colors.black26,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          constraints: BoxConstraints(maxWidth: width, maxHeight: maxHeight),
          decoration: BoxDecoration(
            color: colors.backgroundPrimary,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: colors.borderLight),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                12, // left
                8, // top (close button header adds visual padding above content)
                12, // right
                // Bottom: 24px for symmetry with top (8px + close button header ~16px)
                // Bug #46: Add keyboard height to bottom padding
                24 + keyboardInset,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
