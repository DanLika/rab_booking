# BookBed Owner Dashboard — Kompletna baza znanja za AI chatbot

## 1. Pregled Owner Dashboard-a

Owner Dashboard je glavni upravljački panel za vlasnike nekretnina u BookBed sustavu. Dostupan je kao:
- **Web aplikacija**: `app.bookbed.io`
- **Android aplikacija**: Google Play Store
- **iOS aplikacija**: App Store
- **PWA (Progressive Web App)**: instaliraj iz preglednika

Dashboard se sastoji od sljedećih glavnih stranica:
1. **Pregled (Dashboard)** — statistike i grafikoni
2. **Rezervacije (Bookings)** — upravljanje svim rezervacijama
3. **Kalendar (Calendar)** — vremenski prikaz zauzetosti
4. **Nekretnine (Properties)** — upravljanje smještajnim jedinicama
5. **FAQ** — česta pitanja s odgovorima
6. **Obavještenja (Notifications)** — sve obavijesti na jednom mjestu
7. **Profil (Profile)** — osobne postavke i račun

Ovaj dokument pokriva stranice: Rezervacije, Pregled, FAQ, Obavještenja i Profil.

---

## 2. Stranica Rezervacije (Bookings)

### 2.1 Pregled

Stranica Rezervacije prikazuje sve rezervacije vlasnika — i one kreirane kroz BookBed widget, i one uvezene s drugih platformi (Booking.com, Airbnb, itd.). Vlasnik ovdje odobrava, otkazuje, uređuje i prati sve rezervacije.

### 2.2 Dva pogleda

| Pogled | Opis | Najprikladniji za |
|--------|------|--------------------|
| **Card pogled** | Svaka rezervacija je kartica s ključnim podacima. 1 kolona na mobitelu, 2 kolone na desktopu | Brzi pregled, mobilne uređaje |
| **Tabela pogled** | Tablični prikaz u redovima s kolonama (ime gosta, datumi, status, iznos, izvor) | Desktop korisništvo, pregled više rezervacija odjednom |

Prebacivanje između pogleda vrši se klikom na ikonu u zaglavlju stranice (kartica / tablica).

### 2.3 Kartice za brzo filtriranje

Na vrhu stranice nalaze se kartice koje prikazuju broj rezervacija po statusu:
- **Sve** — ukupan broj svih rezervacija
- **Na čekanju** — rezervacije koje čekaju odobrenje vlasnika
- **Potvrđene** — odobrene i aktivne rezervacije
- **Otkazane** — otkazane rezervacije
- **Završene** — rezervacije čiji je boravak završen

Klikom na karticu filtrira se prikaz samo na taj status.

### 2.4 Statusi rezervacija

| Status | Značenje | Boja |
|--------|----------|------|
| **Na čekanju (Pending)** | Gost je kreirao rezervaciju, vlasnik je još nije odobrio | Žuta / Amber |
| **Potvrđena (Confirmed)** | Vlasnik je odobrio rezervaciju (ili je automatski potvrđena nakon Stripe plaćanja) | Zelena |
| **Otkazana (Cancelled)** | Rezervacija je otkazana (od strane vlasnika ili gosta) | Crvena |
| **Završena (Completed)** | Gost je završio boravak | Siva / Plava |

**Automatska promjena statusa:** Sustav automatski označava rezervacije kao "Završene" nakon datuma odjave (check-out). Ovo se izvršava svakodnevno u 2:00 ujutro. Ovo se odnosi samo na BookBed rezervacije — uvezene rezervacije s drugih platformi se ne mijenjaju automatski.

### 2.5 Filteri i pretraga

| Filter | Opis |
|--------|------|
| **Status** | Filtriraj po statusu (na čekanju, potvrđena, otkazana, završena) |
| **Nekretnina** | Filtriraj po nekretnini (korisno ako vlasnik ima više nekretnina) |
| **Raspon datuma** | Filtriraj po datumu dolaska (od-do) |
| **Pretraga** | Traži po imenu gosta, emailu, referenci rezervacije |

Gumb **"Očisti sve filtere"** vraća prikaz na početno stanje.

### 2.6 Kartice rezervacija (Card pogled)

Svaka kartica prikazuje:
- **Ime gosta** i kontakt podaci
- **Datum dolaska** (check-in) i **datum odlaska** (check-out)
- **Broj noći**
- **Status** (badge u boji)
- **Ukupna cijena**
- **Izvor rezervacije** (BookBed Widget, Booking.com, Airbnb, iCal, itd.)
- **Referenca rezervacije** (npr. BK-2024-001234)

Klikom na karticu otvara se **Dijalog s detaljima rezervacije**.

### 2.7 Dijalog s detaljima rezervacije

Dijalog prikazuje kompletne informacije o rezervaciji podijeljene u sekcije:

**1. Informacije o rezervaciji**
- Referenca rezervacije (npr. BK-2024-001234) — moguće kopirati
- Status (badge u boji)

**2. Informacije o gostu**
- Ime i prezime
- Email adresa (moguće kopirati dugim pritiskom)
- Telefon (ako je dostupan, moguće kopirati)
- Izvor (Booking.com, Airbnb, Widget, itd.) — samo za uvezene rezervacije

**3. Informacije o smještaju**
- Naziv nekretnine
- Naziv smještajne jedinice (apartman, soba)

**4. Detalji boravka**
- Datum dolaska (check-in)
- Datum odlaska (check-out)
- Broj noći
- Broj gostiju

**5. Informacije o plaćanju**
- Ukupna cijena (istaknuto)
- Plaćeni iznos
- Preostali iznos (zeleno ako plaćeno, crveno ako duguje)
- Metoda plaćanja (Stripe, Bankovni prijenos, Gotovina, Ostalo)
- Opcija plaćanja (Depozit ili Puni iznos) — ako je dostupno

**6. Napomene** (ako postoje)
- Napomene gosta unesene prilikom rezervacije

**7. Informacije o otkazivanju** (samo za otkazane)
- Datum otkazivanja
- Razlog otkazivanja

**Akcije u dijalogu:**
- **Uredi** — otvara dijalog za uređivanje rezervacije
- **Pošalji email** — šalje prilagođeni email gostu
- **Ponovno pošalji** — ponovno šalje email s potvrdom rezervacije

### 2.8 Akcije na rezervacijama

| Akcija | Dostupno za | Opis |
|--------|-------------|------|
| **Odobri** | Na čekanju | Mijenja status u "Potvrđena", šalje email gostu |
| **Odbij** | Na čekanju | Mijenja status u "Otkazana" s razlogom, šalje email gostu |
| **Završi** | Potvrđena (nakon odjave) | Označava rezervaciju kao završenu |
| **Otkaži** | Na čekanju, Potvrđena | Otkazuje rezervaciju s razlogom, gost prima email |
| **Uredi** | Sve osim otkazanih | Omogućava promjenu datuma, broja gostiju, cijene |
| **Premjesti** | Potvrđena | Premješta rezervaciju u drugi apartman (drag-and-drop u kalendaru ili putem izbornika) |
| **Pošalji email** | Sve | Šalje prilagođeni email gostu |
| **Obriši** | Sve | Trajno briše rezervaciju (s potvrdom) |

### 2.9 Kreiranje ručne rezervacije

Vlasnik može kreirati rezervaciju ručno klikom na **"Dodaj rezervaciju"**:
1. Odabere nekretninu i smještajnu jedinicu
2. Unese datume (check-in, check-out)
3. Unese podatke gosta (ime, email, telefon)
4. Unese cijenu i napomene
5. Sustav automatski provjerava da li se datumi preklapaju s postojećim rezervacijama

Ako postoji preklapanje, prikazuje se **upozorenje o overbookingu** s popisom konfliktnih rezervacija.

### 2.10 Overbooking detekcija

Sustav automatski detektira preklapanja datuma:
- Kada nova rezervacija stigne putem widgeta, a datumi su već zauzeti
- Kada vlasnik ručno kreira rezervaciju za zauzete datume
- Crveni badge s brojem konflikata prikazuje se na rezervaciji

**Automatsko odbijanje:** Kada vlasnik potvrdi jednu od konfliktnih rezervacija, ostale rezervacije na čekanju za iste datume automatski se odbijaju.

### 2.11 Uvezene rezervacije (Imported Tab)

Tab **"Uvezene"** prikazuje samo rezervacije uvezene s drugih platformi putem iCal sinkronizacije:
- Booking.com rezervacije
- Airbnb rezervacije
- Ostale platforme (Adriagate, Atraveo, itd.)

Uvezene rezervacije prikazuju badge s nazivom platforme (npr. "Booking.com" u plavoj boji, "Airbnb" u crvenoj).

**Važno:** Uvezene rezervacije se ne mogu uređivati jer su kreirane na drugoj platformi. Vlasnik ih može samo pregledavati i premještati između apartmana.

### 2.12 Slanje prilagođenog emaila gostu

Vlasnik može slati email gostu iz dijaloga rezervacije:
- **Potvrda** — standardni email s potvrdom
- **Podsjetnik** — podsjetnik za plaćanje ili dolazak
- **Otkazivanje** — obavijest o otkazivanju
- **Prilagođeni email** — slobodan tekst koji vlasnik sam napiše

Email se šalje na email adresu gosta povezanu s rezervacijom.

---

## 3. Stranica Pregled (Dashboard)

### 3.1 Pregled

Dashboard stranica daje vlasnicima brzi pregled poslovanja kroz ključne statistike, grafikone i nedavnu aktivnost. Ovo je prva stranica koja se prikazuje nakon prijave.

