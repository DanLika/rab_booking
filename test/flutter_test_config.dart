import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'mocks/mocks.dart';

/// Global test configuration
/// This file runs before all tests
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // Register fallback values for mocktail
    registerFallbackValues();
  });

  tearDownAll(() {
    // Cleanup after all tests
  });

  await testMain();
}
