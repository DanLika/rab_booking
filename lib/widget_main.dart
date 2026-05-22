import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/config/router_widget.dart';
import 'core/utils/sentry_env.dart';
import 'core/utils/web_utils.dart'; // For hideNativeSplash
import 'features/widget/presentation/theme/dynamic_theme_service.dart';
import 'features/widget/presentation/providers/widget_config_provider.dart';
import 'shared/providers/widget_repository_providers.dart';
import 'firebase_options.dart';
import 'core/config/environment.dart';

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

/// Safari-compatible Firebase initialization
/// Firebase.apps getter throws "Null check operator used on a null value" on Safari
/// This wrapper catches that error and proceeds with initialization
Future<void> _initializeFirebaseSafely() async {
  try {
    // SAFARI FIX: Firebase.apps getter can throw on Safari
    bool needsInit = true;
    try {
      needsInit = Firebase.apps.isEmpty;
    } catch (_) {
      // Safari throws here - assume Firebase needs initialization
      needsInit = true;
    }

    if (needsInit) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Safety: crash early in debug if our init landed on the wrong project.
      // Only fires when we did the init ourselves (needsInit=true). If another
      // entry point already initialized Firebase, that entry owns the assert.
      if (kDebugMode) {
        const expectedProjectId = 'rab-booking-248fc';
        final actualProjectId = Firebase.app().options.projectId;
        assert(
          actualProjectId == expectedProjectId,
          'PROD widget entry point connected to wrong Firebase project: '
          '$actualProjectId (expected $expectedProjectId). '
          'Did you mean to run lib/widget_main_dev.dart or '
          'lib/widget_main_staging.dart? '
          'Or is ios/Runner/GoogleService-Info.plist swapped to a dev variant?',
        );
      }
    }
  } catch (e) {
    // Ignore duplicate-app errors
    if (!e.toString().contains('duplicate-app')) {
      rethrow;
    }
  }
}

void main() async {
  // Use path-based URL strategy (clean URLs without #)
  // This allows email links like /view?ref=XXX to work correctly
  // Firebase hosting rewrites are already configured to support this
  usePathUrlStrategy();

  WidgetsFlutterBinding.ensureInitialized();

  // CRITICAL: Disable Google Fonts runtime fetching to prevent crashes when offline
  // When false, the package uses system fonts as fallback instead of attempting network download
  GoogleFonts.config.allowRuntimeFetching = false;

  // PERFORMANCE OPTIMIZATION: Run heavy initializations in parallel
  // This reduces startup time by ~100-200ms compared to sequential await
  SharedPreferences? prefs;

  await Future.wait([
    // Initialize Firebase (with Safari fix)
    _initializeFirebaseSafely(),

    // Initialize SharedPreferences for widget entry point
    // This is needed for providers that use SharedPreferences (e.g., form persistence)
    Future(() async {
      try {
        prefs = await SharedPreferences.getInstance();
      } catch (e) {
        // If SharedPreferences fails to initialize, continue without it
        // Providers will handle missing SharedPreferences gracefully
        prefs = null;
      }
    }),

    // Initialize date formatting for all locales (required by intl package)
    // Supports: hr, en, de, it based on URL ?language= parameter
    initializeDateFormatting(),
  ]);

  // Override SharedPreferences provider if initialization succeeded
  final overrides = prefs != null
      ? [sharedPreferencesProvider.overrideWithValue(prefs)]
      : <Override>[];

  // Initialize Sentry for error tracking (production only)
  final sentryDsn = EnvironmentConfig.sentryDsn;
  if (kReleaseMode && sentryDsn != null && sentryDsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options.dsn = sentryDsn;
        options.tracesSampleRate = 0.2;
        options.environment = detectSentryEnvironment();
        // Tag as widget to distinguish from owner dashboard
        // Filter non-critical errors before sending
        options.beforeSend = (event, hint) {
          final exception = event.throwable;
          final exceptionString = exception?.toString().toLowerCase() ?? '';
          final message = event.message?.formatted.toLowerCase() ?? '';

          // Downgrade geolocation errors to info level
          // These are expected failures when geolocation services are unreachable or slow
          if (exceptionString.contains('geolocation') ||
              exceptionString.contains('ipapi') ||
              exceptionString.contains('ipwhois') ||
              message.contains('geolocation') ||
              message.contains('ipapi') ||
              message.contains('ipwhois')) {
            return event.copyWith(
              level: SentryLevel.info,
              tags: {...?event.tags, 'app_type': 'booking_widget'},
            );
          }

          // Drop WebGL/CanvasKit errors entirely
          // These are expected on some browsers (e.g., Chrome iOS) with automatic fallback
          // and are completely unactionable — no need to track them
          if (exceptionString.contains('getparameter') ||
              exceptionString.contains('webgl') ||
              exceptionString.contains('canvaskit') ||
              message.contains('getparameter') ||
              message.contains('webgl') ||
              message.contains('canvaskit')) {
            return null;
          }

          // Drop Firestore offline/unavailable errors
          // Widget has no persistence — offline errors are expected in iframe
          // contexts with intermittent connectivity. Retry logic handles recovery.
          if (exceptionString.contains('client is offline') ||
              (exceptionString.contains('cloud_firestore') &&
                  exceptionString.contains('unavailable'))) {
            return null;
          }

          // All other errors - add app_type tag
          return event.copyWith(
            tags: {...?event.tags, 'app_type': 'booking_widget'},
          );
        };
      },
      appRunner: () => runApp(
        ProviderScope(overrides: overrides, child: const BookingWidgetApp()),
      ),
    );
  } else {
    // Debug mode - run without Sentry
    runApp(
      ProviderScope(overrides: overrides, child: const BookingWidgetApp()),
    );
  }
}

