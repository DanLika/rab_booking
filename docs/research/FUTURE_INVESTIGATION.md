# BookBed - Future Investigation & Research Summary

**Datum:** 2025-12-17
**Verzija:** 1.0

Ovaj dokument sadrži sva istraživanja vezana za channel management, iCal sync, scraping za lead generation, i konkurentsku analizu.

---

## Sadržaj

1. [Channel Manager API - Realnost](#1-channel-manager-api---realnost)
2. [iCal Sync - Tehnička Analiza](#2-ical-sync---tehnička-analiza)
3. [Middleware/iPaaS Opcije](#3-middlewareipas-opcije)
4. [Konkurentska Analiza](#4-konkurentska-analiza)
5. [Lead Generation Scraping](#5-lead-generation-scraping)
6. [BookBed Pozicioniranje](#6-bookbed-pozicioniranje)
7. [Akcijski Plan](#7-akcijski-plan)

---

## 1. Channel Manager API - Realnost

### Status API Pristupa (2025)

| Platforma | Status | Napomena |
|-----------|--------|----------|
| **Airbnb** | 🔒 Zatvoren | Invite-only, ne primaju prijave |
| **Booking.com** | 🔒 Zatvoren | "Paused until further notice" |

### Zašto Je Zatvoren?

- Kontrola kvalitete integracija
- GDPR zaštita podataka gostiju
- Business model - žele da owneri koriste njihov dashboard
- Sprječavanje konkurencije novim PMS-ovima

### Zahtjevi za Direktan API (kad se otvori)

**Airbnb:**
- Profitable business s track recordom
- Tehnička snaga za implementaciju
- Customer support sposobnost
- Kontakt: airbnb-platform@airbnb.com

**Booking.com:**
- PCI compliance
- GDPR compliance
- Cloud-based infrastructure
- Real-time reservation confirmation
- Monitor: connect.booking.com

### Jedini Način za API Pristup

Korištenje **certificiranih channel managera** kao middleware:
- Channex.io
- Beds24
- Rentals United
- NextPax

---

## 2. iCal Sync - Tehnička Analiza

### Službena Dokumentacija

**Airbnb iCal Update Frequency:**
> "Your Airbnb calendar automatically updates every 3 hours"
>
> Izvor: [Airbnb Help Article 99](https://www.airbnb.com/help/article/99)

**Booking.com:** Nema službene dokumentacije o frekvenciji.

### Verificirani Podaci

| Aspekt | Airbnb | Booking.com |
|--------|--------|-------------|
| Update frekvencija | **3 sata** (službeno) | Nedokumentirano (30min-24h) |
| Rate limit | **80 req/min/IP** | Nedokumentirano |
| Real-world delay | 30min - 24h | 30min - 24h |
| Worst case | Do 48 sati | Do 24 sati |

### Podaci u iCal Feedu (nakon Dec 2019)

**UKLJUČENO:**
- Check-in/check-out datumi (samo datum, ne vrijeme)
- Summary: "Reserved"
- Reservation URL link
- Zadnje 4 cifre telefona gosta
- Unique event identifier (UID)

**ISKLJUČENO (od 1.12.2019):**
- Guest name
- Full phone number
- Email address
- Pricing
- Payment details
- Number of guests
- Check-in/out times
- Listing name
- Booking confirmation codes

### Booking.com Cancellation Problem

> "iCal syncing can be delayed even up to 6 hours or more if not done manually."
>
> Cancelled bookings mogu ostati blokirani na connected kalendarima.

### Preporuka za Polling Interval

| Interval | Preporuka |
|----------|-----------|
| 15 min | ❌ Besmisleno - OTA ne ažurira tako često |
| 30 min | ⚠️ Kompromis |
| **60 min** | ✅ Optimalno |
| 3 sata | OK za low-volume |

**BookBed promjena:** `scheduledIcalSync` promijenjen sa 15 min na **60 min**.

### Double Booking Rizik

```
Danger window: 1-6 sati (realno)

Mitigacija:
1. Buffer days (min 1 dan između bookinga)
2. Manual refresh nakon booking notifikacija
3. Instant booking samo na jednoj platformi
```

---

## 3. Middleware/iPaaS Opcije

### No-Code Platforme - NEMAJU OTA Pristup

| Platforma | Airbnb | Booking.com | Two-Way |
|-----------|--------|-------------|---------|
| Zapier | ❌ Email parsing only | ❌ | Ne |
| Make | ❌ Via PMS only | ❌ | Ne |
| n8n | ❌ Scraping only | ❌ | Ne |
| Pipedream | ❌ | ❌ | Ne |
| Tray.io | ❌ | ❌ | Ne |

**Zaključak:** Zapier/Make/n8n NE MOGU riješiti problem.

### Channex - Najbolja Middleware Opcija

| Aspekt | Detalj |
|--------|--------|
| Model | API-only middleware (nije PMS konkurent) |
| Cijena VR | **$0.50/unit/mjesec** |
| Cijena Hotel | $7/property/mjesec |
| Two-way sync | ✅ Da |
| Response time | <100ms |
| Uptime SLA | 99.9% |
| Dokumentacija | docs.channex.io |
| Free staging | staging.channex.io |

**Za 100 vacation rental unita:** ~$50/mjesec

### Usporedba Middleware Cijena

| Opcija | 100 VR Unita/mj | Two-Way |
|--------|-----------------|---------|
| Channex | ~$50 | ✅ |
| Beds24 | ~$180 | ✅ |
| Email parsing | ~$100-150 | ❌ Read only |
| QloApps (hosting) | ~$100-200 | ✅ |

---

## 4. Konkurentska Analiza

### Pricing Comparison

| Konkurent | Mjesečno | Godišnje | Booking Fee |
|-----------|----------|----------|-------------|
| Beds24 | €15.90 | €191 | 0% |
| BedBooking | ~€15 | ~€150 | 0% |
| Lodgify Starter | $16 | $192 | 1.9% |
| Smoobu Flex | €29 | €313 | 0.9% |
| Hospitable | $29 | $306 | 1-7% |
| Lodgify Pro | $40 | $480 | 0% |
| Amenitiz | $42-113 | $504-1,356 | 0% |
| Hostaway | $40-100 | $480-1,200 | 1.8% |
| Cloudbeds | $99-108 | $1,188-1,296 | 0% |
| Little Hotelier | $104-109 | $1,248-1,308 | 1% |
| **BookBed** | **€0** | **€400 lifetime** | **0%** |

### Break-Even Analysis

| Konkurent | BookBed Break-even |
|-----------|-------------------|
| Little Hotelier | 4 mjeseca |
| Cloudbeds | 4-5 mjeseci |
| Hostaway | 5-8 mjeseci |
| Amenitiz | 4-10 mjeseci |
| Lodgify Pro | 11 mjeseci |
| Smoobu | 14 mjeseci |
| Hospitable | 17 mjeseci |
| Beds24 | 25 mjeseci |

### Feature Comparison

| Feature | BookBed | Konkurenti |
|---------|---------|------------|
| Embeddable Widget | ✅ | ✅ |
| API Channel Manager | ❌ iCal only | ✅ |
| Website Builder | ❌ (+€200) | ✅ Često uključeno |
| SEPA/Bank Transfer | ✅ | ⚠️ Partial |
| Pay on Arrival | ✅ | ⚠️ Rijetko |
| Stripe | ✅ | ✅ |
| Booking Fee | **0%** | 0-1.9% |
| Lifetime Option | ✅ | ❌ |

### BookBed USP

```
"Plati jednom, koristi zauvijek - 0% provizije, fleksibilna plaćanja"

1. Lifetime ownership - nema recurring troškova
2. Zero booking fees - konkurenti uzimaju 0.9-1.9%
3. Payment flexibility - SEPA, bank transfer, cash
```

### Idealni Klijent za BookBed

- 1-3 nekretnine
- Fokus na direktne rezervacije (ne OTA)
- Europski market (SEPA važan)
- Planira raditi 2+ godine
- Frustriran subscription fees i provizijama

---

## 5. Lead Generation Scraping

### Razumijevanje Alata - Šta Koji Radi

**VAŽNO:** Mnogi alati se pogrešno percipiraju. Evo jasne podjele:

| Kategorija | Alati | Može naći email? | Može scrapati OTA? |
|------------|-------|------------------|-------------------|
| **SEO alati** | SEMrush, Ahrefs, Majestic, Moz | ❌ Ne | ❌ Ne |
| **Website crawleri** | Screaming Frog | ✅ Sa običnih sajtova | ❌ Ne (anti-bot) |
| **OTA scraperi** | Apify, Bright Data | ❌ Samo host ime | ✅ Da |
| **Email finderi** | Snov.io, Hunter.io | ✅ Da | N/A |
| **Google scraping** | Apify Google Maps | ✅ Direktno | N/A |

### SEO Alati - Šta NE Rade

```
SEMrush, Ahrefs, Majestic, Moz su za:
✅ Keyword research (koje riječi ljudi traže)
✅ Backlink analysis (ko linkuje na sajt)
✅ Competitor analysis (SEO strategija konkurencije)
✅ Domain authority (snaga domene)

SEO alati NE MOGU:
❌ Scrapati Airbnb/Booking.com
❌ Pronalaziti email adrese
❌ Izvlačiti kontakt podatke vlasnika
❌ Raditi lead generation direktno
```

### Screaming Frog - Ograničenja

**Screaming Frog MOŽE:**
- Crawlati obične website-ove (villa-marija.com, apartmani-zadar.hr)
- Izvući email/telefon sa stranica
- Bulk extraction iz liste URL-ova
- Export u CSV/Excel

**Screaming Frog NE MOŽE:**
- Scrapati Airbnb/Booking.com (anti-bot zaštita, JavaScript rendering)
- Pronaći URL-ove sam (treba mu input lista)
- Raditi bez početnih URL-ova

**Realna vrijednost:** Kad imaš 500+ URL-ova property sajtova, automatizira extraction umjesto ručnog kopiranja (50+ sati → 2 sata).

### Apify Platforma - Detaljno

Apify je **platforma** sa mnogo različitih scrapera (nije samo za Airbnb!):

| Scraper | Cijena | Podaci |
|---------|--------|--------|
| `tri_angle/airbnb-scraper` | $1.25/1000 | Listing, host ime, lokacija, cijena |
| `voyager/booking-scraper` | $2.50/1000 | Listing, property name, lokacija |
| `apify/google-maps-scraper` | $2/1000 | Ime, telefon, email, adresa |
| `apify/google-search-scraper` | $1/1000 | Google rezultati |

### Google Maps - Najbolja Alternativa

**Zašto Google Maps scraping?**
- Telefon/email su **direktno dostupni** (business listing)
- Nema potrebe za enrichment
- Uključuje apartmane koji NISU na Airbnb/Booking
- Cijena: ~$2/1000 rezultata

**Search queries za Hrvatsku:**
```
"apartman" + [grad] (Zadar, Split, Dubrovnik, Rijeka...)
"villa rental" + Croatia
"privatni smještaj" + [regija]
```

### Dostupni Servisi

| Servis | Cijena | Airbnb | Booking.com | Google Maps |
|--------|--------|--------|-------------|-------------|
| [Apify](https://apify.com/tri_angle/airbnb-scraper) | $1.25-2.50/1000 | ✅ | ✅ | ✅ |
| [Bright Data](https://brightdata.com) | ~$500+/mj | ✅ | ✅ | ✅ |
| [Outscraper](https://outscraper.com) | Pay per result | ❌ | ✅ | ✅ |

### Apify Detalji

- **Cijena:** $1.25-2.50 per 1,000 rezultata (ovisi o scraperu)
- **Free tier:** $5/mjesec (~4,000 listinga)
- **Starter plan:** $49/mj
- **Airbnb Leads Email Scraper:** Specijaliziran za B2B lead generation
- **Booking.com scraper:** `voyager/booking-scraper`
- **Google Maps scraper:** `apify/google-maps-scraper`

### Dostupni Podaci

**Javno dostupni (scrapable):**
- Naziv apartmana
- Lokacija
- Cijene
- Slike
- Rating/Reviews
- Host ime (djelomično)

**NIJE javno dostupno:**
- Email vlasnika
- Telefon vlasnika
- Privatni podaci

### Enrichment Strategija

1. Scrape naziv apartmana + host ime
2. Google search: "{naziv apartmana} Instagram/Facebook"
3. Koristi enrichment tool (Hunter.io, Snov.io)
4. Manual research za high-value targets

### Email Finder Alati - Detaljno

**Snov.io** (€39/mj za 1,000 credits):
```
INPUT:  "Marko Horvat" + "Villa Sunset Zadar"
OUTPUT: marko.horvat@gmail.com (30-50% success rate)

Funkcije:
- Email Finder: Pronalazi email iz imena + kompanije/domene
- Domain Search: Svi emailovi na jednoj domeni
- Email Verifier: Provjerava da li email postoji
- Drip Campaigns: Šalje cold email sekvence
```

**Hunter.io** (Besplatan tier: 50 searches/mj):
- Pronalazi email po domeni
- Dobro za sajtove koji imaju vlastitu domenu

**Apollo.io** (Besplatan tier):
- Većinom B2B fokus
- Manje korisno za male property ownere

### Praktični Workflow - Tri Pristupa

**PRISTUP 1: OTA Scraping (Airbnb/Booking)**
```
Apify OTA scraper → host ime + listing
         ↓
Snov.io enrichment → email (30-50% recovery)
         ↓
Cold email kampanja

Trošak: ~€50-65
Rezultat: 1,500-2,500 emailova od 5,000 listinga
```

**PRISTUP 2: Google Maps (direktni kontakti)**
```
Apify Google Maps → ime + telefon + email direktno
         ↓
Nema enrichment potreban!
         ↓
Cold email/SMS kampanja

Trošak: ~€10-20
Rezultat: Direktni kontakti, uključuje i non-OTA apartmane
```

**PRISTUP 3: Samostalni sajtovi (van OTA)**
```
Ahrefs/SEMrush → pronađi sajtove po keywordu
         ↓
Screaming Frog → bulk email/telefon extraction
         ↓
Cold email kampanja

Trošak: €0 (ako imaš pristup alatima)
Rezultat: Vlasnici sa vlastitim sajtovima = IDEALNI klijenti za BookBed
```

### ROI Kalkulacija

```
Scraping 5,000 listinga: ~$10
Email tool: ~$20-50/mj
Ukupno: ~$60

0.1% conversion = 5 klijenata × €400 = €2,000
ROI: 3,300%
```

### Legalna Razmatranja

- Scraping javnih podataka: Sivo područje, ali OK za većinu
- GDPR: Pažnja - treba legitimate interest
- Cold email B2B u EU: Dopušteno
- Airbnb TOS: Tehnički kršenje, ali teško za otkriti

### Detaljna Analiza (Dec 2025)

**Ključni nalaz:** Direktan email/telefon iz Airbnb/Booking.com **NIJE MOGUĆE** - platforme namjerno skrivaju podatke.

**Rješenje:** Enrichment workflow

| Korak | Alat | Cijena |
|-------|------|--------|
| Scraping | Apify tri_angle | ~€12 za 10,000 listinga |
| Enrichment | Snov.io | €39/mj (1,000 lookups) |
| Social search | PhantomBuster | €56/mj (opcija) |
| Email kampanja | Lemlist/Mailchimp | €30-50/mj |

**Contact Recovery Rate:** 30-50% (bolje za property managere, lošije za individualne ownere)

**EU DSA (Feb 2025):** Business hosts na Airbnb MORAJU javno prikazati kontakt podatke. Ovo će značajno poboljšati recovery rate.

**GDPR Compliance za Hrvatsku:**
- B2B cold email: ✅ LEGALNO (opt-out framework)
- Potrebno: Article 14 disclosure u emailu
- Potrebno: Jasan opt-out mehanizam
- Potrebno: Obrisati podatke non-respondera u 30 dana

**Sample compliant email footer:**
> "Pronašli smo vaš oglas na Airbnb-u. Kontaktiramo vas temeljem legitimnog interesa da ponudimo BookBed usluge relevantne za vlasnike apartmana. Odgovorite 'STOP' za trenutnu odjavu. Vaši podaci će biti obrisani u roku 30 dana."

**Procjena troškova za 10,000 hrvatskih listinga:**
| Komponenta | Cijena |
|------------|--------|
| Apify scraping | €15-25 |
| Snov.io (3 mjeseca) | €100-120 |
| Email platforma | €30-50/mj |
| **UKUPNO** | **€180-350** |

**Očekivani rezultati:**
- 10,000 listinga → 5,000 kvalificiranih (mali owneri)
- 30-50% enrichment → 1,500-2,500 emailova
- 0.5% conversion → 8-12 klijenata
- ROI: ~1,000%+

---

## 6. BookBed Pozicioniranje

### Što BookBed JESTE

- Alat za **direktne rezervacije** bez provizija
- Profesionalni booking widget za vlastiti website
- **Lifetime** licenca - bez recurring troškova
- Podrška za SEPA, bank transfer, cash, Stripe

### Što BookBed NIJE

- Channel manager za OTA
- Zamjena za Beds24/Guesty/Hostaway
- Alat za upravljanje Airbnb/Booking rezervacijama

### Konkurencija

```
❌ NE KONKURIRA: Beds24, Guesty, Hostaway (channel management)
✅ KONKURIRA: WhatsApp, Excel, ručno upravljanje
```

### Value Proposition

| Za Ownera | Benefit |
|-----------|---------|
| €30,000/god direktnih rezervacija | |
| Na Lodgify (1.9% + subscription) | ~€762/god troškova |
| Na BookBed | €400 JEDNOM |
| **Ušteda 3 godine** | **€1,886+** |

### Marketing Poruke

> "Nakon 8 mjeseci, svaki konkurent košta više od nas - zauvijek"

> "0% booking fees = 100% tvog prihoda ostaje tebi"

> "Plaćanje na europski način: SEPA, bank transfer, ili gotovina"

---

## 7. Akcijski Plan

### Kratkoročno (MVP)

- [x] iCal sync promijenjen na 60 min
- [ ] Implementirati "Manual Refresh" button
- [ ] Dodati buffer days preporuku u UI
- [ ] Jasna komunikacija o iCal ograničenjima

### Srednjoročno (20+ klijenata)

- [ ] Evaluirati Channex integraciju
- [ ] Odluka: uključiti u lifetime ILI kao addon
- [ ] Aplicirati za direktan API kad se otvori

### Lead Generation

- [ ] Testirati Apify za Croatian listings
- [ ] Razviti enrichment workflow
- [ ] Email outreach kampanja
- [ ] Landing page za conversions

### Dugoročno

- [ ] 500+ korisnika za API aplikaciju
- [ ] Direktan Airbnb/Booking API pristup
- [ ] Volume discount od middleware providera

---

## Resursi i Linkovi

### Channel Manager API
- Channex: https://channex.io | docs.channex.io
- Beds24: https://beds24.com/api/v2
- Rentals United: https://rentalsunited.com

### Platform Partner Programs
- Airbnb Developer: https://developer.airbnb.com
- Airbnb API Terms: https://airbnb.com/help/article/3418
- Booking.com Connectivity: https://connect.booking.com

### Scraping
- Apify Airbnb: https://apify.com/tri_angle/airbnb-scraper
- Apify Leads: https://apify.com/datavoyantlab/airbnb-leads-email-scraper
- Bright Data: https://brightdata.com

### Konkurenti
- Lodgify: https://lodgify.com
- Smoobu: https://smoobu.com
- Hospitable: https://hospitable.com
- Beds24: https://beds24.com

---

## Changelog

| Datum | Promjena |
|-------|----------|
| 2025-12-17 | Inicijalni dokument kreiran |
| 2025-12-17 | iCal sync interval promijenjen na 60 min |
| 2025-12-18 | Dodana sekcija o razumijevanju alata (SEO vs Scraping vs Email finder) |
| 2025-12-18 | Pojašnjeno šta Screaming Frog može i ne može |
| 2025-12-18 | Dodani Apify scraperi za Booking.com i Google Maps |
| 2025-12-18 | Dodana detaljna objašnjenja za Snov.io, Hunter.io, Apollo.io |
| 2025-12-18 | Dodana tri praktična workflow pristupa za lead generation |

---

*Ovaj dokument će se ažurirati kako budu nova istraživanja.*
