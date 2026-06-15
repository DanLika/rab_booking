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

## Desktop verification (continue pass, same day)

- **Login split**: a layout bug shipped in the first cut — `Row(crossAxisAlignment: stretch)` inside the keyboard-aware `SingleChildScrollView` forces infinite height; split never rendered. Fixed (pitch panel pins viewport height via SizedBox; stats Row → Wrap) + 2 regression tests (`test/features/auth/login_desktop_split_test.dart`: ≥1200 split, <1200 centered). Verified live on Chrome 1440×900: pitch panel (logo/eyebrow/headline/copy/stats/footer) + 560px card per `auth.jsx`.
- **Pregled desktop grid**: verified live at 1440 — header row (greeting + period pill + Nova rezervacija CTA), hero 3fr + radial/deposits rail 2fr, KPI 4-across, arrivals 3fr + channels 2fr.
- **Tooling gotchas burned this pass**: (1) `flutter run -d chrome/web-server` + MCP browser serves **stale DDC modules from browser cache** — verify with `fetch('/main.dart.js')` content probe and reload with `ignoreCache:true` before trusting a "bug"; (2) CanvasKit text input on web: DOM `value=` + InputEvent does NOT reach the Flutter controller — focus the field and use `document.execCommand('insertText', …)`.
- **CI**: firebase-tools dropped Java <21 → `Validate Firestore Rules` failed repo-wide; fixed via PR #729 (Java 17→21, merged). Workflow-editing PRs get a restricted token (`Resource not accessible by integration` in paths-filter) — expected, not a regression. PR #728's post-merge check run hit instant-fail runners (2s, all jobs) — rerun when convenient; not re-triggered to save Actions minutes per user instruction.

## Known residuals (deliberate / product-scope, not styling)
- **14 Embed guide**: handoff `EmbCodeCard` mode tabs + `EmbPreview` + `EmbCustomize` panels not present — implementation deliberately routes customization to Widget settings screens (audit/121); colors token-true. Product call, not drift.
- **Pregled AI insight + Rezervacije AI nudge**: kDebug/define-gated until a real BookBed AI provider exists (audit/114 decision upheld).
- **PROSJEČNA OCJENA** KPI renders `—` until a reviews feature exists (audit/120/121).
- **Hero dual-series chart**: handoff shows current+previous ghost line; impl uses single sparkline + prev-period caption (provider has no prior-period series; caption covers the comparison).
- **Tab count badges** (handoff RZP tabs show per-status counts): needs per-status count providers; not wired this pass.
- **Page background (2026-06-13, PR fix/fidelity-pagebg):** `pageBackground` token = user-mandated TIP 1 (2 opaque colors, stops `[0.0, 0.3]`, topLeft → bottomRight — mirror of the section's topRight → bottomLeft; light `#ECEDF2 → #FFFFFF`, dark `#1A1A1A → #2D2D2D`) vs handoff flat `--bb-bg`. Restores the diagonal after audit/121 flattened the token to `#F0F1F5`/`#000` — the "TIP 1 diagonal" claim on this line is now true in code. Per user's standing instruction, NOT drift, do NOT revert to flat.
- **Sections too (2026-06-12, PR #730):** `sectionBackground` token = user-mandated TIP 1 (2 opaque colors, stops `[0.0, 0.3]`, topRight → bottomLeft; light `#ECEDF2 → #FFFFFF`, dark `#1A1A1A → #2D2D2D`) vs handoff flat `--bb-panel-bg` — NOT drift, do NOT revert to flat. Covers Jedinice endDrawer + desktop master panel + Cjenovnik sections (Osnovna cijena / bulk-edit header / calendar grid) + all dialog content surfaces on the token.

## Rezervacije lean ledger rebuild + gate-fix (2026-06-15, `420b48ed`)

Follow-up to §02 (which token-fixed the *old* card list). This pass replaces the booking-list **structure** with the handoff `rezervacije-premium.jsx` RZPLedger, single atomic commit direct on `main`.

- **New `bookings_ledger.dart`** (pure/testable, consumes shared `Bb*` only): desktop 7-col grid table (Gost/Objekt/Termin/Plaćanje/Iznos/Status/chevron) + tablet/mobile compact rows (RZPMobileRow), inline payment-progress cell, `Prikazano X` footer. `BookingsLedgerEntry` normalizes `OwnerBooking` + iCal events (imported = read-only, `—` payment/amount, **no detail route → no chevron**). Replaces feature-rich `_BookingCard` + card/table view toggle (responsive auto-switch ~820px body width).
- **Rows read-only** (tap → detail). Daily-driver approve/reject stays in the pending queue (untouched); **complete/cancel re-homed to the detail screen** so the removed inline actions are not stranded. Gating = `detailActionVisibility` (`@visibleForTesting`, **consumed by** `_BDStatusActions.build` — no duplicated logic): confirmed-past→Završi, confirmed-upcoming→Otkaži, in-progress→neither (Poruka/Uredi only), pending→approve/reject. Guarantee: no confirmed booking is action-less.
- **Removed 10 orphan widgets** (`bookings_table_view`, `imported_reservations_list`, 7 `booking_card/*`, `imported_reservation_card`) + dead `BookingsPremiumLedgerFooter` — repo-wide grep zero importers. **−2451 net lines**.
- Overbooking banner preserved (`_OverbookingBanner`, token error tint); Filteri → existing `BookingsFiltersDialog`; **Sortiraj deferred/hidden** (windowed-window sort misleads on amount/status; real server-sort = follow-up). Sync/FAQ token-hygiened (keep layout). 0 hex / 0 raw spacing·radius·fontSize literals in ledger + screen (BB* tokens + named `_k*` consts).
- **Tests:** `bookings_ledger_responsive_test` (overflow, 8 breakpoints × light/dark + empty bodyOverride) + `owner_booking_detail_actions_test` (gate-fix gating, 4 states). `flutter analyze` 0 net-new · full `flutter test` **1443 pass** · `build web --no-tree-shake-icons` clean · scope-check = only Rezervacije + detail + 2 tests, no shared/FROZEN.
- **Dev smoke (Android Impeller, Marionette/adb, ref-verified):** gate-fix **4/4 PASS** — Ivan `#BB-SMOKE-02` upcoming→Otkaži · Luka `#BB-SMOKE-03` past→Završi · Marko `#BB-SMOKE-04` in-progress→neither · Petra `#BB-SMOKE-01` pending→approve→Potvrđeno end-to-end. Seed `scripts/seed-rezervacije-smoke-dev.js` (20 bookings + 2 iCal state-matrix; `--delete` wipes). ⚠ dev test-account now holds 3 seed generations with colliding guest names + a global €520 dup → lean row shows no `#ref` (per handoff), so smoke taps by **unique € amount** + verifies detail `#BB-SMOKE-NN` ref. A one-time dev-data reset would restore tap-by-name safety.
- **Deferred:** owner PROD deploy (batch with Pregled `07a9caf7`, awaiting GO); booking **detail screen = its own future fidelity pass** (mixed hygiene — gate-fix additions token-clean, rest retains pre-existing `Color(0x…)`/spacing per CLAUDE.md no-in-place-codemod); live web/iOS phone eyeball.
