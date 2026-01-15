import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/config/environment.dart';
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
import 'shared/widgets/offline_indicator.dart';

import 'shared/widgets/global_navigation_loader.dart';

// Sentry DSN loaded from EnvironmentConfig (eliminates hardcoded constant)

/// Global initialization state - tracks what has been initialized
class AppInitState {
  static final Completer<void> firebaseReady = Completer<void>();
  static final Completer<SharedPreferences> prefsReady =
      Completer<SharedPreferences>();
  static final Completer<void> allReady = Completer<void>();

  static bool get isFirebaseReady => firebaseReady.isCompleted;
  static bool get isPrefsReady => prefsReady.isCompleted;
  static bool get isAllReady => allReady.isCompleted;
}

/// Safely convert error to string, handling null and edge cases
/// Prevents "Null check operator used on a null value" errors
String _safeErrorToString(dynamic error) {
  if (error == null) {
    return 'Unknown error';
  }
  try {
    return error.toString();
  } catch (e) {
    // If toString() itself throws, return a safe fallback
    return 'Error: Unable to display error details';
  }
}

/// FCM: Background message handler
/// Must be a top-level function and annotated with `@pragma('vm:entry-point')`
/// to ensure it can be found by the Flutter engine when the app is killed.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized (required for background headless isolate)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Log background message (optional: could update local database, acknowledge receipt, etc.)
  LoggingService.log(
    'FCM Background Message: ${message.messageId}',
    tag: 'FCM_BACKGROUND',
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Start Flutter UI IMMEDIATELY - don't wait for Firebase
  // This allows the splash screen to show while initialization happens
  _runAppWithDeferredInit();
}

/// Entry point for environment-specific main files
/// Called AFTER Firebase is initialized by the environment entry point
void runMainApp() {
  // Mark Firebase as ready since it was initialized by the entry point
  if (!AppInitState.firebaseReady.isCompleted) {
    AppInitState.firebaseReady.complete();
  }

  // Setup error handling and run app
  _setupErrorHandling();
  runApp(const ProviderScope(child: BookBedApp()));

  // Initialize remaining services in background (SharedPreferences, Sentry)
  _initializeRemainingServices();
}

/// Setup error handling (extracted from _runAppWithDeferredInit)
void _setupErrorHandling() {
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
    } else {
      // Web: Handle errors gracefully, including WebGL/CanvasKit errors
      FlutterError.onError = (details) {
        final exception = details.exception;
        final errorString = _safeErrorToString(exception);
        if (errorString.contains('getParameter') ||
            errorString.contains('WebGL') ||
            errorString.contains('CanvasKit')) {
          LoggingService.log(
            'WebGL/CanvasKit error (non-fatal): ${_safeErrorToString(exception)}',
            tag: 'WEBGL_ERROR',
          );
          return;
        }
        LoggingService.log(
          'Flutter error: ${_safeErrorToString(exception)}',
          tag: 'FLUTTER_ERROR',
        );
      };
      PlatformDispatcher.instance.onError = (error, stack) {
        final errorString = _safeErrorToString(error);
        if (errorString.contains('getParameter') ||
            errorString.contains('WebGL') ||
            errorString.contains('CanvasKit')) {
          LoggingService.log(
            'WebGL/CanvasKit error (non-fatal): $error',
            tag: 'WEBGL_ERROR',
          );
          return true;
        }
        LoggingService.log('Platform error: $error', tag: 'PLATFORM_ERROR');
        return true;
      };
    }
  } else {
    GlobalErrorHandler.initialize();
  }

  // Set custom ErrorWidget for graceful error display
  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (kDebugMode) {
      return Material(
        child: Container(
          color: const Color(0xFFFFF3F3),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: Color(0xFFD32F2F),
              ),
              const SizedBox(height: 16),
              const Text(
                'Widget Error',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFD32F2F),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _safeErrorToString(details.exception),
                style: const TextStyle(fontSize: 12, color: Color(0xFFC62828)),
                textAlign: TextAlign.center,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
    }
    return const Material(
      child: Center(
        child: Text(
          'Something went wrong',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ),
    );
  };
}

