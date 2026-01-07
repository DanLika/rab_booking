# Plan: Stripe Security Improvements

**Status**: ✅ IMPLEMENTIRANO (KRITIČNO I VISOKO)
**Zadnje ažurirano**: 2025-12-16

---

> **Napomena (2025-12-16):** Kritični i visoki prioritet stavke su IMPLEMENTIRANE:
> - ✅ Rate limiting na Stripe checkout creation
> - ✅ Stripe Connect account verification (`charges_enabled`, `card_payments`, `transfers`)
> - ✅ Security monitoring (`securityMonitoring.ts`)
> - ✅ Error message cleanup (generičke poruke za korisnike)
>
> Srednji prioritet stavke (webhook idempotency enhancement) su opcionalne.

---

## Pregled

Plan pokriva kritične sigurnosne rizike u Stripe integraciji identificirane tokom sigurnosne analize. Fokus je na:

1. Ograničavanje pristupa booking podacima u Firestore
2. Dodavanje rate limiting-a na Stripe checkout creation
3. Verifikacija Stripe Connect account statusa
4. Implementacija monitoring i alerting sistema
5. Ostala sigurnosna poboljšanja

## Kritični Rizici

### 1. Firestore Rules - Bookings Collection (KRITIČNO)

**Problem**: Trenutno `allow read: if true;` omogućava svima da čitaju sve booking podatke.

**Rizik**:
- Ekspozicija osjetljivih podataka (email, ime, cijene, datumi)
- Potencijalno GDPR kršenje
- Mogućnost scraping-a booking podataka

**Rješenje**: Implementirati selektivni read pristup sa query optimization.

**Fajlovi za izmjenu**:
- `firestore.rules` - linija 156

**Implementacija**:
```javascript
// Umjesto: allow read: if true;
// Koristiti:
match /bookings/{bookingId} {
  // READ: Selektivni pristup
  // 1. Owner može čitati svoje booking-ove
  // 2. Widget calendar: query samo za availability (status, check_in, check_out, unit_id)
  // 3. Guest: preko Cloud Function verifyBookingAccess (ne direktno)
  // 4. Stripe webhook polling: preko Cloud Function (ne direktno)
  
  allow read: if request.auth != null && 
    resource.data.owner_id == request.auth.uid;
  
  // Widget calendar queries - samo availability podaci
  allow list: if request.query.limit <= 100 && 
    (request.query.select == null || 
     request.query.select == "status,check_in,check_out,unit_id");
  
  // Individual document read - samo owner
  allow get: if request.auth != null && 
    resource.data.owner_id == request.auth.uid;
}
```

**Napomena**: Može utjecati na widget calendar queries. Potrebno je testirati i možda kreirati dedicated Cloud Function za calendar availability.

**Alternativno rješenje**: Kreirati `calendar_availability` collection sa minimalnim podacima (samo status, datumi, unit_id) za widget calendar.

### 2. Rate Limiting na Stripe Checkout Creation (KRITIČNO)

**Problem**: Nema rate limiting-a na `createStripeCheckoutSession` Cloud Function.

**Rizik**:
- DoS napadi (prekomjerni Stripe API pozivi)
- Finansijski rizik (svaki poziv može kreirati Stripe session)
- Potencijalno blokiranje Stripe accounta zbog prekomjernih poziva

**Rješenje**: Dodati rate limiting koristeći postojeći `rateLimit` utility.

**Fajlovi za izmjenu**:
- `functions/src/stripePayment.ts` - linija 103 (createStripeCheckoutSession)

**Implementacija**:
```typescript
import { checkRateLimit, enforceRateLimit } from "./utils/rateLimit";

export const createStripeCheckoutSession = onCall({ secrets: [stripeSecretKey] }, async (request) => {
  // Rate limiting - PRIJE bilo kakvih operacija
  const clientIp = (request as any).rawRequest?.ip || 
    (request as any).rawRequest?.headers?.["x-forwarded-for"]?.split(",")[0]?.trim() || 
    "unknown";
  
  // In-memory check first (fast)
  if (!checkRateLimit(`stripe_checkout:${clientIp}`, 10, 300)) {
    throw new HttpsError(
      "resource-exhausted",
      "Too many checkout attempts. Please wait 5 minutes before trying again."
    );
  }
  
  // Firestore-backed check (persistent across instances)
  const ipHash = Buffer.from(clientIp).toString("base64").substring(0, 16);
  await enforceRateLimit(`ip_${ipHash}`, "stripe_checkout", {
    maxCalls: 20,
    windowMs: 600000, // 20 attempts per 10 minutes per IP
    errorMessage: "Too many checkout attempts. Please wait a few minutes before trying again.",
  });
  
  // Existing code continues...
});
```

