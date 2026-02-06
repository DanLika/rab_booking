# BookBed Plaćanja — Kompletna baza znanja za AI chatbot

## 1. Pregled sustava plaćanja

BookBed podržava **tri metode plaćanja** za goste koji rezerviraju putem booking widgeta:

| Metoda | Opis | Automatska potvrda? |
|--------|------|---------------------|
| **Stripe (kartica)** | Online plaćanje kreditnom/debitnom karticom | Da — nakon uspješnog plaćanja |
| **Bankovni prijenos** | Gost manualno uplati na IBAN vlasnika | Ne — vlasnik mora potvrditi primitak |
| **Plaćanje pri dolasku** | Bez unaprijed plaćanja, gost plaća na lokaciji | Ne — vlasnik ručno potvrđuje |

Vlasnik može omogućiti **jednu, dvije ili sve tri metode** — gost bira pri rezervaciji.

---

## 2. Postavljanje plaćanja (za vlasnika)

### 2.1 Stripe Connect — Kartično plaćanje

**Što je Stripe Connect?**
Stripe Connect omogućava vlasnicima primanje kartičnih plaćanja direktno na svoj Stripe račun. Novac ide **izravno vlasniku**, ne kroz BookBed.

**Koraci za postavljanje:**
1. Otvorite **Owner Dashboard → Integracije → Stripe**
2. Kliknite **"Poveži Stripe račun"**
3. Sustav vas preusmjerava na Stripe stranicu za identifikaciju
4. Ispunite Stripe verifikaciju (osobni podaci, adresa, dokument)
5. Po završetku vraćate se u BookBed dashboard
6. Status se mijenja u **"Povezano — Aktivno"**

**Uvjeti za aktivaciju:**
- Vlasnik mora završiti Stripe identifikacijsku verifikaciju
- Stripe račun mora imati aktivne mogućnosti za naplatu (`charges_enabled`)
- Podržane kartice: Visa, Mastercard, American Express, i ostale

**Konfiguracija (po smještajnoj jedinici):**
- **Postotak depozita**: 0–100% (zadano: 20%)
  - Primjer: 20% = gost plaća 20% unaprijed, 80% pri dolasku
  - 100% = gost plaća cijeli iznos unaprijed
- **Uključi/Isključi**: prekidač za aktivaciju Stripe-a na pojedinoj jedinici

**Prekid veze:**
- Vlasnik može odspojiti Stripe u bilo kojem trenutku
- Stripe račun i dalje postoji — vlasnik ga može koristiti neovisno
- Odspajanje samo uklanja vezu s BookBed-om

**Stripe naknade:**
- Stripe naplaćuje: **1,4% + €0,25** po transakciji
- Naknada se **odbija od vlasnikove isplate**, NE dodaje se gostu
- Primjer: gost plati €170 → vlasnik primi €167,73

---

### 2.2 Bankovni prijenos

**Što je?**
Gost dobiva podatke bankovnog računa vlasnika i manualno izvršava uplatu. Vlasnik potvrđuje primitak u dashboardu.

**Koraci za postavljanje:**
1. Otvorite **Owner Dashboard → Profil → Bankovni račun**
2. Unesite podatke:
   - **Naziv banke** (npr. "Erste Bank")
   - **Vlasnik računa** (ime i prezime na računu)
   - **IBAN** (obavezan — za nacionalne i međunarodne transfere)
   - **SWIFT/BIC** (opcionalan — za međunarodne transfere)
3. Spremite

**Konfiguracija (po smještajnoj jedinici):**

| Opcija | Opis | Zadano |
|--------|------|--------|
| **Postotak depozita** | Koliko gost plaća unaprijed (0–100%) | 20% |
| **Rok za uplatu** | Koliko dana gost ima za uplatu (1–14 dana) | 7 dana |
| **EPC QR kod** | Gost skenira QR kod mobilnom bankovnom aplikacijom | Uključen |
| **Prilagođene upute** | Vlastita poruka vlasniku uz upute za uplatu (do 500 znakova) | Prazno |

