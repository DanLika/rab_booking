# Subdomain Setup za Booking Details Page

**Status**: ✅ CODE IMPLEMENTED | ⚠️ DEPLOYMENT PENDING
**Last Updated**: 2025-12-16

---

## 📋 Deployment Checklist

### Kod (✅ Implementirano)
- [x] `/view` ruta u `router_widget.dart`
- [x] `BookingViewScreen` za prikaz booking detalja
- [x] `view.bookbed.io` preskočen u `subdomain_service.dart`
- [x] `generateViewBookingUrl()` u `emailService.ts`
- [x] `BOOKING_DOMAIN` env var logika
- [x] `viewBookingUrl` u svim email template-ima

### Deployment (⚠️ Manual koraci - NIJE URAĐENO)
- [ ] Firebase Console: Dodati `view.bookbed.io` custom domain
- [ ] Cloudflare DNS: CNAME `view` → `bookbed-widget.web.app`
- [ ] Firebase Functions: Provjeriti `BOOKING_DOMAIN` env var
- [ ] Cloudflare SSL/TLS: Postaviti na "Full" ili "Full (strict)"
- [ ] Testiranje: Provjeriti `https://view.bookbed.io`

---

## Pregled

Za Booking Details Page koristimo novi subdomain `view.bookbed.io` jer:
- `app.bookbed.io` je već korišćen za owner dashboard
- `bookbed.io` će biti korišćen za prezentaciju softvera
- `view.bookbed.io` jasno označava da je za pregled rezervacija

## Firebase Hosting Configuration

**VAŽNO**: Booking details page je deo widget aplikacije, tako da koristimo **isti hosting target** kao widget (`bookbed-widget`). Ne treba novi hosting target!

### 1. Dodati Custom Domain u Firebase Console