/// Initialize remaining services after Firebase (SharedPreferences, Sentry)
Future<void> _initializeRemainingServices() async {
  LoggingService.log('Initializing remaining services...', tag: 'INIT');
  final stopwatch = Stopwatch()..start();

  try {
    // Initialize SharedPreferences
    LoggingService.log('Initializing SharedPreferences...', tag: 'INIT');
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!AppInitState.prefsReady.isCompleted) {
        AppInitState.prefsReady.complete(prefs);
      }
      LoggingService.log(
        'SharedPreferences ready (${stopwatch.elapsedMilliseconds}ms)',
        tag: 'INIT',
      );
    } catch (e, stack) {
      LoggingService.log(
        'SharedPreferences init failed: $e',
        tag: 'INIT_ERROR',
      );
      if (!AppInitState.prefsReady.isCompleted) {
        AppInitState.prefsReady.completeError(e, stack);
      }
    }

    // Initialize Sentry for web (non-blocking)
    if (kReleaseMode && kIsWeb && EnvironmentConfig.sentryDsn != null) {
      unawaited(_initSentry());
    }

    // Mark all initialization as complete
    if (!AppInitState.allReady.isCompleted) {
      AppInitState.allReady.complete();
    }
    LoggingService.log(
      'All initialization complete (${stopwatch.elapsedMilliseconds}ms)',
      tag: 'INIT',
    );
  } catch (e, stack) {
    LoggingService.log('Initialization error: $e', tag: 'INIT_ERROR');
    if (!AppInitState.allReady.isCompleted) {
      AppInitState.allReady.completeError(e, stack);
    }
  }
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
    } else {
      // Web: Handle errors gracefully, including WebGL/CanvasKit errors
      FlutterError.onError = (details) {
        // Log WebGL/CanvasKit errors but don't crash the app
        final exception = details.exception;
        final errorString = _safeErrorToString(exception);
        if (errorString.contains('getParameter') ||
            errorString.contains('WebGL') ||
            errorString.contains('CanvasKit')) {
          LoggingService.log(
            'WebGL/CanvasKit error (non-fatal): ${_safeErrorToString(exception)}',
            tag: 'WEBGL_ERROR',
          );
          // Don't rethrow - allow app to continue
          return;
        }
        // For other errors, log and continue
        LoggingService.log(
          'Flutter error: ${_safeErrorToString(exception)}',
          tag: 'FLUTTER_ERROR',
        );
      };
      PlatformDispatcher.instance.onError = (error, stack) {
        // Handle WebGL/CanvasKit errors gracefully
        final errorString = _safeErrorToString(error);
        if (errorString.contains('getParameter') ||
            errorString.contains('WebGL') ||
            errorString.contains('CanvasKit')) {
          LoggingService.log(
            'WebGL/CanvasKit error (non-fatal): $error',
            tag: 'WEBGL_ERROR',
          );
          return true; // Mark as handled, don't crash
        }
        // Log other errors
        LoggingService.log('Platform error: $error', tag: 'PLATFORM_ERROR');
        return true; // Mark as handled
      };
    }
  } else {
    // Debug: Use custom error handler with better logging
    GlobalErrorHandler.initialize();
  }

  // Set custom ErrorWidget for graceful error display in both debug and release
  ErrorWidget.builder = (FlutterErrorDetails details) {
    // In debug mode, show more details; in release, show friendly message
    if (kDebugMode) {
      return Material(
        child: Container(
          color: const Color(0xFFFFF3F3),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: Color(0xFFD32F2F),
              ),
              const SizedBox(height: 16),
              const Text(
                'Widget Error',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFD32F2F),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _safeErrorToString(details.exception),
                style: const TextStyle(fontSize: 12, color: Color(0xFFC62828)),
                textAlign: TextAlign.center,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
    }
    // Release mode: minimal error display
    return const Material(
      child: Center(
        child: Text(
          'Something went wrong',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ),
    );
  };

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
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
    } catch (e) {
      if (!e.toString().contains('duplicate-app')) {
        rethrow;
      }
    } // Enable Firestore Persistence (must be done before other Firestore usage)
    try {
      // Use settings for all platforms
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      LoggingService.log('Firestore persistence enabled', tag: 'INIT');
    } catch (e) {
      LoggingService.log(
        'Firestore persistence failed: $e',
        tag: 'INIT_WARNING',
      );
    }
    AppInitState.firebaseReady.complete();
    LoggingService.log(
      'Firebase ready (${stopwatch.elapsedMilliseconds}ms)',
      tag: 'INIT',
    );

    // Initialize SharedPreferences
    LoggingService.log('Initializing SharedPreferences...', tag: 'INIT');
    try {
      final prefs = await SharedPreferences.getInstance();
      AppInitState.prefsReady.complete(prefs);
      LoggingService.log(
        'SharedPreferences ready (${stopwatch.elapsedMilliseconds}ms)',
        tag: 'INIT',
      );
    } catch (e, stack) {
      LoggingService.log(
        'SharedPreferences init failed: $e',
        tag: 'INIT_ERROR',
      );
      // Complete with error so app can handle it gracefully
      if (!AppInitState.prefsReady.isCompleted) {
        AppInitState.prefsReady.completeError(e, stack);
      }
      // Re-throw to be caught by outer catch block
      rethrow;
    }

    // Configure FCM background message handler (mobile only)
    if (!kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );
      LoggingService.log('FCM background handler configured', tag: 'INIT');
    }

    // Initialize Sentry for web (non-blocking)
    if (kReleaseMode && kIsWeb && EnvironmentConfig.sentryDsn != null) {
      unawaited(_initSentry());
    }

    // Mark all initialization as complete
    AppInitState.allReady.complete();
    LoggingService.log(
      'All initialization complete (${stopwatch.elapsedMilliseconds}ms)',
      tag: 'INIT',
    );
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
      options.dsn = EnvironmentConfig.sentryDsn;
      options.tracesSampleRate = 0.2;
      options.environment = 'production';

      // Filter non-critical errors before sending to Sentry
      options.beforeSend = (event, hint) {
        final exception = event.throwable;
        final exceptionString = exception?.toString().toLowerCase() ?? '';
        final message = event.message?.formatted.toLowerCase() ?? '';

        // Downgrade geolocation errors to info level
        // These are expected failures when ip-api.com is unreachable or slow
        if (exceptionString.contains('ip-api.com') ||
            exceptionString.contains('geolocation') ||
            message.contains('ip-api.com') ||
            message.contains('geolocation')) {
          return event.copyWith(level: SentryLevel.info);
        }

        // Downgrade WebGL/CanvasKit errors to info level
        // These are expected on some browsers (e.g., Chrome iOS) with automatic fallback
        if (exceptionString.contains('getparameter') ||
            exceptionString.contains('webgl') ||
            exceptionString.contains('canvaskit') ||
            message.contains('getparameter') ||
            message.contains('webgl') ||
            message.contains('canvaskit')) {
          return event.copyWith(level: SentryLevel.info);
        }

        // All other errors pass through unchanged
        return event;
      };
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Precache critical logo asset for splash screen and auth screens (transparent 1024x1024)
    precacheImage(const AssetImage('assets/images/logo-light.png'), context);
  }

  /// Wait for all initialization to complete
  Future<void> _waitForInitialization() async {
    LoggingService.log('Waiting for initialization...', tag: 'APP');

    try {
      // Wait for SharedPreferences (needed for theme/locale)
      // If SharedPreferences fails to initialize, providers will handle it gracefully
      _prefs = await AppInitState.prefsReady.future;
      LoggingService.log('Prefs ready, updating state...', tag: 'APP');
    } catch (e) {
      LoggingService.log(
        'SharedPreferences init error: $e - continuing without persistence',
        tag: 'APP_ERROR',
      );
      // Continue without SharedPreferences - providers will use fallbacks
      _prefs = null;
    }

    // Mark as initialized regardless of SharedPreferences status
    // Providers will handle missing SharedPreferences gracefully
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Phase 1: Before initialization - show Flutter splash (matches HTML splash)
    if (!_isInitialized) {
      return const _InitializingSplash();
    }

    // Phase 2: Initialized - show app with auth-aware splash overlay
    // Override SharedPreferences provider if available (null is acceptable - providers handle it)
    final overrides = _prefs != null
        ? [sharedPreferencesProvider.overrideWithValue(_prefs)]
        : <Override>[];

    return ProviderScope(
      overrides: overrides,
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
    final backgroundColor = isDark
        ? const Color(0xFF000000)
        : const Color(0xFFFAFAFA);

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

  const _InitializedApp({
    required this.showSplash,
    required this.onSplashComplete,
  });

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
        LoggingService.log(
          'Auth check complete, isAuthenticated=${authState.isAuthenticated}',
          tag: 'APP',
        );
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
        final wrappedChild = ErrorBoundary(
          child: GlobalNavigationOverlay(child: child!),
        );
        return Stack(children: [wrappedChild, const OfflineIndicator()]);
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
