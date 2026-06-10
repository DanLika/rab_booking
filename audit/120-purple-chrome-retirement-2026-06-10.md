# 120 — Purple-chrome retirement + Pregled/Rezervacije/Timeline handoff alignment (2026-06-10)

**Scope:** Owner (mobile-first) + Admin + shared/core surfaces.
**Branch:** `feat/marionette-list-row-keys` (carries 665ed3a7 test-hooks commit + this batch).
**Verified:** 2 live smoke passes on bookbed-dev iPhone 17 Pro (iOS 26.1).

## What changed

Two converging passes:

### Pass 1 — `BBGradient.brandPrimary` chrome retirement (~30 files)

Heavy brand-purple slabs on dialog headers, hero banners, button backgrounds, accent strips, FAB, loading spinner circles, info chips, and tab decorations swapped to **theme-aware shell-tone** chrome:
- `Container.decoration.color = Theme.of(context).colorScheme.surface`
- Hairline border via `theme.dividerColor.withValues(alpha: 0.4)`
- Icon tile: `colorScheme.primary.withValues(alpha: 0.10)` + primary glyph
- Title text: `colorScheme.onSurface` (700 weight)
- CTAs: solid `colorScheme.primary` + `onPrimary`

Touched files (alphabetical, abbreviated):
- `core/error_handling/error_boundary.dart` — Try Again CTA
- `core/theme/{app_colors, app_gradients, app_theme}.dart` — token tweaks consumed by below
- `features/admin/presentation/screens/admin_shell_screen.dart` — light surface `#F8F9FA → #F4F5F9`
- `features/owner_dashboard/presentation/screens/calendar/month_calendar_screen.dart`
- `features/owner_dashboard/presentation/screens/dashboard_overview_tab.dart` — `_ActionStepCard` refactor (dropped `gradient` param) + KPI tile 1 swap (see Pass 2)
- `features/owner_dashboard/presentation/screens/guides/{embed_help, embed_widget_guide, ai_assistant}_screen.dart`
- `features/owner_dashboard/presentation/screens/ical/{ical_export_list, ical_sync_settings}_screen.dart`
- `features/owner_dashboard/presentation/screens/{owner_bookings, owner_timeline_calendar}_screen.dart`
- `features/owner_dashboard/presentation/screens/{profile, property_form, stripe_connect_setup, unified_unit_hub, unit_form, unit_wizard/unit_wizard, widget_advanced_settings, widget_settings}_screen.dart`
- `features/owner_dashboard/presentation/widgets/advanced_settings/{email_verification, tax_legal_disclaimer}_card.dart` — 40×2 title accent strips → solid primary
- `features/owner_dashboard/presentation/widgets/booking_actions/base_booking_dialog.dart` — default branch theme-aware; status-action variants (reject red, etc.) preserved
- `features/owner_dashboard/presentation/widgets/calendar/{booking_action_menu, booking_inline_edit_dialog, booking_status_change_dialog, calendar_filters_panel, calendar_search_dialog, unit_future_bookings_dialog}.dart`
- `features/owner_dashboard/presentation/widgets/{booking_create_dialog, booking_details_dialog, booking_details_dialog_v2, edit_booking_dialog, owner_app_drawer, price_list_calendar_widget, send_email_dialog}.dart` + bookings/{bookings_filters_dialog, bookings_premium_header}.dart + units/unit_hub_empty_state.dart
- `shared/widgets/custom_date_range_picker.dart` — modal header + Apply CTA

