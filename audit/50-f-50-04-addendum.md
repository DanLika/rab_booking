# F-50-04 addendum 2026-05-26 — entryFromArgs wrap discovery

**Status:** PR #483 closed superseded. v2 PR opens against `fix/f-50-04-error-stack-scrub-v2`.

## Why the original prescription was incomplete

Original prescription "scrub stack from Sentry payload" was incomplete.

`firebase-functions` logger `entryFromArgs` synthesizes `new Error(msg).stack` when `severity === "ERROR"` and no `Error` instance is in `args`, writing the result to `jsonPayload.message`. PR #483 removed `logData.error.stack` (Path 1 leak) but did NOT change the call from `functions.logger.error(message, logData)` to a primitive that bypasses `entryFromArgs` (Path 2 leak). Leaks source paths to anyone with `roles/logging.viewer` in GCP — typically contractors and on-call rotations.

Smoke evidence (`audit/raw/pr483-smoke-2026-05-26-cloud-logging.json`) shows `jsonPayload.message` carrying:

```
Error: Password reset failed - domain not authorized. ...
    at entryFromArgs (/workspace/node_modules/firebase-functions/lib/logger/index.js:144:19)
    at Object.error (/workspace/node_modules/firebase-functions/lib/logger/index.js:131:11)
    at Logger.error (/workspace/lib/logger.js:176:30)
    at logError (/workspace/lib/logger.js:244:51)
    at /workspace/lib/passwordReset.js:134:35
    ...
```

The `error` sub-object is correctly scrubbed (PR #483 worked for Path 1). The PARENT `message` field carries the synthesized stack instead.

## Why unit tests missed it

Unit-test mocks intercept `functions.logger.error(message, logData)` BEFORE `entryFromArgs` runs. The mock captures `args` as `[message, logData]` where `message` is the plain string we passed in. `entryFromArgs` is a private function inside `firebase-functions/lib/logger/index.js` — it executes AFTER `logger.error()` is called, and the unit-test mock never reaches it.

Pure integration-time bug. Live ERROR-severity log against a deployed CF is the only sink that exposes it.

## v2 fix (this PR)

Two changes in `functions/src/logger.ts`:

1. **Path 1 (carry forward from PR #483):** Drop `stack` field from `logData.error`. Sentry still receives full stack via `captureException`.
2. **Path 2 (new):** Replace `functions.logger.error(message, logData?)` with `functions.logger.write({severity: "ERROR", ...logData, message})`. `write()` is `@public` per `firebase-functions/lib/logger/index.d.ts:22` and bypasses `entryFromArgs` entirely — the `LogEntry` is written verbatim, `message` stays a plain string. WARN path (client-fault `HttpsError`) is UNCHANGED — `entryFromArgs` wraps only on `severity === "ERROR"`.

Scope kept tight: only the `logger.ts` wrapper changes. Every other `logger.error(msg, error)` call site in the codebase flows through `logError` → `Logger.error` transitively, so the bypass propagates without touching individual call sites.

## Validation requirement (operator smoke gate)

Unit tests assert the payload sent TO `write()` is a plain string. The bypass property is `firebase-functions`'s contract that we trust. The ONLY way to prove the leak is closed end-to-end is the live smoke:

```bash
# 1. Deploy bookbed-dev
tool/deploy-dev.sh   # or `cd functions && firebase deploy --only functions --project bookbed-dev`

# 2. Trigger ERROR-severity log on a CF that calls logError() without an Error instance
curl -X POST https://us-central1-bookbed-dev.cloudfunctions.net/sendPasswordResetEmail \
  -H 'Content-Type: application/json' \
  -d '{"data":{"email":"smoke-f50-04-v2@example.com"}}'

# 3. Read the log entry
gcloud logging read 'resource.labels.function_name="sendPasswordResetEmail"' \
  --project=bookbed-dev --limit 5 --format=json

# 4. Assert: jsonPayload.message is a plain string with NO "\n    at /workspace/" substring
```

If the `message` field still contains `at /workspace/...`, the fix did NOT land — investigate before merge. If it's a plain string, F-50-04 closes.

## Evidence

`audit/raw/pr483-smoke-2026-05-26-cloud-logging.json` — durable JSON capture of two ERROR entries from `sendPasswordResetEmail` (2026-05-26 05:44:16 UTC) where `jsonPayload.message` shows the synthesized stack. Committed alongside this addendum for future-proof reference.

## Scope expansion follow-up

`Logger.error` is the only ERROR-severity sink in `logger.ts`. Other modules that directly call `functions.logger.error(...)` (bypassing `logError`) are NOT in this PR's scope and would still leak via `entryFromArgs`. Audit + remediate as **SF-034** (separate PR).

Quick triage command for SF-034:

```bash
grep -RnE "functions\\.logger\\.error\\(" functions/src/ | grep -v "logger\\.ts"
```

## See also

- PR #483 (CLOSED — superseded) — `fix/f-50-04-error-stack-scrub`
- `audit/50-security-audit-2026-05-25.md` § F-50-04
- `memory/pr483-stack-leak-finding.md` — finding writeup + linked memories
- `firebase-functions/lib/logger/index.d.ts:22` — `write(entry: LogEntry)` @public API
- `firebase-functions/lib/logger/index.js:142-144` — the `entryFromArgs` wrap source line
