# Stripe Cross-Tab Communication - Debug Guide

## Debug Mode

Svi kritični koraci u Stripe payment flow-u imaju detaljno logging za debugging.

## Browser Console Logs

### Flutter/Dart Logs

Svi logovi su dostupni u browser console sa sljedećim tag-ovima:

#### Payment Flow
- `[Stripe]` - Opći Stripe payment flow events
- `[STRIPE_SESSION]` - Stripe session handling i polling
- `[STRIPE_TIMEOUT]` - Timeout mehanizam events
- `[STRIPE_RETURN]` - Stripe return handling

#### Cross-Tab Communication
- `[CrossTab]` / `[TAB_COMM]` - Cross-tab communication via BroadcastChannel
- `[PostMessage]` - PostMessage communication
- `[PaymentBridge]` - PaymentBridge JavaScript bridge events
- `[PaymentComplete]` - Payment completion notifications

### JavaScript Console Logs

PaymentBridge JavaScript logs su dostupni sa `[PaymentBridge]` prefixom:

```javascript
[PaymentBridge] Notifying payment complete: {...}
[PaymentBridge] Sent via BroadcastChannel
[PaymentBridge] Sent via postMessage to opener
[PaymentBridge] Retry sent via BroadcastChannel
```

## Debug Scenarios

### 1. Payment Flow Start

**Kada se vidi**: Korisnik klikne "Pay" button

**Logovi**:
```
[Stripe] Pre-opened popup, result: popup
[Stripe] Return URL validated: https://...
[Stripe] Creating checkout session...
[Stripe] Checkout session created: https://...
[Stripe] Popup URL updated successfully
[Stripe] Starting payment completion timeout (30s)
```

### 2. Payment Completion Message Received

**Kada se vidi**: Poruka o završetku plaćanja stigne u originalni tab

**Logovi**:
```
[PaymentBridge] Payment complete received, sessionId: cs_xxx
[PaymentBridge] Payment completion timeout cancelled (message received)
[PaymentBridge] Loading state reset (message received)
[STRIPE_RETURN] Handling Stripe return with session_id: cs_xxx
[STRIPE_RETURN] Payment completion timeout cancelled
```

**ILI**:
```
[PostMessage] Received: stripe-payment-complete
[PostMessage] Payment complete, showing confirmation
[PostMessage] Payment completion timeout cancelled (message received)
[PostMessage] Loading state reset (message received)
```

**ILI**:
```
[CrossTab] Received message: paymentComplete
[CrossTab] Payment complete received for booking: BOOK-123
[CrossTab] Payment completion timeout cancelled (message received)
[CrossTab] Loading state reset (message received)
```

### 3. Timeout Scenario

**Kada se vidi**: Poruka ne stigne u 30 sekundi

**Logovi**:
```
[PaymentTimeout] Starting 30-second timeout timer for payment completion
[PaymentTimeout] ⚠️ Payment completion message not received within 30 seconds, resetting loading state
[PaymentTimeout] Loading state reset due to timeout
```

### 4. Error Scenarios

#### Invalid Return URL
```
[Stripe] Invalid return URL format: ...
[Stripe] Error in payment flow
```

#### Missing Booking Data
```
[StripeService] Firebase Functions error: invalid-argument - Missing required booking fields: unitId, checkIn
```

#### Stripe Account Not Connected
```
[StripeService] Firebase Functions error: failed-precondition - Owner has not connected their Stripe account
```

## Backend Logs (Firebase Functions)

### createStripeCheckoutSession

**Success**:
```
createStripeCheckoutSession called { hasBookingData: true, returnUrl: "provided", hasAuth: true }
createStripeCheckoutSession: Return URL parsed { origin: "https://...", pathname: "/", hash: "#/calendar" }
createStripeCheckoutSession: Owner Stripe account found { ownerId: "...", stripeAccountId: "acct_..." }
Placeholder booking created: booking_123 (BOOK-123)
Stripe checkout session created: cs_xxx
```

**Error**:
```
createStripeCheckoutSession: Missing required booking fields: unitId, checkIn
createStripeCheckoutSession: Invalid return URL (not in whitelist): https://...
createStripeCheckoutSession: Owner ... has not connected Stripe account
```

### handleStripeWebhook

**Success**:
```
Processing Stripe webhook for placeholder booking: booking_123
Updating placeholder booking booking_123 to confirmed status
Placeholder booking booking_123 confirmed after Stripe payment
```

**Error**:
```
Missing required metadata in session { has_unit_id: false, has_property_id: true, ... }
Missing placeholder_booking_id in webhook metadata
Placeholder booking not found: booking_123 - may have expired
```

## Troubleshooting

### Problem: Loading state se ne resetuje

**Provjeri**:
1. Da li se timeout pokreće: `[Stripe] Starting payment completion timeout (30s)`
2. Da li se poruka prima: `[PaymentBridge] Payment complete received` ili `[PostMessage] Received`
3. Da li se timeout canceluje: `[PaymentBridge] Payment completion timeout cancelled`

**Rješenje**: Ako timeout ne radi, provjeri da li je `_startPaymentCompletionTimeout()` pozvan nakon što se popup otvori.

### Problem: Poruke se ne primaju

**Provjeri**:
1. Da li se poruke šalju: `[PaymentComplete] Sent via BroadcastChannel`
2. Da li su listeneri aktivni: `[PostMessage] Initialized listener`
3. Browser console za JavaScript errors

**Rješenje**: Provjeri da li su BroadcastChannel i postMessage listeneri pravilno postavljeni.

### Problem: Stripe Error 400

**Provjeri**:
1. Backend logs za detaljne error poruke
2. Return URL format: `[Stripe] Return URL validated`
3. Missing fields: `createStripeCheckoutSession: Missing required booking fields`

**Rješenje**: Provjeri backend logs za specifičan error i popravi prema poruci.

## Debug Checklist

- [ ] Payment flow start logovi se vide
- [ ] Timeout timer se pokreće
- [ ] Poruke se šalju iz confirmation screen-a
- [ ] Poruke se primaju u originalnom tabu
- [ ] Timeout se canceluje kada se primi poruka
- [ ] Loading state se resetuje
- [ ] Nema JavaScript errors u console-u
- [ ] Backend logs pokazuju uspješan flow

## Production Monitoring

Za produkciju, svi logovi su dostupni u:
- **Browser Console**: Flutter/Dart i JavaScript logs
- **Firebase Functions Logs**: Backend logs sa detaljnim kontekstom
- **Sentry** (ako je konfigurisan): Error tracking i monitoring

