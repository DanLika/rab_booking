# Stripe Checkout Iframe Implementation - Review & Test Plan

**Status**: ✅ IMPLEMENTIRANO | ⚠️ TESTIRANJE POTREBNO
**Last Updated**: 2025-12-16

---

> **Napomena (2025-12-16):** Sav kod je implementiran i nema linter grešaka.
> Test checklist (linije 132-164) pokazuje da nijedan browser/mobile test nije proveden.
> Preporuka: provesti testove prije production deploy-a.

---

## ✅ Implementation Summary

### 1. Core Functions Added

#### `redirectTopLevelWindow()` - `lib/core/utils/web_utils_web.dart`
- **Purpose**: Redirects top-level window to break out of iframe
- **Strategy**: 
  1. Try `window.top.location.href` (same-origin)
  2. Fallback to `window.open(url, '_top')` (cross-origin)
  3. Last resort: `window.location.href` (current window)
- **Status**: ✅ Implemented, no linter errors

#### `BrowserDetection` - `lib/core/utils/browser_detection.dart`
- **Methods**:
  - `getBrowserName()`: Returns 'chrome', 'firefox', 'safari', 'edge', 'duckduckgo', etc.
  - `getDeviceType()`: Returns 'desktop', 'mobile', 'tablet'
- **Status**: ✅ Implemented, no linter errors

#### Analytics Methods - `lib/core/services/analytics_service.dart`
- `logStripePaymentInitiated()`: Tracks payment start with method, browser, device
- `logStripePopupBlocked()`: Tracks when popup is blocked
- `logStripePaymentCompleted()`: Tracks payment completion with timing
- **Status**: ✅ Implemented, no linter errors

#### `PopupBlockedDialog` - `lib/features/widget/presentation/widgets/popup_blocked_dialog.dart`
- **Features**:
  - "Open Payment Page" button (redirects top-level window)
  - "Copy Payment Link" button (copies to clipboard)
  - "Try Again" button (optional, for retry)
- **Status**: ✅ Implemented, no linter errors

### 2. Payment Flow Updates

#### `_handleStripePayment()` - `lib/features/widget/presentation/screens/booking_widget_screen.dart`

**Flow Logic:**

1. **Pre-open popup (synchronous, on user click)**
   ```dart
   if (kIsWeb && isInIframe) {
     popupResult = preOpenPaymentPopup(); // 'popup', 'redirect', 'blocked', or 'error'
     // Track analytics
   }
   ```

2. **Create checkout session (async)**
   ```dart
   final checkoutResult = await stripeService.createCheckoutSession(...);
   ```

3. **Handle based on popupResult:**
   - **'popup'**: Update popup URL → Refresh widget (close loading, show calendar)
   - **'redirect'**: Redirect top-level window → Refresh widget
   - **'blocked'**: Show PopupBlockedDialog with options
   - **null/error**: Fallback to redirect top-level window

**Key Changes:**
- ✅ Never uses `navigateToUrl()` in iframe scenarios
- ✅ Always refreshes widget when popup/redirect opens (closes loading, shows calendar)
- ✅ Analytics tracking at each step
- ✅ Proper error handling with fallbacks

### 3. Payment Completion Handling

#### Cross-tab Communication
- ✅ `_setupPaymentBridgeListener()`: Listens for PaymentBridge messages
- ✅ `_handlePaymentCompleteFromOtherTab()`: Handles BroadcastChannel messages
- ✅ `_handleStripeReturnWithSessionId()`: Handles URL-based returns with polling

**Analytics Tracking:**
- ✅ Payment completion tracked with browser/device info
- ✅ Time to completion tracked (when available)

## 🔍 Logic Review

### Scenario 1: Desktop Chrome - Popup Allowed
1. User clicks "Pay" → `preOpenPaymentPopup()` returns 'popup'
2. Checkout session created → `updatePaymentPopupUrl()` updates popup
3. Widget refreshes (loading closes, calendar shows)
4. User pays in popup → PaymentBridge notifies → Booking confirmation shows
5. ✅ **Expected**: Works correctly

### Scenario 2: Desktop Chrome - Popup Blocked
1. User clicks "Pay" → `preOpenPaymentPopup()` returns 'blocked'
2. Analytics tracks popup blocked
3. Checkout session created
4. `PopupBlockedDialog` shown with options
5. User clicks "Open Payment Page" → `redirectTopLevelWindow()` called
6. Widget refreshes (loading closes, calendar shows)
7. Payment completes in new tab → BroadcastChannel notifies → Booking confirmation shows
8. ✅ **Expected**: Works correctly

### Scenario 3: Mobile Safari - Redirect
1. User clicks "Pay" → `preOpenPaymentPopup()` returns 'redirect'
2. Checkout session created
3. `redirectTopLevelWindow()` called → Top-level window redirects
4. Widget refreshes (loading closes, calendar shows)
5. Payment completes → Returns to widget → `_handleStripeReturnWithSessionId()` polls for booking
6. ✅ **Expected**: Works correctly

### Scenario 4: Standalone Page (Not in iframe)
1. User clicks "Pay" → `popupResult` remains null (not in iframe)
2. Checkout session created
3. `navigateToUrl()` called (safe for standalone)
4. ✅ **Expected**: Works correctly (no changes needed)

## ✅ Potential Issues & Edge Cases (ALL RESOLVED)

### Issue 1: popupResult null in iframe
**Current**: Added else block that falls back to `redirectTopLevelWindow()`
**Status**: ✅ FIXED

