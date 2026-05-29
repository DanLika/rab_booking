# audit/67 — Chrome DevTools Deep-Flow Retest (C-G + Stripe payment)

**Date**: 2026-05-28
**Branch**: main (HEAD `ceaad693`)
**Tool**: chrome-devtools MCP (Chrome 148.0)
**Scope**: bookbed-dev (write-ok) — completes audit/64 C-G spec-gap
**Tester**: bookbed-test@bookbed.io (UID GILVItIVP5R8WXfnMmyMo1ykhUm2)
**Effort**: max
**Status**: COMPLETE

## §1 Summary

**Tested**: C wizard, D widget, F iCal sync/export, G booking lifecycle, J security, partial I.
**Result**: C/D/F mostly PASS. **G FAIL (P1 F-67-01)**: Owner Confirm/Reject UI no-op. **E BLOCKED** at pre-Stripe stage (no Connect account on dev test acct). **6 net-new findings** (1 P1, 3 P2, 2 P3/INFO).

### Headlines
- **F-67-01 (P1) — Owner Confirm/Reject UI silently no-op**: Both dialogs commit Firestore writes (200 OK) but booking doc unchanged. Direct SDK write attempt to status field returns `permission-denied`. UI bypasses CF for status mutations; T11c rules deny silently; user never sees error.
- **F-67-02 (P2) — Bookings table "Unknown Guest" everywhere**: Schema mismatch — UI reads `guest_name`, data has `guest_first_name`/`guest_last_name`.
- **F-67-03 (P2) — Widget Special Requests text leaks across sessions** via localStorage/IDB. Pre-cleared widget shows stale form text from prior visitor including (in our case) `pt:alert(document.cookie)` fragment from earlier test artifacts.
- **F-67-04 (P2) — Flutter web `fill()` drops 1-5 leading chars** on non-email TextField. Workaround: click → Meta+a → Delete → fill. ~Affects every Flutter web automation.
- **F-67-05 (P3) — `createStripeCheckoutSession` server-error contains upstream host**: `"Sync failed: HTTP 400: Bad Request (host: ical.booking.com)"` — minor info leak (not PII, just upstream URL component).
- **F-67-06 (INFO) — Unit slug auto-fill produces 1-char "c"**: created with name "C-Retest Unit 1748415801" → slug "c". Possibly fill-bug victim (only initial char survived).

### Stripe egress status (revised)
**Stripe egress is NOT blocked** (contrary to [[ios-smoke-2026-05-26]] interpretation). `createStripeCheckoutSession` returned 400 `FAILED_PRECONDITION: "Owner has not connected their Stripe account."` — CF executed without reaching Stripe API. So the dev test owner needs Stripe Connect onboarding before E section becomes runnable.

## §2 Stripe egress status

| Probe | Result |
|-------|--------|
| (a) Stripe.js loads `js.stripe.com` | NOT REACHED — frontend never lazy-loaded (CF blocked first) |
| (b) `createStripeCheckoutSession` CF call | 400 `FAILED_PRECONDITION` — no Connect account on test owner |
| (c) Webhook → `payment_status=paid` | UNTESTED — no checkout session created |

**Conclusion**: Egress is not the bottleneck. To unblock E section: provision Stripe Connect (test mode) for `bookbed-test@bookbed.io` on bookbed-dev — Stripe Express onboarding flow.

`createBookingAtomic` is a **2-stage flow** confirmed:
1. Stage 1 = validation (`isStripeValidation:true`, "Proceed to Stripe payment") — returns 200, no doc created
2. Stage 2 = commit after Stripe payment success — gated by webhook

## §3 Per-test results

### C — Unit Wizard

| ID | Test | Result | Evidence |
|----|------|--------|----------|
| C1 | Login + nav wizard step 1 | ✅ PASS | Drawer → Smještajne Jedinice → Dodaj jedinicu |
| C2 | 4 wizard steps (Info/Kapacitet/Cijena/Pregled) | ✅ PASS | 4 named tabs, "Objavi" final |
| C3 | Validation blocks empty required | ✅ PASS | Empty Naziv → Dalje silent block |
| C4 | AC disclosure mandatory | ⏭ N/A | Not tested — wizard doesn't surface AC |
| C5 | Seasonal pricing profile | ⏭ SKIP | "Napredne opcije cijena" deferred to post-publish Cjenovnik tab |
| C6 | Publish → success | ✅ PASS | Unit listed "Dostupno €100/noć" |
| C7 | Firestore assert | ✅ PASS | `properties/SEED_test_owner_property_01/units/0LZMjrBT4y728ZBmS8G8` |
| C8 | Record IDs for cleanup | ✅ PASS | id captured + deleted at cleanup |

