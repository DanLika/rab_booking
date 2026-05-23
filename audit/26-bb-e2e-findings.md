# audit/26 — BB E2E findings consolidation

**Date:** 2026-05-23
**Scope:** Consolidates BB E2E flow results (bookbed-dev, Phase 2 direct-write probe) + LL deep-dive investigation outputs. Becomes input for follow-up PR scoping.
**Status:** DOC ONLY. Five findings catalogued. Two PR groups recommended (PR-A, PR-B). One architectural item deferred. Two fixture gaps surfaced.
**Cross-refs:** `audit/25-e2e-test-catalog.md` (test inventory), `audit/22-prod-cutover-plan.md` §6 (PROD cutover risk register — orthogonal surface, see §8).

---

## 1. Executive summary

| # | Finding | Severity | Scope | Recommended PR group |
|---|---|---|---|---|
| #4 | Owner direct-write bypass (skips atomicBooking overlap + SF-026) | **HIGH** | 5 UI write paths | own PR-A (CF + repository refactor) |
| #4-corollary | `emails_sent.*` idempotency reads never SET 3 of 6 keys | MEDIUM | confirmation + bank_transfer + pending_request | fold into PR-A |
| #4-meta | 2 booking repositories coexist (one FROZEN per CLAUDE.md) | LOW (architectural) | repo dedup | defer, separate refactor sprint |
| #1 | `provider_id` never captured from Resend send result | MEDIUM | 18 v2 templates (audit/28 §0.1 recount — earlier "21" likely included 2 aliases `sendBookingCancellationEmail`/`sendCustomEmailToGuest` + 1 inlined Stripe path) + 3 booking events | own PR-B (Option B) |
| #5 | `nights` field not written on direct write | LOW UX | display only | auto-resolves with #4 fix |

**Hot summary:** Owner-side workflows have a serious overlap-bypass class (BB Phase 2 confirmed direct-write lands cleanly). PROD cutover (audit/22) tightens UNAUTHENTICATED reads — different surface, ships safely. Post-cutover follow-up: PR-A (HIGH) + PR-B (MEDIUM) in parallel.

---

## 2. Finding #4 — Owner direct-write bypass (HIGH)

### 2.1 Empirical evidence (BB Phase 2)

Direct firebase-admin write to
`properties/SEED_test_owner_property_01/units/SEED_test_owner_unit_01/bookings/{auto-id}`
**succeeded**:

- Firestore rules permit owner-context writes (`request.auth.uid == property.owner_id`).
- `onBookingCreated` Firestore trigger fires (status-change flow observed working).
- BUT the overlap check at `functions/src/atomicBooking.ts:743` is **NEVER invoked** on direct writes — it lives inside the `createBookingAtomic` callable, not the trigger.
- CF availability immediately reflected the booking (windows array populated).
- `getUnitAvailability` returned `source: "booking"` — confirms CG query path.

**Conclusion:** A second concurrent direct write with overlapping dates would NOT be blocked. No transaction is running.

### 2.2 Affected UI paths (5 direct-write surfaces)

Source: `/tmp/finding-4-investigation.md` (consolidated into this table).

| # | UI flow | File:line | Repository method | SF-026 applied? | Overlap-check on server? | Risk class |
|---|---|---|---|---|---|---|
| 1 | **Add manual booking** dialog (Save tap) | `lib/features/owner_dashboard/.../booking_create_dialog.dart:836` | `repository.createBooking(booking)` → `firebase_booking_repository.dart:122` (bare `.add()`) | ❌ | ❌ | 🔴 Worst offender — net-new doc, no server validation |
| 2 | **Edit booking** dialog (desktop) | `lib/features/owner_dashboard/.../edit_booking_dialog.dart:~720` | open-coded `firestore.runTransaction → transaction.update({check_in, check_out, ...})` | ❌ | ❌ | 🔴 Owner can shift dates onto another booking |
| 3 | **Inline edit** dialog (calendar) | `lib/features/owner_dashboard/.../booking_inline_edit_dialog.dart:~700` | same pattern as #2 | ❌ | ❌ | 🔴 Same as #2 |
| 4 | **Drag-and-drop** booking move (calendar) | `lib/features/owner_dashboard/.../calendar_drag_drop_provider.dart:194, :249` | `_bookingRepository.updateBooking(updatedBooking, originalBooking: booking)` | ❌ | ❌ (only in-memory `BookingOverlapDetector.validateBookingMove`) | 🔴 Move with date/unit change, race with widget guest submission |
| 5 | **Move-to-unit** (action menu) | `lib/features/owner_dashboard/.../booking_action_menu.dart:875` | `bookingRepo.updateBooking(updatedBooking, originalBooking)` | ❌ | ❌ (pre-check `areDatesAvailable` is racey: CG read + check + write, no txn) | 🔴 Cross-unit moves can collide |

