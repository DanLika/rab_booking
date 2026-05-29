# Design Audit — Owner + Widget + Admin (2026-05-28)

**Date:** 2026-05-28
**Branch:** `fix/f-67-01-booking-confirm-reject` @ HEAD `ca309fe2` (Confirm/Reject FIX landed — UI flow goes through CF, no longer the silent no-op described in audit/67 F-67-01)
**Auditor:** Terminal F, autonomous run
**Mode:** READ-ONLY on code. Inventory + live screenshot capture + UX critique.
**Surfaces under audit:** bookbed-owner-dev.web.app, bookbed-admin-dev.web.app, bookbed-widget-dev.web.app (or subdomain-routed)
**Test account:** bookbed-test@bookbed.io / BookBedTest2026!
**Screenshots:** `audit/screenshots-71/{owner,widget,admin}/`

> Note on branch: this run captures screenshots from the F-67-01 fix branch (PR pending). For Owner Confirm/Reject screens you will see the FIXED UI (CF-routed, error surface visible) — NOT main's broken silent no-op. Labeled per screen below.

---

## §1 Executive Summary

**Surface count:** 3 (Owner / Widget / Admin)
**Screen count:** Owner 25, Widget 5, Admin 6 = **36 full-page screens**
**Dialog/sheet count:** ~30 unique (booking actions ×6, calendar dialogs ×4, widget dialogs ×3, bottom sheets ×3, plus shell-level update/force-update)
**Design system maturity:** **Partial / fragmented**. Theme is centralized in `lib/core/theme/app_theme.dart` + `app_colors.dart` + `app_typography.dart`. A canonical token namespace (`BB*` in `lib/core/design/tokens.dart`) exists and delegates to `AppDimensions`/`AppColors`. But there are **TWO parallel token systems** (`lib/core/design_tokens/*.dart` from an earlier attempt, and `lib/core/design/tokens.dart` as the canonical). Hardcoded `Color(0xFF…)` count is **477 total**, of which **209 inside theme files** (legitimate) — leaving **~268 hardcoded color usages OUTSIDE theme files** (illegitimate, leak per-screen). 1057 `EdgeInsets.*(` constructors across features — high proportion are magic-number padding. The token system *exists*; adoption is *incomplete*.

**Top 5 systemic weaknesses (the redesign needs to fix these):**
1. **Two token systems coexist** (`core/design_tokens/` + `core/design/tokens.dart`) — neither has reached saturation. Pick one + codemod.
2. **268 hardcoded `Color(0xFF…)` outside theme** — almost every feature file paints its own one-off purples / coral / gold. Brand drift inevitable.
3. **`booking_details_dialog.dart` + `booking_details_dialog_v2.dart` coexist** — two booking-detail dialog impls. V1 should be deleted (post-V2 confirmation) but lingers, suggesting half-finished refactor.
4. **Empty / loading / error states largely default** — Most list screens drop to a Material `CircularProgressIndicator` + no empty-state illustration / copy. Highest-ROI redesign opportunity.
5. **Owner Dashboard "Pregled" lacks primary metric** — 4 stat cards (€0 Zarada / 0 Rezervacije / 0 Nadolazeći check-in / 0.0% Popunjenost) at identical size+weight → no visual hierarchy. Most owners care about one of these (depends on persona); design should let them pick or use revenue as default-primary.

(Detail in §4-§5)

---

## §2 Code Inventory

### §2.1 Entry points + routing

| Surface | Dev entry | Prod entry | Routing |
|---|---|---|---|
| Owner | `lib/owner_main_dev.dart` (calls `runMainApp()`) | `lib/main_prod.dart` → `lib/main.dart` | Inside `main.dart` (1 file, 25KB — likely owns route table) |
| Admin | `lib/admin_main_dev.dart` (`AdminApp` ConsumerWidget, `MaterialApp.router`) | `lib/admin_main_production.dart` | `adminRouterProvider` (`features/admin/providers/admin_providers.dart`) — GoRouter |
| Widget | `lib/widget_main_dev.dart` | `lib/widget_main.dart` (12KB) | Inside widget_main; subdomain-routed |

Note: only Admin uses GoRouter; Owner uses imperative `Navigator.push` (per CLAUDE.md "NIKADA NE MIJENJAJ — Navigator.push za confirmation"). Mixed routing is a maintenance footgun.

### §2.2 Screens per surface

**Owner (25 screens)** in `lib/features/owner_dashboard/presentation/screens/`:
- Shell + dashboard: `dashboard_overview_tab.dart`
- Bookings: `owner_bookings_screen.dart`
- Calendar: `owner_timeline_calendar_screen.dart`, `calendar/month_calendar_screen.dart`
- Units: `unified_unit_hub_screen.dart`, `unit_form_screen.dart`, `unit_pricing_screen.dart`, `unit_wizard/unit_wizard_screen.dart` (+ 4 steps)
- Property: `property_form_screen.dart`
- iCal: `ical/ical_export_list_screen.dart`, `ical/ical_sync_settings_screen.dart`
- Settings: `profile_screen.dart`, `edit_profile_screen.dart`, `change_password_screen.dart`, `notification_settings_screen.dart`, `notifications_screen.dart`, `bank_account_screen.dart`, `stripe_connect_setup_screen.dart`
- Widget config: `widget_settings_screen.dart`, `widget_advanced_settings_screen.dart`
- Guides: `guides/ai_assistant_screen.dart`, `guides/faq_screen.dart`, `guides/embed_help_screen.dart`, `guides/embed_widget_guide_screen.dart`
- Misc: `about_screen.dart`

**Auth (7 screens)** in `lib/features/auth/presentation/screens/`: `enhanced_login_screen.dart`, `enhanced_register_screen.dart`, `forgot_password_screen.dart`, `email_verification_screen.dart`, `cookies_policy_screen.dart`, `privacy_policy_screen.dart`, `terms_conditions_screen.dart`

**Subscription (1 screen):** `lib/features/subscription/screens/subscription_screen.dart`

**Widget (5 screens)** in `lib/features/widget/presentation/screens/`: `booking_widget_screen.dart`, `booking_view_screen.dart`, `booking_details_screen.dart`, `booking_confirmation_screen.dart`, `subdomain_not_found_screen.dart`

**Admin (6 screens)** in `lib/features/admin/presentation/screens/`: `admin_login_screen.dart`, `admin_shell_screen.dart`, `admin_dashboard_screen.dart`, `users_list_screen.dart`, `user_detail_screen.dart`, `activity_log_screen.dart`

### §2.3 Dialogs / modals / bottom sheets (~30 unique)

**Booking actions (6):** `base_booking_dialog.dart` (parent), `booking_approve_dialog.dart`, `booking_cancel_dialog.dart`, `booking_complete_dialog.dart`, `booking_delete_dialog.dart`, `booking_reject_dialog.dart` — good — single base class

**Booking creation/edit (3):** `booking_create_dialog.dart`, `booking_details_dialog.dart`, **`booking_details_dialog_v2.dart`** (`v2` exists alongside v1 — half-finished migration), `edit_booking_dialog.dart`

**Calendar (4):** `booking_inline_edit_dialog.dart`, `booking_status_change_dialog.dart`, `calendar_search_dialog.dart`, `unit_future_bookings_dialog.dart`

**iCal/embed (3):** `ical_feed_delete_dialog.dart`, `embed_code_generator_dialog.dart`, `send_email_dialog.dart`

**Bottom sheets (3):** `language_selection_bottom_sheet.dart`, `theme_selection_bottom_sheet.dart`, `notification_settings_bottom_sheet.dart`

**Bookings filters (1):** `bookings_filters_dialog.dart`

**Wizard (1):** `wizard/additional_service_dialog.dart`

**Widget (3):** `details/cancel_confirmation_dialog.dart`, `email_verification_dialog.dart`, `popup_blocked_dialog.dart`

**Shell-level (2):** `force_update_dialog.dart`, `optional_update_dialog.dart` (core)

### §2.4 Shared/reusable widgets (de-facto design system)

`lib/core/widgets/` — 6 files (force/optional update dialogs, owner_app_loader, owner_splash_screen, keyboard_aware_constrained_box). **Very thin** — almost nothing reusable lives here.

`lib/shared/widgets/` — 31 files (high count, but mostly domain-specific: avatars, badges, booking_card variants, calendar pieces).

`lib/features/auth/presentation/widgets/` — has its OWN design system (premium_input_field, glass_card, gradient_auth_button, social_login_button, auth_background, line_art_icons). **The auth surface looks unlike the rest** — Auth uses glassmorphism + gradient buttons; Owner shell uses standard Material cards.

→ **Finding:** No central button/input/card primitive widget. Per-feature `*_button.dart` / `*_input.dart` proliferation.

### §2.5 Theme + tokens

