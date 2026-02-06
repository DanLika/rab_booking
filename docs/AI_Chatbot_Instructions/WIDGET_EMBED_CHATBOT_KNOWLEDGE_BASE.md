# BookBed Widget ugradnja — Kompletna baza znanja za AI chatbot

## 1. Pregled sustava

BookBed **Widget** je booking kalendar koji se ugrađuje na web stranicu vlasnika nekretnine putem `<iframe>` HTML elementa. Gosti na toj stranici mogu pregledavati dostupnost, odabirati datume i kreirati rezervaciju — sve bez napuštanja vlasnikove web stranice.

Widget je zasebna web aplikacija hostana na `view.bookbed.io` domeni. Vlasnik kopira gotov `<iframe>` kod iz Owner Dashboard-a i zalijepi ga u HTML svoje web stranice. Nikakva dodatna konfiguracija na strani web stranice nije potrebna.

---

## 2. Testiranje widgeta prije ugradnje

### 2.1 Zašto testirati prije ugradnje?

Prije lijepljenja embed koda na web stranicu, vlasnik bi trebao:
- Provjeriti da widget ispravno prikazuje kalendar i dostupnost
- Potvrditi da su cijene, minimalni boravak i ostale postavke ispravne
- Testirati booking flow (ako je omogućen) da vidi kako gost doživljava proces

### 2.2 Kako testirati — Demo link (Live Preview)

U Owner Dashboard-u na stranici **Embed Widget Guide** postoji sekcija **"Test Widget"** s opcijom Live Preview:

1. Odlazite na **Embed Widget Guide** (iz navigacijskog izbornika)
2. U sekciji "Test Widget" odabirete smještajnu jedinicu iz padajućeg izbornika
3. Kliknete **"Preview Live"** — otvara se nova kartica preglednika s vašim widgetom
4. Widget se prikazuje točno onako kako će ga vidjeti gosti na vašoj web stranici

**URL koji se otvara ima format:**
```
https://view.bookbed.io/?property={PROPERTY_ID}&unit={UNIT_ID}
```

Taj link možete slobodno dijeliti s kolegama ili web developerom za provjeru prije ugradnje.

### 2.3 Što provjeriti tijekom testiranja?

| Provjera | Gdje pogledati |
|----------|----------------|
| Kalendar prikazuje ispravnu dostupnost | Zeleni datumi = slobodno, crveni = zauzeto |
| Cijene po noćenju su ispravne | Vidljive u kalendaru (hover na desktopu, direktno na mobitelu) |
| Vikend cijene (ako su različite) | Petkom i subotom trebala bi se prikazivati viša cijena |
| Blokirani datumi su označeni | Ručno blokirani dani prikazani kao nedostupni |
| Minimalni boravak funkcionira | Pokušajte odabrati manje noći od minimuma — trebala bi se pojaviti poruka |
| Booking forma se prikazuje (ako je omogućena) | Nakon odabira datuma, trebala bi se pojaviti forma za unos podataka gosta |
| Metode plaćanja su ispravne | Stripe, bankovni prijenos ili plaćanje na lokaciji — prema vašim postavkama |
| Kontakt podaci (calendar-only mod) | Ako koristite samo kalendar, provjerite da su prikazani ispravni kontakt podaci |
| Mobilni prikaz | Otvorite link na mobitelu — widget se automatski prilagođava veličini ekrana |

### 2.4 Slug URL za testiranje (čisti linkovi)

Ako imate postavljenu subdomenu za nekretninu i slug za jedinicu, možete koristiti čisti URL format:
```
https://{subdomena}.view.bookbed.io/{slug-jedinice}
```

Primjer:
```
https://jasko-rab.view.bookbed.io/apartman-6
```

Ovaj format je pogodniji za dijeljenje na društvenim mrežama, u emailovima i oglasima jer je kraći i čitljiviji.

### 2.5 Razlika između demo linka i ugrađenog widgeta

Demo link otvara widget na cijeloj stranici (fullscreen). Kad se widget ugradi u iframe na vašoj web stranici, prikazuje se unutar okvira koji ste definirali u embed kodu. Funkcionalno su identični — isti kalendar, iste cijene, isti booking flow.

---

## 3. Ugradnja widgeta na web stranicu

### 3.1 Gdje pronaći embed kod?

