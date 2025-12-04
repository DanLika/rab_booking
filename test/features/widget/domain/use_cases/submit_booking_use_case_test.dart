import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rab_booking/core/constants/enums.dart';
import 'package:rab_booking/core/services/booking_service.dart';
import 'package:rab_booking/features/widget/domain/models/widget_mode.dart';
import 'package:rab_booking/features/widget/domain/models/widget_settings.dart';
import 'package:rab_booking/features/widget/domain/use_cases/submit_booking_use_case.dart';
import 'package:rab_booking/shared/models/booking_model.dart';
import 'package:rab_booking/shared/models/unit_model.dart';

// Mock classes
class MockBookingService extends Mock implements BookingService {}

void main() {
  late MockBookingService mockBookingService;
  late SubmitBookingUseCase useCase;

  // Test data
  final testCheckIn = DateTime(2025, 6);
  final testCheckOut = DateTime(2025, 6, 5);

  final testBooking = BookingModel(
    id: 'test-booking-123',
    unitId: 'unit-1',
    ownerId: 'owner-1',
    guestName: 'John Doe',
    guestEmail: 'john@example.com',
    guestPhone: '+385 91 123 4567',
    checkIn: testCheckIn,
    checkOut: testCheckOut,
    status: BookingStatus.pending,
    totalPrice: 500.0,
    advanceAmount: 100.0,
    paymentMethod: 'bank_transfer',
    paymentStatus: 'pending',
    source: 'widget',
    guestCount: 2,
    createdAt: DateTime.now(),
  );

  final testUnit = UnitModel(
    id: 'unit-1',
    propertyId: 'property-1',
    name: 'Test Villa',
    maxGuests: 4,
    pricePerNight: 100.0,
    weekendBasePrice: 120.0,
    createdAt: DateTime(2025),
  );

  setUp(() {
    mockBookingService = MockBookingService();
    useCase = SubmitBookingUseCase(mockBookingService);

    // Register fallback values for mocktail
    registerFallbackValue(testCheckIn);
    registerFallbackValue(testCheckOut);
  });

  group('SubmitBookingUseCase -', () {
    group('bookingPending mode', () {
      test('should create booking with status=pending and no payment', () async {
        // Arrange
        final widgetSettings = WidgetSettings(
          id: 'unit-1',
          propertyId: 'property-1',
          widgetMode: WidgetMode.bookingPending,
          requireOwnerApproval: true,
          contactOptions: const ContactOptions(),
          emailConfig: const EmailNotificationConfig(),
          taxLegalConfig: const TaxLegalConfig(),
          createdAt: DateTime(2025),
          updatedAt: DateTime(2025),
        );

        final params = SubmitBookingParams(
          unitId: 'unit-1',
          propertyId: 'property-1',
          ownerId: 'owner-1',
          unit: testUnit,
          widgetSettings: widgetSettings,
          checkIn: testCheckIn,
          checkOut: testCheckOut,
          firstName: 'John',
          lastName: 'Doe',
          email: 'john@example.com',
          phoneWithCountryCode: '+385 91 123 4567',
          notes: 'Test notes',
          adults: 2,
          children: 0,
          totalPrice: 500.0,
          paymentMethod: 'none',
          paymentOption: 'none',
          taxLegalAccepted: false,
        );

        when(() => mockBookingService.createBooking(
              unitId: any(named: 'unitId'),
              propertyId: any(named: 'propertyId'),
              ownerId: any(named: 'ownerId'),
              checkIn: any(named: 'checkIn'),
              checkOut: any(named: 'checkOut'),
              guestName: any(named: 'guestName'),
              guestEmail: any(named: 'guestEmail'),
              guestPhone: any(named: 'guestPhone'),
              guestCount: any(named: 'guestCount'),
              totalPrice: any(named: 'totalPrice'),
              paymentOption: any(named: 'paymentOption'),
              paymentMethod: any(named: 'paymentMethod'),
              requireOwnerApproval: any(named: 'requireOwnerApproval'),
              notes: any(named: 'notes'),
              taxLegalAccepted: any(named: 'taxLegalAccepted'),
            )).thenAnswer((_) async => BookingResult.booking(testBooking));

        // Act
        final result = await useCase.execute(params);

        // Assert
        expect(result.isStripeFlow, false);
        expect(result.booking, isNotNull);
        expect(result.booking!.id, 'test-booking-123');

        // Verify booking service called with correct params
        verify(() => mockBookingService.createBooking(
              unitId: 'unit-1',
              propertyId: 'property-1',
              ownerId: 'owner-1',
              checkIn: testCheckIn,
              checkOut: testCheckOut,
              guestName: 'John Doe',
              guestEmail: 'john@example.com',
              guestPhone: '385 91 123 4567', // Sanitized (+ removed)
              guestCount: 2,
              totalPrice: 500.0,
              paymentOption: 'none',
              paymentMethod: 'none',
              requireOwnerApproval: true,
              notes: 'Test notes',
              taxLegalAccepted: false,
            )).called(1);
      });

      test('should sanitize XSS input', () async {
        // Arrange
        final widgetSettings = WidgetSettings(
          id: 'unit-1',
          propertyId: 'property-1',
          widgetMode: WidgetMode.bookingPending,
          contactOptions: const ContactOptions(),
          emailConfig: const EmailNotificationConfig(),
          taxLegalConfig: const TaxLegalConfig(),
          createdAt: DateTime(2025),
          updatedAt: DateTime(2025),
        );

        final params = SubmitBookingParams(
          unitId: 'unit-1',
          propertyId: 'property-1',
          ownerId: 'owner-1',
          widgetSettings: widgetSettings,
          checkIn: testCheckIn,
          checkOut: testCheckOut,
          firstName: '<script>alert("XSS")</script>John',
          lastName: 'Doe<img src=x>',
          email: 'john@example.com',
          phoneWithCountryCode: '+385 91 123 4567',
          notes: '<script>malicious</script>Safe notes',
          adults: 2,
          children: 0,
          totalPrice: 500.0,
          paymentMethod: 'none',
          paymentOption: 'none',
          taxLegalAccepted: false,
        );

        when(() => mockBookingService.createBooking(
              unitId: any(named: 'unitId'),
              propertyId: any(named: 'propertyId'),
              ownerId: any(named: 'ownerId'),
              checkIn: any(named: 'checkIn'),
              checkOut: any(named: 'checkOut'),
              guestName: any(named: 'guestName'),
              guestEmail: any(named: 'guestEmail'),
              guestPhone: any(named: 'guestPhone'),
              guestCount: any(named: 'guestCount'),
              totalPrice: any(named: 'totalPrice'),
              paymentOption: any(named: 'paymentOption'),
              paymentMethod: any(named: 'paymentMethod'),
              requireOwnerApproval: any(named: 'requireOwnerApproval'),
              notes: any(named: 'notes'),
              taxLegalAccepted: any(named: 'taxLegalAccepted'),
            )).thenAnswer((_) async => BookingResult.booking(testBooking));

        // Act
        await useCase.execute(params);

        // Assert - Verify sanitized input was passed to service
        final captured = verify(() => mockBookingService.createBooking(
              unitId: any(named: 'unitId'),
              propertyId: any(named: 'propertyId'),
              ownerId: any(named: 'ownerId'),
              checkIn: any(named: 'checkIn'),
              checkOut: any(named: 'checkOut'),
              guestName: captureAny(named: 'guestName'),
              guestEmail: captureAny(named: 'guestEmail'),
              guestPhone: captureAny(named: 'guestPhone'),
              guestCount: any(named: 'guestCount'),
              totalPrice: any(named: 'totalPrice'),
              paymentOption: any(named: 'paymentOption'),
              paymentMethod: any(named: 'paymentMethod'),
              requireOwnerApproval: any(named: 'requireOwnerApproval'),
              notes: captureAny(named: 'notes'),
              taxLegalAccepted: any(named: 'taxLegalAccepted'),
            )).captured;

        // Verify XSS tags removed from guestName
        final guestName = captured[0] as String;
        expect(guestName, isNot(contains('<script>')));
        expect(guestName, isNot(contains('<img')));

        // Verify XSS tags removed from notes
        final notes = captured[3] as String;
        expect(notes, isNot(contains('<script>')));
      });
    });

    group('Stripe payment flow', () {
      test('should return validation data without creating booking', () async {
        // Arrange
        final widgetSettings = WidgetSettings(
          id: 'unit-1',
          propertyId: 'property-1',
          contactOptions: const ContactOptions(),
          emailConfig: const EmailNotificationConfig(),
          taxLegalConfig: const TaxLegalConfig(),
          createdAt: DateTime(2025),
          updatedAt: DateTime(2025),
        );

        final params = SubmitBookingParams(
          unitId: 'unit-1',
          propertyId: 'property-1',
          ownerId: 'owner-1',
          unit: testUnit,
          widgetSettings: widgetSettings,
          checkIn: testCheckIn,
          checkOut: testCheckOut,
          firstName: 'John',
          lastName: 'Doe',
          email: 'john@example.com',
          phoneWithCountryCode: '+385 91 123 4567',
          adults: 2,
          children: 0,
          totalPrice: 500.0,
          paymentMethod: 'stripe',
          paymentOption: 'deposit',
          taxLegalAccepted: true,
        );

        final stripeBookingData = {
          'unitId': 'unit-1',
          'checkIn': testCheckIn.toIso8601String(),
          'checkOut': testCheckOut.toIso8601String(),
          'guestName': 'John Doe',
          'guestEmail': 'john@example.com',
          'totalPrice': 500.0,
          'depositAmount': 100.0,
        };

        when(() => mockBookingService.createBooking(
              unitId: any(named: 'unitId'),
              propertyId: any(named: 'propertyId'),
              ownerId: any(named: 'ownerId'),
              checkIn: any(named: 'checkIn'),
              checkOut: any(named: 'checkOut'),
              guestName: any(named: 'guestName'),
              guestEmail: any(named: 'guestEmail'),
              guestPhone: any(named: 'guestPhone'),
              guestCount: any(named: 'guestCount'),
              totalPrice: any(named: 'totalPrice'),
              paymentOption: any(named: 'paymentOption'),
              paymentMethod: any(named: 'paymentMethod'),
              requireOwnerApproval: any(named: 'requireOwnerApproval'),
              notes: any(named: 'notes'),
              taxLegalAccepted: any(named: 'taxLegalAccepted'),
            )).thenAnswer((_) async => BookingResult.stripeValidation(
              bookingData: stripeBookingData,
              depositAmount: 100.0,
            ));

        // Act
        final result = await useCase.execute(params);

        // Assert
        expect(result.isStripeFlow, true);
        expect(result.stripeBookingData, isNotNull);
        expect(result.stripeBookingData!['unitId'], 'unit-1');
        expect(result.stripeBookingData!['depositAmount'], 100.0);
        expect(result.booking, isNull); // No booking created yet

        // Verify booking service called with Stripe payment method
        verify(() => mockBookingService.createBooking(
              unitId: 'unit-1',
              propertyId: 'property-1',
              ownerId: 'owner-1',
              checkIn: testCheckIn,
              checkOut: testCheckOut,
              guestName: 'John Doe',
              guestEmail: 'john@example.com',
              guestPhone: '385 91 123 4567', // Sanitized (+ removed)
              guestCount: 2,
              totalPrice: 500.0,
              paymentOption: 'deposit',
              paymentMethod: 'stripe',
              taxLegalAccepted: true,
            )).called(1);
      });

      test('should throw exception if Stripe validation returns invalid data', () async {
        // Arrange
        final widgetSettings = WidgetSettings(
          id: 'unit-1',
          propertyId: 'property-1',
          contactOptions: const ContactOptions(),
          emailConfig: const EmailNotificationConfig(),
          taxLegalConfig: const TaxLegalConfig(),
          createdAt: DateTime(2025),
          updatedAt: DateTime(2025),
        );

        final params = SubmitBookingParams(
          unitId: 'unit-1',
          propertyId: 'property-1',
          ownerId: 'owner-1',
          widgetSettings: widgetSettings,
          checkIn: testCheckIn,
          checkOut: testCheckOut,
          firstName: 'John',
          lastName: 'Doe',
          email: 'john@example.com',
          phoneWithCountryCode: '+385 91 123 4567',
          adults: 2,
          children: 0,
          totalPrice: 500.0,
          paymentMethod: 'stripe',
          paymentOption: 'deposit',
          taxLegalAccepted: false,
        );

        // Mock returns non-Stripe result even though Stripe was requested
        when(() => mockBookingService.createBooking(
              unitId: any(named: 'unitId'),
              propertyId: any(named: 'propertyId'),
              ownerId: any(named: 'ownerId'),
              checkIn: any(named: 'checkIn'),
              checkOut: any(named: 'checkOut'),
              guestName: any(named: 'guestName'),
              guestEmail: any(named: 'guestEmail'),
              guestPhone: any(named: 'guestPhone'),
              guestCount: any(named: 'guestCount'),
              totalPrice: any(named: 'totalPrice'),
              paymentOption: any(named: 'paymentOption'),
              paymentMethod: any(named: 'paymentMethod'),
              requireOwnerApproval: any(named: 'requireOwnerApproval'),
              notes: any(named: 'notes'),
              taxLegalAccepted: any(named: 'taxLegalAccepted'),
            )).thenAnswer((_) async => BookingResult.booking(testBooking));

        // Act & Assert
        expect(
          () => useCase.execute(params),
          throwsException,
        );
      });
    });

    group('Bank transfer flow', () {
      test('should create booking immediately with bank_transfer payment', () async {
        // Arrange
        final widgetSettings = WidgetSettings(
          id: 'unit-1',
          propertyId: 'property-1',
          contactOptions: const ContactOptions(),
          emailConfig: const EmailNotificationConfig(),
          taxLegalConfig: const TaxLegalConfig(),
          createdAt: DateTime(2025),
          updatedAt: DateTime(2025),
        );

        final params = SubmitBookingParams(
          unitId: 'unit-1',
          propertyId: 'property-1',
          ownerId: 'owner-1',
          unit: testUnit,
          widgetSettings: widgetSettings,
          checkIn: testCheckIn,
          checkOut: testCheckOut,
          firstName: 'John',
          lastName: 'Doe',
          email: 'john@example.com',
          phoneWithCountryCode: '+385 91 123 4567',
          notes: 'Bank transfer notes',
          adults: 2,
          children: 1,
          totalPrice: 600.0,
          paymentMethod: 'bank_transfer',
          paymentOption: 'full',
          taxLegalAccepted: true,
        );

        final bankTransferBooking = testBooking.copyWith(
          paymentMethod: 'bank_transfer',
          guestCount: 3,
          totalPrice: 600.0,
        );

        when(() => mockBookingService.createBooking(
              unitId: any(named: 'unitId'),
              propertyId: any(named: 'propertyId'),
              ownerId: any(named: 'ownerId'),
              checkIn: any(named: 'checkIn'),
              checkOut: any(named: 'checkOut'),
              guestName: any(named: 'guestName'),
              guestEmail: any(named: 'guestEmail'),
              guestPhone: any(named: 'guestPhone'),
              guestCount: any(named: 'guestCount'),
              totalPrice: any(named: 'totalPrice'),
              paymentOption: any(named: 'paymentOption'),
              paymentMethod: any(named: 'paymentMethod'),
              requireOwnerApproval: any(named: 'requireOwnerApproval'),
              notes: any(named: 'notes'),
              taxLegalAccepted: any(named: 'taxLegalAccepted'),
            )).thenAnswer((_) async => BookingResult.booking(bankTransferBooking));

        // Act
        final result = await useCase.execute(params);

        // Assert
        expect(result.isStripeFlow, false);
        expect(result.booking, isNotNull);
        expect(result.booking!.paymentMethod, 'bank_transfer');
        expect(result.booking!.guestCount, 3);
        expect(result.booking!.totalPrice, 600.0);

        // Verify booking created with correct payment method
        verify(() => mockBookingService.createBooking(
              unitId: 'unit-1',
              propertyId: 'property-1',
              ownerId: 'owner-1',
              checkIn: testCheckIn,
              checkOut: testCheckOut,
              guestName: 'John Doe',
              guestEmail: 'john@example.com',
              guestPhone: '385 91 123 4567', // Sanitized (+ removed)
              guestCount: 3,
              totalPrice: 600.0,
              paymentOption: 'full',
              paymentMethod: 'bank_transfer',
              notes: 'Bank transfer notes',
              taxLegalAccepted: true,
            )).called(1);
      });
    });

    group('Pay on arrival flow', () {
      test('should create booking immediately with pay_on_arrival payment', () async {
        // Arrange
        final widgetSettings = WidgetSettings(
          id: 'unit-1',
          propertyId: 'property-1',
          requireOwnerApproval: true,
          contactOptions: const ContactOptions(),
          emailConfig: const EmailNotificationConfig(),
          taxLegalConfig: const TaxLegalConfig(),
          createdAt: DateTime(2025),
          updatedAt: DateTime(2025),
        );

        final params = SubmitBookingParams(
          unitId: 'unit-1',
          propertyId: 'property-1',
          ownerId: 'owner-1',
          unit: testUnit,
          widgetSettings: widgetSettings,
          checkIn: testCheckIn,
          checkOut: testCheckOut,
          firstName: 'Jane',
          lastName: 'Smith',
          email: 'jane@example.com',
          phoneWithCountryCode: '+385 92 987 6543',
          adults: 1,
          children: 0,
          totalPrice: 300.0,
          paymentMethod: 'pay_on_arrival',
          paymentOption: 'full',
          taxLegalAccepted: false,
        );

        final payOnArrivalBooking = testBooking.copyWith(
          guestName: 'Jane Smith',
          guestEmail: 'jane@example.com',
          guestPhone: '+385 92 987 6543',
          paymentMethod: 'pay_on_arrival',
          guestCount: 1,
          totalPrice: 300.0,
        );

        when(() => mockBookingService.createBooking(
              unitId: any(named: 'unitId'),
              propertyId: any(named: 'propertyId'),
              ownerId: any(named: 'ownerId'),
              checkIn: any(named: 'checkIn'),
              checkOut: any(named: 'checkOut'),
              guestName: any(named: 'guestName'),
              guestEmail: any(named: 'guestEmail'),
              guestPhone: any(named: 'guestPhone'),
              guestCount: any(named: 'guestCount'),
              totalPrice: any(named: 'totalPrice'),
              paymentOption: any(named: 'paymentOption'),
              paymentMethod: any(named: 'paymentMethod'),
              requireOwnerApproval: any(named: 'requireOwnerApproval'),
              notes: any(named: 'notes'),
              taxLegalAccepted: any(named: 'taxLegalAccepted'),
            )).thenAnswer((_) async => BookingResult.booking(payOnArrivalBooking));

        // Act
        final result = await useCase.execute(params);

        // Assert
        expect(result.isStripeFlow, false);
        expect(result.booking, isNotNull);
        expect(result.booking!.paymentMethod, 'pay_on_arrival');
        expect(result.booking!.guestName, 'Jane Smith');

        // Verify booking created with requireOwnerApproval
        verify(() => mockBookingService.createBooking(
              unitId: 'unit-1',
              propertyId: 'property-1',
              ownerId: 'owner-1',
              checkIn: testCheckIn,
              checkOut: testCheckOut,
              guestName: 'Jane Smith',
              guestEmail: 'jane@example.com',
              guestPhone: '385 92 987 6543', // Sanitized (+ removed)
              guestCount: 1,
              totalPrice: 300.0,
              paymentOption: 'full',
              paymentMethod: 'pay_on_arrival',
              requireOwnerApproval: true,
              taxLegalAccepted: false,
            )).called(1);
      });
    });

    group('Tax/legal acceptance', () {
      test('should pass taxLegalAccepted when config is enabled', () async {
        // Arrange
        final widgetSettings = WidgetSettings(
          id: 'unit-1',
          propertyId: 'property-1',
          contactOptions: const ContactOptions(),
          emailConfig: const EmailNotificationConfig(),
          taxLegalConfig: const TaxLegalConfig(
            
          ),
          createdAt: DateTime(2025),
          updatedAt: DateTime(2025),
        );

        final params = SubmitBookingParams(
          unitId: 'unit-1',
          propertyId: 'property-1',
          ownerId: 'owner-1',
          widgetSettings: widgetSettings,
          checkIn: testCheckIn,
          checkOut: testCheckOut,
          firstName: 'John',
          lastName: 'Doe',
          email: 'john@example.com',
          phoneWithCountryCode: '+385 91 123 4567',
          adults: 2,
          children: 0,
          totalPrice: 500.0,
          paymentMethod: 'bank_transfer',
          paymentOption: 'full',
          taxLegalAccepted: true,
        );

        when(() => mockBookingService.createBooking(
              unitId: any(named: 'unitId'),
              propertyId: any(named: 'propertyId'),
              ownerId: any(named: 'ownerId'),
              checkIn: any(named: 'checkIn'),
              checkOut: any(named: 'checkOut'),
              guestName: any(named: 'guestName'),
              guestEmail: any(named: 'guestEmail'),
              guestPhone: any(named: 'guestPhone'),
              guestCount: any(named: 'guestCount'),
              totalPrice: any(named: 'totalPrice'),
              paymentOption: any(named: 'paymentOption'),
              paymentMethod: any(named: 'paymentMethod'),
              requireOwnerApproval: any(named: 'requireOwnerApproval'),
              notes: any(named: 'notes'),
              taxLegalAccepted: any(named: 'taxLegalAccepted'),
            )).thenAnswer((_) async => BookingResult.booking(testBooking));

        // Act
        await useCase.execute(params);

        // Assert - taxLegalAccepted should be true
        verify(() => mockBookingService.createBooking(
              unitId: any(named: 'unitId'),
              propertyId: any(named: 'propertyId'),
              ownerId: any(named: 'ownerId'),
              checkIn: any(named: 'checkIn'),
              checkOut: any(named: 'checkOut'),
              guestName: any(named: 'guestName'),
              guestEmail: any(named: 'guestEmail'),
              guestPhone: any(named: 'guestPhone'),
              guestCount: any(named: 'guestCount'),
              totalPrice: any(named: 'totalPrice'),
              paymentOption: any(named: 'paymentOption'),
              paymentMethod: any(named: 'paymentMethod'),
              requireOwnerApproval: any(named: 'requireOwnerApproval'),
              notes: any(named: 'notes'),
              taxLegalAccepted: true,
            )).called(1);
      });

      test('should pass null for taxLegalAccepted when config is disabled', () async {
        // Arrange
        final widgetSettings = WidgetSettings(
          id: 'unit-1',
          propertyId: 'property-1',
          contactOptions: const ContactOptions(),
          emailConfig: const EmailNotificationConfig(),
          taxLegalConfig: const TaxLegalConfig(enabled: false),
          createdAt: DateTime(2025),
          updatedAt: DateTime(2025),
        );

        final params = SubmitBookingParams(
          unitId: 'unit-1',
          propertyId: 'property-1',
          ownerId: 'owner-1',
          widgetSettings: widgetSettings,
          checkIn: testCheckIn,
          checkOut: testCheckOut,
          firstName: 'John',
          lastName: 'Doe',
          email: 'john@example.com',
          phoneWithCountryCode: '+385 91 123 4567',
          adults: 2,
          children: 0,
          totalPrice: 500.0,
          paymentMethod: 'bank_transfer',
          paymentOption: 'full',
          taxLegalAccepted: true, // User checked it, but config disabled
        );

        when(() => mockBookingService.createBooking(
              unitId: any(named: 'unitId'),
              propertyId: any(named: 'propertyId'),
              ownerId: any(named: 'ownerId'),
              checkIn: any(named: 'checkIn'),
              checkOut: any(named: 'checkOut'),
              guestName: any(named: 'guestName'),
              guestEmail: any(named: 'guestEmail'),
              guestPhone: any(named: 'guestPhone'),
              guestCount: any(named: 'guestCount'),
              totalPrice: any(named: 'totalPrice'),
              paymentOption: any(named: 'paymentOption'),
              paymentMethod: any(named: 'paymentMethod'),
              requireOwnerApproval: any(named: 'requireOwnerApproval'),
              notes: any(named: 'notes'),
              taxLegalAccepted: any(named: 'taxLegalAccepted'),
            )).thenAnswer((_) async => BookingResult.booking(testBooking));

        // Act
        await useCase.execute(params);

        // Assert - taxLegalAccepted should be null (config disabled)
        verify(() => mockBookingService.createBooking(
              unitId: any(named: 'unitId'),
              propertyId: any(named: 'propertyId'),
              ownerId: any(named: 'ownerId'),
              checkIn: any(named: 'checkIn'),
              checkOut: any(named: 'checkOut'),
              guestName: any(named: 'guestName'),
              guestEmail: any(named: 'guestEmail'),
              guestPhone: any(named: 'guestPhone'),
              guestCount: any(named: 'guestCount'),
              totalPrice: any(named: 'totalPrice'),
              paymentOption: any(named: 'paymentOption'),
              paymentMethod: any(named: 'paymentMethod'),
              requireOwnerApproval: any(named: 'requireOwnerApproval'),
              notes: any(named: 'notes'),
            )).called(1);
      });
    });

    group('Error handling', () {
      test('should propagate BookingConflictException from service', () async {
        // Arrange
        final params = SubmitBookingParams(
          unitId: 'unit-1',
          propertyId: 'property-1',
          ownerId: 'owner-1',
          checkIn: testCheckIn,
          checkOut: testCheckOut,
          firstName: 'John',
          lastName: 'Doe',
          email: 'john@example.com',
          phoneWithCountryCode: '+385 91 123 4567',
          adults: 2,
          children: 0,
          totalPrice: 500.0,
          paymentMethod: 'bank_transfer',
          paymentOption: 'full',
          taxLegalAccepted: false,
        );

        when(() => mockBookingService.createBooking(
              unitId: any(named: 'unitId'),
              propertyId: any(named: 'propertyId'),
              ownerId: any(named: 'ownerId'),
              checkIn: any(named: 'checkIn'),
              checkOut: any(named: 'checkOut'),
              guestName: any(named: 'guestName'),
              guestEmail: any(named: 'guestEmail'),
              guestPhone: any(named: 'guestPhone'),
              guestCount: any(named: 'guestCount'),
              totalPrice: any(named: 'totalPrice'),
              paymentOption: any(named: 'paymentOption'),
              paymentMethod: any(named: 'paymentMethod'),
              requireOwnerApproval: any(named: 'requireOwnerApproval'),
              notes: any(named: 'notes'),
              taxLegalAccepted: any(named: 'taxLegalAccepted'),
            )).thenThrow(BookingConflictException('Dates no longer available'));

        // Act & Assert
        expect(
          () => useCase.execute(params),
          throwsA(isA<BookingConflictException>()),
        );
      });

      test('should propagate BookingServiceException from service', () async {
        // Arrange
        final params = SubmitBookingParams(
          unitId: 'unit-1',
          propertyId: 'property-1',
          ownerId: 'owner-1',
          checkIn: testCheckIn,
          checkOut: testCheckOut,
          firstName: 'John',
          lastName: 'Doe',
          email: 'john@example.com',
          phoneWithCountryCode: '+385 91 123 4567',
          adults: 2,
          children: 0,
          totalPrice: 500.0,
          paymentMethod: 'bank_transfer',
          paymentOption: 'full',
          taxLegalAccepted: false,
        );

        when(() => mockBookingService.createBooking(
              unitId: any(named: 'unitId'),
              propertyId: any(named: 'propertyId'),
              ownerId: any(named: 'ownerId'),
              checkIn: any(named: 'checkIn'),
              checkOut: any(named: 'checkOut'),
              guestName: any(named: 'guestName'),
              guestEmail: any(named: 'guestEmail'),
              guestPhone: any(named: 'guestPhone'),
              guestCount: any(named: 'guestCount'),
              totalPrice: any(named: 'totalPrice'),
              paymentOption: any(named: 'paymentOption'),
              paymentMethod: any(named: 'paymentMethod'),
              requireOwnerApproval: any(named: 'requireOwnerApproval'),
              notes: any(named: 'notes'),
              taxLegalAccepted: any(named: 'taxLegalAccepted'),
            )).thenThrow(BookingServiceException('Service error'));

        // Act & Assert
        expect(
          () => useCase.execute(params),
          throwsA(isA<BookingServiceException>()),
        );
      });
    });
  });
}
