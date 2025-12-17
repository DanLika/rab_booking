# 🧪 PWA Testiranje - Developer Guide

**Status:** ✅ IMPLEMENTIRANO (bez Web Push Notifications)
**Zadnje ažurirano:** 2025-12-16

---

## ✅ Šta je konfigurisano

1. **manifest.json** - PWA manifest sa svim potrebnim ikonama i konfiguracijom
2. **Service Worker** - Flutter automatski generiše i registruje `flutter_service_worker.js`
3. **Install Prompt** - Browser će automatski prikazati install prompt kada su kriteriji ispunjeni
4. **Custom Install Button** - Flutter widget za instalaciju PWA (`PwaInstallButton`)
5. **Offline Detection UI** - Flutter widget za prikaz offline statusa (`ConnectivityBanner`)

## 🚀 Kako testirati PWA

### 1. Build aplikacije

```bash
# Build za production
flutter build web --release

# Ili za development
flutter run -d chrome --web-port 8080
```

### 2. Testiranje na localhost

**VAŽNO:** PWA funkcionalnosti rade samo preko HTTPS ili localhost!

```bash
# Pokreni lokalni server (HTTPS nije potreban za localhost)
cd build/web
python3 -m http.server 8000
# ili
npx serve -s .
```

Otvori u browseru: `http://localhost:8000`

### 3. Provjeri PWA kriterije

Otvoriti **Chrome DevTools** (F12) → **Application** tab:

#### Manifest
- ✅ Provjeri da se manifest.json učitava bez grešaka
- ✅ Provjeri da su sve ikone dostupne
- ✅ Provjeri da su svi required fields popunjeni

#### Service Workers
- ✅ Provjeri da je `flutter_service_worker.js` registrovan
- ✅ Provjeri da je status "activated and is running"
- ✅ Provjeri da su resursi cache-ovani

#### Storage
- ✅ Provjeri Cache Storage → `flutter-app-cache`
- ✅ Provjeri da su Flutter assets cache-ovani

### 4. Testiranje instalacije

#### Android (Chrome)
1. Otvori aplikaciju u Chrome browseru
2. Provjeri da se pojavljuje install banner ili menu opcija "Install app"
3. Klikni "Install" i provjeri da se aplikacija instalira
4. Provjeri da aplikacija ima ikonu na home screen-u
5. Provjeri da se aplikacija otvara u standalone modu (bez browser UI-a)

#### iOS (Safari)
1. Otvori aplikaciju u Safari browseru (ne Chrome!)
2. Klikni Share (⬆️) → "Add to Home Screen"
3. Provjeri da se aplikacija dodaje na home screen
4. Provjeri da se aplikacija otvara u standalone modu

#### Desktop (Chrome/Edge)
1. Otvori aplikaciju u Chrome ili Edge browseru
2. Provjeri da se pojavljuje install ikona (➕) u address bar-u
3. Klikni install i provjeri da se aplikacija instalira
4. Provjeri da se aplikacija otvara u zasebnom prozoru

### 5. Testiranje offline funkcionalnosti

1. Instaliraj aplikaciju
2. Otvori aplikaciju
3. Uključi **Airplane Mode** ili isključi internet
4. Provjeri da aplikacija još uvijek radi (cache-ovani sadržaj)
5. Provjeri da se prikazuje offline poruka ako je potrebno

### 6. Testiranje update mehanizma

1. Instaliraj aplikaciju
2. Napravi promjene u kodu
3. Rebuild aplikaciju: `flutter build web --release`
4. Redeploy aplikaciju
5. Otvori instaliranu aplikaciju
6. Provjeri da se nova verzija automatski preuzima
7. Provjeri da se aplikacija ažurira bez problema

## 🔍 Chrome DevTools - PWA Audit

1. Otvori Chrome DevTools (F12)
2. Idi na **Lighthouse** tab
3. Izaberi **Progressive Web App** kategoriju
4. Klikni **Generate report**
5. Provjeri da svi PWA kriteriji prolaze:
   - ✅ Manifest
   - ✅ Service Worker
   - ✅ HTTPS
   - ✅ Responsive design
   - ✅ Fast load time
   - ✅ Offline support

