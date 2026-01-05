# 🔒 SIGURNOSNA ANALIZA: Owner Dashboard Autentifikacija

**Datum**: 2025-01-XX
**Scope**: Owner Dashboard Login/Register/Auth Flow
**Status**: ✅ **SIGURNO** - većina preporuka implementirana
**Zadnje ažurirano**: 2025-12-16

---

## 📊 UKUPNA OCJENA SIGURNOSTI

| Kategorija | Ocjena | Status |
|------------|--------|--------|
| **Firestore Security Rules** | ⭐⭐⭐⭐ (4/5) | Dobro |
| **Rate Limiting** | ⭐⭐⭐⭐⭐ (5/5) | Odlično |
| **Input Validation** | ⭐⭐⭐⭐⭐ (5/5) | ✅ **IMPLEMENTIRANO** |
| **Password Policy** | ⭐⭐⭐⭐ (4/5) | ✅ **2-TIER SISTEM** |
| **Session Management** | ⭐⭐⭐⭐ (4/5) | Dobro |
| **Security Logging** | ⭐⭐⭐⭐⭐ (5/5) | Odlično |
| **Email Verification** | ⭐⭐⭐⭐ (4/5) | ✅ **ENFORCEMENT DODAN** |

**UKUPNO**: ⭐⭐⭐⭐½ (4.5/5) - **SIGURNO za SaaS aplikaciju**

---

## ✅ ŠTA JE DOBRO

### 1. Firestore Security Rules ⭐⭐⭐⭐

**Pozitivno:**
- ✅ `users/{userId}` - Users mogu samo čitati/pisati svoje podatke (`isOwner(userId)`)
- ✅ `loginAttempts` - Potpuno zaključana (`allow read: false, allow write: false`) - samo Cloud Functions
- ✅ `securityEvents` - Write zaključan, read samo vlastiti (`resource.data.userId == request.auth.uid`)
- ✅ `properties/{propertyId}` - Write zaštićen sa `canCreateAsOwner()` i `isResourceOwnerOrLegacy()`
- ✅ `bookings` - Owner-only write, public read (za widget)
- ✅ `notifications` - Owner-only read/write

**Potencijalni problemi:**
- ⚠️ Legacy support (`isResourceOwnerOrLegacy()`) - omogućava update bez `owner_id` provjere za stare dokumente
  - **Rizik**: Nizak - samo za stare dokumente, novi dokumenti moraju imati `owner_id`
  - **Preporuka**: Migrirati sve stare dokumente i ukloniti legacy support

### 2. Rate Limiting ⭐⭐⭐⭐⭐

**Implementacija:**
- ✅ Max 5 pokušaja
- ✅ 15 minuta lockout period
- ✅ 1 sat reset nakon neaktivnosti
- ✅ Firestore-backed (ne može se zaobići)
- ✅ `loginAttempts` collection potpuno zaključana u rules

**Zaštita:**
- ✅ Brute force napadi - **ZAŠTIĆENO**
- ✅ Dictionary attacks - **ZAŠTIĆENO**
- ✅ Distributed attacks - **Djelomično zaštićeno** (per-email, ne per-IP)

**Preporuka**: Dodati IP-based rate limiting u Cloud Functions za dodatnu zaštitu.

### 3. Security Events Logging ⭐⭐⭐⭐⭐

**Implementacija:**
- ✅ Logira sve login/logout/registration evente
- ✅ Geolocation tracking (non-blocking)
- ✅ Device fingerprinting
- ✅ Suspicious activity detection (new device/location)
- ✅ Email notifications za suspicious activity
- ✅ Firestore write zaključan (samo Cloud Functions)

**Zaštita:**
- ✅ Account takeover detection - **ZAŠTIĆENO**
- ✅ Unauthorized access tracking - **ZAŠTIĆENO**
- ✅ Audit trail - **ZAŠTIĆENO**

### 4. Session Management ⭐⭐⭐⭐

**Implementacija:**
- ✅ Firebase Auth session management
- ✅ Web: LOCAL persistence (remember me) ili SESSION persistence
- ✅ Mobile: Native session management
- ✅ Automatic token refresh

**Zaštita:**
- ✅ Session hijacking - **ZAŠTIĆENO** (Firebase Auth tokens)
- ✅ Session fixation - **ZAŠTIĆENO** (Firebase generiše nove tokene)
- ⚠️ Remember me - **Djelomično zaštićeno** (LOCAL persistence traje dok se ne obriše)

**Preporuka**: Dodati "Logout from all devices" funkcionalnost.

---

## ⚠️ PROBLEMI I PREPORUKE

### 1. Input Sanitization ⭐⭐⭐⭐⭐ (5/5) ✅ IMPLEMENTIRANO

**Status:** ✅ **IMPLEMENTIRANO** (2025-12-16)