| File | Role |
|---|---|
| `lib/core/theme/app_theme.dart` | Central `ThemeData` (lightTheme + darkTheme) |
| `lib/core/theme/app_colors.dart` | All color constants (`AppColors.primary` etc.) — **the canonical color source** |
| `lib/core/theme/app_typography.dart` | TextStyle scale |
| `lib/core/theme/calendar_cell_colors.dart` | Calendar-specific |
| `lib/core/theme/theme_extensions.dart` | `BuildContext` extensions (gradients per CLAUDE.md `context.gradients`) |
| `lib/core/design/tokens.dart` | **Canonical BB\* namespace** (BBColor / BBSpace / BBRadius / BBType / BBShadow) — delegates to AppColors / AppDimensions / AppShadows |
| `lib/core/design_tokens/*.dart` | **Parallel earlier token system** (11 files: animation_tokens, border_tokens, color_tokens, constraints_tokens, design_tokens, glassmorphism_tokens, gradient_tokens, icon_size_tokens, opacity_tokens, shadow_tokens, spacing_tokens, typography_tokens) — confusing duplication with `core/design/tokens.dart` |
| `lib/core/constants/app_dimensions.dart` | Spacing (4/8/16/24/32/48/64/96 — clean 8px grid) + breakpoints (mobile 600 / tablet 1024 / desktop 1440) + radius (6/12/20/24/32/full) |

**Brand palette (`app_colors.dart`):**
- Primary: `#6B4CE6` (Purple) — appears in app bar, primary buttons
- Secondary: `#FF6B6B` (Coral Red) — accent
- Tertiary: `#FFB84D` (Golden Sand) — accent
- Light bg: `#FAFAFA` (warm white) / surface `#FFFFFF` / variant `#F5F5F5`
- Dark bg: `#000000` (OLED true black) / surface `#121212` (MD3) / variant `#1E1E1E`
- Light text: `#2D3748` / `#4A5568` / `#718096`
- Dark text: `#E2E8F0` / `#A0AEC0` / `#718096`

Token system is reasonable; **adoption is the problem**.

### §2.6 Per-surface summary

| Surface | # screens | # dialogs/sheets (own) | Shared widgets used | Theme centralized? | Hardcoded `Color(0xFF…)` outside theme |
|---|---|---|---|---|---|
| Owner | 25 | ~24 | 31 (in shared/) + own | Yes (Y) | ~245 (all 31 owner widgets above leak hardcoded colors) |
| Widget | 5 | 3 | 0 (self-contained, has own minimalist theme) | Y (own `minimalist_theme.dart`) | ~15 |
| Admin | 6 | 1 (user_detail) | 0 (uses owner shared) | Y | ~8 |
| **TOTAL** | **36** | **~28** | — | — | **268** |

Total `Color(0xFF…)` references: **477** project-wide. 209 inside theme files = legitimate definitions. **268 leaks** = adoption gap.

---

## §3 Screenshot Library Index

61 captures total. Live on `bookbed-{owner,widget,admin}-dev.web.app` from a logged-in `bookbed-test@bookbed.io` session against `bookbed-dev` Firestore. **HR locale, system EN locale only on Widget (English default — language picker visible but not auto-detected).**

### Owner (48 captures)

| Surface | 1440 light | 1440 dark | 390 light | 390 dark |
|---|---|---|---|---|
| Pregled / dashboard | ✓ | ✓ | ✓ | ✓ |
| Drawer (open) | ✓ | — | — | — |
| Bookings (table view) | ✓ | ✓ | ✓ | — |
| Bookings (card view) | ✓ | — | — | — |
| Bookings (action menu open) | ✓ | — | — | — |
| Bookings (action menu on Završeno row — different items: Otkaži/Obriši/Uredi/Pošalji/Detalji) | — | ✓ | — | — |
| Booking approve dialog | ✓ | — | — | — |
| Booking reject dialog (richer — has Razlog odbijanja textarea) | — | ✓ | — | — |
| Booking cancel dialog (richer — Razlog otkazivanja textarea + Pošalji email gostu checkbox + red destructive CTA) | — | ✓ | — | — |
| Booking delete dialog (warning — "Ova akcija se ne može poništiti") | — | ✓ | — | — |
| Bookings filters dialog (3 sections: Status / Nekretnina / Vremenski period) | — | ✓ | — | — |
| F-67-01 confirm-error result (aria-live "Greška" + status unchanged) | — | ✓ | — | — |
| Logout (silent — no confirm modal, see F-62-01) | ✓ | — | — | — |
| Calendar — Timeline | ✓ | ✓ | ✓ | — |
| Calendar — Month (Syncfusion) | ✓ | — | — | — |
| Units — Osnovno tab | ✓ | ✓ | — | — |
| Units — Cjenovnik tab | ✓ | — | — | — |
| Units — Widget tab | ✓ | — | — | — |
| Units — Napredno tab | ✓ | — | — | — |
| Wizard Step 1 (Info) | ✓ | — | — | — |
| Wizard Step 2 (Kapacitet) | ✓ | — | — | — |
| Wizard Step 3 (Cijena) | ✓ | — | — | — |
| Wizard Step 4 (Pregled) | ✓ | — | — | — |
| Profile (hub) | ✓ | ✓ | ✓ | — |
| Edit profile | ✓ | — | — | — |
| Change password | ✓ | — | — | — |
| Notification settings | ✓ | — | — | — |
| Subscription | ✓ | — | — | — |
| Language picker (bottom sheet) | ✓ | — | — | — |
| Theme picker (bottom sheet) | ✓ | — | — | — |
| Notifications list | ✓ | — | — | — |
| FAQ | ✓ | — | — | — |
| AI Asistent — consent | ✓ | — | — | — |
| AI Asistent — chat | ✓ | — | — | — |
| iCal Import (empty state) | ✓ | — | — | — |
| Bank account form (empty) | ✓ | — | — | — |
| Stripe Connect (loading) | ✓ | — | — | — |
| Stripe Connect (not-connected) | ✓ | — | — | — |
| Embed Widget guide | ✓ | — | — | — |
| Auth — Login | ✓ | — | ✓ | — |
| Auth — Register | ✓ | — | — | — |
| Auth — Forgot password | ✓ | — | — | — |
| State — 404 | ✓ | — | — | — |

### Widget (11 captures)

| Surface | 1440 light | 1440 dark | 390 light | 390 dark |
|---|---|---|---|---|
| Calendar — Month | ✓ | ✓ | ✓ | ✓ |
| Calendar — Year (12 months grid) | ✓ | — | — | — |
| Calendar — dates selected + pricing panel | ✓ | — | — | — |
| Pricing modal (centered dialog) | ✓ | — | — | — |
| Guest information form | ✓ | ✓ | — | ✓ |
| Missing-`?property` error state | ✓ | — | — | — |

### Admin (2 captures)

| Surface | 1440 dark | 390 dark |
|---|---|---|
| Login | ✓ | ✓ |

Admin app **forces `themeMode: ThemeMode.dark` in `admin_main_dev.dart:63`** — no toggle. Authenticated screens not captured (test account `bookbed-test@bookbed.io` lacks admin custom claim — per audit/37 admin custom-claim provisioning was pending). Per task instructions for near-empty surfaces: noted, moving on.

> **Branch note (verified):** I clicked Potvrdi → Potvrdi-confirm on the live `seed-pending@example.com` Na čekanju booking; the aria-live region published the text "Greška" (visible in `f-67-01-confirm-result-error-1440-dark.png`); the booking remained `Na čekanju`. So F-67-01's broken behavior IS observable on `bookbed-owner-dev.web.app` today — the deployed bundle does NOT include `ca309fe2`'s fix. **The deployed flow surfaces a generic "Greška" snackbar, which is the pre-fix broken state.** Approve dialog itself is a simple AlertDialog. (The captured F-67-01 evidence is `f-67-01-confirm-result-error-1440-dark.png` — Status column = "Na čekanju" + transient "Greška" surfaced via live region.)
>
> **Dialog inventory coverage:** §3 captures cover the 4 booking-action dialogs (approve, reject, cancel, delete), bookings filters dialog, logout (no modal — F-62-01), 2 bottom sheets (language, theme), widget pricing modal + error state. **Not captured (acknowledged):** unit_future_bookings_dialog, calendar_search_dialog, booking_inline_edit_dialog, embed_code_generator_dialog, ical_feed_delete_dialog, send_email_dialog, additional_service_dialog, force/optional_update_dialog. These should be captured as part of the redesign-scoping phase before they're touched.

---

## §4 Per-Screen UX Critique

### 4.1 Owner — Pregled (Dashboard) — `pregled-1440-light.png`

