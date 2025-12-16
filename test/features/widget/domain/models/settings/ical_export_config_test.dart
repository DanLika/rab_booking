// ignore_for_file: avoid_redundant_argument_values
// Note: Explicit default values kept in tests for documentation clarity
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bookbed/features/widget/domain/models/settings/ical_export_config.dart';

void main() {
  group('ICalExportConfig', () {
    group('constructor', () {
      test('creates with default values', () {
        const config = ICalExportConfig();

        expect(config.enabled, false);
        expect(config.exportUrl, null);
        expect(config.exportToken, null);
        expect(config.lastGenerated, null);
        expect(config.includeBlockedDates, true);
        expect(config.includePricing, false);
        expect(config.feedTitle, null);
      });

      test('creates with custom values', () {
        final lastGen = DateTime(2024, 1, 15, 10, 30);
        final config = ICalExportConfig(
          enabled: true,
          exportUrl: 'https://example.com/ical/abc123.ics',
          exportToken: 'secure-token-123',
          lastGenerated: lastGen,
          includeBlockedDates: false,
          includePricing: true,
          feedTitle: 'My Property Calendar',
        );

        expect(config.enabled, true);
        expect(config.exportUrl, 'https://example.com/ical/abc123.ics');
        expect(config.exportToken, 'secure-token-123');
        expect(config.lastGenerated, lastGen);
        expect(config.includeBlockedDates, false);
        expect(config.includePricing, true);
        expect(config.feedTitle, 'My Property Calendar');
      });
    });

    group('fromMap', () {
      test('parses nested format correctly', () {
        final timestamp = Timestamp.fromDate(DateTime(2024, 1, 15));
        final map = {
          'enabled': true,
          'export_url': 'https://example.com/ical.ics',
          'export_token': 'token123',
          'last_generated': timestamp,
          'include_blocked_dates': false,
          'include_pricing': true,
          'feed_title': 'Test Calendar',
        };

        final config = ICalExportConfig.fromMap(map);

        expect(config.enabled, true);
        expect(config.exportUrl, 'https://example.com/ical.ics');
        expect(config.exportToken, 'token123');
        expect(config.lastGenerated, timestamp.toDate());
        expect(config.includeBlockedDates, false);
        expect(config.includePricing, true);
        expect(config.feedTitle, 'Test Calendar');
      });

      test('parses legacy flat format correctly', () {
        final map = {
          'ical_export_enabled': true,
          'ical_export_url': 'https://legacy.com/ical.ics',
          'ical_export_token': 'legacy-token',
        };

        final config = ICalExportConfig.fromMap(map);

        expect(config.enabled, true);
        expect(config.exportUrl, 'https://legacy.com/ical.ics');
        expect(config.exportToken, 'legacy-token');
      });

      test('prefers nested format over legacy', () {
        final map = {
          'enabled': true,
          'export_url': 'https://new.com/ical.ics',
          'ical_export_enabled': false,
          'ical_export_url': 'https://old.com/ical.ics',
        };

        final config = ICalExportConfig.fromMap(map);

        expect(config.enabled, true);
        expect(config.exportUrl, 'https://new.com/ical.ics');
      });

      test('uses defaults for missing fields', () {
        final config = ICalExportConfig.fromMap({});

        expect(config.enabled, false);
        expect(config.exportUrl, null);
        expect(config.includeBlockedDates, true);
        expect(config.includePricing, false);
      });

      test('parses DateTime from string', () {
        final map = {
          'last_generated': '2024-01-15T10:30:00.000Z',
        };

        final config = ICalExportConfig.fromMap(map);

        expect(config.lastGenerated, isNotNull);
        expect(config.lastGenerated!.year, 2024);
        expect(config.lastGenerated!.month, 1);
        expect(config.lastGenerated!.day, 15);
      });
    });

    group('fromFlatFields', () {
      test('creates config from flat widget settings fields', () {
        final lastGen = DateTime(2024, 2, 20);
        final config = ICalExportConfig.fromFlatFields(
          enabled: true,
          exportUrl: 'https://flat.com/ical.ics',
          exportToken: 'flat-token',
          lastGenerated: lastGen,
        );

        expect(config.enabled, true);
        expect(config.exportUrl, 'https://flat.com/ical.ics');
        expect(config.exportToken, 'flat-token');
        expect(config.lastGenerated, lastGen);
        // Default values for non-flat fields
        expect(config.includeBlockedDates, true);
        expect(config.includePricing, false);
      });
    });

    group('toMap', () {
      test('serializes all fields correctly', () {
        final lastGen = DateTime(2024, 3, 10, 14, 0);
        final config = ICalExportConfig(
          enabled: true,
          exportUrl: 'https://test.com/ical.ics',
          exportToken: 'test-token',
          lastGenerated: lastGen,
          includeBlockedDates: false,
          includePricing: true,
          feedTitle: 'Test Feed',
        );

        final map = config.toMap();

        expect(map['enabled'], true);
        expect(map['export_url'], 'https://test.com/ical.ics');
        expect(map['export_token'], 'test-token');
        expect((map['last_generated'] as Timestamp).toDate(), lastGen);
        expect(map['include_blocked_dates'], false);
        expect(map['include_pricing'], true);
        expect(map['feed_title'], 'Test Feed');
      });

      test('handles null lastGenerated', () {
        const config = ICalExportConfig(
          enabled: true,
          exportUrl: 'https://test.com/ical.ics',
        );

        final map = config.toMap();

        expect(map['last_generated'], null);
      });
    });

    group('toFlatFields', () {
      test('serializes to legacy flat format', () {
        final lastGen = DateTime(2024, 4, 5);
        final config = ICalExportConfig(
          enabled: true,
          exportUrl: 'https://flat.com/ical.ics',
          exportToken: 'flat-token',
          lastGenerated: lastGen,
        );

        final map = config.toFlatFields();

        expect(map['ical_export_enabled'], true);
        expect(map['ical_export_url'], 'https://flat.com/ical.ics');
        expect(map['ical_export_token'], 'flat-token');
        expect(
            (map['ical_export_last_generated'] as Timestamp).toDate(), lastGen);
      });
    });

    group('isConfigured', () {
      test('returns true when fully configured', () {
        const config = ICalExportConfig(
          enabled: true,
          exportUrl: 'https://example.com/ical.ics',
          exportToken: 'token123',
        );

        expect(config.isConfigured, true);
      });

      test('returns false when not enabled', () {
        const config = ICalExportConfig(
          enabled: false,
          exportUrl: 'https://example.com/ical.ics',
          exportToken: 'token123',
        );

        expect(config.isConfigured, false);
      });

      test('returns false when exportUrl is null', () {
        const config = ICalExportConfig(
          enabled: true,
          exportUrl: null,
          exportToken: 'token123',
        );

        expect(config.isConfigured, false);
      });

      test('returns false when exportToken is null', () {
        const config = ICalExportConfig(
          enabled: true,
          exportUrl: 'https://example.com/ical.ics',
          exportToken: null,
        );

        expect(config.isConfigured, false);
      });

      test('returns false when exportToken is empty', () {
        const config = ICalExportConfig(
          enabled: true,
          exportUrl: 'https://example.com/ical.ics',
          exportToken: '   ',
        );

        expect(config.isConfigured, false);
      });

      test('returns false when exportUrl has invalid format', () {
        const config = ICalExportConfig(
          enabled: true,
          exportUrl: 'not-a-valid-url',
          exportToken: 'token123',
        );

        expect(config.isConfigured, false);
      });

      test('returns false when exportUrl is missing scheme', () {
        const config = ICalExportConfig(
          enabled: true,
          exportUrl: 'example.com/ical.ics',
          exportToken: 'token123',
        );

        expect(config.isConfigured, false);
      });

      test('returns false when exportUrl uses non-http scheme', () {
        const config = ICalExportConfig(
          enabled: true,
          exportUrl: 'ftp://example.com/ical.ics',
          exportToken: 'token123',
        );

        expect(config.isConfigured, false);
      });

      test('returns true with http scheme', () {
        const config = ICalExportConfig(
          enabled: true,
          exportUrl: 'http://example.com/ical.ics',
          exportToken: 'token123',
        );

        expect(config.isConfigured, true);
      });

      test('returns true with https scheme', () {
        const config = ICalExportConfig(
          enabled: true,
          exportUrl: 'https://example.com/ical.ics',
          exportToken: 'token123',
        );

        expect(config.isConfigured, true);
      });
    });

    group('hasValidExportUrl', () {
      test('returns true when exportUrl is null', () {
        const config = ICalExportConfig(exportUrl: null);

        expect(config.hasValidExportUrl, true);
      });

      test('returns true when exportUrl is valid https', () {
        const config = ICalExportConfig(
          exportUrl: 'https://example.com/ical.ics',
        );

        expect(config.hasValidExportUrl, true);
      });

      test('returns false when exportUrl is invalid', () {
        const config = ICalExportConfig(
          exportUrl: 'invalid-url',
        );

        expect(config.hasValidExportUrl, false);
      });
    });

    group('needsRegeneration', () {
      test('returns true when not enabled', () {
        const config = ICalExportConfig(enabled: false);

        expect(config.needsRegeneration, true);
      });

      test('returns true when lastGenerated is null', () {
        const config = ICalExportConfig(
          enabled: true,
          lastGenerated: null,
        );

        expect(config.needsRegeneration, true);
      });

      test('returns true when lastGenerated is too old', () {
        final oldDate = DateTime.now().subtract(const Duration(hours: 2));
        final config = ICalExportConfig(
          enabled: true,
          lastGenerated: oldDate,
        );

        // Default sync interval is 1 hour, so 2 hours ago needs regeneration
        expect(config.needsRegeneration, true);
      });

      test('returns false when recently generated', () {
        final recentDate = DateTime.now().subtract(const Duration(minutes: 30));
        final config = ICalExportConfig(
          enabled: true,
          lastGenerated: recentDate,
        );

        expect(config.needsRegeneration, false);
      });
    });

    group('getDisplayTitle', () {
      test('returns custom feedTitle if set', () {
        const config = ICalExportConfig(
          feedTitle: 'My Custom Calendar',
        );

        expect(config.getDisplayTitle('Beach House'), 'My Custom Calendar');
      });

      test('returns default title with unit name if feedTitle not set', () {
        const config = ICalExportConfig(
          feedTitle: null,
        );

        expect(config.getDisplayTitle('Beach House'),
            'Beach House - Availability Calendar');
      });
    });

    group('copyWith', () {
      test('creates copy with updated fields', () {
        const original = ICalExportConfig(
          enabled: true,
          exportUrl: 'https://original.com/ical.ics',
          feedTitle: 'Original',
        );

        final copy = original.copyWith(
          exportUrl: 'https://updated.com/ical.ics',
          includePricing: true,
        );

        expect(copy.enabled, true); // unchanged
        expect(copy.exportUrl, 'https://updated.com/ical.ics');
        expect(copy.feedTitle, 'Original'); // unchanged
        expect(copy.includePricing, true);
      });
    });

    group('equality', () {
      test('equal configs are equal', () {
        const config1 = ICalExportConfig(
          enabled: true,
          exportUrl: 'https://test.com/ical.ics',
        );
        const config2 = ICalExportConfig(
          enabled: true,
          exportUrl: 'https://test.com/ical.ics',
        );

        expect(config1, equals(config2));
        expect(config1.hashCode, equals(config2.hashCode));
      });

      test('different configs are not equal', () {
        const config1 = ICalExportConfig(
          enabled: true,
          exportUrl: 'https://test1.com/ical.ics',
        );
        const config2 = ICalExportConfig(
          enabled: true,
          exportUrl: 'https://test2.com/ical.ics',
        );

        expect(config1, isNot(equals(config2)));
      });
    });
  });
}
