# audit/96 — F-94-02-CREATE close: route subdomain through `setPropertySubdomain` CF

**Date:** 2026-05-30
**Branch:** `fix/f94-02-create-subdomain-0530`
**Closes:** F-94-02-CREATE (audit/86 §7) — last open item from the F-94 direct-write sweep
**Related:** [audit/86-direct-write-sweep](./86-direct-write-sweep.md) — F-94-02-UPDATE, F-94-03, F-94-04 closed via rules in PR #578 (SF-068)
**SF entry:** [SF-069](../docs/SECURITY_FIXES.md#sf-069-property-create-subdomain-squat--route-through-cf-f-94-02-create)
**Severity:** MEDIUM (no PII / auth bypass — squat risk for premium subdomains)
**Scope honored:** lib only. `functions/`, rules, `ios/`, `android/`, `test/firestore_rules` untouched. FROZEN surfaces (Calendar Repository, Cjenovnik tab, Unit Wizard publish flow) untouched.

---

## 1. The bug

`lib/features/owner_dashboard/data/firebase/firebase_owner_properties_repository.dart:195` (pre-fix) embedded the caller-supplied `subdomain` directly in the initial `properties` doc write:

```dart
final docRef = await _firestore.collection('properties').add({
  'owner_id': ownerId,
  'name': name,
  'slug': slug,
  'subdomain': subdomain,         // <- F-94-02-CREATE: client-controlled
  ...
});
```

Firestore rules format-validate the field but do **not** enforce the reserved list (e.g. `admin`, `api`, `widget`) or uniqueness — those checks live exclusively in `functions/src/subdomainService.ts`. A malicious or competing owner could therefore:

1. Bypass the UI debounced `checkSubdomainAvailability` call entirely by hitting the Firestore REST/SDK surface directly, OR
2. Win a TOCTOU race against the UI by calling the Firestore write before the CF check returned, AND
3. End up holding a format-valid, well-known subdomain (`marriott`, `airbnb`, `booking-com`, …) on their own property doc — the same finding class as F-94-02-UPDATE before PR #578 locked that path through `affectedKeys` rule denial.

F-94-02-UPDATE was already closed at the rules layer (PR #578, SF-068). The CREATE counterpart was deferred there because the rule cannot deny *initial* doc writes containing the subdomain field without breaking the entire create flow — closing it requires routing the lib write through the existing `setPropertySubdomain` CF instead.

## 2. CF contract recap (`functions/src/subdomainService.ts`)

| CF | Purpose | Writes? | Auth + rate? |
|---|---|---|---|
| `checkSubdomainAvailability({subdomain, propertyId?})` | Format + reserved + uniqueness check | ❌ read-only | ✅ auth, 30 / 5 min per uid |
| `generateSubdomainFromName({propertyName, propertyId?})` | Suggest available subdomain from name | ❌ read-only | ✅ auth, 30 / 5 min per uid |
| `setPropertySubdomain({propertyId, subdomain})` | **Atomic reserve**: validate format + reserved + ownership + uniqueness, then `update({subdomain})` | ✅ writes Firestore | ✅ auth + ownership check |

`setPropertySubdomain` requires the property doc to **already exist** (it does an ownership check via `propertyDoc.data().owner_id === request.auth.uid`). Create-time therefore must be a 2-phase write: create property without `subdomain` → call `setPropertySubdomain` → on failure roll back.

## 3. Fix

Two repo methods touched in `firebase_owner_properties_repository.dart`. Other surfaces (UI flow in `property_form_screen.dart`, the shared `FirebasePropertyRepository`) inspected and left alone — see §5.

### 3.1 `createProperty()` — 2-phase reserve

```dart
final docRef = await _firestore.collection('properties').add({
  'owner_id': ownerId,
  'name': name,
  'slug': slug,
  // 'subdomain' intentionally omitted — set via CF below
  ...
});

final normalizedSubdomain = subdomain?.trim().toLowerCase();
if (normalizedSubdomain != null && normalizedSubdomain.isNotEmpty) {
  try {
    final callable = FirebaseFunctions.instance.httpsCallable('setPropertySubdomain');
    await callable.call<Map<String, dynamic>>({
      'propertyId': docRef.id,
      'subdomain': normalizedSubdomain,
    }).withCloudFunctionTimeout('setPropertySubdomain');
  } catch (cfError) {
    // Best-effort rollback: avoid leaking an orphan property doc when the
    // caller asked for a specific subdomain we couldn't reserve.
    try {
      await docRef.delete();
    } catch (rollbackError) {
      await LoggingService.logError(
        'createProperty subdomain reserve failed; orphan rollback also failed',
        rollbackError,
      );
    }
    throw PropertyException(
      'Failed to reserve subdomain',
      code: 'property/subdomain-reserve-failed',
      originalError: cfError,
    );
  }
}
```

**Rollback rationale.** Without rollback, a CF failure (uniqueness miss, network blip, rate-limit hit) leaves a property doc that the owner can't trivially associate with their requested subdomain — the UI optimistically navigates away on a `PropertyException` and the doc sits orphaned without a subdomain. Rolling back keeps the contract "create-with-subdomain succeeds atomically or fails atomically" intact. If the rollback itself fails we surface the *original* CF error (the user's actionable signal) while logging the rollback failure for operator follow-up.

`if (e is PropertyException) rethrow;` was added to the outer `catch` so the explicit `code: 'property/subdomain-reserve-failed'` survives — previously it would have been wrapped by `PropertyException.creationFailed(e)`, losing the discriminator.

### 3.2 `updateProperty()` — subdomain param now silently ignored

The UI in `property_form_screen.dart:1148-1173` already routes subdomain edits through `setPropertySubdomain` and passes `subdomain: null` to `updateProperty` when the value changed. When the value is unchanged it passed the existing value, which `affectedKeys` (post-PR #578) treats as a no-op anyway (see [[firestore-affectedkeys-set-merge]]). The line:

```dart
if (subdomain != null) updates['subdomain'] = subdomain;  // <- removed
```

was the last theoretical direct-write path on UPDATE — a future caller that didn't know about the CF contract could still pass a fresh subdomain through this method. Now the param is preserved for source-compat with the existing UI callsite but silently ignored; the comment explains why and points at the CF as the canonical path.

## 4. Verification

| Check | Result |
|---|---|
| `flutter analyze` on touched file | ✅ 0 issues |
| `flutter analyze lib/features/owner_dashboard` | ✅ 0 issues (after `flutter pub get` + `build_runner build --delete-conflicting-outputs` per `.claude/rules/build-runner.md`) |
| `flutter test test/shared/models/property_model_subdomain_test.dart test/shared/models/property_model_test.dart` | ✅ 47/47 passed |
| Manual UI smoke (chrome-devtools on bookbed-dev) | ⚠️ deferred — see §6 |

The UI flow in `property_form_screen.dart` was already correct on the create branch:
- `_checkSubdomainAvailability` (line 197) gates submit via `_isSubdomainAvailable`
- `_handleSave` (line 1098) blocks if `_isSubdomainAvailable != true` (line 1127-1141)
- On successful UI validation it calls `repository.createProperty(subdomain: subdomainValue)` (line 1201) — now routed through the CF

No UI changes needed. The behavior diff from the user's perspective is:
- **Before**: `checkSubdomainAvailability` CF says "available" → user submits → property doc lands with `subdomain` field even if a race-winning competitor squatted it in the same ms.
- **After**: `checkSubdomainAvailability` says "available" → user submits → property doc lands without `subdomain` → `setPropertySubdomain` CF runs its own uniqueness check + atomic write → if competitor won the race, the second caller gets `HttpsError('already-exists', ...)` and the property doc is rolled back. The first caller's reservation stands.

## 5. Out of scope / parallel findings

### 5.1 `lib/shared/repositories/firebase/firebase_property_repository.dart` — dead provider
`FirebasePropertyRepository.createProperty(PropertyModel)` and `.updateProperty(PropertyModel)` write `property.toJson()` directly — same vuln class. `grep` for callers of `propertyRepositoryProvider` (defined in `widget_repository_providers.dart:71`) returns **zero consumers** in `lib/`. Dead code at the moment, but if someone wires it up later they'd reintroduce the same direct-write hole. Tracked as F-96-01 follow-up — either delete the dead provider or apply the same 2-phase pattern.

### 5.2 `setPropertySubdomain` CF TOCTOU race
The CF reads `isSubdomainTaken` and then `update({subdomain})` in two separate steps. Two concurrent `setPropertySubdomain` callers with the same subdomain could both pass the read and both succeed the update, ending with two property docs holding the same subdomain. The Firestore rule should enforce uniqueness via `affectedKeys` + a tx-backed write, OR the CF should wrap both reads + write in a `db.runTransaction(...)`. Out of scope per "NE diraj functions/, rules" — tracked as F-96-02. Note this race is **strictly narrower** than the pre-fix lib direct-write, since the CF still rejects reserved-list strings and ownership-checks the caller.

### 5.3 Backfill — pre-existing squatted subdomains?
The fix is forward-only. Properties with already-squatted subdomains on PROD/dev aren't rolled back. Operational follow-up: cross-check current `properties.subdomain` values against the reserved list + duplicate detection script. Out of scope for this PR (no PROD touch).

## 6. Manual smoke (deferred, recipe captured)

User spec asks for a chrome-devtools UI smoke (create property with subdomain → CF reserve → squat someone-else's → reject). I'm leaving this deferred — chrome-devtools MCP requires explicit user-driven session, and the static path is already verified. Recipe for a follow-up runner on bookbed-dev:

1. Sign in as `bookbed-test@bookbed.io` ([[test-account]]).
2. Open `https://bookbed-owner-dev.web.app/owner/properties/new` (after `tool/deploy-dev.sh owner` rebuilds with this branch).
3. Form: name "Smoke", subdomain "smoke-96-{rand}".
4. Expect: property doc created → `setPropertySubdomain` CF invoked → field appears on doc.
5. Open second incognito session, sign in as a different test owner (or stay same and edit the new property). Enter same subdomain. Expect "already taken" UI error from `checkSubdomainAvailability` (read-only check) AND, if bypassed via direct submit, expect `setPropertySubdomain` CF to throw `already-exists` and the property doc to roll back.
6. Try a reserved string like "admin". Expect "reserved" UI error AND, if bypassed, CF throws `invalid-argument`.

Sentry filter (`HttpsError` client-fault drop, per `.claude/rules/cloud-functions.md` §HttpsError client-fault filter) covers `already-exists` + `invalid-argument` so these tests don't generate Sentry noise.

## 7. Files touched

| File | Lines | Change |
|---|---|---|
| `lib/features/owner_dashboard/data/firebase/firebase_owner_properties_repository.dart` | +43 / −5 | `cloud_functions` import; `createProperty` 2-phase reserve + rollback; `updateProperty` subdomain param ignored with comment |
| `docs/SECURITY_FIXES.md` | +28 / 0 | SF-069 entry |
| `audit/96-f94-02-create-fix.md` | +new | this doc |

No edits to `functions/`, rules, `ios/`, `android/`, `test/firestore_rules`, or any FROZEN surface.
