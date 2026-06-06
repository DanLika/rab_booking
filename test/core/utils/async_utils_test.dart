import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_async/fake_async.dart';
import 'package:bookbed/core/utils/async_utils.dart';
import 'package:bookbed/core/constants/timeout_constants.dart';

void main() {
  group('FutureTimeoutExtension', () {
    test('withFirestoreTimeout completes successfully if future resolves before timeout', () {
      fakeAsync((async) {
        bool completed = false;

        Future.delayed(const Duration(seconds: 10), () => 'success')
            .withFirestoreTimeout()
            .then((_) => completed = true);

        async.elapse(const Duration(seconds: 10));
        expect(completed, isTrue);
      });
    });

    test('withFirestoreTimeout throws TimeoutException if future does not resolve before timeout', () {
      fakeAsync((async) {
        Object? exception;

        Future.delayed(const Duration(seconds: 40), () => 'fail')
            .withFirestoreTimeout()
            .catchError((e) {
              exception = e;
              return 'error_caught';
            });

        async.elapse(TimeoutConstants.firestoreQuery);

        expect(exception, isA<TimeoutException>());
        expect((exception as TimeoutException).message, contains('Firestore query timed out after 30s'));
      });
    });

    test('withFirestoreTimeout throws TimeoutException with custom operation name', () {
      fakeAsync((async) {
        Object? exception;

        Future.delayed(const Duration(seconds: 40), () => 'fail')
            .withFirestoreTimeout('getUserProfile')
            .catchError((e) {
              exception = e;
              return 'error_caught';
            });

        async.elapse(TimeoutConstants.firestoreQuery);

        expect(exception, isA<TimeoutException>());
        expect((exception as TimeoutException).message, contains('getUserProfile timed out after 30s'));
      });
    });

    test('withHttpTimeout respects http timeout constant', () {
      fakeAsync((async) {
        Object? exception;

        Future.delayed(TimeoutConstants.httpRequest + const Duration(seconds: 1), () => 'fail')
            .withHttpTimeout()
            .catchError((e) {
              exception = e;
              return 'error_caught';
            });

        async.elapse(TimeoutConstants.httpRequest);

        expect(exception, isA<TimeoutException>());
        expect((exception as TimeoutException).message, contains('HTTP request timed out'));
      });
    });

    test('withCloudFunctionTimeout respects cloud function timeout constant', () {
      fakeAsync((async) {
        Object? exception;

        Future.delayed(TimeoutConstants.cloudFunction + const Duration(seconds: 1), () => 'fail')
            .withCloudFunctionTimeout()
            .catchError((e) {
              exception = e;
              return 'error_caught';
            });

        async.elapse(TimeoutConstants.cloudFunction);

        expect(exception, isA<TimeoutException>());
        expect((exception as TimeoutException).message, contains('Cloud Function timed out'));
      });
    });

    test('withBookingFetchTimeout respects booking fetch timeout constant', () {
      fakeAsync((async) {
        Object? exception;

        Future.delayed(TimeoutConstants.bookingFetch + const Duration(seconds: 1), () => 'fail')
            .withBookingFetchTimeout()
            .catchError((e) {
              exception = e;
              return 'error_caught';
            });

        async.elapse(TimeoutConstants.bookingFetch);

        expect(exception, isA<TimeoutException>());
        expect((exception as TimeoutException).message, contains('Booking fetch timed out'));
      });
    });

    test('withListFetchTimeout respects list fetch timeout constant', () {
      fakeAsync((async) {
        Object? exception;

        Future.delayed(TimeoutConstants.listFetch + const Duration(seconds: 1), () => 'fail')
            .withListFetchTimeout()
            .catchError((e) {
              exception = e;
              return 'error_caught';
            });

        async.elapse(TimeoutConstants.listFetch);

        expect(exception, isA<TimeoutException>());
        expect((exception as TimeoutException).message, contains('List fetch timed out'));
      });
    });

    test('withShortTimeout respects short operation timeout constant', () {
      fakeAsync((async) {
        Object? exception;

        Future.delayed(TimeoutConstants.shortOperation + const Duration(seconds: 1), () => 'fail')
            .withShortTimeout()
            .catchError((e) {
              exception = e;
              return 'error_caught';
            });

        async.elapse(TimeoutConstants.shortOperation);

        expect(exception, isA<TimeoutException>());
        expect((exception as TimeoutException).message, contains('Operation timed out'));
      });
    });

    test('withCustomTimeout respects given duration', () {
      fakeAsync((async) {
        Object? exception;
        const customDuration = Duration(seconds: 42);

        Future.delayed(customDuration + const Duration(seconds: 1), () => 'fail')
            .withCustomTimeout(customDuration)
            .catchError((e) {
              exception = e;
              return 'error_caught';
            });

        async.elapse(customDuration);

        expect(exception, isA<TimeoutException>());
        expect((exception as TimeoutException).message, contains('Operation timed out after 42s'));
      });
    });
  });

  group('StreamTimeoutExtension', () {
    test('firstWithTimeout completes if stream emits before timeout', () {
      fakeAsync((async) {
        final controller = StreamController<String>();
        bool completed = false;

        controller.stream.firstWithTimeout().then((_) => completed = true);

        async.elapse(const Duration(seconds: 1));
        controller.add('value');

        // Let event loop process the value
        async.flushMicrotasks();

        expect(completed, isTrue);
        controller.close();
      });
    });

    test('firstWithTimeout throws if stream does not emit before timeout', () {
      fakeAsync((async) {
        final controller = StreamController<String>();
        Object? exception;

        controller.stream.firstWithTimeout().catchError((e) {
          exception = e;
          return 'error_caught';
        });

        async.elapse(TimeoutConstants.realtimeInitial);

        expect(exception, isA<TimeoutException>());
        expect((exception as TimeoutException).message, contains('Stream timed out waiting for first value'));
        controller.close();
      });
    });

    test('firstWithTimeout respects custom duration if provided', () {
      fakeAsync((async) {
        final controller = StreamController<String>();
        Object? exception;
        const customDuration = Duration(seconds: 42);

        controller.stream.firstWithTimeout(customDuration).catchError((e) {
          exception = e;
          return 'error_caught';
        });

        async.elapse(customDuration);

        expect(exception, isA<TimeoutException>());
        expect((exception as TimeoutException).message, contains('Stream timed out waiting for first value after 42s'));
        controller.close();
      });
    });
  });
}