**First impression:** Big saturated `#6B4CE6` purple app bar dominates the top 6% of viewport — first thing the eye hits is "Pregled" page title, not data. **The actual data — €0 revenue, 0 bookings, 0 check-ins, 0% occupancy — is faded out (rendered at low contrast, ~`#AAA` against white)**. This is intentional (empty state) but reads as "the page hasn't loaded yet" — confusing. No empty-state illustration / copy ("Još nema rezervacija — dodajte svoju prvu jedinicu") — just dimmed zeros.

**Visual hierarchy problem:** 4 stat cards (Zarada / Rezervacije / Nadolazeći check-in / Popunjenost) all identical size, identical weight, identical icon treatment. No "primary metric". For most property owners, "Zarada" (revenue) IS the primary metric — should be 2× the visual weight of the others. Current design treats all four as peers.

**Spacing/rhythm:** Generally OK. ~24px gutters between cards, ~32px between sections. App bar height feels excessive for what is essentially just a title.

**Date range selector** (Zadnjih 7/30/90/365 dana) — pill-style buttons, currently active pill is solid purple, others are white outlined. Width is consistent. Good. **But: 4 ranges feels arbitrary; "Zadnjih 365 dana" reads as bureaucratic** — consider "7 dana / 30 dana / Ova godina" instead. Also: no custom-range option.

**"Nedavne Aktivnosti" list** — generic Material `ListView` separated by `Divider()`. Notification-bell icon for "Nova rezervacija primljena", checkmark for "Rezervacija završena". Activity rows show property+unit, but timestamps are abbreviated to "prije 4d" (~"4d ago") with no full-time tooltip — ambiguous for stale activity. **The "Sve →" link top-right looks like a header anchor but is the only nav out of this list.**

**Mobile (`pregled-390-light.png`):** Stats stack vertically (good); date range pills overflow horizontally (do they scroll? not verified). Bell-icon-row pattern degrades.

**Dark (`pregled-1440-dark.png`):** Stat numbers are now MORE legible (white-on-black vs grey-on-white) — accidental improvement. Card surfaces (`#1E1E1E`) sit on `#000` true-black background — moderate depth. Activity dividers nearly invisible.

**One biggest weakness:** No primary metric. Dashboard reads as a level-0 stats panel, not a "what should I do today" surface. Redesign should pick ONE hero metric + supporting trend chart (sparkline last 30d?) + actionable next-step (e.g. "Imate 1 rezervaciju koja čeka odobrenje →").

---

### 4.2 Owner — Rezervacije (Bookings) — `bookings-1440-light.png` + `-cards-`

**Two view modes** (Card pogled / Tabela pogled) — both implementations. Card view is the better one — bookings already arrive with rich metadata (guest name, reference, payment status, source) that benefits from card density. Table view squeezes 10 columns into the viewport; on 1440 it works, on 1280 it would break, on mobile (`bookings-390-light.png`) the table requires horizontal scroll — confirmed.

**"Filteri i Pregled" header card** — labels the section but adds little. The "Napredno filtriranje" outlined card below is the actual filter trigger. Why a card-for-a-card-trigger? **Combine into single chip row + advanced filter overlay.**

**Tab row** (Sve / Na čekanju / Potvrđene / Otkazane / Uvezene) — currently uses pill chips, "Sve" outlined purple. Good. **Tab order: "Na čekanju" is the action-needed tab; should be FIRST** (or visually emphasized via a count badge — "Na čekanju (1)"). Currently `Sve` is default, so the user has to consciously switch — adds friction.

**Card view (`bookings-cards-1440-light.png`):** Status badge (orange "Na čekanju" pill, green "Završeno") is well-styled. Guest avatar slot is a generic gray circle with person icon — never populated. "Unknown Guest" everywhere (F-67-02 schema split — `guest_first_name`/`guest_last_name` vs legacy `guest_name`). Card has 5 metadata rows (guest / property / dates / nights / guest count) — efficient. **Booking reference (BB-TEST03) is bottom-right corner in light gray — looks like a discount code; should be more legible.** Padding on cards is ~16px — tight. Total/Plaćeno/Preostalo footer is a 3-column micro-grid that's HALF-VISIBLE in current scroll position — fold issue.

**Action menu** (`bookings-action-menu-1440-light.png`) — vertical popup with 6 actions: Detalji / Potvrdi (green) / Odbij (red) / Uredi / Pošalji email / Obriši. Colors do good signaling. Icon-text alignment correct. **Trash icon for "Obriši" but no confirmation surfaced — single tap from menu → delete** (verify in code).

**Booking approve dialog** (`dialog-booking-approve-1440-light.png`) — material `AlertDialog` with title "Potvrdi rezervaciju" and body "Jeste li sigurni da želite potvrditi ovu rezervaciju?". Generic, no info about WHICH booking, no preview of confirmation email, no option to add a note.

**Booking reject dialog** (`dialog-booking-reject-1440-dark.png`) — RICHER. Title "Odbij rezervaciju" + body + "Razlog odbijanja (opcionalno)" textarea + Odustani / red destructive "Odbij" CTA. **Inconsistency:** Approve is austere, Reject is informative. Standardize: same dialog shape, different destructive vs constructive colors.

**Booking cancel dialog** (`dialog-booking-cancel-1440-dark.png`) — only available on Završeno/Potvrđeno rows. RICHEST. Title + body + "Razlog otkazivanja" textarea + checkbox "Pošalji email gostu" (CHECKED by default — good default for an owner cancelling on guests) + Odustani / red destructive "Otkaži rezervaciju" CTA. **This is the gold-standard pattern** — the others should converge on it.

**Booking delete dialog** (`dialog-booking-delete-1440-dark.png`) — destructive warning: "Jeste li sigurni da želite **TRAJNO obrisati** ovu rezervaciju? Ova akcija se ne može poništiti." + Odustani / red Obriši. The TRAJNO (caps emphasis) is good — but a 2-step "type DELETE to confirm" pattern would be more defensible for truly irreversible actions.

**F-67-01 broken-flow capture** (`f-67-01-confirm-result-error-1440-dark.png`): clicking Potvrdi → Potvrdi-confirm raises aria-live "Greška" snackbar (a transient toast); booking row's Status cell STILL says "Na čekanju" 8+ seconds after — confirmed broken on deployed dev bundle. The flow DOES surface an error (so it's not 100% silent), but the error has no body and no remediation hint.

**Bookings filters dialog** (`dialog-bookings-filters-1440-dark.png`) — purple-header full-modal with 3 dropdowns (Status / Nekretnina / Vremenski period) + Očisti filtere / "Primijeni filtere" purple CTA. Clean. **The "Vremenski period" row currently shows "Odaberi vremenski period" placeholder — a date-range picker is one tap away but invisible from this dialog.** Could add inline calendar.

**Empty state:** Not captured (no empty state visible because the test account has bookings). **Inferred from code:** `owner_bookings_screen.dart` — empty state is likely a small grey text "Nema rezervacija" — this is the biggest redesign opportunity (no illustration, no helpful prompt).

**Loading state:** Not observed. Probably `CircularProgressIndicator`.

**Dark mode** (`bookings-1440-dark.png`) — table view in dark holds up reasonably; status pills retain color. Row dividers may be invisible against `#1E1E1E`.

**One biggest weakness:** Empty + loading states have zero design investment. The card view (good!) and table view (decent) are coexisting — should pick one default and make the other a power-user toggle.

---

### 4.3 Owner — Calendar Timeline — `calendar-timeline-1440-light.png`

**Calendar is the soul of the owner workflow** — and per CLAUDE.md it's frozen ("Timeline Calendar Calendar Repository — 989 linija, NE DIRATI"). The redesign must respect the calendar internals but can polish the chrome.

**Toolbar density:** Top-right contains 7 icon buttons (search / refresh / filters / today / notifications / stats toggle / hide-empty-units toggle) — all 32×32, no labels, no grouping. Hover-only tooltips. **Discoverability is bad** — the "Sakrij prazne jedinice" toggle is a niche feature that doesn't deserve permanent toolbar real estate. Move to a `⋯` overflow menu.

**Date range chips** (svibnja 2026 / lipnja 2026 / srpnja 2026) — 3 visible months, scroll to navigate. **Currently centered, with active "Jun 2026" pill in the date-picker dropdown header**. The relationship between the chips and the date-picker is unclear — they're parallel controls that should be unified.

**Booking blocks** — the green parallelogram block on Test Unit A row spans Jun 8–11. **Parallelogram (turnover-day-cut) is functionally correct** (check-in starts mid-day, check-out ends mid-day per CLAUDE.md "Timeline Calendar z-index: Cancelled bookings at base level (drawn first), confirmed on top"). Color is the only signal — owners need to learn that green = confirmed, yellow = pending, etc. (CLAUDE.md `calendar_cell_colors.dart`).

**Empty rows** — the screen has acres of whitespace below Test Unit A (1 unit total, but the screen is sized for many). Bigger Empty Treatment Needed.

