# audit/91 — Data-layer smoke on bookbed-dev

**Date:** 2026-05-30
**Scope:** bookbed-dev only — Firestore rules + Storage rules + indexes
**Tooling:** Firestore + Storage REST APIs via gcloud token, Identity Toolkit signInWithPassword, `firebase emulators:exec`
**Test account:** `bookbed-test@bookbed.io` (UID `GILVItIVP5R8WXfnMmyMo1ykhUm2`)
**Worktree:** `/tmp/bb-data-wt` off `main@ed31ae47` (audit/85 tip)
**HARD:** PROD untouched. Read-only describe + emulator + dev-only writes.

---

## §1 — Emulator rules suite

```
cd functions && npm run test:rules
→ Test Suites: 4 passed, 4 total
  Tests:       46 passed, 46 total
  Time:        6.6 s
```

- Suite files: `users.test.ts`, `ical_events.test.ts`, `bookings.test.ts`, `global_collections.test.ts`
- 4 grpc PERMISSION_DENIED warns are expected — deny-path assertions firing.
- **Count drift:** task brief expected 53/53; live count is 46. `git log main..origin/docs/audit-90-prod-cutover-runbook -- functions/test/firestore_rules/` returned empty — no in-flight rules-test additions. 46 is the current baseline.

Verdict: ✅ GREEN.

---

## §2 — Live ruleset parity

REST `firebaserules.googleapis.com/v1/projects/bookbed-dev/releases/...` →

| Surface  | Ruleset id                              | Updated (UTC)             | Source bytes | vs worktree |
|----------|------------------------------------------|---------------------------|--------------|-------------|
| Firestore| `3399f072-09bd-4dbc-85a3-482d8d7dfad7` | 2026-05-29T12:47:20.932Z  | 26176        | ✅ identical |
| Storage  | `4a0bf249-bdac-4c8b-8116-f564c4019e54` | 2026-05-27T13:13:56.102Z  | 3305         | ✅ identical |

Firestore ruleset matches audit/89 SF-062 deploy timestamp. Storage matches PR #558 / audit/79.

Verdict: ✅ no drift between deployed ruleset and `main` worktree.

---

## §3 — Live Firestore probe matrix

37 unique probes — anon + foreign-uid + auth + self. All `403` results carry `PERMISSION_DENIED` body. ✅ = expected; ❌ = mismatch.

### §3.1 — anon (no Bearer, API key only)

| #   | Collection / path                                          | Op    | Expect | Got | Verdict | Rule basis             |
|-----|------------------------------------------------------------|-------|--------|-----|---------|------------------------|
| P1  | CG `bookings` filter `unit_id+status=='confirmed'`          | query | 403    | 403 | ✅      | T11c CG anon deny      |
| P2  | CG `bookings` filter `owner_id=='X'`                       | query | 403    | 403 | ✅      | T11c CG anon deny      |
| GAP-1| CG `bookings` filter `booking_reference=='BB-FAKE-123'`   | query | 403    | 403 | ✅      | T11c CG anon deny      |
| GAP-2| CG `bookings` filter `stripe_session_id=='cs_test_fake'`  | query | 403    | 403 | ✅      | T11c CG anon deny      |
| P3  | CG `ical_events`                                            | query | 403    | 403 | ✅      | SF-023 lockdown        |
| P4  | `properties/X/widget_settings/Y` get                        | GET   | 200/404| 404 | ✅      | public read allow      |
| P5  | `properties/X/widget_secrets/Y` get                         | GET   | 403    | 403 | ✅      | SF-021 owner-only      |
| P6  | `properties/X/ical_events/Y` get                            | GET   | 403    | 403 | ✅      | SF-023 nested deny     |
| P7  | `loginAttempts/{email}` get                                 | GET   | 403    | 403 | ✅      | SF-050 server-only     |
| P8  | `stripe_webhook_events/{id}` get                            | GET   | 403    | 403 | ✅      | SF-038 server-only     |
| P9  | `app_config/web` get                                        | GET   | 403    | 403 | ✅      | requires auth          |
| P10 | `users/{uid}` get                                           | GET   | 403    | 403 | ✅      | self-or-admin only     |
| P32 | `bookings/{id}` PATCH `status`                              | PATCH | 401/403| 403 | ✅      | top-level write deny   |
| P33 | `tenants` list                                              | GET   | 401/403| 403 | ✅      | locked                 |
| P34 | `email_templates` list                                      | GET   | 401/403| 403 | ✅      | locked                 |

