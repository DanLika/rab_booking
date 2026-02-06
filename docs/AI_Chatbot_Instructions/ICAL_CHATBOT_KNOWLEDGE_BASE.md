# BookBed iCal System — Kompletna baza znanja za AI chatbot

## 1. Pregled sustava

BookBed koristi **iCal protokol (RFC 5545)** za dvosmjernu sinkronizaciju kalendara s booking platformama (Booking.com, Airbnb, Adriagate, itd.) i osobnim kalendarima (Google Calendar, Apple Calendar, Outlook).

Sustav se sastoji od dva dijela:
- **iCal Import** — uvoz rezervacija s vanjskih platformi u BookBed
- **iCal Export** — izvoz BookBed rezervacija prema vanjskim platformama

Oba dijela rade zajedno u **hub-and-spoke** arhitekturi gdje je BookBed centralni hub kroz koji prolaze sve informacije o dostupnosti.

---

## 2. iCal Import (Uvoz rezervacija)

### 2.1 Što je iCal Import?

iCal Import automatski dohvaća rezervacije s vanjskih booking platformi i prikazuje ih u BookBed kalendaru. Vlasnik nekretnine vidi sve rezervacije — i one napravljene direktno na BookBedu i one s drugih platformi — na jednom mjestu.

### 2.2 Kako se postavlja?

1. Vlasnik odlazi na **iCal Sinkronizacija** stranicu u Owner Dashboard-u
2. Klikne **"Dodaj iCal Feed"**
3. Bira platformu (Booking.com, Airbnb, ili "Druga platforma" za sve ostale)
4. Ako odabere "Druga platforma", upisuje naziv (npr. "Adriagate", "Smoobu", "Atraveo")
5. Upisuje iCal URL koji je dobio od platforme
6. Opcionalno: može isključiti uvoz (export-only mod) — korisno za platforme koje stvaraju duplikate

### 2.3 Gdje pronaći iCal URL za svaku platformu?

- **Booking.com**: Extranet → Calendar → Sync calendars → Export calendar → Kopiraj link
- **Airbnb**: Calendar → Availability Settings → Export calendar → Kopiraj link
- **Adriagate / druge agencije**: Kontaktirati agenciju za iCal feed URL

### 2.4 Koliko često se sinkronizira?

- Automatska sinkronizacija se pokreće **svakih 15 minuta**
- Vlasnik može ručno pokrenuti sinkronizaciju klikom na "Sinkroniziraj sada" u bilo kojem trenutku
- Svaki feed ima vlastiti interval sinkronizacije koji se može prilagoditi

### 2.5 Što se uvozi?

- **Datumi prijave i odjave** (check-in / check-out)
- **Naziv gosta** (ako platforma to dijeli — mnoge ne dijele zbog GDPR-a)
- **Izvor** (npr. "Booking.com", "Airbnb", "Adriagate")
- **Opis** (ako postoji u iCal feedu)

Uvezene rezervacije automatski blokiraju datume u BookBed kalendaru i vidljive su na vremenskoj crti (timeline) i u listi rezervacija.

### 2.6 Što se NE uvozi?

- Osobni podaci gostiju (email, telefon, adresa) — iCal protokol ih ne prenosi
- Cijene i detalji plaćanja — iCal ne podržava financijske podatke
- Posebni zahtjevi gostiju

### 2.7 Import toggle (Export-only mod)

Za svaki feed može se isključiti uvoz rezervacija. Kada je uvoz isključen:
- BookBed i dalje šalje vaše rezervacije toj platformi (ona vidi vašu dostupnost)
- Ali BookBed NE uvozi njene događaje natrag

Ovo je korisno za platforme koje re-exportiraju uvezene podatke i tako stvaraju duplikate (npr. Holiday-Home).

### 2.8 Podržane platforme

