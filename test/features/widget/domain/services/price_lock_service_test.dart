// ignore_for_file: avoid_redundant_argument_values
// Note: Explicit default values kept in tests for documentation clarity
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bookbed/features/widget/domain/constants/widget_constants.dart';
import 'package:bookbed/features/widget/domain/services/price_lock_service.dart';
import 'package:bookbed/features/widget/presentation/providers/booking_price_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PriceLockResult enum', () {
    test('has correct values', () {
      expect(PriceLockResult.values.length, equals(3));
      expect(PriceLockResult.noChange, isA<PriceLockResult>());
      expect(PriceLockResult.confirmedProceed, isA<PriceLockResult>());
      expect(PriceLockResult.cancelled, isA<PriceLockResult>());
    });

    test('noChange is first value', () {
      expect(PriceLockResult.values[0], equals(PriceLockResult.noChange));
    });

    test('confirmedProceed is second value', () {
      expect(
        PriceLockResult.values[1],
        equals(PriceLockResult.confirmedProceed),
      );
    });

    test('cancelled is third value', () {
      expect(PriceLockResult.values[2], equals(PriceLockResult.cancelled));
    });
  });

  group('PriceChangeDialogConfig', () {
    test('has correct default values', () {
      const config = PriceChangeDialogConfig();

      expect(config.increaseTitleText, '⚠️ Price Increased');
      expect(config.decreaseTitleText, 'ℹ️ Price Decreased');
      expect(config.cancelButtonText, 'Cancel');
      expect(config.proceedButtonText, 'Proceed');
      expect(config.increaseColor, Colors.orange);
      expect(config.decreaseColor, Colors.blue);
      expect(config.currencySymbol, '€');
    });

    test('defaultConfig is a const PriceChangeDialogConfig', () {
      expect(
        PriceChangeDialogConfig.defaultConfig,
        isA<PriceChangeDialogConfig>(),
      );
    });

    test('croatianConfig has Croatian text', () {
      const config = PriceChangeDialogConfig.croatianConfig;

      expect(config.increaseTitleText, '⚠️ Cijena Povećana');
      expect(config.decreaseTitleText, 'ℹ️ Cijena Snižena');
      expect(config.cancelButtonText, 'Odustani');
      expect(config.proceedButtonText, 'Nastavi');
    });

    test('can be created with custom values', () {
      const config = PriceChangeDialogConfig(
        increaseTitleText: 'Custom Increase',
        decreaseTitleText: 'Custom Decrease',
        cancelButtonText: 'Back',
        proceedButtonText: 'Continue',
        increaseColor: Colors.red,
        decreaseColor: Colors.green,
        currencySymbol: r'$',
      );

      expect(config.increaseTitleText, 'Custom Increase');
      expect(config.decreaseTitleText, 'Custom Decrease');
      expect(config.cancelButtonText, 'Back');
      expect(config.proceedButtonText, 'Continue');
      expect(config.increaseColor, Colors.red);
      expect(config.decreaseColor, Colors.green);
      expect(config.currencySymbol, r'$');
    });
  });

  group('PriceChangeDialogBuilder', () {
    testWidgets('buildDialogWidget creates correct widget for price increase', (
      tester,
    ) async {
      bool cancelCalled = false;
      bool proceedCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PriceChangeDialogBuilder.buildDialogWidget(
              priceIncreased: true,
              changeAmount: 10.50,
              originalPrice: 100.0,
              currentPrice: 110.50,
              onCancel: () => cancelCalled = true,
              onProceed: () => proceedCalled = true,
            ),
          ),
        ),
      );

      expect(find.text('⚠️ Price Increased'), findsOneWidget);
      expect(find.textContaining('€10.50'), findsOneWidget);
      expect(find.textContaining('Original: €100.00'), findsOneWidget);
      expect(find.textContaining('Current: €110.50'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Proceed'), findsOneWidget);

      // Test cancel button
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(cancelCalled, isTrue);

      // Test proceed button
      await tester.tap(find.text('Proceed'));
      await tester.pumpAndSettle();
      expect(proceedCalled, isTrue);
    });

    testWidgets('buildDialogWidget creates correct widget for price decrease', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PriceChangeDialogBuilder.buildDialogWidget(
              priceIncreased: false,
              changeAmount: 15.0,
              originalPrice: 100.0,
              currentPrice: 85.0,
              onCancel: () {},
              onProceed: () {},
            ),
          ),
        ),
      );

      expect(find.text('ℹ️ Price Decreased'), findsOneWidget);
      expect(find.textContaining('Good news!'), findsOneWidget);
      expect(find.textContaining('€15.00'), findsOneWidget);
    });

    testWidgets('buildDialogWidget respects custom config', (tester) async {
      const config = PriceChangeDialogConfig(
        increaseTitleText: 'Custom Title',
        cancelButtonText: 'Back',
        proceedButtonText: 'Go',
        currencySymbol: r'$',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PriceChangeDialogBuilder.buildDialogWidget(
              priceIncreased: true,
              changeAmount: 5.0,
              originalPrice: 50.0,
              currentPrice: 55.0,
              onCancel: () {},
              onProceed: () {},
              config: config,
            ),
          ),
        ),
      );

      expect(find.text('Custom Title'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);
      expect(find.text('Go'), findsOneWidget);
      expect(find.textContaining(r'$5.00'), findsOneWidget);
    });

    testWidgets('buildDialogWidget callbacks work', (tester) async {
      bool cancelCalled = false;
      bool proceedCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PriceChangeDialogBuilder.buildDialogWidget(
              priceIncreased: true,
              changeAmount: 10.0,
              originalPrice: 100.0,
              currentPrice: 110.0,
              onCancel: () => cancelCalled = true,
              onProceed: () => proceedCalled = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Cancel'));
      expect(cancelCalled, isTrue);

      await tester.tap(find.text('Proceed'));
      expect(proceedCalled, isTrue);
    });
  });

  group('PriceLockService', () {
    test('defaultTolerance uses WidgetConstants.priceTolerance', () {
      expect(
        PriceLockService.defaultTolerance,
        equals(WidgetConstants.priceTolerance),
      );
      expect(PriceLockService.defaultTolerance, equals(0.01));
    });

    group('pricesEqual', () {
      test('returns true for exactly equal prices', () {
        expect(PriceLockService.pricesEqual(100.0, 100.0), isTrue);
      });

      test('returns true for prices within default tolerance', () {
        expect(PriceLockService.pricesEqual(100.0, 100.005), isTrue);
        expect(PriceLockService.pricesEqual(100.0, 100.009), isTrue);
        expect(PriceLockService.pricesEqual(100.0, 99.995), isTrue);
      });

      test('returns false for prices outside default tolerance', () {
        expect(PriceLockService.pricesEqual(100.0, 100.02), isFalse);
        expect(PriceLockService.pricesEqual(100.0, 99.98), isFalse);
      });

      test('respects custom tolerance', () {
        expect(
          PriceLockService.pricesEqual(100.0, 100.5, tolerance: 1.0),
          isTrue,
        );
        expect(
          PriceLockService.pricesEqual(100.0, 101.5, tolerance: 1.0),
          isFalse,
        );
      });
    });

    group('calculatePriceDelta', () {
      BookingPriceCalculation createCalc(double roomPrice) {
        return BookingPriceCalculation(
          roomPrice: roomPrice,
          additionalServicesTotal: 0,
          depositAmount: roomPrice * 0.2,
          remainingAmount: roomPrice * 0.8,
          nights: 2,
        );
      }

      test('returns positive delta when price increased', () {
        final current = createCalc(120.0);
        final locked = createCalc(100.0);

        expect(PriceLockService.calculatePriceDelta(current, locked), 20.0);
      });

      test('returns negative delta when price decreased', () {
        final current = createCalc(80.0);
        final locked = createCalc(100.0);

        expect(PriceLockService.calculatePriceDelta(current, locked), -20.0);
      });

      test('returns zero for equal prices', () {
        final current = createCalc(100.0);
        final locked = createCalc(100.0);

        expect(PriceLockService.calculatePriceDelta(current, locked), 0.0);
      });
    });
  });

  group('BookingPriceCalculation (used by PriceLockService)', () {
    BookingPriceCalculation createCalculation({
      double roomPrice = 100.0,
      double additionalServicesTotal = 0.0,
      double depositAmount = 20.0,
      double remainingAmount = 80.0,
      int nights = 2,
      double? lockedTotalPrice,
    }) {
      return BookingPriceCalculation(
        roomPrice: roomPrice,
        additionalServicesTotal: additionalServicesTotal,
        depositAmount: depositAmount,
        remainingAmount: remainingAmount,
        nights: nights,
        lockedTotalPrice: lockedTotalPrice,
      );
    }

    test('totalPrice equals roomPrice + additionalServicesTotal', () {
      final calc = createCalculation(additionalServicesTotal: 25.0);
      expect(calc.totalPrice, equals(125.0));
    });

    test('hasPriceChanged returns false when lockedTotalPrice is null', () {
      final calc = createCalculation();
      expect(calc.hasPriceChanged, isFalse);
    });

    test('hasPriceChanged returns false when within tolerance', () {
      final calc = createCalculation(
        lockedTotalPrice: 100.005, // Within 1 cent tolerance
      );
      expect(calc.hasPriceChanged, isFalse);
    });

    test('hasPriceChanged returns true when outside tolerance', () {
      final calc = createCalculation(
        lockedTotalPrice: 98.0, // 2 EUR difference
      );
      expect(calc.hasPriceChanged, isTrue);
    });

    test('priceChangeDelta returns 0 when lockedTotalPrice is null', () {
      final calc = createCalculation();
      expect(calc.priceChangeDelta, equals(0.0));
    });

    test('priceChangeDelta returns positive delta when price increased', () {
      final calc = createCalculation(roomPrice: 110.0, lockedTotalPrice: 100.0);
      expect(calc.priceChangeDelta, equals(10.0));
    });

    test('priceChangeDelta returns negative delta when price decreased', () {
      final calc = createCalculation(roomPrice: 90.0, lockedTotalPrice: 100.0);
      expect(calc.priceChangeDelta, equals(-10.0));
    });

    test('copyWithLock sets priceLockTimestamp and lockedTotalPrice', () {
      final original = createCalculation(roomPrice: 150.0);
      final locked = original.copyWithLock();

      expect(locked.lockedTotalPrice, equals(150.0));
      expect(locked.priceLockTimestamp, isNotNull);
      expect(locked.roomPrice, equals(original.roomPrice));
      expect(locked.nights, equals(original.nights));
    });

    test('copyWithServices updates services and recalculates deposit', () {
      final original = createCalculation();
      final withServices = original.copyWithServices(50.0, 20);

      expect(withServices.additionalServicesTotal, equals(50.0));
      expect(withServices.totalPrice, equals(150.0));
      // 20% of 150 = 30
      expect(withServices.depositAmount, equals(30.0));
      // 80% of 150 = 120
      expect(withServices.remainingAmount, equals(120.0));
    });

    test('copyWithServices with 100% deposit', () {
      final original = createCalculation();
      final withServices = original.copyWithServices(0.0, 100);

      expect(withServices.depositAmount, equals(100.0));
      expect(withServices.remainingAmount, equals(0.0));
    });

    test('copyWithServices with 0% deposit', () {
      final original = createCalculation();
      final withServices = original.copyWithServices(0.0, 0);

      expect(withServices.depositAmount, equals(100.0));
      expect(withServices.remainingAmount, equals(0.0));
    });

    test('formatted getters return correct strings', () {
      final calc = createCalculation(
        roomPrice: 123.45,
        additionalServicesTotal: 20.50,
        depositAmount: 28.79,
        remainingAmount: 115.16,
      );

      expect(calc.formatRoomPrice('€'), equals('€123.45'));
      expect(calc.formatAdditionalServices('€'), equals('€20.50'));
      expect(calc.formatTotal('€'), equals('€143.95'));
      expect(calc.formatDeposit('€'), equals('€28.79'));
      expect(calc.formatRemaining('€'), equals('€115.16'));
    });
  });

  group('PriceLockService.checkAndConfirmPriceChange', () {
    BookingPriceCalculation createCalculation({
      double roomPrice = 100.0,
      double additionalServicesTotal = 0.0,
    }) {
      return BookingPriceCalculation(
        roomPrice: roomPrice,
        additionalServicesTotal: additionalServicesTotal,
        depositAmount: roomPrice * 0.2,
        remainingAmount: roomPrice * 0.8,
        nights: 2,
      );
    }

    testWidgets('returns noChange when lockedCalculation is null', (
      tester,
    ) async {
      PriceLockResult? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    result = await PriceLockService.checkAndConfirmPriceChange(
                      context: context,
                      currentCalculation: createCalculation(),
                      lockedCalculation: null,
                      onLockUpdated: () {},
                    );
                  },
                  child: const Text('Test'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Test'));
      await tester.pump();

      expect(result, equals(PriceLockResult.noChange));
    });

    testWidgets('returns noChange when price within tolerance', (tester) async {
      final current = createCalculation();
      final locked = createCalculation(roomPrice: 100.005); // Within 1 cent
      PriceLockResult? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    result = await PriceLockService.checkAndConfirmPriceChange(
                      context: context,
                      currentCalculation: current,
                      lockedCalculation: locked,
                      onLockUpdated: () {},
                    );
                  },
                  child: const Text('Test'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Test'));
      await tester.pump();

      expect(result, equals(PriceLockResult.noChange));
    });

    testWidgets('shows dialog when price increased', (tester) async {
      final current = createCalculation(roomPrice: 120.0);
      final locked = createCalculation();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    PriceLockService.checkAndConfirmPriceChange(
                      context: context,
                      currentCalculation: current,
                      lockedCalculation: locked,
                      onLockUpdated: () {},
                    );
                  },
                  child: const Text('Test'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Test'));
      await tester.pumpAndSettle();

      // Verify dialog is shown
      expect(find.text('⚠️ Price Increased'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Proceed'), findsOneWidget);
    });

    testWidgets('shows dialog when price decreased', (tester) async {
      final current = createCalculation(roomPrice: 80.0);
      final locked = createCalculation();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    PriceLockService.checkAndConfirmPriceChange(
                      context: context,
                      currentCalculation: current,
                      lockedCalculation: locked,
                      onLockUpdated: () {},
                    );
                  },
                  child: const Text('Test'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Test'));
      await tester.pumpAndSettle();

      // Verify dialog is shown with price decrease message
      expect(find.text('ℹ️ Price Decreased'), findsOneWidget);
      expect(find.textContaining('Good news!'), findsOneWidget);
    });

    testWidgets('returns cancelled when user taps Cancel', (tester) async {
      final current = createCalculation(roomPrice: 120.0);
      final locked = createCalculation();
      PriceLockResult? capturedResult;
      bool lockUpdatedCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    capturedResult =
                        await PriceLockService.checkAndConfirmPriceChange(
                          context: context,
                          currentCalculation: current,
                          lockedCalculation: locked,
                          onLockUpdated: () {
                            lockUpdatedCalled = true;
                          },
                        );
                  },
                  child: const Text('Test'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Test'));
      await tester.pumpAndSettle();

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(capturedResult, equals(PriceLockResult.cancelled));
      // When cancelled, locked price should NOT be updated (user rejected change)
      expect(lockUpdatedCalled, isFalse);
    });

    testWidgets('returns confirmedProceed when user taps Proceed', (
      tester,
    ) async {
      final current = createCalculation(roomPrice: 120.0);
      final locked = createCalculation();
      PriceLockResult? capturedResult;
      bool lockUpdatedCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    capturedResult =
                        await PriceLockService.checkAndConfirmPriceChange(
                          context: context,
                          currentCalculation: current,
                          lockedCalculation: locked,
                          onLockUpdated: () {
                            lockUpdatedCalled = true;
                          },
                        );
                  },
                  child: const Text('Test'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Test'));
      await tester.pumpAndSettle();

      // Tap Proceed
      await tester.tap(find.text('Proceed'));
      await tester.pumpAndSettle();

      expect(capturedResult, equals(PriceLockResult.confirmedProceed));
      expect(lockUpdatedCalled, isTrue);
    });

    testWidgets('respects custom dialogConfig', (tester) async {
      final current = createCalculation(roomPrice: 120.0);
      final locked = createCalculation();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    PriceLockService.checkAndConfirmPriceChange(
                      context: context,
                      currentCalculation: current,
                      lockedCalculation: locked,
                      onLockUpdated: () {},
                      dialogConfig: PriceChangeDialogConfig.croatianConfig,
                    );
                  },
                  child: const Text('Test'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Test'));
      await tester.pumpAndSettle();

      // Verify Croatian text is shown
      expect(find.text('⚠️ Cijena Povećana'), findsOneWidget);
      expect(find.text('Odustani'), findsOneWidget);
      expect(find.text('Nastavi'), findsOneWidget);
    });

    testWidgets('respects custom tolerance', (tester) async {
      final current = createCalculation(roomPrice: 100.5);
      final locked = createCalculation(); // 100.0
      PriceLockResult? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    result = await PriceLockService.checkAndConfirmPriceChange(
                      context: context,
                      currentCalculation: current,
                      lockedCalculation: locked,
                      onLockUpdated: () {},
                      tolerance: 1.0, // Custom tolerance of €1
                    );
                  },
                  child: const Text('Test'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Test'));
      await tester.pump();

      // 0.5 is within 1.0 tolerance, so no change
      expect(result, equals(PriceLockResult.noChange));
    });
  });
}
