# audit/81 — CI path-filter: skip heavy jobs on design/audit/docs-only PRs

**Date:** 2026-05-29
**Branch:** `ops/ci-path-filter`
**Author:** Claude (Opus 4.7)
**Scope:** `.github/workflows/ci.yml` only

## Why

The 40-prompt redesign series (audit/80*, design-token codemods, primitive
refactors) touches only `lib/core/design/**`, `audit/**`, `docs/**`, `memory/**`,
`.claude/**`, or root-level `*.md`. Every such PR currently triggers the full
CI graph including `build-android` (AAB build, 30-min cap, ~11 min wall time)
and `build-web` (15-min cap). For the redesign series this is wasted spend with
no risk reduction — those changes cannot break Android binary linkage or the
Flutter web bundle.

Estimated savings: **~11 min wall × ~30 redesign-only PRs ≈ ~5.5 h CI**. Per-PR
savings are bounded by the longest skipped heavy job (build-android), not the
sum of all skipped jobs, because GitHub Actions runs the graph in parallel.

## Required-status-check audit

`gh api repos/DanLika/rab_booking/branches/main/protection` returns
`{"message":"Branch not protected","status":"404"}`. **No required status
checks exist on `main`.** Therefore no refactor is needed to preserve required
check names. Heavy jobs become "skipped" not "succeeded" when gated off, but
since nothing depends on them being green, that's harmless.

**Future-proofing:** if branch protection is enabled later, do NOT mark
`Build Android AAB`, `Build Web Widget`, `Test Cloud Functions`, or
`Check Bundle Size` as required checks. They legitimately skip on design-only
PRs. The check names that ARE safe to require:
- `Run Tests` (always runs)
- `Check Code Coverage` (always runs, `needs: test`)
- `Validate Firestore Rules` (always runs)
- `Detect Changed Paths` (always runs)

## PR-base sanity check

`gh pr list --state all --limit 50 --json baseRefName` → 50/50 PRs base = `main`.
Workflow trigger `pull_request: branches: [main, develop]` covers every active
PR. No integration-branch workflow gap.

## Modified workflows

| File | Change | Reason |
|---|---|---|
| `.github/workflows/ci.yml` | Added `detect-changes` job; gated `build-web`, `build-android`, `test-functions` | Skip heavy builds on design/audit/docs-only PRs |
| `.github/workflows/deploy-widget.yml` | UNCHANGED | Already path-scoped to `lib/**`, `web/**`, `pubspec.yaml`. Token deploys ship via `lib/core/design/**` ⊂ `lib/**` → correct that this still runs on design-only commits to main |
| `.github/workflows/firestore-rules-drift.yml` | UNCHANGED | Cron + manual + PR-scoped to `firestore.rules`. Out of scope. |

## Job decision matrix

| Job | Gated? | Filter | Rationale |
|---|---|---|---|
| `detect-changes` (new) | n/a | always runs | Sets `heavy` + `functions` outputs |
| `test` (analyze + format + unit + coverage upload) | **NO** | always runs | User explicit: analyze/test catch breakage on every PR |
| `build-web` | YES | `heavy == 'true'` | Builds Flutter web bundle; design-only PRs don't ship a new bundle from CI (deploy-widget on push handles that) |
| `build-android` | YES | `heavy == 'true'` | AAB build, 30-min cap, primary cost target |
| `test-functions` | YES | `functions == 'true'` | Pure Cloud Functions scope; `lib/**` changes can't break TS tests |
| `bundle-size` | cascade | `needs: build-web` → auto-skip when build-web skips | GitHub Actions treats a skipped `needs:` as unsatisfied → bundle-size skips. Intentional. |
| `coverage-check` | **NO** | always runs (`needs: test`) | Re-runs flutter test for coverage; user explicit: don't gate |
| `validate-firestore-rules` | **NO** | always runs | <1 min, low cost, catches `if true` regressions |

## Filter definition

```yaml
filters: |
  heavy:
    - 'lib/**'
    - '!lib/core/design/**'   # negation: design changes alone do NOT trigger heavy
    - 'web/**'
    - 'firestore.rules'
    - 'storage.rules'
    - 'pubspec.yaml'
    - 'pubspec.lock'
    - 'android/**'
    - 'ios/**'
    - 'tool/**'               # tool/build_aab.sh controls AAB build
    - '.github/workflows/**'  # meta-trap guard: workflow edits re-run heavy
  functions:
    - 'functions/**'
    - '.github/workflows/**'
```

## Truth table — expected behavior

