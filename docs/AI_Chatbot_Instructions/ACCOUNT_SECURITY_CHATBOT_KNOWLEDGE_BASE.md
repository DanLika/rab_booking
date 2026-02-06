# BookBed Korisnički račun, sigurnost i privatnost — Kompletna baza znanja za AI chatbot

## 1. Prijava i registracija

BookBed podržava **tri metode autentikacije**:

| Metoda | Platforme | Verifikacija emaila? |
|--------|-----------|----------------------|
| **Email i lozinka** | Web, Android, iOS | Da (obavezna) |
| **Google prijava** | Web, Android, iOS | Ne (Google već verificira) |
| **Apple prijava** | Web, iOS | Ne (Apple već verificira) |

---

### 1.1 Registracija s emailom i lozinkom

**Koraci:**
1. Korisnik otvara aplikaciju i klikne **"Registriraj se"**
2. Popunjava formu:
   - **Ime i prezime** (obavezno — mora sadržavati razmak između imena i prezimena)
   - **Email adresa** (obavezna — validacija formata)
   - **Telefon** (opcionalno — validacija E.164 formata ako se unese)
   - **Lozinka** (obavezna — pravila ispod)
   - **Profilna slika** (opcionalno)
3. Označava **obavezne** kvačice:
   - "Prihvaćam Uvjete korištenja i Politiku privatnosti" — **obavezno**
   - "Želim primati novosti i obavijesti" — opcionalno
4. Klikne **"Registriraj se"**
5. Korisnički profil se kreira
6. Preusmjeravanje na **ekran za verifikaciju emaila**

