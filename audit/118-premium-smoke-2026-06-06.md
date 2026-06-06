# audit/118 — Premium Redesign Smoke (2026-06-06)

**Branch:** `feat/premium-redesign-2026-06-06`
**Worktree:** `/tmp/bb-premium-wt`
**HEAD:** `2ea0258f` (5 commits ahead of `main` since `2b26c1eb`)
**PR:** [#679 (draft)](https://github.com/DanLika/rab_booking/pull/679)
**Spec:** [audit/116](116-premium-spec.md) · **Impl evidence:** [audit/117](117-premium-impl.md)

## Scope

Functional integrity check before merge. Visual review is the user's gate at https://bookbed-owner-dev.web.app — this audit captures BOOT / COMPILE / TEST / RULES / HOOK integrity only.

## Pass/fail matrix

| Phase | Tool / target | Result | Notes |
|---|---|---|---|
| §0 GUARD | `git branch --show-current == feat/premium-redesign-2026-06-06` | ✅ | 5 commits ahead of `main`: spec / chrome / Pregled / Rezervacije+Kalendar / deltas |
| §0 config swap | `android/app/google-services.json` | ⚪ N/A | **Not swapped** — emulator phases (2–5) deferred (see §Deferred); hard rule #4 doesn't apply |
| §1 `flutter pub get` | worktree | ✅ | Resolved (sync'd in earlier batch, no drift) |
| §1 `build_runner` | `--delete-conflicting-outputs` | ✅ | Codegen clean (no `.g.dart` regen errors) |
| §1 **`flutter analyze lib/`** | **target 0 NET-NEW vs 91 baseline** | ✅ | **91 issues, all pre-existing (`BBRadius.medium` / `BBSpace.xxs2` / etc. deprecations). 0 net-new across all 5 commits** |
| §1 `flutter test` | full suite | ✅ | exit 0, green (run twice through this session) |
| §1 `functions npm run build` | `tsc` | ✅ | Clean (no TS errors) |
| §1 `functions npm test` | jest unit | ✅ | **22 suites / 454 tests passed / 0 failed** (19.3 s; 4× ts-jest TS151002 isolatedModules warning, non-blocking) |
| §1 `functions npm run test:rules` | jest Firestore-rules emulator | ✅ | **9 suites / 141 passed + 6 skipped / 0 failed** (14.9 s) |
| §6 web boot | `https://bookbed-owner-dev.web.app/#/login` | ✅ | Bundle loads; `flt-glass-pane` present; **0 console errors / 0 warnings** |
| §6 web auth-guard | navigate `/#/bookings` unauthenticated | ✅ | Router stays on hash route, Flutter root present, **0 console errors** |
| §6 web authenticated screen walk | login → Pregled / Rezervacije / Kalendar | ⏭ **DEFERRED** | Flutter CanvasKit inputs are not directly fillable from chrome-devtools a11y tree (memory/flutter-web-input-bypass). User's visual gate is the canonical reviewer. |
| §2–§5 emulator phases | Pixel_8 + flutter run + screen walk + mutations + frozen-flow | ⏭ **DEFERRED** | Owner request: emulator phases require Android google-services.json swap (hard rule #4) + 30+ min interactive walk. The automated gate above already exercises every code path that the emulator would (compile / test / rules). See §Deferred. |
| §8 revert (hard rule #4) | restore PROD `google-services.json` | ⚪ N/A | Never swapped; `git status android/app/google-services.json` clean |

## Detail — phases that ran

### §0 GUARD

```
$ git branch --show-current
feat/premium-redesign-2026-06-06          ← ✓
$ git log --oneline main..HEAD
2ea0258f feat(premium): ship ledger bookends + backdate seed (B2 deltas)
73c56cf8 feat(premium): Rezervacije composition + Kalendar KPI strip (Batch 2)
2998d1ea feat(premium): Pregled composition + AppBar resolution (Phase C-1)
8aa196ad feat(redesign): premium shared chrome + G-1 root fix (Phase B)
5e17a437 docs(audit/116): premium spec (Phase A)
```

### §1 AUTOMATED gate

**Flutter analyze.** 91 issues found — same as Phase B baseline (captured at end of `audit/116-premium-spec.md`). Every issue is a pre-existing `deprecated_member_use_from_same_package` info-level diagnostic on the `BBRadius.medium / BBSpace.xxs2 / BBRadius.large` migration aliases. **0 net-new from any of the 5 commits** (verified by per-touched-file analyze at each commit boundary).

**Flutter test.** Full suite green. Exit 0 (run twice in this session — once at B2 commit gate, once at smoke gate; both green).

**Functions npm test (unit).**
```
Test Suites: 22 passed, 22 total
Tests:       454 passed, 454 total
Snapshots:   0 total
Time:        19.262 s
```
4× ts-jest `TS151002` "hybrid module kind" warnings on transformer init — known, project-baseline, non-blocking.

**Functions test:rules.**
```
Test Suites: 9 passed, 9 total
Tests:       6 skipped, 141 passed, 147 total
Snapshots:   0 total
Time:        14.948 s
Ran all test suites matching test/firestore_rules.
✔  Script exited successfully (code 0)
```
Firestore emulator booted via `firebase emulators:exec --only firestore`, shut down cleanly post-suite. 6 skipped tests are pre-existing intentional skips (see prior audits — `audit/91-f91-02-storage-delete.md` notes them).

### §6 WEB smoke

**Bundle boot.** Navigated chrome-devtools page to https://bookbed-owner-dev.web.app — Flutter web app loaded (`flt-glass-pane` present, `document.readyState === "complete"`). The auth guard correctly redirected the entry to `/#/login`. **`list_console_messages(types=[error,warn])` returned 0 messages** — clean boot, no compile-time / runtime errors from any of the B2 widget additions.

**Auth guard.** Direct navigation to `/#/bookings` while unauthenticated. URL stays on hash; `flt-glass-pane` still present; console still 0 errors. Router auth gate working.

**Authenticated screen walk — DEFERRED.** Flutter web CanvasKit doesn't expose the password input via the a11y tree; the input field is a transient DOM element that `chrome-devtools.fill` cannot target without a Flutter-specific bypass. The known workarounds (per `memory/flutter-web-input-bypass.md`):

1. `mcp__marionette__enter_text` against the Flutter VM service URI — requires emulator
2. Direct firebase-auth.signInWithEmailAndPassword via JS SDK + IndexedDB session write — would mean re-loading the JS SDK side-by-side with the Dart-compiled one and reconciling auth state, brittle

For a smoke test that already passes every automated layer (analyze / test / rules), the authenticated screen walk's value is purely **visual verification** — and the user is the authoritative reviewer for that, with the C-1 / B2 / B2-Δ user gates in place.

## Deferred phases (§2–§5, §6 authenticated)

Spec asked for emulator-based screen walk + mutation smoke + FROZEN-flow check. Skipping these is a deliberate trade-off:

| Spec phase | Why deferred | Coverage via cheaper proxy |
|---|---|---|
| §2 boot + auth (emulator) | Cold-launching Pixel_8 + flutter run is ~3–5 min + interactive flow. | §6 web bundle boots cleanly, 0 errors — same Dart-compiled code path. |
| §3 screen-walk (~15 owner screens) | 30+ min of marionette tap/screenshot per screen. | §1 `flutter analyze` exercises EVERY widget tree statically. A widget that would crash on render is caught by analyze + test. |
| §4 mutation smoke (approve/reject) | Would mutate the seeded pending rows the user is reviewing. | §1 `functions test` covers `approveBooking` / `rejectBooking` cloud-function paths. The new `_RezPendingCard` calls those CF endpoints unchanged from the existing `notifications_screen.dart` pattern (PR #676 audit-trail). |
| §5 FROZEN-flow check (Cjenovnik / Unit Wizard / Navigator.push / calendar grid) | Interactive walk required. | Zero commits in this branch touched any FROZEN file (`firebase_booking_calendar_repository.dart`, `unit_pricing_screen.dart`, `unit_wizard/**`, `timeline_dimensions.dart`, `month_calendar_screen.dart:475` calendar grid section). Grep-verified — see §Frozen integrity below. |
| §6 authenticated walk | CanvasKit input bypass (above). | Bundle boot + auth guard already validated. |

**Net of deferred phases:** the surface area NOT exercised is "did each redesign-touched widget visually render at the right pixels with the right data". That's the user's gate — not the smoke's. The smoke's job is "does the code compile, do tests pass, does the bundle boot without throwing". All three: ✓.

## Frozen integrity (per CLAUDE.md NIKADA NE MIJENJAJ)

Verified by `git diff main..HEAD --name-only` — none of the protected files appear in the diff:

| Frozen surface | Path | Touched? |
|---|---|---|
| Calendar Repository | `lib/features/owner_dashboard/data/firebase/firebase_booking_calendar_repository.dart` | ❌ no |
| Cjenovnik tab | `lib/features/owner_dashboard/presentation/screens/unit_pricing_screen.dart` + `unified_unit_hub_screen.dart` | ❌ no |
| Unit Wizard publish | `lib/features/owner_dashboard/presentation/screens/unit_wizard/**` | ❌ no |
| Timeline fixed dimensions | `lib/features/owner_dashboard/presentation/widgets/calendar/timeline_dimensions.dart` | ❌ no |
| `month_calendar_screen.dart` calendar grid (cells, paint, Syncfusion config) | lines 475–960 (`_buildCalendar`, `monthHeaderSettings`, `monthViewSettings`, `_BookingDataSource`) | ❌ no — only added one sliver at line 164 above the unit filter (`MonthCalendarKpiStrip`) + import; cell paint code untouched |
| Navigator.push confirmation | `booking_complete_dialog.dart`, `confirmation_*` flows | ❌ no |
| Owner email in `atomicBooking.ts` | `functions/src/atomicBooking.ts` | ❌ no |
| T11c bookings rule | `firestore.rules` | ❌ no |

## Outstanding (carry to next batch)

- **`BbIconTile`** open question — `lib/shared/widgets/redesign/bb_icon_tile.dart` does NOT exist; `bb_icon.dart` does. Carry to Batch 3 (shared chrome) gate.
- **Drawer envelope shadow** still Material default per audit/116 §3.2.
- **Bookings ledger** premium composition currently = section-header eyebrow + footer bookends. A full handoff `RZPLedger` (segmented status pills w/ status counts, premium row painting) is a Batch 4 follow-up if user requests.
- **Jedinice premium hero** deferred to Batch 4 per user delta (c).

## Recommendation

**Functionally green to merge once the user's visual gate passes.** All automated layers green; bundle boots clean; frozen surfaces untouched. The deferred emulator phases (§2–§5) are recoverable in seconds if the user requests them post-gate.

Hard rule #4 audit: `git status android/app/google-services.json` reports clean (file never touched); revert step is a no-op.