### 3.2 Četiri KPI kartice

Na vrhu stranice prikazane su četiri kartice s ključnim pokazateljima:

| KPI | Ikona | Opis |
|-----|-------|------|
| **Zarada** | € | Ukupni prihod u odabranom razdoblju (samo potvrđene i završene rezervacije) |
| **Rezervacije** | Kalendar | Ukupan broj rezervacija u razdoblju (samo potvrđene i završene) |
| **Nadolazeći dolasci** | Raspored | Broj gostiju koji dolaze u nadolazećim danima |
| **Popunjenost** | Grafikon | Postotak zauzetih noći u odnosu na ukupno dostupne (npr. "85.5%") |

**Važno:** Statistike zarade, broja rezervacija i popunjenosti uključuju **samo potvrđene i završene rezervacije**. Rezervacije na čekanju (pending) se **ne računaju** — jer još nisu sigurne.

### 3.3 Vremenski periodi

Vlasnik bira vremenski period za statistike pomoću oznaka (chips):

| Period | Opis |
|--------|------|
| **Zadnjih 7 dana** | Posljednjih 7 dana od danas (zadano) |
| **Zadnjih 30 dana** | Posljednjih 30 dana od danas |
| **Zadnjih 90 dana** | Posljednjih 90 dana od danas (tromjesečje) |
| **Zadnjih 365 dana** | Posljednjih 365 dana od danas (godina) |

Ovi periodi koriste **klizne prozore** (rolling windows), što znači da se automatski ažuriraju svaki dan. Na primjer, "Zadnjih 30 dana" uvijek prikazuje podatke od danas unatrag 30 dana.

### 3.4 Grafikoni

Dashboard prikazuje dva grafikona ispod KPI kartica:

**1. Grafikon zarade (Revenue Chart)**
- Linijski grafikon s popunjenom površinom
- Prikazuje zaradu po danu/tjednu/mjesecu (ovisno o odabranom periodu)
- Vrijednost u eurima prikazana iznad svake točke
- Hover tooltip za detalje

**2. Grafikon rezervacija (Bookings Chart)**
- Stupčasti grafikon
- Prikazuje broj rezervacija po danu/tjednu/mjesecu
- Broj rezervacija prikazan iznad svakog stupca

**Grupiranje podataka na grafikonima:**
- Zadnjih 7 dana → po danu
- Zadnjih 30 dana → po tjednu
- Zadnjih 90 dana → po tjednu
- Zadnjih 365 dana → po mjesecu

### 3.5 Nedavna aktivnost

Ispod grafikona prikazuje se lista nedavnih događaja:
- Nova rezervacija kreirana
- Rezervacija potvrđena
- Rezervacija otkazana
- Rezervacija završena

Svaki događaj prikazuje ime gosta, vrstu događaja i vrijeme. Klikom na događaj otvara se stranica s detaljima rezervacije.

### 3.6 Ekran dobrodošlice (za nove korisnike)

Vlasnici koji još nemaju nekretnine vide poseban **ekran dobrodošlice** umjesto standardnog dashboarda:

- Personalizirani pozdrav: **"Dobrodošli, {Ime}!"**
- Tri kartice s brzim akcijama:
  1. **Dodaj nekretninu** — vodi na formu za kreiranje nekretnine
  2. **Uvezi rezervacije** — vodi na iCal sinkronizaciju
  3. **Postavi plaćanja** — vodi na Stripe Connect integraciju

Ove kartice pomažu novim korisnicima da brzo postave sustav i počnu koristiti platformu.

---

## 4. FAQ stranica

### 4.1 Pregled

FAQ (Frequently Asked Questions) stranica sadrži odgovore na najčešća pitanja vlasnika, organizirana po kategorijama. Vlasnik može pretraživati pitanja ili filtrirati po kategoriji.

### 4.2 Kategorije

| Kategorija | Broj pitanja | Primjeri pitanja |
|------------|--------------|------------------|
| **Sve** | Sva pitanja | (prikazuje kompletnu listu) |
| **Općenito** | 3 | Što je ova platforma? Da li postoji mobilna aplikacija? Koliko košta? |
| **Rezervacije** | 5 | Kako funkcionira booking flow? Kako odobriti rezervaciju? Kako otkazati? Kako spriječiti overbooking? Kako blokirati datume? |
| **Plaćanja** | 4 | Koje metode plaćanja podržavate? Koliki depozit mogu zahtijevati? Kada dolaze isplate? Što ako gost zahtijeva refund? |
| **Widget** | 5 | Kako dodati widget na sajt? Mogu li prilagoditi izgled? Radi li na mobilnim? Više widgeta na stranici? Podržava li više jezika? |
| **iCal Sync** | 5 | Kako povezati Booking.com? Koliko često se sinkronizira? Vidi li se ime gosta? Više platformi istovremeno? Export na Booking.com? |
| **Tehnička podrška** | 4 | Widget se ne učitava? Zaboravio sam lozinku? Email ne stiže? Kako kontaktirati podršku? |

