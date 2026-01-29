import 'package:flutter_test/flutter_test.dart';
import 'package:bookbed/core/utils/profile_validators.dart';

void main() {
  group('ProfileValidators', () {
    group('validateName', () {
      test('returns error for null', () {
        expect(ProfileValidators.validateName(null), isNotNull);
      });

      test('returns error for empty string', () {
        expect(ProfileValidators.validateName(''), isNotNull);
      });

      test('returns error for whitespace only', () {
        expect(ProfileValidators.validateName('   '), isNotNull);
      });

      test('returns error for single character', () {
        expect(ProfileValidators.validateName('A'), contains('at least 2'));
      });

      test('returns error for over 80 characters', () {
        expect(
          ProfileValidators.validateName('A' * 81),
          contains('less than 80'),
        );
      });

      test('returns null for valid name', () {
        expect(ProfileValidators.validateName('John'), isNull);
      });

      test('returns null for 2-character name', () {
        expect(ProfileValidators.validateName('Jo'), isNull);
      });

      test('returns null for 80-character name', () {
        expect(ProfileValidators.validateName('A' * 80), isNull);
      });
    });

    group('validateEmail', () {
      test('returns error for null', () {
        expect(ProfileValidators.validateEmail(null), isNotNull);
      });

      test('returns error for empty', () {
        expect(ProfileValidators.validateEmail(''), isNotNull);
      });

      test('returns error for no @', () {
        expect(ProfileValidators.validateEmail('invalid'), isNotNull);
      });

      test('returns error for no TLD', () {
        expect(ProfileValidators.validateEmail('test@test'), isNotNull);
      });

      test('returns error for single char TLD', () {
        expect(ProfileValidators.validateEmail('test@test.c'), isNotNull);
      });

      test('returns null for valid email', () {
        expect(ProfileValidators.validateEmail('user@example.com'), isNull);
      });

      test('returns null with subdomain', () {
        expect(
          ProfileValidators.validateEmail('user@mail.example.com'),
          isNull,
        );
      });

      test('returns null with plus addressing', () {
        expect(ProfileValidators.validateEmail('user+tag@example.com'), isNull);
      });

      test('trims whitespace', () {
        expect(ProfileValidators.validateEmail('  user@example.com  '), isNull);
      });
    });

    group('validatePhone', () {
      test('returns null for null (optional)', () {
        expect(ProfileValidators.validatePhone(null), isNull);
      });

      test('returns null for empty (optional)', () {
        expect(ProfileValidators.validatePhone(''), isNull);
      });

      test('returns null for valid phone', () {
        expect(ProfileValidators.validatePhone('+385911234567'), isNull);
      });

      test('returns null for phone with formatting', () {
        expect(ProfileValidators.validatePhone('091-123-4567'), isNull);
      });

      test('returns null for phone with parentheses', () {
        expect(ProfileValidators.validatePhone('(091) 123 4567'), isNull);
      });

      test('returns error for too short', () {
        expect(ProfileValidators.validatePhone('12345'), isNotNull);
      });

      test('returns error for too long', () {
        expect(ProfileValidators.validatePhone('1234567890123456'), isNotNull);
      });

      test('returns error for letters', () {
        expect(ProfileValidators.validatePhone('abc1234567'), isNotNull);
      });
    });

    group('validateAddressField', () {
      test('returns null for null (optional)', () {
        expect(ProfileValidators.validateAddressField(null, 'City'), isNull);
      });

      test('returns null for empty (optional)', () {
        expect(ProfileValidators.validateAddressField('', 'City'), isNull);
      });

      test('returns error for single char', () {
        final result = ProfileValidators.validateAddressField('A', 'City');
        expect(result, contains('City'));
        expect(result, contains('at least 2'));
      });

      test('returns error for over 120 chars', () {
        final result = ProfileValidators.validateAddressField(
          'A' * 121,
          'City',
        );
        expect(result, contains('less than 120'));
      });

      test('returns null for valid value', () {
        expect(
          ProfileValidators.validateAddressField('Zagreb', 'City'),
          isNull,
        );
      });
    });

    group('validatePostalCode', () {
      test('returns null for null (optional)', () {
        expect(ProfileValidators.validatePostalCode(null), isNull);
      });

      test('returns null for valid postal code', () {
        expect(ProfileValidators.validatePostalCode('10000'), isNull);
      });

      test('returns null for alphanumeric postal code', () {
        expect(ProfileValidators.validatePostalCode('SW1A 1AA'), isNull);
      });

      test('returns error for single char', () {
        expect(ProfileValidators.validatePostalCode('1'), isNotNull);
      });

      test('returns error for over 20 chars', () {
        expect(ProfileValidators.validatePostalCode('A' * 21), isNotNull);
      });

      test('returns error for special characters', () {
        expect(ProfileValidators.validatePostalCode('10@00'), isNotNull);
      });
    });

    group('validateWebsite', () {
      test('returns null for null (optional)', () {
        expect(ProfileValidators.validateWebsite(null), isNull);
      });

      test('returns null for valid https URL', () {
        expect(
          ProfileValidators.validateWebsite('https://example.com'),
          isNull,
        );
      });

      test('returns null for valid http URL', () {
        expect(ProfileValidators.validateWebsite('http://example.com'), isNull);
      });

      test('returns error for URL without protocol', () {
        expect(ProfileValidators.validateWebsite('example.com'), isNotNull);
      });

      test('returns error for invalid URL', () {
        expect(ProfileValidators.validateWebsite('not a url'), isNotNull);
      });
    });

    group('validateTaxId', () {
      test('returns null for null (optional)', () {
        expect(ProfileValidators.validateTaxId(null), isNull);
      });

      test('returns null for valid tax ID', () {
        expect(ProfileValidators.validateTaxId('12345678901'), isNull);
      });

      test('returns error for too short', () {
        expect(ProfileValidators.validateTaxId('1234'), isNotNull);
      });

      test('returns error for too long', () {
        expect(ProfileValidators.validateTaxId('A' * 21), isNotNull);
      });

      test('returns error for special characters', () {
        expect(ProfileValidators.validateTaxId('123-456'), isNotNull);
      });
    });

    group('validateVatId', () {
      test('returns null for null (optional)', () {
        expect(ProfileValidators.validateVatId(null), isNull);
      });

      test('returns null for valid VAT ID', () {
        expect(ProfileValidators.validateVatId('HR12345678901'), isNull);
      });

      test('returns error for too short', () {
        expect(ProfileValidators.validateVatId('HR12'), isNotNull);
      });

      test('returns error for special characters', () {
        expect(ProfileValidators.validateVatId('HR-12345'), isNotNull);
      });
    });

    group('validateIban', () {
      test('returns null for null (optional)', () {
        expect(ProfileValidators.validateIban(null), isNull);
      });

      test('returns null for valid IBAN', () {
        expect(ProfileValidators.validateIban('HR1210010051863000160'), isNull);
      });

      test('returns null for IBAN with spaces', () {
        expect(
          ProfileValidators.validateIban('HR12 1001 0051 8630 0016 0'),
          isNull,
        );
      });

      test('returns error for too short', () {
        expect(ProfileValidators.validateIban('HR1234567890'), isNotNull);
      });

      test('returns error for too long', () {
        expect(ProfileValidators.validateIban('HR${'1' * 33}'), isNotNull);
      });

      test('returns error for missing country code', () {
        expect(ProfileValidators.validateIban('121234567890123456'), isNotNull);
      });
    });

    group('validateSwift', () {
      test('returns null for null (optional)', () {
        expect(ProfileValidators.validateSwift(null), isNull);
      });

      test('returns null for 8-char SWIFT', () {
        expect(ProfileValidators.validateSwift('PBZGHR2X'), isNull);
      });

      test('returns null for 11-char SWIFT', () {
        expect(ProfileValidators.validateSwift('PBZGHR2XXXX'), isNull);
      });

      test('returns error for wrong length', () {
        expect(ProfileValidators.validateSwift('PBZG'), isNotNull);
        expect(ProfileValidators.validateSwift('PBZGHR2XX'), isNotNull);
      });

      test('returns error for special characters', () {
        expect(ProfileValidators.validateSwift('PBZG-R2X'), isNotNull);
      });
    });
  });
}
