# audit/87 — F-95 LOW bundle + platform_connections dead-code (SF-069)

**Scope:** `functions/src/{icalSync,bookingManagement,unitManagement}.ts` + `firestore.rules` platform_connections block.
**Date:** 2026-05-30
**Branch:** `fix/f95-low-bundle-0530`
**Deploy:** NOT deployed (operator gate). PROD + dev cutover deferred.

NOTE: `audit/95` doc not on `main` HEAD (`ed31ae47`). Scope inferred from
caller brief; F-95-IDs assigned to known items below. F-95-06/07/08 NOT
addressed (no source-of-truth doc to lift specs from).

---

## 1. Summary

| ID | Class | State | Fix |
|----|-------|-------|-----|
| F-95-01 | scheduledIcalSync missing `timeZone` | ✅ FIXED | Added `timeZone: "Europe/Zagreb"` |
| F-95-02 | autoCancelExpiredBookings missing `timeZone` | ✅ FIXED | Added `timeZone: "Europe/Zagreb"` |
| F-95-03 | autoCancel ignores `source` filter | ✅ FIXED | Mirrored external/iCal skip pattern from `autoCompleteCheckedOutBookings.ts:127-140` |
| F-95-04 | autoComplete pending→completed long-deadline guard | 🟡 DEFERRED | Risk doc — see §3.4 |
| F-95-05 | `onUnitDeleted` `deleteSubcollection` redundant `.get()` | ✅ FIXED | Removed pre-check fetch; while-loop handles empty case |
| F-95-06/07/08 | LOW unspecified (audit/95 missing) | ⏸ N/A | No source doc |
| dead-code | `platform_connections` rule | ✅ FIXED | `allow read, write: if false;` (fail-CLOSED) |

`scheduledPushNotifications` mentioned in brief — **does not exist** in
`functions/src/`. Confirmed via `grep -rln scheduledPushNotifications
functions/src/` returning zero. No action.

---

## 2. F-95-01/02 timeZone safety

**`scheduledIcalSync`** (`icalSync.ts:233-239`) used `schedule: "every 15
minutes"` with no `timeZone`. The cron is relative (interval) so timezone
has no effect on firing, but `last_synced.toDate()` + `new Date()`
comparisons throughout the handler use the runtime's clock. Adding
`timeZone: "Europe/Zagreb"` aligns logs and any future date-anchored
logic with the rest of the codebase (PROD operates in `Europe/Zagreb`).

**`autoCancelExpiredBookings`** (`bookingManagement.ts:93-97`) — same
class. `schedule: "every 24 hours"` is interval-based; timeZone is
cosmetic but consistent with `autoCompleteCheckedOutBookings`
(`completeCheckedOutBookings.ts:53,89`) and `cleanupOldRateLimits` /
other Zagreb-anchored CFs.

Zero behavioural risk — interval schedules don't shift firing on
timeZone change.

---

## 3. F-95-03/04 autoCancel + autoComplete

### 3.1 autoComplete already filters external (NOT in scope)

`autoCompleteCheckedOutBookings.ts:126-140` already skips:

```ts
if (data.source && ["booking_com", "airbnb", "ical", "external"]
    .includes(data.source.toLowerCase())) {
  logInfo(`[AutoComplete] Skipping external booking: ${doc.id}`);
  return false;
}
if (doc.id.startsWith("ical_")) { return false; }
```

**No change needed.**

### 3.2 F-95-03 — autoCancel external/iCal skip added

`autoCancelExpiredBookings` previously cancelled ANY `status=pending` +
`payment_deadline<now` row in `collectionGroup("bookings")`. While iCal
imports currently land in `ical_events` (NOT in `bookings`) per memory
[[seed-bookbed-dev-checkin-field]] and audit/30 / audit/40, there's no
schema-level invariant blocking a future webhook-imported external row
landing in `bookings`. Adding the skip is defence-in-depth + behavioural
parity with `autoCompleteCheckedOutBookings`.

Patch: post-query filter pass mirroring `autoComplete`. Filtered
candidates logged with the original delta:

```ts
logSuccess("Auto-cancelled expired bookings", {
  candidates: expiredBookings.size,
  cancelled: filteredBookings.length,
  externalSkipped: expiredBookings.size - filteredBookings.length,
});
```

Risk: zero behaviour change against current data (no external rows in
bookings CG today); explicit skip when an external source field appears.

### 3.3 onBookingStatusChange — not modified

Brief referenced "paralelno onBookingStatusChange". That trigger
(`bookingManagement.ts:287-…`) is `onDocumentUpdated` on subcollection
path, fires on ANY status change. It does not query — no source filter
applicable. Sidebar reference only; no edit needed.

### 3.4 F-95-04 — autoComplete pending→completed deferred (risk doc)

Current `autoCompleteCheckedOutBookings.ts:110-114` query:

```ts
.where("status", "in", ["confirmed", "pending"])
.where("check_out", "<", todayTimestamp)
```

A pending booking whose `check_out` has passed gets flipped to
`completed`. Logical issue: "completed" implies the stay happened; a
never-confirmed pending row past `check_out` more likely means the
guest never paid / owner never approved → should be `cancelled`, not
`completed`.

**Why deferred:**
1. Removing `"pending"` from the `status` filter cuts a fallback path
   for stale pending rows (those autoCancel missed for any reason —
   `payment_deadline` not set, scheduled job failed N runs in a row,
   etc.). They'd sit `pending` indefinitely.
2. Alternative — flip pending past check_out to `cancelled` instead of
   `completed` — touches downstream email / Stripe-refund / iCal-cache
   flows (`onBookingStatusChange` reacts to status transitions and
   sends approval / cancellation mails). Status flip from pending →
   cancelled fires `sendBookingCancellationEmail` → could send
   weeks-late "your booking is cancelled" emails to guests whose stay
   already ended.
3. Long-deadline guard variant (only flip pending if check_out > 7d
   stale) is bespoke logic that needs product owner alignment.

**Recommended follow-up:** audit/95-style finding + targeted PR after
schema-level decision on "what does a stale pending mean". Out of
scope for this LOW bundle.

---

## 4. F-95-05 onUnitDeleted redundant query

`unitManagement.ts:106-117` (pre-fix) did TWO identical reads:

```ts
// 1st read — pre-check for empty
const snapshot = await collectionRef.limit(BATCH_SIZE).get();
if (snapshot.empty) {
  logInfo(`No ${subcollectionName} to delete`);
  return;
}
let totalDeleted = 0;
while (true) {
  // 2nd read — same query, immediately
  const batchSnapshot = await collectionRef.limit(BATCH_SIZE).get();
  …
}
```

Fix: drop the pre-check. While-loop's first iteration handles the
empty case. Empty-log moved to the post-loop `else` branch:

```ts
while (true) {
  const batchSnapshot = await collectionRef.limit(BATCH_SIZE).get();
  if (batchSnapshot.empty) break;
  …
}
if (totalDeleted > 0) {
  logInfo(`Deleted ${subcollectionName}`, {…});
} else {
  logInfo(`No ${subcollectionName} to delete`, {…});
}
```

`onUnitDeleted` calls `deleteSubcollection` 3× (bookings + daily_prices +
widget_settings). Pre-fix: 3 wasted reads on empty subcollections per
unit delete; 1 wasted read per non-empty per call. Fix: zero wasted
reads.

---

## 5. platform_connections dead-code

**Verification:**
```
grep -rln platform_connections /tmp/bb-f95-wt/lib/ /tmp/bb-f95-wt/functions/
# → zero matches
```

Rule was at `firestore.rules:428-432` — owner-scoped CRUD on a
collection nobody reads or writes. The rule shipped `audit/05`-era
when Booking.com / Airbnb OAuth was scoped but never implemented.

**Fix:** `allow read, write: if false;` — fail-CLOSED. Cheaper /
lower-risk than removing the `match` block entirely (which would
default to deny anyway, but leaves no breadcrumb for future readers).
Collection-level cleanup (Firestore CLI delete) deferred to operator;
empty collection has zero cost.

---

## 6. Verification

| Check | Result |
|-------|--------|
| `npm run build` | 0 errors |
| `npm test` | **387 / 387** PASS |
| `npm run test:rules` | **46 / 46** PASS |
| Static grep `platform_connections` outside rules | 0 references in `lib/` + `functions/` |

NOT deployed — operator gate. Pre-PROD checklist:
1. Confirm no PROD doc lives under `/platform_connections/*` (Firestore Data tab).
2. Pre-dev: `firebase deploy --only firestore:rules,functions:scheduledIcalSync,functions:autoCancelExpiredBookings,functions:onUnitDeleted --project bookbed-dev`.
3. Live smoke — trigger autoCancel via `gcloud functions services run` (or wait next 24h fire) and inspect log for `externalSkipped` counter.
4. PROD cutover after dev burn-in.

---

## 7. Open follow-ups

- **F-95-04** — autoComplete pending→completed semantics, per §3.4. Needs product decision before touching.
- **F-95-06/07/08** — audit/95 source doc missing; specs unknown. Either restore the doc or close the placeholder IDs.
- **`platform_connections` collection** — operator cleanup (CLI delete) once docs confirmed absent.

---

## 8. Refs

- `firestore.rules` pre-PR: `ed31ae47`
- File diffs: `functions/src/icalSync.ts`, `functions/src/bookingManagement.ts`, `functions/src/unitManagement.ts`, `firestore.rules`
- Cross-ref: audit/86 §5 platform_connections dead-code recommendation
- Memory link: `[[f94-direct-write-sweep]]` (audit/86 sibling)
