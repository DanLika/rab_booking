# Architecture Refactoring Plan
**Goal:** Fix tight coupling + decompose God object (2649 lines → <300)

---

## Executive Summary

| Metric | Current | Target | Impact |
|--------|---------|--------|--------|
| BookingWidgetScreen | 2649 lines | <300 lines | **90% reduction** |
| Testability | 0% unit tests | 80% coverage | **Infinite improvement** |
| Firebase coupling | Direct | Abstracted | **Swappable backend** |
| Maintainability | Very Low | High | **5x faster features** |

**Total Effort:** 33-46 hours (4-6 weeks, 1 dev)
**Risk:** High (mitigated by incremental approach)

---

## PHASE 1: Decouple Firebase (8-12 hours)

### Goal
Abstract Firebase dependencies → Enable testing + backend flexibility

### Current Problem
```dart
// ❌ BEFORE: Tight coupling
class FirebaseBookingCalendarRepository {
  final FirebaseFirestore _firestore;  // Concrete dependency

  Stream<Map<DateTime, CalendarDateInfo>> watchYearCalendarData(...) {
    return _firestore.collection('bookings')  // Direct Firebase calls
      .where('unitId', isEqualTo: unitId)
      .snapshots();
  }
}

// ❌ Cannot test without Firebase emulator
// ❌ Cannot swap to Supabase/REST API
// ❌ Violates Dependency Inversion Principle
```

### Step 1.1: Create Domain Interfaces (2 hours)

**New File:** `lib/features/widget/domain/repositories/i_booking_calendar_repository.dart`
```dart
import '../models/calendar_date_status.dart';

/// Abstract repository for booking calendar operations.
/// Implementations can use Firebase, Supabase, REST API, or mock data.
abstract class IBookingCalendarRepository {
  /// Watch year calendar data with realtime updates
  Stream<Map<DateTime, CalendarDateInfo>> watchYearCalendarData({
    required String propertyId,
    required String unitId,
    required int year,
  });

  /// Watch month calendar data with realtime updates
  Stream<Map<DateTime, CalendarDateInfo>> watchMonthCalendarData({
    required String propertyId,
    required String unitId,
    required int year,
    required int month,
  });

  /// Check if date range is available
  Future<bool> isDateRangeAvailable({
    required String propertyId,
    required String unitId,
    required DateTime checkIn,
    required DateTime checkOut,
  });

  /// Get price for date range
  Future<double?> getPriceForDateRange({
    required String propertyId,
    required String unitId,
    required DateTime checkIn,
    required DateTime checkOut,
  });
}
```

**New File:** `lib/features/widget/domain/services/i_availability_checker.dart`
```dart
/// Abstract availability checker.
/// Separates availability logic from Firebase implementation.
abstract class IAvailabilityChecker {
  Future<bool> isDateRangeAvailable({
    required String propertyId,
    required String unitId,
    required DateTime checkIn,
    required DateTime checkOut,
  });

  Future<Map<DateTime, bool>> getAvailabilityMap({
    required String propertyId,
    required String unitId,
    required DateTime startDate,
    required DateTime endDate,
  });
}
```

**New File:** `lib/features/widget/domain/services/i_price_calculator.dart`
```dart
import '../../../shared/models/daily_price_model.dart';

/// Abstract price calculator.
/// Separates pricing logic from Firebase implementation.
abstract class IPriceCalculator {
  Future<double?> calculatePriceForRange({
    required String propertyId,
    required String unitId,
    required DateTime checkIn,
    required DateTime checkOut,
  });

  Future<Map<DateTime, DailyPriceModel>> getPriceMap({
    required String propertyId,
    required String unitId,
    required DateTime startDate,
    required DateTime endDate,
  });
}
```

---

### Step 1.2: Refactor Firebase Repository (3 hours)

**Update:** `lib/features/widget/data/repositories/firebase_booking_calendar_repository.dart`

```dart
// ✅ AFTER: Implements abstraction
class FirebaseBookingCalendarRepository implements IBookingCalendarRepository {
  // Inject abstraction, not concrete Firestore
  final IFirestoreDataSource _dataSource;
  final IAvailabilityChecker _availabilityChecker;
  final IPriceCalculator _priceCalculator;

  FirebaseBookingCalendarRepository({
    required IFirestoreDataSource dataSource,
    required IAvailabilityChecker availabilityChecker,
    required IPriceCalculator priceCalculator,
  })  : _dataSource = dataSource,
        _availabilityChecker = availabilityChecker,
        _priceCalculator = priceCalculator;

  @override
  Stream<Map<DateTime, CalendarDateInfo>> watchYearCalendarData({
    required String propertyId,
    required String unitId,
    required int year,
  }) {
    // Use abstraction instead of direct Firebase calls
    return _dataSource.watchCollection(
      path: 'bookings',
      queryBuilder: (query) => query
          .where('unitId', isEqualTo: unitId)
          .where('year', isEqualTo: year),
    ).map((docs) => _buildCalendarMap(docs));
  }

  // ... other methods
}
```

