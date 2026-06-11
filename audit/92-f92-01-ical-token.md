# audit/92 — F-92-01 `getUnitIcalFeed` empty-token bypass + token-class deep test

**Date:** 2026-05-30
**Severity:** MEDIUM (defence-in-depth gap; no PII leaked)
**Branch:** `test/f92-01-ical-token-deep-0530`
**Scope:** READ-ONLY smoke on `bookbed-dev` + 1 surgical fix in `functions/src/icalExport.ts`. **Zero PROD touch.**
**Status:** DEV-CONFIRMED + FIX-LANDED in branch, PR opened. No deploy.

---

## 0. TL;DR

`crypto.timingSafeEqual(Buffer.from("", "utf8"), Buffer.from("", "utf8"))` returns **`true`** on Node 20/25. `getUnitIcalFeed`'s `verifyIcalToken(providedToken, storedToken)` pads to equal length then calls `timingSafeEqual` — when **both sides are empty** ("" vs ""), it short-circuits to `true` and the request returns **HTTP 200 + full RFC 5545 feed**.

Three exploit URL shapes were observed live on bookbed-dev (anonymous GET, no auth):

| URL shape                                          | Status | Body size | Verdict     |
|----------------------------------------------------|--------|-----------|-------------|
| `…/{pid}/{uid}/.ics`                               | 200    | 1892 B    | **BYPASS**  |
| `…/{pid}/{uid}/.ICS`  (case-insensitive strip)     | 200    | 1892 B    | **BYPASS**  |
| `…/{pid}/{uid}/%2eics` (URL-encoded `.ics`)        | 200    | 1892 B    | **BYPASS**  |
| `HEAD …/{pid}/{uid}/.ics`                          | 200    | 0 B       | **BYPASS¹** |

¹ HEAD returns no body but emits `Content-Type: text/calendar` + cache headers, confirming server reached the response-send path.

**Bypass condition:** `widget_settings.ical_export_enabled == true` AND **both** `widget_settings.ical_export_token` and `widget_secrets.ical_export_token` (the read-side key on `main`) are empty/missing. Live state on bookbed-dev SEED units satisfies this — see §3.

**Fix:** add 5-line fail-CLOSED guard inside `verifyIcalToken` rejecting empty either side. PR #NEW. SF-063.

**Blast radius:** dates leak (check-in/check-out), unit name leak (in `LOCATION:` and `DESCRIPTION:` headers), booking IDs leak (in `UID:booking-{id}@bookbed.io`). **No PII** — `SUMMARY:Reserved` per GDPR-by-design (`generateBookingEvent` line 509). Real attack value = competitor occupancy recon + slow-roll surveillance of seasonal patterns.

---

## 1. Root cause — line-by-line

`functions/src/icalExport.ts` (HEAD `main` ed31ae47):

### 1.1 Token parsing — strip + zero-length

```ts
// Line 119
const pathParts = request.path.split("/").filter((p) => p);
// Line 121-124  (length check; 2 parts → 400 Invalid URL format)
if (pathParts.length < 3) { ...400... }
// Line 129
const token = pathParts[2].replace(/\.ics$/i, "");
```

`pathParts[2] === ".ics"` → after `.replace(/\.ics$/i, "")` → `token === ""`. The `/i` flag also accepts `.ICS`; Express decodes `%2eics` → `.ics` before path-split, so URL-encoded form also collapses to empty.

There is **no `length === 0` guard** on `token` before the database lookup.

### 1.2 Dual-read with `(legacyToken || "")` fallback

```ts
// Line 162-169
const storedToken =
  widgetSecretsDoc.exists ? widgetSecretsDoc.data()?.ical_export_token : undefined;
const legacyToken = widgetSettings.ical_export_token;
const tokenToCompare = (typeof storedToken === "string" && storedToken.length > 0) ?
  storedToken :
  (legacyToken || "");
```

- If `widget_secrets.ical_export_token` is missing → `storedToken === undefined`
- If `widget_settings.ical_export_token` is missing → `legacyToken === undefined`
- Then `(undefined || "")` → `tokenToCompare = ""`

This is the **only** path where `tokenToCompare` is `""`. Code at L167 deliberately requires non-empty `storedToken` from secrets; that's not symmetric with `legacyToken` which is allowed to be empty.

### 1.3 timingSafeEqual on empty buffers

