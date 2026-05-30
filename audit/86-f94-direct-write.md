# audit/86 — F-94 direct-write hardening (SF-068)

**Scope:** `firestore.rules` only (CF source touched only for grep/reference).
Closes F-94-02-UPDATE / F-94-03 / F-94-04 + wider direct-write sweep across
authenticated-owner collections.

**Date:** 2026-05-30
**Branch:** `fix/f94-direct-write-0530`
**Deploy:** bookbed-dev only (`firebase deploy --only firestore:rules`).
**PROD:** NOT deployed (operator gate). PROD cutover deferred.

---

## 1. Summary

| ID | Class | State | Vector | Closure |
|----|-------|-------|--------|---------|
| F-94-02-UPDATE | Direct-write subdomain squat (UPDATE) | ✅ CLOSED | Owner direct `update({subdomain:'x'})` bypasses `setPropertySubdomain` CF — squats any subdomain | rule: `affectedKeys().hasAny(['subdomain'])` denied on `properties.update` |
| F-94-02-CREATE | Direct-write subdomain squat (CREATE) | 🟡 PARTIAL | Owner `createProperty` writes subdomain inline (`firebase_owner_properties_repository.dart:195`) — bypasses CF entirely | rule: format-validate at create (3-30 chars, `^[a-z0-9][a-z0-9-]{1,28}[a-z0-9]$`); **format-valid squat still OPEN** — needs lib refactor (see §7) |
| F-94-03 | ical_feeds stats injection | ✅ CLOSED | Owner direct write of `sync_count` / `event_count` / `last_synced` — fakes dashboard activity or freezes scheduled sync via future `last_synced` | rule: `affectedKeys().hasAny(['sync_count','event_count','last_synced'])` denied |
| F-94-04 | widget_settings ical_cache_* injection | ✅ CLOSED | Owner direct write of `ical_cache_content` / `ical_cache_generated_at` / `ical_cache_etag` / `ical_cache_unit_name` — serves arbitrary content to Booking.com / Airbnb via cached export, or freezes cache regen | rule: deny those 4 keys on `widget_settings.update` (subcollection + CG paths) |
| owner_id immutability | Ownership-transfer block | ✅ CLOSED | Owner could write `owner_id` to any UID on update → hand property to attacker | denied on `properties.update` |
| created_at immutability | Audit-trail integrity | ✅ CLOSED | Owner could backdate `created_at` | denied on `properties.update` |

**Tests:** emulator 77/77 PASS; live bookbed-dev probe 16/16 PASS.

---

## 2. F-94-02 subdomain squat

### 2.1 Pre-fix attack surfaces

`functions/src/subdomainService.ts` exposes 3 callables:
- `checkSubdomainAvailability` — advisory, only checks
- `generateSubdomainFromName` — UX helper
- `setPropertySubdomain` — authoritative writer (format, reserved-list, uniqueness validation)

But the **CF is bypassable** via Firestore SDK direct-write because the
properties update rule was unbounded:

```diff
- allow update, delete: if isResourceOwner();
```

The lib client takes two distinct write paths:

| Mode | File:Line | Path |
|------|-----------|------|
| CREATE | `firebase_owner_properties_repository.dart:191-211` | Direct `collection('properties').add({…, subdomain: …})` — never calls `setPropertySubdomain` |
| UPDATE | `property_form_screen.dart:1148-1173` | Calls `setPropertySubdomain` CF *first*, then `updateProperty(subdomain: null)` to skip in batch — **but Firestore SDK is still reachable** for a malicious owner via `doc().update({subdomain:'x'})` |

Both paths let an authenticated owner squat any subdomain (including
competitor / brand names not yet claimed).

### 2.2 Closure

**UPDATE path — fully closed** by adding to `properties.update` rule:

```javascript
allow update: if isResourceOwner()
  && !request.resource.data.diff(resource.data).affectedKeys()
      .hasAny(['subdomain', 'owner_id', 'created_at']);
```

