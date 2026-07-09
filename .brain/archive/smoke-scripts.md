# audit/smoke/ — reusable live regression smokes (KEPT)

**Correction 2026-07-09:** an earlier pass in this branch deleted these as "closed one-shots" — that was wrong. Re-reading them + their README shows they are the *deliberately-kept* reusable regression tools (a prior June prune already removed the true one-shots). **Restored + kept.** They hit the **deployed bookbed-dev** environment — coverage the emulator rules suite cannot give.

| Script | What it guards | Run |
|---|---|---|
| `f92-01-probe.js` | READ-ONLY iCal export-token schema matrix (OK / BROKEN-FEED / FAIL-CLOSED). Regression tool for the audit/92 `_plaintext`/`_hash` vs canonical `ical_export_token` mismatch. PROD-refused. | `GOOGLE_CLOUD_PROJECT=bookbed-dev node audit/smoke/f92-01-probe.js` |
| `complete-booking-smoke.js` | `completeBooking` CF end-to-end (F-67-01): seed confirmed booking → call → assert `completed`+`completed_at` → idempotency-reject → cleanup. PW from `BB_TEST_PW` env, public web key read from `firebase_options_dev.dart`. | `BB_TEST_PW=… GOOGLE_CLOUD_PROJECT=bookbed-dev node audit/smoke/complete-booking-smoke.js` |
| `audit123-deploy-smoke.js` | Post-deploy: iCal feed 200/403 + `getStripeAccountStatus` rate-limit exhaustion (~call 31, limit 30/300s). Secrets from `BB_SMOKE_API_KEY`/`BB_SMOKE_PW` env. Fixed a hardcoded absolute-path wart on line 5 → relative resolve. | `BB_SMOKE_API_KEY=… BB_SMOKE_PW=… node audit/smoke/audit123-deploy-smoke.js` |

All secret-clean (env-var creds, PROD asserted). Not CI-wired (manual pre-deploy smokes). Related: `.claude/rules/firestore.md`, memory `test-account`.
