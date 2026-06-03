# audit/111 — `accountStatus` backfill pre-flight (SF-078)

**Drafted**: 2026-06-03
**Mode**: READ-ONLY audit + dry-run script. NO apply, NO deploy, NO gate-code changes. Script defaults to `--dry-run`; operator opts in with `--execute` after reviewing this doc.
**Companion**: `scripts/backfill-accountstatus.js`, `audit/migrations/2026-06-03-accountstatus-backfill-prod-DRYRUN.log`
**Origin**: SF-078 PR #666 pre-deploy — 54 % of PROD users would be blocked on Step A deploy without prior backfill (audit/109 §9 Q4 + audit/110 §Off-spec drift).

## 1. Writer audit — who writes `accountStatus`?

`grep -rnE "accountStatus[\"' ]*[:=]|\.update.*accountStatus|set.*accountStatus" functions/src scripts lib --include="*.ts" --include="*.js" --include="*.dart"` (excluding tests + node_modules):

| Writer | File:line | Value(s) written |
|---|---|---|
| Stripe webhook — sub cancelled | `stripePayment.ts:1074` | `"trial_expired"` |
| Stripe webhook — sub start | `stripePayment.ts:1149, 1189` | `"active"` |
| Auth trigger — new user | `auth/onUserCreate.ts:61` | `"trial"` |
| Scheduled — trial expiration | `trial/checkTrialExpiration.ts:79` | `"trial_expired"` |
| One-shot migration | `migrations/migrateTrialStatus.ts:110` | `"trial_expired"` or `"trial"` (computed) |
| Admin callable | `admin/updateUserStatus.ts:86` | `newStatus` (parameterized) — validated against `VALID_STATUSES = ["trial","active","trial_expired","suspended"]` at `updateUserStatus.ts:17` |
| Admin callable — lifetime grant | `admin/setLifetimeLicense.ts:88, 107` | `"active"` or `"trial"` (grant / revoke) |

**Verdict: zero live writers produce `accountStatus: 'premium'`.** The 3 PROD users carrying `premium` are legacy data — likely hand-set via Firebase Console with field-name confusion (`accountStatus` vs `accountType`, where the latter DOES accept `premium` per `stripePayment.ts:1190 accountType: "premium"`).

`admin/updateUserStatus.ts:17` enforces the canonical 4-status allow-list — `'premium'` is rejected by the admin tool today.

**Backfill is safe to ship.** No re-drift source exists. Normalised values will stick.

## 2. Dry-run summary (PROD `rab-booking-248fc`)

Generated 2026-06-03 17:07Z. Full log: `audit/migrations/2026-06-03-accountstatus-backfill-prod-DRYRUN.log`.

| Action | Count | Note |
|---|---|---|
| **UPDATE** | 3 | All 3 `premium` users — every one carries `accountType: 'premium'` signal → confidently normalise to `'active'` |
| **NOOP** | 18 | Known-canonical values (`trial` 10, `trial_expired` 7, `active` 1) |
| **MANUAL_REVIEW** | 0 | No premium user lacks a paying signal — all 3 had `accountType` evidence |
| **MANUAL_TRIAGE** | 3 | `<missing>` accountStatus + no `trialExpiresAt` — operator decides per-user |
| **TOTAL** | 24 | matches PROD `users` count from audit/109 §9 Q4 |

## 3. Lifetime / Stripe cross-ref — 3 `premium` users

Required check per task §3 before approving `--execute`. **NONE of the 3 carry a Stripe-subscription or lifetime-license signal in their `users/{uid}` doc.**

| uid | email | accountType | stripeSub | stripeCust | lifetime_granted_at | createdAt |
|---|---|---|---|---|---|---|
| `0rt8PRpXEcWsoAkfkBTG5PXa0Uf1` | *(no email field captured)* | premium | — | — | — | 2026-01-29 |
| `ngbxi8qkmcT0m2p7zikcXkP0ZRJ2` | `duskolicanin1234@gmail.com` | premium | — | — | — | 2026-01-18 |
| `nz4hyOoIOqaje7976DLsJZnXctT2` | `rdmclv@yahoo.com` | premium | — | — | — | 2026-01-19 |