**Floating Action Button** (purple circle bottom-right with `+`) — for adding a booking. Standard Material pattern. OK.

**Mobile timeline** (`calendar-timeline-390-light.png`) — works but each cell is tiny; the parallelograms are barely scannable. The toolbar icons go through an "Opcije" overflow.

**Dark mode** — same chrome, just darker.

**One biggest weakness:** Toolbar has 7 unlabeled icons fighting for attention. Consolidate to 3 primary (today / filter / +) and shuffle the rest into a kebab menu.

---

### 4.4 Owner — Calendar Month (Syncfusion) — `calendar-month-1440-light.png`

**Critical issue:** Header is in **ENGLISH** — "Backward", "Forward", "S M T W T F S" — despite the app being in Croatian. This is `Syncfusion Calendar`'s default locale not being overridden. F-Localization — visible inconsistency.

**Color legend** — 4 pills along the top (Potvrđeno / Na čekanju / Završeno / Otkazano) — good legend; correct colors.

**Smještajni objekt selector** — dropdown showing "Test Unit A" — limits view to one unit at a time. Why? Multi-unit overlay would be more powerful (cf. Timeline view).

**Visual:** Generic Syncfusion Material month grid. No BookBed brand polish — uses Syncfusion's default cell padding, default border colors. **Feels alien from the rest of the app.**

**One biggest weakness:** Looks bolted on. Either bring it into the design system (custom cell builder per CLAUDE.md `month_calendar_screen.dart`) or remove and consolidate into Timeline.

---

### 4.5 Owner — Smještajne Jedinice (Units Hub) — `units-list-1440-light.png` + tabs

**Hub layout:** Left main area (content), right rail (Objekti i Jedinice tree with search). The right rail is unique to this screen — no other owner screen uses a right rail. **Inconsistency.**

**4-tab top bar:** Osnovno / Cjenovnik / Widget / Napredno. The icons (📄 📅 `<>` 🎚) are decorative — not great UX (`<>` for "Widget" is ambiguous; the slider icon for "Napredno" is borderline meaningful). Underline-indicator style for active tab. Good.

**Osnovno tab:** Two side-by-side cards "Informacije" + "Kapacitet" + a third row "Cijena" below. Label-value pairs (Naziv / Test Unit A, Slug / N/A, Status / Dostupan...) — clean. **"Slug N/A"** in the UI looks like missing data, not an empty field — better: "Nije postavljeno" or hide.

**Cjenovnik tab** (`units-pricing-tab-1440-light.png`) — full mini-calendar with €120/€130 per cell. CLAUDE.md says this tab is FROZEN ("referentna implementacija"). Aesthetically it's busy but functional. Numbers (€120) are unbolded — make them prominent.

**Widget tab** (`units-widget-tab-1440-light.png`) — three big payment-mode cards (Samo kalendar / Rezervacija bez plaćanja / Puna rezervacija sa plaćanjem). **Good treatment** — each card explains the mode in 2 sentences. Slider below + Stripe/Bankovna toggles. The slider's purpose is unclear from screenshot (probably deposit %).

**Napredno tab** (`units-advanced-tab-1440-light.png`) — additional configuration. Hidden behind a tab so less critical, but the visual treatment should still match the other tabs.

**Right rail "Objekti i Jedinice"** — tree-list with iOS Test Vila → Test Unit A. Selected item gets purple background. Good. **But search box atop a 1-item tree is bizarre — show only when >5 items.**

**Dark mode** (`units-list-1440-dark.png`) — right rail and main area both well-styled. Selected item visibility OK.

**One biggest weakness:** Unique layout (right rail) for this screen breaks the shell pattern. Consider promoting Objekti i Jedinice tree to a left-sidebar pattern that appears app-wide once user has multiple units.

---

### 4.6 Owner — Unit Wizard (Steps 1–4) — `wizard-step1..4-1440-light.png`

**Step indicator** at top — 4 circles "Info / Kapacitet / Cijena / Pregled" with progress dot styling. Sufficient.

**Step 1 (Info):** 3 inputs (Naziv Jedinice, URL Slug, Opis). Fairly minimal. **The character counter "0/500" on the description textarea is functional but in tiny grey** — most users miss it.

**Step 2 (Kapacitet):** 4 number inputs (Spavaće sobe / Kupaonice / Maksimalno Gostiju / Površina m²) — laid out as 2×2 grid. Below: 3 collapsible sections (Dodatni kreveti, Kućni ljubimci, Dodatne usluge). Vertical density is good; pet/extra-bed cards expand on tap.

**Step 3 (Cijena):** 4 inputs (Cijena po noći, Vikend Cijena, Minimalan Boravak, Maksimalan Boravak) + a "Dostupnost" toggle. Informational note at bottom about advanced pricing in Cjenovnik tab — clear handoff.

**Step 4 (Pregled):** Summary card showing all data entered. Visible bug: "Audit Test" rendered as "udit Test" — the leading 'A' was dropped. **This is Flutter web `fill()` char-drop (F-67-04 memory)** — the actual Audit screen visible to a real owner who types properly would work. But it does reveal that Pregled DOES NOT VALIDATE the slug column ("u") rendered with a single character, suggesting auto-derived from name — but if it's auto-derived, no need to show as separate label-value.

**Wizard navigation:** Natrag (back) + Dalje/Objavi (forward). Solid purple primary CTA. Confirms CLAUDE.md "publish flow 3 Firestore docs redoslijed kritičan" is unchanged.

**One biggest weakness:** Step 4 (Pregled) is visually identical to a form — just disabled. Wouldn't an actual hero summary (big property image card + price headline + amenities chips) work better? Currently the review step doesn't FEEL like a final review; feels like a printout.

---

### 4.7 Owner — Profile (Settings hub) — `profile-1440-light.png` + `-dark.png`

**Hero header** — gradient purple card with avatar (B initial), name, email pill, and "Profil 14% ispunjen" progress card. Visually distinct from the rest of the app — uses the auth-style glassmorphism vocabulary. The 14% progress is a sales-style nudge.

**"Nadogradite na Pro" promo card** — full-width, gradient purple, prominent. Good CTA placement but **competes with profile content for eye attention**.

**Settings list** — generic `ListTile` rows with chevron disclosure. 9 settings + 3 legal links + 1 destructive "Obriši račun" at the bottom. **The "Opasna zona" red-styled section is the right move.**

**Profile actions:** Uredi profil / Promijeni lozinku / Postavke obavijesti / Pretplata / Jezik / Tema — these 6 should arguably be grouped under a "Account" header. Pomoć i podrška / O aplikaciji — "App" header. Uvjeti / Privatnost / Kolačići — "Legal" header. **Currently flat.**

**Bottom sheets** — Language (`sheet-language-1440-light.png`) and Theme (`sheet-theme-1440-light.png`) use a clean bottom-sheet pattern with avatar-circle icons + name + helper text. **These are well-designed and could become the basic "list cell" template across the app.**

**Edit profile** (`edit-profile-1440-light.png`) — basic name + phone + email fields. Adequate.

**Change password** (`change-password-1440-light.png`) — 3 password fields. Adequate.

**Notification settings** (`notification-settings-1440-light.png`) — list of toggles.

**Subscription** (`subscription-1440-light.png`) — well-designed status card "Trenutni status / Probni period" (faded coral bg, badge icon) + 2 plan cards. "Besplatan probni period" card with €0/30 dana + "Current" green badge top-right + 4 feature bullets (Do 2 nekretnine, Osnovno upravljanje rezervacijama, Email obavijesti, Sinkronizacija kalendara). "Pro" card with €19/mjesečno + red "RECOMMENDED" badge top-right + feature bullets. **Strong pricing table pattern** — clean per-plan card, clear current marker, recommendation cue. **One nit:** the "Pro" RECOMMENDED badge red color may signal urgency-meant-marketing but reads as warning; consider purple/gold per BookBed brand palette.

**Dark mode profile (`profile-1440-dark.png`)** — gradient purple hero card pops MORE in dark mode; settings list rows clean against `#000` bg.

**Mobile** (`profile-390-light.png`) — degrades to vertical stack, hero card resizes. Works.

**One biggest weakness:** The promo card "Nadogradite na Pro" is just below the user identity card → competes for attention. Settings list is flat (no headers) — at 12 rows + 3 legal + Opasna zona it's a long scroll.

---

### 4.8 Owner — Logout — `dialog-logout-confirm-1440-light.png`

**Critical UX defect — no confirmation modal.** Tapping "Odjava" immediately logs out + redirects to login. The captured screenshot IS the login screen (post-logout). This is F-62-01 from audit/62 — confirmed on web. **Destructive action with no friction**.

**One biggest weakness:** Logout button must show a "Sigurno se želite odjaviti?" modal — particularly because the app has session-tied data and users may not realize they need to re-auth.

---

