# Archived: remote branch cleanup & salvage — 2026-07-09

Swept GitHub remote **249 → 24 non-main branches**. Record of what was salvaged vs deleted so the knowledge survives the branches.

## Salvaged → PRs
- **#835** salvage/cleanup-quick-wins — secure-random session ID (`Math.random`→`randomUUID`), VAPID env keys, doc-HTML escape, unused import
- **#836** salvage/perf-n1 — 6 perf fixes: N+1 batching (iCal repo, notification service, scheduled push, biweekly summary), RegExp log redaction, dashboard `DateTime.utc` keys + weekly-date bug
- **#837** salvage/features — subscription-tier wiring + suspicious-activity email infra (dead until a trigger CF)

## Deleted (~225)
199 merged/closed (squash-merged → in main, or rejected) + 15 redundant-arg lint bots + 9 salvaged-source branches.

## Key trap (see memory `bot-pr-branch-hygiene`)
Jules bot branches bundle a hardcoded API key + `.gitguardian.yml` deletion + stripe/firebase_storage downgrade with the one real change → **cherry-pick the single real SHA, never merge**; scan the result. Squash-merge makes git-ancestry "unmerged" a lie → classify by `gh pr --state all`.

## Deferred
- Twilio SMS (#804) — touches FROZEN `atomicBooking.ts`, needs operator GO.
- 6 test-adding PRs — real coverage but Jules-contaminated; salvage by cherry-pick if wanted.
- Dependabot majors + serial-conflict lockfile bumps.
