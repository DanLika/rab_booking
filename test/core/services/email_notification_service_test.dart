import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'dart:convert';
import 'package:bookbed/core/services/email_notification_service.dart';
import 'package:bookbed/shared/models/booking_model.dart';
import 'package:bookbed/core/constants/enums.dart';
import 'package:bookbed/features/widget/domain/models/settings/email_notification_config.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  group('EmailNotificationService', () {
    late EmailNotificationService service;
    late MockHttpClient mockHttpClient;
    late EmailNotificationConfig testConfig;

    setUpAll(() {
      registerFallbackValue(Uri.parse('https://example.com'));
    });

    setUp(() {
      mockHttpClient = MockHttpClient();
      service = EmailNotificationService(httpClient: mockHttpClient);
      testConfig = EmailNotificationConfig(
        enabled: true,
        sendBookingConfirmation: true,
        sendPaymentReceipt: true,
        sendOwnerNotification: true,
        requireEmailVerification: false,
        resendApiKey: 'test-api-key',
        fromEmail: 'noreply@bookbed.app',
        fromName: 'BookBed',
      );
    });

    tearDown(() {
      service.dispose();
    });

    final defaultBooking = BookingModel(
      id: '1',
      unitId: 'unit1',
      checkIn: DateTime(2023, 1, 1),
      checkOut: DateTime(2023, 1, 5),
      status: BookingStatus.confirmed,
      guestEmail: 'guest@example.com',
      guestName: 'John Doe',
      guestPhone: '1234567890',
      totalPrice: 100.0,
      createdAt: DateTime(2023, 1, 1),
    );

    group('sendBookingConfirmationEmail', () {
      test('sends email when configured', () async {
        when(() => mockHttpClient.post(
              any(),
              headers: any(named: 'headers'),
              body: any(named: 'body'),
            )).thenAnswer((_) async => http.Response('{"id": "test_id"}', 200));

        await service.sendBookingConfirmationEmail(
          booking: defaultBooking,
          emailConfig: testConfig,
          propertyName: 'Test Property',
          bookingReference: 'REF-123',
        );

        final captured = verify(() => mockHttpClient.post(
              any(),
              headers: any(named: 'headers'),
              body: captureAny(named: 'body'),
            )).captured;

        expect(captured.length, 1);
        final bodyStr = captured.first as String;
        final body = json.decode(bodyStr);

        expect(body['to'], equals(['guest@example.com']));
        expect(body['from'], equals('BookBed <noreply@bookbed.app>'));
        expect(body['subject'], equals('Potvrda rezervacije - Test Property'));
        expect(body['html'], isNotNull);
        expect(body['html'], contains('John Doe'));
        expect(body['html'], contains('REF-123'));
      });

      test('skips when disabled in config', () async {
        final disabledConfig = EmailNotificationConfig(
          enabled: false,
          sendBookingConfirmation: true,
          sendPaymentReceipt: true,
          sendOwnerNotification: true,
          requireEmailVerification: false,
        );

        await service.sendBookingConfirmationEmail(
          booking: defaultBooking,
          emailConfig: disabledConfig,
          propertyName: 'Test Property',
          bookingReference: 'REF-123',
        );

        verifyNever(() => mockHttpClient.post(
              any(),
              headers: any(named: 'headers'),
              body: any(named: 'body'),
            ));
      });

      test('skips when sendBookingConfirmation is false', () async {
        final disabledFeatureConfig = EmailNotificationConfig(
          enabled: true,
          sendBookingConfirmation: false,
          sendPaymentReceipt: true,
          sendOwnerNotification: true,
          requireEmailVerification: false,
        );

        await service.sendBookingConfirmationEmail(
          booking: defaultBooking,
          emailConfig: disabledFeatureConfig,
          propertyName: 'Test Property',
          bookingReference: 'REF-123',
        );

        verifyNever(() => mockHttpClient.post(
              any(),
              headers: any(named: 'headers'),
              body: any(named: 'body'),
            ));
      });

      test('skips when config is not fully configured', () async {
        final incompleteConfig = EmailNotificationConfig(
          enabled: true,
          sendBookingConfirmation: true,
          sendPaymentReceipt: true,
          sendOwnerNotification: true,
          requireEmailVerification: false,
          resendApiKey: '', // Empty API key makes isConfigured false
          fromEmail: 'noreply@bookbed.app',
        );

        await service.sendBookingConfirmationEmail(
          booking: defaultBooking,
          emailConfig: incompleteConfig,
          propertyName: 'Test Property',
          bookingReference: 'REF-123',
        );

        verifyNever(() => mockHttpClient.post(
              any(),
              headers: any(named: 'headers'),
              body: any(named: 'body'),
            ));
      });

      test('handles API errors without throwing', () async {
        when(() => mockHttpClient.post(
              any(),
              headers: any(named: 'headers'),
              body: any(named: 'body'),
            )).thenAnswer((_) async => http.Response('Error', 500));

        // Should not throw
        await expectLater(
          service.sendBookingConfirmationEmail(
            booking: defaultBooking,
            emailConfig: testConfig,
            propertyName: 'Test Property',
            bookingReference: 'REF-123',
          ),
          completes,
        );
      });
    });

    group('sendPaymentReceiptEmail', () {
      test('sends email when configured', () async {
        when(() => mockHttpClient.post(
              any(),
              headers: any(named: 'headers'),
              body: any(named: 'body'),
            )).thenAnswer((_) async => http.Response('{"id": "test_id"}', 200));

        await service.sendPaymentReceiptEmail(
          booking: defaultBooking,
          emailConfig: testConfig,
          propertyName: 'Test Property',
          bookingReference: 'REF-123',
          paidAmount: 50.0,
          paymentMethod: 'Credit Card',
        );

        final captured = verify(() => mockHttpClient.post(
              any(),
              headers: any(named: 'headers'),
              body: captureAny(named: 'body'),
            )).captured;

        expect(captured.length, 1);
        final bodyStr = captured.first as String;
        final body = json.decode(bodyStr);

        expect(body['to'], equals(['guest@example.com']));
        expect(body['from'], equals('BookBed <noreply@bookbed.app>'));
        expect(body['subject'], equals('Potvrda plaćanja - Test Property'));
        expect(body['html'], isNotNull);
        expect(body['html'], contains('John Doe'));
        expect(body['html'], contains('REF-123'));
        expect(body['html'], contains('50.00'));
      });

      test('skips when sendPaymentReceipt is false', () async {
        final disabledFeatureConfig = EmailNotificationConfig(
          enabled: true,
          sendBookingConfirmation: true,
          sendPaymentReceipt: false,
          sendOwnerNotification: true,
          requireEmailVerification: false,
        );

        await service.sendPaymentReceiptEmail(
          booking: defaultBooking,
          emailConfig: disabledFeatureConfig,
          propertyName: 'Test Property',
          bookingReference: 'REF-123',
          paidAmount: 50.0,
          paymentMethod: 'Credit Card',
        );

        verifyNever(() => mockHttpClient.post(
              any(),
              headers: any(named: 'headers'),
              body: any(named: 'body'),
            ));
      });
    });

    group('sendOwnerNotificationEmail', () {
      test('sends email when configured', () async {
        when(() => mockHttpClient.post(
              any(),
              headers: any(named: 'headers'),
              body: any(named: 'body'),
            )).thenAnswer((_) async => http.Response('{"id": "test_id"}', 200));

        await service.sendOwnerNotificationEmail(
          booking: defaultBooking,
          emailConfig: testConfig,
          propertyName: 'Test Property',
          bookingReference: 'REF-123',
          ownerEmail: 'owner@example.com',
          requiresApproval: true,
        );

        final captured = verify(() => mockHttpClient.post(
              any(),
              headers: any(named: 'headers'),
              body: captureAny(named: 'body'),
            )).captured;

        expect(captured.length, 1);
        final bodyStr = captured.first as String;
        final body = json.decode(bodyStr);

        expect(body['to'], equals(['owner@example.com']));
        expect(body['from'], equals('BookBed <noreply@bookbed.app>'));
        expect(body['subject'], equals('Nova rezervacija zahteva potvrdu - Test Property'));
        expect(body['html'], isNotNull);
        expect(body['html'], contains('John Doe'));
        expect(body['html'], contains('REF-123'));
      });

      test('sends regular email when approval is not required', () async {
        when(() => mockHttpClient.post(
              any(),
              headers: any(named: 'headers'),
              body: any(named: 'body'),
            )).thenAnswer((_) async => http.Response('{"id": "test_id"}', 200));

        await service.sendOwnerNotificationEmail(
          booking: defaultBooking,
          emailConfig: testConfig,
          propertyName: 'Test Property',
          bookingReference: 'REF-123',
          ownerEmail: 'owner@example.com',
          requiresApproval: false,
        );

        final captured = verify(() => mockHttpClient.post(
              any(),
              headers: any(named: 'headers'),
              body: captureAny(named: 'body'),
            )).captured;

        expect(captured.length, 1);
        final bodyStr = captured.first as String;
        final body = json.decode(bodyStr);
        expect(body['subject'], equals('Nova rezervacija - Test Property'));
      });

      test('skips when sendOwnerNotification is false', () async {
        final disabledFeatureConfig = EmailNotificationConfig(
          enabled: true,
          sendBookingConfirmation: true,
          sendPaymentReceipt: true,
          sendOwnerNotification: false,
          requireEmailVerification: false,
        );

        await service.sendOwnerNotificationEmail(
          booking: defaultBooking,
          emailConfig: disabledFeatureConfig,
          propertyName: 'Test Property',
          bookingReference: 'REF-123',
          ownerEmail: 'owner@example.com',
        );

        verifyNever(() => mockHttpClient.post(
              any(),
              headers: any(named: 'headers'),
              body: any(named: 'body'),
            ));
      });
    });
  });
}
