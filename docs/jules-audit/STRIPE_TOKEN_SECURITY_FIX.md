# Jules Branch Audit: Stripe Token Security Fix

**Branch:** `fix/stripe-token-leak-6717305895157686096`
**Author:** google-labs-jules[bot]
**Audit Date:** 2026-01-09
**Severity:** 🔴 KRITIČNO

---

## 📋 SAŽETAK

Sigurnosna ranjivost gdje se plaintext access token slao u Stripe checkout session metadata, izlažući ga third-party servisu.

---

## 🔴 RANJIVOST (PRIJE)

```typescript
// createStripeCheckoutSession - RANJIVO
metadata: {
  access_token_plaintext: placeholderResult.accessToken, // ← PLAINTEXT U STRIPE
}

// handleStripeWebhook - ČITA IZ STRIPE
const accessTokenPlaintext = metadata.access_token_plaintext;
```

**Rizici:**
- Token vidljiv u Stripe Dashboard
- Token vidljiv u Stripe API responses
- Token izložen third-party servisu

---

## ✅ FIX (POSLIJE)

```typescript
// createStripeCheckoutSession - SIGURNO
metadata: {
  // access_token_plaintext UKLONJEN
}

// handleStripeWebhook - GENERIRA NOVI TOKEN
const {token: newAccessToken, hashedToken: newHashedToken} =
  generateBookingAccessToken();
```

---

## 📁 PROMJENE

**Fajl:** `functions/src/stripePayment.ts`

### 1. createStripeCheckoutSession()
- Uklonjen `access_token_plaintext` iz Stripe metadata
- Token više nije izložen Stripe-u

### 2. handleStripeWebhook()
- Generira NOVI access token nakon uspješne uplate
- Sprema novi hash u booking (`access_token`, `token_expires_at`)
- Koristi novi plaintext token za email

---

## ⚠️ UTJECAJ NA FRONTEND

**NEMA UTJECAJA** - promjene su samo na backendu:
- Widget flow ostaje isti
- Stripe checkout flow ostaje isti
- Polling/confirmation flow ostaje isti
- Cancel flow ostaje isti

---

## 🔒 SIGURNOSNA POBOLJŠANJA

| Prije | Poslije |
|-------|---------|
| Token u Stripe metadata | Token NIJE u Stripe |
| Token generiran prije plaćanja | Token generiran NAKON plaćanja |
| Isti token za placeholder i confirmed | Novi token za confirmed booking |

---

**Status:** ✅ IMPLEMENTIRANO

**Datum implementacije:** 2026-01-09
