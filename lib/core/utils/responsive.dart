/// Responsive utilities for adaptive layouts
///
/// This file exports all responsive utilities and helpers
/// for building responsive, adaptive UIs.
///
/// Example usage:
/// ```dart
/// import 'package:bookbed/core/utils/responsive.dart';
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

// Context extensions
export 'context_extensions.dart';