### §3.2 — authenticated (test account)

| #   | Collection / path                                                  | Op    | Expect | Got | Verdict | Rule basis                                                 |
|-----|--------------------------------------------------------------------|-------|--------|-----|---------|------------------------------------------------------------|
| P11 | `users/{self}?updateMask=isAdmin` → `true`                          | PATCH | 403    | 403 | ✅      | SF-028 H-01 protected field                                 |
| P12 | `users/{self}?updateMask=role` → `'admin'`                          | PATCH | 403    | 403 | ✅      | SF-028 H-01 protected field                                 |
| P13 | `users/{self}?updateMask=accountStatus` → `'lifetime'`              | PATCH | 403    | 403 | ✅      | SF-028 H-01 protected field                                 |
| P14 | `loginAttempts/{email}` get                                          | GET   | 403    | 403 | ✅      | SF-050 server-only even for auth                            |
| P15 | `stripe_webhook_events/{id}` get                                     | GET   | 403    | 403 | ✅      | SF-038 server-only                                          |
| P16 | `oauth_states/{state}` get                                           | GET   | 403    | 403 | ✅      | server-only                                                 |
| P17 | `sync_failures/{id}` get                                             | GET   | 403    | 403 | ✅      | server-only                                                 |
| P18 | `app_config/web` get                                                 | GET   | 200/404| 404 | ✅      | auth allow path                                             |
| P19 | `app_config/internal_keys` get                                       | GET   | 403    | 403 | ✅      | M-05 platform allowlist                                     |
| P20 | `security_events` POST with `userId='FOREIGN'`                       | POST  | 403    | 403 | ✅      | M-04 userId binds to auth.uid                               |
| P21 | `security_events` POST with `EXTRA_FIELD`                            | POST  | 403    | 403 | ✅      | `hasOnly` shape enforcement                                 |
| P22 | `users/{uid}/securityEvents` POST with `EXTRA_FIELD`                 | POST  | 403    | 403 | ✅      | subcol `hasOnly` shape                                      |
| P23 | `properties/foreign/widget_secrets/X` get                            | GET   | 403    | 403 | ✅      | SF-021 isPropertyOwner                                      |
| P24 | `properties/foreign/ical_events/X` get                               | GET   | 403    | 403 | ✅      | SF-023 isPropertyOwner                                      |
| P25 | CG `bookings` filter `owner_id='FOREIGN'`                            | query | 403/200| 403 | ✅      | auth own-only                                               |
| P26 | `email_verifications/{hash}` get                                     | GET   | 403    | 403 | ✅      | server-only                                                 |
| P27 | `email_templates/{id}` get                                           | GET   | 403    | 403 | ✅      | locked                                                      |
| P28 | `tenants/{id}` get                                                   | GET   | 403    | 403 | ✅      | locked                                                      |
| P29 | `users/{uid}/rate_limits/{action}` get                               | GET   | 403    | 403 | ✅      | server-only                                                 |
| P30 | `properties/foreign/widget_secrets/X?updateMask=resend_api_key` PATCH| PATCH | 403    | 403 | ✅      | SF-021 owner-write only                                     |
| P31 | `properties/foreign/widget_settings/X?updateMask=resend_api_key` PATCH| PATCH| 403    | 403 | ✅      | isPropertyOwner branch denies (NOTE see §6 F-91-03)         |
| P35 | `platform_connections/{id}` get                                      | GET   | 403    | 403 | ✅      | isResourceOwner                                             |
| P36 | `users/{OTHER}` get                                                  | GET   | 403    | 403 | ✅      | self-or-admin only                                          |
| P37 | `users/{self}?updateMask=email_notifications_consent` → `true`       | PATCH | 200/404| 200 | ✅      | non-protected field allow path                              |

