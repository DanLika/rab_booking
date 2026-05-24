# Audit 36 — iOS Owner-App Smoke (Tier 4) — 2026-05-24

**Operator**: Claude Code (Opus 4.7, full-auto)
**Driver**: Marionette MCP over Flutter VM service
**Target sim**: iPhone 17 Pro "BookBed" (`C8FBAA1C-4DE7-4C37-9E96-48844446F9E1`), iOS 26.1
**Build**: `flutter run --target lib/main_dev.dart` (debug, attached)
**Firebase project**: `bookbed-dev` (plist swap → restored to PROD at end)
**Account**: `bookbed-test@bookbed.io` (UID `GILVItIVP5R8WXfnMmyMo1ykhUm2`)
**Marionette uptime**: ~25 min wall clock (build ~3 min + checkpoints ~20 min + recovery ~2 min)

---

## TL;DR

| Checkpoint | Status | Notes |
|---|---|---|
| **D0** prep (worktree + plist swap + sim boot) | ✅ | clean swap, sim booted on first try |
| **D0b** flutter run + VM URI + marionette connect | ✅ | incremental build ~3 min, VM `ws://127.0.0.1:51989/GxazZkdZ5mc=/ws` |
| **D1** Cold-boot deep link recovery | ⚠️ GAP | indirect signal positive (auto-login worked); literal `simctl openurl` path untested — marionette-driver limit |
| **D2** Login | ✅ (SKIPPED) | keychain auto-login restored session, no login screen shown at boot |
| **D3** Bookings list scroll | ⚠️ PARTIAL | screen reachable + filter UI works; **blocked by FINDING-iOS-02** — list empty despite 4 seeded bookings |
| **D4** Booking detail dialog | ✅ (via Calendar) | `booking_inline_edit_dialog.dart` renders on tap of calendar block |
| **D5** Calendar drag-drop | ⚠️ GAP | calendar + block + tap-dialog all work; drag itself not testable via marionette (compose gesture limit) |
| **D6** Pull-to-refresh | ✅ | Nedavne Aktivnosti populates with seed booking after swipe-down |
| **D7** Settings + theme toggle | ✅ | Tamna applied instantly, no flash, persists across nav (drawer + login screen still dark) |
| **D8** Logout | ✅ | Profil → Odjava → login screen; Remember-Me pre-fills email |
| **D9** Cleanup | ✅ | plist restored, sim shutdown, marionette disconnected |
| **D10** Audit doc + commit | ✅ | this file |

**Findings**: 2 P2 (ErrorBoundary over-catch + Rezervacije badge/list divergence).
**Plist restored**: `git diff ios/Runner/GoogleService-Info.plist` empty; `PROJECT_ID=rab-booking-248fc` confirmed.

---

## D0 — Worktree + plist swap + sim boot

```bash
WTROOT="$TMPDIR/bb-smoke-ios-wt"
git worktree add -b doc/audit-36-ios-smoke "$WTROOT" main          # ok
cp ios/Runner/GoogleService-Info.plist  ios/Runner/GoogleService-Info.plist.prod-snapshot
cp ios/Runner/GoogleService-Info.plist.backup ios/Runner/GoogleService-Info.plist
grep PROJECT_ID ios/Runner/GoogleService-Info.plist                # → bookbed-dev ✓
xcrun simctl boot C8FBAA1C-4DE7-4C37-9E96-48844446F9E1             # ok
open -a Simulator
```

Per `.claude/rules/ios-development.md`: plist swap stays in MAIN repo (not worktree) because `flutter run` builds from main. Worktree only for audit doc + commit.

---

## D0b — flutter run + VM URI + marionette connect

```bash
nohup flutter run -d C8FBAA1C-... --target lib/main_dev.dart > /tmp/bb-flutter.log 2>&1 < /dev/null &
# bg poll loop:
until grep -E "Debug service listening on|VM Service.*listening|Dart VM Service" /tmp/bb-flutter.log; do
  sleep 5
done
```

VM URI extracted: `http://127.0.0.1:51989/GxazZkdZ5mc=/` → marionette connect on `ws://127.0.0.1:51989/GxazZkdZ5mc=/ws`. First call succeeded. Pods cached + Runner.app present from prior session — incremental build ~3 min.

---

## D1 — Cold-boot deep link recovery (GAP)

