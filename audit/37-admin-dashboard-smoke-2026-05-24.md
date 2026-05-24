# Audit 37 — Admin Dashboard Smoke (TIER 4)

**Date:** 2026-05-24
**Target:** https://bookbed-admin.web.app (**PROD** — `rab-booking-248fc`)
**DEV equivalent:** https://bookbed-admin-dev.web.app (`bookbed-dev`) — see §6 Path C
**Branch:** doc/audit-37-admin-smoke (from main @ 79b4aea2)
**Outcome:** **BLOCKED — gap report.** Smoke aborted at #E1 (cannot authenticate). No exploit attempted. No state mutated. **Resume against DEV URL** after admin claim provisioning.

---

## 1. Why blocked

Smoke checkpoints #E1–#E6 all require an authenticated session with `request.auth.token.isAdmin === true` (Firebase Auth custom claim). The dashboard:
- Routes via `#/login` for unauthenticated users (verified — see §3).
- Drawer + Users + User-detail + Dashboard-stats + Theme-toggle + Logout all sit behind the admin claim gate.
- Even a successful Firebase Auth sign-in (e.g. `bookbed-test@bookbed.io`, see `memory/test-account.md`) yields an ID token **without** `isAdmin`, so all callable CFs (`setLifetimeLicense`, `updateUserStatus`) and admin Firestore reads return `permission-denied`.

**Available credentials in scope:**
- `bookbed-test@bookbed.io` — vanilla owner on `bookbed-dev`. No `isAdmin` claim (intentionally — `memory/test-account.md`: *"Don't grant elevated roles … keep it a vanilla owner."*).
- No dedicated admin smoke account exists in memory.

**Self-provisioning rejected** — request explicitly forbids exploiting `audit/30` `isAdminFromFirestore()` Firestore-role bypass even though it is pre-#462. Provisioning via `firebase-admin` SDK + `setCustomUserClaims({isAdmin: true})` against either project would mutate live auth state and is out-of-scope for a read-only smoke run. Logged as gap, exited cleanly.

---

## 2. Pre-flight (passed)

| Check | Result |
| --- | --- |
| `git branch --show-current` | `main` ✅ |
| Worktree create | `doc/audit-37-admin-smoke` at `$TMPDIR/bb-smoke-admin-wt` ✅ |
| Target reachable | `https://bookbed-admin.web.app/` → 200, Flutter web boot OK ✅ |
| Console errors on load | None ✅ |
| Login form renders | Welcome Back card + Email/Password/Sign-In ✅ (screenshot `E0-login-landing.png`) |

---

## 3. #E1 — Login (BLOCKED, observation only)

**Reached:** `https://bookbed-admin.web.app/#/login`

**Theme observation (vs CHANGELOG 6.31 description):**
- Purple/violet accent (`Sign In` button, logo badge) — consistent with admin-branded purple.
- Pastel diagonal background (lavender → peach) — distinct from owner-app neutrals.
- "© 2024 BookBed Inc. All rights reserved." footer — copyright year stale (2024, not 2026).
- Logo badge: shield + person glyph — admin shell signal.
- No theme toggle visible on `/login` (consistent with toggle moved into drawer per CHANGELOG 6.31).