**Rok za uplatu:**
- Konfigurirabilan: 1–14 dana od kreiranja rezervacije
- Ako gost ne uplati u roku, **rezervacija se automatski otkazuje** i datumi se oslobađaju

---

### 2.3 Plaćanje pri dolasku

**Što je?**
Gost rezervira bez ikakve unaprijed uplate. Vlasnik i gost dogovaraju plaćanje privatno (gotovina, POS terminal na lokaciji, itd.).

**Postavljanje:** Nije potrebno — uvijek dostupno kao opcija.

**Ponašanje:**
- Sve rezervacije idu u status **"Čekanje"**
- Vlasnik ručno pregledava i potvrđuje svaku rezervaciju
- BookBed **ne prati** je li plaćanje izvršeno ovom metodom

---

## 3. Tijek plaćanja (gostova perspektiva)

### 3.1 Stripe (kartično) plaćanje — korak po korak

1. Gost odabere datume na kalendaru widgeta
2. Popuni formu za rezervaciju (ime, email, telefon, broj gostiju)
3. Odabere **"Kartica"** kao metodu plaćanja
4. Odabere opciju:
   - **"Depozit"** (npr. 20% cijene) — zadana opcija
   - **"Puna uplata"** (100% cijene)
5. Klikne **"Nastavi na plaćanje"**
6. **Privremena rezervacija se kreira** (status: čekanje)
   - Datumi se **odmah blokiraju** na kalendaru
   - Sprječava da drugi gost rezervira iste datume
   - Istječe za 15 minuta ako se plaćanje ne dovrši
7. Gost je **preusmjeren na Stripe Checkout** stranicu
   - Sigurna Stripe stranica (PCI Level 1 certificirana)
   - BookBed **nikada ne vidi** podatke kartice
   - Prikazani: naziv nekretnine/jedinice, iznos za naplatu
8. Gost unese podatke kartice i plati
9. **Uspješno plaćanje:**
   - Stripe šalje potvrdu BookBed-u (webhook)
   - Rezervacija se automatski **potvrđuje** (status: potvrđena)
   - Gost prima email **"Rezervacija potvrđena"**
   - Vlasnik prima email **"Nova rezervacija"**
   - Gost vidi ekran potvrde u widgetu
10. **Neuspješno plaćanje:**
    - Gost vidi Stripe poruku o grešci
    - Privremena rezervacija se briše nakon 15 minuta
    - Datumi postaju ponovo slobodni
    - Gost može pokušati ponovno

**Minimalni iznos:** Stripe zahtijeva minimum **€0,50** — ako je depozit manji, sustav ga automatski prilagođava na €0,50.

---

### 3.2 Bankovni prijenos — korak po korak

1. Gost odabere datume na kalendaru widgeta
2. Popuni formu za rezervaciju
3. Odabere **"Bankovni prijenos"** kao metodu plaćanja
4. Odabere opciju: Depozit ili Puna uplata
5. Klikne **"Nastavi na bankovni prijenos"**
6. **Rezervacija se kreira** (status: čekanje)
   - Datumi se blokiraju na kalendaru
   - Rok za uplatu se postavlja (npr. 7 dana)
7. Gost vidi **ekran s uputama za uplatu**:

   | Podatak | Primjer |
   |---------|---------|
   | Naziv banke | Erste Bank |
   | Vlasnik računa | Ivan Horvat |
   | IBAN | HR12 3456 7890 1234 56789 |
   | SWIFT/BIC | ESPCHR2X |
   | Referenca plaćanja | BK-2026-001234 |
   | Iznos za uplatu | €34,00 (depozit 20%) |
   | Rok za uplatu | 13. veljače 2026. |
   | QR kod | Za skeniranje mobilnom bankovnom aplikacijom |

   - IBAN i SWIFT se mogu **kopirati** jednim klikom
   - Referenca plaćanja se **mora navesti** u opisu naloga
   - QR kod (ako je omogućen) automatski popunjava IBAN, iznos i referencu u bankovnoj aplikaciji

