# Owner mobile design QA — 2026-06-05

Scope: live walkthrough of the BookBed Owner Flutter app on Android (Pixel_8 emulator), `lib/main_dev.dart` → `bookbed-dev` (project_id `bookbed-dev`). Driven via Marionette MCP. Read-only — `lib/**`, FROZEN regions, rules untouched. PROD `google-services.json` restored at end (see §Revert).

Fidelity reference: `design_handoff/source/*.jsx` + `design_handoff/screens/NN-owner.png` (Premium variant).

## Environment

| Field | Value |
|---|---|
| Branch | `main` (clean) |
| Entry point | `lib/main_dev.dart` |
| Firebase project | `bookbed-dev` (asserted at boot via `expectedProjectId` in `lib/main_dev.dart:43-48`) |
| Device | Pixel_8 emulator, 1080×2400, Android 16 system image |
| Build | `flutter run --debug` — succeeds on `firebase_storage: ^13.0.6` (cf. [[android-debug-build-firebase-storage-13]]) |
| Login | `bookbed-test@bookbed.io` (UID `GILVItIVP5R8WXfnMmyMo1ykhUm2`) per [[test-account]] |
| Screenshot dir | `~/bookbed-design-qa/` |

## Sweep table — owner mobile screens vs handoff

Migrated = chrome rebuilt against Bb* primitives/AppBar/tokens. Fidelity is a coarse "how close does mobile match handoff Mobile/Desktop reference, accepting mobile compression of the Desktop layout."