`owner_id` + `created_at` immutability are bundled (they were never
deliberately allowed; the rule was just too permissive).

**CREATE path — partial format guard** (advisor-recommended mitigation
without lib edits):

```javascript
allow create: if canCreateAsOwner()
  && (request.resource.data.get('subdomain', null) == null
      || (request.resource.data.subdomain is string
          && request.resource.data.subdomain.size() >= 3
          && request.resource.data.subdomain.size() <= 30
          && request.resource.data.subdomain.matches('^[a-z0-9][a-z0-9-]{1,28}[a-z0-9]$')));
```

Reserved-name list NOT replicated in rules (drift risk vs CF source of truth).

The `.get('subdomain', null)` pattern is load-bearing — Firestore Rules
errors on undefined property access in compound expressions; `.get()` is the
safe-default accessor. Confirmed by a failing test against
`request.resource.data.subdomain == null` (works for present-null, errors
for absent key) before refactoring.

### 2.3 Still OPEN: F-94-02-CREATE squat

A format-valid subdomain ('marriott', 'airbnb', 'lufthansa') passes the
regex. Owner can still squat at create. **Closing this requires a lib
refactor**:

```diff
// firebase_owner_properties_repository.dart createProperty()
- final docRef = await _firestore.collection('properties').add({
-   …,
-   'subdomain': subdomain,
-   …,
- });
+ final docRef = await _firestore.collection('properties').add({
+   …,
+   // 'subdomain' deliberately omitted — call setPropertySubdomain post-create
+   …,
+ });
+ if (subdomain != null && subdomain.isNotEmpty) {
+   final callable = FirebaseFunctions.instance.httpsCallable('setPropertySubdomain');
+   await callable.call({'propertyId': docRef.id, 'subdomain': subdomain});
+ }
```

Lib touch out of scope for this PR (orchestration constraint). Filed as
F-94-02-CREATE follow-up. Once lib lands, the rules `allow create` can be
tightened further to **require** subdomain == null (CF-only).

---

## 3. F-94-03 ical_feeds stats injection

### 3.1 CF-managed fields

`functions/src/icalSync.ts:535-542` (scheduled sync success path):

```typescript
await feedRef.update({
  last_synced: admin.firestore.Timestamp.now(),
  sync_count: admin.firestore.FieldValue.increment(1),
  event_count: result.insertedCount,
  status: "active",
  last_error: null,
  updated_at: admin.firestore.Timestamp.now(),
});
```

Plus error path at `:569-573`. `status` + `last_error` are deliberately
left client-writable too — owners pause/resume feeds via the dashboard
(see `IcalStatus.paused` enum at `lib/.../ical_feed.dart:96-107`).

### 3.2 Attack vectors

- **Stats inflation**: owner UI shows "Synced N times", "M events imported". Owner can fabricate.
- **Scheduler freeze**: scheduled job at `icalSync.ts:296-311` gates on `last_synced + sync_interval_minutes >= now`. Owner writing `last_synced: 2099-01-01` silently halts scheduled sync for that feed indefinitely.

### 3.3 Closure

```javascript
match /ical_feeds/{feedId} {
  allow read: if isPropertyOwner(propertyId);
  allow create: if isPropertyOwner(propertyId);
  allow update: if isPropertyOwner(propertyId)
    && !request.resource.data.diff(resource.data).affectedKeys()
        .hasAny(['sync_count', 'event_count', 'last_synced']);
  allow delete: if isPropertyOwner(propertyId);
}
```

`status` deliberately not in the deny list — owners legitimately set
`status: 'paused'` from the dashboard. The CF rewrites it back to
`'active'` on next successful sync. Client model round-trip
(`fromFirestore → copyWith → toFirestore`) preserves stored values for
denied fields, so `affectedKeys()` reports zero delta on benign owner saves.

CG `ical_feeds` rule unchanged — already write-locked
(`allow read … allow write: false` via the subcollection-only write path).

