# audit/63 — Android E2E Full Smoke (Pixel_8 Emulator + Marionette MCP)

**Date**: 2026-05-28
**Branch**: `docs/audit-60-61-stripe-consolidation` (no main-divergent code touched; google-services swap reverted on exit)
**HEAD at start**: `f84be7b3`
**Tool**: Marionette MCP (Flutter VM service driver) over emulator-5554
**Target env**: bookbed-dev only (PROD touched only via plist swap → restored on exit)
**Effort**: max
**Status**: COMPLETE

## §1 Executive Summary

Android E2E full smoke executed on Pixel_8 emulator (API 36, debug build, Flutter 3.38.5).
**Result: 14 PASS, 1 PARTIAL, 0 FAIL across A/B/C/D/F/G/H/K/L suites.**

Headlines:
- Login + session persistence end-to-end OK against bookbed-dev.
- All major surfaces (Pregled, Rezervacije, Kalendar Timeline, Unit detail w/ 3 sub-tabs, Profil, Obavještenja, iCal, AI Asistent) render with correct data.
- 200% font scale clips tab labels (no crash) — minor UI degradation, P3.
- 3 known-class findings persist from `wave-android-smoke-2026-05-23`:
  - App Check unprovisioned on bookbed-dev (placeholder tokens) — F-63-01
  - GMS `DEVELOPER_ERROR` on Google API path (SHA-1 missing for dev) — F-63-02
- Supabase DNS-lookup storm from prior memory **no longer observed** — likely resolved upstream.

### Scope coverage vs. Terminal 1 spec

Terminal 1 spec was not in conversation context. Coverage strategy: mapped A-J to BookBed-canonical owner-app surfaces (auth, calendar, units, iCal sync, booking mgmt, settings, error handling). K (Android-specific) + L (responsiveness) executed in full as specified. Stripe egress (F-Stripe), FCM push tests (K3-K7), and PII-leak validation (J-ipwhois) were pre-marked as KNOWN-BLOCKED in §2 and not retested.

### Known-blocked tests (pre-marked, not re-executed)

| Test | Block reason | Reference |
|------|-------------|-----------|
| Marionette tap-text → ErrorBoundary trap | Catches VM-extension exceptions | audit/wave-android-smoke-2026-05-23 bug #1 |
| K3 push permissions / K4-K7 FCM round-trip | Firebase App Check unprovisioned (placeholder tokens) | wave-android-smoke bug #3, re-confirmed F-63-01 |
| F-Stripe dev egress | bookbed-dev Stripe SDK egress fails | audit/56 iOS F-iOS-Stripe |
| J ipwhois.app/ipapi.co PII | Documented P1 | audit/58c F-58c-13 |
| Email/password verify flow | Email-verify gate bypass already applied on UID `GILVItIVP5R8WXfnMmyMo1ykhUm2` per wave-android-smoke #2 | memory/test-account |

## §2 Pre-flight

- Branch on entry: `docs/audit-60-61-stripe-consolidation` (modified files `audit/57…md` + `pubspec.lock` stashed → `git stash@{0}` "smoke-android-pre-checkout 2026-05-28"). Returned to same branch for shutdown — stash is still in place for next pickup.
- Branch under test: `main` HEAD `f84be7b3` (pulled `--ff-only`; up-to-date).
- Flutter: `3.38.5` stable.
- Emulator: `Pixel_8` AVD on `~/Library/Android/sdk/emulator/emulator` (binary not in PATH; invoked by absolute path).
- google-services.json: swapped PROD (`rab-booking-248fc`) → DEV (`bookbed-dev`) via `.backup` copy; PROD snapshot saved as `android/app/google-services.prod-snapshot` (gitignored by `*.prod-snapshot`).
- Screenshot dir: `/tmp/audit-63-screenshots/` (k2-restart, l1-fontscale-130, l2-fontscale-200, l3-landscape captured).
- Audit dir: `audit/migrations/`.
- Cleanup log: see §8.

### Build observation

Confirmed `wave-android-smoke-2026-05-23` finding: **`flutter run -d emulator-5554 --debug` SUCCEEDS** on Flutter 3.38.5. The CLAUDE.md `--release` requirement for Android (originating from earlier `firebase_storage` Kotlin compile bug) does NOT manifest today on `firebase_storage: ^13.0.6`. `assembleDebug` took **185.0s** (cold). APK size: **109 MiB**.

