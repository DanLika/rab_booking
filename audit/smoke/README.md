# audit/smoke — reusable live smokes (bookbed-dev)

Pruned 2026-06-11: one-time phase scripts deleted (f50-02-smoke1/2/3.sh —
F-50-02 closed via PR #517, dead `/tmp` worktree dep; 95-probe-*.js —
audit/95 investigation closed via SF-071/072/073). Recover via
`git log --diff-filter=D -- audit/smoke/`. The deny-rules invariants those
scripts guarded are covered by the emulator suite:
`cd functions && npm run test:rules` (10 suites — green 2026-06-11; NOT
wired into CI, run manually before rules deploys).

## Kept scripts

All runs need `NODE_PATH=<repo>/functions/node_modules` (scripts live outside
a package).

*Deleted 2026-06-11 after a final live 16/16 PASS:*
`audit86-direct-write-smoke.js` — fully subsumed by (a) the emulator rules
suite now in CI (`validate-firestore-rules` job) for behavior and (b) the
daily `firestore-rules-drift.yml` cron for deployed≡repo equivalence.
Recover via `git log --diff-filter=D -- audit/smoke/`.

| Script | What | Run |
|---|---|---|
| `complete-booking-smoke.js` | `completeBooking` CF end-to-end (F-67-01 path): throwaway confirmed booking → CF call → post-state assert → idempotency reject → cleanup. Last run 2026-06-11: PASS. | `NODE_PATH=functions/node_modules BB_TEST_PW=<memory: test-account.md> GOOGLE_CLOUD_PROJECT=bookbed-dev node audit/smoke/complete-booking-smoke.js` |
| `f92-01-probe.js` | READ-ONLY iCal export token matrix. Post-SF-063 nothing is exploitable (`verifyIcalToken` empty-fail-CLOSED); verdicts are `OK` / `BROKEN-FEED` (PR #482 `_plaintext`/`_hash` schema present but read-side `icalExport.ts` reads `ical_export_token` → 403 on every request — audit/92 schema mismatch, OPEN) / `FAIL-CLOSED`. Re-run 2026-06-11: 2/2 BROKEN-FEED -> root cause = ORPHANED PR #482-era `_plaintext`/`_hash` fields (that schema was abandoned; current writer = Flutter export screen writes `ical_export_token`). Dev backfill executed same day: canonical field restored, orphans deleted -> probe 2/2 OK + live feed GET 200 VCALENDAR / wrong-token 403. **audit/92 FULLY CLOSED** (docs deleted; this probe is the regression tool). | `GOOGLE_CLOUD_PROJECT=bookbed-dev node ../audit/smoke/f92-01-probe.js` (cwd `functions/`) |

## Open follow-ups surfaced here

1. ~~iCal read-side schema reconciliation~~ — CLOSED 2026-06-11: no code change
   needed; the `_plaintext`/`_hash` schema was an abandoned PR #482-era artifact
   on 2 dev docs. Backfilled to canonical `ical_export_token` + orphans removed;
   feed verified live (200 + 403 negative control). PROD unaffected (all 13
   units carry the canonical field per the earlier audit/92 matrix).
2. ~~`npm run test:rules` not in CI~~ — CLOSED 2026-06-11: wired into the
   always-running `validate-firestore-rules` job (Java 17 + emulator suite).