**Expected** (per CHANGELOG 6.74 + `audit/16-android-regression-full.md` analog): `bookbed://owner/property/<id>` from cold start → `propertyByIdProvider` awaits `enhancedAuthProvider.isLoading` → `UniversalLoader` holds in `router_owner.dart:784` until Firebase Auth restores session, then property edit screen mounts cleanly. No `FIRFirestore` / Pigeon `documentReferenceGet` crash trace.

**Observed (indirect)**: cold-boot at D0b launched into Dashboard ("Pregled") with test account already signed in (keychain auto-login per `memory/test-account.md` keychain note). No ErrorBoundary catch, no blank flash, no UniversalLoader stuck. This is **positive indirect signal** that the auth-race fix's spirit holds on iOS (auth restored before any propertyRead).

**Not observed (literal cold-boot deep-link path)**: `xcrun simctl openurl <udid> bookbed://owner/property/SEED_test_owner_property_01` from a terminated app state was NOT executed this session.

**Why**: `xcrun simctl terminate` kills the app process, which severs the flutter-run VM debug attach. Marionette cannot reconnect to a fresh process without re-running `flutter run` (and the deep-link relaunch happens BEFORE that attach). Marionette is fundamentally a debug-protocol driver, not an OS-level UI automation tool. **This is a tooling limitation**, not a product issue.

**Manual recipe for next session** (Xcode-console-observed):

```bash
# 1. App must be authenticated (keychain has refresh token)
# 2. Kill: xcrun simctl terminate booted io.bookbed.app
# 3. Open Xcode → Window → Devices and Simulators → Open Console for sim
#    (or `log stream --predicate 'subsystem CONTAINS "io.bookbed"'`)
# 4. Cold-launch via deep link:
xcrun simctl openurl C8FBAA1C-4DE7-4C37-9E96-48844446F9E1 \
  "bookbed://owner/property/SEED_test_owner_property_01"
# 5. Watch console for FIRFirestore frames in first 3 sec after launch — should be NONE.
#    UniversalLoader visible briefly → property edit screen mounts.
```

