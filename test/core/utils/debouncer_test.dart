import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:bookbed/core/utils/debouncer.dart';

void main() {
  group('Debouncer', () {
    test('executes action after the delay', () async {
      int counter = 0;
      final debouncer = Debouncer(delay: const Duration(milliseconds: 50));

      debouncer.run(() {
        counter++;
      });

      expect(counter, 0);

      await Future.delayed(const Duration(milliseconds: 70));

      expect(counter, 1);
    });

    test(
      'cancels previous action if called multiple times within delay',
      () async {
        int counter = 0;
        final debouncer = Debouncer(delay: const Duration(milliseconds: 50));

        debouncer.run(() {
          counter++;
        });

        await Future.delayed(const Duration(milliseconds: 20));

        debouncer.run(() {
          counter++;
        });

        await Future.delayed(const Duration(milliseconds: 20));

        debouncer.run(() {
          counter++;
        });

        expect(counter, 0);

        await Future.delayed(const Duration(milliseconds: 70));

        expect(counter, 1);
      },
    );

    test('cancel() prevents action from executing', () async {
      int counter = 0;
      final debouncer = Debouncer(delay: const Duration(milliseconds: 50));

      debouncer.run(() {
        counter++;
      });

      debouncer.cancel();

      await Future.delayed(const Duration(milliseconds: 70));

      expect(counter, 0);
    });

    test('dispose() prevents action from executing', () async {
      int counter = 0;
      final debouncer = Debouncer(delay: const Duration(milliseconds: 50));

      debouncer.run(() {
        counter++;
      });

      debouncer.dispose();

      await Future.delayed(const Duration(milliseconds: 70));

      expect(counter, 0);
    });
  });

  group('Throttler', () {
    test('executes action immediately on first call', () {
      int counter = 0;
      final throttler = Throttler(duration: const Duration(milliseconds: 50));

      throttler.run(() {
        counter++;
      });

      expect(counter, 1);
    });

    test('ignores subsequent calls within duration', () {
      int counter = 0;
      final throttler = Throttler(duration: const Duration(milliseconds: 50));

      throttler.run(() {
        counter++;
      });

      throttler.run(() {
        counter++;
      });

      throttler.run(() {
        counter++;
      });

      expect(counter, 1);
    });

    test('executes again after duration has passed', () async {
      int counter = 0;
      final throttler = Throttler(duration: const Duration(milliseconds: 50));

      throttler.run(() {
        counter++;
      });

      expect(counter, 1);

      await Future.delayed(const Duration(milliseconds: 70));

      throttler.run(() {
        counter++;
      });

      expect(counter, 2);
    });

    test('cancel() resets readiness and allows immediate execution', () {
      int counter = 0;
      final throttler = Throttler(duration: const Duration(milliseconds: 50));

      throttler.run(() {
        counter++;
      });

      expect(counter, 1);

      throttler.cancel();

      throttler.run(() {
        counter++;
      });

      expect(counter, 2);
    });

    test(
      'dispose() prevents timer from resetting readiness but allows pending sync code',
      () async {
        int counter = 0;
        final throttler = Throttler(duration: const Duration(milliseconds: 50));

        throttler.run(() {
          counter++;
        });

        expect(counter, 1);

        throttler.dispose();

        // Because dispose only cancels the timer, _isReady remains false
        // until manually reset or new instance created. Wait for duration
        // to ensure the timer didn't fire and reset it.
        await Future.delayed(const Duration(milliseconds: 70));

        throttler.run(() {
          counter++;
        });

        expect(counter, 1);
      },
    );
  });
}
