# Archived: audit/smoke/ one-shot scripts

Deleted 2026-07-09 (recoverable via `git log --diff-filter=D -- audit/smoke/`). One-line record of what each probed so the knowledge survives the code.

| Script | Purpose | Status |
|---|---|---|
| `audit123-deploy-smoke.js` | audit/123 dev-deploy smoke: F-92-01 iCal feed 200/403 regression + F-123-07 `getStripeAccountStatus` 30/300s per-owner rate limit. bookbed-dev only; needed `BB_SMOKE_API_KEY`. | Findings closed; secret already stripped (#803). |
| `complete-booking-smoke.js` | F-67-01 closure smoke: `completeBooking` CF on bookbed-dev — mint throwaway confirmed booking, ID-token via custom-token, call CF, assert post-state, cleanup. | Closed. |
| `f92-01-probe.js` | F-92-01 read-only probe: enumerate `widget_settings`/`widget_secrets` on bookbed-dev, classify each `ical_export_enabled` unit vulnerable/safe/unknown. | Closed (SF fix wave). |
| `README.md` | Noted these were reusable dev smokes; earlier one-time scripts already pruned 2026-06-11. | — |

**Invariants these guarded are covered by the emulator suite:** `cd functions && npm run test:rules` (run manually before rules deploys; not CI-wired). Related: [[../../obsidian-vault/01-Security/Known Open Items]], `.claude/rules/firestore.md`.
