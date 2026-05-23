# Dependabot Triage — 2026-05-22

27 open dependabot branches classified against current versions in `pubspec.yaml` + `functions/package.json`. Spec said "APPROVE-AUTOMATIC: patch + minor bumps of utility packages" — but advisor flagged that the actual branch list contains multiple MAJOR bumps that would slip through a mechanical apply.

**No merges, closes, or branch deletes executed in this session** — see "Why deferred" below.

## Current versions (truth)

**`pubspec.yaml`:**
- `flutter_riverpod: ^2.5.1` (PINNED per memory — no 3.x)
- `freezed: ^2.5.8` (PINNED per memory — no 3.x)
- `intl: ^0.20.1`
- `url_launcher: ^6.3.1`
- `package_info_plus: ^8.1.2`
- `flutter_secure_storage: ^9.0.0`
- `flutter_launcher_icons: ^0.13.1`

**`functions/package.json`:**
- `firebase-admin: ^12.6.0`
- `firebase-functions: ^6.0.1`
- `firebase: ^10.14.1`
- `stripe: ^19.1.0`
- `@sentry/node: ^10.38.0`
- `eslint: ^8.57.0`
- `node-ical: ^0.24.2`
- `typescript: ^5.7.0`

## REJECT — close PR + delete branch (MAJOR bumps on locked / critical libs)

| Branch | Bump | Reason |
|---|---|---|
| `dependabot/pub/flutter_secure_storage-10.0.0` | 9 → 10 MAJOR | Credential storage; major bump needs hands-on verify |
| `dependabot/pub/package_info_plus-9.0.0` | 8 → 9 MAJOR | Per memory: "no major bumps without dev verify" |
| `dependabot/npm_and_yarn/functions/eslint-10.0.0` | 8.57 → 10 MAJOR | TypeScript-ESLint stack pinned to 8.x peer range |
| `dependabot/npm_and_yarn/functions/stripe-20.3.1` | 19.1 → 20 MAJOR | Per CLAUDE.md NIKADA NE MIJENJAJ: payment-critical path; user spec says INVESTIGATE stripe — actual delta is MAJOR, reject |

## INVESTIGATE — read diff, decide per branch

### GitHub Actions (3 — all major bumps to CI)

| Branch | Action |
|---|---|
| `dependabot/github_actions/actions/download-artifact-8` | Major action bump; v3/v4 to v8. Check workflow files for usage. |
| `dependabot/github_actions/actions/upload-artifact-7` | Same. Major action bumps can change input/output names. |
| `dependabot/github_actions/codecov/codecov-action-6` | Codecov v5/v6 deprecated tokens; verify token env still works. |

### Critical libraries

| Branch | Why |
|---|---|
| `dependabot/pub/sentry_flutter-9.13.0` | Sentry library — user spec INVESTIGATE rule + recent sentry env-tag work (see `audit/11-sentry-env-fix.md`). Verify no API breakage. |
| `dependabot/npm_and_yarn/functions/sentry/node-10.39.0` | Same project; verify minor delta 10.38 → 10.39 is API-stable. |
| `dependabot/npm_and_yarn/functions/node-ical-0.25.2` | iCal is CORE to BookBed (per memory iCal sync architecture). 0.24 → 0.25 = breaking under 0.x semver convention. Verify echo detection + hub-and-spoke flow not affected. |
| `dependabot/npm_and_yarn/functions/firebase-448532bdc8` | Group update (hash suggests multi-package). Read full diff before deciding. |

### Group updates (unknown contents until inspected)

| Branch | Notes |
|---|---|
| `dependabot/pub/multi-e1d748c033` | Hash = grouped update. `git log origin/<branch> -1 --stat` to enumerate. |
| `dependabot/npm_and_yarn/functions/multi-46e2463325` | Same. |

### Borderline minor

| Branch | Bump | Verdict |
|---|---|---|
| `dependabot/pub/flutter_launcher_icons-0.14.4` | 0.13 → 0.14 | 0.x minor = breaking per pub convention. Build icons locally + verify Android + iOS launcher assets unchanged. |
| `dependabot/npm_and_yarn/functions/protobufjs-7.6.0` | minor | Used transitively by firebase-admin. Check peer compat. |

## AUTO-MERGE candidates (transitive lockfile patches — likely npm-audit CVE fixes)

These are indirect deps where dependabot is raising lockfile-only updates. Safe in principle, but each merge still kicks CI and risks a transient test failure.