1. Prijavite se u **Owner Dashboard** (`app.bookbed.io`)
2. Otvorite **Embed Widget Guide** iz navigacijskog izbornika
3. Skrolajte do sekcije **"Your Embed Codes"**
4. Za svaku smještajnu jedinicu vidjet ćete gotov `<iframe>` kod
5. Kliknite **"Copy"** da kopirate kod u međuspremnik

### 3.2 Kako izgleda embed kod?

```html
<iframe
  src="https://view.bookbed.io/?property=ABC123&unit=XYZ789&embed=true"
  style="width: 100%; border: none; aspect-ratio: 1/1.4; min-height: 500px; max-height: 850px;"
  title="Apartman 6"
></iframe>
```

### 3.3 Objašnjenje parametara

| Parametar | Značenje |
|-----------|----------|
| `src` | URL widgeta — **NE MIJENJATI!** Sadrži identifikatore vaše nekretnine i jedinice |
| `style="width: 100%"` | Widget zauzima punu širinu roditeljskog elementa |
| `border: none` | Bez okvira oko iframe-a |
| `aspect-ratio: 1/1.4` | Omjer širine i visine (kalendar + forma) |
| `min-height: 500px` | Minimalna visina — da widget bude upotrebljiv i na manjim ekranima |
| `max-height: 850px` | Maksimalna visina — sprječava preveliki widget na velikim ekranima |
| `title` | Naziv jedinice — za pristupačnost (screen readere) |

### 3.4 Gdje zalijepiti kod?

Embed kod se lijepi u HTML izvorni kod vaše web stranice, na mjesto gdje želite da se widget prikaže. Primjeri:

**WordPress:**
1. Uredite stranicu/post
2. Dodajte **Custom HTML** blok (u Gutenberg editoru)
3. Zalijepite embed kod
4. Objavite/ažurirajte stranicu

**Wix:**
1. Uredite stranicu
2. Dodajte **Embed HTML** element
3. Zalijepite embed kod
4. Prilagodite veličinu elementa

**Squarespace:**
1. Uredite stranicu
2. Dodajte **Code** blok
3. Zalijepite embed kod
4. Objavite

**Čisti HTML (ručno):**
```html
<div style="max-width: 800px; margin: 0 auto;">
  <iframe
    src="https://view.bookbed.io/?property=ABC123&unit=XYZ789&embed=true"
    style="width: 100%; border: none; aspect-ratio: 1/1.4; min-height: 500px; max-height: 850px;"
    title="Apartman 6"
  ></iframe>
</div>
```

### 3.5 Koliko widgeta mogu ugraditi?

Nema ograničenja. Možete ugraditi zasebni widget za svaku smještajnu jedinicu. Svaki widget ima vlastiti embed kod s jedinstvenim `property` i `unit` identifikatorima.

Primjer: Ako imate 3 apartmana, možete na svojoj stranici imati 3 zasebna widgeta — svaki prikazuje kalendar i booking formu za svoj apartman.

---

## 4. Prilagodba widgeta (za developere)

### 4.1 Što se može prilagoditi u CSS-u iframe-a?

Vlasnik ili developer može prilagoditi **samo vanjski izgled iframe-a** (ne sadržaj unutar njega):

| Svojstvo | Primjer | Napomena |
|----------|---------|----------|
| Širina | `width: 600px;` ili `width: 100%;` | Responzivno: 100% preporučeno |
| Visina | `height: 800px;` | Ako ne koristite `aspect-ratio` |
| Zaobljeni rubovi | `border-radius: 8px;` | Zaobljuje kutove iframe-a |
| Okvir | `border: 1px solid #ccc;` | Dodaje okvir oko widgeta |
| Sjena | `box-shadow: 0 2px 10px rgba(0,0,0,0.1);` | Daje dubinu |
| Responzivnost | `width: 100%; height: 100vh;` | Prilagođava se ekranu |

### 4.2 Što se NE smije mijenjati?

**`src` URL se nikada ne smije mijenjati!** On sadrži:
- `property=` — identifikator vaše nekretnine
- `unit=` — identifikator smještajne jedinice
- `embed=true` — signal widgetu da radi u iframe modu

Promjena bilo kojeg od ovih parametara može uzrokovati da widget ne radi ili prikaže pogrešnu jedinicu.

### 4.3 Napredni URL parametri (opcionalno)

Za napredno korištenje, mogu se dodati dodatni parametri u `src` URL:

| Parametar | Vrijednosti | Opis |
|-----------|-------------|------|
| `language` | `en`, `hr`, `de`, `it` | Forsiraj jezik widgeta (inače koristi jezik preglednika) |
| `theme` | `light`, `dark`, `system` | Forsiraj temu (inače prati sistem) |