### §3.3 — total

**37 / 37 PASS** across 24 collection × actor × op combinations.

---

## §4 — Live Storage probe matrix

Bucket: `bookbed-dev.firebasestorage.app`. 13 probes + 3 delete-class probes.

| #   | Path                                            | Op     | Auth | Expect          | Got | Verdict | Rule basis                                  |
|-----|-------------------------------------------------|--------|------|-----------------|-----|---------|---------------------------------------------|
| S1  | `ical-exports/synth/synth/calendar.ics`         | GET    | anon | 401/403/404     | 403 | ✅      | SF-025 lockdown                             |
| S2  | `users/synth-uid/profile.jpg`                   | GET    | anon | 401/403/404     | 403 | ✅      | owner-only read                             |
| S3  | `properties/synth/photo.jpg`                    | GET    | anon | 200/404         | 404 | ✅      | properties public read — NOT 403            |
| S4  | `random/path/file.txt`                          | GET    | anon | 401/403/404     | 403 | ✅      | default deny catch-all                      |
| S5  | `public/logo.png`                               | GET    | anon | 200/404         | 404 | ✅      | public read allow                           |
| S6  | `ical-exports/synth-foreign/U/probe.ics`        | POST   | auth | 403             | 403 | ✅      | isPropertyOwner                             |
| S7  | `users/{self}/probe.svg` `image/svg+xml`        | POST   | auth | 403             | 403 | ✅      | L-04 SVG not in image/(jpeg\|png\|webp\|gif\|heic\|heif) |
| S8  | `users/{self}/probe.bin` `application/octet-stream` | POST | auth | 403             | 403 | ✅      | contentType allowlist                       |
| S9  | `users/FOREIGN/probe.jpg`                       | POST   | auth | 403             | 403 | ✅      | users IDOR                                  |
| S10 | `properties/FOREIGN/probe.jpg`                  | POST   | auth | 403             | 403 | ✅      | SEC-001 properties IDOR                     |
| S11 | `public/probe.png`                              | POST   | auth | 403             | 403 | ✅      | public write `if false`                     |
| S12 | `ical-exports/foreign/U/calendar.ics`           | GET    | auth | 401/403/404     | 403 | ✅      | isPropertyOwner read                        |
| S13 | `users/{self}/probe-legit.jpg` `image/jpeg`     | POST   | auth | 200             | 200 | ✅      | ALLOW path (cleaned up via Admin)           |
| F-91-02a | `users/{self}/del-probe.jpg`               | DELETE | auth | 200/204/403     | 403 | ❗      | see §6 F-91-02                              |
| F-91-02b | `properties/foreign/probe.jpg`             | DELETE | auth | 200/204/403/404 | 403 | ✅†     | denied by isPropertyOwner pre-resource check |
| F-91-02c | `ical-exports/foreign/U/probe.ics`         | DELETE | auth | 200/204/403/404 | 403 | ✅†     | denied by isPropertyOwner pre-resource check |

† b/c only confirm the foreign-owner branch — they do NOT differentiate the F-91-02 class on `properties/{own}/**` and `ical-exports/{own}/{own_unit}/**`. Class extends by rule shape; live confirmation limited to `users/`.

**13 + 3 = 16 / 16 PASS** against expectation; F-91-02a is recorded as expected (403 in set) but flags the bug class.

Cleanup: Admin SDK `gcloud storage rm` used to remove S13 + F-91-02a artifacts. Bucket parity restored.

---

## §5 — Indexes audit