| # | Screen | Handoff source | Migrated? | Fidelity | Capture | Deltas |
|---|---|---|---|---|---|---|
| 01 | Prijava (Login) — pre-auth | `auth.jsx`, `screens/15-owner.png` | ✅ | ~85% | `p01-pregled-…` → see `01-login.png` | Lavender shell, `BbInput(iconLeft)` rows, `BbButton` primary CTA + outline Google CTA, "Zapamti me" + "Zaboravili lozinku?" pair. Handoff calls for **glass card on gradient (hero-only)**; current is solid `panelBg` floating panel. Glass effect missing — P2. |
| 02 | Drawer / nav | `primitives.jsx` `BBSidebar` + chrome | ✅ | ~80% | `p02-drawer.png`, `p11-drawer-integracije.png` | Mobile = hamburger+drawer per handoff. Purple hero header + circle avatar. Items use raised pill w/ icon tile, active state lavender tint + purple glow. Groups (iCal, Plaćanja) use **muted purple eyebrow labels** — matches handoff. Drawer scroll is brittle: items below Profil clip on small screens (no internal scroll-event reach during this run; collapse Integracije workaround needed). P3. |
| 03 | Pregled (Dashboard) | `pregled-premium.jsx`, `screens/01-owner.png` | ✅ partial | ~55% | `p01-pregled.png` | AppBar + greeting card + date-range chips + 4 KPI tiles + recent-activity list rendered. **Missing vs handoff:** north-star revenue count-up, AI insight card, dual-series chart, occupancy radial, channel mix, colored KPI sparklines, "next guest" hero chip. Current = 4 KPI + activity. Heaviest Pregled gap. P1 candidate for next dispatch. |
| 04 | Kalendar — Timeline (FROZEN grid) | `calendar-timeline.jsx` + `calendar-premium.jsx`, `screens/03-owner.png` | ✅ chrome | ~80% | `p03-kalendar.png`, `p04-kalendar-timeline.png` | Premium chrome (purple AppBar, "lipanj 2026" period chip w/ chevrons, alert badge, FAB) on top of FROZEN parallelogram grid. Conflict overlay (red-bordered green blocks w/ ⚠ icon) renders. FROZEN cell dims `50/42/100/60` per `lib/features/calendar/.../timeline_dimensions.dart`. No regression. |
| 05 | Kalendar — Mjesečni | `calendar-month.jsx`, `screens/04-owner.png` | ✅ | ~75% | `p05-kalendar-month.png` | Migrated: unit selector dropdown + status legend row + Monday-start grid + spanning Google-Calendar-style bars + day badges. **Drift:** legend "Završeno" rendered **blue** (`#4A90D9` = imported per handoff) — should be **purple** (`#6B4CE6 = completed`). Rezervacije card status pill correctly purple for "Završeno" → legend is the divergent surface. Confirms a color-token mapping bug on the mjesečni legend. **P2**. |
| 06 | Rezervacije | `rezervacije-premium.jsx`, `screens/02-owner.png` | ✅ partial | ~65% | `p06-rezervacije.png` | KPI strip → Filteri card + conflict warning + Napredno filtriranje row + status filter chips + booking card. **Missing vs handoff:** KPI strip across top, AI nudge banner, pending priority queue w/ inline approve/reject + payment progress, bookings ledger table. Current = filter-first list. **P1 candidate** alongside Pregled. Status pill "Završeno" correctly purple — confirms #05 is the broken surface. |
| 07 | Smještajne Jedinice — Osnovno | `units.jsx`, `screens/06-owner.png` | ✅ | ~85% | `p07-units.png` | 4-tab strip (Osnovno/Cjenovnik/Widget/Napredno) w/ purple underlined indicator, Bb* card chrome (icon tile + underlined h3), Status "Dostupan" green token, `BbButton(primary, iconLeft:edit) Uredi`, Cijena card w/ €120/€130 in purple. Right-edge AppBar icon = list (back to unit list). Migrated cleanly. |
| 08 | Cjenovnik (FROZEN) | `units.jsx` cijenovnik panel | ✅ chrome | n/a (FROZEN) | `p08-cjenovnik-frozen.png` | Chrome migrated (AppBar, card shells, primary CTA) while internal pricing grid + Pon/Uto/…/Ned headers + €120/€130 chips + weekend amber-tint cells preserved. Per CLAUDE.md "NIKADA NE MIJENJAJ — Cjenovnik tab". No regression. |
| 09 | Profil | `profile-premium.jsx`, `screens/05-owner.png` | ✅ | ~75% | `p09-profil.png`, `p09b-profil-scroll.png` | RAČUN · VLASNIK eyebrow + h1 + identity card (avatar + Domaćin badge + status chips Email potvrđen/Telefon nedostaje) + completion **radial 14%** + Dovrši CTA + Pretplata upsell card w/ "Probni period" amber pill + 3-row settings list (Uredi/Promijeni lozinku/Postavke obavijesti). **Missing vs handoff:** host-trust KPIs row, verified-chips emphasis. Strong fidelity overall. |
| 10 | AI Asistent | `ai-assistant.jsx`, `screens/11-owner.png` | ✅ | ~70% | `p10-ai-assistant.png` | Empty-state w/ 3D robot illustration, h2 "Još nema razgovora", body, primary CTA "Novi razgovor". Handoff shows **consent onboarding + chat surface**; current is the post-consent empty state. Reasonable. |
| 11 | Smještajne Jedinice list | `units.jsx` | n/a observed via detail | — | — | Reached only at detail level via drawer → already migrated chrome. |
| 12 | Stripe Plaćanja (Isplate) | `payouts.jsx`, `screens/09-owner.png` | ✅ partial | ~55% | `p12-stripe-payouts.png` | Onboarding state: purple hero card w/ Stripe icon tile + status pill "Setup u toku" + acct ID chip `acct_1Tc037PnKJAl9q6s` (cf. [[stripe-connect-test-fixture]] — `charges_enabled=false` because of hCaptcha blocker, by design) + white CTA. Below: "Zašto Stripe Connect" 4-row card + numbered onboarding stepper. **Missing vs handoff:** balance tiles, IBAN block, schedule — those are gated on completed Connect, not on this fixture. Validate again against a `charges_enabled=true` fixture before grading P-level. |
| 13 | iCal Sinkronizacija (Import) | `ical.jsx`, `screens/10-owner.png` | ✅ partial | ~65% | `p13-ical-import.png` | Purple hero card "Nema feedova" + Dodaj Feed CTA, reasons card (4 rows), then "iCal Sinkronizacija" group w/ Booking.com row. **Delta:** OTA logo is a generic "B" badge, handoff calls for **real OTA logos** (`booking.png`, `airbnb.png`, `other-sync.png` in `source/assets/`). Asset wiring incomplete. **P2**. |
| 14 | Obavještenja | `notifications.jsx`, `screens/12-owner.png` | ✅ partial | ~70% | `p14-obavjestenja.png` | Day-grouped headers + cards w/ left orange unread bar + category icon tile + title + body + relative time + unread dot + chevron + FAB (mark-all). **Missing vs handoff:** **inline actions** on cards (approve/reject etc.) — current uses chevron-only navigation. **P2**. |
| 15 | FAQ | `faq.jsx`, `screens/13-owner.png` | ✅ partial | ~70% | `p15-faq.png` | Search bar + category chips (Sve/Rezervacije/Plaćanja/Widget/iCal Sync/Tehnička Podrška) w/ icon prefix + collapsed accordion cards. **Missing vs handoff:** "contact card" CTA at bottom (not seen at first viewport — may exist below; not confirmed). |
| 16 | Bankovni Račun | implied by `payouts.jsx` IBAN block | ✅ | ~80% | `p16-bankovni-racun.png` | Info banner card (left purple bar + i icon + h3 + body), form card w/ 4 BbInput rows (IBAN, SWIFT/BIC, Naziv Banke, Vlasnik Računa) each w/ iconLeft + label-above. Sticky "Spremi Promjene" CTA disabled (empty form). Clean Bb* composition. |
| 17 | iCal Export | `ical.jsx` (mobile sub-screen) | ✅ | ~75% | `p17-ical-export.png` | Purple hero card "Spremno za Export" + 4-row reasons card + "Odaberi Jedinicu" card w/ counter pill + unit row w/ link + download circle icon buttons. Migrated. |
| 18 | Pretplata (Subscription) | `subscription.jsx`, `screens/08-owner.png` | ✅ stub | n/a | `p18-pretplata.png` | Mobile = **web-redirect stub** ("Potreban web dashboard" + Nastavi na web CTA). Handoff trial hero + billing toggle + Besplatno↔Pro tiles intentionally not rendered on mobile. Acceptable product choice; flag for confirmation that the redirect is the agreed mobile path. |
| 19 | Rezervacija — Detalji (Booking detail) | `booking-detail.jsx`, `screens/07-owner.png` | ⚠ partial — modal | ~40% | `p19-booking-detail.png` | Implemented as **modal sheet** w/ 5 sectioned info groups + 3-button action row (Uredi/Email/Ponovo). **Significant gap vs handoff full-screen booking-detail:** no cover image-slot, no activity timeline, no status+actions panel. Status pill rendered in blue (drift — confirmed-completed should be purple per `screens/02-owner.png`). Architectural delta — modal vs full-route. **P1 candidate**. |
| 20 | Postavke — Uredi profil | `settings.jsx`, `screens/16-owner.png` | ✅ | ~85% | `p20-postavke-uredi-profil.png` | Back-arrow only (no AppBar — handoff "sub-screen pattern"), BT avatar w/ camera FAB overlap (BbAvatarSlot), h1 + body, 2 cards (Osobni podaci, Adresa) w/ Bb* inputs. Strong match. |
| 21 | Promijeni lozinku | `settings.jsx` sub-screen | ✅ | ~85% | `p21-promijeni-lozinku.png` | Back-arrow + card "Promijeni lozinku" + 3 password fields w/ lock iconLeft + eye toggle trailingAction, info banner card + primary CTA + Odustani text button. Bb* composition consistent. |
| 22 | Postavke obavijesti | `settings.jsx` settings sub-screen | ✅ | ~80% | `p22-postavke-obavijesti.png` | Bottom-sheet over Profil w/ bell-icon header + X close. Master switch card + locked "Uvijek se šalju" group (3 critical rows w/ lock icon trailing) + expandable Marketing card. Bottom-sheet sub-route rather than push — acceptable design choice for a settings sub-detail. |