| Platforma | Tip | Re-exportira? | Korupcija datuma? | Napomene |
|-----------|-----|---------------|-------------------|----------|
| Booking.com | Autoritativna | NE | NE | Siguran izvor — prikazuje samo vlastite rezervacije |
| Airbnb | Autoritativna | NE | NE | Siguran izvor — prikazuje samo vlastite rezervacije |
| Adriagate | Agregator | DA | NE | Spaja susjedne blokove u jedan VEVENT |
| Holiday-Home | Agregator | DA | DA (-29 dana) | Uklonjen iz sinkronizacije — kvari datume |
| Atraveo | Agregator | DA | NE | Ima opciju `&dontincludeimported=1` za isključivanje re-exporta |
| Google Calendar | Osobni | NE | NE | Samo za osobni pregled |
| Apple Calendar | Osobni | NE | NE | Samo za osobni pregled |
| Outlook | Osobni | NE | NE | Samo za osobni pregled |
| Bilo koja druga platforma s iCal podrškom | Ovisi | Ovisi | Ovisi | Tretira se s oprezom |

**Autoritativna platforma** = prikazuje samo vlastite rezervacije, ne re-exportira uvezene podatke. Sigurna za uvoz.

**Agregator** = može re-exportirati uvezene podatke, što stvara rizik od kružne sinkronizacije i duplikata. BookBed ima zaštitu (echo detekcija).

---

## 3. iCal Export (Izvoz rezervacija)

### 3.1 Što je iCal Export?

iCal Export generira URL koji sadrži sve BookBed rezervacije u standardnom iCal formatu. Taj URL se može zalijepiti u bilo koju platformu ili kalendarsku aplikaciju koja podržava iCal uvoz.

### 3.2 Kako funkcionira?

1. Vlasnik odlazi na **Export Rezervacija** stranicu
2. Klikne ikonu linka (🔗) pored željene smještajne jedinice
3. Otvara se dijalog s padajućim izbornikom platformi
4. Bira odredišnu platformu (Booking.com, Adriagate, ili "Ostalo / Google Calendar")
5. URL se automatski generira s ispravnim filterom
6. Kopira URL i lijepi ga u postavke uvoza na odredišnoj platformi

### 3.3 Vrste URL-ova

BookBed generira **filtrirane URL-ove za svaku platformu** koristeći `?exclude=` parametar:

| Odredište | URL format | Što sadrži | Što NE sadrži |
|-----------|-----------|------------|---------------|
| Booking.com | `...?exclude=booking_com` | BookBed rezervacije + Adriagate uvoz + blokirani dani | Booking.com vlastite rezervacije |
| Adriagate | `...?exclude=adriagate` | BookBed rezervacije + Booking.com uvoz + blokirani dani | Adriagate vlastite rezervacije |
| Google Calendar | `...` (bez filtera) | SVE rezervacije i blokovi | Ništa — vidi sve |

**Zašto filtriranje?** Ako Booking.com-u pošaljemo NJIHOVE vlastite rezervacije nazad, nastaje kružna sinkronizacija — Booking.com uveze svoju rezervaciju kao novu, pa se ona ponovno exportira, pa se ponovno uveze... beskonačna petlja.

### 3.4 Što se exportira?

Export sadrži 4 vrste podataka:

1. **Direktne BookBed rezervacije** (status: confirmed, pending, completed)
   - `SUMMARY: Reserved` (bez imena gosta — GDPR usklađenost)
   - `DESCRIPTION: {Naziv jedinice}\nManaged by BookBed`
   - `STATUS: CONFIRMED` (i pending rezervacije se exportiraju kao CONFIRMED jer Airbnb ignorira TENTATIVE)

2. **Uvezene rezervacije s DRUGIH platformi** (re-export za vidljivost)
   - Adriagate rezervacije se šalju prema Booking.com-u
   - Booking.com rezervacije se šalju prema Adriagateu
   - Svaka platforma tako vidi potpunu sliku dostupnosti

3. **Ručno blokirani dani** (iz pricing kalendara, `available=false`)
   - `SUMMARY: Not Available`
   - Vlasnik može blokirati datume za osobne razloge, održavanje, itd.

4. **Gap blokovi (automatski generirani)**
   - Ako je praznina između dvije rezervacije kraća od minimalnog broja noćenja, ta praznina se automatski blokira
   - Primjer: min-stay = 7 noći, praznina = 6 noći → blokira se jer nitko ne može rezervirati 6 noći
   - `SUMMARY: Not Available`
   - Sprječava OTA platforme (Booking.com, Airbnb) da prihvate rezervacije koje krše pravilo minimalnog boravka

