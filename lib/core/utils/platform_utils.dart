import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

/// Platform-specific utilities for adaptive UI
/// Provides helpers for platform detection and platform-specific widgets
class PlatformUtils {
  PlatformUtils._(); // Private constructor

  // ============================================================================
  // PLATFORM DETECTION
  // ============================================================================

  /// Check if running on web
  static bool get isWeb => kIsWeb;

  /// Check if running on iOS
  static bool get isIOS => !kIsWeb && Platform.isIOS;

  /// Check if running on Android
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;

  /// Check if running on macOS
  static bool get isMacOS => !kIsWeb && Platform.isMacOS;

  /// Check if running on Windows
  static bool get isWindows => !kIsWeb && Platform.isWindows;

  /// Check if running on Linux
  static bool get isLinux => !kIsWeb && Platform.isLinux;

  /// Check if running on mobile platform (iOS or Android)
  static bool get isMobilePlatform => isIOS || isAndroid;

  /// Check if running on desktop platform (macOS, Windows, Linux)
  static bool get isDesktopPlatform => isMacOS || isWindows || isLinux;

  /// Check if platform uses Cupertino design (iOS, macOS)
  static bool get usesCupertinoDesign => isIOS || isMacOS;

  /// Check if platform uses Material design (Android, Web, Windows, Linux)
  static bool get usesMaterialDesign => isAndroid || isWeb || isWindows || isLinux;

  // ============================================================================
  // PLATFORM CAPABILITIES
  // ============================================================================

  /// Check if platform supports haptic feedback (mobile devices)
  static bool get supportsHaptics => isMobilePlatform;

  /// Check if platform supports keyboard navigation (desktop and web)
  static bool get supportsKeyboard => isDesktopPlatform || isWeb;

  /// Check if platform supports hover interactions (desktop and web)
  static bool get supportsHover => isDesktopPlatform || isWeb;

  // ============================================================================
  // PLATFORM-SPECIFIC WIDGETS
  // ============================================================================

  /// Build platform-specific widget
  static Widget adaptive({
    required Widget material,
    required Widget cupertino,
  }) {
    return usesCupertinoDesign ? cupertino : material;
  }

  /// Platform-specific switch widget
  static Widget adaptiveSwitch({
    required bool value,
    required ValueChanged<bool> onChanged,
    Color? activeColor,
  }) {
    if (usesCupertinoDesign) {
      return CupertinoSwitch(
        value: value,
        onChanged: onChanged,
        activeTrackColor: activeColor,
      );
    }
    return Switch(
      value: value,
      onChanged: onChanged,
      activeThumbColor: activeColor,
    );
  }

  /// Platform-specific slider widget
  static Widget adaptiveSlider({
    required double value,
    required ValueChanged<double> onChanged,
    double min = 0.0,
    double max = 1.0,
    Color? activeColor,
  }) {
    if (usesCupertinoDesign) {
      return CupertinoSlider(
        value: value,
        onChanged: onChanged,
        min: min,
        max: max,
        activeColor: activeColor,
      );
    }
    return Slider(
      value: value,
      onChanged: onChanged,
      min: min,
      max: max,
      activeColor: activeColor,
    );
  }

  /// Platform-specific activity indicator
  static Widget adaptiveProgressIndicator({
    Color? color,
    double? value,
  }) {
    if (usesCupertinoDesign) {
      return CupertinoActivityIndicator(
        color: color,
      );
    }
    return CircularProgressIndicator(
      valueColor: color != null ? AlwaysStoppedAnimation<Color>(color) : null,
      value: value,
    );
  }

