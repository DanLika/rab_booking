# Booking Widget Refactoring Plan

**Datum kreiranja:** 2025-12-02
**Status:** PENDING APPROVAL
**Target File:** `lib/features/widget/presentation/screens/booking_widget_screen.dart`
**Trenutno stanje:** 2,145 linija
**Ciljno stanje:** <1,000 linija (-53%)

---

## Executive Summary

`booking_widget_screen.dart` je srce javnog booking widgeta - embedded komponenta koju vlasnici ugrađuju na svoje web stranice. Fajl trenutno ima **2,145 linija** (prošao jedan refactoring sa 4,238 linija).

**Cilj ovog plana:** Smanjiti na **<1,000 linija** kroz 3-phase incremental refactoring bez breaking changes.

**Procjena:** 8-11 radnih dana (16-22 dana sa buffer-om za solo dev)

---

## Table of Contents

1. [Trenutno Stanje - Strukturna Analiza](#1-trenutno-stanje---strukturna-analiza)
2. [Identifikovani Problemi](#2-identifikovani-problemi)
3. [Phase 1: Widget Extraction (LOW RISK)](#3-phase-1-widget-extraction-low-risk)
4. [Phase 2: State Management Refactoring (MEDIUM RISK)](#4-phase-2-state-management-refactoring-medium-risk)
5. [Phase 3: Business Logic Extraction (MEDIUM RISK)](#5-phase-3-business-logic-extraction-medium-risk)
6. [File Changes Summary](#6-file-changes-summary)
7. [Risk Assessment & Mitigation](#7-risk-assessment--mitigation)
8. [Testing Strategy](#8-testing-strategy)
9. [Rollout Plan](#9-rollout-plan)
10. [Estimation & Timeline](#10-estimation--timeline)
11. [Success Criteria](#11-success-criteria)
12. [Decision Matrix](#12-decision-matrix)

---

## 1. Trenutno Stanje - Strukturna Analiza

### Code Distribution (Line Count Breakdown)

```
booking_widget_screen.dart (2,145 lines total)
│
├── State Management (Lines 66-111)              [45 lines]   2.1%
│   ├── Date selection state (_checkIn, _checkOut)
│   ├── Form controllers (5x TextEditingController)
│   ├── Guest count (_adults, _children)
│   ├── UI state (_showGuestForm, _isProcessing, etc.)
│   └── Price lock (_lockedPriceCalculation)
│
├── Lifecycle & Initialization (Lines 113-238)   [125 lines]  5.8%
│   ├── initState() - URL parsing, validation, persistence
│   ├── _validateUnitAndProperty() - 80 lines
│   ├── _loadWidgetSettings() - 25 lines
│   └── dispose() - Controller cleanup
│
├── Form Persistence (Lines 305-438)             [133 lines]  6.2%
│   ├── _saveFormData() - SharedPreferences save
│   ├── _loadFormData() - Cache restore
│   └── _clearFormData() - Cleanup after booking
│
├── Main Build Method (Lines 458-721)            [263 lines]  12.2%
│   ├── Theme setup, loading/error states
│   ├── Responsive layout logic (breakpoints)
│   ├── Calendar integration (CalendarViewSwitcher)
│   ├── Contact pill card (calendar-only mode)
│   ├── Floating pill bar orchestration
│   └── Rotate device overlay
│
├── Contact Pill Card (Lines 732-898)            [166 lines]  7.7%
│   ├── _buildContactPillCard()
│   ├── _buildDesktopContactRow()
│   └── _buildMobileContactColumn()
│
├── Floating Pill Bar (Lines 901-1,117)          [216 lines]  10.1%
│   ├── _buildFloatingDraggablePillBar()
│   ├── Price calculation integration
│   ├── Drag-to-dismiss logic
│   └── PillBarContent builders
│
├── Payment Section (Lines 1,119-1,414)          [295 lines]  13.7%  ← LARGEST
│   ├── _buildPaymentSection()
│   ├── Payment validation
│   ├── Auto-select single payment method
│   ├── Multiple payment method selectors
│   └── Confirm button with dynamic text
│
├── Guest Info Form (Lines 1,416-1,581)          [165 lines]  7.7%
│   ├── _buildGuestInfoForm()
│   ├── GuestNameFields, EmailFieldWithVerification
│   ├── PhoneField with CountryCodeDropdown
│   └── NotesField, GuestCountPicker
│
├── Button Text Logic (Lines 1,583-1,609)        [26 lines]   1.2%
│   └── _getConfirmButtonText()
│
├── Booking Confirmation (Lines 1,611-1,828)     [217 lines]  10.1%
│   ├── _handleConfirmBooking()
│   ├── bookingPending vs bookingInstant flow
│   ├── Stripe/Bank/Pay on Arrival routing
│   └── Error handling
│
├── Navigation Helper (Lines 1,832-1,882)        [50 lines]   2.3%
│   └── _navigateToConfirmationAndCleanup()
│
├── Email Notifications (Lines 1,884-1,938)      [54 lines]   2.5%
│   └── _sendBookingEmails()
│
├── Stripe Payment (Lines 1,940-1,986)           [46 lines]   2.1%
│   └── _handleStripePayment()
│
├── Stripe Return (Lines 1,988-2,101)            [113 lines]  5.3%
│   ├── _showConfirmationFromUrl()
│   └── Webhook polling (Bug #40 fix)
│
├── Rotate Overlay Logic (Lines 2,103-2,123)     [20 lines]   0.9%
│   └── _shouldShowRotateOverlay()
│
└── Email Verification (Lines 2,125-2,145)       [20 lines]   0.9%
    └── _openVerificationDialog()
```

### TOP 5 Hotspots (Largest Components)

| Component | Lines | % | Complexity |
|-----------|-------|---|-----------|
| **Payment Section** | 295 | 13.7% | HIGH - Payment method logic, auto-select, validation |
| **Main Build** | 263 | 12.2% | MEDIUM - Orchestration, responsive layout |
| **Booking Confirmation** | 217 | 10.1% | HIGH - Validation, flow split, error handling |
| **Floating Pill Bar** | 216 | 10.1% | MEDIUM - Price calc, drag logic, positioning |
| **Guest Info Form** | 165 | 7.7% | LOW - Mostly widget composition |

---

## 2. Identifikovani Problemi

### Problem 1: GOD OBJECT Anti-Pattern

```dart
class _BookingWidgetScreenState extends ConsumerState<BookingWidgetScreen> {
  // TOO MANY RESPONSIBILITIES:
  // 1. URL parsing & validation
  // 2. Widget settings management
  // 3. Form state management
  // 4. Payment orchestration
  // 5. Email notifications
  // 6. Stripe integration
  // 7. UI state management
  // 8. Persistence logic
  // 9. Price calculation
  // 10. Booking creation
}
```

**Impact:** 12+ state variables, 20+ methods, 2,145 lines

### Problem 2: Build Method Size

Main `build()` metoda ima **263 linija** - trebalo bi biti <50.

### Problem 3: Payment Section Complexity

`_buildPaymentSection()` ima **295 linija** sa:
- Payment validation
- Auto-select logic
- Multiple nested conditionals
- Hard to test in isolation

### Problem 4: Booking Confirmation Method

`_handleConfirmBooking()` ima **217 linija** sa:
- Validation
- Mode splitting (pending vs instant)
- Payment routing
- Error handling
- Too many responsibilities

---

## 3. Phase 1: Widget Extraction (LOW RISK)

**Cilj:** Ekstraktovati preostale build helper metode u zasebne stateless widgets

**Procjena:** ~680 linija ekstrakovano, **2 dana rada**

**Rizik:** 🟢 LOW - Samo prebacivanje koda, callbacks ostaju isti

### 3.1 ContactSectionWidget

**Ekstrahovati:** Lines 732-898 (166 lines)

**Trenutno:**
```dart
Widget _buildContactPillCard(bool isDarkMode, double screenWidth)
Widget _buildDesktopContactRow(ContactOptions? contactOptions, bool isDarkMode)
Widget _buildMobileContactColumn(ContactOptions? contactOptions, bool isDarkMode)
```

**Novo:**
```dart
// lib/features/widget/presentation/widgets/booking/contact_section.dart

class ContactSectionWidget extends StatelessWidget {
  final ContactOptions? contactOptions;
  final bool isDarkMode;
  final double screenWidth;
  final Future<void> Function(String url) onLaunchUrl;

  const ContactSectionWidget({
    super.key,
    required this.contactOptions,
    required this.isDarkMode,
    required this.screenWidth,
    required this.onLaunchUrl,
  });

  @override
  Widget build(BuildContext context) {
    final hasEmail = contactOptions?.showEmail == true &&
        contactOptions?.emailAddress != null &&
        contactOptions!.emailAddress!.isNotEmpty;
    final hasPhone = contactOptions?.showPhone == true &&
        contactOptions?.phoneNumber != null &&
        contactOptions!.phoneNumber!.isNotEmpty;

    if (!hasEmail && !hasPhone) {
      return const SizedBox.shrink();
    }

    final useRowLayout = screenWidth >= 350;
    final maxWidth = useRowLayout ? 500.0 : 200.0;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDarkMode
                ? MinimalistColorsDark.backgroundSecondary
                : MinimalistColors.backgroundSecondary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDarkMode
                  ? MinimalistColorsDark.borderDefault
                  : MinimalistColors.borderDefault,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: useRowLayout
              ? _buildDesktopRow(hasEmail, hasPhone)
              : _buildMobileColumn(hasEmail, hasPhone),
        ),
      ),
    );
  }

  Widget _buildDesktopRow(bool hasEmail, bool hasPhone) {
    // ... existing _buildDesktopContactRow logic
  }

  Widget _buildMobileColumn(bool hasEmail, bool hasPhone) {
    // ... existing _buildMobileContactColumn logic
  }
}
```

**Korištenje u main fajlu:**
```dart
// BEFORE (in build method):
_buildContactPillCard(isDarkMode, screenWidth)

// AFTER:
ContactSectionWidget(
  contactOptions: _widgetSettings?.contactOptions,
  isDarkMode: isDarkMode,
  screenWidth: screenWidth,
  onLaunchUrl: _launchUrl,
)
```

**Benefit:** -166 linija, isolated component, reusable

---

### 3.2 PaymentSectionWidget

**Ekstrahovati:** Lines 1,119-1,414 (295 lines)

**Novo:**
```dart
// lib/features/widget/presentation/widgets/booking/payment/payment_section_widget.dart

class PaymentSectionWidget extends StatelessWidget {
  final WidgetSettings? widgetSettings;
  final BookingPriceCalculation calculation;
  final String selectedPaymentMethod;
  final ValueChanged<String> onPaymentMethodChanged;
  final bool isProcessing;
  final VoidCallback onConfirmPressed;
  final bool isDarkMode;

  const PaymentSectionWidget({
    super.key,
    required this.widgetSettings,
    required this.calculation,
    required this.selectedPaymentMethod,
    required this.onPaymentMethodChanged,
    required this.isProcessing,
    required this.onConfirmPressed,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final getColor = ThemeColorsHelper.createColorGetter(isDarkMode);

    // Safety check: At least one payment method must be available
    final hasAnyPaymentMethod =
        (widgetSettings?.stripeConfig?.enabled == true) ||
        (widgetSettings?.bankTransferConfig?.enabled == true) ||
        (widgetSettings?.allowPayOnArrival == true);

    if (widgetSettings?.widgetMode == WidgetMode.bookingInstant &&
        !hasAnyPaymentMethod) {
      return _buildNoPaymentMethodsError(getColor);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Payment method section (only for bookingInstant mode)
        if (widgetSettings?.widgetMode == WidgetMode.bookingInstant) ...[
          _buildPaymentMethodSelector(getColor),
          const SizedBox(height: SpacingTokens.m),
        ],

        // Info message for bookingPending mode
        if (widgetSettings?.widgetMode == WidgetMode.bookingPending) ...[
          InfoCardWidget(
            message: 'Your booking will be pending until confirmed by the property owner',
            isDarkMode: isDarkMode,
          ),
          const SizedBox(height: SpacingTokens.m),
        ],

        // Confirm button
        _buildConfirmButton(getColor),
      ],
    );
  }

  Widget _buildNoPaymentMethodsError(Color Function(Color, Color) getColor) {
    // ... error UI
  }

  Widget _buildPaymentMethodSelector(Color Function(Color, Color) getColor) {
    // Count enabled payment methods
    final isStripeEnabled = widgetSettings?.stripeConfig?.enabled == true;
    final isBankTransferEnabled = widgetSettings?.bankTransferConfig?.enabled == true;
    final isPayOnArrivalEnabled = widgetSettings?.allowPayOnArrival == true;

    int enabledCount = 0;
    if (isStripeEnabled) enabledCount++;
    if (isBankTransferEnabled) enabledCount++;
    if (isPayOnArrivalEnabled) enabledCount++;

    // Single method: auto-select and show simplified UI
    if (enabledCount == 1) {
      return _buildSingleMethodInfo(getColor, isStripeEnabled, isBankTransferEnabled, isPayOnArrivalEnabled);
    }

    // Multiple methods: show selector
    return _buildMultipleMethodSelector(getColor, isStripeEnabled, isBankTransferEnabled, isPayOnArrivalEnabled);
  }

  Widget _buildSingleMethodInfo(...) {
    // ... single payment method info card
  }

  Widget _buildMultipleMethodSelector(...) {
    // ... payment method radio buttons
  }

  Widget _buildConfirmButton(Color Function(Color, Color) getColor) {
    // ... confirm button with dynamic text
  }

  String _getConfirmButtonText() {
    // ... button text logic (move from main file)
  }
}
```

**Korištenje u main fajlu:**
```dart
// BEFORE:
_buildPaymentSection(calculation)

// AFTER:
PaymentSectionWidget(
  widgetSettings: _widgetSettings,
  calculation: calculation,
  selectedPaymentMethod: _selectedPaymentMethod,
  onPaymentMethodChanged: (method) => setState(() => _selectedPaymentMethod = method),
  isProcessing: _isProcessing,
  onConfirmPressed: () => _handleConfirmBooking(calculation),
  isDarkMode: isDarkMode,
)
```

**Benefit:** -295 linija, testable payment logic

---

### 3.3 BookingBarContainer

**Ekstrahovati:** Lines 901-1,117 (216 lines)

**Novo:**
```dart
// lib/features/widget/presentation/widgets/booking/booking_bar_container.dart

class BookingBarContainer extends ConsumerWidget {
  final String unitId;
  final DateTime checkIn;
  final DateTime checkOut;
  final BoxConstraints constraints;
  final bool isDarkMode;
  final bool showGuestForm;
  final Offset? position;
  final int depositPercentage;
  final ValueChanged<Offset?> onPositionChanged;
  final VoidCallback onClose;
  final VoidCallback onReserve;
  final Widget Function(BookingPriceCalculation) guestFormBuilder;
  final Widget Function(BookingPriceCalculation) paymentSectionBuilder;
  final WidgetBuilder additionalServicesBuilder;
  final WidgetBuilder taxLegalBuilder;

  const BookingBarContainer({
    super.key,
    required this.unitId,
    required this.checkIn,
    required this.checkOut,
    required this.constraints,
    required this.isDarkMode,
    required this.showGuestForm,
    required this.position,
    required this.depositPercentage,
    required this.onPositionChanged,
    required this.onClose,
    required this.onReserve,
    required this.guestFormBuilder,
    required this.paymentSectionBuilder,
    required this.additionalServicesBuilder,
    required this.taxLegalBuilder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final priceCalc = ref.watch(
      bookingPriceProvider(
        unitId: unitId,
        checkIn: checkIn,
        checkOut: checkOut,
        depositPercentage: depositPercentage,
      ),
    );

    return priceCalc.when(
      data: (calculationBase) {
        if (calculationBase == null) {
          return const SizedBox.shrink();
        }

        // Watch additional services
        final servicesAsync = ref.watch(unitAdditionalServicesProvider(unitId));
        final selectedServices = ref.watch(selectedAdditionalServicesProvider);

        // Calculate services total
        double servicesTotal = 0.0;
        servicesAsync.whenData((services) {
          if (services.isNotEmpty && selectedServices.isNotEmpty) {
            servicesTotal = ref.read(
              additionalServicesTotalProvider((
                services,
                selectedServices,
                checkOut.difference(checkIn).inDays,
                // Note: guests count needs to be passed
              )),
            );
          }
        });

        final calculation = calculationBase.copyWithServices(
          servicesTotal,
          depositPercentage,
        );

        return _buildPillBar(context, calculation);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildPillBar(BuildContext context, BookingPriceCalculation calculation) {
    // Calculate responsive dimensions
    final screenWidth = constraints.maxWidth;
    final screenHeight = constraints.maxHeight;

    double pillBarWidth;
    double maxHeight;

    if (showGuestForm) {
      // Step 2: Full form
      if (screenWidth < 600) {
        pillBarWidth = screenWidth * 0.95;
        maxHeight = screenHeight * 0.9;
      } else if (screenWidth < 1024) {
        pillBarWidth = screenWidth * 0.8;
        maxHeight = screenHeight * 0.8;
      } else {
        pillBarWidth = screenWidth * 0.7;
        maxHeight = screenHeight * 0.7;
      }
    } else {
      // Step 1: Compact
      pillBarWidth = screenWidth < 600 ? 350.0 : 400.0;
      maxHeight = 282.0;
    }

    // Calculate default position
    final defaultPosition = Offset(
      (constraints.maxWidth / 2) - (pillBarWidth / 2),
      (constraints.maxHeight / 2) - (maxHeight / 2),
    );

    final currentPosition = position ?? defaultPosition;

    // Drag-to-dismiss logic
    final isMoreThanHalfOffScreen = _checkIfMoreThanHalfOffScreen(
      currentPosition,
      pillBarWidth,
      maxHeight,
    );

    final isCompletelyOffScreen = _checkIfCompletelyOffScreen(
      currentPosition,
      pillBarWidth,
      maxHeight,
    );

    if (isCompletelyOffScreen) {
      return const SizedBox.shrink();
    }

    return BookingPillBar(
      position: currentPosition,
      width: pillBarWidth,
      maxHeight: maxHeight,
      isDarkMode: isDarkMode,
      keyboardInset: MediaQuery.of(context).viewInsets.bottom,
      onDragUpdate: (delta) {
        onPositionChanged(Offset(
          currentPosition.dx + delta.dx,
          currentPosition.dy + delta.dy,
        ));
      },
      onDragEnd: () {
        if (isMoreThanHalfOffScreen) {
          onClose();
        }
      },
      child: PillBarContent(
        checkIn: checkIn,
        checkOut: checkOut,
        nights: checkOut.difference(checkIn).inDays,
        formattedRoomPrice: calculation.formattedRoomPrice,
        additionalServicesTotal: calculation.additionalServicesTotal,
        formattedAdditionalServices: calculation.formattedAdditionalServices,
        formattedTotal: calculation.formattedTotal,
        formattedDeposit: calculation.formattedDeposit,
        depositPercentage: calculation.totalPrice > 0
            ? ((calculation.depositAmount / calculation.totalPrice) * 100).round()
            : 20,
        isDarkMode: isDarkMode,
        showGuestForm: showGuestForm,
        isWideScreen: MediaQuery.of(context).size.width >= 768,
        onClose: onClose,
        onReserve: onReserve,
        guestFormBuilder: () => guestFormBuilder(calculation),
        paymentSectionBuilder: () => paymentSectionBuilder(calculation),
        additionalServicesBuilder: additionalServicesBuilder,
        taxLegalBuilder: taxLegalBuilder,
      ),
    );
  }

  bool _checkIfMoreThanHalfOffScreen(Offset pos, double width, double height) {
    return pos.dx < -width / 2 ||
        pos.dy < -height / 2 ||
        pos.dx > constraints.maxWidth - width / 2 ||
        pos.dy > constraints.maxHeight - height / 2;
  }

  bool _checkIfCompletelyOffScreen(Offset pos, double width, double height) {
    return pos.dx + width < 0 ||
        pos.dy + height < 0 ||
        pos.dx > constraints.maxWidth ||
        pos.dy > constraints.maxHeight;
  }
}
```

**Benefit:** -216 linija, isolated drag logic

---

### Phase 1 Summary

| Widget | Lines Extracted | New File |
|--------|----------------|----------|
| ContactSectionWidget | 166 | `widgets/booking/contact_section.dart` |
| PaymentSectionWidget | 295 | `widgets/booking/payment/payment_section_widget.dart` |
| BookingBarContainer | 216 | `widgets/booking/booking_bar_container.dart` |
| **TOTAL** | **677** | 3 new files |

**Remaining in main file:** 2,145 - 677 = **~1,468 linija**

---

## 4. Phase 2: State Management Refactoring (MEDIUM RISK)

**Cilj:** Razdvojiti UI state i business state u zasebne providers

**Procjena:** ~180 linija refactored, **3-4 dana rada**

**Rizik:** 🟡 MEDIUM - Riverpod migration zahtijeva pažljivo testiranje

### 4.1 BookingFormProvider

**Problem:** Form state scattered across 12+ variables

**Novo:**
```dart
// lib/features/widget/presentation/providers/booking_form_provider.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../widgets/country_code_dropdown.dart';

part 'booking_form_provider.freezed.dart';
part 'booking_form_provider.g.dart';

@freezed
class BookingFormState with _$BookingFormState {
  const factory BookingFormState({
    @Default('') String firstName,
    @Default('') String lastName,
    @Default('') String email,
    @Default('') String phone,
    @Default(2) int adults,
    @Default(0) int children,
    @Default('') String notes,
    @Default(false) bool emailVerified,
    @Default(false) bool taxLegalAccepted,
    Country? selectedCountry,
  }) = _BookingFormState;

  factory BookingFormState.fromJson(Map<String, dynamic> json) =>
      _$BookingFormStateFromJson(json);
}

@riverpod
class BookingFormNotifier extends _$BookingFormNotifier {
  static const String _formDataKey = 'booking_widget_form_data';

  // Text controllers - managed by provider
  late final TextEditingController firstNameController;
  late final TextEditingController lastNameController;
  late final TextEditingController emailController;
  late final TextEditingController phoneController;
  late final TextEditingController notesController;

  @override
  BookingFormState build(String unitId) {
    // Initialize controllers
    firstNameController = TextEditingController();
    lastNameController = TextEditingController();
    emailController = TextEditingController();
    phoneController = TextEditingController();
    notesController = TextEditingController();

    // Setup listeners for auto-save
    firstNameController.addListener(() => _onFieldChanged('firstName', firstNameController.text));
    lastNameController.addListener(() => _onFieldChanged('lastName', lastNameController.text));
    emailController.addListener(() => _onFieldChanged('email', emailController.text));
    phoneController.addListener(() => _onFieldChanged('phone', phoneController.text));
    notesController.addListener(() => _onFieldChanged('notes', notesController.text));

    // Load persisted data
    _loadPersistedData(unitId);

    // Cleanup on dispose
    ref.onDispose(() {
      firstNameController.dispose();
      lastNameController.dispose();
      emailController.dispose();
      phoneController.dispose();
      notesController.dispose();
    });

    return BookingFormState(
      selectedCountry: defaultCountry,
    );
  }

  void _onFieldChanged(String field, String value) {
    switch (field) {
      case 'firstName':
        state = state.copyWith(firstName: value);
        break;
      case 'lastName':
        state = state.copyWith(lastName: value);
        break;
      case 'email':
        state = state.copyWith(email: value, emailVerified: false);
        break;
      case 'phone':
        state = state.copyWith(phone: value);
        break;
      case 'notes':
        state = state.copyWith(notes: value);
        break;
    }
    _saveToCache();
  }

  void updateAdults(int value) {
    state = state.copyWith(adults: value);
    _saveToCache();
  }

  void updateChildren(int value) {
    state = state.copyWith(children: value);
    _saveToCache();
  }

  void updateCountry(Country country) {
    state = state.copyWith(selectedCountry: country);
    _saveToCache();
  }

  void setEmailVerified(bool verified) {
    state = state.copyWith(emailVerified: verified);
    _saveToCache();
  }

  void setTaxLegalAccepted(bool accepted) {
    state = state.copyWith(taxLegalAccepted: accepted);
    _saveToCache();
  }

  void resetForm() {
    firstNameController.clear();
    lastNameController.clear();
    emailController.clear();
    phoneController.clear();
    notesController.clear();

    state = BookingFormState(
      selectedCountry: defaultCountry,
    );

    _clearCache();
  }

  String get fullName => '${state.firstName} ${state.lastName}'.trim();
  String get fullPhone => '${state.selectedCountry?.dialCode ?? ''} ${state.phone}'.trim();
  int get totalGuests => state.adults + state.children;

  Future<void> _saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        ...state.toJson(),
        'timestamp': DateTime.now().toIso8601String(),
      };
      await prefs.setString('${_formDataKey}_${ref.read(unitIdProvider)}', jsonEncode(data));
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> _loadPersistedData(String unitId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedData = prefs.getString('${_formDataKey}_$unitId');

      if (savedData == null) return;

      final data = jsonDecode(savedData) as Map<String, dynamic>;

      // Check if data is not too old (max 24 hours)
      final timestamp = DateTime.parse(data['timestamp'] as String);
      if (DateTime.now().difference(timestamp).inHours > 24) {
        await _clearCache();
        return;
      }

      // Restore state
      state = BookingFormState.fromJson(data);

      // Sync controllers with state
      firstNameController.text = state.firstName;
      lastNameController.text = state.lastName;
      emailController.text = state.email;
      phoneController.text = state.phone;
      notesController.text = state.notes;
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> _clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('${_formDataKey}_${ref.read(unitIdProvider)}');
    } catch (e) {
      // Silent fail
    }
  }
}

// Helper provider to access unit ID
@riverpod
String unitId(UnitIdRef ref) => '';
```

**Benefit:** Form state centralizovan, auto-save/load u provider lifecycle

---

### 4.2 BookingFlowProvider

**Problem:** UI state scattered across multiple variables

**Novo:**
```dart
// lib/features/widget/presentation/providers/booking_flow_provider.dart

import 'dart:ui';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'booking_flow_provider.freezed.dart';
part 'booking_flow_provider.g.dart';

@freezed
class BookingFlowState with _$BookingFlowState {
  const factory BookingFlowState({
    DateTime? checkIn,
    DateTime? checkOut,
    @Default(false) bool showGuestForm,
    @Default(false) bool isProcessing,
    Offset? pillBarPosition,
    @Default(false) bool pillBarDismissed,
    @Default(false) bool hasInteracted,
  }) = _BookingFlowState;
}

@riverpod
class BookingFlowNotifier extends _$BookingFlowNotifier {
  @override
  BookingFlowState build(String unitId) {
    // Could restore from cache if needed
    return const BookingFlowState();
  }

  void selectDates(DateTime? checkIn, DateTime? checkOut) {
    state = state.copyWith(
      checkIn: checkIn,
      checkOut: checkOut,
      hasInteracted: checkIn != null && checkOut != null,
      pillBarDismissed: false, // Reset on new selection
      pillBarPosition: null, // Reset position
    );
  }

  void clearDates() {
    state = state.copyWith(
      checkIn: null,
      checkOut: null,
      showGuestForm: false,
      pillBarPosition: null,
    );
  }

  void showGuestForm() {
    state = state.copyWith(
      showGuestForm: true,
      hasInteracted: true,
    );
  }

  void hideGuestForm() {
    state = state.copyWith(showGuestForm: false);
  }

  void dismissPillBar() {
    state = state.copyWith(
      pillBarDismissed: true,
      showGuestForm: false,
      pillBarPosition: null,
    );
  }

  void updatePillBarPosition(Offset? position) {
    state = state.copyWith(pillBarPosition: position);
  }

  void setProcessing(bool processing) {
    state = state.copyWith(isProcessing: processing);
  }

  void resetFlow() {
    state = const BookingFlowState();
  }

  // Computed getters
  int get nights => state.checkIn != null && state.checkOut != null
      ? state.checkOut!.difference(state.checkIn!).inDays
      : 0;

  bool get hasDatesSelected => state.checkIn != null && state.checkOut != null;

  bool get shouldShowPillBar =>
      hasDatesSelected && state.hasInteracted && !state.pillBarDismissed;
}
```

**Benefit:** UI state lifecycle jasno definiran, lakše trackovati state transitions

---

### Phase 2 Summary

| Provider | Lines | New File |
|----------|-------|----------|
| BookingFormProvider | ~150 | `providers/booking_form_provider.dart` |
| BookingFlowProvider | ~80 | `providers/booking_flow_provider.dart` |
| **TOTAL** | **~230** | 2 new files + generated |

**Remaining in main file:** 1,468 - 180 = **~1,288 linija**

---

## 5. Phase 3: Business Logic Extraction (MEDIUM RISK)

**Cilj:** Izvući business logic u service layer

**Procjena:** ~380 linija ekstrakovano, **2-3 dana rada**

**Rizik:** 🟡 MEDIUM - Service integration sa existing providers

### 5.1 BookingSubmissionService

**Ekstrahovati:** Lines 1,611-1,828 (217 lines) + email logic (54 lines)

**Novo:**
```dart
// lib/features/widget/domain/services/booking_submission_service.dart

import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/models/widget_settings.dart';
import '../../domain/models/widget_mode.dart';
import '../../../../shared/models/booking_model.dart';
import '../../../../core/services/booking_service.dart';
import '../../../../core/services/email_notification_service.dart';
import 'booking_validation_service.dart';
import 'price_lock_service.dart';

part 'booking_submission_service.freezed.dart';

@freezed
class BookingSubmissionParams with _$BookingSubmissionParams {
  const factory BookingSubmissionParams({
    required String unitId,
    required String propertyId,
    required String ownerId,
    required DateTime checkIn,
    required DateTime checkOut,
    required String guestName,
    required String guestEmail,
    required String guestPhone,
    required int guestCount,
    required double totalPrice,
    required String paymentOption,
    required String paymentMethod,
    required bool requireOwnerApproval,
    String? notes,
    bool? taxLegalAccepted,
  }) = _BookingSubmissionParams;
}

@freezed
sealed class BookingSubmissionResult with _$BookingSubmissionResult {
  const factory BookingSubmissionResult.success({
    required BookingModel booking,
    required String paymentMethod,
  }) = BookingSubmissionSuccess;

  const factory BookingSubmissionResult.stripePaymentRequired({
    required BookingModel booking,
  }) = BookingSubmissionStripePayment;

  const factory BookingSubmissionResult.validationFailed({
    String? errorMessage,
    Duration? snackBarDuration,
  }) = BookingSubmissionValidationFailed;

  const factory BookingSubmissionResult.conflict({
    required String errorMessage,
  }) = BookingSubmissionConflict;

  const factory BookingSubmissionResult.cancelled() = BookingSubmissionCancelled;

  const factory BookingSubmissionResult.error({
    required String errorMessage,
  }) = BookingSubmissionError;
}

class BookingSubmissionService {
  final BookingService _bookingService;
  final EmailNotificationService _emailService;

  BookingSubmissionService({
    required BookingService bookingService,
    required EmailNotificationService emailService,
  })  : _bookingService = bookingService,
        _emailService = emailService;

  Future<BookingSubmissionResult> submitBooking({
    required BookingSubmissionParams params,
    required WidgetSettings widgetSettings,
    required BookingPriceCalculation currentCalculation,
    BookingPriceCalculation? lockedCalculation,
    required GlobalKey<FormState> formKey,
    required bool emailVerified,
    required bool taxLegalAccepted,
    required int maxGuests,
  }) async {
    // 1. Validate all inputs
    final validationResult = BookingValidationService.validateAllBlocking(
      formKey: formKey,
      requireEmailVerification: widgetSettings.emailConfig.requireEmailVerification,
      emailVerified: emailVerified,
      taxConfig: widgetSettings.taxLegalConfig,
      taxLegalAccepted: taxLegalAccepted,
      checkIn: params.checkIn,
      checkOut: params.checkOut,
      propertyId: params.propertyId,
      ownerId: params.ownerId,
      widgetMode: widgetSettings.widgetMode,
      selectedPaymentMethod: params.paymentMethod,
      widgetSettings: widgetSettings,
      adults: params.guestCount, // Simplified - actual implementation tracks adults/children
      children: 0,
      maxGuests: maxGuests,
    );

    if (!validationResult.isValid) {
      return BookingSubmissionResult.validationFailed(
        errorMessage: validationResult.errorMessage,
        snackBarDuration: validationResult.snackBarDuration,
      );
    }

    // 2. Check price lock (requires UI context - handled separately)
    // Note: Price lock check should be done in UI layer before calling this service

    // 3. Create booking
    try {
      final booking = await _createBookingForMode(params, widgetSettings);

      // 4. Send emails
      _sendNotificationEmails(
        booking: booking,
        widgetSettings: widgetSettings,
        requiresApproval: widgetSettings.widgetMode == WidgetMode.bookingPending ||
            widgetSettings.requireOwnerApproval,
        paymentMethod: params.paymentMethod,
      );

      // 5. Route based on payment method
      if (params.paymentMethod == 'stripe') {
        return BookingSubmissionResult.stripePaymentRequired(booking: booking);
      }

      return BookingSubmissionResult.success(
        booking: booking,
        paymentMethod: params.paymentMethod,
      );
    } on BookingConflictException catch (e) {
      return BookingSubmissionResult.conflict(errorMessage: e.message);
    } catch (e) {
      return BookingSubmissionResult.error(errorMessage: e.toString());
    }
  }

  Future<BookingModel> _createBookingForMode(
    BookingSubmissionParams params,
    WidgetSettings widgetSettings,
  ) async {
    if (widgetSettings.widgetMode == WidgetMode.bookingPending) {
      return _bookingService.createBooking(
        unitId: params.unitId,
        propertyId: params.propertyId,
        ownerId: params.ownerId,
        checkIn: params.checkIn,
        checkOut: params.checkOut,
        guestName: params.guestName,
        guestEmail: params.guestEmail,
        guestPhone: params.guestPhone,
        guestCount: params.guestCount,
        totalPrice: params.totalPrice,
        paymentOption: 'none',
        paymentMethod: 'none',
        requireOwnerApproval: true, // Always true for pending
        notes: params.notes,
        taxLegalAccepted: params.taxLegalAccepted,
      );
    }

    return _bookingService.createBooking(
      unitId: params.unitId,
      propertyId: params.propertyId,
      ownerId: params.ownerId,
      checkIn: params.checkIn,
      checkOut: params.checkOut,
      guestName: params.guestName,
      guestEmail: params.guestEmail,
      guestPhone: params.guestPhone,
      guestCount: params.guestCount,
      totalPrice: params.totalPrice,
      paymentOption: params.paymentOption,
      paymentMethod: params.paymentMethod,
      requireOwnerApproval: widgetSettings.requireOwnerApproval,
      notes: params.notes,
      taxLegalAccepted: params.taxLegalAccepted,
    );
  }

  void _sendNotificationEmails({
    required BookingModel booking,
    required WidgetSettings widgetSettings,
    required bool requiresApproval,
    String? paymentMethod,
  }) {
    final emailConfig = widgetSettings.emailConfig;
    if (emailConfig.enabled != true || emailConfig.isConfigured != true) {
      return;
    }

    final bookingReference = booking.id.substring(0, 8).toUpperCase();

    // Send guest confirmation email
    _emailService.sendBookingConfirmationEmail(
      booking: booking,
      emailConfig: emailConfig,
      propertyName: 'Property', // Should be passed in
      bookingReference: bookingReference,
      paymentMethod: paymentMethod,
      bankTransferConfig: widgetSettings.bankTransferConfig,
      allowGuestCancellation: widgetSettings.allowGuestCancellation,
      cancellationDeadlineHours: widgetSettings.cancellationDeadlineHours,
      ownerEmail: widgetSettings.contactOptions.emailAddress,
      ownerPhone: widgetSettings.contactOptions.phoneNumber,
      customLogoUrl: widgetSettings.themeOptions?.customLogoUrl,
    );

    // Send owner notification
    if (emailConfig.sendOwnerNotification && emailConfig.fromEmail != null) {
      _emailService.sendOwnerNotificationEmail(
        booking: booking,
        emailConfig: emailConfig,
        propertyName: 'Property',
        bookingReference: bookingReference,
        ownerEmail: emailConfig.fromEmail!,
        requiresApproval: requiresApproval,
        customLogoUrl: widgetSettings.themeOptions?.customLogoUrl,
      );
    }
  }

  void dispose() {
    _emailService.dispose();
  }
}
```

**Benefit:** Booking creation logic testable u izolaciji

---

### 5.2 StripePaymentService

**Ekstrahovati:** Lines 1,940-2,101 (161 lines)

**Novo:**
```dart
// lib/features/widget/domain/services/stripe_payment_service.dart

import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../shared/models/booking_model.dart';
import '../../../../shared/repositories/booking_repository.dart';
import '../../../../core/services/stripe_service.dart';
import '../../../../core/services/logging_service.dart';
import '../../../../core/constants/enums.dart';

part 'stripe_payment_service.freezed.dart';

@freezed
sealed class StripePaymentResult with _$StripePaymentResult {
  const factory StripePaymentResult.success({
    required String checkoutUrl,
  }) = StripePaymentSuccess;

  const factory StripePaymentResult.error({
    required String errorMessage,
  }) = StripePaymentError;
}

class StripePaymentService {
  final StripeService _stripeService;
  final BookingRepository _bookingRepo;

  StripePaymentService({
    required StripeService stripeService,
    required BookingRepository bookingRepo,
  })  : _stripeService = stripeService,
        _bookingRepo = bookingRepo;

  /// Initiates Stripe checkout session
  Future<StripePaymentResult> initiateCheckout({
    required String bookingId,
    required String bookingReference,
    required String guestEmail,
    required Uri baseUrl,
  }) async {
    try {
      final returnUrl = _buildReturnUrl(
        baseUrl: baseUrl,
        bookingId: bookingId,
        bookingReference: bookingReference,
        guestEmail: guestEmail,
      );

      final checkoutResult = await _stripeService.createCheckoutSession(
        bookingId: bookingId,
        returnUrl: returnUrl,
        guestEmail: guestEmail,
      );

      return StripePaymentResult.success(
        checkoutUrl: checkoutResult.checkoutUrl,
      );
    } catch (e) {
      return StripePaymentResult.error(
        errorMessage: e.toString(),
      );
    }
  }

  /// Handles return from Stripe checkout
  /// Fetches booking and polls for webhook update if needed
  Future<BookingModel?> handleStripeReturn({
    required String bookingId,
    int maxPollingAttempts = 10,
    Duration pollingInterval = const Duration(seconds: 2),
  }) async {
    var booking = await _bookingRepo.fetchBookingById(bookingId);
    if (booking == null) return null;

    // Poll for webhook update if pending (Bug #40 fix)
    if (booking.paymentStatus == 'pending' ||
        booking.status == BookingStatus.pending) {
      LoggingService.log(
        '⚠️ Payment status pending after Stripe return, polling for webhook update...',
        tag: 'STRIPE_WEBHOOK_FALLBACK',
      );

      booking = await _pollForWebhookUpdate(
        bookingId: bookingId,
        currentBooking: booking,
        maxAttempts: maxPollingAttempts,
        interval: pollingInterval,
      );
    }

    return booking;
  }

  Future<BookingModel?> _pollForWebhookUpdate({
    required String bookingId,
    required BookingModel currentBooking,
    required int maxAttempts,
    required Duration interval,
  }) async {
    var booking = currentBooking;

    for (var i = 0; i < maxAttempts; i++) {
      await Future.delayed(interval);

      final updatedBooking = await _bookingRepo.fetchBookingById(bookingId);
      if (updatedBooking == null) break;

      // Check if webhook has updated the booking
      if (updatedBooking.paymentStatus == 'paid' ||
          updatedBooking.status == BookingStatus.confirmed) {
        LoggingService.log(
          '✅ Webhook update detected after ${(i + 1) * interval.inSeconds} seconds',
          tag: 'STRIPE_WEBHOOK_FALLBACK',
        );
        return updatedBooking;
      }

      booking = updatedBooking;
    }

    // Still pending after polling
    LoggingService.log(
      '⚠️ Webhook not received after ${maxAttempts * interval.inSeconds} seconds',
      tag: 'STRIPE_WEBHOOK_FALLBACK',
    );

    return booking;
  }

  String _buildReturnUrl({
    required Uri baseUrl,
    required String bookingId,
    required String bookingReference,
    required String guestEmail,
  }) {
    return Uri(
      scheme: baseUrl.scheme,
      host: baseUrl.host,
      port: baseUrl.port,
      path: baseUrl.path,
      queryParameters: {
        ...baseUrl.queryParameters,
        'confirmation': bookingReference,
        'bookingId': bookingId,
        'email': guestEmail,
        'payment': 'stripe',
      },
    ).toString();
  }
}
```

**Benefit:** Stripe flow testable u izolaciji, webhook polling reusable

---

### Phase 3 Summary

| Service | Lines | New File |
|---------|-------|----------|
| BookingSubmissionService | ~250 | `domain/services/booking_submission_service.dart` |
| StripePaymentService | ~150 | `domain/services/stripe_payment_service.dart` |
| **TOTAL** | **~400** | 2 new files |

**Remaining in main file:** 1,288 - 380 = **~908 linija** ✅ **GOAL ACHIEVED!**

---

## 6. File Changes Summary

### New Files

**Phase 1 - Widgets:**
```
lib/features/widget/presentation/widgets/booking/
├── contact_section.dart                    [~180 lines]
├── booking_bar_container.dart              [~230 lines]
└── payment/
    └── payment_section_widget.dart         [~300 lines]
```

**Phase 2 - Providers:**
```
lib/features/widget/presentation/providers/
├── booking_form_provider.dart              [~150 lines]
├── booking_form_provider.freezed.dart      [generated]
├── booking_form_provider.g.dart            [generated]
├── booking_flow_provider.dart              [~80 lines]
├── booking_flow_provider.freezed.dart      [generated]
└── booking_flow_provider.g.dart            [generated]
```

**Phase 3 - Services:**
```
lib/features/widget/domain/services/
├── booking_submission_service.dart         [~250 lines]
├── booking_submission_service.freezed.dart [generated]
├── stripe_payment_service.dart             [~150 lines]
└── stripe_payment_service.freezed.dart     [generated]
```

### Modified Files

```
lib/features/widget/presentation/screens/
└── booking_widget_screen.dart
    BEFORE: 2,145 lines
    AFTER:  ~905 lines (-1,240 lines = -58%)
```

---

## 7. Risk Assessment & Mitigation

### Phase 1 Risks (Widget Extraction) 🟢

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|-----------|
| Callback parameter mismatches | LOW | MEDIUM | Strong typing, compile-time checks |
| State updates broken | LOW | HIGH | Widget tests for each component |
| Theme context lost | LOW | MEDIUM | Pass `isDarkMode` explicitly |

**Mitigation:**
1. Extract ONE widget at a time
2. Test immediately after extraction
3. Run `flutter analyze` after each
4. Manual UI testing

### Phase 2 Risks (State Management) 🟡

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|-----------|
| Provider lifecycle issues | MEDIUM | HIGH | keepAlive, dispose checks |
| State persistence broken | MEDIUM | HIGH | Integration tests |
| Form controllers not disposed | LOW | MEDIUM | Provider dispose() |
| Race conditions | LOW | HIGH | Provider listeners ordering |

**Mitigation:**
1. Write provider tests FIRST (TDD)
2. Integration test: form persistence
3. Monitor provider rebuild logs

### Phase 3 Risks (Business Logic) 🟡

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|-----------|
| Booking creation broken | MEDIUM | CRITICAL | Integration tests all payment methods |
| Email notifications not sent | LOW | HIGH | Mock email service |
| Stripe redirect broken | MEDIUM | HIGH | E2E test with Stripe test mode |
| Webhook polling broken | LOW | MEDIUM | Unit test polling logic |

**Mitigation:**
1. Integration test: full booking flows
2. E2E smoke test on staging
3. Monitor Sentry for errors

---

## 8. Testing Strategy

### Unit Tests

```dart
// Phase 1: Widget tests
test/widget/presentation/widgets/booking/contact_section_test.dart
test/widget/presentation/widgets/booking/payment_section_widget_test.dart
test/widget/presentation/widgets/booking/booking_bar_container_test.dart

// Phase 2: Provider tests
test/widget/presentation/providers/booking_form_provider_test.dart
test/widget/presentation/providers/booking_flow_provider_test.dart

// Phase 3: Service tests
test/widget/domain/services/booking_submission_service_test.dart
test/widget/domain/services/stripe_payment_service_test.dart
```

### Integration Tests

```dart
// test/integration/booking_flow_test.dart
- bookingPending: Request → Email → Confirmation
- bookingInstant + Stripe: Form → Redirect → Webhook → Confirmation
- bookingInstant + Bank: Form → Confirmation with instructions
- bookingInstant + Pay on Arrival: Form → Confirmation
- Booking conflict (race condition)
- Price change warning (Bug #64)
```

### E2E Smoke Test Checklist

```
Phase 1:
☐ Mobile: Contact pill card responsive layout
☐ Desktop: Contact pill card row layout
☐ Multiple payment methods selector
☐ Single payment method auto-select
☐ Booking bar drag-to-dismiss

Phase 2:
☐ Form data persists after refresh
☐ Form clears after booking
☐ Pill bar dismissed state persists
☐ Guest count updates
☐ Email verification flag resets

Phase 3:
☐ bookingPending full flow
☐ bookingInstant + Stripe full flow
☐ bookingInstant + Bank Transfer full flow
☐ bookingInstant + Pay on Arrival full flow
☐ Booking conflict error
☐ Price change warning
```

---

## 9. Rollout Plan

### Deployment Strategy: Feature Flags

```dart
// lib/core/config/feature_flags.dart
class FeatureFlags {
  static const bool useNewWidgetProviders = false; // Phase 2
  static const bool useBookingSubmissionService = false; // Phase 3
}
```

### Rollout Steps

**Week 1:** Phase 1 (widgets only)
- NO feature flag needed (pure UI extraction)
- Deploy → Monitor 3 days

**Week 2:** Phase 2 (providers)
- `useNewWidgetProviders = true` for 10% users
- If stable 3 days → 100%

**Week 3:** Phase 3 (services)
- `useBookingSubmissionService = true` for 10% users
- If stable 3 days → 100%

### Rollback Plan

- **Phase 1:** Git revert (LOW risk)
- **Phase 2:** Set flag false + deploy
- **Phase 3:** Set flag false + deploy

---

## 10. Estimation & Timeline

| Phase | Tasks | Effort | Dependencies |
|-------|-------|--------|--------------|
| **Phase 1** | Widget Extraction | **2 days** | None |
| **Phase 2** | State Management | **3-4 days** | Phase 1 |
| **Phase 3** | Business Logic | **2-3 days** | Phase 2 |
| **Testing** | All tests | **1-2 days** | All phases |
| **TOTAL** | | **8-11 days** | |

**Solo Developer Rule:** Double for buffer → **16-22 days (3-4 weeks)**

---

## 11. Success Criteria

### Phase 1 Complete When:
- ✅ 3 new widget files created
- ✅ Main file reduced to ~1,468 lines
- ✅ All tests passing
- ✅ Zero analyzer warnings
- ✅ UI identical (no behavioral changes)

### Phase 2 Complete When:
- ✅ 2 new provider files created
- ✅ Main file reduced to ~1,288 lines
- ✅ Form persistence working
- ✅ Provider tests passing
- ✅ No memory leaks

### Phase 3 Complete When:
- ✅ 2 new service files created
- ✅ Main file reduced to ~905 lines (**TARGET!**)
- ✅ All booking flows working
- ✅ E2E smoke test passed
- ✅ Production metrics stable

---

## 12. Decision Matrix

### Option A: Full Refactoring (RECOMMENDED)

```
All 3 phases sequentially:
- Phase 1 (2 days) → Deploy → Monitor 3 days
- Phase 2 (4 days) → Deploy → Monitor 3 days
- Phase 3 (3 days) → Deploy → Monitor 3 days

Total: 12 days + 9 days monitoring = 3 weeks
Result: ~905 lines (-58%)
```

### Option B: Partial Refactoring (Conservative)

```
Only Phase 1:
- Widget extraction (2 days)
- Result: ~1,468 lines (-32%)
- SAFEST option

Decide later on Phase 2/3.
```

### Option C: Skip Refactoring (Status Quo)

```
File works perfectly, 2,145 lines is high but not critical.
Document architecture in CLAUDE.md and skip refactoring.
```

---

## Approval

- [ ] Plan reviewed by: _______________
- [ ] Approved for Phase 1: _______________
- [ ] Approved for Phase 2: _______________
- [ ] Approved for Phase 3: _______________

---

## Changelog

| Date | Author | Change |
|------|--------|--------|
| 2025-12-02 | Claude | Initial plan created |

---

**REMINDER:** ⚠️ **NE DIRATI** widget dok user NE prijavi bug ili NE traži novu feature. Trenutno radi **besprijekorno**.