```ts
// Line 31-51
function verifyIcalToken(providedToken: string, storedToken: string): boolean {
  if (typeof providedToken !== "string" || typeof storedToken !== "string") return false;
  const maxLength = Math.max(providedToken.length, storedToken.length); // 0
  const paddedProvided = providedToken.padEnd(maxLength, "\0");          // ""
  const paddedStored = storedToken.padEnd(maxLength, "\0");              // ""
  try {
    return crypto.timingSafeEqual(
      Buffer.from(paddedProvided, "utf8"),                                // <Buffer >
      Buffer.from(paddedStored, "utf8")                                   // <Buffer >
    );
  } catch { return false; }
}
```

**Verified on Node v25.1.0 (Cloud Functions runtime is Node 20 — same crypto contract):**

```js
crypto.timingSafeEqual(Buffer.from('', 'utf8'), Buffer.from('', 'utf8'));  // → true
```

Two zero-length buffers compare equal (same byte length 0 + no bytes differ). No exception thrown.

### 1.4 Why peppered-hash path doesn't help on `main`

Per memory entry `[[widget-secrets-exfil-deploy-prereqs]]` and `[[pr482-j-smoke-2026-05-26]]`: PR #482 (SF-021 widget_secrets exfil) wrote `widget_secrets.ical_export_token_plaintext` and `widget_secrets.ical_export_token_hash` (peppered SHA-256) but the corresponding **read-side** patch in `icalExport.ts` never landed on `main` — current code still reads `widget_secrets.ical_export_token` (bare). On bookbed-dev where the migration ran, this is a schema/code mismatch:

- Migration moved the legacy plaintext OUT of `widget_settings.ical_export_token`
- New plaintext lives in `widget_secrets.ical_export_token_plaintext` (NOT read)
- Read-side reads `widget_secrets.ical_export_token` → undefined → fallback to empty legacy → **empty bypass**

`ICAL_TOKEN_PEPPER` is bound on bookbed-dev but the read code on `main` doesn't consume it. Peppered-hash logic is wire-correct in the migration; the `getUnitIcalFeed` handler simply has not been updated to perform `sha256(token + pepper) === storedHash` against the new field.

---

## 2. Probe matrix — URL form × method × verdict (live bookbed-dev anonymous)

Property/unit: `SEED_test_owner_property_01` / `SEED_test_owner_unit_01`.

| # | URL                                                     | Method  | HTTP | CT                          | Body                | Verdict       | Note                                                         |
|---|---------------------------------------------------------|---------|------|-----------------------------|---------------------|---------------|--------------------------------------------------------------|
| 1 | `…/{p}/{u}` (no token)                                  | GET     | 400  | text/html                   | "Invalid URL…"      | safe          | `pathParts.length < 3`                                       |
| 2 | `…/{p}/{u}/.ics`                                        | GET     | 200  | text/calendar               | VCALENDAR (1892 B)  | **BYPASS**    | `pathParts[2]=".ics"` → strip → ""                           |
| 3 | `…/{p}/{u}/calendar.ics`                                | GET     | 403  | text/html                   | "Invalid token"     | safe          | strip → "calendar", != ""                                    |
| 4 | `…/{p}/{u}/bogus123`                                    | GET     | 403  | text/html                   | "Invalid token"     | safe          | mismatch                                                     |
| 5 | `…/{p}/{u}/bogus.ics`                                   | GET     | 403  | text/html                   | "Invalid token"     | safe          | strip → "bogus"                                              |
| 6 | `…/{p}/{u}/x`                                           | GET     | 403  | text/html                   | "Invalid token"     | safe          | length-1, mismatch                                           |
| 7 | `HEAD …/{p}/{u}/.ics`                                   | HEAD    | 200  | text/calendar               | (no body)           | **BYPASS¹**   | reaches response-send; cache-headers leak                    |
| 8 | `OPTIONS …/{p}/{u}/.ics`                                | OPTIONS | 204  | text/html                   | ""                  | safe          | early preflight return (L106-109)                            |
| 9 | `POST …/{p}/{u}/.ics`                                   | POST    | 405  | text/html                   | "Method Not Allowed"| safe          | L111-114                                                     |
|10 | `…/{p}` (1 part)                                        | GET     | 400  | text/html                   | "Invalid URL…"      | safe          |                                                              |
|11 | `…/does-not-exist/{u}/.ics`                             | GET     | 404  | text/html                   | "Unit not found"    | safe-ish²     | widget_settings 404 — early-out before token check           |
|12 | `…/{p}/does-not-exist/.ics`                             | GET     | 404  | text/html                   | "Unit not found"    | safe-ish²     | same                                                         |
|13 | `…/{p}/{u}/.ICS`                                        | GET     | 200  | text/calendar               | VCALENDAR (1892 B)  | **BYPASS**    | regex `/\.ics$/i` strips case-insensitively                  |
|14 | `…/{p}/{u}/%2eics` (URL-encoded `.ics`)                 | GET     | 200  | text/calendar               | VCALENDAR (1892 B)  | **BYPASS**    | Express normalises `%2e`→`.` before path-split               |

