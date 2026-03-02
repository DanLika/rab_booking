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