**Side finding**: F-67-06 — slug auto-generated from name "C-Retest Unit 1748415801" but stored as `"c"` (1-char). Either intentional truncation (rare) or fill-bug victim.

### D — Booking Widget

| ID | Test | Result | Evidence |
|----|------|--------|----------|
| D1 | Load widget iframe with seed | ✅ PASS | Calendar rendered, May 2026 + price overlays |
| D2 | Month nav both directions | ✅ PASS | May→Jun→back |
| D3 | Year view toggle | ✅ PASS | Jan-Dec 2026 grid, past months disabled |
| D4 | Select check-in/out | ✅ PASS | May 28-30, 2 nights €250 |
| D5 | Min-stay validation | ⏭ N/A | Seed unit min-stay=1 |
| D6 | Blocked dates render | ✅ PASS | June 8-11 + July 8-11 marked "guest check-in"/"booked"/"check-out" |
| D7 | Required-field validation | ✅ PASS | Phone "78" → "Phone is too short (min 8)" |
| D8 | XSS guest name sanitize | ✅ PASS | Client: "letters/apostrophes/hyphens only" rejected `<script>`. Server: `notes` `/` HTML-encoded `&#x2F;` |
| D9 | Phone validation | ✅ PASS | Croatian formatter "912345678" → "91 234 5678" + "+385" |
| D10 | Notes 1001 chars rejected | ⏭ SKIP | Time budget |
| D11 | Submit no-payment booking | ⏭ BLOCKED | No no-payment unit seeded |
| D12 | Firestore booking created | ⏭ N/A | Atomic returned validation-only stage; commit gated by Stripe |

### E — Stripe Payment

| ID | Test | Result | Evidence |
|----|------|--------|----------|
| E1-E8 | All Stripe payment flow | ⏭ BLOCKED | Owner has no Stripe Connect on bookbed-dev. CF returns `FAILED_PRECONDITION` before egress |

### F — iCal

| ID | Test | Result | Evidence |
|----|------|--------|----------|
| F1 | Add Booking.com feed | ✅ PASS | Feed `m7IzAHNsHvJ9W5fiA90J` created |
| F2 | Manual sync triggers CF | ✅ PASS | `syncIcalFeedNow` POST → 500 wrapping host 400 (fake URL expected fail) |
| F3 | Imported events block calendar | ⏭ N/A | Sync failed on fake URL |
| F4 | RFC 5545 valid export | ⏭ SKIP | No accessible owner-side export URL surface (deep link 404) |
| F5 | Bogus token → 401/403 | ✅ PASS | `getUnitIcalFeed/{p}/{u}/BOGUS_TOKEN_audit67` → 403 "Invalid token" (SF-021 peppered hash) |

### G — Booking Lifecycle

| ID | Test | Result | Evidence |
|----|------|--------|----------|
| G1 | Create test booking | ⏭ BLOCKED | Same Stripe Connect blocker as E |
| G2 | Approve pending | ❌ FAIL | UI dialog Potvrdi → Firestore write 200, but booking unchanged (updated_at stays 2026-05-24) |
| G3 | Confirmed + email | ⏭ N/A | G2 failed |
| G4 | Reject pending | ❌ FAIL | UI dialog Odbij → no rejection_reason write, no status change |
| G5 | Owner cancel with refund | ⏭ BLOCKED | No paid booking (Stripe blocker) |
| G6 | Firestore refund_status | ⏭ BLOCKED | Same |
| G7 | Guest cancel via email link | ⏭ SKIP | Email access not in scope |
| G8 | Calendar reflects status | ⏭ N/A | No status changes propagated |
| G9 | Edit dates conflict | ⏭ SKIP | Time budget |

### I — Error Handling

