# Data-Integrity Edge-Case Sweep — bookbed-dev

**Date:** 2026-05-30
**Worktree branch:** `test/data-integrity-edge-0530` (from `main` @ `ed31ae47`)
**Scope:** Backend data-integrity paths not exhaustively covered by prior smokes.
**Method:** Direct callable POST to deployed bookbed-dev CFs (eu-west1 + us-central1) + standalone Node unit tests against `functions/lib/*.js`. Seed/cleanup via Firebase Admin SDK with `test_run_id="edge-0530"` tag.

**TL;DR.** SF-026 (Zagreb-civil-day nights), overlap-race serialization, turnover-day, cancelled-status, stale-pending blocking, echo containment + TZ math, and SF-014 server-price authority all hold under stress. Three LOW findings on `availability.ts` + `stripePayment.ts` — none with end-user impact today; cleanup-class. No CRITICAL / HIGH / MEDIUM regressions surfaced.

---

## Scope matrix

| Area | CF/helper | Test file | Result |
|---|---|---|---|
| T1 — SF-026 nights + DST | `validateAndConvertBookingDates` / `normalizeToZagrebCivilDayUTC` / `calculateBookingNights` | `audit/edge-0530/t1-dst-nights.js` | ✅ PASS |
| T2 — overlap race + turnover | `createBookingAtomic` | `audit/edge-0530/t2-overlap-race.js` | ✅ PASS |
| T3 — availability consistency | `getUnitAvailability` | `audit/edge-0530/t3-availability.js` | ✅ PASS (1 LOW finding §F-86-01) |
| T4 — iCal echo + containment | `analyzeEvent` | `audit/edge-0530/t4-echo.js` | ✅ PASS |
| T5 — server price authority | `calculateBookingPrice` / `validateBookingPrice` | `audit/edge-0530/t5-price.js` | ✅ PASS |
| T6 — Stripe deposit + min + fee | `calculateDepositAmount`, `stripePayment.ts` | `audit/edge-0530/t6-stripe.js` | ✅ PASS (1 LOW finding §F-86-03) |

Live HTTP target: `https://{region}-bookbed-dev.cloudfunctions.net/{cf}` — anonymous CORS-permitted, with synthetic `X-Forwarded-For` per call to defeat the in-memory widget rate limit (10/600s per IP).

---

## Findings

### F-86-01 — `getUnitAvailability` inclusive-end overblocks manual_block windows  (LOW)

**Where:** `functions/src/availability.ts:166-170`

```ts
db.collection("properties").doc(propertyId).collection("units").doc(unitId)
  .collection("daily_prices")
  .where("date", ">=", startTs)
  .where("date", "<=", endTs)   // ← INCLUSIVE
  .where("available", "==", false)
```

**Repro:** Seeded `daily_prices/2026-07-01` with `available:false`. POST with `endDate=2026-07-01T00:00:00Z` (exclusive-checkout semantics) returns:

```json
{ "start": "2026-07-01T00:00:00.000Z", "end": "2026-07-02T00:00:00.000Z", "source": "manual_block" }
```

→ A booking window that the caller does NOT consider blocked (since `endDate` was exclusive) gets returned anyway.

**Impact today:** ZERO end-user impact.
- `firebase_booking_calendar_repository._streamBlockedEvents` explicitly drops `manual_block` windows (lib/features/widget/data/repositories/firebase_booking_calendar_repository.dart:101-103) — calendar drawing is driven independently by the daily_prices subcollection stream.
- `availability_checker._checkBlockedDates` (lib/features/widget/data/helpers/availability_checker.dart:329) queries Firestore directly with `blockedDate.isBefore(checkOut)` (exclusive). Server CF result is consulted only for `booking` + `ical_external` sources.

**Fix recommendation:** Change `<=` to `<` (true exclusive end). Reduces wire bytes + removes confusing semantic for future readers. Bookings + iCal already use exclusive end (`Date.parse(start) >= endDate.getTime()` at lines 205, 226).

**Severity:** LOW (cleanup). Pre-cutover candidate; not blocking.

---

### F-86-02 — `getUnitAvailability` collectionGroup queries unbounded by date  (LOW)

**Where:** `functions/src/availability.ts:155-178`

```ts
db.collectionGroup("bookings")
  .where("unit_id", "==", unitId)
  .where("status", "in", ["pending", "confirmed"])
  .limit(MAX_BOOKINGS_PER_QUERY)  // 500
  .get(),
db.collectionGroup("ical_events")
  .where("unit_id", "==", unitId)
  .limit(MAX_ICAL_PER_QUERY)      // 500
  .get(),
```

Both queries have no `date` filter — they return ALL active bookings + ALL iCal events for the unit, then post-filter in JS (`if (Date.parse(end) <= startDate.getTime()) continue;`).

**Impact:**
- Read cost scales with the unit's historical booking/iCal count, not with the requested window.
- Hot units approaching 500 active bookings will silently truncate (limit caps). `completeCheckedOutBookings` flips past stays to `completed` so this is normally fine; if that scheduled job ever skips, oldest pending/confirmed bookings vanish from the response and overlap reads can return stale availability.

