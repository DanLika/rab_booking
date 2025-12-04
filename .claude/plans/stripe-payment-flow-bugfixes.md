# Stripe Payment Flow & Email Notification Bug Fixes

**Created**: 2025-12-02
**Status**: PLAN
**Priority**: HIGH - Payment flow is broken

---

## Executive Summary

Based on detailed analysis of the codebase, I've identified 6 interconnected bugs in the booking payment flow. The ROOT CAUSE appears to be that **Stripe webhook is not firing or not being processed correctly**, which cascades into multiple display and notification issues.

### Evidence

Firebase booking document `BK-1764669646881-8485`:
```yaml
status: confirmed
payment_status: pending     # BUG: Should be "paid"
paid_amount: 0              # BUG: Should be 20.8 (deposit_amount)
payment_method: stripe
deposit_amount: 20.8
stripe_session_id: cs_test_a1dCI3fwTDegw23Q5WPaVYWxbipJN9wnOTb3rFef8JT9goNaF4JXZWtSl1
```

The webhook code at `stripePayment.ts:254-262` SHOULD set:
```typescript
await bookingRef.update({
  status: "confirmed",
  payment_status: "paid",
  payment_method: "stripe",
  paid_amount: booking.deposit_amount,  // ← NOT BEING SET
  stripe_payment_intent: session.payment_intent,
  paid_at: admin.firestore.FieldValue.serverTimestamp(),
  updated_at: admin.firestore.FieldValue.serverTimestamp(),
});
```

---

## Bug List

| # | Bug | Root Cause | Priority | Status |
|---|-----|------------|----------|--------|
| 1 | Stripe redirect shows owner login page | returnUrl + webhook not firing | CRITICAL | ✅ FIXED |
| 2 | Owner doesn't receive email notification | Conditional on settings + webhook | HIGH | |
| 3 | "View my reservation" email button broken | Missing route or token | HIGH | |
| 4 | Original tab keeps pill bar after Stripe | No cross-tab communication | MEDIUM | |
| 5 | Calendar doesn't update in real-time | Cache invalidation timing | MEDIUM | |
| 6 | Payment shows 0 instead of deposit | Webhook not updating `paid_amount` | CRITICAL | |

---

## Bug #1: Stripe Redirect Issue ✅ FIXED

**Fixed**: 2025-12-03
**Verified by**: Manual testing + Firebase logs

### Solution Implemented

1. **Same-tab Stripe redirect** (`booking_widget_screen.dart:2406-2408`):
   ```dart
   if (kIsWeb) {
     html.window.location.href = checkoutResult.checkoutUrl;
   }
   ```

2. **Return URL with hash routing** (`booking_widget_screen.dart:2389-2390`):
   ```dart
   final returnUrl = '$returnUrlWithoutHash#/calendar';
   ```

3. **Session ID polling** (`booking_widget_screen.dart:411-483`):
   - `_handleStripeReturnWithSessionId()` polls Firestore for booking by `session_id`
   - Max 30 seconds wait (15 attempts × 2s)

4. **Router public route detection** (`router_owner.dart:213-224`):
   - `/calendar` is public route
   - Widget params (`property`, `unit`, `confirmation`) detected from `Uri.base`
   - Login route shows `BookingWidgetScreen` if widget params present

### Verification

**Firebase logs (2025-12-03 08:16 UTC):**
```
Processing Stripe webhook for booking: BK-1764749785077-2714
Booking eFC5lk53DDwlOLCLHhy7 created after Stripe payment
Confirmation email sent to duskolicanin1234@gmail.com
Owner notification sent to zgembokrkan@gmail.com
```

**Working URL flow:**
```
1. User clicks "Pay with Stripe"
2. Same-tab redirect to Stripe Checkout
3. Stripe webhook creates booking
4. Stripe redirects back: ?stripe_status=success&session_id=cs_xxx#/calendar
5. Widget polls for booking by session_id
6. Found booking → shows confirmation screen
```

---

## Bug #2: Owner Email Notification Not Sent

### Current Behavior
Owner doesn't receive email when guest creates booking

### Analysis

**Email is sent conditionally** (`atomicBooking.ts:581-644`):
```typescript
if (shouldSendEmailNotification) {
  await sendOwnerNotificationEmail(
    ownerEmail,
    ownerData.name || "Owner",
    ...
  );
}
```

**`shouldSendEmailNotification`** comes from owner's notification preferences.

### Fix Required

1. **Check owner's notification settings in Firestore**
   - `users/{ownerId}/notification_preferences`

