# audit/smoke — reusable live smokes (bookbed-dev)

Pruned 2026-06-11: one-time phase scripts deleted (f50-02-smoke1/2/3.sh —
F-50-02 closed via PR #517, dead `/tmp` worktree dep; 95-probe-*.js —
audit/95 investigation closed via SF-071/072/073). Recover via
`git log --diff-filter=D -- audit/smoke/`. The deny-rules invariants those
scripts guarded are covered by the emulator suite:
`cd functions && npm run test:rules` (10 suites — green 2026-06-11; NOT
wired into CI, run manually before rules deploys).

## Kept scripts

| Script | What | Run |
|---|---|---|
| `audit86-direct-write-smoke.js` | LIVE deployed-rules deny smoke (properties/ical_feeds/widget_settings direct-write, owner + foreign UID). Complements the emulator suite by exercising the deployed ruleset. Creates + tears down throwaway docs. | `BOOKBED_DEV_WEB_API_KEY=<web.apiKey> BOOKBED_DEV_OWNER_PASS=<memory: test-account.md> GOOGLE_CLOUD_PROJECT=bookbed-dev node audit/smoke/audit86-direct-write-smoke.js` (cwd `functions/` for node_modules) |
| `complete-booking-smoke.js` | `completeBooking` CF end-to-end (F-67-01 path): throwaway confirmed booking → CF call → post-state assert → cleanup. | `BB_TEST_PW=<memory: test-account.md> node audit/smoke/complete-booking-smoke.js` (cwd `functions/`) |
| `f92-01-probe.js` | READ-ONLY iCal export token matrix. Post-SF-063 nothing is exploitable (`verifyIcalToken` empty-fail-CLOSED); verdicts are `OK` / `BROKEN-FEED` (PR #482 `_plaintext`/`_hash` schema present but read-side `icalExport.ts` reads `ical_export_token` → 403 on every request — audit/92 schema mismatch, OPEN) / `FAIL-CLOSED`. Re-run 2026-06-11: dev 2/2 BROKEN-FEED. | `GOOGLE_CLOUD_PROJECT=bookbed-dev node ../audit/smoke/f92-01-probe.js` (cwd `functions/`) |

## Open follow-ups surfaced here

1. **iCal read-side schema reconciliation** (audit/92, functional not security):
   `functions/src/icalExport.ts:177-182` must also accept
   `widget_secrets.ical_export_token_plaintext` (or verify the peppered
   `_hash`) before the legacy fallback — otherwise every unit provisioned via
   the PR #482 writer ships a dead feed URL.
2. **`npm run test:rules` not in CI** — rules regressions only caught when run
   manually.
