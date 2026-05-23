# Audit 20 — ErrorBoundary catch too broad — narrow filter to user-relevant exceptions

**Date**: 2026-05-23
**Branch**: not yet created — queue as separate PR after `#447` / `#448` / `#449` merge
**Scope**: `lib/core/error_handling/error_boundary.dart` — narrow the `FlutterError.onError` replacement inside `_setupErrorListener()` to ignore non-user-facing exceptions (VM service extension dispatch, `dart:developer` noise) so they don't surface as the user-visible "Oops! Something went wrong" screen.
**Status**: Skeleton only. Doc-first. No code change in this audit.

---

## 1. Problem statement

`ErrorBoundary` (`lib/core/error_handling/error_boundary.dart:31`) wraps 4 route groups in `lib/core/config/router_owner.dart:786,815,843,871` and one root in `lib/main.dart`. Its internal `_setupErrorListener()` overrides the global `FlutterError.onError` and unconditionally surfaces *every* `FlutterErrorDetails` it receives as a user-visible error screen. This includes exceptions thrown by infrastructure that the user neither triggered nor can recover from — Flutter VM service extension dispatch failures, `dart:developer` integration noise, and Marionette test-harness `tap`/`scroll_to` matchers failing during instrumented runs. The user sees "Oops! Something went wrong" with the raw exception text exposed in `kDebugMode`, and Sentry receives the same payload (because the original handler is called first at line 79 before the boundary captures it). Narrowing the catch reduces both surfaces without expanding what the boundary protects against.

---

## 2. Evidence — Android smoke 2026-05-23 (2 repros)

Source: `memory/wave-android-smoke-2026-05-23.md`, "Bugs found — #1 ErrorBoundary catches Marionette test-harness exceptions".

### Repro A — failed `tap by text: "Natrag na prijavu"`

Context: post-login, user reached the in-app `EmailVerificationScreen` (Croatian "Verifikacija e-pošte"). Marionette agent attempted `mcp__marionette.tap text:"Natrag na prijavu"` (intent: navigate back to login). The element was visible in the screenshot but the matcher failed at the Flutter VM extension layer — exception propagated through `FlutterError.onError` and the ErrorBoundary captured it.

Resulting UI:
```
Oops! Something went wrong
Don't worry, this happens sometimes. You can try again or go back to the dashboard.
Exception: Element matching {text: Natrag na prijavu} not found
[ Go Home ]  [ Try Again ]
```

Recovery: tap "Go Home" → dashboard restored cleanly.

### Repro B — failed `tap by text: "Integracije"`

Context: drawer was open with `Integracije` accordion already expanded. Marionette `mcp__marionette.tap text:"Integracije"` was issued to collapse it (so that `Profil` would become visible for the logout flow). Exception thrown — same path — same ErrorBoundary screen, this time with `Exception: Element matching {text: Integracije} not found`.

Recovery: tap "Go Home" → dashboard.

### Common signature