| Branch | Bump |
|---|---|
| `dependabot/npm_and_yarn/functions/ajv-6.15.0` | patch within 6.x |
| `dependabot/npm_and_yarn/functions/brace-expansion-2.1.0` | patch |
| `dependabot/npm_and_yarn/functions/fast-xml-parser-4.5.6` | patch within 4.x |
| `dependabot/npm_and_yarn/functions/flatted-3.4.2` | patch |
| `dependabot/npm_and_yarn/functions/handlebars-4.7.9` | patch within 4.x |
| `dependabot/npm_and_yarn/functions/lodash-4.18.1` | patch (verify — could be security) |
| `dependabot/npm_and_yarn/functions/minimatch-3.1.5` | patch within 3.x |
| `dependabot/npm_and_yarn/functions/minimatch-9.0.9` | patch within 9.x |
| `dependabot/npm_and_yarn/functions/node-forge-1.4.0` | minor (1.3 → 1.4) — verify if used by firebase-admin |
| `dependabot/npm_and_yarn/functions/path-to-regexp-0.1.13` | patch |
| `dependabot/npm_and_yarn/functions/picomatch-4.0.4` | minor transitive |
| `dependabot/npm_and_yarn/functions/protobufjs/utf8-1.1.1` | patch (nested) |

## Commands (for execution in a quiet window)

### Reject single branch + close PR
```bash
BRANCH="dependabot/pub/flutter_secure_storage-10.0.0"
PR_NUM=$(gh pr list --head "$BRANCH" --json number --jq '.[0].number')
gh pr close "$PR_NUM" --comment "Closed: major bump of locked credential-storage library. Re-evaluate manually when scheduled (see audit/18-dependabot-triage-2026-05-22.md)."
git push origin --delete "$BRANCH"
```

### Auto-merge single transitive (with CI watch)
```bash
BRANCH="dependabot/npm_and_yarn/functions/brace-expansion-2.1.0"
git fetch origin "$BRANCH":"$BRANCH"
git merge --no-ff "$BRANCH" -m "Merge dependabot: brace-expansion 2.1.0"
# Push and wait for CI BEFORE next merge
git push origin main
gh pr checks --watch
```

### Read group update contents
```bash
BRANCH="dependabot/pub/multi-e1d748c033"
git log origin/"$BRANCH" -1 --stat
git diff main..origin/"$BRANCH" -- pubspec.yaml
```

## Why deferred this session

1. **Multi-agent race:** Stash count grew 18 → 21 → 29 mid-session; `.git/index.lock` was held by sibling agent. Merging onto a divergent local main risks committing sibling's WIP into a dependabot merge commit.
2. **CI watch impractical:** Each auto-merge needs `gh pr checks --watch` (minutes) before the next. 12 transitive-only merges = 30–60 min sequential.
3. **Shared-state destructiveness:** `gh pr close` is visible to maintainers + dependabot. Per system instructions, batch confirm with user before closing 4 PRs.
4. **Spec mismatch:** User spec said "APPROVE-AUTOMATIC: patch + minor bumps of utility packages (intl, url_launcher, package_info_plus, etc)" — but `package_info_plus-9.0.0` is a MAJOR bump. Mechanical apply would have merged a major.

## Recommended sequencing

1. User reviews this doc, confirms REJECT list.
2. Quiet window (no sibling agents): close 4 REJECT branches.
3. Per-INVESTIGATE: open branch in PR UI, read diff, decide.
4. Auto-merge transitives in batches of 3-5, push + watch CI between batches.

## See also

- `audit/11-cloudfunctions-inventory.md` — CF cleanup tracking
- `audit/11-sentry-env-fix.md` — recent sentry env-tag fix
- `memory/multi-agent-git-race.md`

---

## Addendum 2026-05-22 — Execution decisions (4 MAJOR bumps)

User reviewed per-package and decided:

| PR | Package | Bump | Decision | Action |
|---|---|---|---|---|
| #270 | `stripe` | 19.1.0 → 20.3.1 | REJECT | Closed + remote branch deleted |
| #271 | `eslint` | 8.57.1 → 10.0.0 | REJECT | Closed + remote branch deleted |
| #240 | `flutter_secure_storage` | 9.2.4 → 10.0.0 | REJECT | Closed + remote branch deleted |
| #242 | `package_info_plus` | 8.3.1 → 9.0.0 | POSTPONE | PR open; revisit ≤ 2 weeks (by 2026-06-05) |

### Rationale