Not covered this run (intentional):
- Owner Login *desktop* — Marionette test was mobile only.
- Widget (screen 14 embed guide) — separate code surface, owner only links out.
- Register / Recovery / Legal — pre-auth, requires logout (out of scope to preserve session).
- Unit Wizard publish step (`wizard.jsx` Step 4 FROZEN) — not entered this run.
- Filters dialog, Booking create dialog (`dialogs.jsx`) — entry points not exercised.

## Cross-cutting findings

1. **Mjesečni kalendar legend uses imported-blue (`#4A90D9`) for "Završeno"** when handoff status tokens map `completed → #6B4CE6 (purple)`. Rezervacije status pill on the same status is correctly purple. → **legend color token mismatch** isolated to `lib/features/calendar/.../[month-view legend].dart`. P2.
2. **Booking detail is a modal sheet**, handoff specifies a full-screen route with cover image, activity timeline, status+actions panel. Architectural redesign required to close gap. P1 candidate for next dispatch.
3. **Pregled mobile is 4-KPI-plus-activity**; handoff specifies north-star revenue card + AI insight + dual-series chart + occupancy radial + colored KPI sparklines + channel mix + arrivals hero. Largest single-screen gap. P1 candidate.
4. **Rezervacije mobile is filter-first list**; handoff specifies KPI strip + AI nudge + pending priority queue (approve/reject + payment progress) + bookings ledger table. P1 candidate alongside #3.
5. **OTA assets** in `source/assets/` (Booking/Airbnb/other) not wired into the iCal Sync feed list — generic "B" badges in their place. P2.
6. **Notifications cards** ship without **inline actions** that handoff calls for. Chevron-only nav. P2.
7. **Login glass card** missing — current uses solid `panelBg` floating panel; handoff calls for **glass on gradient (auth/hero-only)**. P2.
8. **Subscription mobile is a web-redirect stub** — confirm this is the agreed product behavior, otherwise flag for native build. Product question, not a code gap.

