# Email Verification Status Implementation Plan (OPCIJA B)

**Datum**: 2025-12-04
**Cilj**: Implementirati `checkEmailVerificationStatus` sa pre-check logikom i session tracking

---

## 📋 PREGLED IZMJENA

### Cloud Functions Izmjene (Backend)
1. ✅ `functions/src/emailVerification.ts` - Produži TTL i dodaj session tracking
2. ✅ `functions/src/emailVerification.ts` - Već postoji `checkEmailVerificationStatus` (samo testiranje)

### Flutter Izmjene (Frontend)
3. ✅ **NOVI FAJL**: `lib/features/widget/data/services/email_verification_service.dart` - Client wrapper
4. ✅ `lib/features/widget/presentation/screens/booking_widget_screen.dart` - Pre-check logika
5. ✅ `lib/features/widget/presentation/widgets/email_verification_dialog.dart` - Opcionalno: prikaz session info

---

## 🔧 FAZA 1: Cloud Functions - Backend Izmjene

### Fajl: `functions/src/emailVerification.ts`

#### Izmjena 1.1: Konfiguracijski konstante (na vrh fajla)

**Lokacija**: Linija ~7 (poslije importa)

```typescript
// Configuration constants
const VERIFICATION_TTL_MINUTES = 30; // Extended from 10 to 30 minutes
const MAX_ATTEMPTS = 3;
const DAILY_LIMIT = 5;
const RESEND_COOLDOWN_SECONDS = 60;
```

**Razlog**: Centralizovane konstante za lakše održavanje.

---

#### Izmjena 1.2: Dodaj session tracking u `sendEmailVerificationCode`

**Lokacija**: Linija ~90 (await verificationRef.set block)

**STARI KOD** (linija 90-103):
```typescript
await verificationRef.set({
  code,
  email: emailLower,
  expiresAt,
  verified: false,
  attempts: 0,
  lastSentAt: FieldValue.serverTimestamp(),
  createdAt: existingDoc.exists ?
    existingDoc.data()?.createdAt :
    FieldValue.serverTimestamp(),
  dailyCount: existingDoc.exists ?
    FieldValue.increment(1) :
    1,
}, {merge: true});
```

**NOVI KOD**:
```typescript
// Generate session ID for tracking (SHA-256 of timestamp + email + random)
const sessionId = createHash("sha256")
  .update(`${Date.now()}-${emailLower}-${Math.random()}`)
  .digest("hex");

// Extract device fingerprint from request headers
const userAgent = request.rawRequest?.headers?.["user-agent"] || "unknown";
const ipAddress = request.rawRequest?.ip || "unknown";

await verificationRef.set({
  code,
  email: emailLower,
  expiresAt,
  verified: false,
  attempts: 0,
  lastSentAt: FieldValue.serverTimestamp(),
  createdAt: existingDoc.exists ?
    existingDoc.data()?.createdAt :
    FieldValue.serverTimestamp(),
  dailyCount: existingDoc.exists ?
    FieldValue.increment(1) :
    1,
  // ✨ NEW FIELDS - Session tracking
  sessionId,
  deviceFingerprint: {
    userAgent,
    ipAddress,
  },
}, {merge: true});
```

**Šta dodajemo**:
- `sessionId` - Unique identifier za ovaj verification session
- `deviceFingerprint.userAgent` - Browser/device info
- `deviceFingerprint.ipAddress` - IP adresa (dodatna sigurnost)

---

#### Izmjena 1.3: Update TTL u `sendEmailVerificationCode`

**Lokacija**: Linija ~87

**STARI KOD**:
```typescript
const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes
```

**NOVI KOD**:
```typescript
const expiresAt = new Date(Date.now() + VERIFICATION_TTL_MINUTES * 60 * 1000); // 30 minutes
```

**Razlog**: Koristi konfiguracijsku konstantu.

---

#### Izmjena 1.4: Poboljšaj `checkEmailVerificationStatus` response

**Lokacija**: Linija ~280 (return statement u checkEmailVerificationStatus)

**STARI KOD**:
```typescript
return {
  verified: data.verified === true && !isExpired,
  exists: true,
  expired: isExpired,
};
```

