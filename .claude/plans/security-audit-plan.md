# 🔒 Security Audit & Fix Plan - FINAL VERSION

## Executive Summary

**CRITICAL SECURITY VULNERABILITIES** discovered:
- **Problem #63**: 17 permissive Firebase rules (`allow read/write: if true`)
- **Problem #64**: Permissive CORS (`"origin": ["*"]`)

**Impact**: GDPR violation, data theft, booking manipulation, rate limit bypass

**Solution**: Lock down bookings with Cloud Function-based access + minimal exception for Stripe polling

---

## 🎯 SAFE STRIPE POLLING SOLUTION

### The Problem
Widget needs to poll for booking creation after Stripe redirect:
```dart
// After Stripe redirect: ?session_id=cs_test_xxx
fetchBookingByStripeSessionId(sessionId)
  → Query: WHERE stripe_session_id == sessionId
  → ❌ BLOCKED if rules say: allow read: if false
```

### The Solution - Minimal Exception Rule

**Security Analysis:**
- `stripe_session_id` je **random 64+ character string** (cs_test_a1b2c3d4e5f6...)
- Vraća se SAMO u Stripe redirect URL (nije guessable)
- Query vraća **MAX 1 booking** (limit: 1)
- Window of exposure: **~20 seconds** (10 polling attempts × 2s)

**SAFE Exception:**
```javascript
match /bookings/{bookingId} {
  // EXCEPTION #1: Allow Stripe return flow polling
  // Widget queries: WHERE stripe_session_id == cs_xxx LIMIT 1
  // SAFE because:
  // - stripe_session_id is cryptographically random (64+ chars)
  // - Only visible in Stripe redirect URL (can't be guessed)
  // - Returns max 1 booking
  // - Short exposure window (~20 seconds during polling)
  allow read: if request.query.where.keys().hasOnly(['stripe_session_id']) &&
                 request.query.limit <= 1;

  // EXCEPTION #2: Allow owner to read their own bookings (authenticated)
  allow read: if isAuthenticated() &&
                 resource.data.owner_id == request.auth.uid;

  // Block all writes (only Cloud Functions via Admin SDK)
  allow write: if false;

  // All other reads BLOCKED (must use Cloud Function getBookingByToken)
}
```

**What This BLOCKS:**
```dart
// ❌ BLOCKED - Direct read by ID
fetchBookingById('abc123')

// ❌ BLOCKED - Query by unit
where('unit_id', isEqualTo: 'unit123')

// ❌ BLOCKED - Query by guest email
where('guest_email', isEqualTo: 'guest@example.com')

// ✅ ALLOWED - Stripe polling (temporary, 20s window)
where('stripe_session_id', isEqualTo: 'cs_test_xxx').limit(1)

// ✅ ALLOWED - Owner authenticated read
// (rules check: resource.data.owner_id == request.auth.uid)
```

---

## 📋 REVISED IMPLEMENTATION PLAN

### Phase 1: Backend Security (Day 1, 4-6h)

#### Step 1.1: Create Cloud Functions

**File:** `functions/src/getBooking.ts` (NEW)
- `getBookingByToken()` - Guest access with access_token validation
- `getOwnerBooking()` - Owner access with Firebase Auth

#### Step 1.2: Update Firestore Rules with Stripe Exception

**File:** `firestore.rules` (MODIFY)

**CRITICAL FIX #1 - Bookings (with Stripe exception):**
```javascript
match /bookings/{bookingId} {
  // ========================================================================
  // SECURE BOOKING ACCESS
  // ========================================================================

  // EXCEPTION #1: Stripe return flow polling (temporary, 20s window)
  // Allows: WHERE stripe_session_id == "cs_xxx" LIMIT 1
  // Safe because stripe_session_id is cryptographically random
  allow read: if request.query.where.keys().hasOnly(['stripe_session_id']) &&
                 request.query.limit <= 1;

  // EXCEPTION #2: Owner can read their own bookings (authenticated)
  allow read: if isAuthenticated() &&
                 resource.data.owner_id == request.auth.uid;

  // GUESTS: Must use Cloud Function getBookingByToken() with access_token
  // All other reads → BLOCKED

  // WRITES: Only Cloud Functions (Admin SDK bypasses rules)
  allow write: if false;
}
```