## P-priority queue (suggested next dispatch order)

| P | Item | Why now |
|---|---|---|
| P1 | Pregled mobile (KPI sparklines, AI insight, dual-series chart, occupancy radial, channel mix) | Largest single-screen gap; this is the marketing screen owners land on. |
| P1 | Rezervacije mobile (KPI strip, pending priority queue, ledger table) | Operational screen; missing inline actions hurts daily workflow. |
| P1 | Booking detail — full-route refactor (cover image-slot, activity timeline, status+actions) | Architectural delta; gates linkability + share-able state. |
| P2 | Mjesečni kalendar legend color (`Završeno → purple`) | One-line token mapping fix. |
| P2 | iCal Sync — real OTA logos | Asset wiring; logos already in `design_handoff/source/assets/`. |
| P2 | Notifications inline actions | UX gap; matches handoff `notifications.jsx`. |
| P2 | Login glass card on gradient | Auth-hero token; isolated to login route. |
| P3 | Drawer scroll behavior under expanded Integracije | Affects discoverability of Profil item; small phones may need scroll fix. |

## Methodology notes

- Marionette tap targets are matched by widget `key` where available (login flow used `login_email` / `login_password` / `login_submit`); for navigation, drawer `text` matches worked reliably, AppBar hamburger required coord-tap at logical `(28, 76)` because multiple `IconButton` widgets share the row.
- `mcp__marionette__scroll_to` and certain `tap` calls intermittently returned `Server error` against Flutter framework state under modal sheets — retried via `mcp__marionette__press_back_button` and coord-taps.
- All screenshots persisted via `adb -s emulator-5554 exec-out screencap -p` (physical PNG, 1080×2400) — not via Marionette base64 — to keep file footprint minimal and reproducible.
- See `~/bookbed-design-qa/p01-…p22-…` for full PNG set.

## Revert (HARD RULE #4)

Per `.claude/rules/android-development.md`:
- `cp /tmp/gs-prod-backup.json android/app/google-services.json`
- Verify `grep project_id android/app/google-services.json` = `rab-booking-248fc`
- `git status` clean for `android/app/google-services.json`

(Executed at end of this audit run — see Step 6 in driver session. Also executed at end of Round 2 — see §Round 2 below.)

---

## Round 2 — P2 batch verification (2026-06-05, branch `chore/p2-quick-wins-batch-2026-06-05`)

Followup walk after applying one surgical edit (F1) and re-screenshotting on the same emulator. New shots at `~/bookbed-design-qa/round2/r2-…`.

