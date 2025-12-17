# Cloud Functions Bugs - RESOLVED

**Date Resolved**: 2025-12-15
**Total Bugs Fixed**: 5 bugs + 1 index deployment

---

## 1. Price Mismatch Error (atomicBooking.ts)

**Sentry Issue ID**: #83347184

**Error Message**:
```
Price mismatch. Expected €200.00, received €102.00
```

**Root Cause**:
Non-Stripe payments (bank_transfer, pay_on_arrival) threw errors when client's locked price didn't match server-calculated price. The client locks the price when user opens the booking form, but if prices change before submission, the booking would fail.

**Fix**:
Added graceful handling - if price mismatch occurs, use server-calculated price instead of blocking the booking. This matches the Stripe flow behavior.

**File**: `functions/src/atomicBooking.ts`
**Lines**: 407-470

**Code Changes**:
```typescript
// Added import
import {validateBookingPrice, calculateBookingPrice} from "./utils/priceValidation";

// Lines 417-470 - Graceful price mismatch handling
let finalTotalPrice = numericTotalPrice;
let finalDepositAmount = depositAmount;

try {
  await validateBookingPrice(unitId, checkInDate, checkOutDate, numericTotalPrice, propertyId);
} catch (priceError: any) {
  if (priceError.code === "invalid-argument" && priceError.message?.includes("Price mismatch")) {
    // Calculate server-side price and use it instead
    const {totalPrice: serverPrice} = await calculateBookingPrice(unitId, checkInDate, checkOutDate, propertyId);
    finalTotalPrice = serverPrice;

    // Recalculate deposit based on new price
    if (paymentOption === "deposit") {
      finalDepositAmount = calculateDepositAmount(serverPrice, depositPercentage);
    } else if (paymentOption === "full") {
      finalDepositAmount = serverPrice;
    }
  } else {
    throw priceError;
  }
}
```

---

## 2. Invalid Payment Method "pay_on_arrival" (atomicBooking.ts)

**Sentry Issue ID**: #83347645

**Error Message**:
```
Invalid payment method: 'pay_on_arrival'. Must be one of: stripe, bank_transfer, none
```

**Root Cause**:
Client sends "pay_on_arrival" as payment method value, but server only accepted `["stripe", "bank_transfer", "none"]`.

**Fix**:
Added "pay_on_arrival" to allowed methods array and updated all conditional logic.

**File**: `functions/src/atomicBooking.ts`
**Lines**: 201, 285-286, 482, 1071

**Code Changes**:
```typescript
// Line 201 - Added pay_on_arrival to allowed methods
const allowedPaymentMethods = ["stripe", "bank_transfer", "none", "pay_on_arrival"];

// Lines 285-286 - Updated disabled check
const isPayOnArrivalDisabled =
  (paymentMethod === "none" || paymentMethod === "pay_on_arrival") && !allowPayOnArrival;

// Line 482 - Updated payment status logic
paymentStatus = (paymentMethod === "none" || paymentMethod === "pay_on_arrival") ? "not_required" : "pending";

// Line 1071 - Updated success message
(paymentMethod === "none" || paymentMethod === "pay_on_arrival") ?
  "Booking confirmed. Payment will be collected on arrival." :
```

---

## 3. Expired Placeholder Bookings Blocking Dates (stripePayment.ts)

**Sentry Issue ID**: #83282750

**Error Message**:
```
Dates no longer available. Another booking is in progress or confirmed.
```

**Root Cause**:
Expired placeholder bookings (from abandoned Stripe checkout sessions) still blocked dates. When a user starts Stripe checkout but abandons it, a placeholder booking with `stripe_pending_expires_at` is created. These expired placeholders weren't being filtered out in the conflict check.

**Fix**:
Added filtering to exclude expired placeholder bookings (where `stripe_pending_expires_at < now`) from conflict check.

**File**: `functions/src/stripePayment.ts`
**Lines**: 352-370