**CRITICAL FIX #2 - Login Attempts:**
```javascript
match /loginAttempts/{email} {
  allow read: if false;  // Only Cloud Functions
  allow write: if false; // Only Cloud Functions
}
```

**CRITICAL FIX #3 - Security Events:**
```javascript
match /securityEvents/{eventId} {
  allow read: if isOwnerOrAdmin();
  allow write: if false; // Only Cloud Functions
}
```

**MEDIUM FIX - Booking Services (validation):**
```javascript
match /booking_services/{bookingServiceId} {
  allow read: if true; // OK - widget needs prices
  allow create: if request.resource.data.keys().hasAll(['bookingId', 'serviceId', 'price']) &&
                   request.resource.data.price is number &&
                   request.resource.data.price >= 0;
  allow update, delete: if isOwnerOrAdmin();
}
```

#### Step 1.3: Restrict CORS

**File:** `cors.json` (MODIFY)
```json
[
  {
    "origin": [
      "https://rab-booking-widget.web.app",
      "https://rab-booking-widget.firebaseapp.com",
      "http://localhost:5000",
      "http://localhost:3000"
    ],
    "method": ["GET", "HEAD"],
    "maxAgeSeconds": 3600,
    "responseHeader": ["Content-Type", "Access-Control-Allow-Origin"]
  }
]
```

---

### Phase 2: Frontend Migration (Day 2, 4-6h)

#### Step 2.1: Create Secure Booking Service

**File:** `lib/core/services/secure_booking_service.dart` (NEW)
- Wraps Cloud Function calls
- Maps errors to app exceptions

#### Step 2.2: Update Booking Repository

**File:** `lib/shared/repositories/firebase/firebase_booking_repository.dart` (MODIFY)

**KEY CHANGE - Keep Stripe polling, deprecate others:**
```dart
class FirebaseBookingRepository implements BookingRepository {
  final FirebaseFirestore _firestore;
  final SecureBookingService _secureBookingService;

  // ✅ KEEP - Stripe return flow polling
  @override
  Future<BookingModel?> fetchBookingByStripeSessionId(String sessionId) async {
    // Still uses direct Firestore (allowed by rules exception)
    final snapshot = await _firestore
        .collection('bookings')
        .where('stripe_session_id', isEqualTo: sessionId)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    return BookingModel.fromJson({...doc.data(), 'id': doc.id});
  }

  // ❌ DEPRECATED - Direct ID access (use Cloud Function)
  @override
  @Deprecated('Use SecureBookingService.getBookingByToken() instead')
  Future<BookingModel?> fetchBookingById(String id) async {
    throw BookingException(
      'Direct booking access disabled. Use getBookingByToken() or getOwnerBooking().',
      code: 'booking/direct-access-disabled',
    );
  }

  // ✅ NEW - Secure guest access via Cloud Function
  Future<BookingModel> getBookingByToken({
    required String bookingReference,
    required String guestEmail,
    required String accessToken,
  }) async {
    return _secureBookingService.getBookingByToken(
      bookingReference: bookingReference,
      guestEmail: guestEmail,
      accessToken: accessToken,
    );
  }

  // ✅ KEEP - Owner authenticated access (works with rules exception #2)
  @override
  Future<List<BookingModel>> fetchPropertyBookings(String propertyId) async {
    // Rules allow because: resource.data.owner_id == request.auth.uid
    final snapshot = await _firestore
        .collection('bookings')
        .where('property_id', isEqualTo: propertyId)
        .get();
    return snapshot.docs
        .map((doc) => BookingModel.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }
}
```

