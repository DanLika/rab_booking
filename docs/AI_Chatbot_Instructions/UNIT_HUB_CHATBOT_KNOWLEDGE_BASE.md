# BookBed Smještajne Jedinice (Unit Hub) — Kompletna baza znanja za AI chatbot

## 1. Pregled

Stranica **Smještajne Jedinice** (Unit Hub) je središnje mjesto u Owner Dashboard-u za upravljanje svim aspektima smještajnih jedinica — od osnovnih podataka i kapaciteta, preko cijena i kalendara, do postavki booking widgeta. Sve se kontrolira s jednog mjesta.

Struktura je hijerarhijska:
- **Objekt (Property)** = nekretnina (npr. "Villa Mediteran")
  - **Jedinica (Unit)** = smještajna jedinica unutar objekta (npr. "Apartman prizemlje", "Studio 1")

Jedan vlasnik može imati više objekata, a svaki objekt može imati više jedinica.

---

## 2. Raspored ekrana (Layout)

### 2.1 Desktop (≥900px)

Ekran je podijeljen na dva panela:
- **Lijevi panel (Detail)** — prikazuje tabove s detaljima odabrane jedinice (Osnovno, Cjenovnik, Widget, Napredno)
- **Desni panel (Master)** — prikazuje listu objekata i jedinica za brzo prebacivanje

### 2.2 Tablet i Mobitel (<900px)

- Tabovi s detaljima jedinice zauzimaju cijeli ekran
- Lista objekata i jedinica dostupna je putem **bočnog izbornika** (end-drawer) koji se otvara klikom na ikonu izbornika

### 2.3 Navigacija između jedinica

- Na desktopom: kliknite na drugu jedinicu u desnom panelu
- Na mobitelu: otvorite bočni izbornik → odaberite drugu jedinicu
- Prva jedinica se automatski odabire pri učitavanju stranice

---

## 3. Lista objekata i jedinica (Master panel)

### 3.1 Prikaz

Objekti su prikazani kao proširive sekcije. Svaki objekt prikazuje:
- Naziv objekta
- Broj jedinica (npr. "3 jedinice")
- Dugmad za uređivanje i brisanje objekta

Unutar svakog objekta prikazane su jedinice, svaka s:
- **Naziv jedinice**
- **Status** (zeleni badge "Dostupno" ili crveni "Nedostupno")
- **Kratki opis** (broj gostiju, cijena po noći)
- **Dugme za dupliciranje** (ikona kopiranja)
- **Dugme za brisanje** (crvena ikona)

### 3.2 Pretraga

Na vrhu panela nalazi se polje za pretragu. Pretražuje po:
- Nazivu jedinice
- Opisu jedinice
- Nazivu objekta

### 3.3 Sortiranje

Jedinice su sortirane abecedno (A-Z) unutar svakog objekta.

---

## 4. Upravljanje objektima (Properties)

### 4.1 Kreiranje novog objekta

Kliknite **"Dodaj novi objekt"** (dugme + u zaglavlju panela). Otvara se forma s poljima:

| Polje | Obavezno | Opis |
|-------|----------|------|
| **Naziv nekretnine** | Da | Npr. "Villa Mediteran" |
| **URL Slug** | Da | Automatski generiran iz naziva (npr. "villa-mediteran"). Može se ručno urediti. |
| **Poddomena (Subdomain)** | Ne | Kreira prilagođeni URL: `vasa-nekretnina.view.bookbed.io`. Sustav provjerava dostupnost u realnom vremenu. |
| **Vrsta nekretnine** | Da | Vila, Apartman, Kuća, Studio, Ostalo |
| **Opis** | Da | Detaljan opis nekretnine (min 100 znakova) |
| **Lokacija** | Da | Npr. "Rab (grad), Otok Rab" |
| **Ulica i broj** | Da | Adresa nekretnine |
| **Grad** | Da | Grad |
| **Sadržaji (Amenities)** | Ne | Višestruki odabir: WiFi, parking, grijanje, klima, bazen, vrt, terasa, itd. |
| **Fotografije** | Ne | Minimalno 3 fotografije preporučeno |
| **Objavi odmah** | Ne | Preklopnik za objavu (zadano: uključeno) |

