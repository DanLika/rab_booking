# audit/28 — TIER 4: Resend email delivery + Sentry baseline

**Date:** 2026-05-23
**Scope:** Resend (dev env) delivery verification across V2 email templates + Sentry (dev) 24h rolling baseline for `getUnitAvailability` + `atomicBooking` + widget initial load. Fail-CLOSED widget recipe documented for user-driven execution.
**Env:** `bookbed-dev` only (PROD untouched per task constraint).
**Cross-refs:**
- `audit/26-bb-e2e-findings.md` §5 (Finding #1 — `provider_id` never captured) — confirmed scope here.
- `audit/22-prod-cutover-plan.md` §6 (T11c fail-CLOSED proof) — reference for §6 below.
- `audit/25-e2e-test-catalog.md` (test surfaces inventory).

---

## 0. Discrepancies surfaced upfront

| Audit/26 claim | Actual (verified `2026-05-23`) | Impact |
|---|---|---|
| "21 v2 templates" (audit/26 §1, §5.4, §5.6, §5.7, §6) | **18 unique `sendXxxEmailV2` exports** confirmed by `grep -rh "^export.*function.*EmailV2"` across `functions/src/`. 18 files in `functions/src/email/templates/` (excluding `base.ts`). Possible audit/26 over-count by 3 — could be aliases (`sendBookingCancellationEmail` = `sendGuestCancellationEmail`, `sendCustomEmailToGuest` = `sendCustomGuestEmail` — 2 found) + an inlined Stripe path. Reconcile in PR-B description: "18 distinct template files" is the more defensible scope. |
| Task assumed `book-bed.com` sender domain | Active sender = `bookings@bookbed.io` (`functions/.env:5` + prod `.env.rab-booking-248fc:5`) | SPF/DKIM verification target = `bookbed.io`. `book-bed.com` is the contact/marketing domain (`assets/kb/bookbed_knowledge_base.md` etc.), not transactional sender. |
| Task assumed seed-bookbed-dev `--everything` fixtures landed | **PR #453 OPEN** (state=OPEN, base=`chore/seed-test-owner-mode`/#449, not merged) | Spot-check triggers manual via direct firebase-admin writes; fixtures fallback. |

---

## 1. Executive summary

| Surface | Status (this session) | Severity |
|---|---|---|
| 18-template `provider_id` matrix | ✅ Static: 18/18 templates still drop the id (despite mid-session `643403d6` wrapper migration — see §2.1) | per-audit/26: MEDIUM |
| 5 DORMANT templates (no active CF caller) | 🆕 **NEW FINDING** — see §3 — **resolved via PR #462** (Option A landed 2026-05-24, §3.4) | LOW (dead code OR feature gap) |
| SPF gap — `bookbed.io` SPF excludes `_spf.resend.com` | 🆕 **NEW FINDING** — see §5.1 | LOW (deliverability optimization) |
| `bookbed.io` DKIM + DMARC | ✅ DKIM present, DMARC `p=none` (monitoring) — §5 | — |
| Resend dev delivery spot-check (6 templates) | ⏳ scripts ready, pending RESEND_API_KEY — §8 | — |
| Sentry 24h baseline (4 metrics) | ⏳ script ready, pending SENTRY_AUTH_TOKEN — §8 | — |
| Fail-CLOSED widget recipe | ✅ §6 below — awaits user execution | — |

**4 net-new findings** beyond audit/26's scope (A1 SPF gap, A2 dormant-5, A3 count discrepancy with audit/26, A4 sender-domain terminology). All LOW severity. See §9.1.

---

## 2. 18-template `provider_id` matrix (static)

`provider_id` capture status confirmed by code inspection. Per audit/26 §5: Resend SDK returns `{data: {id}, error}` from `resendClient.emails.send()`; the call chain commits to `Promise<void>` at `sendEmailWithRetry` (`functions/src/utils/emailRetry.ts:39`) which discards `result.data.id` from every callsite.

### 2.1 Mid-session update — commit `643403d6` + `3db8e76e` (2026-05-23)

While this audit was in progress, two commits landed on the `chore/migrate-email-templates-through-wrapper` branch (not yet merged to `main` as of write-time) that partially address audit/26 PR-B Option B:

- **`3db8e76e` security(email): CRLF + header-injection guards on Resend boundary** — adds `assertSafeHeader` + `validateRecipient` to `sendEmailWithValidation`, signature confirmed `Promise<string | undefined>` (returns Resend message id).
- **`643403d6` security(email): route 18 templates through guarded wrapper** — migrates ALL 18 V2 senders from inlined `resendClient.emails.send({...})` to `sendEmailWithValidation(resendClient, {...})`. **`provider_id` is now reachable** via the wrapper's return value.

**But the matrix below still stands.** Inspection of `functions/src/email/templates/booking-approved.ts` (post-migration) shows:

```ts
export async function sendBookingApprovedEmailV2(...): Promise<void> {
  ...
  await sendEmailWithValidation(resendClient, {...});  // ← returns Promise<string | undefined>
}                                                         //   but template throws it away
```

The template still declares `Promise<void>` and discards the wrapper's return. **0/18 templates surface the id to their callers today.** Only `email-verification.ts` peeks at it for a debug-console log (per commit message).

**Effect on PR-B (audit/26 §5.7) scope:**

| What's done by `643403d6` | What still remains for `provider_id` capture |
|---|---|
| ✅ All 18 templates call `sendEmailWithValidation` (wrapper is the single chokepoint) | ❌ Template exports still `Promise<void>` — change to `Promise<string \| undefined>` in 18 files |
| ✅ Wrapper signature returns `Promise<string \| undefined>` | ❌ `emailService.ts` wrappers (15 functions) still `Promise<void>` — propagate |
| ✅ Header-injection + recipient validation now uniform | ❌ `sendEmailWithRetry` (`functions/src/utils/emailRetry.ts`) — generic over `T` so it works either way; type signature OK |
| | ❌ 3 `emails_sent.*` writes (`bookingManagement.ts:342, 404, 497`) — add `provider_id: providerId ?? null` |
| | ❌ `EmailSent` interface (`bookingHelpers.ts:8`) — extend with `provider_id?: string \| null` |

PR-B remaining surface ≈ **18 template signature edits + 15 emailService.ts wrapper signature edits + 3 emails_sent.* write sites + 1 interface field**. Smaller than the pre-migration estimate in audit/26 §5.7 (which assumed all 18 inlined sends would need to be migrated AS PART OF PR-B).

**Column key:**
- `chain returns id?` — does the wrapper's TypeScript signature propagate the Resend message id back?
- `emails_sent.* write?` — is there a Firestore `emails_sent.<key>` write tied to this template?
- `provider_id field?` — IF a write exists, does it include `provider_id`?
- `active CF caller?` — does any deployed trigger/callable/schedule invoke this template? (NEW column)

| # | Template (file) | V2 sender | Trigger entry point | chain returns id? | `emails_sent.*` write? | `provider_id` field? | active CF caller? | Spot-check? |
|---|---|---|---|---|---|---|---|---|
| 1 | `booking-confirmation.ts` | `sendBookingConfirmationEmailV2` | `atomicBooking.createBookingAtomic:1325` + `stripePayment.handleStripeWebhook:~1300` + `resendBookingEmail` (callable) + `resendGuestBookingEmail` (callable) | ❌ | ❌ (audit/26 §5.4 lists `confirmation` as `emails_sent.confirmation` to be added in PR-A) | n/a | ✅ | **YES** (callable) |
| 2 | `booking-approved.ts` | `sendBookingApprovedEmailV2` | `bookingManagement.onBookingStatusChange:320` + `stripePayment.handleStripeWebhook:1300` | ❌ | ✅ `emails_sent.approval` (`bookingManagement.ts:342`) | ❌ | ✅ | **YES** (status flip) |
| 3 | `booking-rejected.ts` | `sendBookingRejectedEmailV2` | `bookingManagement.onBookingStatusChange:388` | ❌ | ✅ `emails_sent.rejection` (`bookingManagement.ts:404`) | ❌ | ✅ | **YES** (status flip + reason) |
| 4 | `pending-request.ts` | `sendPendingBookingRequestEmailV2` | `atomicBooking.createBookingAtomic:1250` | ❌ | ❌ (audit/26 §5.4 — to be added in PR-A as `emails_sent.pending_request`) | n/a | ✅ | indirect (callable, manual-approve flag) |
| 5 | `pending-owner-notification.ts` | `sendPendingOwnerNotificationEmailV2` | `atomicBooking.createBookingAtomic:1283` | ❌ | ❌ | n/a | ✅ | indirect |
| 6 | `owner-notification.ts` | `sendOwnerNotificationEmailV2` | `atomicBooking.createBookingAtomic:1383` + `stripePayment.handleStripeWebhook:1328` | ❌ | ❌ | n/a | ✅ | indirect (fires with #1) |
| 7 | `guest-cancellation.ts` | `sendGuestCancellationEmailV2` | `bookingManagement.autoCancelExpiredBookings:114` (schedule) + `bookingManagement.onBookingStatusChange:476` + `guestCancelBooking:384` (callable) | ❌ | ✅ `emails_sent.cancellation` (`bookingManagement.ts:497`) | ❌ | ✅ | YES via `guestCancelBooking` |
| 8 | `owner-cancellation.ts` | `sendOwnerCancellationEmailV2` | none active (wrapper `sendOwnerCancellationNotificationEmail` in `emailService.ts:647` has no CF caller) | ❌ | ❌ | n/a | **❌ DORMANT** | n/a |
| 9 | `refund-notification.ts` | `sendRefundNotificationEmailV2` | none active (wrapper `sendRefundNotificationEmail` in `emailService.ts:702` has no CF caller) | ❌ | ❌ | n/a | **❌ DORMANT** | n/a |
| 10 | `check-in-reminder.ts` | `sendCheckInReminderEmailV2` | none active (`scheduledPushNotifications.checkInTomorrowReminder` uses **push** path, sets `checkInReminderSent` but no email) | ❌ | ❌ | n/a | **❌ DORMANT** | n/a |
| 11 | `check-out-reminder.ts` | `sendCheckOutReminderEmailV2` | none active (`scheduledPushNotifications.checkOutTodayReminder` uses **push** path) | ❌ | ❌ | n/a | **❌ DORMANT** | n/a |
| 12 | `payment-reminder.ts` | `sendPaymentReminderEmailV2` | none active (`scheduledPushNotifications.pendingPaymentReminder` uses **push** path) | ❌ | ❌ | n/a | **❌ DORMANT** | n/a |
| 13 | `overbooking-detected.ts` | `sendOverbookingDetectedEmailV2` | `overbookingNotifications:127` (Firestore trigger on iCal block-detected) | ❌ | ❌ | n/a | ✅ | difficult (needs iCal conflict state) |
| 14 | `email-verification.ts` | `sendEmailVerificationEmailV2` | `emailVerification.sendEmailVerificationCode:56` (callable) | ❌ | ❌ (verification has its own state in `users.email_verification_*` fields, not `emails_sent`) | n/a | ✅ | **YES** (callable) |
| 15 | `password-reset.ts` | `sendPasswordResetEmailV2` | `passwordReset.sendPasswordResetEmail:58` (callable) | ❌ | ❌ | n/a | ✅ | **YES** (callable) |
| 16 | `custom-email.ts` | `sendCustomGuestEmailV2` | `customEmail.sendCustomEmailToGuest:20` (callable) | ❌ | ❌ | n/a | ✅ | **YES** (callable) |
| 17 | `trial-expiring-soon.ts` | `sendTrialExpiringSoonEmailV2` | `trial/sendTrialExpirationWarning:23` (`onSchedule` daily, 7/3/1-day window) | ❌ | ❌ | n/a | ✅ | difficult (date-gated) |
| 18 | `trial-expired.ts` | `sendTrialExpiredEmailV2` | `trial/checkTrialExpiration:21` (`onSchedule` daily) | ❌ | ❌ | n/a | ✅ | difficult (date-gated) |

**Summary roll-up:**

| Metric | Count | Pct |
|---|---|---|
| Templates with `provider_id` captured | 0 / 18 | 0% |
| Templates with any `emails_sent.*` write today | 3 / 18 | 17% (approval, rejection, cancellation) |
| Templates DORMANT (no active CF caller) | 5 / 18 | 28% (owner-cancellation, refund-notification, check-in-reminder, check-out-reminder, payment-reminder) |
| Templates spot-checkable on-demand (callable, no time/state gating) | 6 / 18 | 33% (confirmation, approval, rejection, verification, password-reset, custom-email) |
| Templates date/state-gated (need fixtures) | 5 / 18 | 28% (pending-request indirect, pending-owner-notification, owner-notification indirect, overbooking-detected, trial-expiring-soon, trial-expired) |
| Templates trigger-fireable but flow-coupled | 1 / 18 | guest-cancellation via `guestCancelBooking` callable |

---

## 3. NEW FINDING — 5 DORMANT templates

`owner-cancellation`, `refund-notification`, `check-in-reminder`, `check-out-reminder`, `payment-reminder` — these V2 templates exist with full styles + helpers + `send*EmailV2` exports, but **no deployed Cloud Function invokes them**.

### 3.1 Evidence

```
$ grep -rn "sendOwnerCancellationNotificationEmail|sendRefundNotificationEmail|\
sendPaymentReminderEmail|sendCheckInReminderEmail|sendCheckOutReminderEmail" \
  functions/src --include="*.ts" | grep -v "emailService.ts" | grep -v "/email/"
(0 hits — only declarations in emailService.ts itself)
```

The wrappers exist at `functions/src/emailService.ts:647/702/799/862/926` but have zero external callers. The corresponding scheduled functions in `functions/src/scheduledPushNotifications.ts` (`checkInTomorrowReminder:47`, `checkOutTodayReminder:155`, `pendingPaymentReminder:262`) use the **push notification** path (FCM), not email — they set `checkInReminderSent` / `checkOutReminderSent` / `paymentReminderSent` flags but never call any email function.

### 3.2 Impact

| Class | Impact |
|---|---|
| Dead code surface | ~750 LOC across 5 template files + 5 wrapper functions in `emailService.ts` |
| Maintenance burden | PR-B (audit/26 §5.7) touches all 5 unnecessarily if "migrate all 18" framing is taken literally; can scope down to 13 |
| Product gap | Owners do not receive email cancellation/refund confirmations. Guests do not receive email reminders. **This may be intentional (push-only)** — needs product confirmation before code cleanup. |

### 3.3 Recommendation

Two options were considered:

- **Option A — confirm intentional + delete dead code.** Delete 5 template files + 5 wrappers in `emailService.ts` + 5 V2 exports in `email/index.ts`. ~1–2h work, narrow PR. Scope down PR-B to 13 templates.
- **Option B — wire missing CFs.** If product wants email parity with push (e.g., guests who opted out of push still get reminders), add CF calls inside `scheduledPushNotifications.{checkInTomorrowReminder,checkOutTodayReminder,pendingPaymentReminder}` + add cancellation/refund email send into `bookingManagement.onBookingStatusChange` and `stripePayment.handleStripeWebhook` (refund path).

### 3.4 Resolution — Option A landed via PR #462 (2026-05-24)

PR #462 (`hotfix/role-escalation-deploy-unblock`, Terminal G — multi-fix atomic hotfix) bundles the dormant-5 deletion among other security fixes. Verified via `gh pr diff 462 --name-only`: all 5 template files (`owner-cancellation.ts`, `refund-notification.ts`, `check-in-reminder.ts`, `check-out-reminder.ts`, `payment-reminder.ts`) are in the diff.

Terminal F's draft branch `chore/delete-dormant-5-email-templates` (commit `0e49f254`, never pushed) was made redundant and dropped 2026-05-24 (`git branch -D`). The tsc + Jest verification from the dropped branch (161/4 Jest, 4 failures pre-existing-on-main in `stripeConnect.test.ts`, no regression) is documented in `memory/dormant-5-email-templates.md`. Reflog retains `0e49f254` for 90 days if PR #462 has issues.

PR-B scope shrinks: 18 → 13 templates touched in the eventual `provider_id` capture migration (audit/26 §5.7).

---

## 4. Resend dev delivery — spot-check plan (6 templates)

⏳ **PENDING RESEND_API_KEY (dev)** — script written, execution blocked.

### 4.1 Spot-check selection

| # | Template | Trigger | Trigger mechanism | Recipient |
|---|---|---|---|---|
| 1 | `booking-confirmation` | Direct call: `createBookingAtomic` (auto-confirm flow) | callable | seeded guest email |
| 2 | `booking-approved` | Firestore write: `bookings/{id}.status = "confirmed"` (was pending) | Firestore trigger | seeded guest email |
| 3 | `booking-rejected` | Firestore write: `bookings/{id}.status = "cancelled"` + `rejection_reason` | Firestore trigger | seeded guest email |
| 4 | `email-verification` | Direct call: `sendEmailVerificationCode` | callable | seeded test owner email |
| 5 | `password-reset` | Direct call: `sendPasswordResetEmail` | callable | seeded test owner email |
| 6 | `custom-email` | Direct call: `sendCustomEmailToGuest` | callable | seeded guest email |

### 4.2 Trigger script

→ `scripts/trigger-6-spot-check.js` (to be created at execution time — see §8).

### 4.3 Resend API verification

For each trigger, capture from Resend `GET https://api.resend.com/emails/{id}`:

| Field | Source |
|---|---|
| `id` | Resend message id (would-be `provider_id`) |
| `to` | recipient (seeded guest/owner email) |
| `subject` | rendered subject line |
| `last_event` | `delivered` / `bounced` / `complained` / etc. |
| `created_at` | Resend-side timestamp |

Note: Resend API does NOT expose render screenshots or DKIM-pass-per-message — DKIM/SPF are domain-level (verified once via DNS lookup in §5).

⏳ Data table populated post-execution.

---

## 5. SPF / DKIM / DMARC for `bookbed.io` — DNS verification (executed `2026-05-23`)

| Record | Status | Value | Finding |
|---|---|---|---|
| SPF | **⚠ does not reference resend.com** | `v=spf1 include:_spf.mx.cloudflare.net include:amazonses.com ~all` | Resend sends from bookbed.io but is NOT in the SPF include list. **Deliverability risk** — see §5.1. |
| DKIM (`resend._domainkey.bookbed.io`) | ✓ present | 1 record | Resend DKIM signing verified in DNS. |
| DMARC (`_dmarc.bookbed.io`) | ✓ present, **p=none** (monitoring only) | `v=DMARC1; p=none;` | No enforcement policy. With DKIM-only alignment, mail still passes DMARC (relaxed mode default). |

### 5.1 Finding — SPF does not include `_spf.resend.com` 🆕

The SPF record on `bookbed.io` lists `_spf.mx.cloudflare.net` + `amazonses.com` as authorized senders, but not Resend. Implications:

- **DMARC pass via DKIM alignment is still possible.** `p=none` + DKIM signed = `dmarc=pass` for receivers that allow DKIM-only alignment (most major receivers).
- **SPF `softfail` on receivers checking SPF directly.** Some spam filters (Postfix, Spamhaus, legacy MTAs) treat SPF mismatch as a deliverability signal — net effect: higher chance of junk folder, lower inbox placement rate.
- **AmazonSES include suggests prior SES setup**, possibly legacy. Worth confirming whether SES is still used; if not, remove to tighten the record.

**Recommended fix (P3 follow-up, ~5min):**
```
v=spf1 include:_spf.mx.cloudflare.net include:_spf.resend.com ~all
```
(Drop `amazonses.com` if SES is no longer in use; if it IS still in use for some transactional path, leave it and add Resend alongside.)

This is a **deliverability optimization**, not a correctness bug. Mail still flows; just lower inbox placement than it could have.

### 5.2 DMARC `p=none` is acceptable for now

`p=none` is the standard ramp-up policy. Once SPF includes Resend and you've watched DMARC aggregate reports for 1-2 weeks with no legitimate-source failures, progress to `p=quarantine` → `p=reject`. Out-of-scope for this audit; flag for the email-deliverability backlog.

---

## 6. Fail-CLOSED widget recipe (user-driven)

Reference baseline: `audit/22-prod-cutover-plan.md` §6 verified fail-CLOSED on T11c via empirical proof. This recipe re-verifies on dev env.

### 6.1 Setup

1. Open `https://book-bed.com/widget/{ownerSubdomain}?unit_id={unitId}` (or local `flutter run -d chrome -t lib/widget_main_dev.dart` if testing dev build) in Chrome.
2. Wait for widget to fully load (unit cover image visible, date picker enabled).
3. Open DevTools (`Cmd+Opt+I`) → **Network** tab.
4. In Network filter, type `getUnitAvailability` — confirm at least one outbound call lands during page load (`Status 200`).

### 6.2 Block the CF endpoint

5. DevTools → **Network** → click ⋮ (more options) → **Block request URL**.
6. Add pattern: `*getUnitAvailability*`. Click Add.
7. Disable network throttling (if any).
8. **Hard-refresh** the widget page (`Cmd+Shift+R`).

### 6.3 Attempt booking — observe blocked state

9. Pick check-in date, check-out date, fill guest count + name + email + phone.
10. Click **"Pošalji rezervaciju"** (Submit booking).
11. **Expected outcome (PASS):** UI shows error state — typically a snackbar/toast: `"Trenutno ne možemo provjeriti dostupnost. Pokušajte ponovo."` or equivalent. The booking submission MUST NOT proceed. `availability_checker.dart` short-circuits before any write attempt to `bookings/`.
12. **FAIL signal:** if booking submits anyway, file as P0 incident — fail-CLOSED gate broken.

### 6.4 Verify in Firestore + Resend

13. After step 11 (PASS path): open Firebase Console → `bookbed-dev` → Firestore → `properties/{pid}/units/{uid}/bookings/` → confirm NO new booking doc with `created_at >= step-11-timestamp`.
14. Check Resend logs (or API): NO `booking-confirmation` email sent during step-11 window.

### 6.5 Cleanup

15. DevTools → Network → Block request URL → remove the `getUnitAvailability` block.
16. Hard-refresh once more to confirm widget recovers (booking flow becomes functional again).

**Report back to this audit:** PASS / FAIL + DevTools console screenshot + timestamp. Anomalies → log as section §9 entries.

---

## 7. Sentry 24h baseline — query plan

⏳ **PENDING SENTRY_AUTH_TOKEN + org/project slug (dev)** — query strings ready, execution blocked.

### 7.1 Targets

Per task scope:
- `getUnitAvailability` CF (T11c hot-path)
- `atomicBooking.createBookingAtomic` CF
- Widget initial load (Flutter Sentry SDK)

### 7.2 Metrics (24h rolling, dev project only)

| # | Metric | API query | Expected dev value |
|---|---|---|---|
| 1 | Overall error rate | `GET /api/0/organizations/{org}/stats_v2/?statsPeriod=24h&field=sum(quantity)&groupBy=outcome` | low single-digit / minute (dev = noisy from manual testing) |
| 2 | Top 5 issues (Flutter + CF) | `GET /api/0/projects/{org}/{proj}/issues/?statsPeriod=24h&sort=freq&limit=5` | enumerate w/ short_id |
| 3 | P95 transaction latency — `getUnitAvailability` | `GET /api/0/organizations/{org}/events/?field=transaction&field=p95(transaction.duration)&query=transaction:getUnitAvailability&statsPeriod=24h` | target: <600ms (T11c says polling = 30s, but single call should be <600ms) |
| 4 | P95 latency — `createBookingAtomic` | `GET .../events/?field=p95(transaction.duration)&query=transaction:createBookingAtomic&statsPeriod=24h` | target: <2000ms (writes + email send chain) |
| 5 | Widget initial load — `app.start` | `GET .../events/?field=p95(transaction.duration)&query=transaction:app.start+platform:flutter&statsPeriod=24h` | target: <3000ms (cold) |
| 6 | SF-026 normalize exception count | `GET .../events/?field=count_unique(issue)&query="normalizeToZagrebCivilDayUTC"+OR+"validateAndConvertBookingDates"&statsPeriod=24h` | target: 0 (per T11c proof, SF-026 transactions clean) |

### 7.3 HttpsError filter caveat

Per `.claude/rules/cloud-functions.md` § "HttpsError client-fault filter (since 6.71)": Sentry `beforeSend` DROPs `HttpsError` events with client-fault codes (`invalid-argument`, `unauthenticated`, etc.). When reading top-issue counts, remember 4xx-class errors are filtered — visible counts reflect server-class only (`internal`, `unknown`, `data-loss`, `unavailable`, `deadline-exceeded`, `aborted`).

⏳ Data tables populated post-execution.

---

## 8. Execution checklist + handoff commands

This session produced the static report (§0–§5 + §6 recipe). Dynamic verification (Resend correlation + Sentry baseline) is gated on tokens and is run via three scripts dropped in `scripts/`. The complete handoff sequence:

### 8.1 Trigger 6 templates via deployed `bookbed-dev` CFs

```bash
gcloud auth application-default login  # one-time, if not set
node scripts/trigger-6-spot-check.js \
  --guest-email='<addr-you-control>' \
  --owner-email='bookbed-test@bookbed.io' \
  [--web-api-key='<firebase-web-api-key>']  # optional, for custom-email
```

Output: `audit/trigger-spot-check-<ts>.json` with booking IDs + fire timestamps.

**Schema verification** — the script's call shapes were verified against:
- `functions/src/atomicBooking.ts:100-119` — `createBookingAtomic` accepts **camelCase** `{unitId, propertyId, checkIn, checkOut, guestName, guestEmail, guestPhone, guestCount, totalPrice, paymentMethod, requireOwnerApproval}`. `paymentMethod='none'` is the auto-confirm pay-on-arrival path that sends `booking-confirmation`. Return shape: `{success, bookingId, bookingReference, ...}`.
- `functions/src/bookingManagement.ts:278` — approval email **requires `after.approved_at` to be set** alongside the pending→confirmed transition (idempotency-tagged via `emails_sent.approval`). The script writes both `status: 'confirmed'` and `approved_at: serverTimestamp()`.
- `functions/src/bookingManagement.ts:362` — rejection email **requires `after.rejection_reason`** alongside pending→cancelled. The script writes both.

Notes:
- Refuses prod (`rab-booking-248fc`) by name.
- For #4 (`email-verification`) and #5 (`password-reset`), use an inbox you control (anti-spam — both send real codes/tokens).
- For #6 (`custom-email`), the Firebase Web API key is needed to mint a Firebase Auth ID token for `OWNER_UID=Zo01CJ3wymb0pplaYOyaZ2yGUWG2` (per `memory/test-account.md`). Omit → step skipped.
- Approval/rejection paths create temporary pending bookings under `properties/SEED_property_dev_01/units/SEED_unit_dev_01/bookings/` and flip them. They leave debris; clean up afterward if needed.

### 8.2 Correlate to Resend + verify DNS

```bash
RESEND_API_KEY='re_...' node scripts/resend-verify-spot-check.js
# or
node scripts/resend-verify-spot-check.js --api-key='re_...' --domain=bookbed.io
```

Output: `audit/resend-correlation-<ts>.md` — picks up the latest manifest from §8.1, queries Resend list-emails (`GET /emails`), correlates by `to` + 70-second time window around `fired_at`.

For dry-run DNS only (no token):
```bash
node scripts/resend-verify-spot-check.js --dry-run --domain=bookbed.io
```

### 8.3 Sentry 24h baseline

```bash
SENTRY_AUTH_TOKEN='sntrys_...' node scripts/sentry-baseline.js \
  --org='<dev-org-slug>' \
  --cf-project='<cf-project-slug>' \
  --flutter-project='<flutter-project-slug>'
```

Output: `audit/sentry-baseline-<ts>.md` — 4 metric groups + raw response samples.

Required token scope: `org:read` + `project:read`. Script refuses any org slug matching `/prod|live|main/i` unless `--i-know-this-is-not-prod` is passed.

### 8.4 Fail-CLOSED widget — §6 recipe

User-driven. After completion, append PASS/FAIL + DevTools console screenshot + timestamp to §9 below.

### 8.5 Final synthesis

Roll the three outputs back into this doc:
- §4.3 → from `audit/resend-correlation-<ts>.md` table
- §5 → already filled (this session)
- §7 → from `audit/sentry-baseline-<ts>.md`
- §6 outcome → manual paste

---

## 9. Anomalies (filled post-execution)

### 9.1 Pre-execution anomalies (this session)

| # | Anomaly | Severity | Source | Next step |
|---|---|---|---|---|
| A1 | SPF on `bookbed.io` does not include `_spf.resend.com` | LOW (deliverability optimization) | §5.1 DNS lookup | P3 backlog: tighten SPF, drop `amazonses.com` if unused |
| A2 | 5 V2 email templates DORMANT — no active CF caller | LOW (dead code OR feature gap) | §3 grep analysis | Product confirms intentional → delete OR wire missing CFs |
| A3 | audit/26 "21 templates" claim mismatches actual 18 V2 templates | LOW (doc correctness) | §0.1 ls count | audit/26 §1 + §5.4 + §5.6 + §5.7 + §6 callouts can be corrected to "18" in PR-B description |
| A4 | Sender domain claim mismatch — task said `book-bed.com`, actual is `bookbed.io` | LOW (terminology) | §0 env inspection | None — clarify in future task definitions |

### 9.2 Post-execution anomalies

⏳ none yet — append after §8.1–§8.4 runs.

---

## 10. Sign-off

| Section | State |
|---|---|
| §0 discrepancies | ✅ done |
| §1 executive summary | ✅ done |
| §2 18-template matrix (static) | ✅ done |
| §3 DORMANT-5 finding | 🆕 done |
| §4 Resend spot-check plan | ✅ plan; ⏳ data |
| §5 SPF/DKIM/DMARC | ✅ done (DNS verified) — SPF gap (A1) flagged |
| §6 fail-CLOSED recipe | ✅ done — awaits user execution |
| §7 Sentry baseline plan | ✅ plan; ⏳ data |
| §8 handoff commands | ✅ done |
| §9 anomalies | ✅ §9.1 (4 pre-execution); ⏳ §9.2 |
| Scripts ready: `trigger-6-spot-check.js`, `resend-verify-spot-check.js`, `sentry-baseline.js` | ✅ |

**Status:** Self-contained handoff document. Three new findings surface from the static-analysis pass alone (A1 SPF gap, A2 dormant templates, A3 count discrepancy). Dynamic verification awaits credentials + ~15min of execution time.
