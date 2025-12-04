import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/router_widget.dart';
import 'core/providers/language_provider.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';

/// Widget Entry Point
/// This is the main entry point for the embeddable booking widget.
/// Uses widgetRouterProvider which only includes public routes:
/// - / (calendar/booking widget)
/// - /view (booking lookup from email links)
/// - /view/details (booking details display)
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    const ProviderScope(
      child: RabBookingWidgetApp(),
    ),
  );
}

/// Widget Application
/// Minimal app for the embeddable booking widget.
/// NO authentication, NO owner dashboard routes.
class RabBookingWidgetApp extends ConsumerWidget {
  const RabBookingWidgetApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(widgetRouterProvider);
    final locale = ref.watch(currentLocaleProvider);

    return MaterialApp.router(
      title: 'Rab Booking',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      // Widget always uses light theme for consistency on external sites
      themeMode: ThemeMode.light,
      routerConfig: router,
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