**Ukupno: ~26 pitanja i odgovora**

### 4.3 Pretraga i filtriranje

- **Polje za pretragu**: Vlasnik unosi ključne riječi i sustav filtrira pitanja koja sadrže taj tekst (u pitanju ili odgovoru)
- **Oznake kategorija**: Horizontalno pomične oznake za brzo filtriranje po kategoriji
- **Brojač rezultata**: "Pronađeno: X rezultata" prikazuje se ispod pretrage
- **Prazan rezultat**: Ako pretraga ne pronađe ništa, prikazuje se poruka "Nema rezultata — Pokušajte s drugom pretragom ili kategorijom"

### 4.4 Prikaz pitanja

Svako pitanje je prikazano kao proširiva kartica (expandable card):
- Klikom na pitanje otvara se odgovor ispod
- Oznaka kategorije prikazana je na svakoj kartici (npr. "Rezervacije", "Plaćanja")
- Samo jedno pitanje može biti otvoreno istovremeno

### 4.5 Najvažnija pitanja i odgovori

**Općenito:**

> **P: Što je ova platforma?**
> O: Ovo je multi-tenant booking platforma koja omogućava vlasnicima apartmana da upravljaju rezervacijama, primaju plaćanja i ugrade widget za rezervacije na svoju web stranicu. Platforma podržava Stripe plaćanja, iCal sinkronizaciju s Booking.com/Airbnb, i više jezika.

> **P: Da li postoji mobilna aplikacija?**
> O: Da! Owner aplikacija je dostupna za Android i iOS. Možete upravljati rezervacijama, pregledati kalendar, odobriti/otkazati rezervacije i primati obavijesti na telefon.

> **P: Koliko košta korištenje?**
> O: Platforma trenutno ima trial verziju. Planirane su tri pretplate: Trial (1 nekretnina), Premium (5 nekretnina), i Enterprise (neograničeno). Stripe provizija (1.4% + 0.25€) se naplaćuje odvojeno.

**Rezervacije:**

> **P: Kako funkcionira booking flow?**
> O: Postoje tri moda: (1) Calendar Only — gosti vide samo dostupnost i zovu vas, (2) Booking Pending — gosti kreiraju rezervaciju koja čeka vašu potvrdu, (3) Booking Instant — gosti mogu odmah rezervirati i platiti. Mod se odabire u Widget Settings.

> **P: Kako odobriti rezervaciju?**
> O: Idite na Rezervacije → Pending rezervacije → Kliknite na rezervaciju → "Odobri". Email će automatski biti poslan gostu s potvrdom.

> **P: Kako spriječiti overbooking?**
> O: Koristite iCal sinkronizaciju da uvezete rezervacije s Booking.com, Airbnb i drugih platformi. Sve rezervacije će se prikazati u kalendaru kao zauzeti dani.

> **P: Kako ručno blokirati datume?**
> O: U kalendaru, kliknite na datum ili raspon datuma → "Blokiraj" → Unesite razlog (neobavezno). Blokirani dani će biti prikazani kao nedostupni u widgetu.

**Plaćanja:**

> **P: Koje metode plaćanja podržavate?**
> O: Podržavamo: (1) Stripe plaćanja karticom (instant), (2) Bankovna uplata (ručna potvrda), (3) Plaćanje po dolasku. Svaku metodu možete omogućiti/onemogućiti u Widget Settings.

> **P: Koliki depozit mogu zahtijevati?**
> O: Depozit od 0% do 100% ukupne cijene. Standardno je 20%. Preostali iznos gost plaća pri dolasku. Podesite u Widget Settings.

> **P: Kada dolaze isplate od Stripe-a?**
> O: Stripe automatski prebacuje sredstva na vaš bankovni račun svakih 7 dana. Nakon prvog mjeseca možete promijeniti na dnevne isplate u Stripe nadzornoj ploči.

**Widget:**

> **P: Kako dodati widget na moj sajt?**
> O: Idite na Unit Form → "Generiraj kod" → Kopirajte iframe kod → Zalijepite u HTML vaše stranice. Detaljnije uputstvo je na stranici "Ugradnja widgeta" u navigacijskom izborniku.

> **P: Mogu li prilagoditi izgled widgeta?**
> O: Da! U Widget Settings možete: promijeniti primarnu boju, uploadovati logo, prilagoditi custom message, i omogućiti/onemogućiti "Powered by" branding.

> **P: Da li widget podržava više jezika?**
> O: Da! Widget podržava hrvatski, engleski, njemački i talijanski jezik. Jezik se može dodati u URL (&language=en) ili omogućiti language selector u widgetu.