**Implementacija** (`enhanced_register_screen.dart`, linije 96-101):
```dart
final sanitizedEmail = InputSanitizer.sanitizeEmail(_emailController.text.trim());
final sanitizedFirstName = InputSanitizer.sanitizeName(_firstName);
final sanitizedLastName = InputSanitizer.sanitizeName(_lastName);
final sanitizedPhone = _phoneController.text.trim().isNotEmpty
    ? InputSanitizer.sanitizePhone(_phoneController.text.trim())
    : null;
```

**Pokriveno:**
- ✅ Email sanitization prije Firebase Auth
- ✅ firstName/lastName sanitization (XSS zaštita)
- ✅ Phone sanitization

**Rizik:** ✅ **ZAŠTIĆENO**

---

### 2. Password Policy ⭐⭐⭐⭐ (4/5) ✅ 2-TIER SISTEM

**Status:** ✅ **NAMJERNI 2-TIER DIZAJN** (dokumentirano 2025-12-16)

**Tier 1 - Registracija/Login** (`PasswordValidator.validateMinimumLength`):
- ✅ Minimum 8 karaktera
- ✅ Maximum 128 karaktera
- ✅ Sprječava sekvencijalne brojeve (12345678)
- ✅ Sprječava ponavljajuće karaktere (aaaaaaaa)
- **Koristi se u:** `enhanced_register_screen.dart`, `enhanced_auth_provider.dart`

