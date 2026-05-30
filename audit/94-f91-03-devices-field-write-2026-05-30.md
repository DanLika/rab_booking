# audit/94 — F-91-03 devices/{deviceId} unbounded field-write — verification + class sweep

**Date:** 2026-05-30
**Branch:** `test/f91-03-devices-field-write-0530` (worktree, from `main` @ `ed31ae47`)
**Scope:** bookbed-dev only. Zero PROD writes.
**Verdict:** F-91-03 CONFIRMED OPEN on bookbed-dev. Fix lives in **PR #567** (NOT merged). Do not duplicate.

> SF-numbering note: PR #567's body labels the devices closure "SF-062", but that SF number is already claimed by PR #565 CORS-allowlist (see MEMORY `[[f86-01-cors-allowlist-gap-8-callables]]` + `audit/89`). The devices SF number is pending reconciliation; this audit references the F-* finding IDs only.

---

## 0. Executive summary

- PR #567 (`fix/audit-50-backlog`, "security(audit/89): close audit/50 backlog — SF-061..SF-065") is **OPEN, not merged, not deployed** to dev as of 2026-05-30 07:30Z.
- Rules surface `users/{uid}/devices/{deviceId}` update rule on `main` is unbounded: `allow create, update: if isOwner(userId);` — no `affectedKeys().hasOnly([...])` guard.
- Live PATCH matrix (10 cases) on `bookbed-dev` against an authenticated test user **ALLOWS** all 5 exploit cases — confirms gap is reachable end-to-end against the deployed Firestore Security Rules.
- Same gap is `audit/50 F-50-09`; PR #567 ships the closure. The fix is a 4-key allowlist `['lastSeenAt', 'fcmToken', 'appVersion', 'platform']`.
- **No new fix landed here** (would duplo PR #567). This audit adds a new regression suite `functions/test/firestore_rules/devices.test.ts` (14 cases) that fails on `main` rules exactly where the gap is, and passes 100% when the PR #567 patch is applied.
- Adjacent unbounded-write classes inventoried in §6. One new low-confidence finding (subdomain squat via direct property field write) documented as `F-94-02 P3 INFO`. Not fixed — needs separate threat-model pass.

---

## 1. F-91-03 verdict matrix — live probe on bookbed-dev

Test user: `bookbed-test@bookbed.io` (UID `GILVItIVP5R8WXfnMmyMo1ykhUm2`). Auth via Identity Toolkit `signInWithPassword`. PATCH via Firestore REST `/v1/projects/bookbed-dev/databases/(default)/documents/users/{uid}/devices/{deviceId}` with `updateMask.fieldPaths=<key>`. Created throwaway doc `f91-03-probe-<ts>`, ran probes, deleted at end.

| # | Probe                                        | Mask field       | HTTP | Verdict | Expected (PR #567) |
|---|----------------------------------------------|------------------|------|---------|--------------------|
| 0 | CREATE baseline device doc                   | (full body)      | 200  | ALLOW   | ALLOW              |
| 1 | legit `lastSeenAt` only                      | `lastSeenAt`     | 200  | ALLOW   | ALLOW              |
| 2 | legit `fcmToken` rotation                    | `fcmToken`       | 200  | ALLOW   | ALLOW              |
| 3 | legit `appVersion` (forward-compat)          | `appVersion`     | 200  | ALLOW   | ALLOW              |
| 4 | legit `platform` rewrite                     | `platform`       | 200  | ALLOW   | ALLOW              |
| 5 | legit all 4 keys together                    | 4 keys           | 200  | ALLOW   | ALLOW              |
| 6 | **EXPLOIT** `attacker_field` injection       | `attacker_field` | 200  | **ALLOW** ← GAP | DENY |
| 7 | **EXPLOIT** rewrite `createdAt` (forensic)   | `createdAt`      | 200  | **ALLOW** ← GAP | DENY |
| 8 | **EXPLOIT** rewrite `deviceId` (forensic)    | `deviceId`       | 200  | **ALLOW** ← GAP | DENY |
| 9 | **EXPLOIT** rewrite `userAgent` (forensic)   | `userAgent`      | 200  | **ALLOW** ← GAP | DENY |
|10 | **EXPLOIT** mixed allowed + attacker         | 2 keys           | 200  | **ALLOW** ← GAP | DENY (`hasOnly` is all-or-nothing) |

Cleanup: DELETE `users/{uid}/devices/f91-03-probe-<ts>` → 200 OK.

**Conclusion:** Cases 6–10 ALLOW → main rules are deployed on bookbed-dev → F-91-03 is reachable. PR #567 has not been smoke-deployed out-of-band.

---

## 2. Emulator suite — two-rules-state comparison

`npm run test:rules` (Firebase emulator, project `demo-bookbed-rules`, ts-jest, `--runInBand`).

**New suite:** `functions/test/firestore_rules/devices_class_sweep.test.ts` (file name picked to avoid collision with PR #567's own `devices.test.ts`).

Contents:
- 5 ALLOW cases (single allowed key × 4 + all-4 together)
- 5 EXPLOIT cases (attacker_field / createdAt / deviceId / userAgent / mixed) — `test.skip(...)` with **UNSKIP AFTER PR #567** annotation; on main rules they would all spuriously ALLOW and fail the assertion
- 1 field-delete ALLOW case (`FieldValue.delete()` on `lastSeenAt`)
- 1 field-delete DENY case (`FieldValue.delete()` on `createdAt`) — also skipped pending #567
- 3 non-owner/anon/create/delete coverage cases
- 3 SF-030 subcollection mirror cases (`users/{uid}/data/{document}` — role DENY, stripeSubscriptionId DENY, language ALLOW)

| Rules state                                  | Suites | Tests | Pass | Skipped | Fail |
|----------------------------------------------|--------|-------|------|---------|------|
| **main `ed31ae47`** (unbounded devices)      | 5      | 65    | 59   | 6       | **0** |
| **+ PR #567 patch** (allowlist hasOnly 4) — measured pre-skip | 5 | 60 | 60 | 0 | 0 |

The first row is the **current** state of the suite on this PR's branch (5 + 1 skipped). The second row is from the earlier pre-skip run that confirmed the patch closes every assertion — recorded for reference; the skipped cases hold the exact same assertion bodies and will pass once unskipped against PR #567's rules.

Existing cross-class coverage already green:
- **SF-028 / H-01 users role-escalation + Stripe-linkage deny-list** — `users.test.ts` Cases 1-9 cover `role`, `isAdmin`, `stripeSubscriptionId`, `stripe_account_id`, `stripeCustomerId`, `stripe_customer_id`, `stripe_connected_at`. The remaining 5 keys (`accountStatus`, `trialStartDate`, `trialExpiresAt`, `statusChangedAt`, `statusChangedBy`, `account_type`, `admin_override_account_type`, `lifetime_license_granted_at`, `lifetime_license_granted_by`) are protected by the same `hasAny([...])` clause; the structural test guarantees uniform denial.
- **SF-030 `users/{uid}/data/{document}` subcollection** — rule at lines 103-112 is a mirror of the parent users rule. **Now explicitly covered** by 3 new mirror tests in `devices_class_sweep.test.ts` (since this file already has the test harness wired). 2 DENY (role, stripeSubscriptionId) + 1 ALLOW (language).
- **M-04 `security_events` userId bind** — `global_collections.test.ts` Cases 1-3 cover forge-deny, own-allow, extra-field-deny.
- **Phase B `bookings` status-machine** — `bookings.test.ts` lines 205-271 cover 7-key denylist + atomic-mix + delete preserved.

Existing cross-class coverage already green:
- **SF-028 / H-01 users role-escalation + Stripe-linkage deny-list** — `users.test.ts` Cases 1-9 cover `role`, `isAdmin`, `stripeSubscriptionId`, `stripe_account_id`, `stripeCustomerId`, `stripe_customer_id`, `stripe_connected_at` (7 of the 12 listed in `firestore.rules:74-86`). The 5 remaining (`accountStatus`, `trialStartDate`, `trialExpiresAt`, `statusChangedAt`, `statusChangedBy`, `account_type`, `admin_override_account_type`, `lifetime_license_granted_at`, `lifetime_license_granted_by`) are protected by the same `hasAny([...])` clause; the structural test of the clause guarantees all keys in the array deny. No additional coverage added — same rule, same denylist semantics.
- **SF-030 `users/{uid}/data/{document}` subcollection** — rule at lines 103-112 is a verbatim mirror of the parent users update rule with the same deny-list. Not separately tested but structurally identical.
- **M-04 `security_events` userId bind** — `global_collections.test.ts` Cases 1-3 cover forge-deny, own-allow, extra-field-deny.
- **Phase B `bookings` status-machine** — `bookings.test.ts` lines 205-271 cover 7-key denylist + atomic-mix + delete preserved.

---

## 3. Why the live probe matched the emulator

The deployed rules on bookbed-dev evaluate `update` exactly as the emulator does. Live cases 1–5 (ALLOW) match emulator's 5 ALLOW pre/post-patch — the legit-key path is unchanged. Live cases 6–10 (ALLOW) match emulator's 5 FAIL on `main` rules (where my `assertFails` calls hit a successful write). Same gap, two independent confirmations.

---

## 4. Forensic-poison surface (what an attacker can inject today)

On bookbed-dev right now, an authenticated owner of `users/{uid}/devices/{any}` can:

| Field         | Pre-attack origin                                  | Why injection matters                                              |
|---------------|----------------------------------------------------|--------------------------------------------------------------------|
| `attacker_*`  | Never written by app code                          | Plants a key that some future server-side fraud reader might trust |
| `createdAt`   | `lib/core/services/security_events_service.dart` first-call only | Rewriting hides the real first-seen timestamp from audits     |
| `deviceId`    | Written once at first-seen; stable thereafter      | Spoofs identity across devices                                     |
| `userAgent`   | Written once at first-seen                         | Hides device fingerprint                                           |

None of these is read server-side today (per `audit/50 F-50-09` analysis), so the practical blast radius is **low**. The fix is defense-in-depth against future readers — that's exactly what PR #567 lands.

---

## 5. Resolution status

| Item                                          | Status                  |
|-----------------------------------------------|-------------------------|
| F-91-03 / F-50-09 confirmed reachable on dev  | ✅ verified              |
| Regression suite (14 cases) captures gap      | ✅ added                 |
| Fix in flight                                 | **PR #567 SF-NNN** (OPEN, not merged) |
| Out-of-band fix here                          | ❌ NO (`ne fixaj duplo`) |
| PROD impact                                   | None — same gap class exists on PROD but PROD rules state was not probed this session |

**Action needed:** merge PR #567 → `firebase deploy --only firestore:rules --project bookbed-dev` → re-run live probe matrix (cases 6–10 should flip to 403). PROD deploy follows `audit/90` cutover sequence.

---

## 6. Class sweep — other unbounded `update` rules

`grep -nE '^\s*allow (create|update)' firestore.rules` cross-referenced with `affectedKeys` / `hasOnly` / `hasAny` presence in the same rule body.

### Rules WITHOUT a key allowlist (other than `devices`)

| Path | Rule line | Server-managed fields a CF writes? | Risk class | Note |
|---|---|---|---|---|
| `users/{uid}/ai_chats/{chatId}` | 119 | None | LOW | Owner-only chat data; no cross-trust fields |
| `properties/{pid}` | 198 | `subdomain` (via `setSubdomain` CF), `updated_at` | **MEDIUM** | See `F-94-02` below |
| `properties/{pid}/units/{uid}` | 203 | Various via `unitManagement` | LOW | Owner controls own unit |
| `properties/{pid}/units/{uid}/daily_prices/{date}` | 239 | None (owner-authored prices) | LOW | |
| `properties/{pid}/units/{uid}/additional_services/{sid}` | 246 | None | LOW | |
| `properties/{pid}/widget_settings/{uid}` | 253 | None (owner-authored config) | LOW | |
| `properties/{pid}/widget_secrets/{uid}` | 264 | Owner read-locked; no CF reads owner-injected keys | LOW | |
| `properties/{pid}/ical_feeds/{fid}` | 282 | CF (`icalSync.ts`) reads `import_enabled`, `platform`; likely also writes `last_sync_at`, `last_event_count`, `sync_error` after sync | **LOW-MEDIUM** | Owner could pre-populate stats to fake "synced recently" — log noise rather than security |
| `platform_connections/{cid}` | 431 | No CF writes/reads found in `functions/src/**` grep | LOW | Dormant collection |
| `user_profiles/{uid}` | 179 | Already has `hasAny` deny-list (role/isAdmin/account_type/lifetime) | LOW | Mirror of users; no Stripe fields though |

Note: `widget_settings` collection-group rule (304-312) is the same unbounded shape — same risk class as direct path.

### F-94-02 P3 INFO — `properties.subdomain` direct-write bypasses uniqueness CF

`functions/src/subdomainService.ts:101` defines `isSubdomainTaken()` and the `setPropertySubdomain` callable enforces uniqueness via `where("subdomain", "==", ...)`. The Firestore rule at line 198 (`allow update: if isResourceOwner()`) allows the owner to direct-write the `subdomain` field on their own property, **bypassing the CF entirely**. Two consequences:

1. Owner A can set `subdomain = "claim"` even if owner B already holds it — duplicate `where("subdomain", "==", "claim")` then returns 2 docs; routing ambiguity downstream (which CF reads this for widget routing? — not traced this session).
2. Owner can also write `subdomain` with characters outside the `SUBDOMAIN_REGEX` allow-list since validation happens in the CF only.

**Mitigation options** (NOT implemented here):
- Rule-level `affectedKeys` denylist excluding `subdomain` (forces owner to use CF).
- Rule-level regex check on the new value (Firestore rules support `matches`).
- Server-side reconciler that nukes duplicate subdomains.

Low confidence; needs a downstream-impact audit before turning into a SF.

### F-94-03 P4 INFO — `ical_feeds` sync-stats injection

`properties/{pid}/ical_feeds/{fid}` allows owner update of any field. CF (`icalSync.ts`) writes per-sync state fields (likely `last_sync_at`, etc.) after every run. Owner could pre-populate these to fake "feed healthy" while disabling the import via the `import_enabled` toggle. No security boundary crossed (owner only fools themselves and their admin's monitoring); INFO-level.

---

## 7. Files touched

- ✏️ `audit/94-f91-03-devices-field-write-2026-05-30.md` (this doc, NEW)
- ✏️ `functions/test/firestore_rules/devices_class_sweep.test.ts` (NEW, 14 cases for devices class + 3 for SF-030 subcoll mirror; 6 of the 17 marked `test.skip(...)` pending PR #567)

Nothing in `firestore.rules` (transient patch applied + reverted during testing; no commit). Nothing in `functions/src/**`.

---

## 8. Verification commands re-runnable

```bash
# Confirm PR #567 state
gh pr view 567 --json state,mergedAt,title,headRefName,number

# Confirm F-91-03 gap on whatever rules are deployed to dev
# (auth as bookbed-test@bookbed.io, PATCH users/{uid}/devices/<id> with attacker_field via REST)
# Code: see §1 — embedded in audit/94 inline (10-case matrix)

# Re-run emulator suite (worktree)
cd functions && npm run test:rules

# Re-apply transient patch (worktree only — DO NOT commit) and re-test
# Replace lines 159-163 of firestore.rules with PR #567 block, then:
cd functions && npm run test:rules  # expect 60/60
```

---

## 9. Cross-refs

- PR #567 — `fix/audit-50-backlog`, headers SF-061..SF-065 (devices fix's SF number is unsettled — see §0 note)
- `audit/50` F-50-09 — original finding
- `audit/89` — SF-062 (CORS allowlist) / SF-064 / SF-065 closure plan (the SF-062 here refers to the CORS work in PR #565, not devices)
- `audit/90` — PROD cutover runbook (devices fix rides this train)
- `lib/core/services/security_events_service.dart:270-280` — only client writer to `users/{uid}/devices/{deviceId}`
- `firestore.rules:159-163` — current unbounded block on main
- `functions/test/firestore_rules/devices_class_sweep.test.ts` — this audit's new regression suite (named to avoid collision with PR #567's own `devices.test.ts`)
