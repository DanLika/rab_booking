import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'core/config/environment.dart';
import 'core/error_handling/error_filter.dart';
import 'core/init/app_check_init.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/sentry_env.dart';
import 'features/admin/providers/admin_providers.dart';
// Using production Firebase project
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';

/// Admin Dashboard Entrypoint
///
/// Separate main() for admin-only web build.
/// Build with: flutter build web --target lib/admin_main.dart -o build/web_admin
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await AppCheckInit.activate(isProd: true);

  // Sentry error tracking (release builds only). Admin was the only PROD
  // surface without it — owner (main.dart) and widget (widget_main.dart)
  // already report; same DSN, distinguished by the app_type tag.
  final sentryDsn = EnvironmentConfig.sentryDsn;
  if (kReleaseMode && sentryDsn != null && sentryDsn.isNotEmpty) {
    await SentryFlutter.init((options) {
      options.dsn = sentryDsn;
      options.tracesSampleRate = 0.2;
      options.environment = detectSentryEnvironment();
      options.beforeSend = (event, hint) {
        // Same noise gate as owner/widget entries: drop infrastructure /
        // test-harness exceptions that no user ever sees.
        if (!isUserFacingException(throwable: event.throwable)) {
          return null;
        }
        return event.copyWith(
          tags: {...?event.tags, 'app_type': 'admin_dashboard'},
        );
      };
    }, appRunner: () => runApp(const ProviderScope(child: AdminApp())));
  } else {
    runApp(const ProviderScope(child: AdminApp()));
  }
}

/// Admin Application
class AdminApp extends ConsumerWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(adminRouterProvider);

    return MaterialApp.router(
      title: 'BookBed Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: router,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('hr')],
    );
  }
}