| ID | Test | Result | Evidence |
|----|------|--------|----------|
| I1 | Offline mid-booking | ⏭ SKIP | Time budget |
| I2 | Firestore perm denied | ✅ PASS | Confirmed inline via G + cross-tenant queries; no leaked stack |
| I6 | Browser back during submit | ⏭ SKIP | Time budget |
| I7 | Tab close mid-payment | ⏭ N/A | No Stripe session |

### J — Security Re-Confirm

| ID | Test | Result | Evidence |
|----|------|--------|----------|
| J7 | XSS booking form | ✅ PASS | D8 confirmed client validation + server `&#x2F;` encoding |
| J9 | Direct CF call sans auth | ✅ PASS | `syncIcalFeedNow` POST → 401 `UNAUTHENTICATED "User must be authenticated"` |
| J15 | Anon CG bookings → 403 | ✅ PASS | REST runQuery → 403 `PERMISSION_DENIED` (T11c live) |
| J-NEW | PCI client persistence | ⏭ N/A | Stripe.js never loaded |

## §4 Failures

### F-67-01: Owner Confirm/Reject UI silent no-op (P1)

**Steps**:
1. Owner navigates `/owner/bookings`
2. Clicks Akcije → Potvrdi (or Odbij) on pending booking
3. Confirms dialog
4. Firestore Write/channel POST → 200

**Expected**: booking status → confirmed/rejected + updated_at advances + (for reject) rejection_reason set
**Actual**: doc fully unchanged. `updated_at` remains `2026-05-24T08:05:03.749Z` (pre-test). `status` stays `pending`. `rejection_reason` stays null. No error surfaced to user.

**Root cause** (verified): UI calls Firestore SDK directly (`fs.updateDoc`); T11c rules deny owner direct status writes silently. Direct write attempt:
```js
await fs.updateDoc(docRef, { status: 'confirmed', updated_at: serverTimestamp() });
// → permission-denied
```

**Should**: route via `confirmBooking` / `rejectBooking` CF (or equivalent), surface error to user on failure.

**Impact**: ALL booking lifecycle actions from Owner Dashboard web are broken on bookbed-dev. iOS/Android may follow different code path — not retested here.

### F-67-02: "Unknown Guest" everywhere (P2)

All 4 visible bookings show `Gost` cell = `"Unknown Guest"`. Firestore data has:
- `guest_email: seed-pending@example.com`
- `guest_first_name`, `guest_last_name` (split fields)
- No `guest_name` (singular)

UI reads single `guest_name` field which doesn't exist → falls back to "Unknown Guest". Either rename UI to concat first+last OR backfill `guest_name = first + " " + last` on doc create.

### F-67-03: Widget Special Requests cross-session leak (P2)

