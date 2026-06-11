# Audit 124 — Owner page-by-page design fidelity vs handoff (2026-06-11)

**Scope:** per user request — page-by-page audit of all 16 owner pages + drawer + app bar against `design_handoff` (jsx + `source/tokens.css` ground truth), every section + background, light + dark, **fix-as-you-go**. Method: per-page Explore delta-agents (spec extraction + impl mapping, killing already-fixed/false-positive findings from audit/114/115/120/121) + my code fixes + live iOS-sim verify (Marionette, bookbed-dev, light+dark). Builds on audit/121 (token layer) — this pass is structural + residual color.

## Fixed this session (PR branch `design/124-owner-page-fidelity`)

### 01 Pregled (`dashboard_overview_tab.dart` + provider + model) — `cd108f21`
- **Nadolazeći dolasci card (P1)**: real next-14-days arrivals — `UpcomingArrival` model on `UnifiedDashboardData`, built in provider from `_queryUpcomingCheckIns` (window 7→14d, property_id recovered from doc path), names from cached units/properties, soonest-first top 4. In-card header (title + "Sljedećih 14 dana" + Kalendar action), replaces the recent-activity section (recent ≠ upcoming semantics).
- **Desktop ≥900 handoff grid (P1)**: hero 3fr + radial/deposits rail 2fr; arrivals 3fr + channel mix 2fr (was single column everywhere).
- **Header row ≥600**: greeting left, period pill + `Nova rezervacija` gradient CTA right (mobile keeps centered pill).
- **Period pill active state (P2)**: surface chip + `BBShadow.sm` on surfaceVariant track (was off-spec primary fill).
- **Hero command**: radial gradient wash behind value + prev-period caption `€X u prethodnom razdoblju · ±€Y` (split-half derivation, diff added to `_deltaVsPrior`).
- **Deposits bar**: surfaceVariant track + success gradient fill (`#2E7D5B→#4FAE7F`, was solid+tint flex hack).
- **Channel mix**: per-channel thin breakdown bars under rows.
- **Removed legacy Prihodi/Rezervacije chart row** — not in handoff; `_RevenueChart` kept only for the welcome-screen preview; `_BookingsChart` deleted.

### 02 Rezervacije — `c44e66f0`
- audit/115 G-3 ("premium layout missing") **STALE** — premium header (KPI strip + AI nudge + pending queue + ledger bookends) shipped via `73c56cf8`/`2ea0258f`. Verified live.
- Tab bar: dots via `colorOf(context)` (dark lifts), **Završene tab added** (handoff RZP order; new l10n `bookingsTabCompleted` en+hr), imported tab dot = `statusImported` (was grey + cloud icon).
- Table source badges: `Colors.orange/red/green/grey` + `authSecondary` → channel tones (booking=info, airbnb=error, widget=primary, ical=statusImported, manual=neutral).
- Booking card header: grey band → `surfaceVariant`; imported badge grey solid → statusImported tint+text.
- Imported list: conflict border/badge red shades → error token; notes icon amber → warning/statusPending.

### 03 Timeline + 04 Mjesečni + shared — `732d3f06`
- Day headers: **weekday eyebrow** (Pon..Ned) above number per handoff, weekend tone = tertiary token (was hardcoded `#E67E22`), today tint 6%/8% (was 20%) — all inside FROZEN 60px header band (compact metrics, no overflow).
- Header band: solid surfaceVariant (was transparent over page gradient).
- Status legend: `colorOf(context)` + **Uvezene** item (5/5 statuses).
- `CalendarCellColors` weekend: purple tints → handoff golden composites (`#FFFBF6` light / `#29262A` dark = rgba(255,184,77,.05) over base); today-highlight defaults theme-split 6/8%.
- Mjesečni KPI tile tints per handoff tone map (primary 6%, tertiary 16%, success/info 12%; was uniform 14%).

### 11 AI Asistent — `732d3f06`
- 8 static `isDark ? BBColor.surfaceVarDark : BBColor.surface(Var)Light` picks → `BBColor.of(context)` theme-resolved; dark assistant bubbles/avatar/suggestion tiles were on **surfaceVariant** where spec = **surface** (#121212).

### 15 Login — `8b6f7a9b`
- **Desktop split ≥1200 (P1)**: left brand pitch panel (logo+wordmark, OWNER APLIKACIJA eyebrow, 48px headline "Sve vaše rezervacije. / Jedno mjesto.", sync copy, 3 pitch stats, legal footer → Uvjeti/Privatnost routes) + right fixed 560px glass card, per `auth.jsx` AuthLoginDesktop. Mobile/tablet unchanged.

## Verified CLEAN (agents + live sim, no changes needed)
- **05 Profil / 16 Uredi profil**: structure matches `profile-premium.jsx` (4-group desktop grid = premium variant), tokens clean both themes (glass tokens byte-checked).
- **06 Units hub / 07 Booking detail / 08 Pretplata**: clean; photo-scrim + `rd.heroGradient` white-on-gradient confirmed deliberate (audit/121 false-positive list upheld). Cjenovnik tab untouched (FROZEN).
- **09 Isplate / 10 iCal / 12 Obavještenja**: clean; audit/114 R3 + /121 fixes verified landed.
- **13 FAQ**: clean.
- **Chrome**: drawer (shell bg, primary selected pill, lifted dark) + app bar (shellBg both themes) verified live light+dark.

## Verification
- `flutter analyze lib/` → 0 errors / 0 warnings (infos = pre-existing baseline)
- `flutter test` full suite → **1402 pass**
- Live iOS sim (bookbed-dev, debug, Marionette): Pregled light+dark full scroll (arrivals real data "Pon 15 · Smoke Test · Potvrđeno", deposits €1890 na dolasku, channel bars), Rezervacije dark+light (6 tabs incl. Završene/Uvezene dots, premium header, Završene filter functional), Timeline dark+light (weekday eyebrows, golden weekends, today circle+tint, 5-item legend), Mjesečni dark, Profil light+dark, drawer light+dark. Theme restored to Sustavna, plist restored to PROD.
- Gotcha re-confirmed: Marionette `hot_reload` does NOT recompile changed sources (reassemble-only) — edits made after `flutter run` launch need a full re-run; weekday-eyebrow "missing" was a stale-kernel artifact.

## Known residuals (deliberate / product-scope, not styling)
- **14 Embed guide**: handoff `EmbCodeCard` mode tabs + `EmbPreview` + `EmbCustomize` panels not present — implementation deliberately routes customization to Widget settings screens (audit/121); colors token-true. Product call, not drift.
- **Pregled AI insight + Rezervacije AI nudge**: kDebug/define-gated until a real BookBed AI provider exists (audit/114 decision upheld).
- **PROSJEČNA OCJENA** KPI renders `—` until a reviews feature exists (audit/120/121).
- **Hero dual-series chart**: handoff shows current+previous ghost line; impl uses single sparkline + prev-period caption (provider has no prior-period series; caption covers the comparison).
- **Tab count badges** (handoff RZP tabs show per-status counts): needs per-status count providers; not wired this pass.
- Page background stays `context.gradients.pageBackground` (user-mandated TIP 1 diagonal gradient) vs handoff flat `--bb-bg` — per user's standing instruction, not drift.