  /// Platform-specific alert dialog
  static Future<T?> showAdaptiveDialog<T>({
    required BuildContext context,
    required String title,
    required String content,
    String? confirmText,
    String? cancelText,
    VoidCallback? onConfirm,
  }) {
    if (usesCupertinoDesign) {
      return showCupertinoDialog<T>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            if (cancelText != null)
              CupertinoDialogAction(
                child: Text(cancelText),
                onPressed: () => Navigator.of(context).pop(),
              ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () {
                onConfirm?.call();
                Navigator.of(context).pop();
              },
              child: Text(confirmText ?? 'OK'),
            ),
          ],
        ),
      );
    }

    return showDialog<T>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          if (cancelText != null)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(cancelText),
            ),
          TextButton(
            onPressed: () {
              onConfirm?.call();
              Navigator.of(context).pop();
            },
            child: Text(confirmText ?? 'OK'),
          ),
        ],
      ),
    );
  }

  /// Platform-specific action sheet / bottom sheet
  static Future<T?> showAdaptiveActionSheet<T>({
    required BuildContext context,
    required String title,
    required List<ActionSheetAction> actions,
    String? cancelText,
  }) {
    if (usesCupertinoDesign) {
      return showCupertinoModalPopup<T>(
        context: context,
        builder: (context) => CupertinoActionSheet(
          title: Text(title),
          actions: actions
              .map(
                (action) => CupertinoActionSheetAction(
                  onPressed: () {
                    action.onPressed();
                    Navigator.of(context).pop();
                  },
                  isDestructiveAction: action.isDestructive,
                  child: Text(action.label),
                ),
              )
              .toList(),
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(cancelText ?? 'Cancel'),
          ),
        ),
      );
    }

    return showModalBottomSheet<T>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ...actions.map(
              (action) => ListTile(
                onTap: () {
                  action.onPressed();
                  Navigator.of(context).pop();
                },
                title: Text(
                  action.label,
                  style: TextStyle(
                    color: action.isDestructive ? Colors.red : null,
                  ),
                ),
              ),
            ),
            const Divider(),
            ListTile(
              onTap: () => Navigator.of(context).pop(),
              title: Text(
                cancelText ?? 'Cancel',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Platform-specific date picker
  static Future<DateTime?> showAdaptiveDatePicker({
    required BuildContext context,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
  }) {
    if (usesCupertinoDesign) {
      DateTime? selectedDate = initialDate;

      return showCupertinoModalPopup<DateTime>(
        context: context,
        builder: (context) => Container(
          height: 300,
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  CupertinoButton(
                    child: const Text('Done'),
                    onPressed: () => Navigator.of(context).pop(selectedDate),
                  ),
                ],
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: initialDate,
                  minimumDate: firstDate,
                  maximumDate: lastDate,
                  onDateTimeChanged: (date) => selectedDate = date,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
  }

  // ============================================================================
  // PLATFORM-SPECIFIC NAVIGATION
  // ============================================================================

  /// Get platform-specific page route
  static PageRoute<T> adaptiveRoute<T>({
    required WidgetBuilder builder,
    RouteSettings? settings,
  }) {
    if (usesCupertinoDesign) {
      return CupertinoPageRoute<T>(
        builder: builder,
        settings: settings,
      );
    }
    return MaterialPageRoute<T>(
      builder: builder,
      settings: settings,
    );
  }

  /// Platform-specific back button
  static Widget adaptiveBackButton({
    VoidCallback? onPressed,
    Color? color,
  }) {
    if (usesCupertinoDesign) {
      return CupertinoNavigationBarBackButton(
        onPressed: onPressed,
        color: color,
      );
    }
    return BackButton(
      onPressed: onPressed,
      color: color,
    );
  }

  // ============================================================================
  // PLATFORM-SPECIFIC SCROLLING
  // ============================================================================

  /// Get platform-specific scroll physics
  static ScrollPhysics get adaptiveScrollPhysics {
    if (usesCupertinoDesign) {
      return const BouncingScrollPhysics();
    }
    return const ClampingScrollPhysics();
  }
}

/// Action sheet action model
class ActionSheetAction {
  final String label;
  final VoidCallback onPressed;
  final bool isDestructive;

  const ActionSheetAction({
    required this.label,
    required this.onPressed,
    this.isDestructive = false,
  });
}

/// Extension on BuildContext for easier platform utilities access
extension PlatformContext on BuildContext {
  /// Check if iOS
  bool get isIOS => PlatformUtils.isIOS;

  /// Check if Android
  bool get isAndroid => PlatformUtils.isAndroid;

  /// Check if Web
  bool get isWeb => PlatformUtils.isWeb;

  /// Check if mobile platform
  bool get isMobilePlatform => PlatformUtils.isMobilePlatform;

  /// Check if desktop platform
  bool get isDesktopPlatform => PlatformUtils.isDesktopPlatform;

  /// Check if uses Cupertino design
  bool get usesCupertinoDesign => PlatformUtils.usesCupertinoDesign;

  /// Check if uses Material design
  bool get usesMaterialDesign => PlatformUtils.usesMaterialDesign;
}
