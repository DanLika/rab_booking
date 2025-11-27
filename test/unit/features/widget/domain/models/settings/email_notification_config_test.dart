import 'package:flutter_test/flutter_test.dart';
import 'package:rab_booking/features/widget/domain/models/settings/email_notification_config.dart';

void main() {
  group('EmailNotificationConfig', () {
    group('constructor', () {
      test('creates with default values', () {
        const config = EmailNotificationConfig();

        expect(config.enabled, false);
        expect(config.sendBookingConfirmation, true);
        expect(config.sendPaymentReceipt, true);
        expect(config.sendOwnerNotification, true);
        expect(config.requireEmailVerification, false);
        expect(config.resendApiKey, isNull);
        expect(config.fromEmail, isNull);
        expect(config.fromName, isNull);
      });

      test('creates with custom values', () {
        const config = EmailNotificationConfig(
          enabled: true,
          sendBookingConfirmation: false,
          sendPaymentReceipt: false,
          sendOwnerNotification: false,
          requireEmailVerification: true,
          resendApiKey: 'test-api-key',
          fromEmail: 'noreply@test.com',
          fromName: 'Test Property',
        );

        expect(config.enabled, true);
        expect(config.sendBookingConfirmation, false);
        expect(config.sendPaymentReceipt, false);
        expect(config.sendOwnerNotification, false);
        expect(config.requireEmailVerification, true);
        expect(config.resendApiKey, 'test-api-key');
        expect(config.fromEmail, 'noreply@test.com');
        expect(config.fromName, 'Test Property');
      });
    });

    group('fromMap', () {
      test('parses all fields from map', () {
        final map = {
          'enabled': true,
          'send_booking_confirmation': false,
          'send_payment_receipt': false,
          'send_owner_notification': false,
          'require_email_verification': true,
          'resend_api_key': 'api-key-123',
          'from_email': 'booking@example.com',
          'from_name': 'Example Hotel',
        };

        final config = EmailNotificationConfig.fromMap(map);

        expect(config.enabled, true);
        expect(config.sendBookingConfirmation, false);
        expect(config.sendPaymentReceipt, false);
        expect(config.sendOwnerNotification, false);
        expect(config.requireEmailVerification, true);
        expect(config.resendApiKey, 'api-key-123');
        expect(config.fromEmail, 'booking@example.com');
        expect(config.fromName, 'Example Hotel');
      });

      test('uses defaults for missing fields', () {
        final config = EmailNotificationConfig.fromMap({});

        expect(config.enabled, false);
        expect(config.sendBookingConfirmation, true);
        expect(config.sendPaymentReceipt, true);
        expect(config.sendOwnerNotification, true);
        expect(config.requireEmailVerification, false);
        expect(config.resendApiKey, isNull);
        expect(config.fromEmail, isNull);
        expect(config.fromName, isNull);
      });
    });

    group('toMap', () {
      test('serializes all fields to map', () {
        const config = EmailNotificationConfig(
          enabled: true,
          sendBookingConfirmation: true,
          sendPaymentReceipt: false,
          sendOwnerNotification: true,
          requireEmailVerification: true,
          resendApiKey: 'my-api-key',
          fromEmail: 'test@test.com',
          fromName: 'Test Name',
        );

        final map = config.toMap();

        expect(map['enabled'], true);
        expect(map['send_booking_confirmation'], true);
        expect(map['send_payment_receipt'], false);
        expect(map['send_owner_notification'], true);
        expect(map['require_email_verification'], true);
        expect(map['resend_api_key'], 'my-api-key');
        expect(map['from_email'], 'test@test.com');
        expect(map['from_name'], 'Test Name');
      });

      test('round-trips correctly through fromMap/toMap', () {
        const original = EmailNotificationConfig(
          enabled: true,
          sendBookingConfirmation: false,
          sendPaymentReceipt: true,
          sendOwnerNotification: false,
          requireEmailVerification: true,
          resendApiKey: 'round-trip-key',
          fromEmail: 'round@trip.com',
          fromName: 'Round Trip',
        );

        final restored = EmailNotificationConfig.fromMap(original.toMap());

        expect(restored, original);
      });
    });

    group('isConfigured', () {
      test('returns false when disabled', () {
        const config = EmailNotificationConfig(
          enabled: false,
          resendApiKey: 'key',
          fromEmail: 'email@test.com',
        );

        expect(config.isConfigured, false);
      });

      test('returns false when API key is missing', () {
        const config = EmailNotificationConfig(
          enabled: true,
          resendApiKey: null,
          fromEmail: 'email@test.com',
        );

        expect(config.isConfigured, false);
      });

      test('returns false when from email is missing', () {
        const config = EmailNotificationConfig(
          enabled: true,
          resendApiKey: 'key',
          fromEmail: null,
        );

        expect(config.isConfigured, false);
      });

      test('returns true when fully configured', () {
        const config = EmailNotificationConfig(
          enabled: true,
          resendApiKey: 'key',
          fromEmail: 'email@test.com',
        );

        expect(config.isConfigured, true);
      });
    });

    group('copyWith', () {
      test('creates copy with updated fields', () {
        const original = EmailNotificationConfig(
          enabled: false,
          sendBookingConfirmation: true,
          resendApiKey: 'old-key',
        );

        final updated = original.copyWith(
          enabled: true,
          resendApiKey: 'new-key',
          fromEmail: 'new@email.com',
        );

        expect(updated.enabled, true);
        expect(updated.sendBookingConfirmation, true); // unchanged
        expect(updated.resendApiKey, 'new-key');
        expect(updated.fromEmail, 'new@email.com');
      });

      test('preserves all fields when no arguments provided', () {
        const original = EmailNotificationConfig(
          enabled: true,
          sendBookingConfirmation: false,
          sendPaymentReceipt: false,
          sendOwnerNotification: false,
          requireEmailVerification: true,
          resendApiKey: 'preserve-key',
          fromEmail: 'preserve@test.com',
          fromName: 'Preserve Name',
        );

        final copy = original.copyWith();

        expect(copy, original);
      });
    });

    group('equality', () {
      test('equal configs are equal', () {
        const config1 = EmailNotificationConfig(
          enabled: true,
          resendApiKey: 'key',
          fromEmail: 'test@test.com',
        );
        const config2 = EmailNotificationConfig(
          enabled: true,
          resendApiKey: 'key',
          fromEmail: 'test@test.com',
        );

        expect(config1, config2);
        expect(config1.hashCode, config2.hashCode);
      });

      test('different configs are not equal', () {
        const config1 = EmailNotificationConfig(enabled: true);
        const config2 = EmailNotificationConfig(enabled: false);

        expect(config1, isNot(config2));
      });
    });

    group('toString', () {
      test('returns readable string representation', () {
        const config = EmailNotificationConfig(
          enabled: true,
          resendApiKey: 'key',
          fromEmail: 'test@test.com',
        );

        expect(
          config.toString(),
          'EmailNotificationConfig(enabled: true, isConfigured: true)',
        );
      });
    });
  });
}