### 3.5 Padajući izbornik platformi

Popis platformi u padajućem izborniku dolazi **dinamički iz Firestore-a** — prikazuju se samo platforme za koje vlasnik ima postavljene uvozne feedove. Ako vlasnik ima feedove za Booking.com i Adriagate, u padajućem izborniku će vidjeti:
- "Ostalo / Google Calendar" (uvijek prisutno — generički URL bez filtera)
- "Booking.com" (filtrirani URL)
- "Adriagate" (filtrirani URL)

Ako vlasnik nema nijedan uvozni feed, vidi samo generički URL i napomenu da postavi uvozne feedove za pristup filtriranim URL-ovima.

### 3.6 Sigurnost linka

Svaki URL sadrži **tajni token** (UUID v4) koji služi kao autentikacija. Bez ispravnog tokena, feed nije dostupan. Token se generira automatski pri prvom otvaranju dijaloga za tu jedinicu.

**Upozorenje za vlasnike:** Link ne treba dijeliti javno jer svatko s linkom može vidjeti raspored rezervacija.

### 3.7 GDPR usklađenost

iCal export **NE sadrži osobne podatke gostiju** (ime, email, telefon, cijena). Svi eventi prikazuju samo `Reserved` ili `Not Available`. Ovo je industriijski standard — Airbnb, Booking.com i agencije rade isto.

### 3.8 Vremena sinkronizacije po platformi

Različite platforme dohvaćaju iCal feed u različitim intervalima:
- **Google Calendar**: svakih 5-15 minuta
- **Apple Calendar**: svakih 5-15 minuta
- **Outlook**: svakih 5-15 minuta
- **Booking.com**: svakih 15-60 minuta
- **Airbnb**: svakih 3-6 sati

Za trenutnu sinkronizaciju, vlasnik može ručno osvježiti kalendar na platformi.

### 3.9 Same-day turnover (odjava i prijava istog dana)

BookBed podržava odjavu i prijavu na isti dan. Primjer:
- Rezervacija A: 1.–5. srpnja (odjava 5. srpnja)
- Rezervacija B: 5.–10. srpnja (prijava 5. srpnja)

U iCal feedu, DTEND je **ekskluzivan** (RFC 5545 standard). To znači da rezervacija A s DTEND=5. srpnja oslobađa 5. srpanj za novu prijavu. Platforme koje ispravno implementiraju iCal standard (Booking.com, Airbnb) automatski podržavaju ovo.

### 3.10 Booking.com iCal import — funkcionira!

Booking.com **prihvaća** iCal linkove s BookBeda, uključujući `?exclude=booking_com` parametar. Testiranje potvrđeno u veljači 2026. — Booking.com Extranet prikazuje status "U redu" nakon uvoza.

Koraci: Booking.com Extranet → Calendar → Sync calendars → Add calendar connection → Zalijepiti BookBed URL.

---

## 4. Hub-and-Spoke arhitektura

### 4.1 Što je hub-and-spoke?

BookBed je **centralni hub** kroz koji prolaze sve informacije o dostupnosti. Svaka platforma (spoke) komunicira samo s BookBedom, ne direktno s drugim platformama.

```
Booking.com ←→ BookBed ←→ Adriagate
                  ↕
               Airbnb
                  ↕
           Google Calendar
```

### 4.2 Tok podataka (primjer)

1. Gost rezervira na Adriagateu (Jul 19-24)
2. Adriagate objavi rezervaciju u svom iCal feedu
3. BookBed uveze tu rezervaciju (svakih 15 min automatski)
4. BookBed exportira tu rezervaciju u feedu za Booking.com (`?exclude=adriagate` NE isključuje Adriagate za Booking.com — Booking.com treba vidjeti tu rezervaciju!)

Ispravka: feed za Booking.com je `?exclude=booking_com`, što znači da Booking.com vidi SVE osim svojih vlastitih rezervacija. Dakle vidi i Adriagate rezervaciju.