**NOVI KOD**:
```typescript
// Calculate remaining time in minutes
const remainingMinutes = expiresAt
  ? Math.max(0, Math.floor((expiresAt.getTime() - Date.now()) / 60000))
  : 0;

return {
  verified: data.verified === true && !isExpired,
  exists: true,
  expired: isExpired,
  remainingMinutes, // How many minutes until expiry
  verifiedAt: data.verifiedAt?.toDate().toISOString() || null,
  sessionId: data.sessionId || null, // Include for session tracking
};
```

**Šta dodajemo**:
- `remainingMinutes` - Koliko još minuta je verification validan
- `verifiedAt` - Kada je email verifikovan (ISO timestamp)
- `sessionId` - Session ID za tracking

---

#### Izmjena 1.5: Update return kada dokument ne postoji

**Lokacija**: Linija ~270

**STARI KOD**:
```typescript
if (!doc.exists) {
  return {
    verified: false,
    exists: false,
  };
}
```

**NOVI KOD**:
```typescript
if (!doc.exists) {
  return {
    verified: false,
    exists: false,
    expired: false,
    remainingMinutes: 0,
    verifiedAt: null,
    sessionId: null,
  };
}
```

**Razlog**: Konzistentan response format.

---

### 📝 Rezime: functions/src/emailVerification.ts izmjene

| Sekcija | Linija | Akcija |
|---------|--------|--------|
| Konstante | ~7 | Dodaj VERIFICATION_TTL_MINUTES = 30 |
| sendEmailVerificationCode | ~87 | Zamijeni hardcoded 10 sa konstantom |
| sendEmailVerificationCode | ~90-103 | Dodaj sessionId + deviceFingerprint |
| checkEmailVerificationStatus | ~270 | Update "not exists" response |
| checkEmailVerificationStatus | ~280 | Dodaj remainingMinutes, verifiedAt, sessionId |

---

## 🎨 FAZA 2: Flutter - Email Verification Service (Client Wrapper)

### **NOVI FAJL**: `lib/features/widget/data/services/email_verification_service.dart`

**Razlog**: Centralizovana logika za pozivanje Cloud Function-a.

```dart
import 'package:cloud_functions/cloud_functions.dart';
import '../../../../../core/services/logging_service.dart';

/// Response model for email verification status check
class EmailVerificationStatus {
  final bool verified;
  final bool exists;
  final bool expired;
  final int remainingMinutes;
  final String? verifiedAt;
  final String? sessionId;

  const EmailVerificationStatus({
    required this.verified,
    required this.exists,
    required this.expired,
    required this.remainingMinutes,
    this.verifiedAt,
    this.sessionId,
  });

  factory EmailVerificationStatus.fromJson(Map<String, dynamic> json) {
    return EmailVerificationStatus(
      verified: json['verified'] as bool? ?? false,
      exists: json['exists'] as bool? ?? false,
      expired: json['expired'] as bool? ?? false,
      remainingMinutes: json['remainingMinutes'] as int? ?? 0,
      verifiedAt: json['verifiedAt'] as String?,
      sessionId: json['sessionId'] as String?,
    );
  }

  /// Helper: Is email verified and NOT expired?
  bool get isValid => verified && !expired;

  /// Helper: User-friendly message
  String get statusMessage {
    if (isValid) {
      return 'Email verified ✓ (expires in $remainingMinutes min)';
    } else if (expired) {
      return 'Verification expired. Please verify again.';
    } else if (exists) {
      return 'Verification pending.';
    } else {
      return 'Email not verified.';
    }
  }
}

/// Service for email verification operations
class EmailVerificationService {
  static final _functions = FirebaseFunctions.instance;

  /// Check email verification status without sending a new code
  ///
  /// Returns [EmailVerificationStatus] with current verification state.
  /// Throws [FirebaseFunctionsException] on error.
  static Future<EmailVerificationStatus> checkStatus(String email) async {
    try {
      LoggingService.logOperation(
        '[EmailVerificationService] Checking status for: $email',
      );

      final callable = _functions.httpsCallable('checkEmailVerificationStatus');
      final result = await callable.call({'email': email});

      final data = result.data as Map<String, dynamic>;
      final status = EmailVerificationStatus.fromJson(data);

      LoggingService.logSuccess(
        '[EmailVerificationService] Status: verified=${status.verified}, '
        'expired=${status.expired}, remaining=${status.remainingMinutes}min',
      );

      return status;
    } on FirebaseFunctionsException catch (e) {
      await LoggingService.logError(
        '[EmailVerificationService] Functions error',
        e,
      );
      rethrow;
    } catch (e) {
      await LoggingService.logError(
        '[EmailVerificationService] Unexpected error',
        e,
      );
      rethrow;
    }
  }

  /// Send email verification code
  ///
  /// This is a convenience wrapper around the existing function.
  /// Returns true if code was sent successfully.
  static Future<bool> sendCode(String email) async {
    try {
      LoggingService.logOperation(
        '[EmailVerificationService] Sending code to: $email',
      );

      final callable = _functions.httpsCallable('sendEmailVerificationCode');
      await callable.call({'email': email});

      LoggingService.logSuccess('[EmailVerificationService] Code sent');
      return true;
    } catch (e) {
      await LoggingService.logError(
        '[EmailVerificationService] Failed to send code',
        e,
      );
      return false;
    }
  }

  /// Verify email code
  ///
  /// Returns true if code is valid and email is now verified.
  static Future<bool> verifyCode(String email, String code) async {
    try {
      LoggingService.logOperation(
        '[EmailVerificationService] Verifying code',
      );

      final callable = _functions.httpsCallable('verifyEmailCode');
      final result = await callable.call({'email': email, 'code': code});

      final data = result.data as Map<String, dynamic>;
      final verified = data['verified'] as bool? ?? false;

      if (verified) {
        LoggingService.logSuccess('[EmailVerificationService] Verified!');
      }

      return verified;
    } catch (e) {
      await LoggingService.logError(
        '[EmailVerificationService] Verification failed',
        e,
      );
      return false;
    }
  }
}
```

