# audit/75 — Merge Session (10 PRs to main, PROD CF deploy halted)

**Date:** 2026-05-28
**Session:** Terminal J
**Pre-merge main HEAD:** `ceaad693` (`chore(deps): bump graphic from 2.6.0 to 2.7.0 (#525)`)
**Post-merge main HEAD:** `02181ad3` (`Merge pull request #540 …`)
**Result:** 10/10 merged green, PROD deploy **HALTED awaiting `go prod cf`**.

## §1 Merge Log

| Order | PR | Title | Mergeable | Rebase needed? | Post-merge analyze | Post-merge flutter test | Post-merge CF (build/test/rules) |
|---|---|---|---|---|---|---|---|
| 1 | #531 | docs(audit): SF-051 closure + webhook coverage + Stripe model fix | UNKNOWN→OK | no | 2 pre-existing info, 0 new | 1205/1205 | n/a (docs) |
| 2 | #534 | fix(a11y): add lang=hr to web/index.html (F-64-04) | OK (ff) | no | 0 new | 1205/1205 | n/a |
| 3 | #535 | fix(ui): wrap filter chip rows for large font scale (F-63-04) | OK | no | 0 new | 1205/1205 | n/a |
| 4 | #537 | fix(bookings): display guest first+last name instead of Unknown Guest (F-67-02) | OK | **#536 dragged in via stack** | 0 new | 1205/1205 | build clean, 317/317, rules ok |
| 4b | #536 (auto) | fix(bookings): approve/reject CF (F-67-01 P1) | stacked under #537 | merged transitively | (combined w/ #537) | (combined) | (combined) |
| 5 | #538 | fix(widget): stop persisting special requests + tighten draft TTL (F-67-03) | OK | no | 0 new | 1205/1205 | n/a |
| 6 | #539 | fix(ical): sanitize sync error message (F-67-05) | OK | no | 0 new | 1205/1205 | build clean, 318/318 (+1 new), rules ok |
| 7 | #532 | fix(auth): logout confirmation dialog (F-62-01) | OK | no | 0 new | 1205/1205 | n/a |
| 8 | #533 | fix(auth): clear saved email + rememberMe on explicit logout (F-62-03) | OK | no (clean against merged #532) | 0 new | 1205/1205 | n/a |
| 9 | #540 | fix(bookings): owner-cancel CF + refund (F-67-01 sibling) | OK | no (worktree-only conflict, resolved with `git checkout --`) | 0 new | 1205/1205 | build clean, 318/318, rules ok |

**Stacked-pair note:**
- #536 was stacked under #537 (`fix/f-67-02-guest-name` was branched from `fix/f-67-01-booking-confirm-reject`). When #537 merged via merge-commit, the #536 commit (`ca309fe2`) came along in the same fast-forwarded chain. GitHub auto-closed #536 as MERGED. No separate `gh pr merge 536` needed.
- #540 was stacked under #536. After #536's content landed via #537, #540 merged cleanly against the new main HEAD — no rebase required.

**Worktree-only friction (not a PR issue):**
- `gh pr merge 540` succeeded on GitHub but `git pull --ff-only` failed locally twice:
  1. Untracked `functions/src/utils/bookingRefund.ts` in worktree (leftover from a Terminal G branch-swap earlier in session) — removed with `rm`.
  2. Modified `functions/src/guestCancelBooking.ts` in worktree (same leftover) — discarded via `git checkout -- …`. The discarded content was exactly what #540 brings in.

After cleanup, `git pull --ff-only` advanced cleanly.

## §2 Integration Issues Surfaced

**None.** No regressions when combining branches:

- #532 + #533 both touched `lib/features/auth/.../profile_screen.dart` and `enhanced_auth_provider.dart`. Because #533 was branched from the #532 tip, the merges composed without textual conflicts; the integrated logout flow compiles, tests stay green.
- #536 + #540 both edited `functions/src/bookingActions.ts`. #540 was branched from #536, so the generalized loader (`loadOwnedBookingForAction`) introduced by #540 supersedes #536's `loadOwnedPendingBooking` cleanly; CF build + 318 unit tests + 39 rules tests pass on integrated main.
- The `processStripeRefund` helper from #540 is consumed by both `guestCancelBooking` (refactored) and the new `cancelBooking` callable. Both compile + test as expected against the integrated tree.

## §3 Final Integrated Verification — main @ `02181ad3`

```
$ flutter analyze
  info • The value of the argument is redundant because it matches the default value
        • lib/core/services/rate_limit_service.dart:167:22 • avoid_redundant_argument_values
  info • Angle brackets will be interpreted as HTML
        • lib/core/utils/web_utils_web.dart:349:51 • unintended_html_in_doc_comment
2 issues found. (0 NEW, both pre-existing pre-#531)

$ flutter test --no-pub
All tests passed!  →  1205 / 1205

$ cd functions && npm run build
tsc → clean

$ npm test
Test Suites: 14 passed, 14 total
Tests:       318 passed, 318 total
(was 317 pre-#539; #539 added 1 ical-error sanitization test)

$ npm run test:rules
firestore_rules: ✔ Script exited successfully (code 0)
39/39 passed
```

## §4 PROD Deploy — HALTED

**Per brief: HALT before any PROD action. Await explicit `go prod cf`.**

### CFs that need PROD deploy

| CF | Source PR | Status on PROD pre-deploy |
|---|---|---|
| `syncIcalFeedNow` (us-central1) | #539 | exists; this is a behaviour update (error-message sanitization + new test) |
| `approveBooking` (europe-west1) | #536 | **NEW** — doesn't exist on PROD |
| `rejectBooking` (europe-west1) | #536 | **NEW** — doesn't exist on PROD |
| `cancelBooking` (europe-west1) | #540 | **NEW** — doesn't exist on PROD |
| `guestCancelBooking` (us-central1) | #540 | exists; this is the refactor that delegates refund to the shared `processStripeRefund` helper. Behaviour preserved (CF unit tests 317→318 green post-refactor). |