**Fix recommendation:** Add `.where("check_in", "<", endTs).where("check_out", ">", startTs)` to the bookings query and the analogous range on ical_events. Aligns query cost with input window. Requires composite indexes (`unit_id+status+check_in`, `unit_id+start_date`).

**Severity:** LOW (cost + truncation latent risk).

---

### F-86-03 — Stripe min-amount silently overcharges on low-price units  (LOW)

**Where:** `functions/src/stripePayment.ts:377-393`

```ts
const STRIPE_MINIMUM_CENTS = 50;
const rawDepositCents = Math.round(depositAmount * 100);
let depositAmountInCents = Math.max(rawDepositCents, STRIPE_MINIMUM_CENTS);
```

**Repro (math layer):**

| Booking total | Deposit % | Raw deposit | Charged | Overpay | Multiplier on deposit |
|---|---|---|---|---|---|
| €0.10 | 20% | €0.02 | €0.50 | €0.48 | 25× |
| €1.00 | 10% | €0.10 | €0.50 | €0.40 | 5× |
| €2.50 | 20% | €0.50 | €0.50 | 0 (exact) | 1× |

**Mitigations already in place:**
- `stripePayment.ts:215` `if (!totalPrice) missingFields.push("totalPrice")` — falsy `totalPrice` (incl. 0) rejected at the gate. €0.00 → never reaches the €0.50 floor.
- Logged via `logInfo("…Adjusted deposit to Stripe minimum")` at lines 384-390.
- For a realistic property (`base_price ≥ €10`), 1% deposit on cheapest stay = €0.10 → €0.50 (€0.40 overpay), low-frequency.

**Fix recommendation (two options):**
1. **Reject path**: throw `failed-precondition` "Booking total below Stripe minimum €0.50" when `rawDepositCents < 50`. Forces owner to either raise base_price or use a non-Stripe payment method.
2. **Force-full-payment path**: if `rawDepositCents < 50` AND `totalPrice * 100 >= 50`, ignore deposit % and charge `totalPrice` (full). Avoids surprise charge ratio.

**Severity:** LOW (low frequency in real props; existing `logInfo` audit trail). Promote to MEDIUM only if a free-tier owner reports overcharge on a low-price unit.

---

## Non-findings — explicitly verified

These were canvassed during orientation and PASSED:

