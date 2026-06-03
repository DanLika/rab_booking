# audit/110 — Trial gate scope map (Step A1 — Layer 1 only)

**Drafted**: 2026-06-03
**Mode**: scope map for Step A1 (owner-management callables). Sibling of `audit/109` §1. NO L2 / guest-facing callables touched in this PR — Step A2 covers those.
**Repo HEAD**: `cf65f9c8` on `main`.

## Client-taxonomy mirror (the authoritative source for the server allow-list)

`lib/features/subscription/models/trial_status.dart:51-106`:

```dart
enum AccountStatus {
  trial,         // Firestore value: 'trial'
  active,        // Firestore value: 'active'
  trialExpired,  // Firestore value: 'trial_expired'
  suspended,     // Firestore value: 'suspended'
}

bool get hasFullAccess =>
    accountStatus == AccountStatus.trial ||
    accountStatus == AccountStatus.active;
```

`AccountStatusExtension.fromString(...)` defaults unknown values to `AccountStatus.trial` (line 44).

So the **canonical client allow-list is `['trial', 'active']`**. The server allow-list MUST match — no new taxonomy introduced.

### Off-spec drift noted (not introduced by this PR)

`functions/src/scheduledPushNotifications.ts:390, 499, 629` uses `.where('accountStatus', 'in', ['trial', 'active', 'premium'])`. The `'premium'` value is NOT in the client enum — likely legacy. The trial gate helper treats `'premium'` as UNKNOWN per §Unknown handling below. Push notif filter is unaffected (different code path) but the drift is documented here for a future cleanup PR.

## Missing/unknown status handling

The Firestore `users/{uid}.accountStatus` field may be missing or carry a value outside the client enum. **Server is the authority — fail-CLOSED on unknown.**

| Option | Behaviour | Verdict |
|---|---|---|
| **Fail-CLOSED + Sentry WARN** (CHOSEN) | Helper throws `failed-precondition` and logs WARN to Sentry with `{uid, observedStatus}`. Same user-visible error as `trial_expired`. | ✅ matches the project's documented stance for security gates (`functions/src/utils/rateLimit.ts` header: "Default behavior is fail-closed (block on error)"). Trial gate is a revenue gate — same class. Mass-block risk is bounded: `migrateTrialStatus.ts` ran on PROD; unknown today implies data corruption or a never-onboarded edge case; `onUserCreate` auto-backfills on re-trigger; operator can manually fix via `updateUserStatus`. Better hard-stop with a clear "upgrade" affordance than silent revenue leak. |
| Fail-OPEN + Sentry WARN | Helper allows + logs. | ✗ Permissive on a revenue gate. Mirroring client `fromString` default-to-`trial` is a UX argument for the client (rendering stale data), not a security argument for the server. |

**Decision: fail-CLOSED, non-flag-driven.** Flags on security defaults rot (the flag becomes the default through neglect). The SF-078 entry documents the choice; future operator can change posture in a follow-up PR with explicit review.

## Callable inventory + classification

35 callables found via `grep -rn "onCall\s*(" functions/src --include="*.ts"`. Plus `getUnitIcalFeed` is an `onRequest` (HTTP) endpoint, not a callable — listed in EXEMPT for completeness.

### L1 — owner-management (gate in this PR)

**7 callables.** Caller is the property owner; action mutates owner infrastructure or generates owner-side resource consumption (Resend mails, Stripe API calls, iCal fetches). Trial-expired owner should not be doing these.

| Callable | File:line | What it does | Why L1 |
|---|---|---|---|
| `createOwnerBookingAtomic` | `atomicBooking.ts:1657` | Owner creates a booking on one of their own units (manual/admin source). | Mutates booking state on owner's units; clearly owner-management. **User-visible**: existing reservation pipeline freezes for trial_expired owners — the `trial_banner.dart` "trial expired — upgrade" affordance is the correct UX response. |
| `updateBookingAtomic` | `atomicBooking.ts:1920` | Owner updates a booking (dates, guest count, status, etc.). | Same as above. |
| `updateBookingTokenExpiration` | `updateBookingTokenExpiration.ts:20` | Owner extends check_out → token expiration recalculated. F-NEW-06 comment explicitly identifies owner-as-caller. | Owner action; token rotation. |
| `resendBookingEmail` | `resendBookingEmail.ts:45` | Owner re-sends booking email (rotates access_token). Resend bill + guest-mailbox impact. | Owner-triggered guest contact + revenue surface. SF-vibe57 H-06 already rate-limits this for the same reason. |
| `sendCustomEmailToGuest` | `customEmail.ts:21` | Owner sends a free-form custom email to a guest. Resend bill. | Owner-initiated guest contact. |
| `syncIcalFeedNow` | `icalSync.ts:407` | Owner clicks "Sync Now" in dashboard. iCal fetch + parse. | Owner action; explicit "Called from Owner Dashboard when user clicks Sync Now" docstring. |
| `createStripeConnectAccount` | `stripeConnect.ts:16` | Owner sets up Express Connect account. Stripe API call. | Owner infrastructure setup; trial_expired should not start NEW Stripe integration without upgrading. |

