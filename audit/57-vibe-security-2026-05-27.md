# Vibe-Security Audit — 2026-05-27 (audit/57)

**Skill:** `/vibe-security` run on `main` HEAD (re-baselined to `a2831e91` post PR #514 + #516 merge).
**Method:** 4 parallel `security-engineer` agents (Stripe, Firestore+Storage, CF+auth, secrets+client).
**Excludes already-known fixes:** SF-001..SF-053 + F-50-01..04 + PR #514 + audit/52..56.

## Status snapshot (2026-05-27 evening)

| Finding | Original sev | Status | Closure |
|---|---|---|---|
| C-01 SSRF DNS pin missing | Critical | **CLOSED** | PR #514 F-NEW-05 (commit `38701f6c` + `76208336`) — async DNS validator landed `main` |
| C-02 Stripe Connect open-redirect | Critical | **CLOSED** | PR #514 F-NEW-02 — `isAllowedReturnUrl` extracted to `utils/returnUrlValidation.ts`, imported by `stripeConnect.ts:8` |
| C-03 Stripe Subscription open-redirect | Critical | **CLOSED** | PR #514 F-NEW-02 — same module imported by `stripeSubscription.ts:6`, validates checkout + portal |
| H-01 Stripe-field UID-squat | High | **APPLIED THIS SESSION** | `firestore.rules` deny-list +5 fields × 4 blocks (parent + data subcoll, create + update). 28/28 rules tests green |
| H-02..H-09 + M-01..M-11 + L-01..L-07 | High/Med/Low | **OPEN** | See list below |

---

## OPEN findings (priority order)

### High (8 open)

**H-02 — Property `owner_id` immutable on update missing**
`firestore.rules:151-153`:
```
allow update, delete: if isResourceOwner();
```
`isResourceOwner()` checks `resource.data.owner_id == auth.uid` (existing) but does NOT enforce `request.resource.data.owner_id == resource.data.owner_id`. Same gap on `units`, `bookings`, `daily_prices`, `additional_services`, `widget_settings`, `widget_secrets`, `ical_feeds`, `platform_connections`.

Attack: owner sets `owner_id: <victim_uid>` on own property → orphans property to victim. CF queries (`atomicBooking` overlap detection, analytics) may treat poisoned doc as victim's.

Fix:
```
allow update: if isResourceOwner() &&
  request.resource.data.owner_id == resource.data.owner_id;
```

**H-03 — Deprecated top-level `/bookings/{id}` create still open**
`firestore.rules:337-344` — `allow create: if canCreateAsOwner();`. Authenticated owner can write `/bookings/{any}` with arbitrary `unit_id`, dates, `status:'confirmed'`. T11c CG-read clause already filters reads, but writes remain. Lock once `atomicBooking` confirmed subcollection-only: `allow create, update, delete: if false;`

**H-04 — `verifyEmailCode` no IP rate limit → OTP brute force**
`functions/src/emailVerification.ts:242-387` gates only on per-doc `attempts >= MAX_ATTEMPTS=3` + 60s cooldown for fresh code. Attacker: 3 guesses/min indefinitely. 10⁶ codespace. Fix: rateLimitService 10/min per IP + global per-email cap.

**H-05 — `checkEmailVerificationStatus` enumerates emails**
`functions/src/emailVerification.ts:404-472` — no auth, no rate limit, returns `{exists, verified, verifiedAt, sessionId}` keyed by email. Account-takeover staging surface. Fix: require auth OR IP rate limit + return only `{verified: bool}`.

**H-06 — `resendBookingEmail` no per-uid throttle**
`functions/src/resendBookingEmail.ts:43` — owner-authed but no quota. Each call rotates `access_token` + sends mail. Mailbox harassment + Resend bill amp. Fix: rateLimitService 5/hr per owner+bookingId.

**H-07 — `resendGuestBookingEmail` rotates token without ownership proof**
`functions/src/resendGuestBookingEmail.ts:166-170` — after `email + booking_reference` match, unconditionally overwrites `access_token` + `token_expires_at`. Anyone knowing `BK-xxxxxxxx + guest_email` (predictable; leak via co-guest, past breach, browser history) → invalidate legit token-link → DoS. Fix: require existing token, or don't rotate.

**H-08 — `customer_email` raw vs sanitized in Stripe checkout**
`functions/src/stripePayment.ts:826-827` uses `sanitizedGuestEmail` for metadata; `:839` uses raw `guestEmail` for `customer_email`. Stripe stores raw → audit-trail desync + targeted spear-phishing via Stripe receipt. Fix: `customer_email: sanitizedGuestEmail`.

**H-09 — `customer.subscription.deleted` no Connect-account correlation**
`functions/src/stripePayment.ts:1066-1070,1138` — `where("stripeSubscriptionId","==",subscriptionId).limit(1)` order-unstable without orderBy. Post-H-01 still verify `userData.stripeCustomerId === subscription.customer`. Belt + suspenders.

### Medium (11 open)

**M-01** `charge.refunded` no Connect-acct scoping — `functions/src/stripePayment.ts:965-991` — assert `owner.stripe_account_id === event.account`.
**M-02** `refund_amount` no bounds check — `:985-988` — clamp to `total_price`.
**M-03** `user_profiles` legacy unrestricted write — `firestore.rules:139-142` — `allow write: if false;`.
**M-04** `security_events` user-forgeable audit log — `firestore.rules:448-452` — `request.resource.data.userId == request.auth.uid` minimum.
**M-05** `app_config/{platform}` enumerable for any authed user — `firestore.rules:439-442`.
**M-06** `verifyBookingAccess` returns `bankDetails` on email-only path — `functions/src/verifyBookingAccess.ts:87-122,127-162,210-211` — require valid `accessToken` for `bankDetails`.
**M-07** `loginLockout.emailToDocId` regex collides `+` and `_` — `functions/src/loginLockout.ts:51` — sha256 of normalized email.
**M-08** `setPropertySubdomain` no rate limit — `functions/src/subdomainService.ts:325-386` — rateLimitService 5/hr per ownerId.
**M-09** Hosting CSP + HSTS missing — `firebase.json:36-145` — add per-target CSP + HSTS preload.
**M-10** Stripe metadata stores `access_token_plaintext` — `functions/src/stripePayment.ts:1311` — store sha256 only, derive plaintext from booking doc.
**M-11** SSRF IPv4-mapped IPv6 hex hole — `functions/src/icalSync.ts:38` — decimal regex misses `::ffff:a9fe:a9fe`. Even with F-NEW-05 merged. SF-052 candidate (also tracked in memory `[[ssrf-ipv4-mapped-ipv6-hex-hole]]`).

### Low (7 open)

**L-01** Token `EXTENDED_EXPIRATION_DAYS = 3650` (10 yr) — `functions/src/bookingAccessToken.ts:18,67-95`.
**L-02** `customEmail` 50KB body × 10/min — Resend quota amp — `functions/src/customEmail.ts:84`.
**L-03** `getBookingByStripeSession` returns full PII on session-id — `functions/src/getBookingByStripeSession.ts:23-25,80+`.
**L-04** Storage `image/*` allows SVG → stored XSS — `storage.rules:21-30` — restrict to `image/(jpeg|png|webp|gif)`.
**L-05** `widget_settings` public-read field audit needed — `firestore.rules:198-201,251-259`.
**L-06** SMS service dead code with env at module-load — `functions/src/smsService.ts:13-15` — delete or rewire to `defineSecret`.
**L-07** `isAdminFromFirestore()` latent footgun — `firestore.rules:37-40,54,67,74-75,283,449` — migrate fully to custom claims.

### Code-smell (non-security)

**Duplicate `isAllowedReturnUrl` after PR #514 refactor** — `functions/src/stripePayment.ts:80` still defines a private copy; `functions/src/utils/returnUrlValidation.ts:51` has the canonical export now imported by `stripeConnect.ts` + `stripeSubscription.ts`. Both impls byte-identical (`startsWith` + wildcard split-validation). PR #514's refactor extracted to utils but didn't delete the local copy. Minor cleanup: import from utils, drop local. Doesn't affect security; both produce identical truth values.

---

## Applied this session

### H-01 — Stripe-field UID-squat (CLOSED)

`firestore.rules:61-79, 81-100` — added 5 fields to user-doc deny-list (parent create/update + data subcollection create/update):

```diff
           'lifetime_license_granted_at', 'lifetime_license_granted_by',
-          'role', 'isAdmin'
+          'role', 'isAdmin',
+          // SF-vibe57 H-01: Stripe linkage fields are server-managed
+          'stripe_account_id', 'stripe_customer_id', 'stripe_connected_at',
+          'stripeSubscriptionId', 'stripeCustomerId'
         ])) || isAdmin() || isAdminFromFirestore();
```

**Attack prevented:** owner writes `stripeSubscriptionId = "<victim_sub>"` to own `users/{A}` doc → `customer.subscription.deleted` webhook in `functions/src/stripePayment.ts:1066-1070` lookups `where("stripeSubscriptionId","==",subscriptionId).limit(1)` → returns ≥2 docs → `.limit(1)` order-unstable → may downgrade wrong UID or corrupt B's billing state.

**Verification:** `npm run test:rules` → 28/28 PASS (`users.test.ts` Case 1-4 + `ical_events.test.ts` + `bookings.test.ts`).

**Deploy gate:** `firebase deploy --only firestore:rules --project bookbed-dev` then `firestore-rules-drift-check` workflow re-runs on next PR.

---

## Stash hygiene note

`git stash list` `stash@{0}: On main: sf-vibe57-drift-2026-05-27` contains earlier iteration of this work (C-02/C-03 implementations now superseded by PR #514, plus H-01 reapplied above). Safe to drop after manual review.

## Next batch (recommended order)

1. **H-02** owner_id immutability — small rule edit, broad impact
2. **H-08** customer_email sanitize — 1-line stripePayment.ts:839 swap
3. **H-04** verifyEmailCode rate limit — OTP brute mitigation
4. **M-09** CSP + HSTS — pure firebase.json hosting config
5. **M-11** IPv6 hex hole — `icalSync.ts` `isPrivateOrUnsafeIp` extension (SF-052)

Bundle as separate PR per category. Don't rebatch with PR #514 surface.
