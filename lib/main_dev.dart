// Development entry point
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/config/environment.dart';
import 'firebase_options_dev.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main.dart' as app;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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

  // Connect to emulators in development
  // await _connectToEmulators();

  app.runMainApp();
}

// Future<void> _connectToEmulators() async {
//   final host = 'localhost';
//   FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
//   await FirebaseAuth.instance.useAuthEmulator(host, 9099);
//   FirebaseStorage.instance.useStorageEmulator(host, 9199);
//   FirebaseFunctions.instance.useFunctionsEmulator(host, 5001);
// }
