# audit/88 — Branch hygiene inventory

**Date**: 2026-05-29
**Action policy**: documentation only. NO branches deleted. Awaiting user per-batch approval.

---

## Headline

| Scope | Count |
|---|---|
| **Total refs** (local + remote) | 119 |
| Local branches | 58 |
| Remote `origin/*` branches | 60 (− 1 main = 59 feature) |
| Active worktrees | 4 (`main`, `auto/web-bughunt-0529`, `auto/ios-smoke-0529`, `auto/android-sf-verify-0529`) |
| Open PRs | 1 (`hotfix/widget-secrets-exfil` → #482) |

---

## ⚠️ Protected — NEVER DELETE

| Branch | Reason |
|---|---|
| `main` | trunk |
| `hotfix/widget-secrets-exfil` (local + remote) | Open PR #482, prereq-blocked, but live |
| `auto/web-bughunt-0529` (local + remote, NOT merged but worktree) | Active background agent A |
| `auto/ios-smoke-0529` (local + remote, merged-into-main but worktree) | Active background agent B |
| `auto/android-sf-verify-0529` (local + remote, merged-into-main but worktree) | Active background agent C |

⚠️ The two `auto/ios-smoke-0529` + `auto/android-sf-verify-0529` are reported by `git branch --merged main` (they sit at `ed31ae47` — same SHA as main, because the agents haven't pushed work yet). **Do NOT delete** despite "merged" status; they are linked to live worktrees. A worktree-linked branch delete returns the agents' `HEAD` to nothing.

---

## REMOTE — merged into `origin/main` (safe-delete candidates after user approval)

All 12 below have PRs already MERGED into main. Source-branch retention serves no purpose; orphan refs.

```
origin/docs/audit-53-prod-stripe-key-name-leak
origin/docs/audit-60-61-stripe-consolidation
origin/fix/f-62-01-logout-confirmation       (PR #532, audit/65 batch)
origin/fix/f-62-03-logout-clear-remember-me  (PR #533, audit/65 batch)
origin/fix/f-63-04-chip-row-overflow         (PR #535, audit/65 batch)
origin/fix/f-64-04-html-lang                 (PR #534, audit/65 batch)
origin/fix/f-67-01-booking-confirm-reject    (audit/67 → audit/77 Phase A)
origin/fix/f-67-02-guest-name
origin/fix/f-67-03-widget-form-leak
origin/fix/f-67-05-ical-error-leak
origin/fix/f-70-01-stripe-ipv4-egress        (PR #541, audit/74)
origin/fix/owner-cancel-booking
```

### Suggested delete batch (user must approve)

```bash
# Per-branch — sequential, branch-guard prerequisite
for b in \
  docs/audit-53-prod-stripe-key-name-leak \
  docs/audit-60-61-stripe-consolidation \
  fix/f-62-01-logout-confirmation \
  fix/f-62-03-logout-clear-remember-me \
  fix/f-63-04-chip-row-overflow \
  fix/f-64-04-html-lang \
  fix/f-67-01-booking-confirm-reject \
  fix/f-67-02-guest-name \
  fix/f-67-03-widget-form-leak \
  fix/f-67-05-ical-error-leak \
  fix/f-70-01-stripe-ipv4-egress \
  fix/owner-cancel-booking; do
  echo "Delete origin/$b?"
  read -r confirm && [[ "$confirm" == "yes" ]] && git push origin --delete "$b"
done
```

---

## REMOTE — NOT merged (manual review per branch)

47 remote branches. Many likely candidates for archival (work landed via different branch or superseded). Grouped by suspected disposition:

### Likely superseded — verify-then-delete

```
origin/audit/f-50-01-allowlist-smoke-script       # F-50-01 closed via PR #481 (audit/38)
origin/chore/audit-50-f-50-05a-undici-override    # F-50-05a not pursued
origin/chore/cherry-pick-jules-security-fixes     # jules sprint folded into hotfix/* branches
origin/docs/audit-49-post-merge-smoke             # docs landed in main via direct commits
origin/docs/audit-53-stripe-name-leak             # superseded by audit-53 PROD closure
origin/fix/audit-33-har-followups                 # closed in audit/33 §11.4
origin/fix/audit-38-security-sprint               # closed via PR #481
origin/fix/f-50-02-login-attempts-server-side     # closed via PR #517 SF-050
origin/fix/f-50-04-error-stack-scrub              # closed via PR #495
origin/fix/f-50-04-error-stack-scrub-v2           # same — v2 likely abandoned
origin/fix/sentry-dsn-env-var-to-main             # closed via PR #515 audit/54
origin/fix/sf-vibe57-cf                           # closed via PR #527
origin/fix/sf-vibe57-hosting                      # closed via PR #528
origin/fix/sf-vibe57-rules                        # closed via PR #526
origin/hotfix/role-escalation-deploy-unblock      # closed via PR #481 (a847497e)
origin/hotfix/security-sprint-sf-038-046-047-048  # CFs already deployed
```

### Likely active or carry-forward — DO NOT delete without owner sign-off

```
origin/hotfix/widget-secrets-exfil                # PROTECTED — PR #482
origin/ops/dependabot-503-stripe-22-adapt         # audit/78 PR #503 status TBD
origin/chore/pin-google-signin-6                  # PR #553 — recently MERGED, may be safe (verify)
origin/ops/appcheck-client-init                   # PR #560 — recently MERGED, may be safe (verify)
origin/ops/auth-pii-logout                        # PR #558 — recently MERGED, may be safe (verify)
origin/ops/cors-allowlist                         # PR #559 — recently MERGED, may be safe (verify)
origin/ops/csp-hosting                            # PR #557 — recently MERGED, may be safe (verify)
origin/ops/rules-tighten-phase-a-complete-edit-cf # PR #549 — recently MERGED, may be safe (verify)
origin/ops/rules-tighten-phase-b                  # PR #554 — recently MERGED, may be safe (verify)
origin/ops/sentry-fix-b-price-tier                # PR #555 — recently MERGED, may be safe (verify)
origin/ops/sentry-fix-c-auth-recoverable          # PR #556 — recently MERGED, may be safe (verify)
origin/ops/test-coverage-expansion                # PR #551 — recently MERGED, may be safe (verify)
origin/ops/a11y-perf-sweep                        # PR #550 — recently MERGED, may be safe (verify)
origin/ops/visual-qa-sweep                        # PR #552 — recently MERGED, may be safe (verify)
origin/ops/ci-path-filter                         # PR #548 — recently MERGED, may be safe (verify)
origin/redesign/00-design-system-foundation       # PR #542 — recently MERGED, may be safe (verify)
origin/redesign/00b-token-consolidation           # PR #543 — recently MERGED, may be safe (verify)
origin/redesign/01-responsive-harness             # PR #547 — recently MERGED, may be safe (verify)
origin/redesign/02-localization-sweep             # PR #546 — recently MERGED, may be safe (verify)
origin/redesign/2a-token-codemod                  # PR #544 — recently MERGED, may be safe (verify)
origin/redesign/2b-app-theme-inter                # PR #545 — recently MERGED, may be safe (verify)
origin/test/audit-38-pr481-regression-tests       # PR may have been closed without merge
```

> Note: "recently MERGED" entries should be safe to delete (their PR is closed-merged), but `git branch -r --merged origin/main` did NOT pick them up. Possible cause: PRs were squash-merged or rebase-merged, so the source-branch tip SHA is NOT an ancestor of main. The work landed; the branch tip is orphaned. Cross-check via `gh pr view <PR#> --json mergedAt,mergeCommit` before deleting.

### Investigation — needs owner check

```
origin/chore/add-crlf-guard-email                 # status unknown
origin/chore/migrate-email-templates-through-wrapper  # V2 wrapper — V2 migration MERGED, branch may be orphan
origin/chore/test-debt-cleanup-audit-19           # audit/19 wave 3 cleanup
origin/doc/audit-35-followups                     # audit/35 closure
origin/docs/audit-52-p3-deferral                  # audit/52 status
origin/docs/sf-049-dev-webhook-secret-postmortem  # SF-049 docs
origin/docs/sf-vibe57-rollup                      # vibe57 rollup
origin/fix/audit-33-deploy-contamination          # closed via merge — verify
origin/fix/onUnitDeleted-property-widget-settings # status unknown
origin/fix/quick-wins-sf-039-040-maps-piilogs     # SF-039/040
origin/fix/security-audit-followup-9-findings     # status unknown
origin/investigate/finding-ios-02                 # closed via audit/40 — safe-delete candidate
origin/smoke/audit-65-integration                 # audit/65 work
```

---

## LOCAL — NOT merged (55 branches)

Mirror of remote-NOT-merged set plus a few never-pushed locals:

```
audit/f-50-01-allowlist-smoke-script
claude-md-compress                                # likely never-pushed local experimental
docs/audit-28-spf-5.3-fill
fix/audit-28-auth-d7-reset-url-env-derived
fix/audit-33-deploy-contamination
fix/audit-33-har-followups
fix/seed-checkin-field-name                       # NOT pushed per memory/seed-bookbed-dev-checkin-field.md
... (rest mirror remote)
```

`fix/seed-checkin-field-name` is documented in memory as worktree-only / NOT pushed (audit/40 finding). Verify before delete; the audit doc references the SHA `be93449a`.

`claude-md-compress` looks like ephemeral local work.

### Suggested local cleanup batch (user must approve)

```bash
# Safety prefix
git checkout main && git status

# Branch-by-branch — for each, verify HEAD SHA matches remote OR is in main history
for b in $(git branch | grep -vE '^\*|main$|auto/|hotfix/widget-secrets-exfil'); do
  b=$(echo "$b" | xargs)
  remote_sha=$(git rev-parse "origin/$b" 2>/dev/null || echo NONE)
  local_sha=$(git rev-parse "$b" 2>/dev/null || echo NONE)
  if [[ "$remote_sha" == "NONE" ]]; then
    echo "LOCAL-ONLY: $b — needs manual check (may have unpushed work)"
  elif [[ "$remote_sha" == "$local_sha" ]]; then
    echo "SAFE-DELETE: $b — local matches origin"
  else
    echo "DRIFT: $b — local=$local_sha origin=$remote_sha"
  fi
done
```

This identifies drift (don't auto-delete) vs LOCAL-ONLY (may have unpushed audit-history) vs SAFE-DELETE (mirror of remote, will still exist on origin).

---

## Cross-reference

- [audit/51 final cleanup summary](./51-final-cleanup-summary-2026-05-25.md) — previous 42→11 PR / 44→18 local sweep; baseline for delta
- [memory/seed-bookbed-dev-checkin-field.md](../memory/seed-bookbed-dev-checkin-field.md) — `fix/seed-checkin-field-name` audit retention
- Active worktree set documented in `git worktree list`

---

## Sign-off

12 remote branches qualify for immediate delete (merged into main). 47 remote branches need triage (squash-merge orphans vs abandoned). 55 local branches need drift-vs-mirror cross-check. Worktree-linked branches (auto/web/ios/android-0529) protected.

Action gate: per-batch user approval. No deletes performed.
