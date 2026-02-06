# BookBed Booking Widget — Kompletna baza znanja za AI chatbot

## 1. Pregled widgeta

BookBed Booking Widget je interaktivni kalendar s mogućnošću rezervacije koji se ugrađuje na web stranicu vlasnika nekretnine. Widget omogućava gostima pregledavanje dostupnosti, odabir datuma, unos podataka i kreiranje rezervacije — sve unutar vlasnikove stranice, bez preusmjeravanja na drugi web.

Widget je samostalna web aplikacija hostana na `view.bookbed.io`. Vlasnik ga ugrađuje kopiranjem `<iframe>` koda na svoju stranicu.

---

## 2. Tri moda rada widgeta

Vlasnik u Owner Dashboard-u bira jedan od tri moda za svaku smještajnu jedinicu (apartman, sobu):

### 2.1 Samo kalendar (`calendarOnly`)

- Widget prikazuje **samo kalendar dostupnosti** i kontakt informacije vlasnika
- Gost **ne može** rezervirati kroz widget — mora kontaktirati vlasnika telefonom, emailom ili WhatsApp-om
- Korisno za vlasnike koji žele osobno komunicirati s gostima prije potvrde rezervacije

**Gost vidi:** Kalendar + kontakt dugmad (telefon, email, WhatsApp — prema postavkama vlasnika)

### 2.2 Rezervacija bez plaćanja (`bookingPending`)

- Widget prikazuje kalendar + **formu za rezervaciju** (bez opcija plaćanja)
- Gost popunjava podatke i šalje zahtjev
- Rezervacija se kreira sa statusom **"čekanje"** — vlasnik mora ručno odobriti
- Plaćanje se dogovara privatno (bankovni prijenos, gotovina pri dolasku, itd.)

**Gost vidi:** Kalendar + forma za unos podataka gosta

### 2.3 Puna rezervacija s plaćanjem (`bookingInstant`)

- Widget prikazuje kalendar + formu + **opcije plaćanja**
- Gost odabire metodu plaćanja i plaća odmah
- Za kartična plaćanja (Stripe): gost je preusmjeren na sigurnu Stripe stranicu, nakon plaćanja rezervacija se automatski potvrđuje
- Za bankovni prijenos: rezervacija čeka dok vlasnik ne potvrdi primitak uplate

**Gost vidi:** Kalendar + forma + odabir plaćanja + prikaz cijene s depozitom

---

## 3. Metode plaćanja

### 3.1 Kartično plaćanje (Stripe)

- Gost plaća kreditnom/debitnom karticom putem sigurne Stripe Checkout stranice
- Minimalni iznos: **€0.50** (Stripe zahtjev)
- Nakon uspješnog plaćanja, rezervacija se **automatski potvrđuje**
- Novac ide direktno na Stripe račun vlasnika (Stripe Connect Standard model)
- Vlasnik može uključiti opciju "Zahtijevaj odobrenje" — tada čak i nakon plaćanja rezervacija čeka ručnu potvrdu

**Tijek za gosta:**
1. Gost popuni podatke i odabere "Kartica"
2. Preusmjeravanje na Stripe Checkout stranicu
3. Gost unese podatke kartice i plati
4. Automatsko vraćanje na widget → prikaz potvrde

### 3.2 Bankovni prijenos

- Gost vidi podatke za uplatu (IBAN, naziv računa, referenca plaćanja) i rok za uplatu
- **EPC QR kod** — gost skenira QR kod mobilnom bankovnom aplikacijom za brzu uplatu (opcionalno, vlasnik može uključiti/isključiti)
- Rok za uplatu je prilagodljiv: **1, 3, 5, 7 ili 14 dana** (vlasnik bira)
- Vlasnik može dodati **prilagođenu poruku** uz upute za plaćanje (do 500 znakova)
- Rezervacija ima status "čekanje" dok vlasnik ne potvrdi primitak uplate

**Podatci prikazani gostu:**
- Naziv banke
- Naziv vlasnika računa
- IBAN (može se kopirati klikom)
- SWIFT/BIC (može se kopirati klikom)
- Referenca plaćanja (booking referenca)
- QR kod za mobilno plaćanje (ako je omogućen)

### 3.3 Plaćanje pri dolasku

