# BookBed Kalendari — Kompletna baza znanja za AI chatbot

## 1. Pregled kalendara u Owner Dashboard-u

BookBed nudi **dva tipa kalendara** za vlasnike nekretnina, svaki optimiziran za različite potrebe upravljanja rezervacijama:

| Kalendar | Namjena | Pristup |
|----------|---------|---------|
| **Timeline kalendar** | Gantt-prikaz svih smještajnih jedinica u redovima, s blokovima rezervacija po danima | Drawer > Kalendar > Timeline |
| **Mjesečni kalendar** | Klasični mjesečni prikaz s agendaom, po jednoj smještajnoj jedinici | Drawer > Kalendar > Mjesečni kalendar |

Oba kalendara prikazuju iste podatke (rezervacije, konflikti, platforme) — razlikuju se samo u vizualnom prikazu.

---

## 2. Timeline kalendar

### 2.1 Što vlasnik vidi

Timeline kalendar je **Gantt-dijagram** koji prikazuje sve smještajne jedinice (apartmane, sobe) kao **redove**, a rezervacije kao **obojene blokove** koji se protežu po danima. Ovo je idealan prikaz za:

- Brzi pregled zauzetosti **svih jedinica odjednom**
- Uočavanje preklapanja i turnover dana (dan odjave jednog gosta = dan prijave sljedećeg)
- Vizualno planiranje slobodnih termina

**Elementi na ekranu:**
- **Toolbar** (gornja traka): strelice za navigaciju lijevo/desno, gumb "Danas", birač datuma (skok na bilo koji datum)
- **Redovi**: svaka smještajna jedinica ima svoj red s imenom jedinice na lijevoj strani
- **Blokovi rezervacija**: obojeni paralelogrami koji predstavljaju rezervacije
- **Legenda boja**: zelena = potvrđena, narančasta = čekanje, plava = završena, siva = otkazana
- **Značka konflikta**: crvena ikona s brojem preklapajućih rezervacija (ako ih ima)
- **Plutajući gumb (+)**: za brzo kreiranje nove rezervacije

### 2.2 Boje i značenje statusa

| Boja | Status | Značenje |
|------|--------|----------|
| Zelena | Potvrđena | Rezervacija je potvrđena, datumi su blokirani |
| Narančasta | Čekanje | Rezervacija čeka odobrenje vlasnika |
| Plava | Završena | Gost je odsjeo i odjavio se |
| Siva | Otkazana | Rezervacija je otkazana, datumi su slobodni |

### 2.3 Ikone platformi

Ako je rezervacija uvezena s vanjske platforme (Booking.com, Airbnb, iCal), u gornjem desnom kutu bloka prikazuje se **ikona platforme**:

| Ikona | Platforma |
|-------|-----------|
| **B** (plava) | Booking.com |
| **A** (crvena) | Airbnb |
| **W** (ljubičasta) | Direktna rezervacija (widget) |
| Link ikona (narančasta) | iCal / Vanjski izvor |

### 2.4 Navigacija

- **Strelice lijevo/desno**: pomicanje po danima (jedan korak = broj vidljivih dana na ekranu)
- **Gumb "Danas"**: skok na današnji datum
- **Birač datuma**: klik otvara kalendar za skok na bilo koji datum (čak i mjesecima unaprijed/unazad)
- **Tipkovnički prečaci** (desktop): strelica lijevo/desno za navigaciju, T za "Danas"
- **Horizontalni scroll**: na mobitelu povlačenje prstom lijevo/desno

### 2.5 Kreiranje rezervacije

Vlasnik može kreirati novu rezervaciju na dva načina:

**Način 1 — Dugi pritisak na ćeliju:**
1. Vlasnik **dugo pritisne** (long-press) na prazan dan u redu željene smještajne jedinice
2. Otvara se dijalog za kreiranje s **unaprijed popunjenim** datumom i jedinicom
3. Vlasnik unosi podatke gosta i sprema

**Način 2 — Plutajući gumb (+):**
1. Vlasnik klikne zeleni **+** gumb u donjem desnom kutu
2. Otvara se prazan dijalog za kreiranje
3. Vlasnik ručno bira jedinicu i datume

### 2.6 Pregled i uređivanje rezervacije

- **Klik na blok rezervacije**: otvara dijalog s detaljima i mogućnošću uređivanja
- U dijalogu vlasnik može:
  - Promijeniti datume check-in/check-out
  - Promijeniti broj gostiju (+/- gumbi)
  - Promijeniti status rezervacije (potvrđena, čekanje, završena, otkazana)
  - Dodati/urediti interne bilješke
  - Spremiti promjene