## 🐛 Česti problemi

### Service Worker se ne registruje
- **Problem:** Service worker se ne registruje
- **Rješenje:** Provjeri da li aplikacija radi preko HTTPS ili localhost (ne HTTP na production)

### Install prompt se ne pojavljuje
- **Problem:** Browser ne prikazuje install prompt
- **Rješenje:** 
  - Provjeri da li su svi PWA kriteriji ispunjeni (Lighthouse audit)
  - Provjeri da li je aplikacija već instalirana
  - Provjeri da li koristiš HTTPS ili localhost

### Aplikacija se ne instalira na iOS
- **Problem:** Ne mogu instalirati na iPhone
- **Rješenje:** 
  - Koristi Safari browser (ne Chrome)
  - Provjeri da li koristiš HTTPS (ne HTTP)
  - Provjeri da li manifest.json ima sve potrebne ikone

### Offline funkcionalnost ne radi
- **Problem:** Aplikacija ne radi offline
- **Rješenje:**
  - Provjeri da li je service worker aktivan
  - Provjeri da li su resursi cache-ovani (DevTools → Application → Cache Storage)
  - Provjeri da li Flutter service worker radi kako treba

## 📊 PWA Checklist

- [ ] Manifest.json je validan i učitava se bez grešaka
- [ ] Sve ikone (192x192, 512x512, maskable) postoje i učitavaju se
- [ ] Service worker je registrovan i aktivan
- [ ] Aplikacija se može instalirati na Android (Chrome)
- [ ] Aplikacija se može instalirati na iOS (Safari)
- [ ] Aplikacija se može instalirati na Desktop (Chrome/Edge)
- [ ] Aplikacija radi offline (osnovne funkcionalnosti)
- [ ] Aplikacija se automatski ažurira kada postoji nova verzija
- [ ] Lighthouse PWA audit prolazi sve testove
- [ ] Google Sign-In radi u instaliranoj aplikaciji
- [ ] Apple Sign-In radi u instaliranoj aplikaciji (iOS)

## 🚀 Deployment

Nakon što je sve testirano i radi:

1. Build aplikaciju: `flutter build web --release`
2. Deploy na Firebase/Netlify/ili drugi hosting
3. Provjeri da aplikacija radi preko HTTPS
4. Testiraj instalaciju na stvarnim uređajima
5. Obavijesti korisnike da mogu instalirati aplikaciju

## 📝 Napomene

- Flutter automatski generiše `flutter_service_worker.js` pri build-u
- Service worker se automatski registruje kroz `flutter_bootstrap.js`
- Ne trebaš ručno registrovati service worker - Flutter to radi automatski
- Manifest.json mora biti dostupan na root URL-u (`/manifest.json`)

---

## 🧩 Flutter PWA Widgets

### PwaInstallButton

**Fajl:** `lib/features/widget/presentation/widgets/pwa/pwa_install_button.dart`

Custom install button koji se prikazuje samo kada:
- Radi na web platformi (`kIsWeb`)
- PWA nije već instalirana
- Browser podržava instalaciju (`beforeinstallprompt` event)

**Automatski se skriva** kada:
- Ne radi na webu (mobile apps)
- PWA je već instalirana (standalone mode)
- Browser ne podržava PWA instalaciju

```dart
import 'package:bookbed/features/widget/presentation/widgets/pwa/pwa_install_button.dart';

// Full button sa tekstom "Instaliraj"
PwaInstallButton(
  isDarkMode: isDarkMode,
  compact: false,
)

// Compact button - samo ikona (za male ekrane)
PwaInstallButton(
  isDarkMode: isDarkMode,
  compact: true,
)
```

**Lokalizacija:** HR, EN, DE, IT (via `WidgetTranslations.installApp`)

### ConnectivityBanner

**Fajl:** `lib/features/widget/presentation/widgets/pwa/connectivity_banner.dart`

Banner koji automatski prikazuje offline/online status:
- 🔴 **Crveni banner** kada nema interneta: "Nema internet konekcije"
- 🟢 **Zeleni banner** kada se vrati: "Ponovo online" (auto-hide nakon 3s)
- Smooth slide animacija od vrha ekrana
- Koristi `connectivity_plus` package za detekciju