- Gost ne plaća unaprijed — plaća na lokaciji pri dolasku
- Rezervacija se kreira sa statusom "čekanje" → vlasnik ručno potvrđuje

### 3.4 Depozit (kapara/avans)

Vlasnik postavlja **postotak depozita** (0-100%) koji se primjenjuje na sve metode plaćanja:
- Primjer: ukupna cijena €1.000, depozit 20% → gost plaća €200 unaprijed, ostatak od €800 pri dolasku
- 0% = nema avansa (cijeli iznos pri dolasku)
- 100% = gost plaća ukupan iznos unaprijed

Gost u widgetu vidi razliku:
- **Iznos depozita** (ono što plaća odmah)
- **Preostali iznos** (ono što plaća na lokaciji)

---

## 4. Kalendar dostupnosti

### 4.1 Prikaz kalendara

Widget automatski odabire najprikladniji prikaz ovisno o veličini ekrana:

| Veličina ekrana | Prikaz |
|-----------------|--------|
| Desktop (≥1024px) | Godišnji ili mjesečni kalendar, booking forma pored kalendara |
| Tablet (600-1023px) | Mjesečni kalendar, forma ispod |
| Mobitel (<600px) | Mjesečni kalendar, sve u jednom stupcu |

### 4.2 Značenje boja u kalendaru

| Boja | Značenje | Objašnjenje |
|------|----------|-------------|
| **Zelena** | Slobodno | Gost može rezervirati taj datum |
| **Crvena** | Zauzeto | Datum je već rezerviran (potvrđena rezervacija) |
| **Narančasta** | Čekanje | Rezervacija čeka potvrdu vlasnika |
| **Siva** | Blokirano | Vlasnik je ručno blokirao datum |
| **Svijetlo siva** | Nedostupno | Prošli datumi ili izvan dopuštenog perioda |
| **Dijagonalni uzorak** | Turnover dan | Dan odjave jednog gosta i prijave drugog (isti dan) |

### 4.3 Cijene u kalendaru

- Cijene po noćenju prikazane su na svakom datumu u kalendaru
- **Vikend cijene** (ako su različite od radnih dana) prikazuju se na petkom i subotom
- **Prilagođene dnevne cijene** (sezonske, promotivne) imaju prioritet nad baznom cijenom
- Na desktopu: hover tooltip prikazuje detaljne informacije o datumu (dan u tjednu, status, cijena)
- Na mobitelu: cijene prikazane direktno u ćelijama kalendara (ako je ćelija dovoljno velika)

### 4.4 Odabir datuma

1. Gost klikne na datum prijave → datum se označi kao **check-in**
2. Gost klikne na datum odjave → raspon se označi, svi noći između se odaberu
3. Widget automatski provjerava:
   - Minimalni broj noćenja (npr. 7 noći) — ako gost odabere manje, prikazuje se poruka
   - Maksimalni broj noćenja — ako postoji ograničenje
   - Raspoloživost svih datuma u rasponu — ne može se rezervirati preko zauzetih datuma
4. Ako su datumi ispravni, prikazuje se booking forma (ili cijena, ovisno o modu)

### 4.5 Same-day turnover (odjava i prijava istog dana)

Widget podržava odjavu jednog gosta i prijavu drugog na isti dan:
- Primjer: Gost A odjava 5. srpnja, Gost B prijava 5. srpnja
- Kalendar prikazuje dijagonalni uzorak na turnover danu
- Ovo je standardno ponašanje u iCal protokolu (DTEND je ekskluzivan)

---

## 5. Booking forma (što gost popunjava)

### 5.1 Obavezna polja

| Polje | Opis | Validacija |
|-------|------|------------|
| **Ime** | Ime gosta | Obavezno, ne smije biti prazno |
| **Prezime** | Prezime gosta | Obavezno, ne smije biti prazno |
| **Email** | Email adresa | Obavezno, provjera formata (RFC 5322) |
| **Telefon** | Telefonski broj s pozivnim brojem države | Obavezno, minimalno 7 znamenki |
| **Broj gostiju** | Odrasli (min. 1) + djeca + kućni ljubimci | Ne smije premašiti kapacitet jedinice |

### 5.2 Opcionalna polja