1. Idite na [Firebase Console](https://console.firebase.google.com/)
2. Selektujte projekat `rab-booking-248fc`
3. Idite na **Hosting** → Selektujte `bookbed-widget` site
4. Kliknite **"Add custom domain"**
5. Unesite: `view.bookbed.io`
6. Firebase će dati instrukcije za DNS verifikaciju

**Napomena**: Ne treba menjati `firebase.json` ili `.firebaserc` - koristimo postojeći `widget` target.

### 2. Deploy (isti kao widget)

```bash
# Deploy widget aplikacije (uključuje booking details page)
firebase deploy --only hosting:widget
```

**Napomena**: Booking details page je već deo widget aplikacije, tako da se automatski deploy-uje sa widget-om.

### 3. DNS Configuration

#### Cloudflare Setup (Preporučeno)

**VAŽNO**: Za Firebase Hosting custom domain verifikaciju, **privremeno isključite Cloudflare proxy** (DNS-only mode).

1. **Privremeno isključite proxy** (za verifikaciju):
   - **Name**: `view`
   - **Type**: `CNAME`
   - **Target**: `bookbed-widget.web.app` ✅ (isti kao widget)
   - **Proxy status**: **DNS only** (sivi oblak) ⚠️
   - **TTL**: Auto

2. **Sačekajte Firebase verifikaciju** (5-15 minuta):
   - Firebase će automatski verifikovati domen
   - SSL sertifikat će biti automatski postavljen
   - Proverite status u Firebase Console > Hosting > Custom domains

3. **Nakon verifikacije, uključite proxy ponovo** (preporučeno):
   - **Proxy status**: **Proxied** (narančasti oblak) ✅
   - Cloudflare će sada proxirati zahtev preko Firebase-a
   - **VAŽNO**: Postavite SSL/TLS mode na **"Full"** ili **"Full (strict)"** u Cloudflare SSL/TLS settings

#### Alternativno (bez Cloudflare proxy):

- **Name**: `view`
- **Type**: `CNAME`
- **Value**: `bookbed-widget.web.app` ✅
- **TTL**: 3600 (ili default)
- **Bez proxy-a** (direktno na Firebase)

### 4. Environment Variables

**AUTOMATSKI**: Kod automatski koristi `view.{BOOKING_DOMAIN}` ako je `BOOKING_DOMAIN` environment variable postavljen.

**Nema potrebe za dodatnim environment variable-om!**

Ako već imate `BOOKING_DOMAIN=bookbed.io` postavljen u Firebase Functions, kod će automatski koristiti `view.bookbed.io` za booking details linkove.

#### Provera

Proverite da li već imate `BOOKING_DOMAIN` postavljen:
- Firebase Console → Functions → Configuration → Environment variables
- Ako postoji `BOOKING_DOMAIN=bookbed.io`, sve će raditi automatski!

#### Ako nemate BOOKING_DOMAIN

Ako nemate `BOOKING_DOMAIN` postavljen, dodajte ga:

```bash
# Firebase Functions v2
firebase functions:secrets:set BOOKING_DOMAIN
# Unesite: bookbed.io

# Deploy functions
firebase deploy --only functions
```

**Napomena**: Kod automatski konstruiše `view.bookbed.io` iz `BOOKING_DOMAIN` - nema potrebe za dodatnim `VIEW_BOOKING_URL` variable-om!

### 5. Email Service Update

Email service automatski koristi `view.bookbed.io` za booking details linkove kada je `BOOKING_DOMAIN` postavljen.

## HTTPS Setup

Firebase Hosting automatski obezbeđuje HTTPS za sve subdomain-e. Nema potrebe za dodatnom konfiguracijom SSL sertifikata.

**Ako koristite Cloudflare Proxy:**
- Idite na Cloudflare Dashboard → SSL/TLS
- Postavite SSL/TLS encryption mode na **"Full"** ili **"Full (strict)"**
- Ovo obezbeđuje da Cloudflare komunicira sa Firebase-om preko HTTPS

## Cloudflare Proxy - Sigurnosne Prednosti

Uključivanje Cloudflare Proxy nakon Firebase verifikacije pruža **dodatne sigurnosne slojeve**:

### ✅ Prednosti

1. **DDoS Zaštita**
   - Automatska zaštita od DDoS napada
   - Cloudflare filtrira zlonamerne zahtev pre nego što stignu do Firebase-a
   - Zaštita od volumenskih napada (Layer 3/4 i Layer 7)

2. **Web Application Firewall (WAF)**
   - Dodatna zaštita od web napada (SQL injection, XSS, itd.)
   - Može se konfigurisati custom rules za booking details page
   - Automatska detekcija i blokiranje poznatih napada

3. **Rate Limiting (Infrastrukturni Nivo)**
   - Dodatni rate limiting na nivou Cloudflare-a
   - Komplementarno sa rate limiting-om u Cloud Functions
   - Zaštita od brute force napada na booking details page

4. **Bot Protection**
   - Automatska detekcija i blokiranje botova
   - Zaštita od scraping-a i automatskih napada
   - Challenge-based zaštita (CAPTCHA) za sumnjive zahteve

5. **IP Masking**
   - Skriva prave Firebase IP adrese
   - Otežava direktne napade na Firebase infrastrukturu
   - Dodatni layer anonimnosti

6. **Geolocation Filtering** (opciono)
   - Može se konfigurisati da blokira zahteve iz određenih zemalja
   - Korisno ako booking details page treba da bude dostupan samo u određenim regionima

7. **Caching & Performance**
   - Može poboljšati performanse kroz caching statičkih resursa
   - Smanjuje opterećenje Firebase Hosting-a

### ⚠️ Napomene

- **SSL Mode**: Obavezno postavite SSL/TLS mode na **"Full"** ili **"Full (strict)"** u Cloudflare-u
- **Latency**: Cloudflare proxy obično **smanjuje** latency (edge locations bliže korisnicima)
- **Firebase Functions**: Cloudflare proxy ne utiče na Cloud Functions - one i dalje imaju svoj rate limiting

### 📊 Trenutna Sigurnost (bez Cloudflare Proxy)

Već imate:
- ✅ Rate limiting u Cloud Functions (10 attempts/min za token verification)
- ✅ Rate limiting za widget bookings (5 attempts/5min per IP)
- ✅ Token-based authentication sa expiration
- ✅ Email verification za pristup
- ✅ Firebase Hosting HTTPS

**Cloudflare Proxy dodaje**: Infrastrukturni layer zaštite koji radi **pre** nego što zahtev stigne do Firebase-a.

## Testiranje

1. Deploy na Firebase Hosting: `firebase deploy --only hosting:widget`
2. Proveriti da li je dostupan: `https://view.bookbed.io`
3. Testirati booking details link iz emaila
4. Proveriti da li HTTPS radi ispravno

## Troubleshooting

### Problem: Subdomain ne radi
- Proveriti DNS propagaciju (može trajati do 48h)
- Proveriti Firebase Hosting target configuration
- Proveriti da li je deploy uspešan

### Problem: HTTPS ne radi
- Firebase automatski obezbeđuje HTTPS, ali može potrajati nekoliko minuta
- Proveriti Firebase Console > Hosting > Custom domains
- **Ako koristite Cloudflare proxy**: Privremeno isključite proxy dok Firebase ne postavi SSL sertifikat

### Problem: Email linkovi ne koriste novi subdomain
- Proveriti `BOOKING_DOMAIN` environment variable
- Proveriti `generateViewBookingUrl` funkciju u `emailService.ts`

---

## 📁 Reference (Implementirani fajlovi)

| Fajl | Svrha |
|------|-------|
| [router_widget.dart:43-52](../../../lib/core/config/router_widget.dart#L43) | `/view` ruta definicija |
| [booking_view_screen.dart](../../../lib/features/widget/presentation/screens/booking_view_screen.dart) | Screen za prikaz booking detalja |
| [subdomain_service.dart:50-52](../../../lib/features/widget/domain/services/subdomain_service.dart#L50) | Skip `view.bookbed.io` |
| [emailService.ts:310-357](../../../functions/src/emailService.ts#L310) | `generateViewBookingUrl()` |
| [emailService.ts:149-152](../../../functions/src/emailService.ts#L149) | `BOOKING_DOMAIN` logika |