5. Booking.com dohvati BookBed feed i blokira Jul 19-24
6. Nitko ne može rezervirati Jul 19-24 ni na Booking.com ni na BookBedu

### 4.3 Zašto NE direktna sinkronizacija?

Direktna sinkronizacija (Booking.com → Adriagate → Booking.com) stvara:
- **Kružne petlje** — rezervacija kruži u krug
- **Duplikate** — ista rezervacija se uveze više puta
- **Korupciju datuma** — neki agregatori mijenjaju datume pri re-exportu

Hub-and-spoke s filtriranim URL-ovima rješava sve tri problema.

---

## 5. Echo detekcija (sprječavanje duplikata)

### 5.1 Što je echo?

Echo je situacija kada BookBed uveze svoju vlastitu rezervaciju natrag s platforme koja re-exportira podatke. Primjer:
1. Vlasnik kreira rezervaciju na BookBedu (Jul 1-7)
2. BookBed exportira tu rezervaciju prema Adriagateu
3. Adriagate re-exportira tu rezervaciju u svom feedu
4. BookBed uveze taj feed → vidi "novu" rezervaciju Jul 1-7
5. Problem: to nije nova rezervacija, to je echo vlastite rezervacije!

### 5.2 Kako BookBed detektira echoe?

BookBed koristi **5-faktorski sustav bodovanja** koji analizira svaki uvezeni događaj:

| Faktor | Težina | Što mjeri |
|--------|--------|-----------|
| Podudaranje datuma | 25% | Jesu li datumi prijave/odjave isti ili vrlo bliski? |
| Podudaranje trajanja | 25% | Je li broj noćenja isti? (ključni signal — datumi se mogu pomaknuti, ali trajanje ostaje isto) |
| Korelacija s exportom | 25% | Postoji li već BookBed rezervacija na te datume koja je mogla biti exportirana? |
| Profil platforme | 15% | Je li izvorišna platforma poznati re-exporter (agregator)? |
| Vremenska analiza | 10% | Je li prošlo dovoljno vremena za sync ciklus? (>2 sata = vjerojatniji echo) |

### 5.3 Pragovi pouzdanosti

- **≥95% pouzdanost** → Automatski preskoči (ne uvozi se, samo se zapiše u log)
- **85-94% pouzdanost** → Označi za pregled (uvozi se sa statusom "Potreban pregled")
- **<85% pouzdanost** → Spremi normalno (tretira se kao nova, legitimna rezervacija)

### 5.4 Containment analiza (spajanje blokova)

Adriagate ima specifično ponašanje — **spaja susjedne rezervacije u jedan blok**. Primjer:
- Rezervacija A: Jul 19-31 (12 noći)
- Rezervacija B: Jul 31-Aug 7 (7 noći)
- Blok C: Aug 7-14 (7 noći)

Adriagate exportira kao: **jedan VEVENT Jul 19 - Aug 14 (26 noći)**

Standardna 1:1 echo detekcija ne može prepoznati ovo jer nema jednu rezervaciju od 26 noći. Zato BookBed koristi **containment analizu**:
1. Generira set noći za uvezeni blok (Jul 19, Jul 20, ..., Aug 13)
2. Generira uniju svih postojećih BookBed rezervacija za isti period
3. Provjerava: pokriva li unija 100% noći iz uvezenog bloka?
4. Ako da → to je spojeni echo, automatski se preskače

**Važna nijansa:** Ako spojeni blok sadrži i NATIVE Adriagate rezervaciju (koju Adriagate sam kreira, a ne re-exportira), tada se NE smije preskočiti. Containment analiza preskače samo ako su SVE noći pokrivene BookBed-native podacima.

### 5.5 Status uvezenih događaja

Svaki uvezeni iCal događaj ima jedan od sljedećih statusa:

| Status | Značenje | Blokira datume? |
|--------|----------|-----------------|
| `active` | Normalan, aktivan događaj | DA |
| `needs_review` | Echo detekcija označila za pregled (85-94%) | DA (dok se ne pregleda) |
| `confirmed_echo` | Vlasnik potvrdio da je duplikat | NE |
| `confirmed_overbooking` | Vlasnik potvrdio da je prava rezervacija (overbooking) | DA |