**Tier 2 - Change Password** (`PasswordValidator.validate`):
- ✅ Svi Tier 1 zahtjevi +
- ✅ Obavezno: 1 veliko slovo
- ✅ Obavezno: 1 malo slovo
- ✅ Obavezno: 1 broj
- ✅ Obavezno: 1 specijalni karakter (!@#$%^&*(),.?":{}|<>)
- ✅ Password strength indicator u UI-u
- **Koristi se u:** `change_password_screen.dart`

**Razlog za 2-tier:**
- Registracija: Lakši onboarding za nove korisnike (rate limiting već štiti od brute force)
- Change Password: Stroži zahtjevi za postojeće korisnike (educira o sigurnosti)

**Rizik:** ✅ **PRIHVATLJIV** (rate limiting + 2-tier pristup balansira sigurnost i UX)

---

### 3. Email Verification ⭐⭐⭐⭐ (4/5) ✅ ENFORCEMENT DODAN

**Status:** ✅ **IMPLEMENTIRANO** (2025-12-16)

**Implementacija** (`router_owner.dart`, linije 229-243):
```dart
// SECURITY: Email verification enforcement for authenticated users
final requiresEmailVerification = authState.requiresEmailVerification;
final isEmailVerificationRoute = state.matchedLocation == OwnerRoutes.emailVerification;
final isPublicAuthRoute =
    state.matchedLocation == OwnerRoutes.privacyPolicy ||
    state.matchedLocation == OwnerRoutes.termsConditions ||
    state.matchedLocation == OwnerRoutes.cookiesPolicy;

if (isAuthenticated && requiresEmailVerification && !isEmailVerificationRoute && !isPublicAuthRoute) {
  return OwnerRoutes.emailVerification;
}
```

**Pokriveno:**
- ✅ Email verification se šalje nakon registracije
- ✅ Router BLOKIRA pristup dashboardu dok email nije verifikovan
- ✅ Dozvoljen pristup: Privacy Policy, Terms, Cookies (za compliance)
- ✅ User NE MOŽE zaobići email verification screen

**Rizik:** ✅ **ZAŠTIĆENO**

---

### 4. CSRF Protection ⭐⭐⭐⭐ (4/5)

**Trenutno stanje:**
- ✅ Firebase Auth koristi secure tokens (CSRF zaštićen)
- ✅ Firestore rules provjeravaju `request.auth.uid` (ne može se falsifikovati)
- ✅ Cloud Functions koriste Admin SDK (bypass-uju rules, ali su server-side)

**Rizik:**
- **Nizak** - Firebase Auth i Firestore rules automatski štite od CSRF

**Status**: ✅ **DOVOLJNO ZAŠTIĆENO**

---

### 5. XSS Protection ⭐⭐⭐ (3/5)

**Trenutno stanje:**
- ✅ Flutter automatski escape-uje HTML u Text widget-ima
- ⚠️ firstName/lastName se NE sanitizuje prije spremanja
- ⚠️ Ako se koristi `Html` widget ili `Text.rich`, može biti XSS

**Rizik:**
- **Nizak** - Flutter defaultno escape-uje, ali ako se koristi custom HTML rendering, može biti problem

**Preporuka:**
- Koristiti `InputSanitizer.sanitizeName()` prije spremanja u Firestore
- Ako se koristi HTML rendering, koristiti `Html` widget sa `sanitize: true`

**Prioritet**: Nizak (Flutter već štiti, ali sanitization je dodatna sigurnost)

---

### 6. SQL Injection ⭐⭐⭐⭐⭐ (5/5)

**Trenutno stanje:**
- ✅ Firestore NE koristi SQL (NoSQL database)
- ✅ Svi upiti koriste Firestore API (nema raw SQL)
- ✅ Input sanitization u Cloud Functions (`inputSanitization.ts`)

**Status**: ✅ **NEMA RIZIKA** (Firestore nema SQL injection)

---

### 7. Firestore Indexes ⭐⭐⭐⭐ (4/5)

**Trenutno stanje:**
- ✅ Svi kompleksni upiti imaju definisane indexes
- ✅ `firestore.indexes.json` sadrži sve potrebne indexes
- ✅ Indexes su optimizovani za performanse

**Rizik:**
- **Nizak** - Indexes ne utiču direktno na sigurnost, ali loše performanse mogu dovesti do DoS

**Status**: ✅ **DOBRO** - Svi potrebni indexes su definisani

---

## 🎯 PRIORITETNE PREPORUKE

### ✅ IMPLEMENTIRANO (2025-12-16)

1. ✅ **Input Sanitization u Register Formi** - DONE
   - `InputSanitizer.sanitizeEmail()`, `sanitizeName()`, `sanitizePhone()`
   - **Fajl**: `enhanced_register_screen.dart`

2. ✅ **Email Verification Enforcement** - DONE
   - Router blokira pristup dashboardu dok email nije verifikovan
   - **Fajl**: `router_owner.dart`

3. ✅ **Password Complexity (2-Tier)** - DOKUMENTIRANO KAO NAMJERNO
   - Tier 1 za registraciju (lakši onboarding)
   - Tier 2 za change password (stroži zahtjevi)
   - **Fajlovi**: `enhanced_register_screen.dart`, `change_password_screen.dart`

### 🟡 SREDNJI PRIORITET (Opciono poboljšanje)

4. **IP-based Rate Limiting**
   - Dodati IP tracking za login pokušaje
   - Trenutno: email-based rate limiting (funkcionira)
   - **Poboljšanje**: Dodati IP-based zaštitu od distributed napada
   - **Fajl**: `functions/src/utils/rateLimit.ts`

### 🟢 NISKI PRIORITET (Nice to have)

5. **Password History**
   - Spremati hash-eve prethodnih passworda
   - Onemogućiti korištenje istog passworda
   - **Status**: Nije implementirano, nije kritično

6. **"Logout from all devices"**
   - Invalidate sve Firebase Auth tokene
   - **Status**: Nije implementirano, korisno za kompromitovane accounte

---

## 🔐 NAPADI I ZAŠTITA

| Napad | Zaštita | Status |
|-------|---------|--------|
| **Brute Force** | Rate limiting (5 pokušaja, 15 min lockout) | ✅ **ZAŠTIĆENO** |
| **Dictionary Attack** | Rate limiting + password minimum length | ✅ **ZAŠTIĆENO** |
| **Credential Stuffing** | Rate limiting + Firebase Auth | ✅ **ZAŠTIĆENO** |
| **Session Hijacking** | Firebase Auth secure tokens | ✅ **ZAŠTIĆENO** |
| **CSRF** | Firebase Auth tokens | ✅ **ZAŠTIĆENO** |
| **SQL Injection** | Firestore (NoSQL) | ✅ **NEMA RIZIKA** |
| **XSS** | Flutter auto-escaping | ✅ **ZAŠTIĆENO** (sa preporukom za sanitization) |
| **Account Takeover** | Security events logging + suspicious activity detection | ✅ **ZAŠTIĆENO** |
| **Email Spoofing** | Email verification (ali nije obavezno) | ⚠️ **DJELOMIČNO** |
| **Distributed Attacks** | Per-email rate limiting | ⚠️ **DJELOMIČNO** (dodati IP-based) |

---

## 📝 ZAKLJUČAK

**Trenutna sigurnost**: ⭐⭐⭐⭐½ (4.5/5) - **SIGURNO za SaaS aplikaciju**

**Implementirano (2025-12-16):**
1. ✅ Input sanitization u auth formama
2. ✅ Email verification enforcement u routeru
3. ✅ 2-tier password policy (namjerni dizajn za balans sigurnosti i UX)

**Preostalo (opciono):**
- ⚠️ IP-based rate limiting (SREDNJI prioritet - poboljšava zaštitu od distributed napada)
- 🟢 Password history (NISKI prioritet)
- 🟢 Logout from all devices (NISKI prioritet)

**Performanse:**
- ✅ Rate limiting je non-blocking (ne utiče na UX)
- ✅ Security logging je non-blocking (ne utiče na performanse)
- ✅ Firestore indexes su optimizovani

**User Experience:**
- ✅ Rate limiting poruke su user-friendly
- ✅ Error poruke su jasne
- ✅ Email verification je obavezno (ali user može nastaviti nakon verifikacije)

---

**Status**: Svi VISOKI prioritet preporuke su implementirane. Aplikacija je spremna za production.
