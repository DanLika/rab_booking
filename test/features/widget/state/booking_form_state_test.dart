import 'package:flutter_test/flutter_test.dart';
import 'package:bookbed/features/widget/state/booking_form_state.dart';
import 'package:bookbed/features/widget/presentation/widgets/country_code_dropdown.dart';

void main() {
  late BookingFormState formState;

  setUp(() {
    formState = BookingFormState();
  });

  group('BookingFormState Initial State', () {
    test('should initialize with correct default values', () {
      expect(formState.checkIn, isNull);
      expect(formState.checkOut, isNull);
      expect(formState.adults, 1);
      expect(formState.children, 0);
      expect(formState.pets, 0);
      expect(formState.selectedCountry, defaultCountry);
      expect(formState.selectedPaymentMethod, 'stripe');
      expect(formState.selectedPaymentOption, 'deposit');
      expect(formState.emailVerified, isFalse);
      expect(formState.taxLegalAccepted, isFalse);
      expect(formState.showGuestForm, isFalse);
      expect(formState.isProcessing, isFalse);
      expect(formState.isVerifyingEmail, isFalse);
      expect(formState.pillBarDismissed, isFalse);
      expect(formState.hasInteractedWithBookingFlow, isFalse);
      expect(formState.lockedPriceCalculation, isNull);
    });
  });

  group('BookingFormState Getters', () {
    test('totalGuests should return sum of adults and children', () {
      formState.adults = 2;
      formState.children = 3;
      expect(formState.totalGuests, 5);
    });

    test('nights should calculate difference between checkIn and checkOut correctly', () {
      final now = DateTime.now();
      formState.checkIn = now;
      formState.checkOut = now.add(const Duration(days: 5));
      expect(formState.nights, 5);
    });

    test('nights should return 0 if dates are not selected', () {
      expect(formState.nights, 0);

      formState.checkIn = DateTime.now();
      expect(formState.nights, 0);

      formState.checkIn = null;
      formState.checkOut = DateTime.now();
      expect(formState.nights, 0);
    });

    test('hasDatesSelected should return true only when both dates are selected', () {
      expect(formState.hasDatesSelected, isFalse);

      formState.checkIn = DateTime.now();
      expect(formState.hasDatesSelected, isFalse);

      formState.checkIn = null;
      formState.checkOut = DateTime.now();
      expect(formState.hasDatesSelected, isFalse);

      formState.checkIn = DateTime.now();
      formState.checkOut = DateTime.now().add(const Duration(days: 1));
      expect(formState.hasDatesSelected, isTrue);
    });

    test('guestFullName should return combined first and last names trimmed', () {
      expect(formState.guestFullName, '');

      formState.firstNameController.text = '  John  ';
      formState.lastNameController.text = 'Doe';
      expect(formState.guestFullName, 'John Doe');

      formState.firstNameController.text = '';
      formState.lastNameController.text = '  Doe  ';
      expect(formState.guestFullName, 'Doe');
    });

    test('fullPhoneNumber should return combined country dial code and phone without spaces correctly', () {
      expect(formState.fullPhoneNumber, '');

      formState.selectedCountry = Country(code: 'US', name: 'USA', dialCode: '+1', flag: 'US');
      formState.phoneController.text = ' 1234567890 ';

      expect(formState.fullPhoneNumber, '+1 1234567890');
    });
  });

  group('BookingFormState Methods', () {
    test('adjustGuestCountToCapacity should cap guests to effectiveMax', () {
      formState.adults = 4;
      formState.children = 2;

      formState.adjustGuestCountToCapacity(5);

      expect(formState.adults, 5);
      expect(formState.children, 0);
      expect(formState.totalGuests, 5);
    });

    test('adjustGuestCountToCapacity should ignore if effectiveMax <= 0', () {
      formState.adults = 2;
      formState.children = 1;

      formState.adjustGuestCountToCapacity(0);
      expect(formState.totalGuests, 3);

      formState.adjustGuestCountToCapacity(-1);
      expect(formState.totalGuests, 3);
    });

    test('adjustGuestCountToCapacity should not change counts if within capacity', () {
      formState.adults = 2;
      formState.children = 1;

      formState.adjustGuestCountToCapacity(5);

      expect(formState.adults, 2);
      expect(formState.children, 1);
      expect(formState.totalGuests, 3);
    });

    test('resetState should reset all variables and clear controllers', () {
      // Set to non-default values
      formState.firstNameController.text = 'John';
      formState.lastNameController.text = 'Doe';
      formState.emailController.text = 'test@example.com';
      formState.phoneController.text = '123456';
      formState.notesController.text = 'Notes';

      formState.checkIn = DateTime.now();
      formState.checkOut = DateTime.now().add(const Duration(days: 1));

      formState.adults = 2;
      formState.children = 1;
      formState.pets = 1;

      formState.selectedCountry = Country(code: 'US', name: 'USA', dialCode: '+1', flag: 'US');
      formState.selectedPaymentMethod = 'bank_transfer';
      formState.selectedPaymentOption = 'full';

      formState.emailVerified = true;
      formState.taxLegalAccepted = true;
      formState.showGuestForm = true;
      formState.isProcessing = true;
      formState.isVerifyingEmail = true;
      formState.pillBarDismissed = true;
      formState.hasInteractedWithBookingFlow = true;

      formState.resetState();

      // Verify reset
      expect(formState.firstNameController.text, '');
      expect(formState.lastNameController.text, '');
      expect(formState.emailController.text, '');
      expect(formState.phoneController.text, '');
      expect(formState.notesController.text, '');

      expect(formState.checkIn, isNull);
      expect(formState.checkOut, isNull);

      expect(formState.adults, 1);
      expect(formState.children, 0);
      expect(formState.pets, 0);

      expect(formState.selectedCountry, defaultCountry);
      expect(formState.selectedPaymentMethod, 'stripe');
      expect(formState.selectedPaymentOption, 'deposit');

      expect(formState.emailVerified, isFalse);
      expect(formState.taxLegalAccepted, isFalse);
      expect(formState.showGuestForm, isFalse);
      expect(formState.isProcessing, isFalse);
      expect(formState.isVerifyingEmail, isFalse);
      expect(formState.pillBarDismissed, isFalse);
      expect(formState.hasInteractedWithBookingFlow, isFalse);
      expect(formState.lockedPriceCalculation, isNull);
    });

    test('dispose should not throw error', () {
      expect(() => formState.dispose(), returnsNormally);
    });
  });
}
