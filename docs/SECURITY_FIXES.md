# 🔐 Security Fixes Documentation

Ovaj dokument prati sve sigurnosne ispravke u projektu. Svaka ispravka je detaljno dokumentirana kako bi se u budućnosti moglo provjeriti da li je možda prouzrokovala neki bug.

---

## Sadržaj

1. [SF-001: Owner ID Validation in Booking Creation](#sf-001-owner-id-validation-in-booking-creation)
2. [SF-002: SSRF Prevention in iCal Sync](#sf-002-ssrf-prevention-in-ical-sync)
3. [SF-003: Revenue Chart maxValue Recalculation (ODBIJENO)](#sf-003-revenue-chart-maxvalue-recalculation-odbijeno)
4. [SF-004: IconButton Hover/Splash Feedback](#sf-004-iconbutton-hoversplash-feedback)
5. [SF-005: Phone Number Validation](#sf-005-phone-number-validation)
6. [SF-006: Sequential Character Password Check](#sf-006-sequential-character-password-check)
7. [SF-007: Remove Insecure Password Storage (CRITICAL)](#sf-007-remove-insecure-password-storage-critical)
8. [SF-008: Booking Notes Length Limit](#sf-008-booking-notes-length-limit)
9. [SF-009: Error Handling Info Leakage Prevention](#sf-009-error-handling-info-leakage-prevention)
10. [SF-010: Year Calendar Race Condition Fix](#sf-010-year-calendar-race-condition-fix)
11. [SF-011: Ignore Service Account Key (CRITICAL)](#sf-011-ignore-service-account-key-critical)
12. [SF-012: Secure Error Handling & Email Sanitization](#sf-012-secure-error-handling--email-sanitization)
13. [SF-013: Haptic Feedback on Password Toggle](#sf-013-haptic-feedback-on-password-toggle)
14. [SF-014: Prevent PII Exposure in Booking Widget (HIGH)](#sf-014-prevent-pii-exposure-in-booking-widget-high)
15. [SF-015: DebouncedSearchField ValueNotifier Optimization](#sf-015-debouncedsearchfield-valuenotifier-optimization)
16. [SF-016: AnimatedGradientFAB ValueNotifier Optimization](#sf-016-animatedgradientfab-valuenotifier-optimization)
17. [SF-017: Password Visibility Toggle Tooltips](#sf-017-password-visibility-toggle-tooltips)
18. [SF-018: Common Password Blacklist](#sf-018-common-password-blacklist)
19. [Neriješeni bugovi (Jules audit)](#-neriješeni-bugovi-jules-audit)
    - [BUG-001: iCal Feeds Provider - nedostaje autoDispose](#-bug-001-ical-feeds-provider---nedostaje-autodispose)
    - [BUG-002: IP Geolocation Service - nedostaje in-memory cache](#-bug-002-ip-geolocation-service---nedostaje-in-memory-cache)
    - [BUG-003: iCal Sync - sekvencijalno vs paralelno procesiranje](#-bug-003-ical-sync---sekvencijalno-vs-paralelno-procesiranje)
    - [BUG-004: Owner Bookings Repository - print umjesto LoggingService](#-bug-004-owner-bookings-repository---print-umjesto-loggingservice)
    - [BUG-005: Dashboard Overview - deferred loading za graphic library](#-bug-005-dashboard-overview---deferred-loading-za-graphic-library)
    - [BUG-006: QR Code Payment - deferred loading za qr_flutter library](#-bug-006-qr-code-payment---deferred-loading-za-qr_flutter-library)

---

## SF-001: Owner ID Validation in Booking Creation

**Datum**: 2026-01-05  
**Prioritet**: Low  
**Status**: ✅ Riješeno  
**Zahvaćeni fajlovi**: `functions/src/atomicBooking.ts`

### Problem

U `createBookingAtomic` Cloud Function, `ownerId` parametar je dolazio direktno iz klijentskog zahtjeva bez validacije. Ovo je značilo da je maliciozni korisnik mogao:

1. Presresti Cloud Function poziv
2. Promijeniti `ownerId` na svoj vlastiti user ID
3. Kreirati booking s pogrešnim `owner_id`

**Prije ispravke (linija ~107-110):**
```typescript
const {
  unitId,
  propertyId,
  ownerId,  // ← Direktno iz klijentskog zahtjeva - NEPOUZDANO!
  // ...
} = data;
```

**Posljedice (bez ispravke):**
- Pravi vlasnik nekretnine ne bi vidio rezervaciju u svom dashboardu
- Email notifikacije bi išle pogrešnoj osobi
- Napadač bi vidio rezervaciju u SVOM dashboardu (beskorisno - ne posjeduje nekretninu)
- Kalendar bi i dalje bio blokiran (availability check koristi `unit_id`, ne `owner_id`)

### Rješenje

Umjesto da vjerujemo `ownerId` iz klijentskog zahtjeva, sada dohvaćamo pravi `owner_id` direktno iz property dokumenta u Firestore-u.

**Poslije ispravke:**
```typescript
// SECURITY FIX SF-001: Validate ownerId from property document
// Don't trust client-provided ownerId - fetch from Firestore
const propertyDoc = await db.collection('properties').doc(propertyId).get();

if (!propertyDoc.exists) {
  throw new HttpsError('not-found', 'Property not found');
}

const propertyData = propertyDoc.data();
const validatedOwnerId = propertyData?.owner_id;

if (!validatedOwnerId) {
  throw new HttpsError('failed-precondition', 'Property has no owner');
}

// Log if client sent different ownerId (potential attack attempt)
if (ownerId && ownerId !== validatedOwnerId) {
  logInfo('[AtomicBooking] SECURITY: Client ownerId mismatch - using validated owner', {
    clientOwnerId: ownerId?.substring(0, 8) + '...',
    validatedOwnerId: validatedOwnerId.substring(0, 8) + '...',
    propertyId,
  });
}
```

### Testiranje

1. ✅ Normalni booking flow - koristi se pravi owner_id iz property-ja
2. ✅ Maliciozni zahtjev s pogrešnim ownerId - ignorira se, koristi se pravi
3. ✅ Property bez owner_id - vraća grešku
4. ✅ Nepostojeći property - vraća grešku

### Moguće nuspojave

- **Dodatni Firestore read**: Sada imamo jedan dodatni read za property dokument. Međutim, ovaj read je već potreban kasnije u funkciji za email slanje, tako da možemo cache-irati rezultat.
- **Backward compatibility**: Klijenti koji šalju `ownerId` će i dalje raditi - parametar se jednostavno ignorira i koristi se validirani owner.

### Automatski popravljeni flow-ovi

Ova ispravka automatski popravlja i Stripe payment flow:

1. `atomicBooking.ts` → validira `ownerId` iz property dokumenta
2. `atomicBooking.ts` → vraća validirani `ownerId` u `bookingData` za Stripe
3. `stripePayment.ts` → koristi taj validirani `ownerId` za kreiranje placeholder-a
4. Stripe webhook → čita `owner_id` iz placeholder-a (koji je već validiran)

### Povezani bugovi

- Nema poznatih povezanih bugova

---

## SF-002: SSRF Prevention in iCal Sync

**Datum**: 2026-01-05  
**Prioritet**: Medium  
**Status**: ✅ Riješeno  
**Zahvaćeni fajlovi**: `functions/src/icalSync.ts`  
**Otkrio**: Google Sentinel (automated security scan)

### Problem

U `validateIcalUrl` funkciji, whitelist validacija za iCal URL-ove je bila **zakomentirana**. Server je samo logirao upozorenje ali je **dopuštao** bilo koji URL, što je omogućavalo SSRF (Server-Side Request Forgery) napade.

**Prije ispravke (linija ~81-84):**
```typescript
if (!isAllowed) {
  logWarn("[iCal Sync] URL domain not in whitelist", { hostname });
  // For now, just log warning but allow - can be tightened later
  // return { valid: false, error: `Domain ${hostname} is not in the allowed list.` };
}
```

**Što je SSRF?**
Napadač može natjerati server da šalje HTTP zahtjeve na:
- Interne servise (npr. `http://metadata.google.internal/` - može ukrasti GCP credentials)
- Localhost (npr. `http://localhost:8080/admin`)
- Privatne IP adrese (npr. `http://192.168.1.1/`)
- Napadačev server (za izviđanje ili krađu podataka)

**Primjer napada:**
```
Napadač postavlja iCal feed URL: https://attacker.com/steal?token=SECRET
Server šalje zahtjev na napadačev server, otkrivajući IP adresu i headers
```

### Rješenje

Omogućena whitelist validacija - sada se URL-ovi koji nisu na listi poznatih booking platformi **blokiraju**.

**Poslije ispravke:**
```typescript
// SECURITY FIX SF-002: Enable whitelist validation to prevent SSRF attacks
// Previously this was just logging a warning but allowing any domain
if (!isAllowed) {
  logWarn("[iCal Sync] SECURITY SF-002: URL domain not in whitelist - BLOCKED", { hostname });
  return { valid: false, error: `Domain ${hostname} is not in the allowed list. Contact support to add your calendar provider.` };
}
```

### Postojeća zaštita (zadržana)

Funkcija već ima blocklist za interne adrese:
```typescript
const blockedPatterns = [
  "localhost", "127.0.0.1", "0.0.0.0", "::1",
  "10.", "172.16.", "192.168.", "169.254.",
  "metadata.google.internal", ".internal", ".local",
];
```

### Dozvoljeni domeni (whitelist)

```typescript
const allowedDomains = [
  "ical.booking.com", "admin.booking.com",
  "airbnb.com", "www.airbnb.com",
  "calendar.google.com",
  "outlook.live.com", "outlook.office365.com",
  "p.calendar.yahoo.com",
  "export.calendar.yandex.com",
  "beds24.com", "www.beds24.com",
  "app.hospitable.com",
  "smoobu.com", "api.smoobu.com",
  "rentalsunited.com",
  "api.lodgify.com",
  "ownerrez.com", "api.ownerrez.com",
  "guesty.com", "open.guesty.com",
  "webcal.io", "icalendar.org",
];
```

### Testiranje

1. ✅ Booking.com iCal URL - prolazi validaciju
2. ✅ Airbnb iCal URL - prolazi validaciju
3. ✅ Google Calendar URL - prolazi validaciju
4. ✅ Nepoznati domen (npr. `attacker.com`) - BLOKIRAN
5. ✅ Interni URL (npr. `localhost`) - BLOKIRAN (postojeća zaštita)
6. ✅ Metadata URL (npr. `metadata.google.internal`) - BLOKIRAN (postojeća zaštita)

### Moguće nuspojave

- **Breaking change**: Korisnici koji koriste iCal providere koji nisu na whitelisti neće moći sinkronizirati kalendar
- **Rješenje**: Dodati novi provider na whitelist po potrebi (zahtijeva deploy)
- **Poruka korisniku**: "Contact support to add your calendar provider"

### Povezani bugovi

- Nema poznatih povezanih bugova

---

## SF-003: Revenue Chart maxValue Recalculation (ODBIJENO)

**Datum**: 2026-01-05  
**Prioritet**: Low  
**Status**: ❌ Odbijeno  
**Zahvaćeni fajlovi**: `lib/features/owner_dashboard/presentation/widgets/revenue_chart_widget.dart`  
**Predložio**: Google Bolt (automated optimization scan)

### Predložena promjena

Bolt je predložio pretvaranje `_BarChart` iz `StatelessWidget` u `StatefulWidget` kako bi se cache-irao `maxValue` izračun.

**Trenutni kod:**
```dart
class _BarChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final maxValue = data.map((d) => d.value).reduce(math.max);  // Računa se svaki build
    // ...
  }
}
```

**Predloženi kod:**
```dart
class _BarChart extends StatefulWidget { ... }

class _BarChartState extends State<_BarChart> {
  double _maxValue = 0;

  @override
  void initState() {
    super.initState();
    _maxValue = _computeMaxValue(widget.data);
  }

  @override
  void didUpdateWidget(covariant _BarChart oldWidget) {
    if (widget.data != oldWidget.data) {
      setState(() { _maxValue = _computeMaxValue(widget.data); });
    }
  }
}
```

### Razlog odbijanja

1. **Mikro-optimizacija**: `reduce(math.max)` na 7-12 elemenata je zanemarivo brz (O(n) gdje je n=7-12)
2. **Dodaje kompleksnost**: 45 novih linija koda za minimalnu dobit
3. **Potencijalni bug**: `widget.data != oldWidget.data` uspoređuje reference, ne sadržaj liste
   - Ako se lista mutira umjesto zamijeni, promjena se neće detektirati
   - Ispravna usporedba bi zahtijevala `listEquals()` što dodaje overhead
4. **Flutter već optimizira**: Rendering pipeline već minimizira nepotrebne rebuilds

### Zaključak

Ova "optimizacija" dodaje kompleksnost bez mjerljive dobiti i uvodi potencijalni bug. Flutter-ov StatelessWidget je dovoljan za ovaj use case.

---

## SF-004: IconButton Hover/Splash Feedback

**Datum**: 2026-01-05  
**Prioritet**: Low  
**Status**: ✅ Riješeno  
**Zahvaćeni fajlovi**: `lib/features/widget/presentation/screens/booking_details_screen.dart`  
**Predložio**: Google Labs Jules

### Problem

IconButton widgeti u header-u booking details ekrana (theme toggle i language switcher) nisu imali vizualni feedback na hover i click. Na desktop uređajima, ovo je činilo gumbe "mrtvim" - korisnik nije mogao vidjeti da su interaktivni dok ne klikne.

**Prije ispravke:**
```dart
IconButton(
  icon: Icon(Icons.language, color: colors.textPrimary, size: iconSize),
  onPressed: () => _showLanguageDialog(colors),
  tooltip: tr.tooltipChangeLanguage,
  // Nema hoverColor/splashColor - gumb djeluje neresponzivno
),
```

### Rješenje

Dodani `hoverColor` i `splashColor` parametri na oba IconButton widgeta koristeći postojeću boju iz theme sistema.

**Poslije ispravke:**
```dart
IconButton(
  icon: Icon(Icons.language, color: colors.textPrimary, size: iconSize),
  onPressed: () => _showLanguageDialog(colors),
  tooltip: tr.tooltipChangeLanguage,
  hoverColor: colors.backgroundSecondary,
  splashColor: colors.backgroundSecondary,
),
```

### Zahvaćeni gumbi

1. **Theme toggle button** (dark/light mode switch) - lijeva strana headera
2. **Language switcher button** - desna strana headera

### Testiranje

1. ✅ Hover na desktop - prikazuje se `backgroundSecondary` boja
2. ✅ Click/tap - prikazuje se splash efekt
3. ✅ Dark mode - boje se pravilno prilagođavaju temi
4. ✅ Light mode - boje se pravilno prilagođavaju temi
5. ✅ Mobile - splash efekt radi na tap

### Moguće nuspojave

- **Nema** - ovo je čisto vizualno poboljšanje bez utjecaja na funkcionalnost

### Accessibility poboljšanje

Ova promjena poboljšava UX za:
- Korisnike s mišem (hover feedback)
- Korisnike s touch uređajima (splash feedback)
- Korisnike koji koriste pointer uređaje (jasna indikacija interaktivnosti)

### Povezani bugovi

- Nema poznatih povezanih bugova

---

## SF-005: Phone Number Validation

**Datum**: 2026-01-05  
**Prioritet**: Medium  
**Status**: ✅ Riješeno  
**Zahvaćeni fajlovi**: `lib/features/widget/domain/use_cases/submit_booking_use_case.dart`  
**Otkrio**: Google Sentinel

### Problem

U `SubmitBookingUseCase`, nakon sanitizacije korisničkog unosa, `guestPhone` polje nije bilo validirano. Ako bi sanitizer vratio `null` za maliciozni ili nevažeći broj telefona, kod bi se vraćao na originalni, nesanitizirani broj telefona.

**Prije ispravke:**
```dart
guestPhone: sanitizedPhone ?? params.phoneWithCountryCode,
```

### Rješenje

Dodana validacija da `sanitizedPhone` nije null/empty nakon sanitizacije, jednako kao za `guestName` i `guestEmail`.

**Poslije ispravke:**
```dart
// SECURITY FIX SF-005: Validate phone number after sanitization
if (sanitizedPhone == null || sanitizedPhone.trim().isEmpty) {
  throw Exception(
    'Guest phone is required and cannot be empty. Please enter a valid phone number with country code.',
  );
}
// ...
guestPhone: sanitizedPhone, // SF-005: Validated above - guaranteed non-null
```

### Testiranje

1. ✅ Validan broj telefona - prolazi
2. ✅ Prazan broj - vraća grešku
3. ✅ Maliciozni input koji sanitizer odbaci - vraća grešku

### Moguće nuspojave

- Korisnici moraju unijeti validan broj telefona (već je bilo obavezno polje u UI-u)

---

## SF-006: Sequential Character Password Check

**Datum**: 2026-01-05  
**Prioritet**: Low  
**Status**: ✅ Riješeno  
**Zahvaćeni fajlovi**: `lib/core/utils/password_validator.dart`  
**Otkrio**: Google Sentinel

### Problem

Password validator je detektirao samo sekvencijalne **brojeve** (npr. "12345678"), ali ne i sekvencijalna **slova** (npr. "abcdefgh"). Ovo je omogućavalo slabe, dictionary-like lozinke.

**Prije ispravke:**
```dart
// Check for sequential numbers (12345678, 87654321)
if (_isSequentialNumbers(password)) {
  return 'Password cannot be sequential numbers (e.g., 12345678)';
}
```

### Rješenje

Funkcija `_isSequentialNumbers` preimenovana u `_isSequentialCharacters` i proširena da detektira i uzlazne i silazne sekvence slova i brojeva.

**Poslije ispravke:**
```dart
// SECURITY FIX SF-006: Check for sequential characters (numbers AND letters)
if (_isSequentialCharacters(password)) {
  return 'Password cannot contain sequential characters (e.g., "12345" or "abcde")';
}
```

### Testiranje

1. ✅ "12345678" - odbijeno
2. ✅ "abcdefgh" - odbijeno
3. ✅ "87654321" - odbijeno (silazno)
4. ✅ "hgfedcba" - odbijeno (silazno)
5. ✅ "a1b2c3d4" - prihvaćeno (nije sekvencijalno)

### Moguće nuspojave

- Korisnici s lozinkama koje sadrže 3+ uzastopna slova/broja će morati promijeniti lozinku

---

## SF-007: Remove Insecure Password Storage (CRITICAL)

**Datum**: 2026-01-05  
**Prioritet**: 🔴 Critical  
**Status**: ✅ Riješeno  
**Zahvaćeni fajlovi**: 
- `lib/core/services/secure_storage_service.dart`
- `lib/features/auth/models/saved_credentials.dart`
- `lib/features/auth/presentation/screens/enhanced_login_screen.dart`
- `lib/core/providers/enhanced_auth_provider.dart`

**Otkrio**: Google Sentinel

### Problem

"Remember Me" funkcionalnost je spremala korisničku lozinku u **plaintext** u SecureStorage. Iako je SecureStorage enkriptiran na uređaju, ovo je sigurnosni rizik jer:

1. Ako je uređaj kompromitiran, napadač može izvući lozinku
2. Lozinke se nikada ne bi trebale trajno spremati
3. Korisnik možda koristi istu lozinku na drugim servisima

**Prije ispravke:**
```dart
Future<void> saveCredentials(String email, String password) async {
  await _storage.write(key: _keyEmail, value: email);
  await _storage.write(key: _keyPassword, value: password);  // ❌ OPASNO!
}
```

### Rješenje

Potpuno uklonjena mogućnost spremanja lozinke. "Remember Me" sada sprema samo email adresu.

**Poslije ispravke:**
```dart
/// SECURITY FIX SF-007: Does NOT save the password.
Future<void> saveEmail(String email) async {
  await _storage.write(key: _keyEmail, value: email);
  // Password is NEVER stored
}
```

### Zahvaćene komponente

1. **SecureStorageService**: `saveCredentials()` → `saveEmail()`
2. **SavedCredentials model**: Uklonjen `password` field
3. **EnhancedLoginScreen**: Više ne popunjava password polje automatski
4. **EnhancedAuthProvider**: Poziva `saveEmail()` umjesto `saveCredentials()`

### Testiranje

1. ✅ Login s "Remember Me" - sprema samo email
2. ✅ Povratak na login screen - email je popunjen, password prazan
3. ✅ Logout - briše sve spremljene podatke
4. ✅ Legacy password cleanup - briše stare spremljene lozinke

### Moguće nuspojave

- Korisnici će morati ponovo unijeti lozinku pri svakom loginu (čak i s "Remember Me")
- Ovo je **namjerno** ponašanje za bolju sigurnost

---

## SF-008: Booking Notes Length Limit

**Datum**: 2026-01-05  
**Prioritet**: Low  
**Status**: ✅ Riješeno  
**Zahvaćeni fajlovi**: `lib/features/widget/domain/use_cases/submit_booking_use_case.dart`  
**Otkrio**: Google Sentinel

### Problem

`notes` polje u booking formi nije imalo ograničenje duljine. Napadač bi mogao poslati ekstremno dug string (npr. 10MB), što bi moglo:

1. Uzrokovati DoS (Denial of Service) na serveru
2. Povećati troškove Firestore storage-a
3. Usporiti učitavanje booking podataka

### Rješenje

Dodano ograničenje od 1000 karaktera za `notes` polje.

**Poslije ispravke:**
```dart
// SECURITY FIX SF-008: Limit notes length to prevent DoS and storage abuse
if (sanitizedNotes != null && sanitizedNotes.length > 1000) {
  throw Exception(
    'Notes cannot exceed 1000 characters. Please shorten your message.',
  );
}
```

### Testiranje

1. ✅ Notes < 1000 karaktera - prolazi
2. ✅ Notes = 1000 karaktera - prolazi
3. ✅ Notes > 1000 karaktera - vraća grešku
4. ✅ Prazan notes - prolazi (null)

### Moguće nuspojave

- Korisnici s vrlo dugim napomenama će morati skratiti tekst

---

## SF-009: Error Handling Info Leakage Prevention

**Datum**: 2026-01-05  
**Prioritet**: Medium  
**Status**: ✅ Riješeno  
**Zahvaćeni fajlovi**: `lib/features/widget/presentation/providers/widget_context_provider.dart`  
**Otkrio**: Google Sentinel

### Problem

Kada bi došlo do greške u `widgetContextProvider`, detaljna poruka greške (uključujući Firestore error kodove, TypeErrors, itd.) bi se proslijedila klijentu:

**Prije ispravke:**
```dart
} catch (e) {
  throw WidgetContextException('Failed to load widget context: $e');
  // ❌ Otkriva interne detalje: "Failed to load widget context: FirebaseException: [permission-denied]..."
}
```

Ovo bi moglo pomoći napadaču da razumije internu strukturu aplikacije.

### Rješenje

Detaljne greške se sada logiraju za debugging, ali klijentu se vraća generička poruka.

**Poslije ispravke:**
```dart
} catch (e, stackTrace) {
  // Log detailed error for debugging
  await LoggingService.logError(
    'widgetContextProvider: Failed to load context for $params',
    e,
    stackTrace,
  );

  // SECURITY: Throw generic, user-safe exception
  throw WidgetContextException(
    'Unable to load booking widget configuration. Please check the property and unit IDs.',
  );
}
```

### Testiranje

1. ✅ Validan propertyId/unitId - normalno učitavanje
2. ✅ Nevalidan propertyId - generička greška (ne otkriva detalje)
3. ✅ Firestore permission error - generička greška
4. ✅ TypeError - generička greška

### Moguće nuspojave

- Debugging u produkciji je teži (ali logovi su dostupni)

---

## SF-010: Year Calendar Race Condition Fix

**Datum**: 2026-01-05  
**Prioritet**: Medium  
**Status**: ✅ Riješeno  
**Zahvaćeni fajlovi**: `lib/features/widget/presentation/widgets/year_calendar_widget.dart`  
**Otkrio**: Google Sentinel

### Problem

Year calendar view je validirao dostupnost datuma koristeći samo **lokalno cache-irane podatke**. Ako su podaci bili zastarjeli (npr. drugi korisnik je upravo rezervirao), korisnik bi mogao odabrati već zauzete datume.

**Scenarij:**
1. Korisnik A otvori year calendar (podaci se cache-iraju)
2. Korisnik B rezervira 15-20. siječnja
3. Korisnik A odabere 15-20. siječnja (lokalni cache još uvijek pokazuje "available")
4. Booking bi propao tek na serveru, frustrirajući korisnika

Month calendar je već imao backend provjeru, ali year calendar nije.

### Rješenje

Dodana async backend provjera dostupnosti prije potvrde odabira datuma, identično kao u month calendar.

**Poslije ispravke:**
```dart
bool _isValidating = false; // Prevent concurrent validations

Future<void> _validateAndSetRange(DateTime start, DateTime end) async {
  if (_isValidating) return;
  setState(() => _isValidating = true);

  try {
    // Check availability using backend
    final isAvailable = await ref.read(
      checkDateAvailabilityProvider(
        unitId: widget.unitId,
        checkIn: start,
        checkOut: end,
      ).future,
    );

    if (!isAvailable) {
      // Reset selection and show error
      setState(() { _rangeStart = null; _rangeEnd = null; });
      SnackBarHelper.showError(...);
      return;
    }

    // Availability confirmed, set the range
    setState(() { ... });
    widget.onRangeSelected?.call(_rangeStart, _rangeEnd);
  } finally {
    if (mounted) setState(() => _isValidating = false);
  }
}
```

### Testiranje

1. ✅ Odabir dostupnih datuma - uspješno
2. ✅ Odabir zauzetih datuma (stale cache) - greška, selekcija resetirana
3. ✅ Concurrent validacije - blokirane (`_isValidating` guard)
4. ✅ Widget unmount tijekom validacije - nema crash-a

### Moguće nuspojave

- Mala latencija pri odabiru datuma (backend provjera)
- Bolje korisničko iskustvo (nema frustracije zbog propale rezervacije)

---

## SF-011: Ignore Service Account Key (CRITICAL)

**Datum**: 2026-01-05  
**Prioritet**: 🔴 Critical  
**Status**: ✅ Riješeno  
**Zahvaćeni fajlovi**: `functions/.gitignore`  
**Otkrio**: Google Sentinel

### Problem

`functions/.gitignore` nije imao entry za `service-account-key.json`. Lokalni script `add_test_prices.js` instruira developere da preuzmu ovaj fajl za testiranje, što stvara rizik da se slučajno commitaju **pune admin credentials** za Firebase projekt.

### Što je service-account-key.json?

Ovaj fajl sadrži:
- Private key za Firebase Admin SDK
- Puni pristup Firestore bazi podataka
- Puni pristup Firebase Authentication
- Puni pristup Firebase Storage
- Mogućnost brisanja cijelog projekta

**Ako se commituje, napadač može:**
- Čitati/brisati sve podatke u bazi
- Kreirati/brisati korisničke račune
- Pristupiti svim fajlovima u Storage-u
- Preuzeti potpunu kontrolu nad Firebase projektom

### Rješenje

Dodano `service-account-key.json` u `functions/.gitignore`:

```gitignore
# CRITICAL SECURITY SF-011: Ignore Firebase service account key.
# This file grants full admin access to the project.
# NEVER commit this file to the repository.
service-account-key.json
```

### Testiranje

1. ✅ Kreiran dummy `functions/service-account-key.json`
2. ✅ `git status --ignored` potvrđuje da je ignoriran
3. ✅ Obrisan dummy fajl

### Moguće nuspojave

- Nema - ovo samo sprječava slučajno commitanje osjetljivog fajla

### Dodatne preporuke

- Ako je `service-account-key.json` ikada bio commitovan, potrebno je:
  1. Rotirati ključ u Firebase Console
  2. Očistiti Git history (BFG Repo-Cleaner ili git filter-branch)
  3. Force push na sve brancheve

---

## SF-012: Secure Error Handling & Email Sanitization

**Datum**: 2026-01-05  
**Prioritet**: Medium  
**Status**: ✅ Riješeno  
**Zahvaćeni fajlovi**: 
- `lib/features/owner_dashboard/presentation/mixins/calendar_common_methods_mixin.dart`
- `lib/features/owner_dashboard/presentation/screens/change_password_screen.dart`
- `lib/features/owner_dashboard/presentation/widgets/send_email_dialog.dart`

**Otkrio**: Google Sentinel

### Problem

Tri sigurnosna problema:

1. **Calendar refresh** - Prikazivao tehničke detalje greške korisniku
2. **Change password** - Uključivao `e.message` u error poruku, otkrivajući interne detalje
3. **Send email dialog** - Nije sanitizirao HTML tagove u subject/message poljima

### Rješenje

#### 1. Calendar Refresh Error Handling

**Prije:**
```dart
ErrorDisplayUtils.showErrorSnackBar(context, e);
```

**Poslije:**
```dart
ErrorDisplayUtils.showErrorSnackBar(
  context,
  e,
  userMessage: 'Greška pri osvježavanju kalendara',
);
```

#### 2. Change Password Info Leakage

**Prije:**
```dart
message = '${l10n.passwordChangeError}: ${e.message}';
```

**Poslije:**
```dart
message = l10n.passwordChangeError;
```

#### 3. Send Email Input Sanitization

Dodana `_sanitizeInput()` funkcija:
```dart
String _sanitizeInput(String input) {
  return input.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ').trim();
}
```

Koristi se za sanitizaciju `subject` i `message` prije slanja:
```dart
final subject = _sanitizeInput(_subjectController.text);
final message = _sanitizeInput(_messageController.text);
```

### Testiranje

1. ✅ Calendar refresh error - prikazuje generičku poruku
2. ✅ Password change error - ne otkriva `e.message`
3. ✅ Email s HTML tagovima - tagovi su uklonjeni
4. ✅ Email s HTML entities - entities su uklonjeni

### Moguće nuspojave

- Korisnici neće vidjeti tehničke detalje grešaka (namjerno)
- HTML formatiranje u email porukama neće raditi (sigurnosna mjera)

---

## SF-013: Haptic Feedback on Password Toggle

**Datum**: 2026-01-05  
**Prioritet**: Low  
**Status**: ✅ Riješeno  
**Zahvaćeni fajlovi**: `lib/features/auth/presentation/screens/enhanced_login_screen.dart`  
**Predložio**: Google Palette

### Problem

Password visibility toggle button na login screenu nije imao taktilni feedback. Na mobilnim uređajima, korisnik nije dobivao fizičku potvrdu da je gumb pritisnut.

### Rješenje

Dodano `HapticFeedback.mediumImpact()` prije toggle akcije:

**Prije:**
```dart
onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
```

**Poslije:**
```dart
onPressed: () {
  HapticFeedback.mediumImpact();
  setState(() => _obscurePassword = !_obscurePassword);
},
```

### Testiranje

1. ✅ iOS - vibracija pri pritisku
2. ✅ Android - vibracija pri pritisku
3. ✅ Web - nema efekta (očekivano, web nema haptic)

### Moguće nuspojave

- Nema - ovo je čisto UX poboljšanje

### Accessibility

Poboljšava accessibility jer pruža dodatni non-visual feedback koji potvrđuje akciju korisnika.

---

## SF-014: Prevent PII Exposure in Booking Widget (HIGH)

**Datum**: 2026-01-05  
**Prioritet**: 🔴 High  
**Status**: ✅ Riješeno  
**Zahvaćeni fajlovi**: `lib/features/widget/data/repositories/firebase_booking_calendar_repository.dart`  
**Otkrio**: Google Sentinel

### Problem

Public booking widget calendar je dohvaćao **cijele** Firestore booking dokumente koristeći `BookingModel.fromJson()`. Ovo je izlagalo osjetljive PII (Personally Identifiable Information) podatke svim korisnicima widgeta:

- **Guest name** (ime gosta)
- **Guest email** (email gosta)  
- **Guest phone** (telefon gosta)
- **Notes** (napomene)

**Rizik:** Maliciozni korisnik bi mogao presresti mrežni promet prema public widgetu i prikupiti PII podatke drugih gostiju, što predstavlja ozbiljnu povredu privatnosti.

### Rješenje

Kreirana nova helper metoda `_mapDocumentToBooking()` koja ekstrahira **samo** polja potrebna za prikaz kalendara:

```dart
BookingModel? _mapDocumentToBooking(
  QueryDocumentSnapshot doc, {
  required String unitId,
}) {
  try {
    final data = doc.data() as Map<String, dynamic>;
    final statusString = data['status'] as String?;
    final status = BookingStatus.values.firstWhere(
      (e) => e.name == statusString,
      orElse: () => BookingStatus.confirmed,
    );

    // Extract ONLY non-PII fields needed for calendar display
    return BookingModel(
      id: doc.id,
      unitId: unitId,
      checkIn: (data['check_in'] as Timestamp).toDate(),
      checkOut: (data['check_out'] as Timestamp).toDate(),
      status: status,
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  } catch (e) {
    LoggingService.logError('Error parsing booking document ${doc.id}', e);
    return null;
  }
}
```

### Zahvaćena mjesta (4 stream-a):

1. `watchYearCalendarData()` - year view calendar
2. `watchCalendarData()` - month view calendar
3. `watchYearCalendarDataOptimized()` - optimized year view
4. `watchCalendarDataOptimized()` - optimized month view

### Testiranje

1. ✅ Calendar prikazuje booking datume ispravno
2. ✅ PII podaci (name, email, phone) NISU u network response-u
3. ✅ Status bookinga (pending/confirmed) se ispravno prikazuje
4. ✅ Turnover days (partialCheckIn/partialCheckOut) rade ispravno

### Moguće nuspojave

- Nema - calendar widget nikada nije trebao PII podatke za prikaz

### GDPR/Privacy implikacije

Ova ispravka je važna za usklađenost s GDPR-om jer sprječava neovlašteno izlaganje osobnih podataka gostiju trećim stranama.

---

## SF-015: DebouncedSearchField ValueNotifier Optimization

**Datum**: 2026-01-05  
**Prioritet**: Low  
**Status**: ✅ Riješeno  
**Zahvaćeni fajlovi**: `lib/shared/widgets/debounced_search_field.dart`  
**Predložio**: Google Bolt

### Problem

`DebouncedSearchField` i `CompactDebouncedSearchField` widgeti su koristili `setState()` za toggle vidljivosti clear buttona. Ovo je uzrokovalo rebuild cijelog widgeta na svaki keystroke, što može uzrokovati input lag na sporijim uređajima.

**Prije:**
```dart
bool _showClearButton = false;

void _onTextChanged() {
  setState(() {
    _showClearButton = _controller.text.isNotEmpty;
  });
}
```

### Rješenje

Zamjena `setState` s `ValueNotifier` + `ValueListenableBuilder` pattern:

```dart
late final ValueNotifier<bool> _showClearButtonNotifier;

void _onTextChanged() {
  _showClearButtonNotifier.value = _controller.text.isNotEmpty;
}

// U build():
suffixIcon: ValueListenableBuilder<bool>(
  valueListenable: _showClearButtonNotifier,
  builder: (context, showClear, child) {
    return showClear ? IconButton(...) : const SizedBox.shrink();
  },
),
```

### Zahvaćeni widgeti

1. `DebouncedSearchField` - standardno search polje
2. `CompactDebouncedSearchField` - kompaktno search polje za app bar

### Testiranje

1. ✅ Clear button se prikazuje kad ima teksta
2. ✅ Clear button se skriva kad je polje prazno
3. ✅ Debounce i dalje radi ispravno
4. ✅ Nema vidljivog input laga

### Performance poboljšanje

- Prije: Cijeli widget se rebuilda na svaki keystroke
- Poslije: Samo `ValueListenableBuilder` i clear button se rebuilda
- Rezultat: Manje CPU usage, glatkije tipkanje na sporijim uređajima

### Moguće nuspojave

- Nema - ovo je čista optimizacija bez promjene funkcionalnosti

---

## SF-016: AnimatedGradientFAB ValueNotifier Optimization

**Datum**: 2026-01-05  
**Prioritet**: Low  
**Status**: ✅ Riješeno  
**Zahvaćeni fajlovi**: `lib/features/owner_dashboard/presentation/screens/owner_timeline_calendar_screen.dart`  
**Predložio**: Google Bolt

### Problem

`_AnimatedGradientFAB` widget je koristio `setState()` za toggle hover i press stanja. Svaki hover ili press event je uzrokovao rebuild cijelog FAB widgeta, što je nepotrebno jer se mijenja samo vizualni izgled (scale, shadow, rotation).

**Prije:**
```dart
class _AnimatedGradientFABState extends State<_AnimatedGradientFAB> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      // ...
    );
  }
}
```

### Rješenje

Zamjena `setState` s `ValueNotifier` + `ValueListenableBuilder` pattern:

```dart
class _AnimatedGradientFABState extends State<_AnimatedGradientFAB> {
  late final ValueNotifier<bool> _isHoveredNotifier;
  late final ValueNotifier<bool> _isPressedNotifier;

  @override
  void initState() {
    super.initState();
    _isHoveredNotifier = ValueNotifier<bool>(false);
    _isPressedNotifier = ValueNotifier<bool>(false);
  }

  @override
  void dispose() {
    _isHoveredNotifier.dispose();
    _isPressedNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _isHoveredNotifier.value = true,
      onExit: (_) => _isHoveredNotifier.value = false,
      child: GestureDetector(
        // ...
        child: ValueListenableBuilder<bool>(
          valueListenable: _isHoveredNotifier,
          builder: (context, isHovered, _) {
            return ValueListenableBuilder<bool>(
              valueListenable: _isPressedNotifier,
              builder: (context, isPressed, _) {
                return AnimatedContainer(/* ... */);
              },
            );
          },
        ),
      ),
    );
  }
}
```

### Testiranje

1. ✅ Hover efekt - FAB se povećava na 1.08x
2. ✅ Press efekt - FAB se smanjuje na 0.92x
3. ✅ Shadow animacija - shadow se povećava na hover
4. ✅ Rotation animacija - ikona se rotira 45° na hover
5. ✅ Dispose - notifieri se pravilno čiste

### Performance poboljšanje

- Prije: Cijeli FAB widget se rebuilda na svaki hover/press event
- Poslije: Samo `AnimatedContainer` unutar `ValueListenableBuilder` se rebuilda
- Rezultat: Manje CPU usage, glatkije animacije

### Moguće nuspojave

- Nema - ovo je čista optimizacija bez promjene funkcionalnosti

---

## SF-017: Password Visibility Toggle Tooltips

**Datum**: 2026-01-05  
**Prioritet**: Low  
**Status**: ✅ Riješeno  
**Zahvaćeni fajlovi**: 
- `lib/features/owner_dashboard/presentation/screens/change_password_screen.dart`
- `lib/l10n/app_en.arb`
- `lib/l10n/app_hr.arb`

**Predložio**: Google Palette

### Problem

Password visibility toggle gumbi na Change Password ekranu nisu imali tooltip. Icon-only gumbi bez tooltipa su problematični za:

1. **Screen reader korisnike** - ne znaju što gumb radi
2. **Nove korisnike** - možda ne prepoznaju ikonu visibility_off/visibility
3. **Desktop korisnike** - nema hover feedback koji objašnjava funkciju

### Rješenje

Dodani `tooltip` parametri na sva 3 IconButton widgeta za password visibility toggle:

```dart
IconButton(
  tooltip: _obscureCurrentPassword
      ? l10n.showPassword
      : l10n.hidePassword,
  icon: Icon(_obscureCurrentPassword ? Icons.visibility_off : Icons.visibility),
  onPressed: () => setState(() => _obscureCurrentPassword = !_obscureCurrentPassword),
),
```

### Lokalizacija

Dodani novi stringovi:

| Ključ | EN | HR |
|-------|----|----|
| `showPassword` | Show password | Prikaži lozinku |
| `hidePassword` | Hide password | Sakrij lozinku |

### Zahvaćena polja

1. **Current Password** - toggle za prikaz trenutne lozinke
2. **New Password** - toggle za prikaz nove lozinke
3. **Confirm Password** - toggle za prikaz potvrde lozinke

### Testiranje

1. ✅ Hover na desktop - prikazuje tooltip "Show password" / "Hide password"
2. ✅ Screen reader - čita tooltip tekst
3. ✅ Lokalizacija EN - ispravni stringovi
4. ✅ Lokalizacija HR - ispravni stringovi
5. ✅ Toggle state - tooltip se mijenja ovisno o stanju (show/hide)

### Accessibility poboljšanje

Ova promjena poboljšava WCAG 2.1 usklađenost:
- **1.1.1 Non-text Content** - pruža tekstualnu alternativu za ikonu
- **2.4.4 Link Purpose** - jasno objašnjava funkciju gumba

### Moguće nuspojave

- Nema - ovo je čisto accessibility poboljšanje bez utjecaja na funkcionalnost

---

## SF-018: Common Password Blacklist

**Datum**: 2026-01-06  
**Prioritet**: Medium  
**Status**: ✅ Riješeno  
**Zahvaćeni fajlovi**: `lib/core/utils/password_validator.dart`  
**Predložio**: Google Jules (branch: `enhance-password-validation-2867371911688008985`)

### Problem

Password validator nije provjeravao da li je lozinka na listi najčešćih lozinki. Korisnici su mogli koristiti lozinke poput "Password123!" koje tehnički zadovoljavaju sve zahtjeve (uppercase, lowercase, broj, special char) ali su izuzetno slabe jer su na svim dictionary attack listama.

### Rješenje

Dodana `_commonPasswords` Set konstanta s 15 najčešćih lozinki i provjera u dvije metode:

**1. Blacklist konstanta:**
```dart
/// SECURITY: Common passwords blacklist
/// These passwords are rejected regardless of complexity requirements
static const Set<String> _commonPasswords = {
  'password',
  'password1',
  'password123',
  'qwerty123',
  'letmein',
  'welcome1',
  'admin123',
  'iloveyou',
  'sunshine',
  'princess',
  'football',
  'baseball',
  'trustno1',
  'dragon12',
  'master12',
};
```

**2. Provjera u `validate()` metodi:**
```dart
// SECURITY: Check against common passwords blacklist
if (_commonPasswords.contains(password.toLowerCase())) {
  return PasswordValidationResult.invalid(
    'This password is too common. Please choose a stronger password.',
    missing: ['Choose a less common password'],
  );
}
```

**3. Provjera u `_calculateStrength()` metodi:**
```dart
// SECURITY: Common passwords are always weak
if (_commonPasswords.contains(password.toLowerCase())) {
  return PasswordStrength.weak;
}
```

### Testiranje

1. ✅ "password" - odbijeno (common password)
2. ✅ "Password123!" - odbijeno (common password, case-insensitive)
3. ✅ "qwerty123" - odbijeno (common password)
4. ✅ "MyUn1queP@ss!" - prihvaćeno (nije na listi)
5. ✅ Strength calculation - common passwords vraćaju `weak`

### Moguće nuspojave

- Korisnici koji koriste česte lozinke će morati odabrati drugu lozinku
- Ovo je **namjerno** ponašanje za bolju sigurnost

### Zašto samo 15 lozinki?

Veće liste (npr. 10,000 lozinki) bi:
1. Povećale veličinu aplikacije
2. Usporile validaciju
3. Bile overkill za client-side provjeru

Server-side (Firebase Auth) već ima robustniju provjeru. Ova lista pokriva najčešće slučajeve.

---

## Template za buduće ispravke

```markdown
## SF-XXX: [Naziv problema]

**Datum**: YYYY-MM-DD  
**Prioritet**: Low/Medium/High/Critical  
**Status**: 🔄 U tijeku / ✅ Riješeno / ❌ Odbačeno  
**Zahvaćeni fajlovi**: `path/to/file.ts`

### Problem

[Opis problema]

### Rješenje

[Opis rješenja s code snippetima]

### Testiranje

[Lista testova]

### Moguće nuspojave

[Lista mogućih nuspojava]

### Povezani bugovi

[Lista povezanih bugova ili "Nema poznatih povezanih bugova"]
```


---

## ODBIJENI PRIJEDLOZI (Jules Audit)

Sljedeći prijedlozi iz Jules AI audita su analizirani i odbijeni zbog visokog rizika ili nepotrebnosti:

### ❌ Uklanjanje email iz booking URL-a

**Branch:** `fix/auth-error-handling-9695836915948502280`  
**Razlog odbijanja:** Email u URL-u služi kao dodatni faktor validacije. Uklanjanje bi smanjilo sigurnost - samo token bi štitio pristup booking detaljima. Potrebna dublja analiza backend validacije prije implementacije.

### ❌ Rate limiting za password reset (Cloud Function)

**Branch:** `fix/auth-error-handling-9695836915948502280`  
**Razlog odbijanja:** Firebase `sendPasswordResetEmail` već ima built-in rate limiting. Dodatni IP-based limit može blokirati legitimne korisnike na shared IP adresama (korporativne mreže, VPN).

### ❌ Rate limiting za resend booking email

**Branch:** `fix/auth-error-handling-9695836915948502280`  
**Razlog odbijanja:** Limit od 10 emailova/sat je previše restriktivan. Owner s 50 bookinga ne može poslati reminder svima. Potrebna fleksibilnija implementacija.

### ❌ Generičke auth error poruke

**Branch:** `fix/auth-error-handling-9695836915948502280`  
**Razlog odbijanja:** Zamjena specifičnih poruka ("Wrong password", "Email not found") sa generičkom "An error occurred" drastično pogoršava UX. Korisnici neće znati što je pošlo po zlu. Firebase Auth već štiti od user enumeration vraćajući iste poruke za nepostojeće emailove.

### ❌ Access token iz Firestore umjesto Stripe metadata

**Branch:** `fix/auth-error-handling-9695836915948502280`  
**Razlog odbijanja:** Breaking change. Postojeći bookings nemaju `access_token` polje u placeholder dokumentu. Webhook bi failao za sve in-flight transakcije.

### ❌ Idempotency key za Stripe checkout

**Branch:** `fix/auth-error-handling-9695836915948502280`  
**Razlog odbijanja:** Potrebna analiza kako se `placeholderBookingId` generira. Ako se generira novi ID na svakom retry-u, idempotency key je beskoristan.



### ❌ URL validacija za Stripe Connect (Open Redirect)

**Branch:** `sentinel-open-redirect-fix-4599161851353466478`  
**Razlog odbijanja:** Analizirano i utvrđeno da rizik nije značajan:

1. **Napadač može samo sebe preusmjeriti** - returnUrl se koristi za redirect nakon Stripe onboarding-a, ali napadač mora biti autentificiran i može samo svoj account preusmjeriti
2. **Stripe ne šalje osjetljive podatke** - return URL ne sadrži tokene ili credentials
3. **Već imamo validaciju za payment flow** - `stripePayment.ts` već ima `isAllowedReturnUrl()` za kritičniji payment checkout flow
4. **Rizik od bug-a** - ako validacija nije savršena, legitimni korisnici neće moći završiti Stripe Connect onboarding

**Status:** Nije potrebno implementirati.

### ❌ Sentry DSN iz environment varijable

**Branch:** `sentinel-open-redirect-fix-4599161851353466478`  
**Razlog odbijanja:** Breaking change. Zahtijeva dodatnu konfiguraciju (`.env` fajl ili Firebase environment config). Ako `SENTRY_DSN` nije postavljen, error tracking prestaje raditi bez upozorenja.

### ❌ Owner booking kroz Cloud Function

**Branch:** `sentinel-open-redirect-fix-4599161851353466478`  
**Razlog odbijanja:** `BookingService.createBooking()` je dizajniran za guest bookings (payment, approval flow). Owner bookings imaju drugačiji flow - direktan Firestore write je ispravan jer owner ima puni pristup svojim podacima. Potrebna bi bila posebna Cloud Function za owner bookings.



### ❌ Storage IDOR Fix (Ownership Validation)

**Branch:** `sentinel/fix-storage-idor-6126059184660913074`  
**Razlog odbijanja:** Promjena je **beskorisna** jer path `properties/{propertyId}/` se NE KORISTI u aplikaciji.

**Analiza:**
- Jules je predložio dodavanje ownership validacije za `properties/{propertyId}/` path
- ALI: Aplikacija uploaduje slike u `users/{userId}/properties/{propertyId}/` path
- Taj path je VEĆ ZAŠTIĆEN pravilom: `request.auth.uid == userId`
- Dakle, IDOR ranjivost NE POSTOJI - korisnik može pisati samo u svoj folder

**Stvarni storage paths u aplikaciji:**
- `users/$userId/profile/` - profile slike
- `users/$userId/properties/$propertyId/` - property slike  
- `users/$userId/properties/$propertyId/units/$unitId/` - unit slike
- `ical-exports/{propertyId}/{unitId}/` - iCal exports

**Status:** Nije potrebno implementirati. Sigurnost je već osigurana kroz `users/{userId}/` path strukturu.



### ✅ Lokalizacija "Retry" i "Close" gumba (Ručno implementirano)

**Branch:** `feat/UX-003-calendar-improvements-9632538979079219527`  
**Status:** Ručno implementirano od strane korisnika  
**Promjena:** Zamjena hardcoded "Pokušaj ponovo" i "Zatvori" stringova sa lokaliziranim verzijama u `error_display_utils.dart`

**Ostale promjene iz brancha odbijene** jer brišu naše sigurnosne ispravke (password blacklist, IP rate limiting).



### ❌ Responsive Navigation UX Improvements

**Branch:** `feat/responsive-navigation-16940434846776266174`  
**Status:** Sve promjene preskočene

**Razlozi odbijanja:**

1. **ColorUtils** - Duplikat postojeće `_getContrastTextColor()` funkcije u `timeline_split_day_cell.dart`
2. **Clear button na input poljima** - Tooltip "Očisti" nije lokaliziran, može interferirati sa password visibility toggle
3. **Empty state s filterima** - Nedostaju lokalizacijski stringovi (`ownerBookingsNoBookingsWithFilters`, `ownerBookingsNoBookingsWithFiltersDescription`, `ownerBookingsClearAllFilters`)
4. **Shimmer animacije** - Čisto vizualna promjena, nije kritično
5. **Branded loader refaktoring** - Nepotrebni refaktoring funkcionalne animacije

**Napomena:** Kao i svi Jules branchevi, ovaj također briše naše sigurnosne ispravke (password blacklist, IP rate limiting).



### ✅ UX-019: Accessibility Improvements (Palette)

**Branch:** `palette-auth-ux-improvements-8533954737293328923`  
**Status:** Djelomično implementirano

**Implementirano:**
1. **Tooltip na password visibility toggle** (login + register) - koristi postojeće `showPassword`/`hidePassword` stringove
2. **Haptic feedback na register screen** - usklađeno s login screenom (SF-013)
3. **Semantic label za language switcher** - poboljšava accessibility za screen readere

**Odbijeno:**
- **Disable auth buttons kad forma nije validna** - loša implementacija, provjerava samo da polja nisu prazna (`isNotEmpty`), ne da su validna
- **Unsaved changes warning** - dobra ideja ali zahtijeva puno boilerplate koda

**Zahvaćeni fajlovi:**
- `lib/features/auth/presentation/screens/enhanced_login_screen.dart`
- `lib/features/auth/presentation/screens/enhanced_register_screen.dart`
- `lib/features/widget/presentation/widgets/calendar/calendar_combined_header_widget.dart`
- `lib/features/widget/presentation/l10n/widget_translations.dart`



### ❌ Rate Limiting za Password Reset

**Branch:** `feat/rate-limiting-auth-12758559440638463678`  
**Status:** Odbijeno

**Predložene promjene:**
1. IP-based rate limiting za login - **VEĆ IMPLEMENTIRANO** u našem kodu
2. Email-based rate limiting za password reset - **ODBIJENO**

**Razlozi odbijanja rate limiting-a za password reset:**

1. **Firebase već ima built-in rate limiting** - `sendPasswordResetEmail` automatski ograničava broj zahtjeva po email adresi
2. **Loš UX** - Jules-ova implementacija prikazuje "Email sent" poruku čak i kad reset NIJE uspio:
   ```dart
   } catch (e) {
     // SECURITY: Show a generic message to prevent user enumeration.
     // This is the same message shown on success.
     setState(() {
       _emailSent = true;  // ❌ LOŠE - korisnik misli da je email poslan
       _isLoading = false;
     });
   }
   ```
3. **Korisnik ne zna da je nešto pošlo po zlu** - ako je greška (npr. network error), korisnik će čekati email koji nikad neće doći
4. **Naš kod već ima ispravnu implementaciju** - prikazujemo grešku ako nešto pođe po zlu, a Firebase već štiti od user enumeration vraćajući success za nepostojeće emailove

**Naš trenutni kod (ispravan):**
```dart
try {
  await ref.read(enhancedAuthProvider.notifier).resetPassword(email);
  // SECURITY: Firebase sendPasswordResetEmail already returns success
  // regardless of whether email exists (prevents user enumeration)
  setState(() => _emailSent = true);
} catch (e) {
  ErrorDisplayUtils.showErrorSnackBar(context, e);  // ✅ Prikazuje grešku
}
```



---

## Sažetak Jules AI Audit Brancheva

**Datum analize:** 2026-01-06

### Analizirani branchevi:

| Branch | Status | Implementirano |
|--------|--------|----------------|
| `fix/auth-error-handling-9695836915948502280` | ❌ Odbijeno | Ništa |
| `sentinel-open-redirect-fix-4599161851353466478` | ❌ Odbijeno | Ništa |
| `sentinel/fix-storage-idor-6126059184660913074` | ❌ Odbijeno | Ništa (path se ne koristi) |
| `feat/UX-003-calendar-improvements-9632538979079219527` | ✅ Djelomično | Lokalizacija "retry"/"close" (ručno) |
| `feat/responsive-navigation-16940434846776266174` | ❌ Odbijeno | Ništa |
| `feat/rate-limiting-auth-12758559440638463678` | ❌ Odbijeno | IP rate limiting već implementiran |
| `enhance-password-validation-2867371911688008985` | ✅ Implementirano | SF-018 Password blacklist |
| `bolt-memoize-chart-calculation-14900076675884265651` | ⏭️ Preskočeno | Stari dev branch, nije audit |
| `palette-auth-ux-improvements-8533954737293328923` | ✅ Djelomično | UX-019 Tooltips + Semantic labels |

### Ključni zaključci:

1. **SVI Jules branchevi brišu naše sigurnosne ispravke** - nikad ne merge-ati cijeli branch
2. **Firebase ima built-in zaštite** - rate limiting za auth, user enumeration protection
3. **Većina prijedloga je nepotrebna ili rizična** - bolje preskočiti nego riskirati bug
4. **Jedina korisna promjena:** SF-018 Password blacklist (cherry-picked)

### Implementirane sigurnosne ispravke (SF-001 do SF-018):

- SF-001: Owner ID Validation ✅
- SF-002: SSRF Prevention ✅
- SF-003: Revenue Chart (ODBIJENO)
- SF-004: IconButton Feedback ✅
- SF-005: Phone Validation ✅
- SF-006: Sequential Characters ✅
- SF-007: Remove Insecure Password Storage ✅
- SF-008: Booking Notes Limit ✅
- SF-009: Error Info Leakage ✅
- SF-010: Year Calendar Race Condition ✅
- SF-011: Ignore Service Account Key ✅
- SF-012: Secure Error Handling ✅
- SF-013: Haptic Feedback ✅
- SF-014: Prevent PII Exposure ✅
- SF-015: DebouncedSearchField Optimization ✅
- SF-016: AnimatedGradientFAB Optimization ✅
- SF-017: Password Visibility Tooltips ✅
- SF-018: Common Password Blacklist ✅


---

## NERIJEŠENI BUGOVI / OPTIMIZACIJE (Za buduću implementaciju)

### 🔄 PERF-001: ValueNotifier optimizacija za Timeline Calendar zoom

**Prioritet:** Medium (Performance)  
**Status:** ⏸️ Odgođeno  
**Zahvaćeni fajl:** `lib/features/owner_dashboard/presentation/widgets/timeline_calendar_widget.dart`  
**Predložio:** Google Jules (PERF-001 task)

**Problem:**
Timeline calendar koristi `setState()` za zoom state (`_zoomScale`). Svaki pinch-to-zoom event rebuilda cijeli widget (kompleksan timeline s mnogo ćelija).

**Predloženo rješenje:**
Zamijeniti:
```dart
double _zoomScale = kTimelineDefaultZoomScale;
```

Sa:
```dart
late final ValueNotifier<double> _zoomScaleNotifier;
```

Plus:
- `initState()` za kreiranje notifiera
- `dispose()` za čišćenje
- `ValueListenableBuilder` oko dijelova koji ovise o zoom-u
- Proslijediti `zoomScale` kao parametar umjesto čitanja iz state-a

**Benefit:**
- Fluidnije zumiranje
- Samo dijelovi koji ovise o zoom-u se rebuilda-ju
- Timeline grid (najskuplji dio) ostaje netaknut

**Razlog odgode:**
- Kompleksna promjena (mnogo mjesta koristi `_zoomScale`)
- Treba detaljno testiranje zoom funkcionalnosti
- Timeline calendar radi, ovo je optimizacija

---

### 🔄 OPT-001: ValueNotifier optimizacija za Month Calendar hover

**Prioritet:** Low (Performance)  
**Status:** ⏸️ Odgođeno  
**Zahvaćeni fajl:** `lib/features/widget/presentation/widgets/month_calendar_widget.dart`  
**Predložio:** Google Jules (Palette branch)

**Problem:**
Month calendar koristi `setState()` za hover state (`_hoveredDate`, `_mousePosition`). Svaki hover event rebuilda cijeli widget (~35 ćelija).

**Predloženo rješenje:**
Zamijeniti:
```dart
DateTime? _hoveredDate;
Offset _mousePosition = Offset.zero;
```

Sa:
```dart
late final ValueNotifier<DateTime?> _hoveredDateNotifier;
late final ValueNotifier<Offset> _mousePositionNotifier;
```

Plus `initState()` i `dispose()` za lifecycle, i `ValueListenableBuilder` umjesto direktnog čitanja.

**Razlog odgode:**
- Mikro-optimizacija - calendar nije performance bottleneck
- Dodaje kompleksnost koda
- Rizik od bug-a u tooltip prikazu
- Treba detaljno testiranje

---

### 🔄 OPT-002: ValueNotifier optimizacija za Year Calendar hover

**Prioritet:** Low-Medium (Performance)  
**Status:** ⏸️ Odgođeno  
**Zahvaćeni fajl:** `lib/features/widget/presentation/widgets/year_calendar_widget.dart`  
**Predložio:** Google Jules (Palette branch)

**Problem:**
Year calendar koristi `setState()` za hover state. Svaki hover event rebuilda cijeli widget (**372 ćelija** - 31 × 12).

**Predloženo rješenje:**
Isto kao OPT-001 - zamijeniti state varijable s `ValueNotifier` + `ValueListenableBuilder`.

**Razlog odgode:**
- Ova optimizacija ima VIŠE smisla za year calendar (372 vs 35 ćelija)
- Ali i dalje dodaje kompleksnost
- Rizik od bug-a u tooltip prikazu
- Treba detaljno testiranje

**Napomena:** Ako se odluči implementirati, implementirati OBA kalendara zajedno za konzistentnost.

---

### 🔄 OPT-003: autoDispose za provider caching

**Prioritet:** Low  
**Status:** ⏸️ Odbijeno  
**Zahvaćeni fajlovi:** 
- `calendar_drag_drop_provider.dart`
- `ical_feeds_provider.dart`
- `multi_select_provider.dart`

**Predložio:** Google Jules

**Problem:**
Jules predlaže dodavanje `.autoDispose` na razne providere za automatsko čišćenje memorije.

**Razlog odbijanja:**
- `dragDropProvider` - može pokvariti Undo funkcionalnost
- `icalFeedsStreamProvider` - uzrokuje nepotrebne Firestore reconnections
- `multiSelectProvider` - već imamo ručno čišćenje statea

**Iznimka implementirana:**
- `bookingReferenceProvider` i `lookupEmailProvider` - ✅ IMPLEMENTIRANO (commit `28e7c76`)
- Ovi provideri drže osjetljive podatke (email) i trebaju se očistiti kad korisnik napusti ekran

---

### 🔄 OPT-004: IP Geolocation caching

**Prioritet:** Low  
**Status:** ⏸️ Odbijeno  
**Zahvaćeni fajl:** `lib/core/services/ip_geolocation_service.dart`  
**Predložio:** Google Jules

**Problem:**
Jules predlaže dodavanje 24h in-memory cache za geolokaciju.

**Razlog odbijanja:**
- In-memory cache se briše kad se app restarta
- Geolokacija se koristi samo pri loginu (rijetko)
- IP adresa se može promijeniti (WiFi → mobilni)
- Minimalni benefit za dodanu kompleksnost

---

## 🐛 Neriješeni bugovi (Jules audit)

Ovi bugovi su identificirani tijekom Jules AI audita, ali nisu implementirani jer zahtijevaju dodatnu analizu ili nose rizik od breaking changes.

---

### 🐛 BUG-001: iCal Feeds Provider - nedostaje autoDispose

**Prioritet:** Low  
**Status:** ❌ Neriješeno  
**Zahvaćeni fajl:** `lib/features/ical/presentation/providers/ical_feeds_provider.dart`  
**Predložio:** Google Jules

**Problem:**
`icalFeedsStreamProvider` nema `.autoDispose` modifier. Kad korisnik napusti iCal ekran, stream ostaje aktivan i troši resurse.

**Predloženo rješenje:**
```dart
final icalFeedsStreamProvider = StreamProvider.autoDispose<List<IcalFeed>>((ref) {
  // ...
});
```

**Razlog odgode:**
- Može uzrokovati nepotrebne Firestore reconnections
- Stream se ionako zatvara kad se provider više ne koristi
- Potrebno testirati utjecaj na UX (loading state pri povratku na ekran)

---

### 🐛 BUG-002: IP Geolocation Service - nedostaje in-memory cache

**Prioritet:** Low  
**Status:** ❌ Neriješeno  
**Zahvaćeni fajl:** `lib/core/services/ip_geolocation_service.dart`  
**Predložio:** Google Jules

**Problem:**
`IpGeolocationService` nema in-memory cache. Svaki poziv `getGeolocation()` šalje HTTP request prema vanjskim API-jima, čak i za isti IP.

**Predloženo rješenje:**
```dart
final Map<String, _CacheEntry> _cache = {};
static const Duration _cacheDuration = Duration(hours: 24);

Future<GeoLocationResult?> getGeolocation(String? ipAddress) async {
  final cacheKey = ipAddress ?? 'current';
  final cached = _cache[cacheKey];
  if (cached != null && !cached.isExpired) {
    return cached.result;
  }
  // ... fetch from API
}
```

**Razlog odgode:**
- In-memory cache se briše kad se app restarta
- Geolokacija se koristi samo pri loginu (rijetko)
- IP adresa se može promijeniti (WiFi → mobilni)
- Minimalni benefit za dodanu kompleksnost
- Vanjski API-ji već imaju rate limiting

---

### 🐛 BUG-003: iCal Sync - sekvencijalno vs paralelno procesiranje

**Prioritet:** Low  
**Status:** ❌ Neriješeno  
**Zahvaćeni fajl:** `functions/src/icalSync.ts`  
**Predložio:** Google Jules

**Problem:**
`scheduledIcalSync` procesira feedove sekvencijalno (jedan po jedan) s 1s delay između svakog. Jules predlaže paralelno procesiranje do 5 feedova istovremeno.

**Predloženo rješenje:**
```typescript
const CONCURRENCY_LIMIT = 5;
for (let i = 0; i < feedsToProcess.length; i += CONCURRENCY_LIMIT) {
  const batch = feedsToProcess.slice(i, i + CONCURRENCY_LIMIT);
  const results = await Promise.allSettled(batch.map(...));
}
```

**Razlog odgode:**
- Može preopteretiti eksterne API-je (Airbnb, Booking.com rate limiting)
- Scheduled sync ima 9 min timeout - dovoljno za stotine feedova sekvencijalno
- Naš 1s delay je namjeran da budemo "nice" prema OTA API-jima
- Kompleksniji error handling kod paralelnog procesiranja

---

### 🐛 BUG-004: Owner Bookings Repository - print umjesto LoggingService

**Prioritet:** Low  
**Status:** ❌ Neriješeno  
**Zahvaćeni fajl:** `lib/features/owner_dashboard/data/firebase/firebase_owner_bookings_repository.dart`  
**Predložio:** Google Jules

**Problem:**
U `getOwnerBookings()` metodi koristi se `print()` za logiranje grešaka umjesto centraliziranog `LoggingService`.

**Trenutni kod:**
```dart
} catch (e) {
  // ignore: avoid_print
  print('WARNING: Failed to parse booking ${doc.id}: $e');
}
```

**Predloženo rješenje:**
```dart
} catch (e) {
  LoggingService.logWarning('Failed to parse booking ${doc.id}: $e');
}
```

**Razlog odgode:**
- Mikro-promjena u 1500+ linija fajlu
- Rizik od merge konflikta nije vrijedan benefita
- `print` radi u development modu, a u produkciji se ionako ne vidi
- Može se popraviti kad bude veći refactor tog fajla

---

### 🐛 BUG-005: Dashboard Overview - deferred loading za graphic library

**Prioritet:** Low  
**Status:** ❌ Neriješeno  
**Zahvaćeni fajl:** `lib/features/owner_dashboard/presentation/screens/dashboard_overview_tab.dart`  
**Predložio:** Google Jules

**Problem:**
`graphic` library se učitava sinkrono pri startu aplikacije, što povećava initial bundle size na webu.

**Trenutni kod:**
```dart
import 'package:graphic/graphic.dart';
```

**Predloženo rješenje:**
```dart
import 'package:graphic/graphic.dart' deferred as graphic;

// U build metodi:
FutureBuilder(
  future: graphic.loadLibrary(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.done) {
      return graphic.Chart(...);
    }
    return SkeletonLoader(...);
  },
)
```

**Razlog odgode:**
- Kompleksna promjena - treba zamijeniti SVE reference na graphic klase
- Može uzrokovati UX probleme (loading flash pri prvom prikazu)
- Benefit je samo za web (mobile ne koristi deferred loading)
- Rizik od regresije u chart renderingu

---

### 🐛 BUG-006: QR Code Payment - deferred loading za qr_flutter library

**Prioritet:** Low  
**Status:** ❌ Neriješeno  
**Zahvaćeni fajl:** `lib/features/widget/presentation/widgets/bank_transfer/qr_code_payment_section.dart`  
**Predložio:** Google Jules

**Problem:**
`qr_flutter` library se učitava sinkrono pri startu aplikacije, što povećava initial bundle size na webu.

**Trenutni kod:**
```dart
import 'package:qr_flutter/qr_flutter.dart';

// Direktno korištenje:
QrImageView(data: epcData, size: 200.0, ...)
```

**Predloženo rješenje:**
```dart
import 'package:qr_flutter/qr_flutter.dart' deferred as qr;

// U build metodi:
FutureBuilder(
  future: qr.loadLibrary(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.done) {
      return qr.QrImageView(data: epcData, size: 200.0, ...);
    }
    return CircularProgressIndicator();
  },
)
```

**Razlog odgode:**
- Kompleksna promjena - treba dodati FutureBuilder wrapper
- Može uzrokovati UX probleme (loading spinner pri prvom prikazu QR koda)
- Benefit je samo za web (mobile ne koristi deferred loading)
- QR kod se prikazuje samo na bank transfer payment screenu (rijetko korišteno)


---

### 🐛 BUG-007: FirebaseBookingRepository - query limits i optimizacije

**Prioritet:** Medium  
**Status:** ❌ Neriješeno  
**Zahvaćeni fajl:** `lib/shared/repositories/firebase/firebase_booking_repository.dart`  
**Predložio:** Google Jules

**Problem:**
Više metoda u `FirebaseBookingRepository` nema `.limit()` ili optimalne Firestore filtere, što može uzrokovati performance probleme s rastom baze.

**Predložene promjene:**

1. **`fetchBookingById`** - ukloniti full scan fallback:
```dart
// TRENUTNO: Skenira SVE bookinge ako unitId nije proslijeđen
final snapshot = await _firestore.collectionGroup('bookings').get();
for (final doc in snapshot.docs) { if (doc.id == id) ... }

// JULES: Vraća null umjesto full scan
if (unitId == null) {
  return null; // Callers must provide unitId
}
```

2. **`fetchUnitBookings`** - dodati limit:
```dart
.orderBy('created_at', descending: true)
.limit(1000)
```

3. **`fetchUserBookings`** - dodati limit:
```dart
.orderBy('created_at', descending: true)
.limit(100)
```

4. **`fetchPropertyBookings`** - dodati limit:
```dart
.orderBy('created_at', descending: true)
.limit(1000)
```

5. **`getOverlappingBookings`** - dodati Firestore filter:
```dart
// TRENUTNO: Dohvaća sve bookinge za unit, filtrira u memoriji
// JULES: Dodaje check_in filter na Firestore nivou
.where('check_in', isLessThan: checkOut)
```

6. **`getCurrentBookings`** - optimizirati query:
```dart
// TRENUTNO: Dohvaća SVE user bookinge, filtrira u memoriji
// JULES: Dodaje check_out filter i limit
.where('check_out', isGreaterThan: now)
.limit(50)
```

**Razlog odgode:**
- Promjene mijenjaju ponašanje metoda (npr. `fetchBookingById` više ne radi bez `unitId`)
- Potrebno provjeriti sve pozive tih metoda u aplikaciji
- Limiti mogu "odrezati" podatke ako ih ima više od limita
- Zahtijeva dodavanje novih Firestore indeksa
- Srednji rizik od regresije - bolje testirati temeljito prije implementacije


---

## 🚀 BUDUĆE FUNKCIONALNOSTI (Za razmatranje)

### 💡 FEAT-001: Stripe Refund Webhook Handler

**Prioritet:** Low  
**Status:** ⏸️ Odgođeno (svjesna odluka)  
**Zahvaćeni fajl:** `functions/src/stripePayment.ts`  
**Predložio:** Google Jules (branch: `fix-refund-logic-12134180205821183120`)

**Opis:**
Webhook handler za Stripe `charge.refunded` event koji bi automatski ažurirao booking status kada Owner izvrši refund putem Stripe Dashboard-a.

**Predložena funkcionalnost:**
- Handler za `charge.refunded` event
- Automatsko ažuriranje `payment_status` na `refunded` ili `partially_refunded`
- Automatsko otkazivanje bookinga pri full refund
- Email i in-app notifikacija Owner-u i Guest-u

**Razlog odgode:**
Trenutni flow je **namjerno manualan**:
1. Owner ručno radi refund u Stripe Dashboard
2. Owner ručno otkazuje booking u aplikaciji
3. Owner ima punu kontrolu nad procesom

**Zašto NE implementirati automatizaciju:**
- Owner želi kontrolu - ne želi da sistem automatski otkazuje bookinge
- Refund ne znači uvijek otkazivanje (npr. partial refund za popust)
- Manualni proces je jednostavniji i transparentniji
- Manje koda = manje bug-ova

**Kada razmotriti implementaciju:**
- Ako Owner-i počnu tražiti automatizaciju
- Ako se pojave problemi sa sinkronizacijom Stripe ↔ aplikacija
- Ako se uvede self-service refund za goste

**Branch za referencu:** `fix-refund-logic-12134180205821183120` (može se obrisati)



---

### 🐛 BUG-008: Calendar Date Restrictions Lost During Booking Overlay

**Datum:** 2026-01-07  
**Prioritet:** High  
**Status:** ✅ Riješeno  
**Zahvaćeni fajl:** `lib/features/widget/data/repositories/firebase_booking_calendar_repository.dart`  
**Predložio:** Google Jules (branch: `fix/LOGIC-003-calendar-data-consistency-8111192320731936509`)

**Problem:**
Kada se booking ili iCal event prikazuje na kalendaru, `CalendarDateInfo` se kreirao iznova umjesto da se koristi `copyWith`. Ovo je uzrokovalo gubitak restrikcija iz `daily_prices`:

- `blockCheckIn` - zabrana check-in na taj datum
- `blockCheckOut` - zabrana check-out na taj datum
- `minDaysAdvance` - minimalno dana unaprijed za rezervaciju
- `maxDaysAdvance` - maksimalno dana unaprijed za rezervaciju
- `minNightsOnArrival` - minimalni broj noćenja pri dolasku
- `maxNightsOnArrival` - maksimalni broj noćenja pri dolasku

**Scenarij buga:**
1. Owner postavi `blockCheckIn: true` za 15. januar (npr. zbog čišćenja)
2. Gost rezervira 10-15. januar
3. Kalendar prikaže 15. januar kao `partialCheckOut`
4. **BUG:** `blockCheckIn` je sada `false` (default) umjesto `true`
5. Drugi gost može odabrati 15. januar kao check-in (ne bi trebao moći!)

**Rješenje:**
Korištenje `copyWith` umjesto kreiranja novog `CalendarDateInfo` objekta na 4 mjesta:

```dart
// PRIJE (buggy):
calendar[current] = CalendarDateInfo(
  date: current,
  status: status,
  price: priceMap[priceKey]?.price,
  isPendingBooking: isPending,
  // ❌ Restrikcije se gube!
);

// POSLIJE (fix):
final infoToUpdate = existingInfo ?? CalendarDateInfo(
  date: current,
  status: DateStatus.available,
  price: priceMap[priceKey]?.price,
);
calendar[current] = infoToUpdate.copyWith(
  status: status,
  isPendingBooking: isPending,
  isCheckOutPending: isCheckOutPending,
  isCheckInPending: isCheckInPending,
);
```

**Zahvaćena mjesta (4 lokacije):**
1. `_buildCalendarMap` - booking loop
2. `_buildCalendarMap` - iCal loop
3. `_buildYearCalendarMap` - booking loop
4. `_buildYearCalendarMap` - iCal loop

**Testiranje:**
1. ✅ Kreirati `daily_price` s `blockCheckIn: true` za datum X
2. ✅ Kreirati booking koji završava na datum X (checkout)
3. ✅ Provjeriti da `calendar[X].blockCheckIn == true`
4. ✅ Provjeriti da validacija blokira check-in na datum X

**Moguće nuspojave:**
- Nema - `copyWith` čuva sve postojeće vrijednosti osim onih koje eksplicitno mijenjamo



---

### 🐛 BUG-009: iCal Empty Data Validation - Prevent Data Loss During Sync

**Datum:** 2026-01-07  
**Prioritet:** Critical  
**Status:** ✅ Riješeno  
**Zahvaćeni fajl:** `functions/src/icalSync.ts`  
**Predložio:** Google Jules (branch: `fix/LOGIC-003-calendar-data-consistency-8111192320731936509`)

**Problem:**
U `syncSingleFeed` funkciji nije postojala validacija da li je dohvaćeni iCal odgovor validan. Ako vanjski API (Airbnb, Booking.com) vrati prazan string, HTML error stranicu, ili neispravan format:

1. `parseIcalData` parsira prazan/neispravan sadržaj → 0 evenata
2. `deleteOldEvents` briše SVE postojeće evente za taj feed
3. `insertNewEvents` insertira 0 novih evenata
4. **KATASTROFA:** Kalendar pokazuje slobodne datume koji su zapravo zauzeti!

**Scenarij buga:**
1. Airbnb ima privremeni downtime → vraća HTML error stranicu
2. `fetchIcalData` vraća `"<html>503 Service Unavailable</html>"`
3. `parseIcalData` ne pronalazi VEVENT → vraća `[]`
4. `deleteOldEvents` briše 15 postojećih evenata
5. `insertNewEvents` insertira 0 evenata
6. Gost može rezervirati već zauzete datume → **DOUBLE BOOKING!**

**Rješenje:**
Dodana validacija prije parsiranja i brisanja:

```typescript
// Fetch iCal data
const icalData = await fetchIcalData(ical_url);

// BUG-009 FIX: Validate fetched iCal data before processing
// Prevents accidental deletion of all events if the fetched data is empty/malformed
// Every valid iCal file MUST contain "BEGIN:VCALENDAR" per RFC 5545
if (!icalData || !icalData.includes("BEGIN:VCALENDAR")) {
  throw new Error(`Fetched iCal data is empty or invalid for feed: ${feedId}. ` +
    `Expected iCal format but received: ${icalData ? icalData.substring(0, 100) + '...' : 'empty response'}`);
}

// Parse iCal data
const events = await parseIcalData(icalData);
```

**Zašto `BEGIN:VCALENDAR`?**
Svaki validan iCal fajl MORA početi s `BEGIN:VCALENDAR` prema RFC 5545 standardu. Ako taj string ne postoji, odgovor je neispravan.

**Testiranje:**
1. ✅ Normalan iCal feed → sync radi normalno
2. ✅ Prazan odgovor → sync FAIL-a s greškom, eventi se NE brišu
3. ✅ HTML error stranica → sync FAIL-a s greškom, eventi se NE brišu
4. ✅ Feed se označava kao `status: 'error'` s detaljnom porukom

**Moguće nuspojave:**
- Nema negativnih - sync koji bi inače obrisao sve evente sada FAIL-a s jasnom greškom
- Owner vidi error status i može reagirati



---

### 🐛 BUG-010: Timezone Handling in Past Date Validation

**Datum:** 2026-01-07  
**Prioritet:** Medium  
**Status:** ✅ Riješeno  
**Zahvaćeni fajl:** `functions/src/utils/dateValidation.ts`  
**Predložio:** Google Jules (branch: `fix/LOGIC-003-calendar-data-consistency-8111192320731936509`)

**Problem:**
U `validateAndConvertBookingDates` i `calculateDaysInAdvance` funkcijama, "today" se kreirao na nekonzistentan način:

```typescript
// BUGGY: setUTCHours on local Date
const today = new Date();
today.setUTCHours(0, 0, 0, 0);
```

`new Date()` vraća trenutno vrijeme u lokalnoj timezone servera (npr. Europe/Amsterdam za Firebase europe-west1). Zatim `setUTCHours(0, 0, 0, 0)` postavlja UTC sate na 0, ali datum ostaje lokalni, što može uzrokovati nekonzistentno ponašanje.

**Scenarij buga:**
- Server u UTC-8 (Los Angeles), 7. januar 14:30 PST
- `new Date()` = 2026-01-07T14:30:00-08:00
- `setUTCHours(0, 0, 0, 0)` = 2026-01-06T16:00:00-08:00 (prethodni dan lokalno!)
- Booking za 7. januar bi bio odbijen kao "u prošlosti"

**Rješenje:**
Korištenje `Date.UTC()` za eksplicitno kreiranje UTC datuma:

```typescript
// BUG-010 FIX: Use Date.UTC() for consistent cross-timezone validation
const now = new Date();
const today = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));

const checkInMidnight = new Date(Date.UTC(
  checkInDateObj.getUTCFullYear(),
  checkInDateObj.getUTCMonth(),
  checkInDateObj.getUTCDate()
));
```

**Zahvaćene funkcije:**
1. `validateAndConvertBookingDates` - past date validation
2. `calculateDaysInAdvance` - days in advance calculation

**Testiranje:**
1. ✅ Booking za danas → prolazi
2. ✅ Booking za sutra → prolazi
3. ✅ Booking za jučer → odbijen
4. ✅ Konzistentno ponašanje bez obzira na server timezone

**Moguće nuspojave:**
- Nema - rezultat je isti u većini slučajeva, fix samo osigurava konzistentnost u edge case-ovima



---

### 🐛 BUG-011: Notification Idempotency Key Missing Action

**Datum:** 2026-01-07  
**Prioritet:** Medium  
**Status:** ✅ Riješeno  
**Zahvaćeni fajl:** `functions/src/notificationService.ts`  
**Predložio:** Google Jules (branch: `fix/LOGIC-003-calendar-data-consistency-8111192320731936509`)

**Problem:**
Idempotency key format nije uključivao `action` parametar. Ako se u istoj minuti dogode različite akcije za isti booking (npr. "created" pa odmah "updated"), moglo je doći do gubitka notifikacija.

**Stari format:** `{ownerId}_{type}_{bookingId}_{timestamp_minute}`
**Novi format:** `{ownerId}_{type}_{bookingId}_{action}_{timestamp_minute}`

**Rješenje:**
1. Dodano `action` u idempotency key format
2. Dodano `action` u metadata objekta za `createBookingNotification`

```typescript
// BUG-011 FIX: Improved idempotency key to include action
const actionPart = data.metadata?.action || "default";
const idempotencyKey = `${data.ownerId}_${data.type}_${bookingPart}_${actionPart}_${timestampMinute}`;
```

**Testiranje:**
1. ✅ Kreiranje notifikacije → jedinstveni key
2. ✅ Retry iste notifikacije → isti key (idempotent)
3. ✅ Različite akcije u istoj minuti → različiti keyevi

**Moguće nuspojave:**
- Nema - samo poboljšava granularnost idempotency keya

---

### 🐛 BUG-012: Price Rollback Logic for Deleted Prices

**Datum:** 2026-01-07  
**Prioritet:** Medium  
**Status:** ✅ Riješeno  
**Zahvaćeni fajl:** `lib/features/owner_dashboard/presentation/state/price_calendar_state.dart`  
**Predložio:** Google Jules (branch: `fix/LOGIC-003-calendar-data-consistency-8111192320731936509`)

**Problem:**
`rollbackUpdate` funkcija nije ispravno rukovala slučajem kada je cijena bila obrisana (optimistic delete). Tip `Map<DateTime, DailyPriceModel>` nije dozvoljavao `null` vrijednosti, pa rollback nije mogao vratiti stanje "nema cijene".

**Scenarij buga:**
1. Korisnik obriše cijenu za 15. januar (optimistic delete)
2. Server vrati grešku
3. Rollback pokušava vratiti staro stanje
4. **BUG:** `oldPrices[15.jan] = null` nije moguće s tipom `Map<DateTime, DailyPriceModel>`

**Rješenje:**
Promijenjen tip parametra na `Map<DateTime, DailyPriceModel?>` i dodana provjera:

```dart
void rollbackUpdate(
  DateTime month,
  Map<DateTime, DailyPriceModel?> oldPrices,  // Nullable values
) {
  for (final entry in oldPrices.entries) {
    if (entry.value != null) {
      _priceCache[monthKey]![entry.key] = entry.value!;
    } else {
      _priceCache[monthKey]!.remove(entry.key);  // Restore deletion
    }
  }
}
```

**Testiranje:**
1. ✅ Rollback postojeće cijene → cijena vraćena
2. ✅ Rollback obrisane cijene → cijena uklonjena iz cache-a
3. ✅ Rollback mješovitih promjena → ispravno stanje

**Moguće nuspojave:**
- Pozivi `rollbackUpdate` moraju koristiti nullable tip - ali to je ispravno ponašanje


---

### 🔐 SEC-001: IDOR Vulnerability in Firebase Storage Rules (CRITICAL)

**Datum:** 2026-01-07  
**Prioritet:** 🚨 CRITICAL  
**Status:** ✅ Riješeno  
**Zahvaćeni fajl:** `storage.rules`  
**Otkrio:** Google Sentinel Security Scanner

**Problem:**
Firebase Storage write pravila za `/properties/{propertyId}` i `/ical-exports/{propertyId}` su samo provjeravala da li je korisnik autenticiran (`request.auth != null`), ali NE da li je vlasnik resursa.

**Ranjivost (IDOR - Insecure Direct Object Reference):**
Bilo koji autenticirani korisnik mogao je:
1. Prepisati slike tuđih nekretnina
2. Obrisati iCal exporte drugih vlasnika
3. Uploadati maliciozne fajlove na tuđe property-je

**Prije ispravke:**
```javascript
match /properties/{propertyId}/{allPaths=**} {
  allow read: if true;
  allow write: if request.auth != null;  // ❌ RANJIVO!
}
```

**Rješenje:**
Dodana Firestore lookup provjera koja verificira da `request.auth.uid` odgovara `owner_id` property-ja:

```javascript
match /properties/{propertyId}/{allPaths=**} {
  allow read: if true;
  // SEC-001: Write allowed ONLY by property owner (IDOR fix)
  allow write: if request.auth != null &&
    get(/databases/$(database)/documents/properties/$(propertyId)).data.owner_id == request.auth.uid;
}
```

**Zahvaćeni pathovi:**
- `/properties/{propertyId}/**` - slike nekretnina
- `/ical-exports/{propertyId}/**` - kalendar exporti

**Testiranje:**
1. ✅ Vlasnik uploada sliku → uspješno
2. ✅ Drugi korisnik pokušava upload → ODBIJENO
3. ✅ Neautenticirani korisnik → ODBIJENO
4. ✅ Read ostaje public (za widget prikaz)

**Moguće nuspojave:**
- Svaki write na storage sada radi dodatni Firestore read (minimalan trošak)
- Property dokument MORA imati `owner_id` field (već postoji)

**GDPR/Security implikacije:**
Ova ispravka sprječava neovlašteni pristup i modifikaciju korisničkih podataka, što je kritično za sigurnost i usklađenost s regulativama.