### L2 — guest-facing (DEFER to Step A2)

7 callables. NOT touched in this PR. Listed for completeness.

| Callable | File:line | Why L2 |
|---|---|---|
| `createBookingAtomic` | `atomicBooking.ts:61` | Guest creates booking via widget. Caller is guest (anonymous or auth.uid = booker, not owner). Need to gate on the BOOKED UNIT's owner status — different attack-surface model. |
| `createStripeCheckoutSession` | `stripePayment.ts:52` | **Guest booking payment** (NOT owner subscription — confirmed via reading the bookingData/guestEmail/depositAmount data shape at lines 84-119). Gate on unit's owner status. |
| `verifyBookingAccess` | `verifyBookingAccess.ts:21` | Guest verifies booking access. Anonymous. |
| `guestCancelBooking` | `guestCancelBooking.ts:66` | Guest cancels. Anonymous (token-validated). |
| `getBookingByStripeSession` | `getBookingByStripeSession.ts:27` | Guest retrieves booking by Stripe session. Anonymous. |
| `resendGuestBookingEmail` | `resendGuestBookingEmail.ts:42` | Guest re-requests their email. Anonymous (token-validated). |
| `getUnitAvailability` | `availability.ts` (onCall via index export) | Widget reads unit availability. Anonymous. Listed for completeness — Step A2 must decide whether to block guest bookings on `trial_expired` units OR keep public availability for now. |

### EXEMPT — must work for trial_expired or system

20 callables. Document each reason for the audit trail.

| Callable | File:line | Reason for exemption |
|---|---|---|
| **`createSubscriptionCheckoutSession`** | `stripeSubscription.ts:21` | **Owner-upgrade path.** This is THE callable a trial_expired owner uses to upgrade. Gating it = catch-22. Must always work. |
| **`createCustomerPortalSession`** | `stripeSubscription.ts:165` | Stripe billing portal — billing info / cancel / change plan. Must always work for trial_expired owners. |
| `getStripeAccountStatus` | `stripeConnect.ts:145` | Read-only — owner queries their own Stripe Connect status. No mutation, no abuse vector. |
| `disconnectStripeAccount` | `stripeConnect.ts:232` | Owner disconnects their Stripe Connect. **Customer off-ramp** — no revenue generated, no Resend/Stripe spend, just deletes the Connect link. Gating a "wind-down" action is customer-hostile, not security. Move to EXEMPT (was provisionally L1 in initial draft; advisor-corrected). |
| `setLifetimeLicense` | `admin/setLifetimeLicense.ts:23` | Admin-only callable. Already gated on `request.auth.token.isAdmin === true`. |
| `updateUserStatus` | `admin/updateUserStatus.ts:26` | Admin-only callable. Already gated. |
| `migrateTrialStatus` | `migrations/migrateTrialStatus.ts:34` | Migration script; admin/system. Gate would prevent operator from fixing the data state we'd be checking. |
| `sendEmailVerificationCode` | `emailVerification.ts:57` | Auth onboarding. Pre-trial-state user (newly created or anonymous). |
| `verifyEmailCode` | `emailVerification.ts:243` | Auth onboarding. |
| `checkEmailVerificationStatus` | `emailVerification.ts:419` | Auth onboarding. |
| `checkPasswordHistory` | `passwordHistory.ts:77` | Auth flow. Account hygiene. |
| `savePasswordToHistory` | `passwordHistory.ts:139` | Auth flow. Account hygiene. |
| `sendPasswordResetEmail` | `passwordReset.ts:59` | Auth flow. Recovery. |
| `revokeAllRefreshTokens` | `revokeTokens.ts:39` | Auth flow. Security. |
| `checkLoginRateLimit` | `authRateLimit.ts:53` | Auth flow. Pre-auth. |
| `checkRegistrationRateLimit` | `authRateLimit.ts:112` | Auth flow. Pre-auth. |
| `recordLoginFailure` | `loginLockout.ts:99` | Auth flow. Pre-auth (no `request.auth.uid`). |
| `getLoginLockoutStatus` | `loginLockout.ts:172` | Auth flow. Pre-auth. |
| `clearLoginAttempts` | `loginLockout.ts:213` | Auth flow. Pre-auth (post-success). |
| `deleteUserAccount` | `deleteUserAccount.ts:48` | Account deletion must always work — user's data sovereignty. |
| `getUnitIcalFeed` | `icalExport.ts` (onRequest) | Public iCal feed (token-validated). Not an `onCall`. Listed for transparency. |