---

### Step 1.3: Create Firestore Data Source Abstraction (2 hours)

**New File:** `lib/core/data/i_firestore_data_source.dart`
```dart
/// Abstract Firestore operations.
/// Enables swapping Firebase with other backends.
abstract class IFirestoreDataSource {
  /// Watch a collection with realtime updates
  Stream<List<Map<String, dynamic>>> watchCollection({
    required String path,
    required Query Function(Query query) queryBuilder,
  });

  /// Get a single document
  Future<Map<String, dynamic>?> getDocument({
    required String path,
  });

  /// Get multiple documents
  Future<List<Map<String, dynamic>>> getDocuments({
    required String path,
    required Query Function(Query query) queryBuilder,
  });

  /// Add a document
  Future<String> addDocument({
    required String path,
    required Map<String, dynamic> data,
  });

  /// Update a document
  Future<void> updateDocument({
    required String path,
    required Map<String, dynamic> data,
  });
}
```

**Implementation:** `lib/core/data/firebase_firestore_data_source.dart`
```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'i_firestore_data_source.dart';

/// Firebase implementation of Firestore data source.
class FirebaseFirestoreDataSource implements IFirestoreDataSource {
  final FirebaseFirestore _firestore;

  FirebaseFirestoreDataSource(this._firestore);

  @override
  Stream<List<Map<String, dynamic>>> watchCollection({
    required String path,
    required Query Function(Query query) queryBuilder,
  }) {
    final collectionRef = _firestore.collection(path);
    final query = queryBuilder(collectionRef);

    return query.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id})
          .toList(),
    );
  }

  // ... implement other methods
}
```

---

### Step 1.4: Update Providers (1 hour)

**Update:** `lib/features/widget/presentation/providers/realtime_booking_calendar_provider.dart`

```dart
// ✅ AFTER: Use abstraction
@riverpod
IBookingCalendarRepository bookingCalendarRepository(Ref ref) {
  final dataSource = ref.watch(firestoreDataSourceProvider);
  final availabilityChecker = ref.watch(availabilityCheckerProvider);
  final priceCalculator = ref.watch(priceCalculatorProvider);

  return FirebaseBookingCalendarRepository(
    dataSource: dataSource,
    availabilityChecker: availabilityChecker,
    priceCalculator: priceCalculator,
  );
}

// NEW: Data source provider
@riverpod
IFirestoreDataSource firestoreDataSource(Ref ref) {
  final firestore = ref.watch(firestoreProvider);
  return FirebaseFirestoreDataSource(firestore);
}
```

---

### Step 1.5: Create Mock Implementation for Testing (2 hours)

**New File:** `test/mocks/mock_booking_calendar_repository.dart`
```dart
import 'package:mocktail/mocktail.dart';
import 'package:rab_booking/features/widget/domain/repositories/i_booking_calendar_repository.dart';

class MockBookingCalendarRepository extends Mock
    implements IBookingCalendarRepository {}

// Usage in tests:
void main() {
  late MockBookingCalendarRepository mockRepository;

  setUp(() {
    mockRepository = MockBookingCalendarRepository();
  });

  test('should return available dates', () {
    // ✅ Can now test without Firebase!
    when(() => mockRepository.isDateRangeAvailable(
          propertyId: any(named: 'propertyId'),
          unitId: any(named: 'unitId'),
          checkIn: any(named: 'checkIn'),
          checkOut: any(named: 'checkOut'),
        )).thenAnswer((_) async => true);

    // Test your logic here
  });
}
```

---

### Step 1.6: Write Unit Tests (2-3 hours)