**Poddomena:** Ako unesete "villa-marija", vaš widget će biti dostupan na `villa-marija.view.bookbed.io`. Poddomena mora imati 3-30 znakova (mala slova, brojevi i crtice).

### 4.2 Uređivanje objekta

Kliknite ikonu olovke pored naziva objekta u listi. Otvara se ista forma kao za kreiranje, ali s popunjenim podacima.

### 4.3 Brisanje objekta

Kliknite ikonu kante pored naziva objekta. **Brisanje je moguće samo ako objekt nema jedinica.** Ako ima jedinica, prikazuje se poruka:

> "Objekt '{naziv}' ima {X} jedinica. Morate prvo obrisati sve jedinice prije brisanja objekta."

---

## 5. Kreiranje nove jedinice — Čarobnjak u 4 koraka

### 5.1 Pokretanje čarobnjaka

- Kliknite **"Dodaj jedinicu"** unutar željenog objekta
- Ili kliknite **ikonu kopiranja** na postojećoj jedinici za dupliciranje (sva polja se kopiraju, naziv dobiva sufiks " (kopija)")

### 5.2 Korak 1: Osnovne informacije

| Polje | Obavezno | Opis |
|-------|----------|------|
| **Naziv jedinice** | Da | Npr. "Apartman prizemlje", "Studio 1" |
| **URL Slug** | Da | Automatski generiran iz naziva (npr. "apartman-prizemlje"). Može se ručno urediti. |
| **Opis** | Ne | Kratak opis jedinice (max 500 znakova). Brojač znakova prikazan. |

**URL Slug:** Koristi se za čiste linkove (npr. `villa-marija.view.bookbed.io/apartman-prizemlje`). Ako ručno uredite slug, on se više ne ažurira automatski pri promjeni naziva. Možete ga resetirati klikom na "Regeneriraj iz naziva".

### 5.3 Korak 2: Kapacitet i usluge

**Osnovni kapacitet:**

| Polje | Obavezno | Opis |
|-------|----------|------|
| **Spavaće sobe** | Da | Broj spavaćih soba (min 0) |
| **Kupaonice** | Da | Broj kupaonica (min 0) |
| **Max gostiju** | Da | Maksimalan broj gostiju (min 1) |
| **Površina (m²)** | Ne | Površina jedinice u kvadratnim metrima |

**Dodatni kreveti** (proširiva sekcija):

| Polje | Obavezno | Opis |
|-------|----------|------|
| **Max dodatnih kreveta** | Ne | Koliko dodatnih kreveta je dostupno |
| **Cijena dodatnog kreveta** | Ne | Cijena po krevetu po noći (€) |

**Kućni ljubimci** (proširiva sekcija):

| Polje | Obavezno | Opis |
|-------|----------|------|
| **Max kućnih ljubimaca** | Ne | Koliko ljubimaca je dozvoljeno |
| **Naknada za ljubimce** | Ne | Cijena po ljubimcu po noći (€) |

**Dodatne usluge** (proširiva sekcija):

Ova sekcija je dostupna **tek nakon što je jedinica prvi put spremljena** (jer je potreban ID jedinice za pohranu usluga).

Vlasnik može dodati prilagođene usluge koje gosti biraju tijekom rezervacije. Više detalja u sekciji 9.

### 5.4 Korak 3: Cijena i dostupnost

**Osnovna cijena:**

| Polje | Obavezno | Opis |
|-------|----------|------|
| **Cijena po noći** | Da | Osnovna cijena za radne dane (€). Mora biti veća od 0. |
| **Vikend cijena** | Ne | Cijena za petkom i subotom. Ako je prazno, koristi se osnovna cijena. |
| **Min noći** | Da | Minimalan broj noći za rezervaciju (min 1) |
| **Max noći** | Ne | Maksimalan broj noći. Prazno = bez ograničenja. Mora biti ≥ min noći. |

**Dostupnost:**

