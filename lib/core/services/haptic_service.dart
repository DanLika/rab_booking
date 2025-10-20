import 'package:flutter/services.dart';
import '../utils/platform_utils.dart';

/// Haptic feedback service for mobile platforms
/// Provides tactile feedback for user interactions on iOS and Android
class HapticService {
  HapticService._();

  /// Check if haptics are supported on this platform
  static bool get isSupported => PlatformUtils.supportsHaptics;

  /// Light impact feedback
  /// Use for: switches, toggles, small UI changes
  static Future<void> lightImpact() async {
    if (!isSupported) return;
    await HapticFeedback.lightImpact();
  }

  /// Medium impact feedback
  /// Use for: buttons, navigation, moderate interactions
  static Future<void> mediumImpact() async {
    if (!isSupported) return;
    await HapticFeedback.mediumImpact();
  }

  /// Heavy impact feedback
  /// Use for: important actions, confirmations, major changes
  static Future<void> heavyImpact() async {
    if (!isSupported) return;
    await HapticFeedback.heavyImpact();
  }

  /// Selection changed feedback
  /// Use for: scrolling pickers, sliders, incremental changes
  static Future<void> selectionClick() async {
    if (!isSupported) return;
    await HapticFeedback.selectionClick();
  }

  /// Vibrate for errors
  /// Use for: validation errors, failed actions
  static Future<void> error() async {
    if (!isSupported) return;
    // Use heavy impact for error indication
    await HapticFeedback.heavyImpact();
  }

  /// Vibrate for success
  /// Use for: completed actions, successful submissions
  static Future<void> success() async {
    if (!isSupported) return;
    // Use medium impact for success indication
    await HapticFeedback.mediumImpact();
  }

  /// Vibrate for warnings
  /// Use for: warnings, alerts, attention needed
  static Future<void> warning() async {
    if (!isSupported) return;
    // Use light impact twice for warning
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 50));
    await HapticFeedback.lightImpact();
  }

  /// Button press feedback
  /// Use for: any button tap
  static Future<void> buttonPress() async {
    if (!isSupported) return;
    await HapticFeedback.mediumImpact();
  }

  /// Toggle feedback
  /// Use for: switches, checkboxes, radio buttons
  static Future<void> toggle() async {
    if (!isSupported) return;
    await HapticFeedback.lightImpact();
  }

  /// Navigation feedback
  /// Use for: tab changes, page transitions
  static Future<void> navigation() async {
    if (!isSupported) return;
    await HapticFeedback.selectionClick();
  }

  /// Swipe feedback
  /// Use for: swipe gestures, dismissals
  static Future<void> swipe() async {
    if (!isSupported) return;
    await HapticFeedback.lightImpact();
  }

  /// Long press feedback
  /// Use for: long press actions, context menus
  static Future<void> longPress() async {
    if (!isSupported) return;
    await HapticFeedback.heavyImpact();
  }

  /// Refresh feedback
  /// Use for: pull-to-refresh actions
  static Future<void> refresh() async {
    if (!isSupported) return;
    await HapticFeedback.mediumImpact();
  }

  /// Delete feedback
  /// Use for: delete actions, removals
  static Future<void> delete() async {
    if (!isSupported) return;
    await HapticFeedback.heavyImpact();
  }

  /// Generic vibrate
  /// Use for: custom vibration patterns
  static Future<void> vibrate() async {
    if (!isSupported) return;
    await HapticFeedback.vibrate();
  }
}

/// Extension on functions to add haptic feedback
extension HapticCallback on VoidCallback {
  /// Execute callback with haptic feedback
  VoidCallback withHaptic({HapticFeedbackType type = HapticFeedbackType.medium}) {
    return () async {
      switch (type) {
        case HapticFeedbackType.light:
          await HapticService.lightImpact();
          break;
        case HapticFeedbackType.medium:
          await HapticService.mediumImpact();
          break;
        case HapticFeedbackType.heavy:
          await HapticService.heavyImpact();
          break;
        case HapticFeedbackType.selection:
          await HapticService.selectionClick();
          break;
        case HapticFeedbackType.error:
          await HapticService.error();
          break;
        case HapticFeedbackType.success:
          await HapticService.success();
          break;
        case HapticFeedbackType.warning:
          await HapticService.warning();
          break;
      }
      this();
    };
  }
}

/// Haptic feedback types
enum HapticFeedbackType {
  light,
  medium,
  heavy,
  selection,
  error,
  success,
  warning,
}

/// Example usage:
///
/// ```dart
/// // Simple usage
/// ElevatedButton(
///   onPressed: () async {
///     await HapticService.buttonPress();
///     // Your action here
///   },
///   child: Text('Press Me'),
/// )
///
/// // With extension
/// ElevatedButton(
///   onPressed: _handleSubmit.withHaptic(type: HapticFeedbackType.success),
///   child: Text('Submit'),
/// )
///
/// // For specific actions
/// await HapticService.success(); // After successful operation
/// await HapticService.error();   // After failed operation
/// await HapticService.warning(); // For warnings
/// ```