Both exceptions share the runtime type `Exception` (Dart's base) and the message format `Element matching {<key>: <value>} not found`. Stack origin (not captured in this session — was not in the in-app text display) is the `dart:developer` extension dispatcher → Marionette extension handler. No frame originates in `lib/`.

---

## 3. Root cause hypothesis

Two design facts in `lib/core/error_handling/error_boundary.dart` combine to cause this:

1. **Line 77-93 (`_setupErrorListener`)** replaces `FlutterError.onError` with a wrapper that calls the original handler first (line 79), then unconditionally captures the error into `_errorDetails` (line 87). There is **no filter** on `details.exception.runtimeType`, no inspection of `details.stack` origin, no allowlist/blocklist for source frames.

2. **Line 422-432 (`GlobalErrorHandler.initialize`)** ALSO sets `FlutterError.onError` and a `PlatformDispatcher.instance.onError` global. This is the Sentry / Crashlytics path. ErrorBoundary's override calls this first (line 79), so Sentry receives every captured error in addition to the user seeing it. There is no de-duplication.

The widget was likely written with the assumption that `FlutterError.onError` only fires for *widget tree errors* (build-time exceptions). In practice, the Flutter framework routes a much wider class of errors through this sink — including async exceptions from VM service extension dispatch, which Marionette uses for every `tap`/`scroll_to` call. Production-only equivalents include any future debug-bridge integration (DevTools panels, Flutter Inspector commands, hot-reload callbacks).

---

## 4. Suggested narrowing rule

Replace the unconditional capture (line 84-89) with a filter step. Pseudocode:

```dart
FlutterError.onError = (FlutterErrorDetails details) {
  _originalOnError?.call(details);

  if (!_isUserFacingError(details)) {
    // Test harness, debug bridge, VM extension noise — let it propagate to
    // dart:developer log only, do NOT surface UI.
    return;
  }

  if (mounted) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _errorDetails = details);
    });
    widget.onError?.call(details);
  }
};

static bool _isUserFacingError(FlutterErrorDetails details) {
  // Stack origin check: error must originate in user code (lib/) to qualify
  final stackString = details.stack?.toString() ?? '';

  // Hard reject: VM service / dart:developer extension dispatch
  const blockedFramePatterns = <String>[
    'package:flutter/src/foundation/binding.dart',  // ServiceExtensions
    'dart:developer',
    'dart:vm_service',
    'package:flutter/src/widgets/binding.dart registerExtension',
    'marionette_extension',
  ];
  if (blockedFramePatterns.any(stackString.contains)) return false;

  // Hard reject: matcher-not-found / test-harness exception messages
  final msg = details.exception.toString();
  if (msg.startsWith('Exception: Element matching {')) return false;
  if (msg.contains('VM service extension')) return false;

  // Accept anything else (widget build errors, async user-triggered failures, etc.)
  return true;
}
```

Tighten further over time — start with the blocklist above (high precision, low recall) and broaden only when a real production exception is incorrectly filtered. The reverse — broad catch + later narrow — is what we have today and is the source of this issue.

Alternative shape (more conservative): inspect `details.silent` flag — Flutter sets `silent: true` on infrastructure errors by convention and the framework's default `presentError()` skips them. ErrorBoundary could honor the same convention by returning early when `details.silent == true`. Easier change, narrower fix.

---

## 5. Fix file path + line range

- `lib/core/error_handling/error_boundary.dart:72-94` — the `_setupErrorListener()` method. Replacement happens entirely inside the closure assigned to `FlutterError.onError`.
- No changes to `_DefaultErrorWidget` (line 107+) or `GlobalErrorHandler` (line 420+).
- No changes to the 4 ErrorBoundary callsites in `lib/core/config/router_owner.dart:786,815,843,871` or the root mount in `lib/main.dart`.

---

## 6. Risk assessment

**Low.** Narrowing the catch:
- Reduces the surface of what's captured — never expands it.
- Already-captured errors will continue to be captured (no false negatives for widget build errors or async failures from user-triggered code paths).
- Errors that were *incorrectly* user-visible (the case in evidence above) will now propagate to `debugPrint`/Sentry only, matching how the rest of the framework treats them.
- The Sentry pipeline is untouched — `_originalOnError?.call(details)` still fires first at line 79.

**Worst case if the filter is wrong**: a real production widget build error gets silently swallowed. Mitigation: keep `Sentry.captureException` wired in `GlobalErrorHandler._logError` (line 435-445) so that even silently-swallowed errors land in the dashboard. Set up an alert for any spike in `silent=true` async errors so we detect over-aggressive filtering early.

**No data-integrity risk.** No security risk. No backwards-compat risk — every existing ErrorBoundary callsite continues to work identically for user-relevant errors.

---

## 7. Recommended action

Queue as a separate PR after the active sprint closes:
- Wait for `#447` (Wave 5 Phase 1) + `#448` (test-debt audit/19) + any in-flight billing-blocked PRs to merge first.
- Branch name suggestion: `chore/error-boundary-narrowing-audit-20`.
- One-commit PR scoped to `lib/core/error_handling/error_boundary.dart`.
- Add an integration test (or update existing widget test in `test/core/error_handling/`) that constructs an `ErrorBoundary` and injects:
  - A `FlutterErrorDetails` with an `Exception: Element matching {...} not found` payload — expect `_errorDetails == null` after frame.
  - A `FlutterErrorDetails` with a `BuildContext`-typed exception originating in a `lib/` frame — expect the error widget shows.
- Update `CLAUDE.md` to note ErrorBoundary's filter behavior so future contributors understand why some errors don't surface to UI.

Not a security fix — no `docs/SECURITY_FIXES.md` cross-link needed. This is UX hardening. Internal audit doc only.

---

## 8. Sentry signal impact

**Currently:** Both pathways fire. The boundary captures + UI shows AND Sentry receives (via `_originalOnError?.call(details)` at line 79 which routes to `GlobalErrorHandler._logError` → Crashlytics in production builds).

**Expected post-fix:** When the new filter rejects an error:
- UI surface: removed (✓ goal).
- Sentry/Crashlytics: STILL fires (line 79 unchanged — original handler called BEFORE the filter).

This means the fix removes the user-visible noise but leaves Sentry observability intact. To also clean Sentry, a separate filter in `GlobalErrorHandler._logError` (line 435-445) would need to apply the same allowlist. Recommend doing this in the same PR — copy `_isUserFacingError(details)` logic into `_logError(error, stack)` and early-return when stack matches a blocked pattern. Both fixes are 1-file changes, naturally co-located.

**Sentry verification before/after PR merge:**
- Before: query for `Exception: Element matching {.*} not found` events in the last 30d. Expect non-zero count (every smoke test contributes; current dashboards drown real signal).
- After: count should drop to ~0 within a week. Real widget build errors and user-triggered async errors should remain at baseline.

---

## Cross-references

- Evidence: `memory/wave-android-smoke-2026-05-23.md` — bugs section #1
- Prior iOS observation: `memory/wave0-test-findings.md` — "ErrorBoundary sticky bug" (the same defect surfaced on iOS during Wave 0)
- ErrorBoundary widget: `lib/core/error_handling/error_boundary.dart`
- Callsites: `lib/core/config/router_owner.dart:786,815,843,871`, `lib/main.dart`
- Sentry path: `GlobalErrorHandler.initialize` at `lib/core/error_handling/error_boundary.dart:420`