| Polje | Opis |
|-------|------|
| **Cijelu godinu** | Preklopnik. Uključeno = jedinica dostupna cijele godine. Isključeno = sezonska dostupnost (upravlja se putem cjenovnika). |

### 5.5 Korak 4: Pregled i objava

Prikazuje se sažetak svih unesenih podataka u 4 kartice:
1. **Osnovni podaci** — naziv, slug, opis
2. **Kapacitet** — sobe, kupaonice, gosti, površina, dodatni kreveti, ljubimci
3. **Cijena** — cijena po noći, min noći
4. **Dostupnost** — cjelogodišnja ili sezonska

Klikom na **"Objavi"**:
- Svi obavezni podaci se validiraju
- Jedinica se sprema u sustav
- Automatski se kreiraju zadane Widget postavke
- Jedinica se pojavljuje u listi

---

## 6. Tabovi jedinice (nakon kreiranja)

### 6.1 Tab: Osnovno

Prikazuje sve informacije o jedinici podijeljene u sekcije:

**Sekcija Informacije:**
- Naziv, Slug, Opis, Status (Dostupan/Nedostupan)

**Sekcija Kapacitet:**
- Spavaće sobe, Kupaonice, Max gostiju, Površina

**Sekcija Cijena:**
- Cijena po noći, Min noći

**Sekcija Fotografije:**
- Galerija fotografija s mogućnošću dodavanja/brisanja
- Ako nema fotografija, prikazuje se poruka "Nema fotografija"

**Sekcija Dodatne usluge** (ako postoje):
- Lista usluga s cijenama (npr. "Parking — €5.00 po noći")

Klikom na **"Uredi"** otvara se čarobnjak za uređivanje jedinice.

### 6.2 Tab: Cjenovnik

Vidi sekciju 7 — Cjenovnik (Pricing Calendar).

### 6.3 Tab: Widget

Vidi sekciju 8 — Widget postavke.

### 6.4 Tab: Napredno

Sadrži napredne postavke widgeta i integracije:
- Prilagodba widgeta
- Napredne opcije za sinkronizaciju
- Dodatne mogućnosti konfiguracije

---

## 7. Cjenovnik (Pricing Calendar)

### 7.1 Pregled

Tab Cjenovnik prikazuje kalendar u kojem vlasnik upravlja cijenama, dostupnošću i blokiranim datumima za svaki dan posebno. Ovo je najmoćniji alat za upravljanje cijenama.

### 7.2 Prikaz kalendara

- **Mjesečni prikaz** prikazuje jedan mjesec s danima u mreži
- **Navigacija** između mjeseci pomoću padajućeg izbornika ili strelica
- Svaki dan prikazuje:
  - **Cijenu** (prilagođena dnevna cijena ili osnovna cijena)
  - **Status** (dostupan, blokiran, zauzet)
  - **Boju** prema statusu

### 7.3 Hijerarhija cijena

Sustav koristi sljedeću hijerarhiju pri određivanju cijene za neki dan (od najvišeg prioriteta):

1. **Prilagođena dnevna cijena** — ako je vlasnik ručno postavio cijenu za taj dan
2. **Vikend osnovna cijena** — ako je dan petak ili subota, i vikend cijena je postavljena
3. **Osnovna cijena** — zadana cijena po noći

### 7.4 Radnje na pojedinačnom danu

Klikom na jedan dan otvara se dijalog **"Uredi datum"** s opcijama:

**CIJENA:**
- **Osnovna cijena po noći (€)** — postavljanje prilagođene cijene za taj dan
- **Vikend cijena (€)** — postavljanje vikend cijene

**DOSTUPNOST:**
- **Dostupno** — preklopnik za označavanje dana kao dostupnog/nedostupnog
- **Blokiraj prijavu (check-in)** — gosti ne mogu započeti rezervaciju na taj dan
- **Blokiraj odjavu (check-out)** — gosti ne mogu završiti rezervaciju na taj dan

### 7.5 Radnje na više dana (Bulk operacije)

Vlasnik može odabrati više dana odjednom (klik + povlačenje ili Shift+klik) i tada primijeniti akcije na sve odabrane:

