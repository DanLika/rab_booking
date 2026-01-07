# Comprehensive Plan: Stripe Checkout in Embedded Iframe Widgets

## Executive Summary

Based on the research document and current codebase analysis, this plan addresses the critical issue where Stripe Checkout fails when the BookBed widget is embedded in an iframe. The solution implements a **popup window approach** with robust fallbacks for all browser and device scenarios.

## Current State Analysis

### ✅ What We Already Have

1. **PaymentBridge.js** - Complete JavaScript bridge with:
   - BroadcastChannel support
   - localStorage fallback
   - postMessage support
   - Mobile detection
   - Popup management

2. **Dart Interop** - `web_utils_web.dart` has:
   - `preOpenPaymentPopup()`
   - `updatePaymentPopupUrl()`
   - `setupPaymentResultListener()`
   - `notifyPaymentComplete()`

3. **Payment Flow** - `booking_widget_screen.dart` has:
   - Synchronous popup opening pattern (partially implemented)
   - Payment completion listener setup
   - State saving before payment

### ✅ Critical Issues (ALL FIXED)

1. **~~Fallback to `navigateToUrl()` in iframe~~** - ✅ FIXED: Now uses `redirectTopLevelWindow()` instead
2. **~~Mobile Safari redirect handling~~** - ✅ FIXED: PaymentBridge detects Mobile Safari and uses top-level redirect
3. **~~Popup blocked UX~~** - ✅ FIXED: `PopupBlockedDialog` provides clear options (Open Payment Page, Copy Link, Try Again)
4. **~~Missing top-level window redirect~~** - ✅ FIXED: `redirectTopLevelWindow()` implemented in `web_utils_web.dart`

## Implementation Plan

### Phase 1: Fix Core Payment Flow (CRITICAL)

#### 1.1 Update `_handleStripePayment()` in `booking_widget_screen.dart`

**Current Problem:**
- Line 2248: Falls back to `navigateToUrl()` when popup update fails
- Line 2255: Uses `navigateToUrl()` for mobile redirect (wrong - should redirect top-level)
- Line 2256-2259: Uses `navigateToUrl()` for standalone (correct, but should never reach here in iframe)

**Solution:**
```dart
// Pseudo-code for the fix:
if (kIsWeb && isInIframe) {
  // ALWAYS use popup or top-level redirect - NEVER navigate from iframe
  if (popupResult == 'popup') {
    // Update popup URL
    if (!updatePaymentPopupUrl(checkoutResult.checkoutUrl)) {
      // Popup update failed - redirect TOP-LEVEL window (not iframe)
      _redirectTopLevelWindow(checkoutResult.checkoutUrl);
    }
  } else if (popupResult == 'redirect' || popupResult == 'blocked') {
    // Mobile or blocked - redirect TOP-LEVEL window
    _redirectTopLevelWindow(checkoutResult.checkoutUrl);
  }
} else {
  // Standalone page - safe to use navigateToUrl
  navigateToUrl(checkoutResult.checkoutUrl);
}
```

#### 1.2 Add Top-Level Window Redirect Function

**New function needed in `web_utils_web.dart`:**
```dart
/// Redirect top-level window (breaks out of iframe)
/// CRITICAL: Use this when in iframe and need to redirect for Stripe
void redirectTopLevelWindow(String url) {
  try {
    // Try to redirect parent window (works if same-origin)
    web.window.top?.location.href = url.toJS;
  } catch (e) {
    // Cross-origin iframe - use window.open as fallback
    // This will open in new tab/window
    web.window.open(url.toJS, '_top'.toJS);
  }
}
```

#### 1.3 Update PaymentBridge.js for Better Mobile Handling

**Enhancement needed:**
- Ensure `openPayment()` properly redirects top-level window on mobile
- Add better error handling for cross-origin scenarios

### Phase 2: Improve Popup Blocked UX

#### 2.1 Create Popup Blocked Dialog Widget

**New file: `lib/features/widget/presentation/widgets/popup_blocked_dialog.dart`**

Features:
- Clear explanation of why popup is needed
- "Allow Popups" button (triggers another attempt)
- "Open Payment Page" button (redirects top-level window)
- "Copy Payment Link" button (for manual sharing)

#### 2.2 Update Error Handling

**In `_handleStripePayment()`:**
- When popup is blocked, show dialog instead of just snackbar
- Store checkout URL in state for retry
- Provide multiple fallback options

### Phase 3: Enhance Payment Completion Flow

#### 3.1 Improve Payment Result Detection

**Current:** Listener is set up, but may miss edge cases

**Enhancement:**
- Add polling fallback if BroadcastChannel fails
- Better handling of payment completion in new tab scenario
- Clearer state management during payment flow

#### 3.2 Update Booking Confirmation Screen

**Current:** Already has `_notifyParentOfPaymentComplete()`

**Enhancement:**
- Ensure it works in all scenarios (popup, new tab, redirect)
- Add retry logic if notification fails
- Better handling when confirmation screen opens in new tab

### Phase 4: Mobile Safari Specific Handling

#### 4.1 Detect Mobile Safari Earlier

**In PaymentBridge.js:**
- Already has `isMobileSafari()` detection
- Ensure it's called before any popup attempt

#### 4.2 Redirect Strategy for Mobile Safari

**Pattern:**
```javascript
if (isMobileSafari()) {
  // Save state to sessionStorage
  saveBookingState(bookingData);
  // Redirect top-level window immediately
  window.top.location.href = checkoutUrl;
  return 'redirect';
}
```

### Phase 5: Testing & Edge Cases

#### 5.1 Test Scenarios

1. **Desktop Chrome - Popup Allowed**
   - ✅ Popup opens
   - ✅ Payment completes
   - ✅ Popup closes
   - ✅ Original tab receives notification