**Upozorenje o preklapanju**: Ako vlasnik promijeni datume tako da se preklapaju s drugom rezervacijom, sustav prikazuje upozorenje s detaljima konflikta (ime gosta, datumi) i **ne dopušta spremanje**.

**Upozorenje o platformama**: Ako je jedinica povezana s Booking.com ili Airbnb, a vlasnik mijenja datume, sustav prikazuje upozorenje da ručno ažurira datume i na tim platformama.

### 2.7 Detekcija konflikata (overbooking)

- Ako se dvije ili više rezervacija **preklapaju u datumima** na istoj jedinici, u toolbaru se prikazuje **crvena značka** s brojem konflikata
- Klik na značku automatski **skroluje do prvog konflikta** i prikazuje detalje
- Konflikti se mogu pojaviti kada se rezervacije uvoze s više platformi istovremeno

### 2.8 Dodatne opcije

- **Sakrij prazne jedinice**: gumb koji skriva jedinice bez rezervacija (čišći prikaz)
- **Multi-select mod**: omogućava označavanje više rezervacija odjednom za skupne akcije
- **Sažetak/analitika**: gumb za prikaz sažetka statistike (zauzeto/slobodno)
- **Tutorial**: pri prvom otvaranju prikazuje se kratki vodič kako koristiti kalendar

---

## 3. Mjesečni kalendar

### 3.1 Što vlasnik vidi

Mjesečni kalendar prikazuje **klasični mjesečni prikaz** (7 stupaca × 6 redova) s prilagođenim ćelijama i **agendaom** ispod. Za razliku od Timeline kalendara, ovdje vlasnik gleda **jednu smještajnu jedinicu u jednom trenutku**.

Idealan je za:
- Pregled mjesečne zauzetosti jedne jedinice
- Brzi uvid koliko rezervacija ima na određeni dan
- Kronološku listu nadolazećih rezervacija (Schedule prikaz)

### 3.2 Dva prikaza (prebacivanje)

Mjesečni kalendar ima **dva prikaza** koji se prebacuju gumbom u gornjoj traci:

#### Mjesečni prikaz (Month View)
- Klasična mreža 7×6 s danima u mjesecu
- **Prilagođene ćelije** sa tri elementa:
  - **Broj dana** (gore lijevo) — današnji dan istaknut krugom u boji
  - **Značka broja rezervacija** (gore desno) — mali badge s brojem rezervacija na taj dan
  - **Statusne točkice** (dolje sredina) — obojene točke koje pokazuju koje statuse imaju rezervacije tog dana (zelena = potvrđena, narančasta = čekanje, itd.)
- **Agenda panel** ispod kalendara: klik na dan prikazuje listu rezervacija za taj dan
- Dani iz prethodnog/sljedećeg mjeseca prikazani su bljeđom bojom

#### Schedule prikaz (Lista/Raspored)
- **Kronološka lista** svih nadolazećih rezervacija
- Grupiranje po tjednima s mjesečnim zaglavljima
- Svaka rezervacija prikazuje:
  - Ime gosta (ili naziv platforme ako nema imena)
  - Naziv smještajne jedinice i broj noćenja
  - Ikona platforme (Booking.com, Airbnb, Widget, iCal)
  - Značka statusa (potvrđena, čekanje, završena, otkazana)
  - Ikona upozorenja ako postoji konflikt

### 3.3 Filtriranje po smještajnoj jedinici

Na vrhu ekrana nalazi se **dropdown izbornik** za odabir smještajne jedinice. Vlasnik bira jednu jedinicu, a kalendar prikazuje samo rezervacije za tu jedinicu.

- Automatski se odabire prva jedinica pri otvaranju
- Ako vlasnik ima samo jednu jedinicu, dropdown i dalje postoji ali s jednim izborom

### 3.4 Navigacija

- **Strelice lijevo/desno**: prebacivanje na prethodni/sljedeći mjesec
- **Gumb "Danas"**: skok na trenutni mjesec i današnji dan
- **Birač datuma**: klik na naslov mjeseca/godine otvara birač za skok na bilo koji mjesec
- **Granice datuma**: kalendar je ograničen na **1 godinu unazad** do **2 godine unaprijed** — vlasnik ne može scrollati beskonačno u prošlost ili budućnost

### 3.5 Kreiranje rezervacije

- **Klik na prazan dan** u mjesečnom prikazu: otvara dijalog za kreiranje nove rezervacije s unaprijed popunjenim datumom i odabranom jedinicom
- Ako nema rezervacija, prikazuje se **prazno stanje** s gumbom "Kreiraj rezervaciju"

