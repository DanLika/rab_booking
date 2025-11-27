import 'package:flutter_test/flutter_test.dart';
import 'package:rab_booking/features/widget/domain/models/settings/contact_options.dart';

void main() {
  group('ContactOptions', () {
    group('constructor', () {
      test('creates with default values', () {
        const options = ContactOptions();

        expect(options.showPhone, true);
        expect(options.phoneNumber, isNull);
        expect(options.showEmail, true);
        expect(options.emailAddress, isNull);
        expect(options.showWhatsApp, false);
        expect(options.whatsAppNumber, isNull);
        expect(options.customMessage, isNull);
      });

      test('creates with custom values', () {
        const options = ContactOptions(
          showPhone: false,
          phoneNumber: '+385 91 123 4567',
          showEmail: false,
          emailAddress: 'test@example.com',
          showWhatsApp: true,
          whatsAppNumber: '+385 91 765 4321',
          customMessage: 'Contact us anytime!',
        );

        expect(options.showPhone, false);
        expect(options.phoneNumber, '+385 91 123 4567');
        expect(options.showEmail, false);
        expect(options.emailAddress, 'test@example.com');
        expect(options.showWhatsApp, true);
        expect(options.whatsAppNumber, '+385 91 765 4321');
        expect(options.customMessage, 'Contact us anytime!');
      });
    });

    group('fromMap', () {
      test('parses all fields from map', () {
        final map = {
          'show_phone': true,
          'phone_number': '+1 555 123 4567',
          'show_email': true,
          'email_address': 'owner@hotel.com',
          'show_whatsapp': true,
          'whatsapp_number': '+1 555 987 6543',
          'custom_message': 'We respond within 24 hours',
        };

        final options = ContactOptions.fromMap(map);

        expect(options.showPhone, true);
        expect(options.phoneNumber, '+1 555 123 4567');
        expect(options.showEmail, true);
        expect(options.emailAddress, 'owner@hotel.com');
        expect(options.showWhatsApp, true);
        expect(options.whatsAppNumber, '+1 555 987 6543');
        expect(options.customMessage, 'We respond within 24 hours');
      });

      test('uses defaults for missing fields', () {
        final options = ContactOptions.fromMap({});

        expect(options.showPhone, true);
        expect(options.phoneNumber, isNull);
        expect(options.showEmail, true);
        expect(options.emailAddress, isNull);
        expect(options.showWhatsApp, false);
        expect(options.whatsAppNumber, isNull);
        expect(options.customMessage, isNull);
      });
    });

    group('toMap', () {
      test('serializes all fields to map', () {
        const options = ContactOptions(
          showPhone: false,
          phoneNumber: '+44 20 1234 5678',
          showEmail: true,
          emailAddress: 'booking@property.com',
          showWhatsApp: true,
          whatsAppNumber: '+44 20 8765 4321',
          customMessage: 'Available 9am-6pm',
        );

        final map = options.toMap();

        expect(map['show_phone'], false);
        expect(map['phone_number'], '+44 20 1234 5678');
        expect(map['show_email'], true);
        expect(map['email_address'], 'booking@property.com');
        expect(map['show_whatsapp'], true);
        expect(map['whatsapp_number'], '+44 20 8765 4321');
        expect(map['custom_message'], 'Available 9am-6pm');
      });

      test('round-trips correctly through fromMap/toMap', () {
        const original = ContactOptions(
          showPhone: true,
          phoneNumber: '+385 91 111 2222',
          showEmail: false,
          emailAddress: 'round@trip.com',
          showWhatsApp: true,
          whatsAppNumber: '+385 91 333 4444',
          customMessage: 'Round trip test',
        );

        final restored = ContactOptions.fromMap(original.toMap());

        expect(restored, original);
      });
    });

    group('hasContactMethod', () {
      test('returns false when no contact methods configured', () {
        const options = ContactOptions(
          showPhone: true,
          phoneNumber: null, // No number
          showEmail: true,
          emailAddress: null, // No email
          showWhatsApp: false,
        );

        expect(options.hasContactMethod, false);
      });

      test('returns false when phone enabled but number is empty', () {
        const options = ContactOptions(
          showPhone: true,
          phoneNumber: '', // Empty string
          showEmail: false,
          showWhatsApp: false,
        );

        expect(options.hasContactMethod, false);
      });

      test('returns true when phone is configured', () {
        const options = ContactOptions(
          showPhone: true,
          phoneNumber: '+385 91 123 4567',
          showEmail: false,
          showWhatsApp: false,
        );

        expect(options.hasContactMethod, true);
      });

      test('returns true when email is configured', () {
        const options = ContactOptions(
          showPhone: false,
          showEmail: true,
          emailAddress: 'contact@example.com',
          showWhatsApp: false,
        );

        expect(options.hasContactMethod, true);
      });

      test('returns true when WhatsApp is configured', () {
        const options = ContactOptions(
          showPhone: false,
          showEmail: false,
          showWhatsApp: true,
          whatsAppNumber: '+385 91 999 8888',
        );

        expect(options.hasContactMethod, true);
      });

      test('returns true when multiple methods configured', () {
        const options = ContactOptions(
          showPhone: true,
          phoneNumber: '+385 91 111 2222',
          showEmail: true,
          emailAddress: 'multi@example.com',
          showWhatsApp: true,
          whatsAppNumber: '+385 91 333 4444',
        );

        expect(options.hasContactMethod, true);
      });
    });

    group('enabledMethods', () {
      test('returns empty list when no methods configured', () {
        const options = ContactOptions(
          showPhone: false,
          showEmail: false,
          showWhatsApp: false,
        );

        expect(options.enabledMethods, isEmpty);
      });

      test('returns phone when phone is configured', () {
        const options = ContactOptions(
          showPhone: true,
          phoneNumber: '+385 91 123 4567',
          showEmail: false,
          showWhatsApp: false,
        );

        expect(options.enabledMethods, ['phone']);
      });

      test('returns all methods when all configured', () {
        const options = ContactOptions(
          showPhone: true,
          phoneNumber: '+385 91 111 2222',
          showEmail: true,
          emailAddress: 'all@example.com',
          showWhatsApp: true,
          whatsAppNumber: '+385 91 333 4444',
        );

        expect(options.enabledMethods, ['phone', 'email', 'whatsapp']);
      });

      test('excludes methods with empty values', () {
        const options = ContactOptions(
          showPhone: true,
          phoneNumber: '', // Empty
          showEmail: true,
          emailAddress: 'valid@example.com',
          showWhatsApp: true,
          whatsAppNumber: null, // Null
        );

        expect(options.enabledMethods, ['email']);
      });
    });

    group('enabledMethodCount', () {
      test('returns 0 when no methods configured', () {
        const options = ContactOptions(
          showPhone: false,
          showEmail: false,
          showWhatsApp: false,
        );

        expect(options.enabledMethodCount, 0);
      });

      test('returns correct count for configured methods', () {
        const options = ContactOptions(
          showPhone: true,
          phoneNumber: '+385 91 111 2222',
          showEmail: true,
          emailAddress: 'count@example.com',
          showWhatsApp: false,
        );

        expect(options.enabledMethodCount, 2);
      });
    });

    group('copyWith', () {
      test('creates copy with updated fields', () {
        const original = ContactOptions(
          showPhone: true,
          phoneNumber: '+385 91 111 2222',
          showEmail: true,
        );

        final updated = original.copyWith(
          showPhone: false,
          emailAddress: 'new@email.com',
        );

        expect(updated.showPhone, false);
        expect(updated.phoneNumber, '+385 91 111 2222'); // unchanged
        expect(updated.showEmail, true); // unchanged
        expect(updated.emailAddress, 'new@email.com');
      });

      test('preserves all fields when no arguments provided', () {
        const original = ContactOptions(
          showPhone: false,
          phoneNumber: '+385 91 999 8888',
          showEmail: false,
          emailAddress: 'preserve@test.com',
          showWhatsApp: true,
          whatsAppNumber: '+385 91 777 6666',
          customMessage: 'Preserved message',
        );

        final copy = original.copyWith();

        expect(copy, original);
      });
    });

    group('equality', () {
      test('equal options are equal', () {
        const options1 = ContactOptions(
          showPhone: true,
          phoneNumber: '+385 91 123 4567',
          customMessage: 'Same message',
        );
        const options2 = ContactOptions(
          showPhone: true,
          phoneNumber: '+385 91 123 4567',
          customMessage: 'Same message',
        );

        expect(options1, options2);
        expect(options1.hashCode, options2.hashCode);
      });

      test('different options are not equal', () {
        const options1 = ContactOptions(phoneNumber: '+385 91 111 1111');
        const options2 = ContactOptions(phoneNumber: '+385 91 222 2222');

        expect(options1, isNot(options2));
      });
    });

    group('toString', () {
      test('returns readable string representation', () {
        const options = ContactOptions(
          showPhone: true,
          phoneNumber: '+385 91 123 4567',
          showEmail: true,
          emailAddress: 'test@test.com',
          showWhatsApp: false,
        );

        final str = options.toString();

        expect(str, contains('enabledMethods'));
        expect(str, contains('hasContactMethod: true'));
      });
    });
  });
}