Samo `confirmed_echo` status ne blokira datume. Svi ostali statusi blokiraju datume u kalendaru.

### 5.6 Polja echo detekcije na svakom događaju

Svaki uvezeni događaj sprema:
- `echo_confidence` — broj od 0.0 do 1.0 koji pokazuje koliko je sustav siguran da je echo
- `echo_reason` — čitljivo objašnjenje (npr. "Exact date match; same duration 7 nights; known aggregator source")
- `parent_event_id` — ID originalnog iCal događaja ako je echo drugog uvezenog događaja
- `parent_booking_id` — ID originalne BookBed rezervacije ako je echo vlastite rezervacije

---

## 6. Prednosti BookBed iCal sustava

### 6.1 Za vlasnike nekretnina

1. **Jedan centralni kalendar** — sve rezervacije s Booking.com, Airbnb, Adriagate i drugih platformi na jednom mjestu
2. **Automatska zaštita od duplog bukinga** — filtrirani URL-ovi sprječavaju kružnu sinkronizaciju
3. **Sinkronizacija svakih 15 minuta** — brža od industrijskih standarda (Airbnb sinkronizira svakih 3-6 sati)
4. **Pametna echo detekcija** — automatski prepoznaje duplikate s 95%+ točnošću
5. **Podrška za osobne kalendare** — vlasnik može vidjeti sve rezervacije u Google Calendar, Apple Calendar ili Outlook
6. **Gap block zaštita** — automatski blokira kratke praznine između rezervacija koje ne zadovoljavaju minimalni broj noćenja
7. **Same-day turnover** — podržava odjavu i prijavu na isti dan
8. **GDPR usklađenost** — izvoz ne sadrži osobne podatke gostiju

### 6.2 Prednosti u usporedbi s konkurencijom

BookBed-ov pristup s filtriranim URL-ovima po platformi (`?exclude=`) je napredan — samo Beds24 i OwnerRez nude sličnu funkcionalnost. Većina PMS platformi (Guesty, Lodgify, Hostaway) nudi samo jedan generički URL za sve platforme, što može uzrokovati kružnu sinkronizaciju.

### 6.3 Tehnički standardi

- **RFC 5545 kompatibilnost** — standard koji koriste sve kalendarske aplikacije i booking platforme
- **Timing-safe token provjera** — sprječava timing napade na autentikacijski token
- **ETag / If-None-Match** — optimizacija propusnosti; platforme dohvaćaju samo promjene
- **5-minutni cache** — smanjuje opterećenje na server za česte zahtjeve
- **SSRF zaštita** — blokira opasne URL-ove (localhost, interne IP adrese, cloud metadata)
- **HTTPS zahtjev** — svi iCal URL-ovi moraju koristiti HTTPS (osim rijetkih iznimki)

---

## 7. Mane i ograničenja

### 7.1 Ograničenja iCal protokola

1. **Nema osobnih podataka** — iCal prenosi samo datume, ne imena gostiju, emailove, telefone ili cijene
2. **Nema real-time sinkronizacije** — platforme dohvaćaju feed u intervalima (5 min do 6 sati), ne odmah
3. **Jednosmjerni pull** — iCal je "pull" protokol; BookBed ne može "push-ati" promjene direktno na platforme
4. **Nema potvrde primitka** — BookBed ne zna je li platforma uspješno uvezla feed

### 7.2 Ograničenja platformi

1. **Airbnb sinkronizira sporo** — svakih 3-6 sati, što znači da u tom periodu može doći do dvostrukog bukinga
2. **Neki agregatori re-exportiraju** — Adriagate, Holiday-Home, Atraveo šalju tuđe podatke nazad, što zahtijeva echo detekciju
3. **Holiday-Home kvari datume** — pomak od ~29 dana pri re-exportu (uklonjen iz sinkronizacije)
4. **Adriagate spaja blokove** — susjedne rezervacije spaja u jedan veliki blok, što otežava prepoznavanje

### 7.3 Ograničenja BookBed sustava