### 3.6 Pregled i uređivanje rezervacije

- **Klik na rezervaciju** (u agendi ili mjesečnom prikazu): otvara dijalog za uređivanje
- Dijalog je isti kao u Timeline kalendaru (promjena datuma, broja gostiju, statusa, bilješki)
- Isto upozorenje o preklapanju i platformama

### 3.7 Legenda statusa

Ispod dropdown-a prikazuje se **legenda boja**:
- Zelena = Potvrđena
- Narančasta = Čekanje
- Plava = Završena
- Siva = Otkazana

### 3.8 Osvježavanje podataka

- **Povlačenje prema dolje** (pull-to-refresh): osvježava sve podatke s poslužitelja
- Podaci se također **automatski osvježavaju** u pozadini kada se promijeni bilo koja rezervacija (real-time listener)

---

## 4. Dijalog za kreiranje rezervacije

Kada vlasnik kreira novu rezervaciju (iz bilo kojeg kalendara), otvara se dijalog s ovim poljima:

### 4.1 Obavezna polja

| Polje | Opis |
|-------|------|
| **Smještajna jedinica** | Dropdown s listom svih jedinica (unaprijed popunjeno ako je kliknuto iz kalendara) |
| **Datum prijave** | Birač datuma za check-in |
| **Datum odjave** | Birač datuma za check-out (mora biti nakon check-ina) |
| **Ime gosta** | Puno ime gosta |
| **Email gosta** | Email adresa (validacija formata) |
| **Telefon gosta** | Broj telefona |

### 4.2 Dodatna polja

| Polje | Opis |
|-------|------|
| **Broj gostiju** | Brojčano polje |
| **Ukupna cijena** | Iznos u € |
| **Način plaćanja** | Gotovina / Kartica / Bankovni prijenos / Ostalo |
| **Interne bilješke** | Slobodno tekstualno polje (vidljivo samo vlasniku) |

### 4.3 Validacije

- Sva obavezna polja moraju biti popunjena
- Email mora biti u ispravnom formatu
- Datum odjave mora biti nakon datuma prijave (automatski se prilagođava ako vlasnik izabere krivi redoslijed)
- **Provjera preklapanja**: ako se novi termin preklapa s postojećom rezervacijom, prikazuje se upozorenje s detaljima konflikta. Vlasnik može **nasilno spremiti** unatoč preklapanju.

---

## 5. Dijalog za uređivanje rezervacije

Klik na postojeću rezervaciju otvara dijalog za uređivanje:

### 5.1 Što se može uređivati

| Polje | Opis |
|-------|------|
| **Datum prijave** | Promjena check-in datuma |
| **Datum odjave** | Promjena check-out datuma |
| **Broj gostiju** | +/- gumbi za povećanje/smanjenje |
| **Status** | Dropdown: Potvrđena, Čekanje, Završena, Otkazana |
| **Interne bilješke** | Slobodno tekstualno polje |

### 5.2 Što se NE može uređivati

- Ime gosta (samo za čitanje)
- Email i telefon gosta (uređuju se na stranici s detaljima rezervacije)
- Način plaćanja i cijena (uređuju se na stranici s detaljima rezervacije)

### 5.3 Upozorenja pri spremanju

1. **Preklapanje datuma**: ako promijenjeni datumi kolidiraju s drugom rezervacijom, prikazuje se poruka s imenom gosta i datumima konflikta — **sprema se blokira**
2. **Platformska integracija**: ako je jedinica povezana s Booking.com, Airbnb ili drugom platformom, prikazuje se upozorenje da vlasnik ručno ažurira datume na tim platformama

---

## 6. Usporedba dvaju kalendara

| Značajka | Timeline kalendar | Mjesečni kalendar |
|----------|-------------------|-------------------|
| **Prikaz** | Gantt-dijagram (svi objekti u redovima) | Klasični mjesec + agenda |
| **Objekti odjednom** | Svi objekti vidljivi paralelno | Jedna jedinica (dropdown filter) |
| **Idealan za** | Pregled zauzetosti svih objekata | Detaljan pregled jednog objekta |
| **Kreiranje rezervacije** | Dugi pritisak na ćeliju ili + gumb | Klik na prazan dan ili gumb |
| **Uređivanje** | Klik na blok | Klik na rezervaciju u agendi |
| **Navigacija** | Strelice, Today, birač datuma | Strelice, Today, birač datuma |
| **Status boje** | Zelena/Narančasta/Plava/Siva | Zelena/Narančasta/Plava/Siva |
| **Ikone platformi** | Da (na bloku) | Da (u Schedule prikazu) |
| **Detekcija konflikata** | Značka s brojem + auto-scroll | Vizualno u ćeliji (crveni obrub) |
| **Dark/Light tema** | Da | Da |
| **Real-time ažuriranje** | Da | Da |
| **Min/Max datum** | Bez ograničenja (beskonačno scroll) | 1 godina unazad — 2 godine unaprijed |

