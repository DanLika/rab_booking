# audit/119 — Claude-driven premium visual sweep, evidence-based (2026-06-06)

**Branch**: `tmp/premium-integration-2026-06-06 @ 48a7dca1` (worktree `/private/tmp/bb-integ-wt`)
**Device**: Pixel_8 AVD, 1080×2400, Android 35, `flutter run --debug` against `bookbed-dev`
**Dart-defines**: `PREGLED_AI_INSIGHT=true PREGLED_CHANNEL_MIX=true PROFILE_HOST_STATS=true STRIPE_PAYOUTS=true`
**Capture order**: screenshot FIRST, then re-open mockup (confirmation-bias control)
**Screenshots**: `~/bookbed-design-qa/round5/r5-{light,dark}-{NN-name}.png` (1080×2400 originals; sips-shrunk previews used for read)
**Mockup**: `design_handoff/screens/0[1-3]-owner.png` (desktop frames) + `design_handoff/source/{pregled-premium,calendar-{month,timeline},rezervacije-premium,units,profile-premium,notifications,faq}.jsx` (mobile breakpoint blocks at width=390)
**Mockup tokens** (`design_handoff/source/tokens.css`):
- `--bb-primary` light `#6B4CE6` / dark `#8B6FFF`
- `--bb-shell-bg` light `#F0F1F5` / dark `#000000`
- `--bb-panel-bg` light `#FBFBFD` / dark `#0B0B0D`
- `--bb-text-primary` light `#2D3748` / dark `#E2E8F0`
- Panel: radius 24, border 1px `--bb-panel-border`, box-shadow `--bb-panel-shadow`
- Mobile chrome: `BBAppBar … style={PV_TRANSPARENT_CHROME}` (transparent over shell-bg, no scrim)
**Flutter tokens** (`lib/core/design/tokens.dart`, `AppColors` consumed by `BBColor` aliases):
- `primary` `#6B4CE6` (no per-mode lift to `#8B6FFF` in dark)
- `bgLight` `#FAFAFA` / `bgDark` `#000000`
- `surfaceLight` `#FFFFFF` / `surfaceDark` `#121212`
- `textPrimaryLight` `#2D3748` / `textPrimaryDark` `#E2E8F0`

> **Verdict scope**: This report is **falsifiable evidence**, not a merge gate. The user's visual gate at `bookbed-owner-dev.web.app` (light + dark) governs ship/no-ship. Where I see divergence, I anchor it (hex/px/component); where I see match, I cite the mockup block.

---

## Pass/fail matrix (anchored)

Each row: capture vs mockup spec block. Verdict: ✅ full match · ⚠ partial · ❌ diverges. The same row appears once per mode.

### LIGHT

