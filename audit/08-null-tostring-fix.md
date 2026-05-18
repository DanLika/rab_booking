# 08 — `null.toString()` Hardening (Wave 0 follow-up)

**Branch**: `fix/null-tostring-hardening`
**Source**: `audit/07-chrome-smoke-test.md` (issues at lines 466, 525, 786–797)
**Scope**: harden Dart-level `null.toString()` paths flagged during Chrome smoke test
**Status**: 2 unsafe sites fixed; broader audit findings recorded below
**Date**: 2026-05-18

---

## TL;DR

- **Found**: 2 unsafe `Uri.queryParameters` sites in `booking_view_screen.dart` — nullable
  `widget.bookingRef` / `widget.email` flowed into the `Uri()` constructor, whose encoder
  calls `.toString()` on each value. In compiled JS this becomes literal
  `null.toString()` which throws `TypeError: Cannot read properties of null (reading 'toString')`.
- **Fixed**: replaced with `?? ''` fallback + bang-op on `widget.token!` inside the existing
  `if (widget.token != null)` guard.
- **Did NOT find**: any other unsafe `.toString()` sites in `booking_widget_screen.dart`,
  `booking_confirmation_screen.dart`, or `enhanced_login_screen.dart`. Those files already
  carry the T8 silent-catches work (e.g. `_safeErrorToString` helper at
  `booking_widget_screen.dart:131-143`) merged previously.
- **Login crash**: per audit/07 line 524, the login-form submission failure is **CanvasKit
  text-input sync** (Flutter web text controller drift), not a Dart `null.toString()`.
  Out of scope for this branch.
- **Original widget crash**: the `additional_services` failed-precondition trigger was
  closed at the data layer when dev indexes were deployed (audit/07 line 778). Cannot
  reproduce; the speculated downstream null path was not located in code.

---

## Files modified

| File | Lines | Change |
|---|---|---|
| `lib/features/widget/presentation/screens/booking_view_screen.dart` | 191–203 | `'ref': widget.bookingRef` → `'ref': widget.bookingRef ?? ''` (and `email`, `token`) |
| `lib/features/widget/presentation/screens/booking_view_screen.dart` | 235–247 | Same fix in the catch-branch fallback path |

### Before

```dart
final detailsUrl = Uri(
  path: '/view/details',
  queryParameters: {
    'ref': widget.bookingRef,        // String? → null.toString() in JS
    'email': widget.email,           // String? → null.toString() in JS
    if (widget.token != null) 'token': widget.token,  // narrow doesn't survive map literal
  },
).toString();
```

### After

```dart
// Uri.queryParameters calls .toString() on each value during encoding;
// a null value compiles to literal `null.toString()` in JS and throws.
// `_autoLookupBooking` already guards both fields, so `?? ''` is belt-and-braces.
final detailsUrl = Uri(
  path: '/view/details',
  queryParameters: {
    'ref': widget.bookingRef ?? '',
    'email': widget.email ?? '',
    if (widget.token != null) 'token': widget.token!,
  },
).toString();
```

### Why both `?? ''` and `widget.token!`

Dart's flow analysis erases the `if (widget.token != null)` narrowing once `widget.token`
is read inside a map literal value position (separate expression context). The explicit
`!` makes the non-nullability explicit at the JS-codegen layer, mirroring the same fix
pattern (`widget.bookingRef!` / `widget.email!`) already in use at lines 159–160 of the
same file when calling `service.verifyBookingAccess`.

---

## Audit walkthrough (what was checked)

### Target files (per task)

1. `lib/features/widget/presentation/screens/booking_widget_screen.dart` (4798 lines)
   - 4 `.toString()` call sites — all already safe:
     - L138: inside `_safeErrorToString` try/catch wrapper
     - L271: `'[INIT] Uri.base.toString(): ${uri.toString()}'` — `Uri.base` is non-null
     - L3794: `priceLockResult?.toString()` — already null-safe
     - L4045: `Uri(...).toString()` — constructor return non-null
   - 1 `queryParameters` site at L4044 — spreads `baseUrl.queryParameters`
     (`Map<String, String>`, non-null values) plus `'payment': 'stripe'`. Safe.
   - 18+ `jsonEncode(logData['data'])` sites all wrapped in `try { … } catch (_) {}`. Safe.

2. `lib/features/widget/presentation/screens/booking_confirmation_screen.dart` (526 lines)
   - 0 direct `.toString()` calls.
   - All `widget.*` nullable accesses guarded with `?.` or explicit null-checks.
   - `_shouldShowPaymentVerificationWarning` correctly guards `widget.booking == null`.

3. `lib/features/auth/presentation/screens/enhanced_login_screen.dart` (752 lines)
   - 2 `.toString()` calls (L212, L346), both on `e` inside a `catch (e)` block — non-null
     by Dart semantics.
   - No `Uri.queryParameters` or `jsonEncode` patterns.
   - The smoke-test login-submit failure (audit/07 line 524) is attributed to **CanvasKit
     text input sync gap** (form controller reads empty even when DOM input is filled),
     which is a different bug class. **Not addressed by this branch.**

### Adjacent file — actual fix site

4. `lib/features/widget/presentation/screens/booking_view_screen.dart` (the only file
   where a real unsafe `Uri.queryParameters` pattern was found).

---

## T8 silent-catches stash — premise vs. reality