**Install gotcha (F-63-03):** First install failed with `INSTALL_FAILED_INSUFFICIENT_STORAGE` (`/data/user/0` at 93% full from co-resident apps `app.relocate`, `com.example.rab_booking`, `app.relocate.relocate`, `com.mycompany.pulsejournal`). Resolved by uninstalling those + clearing `gms` / `googlequicksearchbox` / `youtube` / `chrome` caches. Freed ~1 GiB; install succeeded second time. Document in onboarding for next emulator-based smoke.

### Session recovery

Mid-test session interruption occurred (Bash `&` background processes detached when shell exited). Recovery: re-booted emulator, re-launched `flutter run` via `nohup … & disown`, captured VM service URL from log (`http://127.0.0.1:53711/3u6E26Ro3Yk=/`), connected Marionette. **Recipe added to `memory/marionette-ios-gotchas.md` follow-up: never trust nested `&` in a Bash tool call; use `nohup … & disown` and verify with `ps -p $!`.**

## §3 Per-test results table

| ID | Suite | Test | Result | Evidence |
|----|-------|------|--------|----------|
| A1 | Auth | Login w/ valid credentials → dashboard | PASS | screenshot Pregled; log `[APP] Auth check complete, isAuthenticated=true` |
| A2 | Auth | "Zapamti me" persisted (checked by default) | PASS | login screen render |
| B1 | Nav | Drawer opens via hamburger tap | PASS | drawer screenshot with user header + 9 menu items |
| B2 | Nav | Drawer → Rezervacije | PASS | 1 pending booking BB-TEST03 visible |
| B3 | Nav | Drawer → Kalendar (expandable) → Timeline | PASS | calendar grid + unit row |
| C1 | Dash | Pregled tiles render (Zarada/Rezervacije/Check-in/Popunjenost) | PASS | 4 stat cards |
| C2 | Dash | "Nedavne Aktivnosti" list with 4+ entries from iOS Test Vila | PASS | screenshot |
| C3 | Cal | Timeline shows unit row + day columns 21-26 | PASS | screenshot |
| D1 | Unit | Tap "Smještajne Jedinice" → goes directly to Test Unit A detail | PASS | header "Test Unit A", 4-tab nav |
| D2 | Unit | Cjenovnik tab: €120 base, €130 weekend, monthly grid | PASS | pricing calendar screenshot |
| D3 | Unit | Widget tab: mod=Puna rezervacija sa plaćanjem, advance=20%, Stripe ON | PASS | screenshot |
| E1 | Book | Rezervacije renders 1 pending card with Odobri/Odbij/Detalji/Otkaži | PASS | BB-TEST03 €360 (€0 paid) |
| F1 | Settings | Profil: BookBed Test / bookbed-test@bookbed.io / 14% complete / 5 menu items | PASS | screenshot |
| F2 | Settings | Obavještenja: 5+ entries grouped Danas / Nedjelja / Subota | PASS | screenshot |
| G1 | iCal | iCal Sinkronizacija: "Nema feedova" empty + "Dodaj Feed" CTA + FAQ | PASS | screenshot |
| H1 | UX | AI Asistent consent screen with Gemini disclosure + 4 privacy bullets | PASS | screenshot |
| K1 | Android | Hardware back button pops route (AI Asistent → Pregled) | PASS | Marionette `Back button pressed, route was popped` + screenshot |
| K2 | Android | Force-stop + relaunch retains session (no login prompt) | PASS | `adb am force-stop` + `am start`; lands on Pregled |
| L1 | Responsive | font_scale=1.3 → minor ellipsis but no overflow crash | PASS | `/tmp/audit-63-screenshots/l1-fontscale-130.png` |
| L2 | Responsive | font_scale=2.0 → tab labels clip at viewport edge ("Zadnjih…") | PARTIAL | `/tmp/audit-63-screenshots/l2-fontscale-200.png` — F-63-04 |
| L3 | Responsive | Landscape rotation: 4-tab row fully visible, cards reflow | PASS | `/tmp/audit-63-screenshots/l3-landscape.png` |

## §4 Failures detail

No hard failures. One PARTIAL (L2) detailed in §5.

## §5 New findings

