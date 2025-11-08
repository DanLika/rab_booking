import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/router.dart';
import 'features/widget/presentation/theme/villa_jasko_theme.dart';
import 'firebase_options.dart';

/// Widget-only entry point for embeddable booking widget
///
/// This is a separate entry point from main.dart (Owner App) that:
/// - Uses a minimal router (only widget routes)
/// - Has NO authentication required
/// - Is designed to be embedded in iframes
/// - Accepts unit ID via URL query parameter: ?unit=UNIT_ID
///
/// Build command:
/// flutter build web --target lib/widget_main.dart --output build/web_widget --release
///
/// Deploy:
/// firebase deploy --only hosting:widget
///
/// Embed code:
/// <iframe src="https://rab-booking-widget.web.app/?unit=UNIT_ID"
///         width="100%" height="900px" frameborder="0"></iframe>
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    const ProviderScope(
      child: BookingWidgetApp(),
    ),
  );
}

/// Booking Widget App - Minimalna aplikacija samo za widget
class BookingWidgetApp extends ConsumerWidget {
  const BookingWidgetApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use minimal widget router (NO auth, NO owner dashboard routes)
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Villa Jasko Booking',
      debugShowCheckedModeBanner: false,

      // Use Villa Jasko custom theme (Azure blue + Mediterranean colors)
      theme: VillaJaskoTheme.theme,
      themeMode: ThemeMode.light,

      routerConfig: router,

      // Multi-language support via URL parameter (?language=hr/en/de/it)
      // Translations handled in components via WidgetTranslations
    );
  }
}