---

## 7. Česta pitanja (FAQ)

### 7.1 Kako da vidim sve objekte odjednom?

Koristite **Timeline kalendar** — svi objekti se prikazuju kao redovi, a rezervacije kao blokovi. Otvorite Drawer > Kalendar > Timeline.

### 7.2 Kako da vidim detaljni pregled po danu za jedan objekt?

Koristite **Mjesečni kalendar** — odaberite objekt iz dropdown-a, kliknite na dan za prikaz rezervacija u agendi. Otvorite Drawer > Kalendar > Mjesečni kalendar.

### 7.3 Kako prepoznajem s koje platforme dolazi rezervacija?

U Timeline kalendaru, ikona platforme prikazuje se u gornjem desnom kutu bloka. U Mjesečnom kalendaru (Schedule prikaz), ikona platforme prikazuje se lijevo od imena gosta. **B** = Booking.com, **A** = Airbnb, **W** = Direktna (widget).

### 7.4 Što znače obojene točkice u Mjesečnom kalendaru?

Točkice na dnu svake ćelije prikazuju **koji statusi rezervacija** postoje na taj dan. Zelena točka = potvrđena rezervacija, narančasta = rezervacija na čekanju, itd. Ako ima više rezervacija različitih statusa, prikazuje se više točkica.

### 7.5 Što znači broj u značci (gore desno u ćeliji)?

To je **ukupan broj rezervacija** na taj dan za odabranu smještajnu jedinicu.

### 7.6 Kako da kreiram rezervaciju za gosta koji zove telefonom?

1. Otvorite bilo koji kalendar
2. Pronađite željeni datum
3. Kliknite na prazan dan (Mjesečni) ili dugo pritisnite ćeliju (Timeline)
4. Popunite podatke gosta i spremite
5. Rezervacija se odmah prikazuje u kalendaru

### 7.7 Što ako se dvije rezervacije preklapaju?

- U **Timeline kalendaru** pojavljuje se **crvena značka** s brojem konflikata — kliknite za detalje
- U **Mjesečnom kalendaru** preklapajuće rezervacije imaju **crveni obrub**
- Pri kreiranju/uređivanju sustav **upozorava** na preklapanje i blokira spremanje (osim ako vlasnik ne potvrdi)

### 7.8 Mogu li prebaciti prikaz između Month i Schedule?

Da. U Mjesečnom kalendaru, kliknite **ikonu za prebacivanje prikaza** u gornjoj traci (ikona agende za Schedule, ikona kalendara za Month). Prebacivanje je trenutno.

### 7.9 Kako se osvježavaju podaci?

- **Automatski**: kalendar sluša promjene u bazi i osvježava se u realnom vremenu
- **Ručno**: povucite prema dolje (pull-to-refresh) u Mjesečnom kalendaru
- Rezervacije uvezene s Booking.com/Airbnb putem iCal sinkronizacije pojavljuju se automatski svakih **15 minuta**

### 7.10 Zašto ne vidim sve objekte u Mjesečnom kalendaru?

Mjesečni kalendar prikazuje **jednu smještajnu jedinicu** — koristite dropdown na vrhu za prebacivanje između jedinica. Ako želite vidjeti sve objekte odjednom, koristite Timeline kalendar.

### 7.11 Mogu li uređivati rezervacije uvezene s Booking.com ili Airbnb?

Da, ali s upozorenjem. Kada mijenjate datume rezervacije koja dolazi s vanjske platforme, sustav vas upozorava da **ručno ažurirate datume** i na toj platformi. BookBed ne može automatski promijeniti rezervaciju na Booking.com ili Airbnb — to mora vlasnik učiniti u svom extranet/host panelu.

### 7.12 Kako da skočim na određeni datum?

U oba kalendara:
1. Kliknite **gumb "Danas"** za skok na današnji datum
2. Kliknite **birač datuma** (ikona kalendara u toolbaru ili naslov mjeseca) za skok na bilo koji datum
3. Koristite **strelice lijevo/desno** za pomicanje po mjesecima (Mjesečni) ili danima (Timeline)