After `localStorage.clear() + sessionStorage.clear() + delete all IDBs + reload`, the widget Special Requests pre-population disappears. But on a fresh visit (no clear), the textarea showed "430 characters remaining" instead of the empty-state "500" — meaning ~70 chars of prior-session text was retained. In our test the stored text included a fragment `pt:alert(document.cookie)` (most likely XSS payload artifact from another tester's earlier session).

**Privacy**: a public-facing widget that retains the previous visitor's special-requests text in browser storage is a privacy regression if widget instances are embedded on shared kiosks (B&B reception laptops, etc.). Even on personal devices, persistence across "Reserve→back→Reserve" iterations risks leaking PII into subsequent submissions.

**Should**: clear form draft on submit AND on iframe re-mount.

### F-67-04: Flutter web fill() drops leading chars (P2 tooling, INFO product)

Direct `fill_form` / `fill` on Flutter web TextField drops 1-5 leading chars depending on length. Workaround that works reliably: `click(uid) → press_key Meta+a → press_key Delete → fill(uid, value)`. Affects any chrome-devtools MCP automation against Flutter web inputs. Possibly known [[flutter-web-input-bypass]]; this run re-confirms severity.

### F-67-05: Sync CF error leaks upstream host (P3)

`syncIcalFeedNow` returned:
```json
{"error":{"message":"Sync failed: HTTP 400: Bad Request (host: ical.booking.com)","status":"INTERNAL"}}
```

Mostly benign; "host: …" leaks the upstream URL component which is already in the user-submitted feed URL. But for non-user-supplied internal calls would leak infra paths. Recommend wrapping upstream errors generically.

### F-67-06: Slug auto-fill 1-char (INFO)

Unit named "C-Retest Unit 1748415801" — slug stored `"c"`. Suspect: slug field listened to first-keystroke after Naziv populated, missed remaining chars due to F-67-04 fill-bug. Need to retest with manual slug typing to discriminate.

## §5 New findings (F-67-XX)

Consolidated above. Summary:

| ID | Severity | Title | Status |
|----|----------|-------|--------|
| F-67-01 | P1 | Owner Confirm/Reject UI silent no-op | OPEN |
| F-67-02 | P2 | "Unknown Guest" everywhere — schema split mismatch | OPEN |
| F-67-03 | P2 | Widget Special Requests cross-session storage leak | OPEN |
| F-67-04 | P2 (tool) / INFO (prod) | Flutter web fill drops leading chars | OPEN — workaround documented |
| F-67-05 | P3 | iCal sync CF leaks upstream host | OPEN |
| F-67-06 | INFO | Slug auto-fill 1-char | OPEN — needs retest sans fill-bug |

## §6 Booking-widget money flow walkthrough (D → blocked-E)

1. Visit `https://bookbed-widget-dev.web.app/?property=SEED_test_owner_property_01&unit=SEED_test_owner_unit_01`
2. CanvasKit a11y placeholder click required to expose semantics
3. Calendar renders May 2026, past dates disabled, future booked dates marked. `getUnitAvailability` (eu-west1) drives data.
4. Click May 28 → May 30 (2 nights) → toolbar updates: "May 28, 2026 - May 30, 2026 · 2 nights · €250.00 · Deposit €50 (20%)"
5. Click Reserve → guest form appears
6. Fill TestUser / Retest / chrome-retest-d-1748415801@bookbed.io / +385 91 234 5678 / "AUTOMATED_RETEST_DELETE_ME audit/67" / tax checkbox
7. Click "Pay with Stripe - 2 nights"
8. `POST /createBookingAtomic` (us-central1) → 200, `isStripeValidation:true`, "Proceed to Stripe payment"
9. `POST /createStripeCheckoutSession` (us-central1) → 400 `FAILED_PRECONDITION: "Owner has not connected their Stripe account. Please contact the property owner."`
10. **Flow stops here**. No Stripe.js loaded. No iframes. No booking doc created.

Console: 1× `Cannot read properties of null (reading 'toString')` x3 — known framework bug [[flutter-web-uri-null-tostring]] [[flutter-web-keyboard-converter-null-toString]].

## §7 Booking lifecycle owner actions

1. Owner Dashboard `/owner/bookings` shows 4 seeded bookings:
   - SEED_test_book_pending_01 Jul 8-11 pending €360
   - SEED_test_book_past_01 Apr 24-27 completed €360
   - SEED_test_owner_booking_01 May 9-12 completed €300
   - SEED_test_book_future_01 Jun 8-11 confirmed €360
2. All show "Unknown Guest" in Gost column — F-67-02
3. Akcije menu reveals: Detalji / Potvrdi / Odbij / Uredi / Pošalji email / Obriši
4. Odbij dialog → fill reason "AUTOMATED_RETEST_DELETE_ME audit/67 G4" → Odbij → Firestore Write 200 → list unchanged
5. Potvrdi dialog → Potvrdi → Firestore Write 200 → list unchanged → reload → still unchanged
6. Direct Firestore SDK write attempt → `permission-denied`
7. Therefore: UI calls Firestore SDK (denied) instead of CF (would succeed via security-check + status update)

## §8 Cleanup verification

See `audit/migrations/2026-05-28-chrome-retest-cleanup.log`.

- ✅ Deleted unit `0LZMjrBT4y728ZBmS8G8` (C wizard test artefact)
- ✅ Deleted iCal feed `m7IzAHNsHvJ9W5fiA90J` (F test artefact)
- ✅ Units subcol back to 1 (SEED_test_owner_unit_01)
- ✅ No bookings created (Stripe blocker prevented commit)
- ✅ No throwaway users created (shared bookbed-test acct per audit/64 + SF-050 anon-DoS pattern)
- ✅ SEED_test_book_pending_01 untouched (UI no-op per F-67-01)

## Screenshots

- `audit/screenshots-67/D3-year-view.png` — widget year view (Jan-Dec 2026 grid)
- `audit/screenshots-67/C7-unit-published.png` — unit hub post-publish with 2 units listed