Na vrhu se prikazuje broj odabranih dana (npr. "5 dana odabrano") s opcijama:
- **Očisti** — poništava odabir
- **Odaberi sve dane** — odabire sve dane u mjesecu

Akcije za odabrane dane:

| Akcija | Opis |
|--------|------|
| **Postavi cijenu** | Unos nove cijene koja se primjenjuje na sve odabrane dane |
| **Označi kao dostupno** | Svi odabrani dani postaju dostupni |
| **Blokiraj datume** | Svi odabrani dani postaju nedostupni (s potvrdom) |
| **Blokiraj check-in** | Blokiraj dolazak na odabrane dane |
| **Blokiraj check-out** | Blokiraj odlazak na odabrane dane |

**Primjer korištenja:** Želite blokirati cijeli prosinac jer radite renovaciju:
1. Otvorite prosinac u cjenovniku
2. Kliknite "Odaberi sve dane"
3. Kliknite "Blokiraj datume"
4. Potvrdite — svi dani u prosincu su sada nedostupni u widgetu

### 7.6 Brisanje prilagođene cijene

Ako ste postavili prilagođenu cijenu za neki dan i želite je ukloniti:
- Otvorite taj dan → obrišite cijenu → spremite
- Dan će se vratiti na osnovnu cijenu (ili vikend cijenu ako je petak/subota)

### 7.7 Poništavanje akcije (Undo)

Nakon bulk operacija prikazuje se poruka s opcijom **"Poništi"** (undo) koja vraća prethodne vrijednosti.

---

## 8. Widget postavke

### 8.1 Pregled

Tab Widget kontrolira ponašanje booking widgeta ugrađenog na web stranicu vlasnika. Ovdje se odabire mod rada, metode plaćanja, kontakt podaci i pravila rezervacije.

### 8.2 Mod widgeta

Vlasnik bira jedan od tri moda:

| Mod | Opis |
|-----|------|
| **Samo kalendar** | Widget prikazuje samo kalendar dostupnosti i kontakt podatke vlasnika. Gost ne može rezervirati online — mora kontaktirati vlasnika. |
| **Rezervacija bez plaćanja** | Widget prikazuje kalendar i formu za rezervaciju. Gost šalje zahtjev, vlasnik ga ručno odobrava. Plaćanje se dogovara privatno. |
| **Rezervacija s plaćanjem** | Widget prikazuje kalendar, formu i opcije plaćanja. Gost može platiti odmah karticom (Stripe) ili dobiti upute za bankovni prijenos. |

### 8.3 Način plaćanja

Dostupno samo u modu "Rezervacija s plaćanjem":

**Stripe (Kartično plaćanje):**
- Preklopnik za uključivanje/isključivanje
- Gost plaća karticom putem sigurne Stripe stranice
- Minimalni iznos: €0.50
- Nakon plaćanja, rezervacija se automatski potvrđuje
- Zahtijeva povezan Stripe račun (Stripe Connect)

**Bankovna uplata:**
- Preklopnik za uključivanje/isključivanje
- Zahtijeva unesene bankovne podatke u profilu (IBAN, naziv banke, vlasnik računa)
- Postavke:
  - **Rok za uplatu** — broj dana koji gost ima za uplatu (zadano: 3 dana)
  - **Prikaži QR kod** — EPC QR kod koji gost skenira za brži prijenos (zadano: uključeno)
  - **Prilagođena napomena** — opcionaln poruka za gosta (max 500 znakova)

**Plaćanje po dolasku:**
- Automatski omogućeno ako su Stripe i bankovna uplata isključeni
- Gost ne plaća unaprijed — plaća pri dolasku
- Poruka: "Gost plaća prilikom prijave"

**Važno:** U modu "Rezervacija s plaćanjem" mora biti uključena barem jedna metoda plaćanja.

### 8.4 Iznos avansa (depozit)

- Klizač od **1% do 100%** ukupne cijene
- Zadano: **20%**
- Primjenjuje se na sve metode plaćanja
- **100%** = puna uplata unaprijed
- Primjer: Ukupna cijena €500, avans 20% = gost plaća €100 unaprijed, €400 pri dolasku

