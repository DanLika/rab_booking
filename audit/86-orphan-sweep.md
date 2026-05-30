# audit/86 — Cloud Functions orphan sweep (SF-053)

**Date**: 2026-05-29
**Scope**: All 3 Firebase projects — `bookbed-dev`, `rab-booking-248fc` (PROD), `bookbed-staging`
**Methodology**: `comm -23 <(gcloud functions list)` vs `grep -rhnE 'export (const|async function|function) NAME' functions/src/`
**Action policy**: documentation only; no deletions. Per-op auth budget reserved for user approval.

---

## Summary

| Project | Deployed CFs | Source exports | Real orphans | Notes |
|---|---|---|---|---|
| `bookbed-dev` | 62 | 251 | **0** | ✅ Clean. Every deployed CF has a source backing. |
| `rab-booking-248fc` (PROD) | 67 | 251 | 0 real, **5 expected** | All 5 are `ext-*` Firebase Extensions (auto-managed). |
| `bookbed-staging` | 54 | 251 | **5** | All from never-shipped OAuth integrations + trial recovery. |

> "Source exports" = 251 named identifiers in `functions/src/**` exported via `export const/function`. Includes utility helpers (`escapeHtml`, `generateButton`, etc) — not all are CFs. Set is intentionally a superset; cross-ref still catches every deployed name because Firebase CFs MUST be re-exported via `functions/src/index.ts`.

---

## PROD — 5 expected orphans (Firebase Extensions, NOT delete candidates)

```
ext-delete-user-data-clearData
ext-delete-user-data-handleDeletion
ext-delete-user-data-handleSearch
ext-storage-resize-images-backfillResizedImages
ext-storage-resize-images-generateResizedImage
```

These are deployed by Firebase Extensions (`firebase ext:install`):
- `firebase-extensions/delete-user-data` — GDPR-compliant user-data cleanup on auth deletion
- `firebase-extensions/storage-resize-images` — image thumbnail generation

**Lifecycle**: managed via `firebase ext:update` / `firebase ext:uninstall`, NOT via `firebase deploy --only functions`. They have NO src/ representation by design.

**Action**: none. Add to ignore-list in future sweeps. STAGING + DEV do not have these extensions installed; that's an independent decision.

---

## STAGING — 5 real orphans

```
comebackReminder
handleAirbnbOAuthCallback
handleBookingComOAuthCallback
initiateAirbnbOAuth
initiateBookingComOAuth
```

### Classification

| Orphan | Likely origin | Source still present? | Disposition |
|---|---|---|---|
| `comebackReminder` | Abandoned trial-recovery email CF | NO (`grep -r 'comebackReminder' functions/src/` returns 0) | DELETE candidate — STAGING only |
| `initiateAirbnbOAuth` + `handleAirbnbOAuthCallback` | Airbnb OAuth integration spike, never shipped | NO | DELETE candidates — STAGING only |
| `initiateBookingComOAuth` + `handleBookingComOAuthCallback` | Booking.com OAuth integration spike, never shipped | NO | DELETE candidates — STAGING only |

These match the SF-053 survival class documented in `memory/firebase-cf-orphan-survival-class.md`: source-removed CFs are NOT auto-deleted by Firebase; require explicit `firebase functions:delete` or `gcloud functions delete`.

### Why none of these surface on dev/prod

`bookbed-dev` and `rab-booking-248fc` have always been deploy targets for the canonical `functions/src/index.ts` exports. STAGING received OAuth experimentation work that never merged, plus an early-stage `comebackReminder` CF that was removed in the email-template consolidation (V2 wrapper migration, see [v2-trial-email-migration.md]).

### Suggested cleanup command (DO NOT RUN until user approves)

```bash
# STAGING orphan cleanup — sequential, per-CF confirmation
for fn in comebackReminder handleAirbnbOAuthCallback handleBookingComOAuthCallback initiateAirbnbOAuth initiateBookingComOAuth; do
  echo "Delete $fn from bookbed-staging?"
  read -r confirm
  if [[ "$confirm" == "yes" ]]; then
    gcloud functions delete "$fn" --project=bookbed-staging --region=us-central1 --quiet
  fi
done
```

Region inference: all 5 are pre-eu-west1-split era (audit/58 F-58-08), so `us-central1` is the safe first guess. If `--region=us-central1` returns NOT_FOUND, retry with `--region=eu-west1`.

---

## STAGING — 13 missing deploys (not orphans, but adjacent finding)

`bookbed-staging` is **stale** vs `functions/src/index.ts` HEAD. Deployed there but NOT here:

```
getLoginLockoutStatus           # SF-050 / PR #517 / eu-west1
recordLoginFailure              # SF-050 / PR #517 / eu-west1
clearLoginAttempts              # SF-050 / PR #517 / eu-west1
approveBooking                  # booking lifecycle CF
completeBooking                 # PR #549 audit/77 Phase A
rejectBooking                   # booking lifecycle CF
cancelBooking                   # booking lifecycle CF
getUnitAvailability             # T11c / availability.ts / eu-west1
getClientGeolocation            # PR #558 audit/84 / eu-west1
updateBookingAtomic             # atomicBooking.ts
getBookingByStripeSession       # stripe session lookup
cleanupPastDailyPrices          # scheduled CF
createOwnerBookingAtomic        # owner-side booking creation
```

Implication: STAGING cannot be used as a final pre-PROD gate because behavior diverges from PROD. Either redeploy all of `functions/` to STAGING or formally retire STAGING for backend testing. **Recommendation**: redeploy or remove from rotation (no half-mirror).

This is NOT an SF-053 finding — those CFs exist in source and are deployed elsewhere. Separate carry-forward.

---

## Cross-reference

- [SF-053 candidate memory](../memory/firebase-cf-orphan-survival-class.md)
- [audit/55 PR #517 SF-050](./55-f50-02-pr517-design-note-2026-05-27.md) — 3 of the 13 missing-on-staging CFs
- [audit/77](./77-) — booking lifecycle CFs (`completeBooking` migration)
- [audit/58 F-58-08](./58-chrome-devtools-audit-2026-05-27.md) — CF region split (informs delete-region inference)

---

## Sign-off

DEV + PROD have **0 actionable orphans**. STAGING has **5 actionable** + **13 stale-missing**. Awaiting user decision on STAGING role going forward.