¹ HEAD bypass: server reaches the cache-headers path. No body returned per HEAD semantics, but `Content-Type: text/calendar; charset=utf-8` + cache ETag are emitted. A probe knows the bypass worked.

² 404 leaks unit existence information when wrong pid/uid combo supplied. Pre-existing UX; **out-of-scope** for F-92-01.

Tests 2, 13, 14 demonstrate the same root cause (empty token after strip) across three URL forms. The fix at §4 closes all three identically.

---

## 3. Schema state on bookbed-dev SEED units

Probe script: `audit/smoke/f92-01-probe.js` (READ-ONLY, ADC-authed, asserts `projectId !== 'rab-booking-248fc'`).

```
properties: 2
[
  {
    "propertyId": "SEED_property_dev_01",
    "unitId": "SEED_unit_dev_01",
    "ical_export_enabled": true,
    "legacy_token_len": "(missing)",
    "secrets_doc_exists": true,
    "secrets_token_len": "(missing)",
    "secrets_hash_len": 64,
    "secrets_plaintext_len": 64,
    "verdict": "VULNERABLE"
  },
  {
    "propertyId": "SEED_test_owner_property_01",
    "unitId": "SEED_test_owner_unit_01",
    "ical_export_enabled": true,
    "legacy_token_len": "(missing)",
    "secrets_doc_exists": true,
    "secrets_token_len": "(missing)",
    "secrets_hash_len": 64,
    "secrets_plaintext_len": 64,
    "verdict": "VULNERABLE"
  }
]

Total ical_export_enabled units: 2
VULNERABLE: 2
SAFE: 0
```