2. **Desktop Chrome - Popup Blocked**
   - ✅ Dialog appears
   - ✅ "Open Payment Page" redirects top-level
   - ✅ Payment completes in new tab
   - ✅ Original tab receives notification

3. **Mobile Safari - Redirect**
   - ✅ Top-level window redirects
   - ✅ Payment completes
   - ✅ Returns to widget
   - ✅ Booking confirmation shows

4. **Cross-Origin Iframe**
   - ✅ Popup opens (if allowed)
   - ✅ postMessage works for communication
   - ✅ Fallback to localStorage if needed

5. **Standalone Page (Not in iframe)**
   - ✅ Direct redirect works
   - ✅ No popup needed

#### 5.2 Edge Cases to Handle

- **Popup opens but user closes it before payment**
  - Solution: Monitor popup closure, show message

- **Payment completes but notification fails**
  - Solution: Poll for booking in Firestore as fallback

- **Multiple tabs open with same widget**
  - Solution: BroadcastChannel handles this automatically

- **Browser back button during payment**
  - Solution: Save state, restore on return

## Implementation Priority

### 🔴 CRITICAL (Do First) - ✅ ALL COMPLETED
1. ✅ Fix top-level window redirect in iframe scenarios
2. ✅ Remove `navigateToUrl()` fallback when in iframe
3. ✅ Add `redirectTopLevelWindow()` function

### 🟡 HIGH (Do Next) - ✅ ALL COMPLETED
4. ✅ Improve popup blocked UX with dialog (`PopupBlockedDialog`)
5. ✅ Enhance mobile Safari detection and handling (`PaymentBridge.isMobileSafari()`)
6. ✅ Better error messages for users

### 🟢 MEDIUM (Polish) - ✅ ALL COMPLETED
7. ✅ Add payment link copying feature (in `PopupBlockedDialog`)
8. ✅ Improve payment completion polling (`_handleStripeReturnWithSessionId()`)
9. ✅ Add analytics for payment flow success/failure (`AnalyticsService`)

### ⚪ LOW (Future)
10. Consider Stripe Elements for card-only payments (alternative approach)
11. Add payment retry mechanism
12. Enhanced logging and debugging tools

## Code Changes Required

### Files to Modify

1. **`lib/core/utils/web_utils_web.dart`**
   - Add `redirectTopLevelWindow()` function
   - Export it for use in booking widget

2. **`lib/core/utils/web_utils_stub.dart`**
   - Add stub for `redirectTopLevelWindow()`

3. **`lib/features/widget/presentation/screens/booking_widget_screen.dart`**
   - Fix `_handleStripePayment()` to never use `navigateToUrl()` in iframe
   - Add popup blocked dialog
   - Improve error handling

4. **`web/payment_bridge.js`** (Optional Enhancement)
   - Improve mobile Safari detection
   - Better cross-origin handling

5. **`lib/features/widget/presentation/widgets/popup_blocked_dialog.dart`** (New)
   - Create dialog widget for popup blocked scenario

### Files to Review (No Changes Expected)

- `lib/features/widget/presentation/screens/booking_confirmation_screen.dart` - Already good
- `functions/src/stripePayment.ts` - Already good
- `web/index.html` - PaymentBridge already included

## Questions for User

Before implementing, I need clarification on:

1. **User Experience Preference:**
   - When popup is blocked, should we:
     a) Show dialog with options (recommended)
     b) Automatically redirect top-level window
     c) Show snackbar and require user to click "Pay" again

2. **Mobile Behavior:**
   - On mobile Safari, should we:
     a) Always redirect top-level window (recommended)
     b) Try popup first, then redirect if blocked
     c) Show dialog with options

3. **Payment Link Sharing:**
   - Should we add "Copy Payment Link" feature for manual sharing?
   - Useful when popup is blocked and user wants to pay on another device

4. **Analytics:**
   - Do you want to track:
     - Popup success/failure rates
     - Payment completion rates by device/browser
     - Time to payment completion

5. **Error Recovery:**
   - If payment completes but notification fails, should we:
     a) Poll Firestore for booking (current approach)
     b) Show message asking user to refresh
     c) Both (poll + message)

## Success Criteria

✅ Stripe Checkout works in embedded iframe on all browsers
✅ Popup blocked scenarios have clear user guidance
✅ Mobile Safari redirects properly
✅ Payment completion is reliably communicated back to widget
✅ No more "Stripe Checkout is not able to run in an iFrame" errors
✅ Graceful fallbacks for all edge cases

## Implementation Status: ✅ COMPLETE

All critical, high, and medium priority items have been implemented and verified.

---

## Additional Bugs Fixed (Not Originally in This Plan)

### Bug: Price Mismatch Between Widget and Server (Fixed 2024-12)

**Problem**: Booking creation failed with error "Price mismatch. Expected €200.00, received €102.00"

**Root Cause**: `BookingPriceCalculator._fetchDailyPrices()` used `collectionGroup('daily_prices')` which queried ALL daily_prices collections across the database, including old migration data with incorrect prices (€51/night). Server used exact subcollection path and correctly fell back to unit's `price_per_night: 100`.

**Fix Applied**: Updated `BookingPriceCalculator` to:
1. First find unit document via `_findUnitDocument()` to get propertyId
2. Query exact subcollection path: `properties/{propertyId}/units/{unitId}/daily_prices`
3. This matches server-side validation in `functions/src/utils/priceValidation.ts`

**Files Modified**:
- `lib/features/widget/data/helpers/booking_price_calculator.dart`

**Status**: ✅ FIXED

---

**Last Updated**: 2024-12-15

**Note:** This plan is based on the comprehensive research document provided and analysis of the current codebase. All recommendations follow Stripe's best practices and industry-standard patterns for handling payments in embedded contexts.
