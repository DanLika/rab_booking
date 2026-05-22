import 'package:flutter_test/flutter_test.dart';
import 'package:bookbed/core/services/currency_service.dart';

void main() {
  group('Currency Enum', () {
    test('fromCode returns correct currency for valid codes', () {
      expect(Currency.fromCode('EUR'), Currency.eur);
      expect(Currency.fromCode('USD'), Currency.usd);
      expect(Currency.fromCode('GBP'), Currency.gbp);
      expect(Currency.fromCode('HRK'), Currency.hrk);
    });

    test('fromCode returns EUR as fallback for invalid codes', () {
      expect(Currency.fromCode('INVALID'), Currency.eur);
      expect(Currency.fromCode(''), Currency.eur);
      expect(Currency.fromCode('XYZ'), Currency.eur);
    });
  });

  group('CurrencyService', () {
    late CurrencyService service;

    setUp(() {
      service = CurrencyService();
    });

    group('convert (from EUR)', () {
      test('EUR to EUR remains same', () {
        expect(service.convert(100.0, Currency.eur), 100.0);
      });

      test('EUR to USD', () {
        // EUR 100 * 1.09 (rate) = 109.0
        expect(service.convert(100.0, Currency.usd), closeTo(109.0, 0.001));
      });

      test('EUR to GBP', () {
        // EUR 100 * 0.86 (rate) = 86.0
        expect(service.convert(100.0, Currency.gbp), 86.0);
      });

      test('EUR to HRK', () {
        // EUR 100 * 7.53 (rate) = 753.0
        expect(service.convert(100.0, Currency.hrk), 753.0);
      });
    });

    group('convertBetween', () {
      test('USD to EUR', () {
        // USD 109.0 / 1.09 (USD rate) * 1.0 (EUR rate) = 100.0
        expect(service.convertBetween(109.0, Currency.usd, Currency.eur), closeTo(100.0, 0.001));
      });

      test('USD to GBP', () {
        // USD 109.0 -> EUR 100.0 -> GBP 86.0
        expect(service.convertBetween(109.0, Currency.usd, Currency.gbp), closeTo(86.0, 0.001));
      });

      test('GBP to USD', () {
        // GBP 86.0 -> EUR 100.0 -> USD 109.0
        expect(service.convertBetween(86.0, Currency.gbp, Currency.usd), closeTo(109.0, 0.001));
      });

      test('HRK to USD', () {
        // HRK 753.0 -> EUR 100.0 -> USD 109.0
        expect(service.convertBetween(753.0, Currency.hrk, Currency.usd), closeTo(109.0, 0.001));
      });
    });

    group('formatPrice', () {
      test('formats EUR correctly with prefix', () {
        expect(service.formatPrice(100.0, Currency.eur), '€100.00');
        expect(service.formatPrice(100.5, Currency.eur), '€100.50');
      });

      test('formats USD correctly with prefix', () {
        // EUR 100 -> USD 109.0
        expect(service.formatPrice(100.0, Currency.usd), '\$109.00');
      });

      test('formats GBP correctly with prefix', () {
        // EUR 100 -> GBP 86.0
        expect(service.formatPrice(100.0, Currency.gbp), '£86.00');
      });

      test('formats HRK correctly with suffix', () {
        // EUR 100 -> HRK 753.0
        expect(service.formatPrice(100.0, Currency.hrk), '753.00 kn');
      });
    });
  });

  group('CurrencyConversionExtension', () {
    test('toCurrency extension formats EUR correctly', () {
      expect(100.0.toCurrency(Currency.eur), '€100.00');
    });

    test('toCurrency extension formats USD correctly', () {
      expect(100.0.toCurrency(Currency.usd), '\$109.00');
    });

    test('toCurrency extension formats GBP correctly', () {
      expect(100.0.toCurrency(Currency.gbp), '£86.00');
    });

    test('toCurrency extension formats HRK correctly', () {
      expect(100.0.toCurrency(Currency.hrk), '753.00 kn');
    });
  });
}