Primjer:
```
https://view.bookbed.io/?property=ABC&unit=XYZ&embed=true&language=en&theme=light
```

---

## 5. Widget modovi (3 načina rada)

Vlasnik u postavkama widgeta (Widget Settings u Owner Dashboard-u) bira jedan od tri moda:

### 5.1 Samo kalendar (`calendarOnly`)

- Widget prikazuje **samo kalendar dostupnosti** i kontakt informacije vlasnika
- Gost **ne može** kreirati rezervaciju kroz widget — mora kontaktirati vlasnika telefonom, emailom ili WhatsApp-om
- Korisno za vlasnike koji preferiraju osobni kontakt s gostima

**Gost vidi:** Kalendar + kontakt dugmad (telefon, email, WhatsApp)

### 5.2 Rezervacija bez plaćanja (`bookingPending`)

- Widget prikazuje kalendar + **booking formu** (bez metoda plaćanja)
- Gost popuni podatke i pošalje zahtjev za rezervaciju
- Rezervacija se kreira sa statusom **"pending"** — vlasnik mora ručno odobriti
- Plaćanje se dogovara privatno (bankovni prijenos, gotovina pri dolasku, itd.)

**Gost vidi:** Kalendar + forma (ime, email, telefon, broj gostiju, napomene)

### 5.3 Puna rezervacija s plaćanjem (`bookingInstant`)

- Widget prikazuje kalendar + booking formu + **opcije plaćanja**
- Gost odabire metodu plaćanja (kartica putem Stripe, bankovni prijenos, ili plaćanje pri dolasku)
- Za Stripe plaćanja: gost je preusmjeren na Stripe Checkout stranicu
- Rezervacija se automatski potvrđuje nakon uspješnog plaćanja

**Gost vidi:** Kalendar + forma + odabir plaćanja + prikaz cijene s depozitom

**Dostupne metode plaćanja:**
| Metoda | Opis |
|--------|------|
| **Stripe (kartica)** | Gost plaća online karticom — preusmjeravanje na Stripe Checkout |
| **Bankovni prijenos** | Gost dobiva podatke za uplatu (IBAN, rok plaćanja, QR kod) |
| **Plaćanje pri dolasku** | Gost ne plaća unaprijed — plaća na lokaciji |

---

## 6. Što gost vidi u widgetu?

### 6.1 Kalendar dostupnosti

- **Zeleni datumi** = slobodno za rezervaciju
- **Crveni datumi** = zauzeto (rezervirano)
- **Narančasti datumi** = čekanje (pending rezervacija)
- **Sivi/blokirani datumi** = ručno blokirano od strane vlasnika
- **Cijene** su prikazane na svakom datumu (posebno za vikend ako je cijena viša)

### 6.2 Booking forma (bookingPending i bookingInstant modovi)

Gost popunjava:
1. **Ime i prezime** (obavezno)
2. **Email adresa** (obavezno)
3. **Telefonski broj** s pozivnim brojem države (obavezno)
4. **Broj gostiju** (od 1 do maksimalnog kapaciteta jedinice)
5. **Napomene** (opcionalno — posebni zahtjevi, kasni dolazak, itd.)
6. **Dodatne usluge** (ako ih vlasnik nudi — npr. ručnici, čišćenje, transfer)
7. **Metoda plaćanja** (samo u bookingInstant modu)

### 6.3 Prikaz cijene

Widget automatski izračunava i prikazuje:
- Cijena po noćenju (razlikuje radne dane i vikend)
- Ukupna cijena za odabrani period
- Dodatne usluge (ako su odabrane)
- Iznos depozita (postotak ukupne cijene koji vlasnik definira)
- Preostali iznos za plaćanje

### 6.4 Potvrda rezervacije

Nakon uspješne rezervacije, gost vidi:
- Potvrdnu stranicu s detaljima rezervacije
- Referencu za praćenje (format: `BK-XXXXXXXXXXXX`)
- Kontakt podatke vlasnika
- Upute za plaćanje (ako je odabran bankovni prijenos)

Gost također prima email potvrdu s istim informacijama.

---

## 7. Responzivni prikaz

Widget se automatski prilagođava veličini ekrana/iframe-a:

| Veličina ekrana | Prikaz kalendara | Booking forma |
|-----------------|------------------|---------------|
| **Mobitel** (<600px) | Mjesečni kalendar, jedan stupac | Ispod kalendara, jedan stupac |
| **Tablet** (600-1199px) | Višemjesečni pregled | Ispod kalendara, prilagođen razmak |
| **Desktop** (≥1200px) | Godišnji pregled s višemjesečnom mrežom | Pored kalendara (side-by-side) |

Widget funkcionira na svim modernim preglednicima: Chrome, Safari, Firefox, Edge — uključujući mobilne verzije.

---

## 8. Domene i URL struktura

### 8.1 Domena widgeta

Svi widgeti su hostani na **`view.bookbed.io`** domeni. Ovo je potpuno odvojeno od Owner Dashboard-a (`app.bookbed.io`).

### 8.2 Dva formata URL-a

**Format 1: Query parametri** (koristi se u iframe embed kodovima)
```
https://view.bookbed.io/?property=PROPERTY_ID&unit=UNIT_ID&embed=true
```
- Univerzalan — radi uvijek, bez dodatne konfiguracije
- Property i Unit ID-evi su dovoljni za identifikaciju

**Format 2: Subdomena + slug** (za dijeljive linkove)
```
https://jasko-rab.view.bookbed.io/apartman-6
```
- Zahtijeva konfiguriranu subdomenu na nekretnini i slug na jedinici
- Čišći i čitljiviji URL za dijeljenje na društvenim mrežama i u oglasima
- Subdomena se postavlja u postavkama nekretnine (Property Settings)
- Slug se automatski generira iz naziva jedinice (može se ručno promijeniti)

### 8.3 Booking View URL (za pregled rezervacije)

Gosti koji prime email potvrdu mogu pregledati svoju rezervaciju na:
```
https://view.bookbed.io/view?ref=BK-XXXXXXXXXXXX&email=gost@email.com
```

---

## 9. Sigurnost i privatnost

### 9.1 Embed kod je siguran

- Widget se učitava preko **HTTPS** (šifrirana veza)
- Iframe sandboxing: widget ne može pristupiti sadržaju roditeljske stranice i obrnuto
- Svi podaci (rezervacije, osobni podaci) prolaze kroz šifrirani kanal do BookBed servera

### 9.2 Osobni podaci gostiju

- Osobni podaci gostiju (ime, email, telefon) su pohranjeni na BookBed serverima, ne na web stranici vlasnika
- Podaci se koriste isključivo za komunikaciju vezanu uz rezervaciju
- Vlasnik vidi podatke gostiju u svom Owner Dashboard-u

### 9.3 `embed=true` parametar

Ovaj parametar signalizira widgetu da radi unutar iframe-a. Kada je postavljen:
- Widget prilagođava layout za iframe okruženje
- Šalje poruku roditeljskom prozoru o promjeni visine (za automatsko prilagođavanje iframe visine)
- Ne prikazuje elemente koji su relevantni samo za fullscreen prikaz

---

## 10. Česta pitanja (FAQ)

### Testiranje

**P: Kako mogu testirati widget prije ugradnje na svoju stranicu?**
O: U Owner Dashboard-u otvorite Embed Widget Guide → odaberite smještajnu jedinicu → kliknite "Preview Live". Widget se otvara u novoj kartici preglednika, točno onako kako će ga vidjeti gosti.

**P: Mogu li podijeliti demo link s web developerom?**
O: Da! Kopirajte URL iz adresne trake preglednika nakon što kliknete "Preview Live" i pošaljite ga developeru. URL format: `https://view.bookbed.io/?property=ABC&unit=XYZ`

**P: Zašto demo link prikazuje krive cijene?**
O: Widget čita cijene iz BookBed-ovih postavki u realnom vremenu. Provjerite jesu li cijene ispravno postavljene u Cjenovniku (Pricing Calendar) u Owner Dashboard-u.

**P: Mogu li testirati rezervaciju bez pravog plaćanja?**
O: Da, koristite mod "Rezervacija bez plaćanja" (bookingPending) za testiranje. Rezervacija se kreira bez plaćanja i možete je ručno obrisati nakon testiranja.

### Ugradnja

**P: Trebam li znati programirati da ugradim widget?**
O: Ne. Kopirajte embed kod iz BookBed-a i zalijepite ga u Custom HTML blok na vašoj web stranici (WordPress, Wix, Squarespace, itd.). Nije potrebno znanje programiranja.