1. **Zahtijeva postavljanje feedova** — vlasnik mora ručno unijeti iCal URL za svaku platformu
2. **Minimalni boravak samo iz BookBed-a** — gap blokovi koriste BookBed-ov min-stay; ako platforma ima drugačiji, može doći do nesklada
3. **Containment analiza nije 100% savršena** — ako agregator doda vlastitu rezervaciju u sredinu spojenog bloka, containment analiza to neće preskočiti (što je ispravno ponašanje — ali vlasnik može vidjeti "novu" rezervaciju koja uključuje dane koji su već blokirani)

---

## 8. Česta pitanja (FAQ)

### Uvoz (Import)

**P: Kako povezati Booking.com kalendar?**
O: Prijavite se na Booking.com Extranet → Calendar → Sync calendars → Export calendar → Kopirajte iCal URL → Dodajte ga u BookBed pod iCal Sinkronizacija.

**P: Kako povezati Airbnb kalendar?**
O: Prijavite se na Airbnb → Calendar → Availability Settings → Export calendar → Kopirajte iCal link → Dodajte ga u BookBed pod iCal Sinkronizacija.

**P: Koliko često se sinkronizira?**
O: BookBed automatski sinkronizira svakih 15 minuta. Možete pokrenuti ručnu sinkronizaciju u bilo kojem trenutku.

**P: Hoće li gosti vidjeti imena gostiju s drugih platformi?**
O: Ne. iCal protokol prenosi samo datume rezervacija, ne osobne podatke. Rezervacije se prikazuju kao "Adriagate Gost", "Booking.com Gost" itd.

**P: Mogu li sinkronizirati s više platformi istovremeno?**
O: Da! Možete dodati feedove za Booking.com, Airbnb, Adriagate i bilo koju drugu platformu koja podržava iCal format za isti apartman. Sve rezervacije će biti prikazane.

**P: Što znači "Import isključen"?**
O: Vaše rezervacije su i dalje vidljive toj platformi, ali BookBed ne uvozi njene događaje. Koristite ovo za platforme koje re-exportiraju uvezene podatke i stvaraju duplikate.

**P: Mogu li obrisati uvezene rezervacije?**
O: Da. Kada obrišete feed, sve uvezene rezervacije iz tog feeda se automatski brišu.

### Izvoz (Export)

**P: Mogu li dodati BookBed URL na Booking.com?**
O: Da! Booking.com prihvaća iCal linkove s BookBeda. Idite na Extranet → Calendar → Sync calendars → Add calendar connection → Zalijepite BookBed URL s `?exclude=booking_com` parametrom.

**P: Zašto su različiti URL-ovi za različite platforme?**
O: Svaki URL isključuje rezervacije te platforme kako bi se spriječila kružna sinkronizacija. Booking.com ne treba vidjeti svoje vlastite rezervacije jer ih već ima — treba vidjeti samo tuđe.

**P: Mogu li koristiti generički URL za Booking.com?**
O: Tehnički da, ali to će uzrokovati duplikate. Booking.com bi vidio svoje vlastite rezervacije kao "nove" i mogao bi ih duplo blokirati. Uvijek koristite filtrirani URL za booking platforme.

**P: Generički URL — za što služi?**
O: Za osobne kalendare (Google Calendar, Apple Calendar, Outlook) koji ne re-exportiraju podatke. Prikazuje SVE rezervacije i blokove.

**P: Hoće li obrisane rezervacije biti uklonjene?**
O: Da, otkazane i obrisane rezervacije se automatski uklanjaju iz iCal feeda. Platforme će ih obrisati pri sljedećoj sinkronizaciji.

**P: Je li link siguran?**
O: Link sadrži tajni token i ne bi se trebao dijeliti javno. Svatko s linkom može vidjeti vaš raspored rezervacija (ali ne osobne podatke gostiju).

**P: Što su "Not Available" blokovi u feedu?**
O: To su datumi koje ste ručno blokirali u pricing kalendaru ili automatski generirani gap blokovi (praznine kraće od minimalnog broja noćenja).

### Problemi i rješenja

**P: Booking.com/Airbnb ne prikazuje moje rezervacije?**
O: Provjerite je li iCal URL ispravno zalijepljen. Booking.com sinkronizira svakih 15-60 minuta, Airbnb svakih 3-6 sati. Pokušajte ručno osvježiti kalendar na platformi.

