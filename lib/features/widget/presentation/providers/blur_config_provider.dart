import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/widget_settings.dart';

/// Blur Config Provider - Provides blur/glassmorphism configuration for the widget
///
/// This provider is overridden in widget_main.dart with the actual blur config
/// loaded from Firestore (via WidgetSettings).
///
/// Usage in widget screens:
/// ```dart
/// final blurConfig = ref.watch(blurConfigProvider);
/// final isBlurEnabled = blurConfig.enabled && blurConfig.enableCardBlur;
/// ```
final blurConfigProvider = Provider<BlurConfig>((ref) {
  // Default configuration (will be overridden in widget_main.dart)
  return const BlurConfig();
});

/// Helper provider to check if blur is globally enabled
final isBlurEnabledProvider = Provider<bool>((ref) {
  final config = ref.watch(blurConfigProvider);
  return config.enabled;
});

/// Helper provider to check if card blur is enabled
final isCardBlurEnabledProvider = Provider<bool>((ref) {
  final config = ref.watch(blurConfigProvider);
  return config.enabled && config.enableCardBlur;
});

/// Helper provider to check if app bar blur is enabled
final isAppBarBlurEnabledProvider = Provider<bool>((ref) {
  final config = ref.watch(blurConfigProvider);
  return config.enabled && config.enableAppBarBlur;
});

/// Helper provider to check if modal blur is enabled
final isModalBlurEnabledProvider = Provider<bool>((ref) {
  final config = ref.watch(blurConfigProvider);
  return config.enabled && config.enableModalBlur;
});

/// Helper provider to check if overlay blur is enabled
final isOverlayBlurEnabledProvider = Provider<bool>((ref) {
  final config = ref.watch(blurConfigProvider);
  return config.enabled && config.enableOverlayBlur;
});

/// Helper provider to get the blur intensity as a double (0.0 - 1.0)
final blurIntensityProvider = Provider<double>((ref) {
  final config = ref.watch(blurConfigProvider);
  return config.intensityValue;
});