**Not exercised** (require admin claim):
- Redirect to admin shell after sign-in
- Drawer composition
- Drawer-only theme toggle (#E5)

---

## 4. #E2–#E6 — NOT EXECUTED

All deferred pending admin claim provisioning.

| Checkpoint | What was supposed to verify | Why deferred |
| --- | --- | --- |
| #E2 Users list | Collection-group load via `isAdmin()` rule (CHANGELOG 6.31), search/filter | Requires admin auth |
| #E3 User detail | Lifetime License card (CHANGELOG 6.39), bookings-count surface, no grant/revoke | Requires admin auth |
| #E4 Dashboard stats | `lifetimeUsers` count + others (CHANGELOG 6.39) | Requires admin auth |
| #E5 Theme toggle | Verify removed from AppBar, present in drawer (CHANGELOG 6.31) | Drawer only renders post-login |
| #E6 Logout | Cleared admin claim does not leak between sessions | Requires authenticated session first |

---

## 5. Security observations (no exploit attempted)

### 5.1 audit/30 finding — still in scope pre-#462

Confirmed via static read of admin CFs:
- `functions/src/admin/setLifetimeLicense.ts:?` — gates on `request.auth.token.isAdmin === true` (good — JWT-only).
- `functions/src/admin/updateUserStatus.ts:?` — same gate (good).
- Firestore rules: `isAdmin() || isAdminFromFirestore() ||` allows the Firestore-role escape (the very hole PR #462 closes).

**Did NOT attempt** to write `users/{uid}.role = "admin"` to escalate from a vanilla account. Per request: observation-only.

### 5.2 Login footer copyright year stale

`© 2024 BookBed Inc.` — should be 2026. Cosmetic, but a visible inconsistency for an admin tool.

### 5.3 No console messages on login page

Indicates clean Flutter web boot (no Sentry-noisy plugin errors on `/login`). Cannot evaluate authed-page boot until admin claim provisioned.

---

## 6. To resume smoke — Duško action required

**Verdict after Path C precheck:** smoke MUST move off the prod URL. Use **Path C** below. Paths A and B are retained for reference but supersede with Path C.

### Path A (recommended) — dedicated admin smoke account on `bookbed-dev`
```bash
# In a Node REPL with firebase-admin SDK + bookbed-dev ADC:
const admin = require('firebase-admin');
admin.initializeApp({projectId: 'bookbed-dev'});
const u = await admin.auth().createUser({
  email: 'bookbed-smoke-admin@bookbed.io',
  password: '<strong-random>',
  emailVerified: true,
  displayName: 'Smoke Admin'
});
await admin.auth().setCustomUserClaims(u.uid, {isAdmin: true});
console.log('UID:', u.uid);
```
Then save creds + UID to `memory/admin-smoke-account.md` (mirroring `memory/test-account.md` format) and re-run audit/37.

### Path B — promote existing test account temporarily
Set `isAdmin` claim on existing `bookbed-test@bookbed.io` UID `GILVItIVP5R8WXfnMmyMo1ykhUm2`, run smoke, then **revoke** with `setCustomUserClaims(uid, null)` and force token refresh.

Trade-off: pollutes the vanilla-owner contract `memory/test-account.md` is built around — short window of "elevated" state could mask owner-flow regressions if both smokes run in parallel.

### Path C — point smoke at `bookbed-admin-dev.web.app` instead (RECOMMENDED — supersedes A/B)
**Post-precheck finding:** `.firebaserc` confirms:
- `bookbed-admin.web.app` → target `admin` under `rab-booking-248fc` (**PROD**)
- `bookbed-admin-dev.web.app` → target `admin` under `bookbed-dev` (**DEV**)
- `bookbed-admin-staging.web.app` → target `admin` under `bookbed-staging` (**STAGING**)

This audit was scoped against the PROD dashboard URL. **Smoke should run against `bookbed-admin-dev.web.app`**, not prod. Re-pointing the target collapses Path A/B/C into a single action:

```bash
# 1. Verify dev admin site exists in Firebase Console (per hosting-build.md, site IDs must pre-exist)
firebase hosting:sites:list --project bookbed-dev

# 2. If admin dev site not yet built/deployed:
flutter build web --release --target lib/admin_main.dart -o build/web_admin
firebase deploy --only hosting:admin --project bookbed-dev

# 3. Provision dev admin smoke account (firebase-admin SDK + bookbed-dev ADC):
const admin = require('firebase-admin');
admin.initializeApp({projectId: 'bookbed-dev'});
const u = await admin.auth().createUser({
  email: 'bookbed-smoke-admin@bookbed.io',
  password: '<strong-random>',
  emailVerified: true,
  displayName: 'Smoke Admin'
});
await admin.auth().setCustomUserClaims(u.uid, {isAdmin: true});

# 4. Save creds to memory/admin-smoke-account.md
# 5. Re-run audit/37 against https://bookbed-admin-dev.web.app
```

**Why prod-pointing smoke is a non-starter:**
- Any auth/login mutates `rab-booking-248fc` auth users.
- Any list/detail screen exposes real owner PII.
- Any accidental click on Grant/Revoke flips a real customer's `lifetime_license_*` fields + writes to `security_events`.
- Even read-only smoke leaves Sentry breadcrumbs tagged `environment=production`.

---

## 7. Artifacts (worktree only)

- `audit/37-admin-dashboard-smoke-2026-05-24.md` — this report
- `E0-login-landing.png` — screenshot of unauthenticated `/login` landing (worktree root, not committed)

---

## 8. Coverage delta

| Coverage area | Pre-audit | Post-audit |
| --- | --- | --- |
| Admin dashboard reachability | unverified | ✅ live, login renders |
| Theme regression vs CHANGELOG 6.31 | unverified | partial (login-page subset only) |
| Admin-protected surfaces (Users, User-detail, Dashboard, Drawer, Logout) | unverified | **still unverified** |
| audit/30 isAdminFromFirestore() risk | known pre-#462 | unchanged (no exploit attempted) |
| Test-admin account hygiene | no account | **gap formalized** — Path A/B/C above |

---

## 9. Recommendation

1. **Move smoke target to `bookbed-admin-dev.web.app` (Path C).** PROD admin dashboard MUST NOT be a smoke surface. Re-runs of audit/37 should explicitly state DEV URL.
2. **Verify `bookbed-admin-dev` site is built + deployed** before provisioning — `firebase hosting:sites:list --project bookbed-dev` then deploy if missing. CHANGELOG 6.31 added the hosting target but did not document a DEV deploy.
3. **Provision dev admin smoke account** (Path C step 3) and save to `memory/admin-smoke-account.md`.
4. Re-run audit/37 against DEV URL — should complete #E1–#E6 in ~10 min.
5. **Update login footer copyright year** to 2026 (cosmetic, batchable with next admin deploy).
6. After PR #462 merge, re-audit #E2 to verify Firestore-role escape is closed at the rules layer.
7. **Document admin-dashboard env mapping in `.claude/rules/admin.md`** (currently absent — `.claude/rules/hosting-build.md` documents the table but admin-specific safety rules should live in admin scope).

---

**Status:** Smoke not completed. Gap formalized. No state changed. Awaiting admin claim provisioning to resume.