| ID | Original audit/114 finding | Round 2 result | Status |
|---|---|---|---|
| **F1** | Mjesečni legend "Završeno" rendered blue (`#1565C0` / `#1E88E5`) | Edit applied: `month_calendar_screen.dart:937` returns `BBColor.statusCompleted` (`#6B4CE6`) for both light + dark. Legend dot is **now purple** — verified via `r2-01-mjesecni-f1-verify.png`. Single-token swap landed in commit `45bf99b6`. | ✅ **CLOSED** |
| **F2** | iCal Sync feed list uses generic "B" badge instead of real OTA logos | **False positive.** Asset files `assets/images/platforms/{booking,airbnb,other_sync}_icon.png` exist; `pubspec.yaml` already declares `assets/images/platforms/` (line 182); `_getPlatformIconPath()` at `ical_sync_settings_screen.dart:645-649` returns the correct paths. The "B in dark navy circle" I called out in Round 1 IS the **actual Booking.com brand mark** — not a fallback. Airbnb row confirmed to render the **real red Bélo logo**. Round 2 captures: `r2-02-ical-import-f2-verify.png`, `r2-03-ical-airbnb-f2.png`. | ✅ **CLOSED (false-positive in original audit)** |
| **F3** | Notifications cards missing inline approve/reject actions | Untouched this batch — landing site at `notifications_screen.dart:514-663` confirmed; adding inline actions requires a new `NotificationActions` derivation per notification type, callback wiring into the parent `NotificationsScreen`, and l10n strings. Scope exceeds "surgical per finding". | 🟡 **DEFERRED** (next dispatch as its own PR) |
| **F4** | Login screen "glass on gradient" missing | **Partial revision.** The glass primitive **IS** wired in code at `enhanced_login_screen.dart:442-452` (`ClipRRect` + `BackdropFilter` + `Container` w/ `rd.glassBg` + `rd.glassBorder`). Round 2 verified via `r2-04-login-f4-glass.png`. The blur effect is imperceptible at runtime because the **background under the card is the uniform lavender `shellBg`** — `BackdropFilter` has no chromatic gradient source to distort. Handoff `auth.jsx` puts the glass card on a **multi-color hero gradient**, which is what makes glass visually pop. The fix is to add the hero-gradient background to the login route, not to touch the glass primitive itself. | 🟡 **ROOT-CAUSE RE-SCOPED** (glass primitive OK; missing hero gradient → file the gradient task as `F4b`) |

### F4b (new) — Login hero gradient missing under glass card

The login screen needs a hero gradient (per handoff `--bb-gradient-hero` = `linear-gradient(135deg,#6B4CE6 0%,#8B6FFF 60%,#A78BFF 100%)`) painted behind the existing glass card so `BackdropFilter` blur has something visible to operate on. The card itself doesn't need touching. P2.

### Round 2 batch outcome

- Code edits this batch: **1** (F1 — 1 import + 1 case-return swap, +2/-1).
- Screens verified live: 3 (Mjesečni, iCal Sync × 2 views, Login).
- Findings closed: 2 (F1 by edit, F2 by re-observation as false-positive).
- Findings re-scoped: 1 (F4 → F4b).
- Findings deferred: 1 (F3).
- Config revert: ONCE at end of Round 2.

### Process notes (for future P2 batches)

1. **Read landing-site code BEFORE drafting the edit list.** This batch saved a sweep cycle: F2 dissolved on reading `_getPlatformIconPath` + verifying assets exist; F4 narrowed from "glass missing" to "gradient missing under existing glass". The Explore pass + first 60-line reads were the high-leverage steps.
2. **Brand marks vs fallbacks** look the same when an OTA mark is a single initial in a colored shape. Always check the actual asset PNG name + dimensions before logging a logo-missing finding.
3. **Glass effects on uniform backgrounds are invisible**; the visual gap is in the background, not the primitive. Audit glass findings by asking: what is `BackdropFilter` actually filtering?
4. **Surgical-per-finding** holds for single-token swaps and asset wirings; it does not hold for adding action callbacks across a card primitive (F3) — those need their own scope.

### Updated P-priority queue

| P | Item | Status |
|---|---|---|
| ✅ | F1 — Mjesečni legend purple | CLOSED Round 2 |
| ✅ | F2 — Real OTA logos | CLOSED Round 2 (false-positive) |
| P1 | Pregled mobile premium upgrade (KPI sparklines, AI insight, dual-series chart, occupancy radial, channel mix) | Open — next dispatch |
| P1 | Rezervacije mobile premium upgrade (KPI strip, pending priority queue, ledger table) | Open — next dispatch |
| P1 | Booking detail full-route refactor (cover image-slot, activity timeline, status+actions) | Open — next dispatch |
| P2 | F3 — Notifications inline actions | Open — own PR (model field + callback wiring + l10n) |
| P2 | F4b — Login hero gradient under glass card | Open — small, route-scoped |
| P2 | OTA assets verified — no further action | Closed |
| P3 | Drawer scroll behavior under expanded Integracije | Open — small phones |

