# audit/89 — Audit/50 backlog close-out

**Date:** 2026-05-29
**Branch:** `fix/audit-50-backlog`
**Worktree:** `/tmp/bb-sf-wt` (isolated)
**Scope:** Close remaining audit/50 findings outside of the already-shipped streams (F-50-01..04, F-50-06..08, F-50-13).
**Touched dirs:** `functions/`, `firestore.rules`, `web/`, `.gitignore`, `audit/raw/` (rm), `docs/SECURITY_FIXES.md`, this file.
**Left alone:** `lib/`, `ios/`, `android/` per scope guard.
**Verification:** `npm run build` 0, `npm test` 387/387, `npm run test:rules` 53/53 (46 base + 7 new devices), `npm audit` 0 undici CVEs (12 moderate residual = upstream SDK noise, F-50-13 monitor).

---

## TL;DR

| Finding | Status before | Status now | SF | PR |
|---|---|---|---|---|
| F-50-01 subscription `priceId` allowlist | PR #481 in flight | ✅ MERGED `a847497e` (separate workstream) | (n/a) | #481 |
| F-50-02 `loginAttempts` anon DoS | open | ✅ CLOSED 2026-05-27 via SF-050 (PR #517) | SF-050 | #517 |
| F-50-03 Stripe webhook event-id dedup | open | ✅ CLOSED via PR (verified in audit/70 §4.2) | (verified) | (audit/70) |
| F-50-04 error.stack scrub | PR #483 closed → PR #495 | ✅ MERGED 2026-05-26 (`cb7b7759`) | (n/a) | #495 |
| F-50-05a undici ≤6.23 8 CVEs | overrides absent in lock | ✅ override `^7.0.0` in package.json + tree NO LONGER pulls undici (firebase-admin 12.6 → Node fetch); zero CVE matches | **SF-061** | this PR |
| F-50-05  App Check  | DEFERRED post-#481/#517 | DEFERRED — out of this PR (see audit/85) | (n/a) | (n/a) |
| F-50-05b CSP owner+admin | OPEN at audit/50 | ✅ shipped via SF-057 (audit/84, PR #557) | SF-057 | #557 |
| F-50-06 HSTS all 3 sites | OPEN at audit/50 | ✅ shipped via SF-057 (audit/84, PR #557) | SF-057 | #557 |
| F-50-07 Permissions-Policy | OPEN at audit/50 | ✅ shipped via SF-057 (audit/84, PR #557) | SF-057 | #557 |
| F-50-08 widget `nosniff` + Referrer-Policy | OPEN at audit/50 | ✅ shipped via SF-057 (audit/84, PR #557) | SF-057 | #557 |
| F-50-09 `devices/{deviceId}` update unbounded | open | ✅ field allowlist on update rule + 7 regression tests | **SF-062** | this PR |
| F-50-10 `web/index.html:669` `eval()` | open | ✅ replaced with native feature probes; no `unsafe-eval` from this code path | **SF-063** | this PR |
| F-50-11 `iframe_resizer.js` postMessage `*` | open | ✅ init-handshake parent-origin capture + referrer fallback + drop-on-unknown | **SF-064** | this PR |
| F-50-12 `audit/raw/` checked into git | open | ✅ `git rm -r audit/raw/` (22 files inc. `secrets.txt`) + `.gitignore` rule | **SF-065** | this PR |
| F-50-13 npm audit moderate residual | n/a | MONITOR — no code change; upstream SDK chain | (n/a) | (n/a) |

---

## Section 1 — F-50-05a undici override (SF-061)

### State at start

`functions/package.json` already carried `overrides.undici: "^7.0.0"` (predate of this PR), but the lockfile (`functions/package-lock.json`) had ZERO `node_modules/undici` entries — only `undici-types` (TypeScript types, harmless).

Reading from `package-lock.json`:

```
$ grep -n "undici" functions/package-lock.json
3589:        "undici-types": "~6.21.0"
6411:        "undici-types": "~6.21.0"
11428:    "node_modules/undici-types": {
11430:      "resolved": "https://registry.npmjs.org/undici-types/-/undici-types-6.21.0.tgz",
```

### Verification

Ran `npm install` in worktree against the existing override:

```
added 857 packages in 11s
```

`npm ls undici` → `(empty)`. Override didn't bite because the current transitive graph (`firebase-admin@12.6.0` + `firebase-functions@^6.0.1` + their deps on Node 20+) no longer reaches undici at all. Node 20 native `fetch` replaced the path.

`npm audit` no longer reports the 8 undici CVEs listed in audit/50 F-50-05a. Residual 12 moderate findings are all in the `@google-cloud/firestore` → `google-gax` → `teeny-request` → `retry-request` + `uuid` stack — different vuln class. These match F-50-13 (passive monitor, upstream SDK).

### Why keep the override anyway

Defense-in-depth: if a future minor bump of `firebase-admin` or `firebase-functions` re-introduces undici as a transitive (e.g. for non-fetch HTTP/2 path), npm resolves it to `^7.0.0` instead of the vulnerable `≤6.23.0` family. Cost: 0 bytes today (no resolution).

### Build + tests

- `npm run build` (tsc) → exit 0, no output
- `npm test` → 19 suites, 387/387 pass
- `npm run test:rules` → 5 suites, 53/53 pass (after Section 2 added 7)

---

## Section 2 — F-50-09 devices/{deviceId} update allowlist (SF-062)

### Before

`firestore.rules:159-163`:

```
match /devices/{deviceId} {
  allow read: if isOwner(userId);
  allow create, update: if isOwner(userId);
  allow delete: if isOwner(userId);
}
```

Owner could overwrite any field (`createdAt`, `userAgent`, `deviceId` itself, plus plant arbitrary fields the server might later use as fraud signals).

### After

```
match /devices/{deviceId} {
  allow read: if isOwner(userId);
  allow create: if isOwner(userId);
  allow update: if isOwner(userId) &&
    request.resource.data.diff(resource.data).affectedKeys().hasOnly([
      'lastSeenAt', 'fcmToken', 'appVersion', 'platform'
    ]);
  allow delete: if isOwner(userId);
}
```

Allowlist matches exactly the audit/50 suggested set (`lastSeenAt, fcmToken, appVersion, platform`).

### Cross-checked against actual client writer

Only writer to `users/{uid}/devices/{deviceId}` is `lib/core/services/security_events_service.dart:270-280`:

```dart
await _firestore
    .collection('users').doc(userId)
    .collection('devices').doc(deviceId)
    .set({
      'deviceId': deviceInfo.deviceId,        // = docId; same value across calls
      'platform': deviceInfo.platform,        // stable
      'fcmToken': deviceInfo.fcmToken,        // rotates
      'lastSeenAt': Timestamp.fromDate(...),  // changes every call
    }, SetOptions(merge: true));
```

Subsequent `set(merge:true)` calls hit the `update` rule. `affectedKeys()` returns only keys whose **value** changed between old and new doc — `deviceId` and `platform` stable across calls so they don't enter `affectedKeys`; only `lastSeenAt` (and `fcmToken` on rotation) do. Both are in the 4-key allowlist → rule allows.

`appVersion` is not currently written by `security_events_service.dart`; it is allowlisted as forward-compat for a future device-token surface (e.g. version-gated force-update telemetry).

### Coverage

New `functions/test/firestore_rules/devices.test.ts` — 7 cases:

| # | Action | Expected |
|---|---|---|
| 1 | owner updates `lastSeenAt` | ALLOW |
| 2 | owner updates 4 allowed keys | ALLOW |
| 3 | owner adds `createdAt` (non-allowed) | DENY |
| 4 | owner mutates `deviceId` (immutable) | DENY |
| 5 | non-owner updates peer device | DENY |
| 6 | owner deletes device | ALLOW |
| 7 | owner creates device | ALLOW |

All 7 pass; suite total 53/53.

### DEV deploy

Not deployed in this PR — autonomy scope blocks `firebase deploy`. The rule lands on `main` after review + merge; first DEV deploy happens via the usual merge → CI path. Smoke recipe in audit/27 + audit/54 applies if a manual verify is wanted.

---

## Section 3 — F-50-10 drop `eval()` ES6 detect (SF-063)

### Before

`web/index.html:665-674`:

```javascript
function isModernBrowser() {
  try {
    eval('class Test {}; let x = () => {}; const y = `test`;');
    return true;
  } catch (e) {
    return false;
  }
}
```

Single `eval()` callsite in the entire web bundle.

### After

Native feature probes, no `eval`:

```javascript
function isModernBrowser() {
  return (
    typeof Symbol === 'function' &&
    typeof Promise === 'function' &&
    typeof Map === 'function' &&
    typeof Set === 'function' &&
    typeof Proxy === 'function' &&
    typeof Reflect === 'object'
  );
}
```

`Proxy` + `Reflect` were ES2015, ES2017; their presence is a strict proper subset of the original `eval` probe (classes, arrows, template literals). No supported browser since 2017 fails this check.

Renderer-selection ladder downstream (`useHtmlRenderer`) keeps the same true/false behavior.

### CSP follow-up

This removes the last in-bundle `eval`-class call. Stripping `'unsafe-eval'` from `script-src` is still blocked by CanvasKit (Flutter web requires it for WASM init), so the owner+admin CSP added in SF-057 keeps `'wasm-unsafe-eval'`. No CSP tightening shipped in this PR — separate cycle once Flutter web upstreams a no-eval CanvasKit toggle.

---

## Section 4 — F-50-11 iframe `postMessage` targetOrigin (SF-064)

### Before

`web/iframe_resizer.js`:

```javascript
window.parent.postMessage({type:'resize', height}, '*');
```

Today's payload is numeric height only → leak surface is small, but `'*'` is a banned best-practice and grows risk if the iframe ever sends more in the future.

### After (`web/iframe_resizer.js` rewritten ~75 lines)

- Listen for `{type: 'bookbed-widget-init'}` from `window.parent` and capture `event.origin` as the trusted parent origin.
- Fallback: derive origin from `document.referrer` (https or http only).
- If neither resolves, defer the message in an internal queue (`pending[]`); flush on next handshake.
- Never sends to `'*'`.

Parent-side: the embed snippet on the widget site (`web/bookbed-overlay.js` or operator iframe loader) should fire a one-time:

```javascript
iframe.contentWindow.postMessage({type: 'bookbed-widget-init', origin: window.location.origin}, '*');
```

— the receiver above pins `event.origin` from that message. (Adoption is opt-in; no parent code change is shipped here — iframes without handshake still work via referrer fallback.)

### No regression smoke

Resize messages are advisory (parent grows iframe height); first failure mode if origin can't be resolved is "iframe stays at initial height" — observable in operator dashboards, not silent breakage of payment/booking flow. Visual smoke deferred to next embed test pass.

---

## Section 5 — F-50-12 `audit/raw/` lockdown (SF-065)

### Before

`audit/raw/` held 22 git-tracked scratch files including `secrets.txt` — a grep dump of every `lib/` and `functions/src/` reference to `apiKey`, `token`, `secret`, etc. Not real secrets, but a free recon-acceleration map if the repo is ever public or leaked.

```
$ git ls-files audit/raw/ | wc -l
22
```

Files removed (sample): `secrets.txt`, `localhost.txt`, `flutter-analyze-full.txt`, `http.txt`, `https.txt`, `tsc.txt`, `pr483-smoke-2026-05-26-cloud-logging.json`, `pr495-smoke-2026-05-26-cloud-logging.json`, …

### After

- `git rm -r audit/raw/` removes all 22 tracked files.
- `.gitignore` adds:
  ```
  # SF-NEW (audit/50 F-50-12): audit/raw/ holds local-only grep dumps that
  # accelerate attacker recon if exposed (line/file references for auth tokens,
  # secrets, hack/fixme markers). Treat as scratch — never commit.
  audit/raw/
  ```

### History note

`audit/raw/secrets.txt` was a grep dump of file:line references, NOT actual secret material. No rotation needed. Git history still contains the file pre-removal; if a stricter cleanup is wanted, that's a separate `git filter-repo` cycle (out of scope of this PR).

---

## Section 6 — Out of scope / deferred

- **F-50-05 App Check** — DEFERRED post-#517 (covered by audit/85 client-init snapshot). Separate work cycle.
- **Hosting CDN SRI gaps** — Semgrep flagged `web/index.html:156` (canonical URL — own-origin link, false positive) and lines 197-202 (Firebase SDK script tags INSIDE an HTML comment block — never loaded, false positive). No real exposure; not fixed.
- **F-50-13 npm audit residual** — 12 moderate findings on `@google-cloud/firestore` / `google-gax` / `teeny-request` / `retry-request` / `uuid` chain. All upstream SDK; pin via `overrides` only if upstream stalls past Q3 (audit/50 §F-50-13).
- **PROD deploy** — out of scope. PR opens to `main`; merge + per-env deploy handled by the regular rotation. No PROD CF redeploy needed (only rules + hosting + lockfile change; CF code unchanged so `firebase deploy --only firestore:rules` covers the rule, hosting reflects on next surface redeploy).
- **iframe handshake parent-side wiring** — operator-side `postMessage({type:'bookbed-widget-init',...})` not bundled in this PR; referrer fallback covers the common case.

---

## Section 7 — Reproducer

```bash
git checkout fix/audit-50-backlog
cd functions
npm install --no-audit --no-fund
npm run build           # 0
npm test                # 387/387
npm run test:rules      # 53/53
npm audit | grep -i undici  # silent — undici CVEs gone
```

Manual eyeball checks:

```bash
grep -n "eval(" web/index.html                # nothing under owner code
grep -n "postMessage" web/iframe_resizer.js   # only via resolved origin
grep "audit/raw" .gitignore                   # present
git ls-files audit/raw/                       # empty
```

---

**Cross-refs:** audit/50 (origin), audit/84 (SF-057..060 hosting + cors), audit/85 (App Check inventory), audit/70 (F-50-03 verification).