8. Gost prima email s istim uputama za uplatu
9. Gost **manualno izvršava uplatu** putem banke (izvan BookBed-a)
10. Vlasnik provjerava bankovni račun i **potvrđuje primitak** u dashboardu
11. Status se mijenja u **"Potvrđena"** → gost prima email potvrde

**Ako gost ne uplati u roku:**
- **Dan 6**: sustav šalje automatski **email podsjetnik** za uplatu
- **Dan 7** (ili konfigurirani rok): rezervacija se **automatski otkazuje**
- Datumi postaju slobodni za druge goste
- Gost NE prima obavijest o otkazivanju

---

### 3.3 Plaćanje pri dolasku — korak po korak

1. Gost odabere datume na kalendaru widgeta
2. Popuni formu za rezervaciju
3. **Nema opcija plaćanja** — prikazuje se poruka: "Plaćanje ćete dogovoriti s vlasnikom"
4. Klikne **"Pošalji zahtjev za rezervaciju"**
5. **Rezervacija se kreira** (status: čekanje)
6. Gost prima email: "Zahtjev za rezervaciju zaprimljen — vlasnik će vas kontaktirati"
7. Vlasnik prima email: "Nova rezervacija čeka odobrenje"
8. Vlasnik kontaktira gosta (telefon/email) i dogovara plaćanje
9. Vlasnik **potvrđuje rezervaciju** u dashboardu
10. Gost prima email: "Rezervacija potvrđena"

---

## 4. Depozit i ukupna cijena

### 4.1 Kako se izračunava cijena

| Komponenta | Opis |
|------------|------|
| **Osnovna cijena** | Cijena po noćenju × broj noćenja (iz cjenika ili dnevnih cijena) |
| **Dodatni gosti** | (gosti iznad kapaciteta) × naknada za extra krevet × noćenja |
| **Kućni ljubimci** | broj ljubimaca × naknada po ljubimcu × noćenja |
| **Dodatne usluge** | Odabrane usluge (čišćenje, doručak, parking, itd.) |
| **Ukupno** | Osnovna + Dodatni gosti + Ljubimci + Usluge |

### 4.2 Depozit vs. puna uplata

Gost bira jednu od dvije opcije pri plaćanju:

- **Depozit** (avans): postotak ukupne cijene koji se plaća unaprijed
  - Zadano 20%, vlasnik može postaviti 0–100%
  - Ostatak se plaća pri dolasku
  - Primjer: ukupna cijena €500, depozit 20% = gost plaća **€100** unaprijed

- **Puna uplata**: 100% ukupne cijene plaćeno unaprijed
  - Gost nema dodatnih troškova pri dolasku

### 4.3 Preostali iznos

- Prikazuje se gostu na ekranu potvrde i u emailu
- Preostali iznos = Ukupna cijena − Plaćeni depozit
- Gost plaća ostatak **pri dolasku** (gotovina, POS terminal, ili kako se dogovori s vlasnikom)
- BookBed **ne prati** plaćanje preostalog iznosa

---

## 5. Modovi widgeta i plaćanje

Widget za rezervacije ima dva moda rada koji utječu na tijek plaćanja:

### 5.1 Instant Booking (automatska potvrda)

- Gost rezervira i plaća → rezervacija se **automatski potvrđuje**
- Vlasnik ne mora odobravati svaku rezervaciju
- Dostupne metode: **Stripe** i **Bankovni prijenos**
- Plaćanje pri dolasku **nije dostupno** u ovom modu
- Idealno za: etablirane objekte s automatiziranim procesima

### 5.2 Pending Mode (ručno odobrenje)

- Gost šalje zahtjev → vlasnik **ručno odobrava**
- Sve rezervacije idu u status "Čekanje"
- Dostupne metode: **sve tri** (Stripe, Bankovni prijenos, Plaćanje pri dolasku)
- Idealno za: vlasnike koji žele pregledati svaku rezervaciju prije potvrde