**Lower-risk siblings (date-unchanged, status-only):**

| flow | file:line | classification |
|---|---|---|
| Status change (action menu) | `calendar_booking_actions.dart:127` | ⚠️ Bypass but no overlap concern — only status flip |
| Multi-select status change | `multi_select_action_bar.dart:202` | ⚠️ Same — clobbers entire toJson() back |
| Multi-select bulk delete | `multi_select_action_bar.dart:287` | ✅ Delete-only — no overlap concern |
| Legacy owner_repo status flips | `firebase_owner_bookings_repository.dart:845, 885, 928, 954, 983, 1008` | ⚠️ Status only; goes through trigger so Finding #1 also applies here |

**Block-dates feature:** Not present on owner side as "fake booking" writes. `blockedDates` only lives in `unit_wizard_state` (unit-level config field). iCal `BLOCK` events come server-side via `functions/src/icalSync.ts`. **No bypass risk on this axis.**

**Bulk/CSV import:** No CSV import path or batch booking-move repository method found.

### 2.3 SF-026 normalization coverage gap

`validateAndConvertBookingDates` + `normalizeToZagrebCivilDayUTC` + `calculateBookingNights` (defined in `functions/src/utils/dateValidation.ts`) are called ONLY by:

- `functions/src/atomicBooking.ts:329` (createBookingAtomic — guest widget path)
- `functions/src/stripePayment.ts:424` (Stripe checkout path)
- `functions/src/verifyBookingAccess.ts:168` (read-side calculation only)
- `functions/src/getBookingByStripeSession.ts:92` (read-side calculation only)

**Zero owner-side Cloud Functions call this normalization.** All owner edits write raw `Timestamp.fromDate(_checkIn)` (where `_checkIn` is Dart local-midnight from the date picker).

Consequence: owner-created/edited bookings carry inconsistent nights calculations from the moment they're saved. checkIn/checkOut stored as Dart local-midnight Timestamps, never converted to Zagreb-civil-day UTC.

### 2.4 Recommended fix path — two options

#### Option 1 — Route all 5 paths through Cloud Functions (RECOMMENDED)

