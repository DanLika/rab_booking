// ignore_for_file: avoid_redundant_argument_values
// Note: Explicit default values kept in tests for documentation clarity
import 'package:flutter_test/flutter_test.dart';
import 'package:bookbed/features/widget/domain/models/settings/tax_legal_config.dart';

void main() {
  group('TaxLegalConfig', () {
    group('constructor', () {
      test('creates with default values', () {
        const config = TaxLegalConfig();

        expect(config.enabled, true); // Enabled by default for compliance
        expect(config.useDefaultText, true);
        expect(config.customText, isNull);
      });

      test('creates with custom values', () {
        const config = TaxLegalConfig(
          enabled: false,
          useDefaultText: false,
          customText: 'Custom disclaimer text',
        );

        expect(config.enabled, false);
        expect(config.useDefaultText, false);
        expect(config.customText, 'Custom disclaimer text');
      });
    });

    group('fromMap', () {
      test('parses all fields from map', () {
        final map = {
          'enabled': false,
          'use_default_text': false,
          'custom_text': 'My custom text',
        };

        final config = TaxLegalConfig.fromMap(map);

        expect(config.enabled, false);
        expect(config.useDefaultText, false);
        expect(config.customText, 'My custom text');
      });

      test('uses defaults for missing fields', () {
        final config = TaxLegalConfig.fromMap({});

        expect(config.enabled, true);
        expect(config.useDefaultText, true);
        expect(config.customText, isNull);
      });
    });

    group('toMap', () {
      test('serializes all fields to map', () {
        const config = TaxLegalConfig(
          enabled: true,
          useDefaultText: false,
          customText: 'Serialized text',
        );

        final map = config.toMap();

        expect(map['enabled'], true);
        expect(map['use_default_text'], false);
        expect(map['custom_text'], 'Serialized text');
      });

      test('round-trips correctly through fromMap/toMap', () {
        const original = TaxLegalConfig(
          enabled: false,
          useDefaultText: false,
          customText: 'Round trip text',
        );

        final restored = TaxLegalConfig.fromMap(original.toMap());

        expect(restored, original);
      });
    });

    group('disclaimerText', () {
      test('returns empty string when disabled', () {
        const config = TaxLegalConfig(enabled: false);

        expect(config.disclaimerText, '');
      });

      test('returns default Croatian text when useDefaultText is true', () {
        const config = TaxLegalConfig(
          enabled: true,
          useDefaultText: true,
        );

        final text = config.disclaimerText;

        expect(text, contains('VAŽNO - Pravne i porezne informacije'));
        expect(text, contains('Boravišna pristojba'));
        expect(text, contains('Fiskalizacija'));
        expect(text, contains('eVisitor'));
        expect(text, contains('Turistička naknada'));
      });

      test('returns custom text when useDefaultText is false', () {
        const config = TaxLegalConfig(
          enabled: true,
          useDefaultText: false,
          customText: 'My custom legal disclaimer',
        );

        expect(config.disclaimerText, 'My custom legal disclaimer');
      });

      test('falls back to default when custom text is null', () {
        const config = TaxLegalConfig(
          enabled: true,
          useDefaultText: false,
          customText: null,
        );

        // Now falls back to default Croatian text instead of empty string
        expect(config.disclaimerText, contains('VAŽNO - Pravne i porezne informacije'));
      });

      test('falls back to default when custom text is empty', () {
        const config = TaxLegalConfig(
          enabled: true,
          useDefaultText: false,
          customText: '',
        );

        // Falls back to default Croatian text
        expect(config.disclaimerText, contains('VAŽNO - Pravne i porezne informacije'));
      });

      test('falls back to default when custom text is whitespace only', () {
        const config = TaxLegalConfig(
          enabled: true,
          useDefaultText: false,
          customText: '   ',
        );

        // Falls back to default Croatian text
        expect(config.disclaimerText, contains('VAŽNO - Pravne i porezne informacije'));
      });

      test('trims custom text before returning', () {
        const config = TaxLegalConfig(
          enabled: true,
          useDefaultText: false,
          customText: '  My trimmed text  ',
        );

        expect(config.disclaimerText, 'My trimmed text');
      });
    });

    group('hasValidCustomText', () {
      test('returns false when customText is null', () {
        const config = TaxLegalConfig(customText: null);

        expect(config.hasValidCustomText, false);
      });

      test('returns false when customText is empty', () {
        const config = TaxLegalConfig(customText: '');

        expect(config.hasValidCustomText, false);
      });

      test('returns false when customText is whitespace only', () {
        const config = TaxLegalConfig(customText: '   ');

        expect(config.hasValidCustomText, false);
      });

      test('returns true when customText has content', () {
        const config = TaxLegalConfig(customText: 'Valid custom text');

        expect(config.hasValidCustomText, true);
      });
    });

    group('shortDisclaimerText', () {
      test('returns empty string when disabled', () {
        const config = TaxLegalConfig(enabled: false);

        expect(config.shortDisclaimerText, '');
      });

      test('returns short disclaimer when enabled', () {
        const config = TaxLegalConfig(enabled: true);

        final text = config.shortDisclaimerText;

        expect(text, contains('Boravišna pristojba'));
        expect(text, contains('turistička naknada'));
        expect(text, contains('fiskalizaciju'));
        expect(text, contains('eVisitor'));
        // Should be shorter than full disclaimer
        expect(text.length, lessThan(config.disclaimerText.length));
      });
    });

    group('copyWith', () {
      test('creates copy with updated fields', () {
        const original = TaxLegalConfig(
          enabled: true,
          useDefaultText: true,
        );

        final updated = original.copyWith(
          enabled: false,
          customText: 'New custom text',
        );

        expect(updated.enabled, false);
        expect(updated.useDefaultText, true); // unchanged
        expect(updated.customText, 'New custom text');
      });

      test('preserves all fields when no arguments provided', () {
        const original = TaxLegalConfig(
          enabled: false,
          useDefaultText: false,
          customText: 'Preserved text',
        );

        final copy = original.copyWith();

        expect(copy, original);
      });
    });

    group('equality', () {
      test('equal configs are equal', () {
        const config1 = TaxLegalConfig(
          enabled: true,
          useDefaultText: false,
          customText: 'Same text',
        );
        const config2 = TaxLegalConfig(
          enabled: true,
          useDefaultText: false,
          customText: 'Same text',
        );

        expect(config1, config2);
        expect(config1.hashCode, config2.hashCode);
      });

      test('different configs are not equal', () {
        const config1 = TaxLegalConfig(enabled: true);
        const config2 = TaxLegalConfig(enabled: false);

        expect(config1, isNot(config2));
      });
    });

    group('toString', () {
      test('returns readable string representation', () {
        const config = TaxLegalConfig(
          enabled: true,
          useDefaultText: false,
        );

        expect(
          config.toString(),
          'TaxLegalConfig(enabled: true, useDefaultText: false)',
        );
      });
    });
  });
}
