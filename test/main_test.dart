import 'package:flutter_test/flutter_test.dart';
import 'package:bookbed/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('AppInitState', () {
    setUp(() {
      AppInitState.reset();
    });

    tearDown(() {
      AppInitState.reset();
    });

    test('initial state has all ready flags set to false', () {
      expect(AppInitState.isFirebaseReady, isFalse);
      expect(AppInitState.isPrefsReady, isFalse);
      expect(AppInitState.isAllReady, isFalse);
    });

    test('firebaseReady completes successfully', () async {
      AppInitState.firebaseReady.complete();

      expect(AppInitState.isFirebaseReady, isTrue);

      // Wait for future to ensure it resolves without error
      await expectLater(AppInitState.firebaseReady.future, completes);
    });

    test('prefsReady completes successfully', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      AppInitState.prefsReady.complete(prefs);

      expect(AppInitState.isPrefsReady, isTrue);

      // Wait for future to ensure it resolves without error
      await expectLater(
        AppInitState.prefsReady.future,
        completion(equals(prefs)),
      );
    });

    test('allReady completes successfully', () async {
      AppInitState.allReady.complete();

      expect(AppInitState.isAllReady, isTrue);

      // Wait for future to ensure it resolves without error
      await expectLater(AppInitState.allReady.future, completes);
    });

    test('firebaseReady completes with error', () async {
      final error = Exception('Firebase init failed');
      AppInitState.firebaseReady.completeError(error);

      expect(AppInitState.isFirebaseReady, isTrue);

      // Wait for future to ensure it resolves with error
      await expectLater(
        AppInitState.firebaseReady.future,
        throwsA(equals(error)),
      );
    });

    test('prefsReady completes with error', () async {
      final error = Exception('Prefs init failed');
      AppInitState.prefsReady.completeError(error);

      expect(AppInitState.isPrefsReady, isTrue);

      // Wait for future to ensure it resolves with error
      await expectLater(AppInitState.prefsReady.future, throwsA(equals(error)));
    });

    test('allReady completes with error', () async {
      final error = Exception('All init failed');
      AppInitState.allReady.completeError(error);

      expect(AppInitState.isAllReady, isTrue);

      // Wait for future to ensure it resolves with error
      await expectLater(AppInitState.allReady.future, throwsA(equals(error)));
    });
  });
}