#### Step 2.3: Widget Screen - NO CHANGES NEEDED!

**File:** `lib/features/widget/presentation/screens/booking_widget_screen.dart`

**CURRENT CODE (lines 2347-2360) - OSTAJE ISTO:**
```dart
// ✅ RADI - Rules exception dozvoljava ovaj query
for (var i = 0; i < 10; i++) {
  await Future.delayed(const Duration(seconds: 2));
  if (!mounted) return;

  final updatedBooking = await bookingRepo.fetchBookingByStripeSessionId(
    stripeSessionId,
  );

  if (updatedBooking == null) break;

  if (updatedBooking.status == BookingStatus.confirmed ||
      updatedBooking.status == BookingStatus.pending) {
    // Navigate to confirmation
    Navigator.of(context).pushReplacement(...);
    return;
  }
}
```

**Zašto RADI:**
- Rules exception dozvoljava: `where('stripe_session_id', ==).limit(1)`
- Ovo je **TAČNO** taj query
- Nema promjena potrebnih u widget kodu! ✅

---

### Phase 3: Testing (Day 3, 6-8h)

#### Critical Test: Stripe Return Flow

**Manual Test:**
1. Otvori widget
2. Odaberi datume, unesi podatke
3. Klikni "Pay with Stripe"
4. Završi Stripe checkout (test mode)
5. **VERIFY:** Redirectuje nazad na widget
6. **VERIFY:** Polling radi (10 pokušaja × 2s)
7. **VERIFY:** Prikazuje confirmation screen
8. **VERIFY:** Booking details su tačni

**Expected Behavior:**
- ✅ Polling queries RADI (rules exception)
- ✅ Confirmation screen se prikazuje
- ✅ Nema "permission-denied" errora

#### Security Tests

**Test 1: Direct booking access blocked**
```dart
// Firebase console or widget code:
try {
  final booking = await FirebaseFirestore.instance
      .collection('bookings')
      .doc('some-booking-id')
      .get();

  print('❌ FAIL - Direct access should be blocked!');
} catch (e) {
  print('✅ PASS - Permission denied: $e');
}
```

**Test 2: Query by unit_id blocked**
```dart
try {
  final bookings = await FirebaseFirestore.instance
      .collection('bookings')
      .where('unit_id', isEqualTo: 'unit123')
      .get();

  print('❌ FAIL - Unit query should be blocked!');
} catch (e) {
  print('✅ PASS - Permission denied: $e');
}
```

**Test 3: Stripe polling ALLOWED**
```dart
try {
  final bookings = await FirebaseFirestore.instance
      .collection('bookings')
      .where('stripe_session_id', isEqualTo: 'cs_test_xxx')
      .limit(1)
      .get();

  print('✅ PASS - Stripe polling works!');
} catch (e) {
  print('❌ FAIL - Stripe polling blocked: $e');
}
```

**Test 4: Owner authenticated access ALLOWED**
```dart
// As authenticated owner:
try {
  final bookings = await FirebaseFirestore.instance
      .collection('bookings')
      .where('property_id', isEqualTo: 'my-property-id')
      .get();

  print('✅ PASS - Owner query works!');
} catch (e) {
  print('❌ FAIL - Owner query blocked: $e');
}
```

---

### Phase 4: Deployment (Day 4, 2-4h)

#### Deployment Order (CRITICAL)

```bash
# 1. Deploy Cloud Functions FIRST (before rules)
firebase deploy --only functions

# Wait 5 minutes for functions to propagate

# 2. Deploy Firestore rules
firebase deploy --only firestore:rules

# 3. Update CORS
gsutil cors set cors.json gs://YOUR-BUCKET.appspot.com

# 4. Deploy Flutter widget (if changes)
firebase deploy --only hosting
```