`firestore.googleapis.com/v1/.../collectionGroups/-/indexes` →

```
LIVE_COUNT = 64
DECL_COUNT = 64 (firestore.indexes.json)
NOT_READY  = 0
ORPHANS_IN_LIVE = 0
MISSING_IN_LIVE = 0
```

`daily_prices` indexes (live, all `state=READY`):

| collectionGroup | scope             | fields                  |
|-----------------|-------------------|-------------------------|
| daily_prices    | COLLECTION_GROUP  | unit_id:A date:A        |
| daily_prices    | COLLECTION_GROUP  | unit_id:A available:A   |
| daily_prices    | COLLECTION_GROUP  | unit_id:A available:A date:A |
| daily_prices    | COLLECTION        | unit_id:A date:A        |
| daily_prices    | COLLECTION        | **available:A date:A**  |

→ `daily_prices` COLLECTION composite (`available + date`) target from task brief is present + READY ✅.

Verdict: ✅ 100% parity, 0 drift, 0 orphans, 0 creating.

---

## §6 — Findings

### F-91-02 (P3 / INFO — UX gap, security-positive side-effect)

> **Note:** F-91-01 is reserved for the parallel `sanitizeEmail` / `loginAttempts/{garbage}` finding tracked under [`memory/sanitize-email-no-format-check.md`](../memory/sanitize-email-no-format-check.md). Numbers here start at F-91-02 to avoid collision.

**Storage:** client-SDK `DELETE` on **own** `users/{uid}/**` path returns 403 PERMISSION_DENIED.

**Root cause:** rule shape

```
allow write: if request.auth != null
  && request.auth.uid == userId
  && request.resource.size < 10 * 1024 * 1024
  && request.resource.contentType.matches('image/(jpeg|png|webp|gif|heic|heif)');
```

`request.resource` is **null** on DELETE → both `.size` and `.contentType` predicates fail → write denied. `write` covers create + update + **delete** by default — no separate `allow delete` clause restores delete capability.

**Class:** same rule shape applies to:
- `match /users/{userId}/{allPaths=**}` — live-confirmed 403 via F-91-02a
- `match /properties/{propertyId}/{allPaths=**}` — analytical (same shape; foreign-owner test 403 from `isPropertyOwner` branch)
- `match /ical-exports/{propertyId}/{unitId}/{allPaths=**}` — analytical (`request.resource.size < 5 * 1024 * 1024` same trap)

**Impact:** users cannot remove uploaded files (profile pictures, unit images, ical exports) via the client SDK — they have to overwrite. `grep -rE "(deleteObject|deleteFile|admin\.storage|bucket\(\)\.file)" functions/src/` returned **no** CF-mediated delete helper, so this is NOT compensated server-side. Likely an oversight rather than an intentional immutability guarantee.

**Fix sketch:** add per-path `allow delete: if request.auth != null && request.auth.uid == userId;` (and analogous owner-only delete clauses for properties + ical-exports) so DELETE doesn't fall through the create+update write predicate.

**Severity:** P3 — UX issue, not exploitable. Documented for the storage hardening backlog.

### F-91-03 (P2 / MEDIUM — defense-in-depth gap)

**Firestore:** `users/{userId}/devices/{deviceId}` rule allows arbitrary field writes on update.

Probed: `PATCH /users/{self}/devices/{deviceId}?updateMask.fieldPaths=attacker_field` with `attacker_field: "arbitrary"` → **HTTP 200**, doc updated.

**Rule body (live, lines 159-163 of firestore.rules):**

```
match /devices/{deviceId} {
  allow read: if isOwner(userId);
  allow create, update: if isOwner(userId);
  allow delete: if isOwner(userId);
}
```

No `affectedKeys` / `hasOnly` allowlist.

