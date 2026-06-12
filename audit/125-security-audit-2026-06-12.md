# Audit 125 — Security sweep 2026-06-12 (delta + full re-run) + LOW fix wave

**Datum**: 2026-06-12 | **Branch**: `fix/audit-low-wave-2026-06-12` | **PR**: #731
**Prethodni baseline**: audit/123 (2026-06-11, §4 = kanonski open ledger)

## 1. Scope & metoda

Dva passa isti dan:

1. **/vibe-security delta pass** — sve promjene od zadnjeg passa (commits `ca41b3dc` AI-quota wiring, `fd76283c` rules zatvaranja, Podfile.lock pod bumps). Rezultat: **clean** — sve promjene security-pozitivne, gitleaks 0 (3 Podfile SHA false-positives).
2. **/security-audit:run full** — 165+ checks, HUGE strategija (656 dart + 100 TS): 6 domain agenata (secrets/env, rules bypass, CF auth+IDOR+RL+CORS, payments, injection/SSRF/XSS, deps/headers/supply-chain) + koordinatorski CLI scans (npm audit, git-history secrets) + firsthand verifikacija svake agent tvrdnje.

## 2. Rezultat: 0 CRIT / 0 HIGH / 0 MED novih — 5 LOW

Agent tvrdnje ubijene verifikacijom (NISU nalazi):
- ~~`migrateTrialStatus` bez auth~~ — FALSE: `migrateTrialStatus.ts:43` enforce-a `isAdmin` claim.
- ~~"10 funkcija bez rate limita"~~ — naduvano: realno 5 fajlova, svi authed/admin-gated.

| # | Nalaz | Severity | Status |
|---|-------|----------|--------|
| F-125-01 | `bookingActions.ts` 4 callables + `admin/updateUserStatus` + `admin/setLifetimeLicense` bez rate limita (authed/admin-gated, ceiling nizak) | LOW | ✅ FIXED (PR #731) |
| F-125-02 | Units write path trial-ungated — i kanonski `properties/{p}/units` i CG `/{path=**}/units` (original SF-080 scope odluka); `additional_services` ista klasa | LOW | ✅ FIXED (PR #731) — SF-080 extension |
| F-125-03 | `widget_secrets.updated_at` bez timestamp validacije | LOW/INFO | ✅ FIXED (PR #731) — request.time bind when-written |
| F-125-04 | Node 20 runtime EOL Oct 2026 | LOW | ⏳ OPEN — zaseban PR, veže se uz F-107-07/08 major bumps |
| F-125-05 | 8× npm moderate (uuid v3/v5/v6 `buf` bounds) — vulnerable path NEKORIŠTEN | LOW | ⏳ OPEN — fix zahtijeva `firebase-admin@14` (F-107-07/08) |

## 3. Fix wave (commit `b37f1eba`)

1. **SF-080 extension (rules)**: units + additional_services `create, update` → `(isPropertyOwner && isActiveOwner()) || isAdmin* `; gate MIRRORED u CG units blok (permissive-union: rules OR preko match blokova — ungated CG bi poništio kanonski gate). `delete` ostaje ungated (cleanup off-ramp, mirror properties bloka). NAPOMENA: original SF-080 (audit/113) je units OSTAVIO ungated by design — ovo je svjesno proširenje scope-a; frozen happy-path regression cell i dalje prolazi.
2. **widget_secrets timestamp bind (rules)**: pisani `updated_at` mora biti `== request.time` (mirror F-107-16); omission dozvoljen (subset writes — striktna verzija bi srušila 2 legitimna cell-a). Jedini klijentski writer (`ical_export_list_screen.dart:219`) već šalje `FieldValue.serverTimestamp()` — zero client change.
3. **Rate limits (CF)**: `approveBooking`/`rejectBooking`/`cancelBooking`/`completeBooking` → shared Firestore-backed `booking_action` bucket 30/min; admin `updateUserStatus` + `setLifetimeLicense` → `admin_action` 20/min.

**Verifikacija**: rules emulator 12 suita / **196 pass** (+14 ćelija: units/services arms, admin bypass, off-ramp, timestamp bind ×3); functions jest **463/463** (+1 RL assertion); tsc clean. Rules deployani na bookbed-dev.

**PROD pickup ZAVRŠEN 2026-06-12** (post-merge `a5cd544f`): rules + svih 6 CF (approve/reject/cancel/completeBooking + updateUserStatus + setLifetimeLicense, eu-west1) deployani na `rab-booking-248fc`; reachability verify — svih 6 vraća strukturirani `UNAUTHENTICATED` JSON (invoker IAM intaktan, nema cors-shape IAM strip-a). Merge po local-verified protokolu: GitHub billing block se vratio na drugom CI runu (nijedan job nije startao); prvi run prije kaskade: Run Tests + Validate Firestore Rules PASS.

## 4. CI regresija nađena usput (fix u istom PR-u)

`dorny/paths-filter` v3→v4 (dependabot `65d2d393`) → "Resource not accessible by integration" u detect-changes jobu na SVAKOM PR-u; kaskada: heavy jobs skip + coverage canceled. Ista klasa kao "#728 2s infra fail". Fix: eksplicitni `permissions: {contents: read, pull-requests: read}` na detect-changes job.

## 5. Open ledger delta

audit/123 §4 ostaje kanonski. Ovaj audit DODAJE: F-125-04 (Node 22), F-125-05 (uuid via firebase-admin@14). Najveća preostala poluga i dalje **operator App-Check toggle** (zatvara modified-client klasu uklj. AI-quota skip).
