# audit/113 — SF-080: Layer-1 RULES trial gate

**Date:** 2026-06-03
**Branch:** `security/trial-gate-rules` (off `main @ cf65f9c8`)
**Status:** DEV deployed + smoke green. PR opened, NO MERGE.
**Companion of:** audit/110 (SF-078 server-side L1) + audit/112 (SF-079 L2 guest-path)

## 1. Goal

Mirror SF-078's server-side L1 gate at the rules layer. Block owner direct-write
on owner-management paths when caller's `accountStatus` is not in
`['trial','active']`. Admin (custom claim or Firestore role) bypasses the gate.

Server-side CF gate already blocks the CF-callable surface. This PR closes the
direct-Firestore-SDK surface for the same set of owner-management paths.

## 2. Owner direct-write path map

Existing rules (`main @ cf65f9c8`, pre-edit) that lacked status check:

| # | Match path | Ops | Allow predicate (pre-edit) |
|---|---|---|---|
| 1 | `/properties/{propertyId}` | create + update | `canCreateAsOwner()` / `isResourceOwner()` |
| 2 | `/properties/{p}/units/{u}/bookings/{b}` | create + update + delete | `isPropertyOwner(propertyId)` |
| 3 | `/properties/{p}/units/{u}/daily_prices/{d}` | create + update + delete | `isPropertyOwner(propertyId)` |
| 4 | `/properties/{p}/widget_settings/{u}` | create + update + delete | `isPropertyOwner(propertyId)` |
| 4b | `/{path=**}/widget_settings/{u}` (CG mirror) | create + update + delete | `auth + property.owner_id == auth.uid` |

**Not gated** (intentional, out of map):

- `/properties/{propertyId}` **delete** — soft exit for cleanup after trial expiry.
  Owner can still tear down their property; matches L2 anti-strand spirit.
- `/properties/{p}/units/{u}` — unit subcollection writes (user's explicit map
  did not include this path).
- `/properties/{p}/ical_feeds/{feedId}` — iCal feed config writes (not in map).
  iCal feed `sync_count`/`event_count`/`last_synced` already deny-listed by
  SF-068.
- `/properties/{p}/widget_secrets/{u}` — already minimal write surface
  (`isPropertyOwner` only); not requested in map.
- `/properties/{p}/units/{u}/additional_services/{s}` — not in map.
- `/{path=**}/units/{u}` (CG units writes) — not in map.

`firestore.rules` is NOT on the frozen list. The Dart-side frozen flows
(Calendar Repository, Cjenovnik, Unit Wizard publish flow, Navigator.push,
Timeline) all run as the active owner whose accountStatus is `trial` or
`active` — for them the gate is transparent. Trial-expired / suspended owners
already hit the SF-078 server-side gate first; the rules layer is the second
line of defence for direct-SDK paths.

## 3. Predicate

```rules
function isActiveOwner() {
  return isAuthenticated() &&
    exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
    get(/databases/$(database)/documents/users/$(request.auth.uid))
      .data.get('accountStatus', null) in ['trial', 'active'];
}
```

Fail-CLOSED arms:

| Caller state | Result |
|---|---|
| not authed | deny (`isAuthenticated()` = false) |
| `/users/{uid}` doc missing | deny (`exists` short-circuits) |
| accountStatus field missing | deny (`.get(field, null)` → null) |
| `accountStatus: 'trial_expired'` | deny |
| `accountStatus: 'suspended'` | deny |
| `accountStatus: 'premium'` (off-spec drift) | deny |
| `accountStatus: 'trial'` | allow |
| `accountStatus: 'active'` | allow |

Allow-list mirrors `requireActiveOwner.ts` (SF-078) and `requireActiveUnitOwner.ts` (SF-079).

`accountStatus` is in the users self-write deny-list (`rules:62-86`) so a
self-promotion via direct SDK is impossible — the read is trustworthy.

## 4. Threading shape

```rules
allow update: if (
    (isResourceOwner() && isActiveOwner())
    || isAdmin() || isAdminFromFirestore()
  )
  && !request.resource.data.diff(resource.data).affectedKeys()
      .hasAny([...existing CF-only deny-list...]);
```

- Gate prepended (AND with existing ownership predicate).
- Admin bypass via OR clause — same admin claim shape used elsewhere in this file.
- Existing CF-only field deny-list (`affectedKeys()`) preserved verbatim, applies
  to admin too (those fields are CF-managed; nobody on the client side writes them).

## 5. Rule-cost note

`isActiveOwner()` cost = 1 `exists` + 1 `get` per call. `isAdminFromFirestore()` =
1 `get`. On a gated write the worst-case path with no admin claim hits 3 user-doc
operations (the `exists` short-circuits into `get`, but counts separately). Within
the 10-get rules budget; not free. Hot gated paths (daily_prices bulk-write,
booking edit storms) may see modest latency lift versus pre-PR.

If profile shows this is hot, the standard mitigation is to fold `accountStatus`
into a custom claim — that closes the 1 `exists` + 1 `get` path to zero. Deferred;
SF-078/SF-079 also live with the Firestore read pattern.

## 6. Test suite

`functions/test/firestore_rules/trial_gate.test.ts` — **34 NEW tests** across
5 describe blocks:

| Block | Tests | Coverage |
|---|---|---|
| /properties/{p}.create gated | 9 | active/trial/expired/suspended/premium/missing-field/missing-doc/admin-claim/admin-firestore |
| /properties/{p}.update gated | 5 | active/trial/expired/suspended/missing-doc |
| Owner bookings subcoll gated | 6 | active-create, expired-create, active-update, expired-update, active-delete, admin-bypass |
| pricing_calendar gated | 7 | active/trial-set, expired-set, suspended-update, expired-delete, admin-bypass, public-read |
| widget_settings gated | 6 | active-create, expired-create, active-update, suspended-update, admin-bypass, ical_cache deny-list preserved |
| Frozen happy-path guard | 1 | active owner: unit + widget_settings + daily_price triple-write |

**Existing 107 tests** preserved via seeding `accountStatus: 'active'` on the
3 affected test files:

| File | Seed change |
|---|---|
| `bookings.test.ts` | 4 user docs += `accountStatus: 'active'` |
| `properties_direct_write.test.ts` | + 2 user docs (OWNER, FOREIGN) with `accountStatus: 'active'` |

Files NOT touched (paths not gated):
- `ical_events.test.ts` (ical_events rules use `isPropertyOwner`, not the gate)
- `global_collections.test.ts` (no gated path coverage)
- `deprecated_collections.test.ts` (top-level deprecated paths not gated)
- `users.test.ts`, `devices.test.ts`, `devices_class_sweep.test.ts`

### Test result

`npm run test:rules` →
- **Test Suites: 9 passed, 9 total**
- **Tests: 141 passed, 6 skipped (pre-existing), 0 failed**
- Original 107 + 34 new = 141. **Zero regression.**

## 7. Deploy

```
firebase deploy --only firestore:rules --project bookbed-dev
✔ rules file firestore.rules compiled successfully
✔ released rules firestore.rules to cloud.firestore
✔ Deploy complete
```

**Target:** `bookbed-dev` only. PROD operator-gated; not in scope for this PR.

## 8. DEV smoke

Seeded 3 owners (`sf080-active-…`, `sf080-expired-…`, `sf080-suspended-…`) via
Admin SDK, each with property + unit + widget_settings, then signed in as each
via Auth REST `signInWithPassword` and probed all 4 gated paths via Firestore
REST PATCH.

Result matrix:

| Owner status | property.update | widget_settings.update | daily_prices.set | bookings.create |
|---|---|---|---|---|
| **active** | OK ✅ | OK ✅ | OK ✅ | OK ✅ |
| **trial_expired** | DENIED ✅ | DENIED ✅ | DENIED ✅ | DENIED ✅ |
| **suspended** | DENIED ✅ | DENIED ✅ | DENIED ✅ | DENIED ✅ |

**12/12 cells correct.** Active owner happy-path intact (frozen flows continue
to work). Trial-expired + suspended writes blocked at the rules layer.

Cleanup ran successfully (3 owners + properties + subcollections all deleted).

## 9. Frozen happy-path confirmation

Active owner can still execute the Unit Wizard publish flow's writes:

1. `/properties/{p}/units/{u}` — NOT gated by SF-080 → always allowed for owner.
2. `/properties/{p}/widget_settings/{u}` — gated; active passes ✅.
3. `/properties/{p}/units/{u}/daily_prices/{d}` — gated; active passes ✅.

Verified via the dedicated `trial_gate.test.ts` "Frozen happy-path regression
guard" describe block + via DEV smoke (`active` row in matrix above).

`CLAUDE.md` NIKADA NE MIJENJAJ Dart files **untouched**:
`firebase_booking_calendar_repository.dart`, `unified_unit_hub_screen.dart`,
`booking_widget_screen.dart`, Timeline fixed dims, `atomicBooking.ts` owner
flow, etc.

## 10. Diff scope

```
firestore.rules                                              (gate + threading)
functions/test/firestore_rules/trial_gate.test.ts            (new, 34 tests)
functions/test/firestore_rules/bookings.test.ts              (seed accountStatus)
functions/test/firestore_rules/properties_direct_write.test.ts (seed accountStatus)
audit/113-l1-rules-trial-gate.md                             (this file)
docs/SECURITY_FIXES.md                                       (SF-080 entry)
scratch/smoke-sf080-rules.js                                 (one-shot, kept for re-runs)
```

**Zero Dart / Cloud Functions / Storage Rules / frozen-file changes.**

## 11. Open follow-ups

- **PROD deploy** — operator-gated per-session. Order: ensure
  `accountStatus` coverage on PROD users (PR #667 backfill ran 2026-06-03 →
  3 premium normalised, 3 MANUAL_TRIAGE remain), then
  `firebase deploy --only firestore:rules --project rab-booking-248fc`.
- **PROD pre-deploy verification** — count `/users/*` PROD docs missing
  `accountStatus` field; any non-zero needs operator triage before rules go live
  (otherwise legitimate active PROD owners would be denied for a missing seed
  field).
- **Custom-claim migration** — fold `accountStatus` into the auth custom claim
  to drop the per-write `users` doc lookup. Deferred (SF-078/SF-079 already
  live with the Firestore read pattern).
- **PRs #666 (SF-078) and #668 (SF-079) merge** — these PRs are siblings; no
  expected merge conflict with this rules-only PR (different files).
