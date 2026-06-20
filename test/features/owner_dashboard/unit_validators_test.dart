// P7 — form-validation paths for the unit form (UnitValidators).
//
// Closes a coverage gap: the other form validators (profile / password /
// form_validators / booking) already have tests, but the owner unit-form
// validators did not. Exercises each validation branch (required / malformed /
// boundary / valid) against the real English AppLocalizations so the error
// strings actually resolve.

import 'package:bookbed/features/owner_dashboard/presentation/utils/unit_validators.dart';
import 'package:bookbed/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  group('UnitValidators', () {
    test('validateUnitName — required', () {
      expect(UnitValidators.validateUnitName(null, l10n), isNotNull);
      expect(UnitValidators.validateUnitName('   ', l10n), isNotNull);
      expect(UnitValidators.validateUnitName('Studio 4', l10n), isNull);
    });

    test('validateSlug — required + valid format', () {
      expect(UnitValidators.validateSlug(null, l10n), isNotNull);
      expect(UnitValidators.validateSlug('', l10n), isNotNull);
      expect(UnitValidators.validateSlug('UPPER CASE!', l10n), isNotNull);
      expect(UnitValidators.validateSlug('apartman-6', l10n), isNull);
    });

    test('validateBedrooms / validateBeds — required, integer, >= 0', () {
      expect(UnitValidators.validateBedrooms('', l10n), isNotNull);
      expect(UnitValidators.validateBedrooms('abc', l10n), isNotNull);
      expect(UnitValidators.validateBedrooms('-1', l10n), isNotNull);
      expect(UnitValidators.validateBedrooms('0', l10n), isNull);
      expect(UnitValidators.validateBeds('2', l10n), isNull);
    });

    test('validateCapacity — required, >= 1', () {
      expect(UnitValidators.validateCapacity('', l10n), isNotNull);
      expect(UnitValidators.validateCapacity('0', l10n), isNotNull);
      expect(UnitValidators.validateCapacity('1', l10n), isNull);
    });

    test('validatePrice — required, > 0, accepts comma decimal', () {
      expect(UnitValidators.validatePrice('', l10n), isNotNull);
      expect(UnitValidators.validatePrice('0', l10n), isNotNull);
      expect(UnitValidators.validatePrice('-5', l10n), isNotNull);
      expect(UnitValidators.validatePrice('abc', l10n), isNotNull);
      expect(UnitValidators.validatePrice('49,90', l10n), isNull);
      expect(UnitValidators.validatePrice('120', l10n), isNull);
    });

    test('validateMinStay — required, >= 1', () {
      expect(UnitValidators.validateMinStay('', l10n), isNotNull);
      expect(UnitValidators.validateMinStay('0', l10n), isNotNull);
      expect(UnitValidators.validateMinStay('2', l10n), isNull);
    });

    test('validateMaxStay — optional, but >= minStay when given', () {
      expect(UnitValidators.validateMaxStay('', l10n), isNull); // optional
      expect(UnitValidators.validateMaxStay('0', l10n), isNotNull);
      expect(UnitValidators.validateMaxStay('3', l10n, minStay: 5), isNotNull);
      expect(UnitValidators.validateMaxStay('7', l10n, minStay: 5), isNull);
    });

    test('validateDescription — optional (UI caps length)', () {
      expect(UnitValidators.validateDescription(null, l10n), isNull);
      expect(UnitValidators.validateDescription('x' * 5000, l10n), isNull);
    });

    test('validateRequiredInt — required, >= minValue', () {
      expect(UnitValidators.validateRequiredInt('', l10n), isNotNull);
      expect(
        UnitValidators.validateRequiredInt('5', l10n, minValue: 10),
        isNotNull,
      );
      expect(
        UnitValidators.validateRequiredInt('10', l10n, minValue: 10),
        isNull,
      );
    });
  });
}