---

## 4. F-94-04 widget_settings ical_cache_* injection

### 4.1 CF-managed fields

`functions/src/icalExport.ts:328-332` (cache write):

```typescript
await widgetSettingsRef.update({
  ical_cache_content: icalContent,
  ical_cache_generated_at: Timestamp.now(),
  ical_cache_etag: etag,
});
```

`functions/src/utils/icalCache.ts:17-25` (invalidation via
`FieldValue.delete()` on booking lifecycle events).

`icalExport.ts:179-181` then **reads** these on subsequent feed requests
to serve cached content with `If-None-Match: <etag>`.

### 4.2 Attack vectors

- **Feed-injection**: owner writes `ical_cache_content: "BEGIN:VCALENDAR\nSUMMARY:scam-promo\nEND:VCALENDAR"`. Next request to `getUnitIcalFeed` serves the owner-crafted payload to Booking.com / Airbnb / personal subscribers — **including any text content** (phishing, spam, scam URLs in VEVENT description).
- **Cache freeze**: owner writes `ical_cache_generated_at: 2099-01-01`. CF cache-validity check fails → CF never regenerates → stale (potentially malicious) content served indefinitely.
- **ETag clobber**: owner writes a known-good ETag for a poisoned content → conditional requests `If-None-Match` short-circuit to 304 Not Modified.

### 4.3 Closure

Subcollection path (`properties/{pid}/widget_settings/{uid}`):

```javascript
allow update: if isPropertyOwner(propertyId)
  && !request.resource.data.diff(resource.data).affectedKeys()
      .hasAny([
        'ical_cache_content', 'ical_cache_generated_at',
        'ical_cache_etag', 'ical_cache_unit_name'
      ]);
```

CG path (`{path=**}/widget_settings/{uid}`) mirrored — some owner repos
write via CG lookup.

Confirmed safe-for-clients: `lib/features/widget/domain/models/widget_settings.dart`
`toMap()` / `toFirestore()` does NOT include `ical_cache_*` (grep clean
2026-05-30); benign owner save round-trips through models that exclude
these keys → `affectedKeys()` reports zero delta.

---

## 5. Wider direct-write sweep — kolekcija × actor × verdict

Audited every rule in `firestore.rules` for unbounded `update` / `create`
where authenticated owner can write server-managed fields. Verdicts:

| Collection / path | Rule | Owner-writable fields | Verdict |
|---|---|---|---|
| `users/{uid}` | `affectedKeys().hasAny([role, isAdmin, accountStatus, trial*, Stripe linkage, ...])` | name, preferences only | **INTENTIONAL** — closed audit/38 H-01 + audit/57 H-01 + audit/78 |
| `users/{uid}/data/{doc}` | Same deny-list as parent | mirror of parent | **INTENTIONAL** — closed F-NEW-08 |
| `users/{uid}/ai_chats/{chatId}` | `read, write: if isOwner` (unbounded) | All — pure owner data, no server-managed shape | **INTENTIONAL** — no CF writes to this path |
| `users/{uid}/notifications/{nid}` | `update affectedKeys().hasOnly(['isRead'])` | isRead only | **INTENTIONAL** — tight allowlist |
| `users/{uid}/rate_limits/{action}` | `read, write: if false` | none | **INTENTIONAL** — CF-only |
| `users/{uid}/securityEvents/{eid}` | `create hasOnly([type, timestamp, deviceId, ipAddress, location, metadata])` | tight shape | **INTENTIONAL** — closed F-NEW-09 |
| `users/{uid}/devices/{did}` | `read, write: if isOwner` (unbounded for owner) | All | **GAP** — `lastSeenAt` / `verified` / `model` may want narrowing, but **PR #567 SF-062 already in flight** for this path. **NOT TOUCHED** per orchestration scope. |
| `user_profiles/{uid}` (legacy) | Same deny-list as `users` | safe | **INTENTIONAL** — closed F-NEW-08 |
| **`properties/{pid}`** | (pre-fix) `update, delete: if isResourceOwner()` (unbounded!) | All — including `subdomain`, `owner_id`, `created_at` | **GAP → CLOSED THIS PR** (F-94-02-UPDATE + immutability) |
| `properties/{pid}/units/{uid}` | `create, update, delete: if isPropertyOwner` (unbounded) | All | **INTENTIONAL** — no CF writes (other than full doc replace via wizard CF). No server-managed atomic fields. |
| `…/units/{uid}/bookings/{bid}` | `update !affectedKeys().hasAny([status, approved_at, ...])` | non-status fields | **INTENTIONAL** — closed audit/78 Phase B |
| `…/units/{uid}/daily_prices/{date}` | `create, update, delete: if isPropertyOwner` (unbounded) | All | **INTENTIONAL** — CF only reads, never writes (`atomicBooking.ts` / `availability.ts` / `icalExport.ts` are read-only) |
| `…/units/{uid}/additional_services/{sid}` | `create, update, delete: if isPropertyOwner` (unbounded) | All | **INTENTIONAL** — no CF writers |
| **`…/widget_settings/{uid}`** | (pre-fix) `create, update, delete: if isPropertyOwner` (unbounded!) | All — including `ical_cache_*` | **GAP → CLOSED THIS PR** (F-94-04) |
| `…/widget_secrets/{uid}` | `read, create, update, delete: if isPropertyOwner` (unbounded) | All | **INTENTIONAL** — token is owner-set, CF only reads via Admin SDK. No CF writes (verified grep `widget_secrets` in `functions/src/` returns only reads). |
| `…/ical_events/{eid}` | `read: if isPropertyOwner; write: if false` | none | **INTENTIONAL** — SF-023 locked |
| **`…/ical_feeds/{fid}`** | (pre-fix) `create, update, delete: if isPropertyOwner` (unbounded!) | All — including `sync_count`, `event_count`, `last_synced` | **GAP → CLOSED THIS PR** (F-94-03) |
| `platform_connections/{cid}` | `read, create, update, delete: if isResourceOwner` (unbounded) | None — collection ORPHAN | **DEAD CODE** — `grep platform_connections functions/src/ lib/` returns ZERO hits. Recommend rule + collection removal in a separate cleanup PR (mirror `booking_services` removal from SF-023 follow-up). |
| CG `units` | scoped via `property_id` lookup | mirror of subcoll | **INTENTIONAL** |
| CG `widget_settings` | scoped via `property_id` lookup | (pre-fix) unbounded for cache fields | **CLOSED THIS PR** — mirrored F-94-04 deny |
| CG `bookings` | read scoped to owner_id; writes go through subcollection | safe | **INTENTIONAL** |
| CG `daily_prices` | `read: if true; write: false` | none | **INTENTIONAL** |
| CG `ical_events` | scoped via `property_id`; `write: false` | none | **INTENTIONAL** |
| CG `ical_feeds` | scoped via `property_id`; `write: false` | none | **INTENTIONAL** |
| `/units/{uid}` (deprecated top-level) | `create: false; update, delete: if isResourceOwner` | legacy migration cleanup | **INTENTIONAL** — F-NEW-07 lock |
| `/bookings/{bid}` (deprecated top-level) | `create: false; update, delete: if isResourceOwner` | legacy | **INTENTIONAL** — F-NEW-07 |
| `/daily_prices/{pid}` (deprecated top-level) | `create: false; update, delete: if isResourceOwner` | legacy | **INTENTIONAL** — F-NEW-07 |
| `/ical_feeds/{fid}` (deprecated top-level) | `create: false; update, delete: if isResourceOwner` | legacy | **INTENTIONAL** — SF-023 era lock |
| `loginAttempts/{email}` | `read, write: if false` | none | **INTENTIONAL** — SF-050 closed |
| `email_verifications/*` | `read, write: if false` | none | **INTENTIONAL** |
| `stripe_webhook_events/*` | `read, write: if false` | none | **INTENTIONAL** — SF-038 |
| `email_templates/*` | `read, write: if false` | none | **INTENTIONAL** |
| `tenants/*` | `read, write: if false` | none | **INTENTIONAL** |
| `app_config/{platform}` | `read if platform in ['android','ios','web']; write: false` | none | **INTENTIONAL** — M-05 |
| `security_events/*` (root) | `create hasOnly([userId, type, ...]) && userId == auth.uid` | tight shape | **INTENTIONAL** — closed M-04 |
| `oauth_states/*` | `read, write: if false` | none | **INTENTIONAL** |
| `sync_failures/*` | `read, write: if false` | none | **INTENTIONAL** |

