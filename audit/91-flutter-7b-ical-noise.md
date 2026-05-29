# audit/91 — FLUTTER-7B iCal owner-fault Sentry-noise filter (SF-066)

**Date**: 2026-05-29
**Branch**: `fix/flutter-7b-ical-userfault-noise`
**Scope**: `functions/src/icalSync.ts` only
**Sentry issue**: [FLUTTER-7B](https://sentry.io) — `Error: Invalid iCal URL: Invalid protocol: file:. Only HTTP/HTTPS allowed.` (14 events, 1 user, first/latest 2026-05-27)
**Related issues seen same day**: FLUTTER-7C (`TypeError: Invalid IP address: undefined` — closed by PR #514 commit `38701f6c`/squash `76208336`); FLUTTER-72 + FLUTTER-73 (widget `[firebase_functions/internal]` — client-side transient, archived no-fix)

## Symptom

`syncIcalFeedNow` and `scheduledIcalSync` fire `logError` (→ Sentry) whenever an owner-supplied iCal URL fails server-side validation:

- `file://` / `gopher://` / `data:` protocol rejection (SSRF guard)
- `127.0.0.1` / `169.254.169.254` / private-IP rejection (SSRF guard)
- `Hostname does not resolve` / malformed URL
- Upstream HTTP 4xx (owner's URL is wrong, expired, or auth-gated)

The audit/55 SSRF smoke run on 2026-05-27 generated 14 Sentry events from a single test-account session probing the file-scheme rejection — pure noise. The same noise hits every real owner that pastes a malformed feed URL.

## Why F-67-05 alone wasn't sufficient

PR `50753cf5` (2026-05-28, F-67-05) converted the inner throws to `HttpsError("failed-precondition", ...)` to stop leaking upstream hostnames. That's covered by `sentry.ts` `beforeSend` filter (`failed-precondition` is in the dropped client-fault set per `.claude/rules/cloud-functions.md`), so any **thrown** HttpsError is dropped at Sentry init.

But the **inner `syncSingleFeed` catch** still calls `logError("[iCal Sync] Error syncing feed", error, {feedId})` BEFORE re-throwing. `logError` captures the exception via Sentry's `captureException` — `beforeSend` drops it only if the exception is itself an HttpsError. That covers the URL-validation path (now HttpsError) but:

- `fetchIcalData` (`icalSync.ts:738`) rejects with **plain `Error('HTTP 4xx: …')`** for owner-fault upstream responses → not an HttpsError → not dropped by beforeSend → escalates to Sentry.
- Defensive: if any future validateIcalUrl edit slips a plain Error in, it would re-surface the same noise class.

## Fix (Option B from issue triage)

Add `isUserFaultIcalError(error)` next to existing `isTransientFetchError` in `functions/src/icalSync.ts` and route those errors to `logWarn` in all 3 catch sites.

### Filter coverage

```typescript
function isUserFaultIcalError(error: unknown): boolean {
  if (!error) return false;
  const message = error instanceof Error ? error.message : String(error);
  if (/^Invalid iCal URL:/.test(message)) return true;
  if (/^Redirect blocked by SSRF guard:/.test(message)) return true;
  if (/^HTTP 4\d\d:/.test(message)) return true;
  if (/^(Invalid URL format|Invalid protocol:|URL must have a hostname|Hostname (does not resolve|returned no addresses|resolves to a private))/.test(message)) {
    return true;
  }
  return false;
}
```

### Routing sites updated

| Site | Before | After |
|---|---|---|
| `syncSingleFeed` catch (inner — runs on every failure) | `isTransient ? logWarn : logError` | `isTransient ? logWarn : isUserFault ? logWarn : logError` |
| `syncIcalFeedNow` outer catch (handler) | `logError(error)` then wrap in HttpsError(`internal`) | `isUserFault ? logWarn : isTransient ? logWarn : logError` then same wrap |
| `scheduledIcalSync` outer catch (loop) | `isTransient ? logWarn : logError` | `isTransient ? logWarn : isUserFault ? logWarn : logError` |

### What stays on logError (genuine bug class)

- `Fetched iCal data is empty or invalid for feed: … (missing BEGIN:VCALENDAR header)` — could be owner-fault OR upstream serving empty body OR parser regression. Kept on logError pending evidence.
- `Too many redirects` — unusual loop, actionable.
- Database write failures inside the catch's post-processing.
- Any non-Error thrown value with unmatched message.

### What feeds still surface to UI

`feedRef.update({status: "error", last_error: errorMessage, …})` runs **unchanged** in all three sites — the owner-facing signal is identical. Only the Sentry-routing layer is affected.

## Verification

```
$ cd functions
$ npm run build          # tsc clean, 0 errors
$ npx jest               # 389/389 pass (incl. 2 new FLUTTER-7B regression tests)
$ npm run test:rules     # all green, emulator clean shutdown
```

### Regression tests added (`functions/test/icalSync.test.ts`)

1. **`FLUTTER-7B: file:// URL routes through logWarn, not logError`** — wraps `syncIcalFeedNow` with `ical_url: "file:///etc/passwd"`, asserts:
   - throw matches `/Invalid iCal URL: Invalid protocol: file/`
   - `logError` NOT called with `"[iCal Sync] Error syncing feed"`
   - `logWarn` called with `"[iCal Sync] Owner-fault validation rejection"`
2. **`FLUTTER-7B: empty-body parse failure stays on logError`** — over-broadening guard:
   - throw matches `/empty or invalid for feed/`
   - `logError` still called with `"[iCal Sync] Error syncing feed"`

## Out-of-scope (intentional)

- **No PROD deploy** — branch lands as PR; deploy happens via normal cutover sweep.
- **No `lib/` / iOS / Android / rules / hosting changes** — single-file scope.
- **SSRF guard logic untouched** — `validateIcalUrl` + `isPrivateOrUnsafeIp` + pinned-lookup callback unchanged. Only the log-routing layer downstream of the SSRF rejection is affected.
- **No Sentry SDK config change** — `sentry.ts` `beforeSend` filter unchanged.

## Closes

- Sentry FLUTTER-7B (mark Resolve / Archive once PR merges; expect zero recurrence on next audit/55-class smoke).
- SF-066.

## Cross-references

- [`docs/SECURITY_FIXES.md`](../docs/SECURITY_FIXES.md) SF-066
- [PR #514 commit `1c3d6985` / squash `76208336`](../) — sibling FLUTTER-7C autoSelectFamily fix, audit/56
- [PR `50753cf5`](../) F-67-05 — converted inner throws to HttpsError(failed-precondition) so beforeSend covers thrown path
- `.claude/rules/cloud-functions.md` — Sentry HttpsError client-fault filter (the existing layer this PR complements)