**iCal Sync:**

> **P: Kako povezati Booking.com kalendar?**
> O: Prijavite se na Booking.com Extranet → Calendar → Reservations export → Kopirajte iCal URL → Dodajte u aplikaciju pod iCal Sinkronizacija.

> **P: Koliko često se sinkronizira?**
> O: Automatski sync se izvršava svakih 15 minuta. Možete ručno pokrenuti sync bilo kada klikom na "Sync Now" dugme.

> **P: Hoće li gosti vidjeti imena gostiju s drugih platformi?**
> O: Ne. iCal protokol prenosi samo datume rezervacije (check-in/check-out), ne i osobne podatke. Rezervacije će biti prikazane kao "Platform Gost" u vašem kalendaru.

**Tehnička podrška:**

> **P: Widget se ne učitava na mom sajtu?**
> O: Provjerite: (1) Da li ste zalijepili kompletan iframe kod, (2) Da li je unit ID točan, (3) Browser konzolu za greške (F12). Ako problem traje, kontaktirajte podršku.

> **P: Kako kontaktirati podršku?**
> O: Pošaljite email na podršku s detaljnim opisom problema. Uključite snimke zaslona ako je moguće. Odgovaramo unutar 24-48h.

---

## 5. Stranica Obavještenja (Notifications)

### 5.1 Pregled

Stranica obavještenja prikazuje sve obavijesti vlasnika grupirane po datumu. Obavijesti stižu kada se dogodi važan događaj vezan uz rezervacije ili plaćanja.

### 5.2 Vrste obavijesti

| Vrsta | Ikona | Boja | Opis |
|-------|-------|------|------|
| **Nova rezervacija** | Kalendar s kvačicom | Teal | Gost je kreirao novu rezervaciju |
| **Rezervacija ažurirana** | Kalendar s olovkom | Crvena | Rezervacija je izmijenjena |
| **Rezervacija otkazana** | Kalendar s X | Crvena | Gost ili vlasnik je otkazao |
| **Plaćanje primljeno** | Novčanica | Primarna | Potvrđena uplata od gosta |
| **Sustav** | Zvonce | Siva | Sistemska poruka (ažuriranja, upozorenja) |

### 5.3 Prikaz obavijesti

- Obavijesti su **grupirane po datumu** (Danas, Jučer, raniji datumi)
- Svaka obavijest prikazuje:
  - Ikona s obojenom pozadinom (prema vrsti)
  - **Naslov** (podebljano ako je nepročitano)
  - **Poruka** (npr. "Ivan Horvat je kreirao novu rezervaciju.")
  - **Vrijeme** (npr. "Upravo sada", "2h prije", "3d prije")
  - **Plava točka** ako je nepročitano

- Klikom na obavijest:
  - Označava se kao pročitana
  - Ako je vezana uz rezervaciju, otvara se stranica s tom rezervacijom

### 5.4 Formati vremena

| Vrijeme | Prikaz |
|---------|--------|
| Manje od minute | "Upravo sada" |
| Minuti | "5 min prije" |
| Sati | "2h prije" |
| Dani | "3d prije" |
| Tjedni | "2t prije" |
| Mjeseci | "1mj prije" |

### 5.5 Akcije

**Normalni mod:**
- **Povuci za brisanje** (swipe desno) — briše pojedinačnu obavijest s potvrdom

**Mod odabira (Selection Mode):**
- Aktivira se klikom na FAB (floating action button) ili dugme "Odaberi"
- **Odaberi sve / Poništi odabir** — za brzi odabir
- **Obriši odabrane** — briše sve odabrane obavijesti (s potvrdom i brojem)
- **Obriši sve** — briše SVE obavijesti (dostupno iz izbornika ⋮)

### 5.6 Prazan ekran

Kada nema obavijesti, prikazuje se:
- Ikona zvonca
- Naslov: **"Nema obavještenja"**
- Podnaslov: "Ovdje ćete vidjeti sva vaša obavještenja"
- Korisne informacije: "Primit ćete obavijesti za:"
  - Nove zahtjeve za rezervaciju
  - Potvrde plaćanja
  - Otkazivanja rezervacija
  - Podsjetnike za check-in

### 5.7 Push obavijesti (FCM)

BookBed podržava **push obavijesti** na web pregledniku i mobilnim uređajima:
- Kada stigne nova rezervacija dok vlasnik nema otvoren dashboard, prikazuje se **sistemska obavijest** u pregledniku/na telefonu
- Kada vlasnik ima otvoren dashboard, prikazuje se **snackbar** (kratka poruka) na dnu ekrana s dugmetom "Pogledaj"
- Push obavijesti zahtijevaju dozvolu preglednika/uređaja pri prvoj prijavi

