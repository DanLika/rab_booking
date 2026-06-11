# audit/edge-0530 — data-integrity edge regression suite (bookbed-dev)

Companion doc: `audit/86-data-integrity-edge-2026-05-30.md`. Run from
`functions/` (needs `node_modules` + `npm run build` for `lib/`).

| Script | What | Deps | Last run 2026-06-11 |
|---|---|---|---|
| `t1-dst-nights.js` | DST + nights helpers, Dart/TS parity over 400 stays | unit-level (functions/lib) | ✅ PASS |
| `t4-echo.js` | iCal echo detection + containment | unit-level | ✅ PASS |
| `t2-overlap-race.js` | `createBookingAtomic` overlap race + turnover | live CF + **seed.js fixtures** | not run (fixtures absent) |
| `t3-availability.js` | `getUnitAvailability` inclusive-end edge | live CF + seed | not run |
| `t5-price.js` | SF-014 price server-authority | live CF + seed | "FAIL" = `EDGE_prop_0530` fixture MISSING (cleaned post-May-30); CF correctly fail-closes "property unavailable" on unknown property — NOT an SF-014 regression. Re-run `seed.js` first. |
| `t6-stripe.js` | Stripe deposit / minimum / fee-allocation | live CF + seed | not run |
| `seed.js` | provisions `EDGE_prop_0530` fixtures | Admin SDK, dev-only | re-run before t2/t3/t5/t6 |
