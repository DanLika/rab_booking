import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bookbed/core/error_handling/error_boundary.dart';

/// Audit/20 — ErrorBoundary catch narrowing.
///
/// Covers the filter applied at:
///   * `_ErrorBoundaryState._setupErrorListener` → `isUserFacingFlutterError`
///   * `GlobalErrorHandler.initialize` → `isUserFacingAsyncError`
void main() {
  group('isUserFacingFlutterError', () {
    test('rejects framework `silent` errors', () {
      final details = FlutterErrorDetails(
        exception: Exception('background tracing error'),
        stack: StackTrace.current,
        silent: true,
      );
      expect(isUserFacingFlutterError(details), isFalse);
    });

    test('rejects Marionette matcher-not-found exception by message', () {
      final details = FlutterErrorDetails(
        exception: Exception(
          'Element matching {text: Natrag na prijavu} not found',
        ),
        stack: StackTrace.fromString(
          '#0 _someUserSpaceFrame (package:bookbed/main.dart:1)\n',
        ),
      );
      expect(isUserFacingFlutterError(details), isFalse);
    });

    test(
      'rejects errors originating from dart:developer service-extension dispatch',
      () {
        final details = FlutterErrorDetails(
          exception: StateError('extension dispatch failed'),
          stack: StackTrace.fromString(
            '#0 _Service.handleRequest (dart:developer/extension.dart:42)\n'
            '#1 marionette_extension.dispatch (package:marionette/marionette.dart:99)\n',
          ),
        );
        expect(isUserFacingFlutterError(details), isFalse);
      },
    );

    test('rejects "VM service extension" message phrasings', () {
      final details = FlutterErrorDetails(
        exception: Exception('VM service extension threw an unhandled error'),
      );
      expect(isUserFacingFlutterError(details), isFalse);
    });

    test('accepts ordinary widget build errors (default user-facing path)', () {
      final details = FlutterErrorDetails(
        exception: StateError('Cannot read null property'),
        stack: StackTrace.fromString(
          '#0 SomeWidget.build (package:bookbed/features/dashboard/dashboard.dart:42:7)\n',
        ),
      );
      expect(isUserFacingFlutterError(details), isTrue);
    });

    test('accepts null stack as user-facing (no infrastructure signal)', () {
      final details = FlutterErrorDetails(
        exception: Exception('User-triggered failure'),
      );
      expect(isUserFacingFlutterError(details), isTrue);
    });
  });

  group('isUserFacingAsyncError (PlatformDispatcher path)', () {
    test('rejects Element-matching exception payload', () {
      final stack = StackTrace.fromString(
        '#0 _someFrame (package:bookbed/main.dart:1)\n',
      );
      expect(
        isUserFacingAsyncError(
          Exception('Element matching {text: Integracije} not found'),
          stack,
        ),
        isFalse,
      );
    });

    test('rejects dart:vm_service frames', () {
      final stack = StackTrace.fromString(
        '#0 _Service.handleRequest (dart:vm_service/extension.dart:42)\n',
      );
      expect(isUserFacingAsyncError(StateError('async fail'), stack), isFalse);
    });

    test('accepts ordinary async failures', () {
      final stack = StackTrace.fromString(
        '#0 SomeRepo.fetch (package:bookbed/features/x/repo.dart:42)\n',
      );
      expect(
        isUserFacingAsyncError(Exception('Network unreachable'), stack),
        isTrue,
      );
    });

    test('accepts null stack', () {
      expect(isUserFacingAsyncError(StateError('boom'), null), isTrue);
    });
  });
}
