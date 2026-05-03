import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bookbed/core/error_handling/error_boundary.dart';

void main() {
  group('GlobalErrorHandler', () {
    late List<String> debugPrintLogs;
    late DebugPrintCallback originalDebugPrint;

    setUp(() {
      debugPrintLogs = [];
      originalDebugPrint = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) {
          debugPrintLogs.add(message);
        }
      };
    });

    tearDown(() {
      debugPrint = originalDebugPrint;
    });

    group('FlutterError.onError', () {
      test('logs error and stack trace for Exception', () {
        final originalOnError = FlutterError.onError;
        addTearDown(() => FlutterError.onError = originalOnError);

        GlobalErrorHandler.initialize();

        expect(FlutterError.onError, isNotNull);

        final exception = Exception('Test FlutterError');
        final stack = StackTrace.fromString('test stack trace');
        final details = FlutterErrorDetails(exception: exception, stack: stack);

        FlutterError.onError!(details);

        expect(
          debugPrintLogs.any((log) => log.contains('GlobalErrorHandler caught error: Exception: Test FlutterError')),
          isTrue,
        );
        expect(
          debugPrintLogs.any((log) => log.contains('Stack trace:\ntest stack trace')),
          isTrue,
        );
      });

      test('handles null stack trace gracefully', () {
        final originalOnError = FlutterError.onError;
        addTearDown(() => FlutterError.onError = originalOnError);

        GlobalErrorHandler.initialize();

        final exception = Exception('Test null stack');
        final details = FlutterErrorDetails(exception: exception, stack: null);

        FlutterError.onError!(details);

        expect(
          debugPrintLogs.any((log) => log.contains('GlobalErrorHandler caught error: Exception: Test null stack')),
          isTrue,
        );
        // The stack trace block should not be logged if it is null
        expect(
          debugPrintLogs.any((log) => log.startsWith('Stack trace:')),
          isFalse,
        );
      });

      test('handles non-Exception error objects (like strings)', () {
        final originalOnError = FlutterError.onError;
        addTearDown(() => FlutterError.onError = originalOnError);

        GlobalErrorHandler.initialize();

        final error = 'Just a string error';
        final details = FlutterErrorDetails(exception: error, stack: null);

        FlutterError.onError!(details);

        expect(
          debugPrintLogs.any((log) => log.contains('GlobalErrorHandler caught error: Just a string error')),
          isTrue,
        );
      });
    });

    group('PlatformDispatcher.instance.onError', () {
      test('logs async error and stack trace', () {
        final originalOnError = PlatformDispatcher.instance.onError;
        addTearDown(() => PlatformDispatcher.instance.onError = originalOnError);

        GlobalErrorHandler.initialize();

        expect(PlatformDispatcher.instance.onError, isNotNull);

        final exception = Exception('Test AsyncError');
        final stack = StackTrace.fromString('test async stack');

        final handled = PlatformDispatcher.instance.onError!(exception, stack);

        expect(handled, isTrue); // Should return true to indicate it was handled
        expect(
          debugPrintLogs.any((log) => log.contains('GlobalErrorHandler caught error: Exception: Test AsyncError')),
          isTrue,
        );
        expect(
          debugPrintLogs.any((log) => log.contains('Stack trace:\ntest async stack')),
          isTrue,
        );
      });

      test('handles async error with non-Exception objects', () {
        final originalOnError = PlatformDispatcher.instance.onError;
        addTearDown(() => PlatformDispatcher.instance.onError = originalOnError);

        GlobalErrorHandler.initialize();

        final error = {'code': 500, 'message': 'JSON error'};
        final stack = StackTrace.fromString('json stack');

        final handled = PlatformDispatcher.instance.onError!(error, stack);

        expect(handled, isTrue);
        expect(
          debugPrintLogs.any((log) => log.contains('GlobalErrorHandler caught error: {code: 500, message: JSON error}')),
          isTrue,
        );
        expect(
          debugPrintLogs.any((log) => log.contains('Stack trace:\njson stack')),
          isTrue,
        );
      });
    });
  });
}
