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
import 'core/services/logging_service.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/web_utils.dart';
import 'core/widgets/owner_splash_screen.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'shared/providers/repository_providers.dart';
import 'shared/widgets/global_navigation_loader.dart';

// Sentry DSN for web error tracking (Crashlytics doesn't support web)
const String _sentryDsn =
    'https://2d78b151017ba853ff8b097914b92633@o4510516866908160.ingest.de.sentry.io/4510516869464144';

/// Global initialization state - tracks what has been initialized
class AppInitState {
  static final Completer<void> firebaseReady = Completer<void>();
  static final Completer<SharedPreferences> prefsReady = Completer<SharedPreferences>();
  static final Completer<void> allReady = Completer<void>();

  static bool get isFirebaseReady => firebaseReady.isCompleted;
  static bool get isPrefsReady => prefsReady.isCompleted;
  static bool get isAllReady => allReady.isCompleted;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Start Flutter UI IMMEDIATELY - don't wait for Firebase
  // This allows the splash screen to show while initialization happens
  _runAppWithDeferredInit();
}

/// Runs the app immediately, initialization happens in background
void _runAppWithDeferredInit() {
  // Initialize error handling first (sync, fast)
  if (kReleaseMode) {
    if (!kIsWeb) {
      // Mobile: Use Firebase Crashlytics (will work after Firebase init)
      FlutterError.onError = (details) {
        if (AppInitState.isFirebaseReady) {
          FirebaseCrashlytics.instance.recordFlutterFatalError(details);
        }
      };
      PlatformDispatcher.instance.onError = (error, stack) {
        if (AppInitState.isFirebaseReady) {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        }
        return true;
      };
    }
  } else {
    // Debug: Use custom error handler with better logging
    GlobalErrorHandler.initialize();
  }

  // Run app IMMEDIATELY - splash screen will show
  runApp(const ProviderScope(child: BookBedApp()));

  // Initialize everything in background AFTER app is running
  _initializeInBackground();
}

/// Background initialization - happens while splash screen is visible
Future<void> _initializeInBackground() async {
  LoggingService.log('Starting background initialization...', tag: 'INIT');
  final stopwatch = Stopwatch()..start();

  try {
    // Initialize Firebase
    LoggingService.log('Initializing Firebase...', tag: 'INIT');
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    AppInitState.firebaseReady.complete();
    LoggingService.log('Firebase ready (${stopwatch.elapsedMilliseconds}ms)', tag: 'INIT');

    // Initialize SharedPreferences
    LoggingService.log('Initializing SharedPreferences...', tag: 'INIT');
    final prefs = await SharedPreferences.getInstance();
    AppInitState.prefsReady.complete(prefs);
    LoggingService.log('SharedPreferences ready (${stopwatch.elapsedMilliseconds}ms)', tag: 'INIT');

    // Initialize Sentry for web (non-blocking)
    if (kReleaseMode && kIsWeb && _sentryDsn.isNotEmpty) {
      unawaited(_initSentry());
    }

    // Mark all initialization as complete
    AppInitState.allReady.complete();
    LoggingService.log('All initialization complete (${stopwatch.elapsedMilliseconds}ms)', tag: 'INIT');
  } catch (e, stack) {
    LoggingService.log('Initialization error: $e', tag: 'INIT_ERROR');
    // Complete with error so app can handle it
    if (!AppInitState.firebaseReady.isCompleted) {
      AppInitState.firebaseReady.completeError(e, stack);
    }
    if (!AppInitState.allReady.isCompleted) {
      AppInitState.allReady.completeError(e, stack);
    }
  }
}

/// Initialize Sentry (web only, non-blocking)
Future<void> _initSentry() async {
  try {
    await SentryFlutter.init((options) {
      options.dsn = _sentryDsn;
      options.tracesSampleRate = 0.2;
      options.environment = 'production';
    });
    LoggingService.log('Sentry initialized', tag: 'INIT');
  } catch (e) {
    LoggingService.log('Sentry init failed: $e', tag: 'INIT_ERROR');
  }
}