---

## Round 3 — Combined Pregled + Notifications verification sweep (2026-06-05)

Integration worktree `/tmp/bb-sweep-wt` (branch `tmp/sweep-2026-06-05`, never pushed) merged both feature branches off `main` and ran on the Pixel_8 emulator against `bookbed-dev`. Source PRs verified in this sweep:

- **PR #675** `feat/pregled-batch2-2026-06-05` — hero command + occupancy radial + AI insight + channel mix.
- **PR #676** `chore/p2-login-gradient-notif-actions-2026-06-05` — inline approve/reject on notification cards (F3). F4b login gradient **dropped** — see below.

Merge order was Pregled → Notifications, both `--no-ff`. Conflict count: **0** (file-disjoint as designed).

### F4b — DROPPED on inspection

`enhanced_login_screen.dart:358-361` carries an explicit comment from PR #615:

> *"Was previously `rd.heroGradient` (saturated brand purple); swapped per Phase 1.2 (#615) review feedback."*

The "missing" gradient was a deliberate design decision. The pale-lavender `rd.softBg` is the agreed background; the glass card at line 442 remains correct as-is. Adding the hero gradient back = regression on a reviewed call. Audit/114 §Round 1 finding F4 was incorrect — closed as **design-intent, not a fidelity gap**.

### Per-surface fidelity