**Interpretation**: these users were given `premium` status via Firebase Console (or pre-existing admin tooling) WITHOUT routing through a Stripe subscription. The most likely classes:
- **Internal / staff / test accounts** (e.g. `duskolicanin1234@gmail.com` is the project owner's own account per `memory/userEmail`).
- **Manually-granted complimentary access** that bypassed the Stripe flow.

The proposed normalisation `'premium'` → `'active'` is **correct for the helper allow-list** (the gate will pass them), but it does NOT introduce any new entitlement — these users already had `accountType: 'premium'` so they were already treated as paid by `scheduledPushNotifications.ts:390,499,629` (which whitelists `'premium'`). The migration only normalises the `accountStatus` field so the trial gate accepts them.

**Operator confirmation needed**: are these 3 accounts intentionally complimentary? If YES → `--execute` is safe and resolves the SF-078 deploy blocker. If any of them was set to `premium` accidentally → resolve out-of-band before `--execute`.

## 4. MANUAL_TRIAGE — 3 users with `<missing>` accountStatus + no `trialExpiresAt`

These are NOT auto-applied even with `--execute`. Operator decides per-user. Metadata captured for triage:

| uid | email | role | accountType | createdAt | lastLoginAt | Suggested target |
|---|---|---|---|---|---|---|
| `2iVruRvCKIcsGgbmSEO5fGkGQZ83` | `jasko@jasko-rab.com` | owner | **lifetime** | 2025-12-21 | 2026-05-20 | likely `'active'` (lifetime accountType → `setLifetimeLicense` semantics) |
| `CgcQVSNb2NTiqx49G85BbqSsfTm2` | `test@bookbed.io` | owner | **premium** | 2026-01-14 | 2026-01-14 | likely `'active'` (test account, accountType matches the `premium` class above) |
| `qJMif6jRHmN4ZEyWd3rXpwldHEr1` | `ababic785@gmail.com` | owner | **trial** | 2025-12-21 | 2026-01-21 | ambiguous — `accountType: trial` + no `trialExpiresAt` → onboarding gap. Either backfill `trialExpiresAt = createdAt + 30d` then re-run (→ would be `trial_expired`), OR set `'trial_expired'` directly and let the user upgrade. |

Each MANUAL_TRIAGE user carries an `accountType` value that gives strong signal:
- `lifetime` / `premium` → operator can set `accountStatus = 'active'`
- `trial` with no `trialExpiresAt` → operator can choose `'trial_expired'` or backfill the expiry first

The script's classifier deliberately does NOT auto-derive from `accountType` per the original task spec ("NEMA trialExpiresAt → MANUAL_TRIAGE"). Could be relaxed in a follow-up if operator wants `accountType` → `accountStatus` derivation, but that's a different design call (the two fields are semantically distinct).

## 5. Proposed `--execute` step

After operator review of §3 and §4:

```bash
# Authenticate against PROD ADC
gcloud auth application-default login
gcloud config set project rab-booking-248fc

# DRY-RUN one more time (sanity in the maintenance window)
GOOGLE_CLOUD_PROJECT=rab-booking-248fc \
  node scripts/backfill-accountstatus.js --project rab-booking-248fc

# Apply (only after §3 confirmation)
GOOGLE_CLOUD_PROJECT=rab-booking-248fc \
  node scripts/backfill-accountstatus.js --project rab-booking-248fc --execute

# Re-run to confirm idempotency (should now show 0 UPDATE, 21 NOOP, 3 MANUAL_TRIAGE)
GOOGLE_CLOUD_PROJECT=rab-booking-248fc \
  node scripts/backfill-accountstatus.js --project rab-booking-248fc

# Triage the 3 MANUAL_TRIAGE users via admin/updateUserStatus callable
# (per §4 table) — operator-attribution via statusChangedBy = admin uid.
```

The `--execute` apply writes:
- `accountStatus = 'active'` (for the 3 premium users)
- `statusChangedAt = serverTimestamp()`
- `statusChangedBy = 'scripts/backfill-accountstatus.js (SF-078)'`
- `statusChangeReason = 'backfill: premium → active'`

so the audit trail on `users/{uid}` records the migration cleanly (matches the admin-tool's existing audit-field convention).

## 6. Effect on SF-078 deploy plan (PR #666)

Before backfill: 13 of 24 PROD users (54 %) would hit `failed-precondition` on SF-078 deploy (7 intentional + 3 premium drift + 3 missing).

After this backfill `--execute`: 7 of 24 users (29 %) would hit `failed-precondition` — and **all 7 are the intentional `trial_expired` block class** (the gate's actual purpose). The 3 premium normalise to `'active'` (pass). The 3 MANUAL_TRIAGE users remain `<missing>` until operator triages them — they'd still fail-closed (correctly, with a Sentry WARN) until the operator sets them via admin tooling.

So this PR + operator triage of the 3 MANUAL_TRIAGE users = clean SF-078 deploy preconditions.

## 7. Out of scope

- **`accountType` field cleanup**. This PR touches only `accountStatus`. The `accountType` field's `'premium'` value is canonical per `stripePayment.ts:1190` and admin tooling — no drift to normalise there.
- **`scheduledPushNotifications.ts` filter** dropping `'premium'`. Documented in `audit/110 §Off-spec drift` as a follow-up cleanup PR. Not blocking SF-078 deploy.
- **One-shot fix of the 3 MANUAL_TRIAGE users.** Per task scope, operator triages them out-of-band via the admin tool. The script never auto-applies these.

## 8. Files touched by this PR

- `scripts/backfill-accountstatus.js` (NEW, ~200 lines; mirrors `scrub-widget-settings-secrets.js` CLI shape)
- `audit/migrations/2026-06-03-accountstatus-backfill-prod-DRYRUN.log` (NEW — generated by the dry-run)
- `audit/111-accountstatus-backfill-2026-06-03.md` (NEW — this doc)

Zero `functions/src/**`, zero `lib/**`, zero `firestore.rules`, zero `storage.rules` changes. Data-migration-only PR. SF-078 gate code (PR #666) untouched.