| Polje | Opis |
|-------|------|
| **Napomene** | Posebni zahtjevi, kasni dolazak, alergije (do 1.000 znakova) |
| **Dodatne usluge** | Parking, doručak, transfer, kasni check-in, itd. (ako ih vlasnik nudi) |
| **Metoda plaćanja** | Kartica / Bankovni prijenos / Plaćanje pri dolasku (samo u bookingInstant modu) |
| **Opcija plaćanja** | Depozit ili puna cijena |

### 5.3 Verifikacija emaila

Vlasnik može uključiti obaveznu verifikaciju emaila prije kreiranja rezervacije:
1. Gost upiše email
2. Widget šalje 6-znamenkasti kod na email
3. Gost unese kod u dijalog
4. Tek nakon uspješne verifikacije gost može nastaviti s rezervacijom

Ovo sprječava lažne rezervacije s nepostojećim email adresama.

### 5.4 Brojač gostiju

Widget ima intuitivan brojač za goste s +/- dugmadima:
- **Odrasli**: minimalno 1, maksimum = kapacitet jedinice
- **Djeca**: minimalno 0, broje se u ukupni kapacitet
- **Kućni ljubimci**: prikazuju se samo ako vlasnik dopušta ljubimce, s opcionalnom naknadom po ljubimcu po noći
- Ukupan broj gostiju (odrasli + djeca) ne smije premašiti kapacitet jedinice
- Kada je kapacitet dosegnut, dugme + se onemogućuje

### 5.5 Pravna izjava (porezna napomena)

Vlasnik može uključiti obaveznu **checkbox** izjavu koju gost mora prihvatiti prije slanja rezervacije. Sadrži:
- Informacije o boravišnoj pristojbi
- Informacije o turistickoj naknadi
- Obaveza prijavljivanja gostiju u sustav eVisitor
- Napomena da je vlasnik odgovoran za porezne obveze
- Odricanje odgovornosti platforme

Vlasnik može zamijeniti zadani tekst prilagođenom porukom.

---

## 6. Dodatne usluge

### 6.1 Što su dodatne usluge?

Vlasnik može ponuditi dodatne usluge koje gost odabire tijekom rezervacije. Svaka usluga ima naziv, cijenu i način naplate.

### 6.2 Načini naplate

| Način | Objašnjenje | Primjer |
|-------|-------------|---------|
| **Po rezervaciji** | Fiksna cijena, neovisno o trajanju ili broju gostiju | Transfer s aerodroma: €25 po rezervaciji |
| **Po noćenju** | Cijena se množi s brojem noći | Parking: €5/noć × 3 noći = €15 |
| **Po osobi** | Cijena se množi s brojem gostiju | Doručak: €8/osoba × 4 gosta = €32 |
| **Po komadu** | Cijena po naručenoj jedinici | Set ručnika: €5 × 2 seta = €10 |

### 6.3 Kako gost odabire usluge?

- Usluge se prikazuju kao lista s checkbox-ovima
- Gost označava željene usluge
- Za neke usluge moguće je birati količinu (+/- dugmad)
- Ukupna cijena dodatnih usluga prikazuje se u prikazu cijene

### 6.4 Primjer prikaza cijene s dodatnim uslugama

```
Smještaj (3 noći)           €300,00
Naknada za kućnog ljubimca   €45,00
Naknada za dodatnog gosta    €90,00
Dodatne usluge               €65,00
────────────────────────────────────
UKUPNO                      €500,00
────────────────────────────────────
Depozit (20%)               €100,00
Preostali iznos             €400,00
```

---

## 7. Pravila rezervacije (što vlasnik konfigurira)

### 7.1 Minimalni boravak

Vlasnik postavlja **minimalni broj noćenja** za svaku jedinicu (zadano: 1 noć).
- Ako gost pokuša odabrati manje noći, widget prikazuje poruku: "Minimalni boravak je X noći"
- Minimalni boravak se može postaviti globalno i/ili po danu u cjenovniku

### 7.2 Maksimalni boravak

Vlasnik može postaviti **maksimalni broj noćenja** (opcionalno, zadano: nema ograničenja).
- Ako gost pokuša odabrati više noći, widget prikazuje poruku: "Maksimalni boravak je X noći"

### 7.3 Rezervacija unaprijed

Vlasnik kontrolira koliko unaprijed gost može rezervirati:

| Postavka | Zadano | Objašnjenje |
|----------|--------|-------------|
| **Minimum dana unaprijed** | 0 (isti dan) | Koliko dana prije prijave gost MORA rezervirati. 0 = može rezervirati i na dan prijave |
| **Maksimum dana unaprijed** | 365 dana | Koliko daleko u budućnost gost MOŽE rezervirati. 365 = do godinu dana unaprijed |

Primjer: min 3, max 180 → gost mora rezervirati minimalno 3 dana prije, a ne može rezervirati više od 6 mjeseci unaprijed.

### 7.4 Vikend dani

Vlasnik definira koji su dani vikend (za vikend cijene):
- Zadano: **petak i subota** (noći)
- Prilagodljivo: npr. restorti mogu koristiti subotu i nedjelju

### 7.5 Politika otkazivanja

| Postavka | Zadano | Objašnjenje |
|----------|--------|-------------|
| **Dopusti otkazivanje** | Da | Gost može otkazati rezervaciju putem linka u emailu |
| **Rok za otkazivanje** | 48 sati | Koliko sati prije prijave gost MORA otkazati. 0 = može otkazati bilo kada |

Primjer: rok 48 sati, prijava 1. srpnja → gost mora otkazati do 29. lipnja u isto vrijeme.

### 7.6 Odobrenje vlasnika

- **bookingPending mod**: odobrenje je **uvijek obavezno** (automatski)
- **bookingInstant mod + Stripe**: vlasnik može **uključiti/isključiti** obavezno odobrenje
- **bookingInstant mod + bankovni prijenos**: odobrenje je **uvijek obavezno** (jer vlasnik mora potvrditi primitak uplate)

---

## 8. Zaštita od dvostrukog bukinga

### 8.1 Placeholder rezervacija

Kada gost odabere Stripe plaćanje, BookBed **odmah kreira placeholder rezervaciju** sa statusom "čekanje" prije nego gost uopće plati. Ovo blokira odabrane datume za sve ostale goste.

- Ako gost uspješno plati → placeholder se ažurira na "potvrđeno"
- Ako gost ne plati (odustane ili sesija istekne) → placeholder se automatski briše i datumi se oslobađaju

### 8.2 Provjera dostupnosti na serveru

Pri svakoj rezervaciji, server provjerava dostupnost datuma u Firestore-u. Čak i ako dva gosta istovremeno pokušaju rezervirati isti termin, samo prvi će uspjeti — drugi dobiva poruku "Netko je upravo rezervirao te datume."

### 8.3 Zaključavanje cijena

Kada gost odabere datume, cijena se "zaključava" na 10 minuta. Ako vlasnik promijeni cijenu dok gost popunjava formu, gost vidi cijenu koja je vrijedila u trenutku odabira datuma. Server uvijek ponovno izračunava cijenu iz aktualnih podataka i uspoređuje je s cijenom koju je gost vidio.

---

## 9. Što widget NE nudi

### 9.1 Funkcionalnosti koje ne postoje

1. **Galerija slika** — widget prikazuje samo kalendar i formu, ne slike apartmana
2. **Chat s vlasnikom** — komunikacija ide putem emaila i telefona, ne kroz widget
3. **Pregovaranje o cijeni** — cijene su fiksne, gost ne može predložiti drugu cijenu
4. **Višestruke istovremene rezervacije** — gost može kreirati jednu rezervaciju po sesiji
5. **Upravljanje cijenama** — cijene se postavljaju isključivo u Owner Dashboard-u
6. **Offline rad** — widget zahtijeva internetsku vezu za dohvaćanje podataka
7. **Višestruke valute** — widget koristi isključivo **euro (€)**
8. **Povrat novca** — otkazivanje se rješava između vlasnika i gosta, ne automatski kroz widget
9. **Grupne rezervacije** — widget podržava jednu jedinicu po rezervaciji, ne više jedinica odjednom

### 9.2 Ograničenja preglednika

- Zahtijeva moderan preglednik: Chrome 80+, Safari 14+, Firefox 78+, Edge 80+
- Internet Explorer **nije podržan**
- Neke web stranice s restriktivnim Content Security Policy (CSP) pravilima mogu blokirati iframe — u tom slučaju developer mora dodati `view.bookbed.io` u `frame-src` direktivu

---

## 10. Jezična podrška

### 10.1 Podržani jezici

Widget automatski koristi jezik preglednika gosta. Trenutno podržani jezici:

