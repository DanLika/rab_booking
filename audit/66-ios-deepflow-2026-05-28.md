# audit/66 — iOS Deep-Flow Retest (Marionette) 2026-05-28

**Status:** IN PROGRESS
**Branch base:** `fix/f-62-01-logout-confirmation` (no commits ahead of main; just working-tree from audit/62)
**Target:** bookbed-dev (PROD plist swapped → `.plist.backup` per `.claude/rules/ios-development.md`)
**Driver:** Marionette MCP via Flutter VM (debug build, `--target lib/main_dev.dart`, `--machine` JSON)
**Scope:** retest the 56 DEFERRED tests from audit/62 — booking lifecycle, Stripe payment, full unit wizard publish, iCal, throwaway-user destructive auth
**Budget:** 4h (240 min)

---

## §1 Executive Summary

iOS Owner deep-flow retest on bookbed-dev to close the audit/62 deferral set. audit/62 ran the surface re-render PASS but skipped 56/73 deep-flow tests due to network reliability + Stripe egress block + scope cap. This run targets the SKIPPED set.

**Priority order (per advisor):** G (booking lifecycle) > C (wizard full publish) > A destructive subset > F iCal, then H deferred. E (Stripe) is web-surface — iOS owner has no embedded widget — so E1-E6 marked **BLOCKED on iOS** with egress probe captured separately.

**Critical spec correction (from pre-flight grep):**
- Booking action buttons (Odobri/Odbij/Otkaži/Završi) live on **booking list card** (`BookingCardActions` in `owner_bookings_screen.dart`), NOT in detail dialog (`BookingDetailsDialogV2`). Detail dialog only has Uredi/Email/Pošalji ponovo.
- Owner-side **cancel** calls `repository.cancelBooking()` → direct Firestore write (status=cancelled, cancellation_reason, cancelled_at). **No automatic refund** — owner cancel = bookkeeping cancel. Stripe refund only fires through `guestCancelBooking` CF (guest surface, not iOS owner).
- G6/G7 (owner refund) is spec-misclassified — verified no owner-side refund button exists in `lib/features/owner_dashboard/`. Will reframe as "owner cancel preserves payment record, refund is guest-initiated only".

Net new findings: TBD.

| Group | Tests | PASS | FAIL | BLOCKED | DEFERRED | Notes |
|---|---|---|---|---|---|---|
| C. Unit Wizard publish | 10 | — | — | — | — | — |
| E. Stripe payment | 6 | 0 | 0 | TBD | — | iOS owner has no widget surface; deferred to Terminal C (web) |
| G. Booking lifecycle | 10 | — | — | — | — | — |
| F. iCal | 6 | — | — | — | — | — |
| A. Auth destructive | 5 | — | — | — | — | — |
| H. Responsive rotation | 4 | — | — | — | — | — |
| **TOTAL** | **41** | | | | | |

---

## §2 Pre-Flight + Stripe Egress Probe

### Plist swap
| Check | Value | Pass? |
|---|---|---|
| `ios/Runner/GoogleService-Info.plist` post-snapshot+swap | `bookbed-dev` (grep PROJECT_ID) | ✓ |
| `iphone 17 Pro - BookBed` simulator booted | C8FBAA1C-4DE7-4C37-9E96-48844446F9E1 | ✓ |
| Flutter `--machine` debug launch | Xcode build 29.8s, `ws://127.0.0.1:63581/FN9voW9oTgs=/ws` | ✓ |
| Marionette connect | Success | ✓ |
| Login key-fill `bookbed-test@bookbed.io` / `BookBedTest2026!` | Pregled dashboard renders €0/0/0/0.0% | ✓ |

### Pre-flight gotchas encountered

**Sim orientation lock (transient)** — after audit/62's full `pod update`, sim was running but Flutter app rendered in landscape (logical 874×402) even though sim window was portrait (1206×2622). Hot-reload didn't fix; only **sim shutdown + boot + Flutter relaunch + `pod install --repo-update`** unstuck it. Spec-noting as F-66-INFO-A (transient developer-env, not a user-facing bug).

**`pod install --repo-update` required** after sim shutdown — CocoaPods specs cache went stale during the cycle. `pod install` alone failed with "CocoaPods's specs repository is too out-of-date". Spec-noting as audit/62 F-62-06 generalization.

### Stripe egress probe
DEFERRED to during-test live trigger via `createStripeCheckoutSession` (owner-side checkout). iOS owner app has no embedded widget surface, so direct Stripe payment flow (E1-E6) is **BLOCKED on iOS owner** — that flow lives on widget web surface. Will probe CF availability indirectly via `createBookingAtomic` (which writes payment_pending bookings; if CF is reachable, egress is live).

---

## §3 Per-Test Results

### Group C — Unit Wizard Full Publish

| Test | Result | Evidence |
|---|---|---|

### Group G — Booking Lifecycle

| Test | Result | Evidence |
|---|---|---|

### Group F — iCal

| Test | Result | Evidence |
|---|---|---|

### Group A — Auth (throwaway destructive)

| Test | Result | Evidence |
|---|---|---|

### Group H — Responsive

| Test | Result | Evidence |
|---|---|---|

### Group E — Stripe Payment

| Test | Result | Evidence |
|---|---|---|

---

## §4 Failures Detail

TBD.

---

## §5 New Findings (F-66-XX)

TBD.

---

## §6 Booking Lifecycle Verification Chain

TBD — owner create via "Nova rezervacija" → approve → reject → cancel.

---

## §7 Stripe Payment Results

TBD — egress probe + classification.

---

## §8 Cleanup Verification

TBD — log path: `audit/migrations/2026-05-28-ios-retest-cleanup.log`.

---

## §9 Plist Restoration

TBD — must end with `grep PROJECT_ID == rab-booking-248fc`.