**New File:** `test/features/widget/domain/use_cases/validate_booking_dates_use_case_test.dart`
```dart
void main() {
  late ValidateBookingDatesUseCase useCase;
  late MockBookingCalendarRepository mockRepository;

  setUp(() {
    mockRepository = MockBookingCalendarRepository();
    useCase = ValidateBookingDatesUseCase(repository: mockRepository);
  });

  group('ValidateBookingDatesUseCase', () {
    test('should return success when dates are available', () async {
      // Arrange
      when(() => mockRepository.isDateRangeAvailable(
            propertyId: 'prop1',
            unitId: 'unit1',
            checkIn: DateTime(2025, 12, 10),
            checkOut: DateTime(2025, 12, 15),
          )).thenAnswer((_) async => true);

      // Act
      final result = await useCase.execute(
        propertyId: 'prop1',
        unitId: 'unit1',
        checkIn: DateTime(2025, 12, 10),
        checkOut: DateTime(2025, 12, 15),
      );

      // Assert
      expect(result.isSuccess, true);
      verify(() => mockRepository.isDateRangeAvailable(
            propertyId: 'prop1',
            unitId: 'unit1',
            checkIn: DateTime(2025, 12, 10),
            checkOut: DateTime(2025, 12, 15),
          )).called(1);
    });
  });
}
```

---

## PHASE 2: Decompose God Object (17-24 hours)

### Goal
Break 2649-line BookingWidgetScreen into maintainable pieces

---

### Step 2.1: Extract Business Logic → Use Cases (4-6 hours)

#### Use Case 1: Validate Booking Dates

**New File:** `lib/features/widget/domain/use_cases/validate_booking_dates_use_case.dart`
```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import '../repositories/i_booking_calendar_repository.dart';

part 'validate_booking_dates_use_case.freezed.dart';

/// Use case for validating booking date selection.
/// Checks availability, minimum nights, blocked dates, etc.
class ValidateBookingDatesUseCase {
  final IBookingCalendarRepository _repository;

  ValidateBookingDatesUseCase({required IBookingCalendarRepository repository})
      : _repository = repository;

  Future<ValidationResult> execute({
    required String propertyId,
    required String unitId,
    required DateTime checkIn,
    required DateTime checkOut,
    required int minNights,
  }) async {
    // 1. Check date order
    if (checkOut.isBefore(checkIn) || checkOut.isAtSameMomentAs(checkIn)) {
      return ValidationResult.failure(
        error: 'Check-out must be after check-in',
      );
    }

    // 2. Check minimum nights
    final nights = checkOut.difference(checkIn).inDays;
    if (nights < minNights) {
      return ValidationResult.failure(
        error: 'Minimum stay is $minNights nights',
      );
    }

    // 3. Check availability
    final isAvailable = await _repository.isDateRangeAvailable(
      propertyId: propertyId,
      unitId: unitId,
      checkIn: checkIn,
      checkOut: checkOut,
    );

    if (!isAvailable) {
      return ValidationResult.failure(
        error: 'Selected dates are not available',
      );
    }

    return ValidationResult.success();
  }
}

@freezed
class ValidationResult with _$ValidationResult {
  const factory ValidationResult.success() = _Success;
  const factory ValidationResult.failure({required String error}) = _Failure;
}
```

---

#### Use Case 2: Calculate Booking Price

**New File:** `lib/features/widget/domain/use_cases/calculate_booking_price_use_case.dart`
```dart
import '../services/i_price_calculator.dart';
import '../../../shared/models/additional_service_model.dart';

/// Use case for calculating total booking price.
/// Includes base price + additional services + taxes.
class CalculateBookingPriceUseCase {
  final IPriceCalculator _priceCalculator;

  CalculateBookingPriceUseCase({required IPriceCalculator priceCalculator})
      : _priceCalculator = priceCalculator;

  Future<BookingPriceCalculation> execute({
    required String propertyId,
    required String unitId,
    required DateTime checkIn,
    required DateTime checkOut,
    required int adults,
    required int children,
    required List<AdditionalServiceModel> selectedServices,
    required Map<String, int> serviceQuantities,
  }) async {
    // 1. Calculate base accommodation price
    final basePrice = await _priceCalculator.calculatePriceForRange(
      propertyId: propertyId,
      unitId: unitId,
      checkIn: checkIn,
      checkOut: checkOut,
    );

    if (basePrice == null) {
      throw Exception('Unable to calculate price for selected dates');
    }

    // 2. Calculate additional services total
    final nights = checkOut.difference(checkIn).inDays;
    final guests = adults + children;

    double servicesTotal = 0.0;
    for (final service in selectedServices) {
      final quantity = serviceQuantities[service.id] ?? 0;
      if (quantity > 0) {
        servicesTotal += service.calculateTotalPrice(
          quantity: quantity,
          nights: nights,
          guests: guests,
        );
      }
    }

    // 3. Calculate taxes (if applicable)
    final subtotal = basePrice + servicesTotal;
    final taxRate = 0.0; // Get from settings if needed
    final taxAmount = subtotal * taxRate;

    // 4. Calculate total
    final total = subtotal + taxAmount;

    return BookingPriceCalculation(
      basePrice: basePrice,
      servicesTotal: servicesTotal,
      subtotal: subtotal,
      taxAmount: taxAmount,
      total: total,
      nights: nights,
    );
  }
}

class BookingPriceCalculation {
  final double basePrice;
  final double servicesTotal;
  final double subtotal;
  final double taxAmount;
  final double total;
  final int nights;

  BookingPriceCalculation({
    required this.basePrice,
    required this.servicesTotal,
    required this.subtotal,
    required this.taxAmount,
    required this.total,
    required this.nights,
  });
}
```