- New callable `createOwnerBookingAtomic` in `functions/src/atomicBooking.ts` (manual booking — identical to `createBookingAtomic` but skips payment, routes `source: 'admin'`).
- New callable `updateBookingAtomic`. Accepts `{bookingId, checkIn, checkOut, unitId, guestCount, totalPrice, notes, status}` (only fields the owner can change). Inside, runs a Firestore txn that re-checks overlap against `bookings` CG with `whereIn: [pending, confirmed]`, excluding `bookingId`. Throws `failed-precondition` on conflict.
- Tighten Firestore rules: in `bookings` update rule, disallow client writes to `check_in`, `check_out`, `unit_id` (only the CF, running as admin, can change these). Status flips can stay client-side.
- Route owner edits through `validateAndConvertBookingDates` so SF-026 nights normalization applies uniformly (also auto-resolves Finding #5).

**Pros:** Uniform overlap guarantee, free SF-026 normalization, explicit single source of truth.
**Cons:** 5 client refactors + CF API design. Risk: medium — owner workflow regression possible.

#### Option 2 — Server-side trigger that REJECTS direct writes

- Add a Firestore trigger on `onBookingCreated` / `onBookingUpdated` that checks for `write_origin` claim or similar marker; rejects if missing.
- Lighter implementation per fix site, but adds denial-path UX work (rollback after-the-fact in UI), and trigger fires AFTER commit so race window persists until the rollback lands.

**Pros:** No CF API design needed.
**Cons:** Fragile — rejection runs AFTER write lands (~hundreds of ms race window where availability shows wrong); UX rollback complexity; doesn't fix SF-026 gap.

**Recommendation: Option 1.** Explicit routing through CF gives uniform overlap guarantee + SF-026 normalization free. Trigger-based denial doesn't close the race.

### 2.5 PR-A strategy

Scope: lift 5 UI paths onto CF route. Sequence:

1. Identify shared write helper in `lib/features/owner_dashboard/services/` (or extend `lib/shared/repositories/firebase/firebase_booking_repository.dart`).
2. Create new helper wrapping `createOwnerBookingAtomic` + `updateBookingAtomic` callables.
3. Migrate paths one-by-one with feature-flag fallback for safety.
4. Smoke each migration on bookbed-dev (BB Phase 2 recipe — see audit/25 §iCal).
5. Remove direct-write code paths once all 5 green.
6. Tighten Firestore rules to disallow client writes to `check_in/check_out/unit_id` (sequenced AFTER all clients migrated).

Effort: **M (~6-10h)**. Risk: medium.

---

## 3. Finding #4-corollary — Idempotency keys never SET (MEDIUM)

`BookingEmailTracking` interface (`functions/src/utils/bookingHelpers.ts:29`) declares **6 keys**:

```typescript
export interface BookingEmailTracking {
  approval?: EmailSent;
  rejection?: EmailSent;
  cancellation?: EmailSent;
  confirmation?: EmailSent;              // ← never SET
  bank_transfer_instructions?: EmailSent; // ← never SET
  pending_request?: EmailSent;            // ← never SET
}
```

Only the first three are ever WRITTEN (all in `bookingManagement.ts:342, 404, 497`). The remaining three have idempotency READS that check for duplicate sends but the keys never get SET, so the duplicate guard is a no-op on retry.

Most painful gap: `confirmation` (initial guest booking-created email sent from `atomicBooking.ts:1325`) and `bank_transfer_instructions` — both are exactly the senders most at risk of retry-driven duplicate delivery (network blip during widget POST, Stripe webhook retry).

**Fix sketch (~3 lines per site):**

```typescript
// After successful sendBookingConfirmationEmail, atomicBooking.ts:1325-ish:
await bookingRef.update({
  "emails_sent.confirmation": {
    sent_at: admin.firestore.FieldValue.serverTimestamp(),
    email: bookingData.guest_email,
    booking_id: bookingRef.id,
    provider_id: providerId ?? null,   // ← bundle with PR-B Option B too
  },
});
```

Same shape for `bank_transfer_instructions` (after bank-transfer email send in atomicBooking) and `pending_request` (pending-request flow).

**PR sequencing:** Fold into PR-A (clean code-locality with atomicBooking refactor for #4) OR ship as small standalone PR-A1 (~1h). Either is fine — depends on whether PR-A touches atomicBooking.ts in a way that makes the change trivially adjacent.

---

## 4. Finding #4-meta — Two booking repositories coexist (LOW architectural)

Two parallel Flutter repos with overlapping write surface:

| Repo | Path | Lines | Status |
|---|---|---|---|
| `BookingRepository` impl | `lib/shared/repositories/firebase/firebase_booking_repository.dart` | ~310 | Active, used by all 5 finding-#4 paths |
| `FirebaseOwnerBookingsRepository` (FROZEN) | `lib/features/owner_dashboard/data/firebase/firebase_owner_bookings_repository.dart` | 989 | FROZEN per CLAUDE.md "NIKADA NE MIJENJAJ" — no unit tests |

Both write directly to Firestore. The 989-liner has 6 status/lifecycle methods (`approveBooking`, `rejectBooking`, `confirmBooking`, `cancelBooking`, `completeBooking`, `deleteBooking` at lines 845, 885, 928, 954, 983, 1008) that issue direct `bookingDoc.reference.update(...)`. These trigger `onBookingStatusChange` (where Finding #1 originates).

Architectural debt. **Defer** to dedicated refactor sprint — CLAUDE.md explicitly forbids touching the 989-liner without unit tests. PR-A touches the smaller `BookingRepository` only; the 989-liner survives.

---

## 5. Finding #1 — `provider_id` never captured (MEDIUM)

### 5.1 Not a regression — was never present

`git log --all -S 'provider_id' -- functions/src/` returns **no commits**. The `emails_sent.approval` write block (`bookingManagement.ts:341-347`) was introduced in commit `35f4b8eb` (2025-12-04, "comprehensive security & reliability improvements") and shipped without `provider_id` from day one.

Touched in:
- `35f4b8eb` (2025-12-04) — security & reliability improvements (initial add)
- `5596b837` (2025-11-08) — earlier touch on the try/catch

### 5.2 Why the chain drops the id

Resend SDK returns `{data: {id}, error}` from `resendClient.emails.send()`. The send chain commits to `Promise<void>` and discards `result.data.id`:

```
bookingManagement.onBookingStatusChange
  ↓ sendEmailWithRetry(async () => { ... }, "Booking Approved", email)   ← Promise<void>
  ↓ sendBookingApprovedEmail(...)                                          ← emailService.ts:448, Promise<void>
  ↓ sendBookingApprovedEmailV2(resendClient, params, ...)                  ← booking-approved.ts:158, Promise<void>
  ↓ resendClient.emails.send({...}) → {data: {id}, error}                  ← id present here, dropped on floor
```

`sendEmailWithRetry` (`functions/src/utils/emailRetry.ts:39`) signature: `(emailFunc: () => Promise<void>, ...) => Promise<void>`. Both ends are `void` — id can't survive the call.

### 5.3 Affected `emails_sent.*` writes (all 3 in `bookingManagement.ts`)

| event | file:line | shape today | `provider_id`? |
|---|---|---|---|
| **approval** (pending → confirmed) | `bookingManagement.ts:342` | `{sent_at, email, booking_id}` | ❌ |
| **rejection** (pending → cancelled w/ reason) | `bookingManagement.ts:404` | `{sent_at, email, booking_id}` | ❌ |
| **cancellation** (→ cancelled, no rejection reason) | `bookingManagement.ts:497` | `{sent_at, email, booking_id}` | ❌ |

Identical bug at all 3 sites.

### 5.4 Same drop-on-floor pattern across 21 v2 templates

All 21 v2 template senders in `functions/src/email/templates/*.ts` share the shape:

```typescript
const result = await resendClient.emails.send({...});
const typedResult = result as any;
if (typedResult.error) throw new Error(...);
// returns void — id discarded
```

Senders that don't track at all (no `emails_sent.*` write but still send email):

- `sendBookingConfirmationEmail` (atomicBooking.ts:1325, stripePayment.ts:~1300)
- `sendOwnerNotificationEmail` (atomicBooking.ts:1383, stripePayment.ts:1324)
- `sendPaymentReminderEmailV2` (scheduled)
- `sendCheckInReminderEmailV2`, `sendCheckOutReminderEmailV2` (scheduled)
- `sendOverbookingDetectedEmailV2`
- `sendRefundNotificationEmailV2`
- `sendTrialExpiringSoonEmailV2`, `sendTrialExpiredEmailV2`
- All `email-verification.ts`, `password-reset.ts`, `custom-email.ts`, `pending-request.ts`, etc.

**Ironic existing helper:** `functions/src/email/utils/send-with-validation.ts` already exports `sendEmailWithValidation(...)` with signature `Promise<string | undefined>` that returns `typedResult.data?.id`. **Not a single template caller uses it.**

### 5.5 Fix Option A — Thread id through chain (minimal, narrow)

Change `sendBookingApprovedEmail*` chain + `sendEmailWithRetry` return type to `Promise<string | undefined>`. Bubble up `result.data?.id`. Add `provider_id: providerId ?? null` to the three `emails_sent.*` writes. Also extend `EmailSent` interface in `bookingHelpers.ts:8`.

```typescript
// emailRetry.ts
export async function sendEmailWithRetry<T = void>(
  emailFunc: () => Promise<T>,
  emailType: string,
  recipient: string,
  config: RetryConfig = {}
): Promise<T> { ... }

// EmailSent interface — bookingHelpers.ts:8
export interface EmailSent {
  sent_at: admin.firestore.Timestamp;
  email: string;
  booking_id?: string;
  provider_id?: string | null;
}
```

**Pros:** Narrowest possible change. **Cons:** Only fixes the 3 BookingMgmt sites; other 18 templates still silently drop id.

### 5.6 Fix Option B — Migrate all 21 templates to `sendEmailWithValidation` (RECOMMENDED)

Use the existing helper. Each template's `send*` wrapper returns `Promise<string | undefined>`. Caller surfaces `provider_id` into `emails_sent.*` write where applicable.

**Pros:** Smaller per-template diff, uniform shape across the entire mailer surface, sets infrastructure for future `provider_id`-keyed retry idempotency. **Cons:** Touches all 21 templates (larger PR).

**Recommendation: Option B.** The helper already exists and returns the right shape. Long-term hygiene wins.

### 5.7 PR-B strategy

Scope: migrate all 21 v2 template senders to `sendEmailWithValidation`. Extend `EmailSent` interface with `provider_id`. Surface id at the 3 BookingMgmt sites (and `confirmation` / `bank_transfer_instructions` sites if PR-A-corollary lands together).

Effort: **S (~3-4h)**. Risk: low (mechanical refactor; existing helper already validated by absence-of-other-shape).

---

## 6. Finding #5 — `nights` field not written on direct write (LOW UX)

When BB Phase 2 direct-write landed, the resulting booking doc had no `nights` field. `BookingModel.fromJson` in Dart handles `nights == null` (falls back to calculated value), so it's display-only soft data loss.

Auto-resolves if PR-A lands: `createBookingAtomic` / `updateBookingAtomic` compute nights via `calculateBookingNights(checkIn, checkOut)` server-side after SF-026 normalization. Documented here as **auto-resolve dependency on PR-A** — no separate fix needed.

---

## 7. Fixture gaps surfaced by BB

E2E test runs surfaced two seed-data gaps in `scripts/seed-bookbed-dev.js`:

| Gap | Symptom | Effort |
|---|---|---|
| Stripe Connect test account not seeded | DD (Stripe E2E) flow blocked — no `connect_account_id` on seed owner | XS — add Stripe test-mode `acct_*` seed for `SEED_test_owner` |
| `properties/SEED_test_owner_property_01/widget_settings/SEED_test_owner_unit_01` doc not seeded (nested subcollection, NOT top-level — verified `icalExport.ts:142`) | EE (iCal E2E) flow blocked — `getUnitIcalFeed` 404s | XS — add minimal widget_settings seed |
| Cleanup CG sweep on `bookings.source` needs Firestore index exemption | minor — manual cleanup of test bookings hits CG-query cost | XS — add single-field exemption on `bookings.source` (`firestore.indexes.json`) |

Bundle into a micro-PR (XS) or fold into next seed-script enhancement. Not on critical path for PR-A/PR-B.

---

## 8. PROD cutover (audit/22) implication — orthogonal surface

audit/22 PROD cutover focuses on **UNAUTHENTICATED** read paths (T11c rules tightening for widget availability via callable + bookings rules narrowing). Surface today: anon `getUnitAvailability` callable + tightened CG read rules.

Finding #4 affects **AUTHENTICATED owner writes** (BookingRepository → direct Firestore). Completely orthogonal write-vs-read surface.

**Conclusion: PROD cutover still ships safely.** audit/26 PR-A is post-cutover follow-up. Sequence:

1. Land audit/22 PROD cutover first (closes the unauthenticated overshare surface).
2. Then PR-A + PR-B in parallel.

This separation also keeps PROD cutover blast-radius minimal (rules-only, no client refactor).

---

## 9. PR sequencing recommendation

| PR | Scope | Effort | Risk | Sequence | Notes |
|---|---|---|---|---|---|
| **PR-A** | Finding #4 (5 UI paths → new CF callables) + #4-corollary (set 3 missing `emails_sent.*` keys) + #5 auto-resolve via SF-026 routing | M (~6-10h) | Medium | After current 4 PRs merge | Touches: atomicBooking.ts, new callables, 5 client files, firestore.rules, bookingHelpers.ts |
| **PR-B** | Finding #1 — migrate 21 v2 templates to `sendEmailWithValidation`, capture `provider_id` at 3 BookingMgmt sites (and PR-A new sites if landed) | S (~3-4h) | Low | Parallel with PR-A | Touches: 21 template files, emailRetry.ts type signature, EmailSent interface, 3 callsites in bookingManagement.ts |
| **Defer** | Finding #4-meta — `firebase_owner_bookings_repository.dart` (989 lines FROZEN) repository dedup | L (>1d) | Low (architectural) | Future refactor sprint | Per CLAUDE.md, requires unit-test coverage first |
| **Fixture micro-PR** | Stripe Connect seed + `widget_settings` seed + `bookings.source` CG index exemption | XS (~30m) | None | Whenever DD/EE testing prioritized | Touches: `scripts/seed-bookbed-dev.js`, `firestore.indexes.json` |

---

## 10. Cross-references

- `/tmp/finding-4-investigation.md` — folded into §2-§4. **Deleted post-commit.**
- `/tmp/finding-1-investigation.md` — folded into §5. **Deleted post-commit.**
- `audit/25-e2e-test-catalog.md` "What's tested vs not" — BB findings backfill the AUTHENTICATED-write gap.
- `audit/22-prod-cutover-plan.md` §6 risk register — PROD cutover blast-radius confirmed orthogonal to this audit's findings (§8).
- `CLAUDE.md` NIKADA NE MIJENJAJ — `firebase_owner_bookings_repository.dart` 989-line freeze flag relevant to §4-meta.
- `functions/src/atomicBooking.ts:743` — canonical overlap check that direct writes bypass.
- `functions/src/utils/dateValidation.ts` — SF-026 normalization owner-side paths skip.
- `functions/src/email/utils/send-with-validation.ts` — existing helper that returns `Promise<string | undefined>` (key to PR-B Option B).
- `functions/src/utils/bookingHelpers.ts:29` — `BookingEmailTracking` interface (6 keys declared, 3 ever written).

---

## Appendix A — Exact file:line cross-reference table

| Reference | Path | Purpose |
|---|---|---|
| `bookingManagement.ts:342` | `functions/src/bookingManagement.ts` | `emails_sent.approval` write — missing `provider_id` |
| `bookingManagement.ts:404` | `functions/src/bookingManagement.ts` | `emails_sent.rejection` write — missing `provider_id` |
| `bookingManagement.ts:497` | `functions/src/bookingManagement.ts` | `emails_sent.cancellation` write — missing `provider_id` |
| `atomicBooking.ts:329` | `functions/src/atomicBooking.ts` | `validateAndConvertBookingDates` call — SF-026 in guest widget path |
| `atomicBooking.ts:743` | `functions/src/atomicBooking.ts` | Overlap check inside `createBookingAtomic` — bypassed on direct writes |
| `atomicBooking.ts:1325` | `functions/src/atomicBooking.ts` | `sendBookingConfirmationEmail` — no `emails_sent.confirmation` tracking |
| `atomicBooking.ts:1383` | `functions/src/atomicBooking.ts` | `sendOwnerNotificationEmail` — no tracking |
| `bookingHelpers.ts:8` | `functions/src/utils/bookingHelpers.ts` | `EmailSent` interface — extend with `provider_id` |
| `bookingHelpers.ts:29` | `functions/src/utils/bookingHelpers.ts` | `BookingEmailTracking` interface — 6 keys declared, 3 written |
| `dateValidation.ts` (whole file) | `functions/src/utils/dateValidation.ts` | SF-026 normalization functions |
| `emailRetry.ts:39` | `functions/src/utils/emailRetry.ts` | `sendEmailWithRetry` — `Promise<void>` signature drops id |
| `send-with-validation.ts` (whole file) | `functions/src/email/utils/send-with-validation.ts` | Existing helper returning `Promise<string \| undefined>` — key to PR-B Option B |
| `firebase_booking_repository.dart:122` | `lib/shared/repositories/firebase/firebase_booking_repository.dart` | `.add()` direct write — worst-offender entry point |
| `firebase_owner_bookings_repository.dart:845, 885, 928, 954, 983, 1008` | `lib/features/owner_dashboard/data/firebase/firebase_owner_bookings_repository.dart` | 6 status-lifecycle methods — FROZEN |
| `booking_create_dialog.dart:836` | `lib/features/owner_dashboard/.../booking_create_dialog.dart` | Manual booking Save → BookingRepository.createBooking |
| `edit_booking_dialog.dart:~720` | `lib/features/owner_dashboard/.../edit_booking_dialog.dart` | Desktop edit → open-coded txn.update |
| `booking_inline_edit_dialog.dart:~700` | `lib/features/owner_dashboard/.../booking_inline_edit_dialog.dart` | Calendar inline edit → open-coded txn.update |
| `calendar_drag_drop_provider.dart:194, :249` | `lib/features/owner_dashboard/.../calendar_drag_drop_provider.dart` | Drag-and-drop move → BookingRepository.updateBooking |
| `booking_action_menu.dart:875` | `lib/features/owner_dashboard/.../booking_action_menu.dart` | Move-to-unit → BookingRepository.updateBooking |

---

**End audit/26**