### 8.5 Ponašanje rezervacije

| Postavka | Opis | Zadano |
|----------|------|--------|
| **Zahtijeva odobrenje** | Ako je uključeno, vlasnik mora ručno odobriti svaku rezervaciju. Ako je isključeno, rezervacija se automatski potvrđuje. | Uključeno |
| **Dopustite otkazivanje** | Ako je uključeno, gost može otkazati svoju rezervaciju do roka za otkazivanje. | Uključeno |
| **Rok za otkazivanje** | Broj sati prije dolaska do kada gost može otkazati (npr. 48 = 2 dana prije check-in-a). | 48 sati |

**Napomena za mod "Rezervacija bez plaćanja":** U ovom modu sve rezervacije **uvijek** zahtijevaju odobrenje vlasnika, bez obzira na ovu postavku.

### 8.6 Pravila rezervacije

| Postavka | Opis | Zadano |
|----------|------|--------|
| **Min noći** | Minimalan broj noći za rezervaciju | Preuzima iz osnovnih podataka jedinice |
| **Min dana unaprijed** | Koliko dana unaprijed se mora rezervirati (0 = odmah) | 0 |
| **Max dana unaprijed** | Koliko dana unaprijed je moguće rezervirati (365 = godina dana) | 365 |

### 8.7 Kontakt informacije

Kontakt podaci koji se prikazuju u widgetu (posebno važni u modu "Samo kalendar"):

| Polje | Opis |
|-------|------|
| **Broj telefona** | Telefon za kontakt |
| **Email adresa** | Email za kontakt |

Dugme **"Kopiraj iz profila vlasnika"** automatski popunjava ove podatke iz profila.

**U modu "Samo kalendar"** gost koristi ove podatke za kontaktiranje vlasnika (telefon, email, WhatsApp).

---

## 9. Dodatne usluge (Additional Services)

### 9.1 Pregled

Vlasnik može kreirati prilagođene usluge koje gost bira tijekom rezervacije u widgetu. Usluge se dodaju u Koraku 2 čarobnjaka (Kapacitet i usluge) ili u tabu Osnovno.

### 9.2 Dodavanje usluge

Klikom na **"Dodaj uslugu"** otvara se dijalog s poljima:

| Polje | Obavezno | Opis |
|-------|----------|------|
| **Naziv usluge** | Da | Npr. "Parking", "Doručak", "Transfer s aerodroma" |
| **Cijena** | Da | Cijena usluge u eurima (€) |
| **Način obračuna** | Da | Kako se cijena izračunava (vidi tablicu ispod) |
| **Dostupno** | Ne | Preklopnik — da li je usluga trenutno dostupna gostima |

### 9.3 Načini obračuna

| Način | Opis | Primjer |
|-------|------|---------|
| **Po rezervaciji** | Fiksna cijena za cijelu rezervaciju | Parking €20 po rezervaciji = €20 ukupno |
| **Po noći** | Cijena se množi s brojem noći | Doručak €10 po noći × 5 noći = €50 |
| **Po gostu** | Cijena se množi s brojem gostiju | Transfer €15 po gostu × 3 gosta = €45 |
| **Po gostu po noći** | Cijena se množi s brojem gostiju I noći | Polupansion €8 × 3 gosta × 5 noći = €120 |

### 9.4 Uređivanje i brisanje usluge

- **Uredi** — kliknite ikonu olovke na usluzi → otvara se isti dijalog s popunjenim podacima
- **Obriši** — kliknite ikonu kante → potvrda → usluga se trajno briše

### 9.5 Prikaz u widgetu

Gost u booking widgetu vidi dostupne usluge i može ih odabrati tijekom rezervacije. Odabrane usluge se dodaju na ukupnu cijenu. Detaljan prikaz cijena prikazan je u pregledu cijene prije potvrde rezervacije.

### 9.6 Unaprijed definirane vrste usluga

Sustav nudi predložene vrste usluga za brži unos:
- Parking
- Doručak
- Kasni check-in
- Rani check-out
- Čišćenje
- Dječji krevetić
- Naknada za ljubimce
- Transfer s aerodroma