- **#270 stripe**: Payment-critical (NIKADA NE MIJENJAJ class — `CLAUDE.md`). 3 call sites: `functions/src/stripe.ts`, `functions/src/guestCancelBooking.ts`, `functions/src/stripePayment.ts`. v20 SDK has breaking type + API changes; cannot land in a dependabot merge. Revisit must include full checkout + webhook + Connect regression.
- **#271 eslint**: Project uses legacy `functions/.eslintrc.js` with `eslint-config-google` + `@typescript-eslint`. ESLint v9 **removed legacy config format entirely** (flat `eslint.config.js` required); `eslint-config-google` is unmaintained and has no v9+ port. Bump is a config-system rewrite, not a lint-rules bump. Defer to a dedicated migration task.
- **#240 flutter_secure_storage**: Auth-critical. 1 call site (`lib/core/services/secure_storage_service.dart`) — but v10 has native Android KeyStore behavior changes + iOS Keychain option changes. Auth regression scope (Remember Me, login persistence, FCM token re-issue, Apple/Google Sign-In on iOS + Android) too wide for a dependabot merge.
- **#242 package_info_plus**: 1 call site (`lib/core/services/version_check_service.dart`); low surface area. Postponed (not rejected) pending the next dev-build verification window — memory pin "no major without dev verify" requires explicit smoke test.

### Revisit triggers

- **#242 package_info_plus**: Re-evaluate at next dev-build window. If no window by **2026-06-05**, escalate to close (will re-open via new dependabot ping later).
- **#270 / #271 / #240**: Closed; reopen via new dependabot ping after upstream changelog stabilizes or as part of a dedicated migration PR (Stripe payments maintenance / ESLint flat-config / secure_storage auth regression).

---

## Addendum 2026-05-23 — Transitive batch execution (12 PRs)

12 transitive utility bumps from AUTO-MERGE list resolved during `/effort max` cleanup session.

### Merged (11) — squash + delete-branch

Each batch validated locally (`flutter analyze` = 0, `npm run build` = 0) before next batch.

| PR | Package | Bump | Batch | Commit on main |
|---|---|---|---|---|
| #412 | `@protobufjs/utf8` | 1.1.0 → 1.1.1 | 1 | `d44d862a` |
| #415 | `brace-expansion` | 1.1.12 → 2.1.0 | 1 | `51e44966` |
| #416 | `minimatch` | 3.1.2 → 9.0.9 | 1 | `2f9291ef` |
| #414 | `picomatch` | 2.3.1 → 4.0.4 | 2 | `a3554231` |
| #369 | `ajv` | 6.12.6 → 6.15.0 | 3 | `42621796` |
| #327 | `fast-xml-parser` | 4.5.3 → 4.5.6 | 3 | `aa81eab6` |
| #328 | `lodash` | 4.17.23 → 4.18.1 | 3 | `fe547ae1` |
| #309 | `flatted` | 3.3.3 → 3.4.2 | 4 | `867a071e` |
| #314 | `handlebars` | 4.7.8 → 4.7.9 | 4 | `aaa21df0` |
| #316 | `node-forge` | 1.3.3 → 1.4.0 | 4 | `57e7b244` |
| #319 | `path-to-regexp` | 0.1.12 → 0.1.13 | 5 | `81421bfc` |

### Closed (1) — superseded

| PR | Package | Bump | Reason |
|---|---|---|---|
| #281 | `minimatch` | 3.1.2 → 3.1.5 | Superseded by #416 (already at 9.0.9). Remote branch deleted. |

### CI observations

- **Pre-existing failure on main**: `Run Tests` / `Test Cloud Functions` / `Validate Firestore Rules` jobs were already failing on main since `ac225b3d` (2026-05-22 16:49Z), unrelated to these merges. All 11 PRs had SUCCESS on those jobs at PR time.
- **Build Web Widget orphan**: Workflow is SKIPPED on main but appears as FAILURE on dependabot PRs. Treated as orphan (real test jobs were green). Merged anyway.
- **Mergeable computation lag**: After main churn, GitHub returned `UNKNOWN UNKNOWN` mergeable state for ~20s before recomputing — wait then re-check.
- **Multi-agent race observed**: Local branch flipped mid-session by sibling agent (`refactor/booking-widget-phase1`); recovered via `git checkout main`. Two new stashes appeared during execution. Per `memory/multi-agent-git-race.md`.

### Remaining open dependabot PRs (post-batch)

After this execution, the queue is:
- **INVESTIGATE** (untouched, still need manual diff review): #320 codecov-action, #285/#286 download/upload-artifact, #274 sentry_flutter, #272 @sentry/node, #273 node-ical, #413 firebase group, #275 pub multi, #276 multi npm, #238 flutter_launcher_icons, #417 protobufjs
- **POSTPONE** (date-gated): #242 package_info_plus (revisit ≤ 2026-06-05)
