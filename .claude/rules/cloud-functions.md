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
