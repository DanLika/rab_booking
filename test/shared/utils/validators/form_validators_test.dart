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
}
