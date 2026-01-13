import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'core/config/environment.dart';
import 'firebase_options_dev.dart';
import 'main.dart' show runMainApp;

/// Owner Dashboard Entrypoint for DEVELOPMENT environment
///
/// Uses [DevFirebaseOptions] to connect to bookbed-dev project.
/// Build: flutter run -d chrome --web-port=8080 --target lib/owner_main_dev.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set environment
  EnvironmentConfig.setEnvironment(Environment.development);

  // Initialize Firebase with DEV config (bookbed-dev)
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: DevFirebaseOptions.currentPlatform);
    }
  } catch (e) {
    if (!e.toString().contains('duplicate-app')) {
      rethrow;
    }
  }

  // Run the main app (Firebase already initialized)
  runMainApp();
}