| Jezik | Kod | Napomena |
|-------|-----|----------|
| **Engleski** | `en` | Zadani ako jezik preglednika nije podržan |
| **Hrvatski** | `hr` | Ijekavski dijalekt |
| **Njemački** | `de` | Za goste iz Njemačke, Austrije, Švicarske |
| **Talijanski** | `it` | Za goste iz Italije |

### 10.2 Što je prevedeno?

- Sav tekst korisničkog sučelja (dugmad, naslovi, opisi)
- Poruke o greškama
- Nazivi dana u tjednu i mjeseci
- Formatiranje datuma i valute
- Oznake pristupačnosti za čitače ekrana

### 10.3 Forsiranje jezika

Vlasnik može forsirati jezik dodavanjem parametra u embed kod:
```
...&language=hr
```
U tom slučaju widget uvijek prikazuje odabrani jezik, neovisno o jeziku preglednika gosta.

---

## 11. Tema i vizualni izgled

### 11.1 Automatska tema

Widget automatski prati sistemsku temu gosta:
- **Svijetla tema**: bijele/svijetlo sive pozadine, tamni tekst
- **Tamna tema**: crne/tamno sive pozadine, svijetli tekst

### 11.2 Forsiranje teme

Vlasnik može forsirati temu dodavanjem parametra u embed kod:
```
...&theme=light
```
ili
```
...&theme=dark
```

### 11.3 Prilagodba boja (napredno)

Vlasnik može prilagoditi primarne boje widgeta putem URL parametara:
- `primaryColor=#6B4CE6` — glavna boja (dugmad, naglasci)
- `accentColor=#FF5A5F` — sekundarna boja

Widget automatski izračunava kontrastnu boju teksta za svaku pozadinu.

### 11.4 BookBed branding

Widget prikazuje malu oznaku **"Powered by BookBed"** u donjem dijelu. Vlasnik može to isključiti u postavkama.

---

## 12. Email obavijesti

### 12.1 Email gostu

Gost prima email potvrdu koja sadrži:
- Booking referencu (npr. `BK-A3F7E2D1B9C4`)
- Datume prijave i odjave
- Broj noći i gostiju
- Ukupnu cijenu s razdiobom
- Podatke za bankovni prijenos (ako je odabran)
- Rok za uplatu
- Kontakt podatke vlasnika
- Link za pregled rezervacije
- Upute za otkazivanje (ako je dopušteno)

### 12.2 Email vlasniku

Vlasnik prima obavijest o novoj rezervaciji koja sadrži:
- Podatke gosta (ime, email, telefon)
- Datume i broj noći
- Cijenu i metodu plaćanja
- Link za upravljanje rezervacijom u Owner Dashboard-u

### 12.3 Push obavijesti

Ako vlasnik koristi Owner Dashboard u pregledniku, prima **push obavijest** za svaku novu rezervaciju (čak i kada tab nije aktivan).

---

## 13. Pregled postojeće rezervacije

### 13.1 Kako gost pregledava svoju rezervaciju?

Gost može pregledati svoju rezervaciju putem linka u emailu potvrde:
```
https://view.bookbed.io/view?ref=BK-XXXXXXXXXXXX&email=gost@email.com
```

### 13.2 Što gost vidi?

- Status rezervacije (čekanje, potvrđeno, završeno, otkazano)
- Sve detalje rezervacije (datumi, gosti, cijena)
- Politiku otkazivanja
- Kontakt podatke vlasnika
- Opciju otkazivanja (ako je dopušteno i rok nije istekao)

### 13.3 Otkazivanje

Ako je vlasnik omogućio otkazivanje:
1. Gost klikne "Otkaži rezervaciju" na stranici za pregled
2. Widget provjerava rok za otkazivanje
3. Ako je rok prošao: prikazuje poruku "Rok za otkazivanje je istekao"
4. Ako je unutar roka: potvrda otkazivanja → rezervacija se otkazuje → datumi se oslobađaju

---

## 14. Potvrda rezervacije

### 14.1 Što gost vidi nakon uspješne rezervacije?

