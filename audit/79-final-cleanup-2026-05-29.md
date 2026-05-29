# audit/79 — Final cleanup orchestration — 2026-05-29

**Date:** 2026-05-29
**Trigger:** `/effort max` autonomous run pre-authorized for all PROD deploys, PR merges, branch deletes, rule changes listed below.
**Predecessor:** [audit/77](./77-rules-tighten-migration-2026-05-29.md) Phase A + [audit/78](./78-rules-tighten-deny-2026-05-29.md) Phase B.
**Starting state:** main @ `9a9cacca` (PR #549 just landed) — working tree dirty with CLAUDE.md + audit/50 doc tweaks + stale ios/build artifacts.

## §1 Step-by-step result table

| Step | Result | Reference |
|---|---|---|
| 1 — PR #503 Stripe v22 squash | ✅ MERGED `9539b3e5` (8/8 checks green) | [#503](https://github.com/DanLika/rab_booking/pull/503) |
| 2 — google_sign_in pin ^6.3.0 | ✅ MERGED `57ba189e` via [#553](https://github.com/DanLika/rab_booking/pull/553); [#492](https://github.com/DanLika/rab_booking/pull/492) closed (deferred v7) | §2 |
| 3 — PR #457 email-wrapper rebase | ❌ CLOSED — 7-file template conflict, deferred for manual resolution | §3 |
| 4 — SF-052 PROD Sentry DSN | ✅ DEPLOYED-GREEN — full `firebase deploy --only functions` to PROD `rab-booking-248fc` | §4 |
| 5 — T3 Phase A PROD CF deploy | ✅ rolled into Step 4 — `completeBooking` (eu-w1) + `updateBookingAtomic` + `createOwnerBookingAtomic` (both us-c1) first-time PROD; allUsers IAM bound; anon 401 UNAUTHENTICATED 3/3 | §5 |
| 6 — T3 Phase B rules tighten | ✅ MERGED `0bf9cb86` via [#554](https://github.com/DanLika/rab_booking/pull/554); 46/46 rules tests; bookbed-dev + PROD rules deployed | [audit/78](./78-rules-tighten-deny-2026-05-29.md) |
| 7 — Repo hygiene | ✅ docs commit `0e2f16a7`; iOS plist confirmed PROD; ios/build restored; 1 merged branch deleted | §7 |
| 8 — Final audit doc | ✅ this file | — |

## §2 STEP 2 detail — google_sign_in pin

- PR #492 (Dependabot 6.3.0→7.2.0) closed with comment "v7 migration needs auth-flow review — mirror riverpod/freezed pin pattern from #519".
- New branch `chore/pin-google-signin-6` created off `origin/main`; pubspec.yaml `google_sign_in: ^6.2.2 → ^6.3.0`. Resolved sha unchanged (pubspec.lock untouched — caret floor only).
- `dart run build_runner build --delete-conflicting-outputs` ran to clear pub-cache desync on fresh worktree (CLAUDE.md TOOLING GOTCHA — 1538 phantom errors → 92 baseline infos).
- PR #553 squash-merged (no branch protection → instant merge with all 8 checks green pending).

## §3 STEP 3 detail — PR #457 close

`git rebase origin/main` produced content conflicts in 7 template files:

```
password-reset.ts, payment-reminder.ts, pending-owner-notification.ts,
pending-request.ts, refund-notification.ts, trial-expired.ts, trial-expiring-soon.ts
```

Per spec ("close on conflict") rebase aborted, PR closed with deferral comment. The wrapper migration is now blocked on a manual conflict-resolution session.

## §4 STEP 4 detail — SF-052 PROD Sentry DSN

### §4.1 Preflight gates

- `SENTRY_DSN=https://…` present in `functions/.env.rab-booking-248fc` ✅
- `Stripe.createFetchHttpClient()` present in `functions/src/stripe.ts:35` ✅ (PR #541 fix landed PROD-side this deploy)
- `cd functions && npm run build && npm test` 387/387 ✅ — after restoring `package-lock.json` from `origin/main` (local `npm install` had stripped `@emnapi/runtime@1.10.0` — same gotcha audit/77 §8 documented)

### §4.2 Deploy

`firebase deploy --only functions --project rab-booking-248fc` ~7 min wall clock; **first attempt failed** in cloud-build `npm ci` ("Missing: @emnapi/runtime@1.10.0 from lock file") — root cause: local `npm install` ran on macOS stripped the Linux-only optional dep. Lock restored from `origin/main`, redeploy GREEN.

All ~60 CFs reported "Successful update operation". Region split confirmed:

- **us-central1 (Stripe + booking + email + onCall defaults):** Stripe family (`createStripeCheckoutSession`, `getStripeAccountStatus`, `handleStripeWebhook`, etc.), `updateBookingAtomic`, `createOwnerBookingAtomic`, iCal sync, email
- **europe-west1 (audit-driven new code):** `approveBooking` / `rejectBooking` / `cancelBooking` / `completeBooking`, login-lockout family, trial-expiration family, admin lifetime-license / delete-account, FCM new-app-update, audit-driven reminders

### §4.3 Sentry smoke

```text
gcloud functions logs read approveBooking --region europe-west1 …
I  approvebooking  2026-05-29 12:39:49.797  Sentry initialized for Cloud Functions
I  approvebooking  2026-05-28 12:14:14.932  Sentry DSN not provided, skipping initialization   ← PRE-DEPLOY
```

DSN now active; pre-deploy "DSN not provided" line confirms baseline before this run.

### §4.4 Stripe egress smoke (PROD safety gate)

```text
POST https://us-central1-rab-booking-248fc.cloudfunctions.net/getStripeAccountStatus
body: {"data":{"accountId":"acct_1SgkGeBYuq5LimME"}}
→ HTTP=401 {"error":{"message":"User must be authenticated","status":"UNAUTHENTICATED"}}

POST https://us-central1-rab-booking-248fc.cloudfunctions.net/createStripeCheckoutSession
body: {"data":{}}
→ HTTP=400 {"error":{"message":"Booking data is required","status":"INVALID_ARGUMENT"}}
```

Both reached past Stripe SDK init without `INTERNAL` / 5xx — module loaded, fetch-http-client active, no Sentry-OTel-vs-node:https conflict. STRIPE_BROKE=0 → STEP 5 cleared.

## §5 STEP 5 detail — T3 Phase A PROD CFs

The three target CFs deployed as part of STEP 4 full deploy. Post-deploy gcloud IAM bindings + anon 401 smoke:

| CF | Region | IAM binding | Anon 401 body |
|---|---|---|---|
| `completeBooking` | europe-west1 | added `allUsers / roles/run.invoker` | `{"error":{"message":"You must be signed in.","status":"UNAUTHENTICATED"}}` |
| `updateBookingAtomic` | us-central1 | added | `{"error":{"message":"Authentication required.","status":"UNAUTHENTICATED"}}` |
| `createOwnerBookingAtomic` | us-central1 | added | `{"error":{"message":"Authentication required.","status":"UNAUTHENTICATED"}}` |

Region note: brief assumed all three live in europe-west1; deploy log + `gcloud run services describe` confirmed `updateBookingAtomic` + `createOwnerBookingAtomic` land in us-central1 (per their `onCall<>` lack of explicit `{region:...}`). IAM bind region adjusted per actual deploy. No 403/GFE — CF code reached.

## §6 STEP 6 detail — Phase B rules

See [audit/78](./78-rules-tighten-deny-2026-05-29.md). Summary:

- `firestore.rules` bookings subcollection `allow update, delete` split → tightened `allow update` denies any client diff that touches the 7 status-machine fields.
- `functions/test/firestore_rules/bookings.test.ts` +7 cases → `npm run test:rules` 39 → 46 GREEN.
- Test author gotcha: `update({status: existingValue})` does NOT trigger `affectedKeys()` — first test draft passed unmodified-status writes; fixed to write a different value (`'cancelled'` vs seed `'confirmed'`).
- bookbed-dev + rab-booking-248fc rules deployed.
- PR #554 squash-merged.

## §7 STEP 7 detail — Repo hygiene

- Restored: `ios/Podfile.lock`, `functions/build`, `ios/build/*` (gitignored .last_build_id + LogStoreManifest.plist files were spuriously staged-for-delete from a prior session).
- iOS plist `PROJECT_ID` confirmed `rab-booking-248fc` — no swap residual.
- No `ios/Runner/GoogleService-Info.plist.{dev,prod}-snapshot` present (already absent).
- CLAUDE.md + audit/50 docs commit `0e2f16a7` — 8 LOC additions, pure-docs scope verified before commit.
- `git pull --ff-only` brought PR #549 + #553 + #554 into local main. Then docs commit pushed cleanly.
- Branch prune: only `ops/sf-052-prod-sentry-dsn` was actually `--merged origin/main` (squash-merged feature branches don't show as merged in git's view). Deleted that one. Other ~48 historic branches left alone — not in scope of spec's `--merged` clause.
- Worktree sweep: `/tmp/bb-sf052-wt` (= `/private/tmp/bb-sf052-wt`) removed. Final worktree list: primary only.

## §8 PROD state confirmation

| Surface | Pre-session | Post-session |
|---|---|---|
| Stripe SDK on PROD | v19.1.0 | v22.2.0 (#503) |
| Sentry DSN on PROD CFs | unset (PR #515 merged but env file never had DSN populated) | active — "Sentry initialized" log line confirmed |
| `completeBooking` CF | undeployed (PROD) | europe-west1 live, IAM bound, anon UNAUTHENTICATED |
| `updateBookingAtomic` CF | undeployed (PROD) | us-central1 live, IAM bound, anon UNAUTHENTICATED |
| `createOwnerBookingAtomic` CF | undeployed (PROD) | us-central1 live, IAM bound, anon UNAUTHENTICATED |
| Bookings rule client status writes | ALLOWED | DENIED via diff() — 7 fields |
| Open Dependabot PRs against majors blocked locally | #492 (google_sign_in v7), #503 (stripe v22) | #503 merged, #492 closed → pin ^6.3.0 PR #553 merged |
| google_sign_in pubspec floor | ^6.2.2 | ^6.3.0 (pin documents the v7 deferral) |
| Stripe.createFetchHttpClient() PROD | source-only (PR #541 dev-deployed) | LIVE — Sentry+Stripe coexistence verified |

## §9 Remaining / out-of-scope

### §9.1 Manual items (operator-only)

- **Branch protection on `main`**: GitHub Settings → Branches → Add rule → require `test`, `coverage-check`, `validate-firestore-rules`, `detect-changed-paths` + allow squash + auto-merge. Currently NONE — every merge this session went straight in. Manual.
- **Sentry quota / inbound filters**: sentry.io project settings — set monthly spend cap, enable inbound filters (browser extensions, legacy browsers). Manual (UI-only).

### §9.2 Deferred / queued

- **PR #482 SF-021 widget_secrets exfil (Draft)** — still blocked on `WIDGET_SECRET_PEPPER` env-var preflight, unchanged. Reference [[widget-secrets-exfil-deploy-prereqs]].
- **PR #457 email-wrapper migration** — closed this session due to 7-file rebase conflict; needs hand resolution next session.
- **Phase B follow-up fields** (`refund_amount`, `refund_status`, `cancelled_by`) — audit/77 §7 suggested adding to denylist; out of scope per brief. Optional follow-up.

### §9.3 Historic local-branch backlog

48 unmerged local feature branches remain (squash-merged PRs leave the branch ungit-merged). Not in spec scope. Future cleanup: `git branch --no-merged origin/main` review + `gh pr list --state closed --search "head:<branch>"` cross-check before force-delete.

## §10 Commit graph this session

```text
main: 9a9cacca (start)
        → 9539b3e5  PR #503 stripe v22                    (STEP 1)
        → 57ba189e  PR #553 google_sign_in pin            (STEP 2)
        → 0bf9cb86  PR #554 firestore.rules Phase B       (STEP 6)
        → 0e2f16a7  docs CLAUDE.md + audit/50             (STEP 7)
```

PROD env state changed three times (full functions deploy in STEP 4, rules-only deploy ×2 in STEP 6 — once dev, once prod).

## §11 Lessons (auto-recover behavior under load)

- **`@emnapi/runtime` optional-dep stripping**: local `npm install` on macOS removes platform-specific optional deps that Linux cloud-build still expects from `package-lock.json`. Recovery: restore lock from `origin/main` before deploy. Audit/77 §8 already documented; reproduced this session.
- **GraphQL rate limit**: `gh` CLI uses GraphQL by default for `pr view` / `pr list` / `pr checkout`; once exhausted (5000/5000) wait was ~15 min. Workaround: switch entirely to REST `gh api /repos/.../pulls/{n}` + raw HTTP merge. Worked through the rest of the session with no GraphQL calls.
- **Background `&` vs `run_in_background`**: combining both makes the harness see exit-code-0 from the foreground wrapper while the real backgrounded process keeps running. Use one or the other.
- **CF status-machine diff() trap**: `update({status: <existing_value>})` produces empty `affectedKeys()` — passes the deny. Tests must use distinct values to exercise the deny path. Worth a comment in the rule file if Phase C revisits.

— END