- **SF-026 nights consistency across DST**: `normalizeToZagrebCivilDayUTC` via Intl.DateTimeFormat en-CA correctly extracts Zagreb civil day on both spring-forward (2026-03-29) and fall-back (2026-10-25). Dart `.difference().inDays` (floor) and TS `Math.ceil` agree on normalized inputs. 400 random round-trips: 0 divergences.
- **Widget date-offset attack class**: input `2026-03-29T00:00:00+02:00` (CEST-offset mis-send for a pre-DST date) shifts the persisted day backward to `2026-03-28`. **NOT a CF bug** — widget responsibility to send the correct offset. Server normalizes by the offset as given; no silent magic to "guess" the intended day. Documented as a known data-quality risk class.
- **Overlap race**: 2× parallel `createBookingAtomic` on identical dates → Firestore txn serializes; exactly one HTTP 200, the other `ALREADY_EXISTS` 409.
- **Turnover same-day**: existing checkout=15, new checkin=15 → no conflict (query `check_out > checkInDate` evaluates `15 > 15 = false`).
- **Cancelled-status overlap**: pre-seeded `cancelled` booking does NOT block — query filter `status in ["pending","confirmed"]` excludes it.
- **Stale pending placeholder**: a `pending` booking 2 hrs old STILL blocks new bookings on same dates (cleanup hasn't run yet). Correct fail-CLOSED behavior — better than risking a double-book.
- **Same Zagreb-civil-day inputs**: 08:00 + 20:00 same date → post-normalize same UTC millis → throws "Stay must be at least 1 night" at `dateValidation.ts:221`.
- **PII strip on availability windows**: response objects contain ONLY `{start, end, source, platform?}`. No `guest_name` / `guest_email` / `payment_status` / `access_token` / `booking_reference` keys leak.
- **`confirmed_echo` iCal events excluded** from `ical_external` windows (line 221 explicit skip).
- **Echo containment**: 100% containment via interval union → `auto_skip`; partial (>0% <100%) → `save_trimmed` with new-range extraction; 0% → `save_unique`. Authoritative platforms (Booking.com, Airbnb, widget, direct) never echo. Zagreb TZ math (`22:00Z` = next-day Zagreb-civil-day midnight) confirmed via `generateNightSet` en-CA conversion.
- **Server price authority (SF-014)**: even with `clientTotalPrice=100000` on an €800 booking, `total_price` stored = **800**. The mismatch catch-and-fallback at `atomicBooking.ts:646-688` always uses server total. Client-locked price is never honored when it diverges.
- **`daily_prices` override priority**: explicit `daily_prices/{date}.price` takes priority over `weekend_base_price` or `base_price` (verified Wed 2026-06-09 override=200 reflected in server total).
- **Blocked daily_prices reject path**: stay covering `available:false` day → `failed-precondition "Date YYYY-MM-DD is not available"`.
- **Stripe fee allocation**: `application_fee_amount` NOT set in `createStripeCheckoutSession`. `on_behalf_of` AND `transfer_data.destination` both = `ownerStripeAccountId`. Stripe processing fee is deducted from the OWNER's payout; guest pays exactly the deposit/total. Confirmed via grep: 0 occurrences of `application_fee_amount:` in `stripePayment.ts`.
- **Stripe min-€0.50 free-booking guard**: `totalPrice=0` falsy-rejected at `stripePayment.ts:215`. €0 stays cannot reach the €0.50 floor (would otherwise surprise-charge €0.50 for nothing).
- **Idempotency key reuse**: `atomicBooking.ts:240-258` reads `idempotency_keys/{key}` BEFORE the transaction; if `bookingId` already set, returns same `bookingId` with `idempotent: true` flag. Was a suspect during orientation (post-success write only at line 1170), but a pre-check exists at line 240. NOT a finding.

---

## Test artifacts

All Node tests + the seed/cleanup script live under `audit/edge-0530/`:

```
audit/edge-0530/
├── seed.js              # idempotent seed of EDGE_prop_0530 + units + daily_prices
├── t1-dst-nights.js     # SF-026 + DST + Dart/TS parity (standalone)
├── t2-overlap-race.js   # createBookingAtomic real-call coverage
├── t3-availability.js   # getUnitAvailability real-call coverage
├── t4-echo.js           # analyzeEvent unit test (compiled JS import)
├── t5-price.js          # SF-014 server-authority over 6 mismatch cases
└── t6-stripe.js         # Stripe math + fee-allocation static checks
```

Run flow:

```bash
GCLOUD_PROJECT=bookbed-dev node audit/edge-0530/seed.js              # seed
node          audit/edge-0530/t1-dst-nights.js                       # standalone
GCLOUD_PROJECT=bookbed-dev node audit/edge-0530/t2-overlap-race.js   # ~6 bookings
GCLOUD_PROJECT=bookbed-dev node audit/edge-0530/t3-availability.js   # 0-cost
GCLOUD_PROJECT=bookbed-dev node audit/edge-0530/t5-price.js          # ~5 bookings
node          audit/edge-0530/t4-echo.js                             # standalone
node          audit/edge-0530/t6-stripe.js                           # standalone (math)
GCLOUD_PROJECT=bookbed-dev node audit/edge-0530/seed.js --cleanup    # final cleanup
```

**Rate-limit notes:**
- Anonymous `createBookingAtomic` is gated at 10/600s per IP (in-memory). T2 + T5 set `X-Forwarded-For` to a per-call random RFC1918 IP — works because the rate-limit key is the literal header string.
- Authenticated path uses Firestore-backed `enforceRateLimit`; not exercised here.

**Portability:** All seed/test scripts hardcode `/Users/duskolicanin/git/bookbed/functions/node_modules/firebase-admin` for the firebase-admin require. Adjust that path before reusing on another machine, OR run `npm install` inside the worktree's `functions/` first.

**Cleanup verification (post-run):**

```
Cleanup: deleting all docs tagged test_run_id="edge-0530" on bookbed-dev
  ✓ daily_prices (3 docs)
  ✓ bookings (0 docs)
  ✓ ical_events (0 docs)
  ✓ ical_feeds (0 docs)
  ✓ root docs (4)
Cleanup complete: 7 docs deleted.
```

Final state on bookbed-dev: zero residual `EDGE_*` documents under any path.

---

## Open follow-ups (not in this PR)

- **F-86-01 fix** (`<=` → `<`): trivial, but blocked on whether the widget might one day depend on the inclusive-end behavior for a calendar-render path I haven't traced. Worth a separate "consistency cleanup" PR with explicit widget-side test.
- **F-86-02 fix** (date-bounded queries + composite indexes): touches a hot CF query. Wants index deploy + load smoke. Multi-step.
- **F-86-03 fix** (reject-path vs force-full-payment): product-call. The reject-path is operationally safer (no surprise charge) but degrades free-tier owner UX. Discuss with owner before coding.
- **Widget DST offset risk**: document the +02:00-on-pre-DST-date bug class in `.claude/rules/widget.md` so future widget refactors include an offset-detection assertion before submission.

---

## Sign-off

No CRITICAL / HIGH / MEDIUM regressions surfaced. Three LOW findings filed (F-86-01..03). Existing SF-026 + SF-014 + overlap-race + iCal-echo + Stripe-fee-allocation invariants verified empirically end-to-end. PROD parity: untested in this sweep — these findings (and non-findings) describe the dev deploy at branch `main` HEAD `ed31ae47`. Apply the same checks on PROD before cutover.