**Šta ovaj servis pruža**:
1. ✅ `checkStatus()` - Poziva `checkEmailVerificationStatus` Cloud Function
2. ✅ `sendCode()` - Wrapper za slanje koda
3. ✅ `verifyCode()` - Wrapper za verifikaciju koda
4. ✅ `EmailVerificationStatus` model - Type-safe response
5. ✅ Helper metode (`isValid`, `statusMessage`)

---

## 📱 FAZA 3: Flutter - Pre-Check Logika u Booking Widget

### Fajl: `lib/features/widget/presentation/screens/booking_widget_screen.dart`

#### Izmjena 3.1: Import novog servisa

**Lokacija**: ~42 (poslije postojećih importa)

```dart
import '../../data/services/email_verification_service.dart';
```

---

#### Izmjena 3.2: Update `_openVerificationDialog()` sa pre-check logikom

**Lokacija**: Linija 2441-2459

**STARI KOD**:
```dart
Future<void> _openVerificationDialog() async {
  final email = _emailController.text.trim();
  final isDarkMode = ref.read(themeProvider);

  final verified = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => EmailVerificationDialog(
      email: email,
      colors: MinimalistColorSchemeAdapter(dark: isDarkMode),
    ),
  );

  if (verified == true && mounted) {
    setState(() {
      _emailVerified = true;
    });
  }
}
```

**NOVI KOD**:
```dart
Future<void> _openVerificationDialog() async {
  final email = _emailController.text.trim();
  final isDarkMode = ref.read(themeProvider);

  // ✨ PRE-CHECK: Da li je email već verifikovan?
  try {
    LoggingService.logOperation('[BookingWidget] Pre-checking email verification status');

    final status = await EmailVerificationService.checkStatus(email);

    // Email is already verified and NOT expired
    if (status.isValid) {
      LoggingService.logSuccess(
        '[BookingWidget] Email already verified (expires in ${status.remainingMinutes}min)',
      );

      if (mounted) {
        setState(() {
          _emailVerified = true;
        });

        SnackBarHelper.showSuccess(
          context: context,
          message: 'Email already verified ✓ (valid for ${status.remainingMinutes} min)',
        );
      }

      return; // ✅ Skip dialog - email already verified
    }

    // Email exists but expired
    if (status.exists && status.expired) {
      LoggingService.logWarning('[BookingWidget] Verification expired, sending new code');
    }

    // Email not verified or expired - show dialog normally
  } on FirebaseFunctionsException catch (e) {
    // Pre-check failed (network issue, etc.) - fallback to normal flow
    await LoggingService.logWarning(
      '[BookingWidget] Pre-check failed, showing dialog anyway: ${e.message}',
    );
  } catch (e) {
    await LoggingService.logWarning(
      '[BookingWidget] Pre-check error, showing dialog anyway',
    );
  }

  // Show verification dialog (either new verification or pre-check failed)
  if (!mounted) return;

  final verified = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => EmailVerificationDialog(
      email: email,
      colors: MinimalistColorSchemeAdapter(dark: isDarkMode),
    ),
  );

  if (verified == true && mounted) {
    setState(() {
      _emailVerified = true;
    });
  }
}
```

