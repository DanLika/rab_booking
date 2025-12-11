import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/config/router_owner.dart';
import 'core/error_handling/error_boundary.dart';
import 'core/providers/enhanced_auth_provider.dart';
import 'core/providers/language_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/owner_splash_screen.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'shared/providers/repository_providers.dart';
import 'shared/widgets/global_navigation_loader.dart';

// Sentry DSN for web error tracking (Crashlytics doesn't support web)
const String _sentryDsn = 'https://2d78b151017ba853ff8b097914b92633@o4510516866908160.ingest.de.sentry.io/4510516869464144';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();

  // Initialize Global Error Handling based on platform
  if (kReleaseMode) {
    if (kIsWeb && _sentryDsn.isNotEmpty) {
      // Web: Use Sentry (Crashlytics doesn't support web)
      await SentryFlutter.init(
        (options) {
          options.dsn = _sentryDsn;
          options.tracesSampleRate = 0.2; // 20% of transactions for performance
          options.environment = 'production';
        },
        appRunner: () => _runApp(sharedPreferences),
      );
      return; // SentryFlutter.init handles runApp
    } else if (!kIsWeb) {
      // Mobile: Use Firebase Crashlytics
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    }
  } else {
    // Debug: Use custom error handler with better logging
    GlobalErrorHandler.initialize();
  }

  _runApp(sharedPreferences);
}

void _runApp(SharedPreferences sharedPreferences) {
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const BookBedApp(),
    ),
  );
}

/// Main application widget with splash screen
class BookBedApp extends ConsumerStatefulWidget {
  const BookBedApp({super.key});

  @override
  ConsumerState<BookBedApp> createState() => _BookBedAppState();
}

class _BookBedAppState extends ConsumerState<BookBedApp> {
  bool _showSplash = true;
  final Completer<void> _authReadyCompleter = Completer<void>();
  bool _authChecked = false;

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(ownerRouterProvider);
    final locale = ref.watch(currentLocaleProvider);

    // Watch theme mode from theme provider (uses local SharedPreferences)
    final themeMode = ref.watch(currentThemeModeProvider);

    // Watch auth state to detect when initial auth check is complete
    final authState = ref.watch(enhancedAuthProvider);

    // Complete the auth ready future when auth is no longer loading
    // This happens once Firebase Auth determines if user is logged in or not
    if (!_authChecked && !authState.isLoading) {
      _authChecked = true;
      if (!_authReadyCompleter.isCompleted) {
        _authReadyCompleter.complete();
      }
    }

    return MaterialApp.router(
      title: 'BookBed',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      // Global navigation loader + error boundary + splash screen
      builder: (context, child) {
        // Show splash screen overlay during initial load
        if (_showSplash) {
          return OwnerSplashOverlay(
            initializationFuture: _authReadyCompleter.future,
            onComplete: () {
              if (mounted) {
                setState(() {
                  _showSplash = false;
                });
              }
            },
          );
        }
        return ErrorBoundary(child: GlobalNavigationOverlay(child: child!));
      },
      // Localization configuration
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('hr'), // Croatian
      ],
    );
  }
}