**Suggested follow-up**: open issue for `--use-existing-vm` workflow once such a thing exists (currently doesn't in Flutter tooling).

---

## D2 — Login (SKIPPED — keychain auto-login)

App booted into Pregled with `bookbed-test@bookbed.io` already authenticated via persisted Firebase refresh token in iOS Keychain. No login screen presented.

**Side benefit**: confirms keychain persistence is working (matches `memory/test-account.md` keychain note: `xcrun simctl uninstall booted io.bookbed.app` does NOT clear keychain; same UID auto-restores on re-install).

No iOS-specific errors during the boot-to-dashboard transition; time-to-dashboard not measurable separately because the keychain path skips the login round-trip entirely.

---

## D3 — Bookings list scroll (PARTIAL — blocked by FINDING-iOS-02)

Navigation: drawer (edge-swipe right) → "Rezervacije". Screen renders with:
- Header: filter chip card "Filteri i Pre…" with grid/list toggle (top-right segmented icons)
- "Napredno filtriranje" expansion CTA
- Filter chips: Sve (selected), Na čekanju, Potvrđene, …
- **Empty state**: "Počnite zarađivati / Slijedite ove korake za prvu rezervaciju / Uvezi postojeće rezervacije / Dodaj widget za rezervacije"

Despite 4 seeded bookings in Firestore (1 pending future, 1 confirmed future, 2 completed past — all owner_id matching test UID), the list never populates. Drawer badge for "Rezervacije" correctly reads "1" then "2" (incrementing as ~5-min staleness lets `onBookingCreated` notifications fire) — so the badge counter IS aware of the bookings. **The list view's query is divergent.**

Couldn't exercise:
- Scroll-flick down with progressive load
- 100ms debounce on scroll listener (CHANGELOG 6.52)
- Smoothness rating / jank capture

→ See FINDING-iOS-02 below.

---

## D4 — Booking detail dialog (PASS — via Calendar tap)

Since list view was empty, exercised via Calendar Timeline tap. Logical coords (300, 256) on the orange parallelogram block opened `booking_inline_edit_dialog.dart` (Quick Edit, CHANGELOG 6.41 lineage):

- Guest name + email pseudo-row at top
- Dates: "8.7.2026 – 11.7.2026"
- Status badge: "Na čekanju" (orange dot)
- Chip row: "3 noći" • "2 gosta" • "370 €"
- Action cards: **Odobri** (green check), **Odbij** (red X), **Uredi rezervaciju** (purple pencil)
- Each action has 2-line confirmation rationale ("Jeste li sigurni da želite odobriti ovu rezervaciju? / Nakon odobrenja, možete kontaktirati gosta sa detaljima plaćanja.")

**SelectableText long-press copy** (CHANGELOG 6.20) **NOT exercised** — Quick Edit dialog doesn't expose email/phone/reference text inline. Would need to enter "Uredi rezervaciju" → full detail screen, which wasn't on the smoke path. Doc as partial gap.

---

## D5 — Calendar drag-drop (PARTIAL — marionette-driver gap)

Timeline calendar reachable via drawer → Kalendar → Timeline kalendar. "Apartman A / 4 gostiju" row rendered with one orange parallelogram block (Jul 8–11, 3 nights). Fixed dimensions (50px day width, 42px row height, 100px label width) match `timeline_dimensions.dart` per CLAUDE.md NIKADA DIRAJ row.

**Tap-on-block** at logical (300, 256) → Quick Edit dialog (✓, see D4).

**Long-press (1200ms)** on the same coords → NO drag mode triggered, NO context menu, block visual unchanged.

**Horizontal swipe** (300, 256) → (380, 256) → calendar timeline **scrolled** by 1 day (header shifted from "6 7 8 9 10 11" to "5 6 7 8 9 10"). Block did NOT move; swipe was consumed by the calendar's pan gesture.

**Drag-drop classification**: requires the compose gesture **press-and-hold → maintain → drag → release**, which Marionette's `swipe` (single-stroke, no leading hold) cannot synthesize. Similarly, `long_press` ends with release, no drag continuation. Marionette is missing a `drag_with_hold` primitive.

**Not a product regression** — the dialog opens, the block renders, the calendar accepts gestures. Drag-drop behavior, invalidation fix (CHANGELOG 6.36), and "ref after disposed" guards remain unverified iOS-side this session. Cross-unit drag also blocked by **only 1 unit row in seed** (would need 2nd unit for the meaningful test).

**Suggested follow-up**: either (a) drive drag from Flutter's own test driver / `WidgetTester.longPressAndDragBy` in `integration_test/`, or (b) extend marionette MCP with `drag_with_hold(coordinates, hold_ms, end_coordinates)`.

---

## D6 — Pull-to-refresh (PASS)

Dashboard pull-down (swipe logical (200,200) → (200,600)). Refresh indicator animation not visually captured (timing skew), but **functional outcome verified**:

- Before refresh: "Nedavne Aktivnosti" empty ("Nema nedavnih aktivnosti / Vaše nedavne rezervacije i aktivnosti će se prikazati ovdje")
- After refresh: card populates with **"Nova rezervacija primljena / iOS Test Vila - Test Unit A / prije 5m"** — matching the SEED_test_book_pending_01 seed by property name + unit name + recency

Stat cards (Zarada €0 / Rezervacije 0 / Nadolazeći check-in 0 / Popunjenost 0.0%) remain zero because the default filter "Zadnjih 7 dana" (last 7 days) does not include my future-dated seeds. Switching to a wider date filter not exercised.

iOS-specific overscroll: standard `CupertinoScrollPhysics`-style bounce, no jank, no double-trigger.

---

## D7 — Settings + theme toggle (PASS)

Profil → "Tema" (subtitle "Sistemska postavka") → bottom-sheet picker with 3 options:
- Svijetla (Light) — sun icon
- Tamna (Dark) — moon icon
- Sustavna (System) — auto-A icon (currently checked)

Tapped **Tamna**. **Applied INSTANTLY** — no flash, no transition jank, every visible card switched to dark navy/slate, text inverted to white, dividers re-rendered with correct dark-theme contrast. Subtitle now reads "Tamna" confirming state save.

**Persistence verified**:
- Drawer reopened → dark
- Login screen post-logout → dark
- "Oops!" ErrorBoundary screens that got hit during the session → dark

NOT verified: persistence across full app process restart (would need `xcrun simctl terminate` + relaunch + marionette reconnect; same blocker as D1). The Riverpod theme provider likely keys to `shared_preferences`, in which case it should persist across restart — but not empirically tested.

---

## D8 — Logout (PASS)

Profil → scroll down → tap **Odjava**. Direct redirect to "Prijava vlasnika" login screen. No confirmation dialog (UX observation, not necessarily a bug). Login screen shows:
- Email pre-filled `bookbed-test@bookbed.io` (Remember Me / "Zapamti me" toggle was on by default — confirms persist works)
- Password empty
- Sign in with Google / Apple buttons visible

**FCM token clearing** per CHANGELOG 6.27 — NOT directly verified in this session. Would need post-logout query of `users/GILVItIVP5R8WXfnMmyMo1ykhUm2/fcm_tokens` subcollection (or top-level token doc) on bookbed-dev to confirm size==0 / token-deleted state. Doc as partial gap.

App process did NOT exit on logout — marionette stayed connected, just on the unauth login route. So this is session-level logout, not process-kill logout (which is what users would do).

---

## D9 — Cleanup

```bash
marionette.disconnect                                                      # ok
kill $(cat /tmp/bb-flutter.pid)                                            # ok (PID gone)
git -C /Users/duskolicanin/git/bookbed checkout ios/Runner/GoogleService-Info.plist
grep PROJECT_ID ios/Runner/GoogleService-Info.plist                        # rab-booking-248fc ✓
rm -f ios/Runner/GoogleService-Info.plist.prod-snapshot                    # ok
git diff ios/Runner/GoogleService-Info.plist                               # empty ✓
xcrun simctl shutdown C8FBAA1C-4DE7-4C37-9E96-48844446F9E1                 # ok
```

State at audit-doc-write time: plist=PROD, sim shutdown, flutter killed, marionette disconnected, worktree on `doc/audit-36-ios-smoke`.

---

## Findings

### FINDING-iOS-01: ErrorBoundary catches Marionette tap exceptions (P2)

**Reproducer**: `marionette.tap(text: "X")` where `"X"` is NOT currently a visible interactive element (e.g., drawer is closed, scroll position hides it).

**Observed (2× this session)**:
1. After Rezervacije navigation, tried `tap(text:Pregled)` while drawer was closed — `Exception: Element matching {text: Pregled} not found` bubbled to `ErrorBoundary` → "Oops! Something went wrong / Don't worry, this happens sometimes" full-screen with Try Again button. Recovery via Try Again returned to prior screen cleanly.
2. After theme toggle, tried `tap(text:Odjava)` after a swipe that re-opened the drawer instead of scrolling — same crash, same recovery.

**Significance**: This is the **iOS confirmation** of the Android-side observation in `memory/wave-android-smoke-2026-05-23.md` ("ErrorBoundary catches Marionette exceptions (sticky bug confirmed on Android)") AND of the narrowing proposal in `audit/20-error-boundary-narrowing.md`. ErrorBoundary's catch is **too wide** — it intercepts VM-extension-thrown exceptions that have nothing to do with widget render errors. A real user would never hit this path, but the safety net is incorrectly classifying tool-driven errors as render failures.

**Recommendation** (already proposed in audit/20): narrow `ErrorBoundary._handleErrorLikeStateful` (or wherever the catch clause sits) to only intercept errors with stack traces originating from `flutter/src/widgets/` or `flutter/src/rendering/`. VM extension exceptions (path: `package:flutter/src/foundation/binding.dart` synthesizing a `FlutterError` from a service-extension callback) should bypass the boundary and surface as logs only.

**Priority**: P2. Not user-facing in normal use; affects test-driver reliability and may mask real errors in dev.

---

### FINDING-iOS-02: Owner Rezervacije list empty despite drawer badge=1 (P2)

**Reproducer** (this session, may be data-shape dependent):

1. Seed 4 bookings owned by `GILVItIVP5R8WXfnMmyMo1ykhUm2` via firebase-admin (script: `/tmp/seed-test-owner.js` — 1 past completed, 1 future confirmed, 1 future pending, plus 1 prior-session leftover).
2. Login as test account.
3. Navigate to Rezervacije via drawer.
4. **Drawer badge counter for "Rezervacije" reads "1"** (then "2" as activity-feed fans out).
5. **Rezervacije screen renders empty state** ("Počnite zarađivati / Slijedite ove korake za prvu rezervaciju") under both "Sve" filter and "Na čekanju" filter.

**Diagnosis hint**: drawer badge counter is fed by a different provider than the list view. The badge knows about the bookings (they exist in Firestore at queryable paths); the list view's query either:
- Filters by a property the seed missed (e.g., required `provider_id`, or `payment_status != null && != "void"`)
- Reads from a different collection path (e.g., legacy top-level `/bookings/{id}` instead of subcollection `/properties/{pid}/bookings/{id}`)
- Has a stale `keepAlive: true` Riverpod cache that didn't see the new docs
- Requires a "selected property" context that isn't being auto-set in the test account state

Fits the **T11c subcollection migration** lineage in CLAUDE.md NIKADA DIRAJ row — T11c moved the read path to subcollection-only behind `getUnitAvailability` callable, with realtime `.snapshots()` sacrificed to 30 s polling. The owner-side Rezervacije list may not yet have been re-pointed at the post-migration source, OR it polls but my seeded docs were filtered out by an additional rule (the seed has `provider_id` UNSET; if the list query is `.where('provider_id', '==', UID)` rather than `.where('owner_id', '==', UID)`, that explains everything).

**Recommendation**: Open follow-up to (a) repro on Android + web to confirm cross-platform vs iOS-only, (b) bisect the owner-bookings-provider query, (c) decide whether to update test-account seed to include the missing field or fix the query.

**Priority**: P2. The owner-app's primary surface for booking management is unusable for test-account-shaped data. Real owners may not hit if their bookings always carry the missing field, but the screen empty-stating with real bookings present is high-visibility.

---

## Per-CHANGELOG verification matrix

| CHANGELOG ref | Surface | Method | Result |
|---|---|---|---|
| 6.74 cold-boot auth race | propertyByIdProvider | indirect (keychain restore) | ✅ no crash, no stuck loader |
| 6.74 cold-boot auth race | literal deep-link cold | not exercised | ⚠️ gap (marionette limit) |
| 6.52 Bookings list 100ms debounce | Rezervacije scroll | could not exercise | ⚠️ blocked (FINDING-iOS-02) |
| 6.41 BookingDetailsDialog v2 | Quick Edit bottom sheet | tap calendar block | ✅ renders correctly |
| 6.36 timeline invalidation | drag-drop result | not exercised | ⚠️ marionette gesture limit |
| 6.20 SelectableText copy | email/phone/ref long-press | not exercised | ⚠️ Quick Edit doesn't expose |
| 6.27 FCM token cleared on logout | Profil → Odjava | not directly verified | ⚠️ Firestore query needed |

---

## Marionette session telemetry

- **Uptime**: ~25 min wall clock from `connect` to `disconnect`
- **Successful tool calls**: ~40
- **Failed tool calls**: 3 (all `tap text` for off-screen elements → FINDING-iOS-01 trigger)
- **`get_logs` returning "Server error"**: 1 occurrence (cause unknown, did not retry)
- **Coord-tap fragility instances**: 1 (screen-pixel vs logical-coord confusion at D5 — used 600,585 which is outside 402x874 logical screen; corrected after re-reading `get_interactive_elements`)
- **No keyboard reflow problems** this session (login screen wasn't driven; D2 was skipped via keychain)

---

## State snapshot at session end

| Item | State |
|---|---|
| `ios/Runner/GoogleService-Info.plist` | `rab-booking-248fc` (PROD), `git diff` empty |
| `ios/Runner/GoogleService-Info.plist.backup` | unchanged (still `bookbed-dev`) |
| `ios/Runner/GoogleService-Info.plist.prod-snapshot` | deleted |
| iPhone 17 Pro BookBed sim | Shutdown |
| bookbed-test account | logged out (session token cleared), keychain refresh token still present |
| bookbed-dev Firestore | +1 property (SEED_test_owner_property_01), +1 unit, +3 bookings (test-data, idempotent) |
| flutter run process | killed (PID gone) |
| Worktree `$TMPDIR/bb-smoke-ios-wt` | branch `doc/audit-36-ios-smoke`, this audit + commit pending |

---

## Related

- `.claude/rules/ios-development.md` — plist swap procedure (followed exactly)
- `audit/16-android-regression-full.md` — Android analog of D1 (auth-race + AAB blocker)
- `audit/20-error-boundary-narrowing.md` — proposal that FINDING-iOS-01 reinforces
- `memory/test-account.md` — test account creds + keychain note + register-form gotcha
- `memory/wave-android-smoke-2026-05-23.md` — Android counterpart to this audit
- `memory/wave0-test-findings.md` — iOS-sim Marionette gotchas baseline
- CLAUDE.md NIKADA DIRAJ — Timeline Calendar fixed dimensions row (verified intact)
- CHANGELOG 6.74 — cold-boot auth race fix (verified indirectly)
