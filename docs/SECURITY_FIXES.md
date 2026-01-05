# 🔐 Security Fixes Documentation

Ovaj dokument prati sve sigurnosne ispravke u projektu. Svaka ispravka je detaljno dokumentirana kako bi se u budućnosti moglo provjeriti da li je možda prouzrokovala neki bug.

---

## Sadržaj

1. [SF-001: Owner ID Validation in Booking Creation](#sf-001-owner-id-validation-in-booking-creation)
2. [SF-002: SSRF Prevention in iCal Sync](#sf-002-ssrf-prevention-in-ical-sync)

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
