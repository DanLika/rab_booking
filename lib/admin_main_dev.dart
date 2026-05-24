import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/environment.dart';
import 'core/theme/app_theme.dart';
import 'features/admin/providers/admin_providers.dart';
import 'firebase_options_dev.dart';
import 'l10n/app_localizations.dart';

/// Admin Dashboard Entrypoint for DEVELOPMENT environment
///
/// Uses [DevFirebaseOptions] to connect to bookbed-dev project.
/// Build: flutter build web --release --target lib/admin_main_dev.dart -o build/web_admin
/// Run: flutter run -d chrome --web-port=8080 --target lib/admin_main_dev.dart
///
/// Mirrors `lib/owner_main_dev.dart` safety pattern (audit/33 F-OwnerDashboard-001):
/// EnvironmentConfig.setEnvironment + kDebugMode project-ID assert prevent the
/// same PROD-options-bundled-into-dev-hosting contamination class on the admin
/// surface (bookbed-admin-dev.web.app).
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  EnvironmentConfig.setEnvironment(Environment.development);

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: DevFirebaseOptions.currentPlatform);
    }
  } catch (e) {
    if (!e.toString().contains('duplicate-app')) {
      rethrow;
    }
  }

  if (kDebugMode) {
    const expectedProjectId = 'bookbed-dev';
    final actualProjectId = Firebase.app().options.projectId;
    assert(
      actualProjectId == expectedProjectId,
      'DEV admin entry point connected to wrong Firebase project: '
      '$actualProjectId (expected $expectedProjectId). '
      'Check --target flag (must be lib/admin_main_dev.dart for dev).',
    );
  }

  runApp(const ProviderScope(child: AdminApp()));
}

class AdminApp extends ConsumerWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(adminRouterProvider);

    return MaterialApp.router(
      title: 'BookBed Admin (Dev)',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: router,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('hr'),
    );
  }
}