2. **Ensure webhook also sends owner email** (`stripePayment.ts:295-319`)
   - Webhook DOES send owner email on `checkout.session.completed`
   - But webhook may not be firing (see Bug #1)

3. **User's Requirement**: Owner should receive email for ALL bookings regardless of settings

### Implementation Plan

**Option A: Make owner email mandatory**
- Remove conditional check in `atomicBooking.ts`
- Always send owner notification email

**Option B: Fix webhook + verify settings**
- Ensure webhook fires (fixes Bug #1)
- Check owner notification preferences are enabled

**Recommended**: Option A - Owner should always know about new bookings

---

## Bug #3: "View my reservation" Button in Email

### Current Behavior
Button in email has no action / doesn't work

### Analysis

**Email template** (`emailService.ts`):
```typescript
const bookingLink = `${WIDGET_URL}/view?ref=${bookingReference}&email=${guestEmail}&token=${accessToken}`;
```

**Route exists** (`router_owner.dart:327-334`):
```dart
GoRoute(
  path: '/view',
  builder: (context, state) {
    final ref = state.uri.queryParameters['ref'];
    final email = state.uri.queryParameters['email'];
    final token = state.uri.queryParameters['token'];
    return BookingViewScreen(bookingRef: ref, email: email, token: token);
  },
)
```

**BookingViewScreen** (`booking_view_screen.dart:39-92`):
- Calls `verifyBookingAccess` with ref, email, and optional token
- Navigates to `/view/details` on success

### Possible Issues

1. **WIDGET_URL not set correctly** in email service
2. **Token validation failing** in `verifyBookingAccess`
3. **Route not being recognized** as public

### User's Security Request: OTP Verification

User wants guests to verify email with OTP before viewing booking details.

### Implementation Plan

**Step 1: Verify email link works**
- Test URL format manually
- Check WIDGET_URL env variable

**Step 2: Add OTP verification flow**
```
Guest clicks "View my reservation" in email
    → Opens /view?ref=XXX&email=YYY
    → BookingViewScreen asks for OTP
    → Send OTP to guest email
    → Guest enters OTP
    → Verify OTP matches
    → Navigate to booking details
```

**New Files Needed:**
- `lib/features/widget/presentation/screens/booking_otp_verification_screen.dart`
- `lib/features/widget/presentation/providers/otp_verification_provider.dart`

**Cloud Function:**
- Already exists: `sendEmailVerificationCode` in `emailService.ts`
- Already exists: verification logic in `atomicBooking.ts`

---

## Bug #4: Pill Bar Stays Open After Stripe Payment

### Current Behavior
After Stripe opens new tab, original tab still shows pill bar with selected dates

### Analysis

Current state management:
```dart
bool _pillBarDismissed = false;
bool _hasInteractedWithBookingFlow = false;
```

These are LOCAL widget state - not persisted or synchronized across tabs.

### Fix Required

**Option A: User's Choice - Close original tab**
- When Stripe opens in new tab, close the original widget tab
- PRO: Simple, no cross-tab communication needed
- CON: Bad UX if Stripe fails

**Option B: BroadcastChannel API** (Recommended)
- Use web BroadcastChannel to communicate between tabs
- When payment completes, notify original tab
- Original tab shows confirmation screen

### Implementation Plan

**Step 1: Create tab communication service**
```dart
class TabCommunicationService {
  late final html.BroadcastChannel _channel;

  void onMessage(Function(String) callback) {
    _channel.onMessage.listen((event) => callback(event.data));
  }

  void sendMessage(String message) {
    _channel.postMessage(message);
  }
}
```

**Step 2: Original tab listens for completion**
```dart
// In booking_widget_screen.dart initState
tabService.onMessage((message) {
  if (message == 'stripe_complete:$bookingId') {
    _showConfirmationFromUrl(...);
  }
});
```

**Step 3: Stripe return tab notifies**
```dart
// After showing confirmation
tabService.sendMessage('stripe_complete:$bookingId');
```

---

## Bug #5: Calendar Real-Time Updates

### Current Behavior
Calendar doesn't show newly booked dates without page refresh

### Analysis

**Already using StreamProviders**:
- `realtimeYearCalendarProvider` - Real-time Firestore listener
- `realtimeMonthCalendarProvider` - Real-time Firestore listener

**Cache invalidation exists** (`booking_widget_screen.dart:2084-2087`):
```dart
// CRITICAL: Invalidate calendar cache after Stripe return
ref.invalidate(realtimeYearCalendarProvider);
ref.invalidate(realtimeMonthCalendarProvider);
```

### Possible Issues

1. Invalidation not triggering rebuild
2. Firestore listener not detecting new bookings
3. Widget not re-rendering after invalidation

### Implementation Plan

**Step 1: Verify Firestore rules allow real-time reads**
```javascript
match /bookings/{bookingId} {
  allow read: if true;  // Public read for calendar
}
```

**Step 2: Add debug logging**
```dart
ref.listen(realtimeYearCalendarProvider, (prev, next) {
  LoggingService.log('Calendar updated: ${next.bookings.length} bookings');
});
```

**Step 3: Force widget rebuild after invalidation**
```dart
ref.invalidate(realtimeYearCalendarProvider);
ref.invalidate(realtimeMonthCalendarProvider);
setState(() {}); // Force rebuild
```

---

## Bug #6: Payment Shows 0 Instead of Deposit

### Current Behavior
Owner bookings page shows "Paid: 0 EUR" instead of actual deposit amount

### Analysis

This is DIRECT EVIDENCE that webhook is not firing:
```yaml
paid_amount: 0              # Should be 20.8
payment_status: pending     # Should be "paid"
```

Webhook code SHOULD set this (`stripePayment.ts:258`):
```typescript
paid_amount: booking.deposit_amount,  // This line is NOT executing
```

### Root Cause

1. Webhook endpoint not deployed
2. Webhook secret mismatch
3. Webhook endpoint URL incorrect in Stripe Dashboard
4. Firestore write permission issue

### Fix Required

**Critical**: Fix webhook - this is the root cause of multiple bugs

### Implementation Plan

**Step 1: Check webhook deployment**
```bash
firebase deploy --only functions:handleStripeWebhook
```

**Step 2: Verify webhook in Stripe Dashboard**
- Go to Developers → Webhooks
- Check endpoint URL: `https://us-central1-rab-booking-248fc.cloudfunctions.net/handleStripeWebhook`
- Check events: `checkout.session.completed`
- Check webhook signing secret matches `STRIPE_WEBHOOK_SECRET`

**Step 3: Test webhook locally**
```bash
stripe listen --forward-to http://localhost:5001/rab-booking-248fc/us-central1/handleStripeWebhook
stripe trigger checkout.session.completed
```

**Step 4: Check webhook logs**
```bash
firebase functions:log --only handleStripeWebhook
```

---

## Implementation Priority

### Phase 1: CRITICAL (Same Day)
1. **Fix webhook** - Root cause of Bug #1, #6
   - Verify deployment
   - Verify Stripe Dashboard configuration
   - Test with Stripe CLI

### Phase 2: HIGH (1-2 Days)
2. **Fix owner email** - Bug #2
   - Make owner notification mandatory
   - Or fix webhook (emails sent from webhook too)

3. **Fix email link** - Bug #3
   - Verify WIDGET_URL
   - Test `/view` route

### Phase 3: MEDIUM (3-5 Days)
4. **Add OTP verification** - Security enhancement for Bug #3
   - New screen for OTP entry
   - Reuse existing `sendEmailVerificationCode` function

5. **Fix pill bar** - Bug #4
   - Implement BroadcastChannel communication
   - Or close original tab on Stripe open

6. **Verify calendar updates** - Bug #5
   - Add logging
   - Verify Firestore rules

---

## Testing Checklist

After implementing fixes:

- [ ] Create booking with Stripe payment
- [ ] Verify webhook fires (check Firebase logs)
- [ ] Verify `paid_amount` is set in Firestore
- [ ] Verify `payment_status` is "paid"
- [ ] Verify redirect shows confirmation screen (not login)
- [ ] Verify owner receives email notification
- [ ] Verify guest receives email with working link
- [ ] Click "View my reservation" - should show booking details
- [ ] Verify calendar updates in real-time
- [ ] Verify owner bookings page shows correct paid amount

---

## Files to Modify

| File | Changes |
|------|---------|
| `functions/src/stripePayment.ts` | Debug logging for webhook |
| `functions/src/atomicBooking.ts` | Make owner email mandatory |
| `lib/core/config/router_owner.dart` | Verify public route handling |
| `lib/features/widget/presentation/screens/booking_widget_screen.dart` | Tab communication, debug logging |
| `lib/features/widget/presentation/screens/booking_view_screen.dart` | Add OTP step |

---

## Environment Variables to Verify

1. **Firebase Functions Secrets:**
   - `STRIPE_SECRET_KEY` - For Stripe API calls
   - `STRIPE_WEBHOOK_SECRET` - For webhook signature verification
   - `RESEND_API_KEY` - For email sending

2. **Stripe Dashboard:**
   - Webhook endpoint URL
   - Webhook signing secret
   - Enabled events

3. **Widget Deployment:**
   - `WIDGET_URL` environment variable for email links

---

## Conclusion

The ROOT CAUSE is most likely the **Stripe webhook not being configured or deployed correctly**. Fixing this single issue will resolve Bug #1 (redirect), Bug #2 (partial), and Bug #6 (payment display).

After webhook is fixed, the remaining bugs (email link, OTP, pill bar, calendar) can be addressed as enhancements.

**Recommended First Step**: Run `firebase functions:log --only handleStripeWebhook` and `stripe trigger checkout.session.completed` to diagnose webhook issues.
