# BookBed TODO — živo jezgro

**Rewritten 2026-06-11.** Stara verzija (641 linija) vodila je na izvršene/mrtve akcije
(cutover izvršen 2026-05-31; pepper ukinut; #481/#483/#517/#565 merged; F-50-03/04/06/07/08/09/10/12,
M6/M7, escapeHtml, OAuth-orphani — sve verifikovano DONE u HEAD prije brisanja).
Puna istorija: `git log -- docs/TODO.md`.

---

## 🚨 P1 — PROD pickup wave (operator-gated; billing fix prereq za CI)

Kanonski checklist: **`docs/SECURITY_FIXES.md` § SF-081** (7 CF-ova + firestore.rules + audit/123 wave).
Uz to, stariji PROD gapovi koji se voze istim talasom:

- **⚠️ ORDERING (F-86-02, 2026-06-11):** `firebase deploy --only firestore:indexes --project production`
  i sačekaj READY **+30s buffer** (T11c lekcija) PRIJE deploya `getUnitAvailability` — CF sad koristi
  2 nova CG composita (`bookings unit_id+status+check_out`, `ical_events unit_id+end_date`);
  bez indexa availability 500-uje "index currently building" → widget kalendar fail-closed.

- **Hosting headers redeploy** — security headeri (CSP/HSTS/Permissions-Policy) committani u
  `firebase.json` ali PROD owner+admin hosting nikad redeployan → headeri žive samo na dev
  (memorija: prod-hosting-headers-deploy-gap). `firebase deploy --only hosting:owner,hosting:admin --project production`.
- **SF-026 prod migracija** — `normalize-booking-nights.js` PROD dry-run odrađen 2026-05-23
  (`audit/migrations/…DRYRUN.log`); `--force` run nikad potvrđen. Re-dry-run pa force.
- **accountStatus backfill** — `scripts/backfill-accountstatus.js` (audit/111); PROD dry-run log
  2026-06-03 postoji, force pending.
- **B-2 subscription Prices** — tek uz Phase 2 billing ship: kreiraj LIVE Prices pa popuni
  `ALLOWED_SUBSCRIPTION_PRICE_IDS` u `.env.rab-booking-248fc` (deny-all do tada je ispravno; vidi `.claude/rules/stripe.md`).

## 🛡 App Check launch checklist (SF-046 audit-mode živ; F-123 operator note)

`enforceAppCheck: false` i danas na `getUnitAvailability` + `createStripeCheckoutSession`. Za enforcement:
- [ ] Provision `RECAPTCHA_SITE_KEY` (dev + prod)
- [ ] Web client init (`web/index.html` + widget entry) — `FirebaseAppCheck.activate` nigdje u lib/ (verified 2026-05-29)
- [ ] Native init (DeviceCheck / Play Integrity)
- [ ] CSP pre-flight: dodaj recaptcha domene PRIJE flipa (vidi `availability.ts:126` komentar + memorija csp-recaptcha-gsi)
- [ ] 1 sedmica telemetrije ≥99% pa flip `enforceAppCheck: true` + proširi na ostale anon callable-e
- Operator-only (audit/123): App Check enforcement toggle za Firebase AI Logic API.

## 🧰 Deploy-hygiene automatizacija (S/M)

- **SF-052** Sentry lazy init — `sentryDsn.value()` iz module-load u `withSentry()` first-call; ubija deploy-time warning (memorija: sentry-cf-deploy-time-value-warning). XS, bundlaj uz sljedeći `sentry.ts` touch.
- **SF-053** `tool/check-cf-orphans.sh` + CI pre-deploy guard (klasa: memorija firebase-cf-orphan-survival-class).
- `tool/deploy-cors-iam-restore.sh` — kodifikuj IAM re-grant loop (memorija: cf-deploy-cors-shape-iam-strip).
- Worktree bootstrap — `git worktree add` ne kopira gitignored `functions/.env*`; `tool/wt-bootstrap.sh`.
- **F-CUT-01 trajni fix** — pre-push hook ili CI check: `functions/package-lock.json` mora biti npm-10 generisan (recidiv 2026-06-11; memorija: cutover-lockfile-drift).

## 🧹 Hygiene / odluke

- **B-7 staging odluka** — bookbed-staging: redeploy ili penzija (no half-mirror). Orphani + missing CFs.
- **Branch cleanup** — remote merged kandidati za delete; per-batch approval (B-6).
- **Firebase Extensions u git** — `firebase ext:export --project rab-booking-248fc` (delete-user-data + storage-resize-images).
- **PROD test UIDs** — operator delete 2 Wave-0 test UID-a iz prod konzole (audit/35 §6; recipe audit/15).
- **F-86 trio (LOW)** — inclusive-end `<=`, unbounded CG range, Stripe min-floor overcharge → tabela u `audit/edge-0530/README.md`.
- **M5 cancellation policy stub** — `guestCancelBooking.ts:254` TODO (full_refund/50%/no_refund logika).
- **audit/35 ostaci (P3)** — D3 `X-RateLimit-Remaining`/`Retry-After` headeri na 2 CF-a; D5 authStateChanges listener konsolidacija.
- **Region konsolidacija (P3)** — Stripe+booking hot-path us-central1 → europe-west1; dual-deploy + webhook URL update (memorija: cf-region-split-us-eu).
- **firebase-admin 14 bump** — zaseban smoke-tested PR (F-107-07/08; npm audit 8 moderate prati).

## 🧩 Widget refactor Phases 2-5 (P2 tech debt)

Phase 0+1 shipped (CHANGELOG 6.78). Plan-doc audit/12 obrisan — puni plan u git history.
Faze: leaf composers (~8h) → form/payment composers (~12h) → submit-pipeline services (~14h) →
payment messaging + Stripe launcher (~18h, browser-matrix obavezan). Cilj: screen ≤300 LOC orchestrator.

## 📝 Produkt

- **Bookbed website docs** (React site): Owners (getting started, pricing, Stripe Connect, widget, bookings, iCal, notifications), Guests (book, payment, lookup, cancel), API reference. Izvor: ovaj repo.
- **Admin Controls** (nice-to-have, ~30min): `hideSubscription` bool + `adminOverrideAccountType` na UserModel + admin card + subscription gate. Puni recept u git history (TODO.md verzija prije 2026-06-11).
- **Reviews/PROSJEČNA OCJENA** — Pregled KPI placeholder "—" čeka reviews feature (product scope, audit/120).
- **F-123-03 trial-gate** — product decision (vidi audit/123 §2).