Net gaps surfaced this sweep: **3 closed in PR** (F-94-02-UPDATE, F-94-03,
F-94-04 + bonus `owner_id` / `created_at` immutability). **1 partial**
(F-94-02-CREATE). **1 deferred** (`devices` — PR #567). **1 dead-code
recommendation** (`platform_connections` orphan).

---

## 6. Verification

### 6.1 Emulator — `firestore:rules` jest suite

```
Test Suites: 5 passed, 5 total
Tests:       77 passed, 77 total
Snapshots:   0 total
```

New `properties_direct_write.test.ts` file contributes **31 tests** across
3 describe blocks:

- `properties.create — F-94-02 format guard`: 9 tests (subdomain null,
  absent, valid, too-short, too-long, leading-hyphen, special-char,
  uppercase, mismatched owner_id)
- `properties.update — F-94-02-UPDATE`: 6 tests (subdomain, owner_id,
  created_at denied; benign name/description allowed; atomic mix denied;
  foreign uid denied)
- `ical_feeds.update — F-94-03`: 8 tests (sync_count, event_count,
  last_synced denied; benign ical_url + import_enabled + status=paused
  allowed; atomic mix denied; foreign uid denied)
- `widget_settings.update — F-94-04`: 8 tests (4 cache_* denied; benign
  widget_mode + ical_export_enabled allowed; atomic mix denied; foreign
  uid denied)

Existing 46 tests across `bookings.test.ts`, `users.test.ts`,
`ical_events.test.ts`, `global_collections.test.ts` regression-clean.

### 6.2 Live probe — bookbed-dev

Script: `audit/smoke/audit86-direct-write-smoke.js`

Auth path: Firebase Auth REST `signInWithEmailAndPassword` for owner
(`bookbed-test@bookbed.io` test account UID `GILVItIVP5R8WXfnMmyMo1ykhUm2`),
`createUserWithEmailAndPassword` for throwaway foreign UID. Seed via
firebase-admin Firestore (ADC), write probes via firebase JS SDK against
deployed rules.

Run env:

```
GOOGLE_CLOUD_PROJECT=bookbed-dev \
BOOKBED_DEV_WEB_API_KEY=… \
BOOKBED_DEV_OWNER_PASS='BookBedTest2026!' \
node audit86-direct-write-smoke.js
```

Result: **16 pass / 0 fail / 16 total** (post-deploy):

| Cell | Expected | Got |
|---|---|---|
| F-94-02 owner DIRECT subdomain | deny | ✅ deny |
| F-94-02 owner DIRECT owner_id | deny | ✅ deny |
| F-94-02 owner DIRECT created_at | deny | ✅ deny |
| F-94-02 owner benign name update | allow | ✅ allow |
| F-94-02 foreign uid name update | deny | ✅ deny |
| F-94-03 owner DIRECT sync_count=99999 | deny | ✅ deny |
| F-94-03 owner DIRECT event_count=99999 | deny | ✅ deny |
| F-94-03 owner DIRECT last_synced=2099 | deny | ✅ deny |
| F-94-03 owner benign ical_url update | allow | ✅ allow |
| F-94-03 owner legit pause via status | allow | ✅ allow |
| F-94-03 foreign uid feed write | deny | ✅ deny |
| F-94-04 owner DIRECT ical_cache_content=PWN | deny | ✅ deny |
| F-94-04 owner DIRECT ical_cache_generated_at=2099 | deny | ✅ deny |
| F-94-04 owner benign widget_mode toggle | allow | ✅ allow |
| F-94-04 owner ical_export_enabled toggle | allow | ✅ allow |
| F-94-04 foreign uid widget_settings write | deny | ✅ deny |

Throwaway property + foreign auth user torn down at end of run.

---

## 7. Open follow-ups

### F-94-02-CREATE subdomain squat — lib refactor required

Format-valid subdomain squat still possible because lib
`createProperty` writes the field directly via Firestore SDK before any
CF call. Closure recipe — apply in next PR (lib touch, out of scope
here):

1. **`lib/features/owner_dashboard/data/firebase/firebase_owner_properties_repository.dart`** — drop `'subdomain': subdomain` from the `createProperty` payload at line 195 (keep the parameter for the post-create CF call).
2. **`lib/features/owner_dashboard/presentation/screens/property_form_screen.dart`** — at line 1201 (the `else` branch for create-mode), wrap `repository.createProperty(…)` to await the returned property id, then call:
   ```dart
   if (subdomainValue != null && subdomainValue.isNotEmpty) {
     final callable = FirebaseFunctions.instance.httpsCallable('setPropertySubdomain');
     await callable.call({'propertyId': newPropertyId, 'subdomain': subdomainValue});
   }
   ```
3. **`firestore.rules`** — after lib lands, tighten `properties.create` further:
   ```javascript
   allow create: if canCreateAsOwner()
     && request.resource.data.get('subdomain', null) == null;
   ```
   (Drop the format-validate branch entirely — CF-only is the strict
   posture.)

### `platform_connections` orphan removal

`grep -r platform_connections functions/src/ lib/` returns ZERO. The rule
+ underlying collection appear to be dead code. Recommend
removal-cleanup PR analogous to the `booking_services` empty-collection
removal in SF-023 follow-up.

### PROD deploy gate

PR ships rules to bookbed-dev only. **PROD cutover deferred** to the
operator (per orchestration constraint: HARD `nikad PROD`). Pre-PROD
checklist:
1. Verify no production property doc has owner code attempting direct
   `subdomain` rewrites that don't route via CF (otherwise legit save
   will fail post-deploy).