### Critical decision flagged: `createStripeCheckoutSession`

**Result: GUEST BOOKING (L2), not owner subscription.**

Verified by reading `functions/src/stripePayment.ts:84-119`:
- `bookingData` payload contains `unitId, propertyId, ownerId, checkIn, checkOut, guestName, guestEmail, totalPrice, depositAmount, paymentOption`.
- Sentry user context (line 125) tracks `guestEmail` (NOT owner email).
- The callable's purpose is the widget's payment-checkout for a guest booking.

Owner subscription / upgrade uses `createSubscriptionCheckoutSession` (in `stripeSubscription.ts:21`) — a **separate callable**.

Therefore: `createStripeCheckoutSession` is correctly L2 (defer to A2). `createSubscriptionCheckoutSession` is correctly EXEMPT (owner upgrade path). No catch-22 risk in this PR.

## Direct-write paths NOT covered by this PR (firestore.rules scope)

Owner can mutate state DIRECTLY against Firestore without going through a callable:

- `properties/{propertyId}` create/update — `firestore.rules:215` gated on `canCreateAsOwner()` which checks `request.auth.uid == request.resource.data.owner_id` ONLY. No `accountStatus` check.
- `properties/{propertyId}/units/{unitId}` writes — same path.
- `properties/{propertyId}/widget_settings/{unitId}` writes — owner can mutate widget config directly.
- `properties/{propertyId}/pricing_calendar/{...}` writes — owner edits pricing directly.
- `properties/{propertyId}/units/{unitId}/bookings/{bookingId}` writes — owner can write a booking directly (subcollection rule allows `isPropertyOwner(propertyId)`).

**These cannot be gated from a callable.** They require a Firestore-rules-tightening PR that adds a `getUserStatus(uid) in ['trial', 'active']` predicate to each `allow create/update` clause. Per `audit/22 §1` deploy-order ("rules zadnje"), rules tightening is a separate PR with separate dev-first cycle.

→ Scope finding documented; out of scope for Step A1.

## SF-NNN allocation

Next SF number: **SF-078** (verified: `grep -nE "^## SF-078|SF-078:|SF-078\b" docs/SECURITY_FIXES.md` returns zero hits on `cf65f9c8`; the memory file referencing SF-078 was speculative — `docs/SECURITY_FIXES.md` is the source of truth).

## Helper-API shape (preamble pattern)

To avoid 7× redundant `if (!request.auth?.uid)` checks, `requireActiveOwner` takes `request.auth` and BOTH asserts authentication AND checks status, returning the uid:

```ts
const uid = await requireActiveOwner(request.auth);
// throws HttpsError('unauthenticated', …) if no auth
// throws HttpsError('failed-precondition', …) if accountStatus ∉ ['trial','active']
// returns uid on success
```

**Order**: `requireActiveOwner` MUST run BEFORE `enforceRateLimit` / `checkRateLimit`. Otherwise a trial-expired user spamming an endpoint burns their per-user rate-limit budget (and Firestore writes for the rate-limit doc) before hitting the trial gate. Tests cover this ordering.

## Summary

- **L1 callables to gate in this PR**: **7** (`createOwnerBookingAtomic`, `updateBookingAtomic`, `updateBookingTokenExpiration`, `resendBookingEmail`, `sendCustomEmailToGuest`, `syncIcalFeedNow`, `createStripeConnectAccount`)
- **L2 callables deferred to Step A2**: 7
- **EXEMPT (must work or system/admin)**: **21** (was 20; `disconnectStripeAccount` moved from L1 → EXEMPT per advisor — off-ramp, no revenue)
- **Owner-upgrade path**: `createSubscriptionCheckoutSession` + `createCustomerPortalSession` — both EXEMPT, both EXPLICITLY VERIFIED separately from `createStripeCheckoutSession` (which is guest-booking, L2)
- **Allow-list**: `['trial', 'active']` (canonical client `hasFullAccess`)
- **Unknown-status default**: **fail-CLOSED + Sentry WARN** (no flag, per the project's security-gate pattern in `enforceRateLimit`)
- **Helper preamble pattern**: `const uid = await requireActiveOwner(request.auth);` — replaces `if (!request.auth?.uid) throw …` + `enforceRateLimit(uid, …)` ordering. Must run **before** rate-limit checks.
- **Firestore-rules direct-write paths NOT gated by this PR** — cross-referenced in the `docs/SECURITY_FIXES.md` SF-078 entry as open follow-up (properties / widget_settings / pricing_calendar / owner-side bookings subcollection direct writes need a rules-tightening PR; "rules zadnje" per `audit/22 §1`).
- **Off-spec `'premium'` value in `scheduledPushNotifications.ts`** documented; treated as UNKNOWN by the gate (fail-closed). The scheduledPushNotifications CF's own `'in'` filter is unchanged.