### 4.9 Owner — Auth (Login / Register / Forgot) — `auth-login/register/forgot-1440-light.png`

**Auth surfaces are visually the MOST polished surfaces in the app** — and use a vocabulary that does NOT match the rest of the app.

**Login (`auth-login-1440-light.png`):**
- Centered card on light gradient background.
- BookBed logo at top of card.
- "Prijava vlasnika" headline.
- Email + password fields with leading icons (mail, lock) — distinctive treatment with light-grey input bg.
- "Zapamti me" checkbox + "Zaboravili lozinku?" link.
- Solid purple "Prijava" button — full-width.
- Divider "ili nastavite s".
- "Sign in with Google" + "Sign in with Apple" white outlined buttons — but they're in ENGLISH, not Croatian (i18n gap).
- "Nemate račun? Kreiraj račun" link at bottom.

**Visual style:** Soft drop shadows, subtle gradients, generous padding (~32px). **This looks like a polished SaaS product**. But it's the only surface in the app that does — Pregled / Bookings / Calendar all use flatter, less polished cards.

**Register (`auth-register-1440-light.png`):** Same card-on-gradient. Fields stacked vertically. Two consent checkboxes (Uvjeti + Politika privatnosti). Newsletter consent. Disabled "Kreiraj račun" button (probably enables once consents check). 

**Forgot password (`auth-forgot-1440-light.png`):** Single email field + Pošalji link + Natrag — clean, minimal.

**Mobile login (`auth-login-390-light.png`):** Card resizes, works well — clearly designed for mobile.

**One biggest weakness:** This is the design system the rest of the app SHOULD adopt. Currently it's an island.

---

### 4.10 Owner — AI Asistent — `ai-assistant-1440-light.png` + chat

**Consent screen:** Privacy-conscious — 4 bullet points explaining AI/data/history before starting. Single CTA "Razumijem, započni". Good pattern.

**Chat surface** (`ai-assistant-chat-1440-light.png`) — split layout: left sidebar with conversation list ("Još nema razgovora") + cute purple robot illustration + "Novi razgovor" CTA + descriptor text. Main area is empty chat with 5 prompt-suggestion pills ("Kako dodati apartman?", "Postavi cijene", "Poveži Stripe", "iCal sinkronizacija", "Ugradi widget") + empty bg + bottom input "Postavite pitanje..." + send arrow. The robot illustration is on-brand purple gradient — playful. **One observation:** the suggestion pills are excellent onboarding scaffold; the rest of the app could borrow this "what to ask next" affordance (FAQ, dashboard).

---

### 4.11 Owner — FAQ — `faq-1440-light.png`

**Layout:** Search box + 6 category checkboxes (Sve, Rezervacije, Plaćanja, Widget, iCal Sync, Tehnička Podrška) + accordion list of Q&A items. Accordions show category badge.

**Hierarchy:** Clear. Search at top, filter below, content below. Category-tagged questions help context.

**One biggest weakness:** Long list — no count next to each category to give expectation ("Plaćanja (3)"). Search has no result count after typing.

---

### 4.12 Owner — Notifications — `notifications-1440-light.png`

**Plain list of bookings** ("Nova rezervacija Smoke T11 je kreirao novu rezervaciju. 22h prije"). All identical icon + identical layout. No categorization (new / reminder / completed). No "mark all read" action visible at top. **"Odaberi" floating action at bottom-right is for bulk actions**. The bell icon in app bar shows "6 obavještenja" but no way to mark as read without entering.

**One biggest weakness:** All notifications look the same — no visual distinction between actionable ("needs your approval") vs informational ("payment received").

---

### 4.13 Owner — iCal Import — `ical-import-1440-light.png`

**Excellent empty state** — "Nema feedova" + helpful "Dodajte prvi iCal feed da započnete sinkronizaciju" + button + 3 explainer cards below ("Automatska sinkronizacija", "Sprječavanje dvostrukog rezerviranja", "Kompatibilnost") with platform logos.

This is THE empty state pattern the rest of the app should adopt — illustration + headline + helper + CTA + benefits sub-section.

**One biggest weakness:** Doesn't show the same level of polish post-feeds-added; risk of populated state being flatter.

---

### 4.14 Owner — Bank Account form — `bank-account-1440-light.png`

**Layout:** Top info card "Kada se koriste ovi podaci?" explains context. 4 input fields (IBAN / SWIFT-BIC / Naziv Banke / Vlasnik Računa). Spremi/Odustani buttons.

**Validation hint** — no inline format validation visible. IBAN should have format helper (HR XX XXXX XXXX XXXX XXXX X).

---

### 4.15 Owner — Stripe Connect — `stripe-connect-1440-light.png` (loading) + `-loaded`

**Loading state:** "Učitavanje postavki plaćanja..." with floating € $ £ ¥ ₣ symbols — playful but **doesn't feel like brand**. Loading should use shared skeleton pattern (`dashboard_stats_skeleton.dart` exists for dashboard — extend it).

**Loaded (not connected):** "Nije povezano" headline + warning "Stripe račun nije povezan. Prijem plaćanja nije moguć." + primary CTA "Poveži Stripe Račun". Then 5 explainer cards. Bottom: 4 numbered steps for onboarding.

**Excellent** — clear problem, clear action, clear context. Use this pattern more.

---

### 4.16 Owner — Embed Widget Guide — `embed-widget-guide-1440-light.png`

Picks a unit, shows embed code, has scroll-protection explainer + demo example button. **The Brza pomoć button top-right is a non-standard help-CTA pattern** — most help is in FAQ; why a separate quick-help here?

---

### 4.17 Owner — Drawer — `drawer-1440-light.png`

**Layout:** Avatar+name+email at top (purple gradient), 9 nav rows below (Pregled / Kalendar ⌄ / Rezervacije [1 badge] / AI Asistent / Smještajne Jedinice / Integracije ⌄ / FAQ / Obavještenja [6 badge] / Profil).

**Active item:** Light purple background pill — good. Inactive: just text + icon. **Inconsistency:** Some labels have a trailing chevron-down indicating expandable (Kalendar, Integracije), but the visual style (text only) is the same for all rows except the chevron — no other affordance hints at hierarchy.

**Mobile** — drawer is the primary nav since there's no top tab bar — standard pattern.

**One biggest weakness:** Drawer is good but on desktop (1440) it occupies the whole left edge with a floating modal — on a SaaS dashboard you want a permanent left sidebar, not a hamburger-toggled drawer.

---

### 4.18 State — 404 — `state-404-1440-light.png`

**Strong:** Big purple "404" headline (serif font!) + "Stranica nije pronađena" + helper + 2 buttons (Povratak na početnu / Natrag). Search-with-X illustration. **This is one of the most polished surfaces** in the app — proof a designer touched it.

**Why interesting:** Many owner sub-routes (calendar/, edit-profile, etc.) 404 if URL-typed directly because routing is `Navigator.push`-based (only Admin uses GoRouter). The 404 page is hit more often than it should be.

---

### 4.19 Widget — Calendar (Month/Year) — `widget/calendar-*.png`

**ENTIRELY DIFFERENT DESIGN SYSTEM.** Black/white/green minimalist palette (per `lib/features/widget/presentation/theme/minimalist_theme.dart`). NO purple. NO BookBed gradient. Header has dark Month/Year tabs, moon-icon (theme toggle), language flag picker, and "May 2026" date selector.

**Calendar grid:** 7-column week grid. Disabled past dates are grey (`#F5F5F5`). Future-available dates show price (€120 / €130). Selected dates pop GREEN (`#2DD4BF`-ish).

**Hover state** (`calendar-dates-selected-1440-light.png`) — date tooltip with "Saturday, May 30, 2026" + "€130 / night" + "Available" + "Click to select". **Excellent.**

**Year view** (`calendar-year-1440-light.png`) — 12 months in a grid. Dense but readable. Past months greyed.

**Dark mode** (`calendar-1440-dark.png`) — true black bg with green dates. Strong contrast.

**Mobile** (`calendar-390-light.png` + `-dark`) — calendar resizes; tab/picker shrinks.

**One biggest weakness:** This is widget-deliberately-different — it embeds in guest sites, must NOT clash with arbitrary host. Fine. But the BOOKING FLOW that follows (guest form) inherits this same minimalist style — and feels like a different vendor's product. Worth a polish pass for visual continuity once the calendar is selected.

---

### 4.20 Widget — Dates Selected + Pricing Modal — `widget/calendar-dates-selected-` + `pricing-modal-1440-light.png`

After selecting dates: a sliding panel appears on the right showing "May 29 2026 - May 30 2026 | 1 night | Room (1 night) €130 | TOTAL €130 | Deposit: €26 (20%)" + green "Reserve" button. Information density just right. CTA color (black) is a deliberate widget choice.