Color coherence: `0xFFF8F9FA → 0xFFF4F5F9` for light-theme inner-card fills in `ai_assistant_screen`, `month_calendar_screen`, `embed_widget_guide_screen`, `admin_shell_screen` (per user's global preference for a cooler gray that pairs with brand purple).

### Pass 2 — Handoff design-fidelity additions (owner-mobile)

Live side-by-side comparison of each handoff screen against the running app on bookbed-dev. Concrete deltas found and closed:

- **Pregled (`owner-01-pregled.png`)** — AI insight banner missing `Odbaci` / `Primjeni` action CTAs → added at banner bottom-right (verified live). KPI tile 1 swapped from ZARADA (duplicate of hero) → **PROSJEČNA CIJENA NOĆENJA** (derived `revenue / bookings`, `—` when bookings=0, `savings` icon). Reuses `ownerAnalyticsAvgNightlyRate` l10n key.
- **Rezervacije (`02-owner.png`)** — AI insight banner missing `Kasnije` / `Odgovori` action CTAs → added (verified live).
- **Timeline kalendar (`03-owner.png`)** — Missing KPI strip (POPUNJENOST/REZERVACIJE/DOLASCI/SLOBODNE NOĆI) above grid → reused `MonthCalendarKpiStrip` self-contained widget, inserted inside `if (hasUnits)` gate (verified live). Missing status legend row → new `_TimelineStatusLegend` widget (Wrap of `Container(circle, color: BookingStatus.X.color)` + label, reads `BookingStatus.color` extension from `core/constants/enums.dart`).
- **Booking detail (`07-owner.png`)** — pending status banner: full-page `owner_booking_detail_screen.dart` **already** renders it (hardcoded string at line 428). My addition to legacy `booking_details_dialog.dart` lands in dead-code path; harmless. New l10n key `ownerDetailsAwaitingApproval` added (HR + EN) for future migration of the hardcoded string.

## Pages with no fidelity work needed

Live verification confirmed pre-existing alignment:
- 04 Mjesečni kalendar — KPI + legend already present
- 05 Profil — sections + Pro card + STOPA/VRIJEME ODGOVORA already implemented
- 06 Smještajne Jedinice — Cijena card already on Osnovno tab
- 07 Booking detail — full-page screen already at design fidelity
- 08 Subscription — `lib/features/subscription/screens/subscription_screen.dart` already implements VAŠ PLAN / Probni period / Mjesečno-Godišnje
- 09 Isplate — `_StripePayoutsDashboard` (in `stripe_connect_setup_screen.dart`) gated on `bool.fromEnvironment('STRIPE_PAYOUTS') || kDebugMode`
- 10 iCal feedovi — handled by `ical_sync_settings_screen.dart`
- 11 AI Asistent — chat screen already implemented
- 12 Obavještenja — inline Odobri/Odbij shipped via PR #676 (per audit/114)

## Remaining true gaps (not chrome, feature builds)

| Page | Gap | Why deferred |
|---|---|---|
| Pregled | NOVI GOSTI tile, PROSJEČNA OCJENA tile | requires distinct-guests counter + reviews data on `UnifiedDashboardData` |
| Pregled | NAPLAĆENI DEPOZITI card | requires deposit aggregation provider |
| Pregled | "Nadolazeći dolasci" list section | requires upcoming-arrivals UI + provider |
| Pregled | "Zarada po kanalu" donut data | `_PregledChannelMix` exists kDebug-gated; needs source-breakdown column on dashboard data |
| Pregled | header "Nova rezervacija" CTA | mobile UX choice — Timeline FAB serves this role |

These are product-scope, not chrome alignment. The chrome class is genuinely converged.

## Verification

`flutter analyze lib/` → 91 issues, **all pre-existing** (BBRadius.medium deprecation infos + 1 `about_screen` redundant-arg info). Zero new errors or warnings introduced by this batch.

Live screenshots captured during 2 smoke passes:
- Pass 1: `/tmp/bb-premium-baseline/calendar-search-after.png` (date dialog), drawer banner clean shell, Timeline FAB solid primary, Booking action sheet with primary-tint info chips, iCal Export hero clean shell, Unit Hub `_buildInfoCard` accent strip solid primary, Mod Widgeta + Verifikacija emaila + Porezna i pravna izjava accent strips.
- Pass 2: Pregled AI banner with Odbaci/Primjeni inline, Rezervacije AI banner with Kasnije/Odgovori inline, Timeline kalendar with KPI strip + (post-edit) Status legend, booking detail full-page screen with "Ova rezervacija čeka vaše odobrenje" status banner, Mjesečni kalendar with theme-aware KPI tiles.

## Sibling references

- [[redesign-phase1-foundation]] (audit/103) — Bb* primitives, BbScaffold
- [[redesign-phase17-admin-dark-foundation]] (audit/103 §Amendment) — admin shell deep-purple
- [[114-owner-mobile-design-qa]] — design QA before this sweep; F1/F2/F4b closures
- [[design-tokens-bb]] — BB* token namespace; off-scale TODOs kept

## File diff summary

46 source files modified (net **−78 lines** — code got cleaner by deleting gradient param-passing chains and unused imports). 4 l10n files touched (HR + EN ARB + 2 generated dart bundles).