---

## 6. Email obavijesti vezane uz plaćanje

### 6.1 Emailovi koje prima gost

| Email | Kada se šalje | Sadržaj |
|-------|---------------|---------|
| **Rezervacija potvrđena** | Nakon uspješnog Stripe plaćanja ili vlasnikove potvrde | Detalji rezervacije, iznos, datumi, link za pregled |
| **Zahtjev zaprimljen** | Odmah nakon kreiranja pending rezervacije | Detalji + upute za uplatu (ako bankovni prijenos) |
| **Podsjetnik za uplatu** | 1 dan prije isteka roka (dan 6 od 7) | Bankovni podaci, referenca, rok |
| **Podsjetnik za check-in** | 7 dana prije datuma prijave | Detalji rezervacije, adresa nekretnine |

### 6.2 Emailovi koje prima vlasnik

| Email | Kada se šalje | Sadržaj |
|-------|---------------|---------|
| **Nova rezervacija** | Odmah nakon svake rezervacije (UVIJEK) | Ime gosta, kontakt, datumi, cijena, link na dashboard |
| **Čeka odobrenje** | Za pending rezervacije | Detalji + gumb "Pregledaj rezervaciju" |

**Važno:** Vlasnik **uvijek** prima email za svaku novu rezervaciju — čak i ako je isključio obavijesti. Ovo je sigurnosna mjera dok ne postoje push obavijesti na svim platformama.

---

## 7. Sigurnost plaćanja

### 7.1 Zaštita od dvostrukog bookinga

- Kada gost klikne "Plati", sustav **odmah kreira privremenu rezervaciju** i blokira datume
- Ako drugi gost pokuša rezervirati iste datume, dobiva poruku **"Datumi više nisu dostupni"**
- Privremena rezervacija istječe za **15 minuta** ako se plaćanje ne dovrši

### 7.2 Zaštita od manipulacije cijenom

- Cijena se **zaključava** u trenutku slanja forme
- Server **neovisno izračunava** cijenu i uspoređuje
- Ako se cijene razlikuju:
  - Mala razlika (<€10): koristi se serverska cijena, logira se upozorenje
  - Velika razlika (>€10 ili >5%): šalje se sigurnosno upozorenje
- Gost **nikada ne plaća pogrešan iznos**

### 7.3 Zaštita od dvostrukog klika

- Svaki zahtjev za rezervaciju ima **jedinstveni ključ** (idempotencyKey)
- Ako gost klikne dvaput, drugi zahtjev vraća istu postojeću rezervaciju
- Sprječava dvostruku naplatu na sporim mrežama

### 7.4 PCI usklađenost (kartice)

- BookBed **nikada ne vidi i ne pohranjuje** podatke kreditne kartice
- Sva kartična plaćanja obrađuju se na **Stripe-ovim sigurnim serverima**
- Stripe je certificiran po **PCI DSS Level 1** standardu (najviša razina)

---

## 8. Česta pitanja (FAQ)

### Za vlasnike

**P: Mogu li koristiti više metoda plaćanja istovremeno?**
O: Da! Omogućite Stripe + Bankovni prijenos + Plaćanje pri dolasku. Gost bira pri rezervaciji.

**P: Kako promijenim postotak depozita?**
O: Unit Hub → Widget Settings → Plaćanje → Postotak depozita (0–100%). Može se postaviti zasebno za Stripe i Bankovni prijenos.

**P: Što ako gost ne uplati bankovni prijenos na vrijeme?**
O: Rezervacija se automatski otkazuje nakon isteka roka (zadano 7 dana). Datumi postaju slobodni.

**P: Mogu li zahtijevati punu uplatu unaprijed?**
O: Da, postavite postotak depozita na 100%. Gost plaća cijeli iznos prije potvrde.

**P: Koliko Stripe naplaćuje?**
O: 1,4% + €0,25 po transakciji. Naknada se odbija od vaše isplate, NE dodaje se gostu.

