import 'package:flutter_test/flutter_test.dart';
import 'package:rab_booking/features/widget/domain/models/widget_mode.dart';
import 'package:rab_booking/features/widget/domain/models/widget_settings.dart';
import 'package:rab_booking/features/widget/domain/services/booking_validation_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('ValidationResult', () {
    test('success creates valid result', () {
      const result = ValidationResult.success();
      expect(result.isValid, isTrue);
      expect(result.errorMessage, isNull);
      expect(result.isWarning, isFalse);
    });

    test('failure creates invalid result with message', () {
      const result = ValidationResult.failure('Test error');
      expect(result.isValid, isFalse);
      expect(result.errorMessage, equals('Test error'));
      expect(result.isWarning, isFalse);
    });

    test('warning creates valid result with warning flag', () {
      const result = ValidationResult.warning('Test warning');
      expect(result.isValid, isTrue);
      expect(result.errorMessage, equals('Test warning'));
      expect(result.isWarning, isTrue);
    });

    test('failure supports custom snackbar duration', () {
      const result = ValidationResult.failure(
        'Error',
        snackBarDuration: Duration(seconds: 10),
      );
      expect(result.snackBarDuration, equals(const Duration(seconds: 10)));
    });
  });

  group('BookingValidationService.validateEmailVerification', () {
    test('returns success when verification not required', () {
      final result = BookingValidationService.validateEmailVerification(
        requireEmailVerification: false,
        emailVerified: false,
      );
      expect(result.isValid, isTrue);
    });

    test('returns success when required and verified', () {
      final result = BookingValidationService.validateEmailVerification(
        requireEmailVerification: true,
        emailVerified: true,
      );
      expect(result.isValid, isTrue);
    });

    test('returns failure when required but not verified', () {
      final result = BookingValidationService.validateEmailVerification(
        requireEmailVerification: true,
        emailVerified: false,
      );
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('verify your email'));
    });
  });

  group('BookingValidationService.validateTaxLegal', () {
    test('returns success when config is null', () {
      final result = BookingValidationService.validateTaxLegal(
        taxConfig: null,
        taxLegalAccepted: false,
      );
      expect(result.isValid, isTrue);
    });

    test('returns success when config disabled', () {
      final result = BookingValidationService.validateTaxLegal(
        taxConfig: const TaxLegalConfig(enabled: false),
        taxLegalAccepted: false,
      );
      expect(result.isValid, isTrue);
    });

    test('returns success when enabled and accepted', () {
      final result = BookingValidationService.validateTaxLegal(
        taxConfig: const TaxLegalConfig(enabled: true),
        taxLegalAccepted: true,
      );
      expect(result.isValid, isTrue);
    });

    test('returns failure when enabled but not accepted', () {
      final result = BookingValidationService.validateTaxLegal(
        taxConfig: const TaxLegalConfig(enabled: true),
        taxLegalAccepted: false,
      );
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('tax and legal'));
    });
  });

  group('BookingValidationService.validateDates', () {
    test('returns failure when checkIn is null', () {
      final result = BookingValidationService.validateDates(
        checkIn: null,
        checkOut: DateTime.now(),
      );
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('select check-in'));
    });

    test('returns failure when checkOut is null', () {
      final result = BookingValidationService.validateDates(
        checkIn: DateTime.now(),
        checkOut: null,
      );
      expect(result.isValid, isFalse);
    });

    test('returns failure when checkOut is before checkIn', () {
      final checkIn = DateTime(2025, 1, 15);
      final checkOut = DateTime(2025, 1, 10);
      final result = BookingValidationService.validateDates(
        checkIn: checkIn,
        checkOut: checkOut,
      );
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('after check-in'));
    });

    test('returns failure when checkOut equals checkIn', () {
      final date = DateTime(2025, 1, 15);
      final result = BookingValidationService.validateDates(
        checkIn: date,
        checkOut: date,
      );
      expect(result.isValid, isFalse);
    });

    test('returns success when checkOut is after checkIn', () {
      final checkIn = DateTime(2025, 1, 15);
      final checkOut = DateTime(2025, 1, 20);
      final result = BookingValidationService.validateDates(
        checkIn: checkIn,
        checkOut: checkOut,
      );
      expect(result.isValid, isTrue);
    });
  });

  group('BookingValidationService.validatePropertyOwner', () {
    test('returns failure when propertyId is null', () {
      final result = BookingValidationService.validatePropertyOwner(
        propertyId: null,
        ownerId: 'owner123',
      );
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('Property information'));
    });

    test('returns failure when ownerId is null', () {
      final result = BookingValidationService.validatePropertyOwner(
        propertyId: 'prop123',
        ownerId: null,
      );
      expect(result.isValid, isFalse);
    });

    test('returns success when both IDs are present', () {
      final result = BookingValidationService.validatePropertyOwner(
        propertyId: 'prop123',
        ownerId: 'owner123',
      );
      expect(result.isValid, isTrue);
    });
  });

  group('BookingValidationService.validatePaymentMethod', () {
    WidgetSettings createTestSettings({
      bool stripeEnabled = false,
      bool bankTransferEnabled = false,
      bool allowPayOnArrival = false,
    }) {
      return WidgetSettings(
        id: 'unit1',
        propertyId: 'prop1',
        widgetMode: WidgetMode.bookingInstant,
        stripeConfig: StripePaymentConfig(enabled: stripeEnabled),
        bankTransferConfig: BankTransferConfig(enabled: bankTransferEnabled),
        allowPayOnArrival: allowPayOnArrival,
        contactOptions: const ContactOptions(),
        emailConfig: const EmailNotificationConfig(),
        taxLegalConfig: const TaxLegalConfig(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    test('returns success for bookingPending mode regardless of settings', () {
      final result = BookingValidationService.validatePaymentMethod(
        widgetMode: WidgetMode.bookingPending,
        selectedPaymentMethod: 'anything',
        widgetSettings: null,
      );
      expect(result.isValid, isTrue);
    });

    test('returns failure when no payment methods enabled', () {
      final settings = createTestSettings();
      final result = BookingValidationService.validatePaymentMethod(
        widgetMode: WidgetMode.bookingInstant,
        selectedPaymentMethod: 'stripe',
        widgetSettings: settings,
      );
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('No payment methods'));
    });

    test('returns failure when selected stripe but not enabled', () {
      final settings = createTestSettings(bankTransferEnabled: true);
      final result = BookingValidationService.validatePaymentMethod(
        widgetMode: WidgetMode.bookingInstant,
        selectedPaymentMethod: 'stripe',
        widgetSettings: settings,
      );
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('Stripe payment is not available'));
    });

    test('returns failure when selected bank_transfer but not enabled', () {
      final settings = createTestSettings(stripeEnabled: true);
      final result = BookingValidationService.validatePaymentMethod(
        widgetMode: WidgetMode.bookingInstant,
        selectedPaymentMethod: 'bank_transfer',
        widgetSettings: settings,
      );
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('Bank transfer is not available'));
    });

    test('returns failure when selected pay_on_arrival but not enabled', () {
      final settings = createTestSettings(stripeEnabled: true);
      final result = BookingValidationService.validatePaymentMethod(
        widgetMode: WidgetMode.bookingInstant,
        selectedPaymentMethod: 'pay_on_arrival',
        widgetSettings: settings,
      );
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('Pay on arrival is not available'));
    });

    test('returns success when selected method is enabled', () {
      final settings = createTestSettings(stripeEnabled: true);
      final result = BookingValidationService.validatePaymentMethod(
        widgetMode: WidgetMode.bookingInstant,
        selectedPaymentMethod: 'stripe',
        widgetSettings: settings,
      );
      expect(result.isValid, isTrue);
    });

    test('returns success when bank_transfer selected and enabled', () {
      final settings = createTestSettings(bankTransferEnabled: true);
      final result = BookingValidationService.validatePaymentMethod(
        widgetMode: WidgetMode.bookingInstant,
        selectedPaymentMethod: 'bank_transfer',
        widgetSettings: settings,
      );
      expect(result.isValid, isTrue);
    });

    test('returns success when pay_on_arrival selected and enabled', () {
      final settings = createTestSettings(allowPayOnArrival: true);
      final result = BookingValidationService.validatePaymentMethod(
        widgetMode: WidgetMode.bookingInstant,
        selectedPaymentMethod: 'pay_on_arrival',
        widgetSettings: settings,
      );
      expect(result.isValid, isTrue);
    });
  });

  group('BookingValidationService.validateGuestCount', () {
    test('returns success when within capacity', () {
      final result = BookingValidationService.validateGuestCount(
        adults: 2,
        children: 1,
        maxGuests: 4,
      );
      expect(result.isValid, isTrue);
    });

    test('returns success when at max capacity', () {
      final result = BookingValidationService.validateGuestCount(
        adults: 2,
        children: 2,
        maxGuests: 4,
      );
      expect(result.isValid, isTrue);
    });

    test('returns failure when over capacity', () {
      final result = BookingValidationService.validateGuestCount(
        adults: 3,
        children: 2,
        maxGuests: 4,
      );
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('Maximum 4 guests'));
      expect(result.errorMessage, contains('5 guests'));
    });
  });

  group('BookingValidationService.validateAdultCount', () {
    test('returns success when at least 1 adult', () {
      final result = BookingValidationService.validateAdultCount(adults: 1);
      expect(result.isValid, isTrue);
    });

    test('returns success when multiple adults', () {
      final result = BookingValidationService.validateAdultCount(adults: 3);
      expect(result.isValid, isTrue);
    });

    test('returns failure when 0 adults', () {
      final result = BookingValidationService.validateAdultCount(adults: 0);
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('At least 1 adult'));
    });
  });

  group('BookingValidationService.checkSameDayCheckIn', () {
    test('returns success for future date', () {
      final futureDate = DateTime.now().add(const Duration(days: 5));
      final result = BookingValidationService.checkSameDayCheckIn(
        checkIn: futureDate,
      );
      expect(result.isValid, isTrue);
      expect(result.isWarning, isFalse);
    });

    // Note: Same-day check-in tests are time-dependent and harder to test reliably
    // In a real scenario, we'd use a clock abstraction for better testability
  });

  group('BookingValidationService.validateAllBlocking', () {
    WidgetSettings createTestSettings({
      WidgetMode mode = WidgetMode.bookingPending,
    }) {
      return WidgetSettings(
        id: 'unit1',
        propertyId: 'prop1',
        widgetMode: mode,
        contactOptions: const ContactOptions(),
        emailConfig: const EmailNotificationConfig(),
        taxLegalConfig: const TaxLegalConfig(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    test('returns first failure encountered (email verification)', () {
      // Email verification fails first (formKey: null skips form validation)
      final result = BookingValidationService.validateAllBlocking(
        formKey: null, // Skip form validation in unit test
        requireEmailVerification: true,
        emailVerified: false,
        taxConfig: null,
        taxLegalAccepted: false,
        checkIn: DateTime(2025, 1, 15),
        checkOut: DateTime(2025, 1, 20),
        propertyId: 'prop1',
        ownerId: 'owner1',
        widgetMode: WidgetMode.bookingPending,
        selectedPaymentMethod: 'stripe',
        widgetSettings: null,
        adults: 2,
        children: 0,
        maxGuests: 4,
      );
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('verify your email'));
    });

    test('returns success when all validations pass', () {
      final settings = createTestSettings();

      final result = BookingValidationService.validateAllBlocking(
        formKey: null, // Skip form validation in unit test
        requireEmailVerification: false,
        emailVerified: false,
        taxConfig: null,
        taxLegalAccepted: false,
        checkIn: DateTime(2025, 1, 15),
        checkOut: DateTime(2025, 1, 20),
        propertyId: 'prop1',
        ownerId: 'owner1',
        widgetMode: WidgetMode.bookingPending,
        selectedPaymentMethod: '',
        widgetSettings: settings,
        adults: 2,
        children: 0,
        maxGuests: 4,
      );
      expect(result.isValid, isTrue);
    });

    test('fails when dates are invalid', () {
      final settings = createTestSettings();

      final result = BookingValidationService.validateAllBlocking(
        formKey: null, // Skip form validation in unit test
        requireEmailVerification: false,
        emailVerified: false,
        taxConfig: null,
        taxLegalAccepted: false,
        checkIn: null,
        checkOut: DateTime(2025, 1, 20),
        propertyId: 'prop1',
        ownerId: 'owner1',
        widgetMode: WidgetMode.bookingPending,
        selectedPaymentMethod: '',
        widgetSettings: settings,
        adults: 2,
        children: 0,
        maxGuests: 4,
      );
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('select check-in'));
    });

    test('fails when tax legal not accepted but required', () {
      final settings = createTestSettings();

      final result = BookingValidationService.validateAllBlocking(
        formKey: null, // Skip form validation in unit test
        requireEmailVerification: false,
        emailVerified: false,
        taxConfig: const TaxLegalConfig(enabled: true),
        taxLegalAccepted: false,
        checkIn: DateTime(2025, 1, 15),
        checkOut: DateTime(2025, 1, 20),
        propertyId: 'prop1',
        ownerId: 'owner1',
        widgetMode: WidgetMode.bookingPending,
        selectedPaymentMethod: '',
        widgetSettings: settings,
        adults: 2,
        children: 0,
        maxGuests: 4,
      );
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('tax and legal'));
    });

    test('fails when guests exceed max capacity', () {
      final settings = createTestSettings();

      final result = BookingValidationService.validateAllBlocking(
        formKey: null, // Skip form validation in unit test
        requireEmailVerification: false,
        emailVerified: false,
        taxConfig: null,
        taxLegalAccepted: false,
        checkIn: DateTime(2025, 1, 15),
        checkOut: DateTime(2025, 1, 20),
        propertyId: 'prop1',
        ownerId: 'owner1',
        widgetMode: WidgetMode.bookingPending,
        selectedPaymentMethod: '',
        widgetSettings: settings,
        adults: 5,
        children: 3,
        maxGuests: 4,
      );
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('Maximum 4 guests'));
    });

    test('fails when no adults selected', () {
      final settings = createTestSettings();

      final result = BookingValidationService.validateAllBlocking(
        formKey: null, // Skip form validation in unit test
        requireEmailVerification: false,
        emailVerified: false,
        taxConfig: null,
        taxLegalAccepted: false,
        checkIn: DateTime(2025, 1, 15),
        checkOut: DateTime(2025, 1, 20),
        propertyId: 'prop1',
        ownerId: 'owner1',
        widgetMode: WidgetMode.bookingPending,
        selectedPaymentMethod: '',
        widgetSettings: settings,
        adults: 0,
        children: 2,
        maxGuests: 4,
      );
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('At least 1 adult'));
    });
  });
}
