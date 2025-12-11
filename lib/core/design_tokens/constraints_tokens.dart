import 'package:flutter/widgets.dart';

/// Layout constraint design tokens for consistent sizing across the app
///
/// Usage:
/// ```dart
/// ConstrainedBox(
///   constraints: ConstraintTokens.widgetContainer,
///   child: YourWidget(),
/// )
/// ```
class ConstraintTokens {
  // Prevent instantiation
  ConstraintTokens._();

  // ============================================================================
  // Maximum Width Constraints
  // ============================================================================

  /// Maximum width for the booking widget container (mobile-friendly)
  static const double maxWidgetWidth = 480.0;

  /// Maximum width for booking form content (optimal reading width)
  static const double maxFormWidth = 600.0;

  /// Maximum width for modals and dialogs
  static const double maxModalWidth = 500.0;

  /// Maximum width for cards
  static const double maxCardWidth = 400.0;

  /// Maximum width for narrow content (optimal for reading)
  static const double maxNarrowContentWidth = 720.0;

  /// Maximum width for wide content
  static const double maxWideContentWidth = 1200.0;

  /// Maximum width for full content
  static const double maxFullContentWidth = 1440.0;

  // ============================================================================
  // Minimum Width Constraints
  // ============================================================================

  /// Minimum width for the booking widget (prevents cramping)
  static const double minWidgetWidth = 280.0;

  /// Minimum width for buttons
  static const double minButtonWidth = 88.0;

  /// Minimum width for input fields
  static const double minInputWidth = 200.0;

  /// Minimum width for cards
  static const double minCardWidth = 240.0;

  // ============================================================================
  // Height Constraints
  // ============================================================================

  /// Standard button height
  static const double buttonHeight = 48.0;

  /// Compact button height
  static const double buttonHeightCompact = 40.0;

  /// Large button height
  static const double buttonHeightLarge = 56.0;

  /// Standard input field height
  static const double inputHeight = 48.0;

  /// Compact input field height
  static const double inputHeightCompact = 40.0;

  /// Large input field height
  static const double inputHeightLarge = 56.0;

  /// AppBar height
  static const double appBarHeight = 56.0;

  /// Calendar cell minimum height
  static const double calendarCellMinHeight = 60.0;

  /// Calendar cell maximum height
  static const double calendarCellMaxHeight = 120.0;

  /// Modal header height
  static const double modalHeaderHeight = 64.0;

  /// Bottom sheet peek height
  static const double bottomSheetPeekHeight = 100.0;

  /// Maximum height for scrollable content before scrolling
  static const double maxScrollableHeight = 600.0;

  // ============================================================================
  // Aspect Ratios
  // ============================================================================

  /// Standard card aspect ratio (width:height)
  static const double cardAspectRatio = 16 / 9;

  /// Square aspect ratio
  static const double squareAspectRatio = 1.0;

  /// Wide aspect ratio (for hero images)
  static const double wideAspectRatio = 21 / 9;

  /// Portrait aspect ratio
  static const double portraitAspectRatio = 3 / 4;

  // ============================================================================
  // Touch Target Sizes (Accessibility)
  // ============================================================================

  /// Minimum touch target size (WCAG AA recommendation)
  static const double minTouchTarget = 44.0;

  /// Recommended touch target size (Material Design)
  static const double recommendedTouchTarget = 48.0;

  /// Large touch target (for primary actions)
  static const double largeTouchTarget = 56.0;

  // ============================================================================
  // Icon Container Sizes
  // ============================================================================

  /// Small icon container (icon + padding)
  static const double iconContainerSmall = 32.0;

  /// Medium icon container
  static const double iconContainerMedium = 40.0;

  /// Large icon container
  static const double iconContainerLarge = 48.0;

  /// Extra large icon container
  static const double iconContainerXL = 64.0;

  // ============================================================================
  // Spacing Constraints
  // ============================================================================

  /// Maximum gap between sections
  static const double maxSectionGap = 64.0;

  /// Standard section gap
  static const double sectionGap = 32.0;

  /// Compact section gap
  static const double compactSectionGap = 24.0;

  // ============================================================================
  // Calendar-Specific Constraints
  // ============================================================================

  /// Calendar month minimum width (prevents cramping)
  static const double calendarMonthMinWidth = 280.0;

  /// Calendar month maximum width (optimal viewing)
  static const double calendarMonthMaxWidth = 400.0;

  /// Calendar day cell size (for square cells)
  static const double calendarDayCellSize = 48.0;

  /// Calendar day cell minimum size
  static const double calendarDayCellMinSize = 40.0;

  /// Calendar day cell maximum size
  static const double calendarDayCellMaxSize = 64.0;

  /// Month label width for year grid calendar
  static const double monthLabelWidth = 60.0;

  // ============================================================================
  // BoxConstraints Helpers
  // ============================================================================

  /// Widget container constraints
  static BoxConstraints get widgetContainer => const BoxConstraints(
        minWidth: minWidgetWidth,
        maxWidth: maxWidgetWidth,
      );

  /// Form container constraints
  static BoxConstraints get formContainer => const BoxConstraints(
        maxWidth: maxFormWidth,
      );

  /// Modal constraints
  static BoxConstraints get modal => const BoxConstraints(
        maxWidth: maxModalWidth,
        maxHeight: maxScrollableHeight,
      );

  /// Card constraints
  static BoxConstraints get card => const BoxConstraints(
        minWidth: minCardWidth,
        maxWidth: maxCardWidth,
      );

  /// Button constraints
  static BoxConstraints get button => const BoxConstraints(
        minWidth: minButtonWidth,
        minHeight: buttonHeight,
      );

  /// Input field constraints
  static BoxConstraints get input => const BoxConstraints(
        minWidth: minInputWidth,
        minHeight: inputHeight,
      );

  /// Touch target constraints (accessibility)
  static BoxConstraints get touchTarget => const BoxConstraints(
        minWidth: minTouchTarget,
        minHeight: minTouchTarget,
      );

  /// Calendar month constraints
  static BoxConstraints get calendarMonth => const BoxConstraints(
        minWidth: calendarMonthMinWidth,
        maxWidth: calendarMonthMaxWidth,
      );

  /// Calendar cell constraints
  static BoxConstraints get calendarCell => const BoxConstraints(
        minWidth: calendarDayCellMinSize,
        maxWidth: calendarDayCellMaxSize,
        minHeight: calendarCellMinHeight,
        maxHeight: calendarCellMaxHeight,
      );

  // ============================================================================
  // Helper Methods
  // ============================================================================

  /// Create custom BoxConstraints with specified dimensions
  static BoxConstraints custom({
    double minWidth = 0.0,
    double maxWidth = double.infinity,
    double minHeight = 0.0,
    double maxHeight = double.infinity,
  }) {
    return BoxConstraints(
      minWidth: minWidth,
      maxWidth: maxWidth,
      minHeight: minHeight,
      maxHeight: maxHeight,
    );
  }

  /// Create square BoxConstraints
  static BoxConstraints square(double size) {
    return BoxConstraints.tightFor(
      width: size,
      height: size,
    );
  }

  /// Create BoxConstraints with specific aspect ratio
  static BoxConstraints withAspectRatio({
    required double width,
    required double aspectRatio,
  }) {
    return BoxConstraints.tightFor(
      width: width,
      height: width / aspectRatio,
    );
  }
}