/// Booking Widget App - Minimalna aplikacija samo za widget
class BookingWidgetApp extends ConsumerStatefulWidget {
  const BookingWidgetApp({super.key});

  @override
  ConsumerState<BookingWidgetApp> createState() => _BookingWidgetAppState();
}

class _BookingWidgetAppState extends ConsumerState<BookingWidgetApp> {
  bool _splashHidden = false;

  @override
  void initState() {
    super.initState();
    // HYBRID LOADING: Hide native splash IMMEDIATELY when first frame renders
    // This shows Flutter UI with skeleton calendar instead of waiting for data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_splashHidden) {
        _splashHidden = true;
        hideNativeSplash();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Precache logo assets for loaders (prevents white square during load)
    // logo-light.png = purple logo for light theme
    // logo-dark.png = white logo for dark theme
    precacheImage(const AssetImage('assets/images/logo-light.png'), context);
    precacheImage(const AssetImage('assets/images/logo-dark.png'), context);
  }

  @override
  Widget build(BuildContext context) {
    // Use minimal widget router (NO auth, NO owner dashboard routes)
    final router = ref.watch(widgetRouterProvider);

    // Get widget config from URL parameters
    final widgetConfig = ref.watch(widgetConfigProvider);

    // PERFORMANCE OPTIMIZATION: Theme is generated from URL config only.
    // Settings-based theme customization happens after widgetContextProvider loads in BookingWidgetScreen.
    // This reduces initial queries from 4 to 3 (property + unit + settings via widgetContextProvider only).

    // Determine theme mode from URL (default: 'system')
    final String themeMode = widgetConfig.themeMode.isNotEmpty
        ? widgetConfig.themeMode
        : 'system';

    // Convert theme mode string to ThemeMode enum
    final ThemeMode themeModeEnum = _getThemeMode(themeMode);

    // Generate light and dark themes using DynamicThemeService (URL config only)
    final lightTheme = DynamicThemeService.generateTheme(
      config: widgetConfig,
      // settings: null is default - loaded later by widgetContextProvider
      brightness: Brightness.light,
    );

    final darkTheme = DynamicThemeService.generateTheme(
      config: widgetConfig,
      // settings: null is default - loaded later by widgetContextProvider
      brightness: Brightness.dark,
    );

    return MaterialApp.router(
      title: 'BookBed Widget',
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
  ThemeMode _getThemeMode(String mode) => switch (mode.toLowerCase()) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
}
