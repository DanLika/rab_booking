---
paths:
  - "lib/features/widget/**"
  - "lib/widget_main*.dart"
  - "web/bookbed-overlay.js"
---

# Booking Widget System

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

## Brittle host check pattern

`subdomain_service.dart:51` and `booking_view_screen.dart:107` use:
```dart
if (host == 'view.bookbed.io' || host.startsWith('view.')) { … }
```
The `startsWith('view.')` fallback **does not match `staging.view.bookbed.io`** (starts with `staging.`, not `view.`). It also doesn't match `{client}.view.bookbed.io` if `{client}` is non-empty. Once `EnvironmentConfig.widgetHost` exists (proposed in `audit/04c-hardcoded-urls.md` §4), replace with:
```dart
final widgetHost = EnvironmentConfig.widgetHost;
if (host == widgetHost || host.endsWith('.$widgetHost')) { … }
```

## Hardcoded `view.bookbed.io` / `app.bookbed.io` literals

6 prod-path sites currently bypass `EnvironmentConfig` (full list in `audit/04c-hardcoded-urls.md` §3.1):
- `subdomain_service.dart:51`, `booking_view_screen.dart:107` (host checks)
- `booking_widget_screen.dart:4052-4053` (marketing-domain rewrite)
- `embed_widget_guide_screen.dart:31`, `embed_code_generator_dialog.dart:40` (duplicate `_subdomainBaseDomain` consts)
- `subscription_screen.dart:505,515` (user-facing fallback message)

When fixing, use the proposed `EnvironmentConfig.widgetHost` / `dashboardHost` / `marketingHost` / `isMarketingHost()` getters. iCal UID domain (`@bookbed.io` in `ical_generator.dart` and `icalExport.ts`) MUST stay hardcoded — RFC 5545 stable-identifier requirement; environment-dependent UIDs would cause calendar-client duplicate events on re-sync.
