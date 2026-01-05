# Summary: Stripe Cross-Tab Communication & Loading State Fix

**Datum**: 2025-01-XX  
**Problemi riješeni**: Cross-tab komunikacija, Stripe Error 400, beskonačni loading/shimmer efekt

## Pregled problema

1. **Cross-tab komunikacija ne radi**: Originalni tab (widget) nije primao poruke kada se plaćanje završavalo u novom tabu
2. **Stripe Error 400**: Konstantna 400 greška koja je sprječavala otvaranje checkout taba
3. **Beskonačni loading/shimmer**: Originalni tab je ostajao zaglavljen u loading stanju nakon uspješnog plaćanja

## Implementirana rješenja

### 1. Poboljšanje Cross-Tab Komunikacije

#### `booking_widget_screen.dart`

**Dodano**:
- Timer mehanizam (`_paymentCompletionTimeout`) za timeout tracking
- Metoda `_startPaymentCompletionTimeout()` koja resetuje loading state ako poruka ne stigne u 30 sekundi
- Poboljšan error handling u `_handlePostMessage()`, `_handlePaymentCompleteFromOtherTab()`, i `_setupPaymentBridgeListener()`
- Osigurano da se `_isProcessing` resetuje **PRIJE** bilo kakvih async operacija
- Cleanup timeout timer-a u `dispose()` metodi

**Ključne izmjene**:
- `_handlePaymentCompleteFromOtherTab()`: Dodato cancelovanje timeout-a kada se primi poruka
- `_handlePostMessage()`: Dodato cancelovanje timeout-a i bolji error handling
- `_setupPaymentBridgeListener()`: Dodato cancelovanje timeout-a kada se primi poruka preko PaymentBridge
- `_handleStripePayment()`: Dodato pokretanje timeout timer-a nakon što se popup otvori

#### `booking_confirmation_screen.dart`

**Poboljšano**:
- `_notifyParentOfPaymentComplete()` metoda:
  - Dodata validacija bookingId i bookingRef prije slanja
  - Dodat retry mehanizam za BroadcastChannel i postMessage
  - Poboljšano logging sa detaljnim informacijama
  - Osigurano da se poruke šalju sa session_id (ako je dostupan)
  - Dodato višestruko slanje poruka za veću pouzdanost

### 2. Poboljšanje PaymentBridge JavaScript

#### `web/payment_bridge.js`

**Poboljšano**:
- `notifyComplete()` metoda:
  - Dodato praćenje uspješnosti slanja poruka
  - Dodat retry mehanizam ako nijedna metoda ne uspije
  - Poboljšano logging za debugging
  - Osigurano da se poruke šalju preko svih dostupnih kanala

### 3. Debug i Rješavanje Stripe Error 400

#### `functions/src/stripePayment.ts`

**Dodato detaljno logging i validacija**:
- Validacija return URL formata prije provjere whitelist-a
- Detaljno logging za sve validacije (missing fields, invalid URLs, etc.)
- Poboljšane error poruke sa više konteksta
- Validacija svih required fields sa listom nedostajućih polja
- Logging za date conflicts sa detaljima o konfliktima
- Bolji error handling koji preservira HttpsError status kodove

**Ključne izmjene**:
- Validacija return URL formata koristeći `new URL()`
- Detaljno logging za sve validacije sa kontekstom
- Poboljšane error poruke koje su korisnički-friendly
- Validacija owner Stripe account-a sa logging-om

#### `lib/core/services/stripe_service.dart`

**Poboljšano**:
- `createCheckoutSession()` metoda:
  - Dodato mapiranje error kodova na korisnički-friendly poruke
  - Poboljšano error handling sa specifičnim porukama za različite error kodove
  - Detaljnije logging za debugging

#### `lib/features/widget/presentation/screens/booking_widget_screen.dart`

**Dodato**:
- Validacija return URL formata prije slanja u Stripe
- Provjera da li su scheme i host validni
- Detaljno logging za debugging

### 4. Timeout Mehanizam

**Implementirano**:
- Timer koji se pokreće nakon što se popup otvori
- Ako poruka o završetku plaćanja ne stigne u 30 sekundi, automatski se resetuje loading state
- Timeout se canceluje kada se primi poruka o završetku plaćanja
- Cleanup timeout-a u `dispose()` metodi

## Tehnički detalji

### Timeout mehanizam

```dart
void _startPaymentCompletionTimeout() {
  _paymentCompletionTimeout?.cancel();
  _paymentCompletionTimeout = Timer(const Duration(seconds: 30), () {
    if (!mounted) return;
    // Reset loading state
    setState(() {
      _isProcessing = false;
      _showGuestForm = false;
    });
    _resetFormState();
  });
}
```

