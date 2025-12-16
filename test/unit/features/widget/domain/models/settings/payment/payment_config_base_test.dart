// ignore_for_file: avoid_redundant_argument_values
// Note: Explicit default values kept in tests for documentation clarity
import 'package:flutter_test/flutter_test.dart';
import 'package:bookbed/features/widget/domain/models/settings/payment/stripe_payment_config.dart';

void main() {
  group('PaymentConfigBase (via StripePaymentConfig)', () {
    group('calculateDeposit', () {
      test('returns full amount when deposit percentage is 0', () {
        const config = StripePaymentConfig(depositPercentage: 0);

        expect(config.calculateDeposit(500.0), 500.0);
      });

      test('returns full amount when deposit percentage is 100', () {
        const config = StripePaymentConfig(depositPercentage: 100);

        expect(config.calculateDeposit(500.0), 500.0);
      });

      test('calculates 20% deposit correctly', () {
        const config = StripePaymentConfig(depositPercentage: 20);

        expect(config.calculateDeposit(500.0), 100.0);
        expect(config.calculateDeposit(185.175), 37.04); // cent-based rounding
      });

      test('avoids floating point precision errors', () {
        const config = StripePaymentConfig(depositPercentage: 20);

        // This previously would return 37.034999999999997
        final result = config.calculateDeposit(185.175);

        // With cent-based arithmetic: round(18517.5 * 20 / 100) = 3703 cents = 37.03
        // Actually: round(185.175 * 100) = 18518 cents, then 18518 * 20 / 100 = 3703.6 -> 3704 cents = 37.04
        expect(result, 37.04);
        expect(result.toString(), isNot(contains('999'))); // No floating point artifacts
      });

      // Note: Negative amounts trigger assert in debug mode.
      // The safe fallback (return 0.0) only applies in release mode.

      test('handles zero total amount', () {
        const config = StripePaymentConfig(depositPercentage: 20);

        expect(config.calculateDeposit(0.0), 0.0);
      });

      test('calculates various percentages correctly', () {
        const config10 = StripePaymentConfig(depositPercentage: 10);
        const config30 = StripePaymentConfig(depositPercentage: 30);
        const config50 = StripePaymentConfig(depositPercentage: 50);

        expect(config10.calculateDeposit(100.0), 10.0);
        expect(config30.calculateDeposit(100.0), 30.0);
        expect(config50.calculateDeposit(100.0), 50.0);
      });
    });

    group('calculateRemaining', () {
      test('returns 0.0 when deposit percentage is 0', () {
        const config = StripePaymentConfig(depositPercentage: 0);

        expect(config.calculateRemaining(500.0), 0.0);
      });

      test('returns 0.0 when deposit percentage is 100', () {
        const config = StripePaymentConfig(depositPercentage: 100);

        expect(config.calculateRemaining(500.0), 0.0);
      });

      test('calculates remaining correctly after 20% deposit', () {
        const config = StripePaymentConfig(depositPercentage: 20);

        expect(config.calculateRemaining(500.0), 400.0);
      });

      test('avoids floating point precision errors', () {
        const config = StripePaymentConfig(depositPercentage: 20);

        final remaining = config.calculateRemaining(185.175);

        // total=18518 cents, deposit=3704 cents, remaining=14814 cents = 148.14
        expect(remaining, 148.14);
        expect(remaining.toString(), isNot(contains('999')));
      });

      test('deposit + remaining equals total', () {
        const config = StripePaymentConfig(depositPercentage: 20);
        const total = 185.175;

        final deposit = config.calculateDeposit(total);
        final remaining = config.calculateRemaining(total);

        // Due to cent-based rounding, sum might differ by 1 cent
        expect((deposit + remaining - total).abs(), lessThan(0.02));
      });

      // Note: Negative amounts trigger assert in debug mode.
      // The safe fallback (return 0.0) only applies in release mode.
    });
  });
}