**P: Što se događa ako odspojim Stripe?**
O: Vaš Stripe račun i dalje postoji. Možete ga koristiti neovisno. BookBed samo uklanja integraciju. Postojeće rezervacije nisu pogođene.

**P: Trebam li Stripe za bankovni prijenos?**
O: Ne, metode su potpuno neovisne. Možete koristiti samo Bankovni prijenos bez Stripe-a.

**P: Mogu li prilagoditi rok za uplatu kod bankovnog prijenosa?**
O: Da, konfigurirabilan je po smještajnoj jedinici: 1–14 dana (zadano 7 dana).

**P: Gdje postavljam podatke bankovnog računa?**
O: Owner Dashboard → Profil → Bankovni račun. Unesite IBAN, naziv banke, vlasnika računa i SWIFT/BIC.

**P: Može li gost platiti ostatak online naknadno?**
O: Trenutno ne. Preostali iznos (nakon depozita) naplaćuje se pri dolasku. Vlasnik dogovara način s gostom.

### Za goste

**P: Je li plaćanje karticom sigurno?**
O: Da. BookBed nikada ne vidi podatke vaše kartice. Plaćanje obrađuje Stripe, koji je certificiran po najvišim sigurnosnim standardima (PCI DSS Level 1).

**P: Što ako moje plaćanje karticom ne uspije?**
O: Datumi postaju ponovo slobodni nakon 15 minuta. Možete pokušati ponovno ili odabrati drugu karticu.

**P: Moram li platiti cijeli iznos odmah?**
O: Ne nužno. Ako vlasnik nudi opciju depozita, možete platiti samo dio unaprijed (npr. 20%) a ostatak pri dolasku.

**P: Kako znam koliko moram uplatiti bankovnim prijenosom?**
O: Nakon slanja rezervacije prikazuju se detaljne upute: IBAN, iznos, referenca plaćanja. Iste informacije šalju se i na vaš email.

**P: Što ako ne stignem uplatiti u roku?**
O: Rezervacija se automatski otkazuje i datumi postaju slobodni. Možete pokušati rezervirati ponovo.

**P: Što je EPC QR kod?**
O: QR kod koji možete skenirati mobilnom bankovnom aplikacijom. Automatski popunjava IBAN, iznos i referencu — samo potvrdite uplatu u aplikaciji.

**P: Moram li navesti referencu plaćanja pri uplati?**
O: Da, obavezno. Referenca plaćanja (npr. BK-2026-001234) pomaže vlasniku identificirati vašu uplatu i potvrditi rezervaciju.

**P: Kada ću dobiti potvrdu rezervacije?**
O: Kod kartičnog plaćanja — **odmah** nakon uspješnog plaćanja. Kod bankovnog prijenosa — **nakon što vlasnik potvrdi** primitak uplate. Kod plaćanja pri dolasku — **nakon što vlasnik odobri** rezervaciju.

---

## 9. Pregled postavki plaćanja po lokaciji

| Postavka | Gdje se konfigurira |
|----------|---------------------|
| Stripe povezivanje | Owner Dashboard → Integracije → Stripe |
| Bankovni podaci (IBAN) | Owner Dashboard → Profil → Bankovni račun |
| Stripe uklj/isklj po jedinici | Unit Hub → Widget Settings → Plaćanje |
| Postotak depozita (Stripe) | Unit Hub → Widget Settings → Stripe |
| Bankovni prijenos uklj/isklj | Unit Hub → Widget Settings → Plaćanje |
| Postotak depozita (banka) | Unit Hub → Widget Settings → Bankovni prijenos |
| Rok za uplatu (banka) | Unit Hub → Widget Settings → Bankovni prijenos |
| EPC QR kod uklj/isklj | Unit Hub → Widget Settings → Bankovni prijenos |
| Mod widgeta (Instant/Pending) | Unit Hub → Widget Settings → Mod rada |