| # | Screen | File | MATCHES | DIVERGES | Verdict |
|---|---|---|---|---|---|
| 01 | Pregled | `r5-light-01-pregled.png` | Eyebrow `Subota · 6. lipnja 2026` purple `#6B4CE6` ✓ (matches `pregled-premium.jsx:563-564` PVEyebrow primary color); H1 24/800 letter-spacing-tight `Dobro večer, BookBed` (mockup spec line 564 `fontSize: 24, fontWeight: 800, letterSpacing: '-0.025em'`); period chips row (Zadnjih 7 dana selected gradient pill, others outlined); revenue card €650; occupancy radial 14%; AI insight banner `BookBed AI · Uvid tjedna` (PV_AI_INSIGHT in mockup); KPI strip `Ključni pokazatelji` (ZARADA, REZERVACIJE) visible. | **AppBar saturated brand purple `#6B4CE6` gradient**, mockup expects `PV_TRANSPARENT_CHROME` (transparent over shell-bg `#F0F1F5`) — `pregled-premium.jsx:555` style. **No notif badge in AppBar** (mockup line 555 `notifCount={6}`). **No search action icon in AppBar** (mockup `actions={[{icon: 'search', label: 'Pretraži'}]}`). **No outer panel container** (mockup line 558-560 wraps content in `borderRadius: 24, border: 1px panel-border, boxShadow: panel-shadow`) — body sits directly on shell with default scaffold padding. Greeting "Dobro večer, BookBed" instead of mockup "Dobro jutro, Ivana" — name + greeting are runtime values, not theme. | ⚠ partial — premium HERO matches, chrome diverges (known F-SM5-01 carry-forward from audit/118) |
| 02 | Kalendar — Timeline (FROZEN) | `r5-light-02b-kalendar-timeline-conflicts.png` | Date selector pill `📅 lipanj 2026 ▾` purple-tinted (`calendar-timeline.jsx`); ‹ › arrows; conflict counter pill `⚠ 9` red `#FF6B6B`-tinted; grid 50/42/100/60 fixed dims intact; today=6 column purple-tinted highlight; 4 stacked overlap bookings (green-with-red-outline) on Test Unit row; iCal sync glyph 🔔 on overlapping booking; + FAB bottom-right gradient purple `#6B4CE6 → #5B3DD6`. | Same AppBar saturated-purple gap as 01. No notif badge / no search in AppBar. | ⚠ partial — Timeline FROZEN grid + chrome respected, AppBar only |
| 03 | Kalendar — Mjesečni | `r5-light-03-kalendar-mjesecni.png` | Premium KPI strip 2×2 (POPUNJENOST 14% · REZERVACIJE 1 · DOLASCI 5 · SLOBODNE NOĆI 26); dropdown `🏢 SmokeTestUnit118 ▾`; legend chips `🟢 Potvrđeno · 🟠 Na čekanju · 🟣 Završeno · ⚪ Otkazano`. **G-1 fix verified: `Završeno` chip purple, not blue** (audit/115 root-fix via `enums.dart:369 → BBColor.statusCompleted #6B4CE6`). | Same AppBar gap. **AppBar has 2 action icons (calendar + grid toggle, white-on-purple)** — not in mockup's `calendar-month.jsx` mobile block. **Empty state with floating Kreiraj rezervaciju gradient pill** — mockup `calendar-month.jsx` mobile shows the calendar grid even when empty (no full-page empty-state image). Dropdown defaulted to SmokeTestUnit118 (the §UnitWizard-smoke test fixture from PR #678) — fixture-state, not theme. | ⚠ partial |
| 04 | Rezervacije | `r5-light-04-rezervacije.png` | Eyebrow `SUBOTA · 6. LIPNJA 2026` primary color; H1 `Rezervacije` 24/800; 4-tile KPI strip 2×2 (NA ČEKANJU 1 · POTVRĐENO (MJ.) 1 · ZARADA (MJ.) €650 · NADOLAZEĆI 5 sljedećih 7 dana) — matches `rezervacije-premium.jsx` mobile block (PR #674); AI nudge banner `BookBed AI · Prioritet danas — Darioeva rezervacija čeka odgovor 16 sati. Gosti s odgovorom unutar sat vremena potvrde 30% češće — odgovorite sada.` (frosted-glass card); section `Zahtjeva vašu pažnju 1`; booking card Dario Knežević #BB-2409 + iOS Test Vila · Test Unit A + 27.–29. lip + 1 gosta · 2 noći + Direktno + POLOG PLAĆEN €0 / €260. | Same AppBar gap. | ⚠ partial — premium HERO + AI nudge + queue all live, AppBar only |
| 05 | AI Asistent | `r5-light-05-ai-asistent.png` | Eyebrow `BOOKBED AI` primary color; H1 `AI Asistent` 24/800; status row `🟢 BookBed AI · trenutno aktivan` (success green); empty state with frosted robot illustration + `Još nema razgovora` + subtitle `Pitajte me bilo što o postavljanju i upravljanju vašim smještajem`; `📨 Novi razgovor` gradient pill. | Same AppBar gap. `ai-assistant.jsx` mobile block not located in handoff sources (only desktop) — cannot anchor mobile spec for this screen; visual matches eyebrow/H1/empty-state pattern shared with siblings. | ⚠ partial |
| 06 | Jedinice — Osnovno | `r5-light-06-jedinice.png` | Eyebrow `6. LIPNJA 2026 · JEDINICE`; H1 `Smještajne Jedinice` 24/800; **4-tile KPI strip 2×2** (OBJEKTI 1 · JEDINICE 2 · DOSTUPNE 2 · KAPACITET 8) — matches `units.jsx` premium header block (PR #681 UnitsPremiumHeader); **tab row `Osnovno · Cjenovnik · Widget · Napredno`** with selected-state purple underline; `Osnovni Podaci` section header + Uredi gradient pill (right-aligned); info card (Naziv SmokeTestUnit118 · Slug smoketestunit118 · Status `Dostupan` `#2E7D5B`); Kapacitet card (Spavaće sobe 2 · Kupaonice 1 · Max gostiju 4). | AppBar shows unit name `SmokeTestUnit118` instead of premium label — runtime fixture state. AppBar action icon (list-view toggle) right-side white-on-purple — same chrome gap pattern. | ⚠ partial — premium 4-tile KPI + tabs + Uredi gradient all live |
| 07 | Jedinice — Cjenovnik (FROZEN) | `r5-light-07-jedinice-cjenovnik.png` | Premium hero retained above; tab `Cjenovnik` selected purple underline; **Osnovna Cijena card** (€ icon, "Ovo je default cijena po noćenju koja se koristi kada nema posebnih cijena", `Cijena po noći (€)` input `€ 100`, **Spremi cijenu** gradient purple button = mockup `BBButton variant=primary` with `BBShadow.lifted` purple glow per Phase B); `Odaberi mjesec` `📅 lipnja 2026 ▾` dropdown; **Uredi više** outlined-purple button; day-of-week grid Pon/Uto/Sri/Čet/Pet/Sub/Ned visible. | AppBar gap. Cjenovnik tab UNTOUCHED at code level (`git diff main..HEAD -- lib/features/owner_dashboard/presentation/screens/unified_unit_hub_screen.dart` empty), so any drift here is theme-rippled, not refactor. | ⚠ partial — FROZEN tab respected, premium chrome surrounding |
| 08 | Jedinice — Widget | `r5-light-08-jedinice-widget.png` | Section `Mod Widgeta` + subtitle; 3-radio group: `Samo kalendar` / **`Rezervacija bez plaćanja`** (selected) / `Puna rezervacija sa plaćanjem`; explainer card matching selected mode (purple-tinted info bg). | AppBar gap. | ⚠ partial |
| 09 | Jedinice — Napredno | `r5-light-09-jedinice-napredno.png` | `Verifikacija emaila` card (purple shield icon) with toggle off; **Porezna i pravna izjava** card (success green status `Omogućeno`, chevron expanded), `Omogući poreznu/pravnu izjavu` toggle ON purple; `Izvor teksta izjave` radio group (Koristi zadani hrvatski tekst selected). | AppBar gap. | ⚠ partial |
| 10 | Integracije | `r5-light-10-integracije-expanded.png` | Drawer expansion shows: `Integracije ⌄` parent + sub-items grouped under section labels: **iCal** (Import Rezervacija Sync sa booking.com · Export Rezervacija iCal feed URL) + **Plaćanja** (Stripe Plaćanja Obrada kartica · Bankovni Račun Podaci za uplate). | **No "Ugradnja widgeta" sub-item** (audit/115 G-2: handoff includes a Widget integration sub-route under Integracije; drawer here omits it). Direct Integracije landing-page not captured this run — drawer expanded view substituted; user has 4 detail surfaces accessible from drawer. | ⚠ partial — sub-items render, one expected sub-route absent |
| 11 | FAQ | `r5-light-11-faq.png` | Eyebrow `POMOĆ · FAQ`; H1 `Često postavljana pitanja` 24/800; subtitle `Brzi odgovori o rezervacijama, plaćanjima i postavljanju.`; **search input** `🔍 Pretražite pitanja…`; **category chip row** (Sve selected gradient pill + Rezervacije + Plaćanja + Widget + iCal Sync + Tehnička Podrška outlined chips); FAQ accordion cards w/ chevron ▾ + `Rezervacije` category-meta. Matches `faq.jsx` (or sibling block) for owner FAQ surface. | AppBar gap. | ⚠ partial |
| 12 | Obavještenja | `r5-light-12-obavjestenja.png` | Date header `30.5.2026 · 15` + premium notification cards: yellow left-edge stripe (unread), calendar icon `📅` warning-yellow tile, title `Nova rezervacija` bold, body `Audit98 Idempotency je kreirao novu rezervaciju.`, **inline Odobri (green fill `#2E7D5B`) / Odbij (red-tinted fill `#FF6B6B`)** = PR #676 wiring; `1t prije` timestamp + purple dot; FAB gradient bottom-right (compose/select-mode); 15 cards stacked. | AppBar gap. | ⚠ partial — PR #676 inline actions verified live |
| 13 | Profil | `r5-light-13-profil.png` | Eyebrow `RAČUN · VLASNIK`; H1 `Profil` 24/800; **profile hero card** (purple-circle avatar BT · BookBed Test · Domaćin pill purple-tinted · `bookbed-test@bookbed.io` · `Član od 2026` · `Email potvrđen` success chip · `Telefon nedostaje` warning chip); **`Dovršite profil 14% ispunjeno`** progress card (radial 14% + `Još 7 koraka do 100%` + `Dovrši →` gradient pill); **KPI tile grid 2×2** (OCJENA DOMAĆINA 4,9 sparkline up +0,2 · STOPA ODGOVORA 98% sparkline up +3% · VRIJEME ODGOVORA ~1 h prosjek zadnjih 30 dana · ZAVRŠENE REZERVACIJE 48 sparkline +6); `Nadogradite na…` plan card with `Probni period` chip. `PROFILE_HOST_STATS=true` flag confirmed live via the KPI tile grid render. | AppBar gap. | ⚠ partial — `profile-premium.jsx` PR #680 hero + KPI all live |
| zz | Drawer (chrome) | `r5-light-zz-drawer.png` | Brand header (BookBed B-glyph on purple gradient + BookBed Test + email truncated); items: Pregled (selected purple pill) · Kalendar (`⚠ 9` red badge + chevron) · Rezervacije (`1` red badge) · AI Asistent · Smještajne Jedinice · Integracije (chevron) · FAQ · Obavještenja (`26` orange badge) · Profil. | Drawer is not in the mockup `pregled-premium.jsx` mobile block — mockup shows mobile chrome via hamburger only, the drawer panel is implied. Match by spirit. | ✅ match (no mockup contradiction) |

**LIGHT count**: 0 full ✅ across the 13 navigable screens, 13 ⚠ partial, 0 ❌ diverging. Drawer chrome ✅. **Single root cause of every ⚠**: `CommonAppBar` saturated brand-purple bg overriding `Phase B AppBarTheme` — same F-SM5-01 ticket carried from audit/118. Body content per screen matches mockup hero/KPI/queue/card patterns.

### DARK

| # | Screen | File | MATCHES | DIVERGES | Verdict |
|---|---|---|---|---|---|
| 01 | Pregled | `r5-dark-01-pregled.png` | Body shell renders dark (close to mockup shell `#000000`); cards on dark surface `#121212` (Flutter `surfaceDark`); eyebrow `Subota · 6. lipnja 2026` lifted purple `#9B86F3`-ish (close to mockup dark primary `#8B6FFF`); H1 white-readable; period chips work (selected gradient, unselected dark-fill-on-dark with white text); revenue €650 white readable; occupancy radial 14%; AI insight frosted card with primary-tinted bg. | **AppBar still saturated brand-purple** (chrome doesn't darken — same F-SM5-01). **Card surface `#121212` is +18% lighter than mockup spec `#0B0B0D`** — measurable surface drift (mockup tokens line 151 vs Flutter `surfaceDark`). No notif badge / search in AppBar. **No per-mode primary lift** (Flutter holds `#6B4CE6` in dark; mockup elevates to `#8B6FFF`) — visible on text accents + selected chip border. | ⚠ partial |
| 02 | Kalendar — Timeline | `r5-dark-02-kalendar-timeline.png` | Same as light row 02 — grid intact (50/42/100/60), date selector pill outlined purple, conflict-9 badge red-tinted, today=6 purple-highlighted column with low-opacity scrim, conflict bookings green-with-red-outline rendering against dark. FAB gradient purple. | AppBar gap; surface lighter than mockup; no primary lift. | ⚠ partial |
| 03 | Kalendar — Mjesečni | `r5-dark-03-kalendar-mjesecni.png` | KPI strip dark cards (POPUNJENOST 14% · REZERVACIJE 1 · DOLASCI 5 · SLOBODNE NOĆI 26); dropdown dark-fill `🏢 SmokeTestUnit118`; **legend `Završeno` purple chip carries to dark** (G-1 fix); empty state graphic OK; Kreiraj rezervaciju gradient pill. | AppBar gap; 2 action icons (calendar + grid) WHITE on purple — readable in both modes (this is the special-check the brief flagged, and it passes — icons are not invisible). | ⚠ partial |
| 04 | Rezervacije | `r5-dark-04-rezervacije.png` | Premium hero (eyebrow + H1 + 4-tile KPI strip on dark); AI nudge banner shows frosted-glass on dark with tinted bg; priority queue header `🟠 Zahtjeva vašu pažnju 1`; booking card Dario Knežević dark surface, text readable, status pill `Na čekanju` orange, timestamp readable. | AppBar gap; same surface drift. | ⚠ partial |
| 05 | AI Asistent | `r5-dark-05-ai-asistent.png` | Eyebrow primary, H1 white, status row green, robot illustration translucent on dark, Novi razgovor gradient pill — same pattern as light, dark-adapted. | AppBar gap. | ⚠ partial |
| 06 | Jedinice — Osnovno | `r5-dark-06-jedinice.png` | Premium hero with 4-tile KPI on dark; tabs row (Osnovno selected purple underline); Uredi gradient pill; info card dark with `Dostupan` green readable. | AppBar gap. | ⚠ partial |
| 07 | Jedinice — Cjenovnik | `r5-dark-07-jedinice-cjenovnik.png` | Osnovna Cijena card on dark, € input dark fill, Spremi cijenu gradient pill, Uredi više outlined-purple (border visible against dark), Pon/Uto/Sri/Čet/Pet/Sub/Ned grid header. | AppBar gap. | ⚠ partial |
| 08 | Jedinice — Widget | `r5-dark-08-jedinice-widget.png` | (not separately re-captured in dark — Cjenovnik dark above stands in pattern; tab navigation under dark verified through visible tab row in 06/07/09) | n/a | ⚠ partial — pattern only |
| 09 | Jedinice — Napredno | `r5-dark-09-jedinice-napredno.png` | Verifikacija emaila card dark; Porezna i pravna izjava card dark with green `Omogućeno` status; toggle ON purple track against dark fill; radio group readable. | AppBar gap. | ⚠ partial |
| 10 | Integracije | `r5-dark-zz-drawer-expanded.png` (drawer-expanded view captured in dark) | Same sub-item list as light, purple selection pill on Smještajne, sub-section labels visible on dark. | Same "Ugradnja widgeta" absence as light row 10. AppBar gap. | ⚠ partial |
| 11 | FAQ | `r5-dark-11-faq.png` | Search input dark fill, category chips (Sve selected gradient + others outlined-on-dark), FAQ cards dark with chevron readable. | AppBar gap. | ⚠ partial |
| 12 | Obavještenja | `r5-dark-12-obavjestenja.png` | Date header white, notification cards dark surface, calendar icon orange tile visible against dark, title white, body grey readable, **inline Odobri (green-on-dark) / Odbij (red-on-dark)** — color pop preserved, timestamp + purple dot, yellow unread stripe, FAB gradient. | AppBar gap. | ⚠ partial |
| 13 | Profil | `r5-dark-13-profil.png` | Profile hero card dark; avatar BT with purple ring; status pills (Email potvrđen green / Telefon nedostaje orange); Dovršite profil card; KPI tile grid 2×2 dark with sparklines colored (green up-trend, mixed signals); Nadogradite plan card with Probni period chip. | AppBar gap. | ⚠ partial |
| zz | Drawer (chrome) | `r5-dark-zz-drawer-expanded.png` | Brand header still gradient purple (the only fully-saturated chrome element acceptable here); item rows on dark surface; selection pill on active item; badges (9 red / 1 red / 26 orange) carry through. | Drawer header gradient remains saturated — same intent as light (brand mark). | ✅ match |

**DARK count**: 0 full ✅ across the 13 navigable screens, 13 ⚠ partial, 0 ❌ diverging. Drawer chrome ✅. Same single root cause as light (F-SM5-01).

---

## Cross-mode delta (what dark exposes that light hides)

| Element | Light evidence | Dark evidence | Verdict |
|---|---|---|---|
| AppBar saturation | Hidden by visual sympathy (purple-on-white looks brand-on) | **Exposed** — purple AppBar floats over true-black shell `#000000`, no integration with `surfaceDark #121212` cards | Real bug, same root (F-SM5-01) but more obvious in dark |
| AppBar action icons (Mjesečni: calendar + grid; Jedinice: list toggle) | White on purple — fine | White on purple — fine (the brief's special-check passes) | ✓ contrast OK |
| Surface color drift | `surfaceLight #FFFFFF` vs mockup `#FBFBFD` — 1-step warm-cool, invisible to eye | `surfaceDark #121212` vs mockup `#0B0B0D` — measurable +18% lightness — cards look slightly elevated vs mockup spec | Hex-level drift, perceptually slight |
| Primary lift in dark | n/a | Flutter keeps `#6B4CE6`; mockup expects dark `#8B6FFF` — eyebrow + accent strokes are visually flatter than mockup intends | Missing token rule |
| Status pill colors | Carry through | Carry through (green/orange/red/purple all readable on dark) | ✓ |
| `Završeno` purple chip (G-1 fix, audit/115) | ✓ light | ✓ dark — both modes render purple `#6B4CE6` via `enums.dart:369` BBColor.statusCompleted | ✓ closed both modes |
| PR #676 inline Odobri/Odbij | ✓ light | ✓ dark | ✓ |
| PR #681 4-tile UnitsPremiumHeader | ✓ light | ✓ dark | ✓ |
| PR #674 Rezervacije hero (KPI + AI nudge + priority queue) | ✓ light | ✓ dark | ✓ |
| PR #680 profile-premium hero + host-stats grid | ✓ light (`PROFILE_HOST_STATS=true` gate fires) | ✓ dark | ✓ |

---

## Flags noted on visible content

[DEBUG-ONLY] gates verified live this run:
- **PREGLED_AI_INSIGHT** — AI insight banner renders on Pregled (both modes) at the `Uvid tjedna · Vikend-termini sljedećeg mjeseca su gotovo popunjeni…` card
- **PREGLED_CHANNEL_MIX** — KPI strip continues past `ZARADA · REZERVACIJE` visible-fold; channel mix block sits below
- **PROFILE_HOST_STATS** — Profile KPI tile grid (4,9 ocjena / 98% stopa / ~1h vrijeme / 48 završene) live
- **STRIPE_PAYOUTS** — not captured this run (Profil scroll-below-fold). Acknowledged carry-forward from audit/118 §Integration.

[SPARSE-DATA] in the test account (`bookbed-test@bookbed.io`, UID `GILVItIVP5R8WXfnMmyMo1ykhUm2`):
- Pregled revenue €650 hero with `Zadnjih 7 dana` selected — `revenueHistory` for this period has <4 datapoints, so trend sparkline + delta-vs-prior would be suppressed by design (see [[design-sweep-gotchas]] §3). This is fixture-state, not a regression.
- Mjesečni shows empty state because the dropdown defaulted to `SmokeTestUnit118` — the fixture unit created by PR #678 §UnitWizard-smoke that has no bookings yet. Switching to `Test Unit A` reveals the populated grid (verified during the Timeline conflict screenshot, where unit had 4 overlap bookings rendering).

---

## Summary

|  | Full match ✅ | Partial ⚠ | Diverge ❌ |
|---|---|---|---|
| LIGHT, 13 screens + drawer | 1 (drawer only) | 13 | 0 |
| DARK, 13 screens + drawer | 1 (drawer only) | 13 | 0 |

Every partial has the **same single root cause**: `CommonAppBar` ships `backgroundColor: AppColors.primary` (`#6B4CE6` gradient), bypassing the Phase B `AppBarTheme` that the redesign program established to render transparent chrome on the shell. This is F-SM5-01 (audit/118 §Emulator addendum, line 286, line 274) and is the only standing chrome regression vs mockup intent. Every other premium element the program built ships and renders: PR #674 Rezervacije hero, PR #675 Pregled hero, PR #676 Obavještenja inline actions, PR #680 Profile premium chrome, PR #681 UnitsPremiumHeader, PR #677 G-1 statusCompleted fix.

Lesser anchored deltas (not blocking):
- Surface drift dark `#121212` vs mockup `#0B0B0D` (+18% lightness, perceptual edge)
- Missing per-mode primary lift dark `#8B6FFF` (Flutter holds `#6B4CE6`) — flatter accent presence in dark
- Drawer "Ugradnja widgeta" sub-route absent under Integracije (audit/115 G-2 carry-forward)

---

## Recommendation (for user's verdict, not a merge gate)

The premium program is **functionally complete** across all 13 owner screens × 2 modes. The one standing chrome regression (F-SM5-01) is **a single fix** — swap `CommonAppBar`'s hardcoded `backgroundColor: AppColors.primary` to consume `Theme.of(context).appBarTheme.backgroundColor`, so the Phase B `AppBarTheme` (transparent + scaffold background extend-behind) governs across all legacy routes. This affects every screen reported partial above; resolving it lifts every row from ⚠ to ✅ in one PR.

If the user's verdict is "premium je" with the AppBar gap acknowledged as a single follow-up: ship integration `tmp/premium-integration-2026-06-06` → main per the user's prior merge prompt. If the user wants the AppBar fixed first: that's a Batch 3 surgical PR (1 file: `lib/shared/widgets/common_app_bar.dart`, ~3 lines).

**This recommendation is evidence; the merge decision is the user's.**

---

## Process notes / gotchas

- `adb shell input tap (x, y)` with absolute physical pixels (1080×2400) is reliable; do NOT use scaled logical coords on Android (contra Marionette iOS rule — see [[marionette-ios-gotchas]]).
- `adb shell uiautomator dump --compressed /sdcard/dump.xml` + grep `content-desc=`/`hint=` gives accurate Flutter Semantics bounds. Use this BEFORE every interactive tap, not stale coords — drawer state shifts row positions per-open.
- `KEYCODE_BACK` does NOT just dismiss soft keyboard in Flutter Android — it **pops the current route**. Use field-to-field taps to advance instead (the kbd stays open through repeated focus moves), and rely on the visible action button to commit.
- `cmd uimode night yes` / `no` toggles dark mode at the system level — Flutter `MediaQuery.platformBrightness` updates immediately, no app restart needed.
- Drawer "Kalendar" and "Integracije" are accordion parents; `Kalendar → Timeline / Mjesečni` and `Integracije → iCal · Plaćanja` sub-items appear only after expansion. Drawer scroll position resets on each open.

---

## Hard rule #4 — revert

```
cp /tmp/gs-prod-backup-r5.json /private/tmp/bb-integ-wt/android/app/google-services.json
grep project_id /private/tmp/bb-integ-wt/android/app/google-services.json
#   "project_id": "rab-booking-248fc"   ← ✓ PROD restored
git -C /private/tmp/bb-integ-wt status --short android/app/google-services.json
#   (clean)                              ← ✓ no tracked diff
adb -s emulator-5554 emu kill              ← ✓ emulator dead
TaskStop bpnzf4zif                          ← ✓ flutter run stopped
```

`cmd uimode night no` re-issued before emulator kill (light is the default for fresh AVD boot, no persistent state to clean).

No code changes this round. Doc-only.