Ekran potvrde prikazuje:
1. **Ikona uspjeha** — zelena kvačica s animacijom
2. **Booking referenca** — jedinstveni kod (može se kopirati)
3. **Obavijest o emailu** — "Potvrda je poslana na vašu email adresu"
4. **Upute za bankovni prijenos** (ako je odabran) — kompletni podatci za uplatu s QR kodom
5. **Sažetak rezervacije** — gost, datumi, nekretnina, jedinica
6. **Razdioba cijene** — smještaj, dodatne usluge, naknade, ukupno, depozit
7. **Napomena o spam folderu** — "Provjerite spam folder ako email nije stigao"
8. **Dugme za preuzimanje** — preuzimanje .ics kalendarske datoteke
9. **Sljedeći koraci** — što se dalje dogodi
10. **Politika otkazivanja** — uvjeti i rok za otkazivanje

---

## 15. Pristupačnost

### 15.1 Podrška za čitače ekrana

- Svi datumi imaju semantičke oznake: "Četvrtak, 19. prosinca, slobodno"
- Statusni opisi: "Zauzeto", "Čekanje na potvrdu", "Dostupno za prijavu"
- Odabir raspona: "Prijava: 19. prosinca. Odjava: 26. prosinca. 7 noći."
- Iframe `title` atribut s nazivom jedinice

### 15.2 Navigacija tipkovnicom

- Tab navigacija između datuma u kalendaru
- Odabrani datumi vizualno označeni obrubom
- Fokus indikatori na svim interaktivnim elementima

---

## 16. Sigurnosne značajke

### 16.1 Zaštita podataka

- Sva komunikacija šifrirana HTTPS-om
- Osobni podaci gostiju pohranjeni na BookBed serverima, ne na vlasnikovoj stranici
- Iframe sandboxing: widget ne može pristupiti sadržaju roditeljske stranice

### 16.2 Validacija na serveru

- Cijena se **uvijek ponovno izračunava na serveru** — klijentski prikaz je samo za informaciju
- Dostupnost datuma provjerava se na serveru — sprječava race condition
- Broj gostiju se validira prema kapacitetu jedinice
- Email adrese i telefonski brojevi se sanitiziraju (uklanjanje potencijalno opasnih znakova)

### 16.3 Zaštita od zloupotrebe

- **Rate limiting**: maksimalno 10 rezervacija u 10 minuta po IP adresi (za widget)
- **Idempotency ključ**: sprječava duplu rezervaciju ako gost dvaput klikne "Rezerviraj"
- **Webhook verifikacija**: Stripe webhook potpisi se provjeravaju — nitko ne može lažirati potvrdu plaćanja
- **Provjera cijena**: Ako se klijentska i serverska cijena razlikuju više od €10 ili 5%, sustav bilježi sigurnosni događaj

---

## 17. Česta pitanja (FAQ)

### Widget mod i funkcionalnosti

**P: Koja je razlika između "Samo kalendar" i "Rezervacija bez plaćanja"?**
O: "Samo kalendar" prikazuje samo dostupnost i kontakt informacije — gost ne može kreirati rezervaciju kroz widget. "Rezervacija bez plaćanja" ima formu za rezervaciju gdje gost unosi svoje podatke i šalje zahtjev, ali ne plaća unaprijed.

**P: Mogu li promijeniti mod widgeta nakon ugradnje?**
O: Da! Promjena moda u Widget Settings automatski se primjenjuje. Nije potrebno mijenjati embed kod na web stranici.

**P: Što se dogodi ako nemam nijednu metodu plaćanja omogućenu u "Puna rezervacija" modu?**
O: Widget Settings neće dopustiti spremanje ako u "Puna rezervacija" modu nije omogućena barem jedna metoda plaćanja (Stripe ili bankovni prijenos).

### Cijene i plaćanje

**P: Može li gost vidjeti cijene u kalendaru?**
O: Da. Cijene po noćenju prikazane su na svakom datumu. Razlikuju se bazna cijena, vikend cijena i prilagođene dnevne cijene.

**P: Što se dogodi ako promijenim cijene dok gost popunjava formu?**
O: Gost vidi cijenu koja je vrijedila u trenutku odabira datuma. Server pri kreiranju rezervacije izračunava aktualnu cijenu. Ako postoji mala razlika (do €10), rezervacija prolazi sa serverskom cijenom. Veće razlike se bilježe kao sigurnosni događaj.

**P: Mogu li nuditi popust za duže boravke?**
O: Trenutno ne postoji automatski popust za duže boravke u widgetu. Možete ručno postaviti niže cijene za određene datume u cjenovniku.