| PR touches | `heavy` | `functions` | `build-android` | `build-web` | `test-functions` | `bundle-size` |
|---|---|---|---|---|---|---|
| `audit/foo.md` only | false | false | **SKIP** | SKIP | SKIP | SKIP (cascade) |
| `docs/bar.md` only | false | false | **SKIP** | SKIP | SKIP | SKIP (cascade) |
| `memory/baz.md` only | false | false | **SKIP** | SKIP | SKIP | SKIP (cascade) |
| `.claude/rules/x.md` only | false | false | **SKIP** | SKIP | SKIP | SKIP (cascade) |
| `README.md` only (root *.md) | false | false | **SKIP** | SKIP | SKIP | SKIP (cascade) |
| `lib/core/design/tokens.dart` only | false | false | **SKIP** | SKIP | SKIP | SKIP (cascade) |
| `lib/core/design/tokens.dart` + `lib/foo/bar.dart` | **true** | false | RUN | RUN | SKIP | RUN |
| `lib/foo/bar.dart` only | **true** | false | RUN | RUN | SKIP | RUN |
| `functions/src/x.ts` only | false | **true** | SKIP | SKIP | RUN | SKIP (cascade) |
| `firestore.rules` only | **true** | false | RUN | RUN | SKIP | RUN |
| `pubspec.lock` only (dep bump) | **true** | false | RUN | RUN | SKIP | RUN |
| `android/app/build.gradle.kts` only | **true** | false | RUN | RUN | SKIP | RUN |
| `ios/Runner.xcodeproj/project.pbxproj` only | **true** | false | RUN | RUN | SKIP | RUN |
| `tool/build_aab.sh` only | **true** | false | RUN | RUN | SKIP | RUN |
| `.github/workflows/ci.yml` only | **true** | **true** | RUN | RUN | RUN | RUN |
| Mixed: `audit/x.md` + `functions/y.ts` | false | **true** | SKIP | SKIP | RUN | SKIP (cascade) |
| Empty diff (re-run all on same SHA) | dorny default → **true** | dorny default → **true** | RUN | RUN | RUN | RUN |
| New branch first push, no base | dorny default → **true** | dorny default → **true** | RUN | RUN | RUN | RUN |

`test`, `coverage-check`, `validate-firestore-rules` row column omitted —
always RUN regardless.

### Cascade nuance

`bundle-size: needs: build-web`. When `build-web`'s `if:` evaluates false, the
job is marked **"skipped"**, not "succeeded". GitHub Actions treats a skipped
`needs:` as unsatisfied → `bundle-size` is also skipped automatically. No
explicit gate needed. If a future change wants bundle-size to ALWAYS run, it
must drop `needs: build-web` and download the artifact conditionally.

### Negation semantics

`dorny/paths-filter` evaluates rules in order with later patterns overriding
earlier ones. A file like `lib/core/design/tokens.dart`:
1. Matches `lib/**` → tentatively included
2. Matches `!lib/core/design/**` → excluded
3. Final: NOT in `heavy`

A mixed PR with `lib/core/design/tokens.dart` + `lib/foo/bar.dart`:
- `tokens.dart` → excluded (above)
- `bar.dart` → matches `lib/**`, no exclusion applies → included
- Any included file → `heavy=true`

This is the "design + real code" mixed PR case in the truth table.

## Verification

Static YAML check:
```
ruby -ryaml -e 'd = YAML.load_file(".github/workflows/ci.yml"); puts "OK jobs: #{d["jobs"].keys.join(", ")}"'
→ OK jobs: detect-changes, test, build-web, build-android, test-functions, bundle-size, coverage-check, validate-firestore-rules
```

Per-job gate parse-check:
```
build-web needs: ["test", "detect-changes"]  if: "needs.detect-changes.outputs.heavy == 'true'"
build-android needs: ["test", "detect-changes"]  if: "needs.detect-changes.outputs.heavy == 'true'"
test-functions needs: "detect-changes"  if: "needs.detect-changes.outputs.functions == 'true'"
```

Live verification: ship this PR + open the next design-only PR (e.g.
audit/80-series follow-up). In the Actions UI, build-android should appear
greyed "Skipped" while test + coverage-check + validate-firestore-rules go
green. If it runs anyway, the path filter is misconfigured — check the dorny
action output in the `detect-changes` job log.

## Estimated savings

Per-PR savings (wall-clock, longest skipped heavy job dominates):
- Design/audit/docs-only PR: **~11 min** (build-android) + ~10 min (build-web,
  test-functions, bundle-size run in parallel with build-android so partial
  overlap; conservative wall savings = build-android time)

Series-level (40-prompt redesign):
- 30 design-only PRs × ~11 min = **~5.5 h CI runner time saved**
- Plus reduced GitHub Actions minute consumption on private-repo billing

## Out of scope (not changed)

- `deploy-widget.yml` — already path-filtered to `lib/**`/`web/**`/`pubspec.yaml`;
  design changes DO ship via this path post-merge (correct)
- `firestore-rules-drift.yml` — cron + PR-on-rules-only (correct)
- Disabled jobs (build-ios, security-scan, codeql-analysis) — unchanged
- Workflow caching strategy — separate optimization
- Splitting `test` into faster format-only sub-job — separate optimization

## Hard rules respected

- ✓ analyze/test (`test` job) always runs
- ✓ `.github/workflows/**` changes always trigger heavy (meta-trap guard via `heavy` filter)
- ✓ Branch unprotected → no required-check refactor
- ✓ Branch guard before commit (worktree pinned to `ops/ci-path-filter`)
- ✓ CI/YAML edit only — zero code, zero deploys