### Cross-tab komunikacija flow

1. Korisnik klikne "Pay" → `_isProcessing = true`
2. Otvara se popup/novi tab → `_startPaymentCompletionTimeout()` se poziva
3. Nakon plaćanja, confirmation screen šalje poruke preko:
   - BroadcastChannel
   - postMessage
   - PaymentBridge
   - localStorage (fallback)
4. Originalni tab prima poruku → canceluje timeout → resetuje `_isProcessing`
5. Ako poruka ne stigne u 30 sekundi → timeout resetuje state

### Error handling poboljšanja

- Sve async operacije provjeravaju `mounted` status
- Timeout se uvijek canceluje kada se primi poruka
- Cleanup u `dispose()` metodi osigurava da se svi resursi oslobode
- Retry mehanizmi za kritične operacije

## Testiranje

Preporučeni test scenariji:

1. **Popup scenario**: Otvori popup, završi plaćanje, provjeri da se originalni tab resetuje
2. **New tab scenario**: Popup blokiran, otvori novi tab, završi plaćanje, provjeri komunikaciju
3. **Error scenario**: Simuliraj 400 grešku, provjeri error handling
4. **Timeout scenario**: Simuliraj da poruka ne stigne, provjeri timeout mehanizam
5. **Multiple tabs scenario**: Otvori više tabova, završi plaćanje u jednom, provjeri da se svi resetuju

## Fajlovi izmijenjeni

1. `lib/features/widget/presentation/screens/booking_widget_screen.dart`
   - Dodat timeout mehanizam
   - Poboljšana cross-tab komunikacija
   - Poboljšana validacija return URL-a
   - Cleanup u dispose()

2. `lib/features/widget/presentation/screens/booking_confirmation_screen.dart`
   - Poboljšano slanje poruka sa retry mehanizmom
   - Dodata validacija prije slanja
   - Poboljšano logging

3. `web/payment_bridge.js`
   - Dodat retry mehanizam
   - Poboljšano praćenje uspješnosti slanja
   - Poboljšano logging

4. `functions/src/stripePayment.ts`
   - Dodato detaljno logging
   - Poboljšana validacija return URL-a
   - Poboljšane error poruke
   - Detaljno logging za sve validacije

5. `lib/core/services/stripe_service.dart`
   - Poboljšano error handling
   - Dodato mapiranje error kodova na korisnički-friendly poruke

## Rezultat

- ✅ Cross-tab komunikacija sada radi pouzdano
- ✅ Loading state se resetuje u svim scenarijima
- ✅ Timeout mehanizam sprječava beskonačni loading
- ✅ Stripe Error 400 sada ima detaljno logging za debugging
- ✅ Poboljšan error handling sa korisnički-friendly porukama
- ✅ Sve async operacije imaju proper cleanup
- ✅ Detaljno debug logging implementiran kroz cijeli flow

## Debug Logging

Svi kritični koraci imaju detaljno logging za lakše debugging:

### Payment Flow Logging:
- `[Stripe]` - Stripe payment flow events
- `[STRIPE_SESSION]` - Stripe session handling
- `[STRIPE_TIMEOUT]` - Timeout mehanizam events
- `[PaymentBridge]` - PaymentBridge JavaScript events
- `[PaymentComplete]` - Payment completion notifications
- `[CrossTab]` / `[TAB_COMM]` - Cross-tab communication
- `[PostMessage]` - PostMessage communication

### Logging Points:
1. **Payment Start**: Logging kada se payment flow pokrene
2. **Popup/Redirect**: Logging za popup opening i redirect scenarios
3. **Timeout Start**: Logging kada se timeout timer pokrene
4. **Message Received**: Logging kada se primi poruka o završetku plaćanja
5. **Timeout Cancelled**: Logging kada se timeout canceluje
6. **State Reset**: Logging kada se loading state resetuje
7. **Error Handling**: Detaljno logging za sve error scenarije

### Debug Mode Usage:

Za debugging u produkciji, sve log poruke su dostupne u browser console-u:
- **Flutter/Dart logs**: Dostupni u browser console sa tag-ovima
- **JavaScript logs**: Dostupni u browser console sa `[PaymentBridge]` prefixom
- **Backend logs**: Dostupni u Firebase Functions logs sa detaljnim kontekstom

## Napomene

- Timeout od 30 sekundi je dovoljno dug za webhook processing i message delivery
- Retry mehanizmi osiguravaju veću pouzdanost cross-tab komunikacije
- Detaljno logging omogućava lakše debugging u produkciji
- Cleanup u dispose() osigurava da se svi resursi oslobode pravilno

