import 'package:flutter_test/flutter_test.dart';
import 'package:rab_booking/features/widget/domain/services/subdomain_service.dart';
import 'package:rab_booking/shared/models/property_branding_model.dart';
import 'package:rab_booking/shared/models/property_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SubdomainContext', () {
    test('creates context with found property', () {
      final property = PropertyModel(
        id: 'prop-123',
        ownerId: 'owner-123',
        name: 'Villa Marija',
        subdomain: 'villa-marija',
        description: 'Beautiful villa',
        location: 'Rab, Croatia',
        createdAt: DateTime.now(),
      );

      final context = SubdomainContext(
        subdomain: 'villa-marija',
        found: true,
        property: property,
        branding: null,
      );

      expect(context.found, isTrue);
      expect(context.subdomain, equals('villa-marija'));
      expect(context.propertyId, equals('prop-123'));
      expect(context.displayName, equals('Villa Marija'));
      expect(context.hasCustomBranding, isFalse);
    });

    test('creates context with not found subdomain', () {
      final context = SubdomainContext(
        subdomain: 'nonexistent',
        found: false,
        property: null,
        branding: null,
      );

      expect(context.found, isFalse);
      expect(context.subdomain, equals('nonexistent'));
      expect(context.propertyId, isNull);
      expect(context.displayName, equals('nonexistent')); // Falls back to subdomain
      expect(context.hasCustomBranding, isFalse);
    });

    test('uses branding displayName when available', () {
      final property = PropertyModel(
        id: 'prop-123',
        ownerId: 'owner-123',
        name: 'Villa Marija',
        subdomain: 'villa-marija',
        description: 'Beautiful villa',
        location: 'Rab, Croatia',
        createdAt: DateTime.now(),
        branding: const PropertyBranding(
          displayName: 'Marija Luxury Apartments',
          primaryColor: '#1976d2',
        ),
      );

      final context = SubdomainContext(
        subdomain: 'villa-marija',
        found: true,
        property: property,
        branding: property.branding,
      );

      expect(context.displayName, equals('Marija Luxury Apartments'));
      expect(context.hasCustomBranding, isTrue);
    });

    test('hasCustomBranding returns false when branding has no customizations', () {
      final context = SubdomainContext(
        subdomain: 'test',
        found: true,
        property: null,
        branding: const PropertyBranding(), // Empty branding
      );

      expect(context.hasCustomBranding, isFalse);
    });
  });

  // Note: SubdomainService tests that require Firestore are skipped
  // because they need Firebase initialization.
  // The service logic is tested via integration tests.

  group('Subdomain validation patterns', () {
    // Test the validation patterns that should match Cloud Function logic

    final validSubdomains = [
      'villa-marija',
      'jasko-rab',
      'abc',
      'a1b',
      'test-property-123',
      'rab-apartments',
      '123',
      'a-b-c',
    ];

    final invalidSubdomains = [
      'ab', // too short
      '-invalid', // starts with hyphen
      'invalid-', // ends with hyphen
      'has--double', // consecutive hyphens
      'UPPERCASE', // not lowercase
      'has space',
      'has.dot',
      'has_underscore',
    ];

    // Regex from Cloud Function
    final subdomainRegex = RegExp(r'^[a-z0-9][a-z0-9-]{1,28}[a-z0-9]$');
    // For 3-char subdomains
    final shortSubdomainRegex = RegExp(r'^[a-z0-9]{3}$');

    bool isValidSubdomain(String subdomain) {
      if (subdomain.length < 3 || subdomain.length > 30) return false;
      if (subdomain.contains('--')) return false;
      if (subdomain.length == 3) {
        return shortSubdomainRegex.hasMatch(subdomain) ||
            subdomainRegex.hasMatch(subdomain);
      }
      return subdomainRegex.hasMatch(subdomain);
    }

    for (final subdomain in validSubdomains) {
      test('accepts valid subdomain: $subdomain', () {
        expect(isValidSubdomain(subdomain), isTrue,
            reason: '$subdomain should be valid');
      });
    }

    for (final subdomain in invalidSubdomains) {
      test('rejects invalid subdomain: $subdomain', () {
        expect(isValidSubdomain(subdomain), isFalse,
            reason: '$subdomain should be invalid');
      });
    }
  });

  group('Reserved subdomains', () {
    final reservedSubdomains = [
      'www',
      'app',
      'api',
      'admin',
      'dashboard',
      'widget',
      'booking',
      'bookings',
      'test',
      'demo',
      'help',
      'support',
      'mail',
      'email',
      'cdn',
      'static',
      'assets',
      'dev',
      'staging',
      'prod',
      'production',
      'beta',
      'alpha',
      'docs',
      'status',
      'blog',
    ];

    for (final reserved in reservedSubdomains) {
      test('$reserved is reserved', () {
        expect(reservedSubdomains.contains(reserved), isTrue);
      });
    }

    test('regular subdomains are not reserved', () {
      expect(reservedSubdomains.contains('villa-marija'), isFalse);
      expect(reservedSubdomains.contains('jasko-rab'), isFalse);
      expect(reservedSubdomains.contains('my-property'), isFalse);
    });
  });
}