### 5.8 Postavke obavijesti

Postavke obavijesti dostupne su iz **Profil → Postavke obavijesti** ili putem ikone u zaglavlju stranice obavijesti.

**Kritične obavijesti (uvijek se šalju, ne mogu se isključiti):**
- Novi zahtjevi za rezervaciju i čekanja na odobrenje
- Potvrde rezervacija
- Otkazivanja rezervacija

**Opcionalne obavijesti (mogu se isključiti):**

| Kategorija | Opis |
|------------|------|
| **Rezervacije** | Emailovi za instant rezervacije. Rezervacije na čekanju se uvijek šalju. |
| **Podsjetnici za plaćanje** | Opcionalni emailovi o plaćanjima. Početne Stripe potvrde se uvijek šalju. |
| **Sinkronizacija kalendara** | Upozorenja iCal sinkronizacije i konflikti u kalendaru |
| **Marketing i ažuriranja** | Novosti platforme, savjeti za vlasnike i ažuriranja značajki |

Za svaku kategoriju vlasnik može uključiti/isključiti:
- **Email obavijesti**
- **Push obavijesti**

---

## 6. Stranica Profil (Profile)

### 6.1 Pregled

Stranica Profil sadrži osobne postavke vlasnika, upravljanje računom, postavke aplikacije i pravne dokumente. Organizirana je u logične sekcije.

### 6.2 Zaglavlje profila

Na vrhu stranice prikazuju se:
- **Avatar** — profilna slika ili inicijali imena
- **Ime i prezime** vlasnika
- **Email adresa** u obliku oznake (badge)
- **Postotak dovršenosti profila** (ako je manje od 100%)
  - Traka napretka prikazuje koliko je profil popunjen
  - Sugestija za dovršavanje (npr. "Dodajte broj telefona za veću vidljivost")

### 6.3 Banner pretplate (samo za trial korisnike)

Trial korisnici vide banner s pozivom na nadogradnju:
- Gradijentna pozadina u premium boji
- Naslov i opis pogodnosti
- Dugme **"Započnite"** koje vodi na stranicu pretplate
- Banner se **ne prikazuje** za korisnike s premium ili enterprise pretplatom

### 6.4 Sekcija: Postavke računa

| Stavka | Opis |
|--------|------|
| **Uredi profil** | Otvara formu za uređivanje: ime, prezime, email, telefon, adresa, grad, poštanski broj, država |
| **Promijeni lozinku** | Otvara formu za promjenu lozinke (skriveno za korisnike prijavljene putem Google-a ili Apple-a) |
| **Postavke obavijesti** | Otvara bottom sheet s opcijama za email i push obavijesti |
| **Pretplata** | Vodi na stranicu za upravljanje pretplatom (skriveno ako admin postavi `hideSubscription`) |

### 6.5 Sekcija: Postavke aplikacije

| Stavka | Opcije |
|--------|--------|
| **Jezik** | Hrvatski, Engleski |
| **Tema** | Svijetla, Tamna, Sistemska (prati postavke uređaja) |

Promjena jezika i teme primjenjuje se odmah bez potrebe za ponovnom prijavom.

### 6.6 Sekcija: Pomoć i podrška

| Stavka | Opis |
|--------|------|
| **Pomoć i podrška** | Otvara email klijent za slanje poruke timu za podršku |
| **O aplikaciji** | Prikazuje verziju aplikacije, informacije o tvrtki |

### 6.7 Sekcija: Pravni dokumenti

| Dokument | Opis |
|----------|------|
| **Uvjeti korištenja** | Pravila korištenja platforme |
| **Pravila privatnosti** | Kako se prikupljaju i koriste osobni podaci |
| **Pravila o kolačićima** | Informacije o kolačićima na web stranici |

### 6.8 Zona opasnosti (Danger Zone)

**Brisanje računa** — nepovratna akcija:
1. Vlasnik klikne "Obriši račun"
2. Otvara se dijalog upozorenja s popisom posljedica:
   - Svi podaci o nekretninama će biti obrisani
   - Sve rezervacije će biti otkazane
   - Pristup widgetu na web stranicama vlasnika će prestati
3. Vlasnik mora potvrditi lozinkom (za dodatnu sigurnost)
4. Nakon potvrde, račun se trajno briše

**Važno:** Brisanje računa je **nepovratno**. Svi podaci o nekretninama, rezervacijama, postavkama i widgetima bit će trajno izbrisani.

### 6.9 Odjava (Logout)

Dugme za odjavu nalazi se na dnu stranice. Klikom na njega:
- Korisnik se odlogira iz sustava
- Preusmjeravanje na stranicu za prijavu
- FCM tokeni za push obavijesti se brišu
- Lokalna pohrana se čisti

### 6.10 Uređivanje profila — detalji

