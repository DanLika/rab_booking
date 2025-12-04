# FIX SUMMARY: emailService.ts - Input Validation & Config

**Date**: 2025-12-04
**File**: functions/src/emailService.ts
**Status**: VRLO DOBAR KOD - samo 2 mala problema

---

## ✅ KOD JE VEĆ ODLIČAN

**Pozitivne strane:**
- ✅ Odlična input validacija u većini funkcija
- ✅ DRY princip (fetchPropertyData helper eliminira duplikate)
- ✅ Comprehensive error handling sa try-catch
- ✅ Modular templates (V2 - Refined Premium)
- ✅ Security validation (subdomain RFC 1123)

---

## ⚠️ 2 MALA PROBLEMA

### PROBLEM #1: 8 funkcija nemaju input validaciju

**Funkcije SA validacijom (7/15):**
```typescript
✅ sendBookingConfirmationEmail        - Lines 339-347
✅ sendBookingApprovedEmail             - Lines 409-416
✅ sendGuestCancellationEmail           - Lines 530-536
✅ sendRefundNotificationEmail          - Lines 631-635
✅ sendPaymentReminderEmail             - Lines 724-729
✅ sendCheckInReminderEmail             - Lines 788-792
✅ sendCheckOutReminderEmail            - Lines 850-854
```

**Funkcije BEZ validacije (8/15):**
```typescript
❌ sendOwnerNotificationEmail          - Line 466 (9 params, no validation)
❌ sendOwnerCancellationNotificationEmail - Line 578 (8 params, no validation)
❌ sendCustomGuestEmail                 - Line 671 (6 params, no validation)
❌ sendSuspiciousActivityEmail          - Line 895 (6 params, no validation)
❌ sendPendingBookingRequestEmail       - Line 933 (4 params, no validation)
❌ sendPendingBookingOwnerNotification  - Line 967 (5 params, no validation)
❌ sendBookingRejectedEmail             - Line 1003 (6 params, no validation)
❌ sendEmailVerificationCode            - Line 1041 (2 params, no validation)
```

**Rizik:**
- Email funkcije mogu primiti `null`, `undefined`, ili nevaljane formate
- Greške se javljaju tek kod template rendering-a (kasno u procesu)
- Loši error messages (nema konteksta gdje je problem)

---

### PROBLEM #2: Hardcoded FROM_NAME default

**Trenutno (Line 86):**
```typescript
const FROM_NAME = process.env.FROM_NAME || "Rab Booking";
                                            ^^^^^^^^^^^^
                                            Hardcoded!
```

**Problemi:**
- Ako env variable nije postavljena, koristi se "Rab Booking"
- To je OK za development, ali nije fleksibilno
- Trebalo bi biti u config ili fail-fast kao FROM_EMAIL

---

## 🔧 FIX STRATEGIJA

### Fix #1: Dodaj input validaciju u sve funkcije

**Za svaku funkciju dodati na početku:**
```typescript
// Example: sendOwnerNotificationEmail
export async function sendOwnerNotificationEmail(
  ownerEmail: string,
  bookingReference: string,
  guestName: string,
  guestEmail: string,
  guestPhone: string | undefined,
  propertyName: string,
  unitName: string,
  checkIn: Date,
  checkOut: Date,
  guests: number,
  totalAmount: number,
  depositAmount: number,
  paymentMethod?: string
): Promise<void> {
  // ✅ ADD INPUT VALIDATION HERE
  validateEmail(ownerEmail, "ownerEmail");
  validateRequiredString(bookingReference, "bookingReference");
  validateRequiredString(guestName, "guestName");
  validateEmail(guestEmail, "guestEmail");
  // guestPhone is optional, no validation needed
  validateRequiredString(propertyName, "propertyName");
  validateRequiredString(unitName, "unitName");
  validateDate(checkIn, "checkIn");
  validateDate(checkOut, "checkOut");
  validateAmount(guests, "guests"); // or custom validation for > 0
  validateAmount(totalAmount, "totalAmount");
  validateAmount(depositAmount, "depositAmount");
  // paymentMethod is optional

  try {
    // ... rest of function
  }
}
```

---

### Fix #2: Config opcije za FROM_NAME

**Opcija A - Fail Fast (kao FROM_EMAIL):**
```typescript
const FROM_NAME_RAW = process.env.FROM_NAME;
if (!FROM_NAME_RAW) {
  throw new Error("FROM_NAME environment variable not configured");
}
const FROM_NAME: string = FROM_NAME_RAW;
```

**Opcija B - Pametan Default:**
```typescript
// Use domain from FROM_EMAIL as intelligent default
const FROM_NAME = process.env.FROM_NAME ||
  `Bookings - ${FROM_EMAIL.split('@')[1]}`;
// Result: "Bookings - yourdomain.com"
```

**Opcija C - Config File (recommended):**
```typescript
// config/emailConfig.ts
export const EMAIL_CONFIG = {
  FROM_EMAIL: process.env.FROM_EMAIL || (() => {
    throw new Error("FROM_EMAIL not configured");
  })(),
  FROM_NAME: process.env.FROM_NAME || "Booking System",
  REPLY_TO: process.env.REPLY_TO_EMAIL,
  SUPPORT_EMAIL: process.env.SUPPORT_EMAIL || "support@rabbooking.com",
} as const;
```

---

## 📋 CHECKLIST

**Za svaku funkciju dodati validaciju za:**
- [ ] ownerEmail → validateEmail()
- [ ] guestEmail → validateEmail()
- [ ] adminEmail → validateEmail()
- [ ] bookingReference → validateRequiredString()
- [ ] guestName → validateRequiredString()
- [ ] propertyName → validateRequiredString()
- [ ] unitName → validateRequiredString() (ako required)
- [ ] checkIn/checkOut → validateDate()
- [ ] totalAmount/depositAmount → validateAmount()
- [ ] code (verification) → validateRequiredString()

---

## 🎯 PRIORITET

1. **HIGH** - Add validation to owner emails (frequent use):
   - sendOwnerNotificationEmail
   - sendOwnerCancellationNotificationEmail

2. **MEDIUM** - Add validation to security-critical:
   - sendEmailVerificationCode
   - sendSuspiciousActivityEmail

3. **LOW** - Add validation to less frequent:
   - sendCustomGuestEmail
   - sendPendingBookingRequestEmail
   - sendPendingBookingOwnerNotification
   - sendBookingRejectedEmail

4. **Config** - Fix hardcoded FROM_NAME

---

**Estimated time**: 30 minutes
**Risk**: LOW (adding validation won't break existing code)