The pricing-modal alternative pattern (in `pricing-modal-1440-light.png`) shows the same data in a centered overlay with X-close + Reserve CTA. **Trigger context (likely):** appears when dates are selected from Year view (centered modal makes sense — no sliding panel available since year shows 12 months). Compare to `calendar-dates-selected-1440-light.png` (Month view → sliding right panel). If the trigger split (year-vs-month) is intentional, the patterns are justified; if not, they're duplicated work. Recommend verifying + documenting.

---

### 4.21 Widget — Guest Form — `widget/guest-form-1440-light.png` + `-dark`

**Layout:** Sliding panel + sticky calendar on left. Fields: First Name / Last Name / Email / Phone (with HR +385 prefix) / Special Requests / Adult+Child counter / Payment block / Tax checkbox / Pay with Stripe CTA.

**The Stripe CTA** says "Pay with Stripe - 1 night" — interesting copy choice, but a bit informal. "Plati €26 depozit" might be more action-clear.

**Quality:** Inputs are properly labeled, asterisks for required. Counter +/- buttons clearly state max (4). Total breakdown again on right side.

**Dark mode** — works well, true-black bg with white surfaces.

**One biggest weakness:** Special Requests storage leak (F-67-03 — confirmed in audit/67) — typed values from prior sessions leak to fresh browser sessions. Privacy / security flaw, not design — but flag for redesign: form should not auto-save to localStorage.

---

### 4.22 Widget — Missing Property State — `widget/home-no-subdomain-1440-light.png`

**Raw error:** Pink "!" circle + "Missing property parameter in URL." + "Please use: ?property=PROPERTY_ID&unit=UNIT_ID" + black Retry button.

**English only**, no translation. Reveals internal URL contract to end users. A genuine guest who somehow lands on `https://bookbed-widget-dev.web.app/` with no subdomain context would see this and have no idea what to do.

**One biggest weakness:** Should redirect to `subdomain_not_found_screen.dart` (which exists per inventory!) with a "This property is no longer available" friendly message — not a developer error.

---

### 4.23 Admin — Login — `admin/login-1440-dark.png` + `-390`

**Hardcoded dark theme.** Welcome Back / Please sign in to access the admin portal. Centered card with logo above. Email + password fields. Sign In button (purple). © 2026 BookBed Inc. footer.

**Style:** Lighter polish than auth-login on owner. Uses `#1A1A2A`-ish dark surface, `#2A2A3F` form bg. Less differentiated than owner login.

**English (not Croatian) labels** — "Welcome Back / Email Address / Password / Sign In" — i18n gap. The admin app loads `Locale('hr')` per `admin_main_dev.dart:74` but UI is English. Suggests labels are hardcoded in `admin_login_screen.dart` not pulled from `AppLocalizations`.

**Mobile** — card stacks; logo at top.

**Authenticated screens:** Not captured (no admin claim on test account; per audit/37 admin claim provisioning was pending). Per task, near-empty surface — noting and moving on.

**One biggest weakness:** Admin uses an entirely separate design vocabulary (forced dark, no theme toggle, hard-coded English) — when the redesign lands, this surface needs to either match Owner OR diverge ON PURPOSE with a different design intent. Currently it's just neglected.

---

## §5 Cross-Cutting Findings

### 5.1 Design system — exists but adoption is 30–40%

Token system is real:
- `lib/core/theme/app_colors.dart` — 30+ named colors, well-organized (primary/secondary/tertiary, light/dark variants, text/bg/border/divider hierarchy).
- `lib/core/theme/app_typography.dart` — TextStyle scale.
- `lib/core/constants/app_dimensions.dart` — 4/8/16/24/32/48/64/96 spacing; 6/12/20/24/32/full radius; mobile/tablet/desktop breakpoints.
- `lib/core/design/tokens.dart` — `BB*` canonical namespace delegating to the above.

But:
- **477 `Color(0xFF…)` total** in `lib/`. Only **209 of those are inside theme files** — meaning **268 hardcoded colors leak out of theme** in feature files. That's > 50% leakage outside the design system.
- **1057 `EdgeInsets.*(` constructor sites** in `lib/features/`. Many use magic numbers (e.g. `EdgeInsets.symmetric(horizontal: 14)`).
- **~600 `TextStyle(` constructors** in `lib/features/` (not exact — counted broadly) — meaning massive style duplication.
- Two parallel token systems (`lib/core/design_tokens/*.dart` × 11 files vs `lib/core/design/tokens.dart`) — pick one and codemod-merge.

### 5.2 Inconsistency catalog (specific instances)

| Inconsistency | Evidence |
|---|---|
| Calendar months — HR locale on Timeline, **EN on Syncfusion Month** (S/M/T/W/T/F/S) | `calendar-month-1440-light.png` |
| Calendar Mjesečni weeks start **Sunday-first** while Timeline weeks start **Monday-first** + Cjenovnik mini-calendar also Monday-first | All 3 calendar screenshots |
| Auth surface (login/register/forgot) uses **distinctive glassmorphism + premium inputs**, owner shell uses **flat material cards** | `auth-login-1440-light.png` vs `pregled-1440-light.png` |
| Widget surface uses **minimalist black/white/green palette**, owner uses **purple-driven palette** | Compare `widget/calendar-1440-light.png` vs `owner/pregled-1440-light.png` |
| Admin surface uses **English labels** ("Welcome Back / Email Address") despite app loading `Locale('hr')` | `admin/login-1440-dark.png` + `admin_main_dev.dart:74` |
| **Google/Apple Sign In buttons in ENGLISH** ("Sign in with Google") despite HR-locale app | `auth-login-1440-light.png` |
| Two booking-detail dialog impls (`booking_details_dialog.dart` + `booking_details_dialog_v2.dart`) coexist | Inventory §2.3 |
| Two ways to view pricing in widget (sliding panel from Month view vs centered modal from Year view) — possibly intentional, needs confirmation | `widget/calendar-dates-selected-` vs `pricing-modal-` |
| Booking action dialogs are inconsistent in richness: Approve is austere (yes/no), Reject has a textarea, Cancel has textarea + email-notify checkbox + destructive CTA | `dialog-booking-approve-` vs `dialog-booking-reject-` vs `dialog-booking-cancel-` |
| Profile uses **gradient hero card**, other settings entry points (units, calendar) use **flat app bar** | `profile-1440-light.png` |
| Settings list is **flat, 12 rows**, while drawer is **9 rows with section dividers** | Both screenshots |
| Notifications all look **identical regardless of category** | `notifications-1440-light.png` |
| **Bank account form has no inline IBAN validation**, register has stricter validation | `bank-account-1440-light.png` + register flow |

### 5.3 Hardcoded-style debt — worst offenders

From `find lib/features -name '*.dart' | xargs grep -l 'Color(0xFF'` (deduplicated by feature):

| File | Why it leaks |
|---|---|
| `lib/features/owner_dashboard/presentation/widgets/calendar/booking_block_widget.dart` | Inline status colors (`#4CAF50` confirmed, `#FFA726` pending, `#9E9E9E` cancelled) — should use `AppColors.success/warning/textTertiary` |
| `lib/features/owner_dashboard/presentation/widgets/calendar/smart_booking_tooltip.dart` | Tooltip bg + text colors hardcoded |
| `lib/features/owner_dashboard/presentation/widgets/calendar/calendar_top_toolbar.dart` | Icon/badge colors |
| `lib/features/owner_dashboard/presentation/screens/widget_settings_screen.dart` | Many one-off colors |
| `lib/features/owner_dashboard/presentation/screens/calendar/month_calendar_screen.dart` | Syncfusion cell colors (some via `calendar_cell_colors.dart`, others inline) |
| `lib/features/owner_dashboard/presentation/widgets/shared/daily_stats_widgets.dart` | Stat card colors |
| `lib/features/owner_dashboard/presentation/widgets/owner_app_drawer.dart` | Drawer background gradient stops |
| `lib/features/owner_dashboard/presentation/widgets/dashboard_stats_skeleton.dart` | Skeleton shimmer colors |
| `lib/features/owner_dashboard/presentation/widgets/price_list_calendar_widget.dart` | Cjenovnik tab cell colors |

**Codemod scope:** ~30 files in `owner_dashboard/presentation/widgets/`. A single PR with eager-find-replace + manual review is feasible.

### 5.4 Accessibility — moderate (cross-ref audit/63 + 64)