**Read-side mismatch confirmed:**
- `widget_secrets.ical_export_token` — missing on both (this is what `icalExport.ts:165` reads)
- `widget_secrets.ical_export_token_hash` — 64 chars present (PR #482 wrote this; never read by `main`)
- `widget_secrets.ical_export_token_plaintext` — 64 chars present (PR #482 wrote; never read)
- `widget_settings.ical_export_token` — missing on both (PR #482 migration blanked legacy)

100 % of bookbed-dev `ical_export_enabled` units are bypassable. **PROD untouched** by this probe; PROD is non-vulnerable per memory `[[ical-export-empty-token-bypass]]` (legacy slot still populated, migration not yet run).

---

## 4. Fix

`functions/src/icalExport.ts` `verifyIcalToken` (5-line guard, fail-CLOSED):

```ts
function verifyIcalToken(providedToken: string, storedToken: string): boolean {
  // Ensure both are strings and have reasonable length
  if (typeof providedToken !== "string" || typeof storedToken !== "string") {
    return false;
  }

  // F-92-01: empty-token bypass — fail-CLOSED before timing-safe compare.
  // No legitimate token is zero-length; treat empty either side as config gap.
  if (providedToken.length === 0 || storedToken.length === 0) {
    return false;
  }

  // … existing padded timingSafeEqual logic unchanged …
}
```

### Why this scope

- **Minimal** — 5 lines, single function, no call-site changes
- **Defence-in-depth** — closes BOTH bypass paths simultaneously (empty supplied OR empty stored)
- **Pepper-logic-agnostic** — when the PR #482 read-side patch lands on `main`, this guard still applies above any future hash logic; the new path will pass non-empty token + non-empty stored-plaintext to `verifyIcalToken`, so behaviour is unchanged for legit feeds
- **No data migration needed** — works against current bookbed-dev schema mismatch as-is
- **Symmetry with `(legacyToken || "")` fallback** — the existing code accepts empty `legacyToken`; this guard makes that acceptable by rejecting empties downstream

### What this fix does NOT do

- Does not implement the peppered-hash read path (out of scope; tracked in PR #482)
- Does not change the `.ics` strip regex case-insensitivity (regex is correct; the bypass is the empty-token side)
- Does not strip the dual-read fallback (PR #482 migration still in flight; keep compat)
- Does not migrate or repair existing bookbed-dev schema state (operational concern; owner-driven token reset)

---

## 5. Tests added — `functions/test/icalExport.test.ts`

```
✓ F-92-01: rejects empty token via /{pid}/{uid}/.ics strip even when stored token empty
✓ F-92-01: rejects empty token via case-insensitive .ICS strip
✓ F-92-01: rejects when supplied token non-empty but stored token empty (config gap)
✓ F-92-01: legit feed with matching token still 200 (no regression)
```

The 4th test pins the no-regression contract — supplied `"legit-token-32-hex-…"` matches stored same → 200 + VCALENDAR body.

**Full results:**

```
test/icalExport.test.ts        16 / 16 ✓
Total                         391 / 391 ✓  (19 suites)
Build                            0 errors
```

---

## 6. Live re-probe (post-fix, dev)

NOT performed in this branch (no deploy). PR #NEW must be merged + `tool/deploy-dev.sh` against bookbed-dev before re-probing. Expected post-deploy matrix:

| Vector            | Pre-fix | Post-fix expected |
|-------------------|---------|-------------------|
| `/.ics`           | 200     | 403               |
| `/.ICS`           | 200     | 403               |
| `/%2eics`         | 200     | 403               |
| HEAD `/.ics`      | 200     | 403               |
| valid-token GET   | 200     | 200               |
| `/calendar.ics`   | 403     | 403               |

Operator should re-run `audit/smoke/f92-01-probe.js` after deploy to confirm 0/0 still vulnerable (probe is schema check, not HTTP — schema unchanged by this fix; HTTP behaviour is what changes).

---

## 7. Numbering

- Audit: **92**. Memory entry `[[ical-export-empty-token-bypass]]` already promises this number. Selected to match.
- Finding: **F-92-01** (only one finding in this audit).
- Security Fix: **SF-063**. SF-062 reserved per memory entry `[[f86-01-cors-allowlist-gap-8-callables]]` (audit/89 PR #565). SF-061 is the last `## SF-…` heading in `docs/SECURITY_FIXES.md` on `main`.

---

## 8. Out of scope / follow-ups

- **PR #482 read-side wiring** — separate workstream. Once merged + migration run on PROD, the dual-read fallback can be removed and `(legacyToken || "")` empty-default can be tightened. See `audit/90` §1 (`ICAL_TOKEN_PEPPER` missing on PROD blocks PR #482).
- **404-as-existence-oracle** — `Unit not found` (vector 11/12 above) distinguishes missing property vs missing unit. Pre-existing UX class; defer to dedicated audit.
- **Case-insensitive `.ics` strip** — intentional per RFC 5545 client variance. Not changed.
- **Token rotation on bookbed-dev SEED units** — operational. Owner can hit "regenerate" in the iCal settings UI once `getUnitIcalFeed` requires non-empty stored.

---

## 9. References

- `[[ical-export-empty-token-bypass]]` — memory entry describing this bug
- `[[widget-secrets-exfil-deploy-prereqs]]` — PR #482 prereqs
- `[[pr482-j-smoke-2026-05-26]]` — PR #482 J-phase smoke
- `audit/90` §1 — PROD `ICAL_TOKEN_PEPPER` gap (blocks PR #482 deploy)
- `docs/SECURITY_FIXES.md` SF-063 — short-form security entry


---

## Re-run 2026-06-11 (audit/smoke prune)

`f92-01-probe.js` re-run on bookbed-dev with corrected post-SF-063 verdicts:
**2/2 `ical_export_enabled` units = BROKEN-FEED** (only PR #482
`ical_export_token_{plaintext,hash}` present; read-side `icalExport.ts:177-182`
still reads `ical_export_token` → `tokenToCompare=""` → fail-CLOSED 403 on
every request). Security: CLOSED (nothing exploitable). Functional: the
schema-mismatch half of this finding is OPEN — new-schema units ship dead
feed URLs until the read-side accepts `_plaintext` (or verifies `_hash`).
Probe + run recipe live in `audit/smoke/README.md`.
