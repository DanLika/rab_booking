# Phase 2 - Revised Extraction Plan

**Created:** 2024-12-04
**Status:** ACTIVE
**Previous Plan:** `.claude/plans/architecture-refactoring-plan.md` Phase 2 (UI extraction)
**Revision Reason:** Analysis revealed most UI already extracted - real issue is business logic + state

---

## 📊 Analysis Findings

### Current State: BookingWidgetScreen (2651 lines)

**✅ Already Extracted (UI Widgets):**
- `CalendarViewSwitcher` - Month/Year calendar toggle
- `BookingPillBar` - Floating booking pill with animations
- `PillBarContent` - Pill bar internal UI
- `ContactPillCardWidget` - Contact card in pill
- Form field widgets - Individual input fields
- Calendar painters - Custom calendar rendering

**❌ NOT Extracted (Business Logic):**
- Validation logic (lines 1800-2100) - Mixed with UI
- Price calculation orchestration (lines 1600-1700) - In widget
- Booking submission flow (lines 2200-2400) - Tightly coupled
- State management (40+ fields) - Scattered across widget

**Real Problem:**
BookingWidgetScreen is an **orchestrator** that also contains business logic. It should ONLY orchestrate, not execute business rules.

---

## 🎯 Revised Phase 2 Strategy

Instead of extracting UI widgets (already done), extract:

### 1. **Business Logic → Use Cases** (8-10h)
Extract business rules into domain layer use cases:

#### A. Validation Use Case
**File:** `lib/features/widget/domain/use_cases/validate_booking_form_use_case.dart`

**Extract from:** `_validateBookingForm()` + scattered validation logic

**Responsibility:**
- Validate guest info (name, email, phone, guests count)
- Validate date selection
- Validate terms acceptance
- Return structured validation result

**Benefit:**
- Testable without widget
- Reusable across different UIs (web admin, mobile app)
- Single source of truth for validation rules

#### B. Calculate Booking Price Use Case
**File:** `lib/features/widget/domain/use_cases/calculate_booking_price_use_case.dart`

**Extract from:** `_calculateTotalPrice()` orchestration logic

**Responsibility:**
- Orchestrate price calculation through IPriceCalculator
- Handle pricing errors
- Format price for display
- Return PriceCalculationResult with breakdown

**Benefit:**
- Decouples pricing from UI
- Can be tested independently
- Enables price calculation in background jobs

#### C. Submit Booking Use Case
**File:** `lib/features/widget/domain/use_cases/submit_booking_use_case.dart`

**Extract from:** `_submitBooking()` + `_handleStripeCheckout()` + `_handleDirectPayment()`

**Responsibility:**
- Validate booking data
- Check availability one final time
- Calculate final price
- Execute payment flow (Stripe or direct)
- Create booking record
- Return booking confirmation

**Benefit:**
- Complex flow isolated from UI
- Can add retry logic, error recovery
- Testable payment flows

### 2. **State Management → Notifiers** (4-6h)

Current: 40+ fields scattered in StatefulWidget
Target: Consolidated state notifiers

#### A. BookingFormNotifier
**File:** `lib/features/widget/presentation/providers/booking_form_notifier.dart`

**State:**
```dart
class BookingFormState {
  final String guestName;
  final String guestEmail;
  final String guestPhone;
  final int guestsCount;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final bool termsAccepted;
  final bool emailConsent;
  final Map<String, String> validationErrors;
}
```

**Methods:**
- `updateGuestInfo()`
- `updateDateSelection()`
- `updateConsents()`
- `validateForm()`

#### B. BookingPriceNotifier
**File:** `lib/features/widget/presentation/providers/booking_price_notifier.dart`

**State:**
```dart
class BookingPriceState {
  final PriceCalculationResult? result;
  final bool isCalculating;
  final String? errorMessage;
}
```

**Methods:**
- `calculatePrice()`
- `resetPrice()`

#### C. BookingSubmissionNotifier
**File:** `lib/features/widget/presentation/providers/booking_submission_notifier.dart`

**State:**
```dart
class BookingSubmissionState {
  final bool isSubmitting;
  final String? errorMessage;
  final BookingModel? completedBooking;
}
```

**Methods:**
- `submitBooking()`
- `resetSubmission()`

### 3. **Screen Simplification → Pure Orchestrator** (3-4h)

Transform BookingWidgetScreen from 2651 lines to ~300 lines:

