---
paths:
  - "functions/src/**/*.ts"
  - "functions/src/**/*.js"
---

# Cloud Functions (`functions/src/`)

## Logging — UVIJEK strukturirani logger

```typescript
import {logInfo, logError, logWarn} from "./logger";
// NE: console.log() - nestrukturirano, teško za debug
```

## Timezone — UVIJEK UTC za date comparison

```typescript
const today = new Date();
today.setUTCHours(0, 0, 0, 0);  // CORRECT
// NE: today.setHours(0, 0, 0, 0) - koristi local timezone
```

## Rate Limiting

Dostupno u `functions/src/utils/rateLimit.ts`:
- `checkRateLimit()` - in-memory, za hot paths
- `enforceRateLimit()` - Firestore-backed, za critical actions

## Input Sanitization

`functions/src/utils/inputSanitization.ts`:
```typescript
sanitizeText(name), sanitizeEmail(email), sanitizePhone(phone)
```

## Booking Lookup — KRITIČNO

`functions/src/utils/bookingLookup.ts`:
```typescript
// ⚠️ NIKADA ne koristi FieldPath.documentId() sa collectionGroup()!
// Umjesto toga koristi helper funkcije:
import {findBookingById, findBookingByReference} from "./utils/bookingLookup";

// Primjer
const result = await findBookingById(bookingId, ownerId); // ownerId je optional
if (result) {
  const {doc, data, propertyId, unitId} = result;
}
```

**FieldPath.documentId() Bug**: Firestore očekuje PUNI PUT dokumenta (npr. `properties/xxx/units/yyy/bookings/zzz`), ne samo ID. UVIJEK koristi custom field queries umjesto `FieldPath.documentId()` sa `collectionGroup()`.

## Sentry Error Tracking

`sentry.ts`:
```typescript
import {captureException, captureMessage, setUser} from "./sentry";

// User context - UVIJEK na početku callable funkcija:
setUser(request.auth.uid);              // Za authenticated usera
setUser(null, guestEmail);              // Za guest akcije (email verification, booking view)

// Error capture - NE KORISTITI DIREKTNO u većini slučajeva
// logError() iz logger.ts automatski šalje na Sentry
// Koristi captureMessage samo za security events:
captureMessage("Security: Price mismatch detected", "error", {unitId, clientPrice, serverPrice});
```

### HttpsError client-fault filter (since 6.71)

`Sentry.init` u `sentry.ts` ima `beforeSend` koji DROP-a event ako je original exception `HttpsError` sa client-fault `code`:
- Dropped: `invalid-argument`, `unauthenticated`, `permission-denied`, `not-found`, `already-exists`, `failed-precondition`, `out-of-range`, `resource-exhausted`, `cancelled`
- Sent: `internal`, `unknown`, `data-loss`, `unavailable`, `deadline-exceeded`, `aborted`

**Why**: `@sentry/node` firebase otel auto-instrumentation (`mechanism: auto.firebase.otel.functions`) captures SVAKI thrown `HttpsError`, uključujući 4xx-class client mistakes. Bez filtera Sentry je preplavljen invalid-argument noise-om.

**Implikacija za debug**: Ako misliš "ova funkcija throws X ali ne vidim ga u Sentry-u" — provjeri je li `code` u dropped set-u. Za genuine server bugs (`internal`) filter ne djeluje. Discriminator je `err.httpErrorCode !== undefined && err.code in clientFaultCodes` — non-Firebase greške s `.code` stringom (Firestore errors) NISU pogođene.

## Deployment

After code changes to `functions/src/`, always deploy:
```bash
cd functions && npm run deploy
```
Changes in Git don't affect production until deployed!

## Region split (refreshed 2026-05-21 — audit/11-cloudfunctions-inventory.md)

**PROD**: 32 funkcija u `us-central1`, 21 u `europe-west1`. **DEV**: 35/22. Klijentska Dart `EnvironmentConfig.functionsBaseUrl` hardkodira `us-central1-…` — eu-west1 callable funkcije MORAJU se zvati preko region-specific instance:
```dart
final functions = FirebaseFunctions.instanceFor(region: 'europe-west1');
await functions.httpsCallable('setLifetimeLicense').call(...);
```

eu-west1 funkcije (provjeri prije dodavanja novih): `setLifetimeLicense`, `updateUserStatus`, `onUserCreate`, `checkLoginRateLimit`, `checkRegistrationRateLimit`, `scheduledIcalSync`, `syncIcalFeedNow`, `migrateTrialStatus`, `checkPasswordHistory`, `savePasswordToHistory`, `onPropertyDeleted`, `revokeAllRefreshTokens`, `checkTrialExpiration`, `sendTrialExpirationWarning`, `onUnitDeleted`, `deleteUserAccount`, + 6 funkcija u `scheduledPushNotifications.ts`.

**Latency cost (P3 in audit/11)**: Stripe + booking hot-path (`createBookingAtomic`, `createStripeCheckoutSession`, `handleStripeWebhook`, `getUnitIcalFeed`, `onBookingCreated`, `onBookingStatusChange`) sve u `us-central1` → +120ms RTT za EU/HR korisnike po svakom callable pozivu. Migracija u `europe-west1` traži dual-deploy fazu (CF region je immutable) + Stripe webhook URL update. NE deploya nove funkcije u `us-central1` osim ako postoji konkretan razlog.

## Dead Flutter callsite: `sendSuspiciousActivityAlert`

`lib/core/services/security_events_service.dart:356` zove `httpsCallable('sendSuspiciousActivityAlert')`. **Backend funkcija ne postoji** — `functions/src/securityEmail.ts` obrisan u commitu `4cb5a391`. Svaka suspicious-login detekcija triggera `functions/not-found` u logu. Ili obnoviti backend, ili ukloniti Flutter caller. Vidi audit/11-cloudfunctions-inventory.md §5.

## v2 triggers, dva v1 importa zaostala

Svi trigger-i su v2 (`onCall`, `onRequest`, `onSchedule`, `onDocument*`). `functions.config()` se nigdje ne koristi. Dvije lokacije ipak importaju v1 namespace radi non-trigger helpera: `firebase.ts:20` (Admin SDK init), `logger.ts:9` (logger objekt). To je OK; ne mijenjati u v1-removal čišćenju bez razloga.