| # | Surface | Source | Round 3 result | Status | Capture |
|---|---|---|---|---|---|
| **F1** | Mjesečni legend "Završeno" purple | `45bf99b6` on `chore/p2-quick-wins-batch-2026-06-05` | Verified Round 2; no change in Round 3 (still purple). | ✅ LIVE | `round2/r2-01-mjesecni-f1-verify.png` |
| **F2** | iCal OTA logos | (no code change) | Verified Round 2; brand marks correct (false positive). | ✅ LIVE | `round2/r2-02-ical-import-f2-verify.png`, `r2-03-ical-airbnb-f2.png` |
| **F3** | Notifications inline approve/reject (PR #676) | `notifications_screen.dart` + `notifications_provider.dart` | All 4 visible `bookingCreated` cards show green **✓ Odobri** + soft-red **✕ Odbij** buttons. Chevron suppressed when actions present (no double affordance). FAB (mark-all-read) untouched on screen. Non-actionable notifications (out of view) keep chevron-only nav. | ✅ **LIVE** | `round3/r3-04-notifications-inline-actions.png` |
| **F4b** | Login hero gradient under glass | (no code change) | Design intent (PR #615) — soft-bg is the agreed background, glass primitive intact at line 442. | ❌ DROPPED (design-intent) | n/a |
| **C-a** | Pregled hero revenue command (PR #675) | `dashboard_overview_tab.dart` `_PregledHeroCommand` | `Ukupna zarada · zadnjih 30 dana` eyebrow, **€300** tabular north-star, no delta chip + no sparkline (test fixture `revenueHistory.length < 4`, falls through `hasDelta` and `hasSpark` gates as designed). On richer fixtures the chip + sparkline will appear. Card is full-width on mobile, FittedBox-scaled. | ✅ **LIVE** | `round3/r3-01-pregled-hero-radial-insight.png` |
| **C-d** | Pregled occupancy radial (PR #675) | `_PregledOccupancyRadial` + `_OccupancyRadialPainter` | Purple gradient arc, CustomPaint drawing **10%** center value (tabular), eyebrow `POPUNJENOST`, sublabel `Razdoblje · 1 rezervacija`, "2 dolazaka uskoro" purple pill (binds to `data.upcomingCheckIns`). `TweenAnimationBuilder` count-up gated by `MediaQuery.disableAnimations`. | ✅ **LIVE** | same as C-a (rendered below hero in capture) |
| **C-e** | Pregled AI insight banner (PR #675) | `_PregledAiInsight` | Lavender hero-gradient container, sparkles icon tile, eyebrow `BookBed AI · Uvid tjedna`, placeholder copy. Renders in this sweep because the build was `--debug` (kDebugMode true). Hidden in release until `PREGLED_AI_INSIGHT` env flag is on. | ✅ **LIVE (debug-gated)** | same as C-a |
| **C-f** | Pregled channel mix (PR #675) | `_PregledChannelMix` | Stacked bar + per-channel rows: **Direktno €207 69%**, **Booking.com €66 22%**, **Airbnb €27 9%** — proportions are the handoff placeholder (data.revenue × constants), not yet a real source breakdown. kDebugMode-visible; release waits on env flag `PREGLED_CHANNEL_MIX` + a proper provider field. | ✅ **LIVE (debug-gated, placeholder data)** | `round3/r3-02-pregled-channelmix.png` |

### Adjustment applied during sweep (not in PR #675)

The integration build dropped the `if (data.bookings == 0) return SizedBox.shrink()` guard from BOTH the hero/radial/insight block and the channel mix block. Reason: with the guard, all four widgets disappeared when the test fixture had no in-period bookings (which is the common cold-start state on `bookbed-dev`). The handoff `pregled-premium.jsx` has no empty-state branch; hero shows €0 + flat surfaces rather than disappearing. **The adjustment lives only on the throwaway `tmp/sweep-2026-06-05`**; PR #675 still has the guard. To land this behavior, open a follow-up small patch on `feat/pregled-batch2-2026-06-05` BEFORE merge, OR ship without it and accept the empty-state hide.

### Sweep notes / gotchas

1. **Build-runner needed in worktree** — fresh `/tmp/bb-sweep-wt` had no `.freezed.dart` / `.g.dart`. `dart run build_runner build --delete-conflicting-outputs` (~30s) must run after `flutter pub get` before any analyze or run. Same gotcha hit during PR #675 worktree (see commit `45bf99b6`).
2. **Test fixture data is sparse** — the dashboard provider initially failed with `PropertyException: Failed to fetch properties (code: property/fetch-failed)` after a hot-restart. Logging out via `Profil → Opasna zona → Odjava` and re-logging in cleared the stale auth tokens and the provider succeeded thereafter. Reproducible.
3. **Pre-existing `unifiedDashboardNotifierProvider` does NOT use `revenueHistory.length ≥ 4`** — the test fixture's history is single-point so the hero's delta chip and sparkline correctly hide. To force their visibility for design review, seed at least 4 booking entries spanning the period.
4. **F4b discovery saved time** — Explore pass surfaced the PR #615 swap comment before any code was written. Always read the file headers and inline comments first; the team's documented decisions can collapse a finding entirely.
5. **No FROZEN-region touches across the sweep.** Calendar repository, Cjenovnik, timeline dimensions, Unit Wizard publish — all untouched.

### Round 3 batch outcome

- PRs verified live on emulator: **2** (#675 Pregled, #676 Notifications)
- New audit findings closed: **3** (F3 by PR #676; C-a, C-d, C-e, C-f by PR #675)
- Findings re-classified: **1** (F4b → design-intent CLOSED)
- Worktrees used: **3** (Pregled, B, sweep — all to be torn down)
- Merge conflicts: **0**
- Config swap cycles: **1** (single dev↔prod swap as designed)
- Findings still open: F-deposit (PVDeposit card) — secondary, no provider data; drawer scroll under Integracije expansion; channel-mix real source-breakdown field.

### Final P-queue after Round 3

| P | Item | Status |
|---|---|---|
| ✅ | F1 Mjesečni legend | CLOSED Round 2 |
| ✅ | F2 OTA logos | CLOSED Round 2 (false-positive) |
| ✅ | F3 Notifications inline actions | **CLOSED Round 3** (PR #676) |
| ❌ | F4b Login hero gradient | **CLOSED design-intent** (PR #615 review) |
| ✅ | C-a Pregled hero revenue command | **CLOSED Round 3** (PR #675) |
| ✅ | C-d Pregled occupancy radial | **CLOSED Round 3** (PR #675) |
| ✅ | C-e Pregled AI insight | **CLOSED Round 3 (debug-gated)** (PR #675) |
| ✅ | C-f Pregled channel mix | **CLOSED Round 3 (debug-gated + placeholder)** (PR #675) |
| P2 | Drop `bookings == 0` guard on new Pregled widgets | Open — small patch on `feat/pregled-batch2-2026-06-05` |
| P2 | Channel mix real source-breakdown field on `UnifiedDashboardData` | Open — provider extension |
| P2 | Booking detail full-route refactor | Open — separate batch |
| P3 | PVDeposit card | Open — handoff secondary |
| P3 | Drawer scroll under Integracije expansion | Open — small phones |


