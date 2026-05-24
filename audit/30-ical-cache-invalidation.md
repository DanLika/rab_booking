# audit/30 — iCal export cache invalidation (PR #461)

**Date:** 2026-05-23 / 2026-05-24
**Scope:** Resolve `widget_settings.ical_cache_*` 5-min TTL stale-feed problem.
**PR:** [#461](https://github.com/DanLika/rab_booking/pull/461) `fix/ical-cache-invalidation` → `main`
**Memory ref:** `memory/ical-cache-no-invalidation.md` (origin), `memory/multi-agent-git-race.md` (2x swap recovery this session)

---

## 1. Problem

`functions/src/icalExport.ts:318-324` writes 4 cache fields to
`properties/{propertyId}/widget_settings/{unitId}` with `ICAL_CONFIG.CACHE_TTL_SECONDS = 300`:

```
ical_cache_content
ical_cache_generated_at
ical_cache_etag
ical_cache_unit_name
```

`getUnitIcalFeed` reads cache at `:169` and returns cached content if `now < cachedAt + 300s` AND `cachedContent` truthy. ETag short-circuit at `:181` returns `304 Not Modified` if `If-None-Match` matches.

`grep -rn "ical_cache_content\b" functions/src/` returned only the two icalExport sites pre-PR. **No trigger flushed the cache on booking change.** Owner pulling feed URL within 5 min after a status flip / date edit / new booking saw stale feed.

## 2. Constraints

- External aggregators (Airbnb / Booking.com / Google) poll iCal feeds every ≥15 min → 5-min lag invisible there.
- Owner-driven inspection (manual feed pull, validator check, sanity verification right after a booking action) IS sensitive → user-visible bug.
- T11c CLOSED (CLAUDE.md NIKADA NE MIJENJAJ row): `bookings` reads on widget routed through `getUnitAvailability` callable, NOT `getUnitIcalFeed`. iCal feed stays an export surface, not a read surface for the widget.

## 3. Fix architecture

### 3.1 Helper

`functions/src/utils/icalCache.ts` (new file):

```typescript
export async function invalidateIcalCache(propertyId, unitId): Promise<void> {
  try {
    await db.collection("properties").doc(propertyId)
      .collection("widget_settings").doc(unitId)
      .update({
        ical_cache_content: admin.firestore.FieldValue.delete(),
        ical_cache_generated_at: admin.firestore.FieldValue.delete(),
        ical_cache_etag: admin.firestore.FieldValue.delete(),
        ical_cache_unit_name: admin.firestore.FieldValue.delete(),
      });
    logInfo("[iCal Cache] Invalidated", {propertyId, unitId});
  } catch (e) {
    logWarn("[iCal Cache] Invalidation skipped or failed", { /* … */ });
  }
}
```

Non-fatal contract: NOT_FOUND swallowed (units without iCal export have no `widget_settings` doc); any other error logged as `logWarn` and ignored — next feed read regenerates regardless. Pattern matches existing trigger error handling (`bookingManagement.ts:246-249`).

### 3.2 Call sites (4 total)

| Site | File | Gate | Why |
|---|---|---|---|
| `atomicBooking.createBookingAtomic` | `atomicBooking.ts:~1431` | every successful return | Sync flush before client response — closes async-trigger lag window |
| `onBookingCreated` | `bookingManagement.ts:~211` | every fire (after `if (!booking) return`) | Stripe-instant paths early-return before email block; placing invalidation at top covers them |
| `onBookingStatusChange` (status) | `bookingManagement.ts:~283` | `statusChanged \|\| datesChanged` | Cancel/reject drops booking from feed; pending↔confirmed both in feed but cache regen is cheap |
| `onBookingStatusChange` (dates) | same | check_in/check_out diff via `toMillisOrZero(t)` | Owner calendar drag changes date without status change |
| `autoCancelExpiredBookings` (schedule) | n/a | cascades via `onBookingStatusChange` | Schedule writes `status=cancelled`, trigger fires invalidation |

`toMillisOrZero(t)` defensive Timestamp comparison (inline in bookingManagement.ts) — returns 0 on missing/bad input so stale fields can't throw out of a trigger.

### 3.3 Self-retrigger isolation

`onBookingStatusChange` fires on its own writes (`access_token` at `:308`, `emails_sent.*` at `:341`, `booking_reference` auto-heal at `:444`). Status preserved in all → `statusChanged` false; dates preserved → `datesChanged` false; cache flush skipped. No write storm.

## 4. Deferred — `icalSync.ts` external block imports

`icalSync.ts` writes/deletes `ical_events` docs which DO appear in feed (`icalExport.ts:304` passes them to `generateIcalCalendar`). External-platform sync flow (`syncSingleFeed` at `:354`) skips invalidation today — cache stays stale until TTL on external-source changes.

**Not fixed in this PR because:**
1. Concurrent agent has uncommitted edits to `icalSync.ts` (audit/31 SSRF + log-leak fixes). Folding mine = staging confusion + merge risk in multi-agent tree.
2. **Low value in isolation:** the only consumer affected is another external aggregator polling the BookBed export. Per Critical Learning #7 (CLAUDE.md → memory) most aggregators ALSO poll ≥15 min, so the same 5-min lag is invisible to them.

**Follow-up shape:** ~5 lines in `syncSingleFeed` after successful `insertNewEventsWithEchoDetection` (`:386-388`). Land after audit/31 SSRF PR merges.

## 5. Multi-agent race recovery (notable)

Branch swapped on me TWICE during PR #461 work:
1. Once during `utils/icalCache.ts` Write — landed on main as untracked; moved to `/tmp`, switched to fix branch, restored.
2. Once during initial commit attempt — branch guard `[ "$(git branch --show-current)" = "fix/..." ] || exit 1` caught it; recovery as in CHANGELOG 6.87 §3.

Other agents (Terminal D/G/?) had uncommitted edits to `icalSync.ts` + `resendGuestBookingEmail.ts` + `CLAUDE.md` in shared working tree throughout. Never staged any of theirs — explicit per-path `git add` + branch verify right before commit.

Reinforces `memory/multi-agent-git-race.md` patterns. Added: file-Write tools can race the same way `git add` does — the destination branch can swap between read-current-state and write-new-content.

## 6. Coverage matrix

| Scenario | Pre-PR lag | Post-PR lag |
|---|---|---|
| New booking (any payment) → owner pulls feed | 0–300 s | ~0 s (synchronous pre-flush in `atomicBooking`) |
| Status flip (approve / reject / cancel) → owner pulls feed | 0–300 s | ~0 s (`onBookingStatusChange` trigger) |
| Owner drag-edits dates on calendar | 0–300 s | ~0 s (`onBookingStatusChange` date diff) |
| Auto-cancel schedule fires → feed | 0–300 s | ~0 s (cascade through `onBookingStatusChange`) |
| External iCal import block → feed | 0–300 s | **unchanged (0–300 s)** — deferred |
| Owner manually deletes booking doc (no status flip) | 0–300 s | unchanged — `onBookingDeleted` not wired; rare path, no caller |

## 7. Verification

- `npx tsc --noEmit` clean across 3 changed files
- `npx eslint` 0 new violations in my line ranges (166 pre-existing in `bookingManagement.ts` + `atomicBooking.ts` unaffected, all legacy max-len / no-explicit-any)
- `npx jest test/bookingManagement.test.ts` — 4/4 pass (existing trigger tests cover early-returns from mocked Firestore reads cleanly; my helper eats mock NOT_FOUND silently)
- Pre-commit hook (dart format) — clean both PR commits
- Manual dev smoke pending after merge:
  - [ ] Create booking → curl feed URL within 30s → VEVENT present
  - [ ] Status flip → re-pull → updated/removed
  - [ ] Date edit on calendar → re-pull → dates reflected
  - [ ] `dig +short TXT bookbed.io | grep -c spf1` (unrelated, audit/28 §5.3 work)

## 8. Sign-off

| Item | State |
|---|---|
| §1 problem statement | ✅ |
| §2 constraints | ✅ |
| §3 fix architecture | ✅ |
| §4 deferred icalSync | 🚫 known gap, documented, follow-up planned |
| §5 race recovery notes | ✅ |
| §6 coverage matrix | ✅ |
| §7 verification | ✅ static; ⏳ post-merge manual smoke |
| PR #461 | ✅ open, 2 commits (`b71fa0e8` + `6a00abbf`), description updated |

**Status:** Static analysis complete. Awaiting reviewer + merge. Manual smoke deferred to post-merge dev deploy.
