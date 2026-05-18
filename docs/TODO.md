# BookBed TODO Items

Extracted from CLAUDE.md — inactive planning items.

---

## 🚨 TODO: Tech Debt Audit Findings (2026-05-18)

**Prioritet:** Mixed (C1 critical, rest medium)
**Izvor:** `audit/04-techdebt.md`, `audit/04b-flutter-analyze-summary.md`, `audit/04c-hardcoded-urls.md`

### Critical
- **C1 — MD5 IV in `bookingComApi.encryptToken`** (`functions/src/bookingComApi.ts:64-90`). Static IV + AES-CBC leaks token equality. Replace with `crypto.randomBytes(16)` per-encryption (prepend to ciphertext) OR migrate to Cloud KMS per existing TODO.
- **C3 — 2 silent catches in confirmation screen** (`lib/features/widget/presentation/screens/booking_confirmation_screen.dart:171,192`). Wrap `tabService.dispose()` failures with `LoggingService.logWarning` (debug-mode only, no Sentry noise). Attempted in branch `fix/widget-silent-catches` (commit `6f7419147`) but file reverted locally — re-apply.

### High / Medium
- **H2 — Stripe Price IDs hardcoded** (`functions/src/stripeSubscription.ts:44`). Replace with env-sourced IDs.
- **M1 — Booking.com / Airbnb API stubs** are placeholder OAuth/API URLs. Finish or remove dead code.
- **M2 — Trial expiry email templates** are TODO-marked plaintext. Migrate to V2 (see existing "V2 Trial Email Migration" TODO above for branch list).
- **M4 — `rab-booking-248fc` hardcoded in `ical_export_list_screen.dart:211`**. Replace `const projectId = 'rab-booking-248fc'` with `EnvironmentConfig.firebaseProjectId`. Already in `.claude/rules/hosting-build.md`.
- **M5 — Cancellation policy logic stub** (`functions/src/guestCancelBooking.ts:250`).
- **M6 — 7 production `print()` calls** in widget config/helpers (`tax_legal_config.dart`, `booking_price_calculator.dart`, `ical_export_config.dart`, `embed_url_params.dart`, `email_verification_service.dart`, `availability_checker.dart`). Route through `LoggingService`.
- **M7 — Centralize `bookbed.io` literals** in 6 sites (see `audit/04c-hardcoded-urls.md` §3.1). Add `widgetHost`/`dashboardHost`/`marketingHost`/`isMarketingHost()` getters to `EnvironmentConfig` (concrete code in §4).

