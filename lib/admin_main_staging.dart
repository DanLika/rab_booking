import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/admin/providers/admin_providers.dart';
import 'firebase_options_staging.dart';
import 'l10n/app_localizations.dart';

/// Admin Dashboard Entrypoint for STAGING environment
/// Build: flutter build web --target lib/admin_main_staging.dart -o build/web_admin
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with STAGING config
  await Firebase.initializeApp(options: StagingFirebaseOptions.currentPlatform);

  runApp(const ProviderScope(child: AdminApp()));
}

/// Admin App Root Widget
class AdminApp extends ConsumerWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(adminRouterProvider);

    return MaterialApp.router(
      title: 'BookBed Admin (Staging)',
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
