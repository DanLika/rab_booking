---
paths:
  - "lib/core/services/fcm_service*"
  - "lib/core/widgets/fcm_*"
  - "web/firebase-messaging-sw.js"
  - "functions/src/fcmService.ts"
  - "lib/**/pwa/**"
  - "web/manifest.json"
---

# FCM Push Notifications (Web)

## Komponente

| Fajl | Svrha |
|------|-------|
| `lib/core/services/fcm_service.dart` | Flutter FCM service - token management, permission, message handling |
| `lib/core/widgets/fcm_navigation_handler.dart` | Foreground message UI (snackbar) + navigation on tap |
| `web/firebase-messaging-sw.js` | Service Worker za background notifications |
| `functions/src/fcmService.ts` | Cloud Functions - šalje push notifikacije |

**VAPID Key**: Per-env getter `EnvironmentConfig.vapidKey` (since audit/33 §11.4 / 2026-05-24). PROD slot populated; DEV + STAGING are empty placeholders awaiting operator paste from Firebase Console → Project Settings → Cloud Messaging → Web Push certificates. `FcmService.initialize()` returns early on web when the slot is empty (silent disable) — so DEV/STAGING ship without FCM until the VAPID is filled in. `fcm_service.dart:_vapidKey` is now an instance getter, not a `static const`.

**Service Worker env-switching** (since audit/33 §11.4): `web/firebase-messaging-sw.js` selects its Firebase config from a 3-env map keyed on `self.location.hostname` (DEV ↔ `*-dev.web.app` + `localhost`, STAGING ↔ `staging.*.bookbed.io` + `*-staging.web.app`, PROD ↔ `app.bookbed.io` + `view.bookbed.io` + `*.view.bookbed.io` + `bookbed-admin.web.app`). Default = PROD with a `console.warn`. The hostnames listed there MUST stay in sync with `lib/core/config/environment.dart` (`dashboardHost` / `widgetHost`) and `lib/firebase_options{,_dev,_staging}.dart` web blocks. **Three `nosemgrep` suppressions** mark the public Firebase web `apiKey` values inside the config map (Firebase web apiKey is a public client identifier — see header comment in the file).

## Token Storage

`users/{userId}/data/fcmTokens` (Map format)
```json
{
  "fcmToken123...": {
    "token": "fcmToken123...",
    "platform": "web",
    "createdAt": "Timestamp",
    "lastSeen": "Timestamp"
  }
}
```

## Flow

1. User logs in → `fcmService.initialize()` called from `enhanced_auth_provider.dart`
2. Browser requests notification permission
3. FCM token saved to Firestore
4. Booking created → `atomicBooking.ts` calls `sendPendingBookingPushNotification()`
5. Cloud Function reads tokens, sends via `messaging.sendEachForMulticast()`
6. **Foreground**: `FcmNavigationHandler` shows snackbar with "View" button
7. **Background**: Service Worker shows system notification

## Navigation from SnackBar

```dart
// ⚠️ VAŽNO: SnackBar action koristi drugačiji context - nema GoRouter
// Rješenje: koristi ref.read(ownerRouterProvider).go() umjesto context.go()
final router = ref.read(ownerRouterProvider);
router.go('/owner/bookings?booking=$bookingId');
```

## Kada se šalje push

- `sendPendingBookingPushNotification()` - novi pending booking (widget)
- `sendBookingPushNotification()` - booking confirmed/updated/cancelled
- `sendPaymentPushNotification()` - payment received

---

# PWA (Progressive Web App)

**Konfiguracija**: `web/manifest.json`, `web/index.html` (linije 306-372)

## Widgeti

| Widget | Fajl | Svrha |
|--------|------|-------|
| `PwaInstallButton` | `widgets/pwa/pwa_install_button.dart` | Custom install dugme |
| `ConnectivityBanner` | `widgets/pwa/connectivity_banner.dart` | Offline/online status |

## Dart API (`core/utils/web_utils.dart`)

```dart
canInstallPwa()      // true ako je install prompt dostupan
isPwaInstalled()     // true ako je PWA već instalirana
promptPwaInstall()   // async - pokreće install prompt
listenToPwaInstallability(callback)  // listener za promjene
```

## JavaScript API (`web/index.html`)

```javascript
window.pwaCanInstall    // bool
window.pwaIsInstalled   // bool
window.pwaPromptInstall()  // async function
// Eventi: 'pwa-installable', 'pwa-installed'
```