**Rate limit konfiguracija**:
- In-memory: 10 poziva u 5 minuta (300 sekundi)
- Firestore: 20 poziva u 10 minuta (600000 ms)
- Razlog: Firestore limit je viši jer je perzistentan i može se resetovati

### 3. Stripe Connect Account Verification (VISOK)

**Problem**: Nema provjere da li je Stripe Connect account verified prije kreiranja checkout sessiona.

**Rizik**:
- Pristup plaćanjima preko neverified accounta
- Potencijalno blokiranje plaćanja od strane Stripe-a
- Loš user experience (plaćanje ne prolazi)

**Rješenje**: Provjeriti account status i capabilities prije checkout session creation.

**Fajlovi za izmjenu**:
- `functions/src/stripePayment.ts` - linija 206-224 (nakon fetch owner Stripe account ID)

**Implementacija**:
```typescript
// Get owner's Stripe Connect account ID
const ownerDoc = await db.collection("users").doc(ownerId).get();
const ownerStripeAccountId = ownerDoc.data()?.stripe_account_id;

if (!ownerStripeAccountId) {
  // Existing error handling...
}

// NEW: Verify Stripe Connect account status
try {
  const account = await stripeClient.accounts.retrieve(ownerStripeAccountId);
  
  // Check if account is enabled for payments
  if (!account.charges_enabled) {
    logError(`createStripeCheckoutSession: Stripe account ${ownerStripeAccountId} not enabled for charges`, null, {
      ownerId: ownerId,
      stripeAccountId: ownerStripeAccountId,
      accountStatus: account.details_submitted,
      chargesEnabled: account.charges_enabled,
      payoutsEnabled: account.payouts_enabled,
    });
    throw new HttpsError(
      "failed-precondition",
      "Property owner's payment account is not fully set up. Please contact the property owner."
    );
  }
  
  // Check if account has required capabilities
  const hasCardPayments = account.capabilities?.card_payments === "active";
  const hasTransfers = account.capabilities?.transfers === "active";
  
  if (!hasCardPayments || !hasTransfers) {
    logWarn(`createStripeCheckoutSession: Stripe account missing capabilities`, {
      ownerId: ownerId,
      stripeAccountId: ownerStripeAccountId,
      hasCardPayments: hasCardPayments,
      hasTransfers: hasTransfers,
    });
    throw new HttpsError(
      "failed-precondition",
      "Property owner's payment account is not fully configured. Please contact the property owner."
    );
  }
  
  logInfo("createStripeCheckoutSession: Stripe Connect account verified", {
    ownerId: ownerId,
    stripeAccountId: ownerStripeAccountId,
    chargesEnabled: account.charges_enabled,
    payoutsEnabled: account.payouts_enabled,
  });
} catch (error: any) {
  if (error instanceof HttpsError) {
    throw error;
  }
  logError("createStripeCheckoutSession: Error verifying Stripe account", error, {
    ownerId: ownerId,
    stripeAccountId: ownerStripeAccountId,
  });
  throw new HttpsError(
    "internal",
    "Failed to verify payment account. Please try again later."
  );
}
```

### 4. Monitoring i Alerting (VISOK)

**Problem**: Nema automatskog monitoring-a i alerting-a za kritične security events.

**Rizik**:
- Kasna detekcija napada
- Nema upozorenja za neuspješne webhook verifications
- Nema tracking-a za price mismatch detekcije

**Rješenje**: Implementirati monitoring i alerting koristeći Firebase Functions logging i opcionalno Sentry.

