import 'package:flutter_test/flutter_test.dart';
import 'package:bookbed/features/widget/presentation/models/booking_confirmation_data.dart';
import 'package:bookbed/shared/models/booking_model.dart';
import 'package:bookbed/features/widget/domain/models/widget_settings.dart';
import 'package:bookbed/features/widget/domain/models/settings/contact_options.dart';
import 'package:bookbed/features/widget/domain/models/settings/email_notification_config.dart';
import 'package:bookbed/features/widget/domain/models/settings/tax_legal_config.dart';
import 'package:bookbed/core/constants/enums.dart';

void main() {
  group('BookingConfirmationData', () {
    final testBooking = BookingModel(
      id: 'test-booking-id',
      propertyId: 'test-property-id',
      unitId: 'test-unit-id',
      ownerId: 'test-owner-id',
      checkIn: DateTime(2025, 1, 15),
      checkOut: DateTime(2025, 1, 20),
      guestCount: 2,
      totalPrice: 500.0,
      status: BookingStatus.confirmed,
      createdAt: DateTime(2025, 1, 1),
    );

    final testEmailConfig = EmailNotificationConfig(enabled: true, sendBookingConfirmation: true);

    final testWidgetSettings = WidgetSettings(
      id: 'test-unit-id',
      propertyId: 'test-property-id',
      ownerId: 'test-owner-id',
      contactOptions: const ContactOptions(),
      emailConfig: const EmailNotificationConfig(),
      taxLegalConfig: const TaxLegalConfig(),
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
    );

    final baseData = BookingConfirmationData(
      bookingReference: 'BK-123',
      guestEmail: 'guest@example.com',
      guestName: 'John Doe',
      checkIn: DateTime(2025, 1, 15),
      checkOut: DateTime(2025, 1, 20),
      totalPrice: 500.0,
      nights: 5,
      guests: 2,
      propertyName: 'Beach Villa',
      unitName: 'Unit A',
      paymentMethod: 'stripe',
      booking: testBooking,
      emailConfig: testEmailConfig,
      widgetSettings: testWidgetSettings,
      propertyId: 'test-property-id',
      unitId: 'test-unit-id',
    );

    group('copyWith', () {
      test('creates copy with updated required fields', () {
        final updated = baseData.copyWith(
          bookingReference: 'BK-456',
          guestEmail: 'new@example.com',
          propertyName: 'Mountain Villa',
        );

        expect(updated.bookingReference, 'BK-456');
        expect(updated.guestEmail, 'new@example.com');
        expect(updated.propertyName, 'Mountain Villa');
        expect(updated.unitName, 'Unit A'); // Unchanged
        expect(updated.booking, testBooking); // Unchanged
      });

      test('preserves all fields when no arguments provided', () {
        final copy = baseData.copyWith();

        expect(copy.bookingReference, baseData.bookingReference);
        expect(copy.guestEmail, baseData.guestEmail);
        expect(copy.guestName, baseData.guestName);
        expect(copy.checkIn, baseData.checkIn);
        expect(copy.checkOut, baseData.checkOut);
        expect(copy.totalPrice, baseData.totalPrice);
        expect(copy.nights, baseData.nights);
        expect(copy.guests, baseData.guests);
        expect(copy.propertyName, baseData.propertyName);
        expect(copy.unitName, baseData.unitName);
        expect(copy.paymentMethod, baseData.paymentMethod);
        expect(copy.booking, baseData.booking);
        expect(copy.emailConfig, baseData.emailConfig);
        expect(copy.widgetSettings, baseData.widgetSettings);
        expect(copy.propertyId, baseData.propertyId);
        expect(copy.unitId, baseData.unitId);
      });

      test('explicitly sets nullable fields to null', () {
        final updated = baseData.copyWith(
          unitName: null,
          booking: null,
          emailConfig: null,
          widgetSettings: null,
          propertyId: null,
          unitId: null,
        );

        expect(updated.unitName, isNull);
        expect(updated.booking, isNull);
        expect(updated.emailConfig, isNull);
        expect(updated.widgetSettings, isNull);
        expect(updated.propertyId, isNull);
        expect(updated.unitId, isNull);

        // Required fields should remain unchanged
        expect(updated.bookingReference, baseData.bookingReference);
        expect(updated.propertyName, baseData.propertyName);
      });

      test('updates nullable fields to new values', () {
        final newBooking = BookingModel(
          id: 'new-booking-id',
          propertyId: 'new-property-id',
          unitId: 'new-unit-id',
          ownerId: 'new-owner-id',
          checkIn: DateTime(2025, 2, 1),
          checkOut: DateTime(2025, 2, 5),
          guestCount: 4,
          totalPrice: 800.0,
          status: BookingStatus.pending,
          createdAt: DateTime(2025, 1, 15),
        );

        final newEmailConfig = EmailNotificationConfig(enabled: false, sendBookingConfirmation: false);

        final updated = baseData.copyWith(
          unitName: 'Unit B',
          booking: newBooking,
          emailConfig: newEmailConfig,
          propertyId: 'new-property-id',
          unitId: 'new-unit-id',
        );

        expect(updated.unitName, 'Unit B');
        expect(updated.booking, newBooking);
        expect(updated.emailConfig, newEmailConfig);
        expect(updated.propertyId, 'new-property-id');
        expect(updated.unitId, 'new-unit-id');
      });

      test('can set nullable field to null when it was previously null', () {
        final dataWithNulls = baseData.copyWith(unitName: null, booking: null);

        // Setting to null again should work
        final stillNull = dataWithNulls.copyWith(unitName: null, booking: null);

        expect(stillNull.unitName, isNull);
        expect(stillNull.booking, isNull);
      });

      test('can set nullable field to null and then back to a value', () {
        // First set to null
        final nulled = baseData.copyWith(unitName: null);
        expect(nulled.unitName, isNull);

        // Then set back to a value
        final restored = nulled.copyWith(unitName: 'Unit C');
        expect(restored.unitName, 'Unit C');
      });
    });

    group('fromBooking', () {
      test('creates BookingConfirmationData from BookingModel', () {
        final data = BookingConfirmationData.fromBooking(
          booking: testBooking,
          propertyName: 'Test Property',
          unitName: 'Test Unit',
        );

        expect(data.bookingReference, testBooking.id);
        expect(data.guestEmail, '');
        expect(data.guestName, '');
        expect(data.checkIn, testBooking.checkIn);
        expect(data.checkOut, testBooking.checkOut);
        expect(data.totalPrice, testBooking.totalPrice);
        expect(data.nights, 5);
        expect(data.guests, testBooking.guestCount);
        expect(data.propertyName, 'Test Property');
        expect(data.unitName, 'Test Unit');
        expect(data.paymentMethod, 'unknown');
        expect(data.booking, testBooking);
      });
    });
  });
}
