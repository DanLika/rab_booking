# Developer Setup Checklist - Platform API Integracije

**Status**: 📋 PLANNING / FUTURE WORK (NIJE IMPLEMENTIRANO)
**Last Updated**: 2025-12-16

---

## ⚠️ VAŽNO: Trenutni Status

### Direktni API pristup NIJE DOSTUPAN

| Platforma | Status | Razlog |
|-----------|--------|--------|
| **Booking.com** | ❌ PAUZIRAN | Partner program pauziran (late 2024), zahtijeva business registraciju |
| **Airbnb** | ❌ INVITATION-ONLY | Nema javnog API-ja, samo za pozvane partnere |

### Skeleton kod postoji ali NE RADI

Fajlovi ispod sadrže **placeholder kod** koji neće raditi bez partner approval-a:

| Fajl | Status | Napomena |
|------|--------|----------|
| [bookingComApi.ts](../../../functions/src/bookingComApi.ts) | ⚠️ SKELETON | Linija 9: "Direct API access is currently NOT AVAILABLE" |
| [airbnbApi.ts](../../../functions/src/airbnbApi.ts) | ⚠️ SKELETON | Linija 13: "Direct API access is currently NOT AVAILABLE" |

### Šta RADI trenutno

| Funkcionalnost | Status | Detalji |
|----------------|--------|---------|
| **iCal Sync** | ✅ IMPLEMENTIRANO | Import kalendara sa Booking.com, Airbnb, Google Calendar |
| **iCal Export** | ✅ IMPLEMENTIRANO | Export BookBed kalendara u iCal format |

### Preporučena alternativa

Ako treba two-way sync sa Booking.com/Airbnb, koristi **Channel Manager**:
- Vidi: [CHANNEL_MANAGER_SETUP.md](../channel-managers/CHANNEL_MANAGER_SETUP.md)
- Preporuka: **Beds24** (najjeftiniji, unlimited free trial)

---

## Pregled

Ovaj checklist vodi kroz sve korake potrebne za setup Booking.com i Airbnb API integracija **KADA/AKO** direktni API pristup postane dostupan.

## Pre-requisites

- [ ] Research završen (koristi `docs/RESEARCH_PROMPT_PLATFORM_APIS.md`)
- [ ] Odlučeno koji pristup koristiti (direktni API ili channel manager)
- [ ] Odlučeno da li je potrebna firma/company registracija

## Booking.com Setup

### 1. Account Setup
- [ ] Registrovan Booking.com Partner Hub account
- [ ] Verifikovan email
- [ ] Popunjeni business details (ako je potrebno)
- [ ] Upload-ovana dokumentacija (ako je potrebno)

### 2. API Access
- [ ] Podnesen zahtjev za API access
- [ ] Odobren pristup (čekanje na approval)
- [ ] Dobijen Client ID
- [ ] Dobijen Client Secret
- [ ] Dobijen Redirect URI (konfigurisan)

### 3. OAuth Setup
- [ ] Konfigurisan OAuth application u Booking.com dashboard-u
- [ ] Postavljen Redirect URI: `https://your-domain.com/api/booking-com-oauth-callback`
- [ ] Testiran OAuth flow u sandbox okruženju (ako postoji)

### 4. Environment Variables
- [ ] Postavljen `BOOKING_COM_CLIENT_ID` u Firebase Functions config
- [ ] Postavljen `BOOKING_COM_CLIENT_SECRET` u Firebase Functions config
- [ ] Postavljen `BOOKING_COM_REDIRECT_URI` u Firebase Functions config

### 5. Code Updates
- [ ] Ažuriran `functions/src/bookingComApi.ts` sa stvarnim API endpoint-ima
- [ ] Ažuriran OAuth authorization URL
- [ ] Ažuriran OAuth token URL
- [ ] Ažuriran Calendar API endpoint-ovi

### 6. Testing
- [ ] Testiran OAuth flow end-to-end
- [ ] Testirano blokiranje datuma
- [ ] Testirano čitanje rezervacija
- [ ] Testirano error handling

## Airbnb Setup

### 1. Account Setup
- [ ] Registrovan Airbnb Partner API account
- [ ] Verifikovan email
- [ ] Popunjeni business details (ako je potrebno)
- [ ] Upload-ovana dokumentacija (ako je potrebno)

### 2. API Access
- [ ] Podnesen zahtjev za API access
- [ ] Odobren pristup (čekanje na approval)
- [ ] Dobijen Client ID
- [ ] Dobijen Client Secret
- [ ] Dobijen Redirect URI (konfigurisan)