Forma za uređivanje profila sadrži sljedeća polja:

| Polje | Obavezno | Opis |
|-------|----------|------|
| Ime | Da | Ime vlasnika |
| Prezime | Da | Prezime vlasnika |
| Email | Da | Email adresa (promjena zahtijeva verifikaciju) |
| Telefon | Ne | Kontakt telefon |
| Adresa | Ne | Ulica i kućni broj |
| Grad | Ne | Grad |
| Poštanski broj | Ne | Poštanski broj |
| Država | Ne | Država (padajući izbornik) |
| Profilna slika | Ne | Upload slike (JPG, PNG, HEIC podržani) |

**Promjena emaila:** Ako vlasnik promijeni email adresu, mora potvrditi novi email putem verifikacijskog linka koji se šalje na novu adresu. Dok ne potvrdi, prijava koristi stari email.

### 6.11 Stripe Connect integracija

Stripe Connect omogućava vlasnicima primanje kartičnih plaćanja od gostiju. Postavlja se putem:

**Navigacijski izbornik → Integracije → Stripe**

1. Vlasnik klikne "Poveži Stripe račun"
2. Preusmjeren je na Stripe stranicu za onboarding
3. Stripe zahtijeva: poslovne informacije, bankovni račun, identifikaciju
4. Nakon završetka, vlasnik se vraća u BookBed dashboard
5. Status "Povezano" prikazuje se na stranici integracija

**Stripe Connect Standard model:**
- Novac ide **direktno** na bankovni račun vlasnika
- BookBed **ne uzima** proviziju od transakcija
- Stripe naplaćuje svoju standardnu proviziju (1.4% + €0.25 po transakciji u EU)
- Vlasnik je odgovoran za porez

---

## 7. Česta pitanja (FAQ za chatbot)

### Pitanja o Rezervacijama

**P: Kako da vidim sve svoje rezervacije?**
O: Otvorite stranicu "Rezervacije" iz navigacijskog izbornika. Možete pregledavati rezervacije u card ili tabela pogledu, filtrirati po statusu, nekretnini ili datumu, i pretraživati po imenu gosta.

**P: Što znači status "Na čekanju"?**
O: Rezervacija na čekanju znači da je gost kreirao rezervaciju, ali vlasnik je još nije odobrio. Vlasnik mora kliknuti na rezervaciju i odabrati "Odobri" ili "Odbij".

**P: Kako odobriti rezervaciju?**
O: Na stranici Rezervacije kliknite na rezervaciju sa statusom "Na čekanju" → u dijalogu s detaljima kliknite "Odobri". Gost će automatski primiti email s potvrdom.

**P: Kako otkazati rezervaciju?**
O: Kliknite na rezervaciju → "Otkaži" → Unesite razlog otkazivanja → Potvrdite. Gost će primiti email obavijest o otkazivanju.

**P: Kako premjestiti rezervaciju u drugi apartman?**
O: Možete premjestiti rezervaciju putem kalendara (drag-and-drop) ili iz dijaloga rezervacije (izbornik akcija → "Premjesti"). Sustav će provjeriti dostupnost u odredišnom apartmanu.

**P: Što se dogodi s overbookingom?**
O: Ako imate više rezervacija na čekanju za iste datume, kada odobrite jednu, sustav automatski odbija ostale. Koristite iCal sinkronizaciju za sprečavanje overbookinga s drugih platformi.

**P: Mogu li ručno kreirati rezervaciju?**
O: Da. Na stranici Rezervacije kliknite "Dodaj rezervaciju" → unesite podatke gosta i datume. Sustav će upozoriti ako postoji preklapanje s postojećim rezervacijama.

**P: Kako vidjeti uvezene rezervacije s Booking.com/Airbnb?**
O: Na stranici Rezervacije kliknite tab "Uvezene". Tu su prikazane sve rezervacije uvezene putem iCal sinkronizacije, s oznakom platforme.

### Pitanja o Dashboardu

**P: Zašto dashboard pokazuje nula zarade iako imam rezervacije?**
O: Dashboard prikazuje samo zaradu od **potvrđenih i završenih** rezervacija. Rezervacije na čekanju se ne računaju. Provjerite da li ste odobrili vaše rezervacije.

**P: Kako promijeniti vremenski period na dashboardu?**
O: Kliknite na jednu od oznaka iznad grafikona: "Zadnjih 7 dana", "Zadnjih 30 dana", "Zadnjih 90 dana" ili "Zadnjih 365 dana".

**P: Što su "Nadolazeći dolasci"?**
O: Pokazuje broj gostiju čiji je check-in u skoroj budućnosti. Ovo vam pomaže da se pripremite za dolaske.

**P: Što je popunjenost (occupancy rate)?**
O: Postotak noći koje su bile zauzete (potvrđene + završene) u odnosu na ukupan broj dostupnih noći u odabranom razdoblju. Na primjer, 75% znači da je 3/4 vaših noći bilo zauzeto.