2. Re-run `audit/smoke/audit86-direct-write-smoke.js` against PROD with
   an Operator-controlled test account.
3. Deploy `firebase deploy --only firestore:rules --project rab-booking-248fc`.
4. Spot-check PROD owner dashboard: edit a property name → save → verify
   succeeds. Edit subdomain via the form → verify still hits
   `setPropertySubdomain` callable + writes through.

---

## 8. Refs

- Memory: `[[ical-export-empty-token-bypass]]` (F-92-01) — related iCal export hardening
- Memory: `[[storage-rules-firestore-get-iam]]` (F-91-02) — companion direct-write sweep on storage
- Memory: `[[sf-062-pr567-naming-conflict]]` — devices path deferred to that PR
- `firestore.rules` HEAD pre-PR: `ed31ae47`
- `firestore.rules` HEAD post-PR: this branch
- Test file: `functions/test/firestore_rules/properties_direct_write.test.ts`
- Live smoke: `audit/smoke/audit86-direct-write-smoke.js`

## 9. Caveats / partial closures

- **F-94-02-CREATE OPEN** — format-valid squat possible. Closure needs
  lib refactor (see §7).
- `platform_connections` rule kept (cleanup deferred to dedicated PR).
- `users/{uid}/devices/{did}` left unbounded for owner — **PR #567 SF-062**
  handles that path and was explicitly excluded from this scope.
- PROD not deployed.