---

#### Use Case 3: Submit Booking

**New File:** `lib/features/widget/domain/use_cases/submit_booking_use_case.dart`
```dart
import '../../../../core/services/booking_service.dart';
import '../../../../shared/models/booking_model.dart';
import '../../../owner_dashboard/domain/models/notification_model.dart';

/// Use case for submitting a booking request.
/// Handles validation, payment setup, and notifications.
class SubmitBookingUseCase {
  final BookingService _bookingService;

  SubmitBookingUseCase({required BookingService bookingService})
      : _bookingService = bookingService;

  Future<SubmissionResult> execute({
    required String unitId,
    required String propertyId,
    required String ownerId,
    required DateTime checkIn,
    required DateTime checkOut,
    required int adults,
    required int children,
    required String guestFirstName,
    required String guestLastName,
    required String guestEmail,
    required String guestPhone,
    required String? notes,
    required String paymentMethod,
    required String paymentOption,
    required double totalAmount,
    required Map<String, int> selectedServices,
  }) async {
    try {
      // 1. Create booking model
      final booking = BookingModel(
        id: '', // Generated by Firestore
        unitId: unitId,
        propertyId: propertyId,
        ownerId: ownerId,
        checkIn: checkIn,
        checkOut: checkOut,
        adults: adults,
        children: children,
        guestFirstName: guestFirstName,
        guestLastName: guestLastName,
        guestEmail: guestEmail,
        guestPhone: guestPhone,
        notes: notes,
        totalAmount: totalAmount,
        status: BookingStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // 2. Submit booking
      final result = await _bookingService.createBooking(
        booking: booking,
        paymentMethod: paymentMethod,
        paymentOption: paymentOption,
        selectedServices: selectedServices,
      );

      return SubmissionResult.success(
        bookingId: result.bookingId,
        redirectUrl: result.redirectUrl,
      );
    } catch (e) {
      return SubmissionResult.failure(error: e.toString());
    }
  }
}

@freezed
class SubmissionResult with _$SubmissionResult {
  const factory SubmissionResult.success({
    required String bookingId,
    String? redirectUrl,
  }) = _SubmissionSuccess;

  const factory SubmissionResult.failure({required String error}) =
      _SubmissionFailure;
}
```

---

### Step 2.2: Extract State Management → Notifiers (3-4 hours)

#### Notifier 1: Booking Validation State

**New File:** `lib/features/widget/presentation/state/booking_validation_notifier.dart`
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/use_cases/validate_booking_dates_use_case.dart';

part 'booking_validation_notifier.g.dart';

@freezed
class BookingValidationState with _$BookingValidationState {
  const factory BookingValidationState({
    @Default(false) bool isValidating,
    @Default(true) bool isValid,
    String? error,
  }) = _BookingValidationState;
}

@riverpod
class BookingValidationNotifier extends _$BookingValidationNotifier {
  @override
  BookingValidationState build() {
    return const BookingValidationState();
  }

