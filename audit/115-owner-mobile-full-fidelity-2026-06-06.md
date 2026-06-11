# audit/115 — Owner mobile FULL micro-fidelity sweep vs `design_handoff/` (2026-06-06)

Follow-up sweep on top of [[audit/114]] R3 (PRs #675 / #676 / #677 merged). This run is **post-merge live state on `main`** with the explicit mandate: brutally honest, element-by-element divergences (hex / px / token / component), no vibe percentages.

Captures persisted at `~/bookbed-design-qa/round4/r4-*.png`. Each row links to one or more shots. Per-screen comparison uses the `design_handoff/source/*.jsx` + `design_handoff/screens/*-owner.png` cross-reference.

---

## Environment

| Field | Value |
|---|---|
| Branch | `main` (clean) @ commit `2b26c1eb` |
| Owner web | https://bookbed-owner-dev.web.app — deployed `tool/deploy-dev.sh owner` (entry `lib/owner_main_dev.dart`, `--no-tree-shake-icons`) |
| Web projectId verify | `bookbed-dev` runtime; 2× `rab-booking-248fc` matches in `main.dart.js` are enum switch-case literals (`case 2:return"rab-booking-248fc"`) + env-name map (`if(J.i(s,"rab-booking-248fc"))return"production"`) — NOT runtime config |
| Android emulator | Pixel_8 (sdk gphone64 arm64) on `bookbed-dev` (google-services.json swapped) |
| Entry point | `lib/main_dev.dart` (`expectedProjectId=bookbed-dev` asserted at boot, debug-only) |
| Build | `flutter run --target lib/main_dev.dart -d emulator-5554 --debug` (firebase_storage 13.4.1 — `--debug` works per [[android-debug-build-firebase-storage-13]]) |
| Login | `bookbed-test@bookbed.io` UID `GILVItIVP5R8WXfnMmyMo1ykhUm2` per [[test-account]] |
| Build_runner | `dart run build_runner build --delete-conflicting-outputs` → 22 outputs, 26s |
| Screenshot mode | `adb -s emulator-5554 exec-out screencap -p` (1080×2400 raw, some resized via `sips -Z 1600` for inspection) |

## Coverage summary

- **22 owner screens swept** (per audit/114 §Sweep enumeration), 0 omitted, 33 captures.
- 2 P1 architectural gaps from audit/114 verified **unchanged** on `main` (Rezervacije, Booking detail).
- 3 audit/114 merges verified **live on `main`**: F1 mjesečni legend (PR #677), F3 notifications inline (PR #676), Pregled premium upgrade (PR #675).
- 2 **new findings** surfaced this run (G-1 booking-detail status-pill blue drift, G-2 drawer Widget group not in audit/114 enumeration).

| Category | Count | Screens |
|---|---|---|
| Fully matches handoff (within mobile compression accepted) | 6 | #02 drawer chrome, #04 timeline chrome (FROZEN), #08 cjenovnik chrome (FROZEN), #16 bankovni račun, #20 uredi profil, #21 promijeni lozinku |
| Partial match (chrome OK, missing components / arch delta vs handoff) | 13 | #01 login (lavender, no hero gradient — design intent per [[audit/114]] R3), #03 pregled (live PR #675 — sparse data hides delta/sparkline), #05 mjesečni (F1 live), #06 rezervacije (NOT upgraded — see G-3), #07 jedinice osnovno, #09 profil, #10 ai assistant (empty state vs consent onboarding), #12 stripe plaćanja (gated on Connect), #13 iCal sync, #14 obavještenja (F3 live), #15 FAQ, #17 iCal export, #22 postavke obavijesti |
| Stub / out-of-scope | 1 | #18 pretplata (web-redirect stub per product intent) |
| Architectural gap (P1) | 2 | #06 rezervacije (filter-first list vs KPI + AI nudge + priority queue + ledger), #19 booking detail (modal sheet vs full-route w/ cover + timeline + status panel) |

## Tier table (advisor-locked depth budget)

| Tier | Screens | Per-row budget |
|---|---|---|
| **DEEP** (post-merge verify + P1 architectural deltas) | #03 Pregled, #06 Rezervacije, #14 Obavještenja, #05 Mjesečni, #19 Booking detail, #01 Login | ≤3 MATCHES bullets + ≤5 DIVERGES bullets, must cite hex/px/token/component |
| **STANDARD** | #02 Drawer, #07 Jedinice Osnovno, #09 Profil, #10 AI Asistent, #12 Stripe, #13 iCal Sync, #15 FAQ, #16 Bankovni, #17 iCal Export, #20 Uredi profil, #21 Promijeni lozinku, #22 Postavke obavijesti | ≤2 MATCHES + ≤3 DIVERGES |
| **CHROME-ONLY** (FROZEN / stub) | #04 Timeline FROZEN, #08 Cjenovnik FROZEN, #11 Jedinice list, #18 Pretplata stub | Chrome-only, internals out of scope |

---

## Per-screen sweep

Table conventions:
- **MATCHES** cites the element + the handoff anchor (component, token, hex, behavior).
- **DIVERGES** must contain at least one quantified anchor — hex (`#6B4CE6`), px (`padding 20 vs 24`), token (`BBColor.textSecondary`), or component identity (`raw Container vs BbCard`). Vibes rejected.
- **Sev**: P1 (architectural / blocks workflow), P2 (single-token / asset wiring / inline-action gap), P3 (small-phone or scroll behavior), I (informational, design-intent confirm).
- **`[DEBUG-ONLY]`** marker: visible only in `kDebugMode` builds, hidden in release. Reader MUST NOT read these as shipped.
- **`[SPARSE-DATA]`** marker: gated component is hidden when fixture data is below the threshold the component requires (e.g. `revenueHistory.length < 4` hides delta-chip; `< 2` hides sparkline). Hide is by design, not a divergence.

### Tier: DEEP

| # | Screen | Handoff ref | MATCHES | DIVERGES | Sev | Shot |
|---|---|---|---|---|---|---|
| 01 | Prijava (Login) | `source/auth.jsx`, `screens/15-owner.png` | (a) Lavender shell `BbAuthShell` panel-on-shellBg; (b) `BbInput(iconLeft: mail/lock, trailingAction: eye)` rows for email + password; (c) primary `BbButton(label:'Prijava', iconLeft: login-arrow)` full-width + outline `BbButton(label:'Prijava preko Googlea', iconLeft: google_g)` w/ "ili nastavite s" divider between | (a) Handoff `auth.jsx` `--bb-gradient-hero=linear-gradient(135deg,#6B4CE6 0%,#8B6FFF 60%,#A78BFF 100%)` background under glass card → current uses uniform `rd.softBg` per `enhanced_login_screen.dart:358-361` (PR #615 deliberate swap from `rd.heroGradient`). Glass primitive at line 442 intact but `BackdropFilter` has no chromatic gradient to distort. | I (design-intent confirm; **NOT a regression**) | r4-00 |
| 03 | Pregled | `source/pregled-premium.jsx`, `screens/01-owner.png` | (a) PR #675 `_PregledHeroCommand` renders `Ukupna zarada · zadnjih 7 dana` eyebrow + `€0` north-star (FittedBox `tabular`); (b) PR #675 occupancy radial `0%` + `POPUNJENOST` eyebrow + `Razdoblje · 0 rezervacija` + `✦ 2 dolazaka uskoro` chip; (c) PR #675 AI insight card `BookBed AI` `Uvid tjedna` + body — `[DEBUG-ONLY]` per PR #675 design + memory `design-sweep-gotchas`. | (a) Hero north-star renders WITHOUT delta-chip and WITHOUT sparkline — `[SPARSE-DATA]` (test fixture `revenueHistory.length < 4` falls through `hasDelta` + `hasSpark` gates by design, NOT a divergence; flagged here only because handoff shows them present on richer data); (b) "Zarada po kanalu" channel mix card rendering w/ dummy values (`Direktno €1 / 69%`, `Booking.com €0 / 22%`, `Airbnb €0 / 9%`) — `[DEBUG-ONLY]` per memory `design-sweep-gotchas`; release users won't see this; (c) "Nedavne Aktivnosti" KPI list = 5 rows w/ `PG`/`FG`/`PG` avatars (`Past/Future/Pending Guest`) + status pill (`Završeno` PURPLE = correct token, `Potvrđeno` GREEN = correct token); MATCHES (not divergent — listed for completeness); (d) No `next guest hero chip` from handoff `pregled-premium.jsx`; `Nadolazeći check-in 2` KPI tile is the partial substitute; (e) No `colored KPI sparklines` inside the 4 KPI tiles — flat numbers only. | P2 (KPI sparklines), I (DEBUG-ONLY tagging + sparse-data note) | r4-02, r4-03, r4-04 |
| 05 | Kalendar — Mjesečni | `source/calendar-month.jsx`, `screens/04-owner.png` | (a) `BBColor.statusCompleted = #6B4CE6` PURPLE legend dot for "Završeno" (PR #677 commit `375b873c` LIVE on main — `month_calendar_screen.dart:937`); (b) Conflict overlay green "Future Guest" multi-day bars w/ RED `BoxBorder` + `⚠` icon, day 8–11 SRI-ČET, matches handoff conflict treatment; (c) Today indicator: SUB column day `6` rendered as filled purple `Material` circle + white text. | (a) Below-grid panel "Nema odabranog datum" placeholder visible — handoff `calendar-month.jsx` shows a populated bottom-sheet selection card on date tap; no day selected here so placeholder correct; (b) Day-cell dots for non-conflict bookings render under bar (purple `2 / 2 / 2 / 2 / 1 / 1 / 1 / 1` overlap counters on day 8/9/10/11, line 15-18 also shows `1` chips on next month rows) — matches `calendar-month.jsx` overlap indicator. No measured divergence. | ✅ F1 CLOSED | r4-09 |
| 06 | Rezervacije | `source/rezervacije-premium.jsx`, `screens/02-owner.png` | (a) Filter section: `Filteri i Pregl…` card (truncated label vs handoff full "Filteri i Pregled" — label clip is the divergence cited below); (b) Status filter chips Sve(active) / Na čekanju / Potvrđene / Otkazane / Uvezene with correct colored dots per `BBColor.status*`; (c) `Završeno` status pill on booking card is PURPLE `#6B4CE6` = correct token (contrast w/ G-1 below where booking-detail modal pill on the same status renders blue). | (a) **NO KPI strip across top** — handoff `rezervacije-premium.jsx` opens with 4-tile KPI row (`Ukupno bookinga`, `Potvrđene`, `Na čekanju`, `Završene`). Current = filter card first; (b) **NO AI nudge banner** under KPIs (`rezervacije-premium.jsx` has a recommendation card `BookBed AI` w/ purple gradient — entirely missing on mobile); (c) **NO pending priority queue** — handoff opens with `Na čekanju` priority queue showing each pending booking w/ inline `Odobri`/`Odbij` buttons + payment progress bar. Current jumps straight to filter chips then a single booking card; (d) **NO bookings ledger table** — handoff shows tabular ledger w/ columns (Guest / Datumi / Iznos / Status / Akcije). Current = vertically stacked booking card list (`owner_bookings_screen.dart` filter-first surface); (e) "Filteri i Pregl…" h3 truncates the label (no overflow handling) — label `Filteri i Pregled` cut to `Filteri i Pregl…` ellipsis. | **P1** (architectural — full re-layout, NOT a chrome fix). Confirmed `git log -- lib/features/owner_dashboard/presentation/screens/owner_bookings_screen.dart` shows last touch is `ee620f3a feat(redesign-r3-b): Rezervacije onto Bb* foundation (#636)` — **the premium upgrade was NOT merged today** (contrast user-stated assumption). | r4-06 |
| 14 | Obavještenja | `source/notifications.jsx`, `screens/12-owner.png` | (a) Day-group header `30.5.2026` + `15` counter pill = correct group treatment per handoff; (b) PR #676 inline action row LIVE on `bookingCreated` cards: green `✓ Odobri` (`BBColor.success`) + soft-red outlined `✕ Odbij` (`BBColor.statusCanceledBg`) below body, chevron suppressed when actions present (no double affordance); (c) Card chrome: left ORANGE unread bar + 📅 calendar `BbIconTile` + h3 + body + relative time "6d prije" + unread purple dot. | (a) FAB bottom-right purple w/ checklist `✓` icon visible (mark-all-read) — matches handoff. (No measured divergence to call out.) | ✅ F3 CLOSED | r4-13 |
| 19 | Rezervacija — Detalji (Booking detail) | `source/booking-detail.jsx`, `screens/07-owner.png` | (a) 5 sectioned info groups with PURPLE icon tile + underlined h3 anchor matching handoff section pattern (Informacije o rezervaciji / o gostu / o objektu / Detalji boravka / Informacije o plaćanju); (b) 3-button action row at bottom: `✎ Uredi` / `✉ Email` / `🔄 Ponovo` (all purple `BbButton` solid); (c) Modal header `📋 Detalji rezervacije` + `✕` close at top-right (BottomSheet pattern). | (a) **Architectural gap unchanged from audit/114 row 19**: implementation = `booking_details_dialog*.dart` BottomSheet **modal**; handoff `booking-detail.jsx` = **full-screen route** w/ (1) cover image-slot at top (`image-slot.js`), (2) activity timeline section, (3) status + actions panel w/ pending-payment progress; (b) **G-1 (NEW)**: Status pill `Završeno` rendered BLUE. Visual ≈ `Color(0xFF42A5F5)` (Material `Colors.blue.shade400`-ish — NOT exactly the `#4A90D9` imported-blue token, but indistinguishable to a user). Root cause = hardcoded blue in `BookingStatus.color` extension at `lib/core/constants/enums.dart:369`; `booking_details_dialog_v2.dart:595` reads `status.color` from that extension. **NOT the same fix scope as F1**: F1 (PR #677) bypassed the extension by adding a local switch in `month_calendar_screen.dart:932-938`. The real fix = swap `enums.dart:369` `Color(0xFF42A5F5) → BBColor.statusCompleted` — propagates to ~17 consumers in one line. See cross-cutting §G-1 for full consumer list; (c) `Preostalo: €360.00` rendered RED text in plaćanje section — handoff uses softer warning amber/orange for outstanding balances; raw RED reads as error not warning; (d) Status row label `Status:` followed by pill on the SAME baseline row with extra horizontal padding — handoff has Status anchored as section subtitle on its own line; (e) Modal action row truncated under nav bar — bottom edge appears to clip "Detalji" CTA from the parent Rezervacije surface visible behind the modal scrim (BottomSheet over-height issue). | **P1** (arch) + **P2** (G-1 status pill purple token swap; same fix shape as F1) | r4-33 |

### Tier: STANDARD

| # | Screen | Handoff ref | MATCHES | DIVERGES | Sev | Shot |
|---|---|---|---|---|---|---|
| 02 | Drawer | `source/primitives.jsx` `BBSidebar` chrome | (a) Hero header purple `BBColor.primary` w/ BB wordmark + Avatar `BT` purple bordered + name + email; (b) Active item raised pill (lavender bg `BBColor.surfaceContainerHighest`) w/ purple icon tile + h3; (c) **Integracije expandable group** w/ chevron up/down (open shows iCal + Plaćanja + **Widget** sub-groups w/ purple eyebrow + left-bar dividers — matches handoff). | (a) **G-2 (NEW)** vs audit/114 row 02 enumeration: a **`Widget` sub-group** under Integracije containing `Ugradnja widgeta` row (subtitle "Dodavanje na sajt") — not mentioned in audit/114 R1 row 02 (which only enumerated iCal + Plaćanja groups). Drawer item exists but is NOT in audit/114 inventory; informational discovery, not a regression; (b) Drawer scroll required to reach FAQ / Obavještenja / Profil when Integracije is expanded (confirms audit/114 row 02 P3 finding "items below Profil clip on small screens"). Repro on Pixel_8 1080×2400: with Integracije expanded, FAQ is at viewport `~1850`, requires swipe to surface. | I (G-2 discovery), P3 (drawer scroll — pre-existing) | r4-05, r4-15, r4-21 |
| 07 | Smještajne Jedinice — Osnovno | `source/units.jsx`, `screens/06-owner.png` | (a) 4-tab strip (Osnovno / Cjenovnik / Widget / Napredno) w/ purple underlined active indicator + icon-above-label; (b) 3 BbCard panels: Informacije / Kapacitet / Cijena w/ purple `BbIconTile` + underlined h3; (c) Status `Dostupan` rendered in GREEN `BBColor.success` token, Cijena values €120 in PURPLE `BBColor.primary` text. | (a) AppBar far-right icon = `📋 list-back` icon (back to unit list) — matches handoff but is the only nav affordance; no kebab/share/edit secondary actions; (b) `Slug: Nije postavljeno` displayed as plain body text — handoff `units.jsx` makes empty-state slug a tappable "Postavi slug" CTA (chip-with-iconLeft); current is read-only label. | P3 (slug CTA missing) | r4-10 |
| 09 | Profil | `source/profile-premium.jsx`, `screens/05-owner.png` | (a) `RAČUN · VLASNIK` eyebrow w/ `BBType.eyebrow` + h1 `Profil` (`BBType.h1`); (b) Identity `BbCard` w/ TOP-edge PURPLE accent stripe, avatar `BT` (lavender circle + purple letter) + `Domaćin` badge (`BBColor.primary` chip) + status chips `✓ Email potvrđen` (green) + `🔔 Telefon nedostaje` (orange); (c) Completion radial `14% ispunjeno` + `Dovršite profil` + `Još 7 koraka do 100%.` + `→ Dovrši` CTA. | (a) **Profil sublist contains rows NOT in audit/114 row 09 enumeration nor in handoff `profile-premium.jsx`**: `Jezik (Hrvatski)`, `Tema (Sistemska postavka)`, APLIKACIJA group `Pomoć i podrška` / `O aplikaciji`, PRAVNO group `Uvjeti korištenja` / `Politika privatnosti` / `Politika kolačića`, OPASNA ZONA `Odjava` (red) + `Obriši račun` (gray w/ warning subtitle). These are sub-routes — handoff coverage gap on the design side, not a regression on Flutter side; (b) Pretplata upsell card `Nadogradite na…` + `Probni period` amber pill + `→ Pretplata` CTA matches handoff (no divergence). | I (sub-route inventory expanded vs audit/114) | r4-12, r4-23, r4-25, r4-26 |
| 10 | AI Asistent | `source/ai-assistant.jsx`, `screens/11-owner.png` | (a) AppBar hamburger + "AI Asistent"; (b) 3D purple robot illustration centered (circuit-board belly, speech-bubble eyes); (c) h2 `Još nema razgovora` + body `Pitajte me bilo što o postavljanju i upravljanju vašim smještajem` + primary CTA `💬 Novi razgovor`. | (a) Handoff `ai-assistant.jsx` opens with **consent onboarding** (privacy + AI usage disclosure) → user accepts → empty-chat surface. Current jumps straight to post-consent empty state. Acceptable if consent already given on first launch — but the consent flow itself is not exercised in this run; (b) No chat-surface UI rendered (would require tapping `Novi razgovor`). | I (consent flow path coverage gap) | r4-14 |
| 12 | Stripe Plaćanja | `source/payouts.jsx`, `screens/09-owner.png` | (a) Purple hero `BbCard` w/ icon tile + ORANGE `🔔 Setup u tijeku` pill + body + acct ID chip `acct_1Tc037PnKJAl9q6s` (matches [[stripe-connect-test-fixture]]) + white CTA `→ Završi Stripe Setup`; (b) "Zašto Stripe Connect?" 4-reason card; (c) Numbered Stripe Connect stepper: 1 `Kreirajte Stripe Račun` (chevron-down) + 2 ✓ `Dovršite Stripe Onboarding` (chevron-down). | (a) **No balance tiles, IBAN block, schedule visible** — gated on `charges_enabled=true` which is `false` on the test fixture per [[stripe-connect-test-fixture]] (hCaptcha blocker on Express signup). Re-test on a completed-Connect fixture before grading P-level for these surfaces; (b) White CTA on purple hero "→ Završi Stripe Setup" is the only primary affordance — matches handoff. No measured divergence. | I (post-Connect surfaces deferred to fixture w/ `charges_enabled=true`) | r4-18 |
| 13 | iCal Sinkronizacija | `source/ical.jsx`, `screens/10-owner.png` | (a) Purple hero card "Nema feedova" status pill + `+ Dodaj Feed` white CTA on purple bg; (b) "Zašto iCal Sinkronizacija?" 4-row reason card (Automatska sinkronizacija / Sprečavanje dvostrukog rezerviranja / Kompatibilnost / Sigurno i Pouzdano); (c) "iCal Sinkronizacija" group header + Booking.com row w/ real BRAND MARK "B" in dark navy circle (= the actual Booking.com `b.` wordmark — F2 closed false-positive per audit/114 R2). | (a) Audit/114 R1 F2 originally flagged "generic B badge missing real OTA logos" — verified by handoff that BookBed's Booking.com brand-mark is "B" + correct asset. No divergence. | ✅ F2 CLOSED | r4-16 |
| 15 | FAQ | `source/faq.jsx`, `screens/13-owner.png` | (a) Search bar w/ magnifier icon + "Pretražite pitanja..."; (b) Category chips row w/ icon prefix: `Sve` (purple solid active) / 📅 `Rezervacije` / 💳 `Plaćanja` / `<>` `Widget` / 🔁 `iCal Sync` / 🛠 `Tehnička Podrška` (wraps to 2 rows on mobile, ~3 chips/row); (c) Collapsed accordion cards w/ purple `BbIconTile` (`bed` icon) + h3 + body category label + chevron-down. | (a) Handoff `faq.jsx` shows a `contact card` CTA at the bottom (after all categories) — not visible in this viewport. May exist below scroll line — not confirmed this run. P3 deferred verification. | P3 (contact-card existence verification) | r4-22 |
| 16 | Bankovni Račun | implied by `payouts.jsx` IBAN block | (a) Info banner BbCard w/ purple left accent + (i) icon + "Kada se koriste ovi podaci?" h3 + body; (b) "Bankovni Podaci" h2 + form `BbCard` w/ 4 `BbInput(iconLeft)` rows (IBAN / SWIFT/BIC / Naziv Banke / Vlasnik Računa); (c) Sticky bottom `BbButton` "💾 Spremi Promjene" DISABLED state (empty form). | (a) No measured divergence — clean Bb* composition. (Match.) | (none) | r4-19 |
| 17 | iCal Export | `source/ical.jsx` mobile sub-screen | (a) Purple hero card w/ ✓ "Spremno za Export" pill; (b) "Zašto exportirati kalendar?" 4-reason card (Sinkronizacija kalendara / Sinkronizacija platformi / Automatska ažuriranja / Podsjetnici); (c) "Odaberi Jedinicu" group header w/ "1" counter pill + Test Unit A row w/ link 🔗 + download ⬇ circular icon buttons. | (a) AppBar title is `iCal Export - Odaberi Jedinicu` (verbose); handoff uses shorter `iCal Export`. Minor copy choice. | P3 (AppBar title length) | r4-17 |
| 20 | Postavke — Uredi profil | `source/settings.jsx`, `screens/16-owner.png` | (a) Sub-screen pattern: back-arrow only (no AppBar) per handoff "settings sub-screen" treatment; (b) Centered `BbAvatarSlot` (`BT` initials in lavender circle + purple `📷` camera FAB overlap bottom-right); (c) 2 cards `Osobni podaci` (Ime i Prezime / Email / Telefon, all `BbInput(iconLeft)`) + `Adresa` (Država + below). | (a) No measured divergence. (Strong match.) | (none) | r4-27 |
| 21 | Promijeni lozinku | `source/settings.jsx` sub-screen | (a) Sub-screen back-arrow only; (b) `Promijeni lozinku` card w/ 3 password fields, each `BbInput(iconLeft: lock, trailingAction: eye-off)`; (c) Info banner `BbCard` w/ purple left accent + (i) icon + "Ostat ćete prijavljeni nakon promjene lozinke" + primary `BbButton(label:'🔄 Promijeni lozinku')` + `Odustani` text button. | (a) No measured divergence. (Strong match.) | (none) | r4-28 |
| 22 | Postavke obavijesti | `source/settings.jsx` notifications sub-screen | (a) BottomSheet over Profil w/ 🔔 + `Postavke Obavijesti` header + `✕` close; (b) Master switch BbCard `Omogući Opcionalne Obavijesti` + body + purple toggle ON; (c) Outlined `Uvijek se šalju` card w/ 🛡 icon + 3 locked critical rows (Novi zahtjevi / Potvrde rezervacija / Otkazivanja) each w/ lock-icon trailing; (d) "Opcionalne Obavijesti" h2 + `Marketing i ažuriranja` expandable card. | (a) Sub-route renders as a BottomSheet (`showModalBottomSheet`) over the Profil page; handoff suggests a pushed sub-route. Acceptable design choice for settings sub-detail but **the parent Profil page is visible behind the scrim** w/ slightly tinted overlay — handoff sub-screen pattern has no parent leak. Use `Navigator.push` w/ MaterialPageRoute for crisper isolation if changed. | I (BottomSheet vs push, design preference) | r4-29 |

### Tier: CHROME-ONLY (FROZEN / stub)

| # | Screen | Handoff ref | MATCHES (chrome) | Out-of-scope | Sev | Shot |
|---|---|---|---|---|---|---|
| 04 | Kalendar — Timeline (FROZEN grid) | `source/calendar-timeline.jsx` + `calendar-premium.jsx`, `screens/03-owner.png` | (a) AppBar `Kalendar` + hamburger; (b) Period chip `📅 srpanj 2026 ▼` (lavender outlined, chevron arrows) + RED `⚠ 1` alert badge + 3-dot kebab; (c) Bottom-right FAB `+` purple. | FROZEN per CLAUDE.md "Timeline Calendar z-index" + "Timeline Calendar fixed dimensions" + `timeline_dimensions.dart` (50/42/100/60 fixed for ALL devices). Audit limited to AppBar + chrome around grid. Conflict overlay + parallelogram cells preserved (empty grid this run since fixture moved bookings to lipanj 2026 not srpanj). | n/a (FROZEN) | r4-08 |
| 08 | Cjenovnik (FROZEN) | `source/units.jsx` cjenovnik panel | (a) 4-tab strip w/ Cjenovnik active; (b) `Osnovna Cijena` BbCard w/ € icon tile + Cijena po noći (€) input pre-filled `€120` + `✓ Spremi cijenu` CTA; (c) `Odaberi mjesec` dropdown w/ `📅 lipnja 2026` + outlined `✎ Uredi više` CTA; (d) Pricing grid: Pon/Uto/Sri/Čet/Pet/Sub/Ned headers (purple) + €120/€130 amber-tint weekend cells. | FROZEN per CLAUDE.md "Cjenovnik tab (`unified_unit_hub_screen.dart`) — referentna implementacija". Chrome only. | n/a (FROZEN) | r4-11 |
| 11 | Smještajne Jedinice list | `source/units.jsx` | Reached only at detail level via drawer → already migrated chrome (#07). No separate list-route capture this run (only 1 unit on test account). | n/a (single-unit fixture) | n/a | (none — captured at detail via r4-10) |
| 18 | Pretplata (Subscription) | `source/subscription.jsx`, `screens/08-owner.png` | (a) AppBar hamburger + `Pretplata`; (b) Centered: lavender round avatar w/ purple 🌐 globe icon + h2 `Potreban web dashboard` + body + outlined `🔗 Nastavi na web` CTA. | Mobile = web-redirect stub per product intent (see audit/114 row 18). Handoff trial-hero + billing toggle + Besplatno↔Pro tiles intentionally not rendered on mobile. | I (confirm product intent) | r4-24 |

---

## Cross-cutting findings

### NEW findings (vs audit/114)

1. **G-1 — `BookingStatus.color` extension hardcodes `completed → Color(0xFF42A5F5)` blue** at `lib/core/constants/enums.dart:369`. NOT routed through `BBColor.statusCompleted`. Audit/114 F1 PR #677 fix added a NEW LOCAL color switch in `month_calendar_screen.dart:932-938` that returns `BBColor.statusCompleted` for completed — **bypassing the extension** rather than fixing the root. The extension is still wrong; ~17 consumers of `status.color` still render BLUE for completed:
   - `booking_details_dialog.dart:834` ← observed in r4-33 (this audit)
   - `booking_details_dialog_v2.dart:595`
   - `booking_inline_edit_dialog.dart:733`
   - `booking_context_menu.dart:78, 334`
   - `booking_status_change_dialog.dart:135`
   - `smart_booking_tooltip.dart:547, 549, 554`
   - `calendar_filters_panel.dart:499`
   - `calendar_search_dialog.dart:393, 414`
   - `unit_future_bookings_dialog.dart:294, 295, 300, 305, 427, 430, 438`
   - `booking_action_menu.dart:147, 157`
   - `bookings_filters_dialog.dart:238`
   - `bookings_table_view.dart:336, 338, 343`
   - `booking_create_dialog.dart:1054, 1065` (`conflict.status.color`)
   - `timeline_booking_block.dart:202, 203`
   - `timeline_split_day_cell.dart:53, 54`

   The Rezervacije booking card pill renders PURPLE (per audit/114 row 06 + r4-06) because that surface uses `AppColors.statusCompleted` / `BBColor.statusCompleted` directly (e.g. `booking_block_widget.dart:472`), not the `BookingStatus.color` extension getter. Two parallel color paths exist — one (`BBColor`) purple, one (`status.color`) blue — and current code uses both.

   **Correction to the original "P2 — single-token swap" claim**: the fix IS still a single-token swap, but at `enums.dart:369` (NOT scoped per-call-site as originally implied). Change `BookingStatus.completed => const Color(0xFF42A5F5)` to `BookingStatus.completed => BBColor.statusCompleted` (or `AppColors.statusCompleted`) and all ~17 consumers above flip purple in one commit. F1 fix at `month_calendar_screen.dart:932-938` becomes redundant after this change (local switch returns the same value the extension now returns); cleanup follow-up acceptable.

   **Verified via grep** (per advisor #1 falsifiability check):
   ```
   lib/core/constants/enums.dart:369:    BookingStatus.completed => const Color(0xFF42A5F5), // Blue
   lib/features/owner_dashboard/presentation/screens/calendar/month_calendar_screen.dart:938:        return BBColor.statusCompleted;
   ```
   Root cause is the enum extension, not the dialog builder. **P2 — single-token swap at `enums.dart:369`; broader blast radius than originally inferred.**

2. **G-2 — Drawer Widget sub-group not in audit/114 row 02 enumeration**. Integracije expansion now contains 3 sub-groups: iCal (Import / Export Rezervacija), Plaćanja (Stripe Plaćanja / Bankovni Račun), and **Widget (Ugradnja widgeta)**. Audit/114 only enumerated the first two. Informational discovery, no fidelity gap — but `Ugradnja widgeta` was not separately swept this run (single drawer-row, not a full screen).

3. **G-3 — Rezervacije premium upgrade NOT merged** on `main`. Confirmed via `git log -- lib/features/owner_dashboard/presentation/screens/owner_bookings_screen.dart`: last touching commit is `ee620f3a feat(redesign-r3-b): Rezervacije onto Bb* foundation (#636)` — Bb* foundation only, not the audit/114 P1 premium upgrade (KPI strip + AI nudge + pending priority queue + ledger table). Today's merges (`#675`/`#676`/`#677` per audit/114 R3 + 2b26c1eb thread) closed Pregled premium + Notifications inline + Mjesečni legend; Rezervacije premium was **not in scope**. P1 architectural gap from audit/114 row 06 stands unchanged.

### Verified-closed audit/114 findings (regression check)

| Finding | PR | Verification | Status |
|---|---|---|---|
| F1 — Mjesečni legend `Završeno` purple | #677 (`375b873c`) | Visible PURPLE legend dot in r4-09; matches `month_calendar_screen.dart:937` returning `BBColor.statusCompleted` for both light + dark | ✅ LIVE |
| F2 — iCal OTA real logos | (no code change; closed as false-positive) | "B" badge confirmed = real Booking.com brand mark + Airbnb red Bélo logo on row expand. Asset wiring exists per `pubspec.yaml:182` + `_getPlatformIconPath()` | ✅ LIVE (NOT-A-BUG) |
| F3 — Notifications inline approve/reject | #676 | Green `✓ Odobri` + soft-red `✕ Odbij` on all 5 visible `bookingCreated` cards in r4-13; chevron suppressed when actions present | ✅ LIVE |
| F4b — Login hero gradient under glass | (no code change; dropped as design-intent) | `enhanced_login_screen.dart:358-361` carries PR #615 deliberate `rd.heroGradient → rd.softBg` swap; glass primitive intact at line 442. Current uniform `rd.softBg` shell is the agreed design | ❌ DROPPED (design-intent confirmed) |
| C-a — Pregled hero revenue command | #675 | `_PregledHeroCommand` renders `Ukupna zarada · zadnjih 7 dana` + `€0` north-star. Sparse fixture (`revenueHistory.length < 4`) hides delta-chip + sparkline as designed | ✅ LIVE w/ sparse-data caveat |
| C-b — Occupancy radial | #675 | `0%` radial + `POPUNJENOST` eyebrow + `Razdoblje · 0 rezervacija` + `✦ 2 dolazaka uskoro` chip | ✅ LIVE |
| C-c — AI insight card (DEBUG) | #675 | `BookBed AI` card w/ `Uvid tjedna` eyebrow + Vikend-termini body — visible because `--debug` build | ✅ LIVE `[DEBUG-ONLY]` |
| C-d — Channel mix (DEBUG) | #675 | `Zarada po kanalu` w/ purple/red horizontal bar + `Direktno €1 69% / Booking.com €0 22% / Airbnb €0 9%` rows — visible because `--debug` build | ✅ LIVE `[DEBUG-ONLY]` |

### Unchanged P1 architectural gaps from audit/114

1. **Pregled** — partial premium upgrade live; still missing colored KPI sparklines inside the 4 KPI tiles. P2 (one of the audit/114 R1 P1 sub-items remains).
2. **Rezervacije** — full premium upgrade NOT merged. P1 unchanged (G-3).
3. **Booking detail** — modal sheet, not full-route. P1 unchanged. PLUS new G-1 status-pill blue drift (P2).

---

## P-priority queue (post-sweep)

| P | Item | Why now | Audit/114 origin |
|---|---|---|---|
| P1 | Rezervacije mobile premium upgrade (KPI strip + AI nudge + pending priority queue w/ inline approve/reject + bookings ledger table) | Operational screen, user expected merged today but isn't. Mirror Pregled batch shape; reuse the PR #676 inline-action component for priority queue rows. | audit/114 row 06 + G-3 |
| P1 | Booking detail full-route refactor (cover image-slot + activity timeline + status+actions panel) | Modal vs route is architectural; gates linkability + share-able state. | audit/114 row 19 (unchanged) |
| **P2** | **G-1 — `BookingStatus.color` extension root fix** | `lib/core/constants/enums.dart:369` `Color(0xFF42A5F5) → BBColor.statusCompleted`. One-line swap, propagates to ~17 consumers (booking-detail modal, calendar tooltips, action menu, status-change dialog, search dialog, filters panel, future bookings dialog, table view, create-dialog conflicts, timeline blocks/split cells, inline edit). F1 PR #677 local switch in `month_calendar_screen.dart:932-938` becomes redundant — optional cleanup follow-up. | **NEW this audit** |
| P2 | Pregled mobile — colored KPI sparklines inside the 4 KPI tiles | One audit/114 R1 P1 sub-item not closed by PR #675; small Bb* primitive addition. | audit/114 row 03 (residual) |
| P3 | Drawer scroll behavior under expanded Integracije (FAQ / Obavještenja / Profil clip) | Pre-existing; small phones. Either collapse-on-default Integracije, or add internal drawer ListView padding bottom. | audit/114 row 02 |
| P3 | Smještajne Jedinice Osnovno — `Slug: Nije postavljeno` should be tappable `Postavi slug` CTA | Empty-state nudge per handoff `units.jsx`. | NEW this audit (#07) |
| P3 | iCal Export AppBar title length (`iCal Export - Odaberi Jedinicu` → shorter) | Copy-only. | NEW this audit (#17) |
| P3 | FAQ contact-card CTA at bottom — verify exists below scroll | Spec'd in handoff `faq.jsx`. | NEW this audit (#15) |
| I | Profil sublist sub-routes not in handoff (Jezik / Tema / Pomoć / O aplikaciji / Uvjeti / Politika privatnosti / Politika kolačića / Odjava / Obriši račun) | Handoff coverage gap, not a Flutter regression. Question whether handoff should mock these. | NEW this audit (#09) |
| I | Pretplata mobile = web-redirect stub | Confirm with product. | audit/114 cross-cutting #8 (open) |

---

## Methodology notes

1. **Capture before code** (advisor #4 confirmation-bias control): each screenshot was taken BEFORE re-reading the handoff JSX or `lib/**` source for that screen. Divergences are described from the shot, then anchored back to source.
2. **Brutal honesty = measurable** (advisor #5): every DIVERGES bullet contains at least one of (hex / px / token / component). Bullets that would have been "feels off / spacing weird / looks denser" were demoted to "Observation:" lines and not claimed as divergences.
3. **`[DEBUG-ONLY]` + `[SPARSE-DATA]` tags** (advisor #3): non-negotiable on Pregled rows touching AI insight, channel mix, hero delta-chip, hero sparkline.
4. Marionette tap by widget key (`login_email`/`login_password`/`login_submit`) for login; tap-by-text for drawer items; coord-tap `(28, 76)` for the hamburger (logical coord per [[marionette-ios-gotchas]] — same problem class on Android since multiple `IconButton` widgets share the AppBar row).
5. `mcp__marionette__scroll_to` + certain `tap` calls returned `Server error` against system dialogs (POST_NOTIFICATIONS system permission) and against modal-over-modal states — fall back to `adb shell input swipe` for scrolls and `adb shell pm grant` for system permission grants.
6. Screenshots persisted via `adb -s emulator-5554 exec-out screencap -p` raw (1080×2400 PNG); inspection via `sips -Z 1600` resize where the Read tool rejected the raw PNG.
7. Login screen captured at app launch state (r4-00) BEFORE login; post-login state captured immediately after `login_submit` tap (r4-01); system POST_NOTIFICATIONS dialog dismissed via `pm grant io.bookbed.app android.permission.POST_NOTIFICATIONS` (Marionette can't reach Android system dialogs).
8. Flutter web bundle verification used `grep -aoE '.{0,40}rab-booking-248fc.{0,40}' build/web_owner/main.dart.js` — context window confirms both matches are enum switch cases + env-name map literals (Dart `firebase_options*` decode path), NOT runtime config strings.

---

## Revert log (HARD RULE #4)

Executed at end of this run:

```bash
cp /tmp/gs-prod-backup.json android/app/google-services.json
grep project_id android/app/google-services.json
# Should print:    "project_id": "rab-booking-248fc",
git status -- android/app/google-services.json
# Should be clean.
```

Flutter run + emulator stopped. Branch checkpoint per Phase 4.

---

## See also

- audit/114 §Round 1 (initial 22-screen sweep, 2026-06-05) — baseline this audit measures against
- audit/114 §Round 2 (F1 + F2 outcomes) — PR #677 origin + F2 false-positive closure
- audit/114 §Round 3 (combined Pregled + Notifications verification, integration worktree) — PRs #675 / #676 verification + F4b drop
- audit/103 §Phase 1 (PR #611) + §Phase 2 (Bb* token foundation + 19 primitives) — token system this audit cites
- audit/106 (Phase 2 visual regression sweep) — 12 screens, 0 UNINT drift
- CLAUDE.md `NIKADA NE MIJENJAJ` matrix — FROZEN Cjenovnik + Timeline Calendar dims
- memory `design-sweep-gotchas` — DEBUG-ONLY Pregled cards + sparse-data gates
- memory `flutter-web-input-bypass` — type_text over fill for text inputs
- memory `marionette-ios-gotchas` — logical-coord rule for hamburger
- memory `android-debug-build-firebase-storage-13` — `--debug` works on firebase_storage 13.x