**Šta nova logika radi**:
1. ✅ **PRE-CHECK**: Poziva `checkStatus()` prije otvaranja dialoga
2. ✅ **Happy path**: Ako je email već verified i nije expired → skip dialog
3. ✅ **Fallback**: Ako pre-check failed → nastavi sa normalnim flow-om
4. ✅ **UX feedback**: Prikaži koliko još minuta je verification validan

---

## 🛡️ FAZA 4: Safety Check Prije Booking Submita

### Fajl: `lib/features/widget/presentation/screens/booking_widget_screen.dart`

#### Izmjena 4.1: Dodaj `_validateEmailVerificationBeforeBooking()` helper metodu

**Lokacija**: ~2400 (prije `_openVerificationDialog`)

```dart
/// Safety check: Validate that email verification is still valid before booking
///
/// Returns true if verification is valid (or not required).
/// Returns false and shows error if verification expired.
Future<bool> _validateEmailVerificationBeforeBooking() async {
  // Skip check if email verification is not required
  if (_widgetSettings?.emailConfig.requireEmailVerification != true) {
    return true; // No verification needed
  }

  // Skip check if email is not verified in UI state
  if (!_emailVerified) {
    // This shouldn't happen (button should be disabled), but safety check
    SnackBarHelper.showError(
      context: context,
      message: 'Please verify your email before booking',
    );
    return false;
  }

  try {
    LoggingService.logOperation('[BookingWidget] Final email verification check before booking');

    final email = _emailController.text.trim();
    final status = await EmailVerificationService.checkStatus(email);

    // Verification is still valid
    if (status.isValid) {
      LoggingService.logSuccess(
        '[BookingWidget] Email verification valid (${status.remainingMinutes}min remaining)',
      );
      return true;
    }

    // Verification expired between initial verification and booking submit
    if (status.expired) {
      LoggingService.logWarning('[BookingWidget] Email verification expired during booking flow');

      if (mounted) {
        setState(() {
          _emailVerified = false; // Reset UI state
        });

        SnackBarHelper.showError(
          context: context,
          message: 'Email verification expired. Please verify again before booking.',
        );
      }

      return false;
    }

    // Email not verified (shouldn't happen, but safety check)
    LoggingService.logWarning('[BookingWidget] Email not verified at final check');

    if (mounted) {
      setState(() {
        _emailVerified = false;
      });

      SnackBarHelper.showError(
        context: context,
        message: 'Email verification required. Please verify your email.',
      );
    }

    return false;
  } catch (e) {
    // Network error or Cloud Function failed
    await LoggingService.logError(
      '[BookingWidget] Email verification check failed',
      e,
    );

    // ⚠️ DECISION: Allow booking on check failure or block?
    // Option A: Block booking (safer)
    if (mounted) {
      SnackBarHelper.showError(
        context: context,
        message: 'Unable to verify email status. Please try again.',
      );
    }
    return false;

    // Option B: Allow booking (better UX, less safe)
    // return true; // Fallback: Allow booking if check fails
  }
}
```

---

#### Izmjena 4.2: Integriraj u `_handleBookNow()` metodu

**Lokacija**: Traži gdje se poziva `_submitBooking()` (oko linije 1900-2000)

**Potrebno pronaći lokaciju**. Tipično izgleda ovako:

```dart
Future<void> _handleBookNow() async {
  // Existing validation...

  // ✨ DODAJ OVU LINIJU PRIJE SUBMIT-a:

  // Final safety check: Email verification still valid?
  final emailVerificationValid = await _validateEmailVerificationBeforeBooking();
  if (!emailVerificationValid) {
    return; // Block booking - verification expired
  }

  // Continue with booking submission...
  await _submitBooking();
}
```

**Gdje tačno dodati**: Trebam pronaći `_handleBookNow` ili sličnu metodu koja poziva `_submitBooking`.

---

## 🧪 FAZA 5: Testing Scenarios

### Test Case 1: Happy Path (Email Already Verified)

**Setup**:
1. User verifikuje email
2. Čeka 5 minuta
3. Klikne "Verify" ponovo

**Expected**:
- ✅ Pre-check detektuje valid verification
- ✅ Dialog se NE otvara
- ✅ Success message: "Email already verified ✓ (valid for 25 min)"