**P: Vidim duplikate u kalendaru?**
O: Provjerite koristite li filtrirani URL (s `?exclude=` parametrom) za booking platforme. Generički URL bez filtera treba se koristiti samo za osobne kalendare.

**P: Adriagate prikazuje krive datume?**
O: Adriagate ne prikazuje krive datume — testirali smo i datumi su ispravni. Međutim, Adriagate spaja susjedne rezervacije u jedan blok, pa se jedan veliki blok može činiti kao nova rezervacija. BookBed automatski prepoznaje ovo kao echo.

**P: Što ako platforma ne razumije gap blokove?**
O: Gap blokovi su standardni iCal format (`VEVENT` sa `TRANSP:OPAQUE`). Ako ih platforma ne razumije, to je problem platforme — BookBed exportira ispravno prema RFC 5545 standardu.

**P: Holiday-Home prikazuje krive datume?**
O: Da, Holiday-Home ima poznati bug koji pomiče datume za ~29 dana. Preporučujemo ne koristiti Holiday-Home za uvoz. Ako trebate da Holiday-Home vidi vašu dostupnost, koristite export-only mod (isključite uvoz za taj feed).

---

## 9. Firestore struktura podataka

### 9.1 iCal Feed (konfiguracija)

Put u Firestore: `properties/{propertyId}/ical_feeds/{feedId}`

| Polje | Tip | Opis |
|-------|-----|------|
| `unit_id` | string | ID smještajne jedinice |
| `property_id` | string | ID nekretnine |
| `platform` | string | `booking_com`, `airbnb`, ili `other` |
| `ical_url` | string | URL iCal feeda |
| `custom_platform_name` | string? | Naziv platforme ako je `other` (npr. "Adriagate") |
| `import_enabled` | boolean | `true` = uvozi rezervacije; `false` = samo export |
| `sync_interval_minutes` | int | Interval sinkronizacije (zadano: 60) |
| `last_synced` | timestamp? | Kada je zadnja sinkronizacija izvršena |
| `status` | string | `active`, `error`, ili `paused` |
| `last_error` | string? | Opis zadnje greške |
| `sync_count` | int | Ukupan broj izvršenih sinkronizacija |
| `event_count` | int | Broj trenutno uvezenih događaja |
| `created_at` | timestamp | Datum kreiranja |
| `updated_at` | timestamp | Datum zadnje promjene |

### 9.2 iCal Event (uvezena rezervacija)

Put u Firestore: `properties/{propertyId}/ical_events/{eventId}`

| Polje | Tip | Opis |
|-------|-----|------|
| `unit_id` | string | ID smještajne jedinice |
| `feed_id` | string | ID feeda iz kojeg je uvezeno |
| `start_date` | timestamp | Datum prijave |
| `end_date` | timestamp | Datum odjave |
| `guest_name` | string | Ime gosta (ili "Gost" ako nije dostupno) |
| `source` | string | Izvor: `booking_com`, `airbnb`, `adriagate`, itd. |
| `external_id` | string | UID iz iCal feeda |
| `description` | string? | Opis iz iCal feeda |
| `status` | string | `active`, `needs_review`, `confirmed_echo`, `confirmed_overbooking` |
| `echo_confidence` | double? | Pouzdanost echo detekcije (0.0-1.0) |
| `echo_reason` | string? | Objašnjenje echo analize |
| `parent_event_id` | string? | ID originalnog iCal događaja |
| `parent_booking_id` | string? | ID originalne BookBed rezervacije |
| `reviewed_at` | timestamp? | Kada je vlasnik pregledao |
| `reviewed_by` | string? | UID vlasnika koji je pregledao |
| `created_at` | timestamp | Datum kreiranja |
| `updated_at` | timestamp | Datum zadnje promjene |

### 9.3 iCal Export Token

Put u Firestore: `properties/{propertyId}/widget_settings/{unitId}`

| Polje | Tip | Opis |
|-------|-----|------|
| `ical_export_token` | string | UUID v4 token za autentikaciju |
| `ical_export_enabled` | boolean | Je li export omogućen |

---