  Future<void> validateDates({
    required String propertyId,
    required String unitId,
    required DateTime checkIn,
    required DateTime checkOut,
    required int minNights,
  }) async {
    state = state.copyWith(isValidating: true, error: null);

    final useCase = ref.read(validateBookingDatesUseCaseProvider);
    final result = await useCase.execute(
      propertyId: propertyId,
      unitId: unitId,
      checkIn: checkIn,
      checkOut: checkOut,
      minNights: minNights,
    );

    result.when(
      success: () {
        state = state.copyWith(
          isValidating: false,
          isValid: true,
          error: null,
        );
      },
      failure: (error) {
        state = state.copyWith(
          isValidating: false,
          isValid: false,
          error: error,
        );
      },
    );
  }
}
```

---

#### Notifier 2: Booking Submission State

**New File:** `lib/features/widget/presentation/state/booking_submission_notifier.dart`
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/use_cases/submit_booking_use_case.dart';

part 'booking_submission_notifier.g.dart';

@freezed
class BookingSubmissionState with _$BookingSubmissionState {
  const factory BookingSubmissionState.idle() = _Idle;
  const factory BookingSubmissionState.submitting() = _Submitting;
  const factory BookingSubmissionState.success({
    required String bookingId,
    String? redirectUrl,
  }) = _Success;
  const factory BookingSubmissionState.failure({required String error}) =
      _Failure;
}

@riverpod
class BookingSubmissionNotifier extends _$BookingSubmissionNotifier {
  @override
  BookingSubmissionState build() {
    return const BookingSubmissionState.idle();
  }

  Future<void> submitBooking({
    required String unitId,
    required String propertyId,
    required String ownerId,
    required DateTime checkIn,
    required DateTime checkOut,
    required int adults,
    required int children,
    required String guestFirstName,
    required String guestLastName,
    required String guestEmail,
    required String guestPhone,
    String? notes,
    required String paymentMethod,
    required String paymentOption,
    required double totalAmount,
    required Map<String, int> selectedServices,
  }) async {
    state = const BookingSubmissionState.submitting();

    final useCase = ref.read(submitBookingUseCaseProvider);
    final result = await useCase.execute(
      unitId: unitId,
      propertyId: propertyId,
      ownerId: ownerId,
      checkIn: checkIn,
      checkOut: checkOut,
      adults: adults,
      children: children,
      guestFirstName: guestFirstName,
      guestLastName: guestLastName,
      guestEmail: guestEmail,
      guestPhone: guestPhone,
      notes: notes,
      paymentMethod: paymentMethod,
      paymentOption: paymentOption,
      totalAmount: totalAmount,
      selectedServices: selectedServices,
    );

    result.when(
      success: (bookingId, redirectUrl) {
        state = BookingSubmissionState.success(
          bookingId: bookingId,
          redirectUrl: redirectUrl,
        );
      },
      failure: (error) {
        state = BookingSubmissionState.failure(error: error);
      },
    );
  }

  void reset() {
    state = const BookingSubmissionState.idle();
  }
}
```

---

### Step 2.3: Extract UI Components → Widgets (6-8 hours)

#### Widget 1: Calendar Section

**New File:** `lib/features/widget/presentation/widgets/booking_screen/booking_calendar_section.dart`
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../month_calendar_widget.dart';
import '../year_calendar_widget.dart';
import '../providers/calendar_view_provider.dart';
import '../../domain/models/calendar_view_type.dart';

/// Booking calendar section - handles year/month view switching.
/// Extracted from BookingWidgetScreen (lines 800-1200).
class BookingCalendarSection extends ConsumerWidget {
  final String propertyId;
  final String unitId;
  final DateTime? selectedCheckIn;
  final DateTime? selectedCheckOut;
  final Function(DateTime checkIn, DateTime checkOut) onDatesSelected;

  const BookingCalendarSection({
    super.key,
    required this.propertyId,
    required this.unitId,
    required this.selectedCheckIn,
    required this.selectedCheckOut,
    required this.onDatesSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calendarView = ref.watch(calendarViewProvider);

    return Column(
      children: [
        // Calendar view switcher (Year/Month toggle)
        CalendarViewSwitcher(
          currentView: calendarView,
          onViewChanged: (view) {
            ref.read(calendarViewProvider.notifier).state = view;
          },
        ),

        const SizedBox(height: 16),

        // Calendar widget
        Expanded(
          child: calendarView == CalendarViewType.year
              ? YearCalendarWidget(
                  propertyId: propertyId,
                  unitId: unitId,
                  selectedCheckIn: selectedCheckIn,
                  selectedCheckOut: selectedCheckOut,
                  onDateRangeSelected: onDatesSelected,
                )
              : MonthCalendarWidget(
                  propertyId: propertyId,
                  unitId: unitId,
                  selectedCheckIn: selectedCheckIn,
                  selectedCheckOut: selectedCheckOut,
                  onDateRangeSelected: onDatesSelected,
                ),
        ),
      ],
    );
  }
}
```

---

#### Widget 2: Guest Form Section

**New File:** `lib/features/widget/presentation/widgets/booking_screen/booking_guest_form_section.dart`
```dart
import 'package:flutter/material.dart';
import '../../../../shared/models/country.dart';
import '../booking/guest_form/guest_name_fields.dart';
import '../booking/guest_form/email_field_with_verification.dart';
import '../booking/guest_form/phone_field.dart';
import '../booking/guest_form/notes_field.dart';
import '../booking/guest_form/guest_count_picker.dart';

/// Guest information form section.
/// Extracted from BookingWidgetScreen (lines 1500-1800).
class BookingGuestFormSection extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController notesController;
  final Country selectedCountry;
  final Function(Country) onCountryChanged;
  final int adults;
  final int children;
  final Function(int) onAdultsChanged;
  final Function(int) onChildrenChanged;
  final int maxGuests;
  final bool requireEmailVerification;
  final bool emailVerified;
  final Function(String) onEmailChanged;
  final VoidCallback onVerifyPressed;
  final bool isDarkMode;

