import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import 'core/config/router_widget.dart';
import 'features/widget/presentation/theme/dynamic_theme_service.dart';
import 'features/widget/presentation/providers/widget_config_provider.dart';
import 'features/widget/domain/models/widget_config.dart';
import 'features/widget/domain/models/widget_settings.dart';
import 'shared/providers/repository_providers.dart';
import 'firebase_options.dart';

/// Widget-only entry point for embeddable booking widget
///
/// This is a separate entry point from main.dart (Owner App) that:
/// - Uses a minimal router (only widget routes)
/// - Has NO authentication required
/// - Is designed to be embedded in iframes
/// - Accepts unit ID via URL query parameter: ?unit=UNIT_ID
///
/// Build command:
/// flutter build web --target lib/widget_main.dart --output build/web_widget --release
///
/// Deploy:
/// firebase deploy --only hosting:widget
///
/// Embed code:
/// <iframe src="https://bookbed.io/?unit=UNIT_ID"
///         width="100%" height="900px" frameborder="0"></iframe>
void main() async {
  // Use path-based URL strategy (clean URLs without #)
  // This allows email links like /view?ref=XXX to work correctly
  // Firebase hosting rewrites are already configured to support this
  usePathUrlStrategy();

  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ProviderScope(child: BookingWidgetApp()));
}

/// Booking Widget App - Minimalna aplikacija samo za widget
class BookingWidgetApp extends ConsumerWidget {
  const BookingWidgetApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use minimal widget router (NO auth, NO owner dashboard routes)
    final router = ref.watch(widgetRouterProvider);

    // Get widget config from URL parameters
    final widgetConfig = ref.watch(widgetConfigProvider);

    // Try to load widget settings from Firestore (if unitId is available)
    final widgetSettingsAsync =
        widgetConfig.unitId != null && widgetConfig.propertyId != null
        ? ref.watch(_widgetSettingsProvider(widgetConfig))
        : null;

    // Get actual settings value (null if loading/error)
    final widgetSettings = widgetSettingsAsync?.valueOrNull;

    // Determine theme mode (priority: URL > Firestore > default 'system')
    final String themeMode = widgetConfig.themeMode.isNotEmpty
        ? widgetConfig.themeMode
        : (widgetSettings?.themeOptions?.themeMode ?? 'system');

    // Convert theme mode string to ThemeMode enum
    final ThemeMode themeModeEnum = _getThemeMode(themeMode);

    // Generate light and dark themes using DynamicThemeService
    final lightTheme = DynamicThemeService.generateTheme(
      config: widgetConfig,
      settings: widgetSettings,
      brightness: Brightness.light,
    );

    final darkTheme = DynamicThemeService.generateTheme(
      config: widgetConfig,
      settings: widgetSettings,
      brightness: Brightness.dark,
    );

    return MaterialApp.router(
      title: 'Rab Booking Widget',
      debugShowCheckedModeBanner: false,

      // Use Minimalist theme with dark mode support
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeModeEnum,

      routerConfig: router,

      // Multi-language support via URL parameter (?language=hr/en/de/it)
      // Translations handled in components via WidgetTranslations
    );
  }

  /// Convert theme mode string to ThemeMode enum
  ThemeMode _getThemeMode(String mode) {
    switch (mode.toLowerCase()) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }
}

/// Provider to watch widget settings from Firestore (REAL-TIME)
///
/// This provider uses StreamProvider to listen for real-time updates.
/// When owner changes settings in Dashboard, the widget will automatically
/// update without requiring a page refresh.
final _widgetSettingsProvider =
    StreamProvider.family<WidgetSettings?, WidgetConfig>((ref, config) {
      if (config.propertyId == null || config.unitId == null) {
        return Stream.value(null);
      }

      try {
        final repository = ref.read(widgetSettingsRepositoryProvider);
        return repository.watchWidgetSettings(
          propertyId: config.propertyId!,
          unitId: config.unitId!,
        );
      } catch (e) {
        // If settings don't exist or error loading, return null stream (use defaults)
        return Stream.value(null);
      }
    });