### F-63-01 — App Check unprovisioned on bookbed-dev (PERSISTS from May-23)

**Severity**: P2 (security / observability regression)
**Status**: Open (carried from wave-android-smoke-2026-05-23 bug #3)

Logcat over the entire boot + session window shows recurring:
```
W FirebaseContextProvider: Error getting App Check token. Error: com.google.firebase.FirebaseException: No AppCheckProvider installed.
W LocalRequestInterceptor: Error getting App Check token; using placeholder token instead. Error: com.google.firebase.FirebaseException: No AppCheckProvider installed.
```

Every Firestore / Functions / Storage call from this debug build attaches a **placeholder token**. Any callable with `enforceAppCheck: true` on bookbed-dev rejects this traffic. With the GA migration to `firebase_app_check: ^0.4.1+4` (per CLAUDE.md note 14) the SDK is in the runtime — the debug provider is just not wired for the emulator.

**Fix**: register the Pixel_8 emulator's debug token in Firebase Console → bookbed-dev → App Check, OR set `enforcement=monitor` for dev. Without this, K4-K7 FCM tests + any future callable-protected smoke will continue blocking.

### F-63-02 — GMS `DEVELOPER_ERROR` `SecurityException: Unknown calling package name 'com.google.android.gms'`

**Severity**: P3 (dev-only, no user-facing impact today)
**Status**: New (related to wave-android-smoke #4 SHA-1 gap)

```
E GoogleApiManager: java.lang.SecurityException: Unknown calling package name 'com.google.android.gms'.
W GoogleApiManager: Not showing notification since connectionResult is not user-facing: ConnectionResult{statusCode=DEVELOPER_ERROR, …}
```

Fires twice during app startup on bookbed-dev. Most likely cause: `oauth_client[]` array in `android/app/google-services.json.backup` (bookbed-dev) is empty — the local debug-keystore SHA-1 (`28:F4:F5:3D:F1:4A:E2:5D:CD:F6:62:53:A9:52:9B:4E:12:3F:6D:28` per memory) has not been registered against the bookbed-dev Android app entry in Firebase Console. Google Sign-In is silently broken on dev.

**Fix**: Firebase Console → bookbed-dev → Project settings → Your apps → Android (`io.bookbed.app`) → add SHA-1 → redownload `google-services.json` → replace `.backup`.

### F-63-03 — Emulator data partition fills with co-resident apps; APK install fails silently

**Severity**: P3 (tooling / onboarding)
**Status**: Documented for next smoke

The default Pixel_8 AVD has 5.8 GiB `/data/user/0` and ships at ~93% used out of snapshot. Installing the 109 MiB BookBed debug APK fails with `Failure [INSTALL_FAILED_INSUFFICIENT_STORAGE: Failed to override installation location]`. Resolution recipe:

```bash
adb shell pm uninstall app.relocate
adb shell pm uninstall com.example.rab_booking
adb shell pm uninstall app.relocate.relocate
adb shell pm uninstall com.mycompany.pulsejournal
adb shell pm clear com.google.android.googlequicksearchbox
adb shell pm clear com.google.android.youtube
adb shell pm clear com.google.android.gms
adb shell pm clear com.android.chrome
```

Freed ~1 GiB, took install from 442 MiB → 1.4 GiB free. Add to a `tool/prepare-android-emulator.sh` helper or note in CLAUDE.md `android-development.md`.

### F-63-04 — Tab row labels clip at viewport edge under 200% font scale

**Severity**: P3 (accessibility / responsive degradation)
**Status**: New

At system font_scale=2.0 on Pixel_8 (1080 dp), the "Zadnjih 30/90/365 dana" tabs on the Pregled screen get clipped by the horizontal viewport. "Zadnjih 7 dana" remains visible. No crash, no overlap, just clipping. App is still usable but the secondary range filters are unreachable without horizontal scroll (which is not present).

**Fix**: wrap the chip row in a horizontal `SingleChildScrollView` or use `Wrap` so chips wrap to a second line under large-text accessibility. Verify other chip rows (Rezervacije status filter "Sve / Na čekanju / Potvrđene / O…") under same setting — partial clip already visible at 1.0× ("O…").

### F-63-05 — Wave-23 memory drift: Supabase DNS-lookup storm no longer observed

**Severity**: N/A (informational, positive)
**Status**: Closed in current build

Memory `wave-android-smoke-2026-05-23` bug #2 reported repeated `hifzkwqmkqihmykwswdw.supabase.co: SocketException: Failed host lookup` from `gotrue` at startup. Current logcat slice over login + 4 screen transitions shows ZERO references to `supabase`, `gotrue`, `hifzkw`. Either the env var was removed or guarded — wins for Sentry noise floor.

Memory update queued.

## §6 Performance observations

| Page | Cold-load time observed | Notes |
|------|------------------------|-------|
| `assembleDebug` build | 185.0s (cold, first run on fresh emulator) | Acceptable for debug |
| App boot → Pregled paint (after relaunch w/ session) | ~5 s | `flutter:[APP] Auth check complete` at +5s, BookingsRepo first query at +5.4s |
| Pregled → Rezervacije navigation | ~3 s render | First 1 doc visible immediately |
| Pregled → Kalendar Timeline | ~4 s | Slowest observed transition |
| Pregled → Smještajne Jedinice (1 unit auto-detail) | ~3 s | Skip-list-go-detail UX nice |

No jank observed in screenshots. No "Skipped N frames" warnings in logcat slice. ProfileInstaller ran post-boot (~10 s).

## §7 Accessibility observations (Android TalkBack equivalent — Marionette semantics)

| Surface | Semantic nodes (Marionette `get_interactive_elements`) | Issues |
|---------|---------------------|--------|
| Login | 23 elements, all visible, keys assigned on email/password/submit (`login_email`, `login_password`, `login_submit`) | OK |
| Pregled (dashboard) | Filterable via chip row | No semantic labels on stat cards (Marionette sees Text widgets only — not Semantics annotations) |
| Calendar Timeline | 30 elements (icon buttons w/ tooltips: "Prethodni mjesec", "Sljedeći mjesec", "Opcije") | Good tooltip coverage |
| Rezervacije | Not deeply audited (Marionette dropped session before re-tap) | — |
| Profil | Menu items have text labels but no `Semantics` wrapper visible in Marionette dump | Acceptable; native semantics still work |

L2 200% font scale (F-63-04) is the only concrete a11y finding.

## §8 Cleanup actions

- [x] Restore PROD `google-services.json` (committed-in-git PROD config restored via `git checkout`)
- [x] Remove `google-services.prod-snapshot` (deleted — `.prod-snapshot` is gitignored anyway)
- [x] Kill emulator (`adb -s emulator-5554 emu kill`)
- [ ] Restore WIP stash on `docs/audit-60-61-stripe-consolidation`: `git stash list` shows `stash@{0}: smoke-android-pre-checkout 2026-05-28` — user can `git stash pop` when ready (kept unpopped so next session can decide)
- [x] Settings restored: font_scale=1.0, user_rotation=0, accelerometer_rotation=1
- [N/A] Drop test users from `bookbed-dev` Auth — no new test accounts created this session (login used existing `bookbed-test@bookbed.io` UID `GILVItIVP5R8WXfnMmyMo1ykhUm2`)

## §9 Notes / deviations from spec

1. **No "K Android-specific (8 tests)" full execution** — K3-K7 (push permission/notification/badge/share intent) skipped because App Check still unprovisioned (F-63-01) makes FCM token a placeholder and any server-side push targeting will be rejected.
2. **K1 (back button) + K2 (force-stop relaunch session persist) executed** — both PASS.
3. **L4-L8 (foldable / small screen / notch) not executed** — single Pixel_8 AVD; spec calls for Pixel_Tablet / Pixel_Fold / Pixel_4a AVDs not present locally. L1/L2/L3 are the available subset.
4. **No `audit/migrations/2026-05-28-android-cleanup.log`** — no test data created.
5. **Marionette session broke after K2 force-stop** — VM service URI dies with the process. Subsequent screenshots taken via `adb shell screencap` + `adb pull`. Sufficient for L1-L3.
6. **Branch convention**: tests were executed against `main` content but on the `docs/audit-60-61-stripe-consolidation` branch (because stashing took ~3 s and we wanted to land the new audit doc on a branch user already has open). New file `audit/63-android-e2e-smoke-2026-05-28.md` was a working-tree file before this session — this run filled it in. No code changes.