---

## 10. Upravljanje fotografijama

### 10.1 Dodavanje fotografija

Fotografije se dodaju u tabu **Osnovno** u sekciji "Fotografije":
- Kliknite "Dodaj fotografije" ili ikonu kamere
- Odaberite fotografije s uređaja
- Podržani formati: **JPG, PNG, HEIC** (iOS format)
- Fotografije se automatski uploadaju na server

### 10.2 Pregled i brisanje

- Fotografije su prikazane u galeriji (grid)
- Ako ih ima više od prikazanog, pojavljuje se oznaka "+X više"
- Svaka fotografija ima opciju brisanja

### 10.3 Redoslijed

Prva fotografija u nizu koristi se kao glavna slika jedinice (prikazuje se u widgetu i na kartici jedinice).

---

## 11. Dupliciranje jedinice

### 11.1 Kako duplicirati

1. U listi jedinica, kliknite **ikonu kopiranja** pored željene jedinice
2. Kreira se nova jedinica s istim podacima
3. Naziv nove jedinice dobiva sufiks " (kopija)" (npr. "Apartman 1 (kopija)")
4. Možete odmah urediti podatke i promijeniti naziv

### 11.2 Što se kopira

- Svi osnovni podaci (naziv, opis, kapacitet)
- Cijena i pravila boravka
- Widget postavke

### 11.3 Što se NE kopira

- Prilagođene dnevne cijene (cjenovnik)
- Fotografije
- Postojeće rezervacije
- iCal feedovi

---

## 12. Brisanje jedinice

1. U listi jedinica, kliknite **crvenu ikonu kante** pored jedinice
2. Prikazuje se dijalog potvrde: "Jeste li sigurni da želite obrisati '{naziv}'? Ova akcija se ne može poništiti."
3. Klikom na "Obriši" jedinica se trajno briše

**Važno:** Brisanje jedinice:
- Trajno uklanja sve podatke o jedinici
- Widget s tom jedinicom prestaje raditi
- Postojeće rezervacije ostaju u sustavu (ali jedinica im više nije pripisana)

---

## 13. Status jedinice (Dostupno / Nedostupno)

Svaka jedinica ima status koji se prikazuje badgeom u listi:

| Status | Badge | Značenje |
|--------|-------|----------|
| **Dostupan** | Zeleni | Jedinica je aktivna — prikazuje se u widgetu, gosti je mogu rezervirati |
| **Nedostupan** | Crveni | Jedinica je deaktivirana — ne prikazuje se u widgetu |

Status se mijenja u postavkama jedinice (tab Osnovno → Uredi → polje "Dostupnost").

**Korištenje:** Ako vlasnik želi privremeno isključiti jedinicu (npr. renovacija), može je označiti kao nedostupnu umjesto da briše.

---

## 14. Povezane stranice

### 14.1 iCal sinkronizacija

Dostupna iz navigacijskog izbornika pod **"iCal Sync"**. Omogućava:
- **Uvoz** rezervacija s Booking.com, Airbnb i drugih platformi
- **Izvoz** BookBed kalendara za korištenje na drugim platformama
- Automatski sync svakih 15 minuta

### 14.2 Ugradnja widgeta (Embed Widget Guide)

Dostupna iz navigacijskog izbornika. Sadrži:
- Upute za ugradnju widgeta u 3 koraka
- Pregled uživo (Live Preview) — odaberite jedinicu i pogledajte widget u novom tabu
- Embed kodovi za svaku jedinicu

### 14.3 Kalendar

Dostupan iz navigacijskog izbornika. Prikazuje zauzetost svih jedinica:
- **Timeline kalendar** — horizontalni vremenski prikaz sa svakom jedinicom u svom redu
- **Mjesečni kalendar** — klasični mjesečni prikaz

---

## 15. Česta pitanja (FAQ za chatbot)

### Općenita pitanja

**P: Kako kreirati novu smještajnu jedinicu?**
O: U stranici Smještajne Jedinice kliknite "Dodaj jedinicu" unutar željenog objekta. Ispunite 4 koraka čarobnjaka (Osnovne informacije → Kapacitet → Cijena → Pregled) i kliknite "Objavi".