**P: Hoće li widget raditi na mobilnim uređajima?**
O: Da! Widget je potpuno responzivan — automatski se prilagođava veličini ekrana, bilo da je to mobitel, tablet ili desktop računar.

**P: Mogu li ugraditi widget za više apartmana na jednu stranicu?**
O: Da. Za svaki apartman kopirate zaseban embed kod i zalijepite ga na željeno mjesto. Svaki widget radi neovisno.

**P: Widget ne prikazuje ništa / prikazuje bijeli ekran?**
O: Provjerite sljedeće:
1. Jeste li kopirali cijeli embed kod (uključujući `<iframe>` i `</iframe>`)?
2. Je li `src` URL neoštećen? Ne smijete mijenjati property/unit identifikatore.
3. Imate li aktivnu internetsku vezu?
4. Pokušajte otvoriti `src` URL direktno u pregledniku — ako radi tamo ali ne u iframe-u, problem je u vašoj web stranici (moguća Content Security Policy restrikcija).

**P: Mogu li promijeniti veličinu widgeta?**
O: Da. Prilagodite `style` atribut u iframe kodu. Primjeri:
- Fiksna visina: `style="width: 100%; height: 800px; border: none;"`
- Manja širina: `style="width: 600px; height: 900px; border: none; margin: 0 auto; display: block;"`
- Zaobljeni rubovi: dodajte `border-radius: 12px; overflow: hidden;` na wrapper `<div>`

**P: Mogu li ugraditi widget u WordPress stranicu s Elementorom?**
O: Da. Koristite **HTML** widget u Elementoru. Zalijepite embed kod i prilagodite veličinu kroz Elementor sučelje.

**P: Widget je prespor / dugo se učitava?**
O: Widget koristi progresivno učitavanje — skeleton kalendar se prikazuje odmah dok se podaci dohvaćaju s servera (obično 2-4 sekunde). Ako je stalno spor, provjerite internetsku vezu ili kontaktirajte podršku.

### Konfiguracija

**P: Kako promijeniti mod widgeta (samo kalendar / rezervacija / plaćanje)?**
O: U Owner Dashboard-u otvorite **Widget Settings** za željenu smještajnu jedinicu. Odaberite jedan od tri moda i spremite. Promjena se automatski primjenjuje — nije potrebno mijenjati embed kod.

**P: Kako omogućiti Stripe plaćanje?**
O: 1. U Owner Dashboard-u otvorite **Stripe Integration** i povežite Stripe račun. 2. U Widget Settings omogućite Stripe opciju. 3. Widget će automatski prikazati opciju plaćanja karticom.

**P: Mogu li promijeniti jezik widgeta?**
O: Widget automatski koristi jezik preglednika gosta. Ako želite forsirati određeni jezik, dodajte `&language=hr` (ili `en`, `de`, `it`) na kraj `src` URL-a u embed kodu. Podržani jezici: engleski, hrvatski, njemački, talijanski.

**P: Moram li mijenjati embed kod kad promijenim postavke?**
O: Ne! Sve promjene u postavkama widgeta (mod, cijene, metode plaćanja, minimalni boravak) se automatski primjenjuju. Embed kod ostaje isti — samo ga jednom zalijepite na stranicu.

**P: Kako postaviti subdomenu za čiste URL-ove?**
O: U Owner Dashboard-u otvorite postavke nekretnine (Property Settings) → unesite željenu subdomenu (npr. `jasko-rab`). Subdomena mora biti 3-30 znakova, samo mala slova, brojevi i crtice. Nakon postavljanja, widget je dostupan na `vaša-subdomena.view.bookbed.io`.

### Plaćanje i rezervacije

**P: Što se dogodi nakon što gost rezervira?**
O: Ovisi o modu:
- **Samo kalendar**: Gost kontaktira vlasnika telefonom/emailom — widget ne kreira rezervaciju
- **Bez plaćanja**: Rezervacija se kreira kao "pending" → vlasnik prima obavijest → vlasnik odobrava ili odbija
- **S plaćanjem (Stripe)**: Gost plaća online → rezervacija se automatski potvrđuje → oboje primaju email potvrdu
- **S plaćanjem (bankovni prijenos)**: Rezervacija se kreira kao "pending" → gost prima upute za uplatu → vlasnik ručno potvrđuje nakon primitka uplate

**P: Može li gost otkazati rezervaciju?**
O: Da, ako je vlasnik omogućio otkazivanje u Widget Settings-u. Gost može otkazati putem linka u emailu potvrde, do roka koji je vlasnik postavio (npr. 48 sati prije prijave).

