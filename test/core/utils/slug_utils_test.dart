import 'package:flutter_test/flutter_test.dart';
import 'package:bookbed/core/utils/slug_utils.dart';

void main() {
  group('generateSlug', () {
    test('converts basic string to slug', () {
      expect(generateSlug('Villa Jasko'), 'villa-jasko');
      expect(generateSlug('Apartman 6'), 'apartman-6');
    });

    test('handles Croatian special characters', () {
      expect(generateSlug('Češka šuma'), 'ceska-suma');
      expect(generateSlug('Đuro Đaković'), 'duro-dakovic');
    });

    test('handles special characters and removes them', () {
      expect(
        generateSlug('Studio Apartment - Luxury!'),
        'studio-apartment-luxury',
      );
      expect(generateSlug('Suite #5 (Déluxe)'), 'suite-5-deluxe');
    });

    test('removes consecutive hyphens', () {
      expect(generateSlug('Villa   -   Jasko'), 'villa-jasko');
    });

    test('truncates to max length', () {
      final longName =
          'This is a very long property name that exceeds the maximum length';
      final slug = generateSlug(longName, maxLength: 30);
      expect(slug.length, lessThanOrEqualTo(30));
      expect(slug, 'this-is-a-very-long-property');
    });

    test('returns empty string for empty input', () {
      expect(generateSlug(''), '');
    });
  });

  group('generateHybridSlug', () {
    test('creates hybrid slug with short ID', () {
      final slug = generateHybridSlug('apartman-6', 'gMIOos56siO74VkCsSwY');
      expect(slug, 'apartman-6-gMIOos');
    });

    test('handles short unit IDs', () {
      final slug = generateHybridSlug('villa', 'abc123');
      expect(slug, 'villa-abc123');
    });

    test('throws on empty inputs', () {
      expect(
        () => generateHybridSlug('', 'abc123'),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => generateHybridSlug('slug', ''),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('parseShortIdFromHybridSlug', () {
    test('extracts short ID from hybrid slug', () {
      expect(parseShortIdFromHybridSlug('apartman-6-gMIOos'), 'gMIOos');
      expect(parseShortIdFromHybridSlug('villa-jasko-abc123'), 'abc123');
    });

    test('returns null for invalid slugs', () {
      expect(parseShortIdFromHybridSlug(''), null);
      expect(parseShortIdFromHybridSlug('invalid'), null);
      expect(parseShortIdFromHybridSlug('no-id-here-ab'), null); // Too short
    });
  });

  group('isValidSlug', () {
    test('validates correct slug formats', () {
      expect(isValidSlug('villa-jasko'), true);
      expect(isValidSlug('apartman-6'), true);
      expect(isValidSlug('studio-123'), true);
    });

    test('rejects invalid formats', () {
      expect(isValidSlug(''), false);
      expect(isValidSlug('Villa Jasko'), false); // Uppercase
      expect(isValidSlug('villa--jasko'), false); // Double hyphen
      expect(isValidSlug('-villa'), false); // Leading hyphen
      expect(isValidSlug('villa-'), false); // Trailing hyphen
      expect(isValidSlug('villa_jasko'), false); // Underscore
    });
  });
}