  const BookingGuestFormSection({
    super.key,
    required this.formKey,
    required this.firstNameController,
    required this.lastNameController,
    required this.emailController,
    required this.phoneController,
    required this.notesController,
    required this.selectedCountry,
    required this.onCountryChanged,
    required this.adults,
    required this.children,
    required this.onAdultsChanged,
    required this.onChildrenChanged,
    required this.maxGuests,
    required this.requireEmailVerification,
    required this.emailVerified,
    required this.onEmailChanged,
    required this.onVerifyPressed,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Guest count picker
          GuestCountPicker(
            adults: adults,
            children: children,
            maxGuests: maxGuests,
            onAdultsChanged: onAdultsChanged,
            onChildrenChanged: onChildrenChanged,
            isDarkMode: isDarkMode,
          ),

          const SizedBox(height: 16),

          // Name fields
          GuestNameFields(
            firstNameController: firstNameController,
            lastNameController: lastNameController,
            isDarkMode: isDarkMode,
          ),

          const SizedBox(height: 16),

          // Email field with verification
          EmailFieldWithVerification(
            controller: emailController,
            isDarkMode: isDarkMode,
            requireVerification: requireEmailVerification,
            emailVerified: emailVerified,
            onEmailChanged: onEmailChanged,
            onVerifyPressed: onVerifyPressed,
          ),

          const SizedBox(height: 16),

          // Phone field
          PhoneField(
            controller: phoneController,
            selectedCountry: selectedCountry,
            onCountryChanged: onCountryChanged,
            isDarkMode: isDarkMode,
          ),

          const SizedBox(height: 16),

          // Notes field
          NotesField(
            controller: notesController,
            isDarkMode: isDarkMode,
          ),
        ],
      ),
    );
  }
}
```

---

#### Widget 3: Payment Section

**New File:** `lib/features/widget/presentation/widgets/booking_screen/booking_payment_section.dart`
```dart
import 'package:flutter/material.dart';
import '../booking/payment/payment_option_widget.dart';
import '../booking/payment/payment_method_card.dart';
import '../booking/payment/no_payment_info.dart';
import '../../domain/models/widget_settings.dart';

/// Payment options and method selection section.
/// Extracted from BookingWidgetScreen (lines 1800-2000).
class BookingPaymentSection extends StatelessWidget {
  final WidgetSettings widgetSettings;
  final String selectedPaymentOption;
  final String selectedPaymentMethod;
  final Function(String) onPaymentOptionChanged;
  final Function(String) onPaymentMethodChanged;
  final double totalAmount;
  final double depositAmount;
  final bool isDarkMode;

  const BookingPaymentSection({
    super.key,
    required this.widgetSettings,
    required this.selectedPaymentOption,
    required this.selectedPaymentMethod,
    required this.onPaymentOptionChanged,
    required this.onPaymentMethodChanged,
    required this.totalAmount,
    required this.depositAmount,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    // Check if payment is enabled
    if (!widgetSettings.paymentConfig.enablePayments) {
      return const NoPaymentInfo();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Payment option (Full/Deposit)
        if (widgetSettings.paymentConfig.allowDeposit)
          PaymentOptionWidget(
            selectedOption: selectedPaymentOption,
            totalAmount: totalAmount,
            depositAmount: depositAmount,
            onOptionChanged: onPaymentOptionChanged,
            isDarkMode: isDarkMode,
          ),

        const SizedBox(height: 16),

        // Payment method cards
        ...widgetSettings.paymentConfig.paymentMethods.map(
          (method) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: PaymentMethodCard(
              method: method,
              isSelected: selectedPaymentMethod == method.id,
              onTap: () => onPaymentMethodChanged(method.id),
              isDarkMode: isDarkMode,
            ),
          ),
        ),
      ],
    );
  }
}
```

---

### Step 2.4: Refactor Main Screen (2-3 hours)

**After Refactoring:** `lib/features/widget/presentation/screens/booking_widget_screen.dart`

```dart
/// Main booking widget screen - REFACTORED.
/// Now acts as an orchestrator, delegating to specialized components.
///
/// BEFORE: 2649 lines, 30+ methods, 40+ state fields
/// AFTER:  <300 lines, ~10 methods, ~10 state fields
class _BookingWidgetScreenState extends ConsumerState<BookingWidgetScreen> {
  // ============ MINIMAL STATE ============
  late String _unitId;
  String? _propertyId;
  String? _ownerId;