**Code Changes**:
```typescript
const conflictingBookings = await transaction.get(conflictingBookingsQuery);

// Filter out expired placeholder bookings
const now = admin.firestore.Timestamp.now();
const activeConflicts = conflictingBookings.docs.filter((doc) => {
  const data = doc.data();
  if (data.stripe_pending_expires_at) {
    const expiresAt = data.stripe_pending_expires_at as admin.firestore.Timestamp;
    if (expiresAt.toMillis() < now.toMillis()) {
      logInfo("createStripeCheckoutSession: Ignoring expired placeholder", {
        bookingId: doc.id,
        expiresAt: expiresAt.toDate().toISOString(),
      });
      return false; // Exclude expired placeholder
    }
  }
  return true; // Include confirmed bookings and non-expired pending bookings
});

if (activeConflicts.length > 0) {
  // ... error handling uses activeConflicts instead of conflictingBookings
}
```

---

## 4. Email Verification Race Condition (emailVerification.ts)

**Sentry Issue ID**: #83344368

**Error Message**:
```
Invalid code. 2 attempts remaining.
```

**Root Cause**:
Non-atomic read/check/update pattern in `verifyEmailCode` function allowed race conditions. Two simultaneous requests could both pass the attempt limit check before either incremented the counter.

**Fix**:
Wrapped entire verification logic in Firestore transaction for atomic read/check/update operations.

**File**: `functions/src/emailVerification.ts`
**Lines**: 248-320

**Code Changes**:
```typescript
// RACE CONDITION FIX: Use transaction to atomically check AND update attempts
const result = await db.runTransaction(async (transaction) => {
  const doc = await transaction.get(verificationRef);

  // ... all validation checks inside transaction ...

  if (data.code !== codeClean) {
    // Increment failed attempts ATOMICALLY inside transaction
    const newAttempts = (data.attempts || 0) + 1;
    transaction.update(verificationRef, { attempts: newAttempts });

    const remainingAttempts = MAX_ATTEMPTS - newAttempts;
    if (remainingAttempts <= 0) {
      throw new HttpsError("permission-denied", "Too many failed attempts. Please request a new code.");
    }
    throw new HttpsError("invalid-argument", `Invalid code. ${remainingAttempts} attempt${remainingAttempts === 1 ? "" : "s"} remaining.`);
  }

  // CODE IS VALID - Mark as verified ATOMICALLY
  transaction.update(verificationRef, {
    verified: true,
    verifiedAt: FieldValue.serverTimestamp(),
  });

  return { verified: true };
});
```

---

## 5. Daily Limit Race Condition (emailVerification.ts)

**Sentry Issue ID**: #83342720

**Error Message**:
```
Too many verification attempts. Please try again tomorrow.
```

**Status**: ALREADY FIXED (no changes needed)

**Analysis**:
The `sendEmailVerificationCode` function already uses:
- Firestore transaction (line 108)
- UTC day boundary check (lines 120-122)
- Atomic increment inside transaction (line 155)

The error in Sentry was **expected behavior** - a user legitimately hit their daily limit (5 codes per day).

---

## 6. Missing Firestore Index (firestore.indexes.json)

**Sentry Issue ID**: #83264747

**Error Message**:
```
9 FAILED_PRECONDITION: The query requires an index.
```

**Root Cause**:
The index for `bookings` collection with fields `status`, `check_in`, `check_out` existed in `firestore.indexes.json` (lines 120-128) but was not deployed to Firebase.

**Fix**:
Deployed indexes using:
```bash
firebase deploy --only firestore:indexes
```

**File**: `firestore.indexes.json`
**Lines**: 120-128 (already correct)

```json
{
  "collectionGroup": "bookings",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "status", "order": "ASCENDING" },
    { "fieldPath": "check_in", "order": "ASCENDING" },
    { "fieldPath": "check_out", "order": "ASCENDING" }
  ]
}
```

---

## Summary

| Bug | File | Fix Type | Status |
|-----|------|----------|--------|
| Price Mismatch | atomicBooking.ts | Graceful fallback to server price | ✅ Fixed |
| Invalid pay_on_arrival | atomicBooking.ts | Added to allowed methods | ✅ Fixed |
| Expired Placeholders | stripePayment.ts | Filter expired in conflict check | ✅ Fixed |
| Verification Race Condition | emailVerification.ts | Wrapped in transaction | ✅ Fixed |
| Daily Limit Race Condition | emailVerification.ts | Already fixed | ✅ No change needed |
| Missing Index | firestore.indexes.json | Deployed to Firebase | ✅ Deployed |

**All Cloud Functions bugs from this session have been resolved.**