**Responsibilities (ONLY):**
- Watch notifier states
- Render UI based on state
- Dispatch user actions to notifiers
- Navigate on success/error

**NOT Responsible For:**
- Validation logic (use case)
- Price calculation (use case)
- Submission logic (use case)
- Complex state management (notifiers)

---

## 📋 Extraction Order (Safest → Riskiest)

### STEP 1: Validation Use Case (SAFEST) ⭐
**Why first:** Pure logic, no external dependencies, no async
- Create `ValidateBookingFormUseCase`
- Extract validation rules from widget
- Write unit tests
- Replace widget validation with use case call
- **Risk:** MINIMAL - pure function transformation

### STEP 2: Price Calculation Use Case (SAFE) ⭐
**Why second:** Already abstracted through IPriceCalculator
- Create `CalculateBookingPriceUseCase`
- Inject `IPriceCalculator` dependency
- Extract orchestration logic
- Write unit tests
- Replace widget calculation with use case call
- **Risk:** LOW - interfaces already in place

### STEP 3: Booking Form Notifier (MODERATE) ⚠️
**Why third:** State consolidation, many dependencies
- Create `BookingFormNotifier` + `BookingFormState`
- Migrate 15+ form fields to state
- Update widget to read from notifier
- Test form interactions
- **Risk:** MODERATE - careful migration needed

### STEP 4: Price Notifier (MODERATE) ⚠️
**Why fourth:** Depends on use case from Step 2
- Create `BookingPriceNotifier` + `BookingPriceState`
- Wire to `CalculateBookingPriceUseCase`
- Migrate price calculation triggers
- **Risk:** MODERATE - async state management

### STEP 5: Submission Use Case (COMPLEX) ⚠️⚠️
**Why fifth:** Most complex, touches Stripe + Firebase + navigation
- Create `SubmitBookingUseCase`
- Extract Stripe checkout logic
- Extract direct payment logic
- Handle all error cases
- Write integration tests
- **Risk:** HIGH - critical business flow

### STEP 6: Submission Notifier (COMPLEX) ⚠️⚠️
**Why sixth:** Depends on use case from Step 5
- Create `BookingSubmissionNotifier`
- Wire to `SubmitBookingUseCase`
- Handle navigation on success/error
- **Risk:** HIGH - user-facing submission flow

### STEP 7: Screen Simplification (FINAL) ⭐
**Why last:** All dependencies extracted, simple refactor
- Remove extracted logic from widget
- Simplify build() method
- Keep only orchestration code
- **Risk:** LOW - just cleanup

---

## 🎯 Success Metrics

### Before Phase 2:
- BookingWidgetScreen: **2651 lines**
- Business logic: **Mixed with UI**
- State fields: **40+ scattered**
- Testability: **Requires full widget tree**
- Error handling: **Inconsistent**

### After Phase 2:
- BookingWidgetScreen: **~300 lines** (orchestrator only)
- Business logic: **3 testable use cases**
- State fields: **3 notifiers with clear state models**
- Testability: **Unit tests for all business logic**
- Error handling: **Centralized in use cases**

---

## ⚡ Estimated Timeline

| Step | Task | Time | Risk |
|------|------|------|------|
| 1 | Validation use case | 2h | LOW |
| 2 | Price calculation use case | 2h | LOW |
| 3 | Booking form notifier | 3h | MODERATE |
| 4 | Price notifier | 2h | MODERATE |
| 5 | Submission use case | 4h | HIGH |
| 6 | Submission notifier | 3h | HIGH |
| 7 | Screen simplification | 2h | LOW |
| **TOTAL** | | **18h** | |

**Original estimate:** 17-24h (UI extraction)
**Revised estimate:** 18h (business logic extraction)

---

## 🚨 Safety Rules

1. **One step at a time** - Complete + test before moving to next
2. **Run `flutter analyze` after each step** - Zero new errors
3. **Manual testing required** - Test booking flow end-to-end
4. **No changes to Calendar Repository** - Per CLAUDE.md (NIKADA NE MIJENJAJ)
5. **Keep Navigator.push for confirmation** - Per CLAUDE.md
6. **Preserve all existing behavior** - Zero regressions

---

## 📝 Next Actions

**Immediate:**
1. Start with Step 1 (Validation Use Case)
2. Create domain/use_cases directory
3. Extract validation logic
4. Write unit tests
5. Integrate into widget
6. Verify with `flutter analyze`

**After user approval:**
Proceed step-by-step through all 7 steps, testing thoroughly at each stage.