**P: Koliko jedinica mogu imati?**
O: Ovisi o pretplati. Trial dopušta 1 nekretninu, Premium do 5 nekretnina, Enterprise neograničeno. Svaka nekretnina može imati više jedinica.

**P: Mogu li imati više nekretnina?**
O: Da. Kliknite "Dodaj novi objekt" u listi objekata. Svaka nekretnina ima svoju poddomenu i zasebne jedinice.

**P: Kako duplicirati postojeću jedinicu?**
O: Kliknite ikonu kopiranja pored jedinice u listi. Nova jedinica se kreira s istim podacima — samo promijenite naziv i prilagodite po potrebi.

**P: Što je URL Slug?**
O: Slug je dio URL adrese koji identificira vašu jedinicu. Na primjer, ako je slug "apartman-prizemlje", link za tu jedinicu je `vasa-nekretnina.view.bookbed.io/apartman-prizemlje`. Slug se automatski generira iz naziva, ali ga možete i ručno urediti.

**P: Što je poddomena (Subdomain)?**
O: Poddomena je prilagođeni URL za vašu nekretninu. Na primjer, "villa-marija" kreira URL `villa-marija.view.bookbed.io`. Gosti koriste taj link za pristup widgetu. Poddomena se postavlja pri kreiranju objekta.

### Pitanja o cijenama

**P: Kako postaviti različite cijene za vikend?**
O: U Koraku 3 čarobnjaka (ili tab Cjenovnik) unesite "Vikend cijena" pored osnovne cijene. Vikend cijena se automatski primjenjuje na petke i subote.

**P: Kako postaviti različite cijene za sezonu?**
O: Otvorite tab Cjenovnik → navigirajte do željenog mjeseca → odaberite dane → kliknite "Postavi cijenu". Možete odabrati sve dane u mjesecu odjednom za brže postavljanje sezonskih cijena.

**P: Kako blokirati datume (npr. za renovaciju)?**
O: Otvorite tab Cjenovnik → odaberite dane koje želite blokirati → kliknite "Blokiraj datume". Blokirani dani se prikazuju kao nedostupni u widgetu i vanjskim kalendarima.

**P: Koja cijena ima prioritet?**
O: Prilagođena dnevna cijena (postavljena u cjenovniku za specifičan dan) ima najviši prioritet. Zatim vikend cijena (za petke i subote). Na kraju, osnovna cijena po noći.

**P: Kako vratiti dan na osnovnu cijenu?**
O: U cjenovniku kliknite na dan → obrišite prilagođenu cijenu → spremite. Dan se vraća na osnovnu cijenu (ili vikend cijenu ako je petak/subota).

### Pitanja o Widget postavkama

**P: Koji mod widgeta da odaberem?**
O: Ovisi o vašim potrebama:
- **Samo kalendar** — ako želite osobno komunicirati sa svakim gostom prije rezervacije
- **Rezervacija bez plaćanja** — ako želite da gosti mogu kreirati zahtjev, ali vi odobravate i dogovarate plaćanje
- **Rezervacija s plaćanjem** — ako želite potpuno automatiziran sustav s online plaćanjem

**P: Kako omogućiti kartično plaćanje?**
O: Prvo povežite Stripe račun (Integracije → Stripe → "Poveži račun"). Zatim u Widget postavkama uključite "Stripe plaćanje". Gosti će moći platiti karticom.

**P: Kako postaviti bankovnu uplatu?**
O: Unesite bankovne podatke u profilu (Integracije → Plaćanja → Bankovni podaci). Zatim u Widget postavkama uključite "Bankovna uplata". Možete podesiti rok za uplatu i EPC QR kod.

**P: Kako promijeniti postotak avansa/depozita?**
O: U Widget postavkama pomičite klizač "Iznos avansa" na željeni postotak (1-100%). Zadano je 20%.