### Issue 2: Payment completes but notification fails
**Current**: `_handleStripeReturnWithSessionId()` polls Firestore for booking
**Status**: ✅ FIXED (poll + message approach)

### Issue 3: Widget refresh timing
**Current**: Widget refreshes immediately after popup/redirect opens
**Status**: ✅ FIXED - user sees calendar, payment happens in separate window/tab

### Issue 4: Analytics tracking missing sessionId
**Current**: In `_handlePaymentCompleteFromOtherTab()`, uses bookingId as sessionId
**Status**: ✅ FIXED - bookingId works as identifier for analytics tracking

## 🧪 Test Checklist

### Desktop Tests
- [ ] Chrome - Popup allowed
- [ ] Chrome - Popup blocked → Dialog → Open Payment Page
- [ ] Chrome - Popup blocked → Dialog → Copy Link
- [ ] Firefox - Popup allowed
- [ ] Firefox - Popup blocked
- [ ] Safari - Popup allowed
- [ ] Safari - Popup blocked
- [ ] Edge - Popup allowed
- [ ] Edge - Popup blocked
- [ ] DuckDuckGo - Popup allowed
- [ ] DuckDuckGo - Popup blocked

### Mobile Tests
- [ ] iOS Safari - Redirect flow
- [ ] Android Chrome - Popup/redirect flow
- [ ] Mobile Firefox - Popup/redirect flow

### Edge Cases
- [ ] Cross-origin iframe (different domain)
- [ ] Same-origin iframe (same domain)
- [ ] Standalone page (not in iframe)
- [ ] Payment completes but notification delayed
- [ ] User closes popup before payment
- [ ] Multiple tabs open with same widget

### Analytics Verification
- [ ] Payment initiation events tracked
- [ ] Popup blocked events tracked
- [ ] Payment completion events tracked
- [ ] Browser/device info correct

## 📝 Code Quality

### Linter Status
- ✅ No errors in `web_utils_web.dart`
- ✅ No errors in `browser_detection.dart`
- ✅ No errors in `analytics_service.dart`
- ✅ No errors in `booking_widget_screen.dart`
- ✅ No errors in `popup_blocked_dialog.dart`

### Import Verification
- ✅ All imports present and correct
- ✅ `redirectTopLevelWindow` exported via `web_utils.dart`
- ✅ `BrowserDetection` accessible
- ✅ `AnalyticsService` accessible
- ✅ `PopupBlockedDialog` imported

## 🎯 Expected Behavior

### When Popup Opens Successfully
1. Widget immediately refreshes (loading closes, calendar shows)
2. Popup window opens with Stripe Checkout
3. User completes payment in popup
4. Popup closes automatically
5. Original tab receives notification via PaymentBridge
6. Booking confirmation screen shows in original tab

### When Popup is Blocked
1. Widget shows PopupBlockedDialog
2. User can:
   - Click "Open Payment Page" → Redirects top-level window
   - Click "Copy Payment Link" → Copies link to clipboard
   - Click "Try Again" → Closes dialog (user must click Pay again)
3. Widget refreshes after redirect
4. Payment completes in new tab
5. Original tab receives notification via BroadcastChannel
6. Booking confirmation screen shows

### When Mobile Redirect
1. Widget immediately refreshes (loading closes, calendar shows)
2. Top-level window redirects to Stripe Checkout
3. User completes payment
4. Returns to widget with session_id in URL
5. Widget polls Firestore for booking
6. Booking confirmation screen shows

## ✅ Conclusion

**Implementation Status**: ✅ Complete
**Code Quality**: ✅ No linter errors
**Logic Review**: ✅ All scenarios handled
**Edge Cases**: ✅ Covered with fallbacks

**Ready for Testing**: ✅ Yes

**Next Steps**:
1. Test on real browsers (Chrome, Safari, Firefox, Edge, DuckDuckGo)
2. Test on mobile devices (iOS Safari, Android Chrome)
3. Test in real iframe scenarios
4. Monitor analytics data
5. Verify payment completion flow works end-to-end

---

## Additional Bugs Fixed (Related to Booking/Payment Flow)

### Bug: Price Mismatch Between Widget and Server (Fixed 2024-12)

**Problem**: Booking creation failed with error "Price mismatch. Expected €200.00, received €102.00" for Bank Transfer and Pay on Arrival payment methods.

**Root Cause**: `BookingPriceCalculator._fetchDailyPrices()` used `collectionGroup('daily_prices')` which queried ALL daily_prices collections across the database, including old migration data with incorrect prices (€51/night). The server-side validation in `functions/src/utils/priceValidation.ts` used the exact subcollection path and correctly fell back to unit's `price_per_night: 100`.

**Fix Applied**: Updated `BookingPriceCalculator` in `lib/features/widget/data/helpers/booking_price_calculator.dart` to:
1. First find unit document via new `_findUnitDocument()` helper method
2. Extract propertyId from unit's parent path: `properties/{propertyId}/units/{unitId}`
3. Query exact subcollection path: `properties/{propertyId}/units/{unitId}/daily_prices`
4. Updated both `_fetchDailyPrices()` and `getEffectivePriceForDate()` methods

**Why This Matters**: This ensures client-side and server-side price calculations use the same data source, preventing booking failures due to price validation mismatches.

**Status**: ✅ FIXED

---

**Last Updated**: 2024-12-15