**P: Što ako se dva gosta pokušaju rezervirati isti termin?**
O: BookBed automatski blokira datume čim se kreira rezervacija (čak i "pending" rezervacija blokira datume). Drugi gost će vidjeti te datume kao zauzete u kalendaru. Nema mogućnosti dvostruke rezervacije unutar BookBed sustava.

---

## 11. Ograničenja widgeta

### 11.1 Što widget NE može

1. **Prikazivati slike apartmana** — widget prikazuje samo kalendar i booking formu
2. **Upravljati cijenama** — cijene se postavljaju isključivo u Owner Dashboard-u
3. **Slati poruke između gosta i vlasnika** — komunikacija ide putem emaila/telefona
4. **Raditi bez internetske veze** — widget zahtijeva aktivnu vezu za dohvaćanje podataka
5. **Prikazivati se na starim preglednicima** — zahtijeva moderan preglednik (Chrome 80+, Safari 14+, Firefox 78+, Edge 80+)

### 11.2 Poznata ograničenja

- **Content Security Policy (CSP)**: Neke web stranice imaju stroge CSP postavke koje blokiraju iframe-ove s vanjskih domena. U tom slučaju, web developer mora dodati `view.bookbed.io` u `frame-src` direktivu.
- **iOS Safari keyboard fix**: Na iOS Safari, kada se tastatura zatvori, layout se ponekad ne recalculate pravilno. BookBed ima ugrađen fix za ovo, ali može se pojaviti kratko treperenje.
- **Airbnb stil sinkronizacije**: Ako se widget koristi zajedno s iCal sinkronizacijom, promjene dostupnosti s Airbnb-a mogu kasniti 3-6 sati (Airbnb-ovo ograničenje, ne BookBed-ovo).

---

## 12. Koraci za potpunu ugradnju — sažetak

1. **Postavite nekretninu i smještajne jedinice** u Owner Dashboard-u
2. **Postavite cijene** u Cjenovniku (Pricing Calendar)
3. **Odaberite mod widgeta** u Widget Settings (samo kalendar / bez plaćanja / s plaćanjem)
4. **Konfigurirajte plaćanje** (ako koristite bookingInstant mod): Stripe, bankovni prijenos, ili oboje
5. **Testirajte widget** — Embed Widget Guide → Preview Live → provjerite sve stavke iz sekcije 2.3
6. **Kopirajte embed kod** — Embed Widget Guide → Your Embed Codes → Copy
7. **Zalijepite na web stranicu** — u Custom HTML blok na vašoj stranici
8. **Gotovo!** — Svaka promjena u postavkama automatski se primjenjuje na widget

---

## 13. Glossar

| Termin | Objašnjenje |
|--------|-------------|
| **Widget** | Booking kalendar koji se ugrađuje na web stranicu vlasnika putem iframe-a |
| **Iframe** | HTML element koji ugrađuje jednu web stranicu unutar druge |
| **Embed kod** | Gotov HTML kod koji vlasnik kopira i lijepi na svoju web stranicu |
| **Owner Dashboard** | Administratorsko sučelje na `app.bookbed.io` gdje vlasnik upravlja nekretninama |
| **view.bookbed.io** | Domena na kojoj je hostan widget — svi widget URL-ovi počinju s njom |
| **Property ID** | Jedinstveni identifikator nekretnine u BookBed sustavu |
| **Unit ID** | Jedinstveni identifikator smještajne jedinice (apartman, soba) |
| **Subdomena** | Personalizirani prefiks na domeni, npr. `jasko-rab` u `jasko-rab.view.bookbed.io` |
| **Slug** | Čitljivi dio URL-a za jedinicu, npr. `apartman-6` u `jasko-rab.view.bookbed.io/apartman-6` |
| **Widget mod** | Način rada widgeta: samo kalendar, bez plaćanja, ili s plaćanjem |
| **Pending** | Status rezervacije koja čeka odobrenje vlasnika |
| **Confirmed** | Status potvrđene rezervacije |
| **Depozit** | Postotak ukupne cijene koji gost plaća unaprijed (konfigurira vlasnik) |
| **Stripe** | Online platforma za procesiranje kartičnih plaćanja |
| **Preview Live** | Funkcija u Owner Dashboard-u za testiranje widgeta prije ugradnje |
| **CSP** | Content Security Policy — sigurnosna politika web preglednika koja kontrolira što iframe može učitavati |