  // Form state (delegated to BookingFormState)
  final _formState = BookingFormState();

  @override
  void initState() {
    super.initState();
    _initializeBooking();
  }

  Future<void> _initializeBooking() async {
    // Delegate to initialization use case
    final useCase = ref.read(initializeBookingUseCaseProvider);
    await useCase.execute(
      unitId: _unitId,
      propertyId: _propertyId,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch state from notifiers
    final validationState = ref.watch(bookingValidationNotifierProvider);
    final submissionState = ref.watch(bookingSubmissionNotifierProvider);
    final priceCalculation = ref.watch(bookingPriceProvider);

    // Listen for submission result
    ref.listen(bookingSubmissionNotifierProvider, (previous, next) {
      next.whenOrNull(
        success: (bookingId, redirectUrl) {
          _handleBookingSuccess(bookingId, redirectUrl);
        },
        failure: (error) {
          _showErrorDialog(error);
        },
      );
    });

    return Scaffold(
      body: Column(
        children: [
          // Calendar section (extracted widget)
          Expanded(
            child: BookingCalendarSection(
              propertyId: _propertyId!,
              unitId: _unitId,
              selectedCheckIn: _formState.checkIn,
              selectedCheckOut: _formState.checkOut,
              onDatesSelected: _handleDatesSelected,
            ),
          ),

          // Guest form section (extracted widget)
          if (_formState.showGuestForm)
            BookingGuestFormSection(
              formKey: _formState.formKey,
              firstNameController: _formState.firstNameController,
              lastNameController: _formState.lastNameController,
              emailController: _formState.emailController,
              phoneController: _formState.phoneController,
              notesController: _formState.notesController,
              selectedCountry: _formState.selectedCountry,
              onCountryChanged: (country) {
                setState(() => _formState.selectedCountry = country);
              },
              adults: _formState.adults,
              children: _formState.children,
              onAdultsChanged: (adults) {
                setState(() => _formState.adults = adults);
              },
              onChildrenChanged: (children) {
                setState(() => _formState.children = children);
              },
              maxGuests: _unit?.maxGuests ?? 10,
              requireEmailVerification: _widgetSettings?.emailConfig.requireEmailVerification ?? false,
              emailVerified: _formState.emailVerified,
              onEmailChanged: _handleEmailChanged,
              onVerifyPressed: _handleVerifyEmail,
              isDarkMode: Theme.of(context).brightness == Brightness.dark,
            ),

          // Payment section (extracted widget)
          if (_formState.showGuestForm && priceCalculation != null)
            BookingPaymentSection(
              widgetSettings: _widgetSettings!,
              selectedPaymentOption: _formState.selectedPaymentOption,
              selectedPaymentMethod: _formState.selectedPaymentMethod,
              onPaymentOptionChanged: (option) {
                setState(() => _formState.selectedPaymentOption = option);
              },
              onPaymentMethodChanged: (method) {
                setState(() => _formState.selectedPaymentMethod = method);
              },
              totalAmount: priceCalculation.total,
              depositAmount: priceCalculation.depositAmount,
              isDarkMode: Theme.of(context).brightness == Brightness.dark,
            ),

          // Submit button
          if (_formState.showGuestForm)
            _buildSubmitButton(submissionState),
        ],
      ),
    );
  }

  // ============ EVENT HANDLERS (delegated to use cases) ============

  void _handleDatesSelected(DateTime checkIn, DateTime checkOut) {
    setState(() {
      _formState.checkIn = checkIn;
      _formState.checkOut = checkOut;
    });

    // Delegate validation to use case (via notifier)
    ref.read(bookingValidationNotifierProvider.notifier).validateDates(
          propertyId: _propertyId!,
          unitId: _unitId,
          checkIn: checkIn,
          checkOut: checkOut,
          minNights: _widgetSettings?.minNights ?? 1,
        );
  }

  void _handleEmailChanged(String email) {
    // Delegate to email validation use case
    ref.read(emailValidationNotifierProvider.notifier).validateEmail(email);
  }

  void _handleVerifyEmail() {
    // Delegate to email verification use case
    ref.read(emailVerificationNotifierProvider.notifier).verifyEmail(
          email: _formState.emailController.text,
          unitId: _unitId,
        );
  }

  void _handleSubmit() {
    if (!_formState.formKey.currentState!.validate()) return;

    // Delegate submission to use case (via notifier)
    ref.read(bookingSubmissionNotifierProvider.notifier).submitBooking(
          unitId: _unitId,
          propertyId: _propertyId!,
          ownerId: _ownerId!,
          checkIn: _formState.checkIn!,
          checkOut: _formState.checkOut!,
          adults: _formState.adults,
          children: _formState.children,
          guestFirstName: _formState.firstNameController.text,
          guestLastName: _formState.lastNameController.text,
          guestEmail: _formState.emailController.text,
          guestPhone: _formState.phoneController.text,
          notes: _formState.notesController.text,
          paymentMethod: _formState.selectedPaymentMethod,
          paymentOption: _formState.selectedPaymentOption,
          totalAmount: ref.read(bookingPriceProvider)?.total ?? 0,
          selectedServices: ref.read(selectedAdditionalServicesProvider),
        );
  }

  void _handleBookingSuccess(String bookingId, String? redirectUrl) {
    if (redirectUrl != null) {
      // Redirect to Stripe checkout
      _redirectToStripe(redirectUrl);
    } else {
      // Navigate to confirmation
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BookingConfirmationScreen(
            bookingId: bookingId,
          ),
        ),
      );
    }
  }

  // ============ UI BUILDERS (minimal) ============

  Widget _buildSubmitButton(BookingSubmissionState state) {
    return state.maybeWhen(
      submitting: () => const CircularProgressIndicator(),
      orElse: () => ElevatedButton(
        onPressed: _handleSubmit,
        child: const Text('Confirm Booking'),
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Booking Error'),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ... minimal helper methods
}
```

---

## PHASE 3: Testing Infrastructure (8-10 hours)

### Test Coverage Targets
- **Use Cases:** 90% coverage (pure business logic)
- **Repositories:** 80% coverage (with mocks)
- **Widgets:** 70% coverage (extracted components)
- **Integration:** 50% coverage (critical flows)

---

## Rollout Strategy

### Week 1-2: Phase 1 (Decouple Firebase)
- Branch: `refactor/phase1-decouple-firebase`
- Low risk, high value
- Enables testing infrastructure

### Week 3-4: Phase 2 (Decompose God Object)
- Branch: `refactor/phase2-decompose-god-object`
- High risk, requires careful testing
- Incremental approach (one section at a time)

### Week 5: Phase 3 (Testing)
- Branch: same as Phase 2
- Add tests as sections are extracted
- Ensure no regressions

### Week 6: Stabilization & Merge
- Code review
- Performance testing
- Bug fixes
- Merge to main

---

## Success Metrics

| Metric | Before | After | Target |
|--------|--------|-------|--------|
| BookingWidgetScreen LOC | 2649 | <300 | ✅ 90% reduction |
| Repository Dependencies | Direct Firebase | Abstracted | ✅ Swappable |
| Unit Test Coverage | 0% | 80%+ | ✅ Testable |
| Methods per Class | 30+ | <10 | ✅ Cohesive |
| Time to Add Feature | 2-3 days | 4-6 hours | ✅ 4x faster |

---

## Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|-----------|
| Regressions | Medium | High | Comprehensive testing + incremental rollout |
| Performance | Low | Medium | Profiling before/after |
| Scope creep | Medium | Medium | Stick to plan, no "while we're here" changes |
| Team disruption | Low | Low | Branch-based development |

---

## Conclusion

This refactoring addresses critical architectural debt:
- **Problem 55 (Tight coupling):** Solved with abstraction layers
- **Problem 56 (God object):** Solved with decomposition + use cases

**Total investment:** 4-6 weeks
**Long-term ROI:** 5x faster feature development, 10x better testability

**Recommendation:** Proceed with Phase 1 (low risk, high value).
