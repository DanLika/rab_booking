import 'package:flutter_test/flutter_test.dart';
import 'package:bookbed/shared/utils/validators/form_validators.dart';

void main() {
  group('FirstNameValidator', () {
    test('returns error for null', () {
      expect(FirstNameValidator.validate(null), isNotNull);
    });

    test('returns error for empty', () {
      expect(FirstNameValidator.validate(''), isNotNull);
    });

    test('returns error for whitespace only', () {
      expect(FirstNameValidator.validate('   '), isNotNull);
    });

    test('returns null for valid name', () {
      expect(FirstNameValidator.validate('John'), isNull);
    });

    test('allows apostrophes', () {
      expect(FirstNameValidator.validate("O'Brien"), isNull);
    });

    test('allows hyphens', () {
      expect(FirstNameValidator.validate('Jean-Claude'), isNull);
    });

    test('allows Unicode characters', () {
      expect(FirstNameValidator.validate('Müller'), isNull);
      expect(FirstNameValidator.validate('Željko'), isNull);
      expect(FirstNameValidator.validate('Šćepan'), isNull);
    });

    test('rejects numbers', () {
      expect(FirstNameValidator.validate('John2'), isNotNull);
    });

    test('rejects special characters', () {
      expect(FirstNameValidator.validate('John@'), isNotNull);
    });

    test('rejects spaces (first name only)', () {
      expect(FirstNameValidator.validate('John Paul'), isNotNull);
    });
  });

  group('LastNameValidator', () {
    test('returns error for null', () {
      expect(LastNameValidator.validate(null), isNotNull);
    });

    test('returns error for empty', () {
      expect(LastNameValidator.validate(''), isNotNull);
    });

    test('returns null for valid name', () {
      expect(LastNameValidator.validate('Doe'), isNull);
    });

    test('allows spaces for compound names', () {
      expect(LastNameValidator.validate('van der Berg'), isNull);
      expect(LastNameValidator.validate('de la Cruz'), isNull);
    });

    test('allows apostrophes', () {
      expect(LastNameValidator.validate("O'Connor"), isNull);
    });

    test('allows hyphens', () {
      expect(LastNameValidator.validate('Smith-Jones'), isNull);
    });

    test('allows Unicode characters', () {
      expect(LastNameValidator.validate('Müller'), isNull);
      expect(LastNameValidator.validate('Đurić'), isNull);
    });

    test('rejects numbers', () {
      expect(LastNameValidator.validate('Doe2'), isNotNull);
    });

    test('rejects special characters', () {
      expect(LastNameValidator.validate('Doe@'), isNotNull);
    });
  });

  group('NameValidator', () {
    test('returns error for null', () {
      expect(NameValidator.validate(null), isNotNull);
    });

    test('returns error for empty', () {
      expect(NameValidator.validate(''), isNotNull);
    });

    test('returns error for whitespace only', () {
      expect(NameValidator.validate('   '), isNotNull);
    });

    test('returns error for single word', () {
      expect(NameValidator.validate('John'), isNotNull);
    });

    test('returns null for valid full name', () {
      expect(NameValidator.validate('John Doe'), isNull);
    });

    test('allows apostrophes', () {
      expect(NameValidator.validate("John O'Brien"), isNull);
    });

    test('allows hyphens', () {
      expect(NameValidator.validate('Jean-Claude Van Damme'), isNull);
    });

    test('allows Unicode characters', () {
      expect(NameValidator.validate('Jürgen Müller'), isNull);
      expect(NameValidator.validate('Željko Šćepan'), isNull);
    });

    test('rejects numbers', () {
      expect(NameValidator.validate('John Doe2'), isNotNull);
    });

    test('rejects special characters', () {
      expect(NameValidator.validate('John@ Doe'), isNotNull);
    });
  });

  group('EmailValidator', () {
    test('returns error for null', () {
      expect(EmailValidator.validate(null), isNotNull);
    });

    test('returns error for empty', () {
      expect(EmailValidator.validate(''), isNotNull);
    });

    test('returns error for whitespace only', () {
      expect(EmailValidator.validate('   '), isNotNull);
    });

    test('returns error for missing @', () {
      expect(EmailValidator.validate('userexample.com'), isNotNull);
    });

    test('returns error for missing TLD', () {
      expect(EmailValidator.validate('user@example'), isNotNull);
    });

    test('returns error for single char TLD', () {
      expect(EmailValidator.validate('user@example.c'), isNotNull);
    });

    test('returns null for valid email', () {
      expect(EmailValidator.validate('user@example.com'), isNull);
    });

    test('returns null for email with dots in local part', () {
      expect(EmailValidator.validate('first.last@example.com'), isNull);
    });

    test('returns null for email with plus addressing', () {
      expect(EmailValidator.validate('user+tag@example.com'), isNull);
    });

    test('returns null for email with subdomain', () {
      expect(EmailValidator.validate('user@mail.example.co.uk'), isNull);
    });
  });

  group('PhoneValidator', () {
    test('returns error for null', () {
      expect(PhoneValidator.validate(null, '+385'), isNotNull);
    });

    test('returns error for empty', () {
      expect(PhoneValidator.validate('', '+385'), isNotNull);
    });

    test('returns error for letters', () {
      expect(PhoneValidator.validate('abcdefgh', '+385'), isNotNull);
    });

    test('returns null for valid Croatian phone', () {
      expect(PhoneValidator.validate('91 234 5678', '+385'), isNull);
    });

    test('returns error for too short number', () {
      final result = PhoneValidator.validate('12', '+385');
      expect(result, contains('too short'));
    });

    test('returns error for too long number', () {
      final result = PhoneValidator.validate('1234567890123456', '+385');
      expect(result, contains('too long'));
    });

    test('works with different country codes', () {
      // US phone
      expect(PhoneValidator.validate('2025551234', '+1'), isNull);
      // UK phone
      expect(PhoneValidator.validate('7911123456', '+44'), isNull);
    });
  });

  group('NotesValidator', () {
    test('returns null for null (optional)', () {
      expect(NotesValidator.validate(null), isNull);
    });

    test('returns null for empty (optional)', () {
      expect(NotesValidator.validate(''), isNull);
    });

    test('returns null for valid notes', () {
      expect(NotesValidator.validate('Please prepare early check-in.'), isNull);
    });

    test('returns error for notes over 500 chars', () {
      expect(NotesValidator.validate('A' * 501), isNotNull);
    });

    test('returns error for dangerous HTML content', () {
      expect(
        NotesValidator.validate('<script>alert("xss")</script>'),
        isNotNull,
      );
    });

    test('returns error for angle brackets', () {
      expect(NotesValidator.validate('test <b>bold</b>'), isNotNull);
    });

    test('returns error for pipe character', () {
      expect(NotesValidator.validate('test | command'), isNotNull);
    });

    test('returns error for backslash', () {
      expect(NotesValidator.validate('test \\ path'), isNotNull);
    });

    test('returns error for backtick', () {
      expect(NotesValidator.validate('test `code` here'), isNotNull);
    });

    test('allows normal punctuation', () {
      expect(NotesValidator.validate('Hello! How are you?'), isNull);
      expect(NotesValidator.validate('Room #3, floor 2.'), isNull);
    });
  });

  group('PhoneNumberFormatter', () {
    test('formats empty input', () {
      final formatter = PhoneNumberFormatter('+385'); // HR code
      final result = formatter.formatEditUpdate(
        const TextEditingValue(),
        const TextEditingValue(text: ''),
      );
      expect(result.text, isEmpty);
      expect(result.selection.baseOffset, 0);
    });

    test('removes non-digits', () {
      final formatter = PhoneNumberFormatter('+385');
      final result = formatter.formatEditUpdate(
        const TextEditingValue(),
        const TextEditingValue(text: 'a1b2c3!@#'),
      );
      expect(result.text, '12 3'); // 123 formatted for group sizes [2, 3, 3, 3] etc.
    });

    test('formats Croatian number correctly', () {
      final formatter = PhoneNumberFormatter('+385');
      final result = formatter.formatEditUpdate(
        const TextEditingValue(),
        const TextEditingValue(text: '912345678'),
      );
      expect(result.text, '91 234 5678'); // 2, 3, 4 sizes
    });

    test('limits to max length', () {
      final formatter = PhoneNumberFormatter('+385');
      // Croatian max length is 9 digits
      final result = formatter.formatEditUpdate(
        const TextEditingValue(),
        const TextEditingValue(text: '123456789012345678'),
      );
      expect(result.text.replaceAll(' ', '').length, 9);
    });

    test('formats US number correctly', () {
      final formatter = PhoneNumberFormatter('+1');
      final result = formatter.formatEditUpdate(
        const TextEditingValue(),
        const TextEditingValue(text: '2025551234'),
      );
      // US sizes: [3, 3, 4] -> 202 555 1234
      expect(result.text, '202 555 1234');
    });

    test('handles cursor position correctly', () {
      final formatter = PhoneNumberFormatter('+1');
      final result = formatter.formatEditUpdate(
        const TextEditingValue(),
        const TextEditingValue(text: '20255'),
      );
      expect(result.text, '202 55');
      expect(result.selection.baseOffset, 6);
    });

    test('adds remaining digits correctly', () {
      // +39 (Italy) has maxLength 10, but uses europe3_3_3 which is [3, 3, 3] sum 9
      // So 10th digit should trigger the remaining digits branch!
      final formatter = PhoneNumberFormatter('+39');
      final result = formatter.formatEditUpdate(
        const TextEditingValue(),
        const TextEditingValue(text: '1234567890'),
      );
      expect(result.text, '123 456 789 0');
    });
  });
}
