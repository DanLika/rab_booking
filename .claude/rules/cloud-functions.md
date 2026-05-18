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

## Deployment

After code changes to `functions/src/`, always deploy:
```bash
cd functions && npm run deploy
```
Changes in Git don't affect production until deployed!

## Region split (audit 2026-05-18)

**14 functions** deklariraju `region: 'europe-west1'`; ostalih ~22 default na `us-central1`. Klijentska Dart `EnvironmentConfig.functionsBaseUrl` hardkodira `us-central1-…`.

eu-west1 callable funkcije MORAJU se zvati preko region-specific instance:
```dart
final functions = FirebaseFunctions.instanceFor(region: 'europe-west1');
await functions.httpsCallable('setLifetimeLicense').call(...);
```

eu-west1 funkcije (provjeri prije dodavanja novih): `setLifetimeLicense`, `updateUserStatus`, `onUserCreate`, `checkLoginRateLimit`, `checkRegistrationRateLimit`, `scheduledIcalSync`, `syncIcalFeedNow`, `migrateTrialStatus`, `checkPasswordHistory`, `savePasswordToHistory`, `onPropertyDeleted`, `revokeAllRefreshTokens`, `checkTrialExpiration`, `sendTrialExpirationWarning`, `onUnitDeleted`, + 6 funkcija u `scheduledPushNotifications.ts`.

## Sentry env tag bug (audit 2026-05-18)

`functions/src/sentry.ts:30` deriviraju `environment` SAMO iz `FUNCTIONS_EMULATOR`. To znači dev Cloud Run deploy (`bookbed-dev`, ne emulator) šalje errore u Sentry tagovane kao `production` — miješaju se s pravim prod erorima.

Fix prije bilo kojeg dev cloud deploy-a: derivirati iz `GCP_PROJECT`:
```typescript
environment: process.env.GCP_PROJECT === 'rab-booking-248fc' ? 'production' : 'development'
```

## v2 triggers, dva v1 importa zaostala

Svi trigger-i su v2 (`onCall`, `onRequest`, `onSchedule`, `onDocument*`). `functions.config()` se nigdje ne koristi. Dvije lokacije ipak importaju v1 namespace radi non-trigger helpera: `firebase.ts:20` (Admin SDK init), `logger.ts:9` (logger objekt). To je OK; ne mijenjati u v1-removal čišćenju bez razloga.
