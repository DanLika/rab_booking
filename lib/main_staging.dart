// Staging entry point
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/config/environment.dart';
import 'firebase_options_staging.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main.dart' as app;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  // Set environment
  EnvironmentConfig.setEnvironment(Environment.staging);

  // Initialize Firebase with staging options
  await Firebase.initializeApp(options: StagingFirebaseOptions.currentPlatform);

  app.runMainApp();
}