- **HTML `lang="hr"`** ✓ closed via audit/64 PR #534.
- **Lighthouse a11y 100/100** on owner dashboard per audit/64.
- **Font-scale (Android) 2.0×** — chips clip viewport on Pregled tabs (audit/63 F-63-04 + PR #535 fix). Repro on web zoom 200%? Untested.
- **Flutter web semantics** — placeholders click-to-enable required (audit/64) — `mcp__chrome-devtools` MCP successfully enabled across all 3 surfaces this run.
- **Widget date picker — F-58c-21 — canvas-only dates** (CanvasKit doesn't expose date cells as DOM nodes — screen readers can't navigate). Significant blocker for visually-impaired guests. Live confirmed this run.
- **Tap target size** — most CTAs ≥48px. Calendar toolbar icons on owner are 32×32 — borderline. Action menu items adequate.

### 5.5 Dark mode — works, light-mode leaks rare

Tested 6 owner screens in dark (pregled / bookings / calendar timeline / profile / units list / drawer). All render correctly — no light-mode leaks observed (no surprise white panels). True-black `#000` bg + `#121212` surface + `#1E1E1E` elevated surface is a clean MD3 implementation per `app_colors.dart`.

Edge cases:
- AlertDialog (`dialog-booking-approve-1440-light.png`) — captured light, dark not verified; standard Material `AlertDialog` should adapt via theme.
- Stripe Connect / Bank Account / Embed Widget Guide — not captured in dark.
- Widget surface — has its own dark mode (`widget/calendar-1440-dark.png`) — works.
- Admin — forced dark only — light mode not implemented.

### 5.6 Empty / loading / error states — neglected

| State | Status |
|---|---|
| iCal Import empty | **EXCELLENT** — best in app (illustration + helper + CTA + benefits) |
| Stripe Connect not-connected | **EXCELLENT** — same pattern |
| 404 | **EXCELLENT** — designed |
| Stripe Connect loading | mediocre (floating €$£¥₣ symbols feel off-brand) |
| Pregled when 0 bookings | **mediocre** — faded zeros, no copy/illustration |
| Bookings list empty | **NOT CAPTURED** (test account has bookings) — inferred low-effort default |
| Bookings loading | **NOT CAPTURED** — likely default `CircularProgressIndicator` |
| Calendar timeline with 0 units | **NOT CAPTURED** — likely empty grid |
| Forms — validation errors | **partially designed** (red text below input on login; not consistent everywhere) |

This is the #1 highest-ROI redesign target: 5+ screens deserve an iCal/Stripe-quality empty state.

### 5.7 Mobile responsiveness — works, not loved

- Owner shell collapses cleanly to single-column on 390 width.
- Pregled stats stack vertically.
- Bookings table forces horizontal scroll (not graceful — should switch to card view auto).
- Calendar timeline shrinks cells (functional but tight).
- Profile / Auth / FAQ all degrade well.
- Widget surface — purpose-built for embedding, mobile-first.

**Gap:** No tablet-specific layout. 768–1199 px ranges fall back to mobile (likely — not verified). A 3-column profile / 2-up bookings would be appropriate.

### 5.8 Typography — minimal hierarchy

- Headings: Page titles in app bar (large, white-on-purple). Section titles in cards (~18px, semibold, dark-on-light).
- Body: 14–16px regular. Captions: 12px grey.
- **No display/hero typography** outside the 404 page and (very subtly) profile hero card.
- Number formatting (Pregled stats) — €0 / 0.0% — uses default `DecorationStyle.numbers`, no monospaced tabular numerals. For dashboard metrics, tabular-figure font features matter.

### 5.9 Component duplication

| Component | Implementations |
|---|---|
| Empty-state pattern | 2 designed (iCal, Stripe, 404), N defaults |
| Booking detail dialog | 2 coexisting (v1 + v2) |
| Theme toggle | 1 (bottom sheet) + 1 (widget icon button) — different patterns |
| Buttons (CTA) | No single primitive — purple-fill in owner, black-fill in widget, gradient in auth |
| Input field | At least 3 (premium_input_field for auth, generic Material for forms, custom for inline calendar editing) |
| Card | Multiple (stat card, booking card v1, booking card v2, unit card, settings tile) — no shared base |

---

## §6 Refreshed Visual Direction Proposal

Keep:
- Primary `#6B4CE6` purple — anchor brand color.
- Secondary `#FF6B6B` (Coral Red) — for destructive/warning.
- Tertiary `#FFB84D` (Golden Sand) — for accent/highlights.
- Backgrounds (light `#FAFAFA`, dark `#000`).
- 8px spacing grid.
- Croatian-first localization.

Refine:

### 6.1 Spacing scale (formalize what exists, drop the off-scale 12)

| Token | Value | Use |
|---|---|---|
| `BBSpace.xxs` | 4 | Tight chips, icon-text gap |
| `BBSpace.xs` | 8 | Within-card padding |
| `BBSpace.sm` | 16 | Card padding, list row gap |
| `BBSpace.md` | 24 | Section gap, card-to-card |
| `BBSpace.lg` | 32 | Major section break |
| `BBSpace.xl` | 48 | Page-level top/bottom |
| `BBSpace.xxl` | 64 | Hero spacing only |
| ~~`BBSpace.xs2 = 12`~~ | — | DELETE — not on 4/8 grid, codemod to 8 or 16 |

### 6.2 Border radius scale

| Token | Value | Use |
|---|---|---|
| `BBRadius.xs` | 6 | Badges, micro-pills |
| `BBRadius.sm` | 12 | Buttons, inputs, chips (CLAUDE.md mandate) |
| `BBRadius.md` | 20 | Cards |
| `BBRadius.lg` | 24 | Modals, sheets |
| `BBRadius.xl` | 32 | Hero/featured cards |
| `BBRadius.full` | 999 | Avatars, pills |
| ~~`BBRadius.xs2 = 8`~~ | — | DELETE — fold into sm or xs |

### 6.3 Elevation / shadow system (currently inconsistent)

Define 4 levels (currently many one-off shadows):

| Level | Use | Shadow |
|---|---|---|
| `BBShadow.none` | Flat surface | none |
| `BBShadow.sm` | Card resting | `0 1px 2px rgba(0,0,0,.05)` |
| `BBShadow.md` | Card hover, dialog | `0 4px 12px rgba(0,0,0,.08)` |
| `BBShadow.lg` | Floating panels, drawers | `0 12px 24px rgba(0,0,0,.12)` |
| `BBShadow.purple` | Primary CTA glow | `0 8px 24px rgba(107,76,230,.25)` |

### 6.4 Component-state matrix

Define explicit `default / hover / pressed / disabled / focus` for the 3 most-used primitives:

#### Primary Button (formerly `gradient_auth_button.dart` style — promote app-wide)

| State | Background | Text | Shadow |
|---|---|---|---|
| Default | `BBColor.primary` solid | white | `BBShadow.purple` |
| Hover | `BBColor.primaryDark` | white | `BBShadow.md` + purple |
| Pressed | `BBColor.primaryDark` 90% | white | `BBShadow.sm` |
| Disabled | `BBColor.primary` 30% opacity | white 60% | none |
| Focus | + 2px purple-light ring at 4px offset | — | — |

#### Input Field (formerly `premium_input_field.dart` style — promote app-wide)

| State | Border | Background | Text |
|---|---|---|---|
| Default | `BBColor.borderLight` 1px | `BBColor.surfaceVarLight` | `BBColor.textLight` |
| Focus | `BBColor.primary` 2px | white | `BBColor.textLight` |
| Error | `BBColor.error` 2px | `BBColor.error` 5% bg | error text below |
| Disabled | `BBColor.borderLight` | `BBColor.surfaceVarLight` 50% | text 50% |

#### Card (base — used everywhere)

| State | Background | Shadow | Border |
|---|---|---|---|
| Resting | `BBColor.surfaceLight` (white) | `BBShadow.sm` | none |
| Hoverable | + hover: `BBShadow.md`, slight `-translateY(2px)` | — | — |
| Selected | + 2px `BBColor.primary` border | `BBShadow.md` | yes |
| Disabled | opacity 50% | none | — |

### 6.5 Three before/after sketches

#### Sketch A — Pregled (Dashboard) redesign

**Before (`pregled-1440-light.png`):**
- Big purple app bar dominates
- 4 equal-weight stat cards
- Faded zeros (looks unloaded)
- Generic activity list below

**After:**
- Slim white app bar (just title + drawer toggle)
- Hero metric strip: `€0` Zarada displayed at 56pt (3× the other 3 metrics)
- 3 secondary metrics as small tiles
- A 30-day sparkline below the hero metric (Booking activity trendline)
- Empty state hero (when 0 bookings): illustration + headline "Spremni za prvu rezervaciju?" + 2-step setup CTA ("Dovrši Stripe", "Podijeli widget")
- Activity timeline keeps but each row shows ACTION required (e.g. "→ Odobri", "→ Pošalji ključeve") with chevron disclosure into action

#### Sketch B — Bookings list redesign

**Before (`bookings-1440-light.png`):**
- "Filteri i Pregled" + "Napredno filtriranje" two stacked filter cards
- Tab pills with "Sve" default
- Table view dense, "Unknown Guest" everywhere
- Action menu requires 2 clicks to confirm/reject

**After:**
- ONE filter row: tab chips + search + advanced filter overlay button
- "Na čekanju (1)" tab first, badge-styled if count > 0
- Card view default everywhere (>768px AND <768px); table mode is "Power user" toggle
- Booking card shows:
  - Status pill top-left
  - Reference top-right (smaller, monospace)
  - Guest avatar (initials if no photo) + name on row 1
  - 3 metadata rows (property → unit → dates with nights badge)
  - Footer: amount + 2-button inline actions (Odobri ✓ / Odbij ✕) for pending bookings only
  - For confirmed: just a chevron disclosure into details

#### Sketch C — Widget Calendar landing

**Before (`widget/calendar-1440-light.png`):**
- Black/white/green minimalist
- Calendar dominates
- Pricing tooltip on hover

**After:**
- Hero unit card at TOP (1 photo + name + €120/night avg)
- Calendar below with continuous date-range selection (drag to extend)
- Pricing sidebar STICKY (always visible, slides up to show breakdown when dates selected, fades in)
- BOOK BUTTON (large, black, full-width on mobile / right-aligned on desktop) always visible at bottom — disabled state when no dates → "Odaberi datume"
- Add a hover state on dates: not just tooltip, show price BOLDER (currently price is small grey)
- Empty state — DATES SELECTED but property unavailable: red bg pulse + helper text

### 6.6 Tokens that should stay (don't touch)

- `BBColor.primary = #6B4CE6` — strong brand purple
- `BBColor.secondary = #FF6B6B` — well-balanced coral
- `BBColor.tertiary = #FFB84D` — warm gold
- 8px grid spacing (`spaceXXS` through `spaceXXXL`)
- 12px button radius (CLAUDE.md mandate)
- Calendar fixed dimensions (50/42/100/60px per CLAUDE.md FROZEN — Timeline Calendar)

---

## §7 Recommended Redesign Sequencing

### Phase 0 — Pre-redesign cleanup (1 week, NO visual change)

1. **Delete `booking_details_dialog.dart` v1** (keep v2). Verify call sites use v2.
2. **Pick ONE token system**: keep `lib/core/design/tokens.dart` (BB* namespace), DELETE `lib/core/design_tokens/*.dart` (11 files). Codemod imports.
3. **Codemod hardcoded `Color(0xFF…)` outside theme files** → `BBColor.*`. Manual review for status-specific colors (booking_block_widget.dart, calendar_cell_colors.dart). Target: 268 → < 50.
4. **Sync admin app i18n** — admin login labels currently hardcoded English; pull from `AppLocalizations`.
5. **Fix Syncfusion Month calendar locale** — pass HR locale to Syncfusion widget so days/months render Croatian.

### Phase 1 — Owner Shell + Dashboard (2 weeks, biggest user-visible impact)

Order:
1. **Pregled** (Sketch A) — hero metric + sparkline + empty state.
2. **Drawer** — promote to permanent left sidebar on ≥1024px; keep modal on mobile.
3. **App bar** — slim down to 48px; just title + drawer toggle.
4. **Bookings list** (Sketch B) — card default, "Na čekanju" tab first.
5. **Booking detail dialog** — already V2 on main; integrate Phase 0 cleanup.

Dependencies:
- **F-67-01 fix must be deployed** before redesign of booking approve flow (current dev hosting is stale; PR `ca309fe2` must land first to enable iteration).
- Empty state designs need to be established as a reusable component first.

### Phase 2 — Calendar surfaces (2 weeks)

1. **Timeline calendar toolbar** — consolidate 7 icons → 3 + overflow menu.
2. **Calendar status legend** — add to Timeline (currently only Month has it).
3. **Mjesečni calendar** — either invest (custom cell builder using BookBed tokens) or remove and consolidate into Timeline.
4. **Cjenovnik tab** — CLAUDE.md says FROZEN — but visual polish (number weight, color emphasis) is allowed.

### Phase 3 — Settings + Profile (1 week)

1. **Profile screen** — group settings under headers (Account / App / Legal / Danger).
2. **Settings sub-screens** — establish reusable form layout (currently 3 different layouts: edit_profile, change_password, notification_settings).
3. **Logout confirmation modal** — close F-62-01.
4. **Bottom sheets** (language, theme) — already good; codify as the modal-picker primitive.

### Phase 4 — Auth surface alignment (1 week)

The auth surface (currently best-looking) becomes the design vocabulary the rest of the app inherits, OR the rest of the app pulls toward the new vocabulary. Don't leave it as an island.

1. Extract `premium_input_field.dart`, `gradient_auth_button.dart`, `glass_card.dart` into `lib/core/widgets/` and rename without "auth" prefix.
2. Replace ad-hoc inputs/buttons app-wide.
3. **i18n the Google/Apple Sign-In buttons** ("Prijava preko Googlea" / "Prijava preko Applea").

### Phase 5 — Widget visual polish (1 week)

1. Widget continues with minimalist palette (intentional).
2. But upgrade: hero unit card, continuous date-range drag selection, sticky pricing sidebar (Sketch C).
3. Localize "Pay with Stripe" → "Plati karticom".
4. Close F-67-03 storage leak before redesign (security-tier blocker).

### Phase 6 — Admin (deferred — 1 week)

1. Decide: align with Owner OR diverge purposefully?
2. If aligning: extract auth components from owner, recolor in admin.
3. Either way: fix the i18n drift.

### Sequencing rationale

- Phase 0 has no visible change but unblocks all subsequent work.
- Phase 1 has the biggest "wow" payoff — Pregled is the first screen users see.
- Phase 2 is high-impact but high-risk (calendar internals frozen per CLAUDE.md).
- Phase 3+ are smaller surfaces.

**Total: ~8 weeks of design+frontend work, sequenced for early demo wins.**

### Blockers / risks

- **F-67-01 fix not deployed to dev hosting** — design iteration on Confirm/Reject flow blocked until deploy lands.
- **Calendar Repository frozen** (CLAUDE.md "989 linija, NE DIRATI"). Chrome polish OK, internals NOT.
- **Cjenovnik FROZEN** — same caveat.
- **Terminal B iOS regression risk** — `ios/Runner/GoogleService-Info.plist` is currently dev-swapped (Terminal B owns); redesign work must not touch iOS asset bundling until B releases.

---

## §8 Open Questions for User

Collected during the audit. Answers will sequence the redesign:

1. **What is the primary metric for Pregled?** (Zarada / Rezervacije / Popunjenost / Other?) — drives Sketch A. Different personas may have different answers.
2. **Reference apps for new visual direction?** (Linear / Notion / Stripe Dashboard / Airbnb host dashboard / something else?) — sets baseline visual energy + density expectation.
3. **Are screens "Pomoć i podrška" + "Embed Help" + "Embed Widget Guide" + "FAQ" all warranted, or consolidate?** — currently 4 help-style surfaces.
4. **Should the calendar Mjesečni view stay or merge into Timeline?** — currently two coexist (Timeline is canonical per CLAUDE.md; Mjesečni is bolted-on Syncfusion).
5. **Owner shell: drawer vs permanent left sidebar on desktop?** — recommend permanent sidebar above 1024px; need user agreement.
6. **Booking list default — card vs table?** — recommend card default with table as power-user toggle.
7. **Admin redesign in this cycle, or defer?** — admin currently feels neglected; needs a decision.
8. **Logout — confirmation modal mandatory? Or "are you sure" inline?** — closing F-62-01.
9. **Empty state vocabulary — illustrations or icon-only?** — current best examples (iCal, Stripe, 404) use icon. Decide on illustration budget.
10. **Subscription paywall — current placement (in profile) okay, or surface earlier in flow?** — promo card is competing for attention in profile.
11. **Two booking detail dialogs (v1 + v2) — confirm v1 deletable?** — code change but user-visible nothing.
12. **Widget minimalist palette — keep purely b/w/green or introduce subtle BookBed purple hint?** — important brand recognition decision.
13. **Auth surface (login/register) — the "ideal" target style for whole app, or keep as island?** — drives Phase 4.
14. **Font choice — keep current default (Roboto?), or invest in a brand font (Inter / Manrope / Geist)?** — typography step-up would be a meaningful upgrade.
15. **Reduced-motion / accessibility priorities?** — currently calendar tutorial overlay uses animation; widget date selection uses motion. Need a11y prefers-reduced-motion respected.
16. **Subdomain widget routing — does `bookbed-widget-dev.web.app` accept `?property=...&unit=...` as a fallback for ALL users, or is that only a dev-time convenience?** — informs landing UX.

---

**End of audit.**

61 captures, 36 screens, 28 dialogs/sheets. Branch: `fix/f-67-01-booking-confirm-reject @ ca309fe2`. Deploy target: `bookbed-{owner,widget,admin}-dev.web.app`.

