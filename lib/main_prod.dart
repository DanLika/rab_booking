// Production entry point
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/config/environment.dart';
import 'firebase_options.dart';
import 'main.dart' as app;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set environment
  EnvironmentConfig.setEnvironment(Environment.production);

  // Initialize Firebase with production options
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  app.runMainApp();
}
