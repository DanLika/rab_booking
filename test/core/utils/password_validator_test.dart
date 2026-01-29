import 'package:flutter_test/flutter_test.dart';
import 'package:bookbed/core/utils/password_validator.dart';

void main() {
  group('PasswordValidator', () {
    group('validate', () {
      test('returns invalid for null password', () {
        final result = PasswordValidator.validate(null);
        expect(result.isValid, isFalse);
        expect(result.errorMessage, 'Password is required');
      });

      test('returns invalid for empty password', () {
        final result = PasswordValidator.validate('');
        expect(result.isValid, isFalse);
        expect(result.errorMessage, 'Password is required');
      });

      test('returns invalid for common password', () {
        final result = PasswordValidator.validate('password123');
        expect(result.isValid, isFalse);
        expect(result.errorMessage, contains('too common'));
      });

      test('rejects common passwords case-insensitively', () {
        final result = PasswordValidator.validate('Password123');
        // 'password123' is in blacklist, case-insensitive check
        expect(result.isValid, isFalse);
        expect(result.errorMessage, contains('too common'));
      });

      test('returns invalid for short password', () {
        final result = PasswordValidator.validate('Ab1!');
        expect(result.isValid, isFalse);
        expect(result.missingRequirements, contains('At least 8 characters'));
      });

      test('returns invalid for password over max length', () {
        final result = PasswordValidator.validate('A' * 129 + 'b1!');
        expect(result.isValid, isFalse);
        expect(result.errorMessage, contains('less than 128'));
      });

      test('returns invalid without uppercase', () {
        final result = PasswordValidator.validate('abcd1234!');
        expect(result.isValid, isFalse);
        expect(result.missingRequirements, contains('One uppercase letter'));
      });

      test('returns invalid without lowercase', () {
        final result = PasswordValidator.validate('ABCD1234!');
        expect(result.isValid, isFalse);
        expect(result.missingRequirements, contains('One lowercase letter'));
      });

      test('returns invalid without digit', () {
        final result = PasswordValidator.validate('AbcdEfgh!');
        expect(result.isValid, isFalse);
        expect(result.missingRequirements, contains('One number'));
      });

      test('returns invalid without special character', () {
        final result = PasswordValidator.validate('Abcd1234');
        expect(result.isValid, isFalse);
        expect(result.missingRequirements, contains('One special character'));
      });

      test('returns valid for strong password', () {
        final result = PasswordValidator.validate('MyStr0ng!Pass');
        expect(result.isValid, isTrue);
        expect(result.errorMessage, isNull);
      });

      test('short valid password can be weak strength', () {
        final result = PasswordValidator.validate('MyPass1!');
        expect(result.isValid, isTrue);
        // 8 chars, all 4 char types = score 4 = weak (< 5)
        expect(result.strength, PasswordStrength.weak);
      });

      test('long complex password is strong', () {
        final result = PasswordValidator.validate('MyV3ry!Str0ng@Pass');
        expect(result.isValid, isTrue);
        expect(result.strength, PasswordStrength.strong);
      });
    });

    group('validateSimple', () {
      test('returns null for valid password', () {
        expect(PasswordValidator.validateSimple('MyStr0ng!Pass'), isNull);
      });

      test('returns error message for invalid password', () {
        expect(PasswordValidator.validateSimple(''), isNotNull);
      });
    });

    group('validateLoginPassword', () {
      test('returns null for valid length', () {
        expect(PasswordValidator.validateLoginPassword('12345678'), isNull);
      });

      test('returns error for null', () {
        expect(PasswordValidator.validateLoginPassword(null), isNotNull);
      });

      test('returns error for empty', () {
        expect(PasswordValidator.validateLoginPassword(''), isNotNull);
      });

      test('returns error for short password', () {
        final result = PasswordValidator.validateLoginPassword('1234567');
        expect(result, contains('at least 8'));
      });

      test('returns error for too long password', () {
        final result = PasswordValidator.validateLoginPassword('a' * 129);
        expect(result, contains('less than 128'));
      });

      test('does not check complexity for login', () {
        // Login only checks length, not uppercase/special chars etc.
        expect(PasswordValidator.validateLoginPassword('abcdefgh'), isNull);
      });
    });

    group('validateMinimumLength', () {
      test('returns null for valid password', () {
        expect(PasswordValidator.validateMinimumLength('MyP@ss99'), isNull);
      });

      test('rejects sequential numbers', () {
        final result = PasswordValidator.validateMinimumLength('12345678');
        expect(result, contains('sequential'));
      });

      test('rejects descending sequential numbers', () {
        final result = PasswordValidator.validateMinimumLength('87654321');
        expect(result, contains('sequential'));
      });

      test('rejects sequential letters', () {
        final result = PasswordValidator.validateMinimumLength('abcdefgh');
        expect(result, contains('sequential'));
      });

      test('rejects descending sequential letters', () {
        final result = PasswordValidator.validateMinimumLength('hgfedcba');
        expect(result, contains('sequential'));
      });

      test('rejects repeating characters', () {
        final result = PasswordValidator.validateMinimumLength('11111111');
        expect(result, contains('repeating'));
      });

      test('rejects repeating letters', () {
        final result = PasswordValidator.validateMinimumLength('aaaaaaaa');
        expect(result, contains('repeating'));
      });

      test('allows non-sequential non-repeating password', () {
        expect(PasswordValidator.validateMinimumLength('xk9m4p2w'), isNull);
      });
    });

    group('validateConfirmPassword', () {
      test('returns null when passwords match', () {
        expect(
          PasswordValidator.validateConfirmPassword('pass123', 'pass123'),
          isNull,
        );
      });

      test('returns error when confirm is null', () {
        expect(
          PasswordValidator.validateConfirmPassword('pass123', null),
          contains('confirm'),
        );
      });

      test('returns error when confirm is empty', () {
        expect(
          PasswordValidator.validateConfirmPassword('pass123', ''),
          contains('confirm'),
        );
      });

      test('returns error when passwords do not match', () {
        expect(
          PasswordValidator.validateConfirmPassword('pass123', 'pass456'),
          contains('do not match'),
        );
      });
    });
  });

  group('PasswordStrength', () {
    test('has all expected values', () {
      expect(PasswordStrength.values.length, 3);
      expect(PasswordStrength.values, contains(PasswordStrength.weak));
      expect(PasswordStrength.values, contains(PasswordStrength.medium));
      expect(PasswordStrength.values, contains(PasswordStrength.strong));
    });
  });

  group('PasswordValidationResult', () {
    test('valid factory creates valid result', () {
      final result = PasswordValidationResult.valid(PasswordStrength.strong);
      expect(result.isValid, isTrue);
      expect(result.errorMessage, isNull);
      expect(result.strength, PasswordStrength.strong);
      expect(result.missingRequirements, isEmpty);
    });

    test('invalid factory creates invalid result', () {
      final result = PasswordValidationResult.invalid(
        'Error message',
        missing: ['Requirement 1'],
      );
      expect(result.isValid, isFalse);
      expect(result.errorMessage, 'Error message');
      expect(result.strength, PasswordStrength.weak);
      expect(result.missingRequirements, ['Requirement 1']);
    });
  });
}
