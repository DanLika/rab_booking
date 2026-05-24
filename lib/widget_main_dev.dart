import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/config/router_widget.dart';
import 'core/utils/web_utils.dart'; // For hideNativeSplash
import 'features/widget/presentation/providers/language_provider.dart';
import 'features/widget/presentation/theme/dynamic_theme_service.dart';
import 'features/widget/presentation/providers/widget_config_provider.dart';
import 'shared/providers/widget_repository_providers.dart';
import 'firebase_options_dev.dart'; // Import DEV options

// Sentry not used in DEV to avoid noise
// const String _sentryDsn = ...

/// WIDGET DEVELOPMENT ENTRY POINT
///
/// Uses [DevFirebaseOptions] to connect to bookbed-dev project.

/// Safari-compatible Firebase initialization for DEV
Future<void> _initializeFirebaseSafelyDev() async {
  try {
    bool needsInit = true;
    try {
      needsInit = Firebase.apps.isEmpty;
    } catch (_) {
      needsInit = true;
    }

    if (needsInit) {
      await Firebase.initializeApp(options: DevFirebaseOptions.currentPlatform);
    }
  } catch (e) {
    if (!e.toString().contains('duplicate-app')) {
      rethrow;
    }
  }

  // Safety: crash early in debug if Firebase is wired to the wrong project.
  if (kDebugMode) {
    const expectedProjectId = 'bookbed-dev';
    final actualProjectId = Firebase.app().options.projectId;
    assert(
      actualProjectId == expectedProjectId,
      'DEV widget entry point connected to wrong Firebase project: '
      '$actualProjectId (expected $expectedProjectId). '
      'Check ios/Runner/GoogleService-Info.plist and --target flag.',
    );
  }
}

void main() async {
  usePathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();

  // CRITICAL: Disable Google Fonts runtime fetching to prevent crashes when offline
  // When false, the package uses system fonts as fallback instead of attempting network download
  GoogleFonts.config.allowRuntimeFetching = false;

  // Initialize Firebase with DEV options (Safari fix)
  await _initializeFirebaseSafelyDev();

  SharedPreferences? prefs;
  try {
    prefs = await SharedPreferences.getInstance();
  } catch (e) {
    prefs = null;
  }

  await initializeDateFormatting();

  // Run app without Sentry for dev
  runApp(
    ProviderScope(
      overrides: prefs != null
          ? [sharedPreferencesProvider.overrideWithValue(prefs)]
          : [],
      child: const BookingWidgetApp(),
    ),
  );
}

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
    final router = ref.watch(widgetRouterProvider);
    final widgetConfig = ref.watch(widgetConfigProvider);

    final String themeMode = widgetConfig.themeMode.isNotEmpty
        ? widgetConfig.themeMode
        : 'system';

    final ThemeMode themeModeEnum = _getThemeMode(themeMode);

    final lightTheme = DynamicThemeService.generateTheme(
      config: widgetConfig,
      brightness: Brightness.light,
    );

    final darkTheme = DynamicThemeService.generateTheme(
      config: widgetConfig,
      brightness: Brightness.dark,
    );

    // See widget_main.dart for rationale (audit/32 N1).
    final languageCode = ref.watch(languageProvider);
    final appLocale = Locale(languageCode);

    return MaterialApp.router(
      title: 'BookBed Widget (DEV)',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeModeEnum,
      routerConfig: router,
      locale: appLocale,
      supportedLocales: const [
        Locale('hr'),
        Locale('en'),
        Locale('de'),
        Locale('it'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }

  ThemeMode _getThemeMode(String mode) => switch (mode.toLowerCase()) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
}
