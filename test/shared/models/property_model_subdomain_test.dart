import 'package:flutter_test/flutter_test.dart';
import 'package:rab_booking/shared/models/property_model.dart';
import 'package:rab_booking/shared/models/property_branding_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PropertyModel subdomain features', () {
    late PropertyModel baseProperty;

    setUp(() {
      baseProperty = PropertyModel(
        id: 'prop-123',
        ownerId: 'owner-123',
        name: 'Villa Marija',
        description: 'Beautiful villa on Rab island',
        location: 'Rab, Croatia',
        createdAt: DateTime(2024, 1, 1),
      );
    });

    group('hasSubdomain', () {
      test('returns false when subdomain is null', () {
        expect(baseProperty.hasSubdomain, isFalse);
      });

      test('returns false when subdomain is empty', () {
        final property = baseProperty.copyWith(subdomain: '');
        expect(property.hasSubdomain, isFalse);
      });

      test('returns true when subdomain is set', () {
        final property = baseProperty.copyWith(subdomain: 'villa-marija');
        expect(property.hasSubdomain, isTrue);
      });
    });

    group('hasCustomBranding', () {
      test('returns false when branding is null', () {
        expect(baseProperty.hasCustomBranding, isFalse);
      });

      test('returns false when branding has no customizations', () {
        final property = baseProperty.copyWith(
          branding: const PropertyBranding(),
        );
        expect(property.hasCustomBranding, isFalse);
      });

      test('returns true when branding has displayName', () {
        final property = baseProperty.copyWith(
          branding: const PropertyBranding(displayName: 'Custom Name'),
        );
        expect(property.hasCustomBranding, isTrue);
      });

      test('returns true when branding has logoUrl', () {
        final property = baseProperty.copyWith(
          branding: const PropertyBranding(logoUrl: 'https://example.com/logo.png'),
        );
        expect(property.hasCustomBranding, isTrue);
      });

      test('returns true when branding has primaryColor', () {
        final property = baseProperty.copyWith(
          branding: const PropertyBranding(primaryColor: '#1976d2'),
        );
        expect(property.hasCustomBranding, isTrue);
      });
    });

    group('displayName', () {
      test('returns property name when no branding', () {
        expect(baseProperty.displayName, equals('Villa Marija'));
      });

      test('returns property name when branding has no displayName', () {
        final property = baseProperty.copyWith(
          branding: const PropertyBranding(primaryColor: '#1976d2'),
        );
        expect(property.displayName, equals('Villa Marija'));
      });

      test('returns branding displayName when set', () {
        final property = baseProperty.copyWith(
          branding: const PropertyBranding(displayName: 'Marija Luxury'),
        );
        expect(property.displayName, equals('Marija Luxury'));
      });
    });

    group('getSubdomainTestUrl', () {
      test('returns null when no subdomain', () {
        final url = baseProperty.getSubdomainTestUrl('https://widget.web.app');
        expect(url, isNull);
      });

      test('returns null when subdomain is empty', () {
        final property = baseProperty.copyWith(subdomain: '');
        final url = property.getSubdomainTestUrl('https://widget.web.app');
        expect(url, isNull);
      });

      test('returns correct URL when subdomain is set', () {
        final property = baseProperty.copyWith(subdomain: 'villa-marija');
        final url = property.getSubdomainTestUrl('https://widget.web.app');
        expect(url, equals('https://widget.web.app?subdomain=villa-marija'));
      });

      test('works with different base URLs', () {
        final property = baseProperty.copyWith(subdomain: 'test-prop');

        expect(
          property.getSubdomainTestUrl('https://localhost:5000'),
          equals('https://localhost:5000?subdomain=test-prop'),
        );

        expect(
          property.getSubdomainTestUrl('http://127.0.0.1:8080'),
          equals('http://127.0.0.1:8080?subdomain=test-prop'),
        );
      });
    });

    group('customDomain', () {
      test('customDomain is null by default', () {
        expect(baseProperty.customDomain, isNull);
      });

      test('customDomain can be set', () {
        final property = baseProperty.copyWith(
          customDomain: 'booking.villamarija.com',
        );
        expect(property.customDomain, equals('booking.villamarija.com'));
      });
    });

    group('JSON serialization with subdomain fields', () {
      test('subdomain field exists in model', () {
        final property = baseProperty.copyWith(subdomain: 'villa-marija');
        expect(property.subdomain, equals('villa-marija'));
      });

      test('branding field exists in model', () {
        final property = baseProperty.copyWith(
          branding: const PropertyBranding(
            displayName: 'Test Display',
            primaryColor: '#ff0000',
            logoUrl: 'https://example.com/logo.png',
          ),
        );

        expect(property.branding, isNotNull);
        expect(property.branding!.displayName, equals('Test Display'));
        expect(property.branding!.primaryColor, equals('#ff0000'));
        expect(property.branding!.logoUrl, equals('https://example.com/logo.png'));
      });

      test('customDomain field exists in model', () {
        final property = baseProperty.copyWith(
          customDomain: 'booking.example.com',
        );
        expect(property.customDomain, equals('booking.example.com'));
      });

      test('fromJson handles subdomain from raw JSON', () {
        final json = {
          'id': 'test-123',
          'owner_id': 'owner-123',
          'name': 'Test Property',
          'description': 'Test',
          'location': 'Rab',
          'subdomain': 'test-subdomain',
          'created_at': DateTime.now().toIso8601String(),
        };
        final property = PropertyModel.fromJson(json);
        expect(property.subdomain, equals('test-subdomain'));
      });
    });
  });
}