**P: Hoće li gost vidjeti ukupnu cijenu prije plaćanja?**
O: Da. Kompletna razdoba cijene (smještaj, dodatne usluge, naknade, depozit, preostali iznos) prikazuje se prije nego gost potvrdi rezervaciju.

### Dodatne usluge

**P: Kako dodati dodatne usluge?**
O: U Owner Dashboard-u otvorite uređivanje smještajne jedinice → sekcija "Dodatne usluge" → dodajte novu uslugu s nazivom, cijenom i načinom naplate.

**P: Može li gost odabrati količinu usluge?**
O: Da, za usluge koje to podržavaju gost može birati količinu pomoću +/- dugmadi. Vlasnik može postaviti maksimalnu količinu po usluzi.

**P: Što ako gost ne odabere nijednu dodatnu uslugu?**
O: Dodatne usluge su potpuno opcionalne. Ako ih gost ne odabere, cijena uključuje samo smještaj.

### Otkazivanje

**P: Može li gost otkazati rezervaciju?**
O: Samo ako je vlasnik omogućio otkazivanje u postavkama. Gost može otkazati putem linka u emailu potvrde, ali samo do roka koji je vlasnik postavio (npr. 48 sati prije prijave).

**P: Što se dogodi s plaćanjem ako gost otkaže?**
O: Povrat novca se rješava između vlasnika i gosta. BookBed ne procesira automatske povrate — vlasnik odlučuje o uvjetima povrata.

### Tehnička pitanja

**P: Widget prikazuje krivi jezik?**
O: Widget automatski koristi jezik preglednika. Ako želite forsirati jezik, dodajte `&language=hr` na kraj src URL-a u embed kodu.

**P: Kalendar ne prikazuje ispravnu dostupnost?**
O: Kalendar se ažurira u realnom vremenu. Ako se čini neispravnim, provjerite jesu li datumi ispravno blokirani/rezervirani u Owner Dashboard-u. Ako koristite iCal sinkronizaciju, provjerite je li feed aktivan i ispravno sinkroniziran.

**P: Gost kaže da ne vidi opciju plaćanja?**
O: Provjerite u Widget Settings da je mod postavljen na "Puna rezervacija sa plaćanjem" i da je barem jedna metoda plaćanja (Stripe ili bankovni prijenos) omogućena.

**P: Koliko dugo traje učitavanje widgeta?**
O: Widget koristi progresivno učitavanje — skeleton kalendar se prikazuje odmah (ispod 1 sekunde), dok se potpuni podaci učitavaju u pozadini (obično 2-4 sekunde).

---

## 18. Glossar

| Termin | Objašnjenje |
|--------|-------------|
| **Widget** | Interaktivni booking kalendar ugrađen na web stranicu vlasnika |
| **Widget mod** | Način rada: samo kalendar, bez plaćanja, ili s plaćanjem |
| **bookingInstant** | Mod s automatskim plaćanjem i potvrdom |
| **bookingPending** | Mod bez plaćanja — vlasnik ručno odobrava |
| **calendarOnly** | Mod samo s kalendarom — bez mogućnosti rezervacije |
| **Depozit** | Postotak ukupne cijene koji gost plaća unaprijed |
| **Stripe** | Online platforma za sigurna kartična plaćanja |
| **Stripe Connect** | Sustav koji omogućava direktna plaćanja na račun vlasnika |
| **EPC QR kod** | Europski standard QR koda za bankovne prijenose (mobilne aplikacije) |
| **Placeholder** | Privremena rezervacija koja blokira datume dok gost ne plati |
| **Turnover dan** | Dan kada se jedan gost odjavljuje a drugi prijavljuje |
| **Rate limiting** | Ograničenje broja zahtjeva za sprječavanje zloupotrebe |
| **Idempotency** | Mehanizam koji sprječava duplu rezervaciju pri dvostrukom kliku |
| **CSP** | Content Security Policy — sigurnosna pravila web preglednika |
| **RFC 5322** | Standard za format email adresa |
| **Booking referenca** | Jedinstveni kod rezervacije (format: BK-XXXXXXXXXXXX) |
| **Dodatne usluge** | Opcionalne usluge koje gost bira tijekom rezervacije (parking, doručak, itd.) |
