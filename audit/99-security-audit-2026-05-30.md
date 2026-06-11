# Audit 99 — security sweep residual ledger (orig. 2026-05-30, condensed 2026-06-11)

Original multi-agent sweep doc condensed after per-finding verification + a
fix wave (full text: `git log --follow -- audit/99-security-audit-2026-05-30.md`).

## CLOSED (verified or fixed)

| ID | Was | Closure |
|---|---|---|
| F-99-01 HIGH | bookings update deny-list gap | SF-078 / PR #609 (verified merged 2026-06-11) |
| F-99-02 MED | passwordHistory no rate-limit (bcrypt compute-DoS) | 2026-06-11: `checkRateLimit('pwhist:{uid}',10,300)` on both callables; deployed dev |
| F-99-04 MED | widget hosting no CSP | = F-107-03; scoped CSP present in firebase.json (verified 2026-06-11) |
| F-99-05 MED | no COOP on owner/admin (Stripe-popup tabnabbing) | 2026-06-11: `Cross-Origin-Opener-Policy: same-origin-allow-popups` on owner+admin headers (ships per-surface on next hosting redeploy — see memory prod-hosting-headers-deploy-gap) |
| F-99-06 LOW | devices `platform` mutable (forensic tamper) | 2026-06-11: dropped from `hasOnly`; legit `set(merge:true)` refresh unaffected (same-value writes don't enter affectedKeys); emulator cells updated (deny mutation / allow 3-key update); deployed dev |
| F-99-07 LOW | revokeAllRefreshTokens no rate-limit (self-storm) | 2026-06-11: `checkRateLimit('revoke:{uid}',3,300)`; deployed dev; live spot 3×200→429 |
| F-99-08 LOW | syncIcalFeedNow no rate-limit (SSRF budget) | 2026-06-11: Firestore-backed `enforceRateLimit(uid,'ical_sync_now',10/60s)`; deployed dev |
| CONFIRM-OPEN (audit/89 CORS follow-up) | 5 callables | became F-107-02, CLOSED via PR #720 |

PROD pickup for the four CF + rules changes = next deploy wave (dev-verified;
462/462 functions tests + 159 rules cells green).

## OPEN residuals (LOW/INFO, deliberate deferrals)

| ID | Sev | Item | Note |
|---|---|---|---|
| F-99-03 | INFO latent | `user_profiles` deny-list missing Stripe-linkage mirror | zero read sites today; append `stripe_*` fields to both `hasAny` arrays when next touching rules |
| F-99-09 | LOW dormant | Twilio creds via `process.env \|\| ""` not `defineSecret` | early-returns while empty; convert before activating SMS |
| F-99-10 | LOW | shared validators `throw Error` not `HttpsError("invalid-argument")` | Sentry-noise class (FLUTTER-7B sibling); swap opportunistically per file |
| F-99-11 | LOW (MED footgun) | `web_utils_web.dart` `sendMessageToParent` posts `targetOrigin:'*'` | single non-PII caller today; require explicit origin before adding callers |
| F-99-12/13/14 | LOW | CSP scoping (per-project cloudfunctions wildcard; `*.a.run.app` absent; `*.googleapis.com` broad) | hardening-sprint batch — change + 3-surface redeploy + smoke as one unit |
| F-99-15 | INFO latent | deep-link cold-start auth race | no app_links stream wired; guard when wiring deep links (F-62-05 class) |
| F-99-16 | INFO | FCM SW `bookingId` concat without format check | trust-bounded by FCM signing; add `/^[A-Z0-9_-]{6,40}$/i` defense-in-depth opportunistically |
| F-99-17 | INFO | `uuid <11.1.1` transitive advisory via firebase-admin@12 | not exploitable in CF context; clears with firebase-admin@13 upgrade |