**Fajlovi za kreiranje/izmjenu**:
- `functions/src/utils/securityMonitoring.ts` (novi fajl)
- `functions/src/stripePayment.ts` - dodati monitoring calls
- `functions/src/bookingAccessToken.ts` - dodati monitoring calls

**Implementacija**:

**Novi fajl**: `functions/src/utils/securityMonitoring.ts`
```typescript
import { logError, logWarn } from "./logger";
import * as admin from "firebase-admin";

/**
 * Security Event Types
 */
export enum SecurityEventType {
  WEBHOOK_SIGNATURE_FAILED = "webhook_signature_failed",
  PRICE_MISMATCH_DETECTED = "price_mismatch_detected",
  RATE_LIMIT_EXCEEDED = "rate_limit_exceeded",
  INVALID_ACCESS_TOKEN = "invalid_access_token",
  STRIPE_ACCOUNT_NOT_VERIFIED = "stripe_account_not_verified",
  SUSPICIOUS_BOOKING_ATTEMPT = "suspicious_booking_attempt",
}

/**
 * Log security event for monitoring
 */
export async function logSecurityEvent(
  eventType: SecurityEventType,
  details: Record<string, any>,
  severity: "low" | "medium" | "high" | "critical" = "medium"
): Promise<void> {
  const event = {
    type: eventType,
    severity: severity,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    details: details,
  };
  
  // Log to Firestore for analysis
  try {
    await admin.firestore().collection("security_events").add(event);
  } catch (error) {
    // Fallback to console logging if Firestore fails
    logError(`[SecurityMonitoring] Failed to log event: ${eventType}`, error);
  }
  
  // Log based on severity
  if (severity === "critical" || severity === "high") {
    logError(`[Security] ${eventType}`, null, details);
  } else {
    logWarn(`[Security] ${eventType}`, details);
  }
  
  // TODO: Integrate with Sentry for critical events
  // if (severity === "critical") {
  //   Sentry.captureMessage(`Security Event: ${eventType}`, {
  //     level: "error",
  //     extra: details,
  //   });
  // }
}
```

**Izmjene u `stripePayment.ts`**:
```typescript
import { logSecurityEvent, SecurityEventType } from "./utils/securityMonitoring";

// U handleStripeWebhook, nakon signature verification failure:
catch (error: any) {
  await logSecurityEvent(
    SecurityEventType.WEBHOOK_SIGNATURE_FAILED,
    {
      error: error.message,
      hasSignature: !!sig,
    },
    "critical"
  );
  logError("Webhook signature verification failed", error);
  res.status(400).send(`Webhook Error: ${error.message}`);
  return;
}

// U createStripeCheckoutSession, nakon price mismatch:
catch (priceError: any) {
  if (priceError.code === "invalid-argument" && priceError.message?.includes("Price mismatch")) {
    await logSecurityEvent(
      SecurityEventType.PRICE_MISMATCH_DETECTED,
      {
        unitId: unitId,
        clientPrice: totalPrice,
        serverPrice: serverTotalPrice,
        difference: Math.abs(serverTotalPrice - totalPrice),
      },
      "high"
    );
    // Existing code...
  }
}
```

**Izmjene u `rateLimit.ts`**:
```typescript
import { logSecurityEvent, SecurityEventType } from "./securityMonitoring";

// U enforceRateLimit, kada limit exceeded:
if (recentTimestamps.length >= maxCalls) {
  await logSecurityEvent(
    SecurityEventType.RATE_LIMIT_EXCEEDED,
    {
      userId: userId,
      action: action,
      maxCalls: maxCalls,
      windowMs: windowMs,
    },
    "medium"
  );
  // Existing error throw...
}
```

### 5. Error Message Information Leakage (SREDNJI)

**Problem**: Neki errori mogu otkriti previše informacija o sistemu.

**Rješenje**: Generičke poruke za korisnike, detalji samo u logovima.

**Fajlovi za izmjenu**:
- `functions/src/stripePayment.ts` - sve error poruke
- `functions/src/verifyBookingAccess.ts` - error poruke

**Implementacija**: Review svih error poruka i zamijeniti detaljne poruke generičkim, zadržavajući detalje u logovima.

