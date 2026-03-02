---
paths:
  - "functions/src/stripe*.ts"
  - "functions/src/handleStripeWebhook*"
  - "lib/**/stripe*"
  - "lib/**/payment*"
---

# Stripe Flow (LIVE MODE)

**⚠️ KRITIČNO - PRODUKCIJA**: Stripe je u LIVE MODE. Ne mijenjaj bez testiranja!

## Ključni fajlovi — NE DIRATI bez razloga

| Fajl | Svrha |
|------|-------|
| `stripePayment.ts` | Checkout session kreiranje, minimum €0.50 validacija |
| `stripeConnect.ts` | Owner Stripe Connect onboarding |
| `handleStripeWebhook` | Webhook handler za `checkout.session.completed/expired` |

## Firebase Secrets (LIVE ključevi)

- `STRIPE_SECRET_KEY` - Live secret key
- `STRIPE_WEBHOOK_SECRET` - Live webhook signing secret

## Stripe Connect Model: Standard (Direct charges)

- Owner ima nezavisan Stripe račun
- Novac ide DIREKTNO owner-u
- Platforma trenutno NE uzima fee (application_fee_amount = 0)
- Owner je merchant of record (odgovoran za porez)

## Minimum iznos

€0.50 (Stripe zahtjev) - validacija u `stripePayment.ts`

## Payment Flow

```
1. User klikne "Pay with Stripe"
2. PLACEHOLDER booking kreira se sa status="pending" (blokira datume)
3. Same-tab redirect na Stripe Checkout
4. Webhook UPDATE-a placeholder na status="confirmed"
5. Return URL: ?stripe_status=success&session_id=cs_xxx
6. Widget poll-uje fetchBookingByStripeSessionId() (max 30s)
7. Confirmation screen
```

## KRITIČNO - Collection Group Query Bug

- NE KORISTITI `FieldPath.documentId` sa `collectionGroup()` query
- **RJEŠENJE**: Koristi `stripe_session_id` field za lookup umjesto document ID
- Svi cross-tab messaging pathovi (BroadcastChannel, postMessage) MORAJU proslijediti `sessionId`
- `TabCommunicationService.sendPaymentComplete()` prima optional `sessionId` parametar

**KRITIČNO**: Placeholder booking sprječava race condition gdje 2 korisnika plate za iste datume.

## Stripe Fee

- Fee (1.4% + €0.25) se **SKIDA SA OWNER-A**, ne dodaje se na cijenu
- Korisnik plaća: `totalPrice = roomPrice + servicesTotal`
- Owner dobija: `totalPrice - stripeFee` (npr. 170€ → 167.73€)
- `servicesTotal` parametar se UVIJEK šalje sa klijenta na server za validaciju
