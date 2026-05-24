import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'core/config/environment.dart';
import 'firebase_options_dev.dart';
import 'main.dart' show runMainApp;

/// Owner Dashboard Entrypoint for DEVELOPMENT environment
///
/// Uses [DevFirebaseOptions] to connect to bookbed-dev project.
/// Build: flutter build web --release --target lib/owner_main_dev.dart -o build/web_owner
/// Run: flutter run -d chrome --web-port=8080 --target lib/owner_main_dev.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  EnvironmentConfig.setEnvironment(Environment.development);

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: DevFirebaseOptions.currentPlatform);
    }
  } catch (e) {
    if (!e.toString().contains('duplicate-app')) {
      rethrow;
    }
  }

  if (kDebugMode) {
    const expectedProjectId = 'bookbed-dev';
    final actualProjectId = Firebase.app().options.projectId;
    assert(
      actualProjectId == expectedProjectId,
      'DEV owner entry point connected to wrong Firebase project: '
      '$actualProjectId (expected $expectedProjectId). '
      'Check ios/Runner/GoogleService-Info.plist and --target flag.',
    );
  }

  runMainApp();
}