```dart
import 'package:bookbed/features/widget/presentation/widgets/pwa/connectivity_banner.dart';

// Wrap glavni content
ConnectivityBanner(
  isDarkMode: isDarkMode,
  child: Scaffold(
    // ... vaš content
  ),
)
```

**Lokalizacija:** HR, EN, DE, IT (via `WidgetTranslations.offlineMode`, `backOnline`)

---

## 🔧 Dart API (web_utils)

**Fajlovi:**
- `lib/core/utils/web_utils.dart` - barrel export
- `lib/core/utils/web_utils_web.dart` - web implementacija
- `lib/core/utils/web_utils_stub.dart` - stub za non-web platforme

```dart
import 'package:bookbed/core/utils/web_utils.dart';

// Provjeri da li se može instalirati
bool canInstall = canInstallPwa();

// Provjeri da li je već instalirana
bool isInstalled = isPwaInstalled();

// Pokreni install prompt (async)
bool accepted = await promptPwaInstall();

// Slušaj promjene installability-a
final cleanup = listenToPwaInstallability((canInstall) {
  print('Can install: $canInstall');
});
// cleanup() za uklanjanje listener-a
```

---

## 🌐 JavaScript API (index.html)

**Fajl:** `web/index.html` (linije 306-372)

```javascript
// Stanje PWA
window.pwaCanInstall    // bool - da li je install prompt dostupan
window.pwaIsInstalled   // bool - da li je PWA već instalirana

// Pokreni install prompt
const accepted = await window.pwaPromptInstall(); // true ako je korisnik prihvatio

// Eventi
window.addEventListener('pwa-installable', (e) => {
  // Install prompt je postao dostupan
});

window.addEventListener('pwa-installed', () => {
  // PWA je uspješno instalirana
});
```

---

## 📁 Struktura fajlova

```
lib/
├── core/utils/
│   ├── web_utils.dart           # Barrel export (conditional import)
│   ├── web_utils_web.dart       # Web implementacija (JS interop)
│   └── web_utils_stub.dart      # Stub za mobile/desktop
│
└── features/widget/presentation/
    ├── widgets/pwa/
    │   ├── pwa_install_button.dart    # Install dugme widget
    │   └── connectivity_banner.dart   # Offline banner widget
    │
    └── l10n/widget_translations.dart  # Translations (installApp, offlineMode, backOnline)

web/
├── index.html          # PWA JavaScript API (linije 306-372)
└── manifest.json       # PWA manifest
```

---

## 🔮 TODO: Web Push Notifications

**Status:** ❌ NIJE IMPLEMENTIRANO (Future Work)

Web Push notifications su planirane za budućnost. Napomene:
- Safari podržava Web Push tek od iOS 16.4+ (2023)
- Korisnik MORA prvo instalirati PWA na iOS
- Zahtijeva VAPID ključeve i FCM web konfiguraciju
- Trenutno disablovano u `fcm_service.dart`

**Preporučeni koraci za implementaciju:**
1. Generisati VAPID ključeve
2. Konfigurirati FCM za web push
3. Implementirati permission request UI
4. Dodati service worker handling za push notifikacije
5. Testirati na Chrome, Firefox, Safari (iOS 16.4+)

---

## 📊 PWA Status Tabela

| Funkcionalnost | Status | Napomena |
|----------------|--------|----------|
| manifest.json | ✅ DONE | Sve ikone i konfiguracija |
| Service Worker | ✅ DONE | Flutter automatski generiše |
| Install Prompt | ✅ DONE | Browser native + custom button |
| PwaInstallButton widget | ✅ DONE | Custom install dugme |
| ConnectivityBanner widget | ✅ DONE | Offline/online status |
| Offline Support | ✅ DONE | Cache-ovani resursi |
| Web Push Notifications | ❌ TODO | Zahtijeva VAPID ključeve |

---

## Changelog

### 2025-12-16
- Verificiran status PWA implementacije
- Dodana status tabela

