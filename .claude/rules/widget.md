---
paths:
  - "lib/features/widget/**"
  - "lib/widget_main*.dart"
  - "web/bookbed-overlay.js"
---

# Booking Widget System

## ⚠ App Check — NAMJERNO ISKLJUČEN na widgetu (NE re-enable bez Option B)

`widget_main.dart` / `widget_main_dev.dart` / `widget_main_staging.dart` **NE pozivaju `AppCheckInit.activate`** — App Check je namjerno OFF na widgetu.

**Zašto (eternal-shimmer P0, 2026-06-14/15):** `AppCheckInit.activate` → `ReCaptchaV3Provider` učitava `https://www.google.com/recaptcha/api.js`, koji je **CSP-blokiran** na widget surfaceu (`firebase.json` nema `www.google.com` u `script-src`). Token se nikad ne iskuje → Firebase SDK drži SVE Firestore listene I callable pozive čekajući token → **0 requestova → 10s timeout → offline → vječni skeleton**. App Check je `enforceAppCheck:false` svuda gdje widget zalazi (+ Firestore/Storage App Check off u konzoli), pa je na javnom no-auth widgetu bio čista šteta.

**Dokaz:** kontrolisani A/B (čist modular SDK, isti browser): bez App Check `onSnapshot` 459ms/1 doc; s App Check (placeholder reCAPTCHA, CSP-blok) 10s offline/0 doc. PROD-verifikovano na jaskovim unitima (render + `Listen` 200 + `getUnitAvailability` 200, console 0).

**NE re-enable App Check na widgetu bez SVE TRI stavke ZAJEDNO (Option B):**
1. `https://www.google.com` u widget (i owner/admin) `script-src` u `firebase.json`,
2. pravi `--dart-define=APP_CHECK_RECAPTCHA_KEY=<key>` (trenutno `placeholder-debug-only` = nula zaštite),
3. `enforceAppCheck:true` na widget callable-ima.

Inače se vraća shimmer. `forceLongPolling` Settings linija u istim entry-jima je **embed-reliability hardening, NIJE App Check fix** — ne brkati. Puni detalji: `memory/frozen-calendar-optimized-stream-permission-denied.md`.

## Subdomain & URL Slug System

**URL formati** (widget na `view.bookbed.io`):

| Format | Primjer | Korištenje |
|--------|---------|------------|
| Query params | `jasko-rab.view.bookbed.io/?property=XXX&unit=YYY` | iframe embed |
| Clean slug | `jasko-rab.view.bookbed.io/apartman-6` | standalone, dijeljenje |

**Rezolucija slug URL-a**:
1. Subdomain (`jasko-rab`) → `fetchPropertyBySubdomain()` → property
2. Path slug (`apartman-6`) → `fetchUnitBySlug(propertyId, slug)` → unit

**Ključni fajlovi**:
- `subdomain_service.dart` → `resolveFullContext(urlSlug)`
- `subdomain_provider.dart` → `fullSlugContextProvider(slug)`
- `router_widget.dart` → `/:slug` route

**Slug stabilnost**: Slug se NE regenerira automatski kad se promijeni naziv unita (`_isManualSlugEdit` flag u `unit_form_screen.dart`).

**Booking view URL**: `villa-marija.view.bookbed.io/view?ref=XXX&email=YYY`

**⚠️ VAŽNO**: Svi widget URL-ovi koriste `view.bookbed.io` domenu, NE `bookbed.io`!

## Snackbars

`SnackBarHelper` u `shared/utils/ui/snackbar_helper.dart`
- Boje prate calendar status: Success=Available(zelena), Error=Booked(crvena), Warning=Pending(amber), Info=plava
- Light: `#10B981`, `#EF4444`, `#F59E0B`, `#3B82F6`
- Dark: `#34D399`, `#F87171`, `#FBBF24`, `#60A5FA`
- Auto-hide prethodnog, centrirani tekst, sve poruke koriste `WidgetTranslations`

## Iframe Scroll Overlay

`web/bookbed-overlay.js` — v8 Google Maps cooperative pattern:
- Overlay as **sibling** of iframe (no wrapping, no reload)
- `position:absolute` inside iframe's parent
- `pointer-events: auto/none` toggle (click to interact, mouseleave to restore)
- Mobile: script exits immediately (touch doesn't trap scroll)
- **CRITICAL deploy**: `cp web/bookbed-overlay.js build/web_widget/` before `firebase deploy --only hosting:widget`

## Silent debug guards in `booking_widget_screen.dart`

The file has **18** `} catch (_) {}` blocks, each preceded by `// Silent guard — debug telemetry must not break main flow`. They wrap ONLY `LoggingService.log` + `jsonEncode` calls inside `// #region` / `// #endregion` debug-instrumentation blocks.

**DO NOT replace these with `logError`** — they exist so a non-serializable debug payload (a `Set`, a circular ref, etc.) can't throw past the catch and break the payment flow. Adding logging inside would fire Sentry on every unserializable debug field — pure noise, zero actionable signal.

The 2 catches in `booking_confirmation_screen.dart` (around lines 171, 192) ARE different — they wrap `tabService.dispose()` in `Future.delayed` fallback paths. Those CAN be safely logged via `LoggingService.logWarning` (debug-mode only, no Sentry noise).

## Host comparisons — use `EnvironmentConfig`, never literals

All `view.bookbed.io` / `app.bookbed.io` / `bookbed.io` host literals were centralized in T13 (T13, commit `b0bad83c`). New widget code MUST use:

```dart
import '../../../core/config/environment.dart';

// Exact bare widget host (skip subdomain parsing on view.bookbed.io itself)
if (host == EnvironmentConfig.widgetHost) { … }

// Widget host OR any client subdomain (e.g. jasko-rab.view.bookbed.io)
if (EnvironmentConfig.isWidgetHost(host)) { … }

// Bare marketing domain — rewrite onto widget host
if (EnvironmentConfig.isMarketingHost(host)) {
  host = EnvironmentConfig.widgetHost;
}
```

Per-env values:
- **prod** widget/dashboard: `view.bookbed.io` / `app.bookbed.io`
- **staging**: `staging.view.bookbed.io` / `staging.app.bookbed.io`
- **dev**: `bookbed-widget-dev.web.app` / `bookbed-owner-dev.web.app` — real Firebase Hosting sites (no more `localhost:5000`)
- **marketing** (`bookbed.io`): all envs share prod — no dev/staging hosting target exists

### Hardcoded `bookbed.io` exceptions

These MUST stay literal:
- **iCal UID domain** (`ical_generator.dart`, `functions/src/icalExport.ts`) — RFC 5545 stable-identifier namespace. Env-dependent UIDs cause calendar-client duplicate events on re-sync.
- **Embed-snippet copy** (`embed_help_screen.dart`, `embed_widget_guide_screen.dart:679/694/757/760/1140`, `faq_screen.dart`) — HTML for owners to copy/paste into their own websites. MUST reference prod widget URL; staging/dev render shouldn't emit a broken link.
