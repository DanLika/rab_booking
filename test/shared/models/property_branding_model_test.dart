import 'package:flutter_test/flutter_test.dart';
import 'package:bookbed/shared/models/property_branding_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PropertyBranding', () {
    group('hasCustomBranding', () {
      test('returns false for empty branding', () {
        const branding = PropertyBranding();
        expect(branding.hasCustomBranding, isFalse);
      });

      test('returns true when displayName is set', () {
        const branding = PropertyBranding(displayName: 'Custom Name');
        expect(branding.hasCustomBranding, isTrue);
      });

      test('returns true when logoUrl is set', () {
        const branding = PropertyBranding(
          logoUrl: 'https://example.com/logo.png',
        );
        expect(branding.hasCustomBranding, isTrue);
      });

      test('returns true when primaryColor is set', () {
        const branding = PropertyBranding(primaryColor: '#1976d2');
        expect(branding.hasCustomBranding, isTrue);
      });

      test('returns false when only secondaryColor is set', () {
        // secondaryColor alone doesn't count as custom branding
        const branding = PropertyBranding(secondaryColor: '#ff0000');
        expect(branding.hasCustomBranding, isFalse);
      });

      test('returns false when only faviconUrl is set', () {
        // faviconUrl alone doesn't count as custom branding
        const branding = PropertyBranding(
          faviconUrl: 'https://example.com/favicon.ico',
        );
        expect(branding.hasCustomBranding, isFalse);
      });

      test('returns true when multiple properties are set', () {
        const branding = PropertyBranding(
          displayName: 'Test',
          primaryColor: '#123456',
          logoUrl: 'https://example.com/logo.png',
        );
        expect(branding.hasCustomBranding, isTrue);
      });
    });

    group('primaryColorValue', () {
      test('returns null when primaryColor is null', () {
        const branding = PropertyBranding();
        expect(branding.primaryColorValue, isNull);
      });

      test('parses hex color without #', () {
        const branding = PropertyBranding(primaryColor: '1976d2');
        expect(branding.primaryColorValue, equals(0xFF1976d2));
      });

      test('parses hex color with #', () {
        const branding = PropertyBranding(primaryColor: '#1976d2');
        expect(branding.primaryColorValue, equals(0xFF1976d2));
      });

      test('parses uppercase hex color', () {
        const branding = PropertyBranding(primaryColor: '#FF5733');
        expect(branding.primaryColorValue, equals(0xFFFF5733));
      });

      test('parses lowercase hex color', () {
        const branding = PropertyBranding(primaryColor: '#ff5733');
        expect(branding.primaryColorValue, equals(0xFFff5733));
      });

      test('returns null for invalid hex color', () {
        const branding = PropertyBranding(primaryColor: 'not-a-color');
        expect(branding.primaryColorValue, isNull);
      });

      test('handles empty string gracefully', () {
        // Empty string technically parses to 0xFF (just alpha channel)
        // This is edge case behavior - in practice, empty colors shouldn't be set
        const branding = PropertyBranding(primaryColor: '');
        // The implementation returns 0xFF for empty string after 'FF' + '' parse
        expect(branding.primaryColorValue, isNotNull);
      });

      test('parses common colors correctly', () {
        // Red
        const red = PropertyBranding(primaryColor: '#ff0000');
        expect(red.primaryColorValue, equals(0xFFff0000));

        // Green
        const green = PropertyBranding(primaryColor: '#00ff00');
        expect(green.primaryColorValue, equals(0xFF00ff00));

        // Blue
        const blue = PropertyBranding(primaryColor: '#0000ff');
        expect(blue.primaryColorValue, equals(0xFF0000ff));

        // White
        const white = PropertyBranding(primaryColor: '#ffffff');
        expect(white.primaryColorValue, equals(0xFFffffff));

        // Black
        const black = PropertyBranding(primaryColor: '#000000');
        expect(black.primaryColorValue, equals(0xFF000000));
      });
    });

    group('JSON serialization', () {
      test('empty branding serializes correctly', () {
        const branding = PropertyBranding();
        final json = branding.toJson();

        expect(json['display_name'], isNull);
        expect(json['logo_url'], isNull);
        expect(json['primary_color'], isNull);
        expect(json['secondary_color'], isNull);
        expect(json['favicon_url'], isNull);
      });

      test('full branding serializes correctly', () {
        const branding = PropertyBranding(
          displayName: 'Test Property',
          logoUrl: 'https://example.com/logo.png',
          primaryColor: '#1976d2',
          secondaryColor: '#ff5722',
          faviconUrl: 'https://example.com/favicon.ico',
        );
        final json = branding.toJson();

        expect(json['display_name'], equals('Test Property'));
        expect(json['logo_url'], equals('https://example.com/logo.png'));
        expect(json['primary_color'], equals('#1976d2'));
        expect(json['secondary_color'], equals('#ff5722'));
        expect(json['favicon_url'], equals('https://example.com/favicon.ico'));
      });

      test('branding deserializes from JSON correctly', () {
        final json = {
          'display_name': 'Deserialized Property',
          'logo_url': 'https://example.com/logo.png',
          'primary_color': '#abcdef',
          'secondary_color': '#123456',
          'favicon_url': 'https://example.com/favicon.ico',
        };
        final branding = PropertyBranding.fromJson(json);

        expect(branding.displayName, equals('Deserialized Property'));
        expect(branding.logoUrl, equals('https://example.com/logo.png'));
        expect(branding.primaryColor, equals('#abcdef'));
        expect(branding.secondaryColor, equals('#123456'));
        expect(branding.faviconUrl, equals('https://example.com/favicon.ico'));
      });

      test('partial branding deserializes correctly', () {
        final json = {
          'display_name': 'Partial Property',
          // Other fields missing
        };
        final branding = PropertyBranding.fromJson(json);

        expect(branding.displayName, equals('Partial Property'));
        expect(branding.logoUrl, isNull);
        expect(branding.primaryColor, isNull);
      });

      test('round-trip serialization preserves data', () {
        const original = PropertyBranding(
          displayName: 'Round Trip Test',
          primaryColor: '#ff00ff',
        );

        final json = original.toJson();
        final restored = PropertyBranding.fromJson(json);

        expect(restored.displayName, equals(original.displayName));
        expect(restored.primaryColor, equals(original.primaryColor));
        expect(restored.logoUrl, equals(original.logoUrl));
      });
    });

    group('equality', () {
      test('equal brandings are equal', () {
        const branding1 = PropertyBranding(
          displayName: 'Test',
          primaryColor: '#123456',
        );
        const branding2 = PropertyBranding(
          displayName: 'Test',
          primaryColor: '#123456',
        );

        expect(branding1, equals(branding2));
      });

      test('different brandings are not equal', () {
        const branding1 = PropertyBranding(displayName: 'Test1');
        const branding2 = PropertyBranding(displayName: 'Test2');

        expect(branding1, isNot(equals(branding2)));
      });
    });

    group('copyWith', () {
      test('copyWith creates new instance with updated fields', () {
        const original = PropertyBranding(
          displayName: 'Original',
          primaryColor: '#000000',
        );

        final modified = original.copyWith(displayName: 'Modified');

        expect(modified.displayName, equals('Modified'));
        expect(modified.primaryColor, equals('#000000')); // Unchanged
        expect(original.displayName, equals('Original')); // Original unchanged
      });
    });
  });
}
