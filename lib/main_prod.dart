// Production entry point
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/config/environment.dart';
import 'firebase_options.dart';
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

  app.runMainApp();
}