**P: Što znači "Zahtijeva odobrenje"?**
O: Kad je uključeno, svaka nova rezervacija čeka vaše odobrenje. Vi ručno odobravate ili odbijate svaki zahtjev. Kad je isključeno, rezervacija se automatski potvrđuje.

**P: Kako postaviti rok za otkazivanje?**
O: U Widget postavkama podesite "Rok za otkazivanje" u satima. Na primjer, 48 znači da gost može otkazati do 2 dana prije dolaska. Ako postavite 0, gost ne može otkazati.

### Pitanja o dodatnim uslugama

**P: Kako dodati dodatnu uslugu (npr. parking)?**
O: U Koraku 2 čarobnjaka (ili tab Osnovno → Uredi) proširite sekciju "Dodatne usluge" → kliknite "Dodaj uslugu" → unesite naziv, cijenu i način obračuna.

**P: Koji su načini obračuna za usluge?**
O: Četiri opcije:
- **Po rezervaciji** — fiksna cijena (npr. Parking €20)
- **Po noći** — pomnoženo s brojem noći (npr. Doručak €10/noć)
- **Po gostu** — pomnoženo s brojem gostiju (npr. Transfer €15/gost)
- **Po gostu po noći** — pomnoženo s gostima i noćima (npr. Polupansion €8/gost/noć)

**P: Mogu li privremeno isključiti neku uslugu?**
O: Da. Uredite uslugu i isključite preklopnik "Dostupno". Usluga neće biti prikazana gostima, ali se neće obrisati.

### Pitanja o fotografijama

**P: Kako dodati fotografije jedinice?**
O: Otvorite tab Osnovno → sekcija Fotografije → kliknite za dodavanje. Podržani formati: JPG, PNG, HEIC (iOS). Preporučamo minimalno 3 fotografije.

**P: Koja fotografija se prikazuje kao glavna?**
O: Prva fotografija u nizu. Ona se prikazuje na kartici jedinice i u widgetu kao glavna slika.

---

## 16. Pojmovnik

| Pojam | Značenje |
|-------|----------|
| **Objekt (Property)** | Nekretnina u sustavu (vila, apartman, kuća). Može sadržavati više jedinica. |
| **Jedinica (Unit)** | Smještajna jedinica unutar objekta (npr. "Apartman 1", "Studio gornji kat") |
| **URL Slug** | SEO-prijateljski dio URL adrese za čiste linkove (npr. "apartman-prizemlje") |
| **Poddomena (Subdomain)** | Prilagođeni URL nekretnine (npr. villa-marija.view.bookbed.io) |
| **Cjenovnik** | Kalendar za upravljanje cijenama po danima, blokiranje datuma i sezonske cijene |
| **Vikend cijena** | Posebna cijena za petke i subote (veća od osnovne) |
| **Prilagođena dnevna cijena** | Ručno postavljena cijena za specifičan datum (ima najveći prioritet) |
| **Blokirani datum** | Dan koji je označen kao nedostupan — ne može se rezervirati |
| **Min noći** | Minimalan broj noći koji gost mora rezervirati |
| **Max noći** | Maksimalan broj noći za jednu rezervaciju |
| **Mod widgeta** | Način rada booking widgeta (samo kalendar, bez plaćanja, s plaćanjem) |
| **Avans (Depozit)** | Dio ukupne cijene koji gost plaća unaprijed |
| **Stripe Connect** | Sustav za primanje kartičnih plaćanja od gostiju putem Stripe-a |
| **EPC QR kod** | Europski standard za QR kod bankovnog plaćanja — gost skenira telefonom |
| **Bulk operacija** | Akcija primijenjena na više odabranih dana odjednom |
| **Čarobnjak (Wizard)** | Postupak u koracima za kreiranje nove jedinice |
| **Dupliciranje** | Kopiranje postojeće jedinice s istim podacima za brže kreiranje |
| **iCal Sync** | Sinkronizacija kalendara s Booking.com, Airbnb i drugim platformama |
| **Badge** | Mala oznaka u boji koja prikazuje status (zelena=dostupno, crvena=nedostupno) |
| **Dodatna usluga** | Prilagođena usluga koju gost može odabrati uz rezervaciju (npr. parking, doručak) |