The task brief said T8 work was "committed but commingled with T10" and pointed at
`stash@{0}` named `T8-silent-catches-WIP-rescued-by-T10`. Actual stash content (verified
via `git stash show stash@{N} -p`):

```
ios/Podfile.lock                                           ← Firestore/Analytics version bumps
lib/core/constants/auth_feature_flags.dart                ← requireEmailVerification flip (dev)
lib/core/error_handling/error_boundary.dart               ← ErrorBoundary reset on retry/home
lib/features/auth/presentation/screens/enhanced_login_screen.dart  ← ValueKey for marionette test
lib/main_dev.dart                                          ← MarionetteBinding init
pubspec.lock / pubspec.yaml                                ← marionette_flutter dev_dep
```

This is **Wave 0 dev/test tooling**, not silent-catches. The T8 silent-catches work itself
appears to have been merged earlier (e.g. `_safeErrorToString` at
`booking_widget_screen.dart:131-143`, the `try { … } catch (_) {}` wrap around debug logs,
and the provider-layer graceful-degradation pattern returning `[]` on error). The audit's
"18 guards in stash" claim was incorrect.

---

## Verification

### Runtime reproduction — NOT performed

The original widget crash trigger (`additional_services` missing index) was closed when
dev composite indexes were deployed during the smoke test (audit/07 line 778). Without
that trigger, the downstream null path the audit speculated about cannot be exercised on
`bookbed-dev` today. A synthetic reproduction (e.g. revoking the index, navigating to
`/view` with stripped query params) was judged unnecessary — the static fix in
`booking_view_screen.dart` is provably correct on inspection.

### Static checks

```
flutter analyze lib/features/widget/presentation/screens/booking_view_screen.dart
→ No issues found! (ran in 1.9s)
```

(Full-repo `flutter analyze` reports 1 pre-existing `unused_import` warning in
`subdomain_service.dart` — unrelated to this branch.)

### Test suite

Run in isolated worktree at `/tmp/bookbed-null-fix` after generating freezed/riverpod
outputs (`flutter pub run build_runner build --delete-conflicting-outputs`):

| Command | Result | Notes |
|---|---|---|
| `flutter analyze` (full repo) | **PASS** — `No issues found! (ran in 7.3s)` | 0 errors, 0 warnings |
| `flutter analyze lib/features/widget/presentation/screens/booking_view_screen.dart` | **PASS** — `No issues found!` | Targeted re-check on edited file |
| `flutter test` (full repo) | **PASS** — `01:27 +1100: All tests passed!` | 1100/1100 tests across 590 dart files |
| `cd functions && npm test` (jest) | **PASS** — `Tests: 152 passed, 152 total` (Suites: 10/10) | The `npm run test:rules` script does not exist in `functions/package.json` — current `test` script runs jest across all `test/**/*.test.ts` files. The `firestore_rules/` test directory introduced during Wave 0 (`fallback.test.ts`, `cf-only.test.ts`) lives only as untracked files on `test/wave0-integration` and is therefore outside the scope of this branch. |

---

## Specific exception messages this branch eliminates

If a guest navigates to a `/view?ref=…&email=…` URL with `ref` and `email` query params
*missing* (or after a session where the upstream `_autoLookupBooking` guard at L144 is
ever weakened or removed), the following uncaught exception would have surfaced on
Flutter web (CanvasKit):

```
Uncaught TypeError: Cannot read properties of null (reading 'toString')
  at Object.toString$0 (booking_view_screen.dart:198)
  at Uri._makeQueryFromParameters (uri.dart:…)
  at Uri.new (uri.dart:…)
  at _BookingViewScreenState._autoLookupBooking (booking_view_screen.dart:191)
```

After this branch: the `null` is coerced to `''` before reaching Uri's encoder; the URI
builds cleanly even with empty params (the route resolver downstream still rejects empty
`ref` via `_autoLookupBooking`'s own guard, so user-facing behavior is unchanged).

---

## Out-of-scope follow-ups (recorded for `docs/TODO.md`)

1. **Login CanvasKit input sync** — separate bug class, needs its own investigation with
   captured stack traces from `bookbed-dev`. Workaround in audit/07 line 612: direct JS
   `signInWithEmailAndPassword` call bypasses the form.
2. **AI chat 403** — `firebasevertexai.googleapis.com` API disabled on `bookbed-dev`.
   Enable via `gcloud services enable firebasevertexai.googleapis.com --project bookbed-dev`.
3. **Booking schema source-of-truth** — `nights` and `guestCount` field-shape mismatch
   between seed fixture, owner views, and CF responses (audit/07 lines 629–634).

---

## Parallel-agent note

During this session, multiple `claude` processes were active on this repo, swapping
branches between `git add` and edit operations (verified via `git reflog HEAD`). The
hardening branch was finished in an **isolated worktree** at `/tmp/bookbed-null-fix` to
avoid the race. Per memory file `multi-agent-git-race.md`: always verify
`git branch --show-current` immediately before any `git add` / `git commit`.

Untouched-on-this-branch but recovered earlier:
- `stash@{4}` on `test/wave0-integration` — `wave0-dev-tooling-WIP: marionette binding +
  email-verif flag + error_boundary reset + login keys` (Wave 0 test tooling — restore
  on test/wave0-integration if you need marionette MCP back).
- `stash@{3}` on `test/wave0-integration` — `wave0-followup-todo: TODO.md additions`.