### Pitanja o Obavještenjima

**P: Kako omogućiti push obavijesti?**
O: Prilikom prve prijave, preglednik/uređaj će vas pitati za dozvolu. Kliknite "Dopusti". Ako ste odbili, idite u postavke preglednika i omogućite obavijesti za BookBed.

**P: Mogu li isključiti neke obavijesti?**
O: Da, ali samo opcionalne. Idite na Profil → Postavke obavijesti. Kritične obavijesti (nove rezervacije, potvrde, otkazivanja) se uvijek šalju i ne mogu se isključiti.

**P: Zašto imam nepročitane obavijesti?**
O: Nepročitane obavijesti označene su plavom točkom. Kliknite na obavijest da je označite kao pročitanu. Svaka nova rezervacija, plaćanje ili otkazivanje generira obavijest.

**P: Kako obrisati sve obavijesti?**
O: Na stranici obavijesti kliknite ikonu izbornika (⋮) → "Obriši sve". Ili uđite u mod odabira (dugme "Odaberi") pa odaberite i obrišite specifične obavijesti.

### Pitanja o Profilu

**P: Kako promijeniti email adresu?**
O: Idite na Profil → Uredi profil → Promijenite email → Spremite. Na novu email adresu bit će poslan verifikacijski link koji morate potvrditi.

**P: Kako promijeniti lozinku?**
O: Idite na Profil → Promijeni lozinku → Unesite trenutnu lozinku i novu lozinku → Spremite. Napomena: Ova opcija nije dostupna ako ste se prijavili putem Google-a ili Apple-a.

**P: Kako promijeniti jezik aplikacije?**
O: Idite na Profil → Jezik → Odaberite željeni jezik. Promjena se primjenjuje odmah.

**P: Kako promijeniti temu (svijetla/tamna)?**
O: Idite na Profil → Tema → Odaberite Svijetla, Tamna ili Sistemska. Sistemska prati postavke vašeg uređaja.

**P: Kako obrisati svoj račun?**
O: Idite na Profil → Zona opasnosti → Obriši račun. Ovo je nepovratna akcija — svi podaci će biti trajno izbrisani. Morate potvrditi lozinkom.

**P: Kako povezati Stripe za kartična plaćanja?**
O: Idite na Integracije → Stripe → "Poveži Stripe račun". Bit ćete preusmjereni na Stripe stranicu za kreiranje/povezivanje računa. Nakon završetka, gosti mogu plaćati karticom kroz widget.

**P: Koja je razlika između trial i premium pretplate?**
O: Trial verzija dopušta 1 nekretninu. Premium dopušta do 5 nekretnina. Enterprise dopušta neograničen broj. Stripe provizija se naplaćuje odvojeno od pretplate.

---

## 8. Pojmovnik

| Pojam | Značenje |
|-------|----------|
| **Owner Dashboard** | Glavni upravljački panel za vlasnike nekretnina |
| **KPI** | Key Performance Indicator — ključni pokazatelj uspješnosti |
| **Rolling window** | Klizni vremenski prozor koji se automatski ažurira (npr. "zadnjih 30 dana" uvijek gleda od danas unatrag) |
| **Overbooking** | Situacija kada su isti datumi rezervirani više puta |
| **iCal Sync** | Sinkronizacija kalendara putem iCal protokola (format za razmjenu kalendarskih podataka) |
| **Pending** | Status "na čekanju" — rezervacija čeka odobrenje vlasnika |
| **Confirmed** | Status "potvrđena" — rezervacija je odobrena |
| **Completed** | Status "završena" — gost je završio boravak |
| **Cancelled** | Status "otkazana" — rezervacija je poništena |
| **Push obavijest** | Obavijest koja se prikazuje na uređaju čak i kada aplikacija nije otvorena |
| **FCM** | Firebase Cloud Messaging — sustav za slanje push obavijesti |
| **Stripe Connect** | Stripe sustav koji omogućava vlasnicima primanje kartičnih plaćanja od gostiju |
| **Depozit (avans)** | Dio ukupne cijene koji gost plaća unaprijed |
| **Badge** | Oznaka u boji koja prikazuje status ili platformu |
| **Swipe** | Povlačenje prstom (na mobitelu) — koristi se za brisanje obavijesti |
| **Drag-and-drop** | Povuci i pusti — koristi se za premještanje rezervacija u kalendaru |
| **Card pogled** | Prikaz u obliku kartica (vizualniji) |
| **Tabela pogled** | Prikaz u obliku tablice (kompaktniji, više podataka) |
| **Bottom sheet** | Ploča koja klizi od dna ekrana — koristi se za postavke |
| **Avatar** | Profilna slika ili krug s inicijalima imena |