## 10. Tehnički detalji Cloud Functions

### 10.1 getUnitIcalFeed (Export endpoint)

- **URL**: `https://us-central1-{project}.cloudfunctions.net/getUnitIcalFeed/{propertyId}/{unitId}/{token}.ics`
- **Metoda**: GET
- **Parametri**: `?exclude={source}` (opcionalno)
- **Cache**: 5 minuta (ETag/If-None-Match podrška)
- **Limiti**: max 500 bookinga, max 500 iCal događaja, max 1000 blokiranih dana
- **Vremenski raspon**: 90 dana u prošlost, 365 dana u budućnost
- **Timezone**: Europe/Zagreb
- **Prazan kalendar**: generira placeholder VEVENT (Booking.com zahtjev)

### 10.2 scheduledIcalSync (Automatska sinkronizacija)

- **Raspored**: svakih 15 minuta
- **Obrada**: sekvencijalna s 1-sekundnom pauzom između feedova
- **Timeout HTTP zahtjeva**: 30 sekundi
- **Max preusmjeravanja**: 5
- **Validacija**: URL mora vraćati sadržaj koji sadrži `BEGIN:VCALENDAR`
- **SSRF zaštita**: blokirani localhost, interne IP adrese, cloud metadata endpointi

### 10.3 syncIcalFeedNow (Ručna sinkronizacija)

- **Tip**: Callable Cloud Function (zahtijeva autentikaciju)
- **Validacija**: provjerava da vlasnik posjeduje nekretninu
- **Preskače**: feedove s isključenim uvozom (`import_enabled: false`)
- **Odgovor**: `{bookingsCreated, skippedEchoes, flaggedForReview}`

---

## 11. Važne timezone napomene

### Problem s datumima

Firestore sprema datume kao UTC Timestamp. Kad se BookBed koristi u Hrvatskoj (UTC+1/UTC+2), midnight u Zagrebu = 23:00/22:00 prethodnog dana u UTC. Ovo uzrokuje pomak -1 dan ako se koristi naivni `getUTCDate()`.

### Rješenje

Export koristi `truncateTime()` funkciju koja dodaje 12 sati prije ekstrakcije datuma:
- Primjer: `May 28, 00:00 UTC+2` → JS Date: `May 27, 22:00 UTC` → +12h → `May 28, 10:00 UTC` → `getUTCDate()` = 28 ✅
- Radi za bilo koji timezone od UTC-12 do UTC+14

Email sustav koristi `timeZone: "Europe/Zagreb"` parametar u `toLocaleDateString()` koji automatski konvertira UTC u lokalno vrijeme.

---

## 12. Glossar

| Termin | Objašnjenje |
|--------|-------------|
| **iCal** | Internet Calendar format (RFC 5545) — standard za razmjenu kalendarskih podataka |
| **VEVENT** | Jedan događaj unutar iCal feeda (rezervacija, blokiran dan, itd.) |
| **DTSTART** | Datum početka događaja (check-in) |
| **DTEND** | Datum kraja događaja (check-out) — ekskluzivan (taj dan je slobodan) |
| **TRANSP:OPAQUE** | Događaj blokira vrijeme (za razliku od TRANSPARENT koji ne blokira) |
| **Hub-and-spoke** | Arhitektura gdje centralni sustav (BookBed) komunicira sa svim platformama |
| **Echo** | Duplikat rezervacije nastao kružnom sinkronizacijom |
| **Agregator** | Platforma koja re-exportira uvezene podatke (npr. Adriagate) |
| **Autoritativna** | Platforma koja exportira samo vlastite podatke (npr. Booking.com) |
| **Containment** | Analiza koja provjerava pokriva li jedan veliki blok više manjih rezervacija |
| **Gap block** | Automatski blokirana praznina između rezervacija kraća od min-stay |
| **Min-stay** | Minimalni broj noćenja koji gost mora rezervirati |
| **Same-day turnover** | Mogućnost odjave i prijave na isti dan |
| **Export-only mod** | Feed koji šalje podatke platformi ali ne uvozi natrag |
| **`?exclude=`** | URL parametar koji isključuje rezervacije određene platforme iz feeda |