/// Main application widget with splash screen
class BookBedApp extends ConsumerStatefulWidget {
  const BookBedApp({super.key});

  @override
  ConsumerState<BookBedApp> createState() => _BookBedAppState();
}

class _BookBedAppState extends ConsumerState<BookBedApp> {
  bool _isInitialized = false;
  bool _showFlutterSplash = true;
  SharedPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    _waitForInitialization();
  }

  /// Wait for all initialization to complete
  Future<void> _waitForInitialization() async {
    LoggingService.log('Waiting for initialization...', tag: 'APP');

    try {
      // Wait for SharedPreferences (needed for theme/locale)
      _prefs = await AppInitState.prefsReady.future;
      LoggingService.log('Prefs ready, updating state...', tag: 'APP');

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      LoggingService.log('Init error: $e', tag: 'APP_ERROR');
      // Still mark as initialized so app can show error state
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Phase 1: Before initialization - show Flutter splash (matches HTML splash)
    if (!_isInitialized || _prefs == null) {
      return const _InitializingSplash();
    }

    // Phase 2: Initialized - show app with auth-aware splash overlay
    return ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(_prefs!)],
      child: _InitializedApp(
        showSplash: _showFlutterSplash,
        onSplashComplete: () {
          if (mounted) {
            setState(() {
              _showFlutterSplash = false;
            });
            // Hide native HTML splash
            _hideNativeSplash();
          }
        },
      ),
    );
  }

  /// Hide the native HTML splash screen
  void _hideNativeSplash() {
    hideNativeSplash();
  }
}

/// Simple splash screen shown during initialization (before providers are ready)
class _InitializingSplash extends StatelessWidget {
  const _InitializingSplash();

  @override
  Widget build(BuildContext context) {
    // Use platform brightness to match HTML splash
    final brightness = MediaQuery.platformBrightnessOf(context);
    final isDark = brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF000000) : const Color(0xFFFAFAFA);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: Scaffold(
        backgroundColor: backgroundColor,
        body: const Center(
          // Empty - native HTML splash is still visible
          // This just provides a Flutter surface behind it
          child: SizedBox.shrink(),
        ),
      ),
    );
  }
}

/// The fully initialized app with all providers
class _InitializedApp extends ConsumerStatefulWidget {
  final bool showSplash;
  final VoidCallback onSplashComplete;

  const _InitializedApp({required this.showSplash, required this.onSplashComplete});

  @override
  ConsumerState<_InitializedApp> createState() => _InitializedAppState();
}

class _InitializedAppState extends ConsumerState<_InitializedApp> {
  final Completer<void> _authReadyCompleter = Completer<void>();
  bool _authChecked = false;

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(ownerRouterProvider);
    final locale = ref.watch(currentLocaleProvider);
    final themeMode = ref.watch(currentThemeModeProvider);

    // Watch auth state to detect when initial auth check is complete
    final authState = ref.watch(enhancedAuthProvider);

    // Complete the auth ready future when auth is no longer loading
    if (!_authChecked && !authState.isLoading) {
      _authChecked = true;
      if (!_authReadyCompleter.isCompleted) {
        LoggingService.log('Auth check complete, isAuthenticated=${authState.isAuthenticated}', tag: 'APP');
        _authReadyCompleter.complete();
      }
    }

    // Build the main app
    final app = MaterialApp.router(
      title: 'BookBed',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        return ErrorBoundary(child: GlobalNavigationOverlay(child: child!));
      },
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('hr')],
    );

    // Show splash overlay while waiting for auth
    if (widget.showSplash) {
      return OwnerSplashOverlay(
        initializationFuture: _authReadyCompleter.future,
        minimumDisplayTime: 0,
        onComplete: widget.onSplashComplete,
        child: app,
      );
    }

    return app;
  }
}
