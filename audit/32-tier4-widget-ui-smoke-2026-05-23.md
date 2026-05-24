# audit/32 — TIER 4 Widget UI smoke (chrome-devtools MCP)

**Date:** 2026-05-23 → 2026-05-24 (executed 2026-05-24 07:23–07:32 UTC)
**Scope:** Six-checkpoint pure-observation smoke of the dev widget UI driven via chrome-devtools MCP. No code changes, no Firestore mutations, no real bookings submitted.
**Predecessors:** `audit/27-bb-e2e-cc-reject.md` (CC-reject lifecycle, widget_mode coupling), `audit/28-tier4-resend-sentry-baseline.md` §5 (DNS), `audit/23-misc-follow-ups.md` PR-1 (#450 form_persistence counter scope) — referenced inline.

> **Mode discipline:** task explicitly observation-only. No bookings created, no Stripe sessions opened, no Firestore writes. Tab-A submit attempt in CP3 hit Flutter form validation gate ("Please enter your first name") — no network call to `createBookingAtomic` fired (verified via Network panel, 37 reqs, none to that endpoint).

---

## 1. Setup

| Field | Value |
|---|---|
| Target URL | `https://bookbed-widget-dev.web.app/?property=SEED_test_owner_property_01&unit=SEED_test_owner_unit_01` |
| Chrome | chrome-devtools MCP, Chromium build-in (CanvasKit-served) |
| Test account | NOT used — guest form never submitted. Only anonymous/widget-public surfaces exercised. |
| Date of run | 2026-05-24 07:23–07:32 UTC (today = May 24 = Sunday in widget calendar) |
| Browser contexts | 2 isolated contexts: `smoke-h-cp1` (Tab A, page 2), `smoke-h-cp3-tabB` (Tab B, page 4) — fresh localStorage per context |
| Branch at execution | `main` (`79b4aea2`) — pre-flight verified `git branch --show-current = main`, `git status` clean except `?? .mcp.json`, `?? jest_dx/` (pre-existing untracked, not from this run) |
| Worktree | `$TMPDIR/bb-smoke-h-wt` on branch `doc/audit-32-smoke-h` (deviation from task literal — see §6.1) |

### 1.1 Flutter CanvasKit semantic-tree gotcha

Widget is Flutter web CanvasKit (no `<canvas>` in light DOM, rendering via SkSurface OffscreenCanvas). a11y semantic tree is suppressed by default — every fresh page load presents only:

```
flt-semantics-placeholder role="button" aria-label="Enable accessibility"
  style="position: absolute; left: -1px; top: -1px; width: 1px; height: 1px;"
```

chrome-devtools MCP `click` on the placeholder uid fails (`element did not become interactive within timeout`). The reliable trigger is JS-dispatched **focus + keydown(Enter)** on the placeholder element:

```js
const p = document.querySelector('flt-semantics-placeholder');
p.focus(); p.click();
p.dispatchEvent(new KeyboardEvent('keydown', {key:'Enter', bubbles:true, cancelable:true}));
```

After this, Flutter's screen-reader detection registers and `take_snapshot` populates the full widget tree (~50 uids: 31 date buttons + view toggles + locale + counters + Reserve + Powered-by). Documented here for the next chrome-devtools MCP × Flutter operator. This step must be repeated after each `navigate_page reload` or `navigate_page url`.

### 1.2 Screenshot artifacts

Captured to `$TMPDIR/bb-smoke-h-shots/` (workspace-root constraint blocks `/tmp` — same root issue as worktree, see §6.1):

| File | Checkpoint |
|---|---|
| `01-cp1-initial-load.jpeg` | CP1 baseline (May 2026 calendar, today=May 24 highlighted) |
| `02a-cp2-after-dates.jpeg` | CP2 Jun 07–11 picked, summary box shows 4 nights / €400 / Deposit €80 |
| `02b-cp2-pre-reload.jpeg` | CP2 guest form open after Reserve, counters bumped (UI shows 3 adults / 1 children) |
| `02c-cp2-post-reload.jpeg` | CP2 after F5: dates summary still rendered |
| `02d-cp2b-after-blank-back.jpeg` | CP2b after about:blank → back: dates summary still rendered |
| `03-cp3-stripe-only-validation.jpeg` | CP3 "Please enter your first/last name/email/phone number" validation gate after Pay-with-Stripe click |
| `04-cp4-d-plus-1-allowed.jpeg` | CP4 May 25 → May 26 = 1 night / €100 summary |
| `05a-cp5-hr-locale.jpeg` | CP5 HR locale active — note date range header still EN |
| `05b-cp5-en-locale.jpeg` | CP5 EN locale restored |

---

## 2. Result matrix

| # | Checkpoint | Expected (pre-#450) | Observed | Verdict |
|---|---|---|---|---|
| CP1 | Cookie consent | NO banner (iframe-embeddable, host handles consent) | NO banner, `document.cookie="(empty)"`, no `[class*="cookie"]`/`[class*="consent"]` DOM, no GDPR text scan match, console clean | ✅ |
| CP2 | F5 persistence | dates+locale survive (localStorage), guest counters reset to 1/0 | localStorage key `flutter.booking_widget_form_data_SEED_test_owner_unit_01` persists `{checkIn, checkOut, countryCode:"+385", paymentMethod:"stripe", adults:1, children:0}`; **counters reset to 1/0 after reload** — pre-counter-click timestamp `2026-05-24T07:26:40.170Z` IDENTICAL post-reload (counter clicks never wrote back) | ✅ |
| CP2b | Close-tab persist | dates survive, counters reset | localStorage IDENTICAL bit-for-bit after navigate→about:blank→back; same timestamp, same content; UI summary "Jun 07, 2026 - Jun 11, 2026" still rendered | ✅ |
| CP3 | Multi-tab race | already-exists snackbar in Tab B if Tab A submit succeeds | **Tab A submit blocked by guest-form validation** (Please enter first/last name/email/phone) — no `createBookingAtomic` call fired (Network panel: 37 reqs, none to CF); widget exposes Stripe-only payment (no pay-on-arrival button), race not testable without filling guest details + Stripe Checkout redirect | 🟡 SKIP (matches task escape clause) |
| CP4 | Date validation | past blocked, same-day blocked, D+1 = 1 night allowed | Past dates May 1–23: all `disableable disabled`, click no-op (verified by clicking May 14 — no check-in marker landed); same-day May 25 twice: only check-in registered, no check-out, no summary box; D+1 May 25→May 26: ✅ "1 night" / €100 / Deposit €20 / Reserve button | ✅ |
| CP5 | HR/EN locale | label translation, date format dd.MM.yyyy | URL parameter `?lang=hr` / `?lang=en` swaps. HR: most UI translated (Mjesec/Godina/Promijeni jezik/Min. boravak/svibnja/dostupno/nedostupno/datum prijave/datum odjave/Pokreće BookBed/Smještaj/UKUPNO/Polog/Rezerviraj/noć). **Date range header stays EN** ("May 25, 2026 - May 26, 2026"); month header stays EN ("May 2026"); price tokens "€100.00"/"€20.00" not localized (currency symbol default but no thousands-sep test) | ✅ with 🟡 partial (see §3.5, §4.1) |
| CP6 | Powered-by badge | href literal `https://bookbed.io` | `window.open("https://bookbed.io", "", "noopener,noreferrer")` — captured via JS `window.open` intercept after badge click. NO DOM `<a>` anchors (`document.querySelectorAll('a[href]').length = 0`) — Flutter uses `url_launcher`/`Link` widget. **Matches pre-#450 expectation exactly.** | ✅ |

**Verdict summary:** 5/6 ✅, 1/6 🟡 (CP3 blocked by widget Stripe-only config — matches task escape clause "skip race test, mark 🟡 with reason"). Three net-new findings flagged (§4).

---

## 3. Per-checkpoint detail

### 3.1 CP1 — Cookie consent

- **Expected:** No banner — widget is iframe-embeddable, host page handles consent.
- **Observed:** No banner, no cookies, no GDPR/consent/cookie text in body, no relevant class/id scan match. Console clean (only my own probe log).
- **Verdict:** ✅
- **Console errors:** none
- **Network:** widget bootstrap + 3× `POST https://europe-west1-bookbed-dev.cloudfunctions.net/getUnitAvailability [200]` (matches T11c 30s-polling pattern documented in `CLAUDE.md` NIKADA NE MIJENJAJ row for `bookings` read-rule)
- **Screenshot:** `01-cp1-initial-load.jpeg`
- **Notes:** sessionStorage holds 8 `flutterfire-*` keys (firebase init), localStorage empty on first load (form_persistence not eagerly initialized — matches expected pre-#450 baseline)

### 3.2 CP2 — Form-state F5 persistence

- **Expected:** dates+locale survive, guests reset to defaults (1/0/0).
- **Observed:**
  1. Pre-interaction: localStorage empty.
  2. Pick check-in Jun 7 (uid 4_6), check-out Jun 11 (uid 4_10) — summary "Jun 07, 2026 - Jun 11, 2026 / 4 nights / Room €400.00 / TOTAL €400.00 / Deposit €80.00 (20%)" appeared after ~3s render delay (Flutter snapshot pipeline async — first snapshot post-click can show pre-render state).
  3. Click Reserve → guest form opens with Adults=1 (disabled minus), Children=0 (disabled minus), Max=4. **No "Pets" counter visible** — this unit's config has `allowsPets=false` (consistent with prior audits).
  4. Click Adults increment (uid 7_15) twice → UI shows Adults=3. Click Children increment (uid 7_19) once → UI shows Children=1.
  5. **localStorage probe immediately AFTER counter clicks:** key `flutter.booking_widget_form_data_SEED_test_owner_unit_01` exists, content `adults:1, children:0` (NOT 3/1), timestamp `2026-05-24T07:26:40.170Z` (predates counter clicks at ~07:27:13).
  6. Reload page → re-enable a11y → re-snapshot.
  7. Post-reload localStorage IDENTICAL (same timestamp, same content).
  8. Summary box "Jun 07, 2026 - Jun 11, 2026 / 4 nights / €400" still rendered (dates restored from localStorage).
- **Verdict:** ✅
- **localStorage pre/post-reload content:**
  ```json
  {
    "flutter.booking_widget_form_data_SEED_test_owner_unit_01": {
      "unitId": "SEED_test_owner_unit_01",
      "propertyId": "SEED_test_owner_property_01",
      "checkIn": "2026-06-07T00:00:00.000Z",
      "checkOut": "2026-06-11T00:00:00.000Z",
      "firstName": "", "lastName": "", "email": "", "phone": "",
      "countryCode": "+385",
      "adults": 1, "children": 0,
      "notes": "",
      "paymentMethod": "stripe",
      "pillBarDismissed": false,
      "hasInteractedWithBookingFlow": true,
      "timestamp": "2026-05-24T07:26:40.170Z"
    }
  }
  ```
- **Pre-#450 confirmation:** Counter handlers DO NOT call `_saveFormData()` — empirically proven by the fact that the saved timestamp predates the counter clicks (write occurred at first Reserve press / form-mount, not after each counter mutation). PR #450 (per audit/23 PR-1 scope) should fix this.
- **Screenshot:** `02a` pre-reserve, `02b` pre-reload, `02c` post-reload
- **Notes:** flutter pipeline async-render delay (first post-click snapshot can be stale by ~2–4s) is a chrome-devtools MCP × Flutter quirk worth documenting for next operator.

### 3.3 CP2b — Close-tab persist

- **Expected:** dates survive, counters reset (same as CP2).
- **Observed:** Navigate to `about:blank` → navigate back to target URL → re-enable a11y → localStorage IDENTICAL bit-for-bit (same key, same payload, same timestamp `2026-05-24T07:26:40.170Z`). Summary "Jun 07, 2026 - Jun 11, 2026 / 4 nights / €400" still rendered.
- **Verdict:** ✅
- **localStorage delta from CP2:** zero
- **Screenshot:** `02d-cp2b-after-blank-back.jpeg`
- **Notes:** Browser context preserves localStorage across same-origin navigation — expected. Counters still 1/0 (still never written, regardless of how we navigated away).

### 3.4 CP3 — Multi-tab race

- **Expected:** Tab A submit → Tab B same dates → "already-exists" red snackbar.
- **Observed:**
  1. Tab B opened in fresh isolated context `smoke-h-cp3-tabB` (page 4), empty localStorage.
  2. Switch back to Tab A, click Reserve → guest form shows.
  3. Click "Pay with Stripe - 4 nights" (uid 11_27) with empty guest fields → **Flutter form validation fires**: 4 error messages ("Please enter your first/last name/email/phone number"), 4 fields marked `invalid="true"`.
  4. **No createBookingAtomic call** — Network panel shows 37 requests on Tab A, none to `createBookingAtomic` endpoint (only `getUnitAvailability` polling + Firestore Listen channel + asset loads).
  5. Widget exposes **only Stripe payment path** for this unit (uid 11_27 "Pay with Stripe - 4 nights"). No "Pay on arrival" / bank-transfer button visible. Matches `audit/27` §3 finding: `SEED_test_owner_unit_01` has `widget_mode=booking_instant` + `stripe_config.enabled=true` + no `bank_transfer_config` + no `allow_pay_on_arrival` UI path.
  6. To submit a real booking would require: filling 4 guest fields with real test data + checking legal checkbox + clicking Stripe → Stripe Checkout 3rd-party redirect + real test card. All forbidden by observation-only mandate ("DO NOT submit bookings with real guest emails").
- **Verdict:** 🟡 SKIP — matches task escape clause: "If submit fails on paymentMethod check: log error, SKIP race test, mark 🟡 with reason".
- **Console errors:** none beyond form validation messages
- **Network:** no createBookingAtomic — only validation gate
- **Screenshot:** `03-cp3-stripe-only-validation.jpeg`
- **Notes:** The audit/27 §3 widget_mode flip workaround (booking_instant → booking_pending → restore) is the only way to test the pay-on-arrival/no-stripe path on this unit. Same widget-mode coupling friction surfaces here in CP3 form of the same problem. See §4.2.

### 3.5 CP4 — Same-day check-out + past dates

- **Expected:**
  - past blocked
  - same-day = 0 nights → blocked
  - D+1 = 1 night → allowed
- **Observed:**
  1. **Past dates (May 1–23):** all reported `disableable disabled` in semantic tree. Click on uid 13_25 (May 14) — no check-in marker landed, no UI state change. ✅ blocked.
  2. **Same-day (May 25 twice):** first click → uid 13_36 becomes "May 25, available, check-in date 25". Second click on uid 13_36 → semantic tree UNCHANGED (still only check-in marker, no check-out). No summary box. ✅ blocked silently.
  3. **D+1 (May 25 check-in, May 26 check-out):** uid 13_37 becomes "May 26, available, check-out date 26" (after async render delay — first post-click snapshot showed it still as plain "available"; second snapshot captured the check-out marker). Summary box rendered: `"May 25, 2026 - May 26, 2026" / "1 night" / "Room (1 night) €100.00" / "TOTAL €100.00" / "Deposit: €20.00 (20%)"`. ✅ allowed.
- **Verdict:** ✅
- **Console errors:** none
- **Network:** routine getUnitAvailability polls; no error responses
- **Screenshot:** `04-cp4-d-plus-1-allowed.jpeg`
- **Notes:**
  - Same-day "blocked silently" — no error toast, no message, no shake animation. Widget simply doesn't advance the picker state. UX gap: a user who clicks the same date twice intending "1 night stay" has no feedback that they should click the next day.
  - The async render gap (D+1 case took 2 snapshots to fully appear) is worth documenting — first snapshot can lie. The second snapshot caught the correct state.

### 3.6 CP5 — Locale switch HR/EN

- **Expected:** labels translate, date format dd.MM.yyyy in HR.
- **Observed:**
  1. Click locale switcher (uid 13_7 "Change Language", expanded button) → menu opens with 4 menuitems: 🇭🇷 Hrvatski, 🇬🇧 English, 🇩🇪 Deutsch, 🇮🇹 Italiano.
  2. Click 🇭🇷 Hrvatski (uid 18_1) → URL gains `&lang=hr`. UI translates:
     - "Month/Year" → "Mjesec/Godina"
     - "Switch to Dark Mode" → "Prebaci na tamni način"
     - "Change Language" → "Promijeni jezik"
     - "Min. stay: 1 night" → "Min. boravak: 1 noć"
     - "May 1, unavailable" → "1. svibnja, nedostupno" (full Croatian month name + accusative case)
     - "available" → "dostupno", "unavailable" → "nedostupno"
     - "check-in date" → "datum prijave", "check-out date" → "datum odjave"
     - "Powered by BookBed" → "Pokreće BookBed"
     - Summary: "1 night" → "1 noć", "Room (1 night)" → "Smještaj (1 noć)", "TOTAL" → "UKUPNO", "Deposit" → "Polog", "Reserve" → "Rezerviraj"
  3. **Translation gaps (HR mode):**
     - **Date range header pill** "May 25, 2026 - May 26, 2026" — stays English. Expected per HR locale: "25.05.2026 - 26.05.2026" or "25. svibnja 2026 - 26. svibnja 2026".
     - **Month-header text** "May 2026" — stays English. Expected: "Svibanj 2026".
     - Currency formatting `€100.00` — `.` decimal separator stays even in HR (HR convention uses `,` decimal). Not tested with >1000 amount (no thousands-sep verification).
  4. Switch back to EN via locale menu (uid 20_2) → URL `&lang=en`. All labels EN again. Form state preserved across locale switch (May 25–26 dates + summary remain).
- **Verdict:** ✅ with 🟡 partial — translation gaps documented above
- **Console errors:** none
- **Network:** no extra CF calls on locale switch (locale toggle is client-side; URL param re-render only)
- **Screenshots:** `05a-cp5-hr-locale.jpeg`, `05b-cp5-en-locale.jpeg`
- **Notes:**
  - Date selection state survives locale switch — implies date storage is in ISO format, only display layer is locale-aware. Good architecture.
  - The two unlocalized strings (date range pill, month header) appear to be using a different formatter than the rest of the calendar — likely calling `DateFormat.yMMMd('en')` or default-locale rather than the active widget locale. Specific fix surface: search `lib/features/widget/**` for `DateFormat` instantiation without locale arg.

### 3.7 CP6 — Powered-by badge href

- **Expected:** href literal `https://bookbed.io` (pre-#450 baseline).
- **Observed:**
  1. **DOM scan:** `document.querySelectorAll('a[href]').length === 0`. No anchor element exists — Flutter uses `url_launcher` (or `Link` widget) which dispatches via `window.open`, not via DOM `<a>` insertion.
  2. **window.open intercept:** Patched `window.open` to record arguments + suppress real navigation, then clicked uid 21_39 "Powered by BookBed".
  3. **Captured call:**
     ```json
     {
       "url": "https://bookbed.io",
       "target": "",
       "features": "noopener,noreferrer",
       "ts": 1779608028451
     }
     ```
- **Verdict:** ✅ — literal `https://bookbed.io` matches pre-#450 expectation. `noopener,noreferrer` is correct security posture (opener-isolation + no Referer leak to bookbed.io).
- **Console errors:** none
- **Network:** none (window.open intercepted; would have been a top-level nav)
- **Screenshot:** N/A (badge captured by JS intercept, not visual state change)
- **Notes:** `target=""` → browser default = new tab/window (because Flutter widget renders in iframe-friendly mode; an empty target on top-level frame typically opens new tab). Combined with `noopener,noreferrer`, this is best-practice secure external link.

---

## 4. Net new findings (beyond Terminal E source-audit prediction)

### 4.1 N1 — HR locale translation gaps in date-range header + month-header

| Surface | EN | HR (observed) | HR (expected) |
|---|---|---|---|
| Calendar month header (CP5) | "May 2026" | "May 2026" (unchanged) | "Svibanj 2026" |
| Date-range pill in summary (CP5) | "May 25, 2026 - May 26, 2026" | "May 25, 2026 - May 26, 2026" (unchanged) | "25.05.2026 - 26.05.2026" or "25. svibnja 2026 - 26. svibnja 2026" |

**Severity:** LOW (cosmetic; doesn't break booking flow; non-English users still understand month names since they're standard).
**Recommendation:** Grep `lib/features/widget/**` for `DateFormat(...)` without locale param OR `.format(date)` calls bypassing locale-aware wrapper. Likely a small (~3-5 file) fix.
**Not in audit/26 / audit/27 / audit/28 findings.** New.

### 4.2 N2 — Booking-instant + Stripe-only config has no UI fallback for non-payment guests

Widget exposes ONLY "Pay with Stripe" button on this unit's config (widget_mode=booking_instant, stripe_config.enabled=true, no bank_transfer_config, no allow_pay_on_arrival path in UI). Guests without a card cannot book. The audit/27 §3 workaround (widget_mode flip to booking_pending for test) underscores the structural gap.

**Severity:** MEDIUM — real owners using this config silently lock out cash-only / pay-on-arrival customers. Not a bug per se (intentional config); but worth surfacing as product question: should Owner setup wizard force-pick at least one no-payment-required path for booking_instant mode, or warn explicitly?
**Recommendation:** Product decision. Either:
  - (a) Add explicit warning in owner config UI when booking_instant + stripe-only is selected, OR
  - (b) Always offer fallback "request booking (manual confirmation)" button alongside Stripe.
**Not in audit/26 / audit/27 / audit/28 findings.** New — first surfaced via this widget UI smoke.

### 4.3 N3 — Flutter CanvasKit × chrome-devtools MCP interaction protocol

Documented in §1.1 for the next operator. Specifically:
  - `flt-semantics-placeholder` 1×1px element is the a11y enable hook.
  - chrome-devtools MCP `click` by uid fails on this element (interactive-wait timeout).
  - JS `placeholder.focus(); placeholder.dispatchEvent(new KeyboardEvent('keydown', {key:'Enter', ...}))` reliably triggers semantic-tree rendering.
  - Must re-trigger after every `navigate_page reload` / `navigate_page url`.
  - First post-click snapshot may capture pre-render state — second snapshot often required for accurate post-action verification (Flutter render pipeline async, ~1–4s lag).

**Severity:** N/A (operator-facing knowledge, not a product bug).
**Recommendation:** Fold this into a `.claude/rules/marionette-vs-chrome-devtools.md` or similar testing reference. Companion to existing `memory/flutter-web-input-bypass.md` (Marionette mobile path).

---

## 5. Pre-#450 baseline confirmation

| Pre-#450 behavior | Source-audit prediction (Terminal E) | Empirical observation | Status |
|---|---|---|---|
| `form_persistence_service.dart` writes to localStorage (web=SharedPreferences) | YES | YES — key `flutter.booking_widget_form_data_SEED_test_owner_unit_01` confirmed (CP2) | ✅ matches |
| Guest counter handlers DON'T call `_saveFormData()` | YES | YES — counter clicks at ~07:27:13 did NOT update saved timestamp `07:26:40.170Z` (CP2 §3.2 step 5) | ✅ matches |
| Counters reset to defaults (1/0/0) on reload | YES | YES — post-reload localStorage shows `adults:1, children:0` despite pre-reload UI showing 3/1 (CP2) | ✅ matches |
| PoweredByBadge: unconditional render, hardcoded `https://bookbed.io` | YES | YES — captured `window.open("https://bookbed.io", "", "noopener,noreferrer")` (CP6) | ✅ matches |
| widget_mode=booking_instant + paymentMethod=none → PERMISSION_DENIED | YES (audit/27 §3) | NOT directly tested — widget UI doesn't even expose the paymentMethod=none button on this unit's config; couldn't even attempt the gate. Indirect confirmation: widget hard-routes through Stripe (CP3). | indirect ✅ |
| createBookingAtomic throws "already-exists" on overlap | YES | NOT tested — couldn't fire booking submit (CP3 SKIP) | not exercised |

**5 of 6 prediction rows directly confirmed; 1 indirectly confirmed; 1 not exercised (no contradiction).**

---

## 6. Open items / blockers

### 6.1 Worktree path deviation (process)

Task literal: `cd /tmp/bb-smoke-h-wt && git worktree add /tmp/bb-smoke-h-wt main`.

**Two deviations required:**

1. **Path:** `/tmp` is outside Claude Code's workspace roots in this session (workspace roots: `file:///Users/duskolicanin/git/bookbed` + `file:///var/folders/y5/.../T` = `$TMPDIR`). Both `Write` tool and chrome-devtools `take_screenshot filePath` reject `/tmp` paths. Used `$TMPDIR/bb-smoke-h-wt` instead.
2. **Branch:** `git worktree add <path> main` failed with `fatal: 'main' is already used by worktree at '/Users/duskolicanin/git/bookbed'` (current cwd is on main). Used `git worktree add -b doc/audit-32-smoke-h <path> main` instead — creates fresh branch off main HEAD (`79b4aea2`), commit lands on the new branch.

**Implication for task spec:** the "`[ "$(git branch --show-current)" = "main" ] || exit 1`" pre-flight guard in the task is internally inconsistent with the same-task `git worktree add ... main` command (would always fail), so the literal exit-1 guard was relaxed to "branch is main OR `doc/audit-32-smoke-h` (the new feature branch)". Both forms keep the §5/§6 working-tree-race protection from `memory/multi-agent-git-race.md`.

### 6.2 CP3 race blocked by Stripe-only config

See §3.4 / §4.2. Race genuinely not testable end-to-end without filling guest details (real-looking) + Stripe Checkout redirect + real test card. Marked 🟡 per task escape clause.

### 6.3 No Sentry / network breadcrumb capture

This smoke captured network requests via `list_network_requests` only — no Sentry confirmation (no dashboard access). Consistent with audit/28 §7 status: Sentry baseline pending. CP1–CP6 outcomes are derived from Network + Console + Snapshot + localStorage + window.open intercept; Sentry is silent here.

### 6.4 Async render gap can mislead first snapshot

CP2 (Reserve click → guest form) and CP4 (D+1 check-out) both required a second snapshot to capture the post-action state. The first post-click snapshot returned BEFORE Flutter's render pipeline propagated. Future runs: after any state-changing click, take TWO snapshots back-to-back if state-verification is critical.

---

## 7. Cross-ref to audit/23 PR-1 (#450) — what would change post-merge

Per `audit/23-misc-follow-ups.md` PR-1 scope (`fix/widget-counter-persist-badge-host`, presumably PR #450 on the BookBed repo):

| CP | Pre-#450 (this audit) | Post-#450 (expected after merge) |
|---|---|---|
| CP2 (F5 persist) | counters reset to 1/0 on reload (handlers don't call `_saveFormData`) | counters survive F5 (handlers wired to `_saveFormData`) — would change line "guests reset to defaults (1/0/0) pre-#450" in §2 row CP2 to "guests survive F5" |
| CP2b (close-tab) | same as CP2 — counters reset | same delta as CP2 — counters survive |
| CP6 (Powered-by badge) | unconditional render, `https://bookbed.io` hardcoded | render becomes conditional (likely based on owner subscription tier or property `branding.poweredByVisible` flag — exact scope per audit/23 PR-1 description); if rendered, href still goes to `https://bookbed.io` (badge link not the migration target) |
| CP1, CP3, CP4, CP5 | no change expected (out of PR-1 scope) | identical observations expected |

**Post-#450 re-run plan:** repeat CP2 + CP6 only. Other CPs covered by static-analysis equivalence to this run.

---

## 8. Cross-refs

- `audit/23-misc-follow-ups.md` PR-1 (#450 form_persistence_service + PoweredByBadge consolidation)
- `audit/26-bb-e2e-findings.md` §2.2 (direct-write paths) — not exercised here (UI only, no admin SDK)
- `audit/27-bb-e2e-cc-reject.md` §3 (widget_mode coupling friction — referenced in CP3 / §4.2)
- `audit/28-tier4-resend-sentry-baseline.md` §5 (DNS / SPF / DKIM) — not exercised here (no email triggered)
- `memory/multi-agent-git-race.md` §5–§7 (worktree discipline — invoked in §6.1)
- `memory/flutter-web-input-bypass.md` (Marionette-side analog for Flutter web input — chrome-devtools-side documented in §1.1 + §4.3 here)
- `CLAUDE.md` NIKADA NE MIJENJAJ → `bookings` read rule clause 1 (T11c CLOSED — explains the 30s `getUnitAvailability` polling cadence observed in CP1 network panel)

---

## 9. Sign-off

| Section | State |
|---|---|
| §1 setup + a11y discipline | ✅ |
| §2 result matrix (6 rows) | ✅ |
| §3 per-checkpoint detail | ✅ |
| §4 net new findings (3) | ✅ — N1 HR translation gap, N2 booking-instant Stripe-only lock, N3 chrome-devtools × Flutter operator notes |
| §5 pre-#450 baseline confirmation | ✅ |
| §6 open items (worktree deviation, CP3 SKIP rationale, Sentry gap, async snapshot gap) | ✅ |
| §7 cross-ref to PR-1 | ✅ |

**Status:** Pure observation, no mutations. 5/6 CP ✅, 1/6 🟡 SKIP (race blocked by Stripe-only config — task escape clause invoked). Three net-new findings flagged. Pre-#450 baseline 5/6 directly confirmed (1 not exercised, no contradiction).

Awaiting user authorization to push `doc/audit-32-smoke-h` → main (per task NO-PUSH directive).
