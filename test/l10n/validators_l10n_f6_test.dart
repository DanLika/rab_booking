// F6 — profile-validator l10n guard.
//
// Verifies that every [ProfileValidatorError] code resolves to a non-empty,
// non-English string in Croatian (the primary owner locale) and to a non-empty
// string in English, so no error falls back to an empty label or an enum name.
//
// Also smoke-tests the code→l10n round-trip through the actual AppLocalizations
// delegate to catch any missing ARB key that would throw a LookupError at runtime.

import 'package:bookbed/core/utils/profile_validator_error_l10n.dart';
import 'package:bookbed/core/utils/profile_validators.dart';
import 'package:bookbed/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppLocalizations l10nEn;
  late AppLocalizations l10nHr;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    l10nEn = await AppLocalizations.delegate.load(const Locale('en'));
    l10nHr = await AppLocalizations.delegate.load(const Locale('hr'));
  });

  // ---------------------------------------------------------------------------
  // Code→l10n mapping: every enum variant must yield a non-empty string in
  // both English and Croatian, and the Croatian text must differ from English
  // (proving the HR ARB key was actually translated, not copied verbatim).
  // ---------------------------------------------------------------------------
  group('ProfileValidatorError l10n', () {
    for (final error in ProfileValidatorError.values) {
      test('$error — en non-empty', () {
        expect(l10nEn.profileValidatorErrorText(error), isNotEmpty);
      });

      test('$error — hr non-empty', () {
        expect(l10nHr.profileValidatorErrorText(error), isNotEmpty);
      });

      test('$error — hr ≠ en (actually translated)', () {
        // emailRequired reuses the shared "emailRequired" key which happens to
        // differ (hr = "Unesite svoju e-poštu" vs en "Please enter your email"),
        // so the check is safe for all variants.
        expect(
          l10nHr.profileValidatorErrorText(error),
          isNot(equals(l10nEn.profileValidatorErrorText(error))),
        );
      });
    }
  });

  // ---------------------------------------------------------------------------
  // Validator logic: each code-returning twin must fire the right code and the
  // round-tripped localized string must match the expected l10n key.
  // ---------------------------------------------------------------------------
  group('ProfileValidators code twins', () {
    group('nameError', () {
      test('null → nameRequired', () {
        expect(
          ProfileValidators.nameError(null),
          ProfileValidatorError.nameRequired,
        );
        expect(
          l10nHr.profileValidatorErrorText(ProfileValidatorError.nameRequired),
          l10nHr.profileNameRequired,
        );
      });

      test('single char → nameTooShort', () {
        expect(
          ProfileValidators.nameError('A'),
          ProfileValidatorError.nameTooShort,
        );
        expect(
          l10nEn.profileValidatorErrorText(ProfileValidatorError.nameTooShort),
          l10nEn.profileNameTooShort,
        );
      });

      test('81 chars → nameTooLong', () {
        expect(
          ProfileValidators.nameError('A' * 81),
          ProfileValidatorError.nameTooLong,
        );
      });

      test('valid name → null', () {
        expect(ProfileValidators.nameError('Ana'), isNull);
      });
    });

    group('emailError', () {
      test('empty → emailRequired', () {
        expect(
          ProfileValidators.emailError(''),
          ProfileValidatorError.emailRequired,
        );
        expect(
          l10nHr.profileValidatorErrorText(ProfileValidatorError.emailRequired),
          l10nHr.emailRequired,
        );
      });

      test('bad format → emailInvalid', () {
        expect(
          ProfileValidators.emailError('notanemail'),
          ProfileValidatorError.emailInvalid,
        );
        expect(
          l10nEn.profileValidatorErrorText(ProfileValidatorError.emailInvalid),
          l10nEn.profileEmailInvalid,
        );
      });

      test('valid email → null', () {
        expect(ProfileValidators.emailError('user@example.com'), isNull);
      });
    });

    group('phoneError', () {
      test('empty → null (optional field)', () {
        expect(ProfileValidators.phoneError(''), isNull);
        expect(ProfileValidators.phoneError(null), isNull);
      });

      test('letters → phoneInvalid', () {
        expect(
          ProfileValidators.phoneError('abc'),
          ProfileValidatorError.phoneInvalid,
        );
        expect(
          l10nHr.profileValidatorErrorText(ProfileValidatorError.phoneInvalid),
          l10nHr.profilePhoneInvalid,
        );
      });

      test('valid phone → null', () {
        expect(ProfileValidators.phoneError('+385911234567'), isNull);
      });
    });

    group('ibanError', () {
      test('empty → null (optional field)', () {
        expect(ProfileValidators.ibanError(''), isNull);
      });

      test('too short → ibanLength', () {
        expect(
          ProfileValidators.ibanError('HR12'),
          ProfileValidatorError.ibanLength,
        );
        expect(
          l10nEn.profileValidatorErrorText(ProfileValidatorError.ibanLength),
          l10nEn.profileIbanLength,
        );
      });

      test('bad format (no country code) → ibanFormat', () {
        expect(
          ProfileValidators.ibanError('12345678901234567'),
          ProfileValidatorError.ibanFormat,
        );
        expect(
          l10nHr.profileValidatorErrorText(ProfileValidatorError.ibanFormat),
          l10nHr.profileIbanFormat,
        );
      });

      test('valid IBAN → null', () {
        expect(ProfileValidators.ibanError('HR1210010051863000160'), isNull);
      });
    });

    group('swiftError', () {
      test('empty → null (optional field)', () {
        expect(ProfileValidators.swiftError(''), isNull);
      });

      test('wrong length → swiftLength', () {
        expect(
          ProfileValidators.swiftError('ABC'),
          ProfileValidatorError.swiftLength,
        );
        expect(
          l10nEn.profileValidatorErrorText(ProfileValidatorError.swiftLength),
          l10nEn.profileSwiftLength,
        );
      });

      test('non-alphanumeric → swiftFormat', () {
        // 8-char but contains dash
        expect(
          ProfileValidators.swiftError('HPBZ-HR-2'),
          ProfileValidatorError.swiftLength,
        ); // stripped to 7 → length error fires first
        expect(
          ProfileValidators.swiftError('HPBZHR2!'),
          ProfileValidatorError.swiftFormat,
        );
        expect(
          l10nHr.profileValidatorErrorText(ProfileValidatorError.swiftFormat),
          l10nHr.profileSwiftFormat,
        );
      });

      test('valid 8-char SWIFT → null', () {
        expect(ProfileValidators.swiftError('HPBZHR2X'), isNull);
      });

      test('valid 11-char SWIFT → null', () {
        expect(ProfileValidators.swiftError('HPBZHR2XXXX'), isNull);
      });
    });
  });
}
