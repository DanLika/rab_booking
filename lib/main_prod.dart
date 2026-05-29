// Production entry point
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/config/environment.dart';
import 'firebase_options.dart';
import 'core/init/app_check_init.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main.dart' as app;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  // Set environment
  EnvironmentConfig.setEnvironment(Environment.production);

  // Initialize Firebase with production options
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    if (!e.toString().contains('duplicate-app')) {
      rethrow;
    }
  }

  // Safety: crash early in debug if Firebase is wired to the wrong project.
  if (kDebugMode) {
    const expectedProjectId = 'rab-booking-248fc';
    final actualProjectId = Firebase.app().options.projectId;
    assert(
      actualProjectId == expectedProjectId,
      'PROD entry point connected to wrong Firebase project: '
      '$actualProjectId (expected $expectedProjectId).',
    );
  }

  await AppCheckInit.activate(isProd: true);

  app.runMainApp();
}
