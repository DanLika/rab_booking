# audit/edge-0530 — data-integrity edge regression suite (bookbed-dev)

Origin report audit/86 deleted 2026-06-11 (git history); its verdict: SF-026
DST/nights, overlap race, turnover, cancelled-status, stale-pending blocking,
echo containment, SF-014 price authority — ALL PASS. Run from `functions/`
(needs `node_modules` + `npm run build` for `lib/`).

## Open LOW findings carried from audit/86 (re-verified open 2026-06-11)

| # | Where | What | Fix shape |
|---|---|---|---|
| F-86-01 | `availability.ts:184` `.where("date", "<=", endTs)` | inclusive-end returns a `manual_block` window the exclusive-checkout caller didn't ask for; zero end-user impact today (widget drops `manual_block` + checks blocked dates exclusively client-side) | `<=` → `<` |
| F-86-02 | `availability.ts` bookings + ical_events CG queries | no date filter — cost scales with unit history; 500-limit silently truncates hot units if `completeCheckedOutBookings` ever skips | add `check_in < endTs && check_out > startTs` range + composite indexes (memory: availability-cf-unbounded-cg-query) |
| F-86-03 | `stripePayment.ts` `Math.max(rawDepositCents, 50)` | Stripe €0.50 floor silently overcharges deposits on ultra-low-price units (€0.10 raw → €0.50 charged); logInfo trail exists | reject (`failed-precondition`) or force-full-payment when raw < 50¢; promote to MED only on real owner report |

| Script | What | Deps | Last run 2026-06-11 |
|---|---|---|---|
| `t1-dst-nights.js` | DST + nights helpers, Dart/TS parity over 400 stays | unit-level (functions/lib) | ✅ PASS |
| `t4-echo.js` | iCal echo detection + containment | unit-level | ✅ PASS |
| `t2-overlap-race.js` | `createBookingAtomic` overlap race + turnover | live CF + **seed.js fixtures** | not run (fixtures absent) |
| `t3-availability.js` | `getUnitAvailability` inclusive-end edge | live CF + seed | not run |
| `t5-price.js` | SF-014 price server-authority | live CF + seed | "FAIL" = `EDGE_prop_0530` fixture MISSING (cleaned post-May-30); CF correctly fail-closes "property unavailable" on unknown property — NOT an SF-014 regression. Re-run `seed.js` first. |
| `t6-stripe.js` | Stripe deposit / minimum / fee-allocation | live CF + seed | not run |
| `seed.js` | provisions `EDGE_prop_0530` fixtures | Admin SDK, dev-only | re-run before t2/t3/t5/t6 |