**Pravila za lozinku:**
- Minimalno **8 znakova**
- Barem **jedno veliko slovo** (A–Z)
- Barem **jedno malo slovo** (a–z)
- Barem **jedan broj** (0–9)
- Barem **jedan poseban znak** (!@#$%^&* itd.)
- **Zabranjeni** sekvencijalni znakovi (npr. "12345678", "abcdefgh")

**Indikator jačine lozinke:**
- Crveno (slaba): nedostaju zahtjevi
- Žuto (srednja): većina zahtjeva ispunjena
- Zeleno (jaka): svi zahtjevi ispunjeni

---

### 1.2 Google prijava

**Tijek:**
1. Korisnik klikne gumb **"Google"** na ekranu za prijavu
2. Otvara se Google account picker (uvijek se prikazuje — čak i ako je korisnik već prijavljen u Google)
3. Korisnik odabere Google račun
4. **Novi korisnik**: profil se kreira, preusmjeravanje na **"Uredi profil"** za dopunu podataka
5. **Postojeći korisnik**: učitava se profil, preusmjeravanje na Dashboard

**Napomena:** Email je automatski verificiran (Google-verificirani emailovi se prihvaćaju bez dodatne provjere).

---

### 1.3 Apple prijava

**Tijek:**
1. Korisnik klikne gumb **"Apple"** na ekranu za prijavu
2. Prikazuje se Apple ID autentikacijski prozor
3. Korisnik potvrđuje identitet (Face ID, Touch ID ili lozinka)
4. **Novi korisnik**: profil se kreira, preusmjeravanje na "Uredi profil"
5. **Postojeći korisnik**: učitava se profil, preusmjeravanje na Dashboard

**Napomena:**
- Apple pruža ime korisnika **samo pri prvoj prijavi** — kasnija prijavljivanja mogu imati prazno ime
- Korisnik može odabrati **"Sakrij email"** — Apple daje proxy email adresu
- Verifikacija emaila nije potrebna (Apple već verificira)

---

### 1.4 Prijava (Login)

**Koraci:**
1. Korisnik unosi email i lozinku
2. Opcionalna kvačica **"Zapamti me"** — sprema **samo email** (ne lozinku!) za brže sljedeće prijavljivanje
3. Klik na **"Prijavi se"**
4. Ako je email verificiran → Dashboard
5. Ako email nije verificiran → Ekran za verifikaciju emaila

**Što ako korisnik koristi krivu metodu?**
- Ako je račun kreiran s Google-om, a korisnik pokuša s emailom/lozinkom → poruka: "Ovaj račun koristi Google prijavu. Prijavite se s Google-om."
- Isto za Apple račune

---

### 1.5 Zaštita od prekomjernih pokušaja (Rate Limiting)

- **Maksimalno 5 neuspjelih pokušaja** prijave po email adresi unutar 15 minuta
- Nakon toga: poruka "Previše pokušaja. Pokušajte ponovno za X sekundi"
- Dodatna zaštita po IP adresi putem Cloud Functions
- Zaštita se primjenjuje i na registraciju

---

## 2. Verifikacija emaila

**Kada je potrebna:** Samo za korisnike koji se registriraju s emailom i lozinkom (Google/Apple korisnici su automatski verificirani).

**Ekran za verifikaciju:**
1. Prikazuje se poruka: "Poslali smo vam email za verifikaciju"
2. Sustav **automatski provjerava** svakih 3 sekunde je li email verificiran
3. Kada gost verificira klik na link u emailu → automatski preusmjeravanje na Dashboard

**Dostupne akcije:**
- **"Pošalji ponovo"**: šalje novi verifikacijski email (60 sekundi cooldown između slanja)
- **"Promijeni email"**: dijalog za unos novog emaila i lozinke (za slučaj pogreške pri unosu)
- **"Povratak na prijavu"**: odjava i povratak na login ekran

**Važno:** Početni cooldown od 60 sekundi sprječava Firebase rate limit grešku ako korisnik odmah klikne "Pošalji ponovo" nakon registracije.

---

## 3. Upravljanje lozinkom

### 3.1 Zaboravljena lozinka

**Koraci:**
1. Na ekranu za prijavu, korisnik klikne **"Zaboravili ste lozinku?"**
2. Unosi email adresu
3. Klikne **"Pošalji link za resetiranje"**
4. Prikazuje se poruka: "Ako postoji račun s ovom adresom, poslali smo vam email"
5. Korisnik klikne link u emailu i postavi novu lozinku

**Sigurnosna napomena:** Sustav uvijek prikazuje istu poruku, neovisno o tome postoji li račun s tim emailom. Ovo sprječava otkrivanje registriranih email adresa (zaštita od user enumeration).

### 3.2 Promjena lozinke

**Koraci:**
1. Korisnik otvara **Profil → Promijeni lozinku**
2. Unosi:
   - Trenutnu lozinku (obavezna za verifikaciju)
   - Novu lozinku (mora zadovoljiti pravila)
   - Potvrdu nove lozinke
3. Sustav provjerava:
   - Je li trenutna lozinka ispravna (re-autentikacija)
   - Zadovoljava li nova lozinka sva pravila
   - **Nije li nova lozinka već korištena** (provjera povijesti lozinki)
4. Ako je sve u redu → lozinka se mijenja, korisnik ostaje prijavljen

**Povijest lozinki:** Cloud Functions pohranjuju hashirane verzije prethodnih lozinki. Korisnik ne može ponovo koristiti nedavno korištenu lozinku.

---

## 4. Upravljanje profilom

### 4.1 Podatci profila

**Što se prikuplja:**

| Podatak | Obavezno? | Uređivanje |
|---------|-----------|------------|
| Ime i prezime | Da | Da |
| Email adresa | Da | Da (s ponovnom verifikacijom) |
| Telefon | Ne | Da |
| Profilna slika | Ne | Da |
| Datum kreiranja računa | Automatski | Ne |
| Tip računa (Trial/Premium/Lifetime) | Automatski | Ne (samo admin) |
| Stripe račun ID | Automatski | Ne |

### 4.2 Uređivanje profila

**Korisnik može promijeniti:**
- Ime i prezime
- Broj telefona
- Profilnu sliku (podržani formati: JPEG, PNG, na iOS-u i HEIC/HEIF)
- Email adresu (zahtijeva ponovnu verifikaciju)

**Korisnik NE može promijeniti:**
- Tip računa / status pretplate
- Datume trial perioda
- Lifetime licencu
- Admin override postavke

---

## 5. Brisanje korisničkog računa

**Obavezno prema pravilima Apple App Store-a** (od 2022.) i Google Play Store-a.

### 5.1 Tijek brisanja

1. Korisnik otvara **Profil → Izbriši račun**
2. Prikazuje se **upozorenje** s crvenim zaglavljem:
   - "Ova radnja je **nepovratna**"
   - "Svi vaši podaci bit će trajno obrisani"
   - Popis što se briše: profil, nekretnine, smještajne jedinice, rezervacije, platformske veze
   - GDPR napomena: "Podaci gostiju iz rezervacija bit će anonimizirani"
3. Korisnik mora **ponovo potvrditi identitet**:
   - Email/lozinka korisnici: unos lozinke
   - Google korisnici: ponovna Google autentikacija
   - Apple korisnici: ponovna Apple autentikacija
4. Korisnik potvrđuje brisanje
5. Cloud Function briše:
   - Korisnički profil i postavke
   - Sve nekretnine i smještajne jedinice
   - Sve rezervacije
   - Platformske veze (Booking.com, Airbnb)
   - Gostove rezervacije se **anonimiziraju** (GDPR usklađenost)
6. Firebase Auth račun se briše
7. Lokalni podaci se brišu (secure storage)
8. Korisnik se odjavljuje i vraća na Login ekran

### 5.2 Što se događa s postojećim rezervacijama?

- **Buduće rezervacije**: gosti dobivaju obavijest o otkazivanju
- **Podaci gostiju**: anonimizirani (ime, email, telefon zamijenjeni) — GDPR usklađenost
- **Podaci vlasnika**: potpuno obrisani — nema oporavka

---

## 6. Sigurnost podataka

### 6.1 Gdje se podaci pohranjuju

| Lokacija | Šifriranje | Podatci |
|----------|------------|---------|
| **Firebase Firestore** | Da (Google Cloud enkripcija u mirovanju) | Profil, nekretnine, rezervacije, postavke |
| **Firebase Auth** | Da | Lozinka (bcrypt hash), email, auth provider |
| **Firebase Storage** | Da | Profilne slike, slike nekretnina |
| **Secure Storage (uređaj)** | Da (Android: EncryptedSharedPreferences, iOS: Keychain) | Samo email za "Zapamti me" |
| **Stripe** | Da (PCI DSS Level 1) | Podatci kartice (BookBed ih nikada ne vidi) |

### 6.2 Redakcija osjetljivih podataka u logovima

BookBed **automatski redaktira** sljedeće iz logova:
- Lozinke
- Access/refresh tokeni
- API ključevi
- CVV i brojevi kartica
- Stripe session ID-ovi
- Auth kodovi i OTP-ovi

Osjetljivi podaci se zamjenjuju s `[REDACTED]` prije slanja na Sentry (web) ili Firebase Crashlytics (mobilno).

### 6.3 Revizijski trag (Audit Log)

Sustav automatski bilježi **sigurnosne događaje**:

| Događaj | Što se bilježi |
|---------|---------------|
| Prijava | Vrijeme, IP adresa, lokacija (ako dostupna) |
| Odjava | Vrijeme |
| Registracija | Vrijeme, metoda (email/Google/Apple) |
| Promjena lozinke | Vrijeme |
| Neuspjeli pokušaji prijave | Vrijeme, email, IP adresa |
| Verifikacija emaila | Vrijeme |

- Događaji se pohranjuju u Firestore: `users/{userId}/securityEvents/`
- Korisnik može **čitati** ali **ne može mijenjati ili brisati** sigurnosne događaje
- Nepromjenjivi revizijski trag za usklađenost

---

## 7. Pravila pristupa (Autorizacija)

### 7.1 Uloge u sustavu

| Uloga | Opis | Pristup |
|-------|------|---------|
| **Vlasnik (Owner)** | Registrirani korisnik koji upravlja nekretninama | Vlastiti profil, nekretnine, jedinice, rezervacije |
| **Admin** | Administrator platforme | Svi korisnici, sve nekretnine, statistike |
| **Gost** | Osoba koja rezervira smještaj | Pregled vlastite rezervacije putem linka/reference |

### 7.2 Što vlasnik može vidjeti/raditi

- **Vlastiti profil**: čitanje i uređivanje (osim zaštićenih polja)
- **Vlastite nekretnine**: kreiranje, čitanje, uređivanje, brisanje
- **Vlastite smještajne jedinice**: kreiranje, čitanje, uređivanje, brisanje
- **Vlastite rezervacije**: čitanje, uređivanje statusa, kreiranje ručnih rezervacija
- **iCal feedovi**: dodavanje, uređivanje, brisanje
- **Stripe postavke**: povezivanje/odspajanje Stripe računa

### 7.3 Što vlasnik NE može

- Pristupati podacima drugih vlasnika
- Mijenjati tip svog računa ili pretplatu
- Brisati sigurnosne događaje
- Pristupati admin panelu
- Mijenjati Firestore pravila pristupa

### 7.4 Što gost može

- Pregledati **vlastitu rezervaciju** putem booking reference linka
- Otkazati vlastitu rezervaciju (ako je omogućeno)
- Pregledati dostupnost na kalendaru (javni pristup)

---

## 8. Uvjeti korištenja i privatnost

### 8.1 Pristup dokumentima

- **Uvjeti korištenja (Terms of Service)** — dostupni:
  - Na ekranu za registraciju (link uz kvačicu)
  - U aplikaciji: Profil → O aplikaciji → Uvjeti korištenja
- **Politika privatnosti (Privacy Policy)** — dostupna:
  - Na ekranu za registraciju (link uz kvačicu)
  - U aplikaciji: Profil → O aplikaciji → Politika privatnosti

### 8.2 Prihvaćanje uvjeta

- Korisnik **mora prihvatiti** Uvjete korištenja i Politiku privatnosti **prije registracije**
- Kvačica je obavezna — gumb za registraciju je onemogućen bez nje
- Prihvaćanje se bilježi s vremenskim pečatom

### 8.3 GDPR usklađenost

| Pravo | Status | Implementacija |
|-------|--------|----------------|
| **Pravo na pristup** | Djelomično | Korisnik vidi sve svoje podatke u aplikaciji |
| **Pravo na ispravak** | Da | Korisnik uređuje profil, rezervacije |
| **Pravo na brisanje** | Da | "Izbriši račun" briše sve podatke |
| **Pravo na prenosivost** | Planirano | Izvoz podataka (budući feature) |
| **Pravo na prigovor** | Da | Korisnik može isključiti marketinške obavijesti |

**Anonimizacija pri brisanju:**
- Kada vlasnik izbriše račun, gostovi podaci iz rezervacija se **anonimiziraju** (ne brišu)
- Ovo omogućava gostima da i dalje imaju zapis o svojoj rezervaciji, bez osobnih podataka vlasnika

---

## 9. Ažuriranje aplikacije (Force Update)

### 9.1 Kako radi (samo Android)

BookBed ima sustav za **prisilno ažuriranje** na Android uređajima. Web verzija se automatski ažurira pri svakom deploy-u.

**Vrste ažuriranja:**

| Vrsta | Ponašanje | Kada se prikazuje |
|-------|-----------|-------------------|
| **Prisilno (Force)** | Dijalog koji se **ne može zatvoriti** — korisnik mora ažurirati | Kada je verzija aplikacije starija od minimalne zahtijevane |
| **Opcionalno** | Dijalog koji se **može zatvoriti** — podsjeća svakih 24 sata | Kada postoji novija verzija ali nije obavezna |
| **Ažurirano** | Bez dijaloga | Kada je aplikacija na najnovijoj verziji |

### 9.2 Prisilno ažuriranje

**Što korisnik vidi:**
- Puni ekran dijalog koji se ne može zatvoriti
- Poruka: "Nova verzija s poboljšanjima je dostupna"
- Gumb **"Ažuriraj sada"** — otvara Google Play Store
- Korisnik **ne može koristiti aplikaciju** dok ne ažurira

**Kada se prikazuje:** Ako je instalirana verzija starija od `minRequiredVersion` (npr. korisnik ima 1.0.1, a zahtijeva se 1.0.3)

### 9.3 Opcionalno ažuriranje

**Što korisnik vidi:**
- Dijalog s porukama o novoj verziji
- Gumb **"Ažuriraj"** i gumb **"Kasnije"**
- Ako korisnik klikne "Kasnije", dijalog se **ponovo prikazuje za 24 sata**

### 9.4 Kada se provjerava verzija

- **Pri pokretanju aplikacije** (jednom nakon učitavanja)
- **Pri vraćanju iz pozadine** (npr. korisnik koristi drugu aplikaciju pa se vrati)

**Napomena:** iOS verzija force update sustava trenutno nije implementirana.

---

## 10. Push obavijesti

### 10.1 Web push obavijesti (FCM)

BookBed šalje push obavijesti vlasnicima putem Firebase Cloud Messaging (FCM) — trenutno **samo na webu**.

**Inicijalizacija:**
- Pri prvoj prijavi, browser traži dopuštenje za obavijesti
- Korisnik može odobriti ili odbiti
- FCM token se sprema u Firestore (podržava više uređaja po korisniku)

**Vrste obavijesti:**

| Obavijest | Kada se šalje |
|-----------|---------------|
| Nova rezervacija | Kada gost kreira novu rezervaciju |
| Rezervacija potvrđena | Kada se status promijeni u "potvrđena" |
| Rezervacija otkazana | Kada gost otkaže rezervaciju |
| Uplata primljena | Kada je Stripe plaćanje uspješno |

### 10.2 Ponašanje obavijesti

**Aplikacija je otvorena (Foreground):**
- Prikazuje se **snackbar** na dnu ekrana s kratkim opisom
- Gumb **"Pogledaj"** → navigacija na detalje rezervacije

**Aplikacija je zatvorena (Background):**
- Prikazuje se **sistemska obavijest** (u notification centru)
- Klik na obavijest otvara aplikaciju i prikazuje rezervaciju

### 10.3 Odjava i obavijesti

- Pri odjavi, FCM token se **briše** iz Firestore-a
- Korisnik više **ne prima obavijesti** nakon odjave
- Sprječava slanje obavijesti pogrešnom korisniku

---

## 11. Tipovi korisničkih računa

### 11.1 Pregled tipova

| Tip | Opis | Kako se dobiva |
|-----|------|----------------|
| **Trial** | Besplatni probni period | Automatski pri registraciji |
| **Premium** | Plaćena pretplata s punim pristupom | Stripe pretplata (web) |
| **Enterprise** | Poslovni tier | Budući feature |
| **Lifetime** | Trajna premium licenca | Samo admin može dodijeliti |

### 11.2 Upravljanje pretplatom

- Pretplata se upravlja **isključivo na webu** (ne u mobilnoj aplikaciji)
- Razlog: Usklađenost s Apple App Store pravilima (Apple zabranjuje kupnju pretplate izvan App Store-a unutar aplikacije)
- U mobilnoj aplikaciji prikazuje se gumb **"Nastavi na web"** koji otvara web stranicu za upravljanje pretplatom

### 11.3 Lifetime licenca

- Dodjeljuje je **samo administrator** putem Admin Dashboard-a
- Korisnik ne može sam kupiti lifetime licencu
- Trajno daje pristup svim premium funkcionalnostima
- Bilježi se tko je dodijelio i kada (revizijski trag)

---

## 12. Česta pitanja (FAQ)

### Registracija i prijava

**P: Koje metode prijave su dostupne?**
O: Email i lozinka, Google prijava, te Apple prijava (na iOS i web-u).

**P: Zašto ne mogu kliknuti gumb za registraciju?**
O: Morate prihvatiti Uvjete korištenja i Politiku privatnosti (kvačica). Također, sva obavezna polja moraju biti popunjena.

**P: Registrirao sam se s Google-om, ali sad pokušavam s emailom/lozinkom i ne radi.**
O: Ako ste kreirali račun s Google prijavom, morate se i prijavljivati s Google-om. Isti email ne može koristiti obje metode.

**P: Zašto moram verificirati email?**
O: Verifikacija emaila potvrđuje da ste vi vlasnik te email adrese. Potrebna je za primanje obavijesti o rezervacijama i za sigurnost vašeg računa.

**P: Koliko imam pokušaja za prijavu?**
O: 5 pokušaja u 15 minuta. Nakon toga, čekate isteku blokade. Ovo štiti vaš račun od neovlaštenog pristupa.

### Sigurnost

**P: Sprema li BookBed moju lozinku na uređaju?**
O: Ne. Opcija "Zapamti me" sprema **samo email adresu** (ne lozinku) u šifrirano spremište uređaja. Lozinka se nikada ne pohranjuje lokalno.

**P: Što se događa ako netko pogodi moju lozinku?**
O: Sustav blokira prijavu nakon 5 neuspjelih pokušaja. Preporučamo korištenje jake lozinke i dvofaktorske autentikacije putem Google ili Apple prijave.

**P: Kako mogu promijeniti lozinku?**
O: Profil → Promijeni lozinku. Morate unijeti trenutnu lozinku i novu lozinku koja zadovoljava pravila sigurnosti.

**P: Mogu li koristiti istu lozinku kao ranije?**
O: Ne. Sustav provjerava povijest lozinki i ne dopušta ponovnu upotrebu nedavno korištenih lozinki.

### Račun i privatnost

**P: Kako mogu izbrisati svoj račun?**
O: Profil → Izbriši račun. Morate ponovo potvrditi identitet (lozinka ili socijalna prijava). Svi vaši podaci bit će trajno obrisani. Ova radnja je nepovratna.

**P: Što se događa s mojim podacima nakon brisanja računa?**
O: Svi vaši osobni podaci, nekretnine, smještajne jedinice i rezervacije se trajno brišu. Podaci gostiju iz vaših rezervacija se anonimiziraju (GDPR usklađenost).

**P: Koji su moji podaci pohranjeni?**
O: Ime, email, telefon (ako ste unijeli), profilna slika, nekretnine, smještajne jedinice, rezervacije, postavke. Podatke o karticama pohranjuje Stripe, ne BookBed.

**P: Tko ima pristup mojim podacima?**
O: Samo vi i BookBed administratori. Gosti vide samo javne podatke o nekretnini i dostupnost kalendara. Osobni kontakt podaci gostiju vidljivi su samo vama (vlasniku).

### Ažuriranje aplikacije

**P: Zašto moram ažurirati aplikaciju?**
O: Prisilno ažuriranje se prikazuje kada je nova verzija potrebna za sigurnost ili ispravnost rada. Opcionalno ažuriranje donosi poboljšanja koja možete instalirati kada želite.

**P: Mogu li nastaviti koristiti staru verziju?**
O: Ako se prikazuje prisilno ažuriranje — ne, morate ažurirati. Ako je opcionalno — da, ali preporučamo ažuriranje za najbolje iskustvo.

### Obavijesti

**P: Zašto ne primam obavijesti?**
O: Provjerite jeste li dopustili obavijesti u pregledniku (web) ili u postavkama uređaja. Obavijesti se šalju samo dok ste prijavljeni.

**P: Kako isključiti obavijesti?**
O: U postavkama preglednika blokirajte obavijesti za BookBed stranicu. U mobilnoj aplikaciji, isključite obavijesti u sistemskim postavkama uređaja.
