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
import 'firebase_options_staging.dart'; // Import STAGING options

/// WIDGET STAGING ENTRY POINT
///
/// Uses [StagingFirebaseOptions] to connect to bookbed-staging project.
/// Mirrors `widget_main_dev.dart` swapping dev → staging options.

/// Safari-compatible Firebase initialization for STAGING
Future<void> _initializeFirebaseSafelyStaging() async {
  try {
    bool needsInit = true;
    try {
      needsInit = Firebase.apps.isEmpty;
    } catch (_) {
      needsInit = true;
    }

    if (needsInit) {
      await Firebase.initializeApp(
        options: StagingFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    if (!e.toString().contains('duplicate-app')) {
      rethrow;
    }
  }

  // Safety: in debug builds, refuse to boot if the runtime Firebase project
  // doesn't match this entry point's declared target. Prevents the iOS
  // "swapped plist + wrong --target" silent contamination class (audit/15).
  if (kDebugMode) {
    const expectedProjectId = 'bookbed-staging';
    final actualProjectId = Firebase.app().options.projectId;
    assert(
      actualProjectId == expectedProjectId,
      'STAGING entry point connected to wrong Firebase project: '
      '$actualProjectId (expected $expectedProjectId). '
      'Check ios/Runner/GoogleService-Info.plist and --target flag.',
    );
  }
}

void main() async {
  usePathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();

  // CRITICAL: Disable Google Fonts runtime fetching to prevent crashes when offline
  GoogleFonts.config.allowRuntimeFetching = false;

  await _initializeFirebaseSafelyStaging();

  SharedPreferences? prefs;
  try {
    prefs = await SharedPreferences.getInstance();
  } catch (e) {
    prefs = null;
  }

  await initializeDateFormatting();

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
      title: 'BookBed Widget (Staging)',
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