### Code-health
- Fix brittle `host.startsWith('view.')` in `subdomain_service.dart:51` + `booking_view_screen.dart:107` → use `host.endsWith('.$widgetHost')` (won't match `staging.view.bookbed.io` today).
- Consolidate duplicate `_subdomainBaseDomain` consts in `embed_widget_guide_screen.dart:31` + `embed_code_generator_dialog.dart:40`.
- 2 discontinued + 133 outdated packages reported by `flutter pub outdated` — separate hygiene pass.

---

## 🚨 TODO: Android Release Blocker — AAB build broken (2026-05-18)

**Prioritet:** **HIGH — blokira svaki Play Store update dok se ne popravi**
**Izvor:** `audit/06-android-16kb-compliance.md` § 6
**Deadline kontekst:** Sljedeći prozor za Android release ≈ **2026-05-31** (Google Play 16 KB rok — sam APK je već usklađen, ali AAB se ne buildaj).

### Problem

`flutter build appbundle --release --target lib/main.dart` puca u
`:app:compileReleaseJavaWithJavac`:

```
android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java:69:
  error: package net.jonhanson.flutter_native_splash does not exist
```

`flutter build apk --release` PROLAZI sa istim source-om — razlika je samo u
`bundleRelease` putu kompilacije.

### Root cause

`flutter_native_splash: ^2.4.3` je u `pubspec.yaml` deklariran kao **`direct dev`**
(build-time CLI za generisanje splash assets). Novije verzije više se ne
auto-registruju kao runtime Flutter plugin, ali `GeneratedPluginRegistrant.java`
i dalje import-uje nepostojeći `net.jonhanson.flutter_native_splash.FlutterNativeSplashPlugin`.

### Fix (jedan od)

1. Premjesti `flutter_native_splash` iz `dependencies:` u `dev_dependencies:`
   (build tool, ne runtime plugin). Flutter će regenerisati registrant bez njega.
2. Obriši `android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java`
   i pusti Flutter da ga ponovo emit-uje na sljedeći `flutter build`.

Verifikuj sa `flutter build appbundle --release --target lib/main.dart`.

### 16 KB compliance — već OK

Sam APK je 100% usklađen sa Google Play 16 KB page-size pravilom (15/15 .so
ALIGNED 2¹⁴ ili 2¹⁶, sve 64-bit ABI). Pošto AAB pakuje iste `.so` outpute iz
`:app:mergeReleaseNativeLibs`, 16 KB verdikt vrijedi i za AAB čim se ovaj
registrant fix odradi. Nije potreban package upgrade.

### Build-environment note (povezano)

`android/gradle.properties` `org.gradle.jvmargs=-Xmx2G` je tačno na granici
OOM-a za JetifyTransform Flutter engine JAR-a sa trenutnim dep tree-em. Tokom
16 KB audit-a privremeno bumpovan na `-Xmx6G` da prođe; vraćen na 2G.
Ako sljedeći Android build ponovo OOM-a na `:app:mergeReleaseNativeLibs`,
razmotri trajno postavljanje `-Xmx6G` kao default za projekat.

---

## 📝 TODO: V2 Trial Email Migration

**Prioritet:** Medium
**Kompleksnost:** ~30 min (cherry-pick + verify)
**Izvor:** Audit `/audit/02-branches.md` (2026-05-18)

### Opis

`functions/src/email/templates/trial-expired.ts` (29 lines) i `trial-expiring-soon.ts` na main su jedini V1 plain-HTML template-i. Svih ostalih 16 koriste V2 (`generateEmailHtml` + `template-helpers`). Migracija je započeta ali nije završena — 6 Jules branch-eva propose istu V2 implementaciju, nijedan nije merge-an.

### Branch-evi koji propose V2 (svi rebased na `eadec3cc`, 1 commit ahead main)

| Branch | `expired` | `expiring-soon` | `emailService.ts` |
|--------|:--:|:--:|:--:|
| `refactor/trial-email-templates-v2-5763908700715533391` | ✓ | ✓ | ✓ |
| `fix-trial-expired-email-templates-18008471850879630724` | ✓ | ✓ | ✓ |
| `chore/email-template-v2-trial-862790160808869431` | ✓ | ✓ | ✗ |
| `feat/trial-expiring-soon-email-v2-14525277221150061144` | ✗ | ✓ | ✓ |
| `code-health/trial-email-template-7946221639053422749` | ✗ | ✓ | ✓ |
| `fix/email-template-trial-expired-v2-3198370588912331709` | ✓ | ✗ | ✓ |

### Akcioni plan

1. Diff dva top kandidata (`refactor/…-v2-5763908700715533391` vs `fix-trial-expired-email-templates-…`) — biraj cleaner.
2. Cherry-pick taj jedan commit (oba template-a + `emailService.ts` wiring).
3. `cd functions && npm test` da provjeris da V2 escape-uje HTML kako treba.
4. Deploy: `cd functions && npm run deploy` (Cloud Functions ne reflect-uju git bez deploy-a — vidi MEMORY.md #3).
5. Kill ostalih 5 branch-eva (`git push origin --delete <branch>`).

### Riziko

Nizak. V2 helper-i (`escapeHtml`, `generateEmailHtml`) već postoje na main i koriste se u svim drugim template-ima. Trial-* su jedini stragglers.

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
