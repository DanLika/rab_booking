import 'package:flutter/material.dart';
import '../theme/villa_jasko_theme_data.dart';
import '../../domain/models/widget_config.dart';

/// Wrapper widget that applies theme and configuration to booking widgets
/// Wraps the widget screens with MaterialApp to apply light/dark mode
/// Uses Azure Blue design system from DESIGN_SYSTEM.md
class ThemedWidgetWrapper extends StatelessWidget {
  final Widget child;
  final WidgetConfig? config;

  const ThemedWidgetWrapper({
    super.key,
    required this.child,
    this.config,
  });

  @override
  Widget build(BuildContext context) {
    // Get theme mode from config
    final themeMode = config != null
        ? VillaJaskoTheme.themeModeFromString(config!.themeMode)
        : ThemeMode.system;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Villa Jasko Booking Widget',
      theme: VillaJaskoTheme.lightTheme,
      darkTheme: VillaJaskoTheme.darkTheme,
      themeMode: themeMode,
      home: child,
    );
  }
}

/// Provider-based themed wrapper with hot reload support
class ThemedWidgetWrapperProvider extends StatelessWidget {
  final Widget Function(WidgetConfig? config) builder;
  final WidgetConfig? config;

  const ThemedWidgetWrapperProvider({
    super.key,
    required this.builder,
    this.config,
  });

  @override
  Widget build(BuildContext context) {
    // Get theme mode from config
    final themeMode = config != null
        ? VillaJaskoTheme.themeModeFromString(config!.themeMode)
        : ThemeMode.system;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Villa Jasko Booking Widget',
      theme: VillaJaskoTheme.lightTheme,
      darkTheme: VillaJaskoTheme.darkTheme,
      themeMode: themeMode,
      home: builder(config),
    );
  }
}