---

### Test Case 2: Verification Expired During Booking

**Setup**:
1. User verifikuje email
2. Ostavi tab otvoren 31 minut
3. Pokušaj booking

**Expected**:
- ✅ Final safety check detektuje expired verification
- ✅ Error message: "Email verification expired. Please verify again."
- ✅ Booking se NE submituje
- ✅ `_emailVerified` = false (UI state reset)

---

### Test Case 3: Pre-Check Failed (Network Error)

**Setup**:
1. Disconnect internet
2. Klikne "Verify"

**Expected**:
- ⚠️ Pre-check throws exception
- ✅ Fallback: Dialog se otvara normalno
- ✅ User može poslati kod (ako je reconnected)

---

### Test Case 4: Multiple Browser Tabs (Session Tracking)

**Setup**:
1. Tab A: Verifikuje email
2. Tab B: Otvori isti email

**Expected** (sa session tracking):
- Tab A: `sessionId = abc123`
- Tab B: `sessionId = xyz789` (different)
- ✅ Pre-check pokazuje "verified" u oba taba (dijele isti email hash)

**Note**: Session tracking JE implementiran u backend-u, ali trenutno NE provjeravamo session match u Flutter-u. To je dodatna feature ako želiš stroži security.

---

## 📊 Rezime Svih Fajlova za Izmjenu

| # | Fajl | Izmjene |
|---|------|---------|
| 1 | `functions/src/emailVerification.ts` | Dodaj konstante, session tracking, produži TTL, poboljšaj response |
| 2 | **NOVI** `lib/features/widget/data/services/email_verification_service.dart` | Client wrapper servis za Cloud Function pozive |
| 3 | `lib/features/widget/presentation/screens/booking_widget_screen.dart` | Import servisa, pre-check u `_openVerificationDialog()` |
| 4 | `lib/features/widget/presentation/screens/booking_widget_screen.dart` | Dodaj `_validateEmailVerificationBeforeBooking()` + integriraj u `_handleBookNow()` |

---

## 🚀 Deployment Checklist

### Backend (Cloud Functions)

```bash
# 1. Build Functions
cd functions
npm run build

# 2. Deploy samo emailVerification funkcije
firebase deploy --only functions:sendEmailVerificationCode,functions:verifyEmailCode,functions:checkEmailVerificationStatus

# 3. Verify deployment
firebase functions:log --only sendEmailVerificationCode
```

### Frontend (Flutter)

```bash
# 1. Run analyzer
flutter analyze

# 2. Test na local emulator
flutter run -d chrome --web-port 5000

# 3. Build production
flutter build web --release

# 4. Deploy
firebase deploy --only hosting:web_widget
```

---

## 🎯 Prioritet Implementacije

**Dan 1** (2-3 sata):
- ✅ FAZA 1: Cloud Functions backend izmjene
- ✅ Deploy Functions
- ✅ FAZA 2: Create Flutter service wrapper

**Dan 2** (2-3 sata):
- ✅ FAZA 3: Pre-check logika
- ✅ FAZA 4: Safety check
- ✅ FAZA 5: Testing

**Total**: ~4-6 sati development + testiranje

---

## ⚠️ Važne Napomene

1. **Session Tracking je INFORMATIVNO**: Backend sprema `sessionId` i `deviceFingerprint`, ali trenutno **NE blokiramo** cross-device pristup. To je dodatna feature za kasnije.

2. **Fallback Strategy**: Ako pre-check ili safety check **fails** (network error), dozvoljavamo user-u da nastavi sa normalnim flow-om. To je **by design** - ne želimo blokirati legit user-e zbog network issua.

3. **TTL 30 minuta**: Možeš konfigurirati preko konstante `VERIFICATION_TTL_MINUTES`. Preporučujem testirati sa 5 minuta za development, pa povećati na 30 za production.

4. **Compatibility**: `checkEmailVerificationStatus` je **read-only** operacija - ne mijenja stanje u Firestore-u. Safe za pozivanje koliko god puta treba.

---

## 📞 Next Steps

Hoćeš li da:
1. **A)** Ja odmah počnem sa implementacijom po ovom planu?
2. **B)** Ti želiš prvo reviewati plan pa mi daš zeleno svjetlo?
3. **C)** Imaš dodatna pitanja ili izmjene u planu?

Javi mi šta preferiraš! 🚀