**Why this order:**
- Cloud Functions MUST exist before rules enforce them
- If rules deployed first → widget broken until functions deploy
- Functions first → gradual migration, no downtime

---

## 🔄 WHAT CHANGES, WHAT STAYS

### ✅ OSTAJE ISTO (NO CHANGES)

| Component | Status | Why |
|-----------|--------|-----|
| Stripe checkout flow | ✅ NO CHANGE | Payment redirect ostaje isti |
| Stripe webhook | ✅ NO CHANGE | Kreira booking kao i prije |
| Polling loop u widget-u | ✅ NO CHANGE | Rules exception dozvoljava query |
| Email verification (OTP) | ✅ NO CHANGE | Već koristi Cloud Functions |
| Widget public data | ✅ NO CHANGE | Properties, units, prices ostaju public |
| Owner dashboard queries | ✅ NO CHANGE | Authenticated owner može čitati svoje bookings |

### 🔄 MIJENJA SE (NEW BEHAVIOR)

| Component | Change | Impact |
|-----------|--------|--------|
| Direct booking read by ID | ❌ BLOCKED | Must use Cloud Function getBookingByToken() |
| Query bookings by email | ❌ BLOCKED | Prevents guest data enumeration |
| Query bookings by unit | ❌ BLOCKED | Prevents competitive intelligence |
| loginAttempts collection | ❌ BLOCKED | Prevents rate limit bypass |
| securityEvents collection | ❌ BLOCKED | Prevents log poisoning |
| CORS origins | 🔒 RESTRICTED | Prevents bandwidth theft |

---

## 🎯 SUCCESS METRICS

### Security
- ✅ 0 direct Firestore reads on bookings (except Stripe polling)
- ✅ 0 permission-denied errors for legitimate users
- ✅ 100% Cloud Function token validation
- ✅ 0 CORS errors from authorized domains

### Functionality
- ✅ Stripe return flow works (confirmation screen shows)
- ✅ Owner dashboard loads bookings
- ✅ Email links work with access tokens
- ✅ Widget availability calendar works

### Performance
- ✅ Stripe polling completes in < 20 seconds
- ✅ Cloud Function latency < 500ms
- ✅ No increase in widget load time

---

## 📝 ROLLBACK PLAN

**IF Stripe polling breaks:**

```javascript
// EMERGENCY ROLLBACK - Add to firestore.rules
match /bookings/{bookingId} {
  // TEMPORARY: Allow all reads (old behavior)
  allow read: if true;
  allow write: if false;
}
```

```bash
# Deploy emergency rollback
firebase deploy --only firestore:rules --force
```

**Full rollback:**
```bash
# Restore backup
cp firestore.rules.backup firestore.rules
firebase deploy --only firestore:rules

# Delete new Cloud Functions
firebase functions:delete getBookingByToken --force
firebase functions:delete getOwnerBooking --force
```

---

## ❓ REMAINING QUESTIONS

### Q1: Stripe Polling - RESOLVED ✅
**Rješenje:** Rules exception za `stripe_session_id` query
**Impact:** Widget ostaje isti, nema promjena u kodu

### Q2: Owner Dashboard - CLARIFIED ✅
**Rješenje:** Authenticated owner može čitati svoje bookings (rules exception #2)
**Impact:** Dashboard ostaje isti

### Q3: Analytics - NOT NEEDED ✅
**Decision:** Ne dodajemo tracking za booking views

### Q4: Monitoring - NOT NEEDED ✅
**Decision:** Koristimo postojeći Firebase monitoring

---

## 🚀 READY TO IMPLEMENT

**Estimated Time:** 16-20 hours (2-3 days)
**Priority:** 🔴 URGENT
**Risk Level:** 🟡 MEDIUM (with Stripe exception tested)

**Next Step:** Kreni sa Phase 1, Step 1.1 - kreiranje `functions/src/getBooking.ts`

Hoćeš da krenem sa implementacijom?