**Primjer**:
```typescript
// PRIJE:
throw new HttpsError("invalid-argument", `Missing required booking fields: ${missingFields.join(", ")}`);

// POSLIJE:
logError("createStripeCheckoutSession: Missing required booking fields", null, {
  missingFields: missingFields,
  bookingDataKeys: Object.keys(bookingData),
});
throw new HttpsError("invalid-argument", "Invalid booking data. Please refresh the page and try again.");
```

### 6. Webhook Idempotency Enhancement (SREDNJI)

**Problem**: Trenutno postoji idempotency check, ali može se poboljšati sa dedicated idempotency key tracking.

**Rješenje**: Dodati idempotency key tracking u webhook metadata.

**Fajlovi za izmjenu**:
- `functions/src/stripePayment.ts` - webhook handling (linija 640-651)

**Implementacija**: Trenutna implementacija je dovoljna, ali može se dodati dodatni check:
```typescript
// Dodati u webhook metadata pri kreiranju sessiona:
metadata: {
  // ... existing metadata
  idempotency_key: crypto.randomUUID(), // Dodati unique key
}

// U webhook handleru, provjeriti da li je već procesiran:
const idempotencyKey = metadata.idempotency_key;
if (idempotencyKey) {
  // Check if we've already processed this key
  const existingBooking = await db.collection("bookings")
    .where("stripe_session_id", "==", session.id)
    .limit(1)
    .get();
  
  if (!existingBooking.empty) {
    // Already processed
    return;
  }
}
```

**Napomena**: Ovo je opcionalno poboljšanje - trenutna implementacija je dovoljna.

## Test Plan

### 1. Firestore Rules Testing
- [ ] Test owner read access (može čitati svoje booking-ove)
- [ ] Test unauthenticated read access (ne može čitati booking-ove)
- [ ] Test widget calendar queries (samo availability podaci)
- [ ] Test calendar performance (query optimization)

### 2. Rate Limiting Testing
- [ ] Test rate limit enforcement (10 poziva u 5 minuta)
- [ ] Test rate limit reset (nakon 5 minuta)
- [ ] Test error poruke (user-friendly)
- [ ] Test Firestore-backed persistence (preko više Cloud Function instances)

### 3. Stripe Connect Verification Testing
- [ ] Test verified account (uspješan checkout)
- [ ] Test unverified account (error poruka)
- [ ] Test account bez capabilities (error poruka)
- [ ] Test error handling (network errors, API errors)

### 4. Monitoring Testing
- [ ] Test security event logging (Firestore)
- [ ] Test severity levels (low, medium, high, critical)
- [ ] Test error handling (ako Firestore fails)
- [ ] Test Sentry integration (ako implementiran)

## Implementation Priority

### Phase 1: Critical (1-2 tjedna)
1. Rate limiting na Stripe checkout creation
2. Firestore rules poboljšanja (sa testiranjem)

### Phase 2: High (2-4 tjedna)
3. Stripe Connect account verification
4. Monitoring i alerting osnovni setup

### Phase 3: Medium (1-2 mjeseca)
5. Error message information leakage fix
6. Webhook idempotency enhancement (opcionalno)

## Dependencies

- Postojeći `rateLimit` utility (`functions/src/utils/rateLimit.ts`)
- Postojeći `logger` utility (`functions/src/logger.ts`)
- Firebase Firestore za security events collection
- Stripe API za account verification

## Notes

- Firestore rules izmjene mogu utjecati na widget calendar performance - potrebno je testirati
- Rate limiting konfiguracija može se prilagoditi na osnovu production metrics
- Monitoring može se proširiti sa Sentry integration u budućnosti
- Security events collection treba cleanup policy (delete events starije od 90 dana)

## Success Criteria

- [ ] Firestore rules ograničavaju pristup booking podacima
- [ ] Rate limiting sprječava DoS napade na Stripe checkout
- [ ] Stripe Connect account verification sprječava plaćanja preko neverified accounta
- [ ] Security events se loguju za monitoring
- [ ] Error poruke su user-friendly bez information leakage
- [ ] Svi testovi prolaze
- [ ] Nema performance degradation na widget calendar

