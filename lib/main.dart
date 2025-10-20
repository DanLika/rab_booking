import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/env_config.dart';
import 'core/config/router.dart';
import 'core/providers/language_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/profile/data/profile_service.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment configuration (uses WebConfig for web builds)
  await EnvConfig.load();

  // Validate configuration
  EnvConfig.validate();

  // Initialize Supabase
  await Supabase.initialize(
    url: EnvConfig.supabaseUrl,
    anonKey: EnvConfig.supabaseAnonKey,
  );

  // Initialize Stripe (only on Android/iOS, not on web or desktop)
  if (!kIsWeb) {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        Stripe.publishableKey = EnvConfig.stripePublishableKey;
        Stripe.merchantIdentifier = 'merchant.com.rab.booking';
        await Stripe.instance.applySettings();
      }
    } catch (e) {
      debugPrint('⚠️ Failed to initialize Stripe: $e');
    }
  }

  runApp(
    const ProviderScope(
      child: RabBookingApp(),
    ),
  );
}

/// Main application widget
class RabBookingApp extends ConsumerWidget {
  const RabBookingApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(currentLocaleProvider);

    // Watch user preferences for theme mode
    final preferencesAsync = ref.watch(userPreferencesNotifierProvider);
    final themeMode = preferencesAsync.maybeWhen(
      data: (prefs) {
        switch (prefs.theme) {
          case 'dark':
            return ThemeMode.dark;
          case 'light':
            return ThemeMode.light;
          default:
            return ThemeMode.system;
        }
      },
      orElse: () => ThemeMode.system,
    );

    return MaterialApp.router(
      title: 'Rab Booking',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
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
