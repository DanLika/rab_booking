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
