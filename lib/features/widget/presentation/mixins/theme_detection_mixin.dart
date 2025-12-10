import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';

/// Mixin for detecting system theme and syncing with themeProvider.
///
/// Extracted from BookingConfirmationScreen and BookingDetailsScreen
/// to reduce code duplication.
///
/// Usage:
/// ```dart
/// class _MyScreenState extends ConsumerState<MyScreen>
///     with ThemeDetectionMixin {
///
///   @override
///   void didChangeDependencies() {
///     super.didChangeDependencies();
///     detectSystemTheme();
///   }
/// }
/// ```
mixin ThemeDetectionMixin<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  /// Flag to prevent override after initial detection.
  /// This preserves manual theme toggles by the user.
  bool _hasDetectedSystemTheme = false;

  /// Detects the system theme on first call and syncs with themeProvider.
  ///
  /// Should be called in `didChangeDependencies()`.
  /// Only runs once per widget lifecycle to preserve manual theme toggles.
  void detectSystemTheme() {
    if (_hasDetectedSystemTheme) return;

    _hasDetectedSystemTheme = true;
    final brightness = MediaQuery.of(context).platformBrightness;
    final isSystemDark = brightness == Brightness.dark;

    // Set theme provider to match system theme (after build frame)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(themeProvider.notifier).state = isSystemDark;
      }
    });
  }

  /// Resets the detection flag.
  /// Useful if you need to re-detect the system theme.
  void resetThemeDetection() {
    _hasDetectedSystemTheme = false;
  }
}
