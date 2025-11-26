import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/minimalist_colors.dart';

/// A draggable floating pill bar container for booking flow.
///
/// Provides the visual container with Material elevation, rounded corners,
/// and gesture detection for drag-to-reposition functionality.
///
/// Extracted from booking_widget_screen.dart _buildFloatingDraggablePillBar method.
///
/// Usage:
/// ```dart
/// BookingPillBar(
///   position: Offset(100, 200),
///   width: 350,
///   maxHeight: 282,
///   isDarkMode: isDarkMode,
///   keyboardInset: MediaQuery.of(context).viewInsets.bottom,
///   onDragStart: () => HapticFeedback.selectionClick(),
///   onDragUpdate: (delta) => setState(() => _position += delta),
///   onDragEnd: () => _checkBounds(),
///   child: PillBarContent(...),
/// )
/// ```
class BookingPillBar extends StatelessWidget {
  /// Current position of the pill bar
  final Offset position;

  /// Width of the pill bar
  final double width;

  /// Maximum height of the pill bar
  final double maxHeight;

  /// Whether dark mode is active
  final bool isDarkMode;

  /// Keyboard inset to add to bottom padding
  final double keyboardInset;

  /// Callback when drag gesture starts
  final VoidCallback onDragStart;

  /// Callback during drag with delta offset
  final void Function(Offset delta) onDragUpdate;

  /// Callback when drag gesture ends
  final VoidCallback onDragEnd;

  /// Child content widget (typically PillBarContent)
  final Widget child;

  const BookingPillBar({
    super.key,
    required this.position,
    required this.width,
    required this.maxHeight,
    required this.isDarkMode,
    required this.keyboardInset,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent, // Better hit test for dragging
        onPanStart: (_) {
          // Provide haptic feedback on drag start
          HapticFeedback.selectionClick();
          onDragStart();
        },
        onPanUpdate: (details) {
          onDragUpdate(details.delta);
        },
        onPanEnd: (_) {
          onDragEnd();
        },
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: width,
              maxHeight: maxHeight,
            ),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? MinimalistColorsDark.backgroundPrimary
                  : MinimalistColors.backgroundPrimary,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isDarkMode
                    ? MinimalistColorsDark.borderLight
                    : MinimalistColors.borderLight,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  12,
                  8,
                  12,
                  // Bug #46: Add keyboard height to bottom padding
                  8 + keyboardInset,
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
