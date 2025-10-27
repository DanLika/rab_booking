import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/widget_config.dart';

/// Provider for widget configuration
final widgetConfigProvider = StateProvider<WidgetConfig>((ref) {
  // Default configuration
  return const WidgetConfig(
    locale: 'en',
  );
});

/// Provider for widget theme based on configuration
final widgetThemeProvider = Provider<ThemeData>((ref) {
  final config = ref.watch(widgetConfigProvider);

  final primaryColor = config.primaryColor ?? Colors.blue;
  final secondaryColor = config.secondaryColor ?? Colors.blueAccent;
  final accentColor = config.accentColor ?? Colors.orange;

  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      secondary: secondaryColor,
      brightness: Brightness.light,
    ).copyWith(
      tertiary: accentColor,
    ),
  );
});
