# Plan za rješavanje Keyboard Dismiss Bug-a u Landscape Mode-u

## Problem

Rješenje za Flutter issue #175074 radi u **portrait mode-u**, ali **ne radi u landscape mode-u** na Android Chrome-u.

## Analiza problema

### Zašto ne radi u landscape mode-u?

1. **JavaScript threshold prevelik** (`web/index.html`):
   - Fiksni threshold od `100px` (`heightDiff > 100`) je prevelik za landscape mode
   - U landscape mode-u, viewport height je manji (npr. 400-500px umjesto 800-900px)
   - Keyboard zauzima manje prostora (150-200px umjesto 300-400px)
   - Promjena height-a kada se keyboard zatvori može biti samo 50-80px
   - **Rezultat**: Threshold od 100px nikad se ne postiže, pa se keyboard dismiss ne detektuje

2. **Ne detektuje orijentaciju**:
   - JavaScript kod ne provjerava da li je telefon u landscape mode-u
   - Ne prilagođava threshold-e dinamički

3. **Dart mixin ima prilagođene threshold-e, ali možda nisu dovoljni**:
   - Landscape threshold: 60px (umjesto 100px)
   - Ali možda i 60px nije dovoljno osjetljiv za sve slučajeve

## Rješenje

### 1. JavaScript fix u `web/index.html`

**Promjene:**
- Detektovati orijentaciju (landscape vs portrait)
- Prilagoditi threshold-e dinamički na osnovu orijentacije i viewport size-a
- Koristiti relativne threshold-e (postotak viewport-a) umjesto fiksnih vrijednosti

**Nova logika:**
```javascript
// Detektuj orijentaciju
var isLandscape = window.innerWidth > window.innerHeight;

// Dinamički threshold na osnovu orijentacije i viewport size-a
var viewportHeight = viewport.height;
var threshold = isLandscape 
  ? Math.max(viewportHeight * 0.15, 50)  // 15% ili minimum 50px za landscape
  : Math.max(viewportHeight * 0.12, 100); // 12% ili minimum 100px za portrait

// Detektuj keyboard dismiss
var keyboardDismissed = heightDiff > threshold && currentHeight >= fullHeight - (threshold * 0.5);
```

### 2. Poboljšati Dart mixin (`keyboard_dismiss_fix_approach1.dart`)

**Promjene:**
- Smanjiti landscape threshold sa 60px na 50px ili koristiti relativni threshold
- Dodati dodatne provjere za landscape mode
- Možda dodati fallback mehanizam ako visualViewport ne radi u landscape mode-u

### 3. Dodati debug logging

**Za testiranje:**
- Console log-ovi u JavaScript-u da vidimo šta se dešava u landscape mode-u
- Log-ovi u Dart mixin-u za debugging

## Koraci implementacije

### Korak 1: Poboljšati JavaScript fix u `web/index.html`

1. Dodati detekciju orijentacije
2. Prilagoditi threshold-e dinamički
3. Dodati debug logging
4. Testirati u landscape mode-u

### Korak 2: Poboljšati Dart mixin

1. Smanjiti landscape threshold
2. Dodati dodatne provjere
3. Testirati

### Korak 3: Testiranje

1. Testirati na stvarnom Android uređaju u landscape mode-u
2. Testirati različite veličine ekrana
3. Testirati različite Android Chrome verzije

## Pitanja za korisnika

1. **Koja je minimalna promjena height-a** kada se keyboard zatvori u landscape mode-u? (trebamo znati da postavimo pravi threshold)

2. **Da li visualViewport API uopće radi** u landscape mode-u na vašem uređaju? (možda je problem što API ne radi, ne samo threshold)

3. **Koja Android Chrome verzija** koristite za testiranje?

4. **Da li se problem dešava na svim ekranima** ili samo na određenim?

5. **Da li možete dodati console.log** u browser developer tools da vidimo šta se dešava? (viewport.height vrijednosti, heightDiff, itd.)

## Alternativni pristupi (ako gornje ne radi)

1. **Koristiti `window.innerHeight` umjesto `visualViewport.height`** u landscape mode-u
2. **Dodati `window.resize` listener kao fallback** za landscape mode
3. **Koristiti `MediaQuery.viewInsets.bottom`** umjesto visualViewport u landscape mode-u
4. **Kombinovati više metoda** za pouzdaniju detekciju

## Test scenariji

**STATUS: KOD IMPLEMENTIRAN - TESTIRANJE POTREBNO**

Svi ekrani imaju implementiran keyboard fix. Potrebno je ručno testiranje:

### Chrome Android - Portrait
- [ ] Otvori login screen
- [ ] Tap na email input (keyboard se otvara)
- [ ] Zatvori keyboard pomoću BACK button-a
- [ ] Provjeri da li se bijeli prostor uklanja
- [ ] Ponovi za password field

### Chrome Android - Landscape
- [ ] Rotiraj telefon u landscape
- [ ] Tap na input field (keyboard se otvara)
- [ ] Zatvori keyboard pomoću BACK button-a
- [ ] Provjeri da li se bijeli prostor uklanja
- [ ] Provjeri da li se layout ispravno prilagođava

### Desktop/Web
- [ ] Osnovna funkcionalnost forme
- [ ] Tab navigacija između polja

## Očekivani rezultat

- Keyboard dismiss se detektuje u landscape mode-u
- Bijeli prostor se uklanja odmah nakon zatvaranja keyboard-a
- Layout se prilagođava bez lag-a
- Portrait mode i dalje radi kako treba
