/// Responsive utilities for adaptive layouts
///
/// This file exports all responsive utilities and helpers
/// for building responsive, adaptive UIs.
///
/// Example usage:
/// ```dart
/// import 'package:rab_booking/core/utils/responsive.dart';
///
/// // Use breakpoint utilities
/// if (context.isMobile) {
///   // Mobile layout
/// }
///
/// // Use responsive values
/// final padding = context.responsiveSpacing(16, 24, 32);
///
/// // Use responsive widgets
/// ResponsiveLayout(
///   mobile: MobileLayout(),
///   desktop: DesktopLayout(),
/// )
/// ```
library;

// Breakpoints
export '../constants/breakpoints.dart';

// Responsive layout widgets
export 'responsive_layout.dart';

// Context extensions
export 'context_extensions.dart';

// Layout helpers
export 'layout_helpers.dart';