The shared util `functions/src/utils/bookingRefund.ts` (new file from #540) is **not a separately-named deploy target** — it ships with whichever CF imports it. Both `cancelBooking` and `guestCancelBooking` import it; deploying either pulls the helper in.

### Proposed deploy command (NOT EXECUTED — awaiting auth)

```
firebase deploy --only \
  functions:syncIcalFeedNow,\
functions:approveBooking,\
functions:rejectBooking,\
functions:cancelBooking,\
functions:guestCancelBooking \
  --project rab-booking-248fc
```

No `--force`. Per audit/06 canonical order is CF → widget bundle → rules; this PR set only touches CF, so the deploy ends at CF.

### Pre-flight checks to run before deploy (not yet executed)

1. **PROD env file** — verify `functions/.env.rab-booking-248fc` exists and has `SENTRY_DSN=…` (Terminal G found dev deploy blocked without it; same will happen on PROD).
2. **In-flight payments** — quick read on Stripe LIVE `payment_intents` (last 60 min) — defer the deploy if non-zero.
3. **Worktree clean** — confirm no untracked / modified files on main pre-deploy. There are still leftover Terminal H worktree mods present; `git stash -u` them before the deploy to avoid `firebase deploy` picking up stray files.

### Post-deploy CRITICAL — IAM `allUsers` invoker

The Terminal G dev deploy found that **fresh `onCall` callables in `europe-west1` did not get the auto-granted `allUsers` `roles/run.invoker` binding** from Firebase deployer. This will likely repeat on PROD for `approveBooking`, `rejectBooking`, `cancelBooking`. Without the binding, every Firebase callable invocation from the app gets a 401 from Cloud Run's IAM layer **before** the function-level auth check runs.

Verification script (read-only, safe to run anytime):

```
for CF in approveBooking rejectBooking cancelBooking; do
  gcloud run services get-iam-policy "$CF" \
    --region=europe-west1 --project=rab-booking-248fc 2>&1 \
    | grep -q allUsers \
    || echo "MISSING invoker binding: $CF"
done
```

If `MISSING invoker binding:` lines appear, the fix per CF (still gated on `go iam`):

```
gcloud run services add-iam-policy-binding "$CF" \
  --region=europe-west1 --member=allUsers \
  --role=roles/run.invoker --project=rab-booking-248fc
```

`syncIcalFeedNow` is `us-central1` (audit/61) and already had its IAM set — no re-grant needed. `guestCancelBooking` is `us-central1`, also an update (not new) — IAM untouched.

### Post-deploy smoke (read-only, non-destructive)

- Reachability probe: anonymous POST to each new CF → expect `401 {error.status:"UNAUTHENTICATED"}` (NOT `404` and NOT GFE-401 HTML). Confirms function-level auth fires (i.e. IAM binding is in place).
- Egress: F-70-01 IPv4-egress fix is **Terminal I's separate stream**; this session does not touch that. Whatever PROD egress state exists today is what PROD continues with.
- **DO NOT** approve / cancel a real PROD booking as a smoke test. Code-review parity with the dev smoke (audit/69 §3 + audit/72 §3) covers behaviour; the prod probe only confirms reachability.

## §5 PROD Post-deploy Smoke

— **NOT YET EXECUTED.** Will be performed only after `go prod cf`.

## §6 What's Deployed to PROD vs Main-only After This Session

| Surface | Main (`02181ad3`) | PROD CF | PROD hosting (owner/widget/admin) |
|---|---|---|---|
| App code (#532, #533, #535, #537, #538) | ✓ | n/a | **MAIN-ONLY** — needs separate hosting deploy |
| Web index lang=hr (#534) | ✓ | n/a | **MAIN-ONLY** — hosting deploy |
| Audit docs (#531) | ✓ | n/a | n/a |
| CF changes (#539, #536, #540) | ✓ | **PENDING** — gated on this session's `go prod cf` | n/a |

App + hosting deploy for #532 / #533 / #534 / #535 / #537 / #538 is **out of scope for this session** (Terminal J is CF-deploy only). Tracked as carryover in §7.

## §7 Remaining Follow-ups

1. **Hosting deploy** (owner + widget + admin) for the app/web changes from #534 / #535 / #532 / #533 / #537 / #538. Use `tool/deploy-dev.sh <surface>` for dev re-verification, then PROD via `firebase deploy --only hosting:<target> --project rab-booking-248fc`.
2. **F-70-01 egress** — Terminal I owns; do not touch from this session.
3. **F-70-02 Stripe Support** — payment flow still blocked on customer-action with Stripe (separate workstream).
4. **IAM invoker** — see §4 post-deploy. Likely needed for all three new callables.
5. **`bookingActions.test.ts` jest suite** — captured as follow-up in audit/72 §7. Approve / reject / cancel currently rely on dev smoke as the only regression guard.
6. **Worktree hygiene** — `bookbed-g-cancel` worktree from Terminal G still on disk (`/Users/duskolicanin/git/bookbed-g-cancel`). Safe to `git worktree remove --force` after this session ends, since the PR has merged.
7. **Stale `M` worktree mods on main** — Terminal H + earlier carryover left `M CLAUDE.md`, `M ios/Podfile.lock`, `M ios/Runner/GoogleService-Info.plist`, `M pubspec.lock`, and `M audit/50-…md` showing in `git status` on main post-session. None of these are this session's work; flag for whichever terminal owns them to commit or discard.
