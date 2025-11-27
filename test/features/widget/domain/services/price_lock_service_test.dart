import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rab_booking/features/widget/domain/services/price_lock_service.dart';
import 'package:rab_booking/features/widget/presentation/providers/booking_price_provider.dart';

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
      expect(PriceLockResult.values[1], equals(PriceLockResult.confirmedProceed));
    });

    test('cancelled is third value', () {
      expect(PriceLockResult.values[2], equals(PriceLockResult.cancelled));
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
      final calc = createCalculation(
        additionalServicesTotal: 25.0,
      );
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
      final calc = createCalculation(
        roomPrice: 110.0,
        lockedTotalPrice: 100.0,
      );
      expect(calc.priceChangeDelta, equals(10.0));
    });

    test('priceChangeDelta returns negative delta when price decreased', () {
      final calc = createCalculation(
        roomPrice: 90.0,
        lockedTotalPrice: 100.0,
      );
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
      final original = createCalculation(
        
      );
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

      expect(calc.formattedRoomPrice, equals('€123.45'));
      expect(calc.formattedAdditionalServices, equals('€20.50'));
      expect(calc.formattedTotal, equals('€143.95'));
      expect(calc.formattedDeposit, equals('€28.79'));
      expect(calc.formattedRemaining, equals('€115.16'));
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

    testWidgets('returns noChange when lockedCalculation is null',
        (tester) async {
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
      expect(lockUpdatedCalled, isTrue);
    });

    testWidgets('returns confirmedProceed when user taps Proceed',
        (tester) async {
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
  });
}
