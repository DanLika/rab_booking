// Development entry point
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
// Marionette is a dev_dependency: imported here for kDebugMode-only init,
// tree-shaken out of release builds. Lint expects production deps for imports.
// ignore: depend_on_referenced_packages
import 'package:marionette_flutter/marionette_flutter.dart';
import 'core/config/environment.dart';
import 'firebase_options_dev.dart';
import 'core/init/app_check_init.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main.dart' as app;

void main() async {
  if (kDebugMode) {
    MarionetteBinding.ensureInitialized();
  } else {
    WidgetsFlutterBinding.ensureInitialized();
  }
  GoogleFonts.config.allowRuntimeFetching = false;

  // Set environment
  EnvironmentConfig.setEnvironment(Environment.development);

  // Initialize Firebase with dev options
  // Initialize Firebase with dev options
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: DevFirebaseOptions.currentPlatform);
    }
  } catch (e) {
    // Ignore duplicate app error which can happen during hot restart
    if (!e.toString().contains('duplicate-app')) {
      rethrow;
    }
  }

  // Safety: crash early in debug if Firebase is wired to the wrong project.
  // Prevents the iOS "swapped plist + wrong --target" silent contamination
  // class documented in audit/15.
  if (kDebugMode) {
    const expectedProjectId = 'bookbed-dev';
    final actualProjectId = Firebase.app().options.projectId;
    assert(
      actualProjectId == expectedProjectId,
      'DEV entry point connected to wrong Firebase project: '
      '$actualProjectId (expected $expectedProjectId). '
      'Check ios/Runner/GoogleService-Info.plist and --target flag.',
    );
  }

  await AppCheckInit.activate(isProd: false);

  app.runMainApp();
}
