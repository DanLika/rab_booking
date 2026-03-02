# BookBed TODO Items

Extracted from CLAUDE.md — inactive planning items.

---

## 📝 TODO: Bookbed Website Documentation

**Prioritet:** High
**Rok:** 2-3 dana
**Lokacija:** Bookbed React website (docs sekcija)

### Potrebna dokumentacija:

**Za Owners (Property Managers):**
1. Getting Started - Kreiranje property-ja i unita
2. Pricing Setup - Postavljanje cijena i sezonskih pravila
3. Stripe Connect - Povezivanje Stripe računa
4. Widget Configuration - Embed kod i postavke
5. Managing Bookings - Pregled i upravljanje rezervacijama
6. iCal Sync - Sinkronizacija sa Booking.com/Airbnb
7. Notifications - Email postavke i obavijesti

**Za Guests:**
1. How to Book - Koraci za rezervaciju
2. Payment Options - Stripe, bank transfer, pay on arrival
3. Booking Lookup - Pregled postojeće rezervacije
4. Cancellation - Otkazivanje rezervacije

**API Reference:**
1. Cloud Functions API - createBookingAtomic, verifyBookingAccess, etc.
2. Widget Embed Options - URL parametri, customization
3. Webhook Events - Stripe webhooks, booking events

**Izvor sadržaja:** Ovaj projekt (CLAUDE.md, SECURITY_FIXES.md, kod)

---

## 📝 TODO: Admin Controls Feature

**Prioritet:** Low (nice-to-have)
**Kompleksnost:** ~20-30 minuta
**Izvor:** Ekstrahirano iz branch `sentinel-firestore-audit-15445911159531971809`

### Opis
Admin kontrole za upravljanje korisničkim računima iz Admin panela bez potrebe za direktnim Firestore editiranjem.

### Nova polja u UserModel (`lib/shared/models/user_model.dart`):
```dart
/// Hide subscription page from this user (e.g., for special deals)
final bool hideSubscription;

/// Admin override of account type (bypasses subscription logic)
final AccountType? adminOverrideAccountType;
```

### Potrebne izmjene:

**1. UserModel** (`lib/shared/models/user_model.dart`):
- Dodati `hideSubscription` (bool, default: false)
- Dodati `adminOverrideAccountType` (AccountType?, nullable)
- Ažurirati `fromJson()` i `toJson()`
- Ažurirati `copyWith()`

**2. AdminUsersRepository** (`lib/features/admin/data/repositories/`):
```dart
Future<void> updateAdminFlags({
  required String userId,
  bool? hideSubscription,
  AccountType? adminOverrideAccountType,
  bool clearOverride = false,  // Set to true to remove override
}) async {
  final updates = <String, dynamic>{
    'updated_at': FieldValue.serverTimestamp(),
  };
  if (hideSubscription != null) {
    updates['hide_subscription'] = hideSubscription;
  }
  if (clearOverride) {
    updates['admin_override_account_type'] = FieldValue.delete();
  } else if (adminOverrideAccountType != null) {
    updates['admin_override_account_type'] = adminOverrideAccountType.name;
  }
  await _firestore.collection('users').doc(userId).update(updates);
}
```

**3. UserDetailScreen** (`lib/features/admin/presentation/screens/user_detail_screen.dart`):
- Dodati "Admin Controls" card sa:
  - Switch za `hideSubscription`
  - Dropdown za `adminOverrideAccountType` (None, Free, Premium, Enterprise)
  - Save button

**4. SubscriptionScreen** provjera:
```dart
// U subscription_screen.dart
if (user.hideSubscription) {
  // Redirect away or show "Contact admin" message
}

// Za account type provjeru
AccountType get effectiveAccountType =>
    user.adminOverrideAccountType ?? user.accountType;
```

### Korištenje
- Admin može sakriti subscription stranicu za korisnika koji ima special deal
- Admin može override-ati account type bez potrebe za Stripe subscription

---

## 📝 TODO: Security Branch Fixes (Za Kasnije)

**Prioritet:** Medium
**Branchevi:** Pregledani 2026-02-01, sadrže korisne security fixeve za budući deploy.

### Branch 1: `security-audit-2026-01-29-9611837304482000277`
**Šta radi**: Premješta `loginAttempts` Firestore write sa klijenta na Cloud Functions.
- `firestore.rules`: `loginAttempts` write → `allow write: if false`
- `authRateLimit.ts`: Nove CF `recordFailedLoginAttempt` + `resetLoginAttempts`
- `rate_limit_service.dart`: Poziva CF umjesto direktnog Firestore write-a
- `stripeSubscription.ts`: Generičke error poruke (ne leaka `error.message`)

**⚠️ Zahtijeva koordiniran deploy** (ovim redoslijedom):
1. Deploy Cloud Functions prvo
2. Deploy Flutter app
3. Deploy Firestore rules zadnje

### Branch 2: `security-audit-2025-05-22-13396931281884778762`
**Šta radi**: XSS fix u email template-ima + Stripe error sanitizacija.
- `trial-expired.ts`: `${userName}` → `${escapeHtml(userName)}`
- `trial-expiring-soon.ts`: isto `escapeHtml`
- `stripePayment.ts`: `error.message` → generička poruka
- `stripeSubscription.ts`: `error.message` → generička poruka

**Jednostavan za cherry-pick** - samo 4 fajla, mali fixevi.
