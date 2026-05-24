import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bookbed/features/widget/presentation/widgets/country_code_dropdown.dart';
import 'package:bookbed/features/widget/services/form_persistence_service.dart';
import 'package:bookbed/features/widget/state/booking_form_state.dart';

void main() {
  group('initial state', () {
    test('has expected defaults', () {
      final state = BookingFormState();
      try {
        expect(state.checkIn, isNull);
        expect(state.checkOut, isNull);
        expect(state.adults, 1);
        expect(state.children, 0);
        expect(state.pets, 0);
        expect(state.selectedCountry, defaultCountry);
        expect(state.selectedPaymentMethod, 'stripe');
        expect(state.selectedPaymentOption, 'deposit');
        expect(state.emailVerified, isFalse);
        expect(state.taxLegalAccepted, isFalse);
        expect(state.showGuestForm, isFalse);
        expect(state.isProcessing, isFalse);
        expect(state.isVerifyingEmail, isFalse);
        expect(state.pillBarDismissed, isFalse);
        expect(state.hasInteractedWithBookingFlow, isFalse);
        expect(state.lockedPriceCalculation, isNull);
        expect(state.hasDatesSelected, isFalse);
        expect(state.nights, 0);
        expect(state.guestFullName, '');
        expect(state.fullPhoneNumber, '');
        expect(state.totalGuests, 1);
      } finally {
        state.dispose();
      }
    });

    test('is a ChangeNotifier subclass', () {
      final state = BookingFormState();
      try {
        expect(state, isA<ChangeNotifier>());
      } finally {
        state.dispose();
      }
    });
  });

  group('setter notification', () {
    test('checkIn setter fires notifyListeners when value changes', () {
      final state = BookingFormState();
      try {
        var fires = 0;
        state.addListener(() => fires++);
        state.checkIn = DateTime.utc(2026, 6, 2);
        expect(fires, 1);
      } finally {
        state.dispose();
      }
    });

    test('checkIn setter is a no-op when value is unchanged', () {
      final state = BookingFormState();
      try {
        final initial = DateTime.utc(2026, 6, 2);
        state.checkIn = initial;
        var fires = 0;
        state.addListener(() => fires++);
        state.checkIn = initial;
        expect(fires, 0);
      } finally {
        state.dispose();
      }
    });

    test('adults setter fires once on change, zero on no-op', () {
      final state = BookingFormState();
      try {
        var fires = 0;
        state.addListener(() => fires++);
        state.adults = 3;
        state.adults = 3;
        expect(fires, 1);
      } finally {
        state.dispose();
      }
    });

    test('selectedPaymentMethod setter fires on change', () {
      final state = BookingFormState();
      try {
        var fires = 0;
        state.addListener(() => fires++);
        state.selectedPaymentMethod = 'bank_transfer';
        expect(fires, 1);
        expect(state.selectedPaymentMethod, 'bank_transfer');
      } finally {
        state.dispose();
      }
    });

    test('taxLegalAccepted setter fires on change', () {
      final state = BookingFormState();
      try {
        var fires = 0;
        state.addListener(() => fires++);
        state.taxLegalAccepted = true;
        expect(fires, 1);
      } finally {
        state.dispose();
      }
    });

    test('every primitive setter notifies exactly once per change', () {
      final state = BookingFormState();
      try {
        var fires = 0;
        state.addListener(() => fires++);

        state.checkIn = DateTime.utc(2026, 6, 2);
        state.checkOut = DateTime.utc(2026, 6, 5);
        state.adults = 2;
        state.children = 1;
        state.pets = 1;
        state.selectedPaymentMethod = 'pay_on_arrival';
        state.selectedPaymentOption = 'full';
        state.emailVerified = true;
        state.taxLegalAccepted = true;
        state.showGuestForm = true;
        state.isProcessing = true;
        state.isVerifyingEmail = true;
        state.pillBarDismissed = true;
        state.hasInteractedWithBookingFlow = true;

        expect(fires, 14);
      } finally {
        state.dispose();
      }
    });
  });

  group('resetState', () {
    test('notifies exactly once', () {
      final state = BookingFormState();
      try {
        // Mutate a bunch of fields first so reset has work to do.
        state.checkIn = DateTime.utc(2026, 6, 2);
        state.checkOut = DateTime.utc(2026, 6, 5);
        state.adults = 4;
        state.children = 2;
        state.selectedPaymentMethod = 'bank_transfer';
        state.taxLegalAccepted = true;
        state.showGuestForm = true;
        state.isProcessing = true;
        state.hasInteractedWithBookingFlow = true;

        var fires = 0;
        state.addListener(() => fires++);
        state.resetState();

        expect(fires, 1);
      } finally {
        state.dispose();
      }
    });

    test('returns every field to defaults', () {
      final state = BookingFormState();
      try {
        state.checkIn = DateTime.utc(2026, 6, 2);
        state.checkOut = DateTime.utc(2026, 6, 5);
        state.adults = 4;
        state.children = 2;
        state.pets = 1;
        state.selectedPaymentMethod = 'bank_transfer';
        state.selectedPaymentOption = 'full';
        state.emailVerified = true;
        state.taxLegalAccepted = true;
        state.showGuestForm = true;
        state.isProcessing = true;
        state.isVerifyingEmail = true;
        state.pillBarDismissed = true;
        state.hasInteractedWithBookingFlow = true;
        state.firstNameController.text = 'John';
        state.lastNameController.text = 'Doe';
        state.emailController.text = 'john@doe.com';
        state.phoneController.text = '123456';
        state.notesController.text = 'a note';

        state.resetState();

        expect(state.checkIn, isNull);
        expect(state.checkOut, isNull);
        expect(state.adults, 1);
        expect(state.children, 0);
        expect(state.pets, 0);
        expect(state.selectedPaymentMethod, 'stripe');
        expect(state.selectedPaymentOption, 'deposit');
        expect(state.emailVerified, isFalse);
        expect(state.taxLegalAccepted, isFalse);
        expect(state.showGuestForm, isFalse);
        expect(state.isProcessing, isFalse);
        expect(state.isVerifyingEmail, isFalse);
        expect(state.pillBarDismissed, isFalse);
        expect(state.hasInteractedWithBookingFlow, isFalse);
        expect(state.firstNameController.text, '');
        expect(state.lastNameController.text, '');
        expect(state.emailController.text, '');
        expect(state.phoneController.text, '');
        expect(state.notesController.text, '');
      } finally {
        state.dispose();
      }
    });
  });

  group('toPersistedFormData', () {
    test('captures current form values', () {
      final state = BookingFormState();
      try {
        state.checkIn = DateTime.utc(2026, 6, 2);
        state.checkOut = DateTime.utc(2026, 6, 5);
        state.adults = 2;
        state.children = 1;
        state.firstNameController.text = 'Jane';
        state.lastNameController.text = 'Smith';
        state.emailController.text = 'jane@smith.com';
        state.phoneController.text = '555-1234';
        state.notesController.text = 'late check-in';
        state.selectedPaymentMethod = 'bank_transfer';
        state.pillBarDismissed = true;
        state.hasInteractedWithBookingFlow = true;

        final data = state.toPersistedFormData(
          unitId: 'unit-123',
          propertyId: 'prop-456',
        );

        expect(data.unitId, 'unit-123');
        expect(data.propertyId, 'prop-456');
        expect(data.checkIn, DateTime.utc(2026, 6, 2));
        expect(data.checkOut, DateTime.utc(2026, 6, 5));
        expect(data.adults, 2);
        expect(data.children, 1);
        expect(data.firstName, 'Jane');
        expect(data.lastName, 'Smith');
        expect(data.email, 'jane@smith.com');
        expect(data.phone, '555-1234');
        expect(data.notes, 'late check-in');
        expect(data.paymentMethod, 'bank_transfer');
        expect(data.pillBarDismissed, isTrue);
        expect(data.hasInteractedWithBookingFlow, isTrue);
        expect(data.countryCode, defaultCountry.dialCode);
      } finally {
        state.dispose();
      }
    });

    test('propertyId may be null', () {
      final state = BookingFormState();
      try {
        final data = state.toPersistedFormData(unitId: 'unit-abc');
        expect(data.propertyId, isNull);
      } finally {
        state.dispose();
      }
    });
  });

  group('applyFromPersisted', () {
    test('restores every persisted field', () {
      final state = BookingFormState();
      try {
        final data = PersistedFormData(
          unitId: 'unit-1',
          propertyId: 'prop-1',
          checkIn: DateTime.utc(2026, 7, 2),
          checkOut: DateTime.utc(2026, 7, 4),
          firstName: 'Ada',
          lastName: 'Lovelace',
          email: 'ada@example.com',
          phone: '555-0100',
          countryCode: defaultCountry.dialCode,
          adults: 3,
          children: 1,
          notes: 'window seat',
          paymentMethod: 'pay_on_arrival',
          pillBarDismissed: true,
          hasInteractedWithBookingFlow: true,
          timestamp: DateTime.utc(2026, 2),
        );

        state.applyFromPersisted(data);

        expect(state.checkIn, data.checkIn);
        expect(state.checkOut, data.checkOut);
        expect(state.firstNameController.text, 'Ada');
        expect(state.lastNameController.text, 'Lovelace');
        expect(state.emailController.text, 'ada@example.com');
        expect(state.phoneController.text, '555-0100');
        expect(state.notesController.text, 'window seat');
        expect(state.adults, 3);
        expect(state.children, 1);
        expect(state.selectedPaymentMethod, 'pay_on_arrival');
        expect(state.pillBarDismissed, isTrue);
        expect(state.hasInteractedWithBookingFlow, isTrue);
      } finally {
        state.dispose();
      }
    });

    test('notifies exactly once', () {
      final state = BookingFormState();
      try {
        final data = PersistedFormData(
          unitId: 'unit-1',
          firstName: 'A',
          lastName: 'B',
          email: 'a@b.com',
          phone: '1',
          countryCode: defaultCountry.dialCode,
          adults: 2,
          children: 1,
          notes: '',
          paymentMethod: 'stripe',
          pillBarDismissed: false,
          hasInteractedWithBookingFlow: false,
          timestamp: DateTime.utc(2026, 2),
        );
        var fires = 0;
        state.addListener(() => fires++);

        state.applyFromPersisted(data);

        expect(fires, 1);
      } finally {
        state.dispose();
      }
    });

    test('round-trip is field-equal', () {
      final source = BookingFormState();
      final target = BookingFormState();
      try {
        source.checkIn = DateTime.utc(2026, 8, 10);
        source.checkOut = DateTime.utc(2026, 8, 17);
        source.adults = 4;
        source.children = 2;
        source.firstNameController.text = 'Grace';
        source.lastNameController.text = 'Hopper';
        source.emailController.text = 'grace@navy.mil';
        source.phoneController.text = '202-555-0101';
        source.notesController.text = 'two cribs please';
        source.selectedPaymentMethod = 'bank_transfer';
        source.pillBarDismissed = true;
        source.hasInteractedWithBookingFlow = true;

        final data = source.toPersistedFormData(
          unitId: 'unit-xyz',
          propertyId: 'prop-xyz',
        );
        target.applyFromPersisted(data);

        expect(target.checkIn, source.checkIn);
        expect(target.checkOut, source.checkOut);
        expect(
          target.firstNameController.text,
          source.firstNameController.text,
        );
        expect(target.lastNameController.text, source.lastNameController.text);
        expect(target.emailController.text, source.emailController.text);
        expect(target.phoneController.text, source.phoneController.text);
        expect(target.notesController.text, source.notesController.text);
        expect(target.adults, source.adults);
        expect(target.children, source.children);
        expect(target.selectedPaymentMethod, source.selectedPaymentMethod);
        expect(target.pillBarDismissed, source.pillBarDismissed);
        expect(
          target.hasInteractedWithBookingFlow,
          source.hasInteractedWithBookingFlow,
        );
      } finally {
        source.dispose();
        target.dispose();
      }
    });
  });

  group('adjustGuestCountToCapacity', () {
    test('clamps adults+children when over capacity, notifies once', () {
      final state = BookingFormState();
      try {
        state.adults = 4;
        state.children = 3; // total 7
        var fires = 0;
        state.addListener(() => fires++);

        state.adjustGuestCountToCapacity(5);

        expect(state.adults, 5);
        expect(state.children, 0);
        expect(fires, 1);
      } finally {
        state.dispose();
      }
    });

    test('no-op when under capacity, no notify', () {
      final state = BookingFormState();
      try {
        state.adults = 2;
        state.children = 1; // total 3
        var fires = 0;
        state.addListener(() => fires++);

        state.adjustGuestCountToCapacity(10);

        expect(state.adults, 2);
        expect(state.children, 1);
        expect(fires, 0);
      } finally {
        state.dispose();
      }
    });

    test('zero or negative max is ignored', () {
      final state = BookingFormState();
      try {
        state.adults = 3;
        state.children = 2;
        state.adjustGuestCountToCapacity(0);
        state.adjustGuestCountToCapacity(-5);
        expect(state.adults, 3);
        expect(state.children, 2);
      } finally {
        state.dispose();
      }
    });
  });

  group('derived getters', () {
    test('nights returns 0 when dates not selected', () {
      final state = BookingFormState();
      try {
        expect(state.nights, 0);
        state.checkIn = DateTime.utc(2026, 6, 2);
        expect(state.nights, 0);
      } finally {
        state.dispose();
      }
    });

    test('nights computes nights between dates', () {
      final state = BookingFormState();
      try {
        state.checkIn = DateTime.utc(2026, 6, 2);
        state.checkOut = DateTime.utc(2026, 6, 5);
        expect(state.nights, 3);
      } finally {
        state.dispose();
      }
    });

    test('guestFullName trims whitespace', () {
      final state = BookingFormState();
      try {
        state.firstNameController.text = '  John  ';
        state.lastNameController.text = '  Doe  ';
        expect(state.guestFullName, 'John Doe');
      } finally {
        state.dispose();
      }
    });

    test('fullPhoneNumber is empty when phone is empty', () {
      final state = BookingFormState();
      try {
        expect(state.fullPhoneNumber, '');
      } finally {
        state.dispose();
      }
    });

    test('fullPhoneNumber prefixes country dial code', () {
      final state = BookingFormState();
      try {
        state.phoneController.text = '555-0100';
        expect(state.fullPhoneNumber, '${defaultCountry.dialCode} 555-0100');
      } finally {
        state.dispose();
      }
    });
  });
}
