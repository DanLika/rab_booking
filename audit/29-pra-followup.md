# audit/29 — PR-A follow-up (post audit/26)

> **Renamed from `audit/28-pra-followup.md` 2026-05-23** — `audit/28-tier4-resend-sentry-baseline`
> landed in parallel and claimed the 28 slot first (changelog 6.88, commit `8e6b0f41`).

**Date:** 2026-05-23
**Scope:** Items deferred from audit/26 PR-A (commit `b63423e2`, PR #456) plus one finding correction
discovered while verifying PR-A coverage. Bundle of 4 items + 1 correction.
**Status:** DOC ONLY. All 4 items are TIER 3 PROD cutover blockers — sequencing matters.
**Cross-refs:** `audit/26-bb-e2e-findings.md` (parent), `audit/22-prod-cutover-plan.md` §6
(TIER 3 cutover), `memory/ical-cache-no-invalidation.md` (A.4 motivation).

---

## 0. audit/26 #5 — `nights` field write — CLOSED ✅

`audit/26` §6 originally claimed: "Finding #5 auto-resolves if PR-A lands". That claim
was **only half true** initially (PR-A `b63423e2` covered owner paths but missed the guest
widget path). audit/27 §5 + §12 surfaced the gap empirically. A 1-line follow-up fold landed
in commit **`e9a45c31`** on `fix/audit-26-pra-owner-direct-write` (PR #456). All three CF
write paths now persist `nights`:

| CF | Computes? | Persists? | Verified |
|---|---|---|---|
| `createBookingAtomic` (widget, atomicBooking.ts:777 + 1091) | ✅ line 777 `const bookingNights = calculateBookingNights(...)` | ✅ line 1091 in `bookingData` (commit `e9a45c31`) | ✅ |
| `createOwnerBookingAtomic` (PR-A, atomicBooking.ts:1748 + 1789) | ✅ line 1748 | ✅ line 1789 in `bookingData` | ✅ |
| `updateBookingAtomic` (PR-A, atomicBooking.ts:1970 + 1984) | ✅ line 1970 | ✅ line 1984 (on date change) | ✅ |

**Status:** audit/26 #5 fully closed. SF-026 normalize migration target population trends to
zero for new bookings created via these three callables.

**Residual scope — VERIFIED open via `grep -n 'nights\|placeholderData' functions/src/stripePayment.ts`:**
- **Stripe placeholder write** (`stripePayment.ts createStripeCheckoutSession`, `placeholderData`
  literal at line 671-708, written via `transaction.set` line 712-721) — **NO `nights` field**.
  Same gap as the widget `createBookingAtomic` had before `e9a45c31`. Trivial 1-line dop:
  add `nights: bookingNights,` between `check_out` (line 680) and `guest_count` (line 681).
  `bookingNights` already computed earlier in the same function (line ~429). Tracked here as
  **audit/29 follow-up A.5** — XS, ship standalone or fold into Tier 4 stripe pass.
  Not gating audit/29 closure.
- **Stripe finalize updates** (`stripePayment.ts:957` + `:1243`) are status-only `.update()`
  calls that don't write `nights`; not a regression because the placeholder doc already
  carried (or will carry, post A.5) the field.
- **Existing K=4 prod drifters** documented in `audit/22` §"PROD --force backfill" still
  require the one-time `--execute` run per the cutover plan. Independent of this fix.

**Verification log:**
- `e9a45c31` diff: single insertion at line 1091: `nights: bookingNights, // closes audit/26 #5 for guest path`
- Test results post-fold (Terminal D, 2026-05-23):
  - `flutter analyze` — 0 issues
  - `flutter test` — 1070 pass / 30 fail (baseline unchanged, all pre-existing widget-test failures)
  - `functions: npm run build` — 0 errors
  - `functions: npm test` — 182/186 pass (4 stripeConnect failures pre-exist)
  - `functions: npm run test:rules` — 24/24 pass

---

## 1. A.2 — Status-flip clobber sites

**Problem:** Status-flip operations (approve / reject / cancel / confirm / complete /
delete) currently write **full `toJson()`** of the booking back to Firestore, clobbering
any field that's drifted on the server (e.g., `nights` filled in by a future trigger,
`access_token` rotated by a CF). audit/26 §2.2 "Lower-risk siblings" table:

| Site | Path | Clobber risk |
|---|---|---|
| `multi_select_action_bar.dart:202` | bulk status change | full `toJson()` clobber per booking |
| `firebase_owner_bookings_repository.dart:845` | `approveBooking` | full `toJson()` clobber (FROZEN) |
| `firebase_owner_bookings_repository.dart:885` | `rejectBooking` | full `toJson()` clobber (FROZEN) |
| `firebase_owner_bookings_repository.dart:928` | `confirmBooking` | full `toJson()` clobber (FROZEN) |
| `firebase_owner_bookings_repository.dart:954` | `cancelBooking` | full `toJson()` clobber (FROZEN) |
| `firebase_owner_bookings_repository.dart:983` | `completeBooking` | full `toJson()` clobber (FROZEN) |
| `firebase_owner_bookings_repository.dart:1008` | `deleteBooking` | direct `.delete()` — no clobber, but bypasses CF |

**Fix path:**
- Migrate to **partial-update payload**: only `{status: 'X', updated_at: serverTimestamp(), cancellation_reason?: '...'}`.
- For `multi_select_action_bar`: trivial — just replace `.update(booking.toJson())` with
  `.update({status: newStatus, updated_at: ...})`.
- For the 989-line FROZEN repo: **SHADOW-TEST PRVO**. CLAUDE.md NIKADA NE MIJENJAJ requires
  unit-test coverage first. Recipe:
  1. Write integration tests against the 6 lifecycle methods using `@firebase/rules-unit-testing`
     against emulated Firestore — verify pre/post doc shape (no clobber, only `status` +
     `updated_at` change, `access_token` preserved, `created_at` preserved, etc.).
  2. Land the tests as their own commit (untouchable repo gets a safety net).
  3. THEN refactor the 6 methods to partial-update payloads.
- New CF `updateBookingStatusAtomic` is **NOT** needed — these are pure status-only writes,
  no overlap concern. They can stay client-side IF rules tightening (A.3) accommodates
  status-only updates via `request.resource.data.diff(resource.data).affectedKeys()`.

**Effort:** ~3-4h for `multi_select_action_bar` + integration test scaffold. ~6-8h for full
FROZEN repo migration with shadow tests.

**Risk:** Medium. FROZEN repo has no tests today and CLAUDE.md tagged it explicitly. Shadow
tests are non-negotiable.

---

## 2. A.3 — Firestore rules tighten (EXTENDED scope)

**Problem:** Firestore rules (`firestore.rules` lines 165-178 + 263-318) still permit
authenticated owners to write directly to `bookings/{id}`. PR-A added CFs but the rules
don't enforce the CF-only path. Any new UI path (or rolled-back client) bypasses the new
overlap check.

**Original audit/26 §2.5 step 6 scope:** "disallow client writes to `check_in/check_out/unit_id`"

**EXTENDED scope (this audit):** Tighten **create + update + delete**, not just update:

- **create** — Reject `request.auth != null` writes. Only Admin SDK (CF) can create. This
  closes the case where a client could call `.add()` with arbitrary `owner_id` (already
  partially blocked by `request.resource.data.owner_id == request.auth.uid` but doesn't
  enforce the overlap-check path).
- **update** — Reject writes where
  `request.resource.data.diff(resource.data).affectedKeys()` overlaps with
  `['check_in', 'check_out', 'unit_id', 'property_id', 'owner_id', 'check_in_date',
   'check_out_date']`. Status-only flips (after A.2 migrates to partial payload) still pass.
- **delete** — Reject client deletes. Only Admin SDK (and via callable). Today deletes go
  through `bookingRepo.deleteBooking()` which directly calls `.delete()` — needs migration
  to a new CF `deleteBookingAtomic` OR a callable wrapper. Tracked as A.3 sub-item.

**Sequencing — CRITICAL:**

```
A.2 deploy
  ↓
A.2 smoke (bookbed-dev, 2-3 days observation, watch Sentry)
  ↓
A.3 deploy
  ↓
A.3 smoke (rules-test full matrix, emulator + dev)
```

**Reverse order = production breakage.** If A.3 deploys first, A.2's still-clobbering
sites will be rejected by tightened rules → owner dashboard breaks for all status flips.

**Effort:** ~1-2h rules change + 4-6h rules-test matrix (test/firestore_rules/bookings.test.ts
already exists; add 12-15 new cases covering the diff-based affectedKeys check). Total ~6-8h.

**Risk:** High if sequencing slips. Medium otherwise.

**Blocks:** TIER 3 PROD cutover (audit/22 §6). Cutover ships rules tightening — needs A.3
in same release window.

---

## 3. A.4 — iCal cache invalidation trigger (NEW)

**Problem:** Per `memory/ical-cache-no-invalidation.md`, `widget_settings.ical_cache_content`
has a 5-min TTL but NO booking trigger flushes it. Owner approve/reject/create operations
take up to 5 minutes to appear in iCal export feeds (Airbnb, Booking.com, etc.).

**Source:** audit/27 Terminal D §7 (parallel session). The cache invalidation is
**adjacent to PR-A scope** — PR-A added new booking write paths through CFs, the cache
invalidation lives in the same trigger surface (`functions/src/onBookingCreated.ts` and
the lifecycle handlers in `bookingManagement.ts`).

**Fix:** Add a Firestore trigger `onBookingWritten` that watches
`properties/{propertyId}/units/{unitId}/bookings/{bookingId}` and on any write:
- Look up the unit's `widget_settings/{unitId}` doc.
- Set `ical_cache_invalidated_at: serverTimestamp()` (new field).
- The iCal export CF (`icalExport.ts`) checks this field; if newer than `ical_cache_built_at`,
  rebuild instead of serving cache.

Alternative (simpler): just DELETE `ical_cache_content` field on booking write. Next iCal
export request triggers rebuild. Cleaner — no schema drift.

**Effort:** ~2-3h CF + 1h smoke (verify Airbnb feed updates within 30s of cancel).

**Risk:** Low. Trigger fan-out is contained.

**Blocks:** Not a TIER 3 hard-blocker but UX-significant (5-min iCal lag is visible to
external platforms — Booking.com partner support has flagged this in past).

---

## 4. PropertyId non-null cleanup

**Problem:** `BookingModel.propertyId` is `String?` (nullable, freezed annotation line 20)
but the CF treats it as required (`OwnerBookingCallableService.createBooking` passes
`String?`, CF rejects null with `invalid-argument`). Code smell — server contract demands
non-null, client model lies. Discovered during PR-A static analysis (5 `argument_type_not_assignable`
errors initially, relaxed to `String?` for PR-A as a workaround).

**Fix:**
1. **Backfill query on BOTH Firebase projects** (dev + PROD):
   - `bookbed-dev`: `firebase firestore:query --project bookbed-dev --collection-group bookings --where 'property_id == null'` (use `gcloud` + JSON output to check raw count; CG queries on null field require single-field index exemption — see `audit/26` §7 fixture gap).
   - `rab-booking-248fc` (PROD): same query, READ-ONLY first to confirm count (expected 0 — every booking write goes through paths that set property_id).
   - If any rows: write a one-shot CF migration to backfill from `parentRef.parent.parent.id` (extract from the subcollection path).
2. Update `lib/shared/models/booking_model.dart` line 20: `@JsonKey(name: 'property_id') required String propertyId,` (drop `?`, mark required).
3. Run `dart run build_runner build --delete-conflicting-outputs` to regenerate freezed.
4. Fix all call sites that pass nullable (5 expected, same as PR-A workaround).
5. Tighten `OwnerBookingCallableService` to `required String propertyId` (revert PR-A workaround).

**Effort:** ~2h backfill check (read-only) + 1h migration if needed + 1h model + 1h call sites + tests. Total ~4-5h.

**Risk:** Medium. PROD backfill query against a hot collection-group needs index exemption
first (audit/26 §7 fixture gap). Do dev first, then PROD.

**Blocks:** Nothing immediately — but reduces future bug surface (every "what if propertyId
is null?" branch can be deleted).

---

## 5. Sequencing summary

| Order | Step | Why this order |
|---|---|---|
| 1 | A.2 deploy + smoke | Must land before A.3 or rules break clients |
| 2 | A.4 deploy | Standalone, can ship parallel with A.2 |
| 3 | A.3 deploy + rules-test | Locks the CF-only path; ships with TIER 3 cutover |
| 4 | PropertyId cleanup | Quality-of-life after the hot path stabilizes |
| 5 | A.5 Stripe placeholder `nights` dop | XS standalone OR fold into Tier 4 Stripe pass |
| — | Finding #5 widget `nights` dop | ✅ CLOSED via PR #456 commit `e9a45c31` |

**TIER 3 PROD cutover (audit/22 §6) blocked on A.3.** A.2 must precede A.3 by 2-3 days
of dev observation. Plan accordingly.

---

## 6. Cross-references

- `audit/26-bb-e2e-findings.md` — parent audit. §6 Finding #5 correction lives here.
- `audit/22-prod-cutover-plan.md` §6 — TIER 3 cutover blocks on A.3.
- `memory/ical-cache-no-invalidation.md` — A.4 motivation.
- `memory/multi-agent-git-race.md` — used during PR #456 commit; same precautions apply
  to follow-up PRs while parallel terminals are active.
- PR #456 (`fix/audit-26-pra-owner-direct-write`) — parent commit `b63423e2`. Closes the
  race-safety + SF-026 normalize portion of audit/26 Finding #4. Does NOT close the rules
  tightening portion (deferred → A.3 here).
- Terminal B (functions/src/bookingManagement.ts changes — audit/26 PR-B) — orthogonal
  scope. Not blocked by A.2/A.3/A.4.
- Terminal C (lib/core/error_handling — audit/20 ErrorBoundary narrowing) — orthogonal
  scope. Not blocked.
- Terminal D (audit/27 — separate scope) — A.4 motivation comes from D's §7 discovery.

---

**End audit/29**