### 3. OAuth Setup
- [ ] Konfigurisan OAuth application u Airbnb dashboard-u
- [ ] Postavljen Redirect URI: `https://your-domain.com/api/airbnb-oauth-callback`
- [ ] Testiran OAuth flow u sandbox okruženju (ako postoji)

### 4. Environment Variables
- [ ] Postavljen `AIRBNB_CLIENT_ID` u Firebase Functions config
- [ ] Postavljen `AIRBNB_CLIENT_SECRET` u Firebase Functions config
- [ ] Postavljen `AIRBNB_REDIRECT_URI` u Firebase Functions config

### 5. Code Updates
- [ ] Ažuriran `functions/src/airbnbApi.ts` sa stvarnim API endpoint-ima
- [ ] Ažuriran OAuth authorization URL
- [ ] Ažuriran OAuth token URL
- [ ] Ažuriran Calendar API endpoint-ovi

### 6. Testing
- [ ] Testiran OAuth flow end-to-end
- [ ] Testirano blokiranje datuma
- [ ] Testirano čitanje rezervacija
- [ ] Testirano error handling

## Firebase Functions Setup

### 1. OAuth Callback Routes
- [ ] Deploy-ovana `handleBookingComOAuthCallback` function
- [ ] Deploy-ovana `handleAirbnbOAuthCallback` function
- [ ] Testirano da callback URL-ovi rade

### 2. Environment Variables
- [ ] Sve environment variables postavljene u Firebase Functions
- [ ] Testirano da se environment variables čitaju ispravno

### 3. Encryption
- [x] Setup-ovan encryption key za token storage (`ENCRYPTION_KEY`) - **KOD POSTOJI**
- [ ] Testirano da se tokeni enkriptuju/dekriptuju ispravno
- [ ] **NAPOMENA:** Za produkciju, koristiti Google Cloud KMS umjesto simple encryption

## Production Deployment

### 1. Pre-Deployment
- [ ] Sve testove prošlo u staging okruženju
- [ ] Error handling testiran
- [ ] Rate limiting testiran (ako je implementiran)
- [ ] Logging testiran

### 2. Deployment
- [ ] Deploy-ovane Cloud Functions
- [ ] Verifikovano da se functions pokreću
- [ ] Testiran OAuth flow u produkciji
- [ ] Testirano blokiranje datuma u produkciji

### 3. Monitoring
- [ ] Setup-ovan monitoring za API calls
- [ ] Setup-ovan alerting za errors
- [ ] Setup-ovan logging za debugging

## Alternativni Pristupi (PREPORUČENO)

### Channel Manager Integration (✅ DOKUMENTIRANO)
- [ ] Odabran channel manager (npr. Beds24, Hosthub, Guesty)
- [ ] Registrovan account
- [ ] Dobijen API access
- [ ] Integrisan channel manager API
- [ ] Testiran sync kroz channel manager

**Vidi:** [CHANNEL_MANAGER_SETUP.md](../channel-managers/CHANNEL_MANAGER_SETUP.md)

### iCal Sync (✅ IMPLEMENTIRANO I RADI)
- [x] iCal import iz Booking.com, Airbnb, Google Calendar
- [x] iCal export iz BookBed
- [x] SSRF zaštita sa whitelist domena
- [x] Scheduled sync (Cloud Function)

**Fajlovi:**
- [icalSync.ts](../../../functions/src/icalSync.ts)
- [icalExport.ts](../../../functions/src/icalExport.ts)
- [ical_sync_settings_screen.dart](../../../lib/features/owner_dashboard/presentation/screens/ical/ical_sync_settings_screen.dart)

## Notes

- **Timeline:** Očekivano vrijeme za setup: 2-4 nedelje (zavisi od approval procesa)
- **Costs:** Provjeriti cijene za API access (ako postoje)
- **Limitations:** Provjeriti rate limits i ograničenja
- **Support:** Provjeriti da li postoji developer support

## Troubleshooting

### Common Issues:
1. **OAuth callback ne radi:** Provjeriti da li je redirect URI ispravno konfigurisan
2. **API calls fail:** Provjeriti da li su credentials ispravni
3. **Token expiration:** Provjeriti refresh token flow
4. **Rate limiting:** Provjeriti rate limits i implementirati retry logic

## Resources

- Booking.com API Docs: https://developers.booking.com/connectivity/docs (restricted access)
- Airbnb API Docs: https://developer.airbnb.com/ (restricted access)
- Firebase Functions Docs: https://firebase.google.com/docs/functions
- OAuth 2.0 Spec: https://oauth.net/2/
- **Channel Manager Setup:** [CHANNEL_MANAGER_SETUP.md](../channel-managers/CHANNEL_MANAGER_SETUP.md)