**Memory clue:** `CLAUDE.md` index references "Firestore `affectedKeys` + `set(merge:true)` (2026-05-29) ... narrow update allowlists stay safe (audit/89 SF-062 devices)". The audit/89 SF-062 work on the in-flight `docs/audit-90-prod-cutover-runbook` branch concerns **CORS** allowlist on callables (per `audit/89-...md` and memory entry [[f86-01-cors-allowlist-gap-8-callables]]). The devices Firestore-rule allowlist appears to be **planned but not deployed**, OR the memory entry is mis-tagged.

**Impact:** if any client/CF code path reads `users/{uid}/devices/{deviceId}` to drive session-management decisions (trusted device flag, push-token routing, login bypass), a user can inject arbitrary fields. Privilege gain is bounded by whatever the consumer code trusts — currently grep `grep -r "users.*devices" lib/ functions/src/` would tell, but is out of scope for a rule-layer smoke.

**Fix sketch:** add an `affectedKeys().hasOnly([...])` clause on update OR an `hasOnly` shape on create — mirror the pattern from `users/{uid}/securityEvents` (rules.lines 147-156).

**Severity:** P2 — depends on consumer code; defense-in-depth missing.

### F-91-04 (INFO — partial coverage acknowledgment)

P31 (`widget_settings` write with secret-named field) returned 403 — but the `firestore.rules` `widget_settings` update rule is `allow create, update, delete: if isPropertyOwner(propertyId);` with no `noSecrets` predicate. The 403 came from `isPropertyOwner` denying foreign-property write, not from any secret-name allowlist. To probe SF-021 noSecretsInWidgetSettings enforcement on an **owned** property, seed an owned property+widget_settings doc under the test account — out of scope here. Likely the noSecrets guarantee is enforced in the CF (`saveWidgetSettings`) write path, not in client-SDK rules.

---

## §7 — Carryovers / out of scope

- **Bookings update affectedKeys clause** (`status`/`approved_at`/... `hasAny` deny) not live-probed — would need a booking owned by the test account. Emulator suite `bookings.test.ts` covers it. Add to seed catalog for next smoke.
- **5 MiB / 10 MiB caps**: rule-body verified, not runtime-probed (would need actual oversized upload).
- **F-91-03 consumer-side impact** — grep `users/.*devices` in client + CF to assess whether arbitrary-field injection has any blast radius downstream.
- **53 vs 46 rules-test count** brief expectation: 46 is the current main + audit/86-90 baseline. If brief expectation comes from a stale branch, reconcile before next sweep.
- **P37 side-effect:** test account `users/GILVItIVP5R8WXfnMmyMo1ykhUm2` has `email_notifications_consent=true` post-probe. Benign + idempotent; not rolled back.

---

## §8 — Reproducibility

All probes scripted via `mcp__plugin_context-mode_context-mode__ctx_execute(javascript)`. Patterns:
- Sign-in: `identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key={dev-web-api-key}` (key in `lib/firebase_options_dev.dart`).
- Anon: omit `Authorization`, send only API key in query (or none — Firestore REST works either way for anon).
- Auth: Bearer = `idToken` from sign-in response.
- Reserved-ID trap: Firestore doc IDs starting with `__` return 400 `INVALID_ARGUMENT` ("Resource id ... is invalid because it is reserved.") — first probe pass hit this 8 times; re-ran with `probe-{timestamp}` IDs.

Live ruleset/index fetch:
```
TOKEN=$(gcloud auth print-access-token)
curl -H "Authorization: Bearer $TOKEN" -H "X-Goog-User-Project: bookbed-dev" \
  "https://firebaserules.googleapis.com/v1/projects/bookbed-dev/releases" | jq
curl -H "Authorization: Bearer $TOKEN" -H "X-Goog-User-Project: bookbed-dev" \
  "https://firestore.googleapis.com/v1/projects/bookbed-dev/databases/(default)/collectionGroups/-/indexes" | jq
```

Note: `?pageSize=200` is rejected ("Invalid page size. Only 0 is supported.") — omit pageSize entirely.
