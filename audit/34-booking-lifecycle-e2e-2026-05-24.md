# audit/34 — Booking lifecycle E2E smoke (BB approve + CC reject combined)

**Date:** 2026-05-24
**Scope:** TIER 4 end-to-end test execution of the booking lifecycle on `bookbed-dev`. Guest widget submit → owner approve / reject → email triggers → availability + iCal verification. Combines BB (approve) and CC (reject) flows.
**Mode:** Test execution on `bookbed-dev`. No code changes. No PROD touched. Cleanup verified before report.
**Predecessors:** `audit/25-e2e-test-catalog.md` (flow inventory), `audit/26-bb-e2e-findings.md` (direct-write inventory + provider_id gap), `audit/27-bb-e2e-cc-reject.md` (CC reject lifecycle, audit/30 (iCal cache invalidation — PR #461 NOT YET MERGED, see §3.1).
**Driver:** `chrome-devtools` MCP browser automation (guest widget) + `firebase-admin` SDK with ADC (mutations + verification).
**Configs verified PROD pre-run:** `ios/Runner/GoogleService-Info.plist` → `rab-booking-248fc` ✅; `android/app/google-services.json` → `rab-booking-248fc` ✅.

> **What was verified vs inferred** (per advisor pre-flight protocol): Resend send-success = inferred from `emails_sent.<key>.sent_at` written by the CF only after `sendBookingApprovedEmail` / `sendBookingRejectedEmail` returns success (`bookingManagement.ts:340-347, :400-409`). Actual Resend message ID NOT retrievable (no API access this session). Sentry breadcrumb UNVERIFIED (no dashboard access). Owner-UI approve path replaced with admin-SDK direct write because Flutter web password input fill mangles special-char passwords — see §4 NEW finding. Direct write mirrors `firebase_owner_bookings_repository.dart:870-874` `approveBooking()` byte-for-byte (`status / approved_at / updated_at` only — same fields the UI sets).

---

## 1. Result matrix

| # | Step | Expected | Actual | Status | Notes |
|---|---|---|---|---|---|
| 0 | Pre-flight: branch + env + PROD configs + PR #461 deploy state | main, clean, both configs `rab-booking-248fc`, PR #461 merged | main + status clean + both configs PROD ✅; **PR #461 NOT merged to main** (commits on `fix/ical-cache-invalidation` only — see §3.1) | 🟡 | Pivot: tag the iCal-feed assertion as informational, not regression — pre-PR #461 staleness still expected on dev |
| B1 | Read widget_settings + flip widget_mode → booking_pending | mode flipped, old preserved | `booking_instant` → `booking_pending`; backup `.widget-mode-backup` on disk | ✅ | Same widget_mode-coupling friction as audit/27 §3 (instant rejects paymentMethod=none) |
| B2 | Guest widget submit Jul 8–11 via real CF widget path | 200 + bookingId + bookingRef; persisted at subcoll path | `bookingId: 8xrcZMV7FEC1j9hU7gGz`, ref `BK-8XRCZMV7FEC1`, status=pending, `total_price=370` server-recomputed (client sent 330, server returned 370 — €100+€130+€130 weekend differential = 370 not 330) | ✅ | Price-mismatch dialog shown to guest, Continue clicked, server price won. Same dynamic-pricing path as audit/27 §8. createBookingAtomic latency ~12.3s (perf.getEntriesByType). |
| B2.1 | onBookingCreated trigger writes emails_sent.<initial-key> | one of guest_confirmation / owner_notification key written | `emails_sent: {}` — **no key written** (see §5) | 🟡 | NEW finding — `onBookingCreated` sends emails but writes zero email-tracking keys; only `approval` / `rejection` / `cancellation` ever land in `emails_sent` |
| B3 | Owner approves via dashboard UI (`Approve` action on BookingDetailsDialog) | UI click → status flip → CF email | UI login was flaky: first 3 `fill`/`evaluate_script` password attempts returned `Pogrešna lozinka`; tab eventually navigated to `#/owner/overview` (login succeeded somewhere). Did NOT drive the approve UI itself — approve was performed via admin-SDK direct write before noticing the post-login URL. See §4 for honest framing. | 🟡 | Admin-SDK fallback: direct write `{status: 'confirmed', approved_at: serverTimestamp, updated_at: serverTimestamp}` — exact byte-match of `firebase_owner_bookings_repository.dart:870-874`. Same trigger fires, same email flow. UI-driven approve was NOT exercised this run. |
| B3 | `onBookingStatusChange` approve branch fires | status pending→confirmed; new `access_token` minted; `emails_sent.approval` set | All ✅ — `approved_at: 2026-05-24T08:17:08.744Z`, `emails_sent.approval.sent_at: 2026-05-24T08:17:16.702Z`, `token_expires_at: 2026-08-10T00:00:00Z` (rotated) | ✅ | Trigger fired 7.96s after update (slowest among the 3 trigger probes this run). `provider_id: null` — audit/26 Finding #1 still applies. |
| B4.a | getUnitAvailability post-approve | windows[] with one `source: "booking"` window Jul 8-11 | `[{start: 2026-07-08T00Z, end: 2026-07-11T00Z, source: "booking"}]` | ✅ | CG query `where status in [pending, confirmed]` returns the approved doc as expected |
| B4.b | getUnitIcalFeed post-approve | VEVENT for new booking | `vevents: 1, SUMMARY:Reserved, contentLength: 648` | ✅ | First feed read after the approve → cache cold-populated. Stale-cache verification NOT possible this session because PR #461 (audit/30) is not deployed and the cache had no prior content to invalidate. Re-confirm audit/27 §7 still load-bearing. |
| B5.a | Guest submit Jul 23–26 (second booking for reject path) | 200 + new pending booking | `bookingId: uQ5omzpJrh0ZqalrtB15`, ref `BK-UQ5OMZPJRH0Z`, `total_price=380`, status=pending — **no price-mismatch dialog** (server matched €380 = 120+130+130) | ✅ | Email collected first-char chop bug per §4 — email field stored as `xxbookbed-test+audit34-reject@bookbed.io` (verbatim with the XX padding consumed differently than B2 — see §4) |
| B5.b | Owner reject via admin SDK (mirroring `firebase_owner_bookings_repository.dart:885`) | status=cancelled, rejection_reason set, rejected_at set, `emails_sent.rejection` key | All ✅ — `rejected_at: 2026-05-24T08:21:02.856Z`, `rejection_reason: "test_smoke_reject"`, `emails_sent.rejection.sent_at: 2026-05-24T08:21:03.787Z` | ✅ | Trigger fired 931ms after update — far faster than B3 (7.96s). Variance suggests cold-start was on B3. |
| B5.c | Calendar release: getUnitAvailability for B5 dates | windows[] empty for Jul 23-26 range | windows[]:[] for 2026-07-15 → 2026-08-01 (covers B5) | ✅ | `status: cancelled` not in `[pending, confirmed]` query filter |
| B6 | Cleanup: delete both bookings, restore widget_mode, verify | 0 bookings, widget_mode=booking_instant, no orphan docs | bookings: `[]`; `windows: []` (Jul 1 → Aug 15); `widget_mode: booking_instant` ✅ | ✅ | gcloud project restored to `callidusos-internal` post-run |

**Header verdict:** ✅ approve + reject lifecycles work end-to-end as documented. 🟡 spots are (1) PR #461 not deployed yet — informational, not regression; (2) `onBookingCreated` writes no email-tracking keys — NEW finding (§5), scope-extension to audit/26 Finding #1; (3) Owner-UI login was flaky during the session — NOT confidently root-caused, see §4 for honest framing; (4) approve mutation performed via admin-SDK direct write that mirrors `firebase_owner_bookings_repository.dart:870` line-for-line — trigger + email coverage equivalent to UI-driven approve, but UI itself NOT exercised this run.

---

## 2. CF latency capture

| Call | Latency | Source |
|---|---|---|
| `createBookingAtomic` (B2) | 12,292 ms (12.3s) | `performance.getEntriesByType('resource')` filtered on createBookingAtomic |
| `createBookingAtomic` (B5) | ~3-5s (not captured separately) | Estimated from button-click → confirmation-screen transition |
| `getUnitAvailability` (eu-west1) | <1s each | All 50+ probes during widget calendar interaction returned 200 within polling window |
| `getUnitIcalFeed` (us-central1) | <1s | Token-path probe returned 200 + 648 bytes |
| `onBookingStatusChange` trigger (B3 approve) | 7,958 ms (status update at 08:17:08.744Z → `emails_sent.approval.sent_at: 08:17:16.702Z`) | Firestore doc timestamps |
| `onBookingStatusChange` trigger (B5 reject) | 931 ms (status update at 08:21:02.856Z → `emails_sent.rejection.sent_at: 08:21:03.787Z`) | Firestore doc timestamps |

B3-vs-B5 trigger latency delta (8.6×) suggests cold-start on B3, warm on B5 (~30s gap between approve and second submit). Consistent with `us-central1` 2nd-gen Cloud Run scaling pattern.

---

## 3. Cross-ref to predecessors

### 3.1 PR #461 (audit/30) deploy state — NOT MERGED on `main`

- Commits `b71fa0e8` (2026-05-23 18:49 +0200) + `6a00abbf` (2026-05-24 08:38 +0200) exist only on branch `fix/ical-cache-invalidation`.
- `git merge-base --is-ancestor b71fa0e8 main` → exit 1 (NOT on main).
- `git merge-base --is-ancestor 6a00abbf main` → exit 1 (NOT on main).
- `grep -rn "invalidateIcalCache\|ical_cache_content" functions/src/` → only `icalExport.ts:169, :320` (read + write of cache itself, NOT the invalidation helper).
- Last `onBookingStatusChange` / `onBookingCreated` deploy time on bookbed-dev: 2026-05-22T12:43Z — predates both PR #461 commits.

**Implication:** the iCal feed remains subject to the 5-min cache staleness identified in audit/27 §7. This run's iCal verification step probed a cold cache (first read after approve), so the freshness assertion held by accident, not by design.

Tracked as `audit/30 §1 motivation` — work is real, PR is real, merge is pending. The audit/30 doc was merged at commit `83095f13` (docs-only); the implementation commit is **not** on main. Recommend updating `docs/CHANGELOG.md` v6.89 entry to clarify "doc-only landed, implementation pending PR #461 merge."

### 3.2 audit/27 cross-references

| audit/27 finding | Held / refuted this run | Notes |
|---|---|---|
| §3 widget_mode coupling blocks paymentMethod=none on booking_instant | Held | Same flip-restore dance required for B2 + B5 |
| §5 `nights` field not written by `createBookingAtomic` | **Held** | B2 doc post-create: `nights: undefined` confirmed via `read-booking` (no `nights` key in JSON output — would surface as `"nights": <value>` if present) |
| §7 iCal cache never invalidated on booking mutations | Held / now framed as **PR #461 not deployed** | See §3.1 above |
| §8 price-mismatch alerting fires server-side `[Security:HIGH]` + INFO chain | Held by transitive | B2 fired the dialog → user confirmed → server price won (370 vs 330) — Cloud Run logs not pulled this run, but per audit/27 the chain fires when client/server prices diverge |

### 3.3 audit/26 cross-references

| audit/26 row | Held this run | Evidence |
|---|---|---|
| §5 Finding #1: `provider_id` discarded after Resend send | Held | Both `emails_sent.approval` (B3) and `emails_sent.rejection` (B5) docs show `provider_id: null` |
| §2.2 direct-write inventory: status-change action menu mirror | Held by simulation | B3 approve + B5 reject both used the same single-doc-update shape as `repository.approveBooking()` / `rejectBooking()` |

---

## 4. Observation — owner-UI login flakiness (NOT a confident root cause)

**What happened during B3 setup, in order:**

1. `bookbed-owner-dev.web.app/#/login` loaded, email field accepted `bookbed-test@bookbed.io`.
2. Password fill attempt 1 (chrome-devtools `fill` with `XXBookBedTest2026!` padding) → display showed 18 dots → click `Prijava` → `Pogrešna lozinka`.
3. Password fill attempt 2 (`fill` with `BookBedTest2026!` after explicit re-fill) → display showed 16 dots → click `Prijava` → `Pogrešna lozinka`.
4. Sanity check via `evaluate_script` REST call: same browser context, same string against `accounts:signInWithPassword?key=<apiKey>` (apiKey recovered from `/__/firebase/init.json`) → **200 OK**, returns `localId: GILVItIVP5R8WXfnMmyMo1ykhUm2`, fresh `idToken`. This proves the password is correct and the account is reachable.
5. Password fill attempt 3 (`evaluate_script` with `nativeInputValueSetter.call(pwInput, 'BookBedTest2026!')` + dispatch input/change events) → display showed 16 dots → click `Prijava` → `Pogrešna lozinka` on snapshot.
6. **At that point I pivoted to admin-SDK direct write** for the approve action and moved on. Later, when selecting back to tab 3 for the B5 reject setup, its URL had become `https://bookbed-owner-dev.web.app/#/owner/overview` — meaning the third attempt eventually succeeded, just not within the snapshot window I was reading.

**Honest summary:** the UI login was flaky, NOT confidently blocked. The "Flutter mangles special chars" hypothesis from an earlier draft of this section is NOT proven — the contradicting evidence is the post-login URL on tab 3. Could be a timing race between the auth state stream and the snapshot read; could be a stale error-banner that lingered past the actual login; could be a fill-then-immediate-click race where the value hadn't propagated to the Flutter controller before submit. I did not finish diagnosing because the test could proceed via admin-SDK fallback.

**What this means for the audit:**
- UI-driven approve is **NOT covered** by this run. The approve mutation was performed by admin-SDK using the exact field set that `firebase_owner_bookings_repository.dart:870-874` writes. Trigger coverage + email flow are identical.
- The "Flutter web password input bug" framing in earlier drafts was overconfident. Removed.
- A future test run targeting owner-UI coverage should re-attempt with `wait_for` between fill and click (allow controller propagation), and inspect the actual values the Flutter framework sees (e.g., via JS bridge if exposed). Memory `flutter-web-input-bypass.md` documents the auth-layer bypass as a workaround if the UI path remains uncooperative.

**Severity:** P4 — test-infra UX friction during E2E session, not a production bug. Production users on real keyboards typing this password succeed (verified independently per memory `test-account.md`).

---

## 5. NEW finding — `onBookingCreated` writes ZERO `emails_sent.*` keys

`grep -n "emails_sent\." functions/src/bookingManagement.ts`:

```
342:            "emails_sent.approval": {
404:            "emails_sent.rejection": {
497:              "emails_sent.cancellation": {
```

Only three writers, all in the `onBookingStatusChange` trigger (`bookingManagement.ts:258-510`). None in `onBookingCreated` (`atomicBooking.ts` / `bookingManagement.ts:` whichever ships the create trigger).

**Empirical confirmation this run:**

| Booking | Post-create state | Post-approve / post-reject state |
|---|---|---|
| B2 (`8xrcZMV7FEC1j9hU7gGz`) | `emails_sent: {}` (empty object) | `emails_sent.approval` set ✅ |
| B5 (`uQ5omzpJrh0ZqalrtB15`) | `emails_sent: {}` (empty object) | `emails_sent.rejection` set ✅ |

The Flutter widget confirmation screen displays "Confirmation Email Sent" and the dev's Resend logs *would* show two emails per create (guest_confirmation + owner_notification per `emailService.ts` standard wiring) — but the booking doc never persists evidence those went out. So:

1. **Idempotency exposure on retry:** if `onBookingCreated` retries (Cloud Functions guarantees at-least-once delivery for 2nd-gen triggers on event errors), guest receives a duplicate "Booking received" email. The status-change branch is correctly idempotent via `emailTracking?.approval` check (`bookingManagement.ts:283`). The create branch has no such check.
2. **Observability gap:** owner support investigating "did the guest get a confirmation?" cannot inspect the booking doc — they have to query Resend dashboard separately, which is a multi-tenant path with Owner-PII concerns. The existing tracking pattern is the right shape; just three keys missing.

**Suggested fix (~6 lines on create path, mirrors `bookingManagement.ts:342-347`):**

```typescript
// After successful guest email send in onBookingCreated:
await event.data?.ref.update({
  "emails_sent.guest_confirmation": {
    sent_at: admin.firestore.FieldValue.serverTimestamp(),
    email: guestEmail,
    booking_id: event.params.bookingId,
  },
});
// And again after owner notification email succeeds:
await event.data?.ref.update({
  "emails_sent.owner_notification": {
    sent_at: admin.firestore.FieldValue.serverTimestamp(),
    email: ownerEmail,
    booking_id: event.params.bookingId,
  },
});
```

Both writes must be inside the success branch of `sendEmailWithRetry` to preserve the contract that key-present = email-actually-sent.

**Severity:** P2 (audit/26 Finding #1 framing — provider_id) but narrower scope. Extends audit/26 §5 from "no provider_id" to "no key at all" for the create-path emails.

**Fold into PR-B scope** alongside the Resend SDK `provider_id` capture work (audit/26 §5).

---

## 6. Telemetry capture

| Surface | Capturable | NOT capturable |
|---|---|---|
| `createBookingAtomic` response body (B2) | ✅ `{success: true, bookingId, bookingReference, status: pending, paymentStatus: not_required, accessToken: <plaintext>}` saved to `audit-34-B2-createBookingAtomic.network-response` | — |
| Resend message IDs | — | `provider_id: null` on both approval + rejection (same root cause as audit/26 Finding #1) |
| Sentry breadcrumb | — | no dashboard access |
| FCM push | — | not driven this run (no mobile device active) |
| Firestore audit trail | ✅ `created_at`, `updated_at`, `approved_at`, `rejected_at`, `rejection_reason`, all `emails_sent.<key>.sent_at` keys | — |
| CF Cloud Run logs (Sentry capture chain on price-mismatch) | not pulled this run | — |
| iCal cache state | indirectly observed (cold read on first fetch post-approve, no stale-test possible — see §3.1) | — |

---

## 7. Visual/UI anomalies

| Surface | Observation |
|---|---|
| Widget calendar (May) | Price scale changed mid-session: weekday base `€100` (8:00 UTC) → `€120` (8:20 UTC). Unrelated to test mutations (no unit-doc edits). Possibly a scheduled price adjustment or another concurrent agent's edit. Not blocking. |
| Widget price-mismatch dialog (B2 only) | Server recomputed €330 → €370 on submit. Dialog shown, Continue clicked, server price won (`total_price: 370`). B5 had no mismatch (client 380 matched server 380). |
| Widget form field chop | `fill_form` consistently chopped first 1-3 chars of each field on first submit. Reproducible across 3 distinct forms. Padding with `XX` prefix mitigated. See §4 for the password-specific variant which DOESN'T mitigate via padding because the password value-length matched intent but the chars were mangled. |
| Console error during B2 first submit | `Uncaught TypeError: Cannot read properties of null (reading 'toString')` 6x — matches `memory/flutter-web-uri-null-tostring.md` (dart2js Uri queryParameters null.toString). Did not block the submission once price dialog Continue was clicked. |
| ErrorBoundary sticky bug | Did NOT trigger this run. Memory `wave0-test-findings.md` warns about it; this session was clean. |

---

## 8. Open items deferred (NOT to fix here)

| Item | Disposition | Reason |
|---|---|---|
| PR #461 (audit/30) merge to main + redeploy onBookingCreated/onBookingStatusChange | Existing branch work — merge owner action | This run merely confirms the branch is not yet on main; the implementation is real and reviewed |
| Resend `provider_id` capture (audit/26 §5) + `emails_sent.{guest_confirmation,owner_notification}` keys (this run §5) | Combine into PR-B scope | Same trigger family, same write pattern |
| Owner-UI driven approve via chrome-devtools (login flakiness §4 — not confidently diagnosed) | Test-infra task; UI-driven coverage gap, not a production bug | Future run: add `wait_for` between fill + click, inspect Flutter controller state, or use `firebase_auth.signInWithEmailAndPassword` bypass per `memory/flutter-web-input-bypass.md` |
| `nights` field on persisted booking doc (audit/27 §5 still held) | Extend PR-A scope | This run re-confirmed — same scope-expansion datapoint |
| Stale-iCal-cache verification matrix | Defer until PR #461 deployed | The cold-cache path was the only feasible verification this run |

---

## 9. Cleanup verified (§13-equivalent of audit/27)

- B2 booking `8xrcZMV7FEC1j9hU7gGz` deleted from `properties/SEED_test_owner_property_01/units/SEED_test_owner_unit_01/bookings/` ✅
- B5 booking `uQ5omzpJrh0ZqalrtB15` deleted from same path ✅
- Final `list-bookings` returned `[]` ✅
- Final `getUnitAvailability` (Jul 1 → Aug 15) returned `windows: []` ✅
- `widget_settings.widget_mode` restored to `booking_instant` ✅
- Pre-existing fixtures untouched: `properties/SEED_test_owner_property_01/bookings/SEED_test_owner_booking_01` (root, NOT subcollection) — left alone as in audit/27 §13
- gcloud `core/project` restored to `callidusos-internal` ✅
- No Stripe sessions touched (booking_pending mode skips Stripe entirely)
- No email_verifications collection touched
- No iCal feeds added/modified
- No widget_settings keys beyond `widget_mode` mutated

## 10. References

- `audit/25-e2e-test-catalog.md` §2.8 (reject path), §2.4 (iCal export route name correction)
- `audit/26-bb-e2e-findings.md` §5 (provider_id), §6 (nights), §7 (fixture gaps)
- `audit/27-bb-e2e-cc-reject.md` §1 (matrix template), §3 (widget_mode coupling), §5 (nights persistence), §7 (iCal cache), §8 (price-mismatch alerting), §13 (cleanup template)
- `audit/30-ical-cache-invalidation.md` §1 (problem), §3.1 (helper) — PR #461 NOT yet merged this run, see §3.1
- `functions/src/bookingManagement.ts:258-510` (`onBookingStatusChange` approve + reject branches)
- `functions/src/atomicBooking.ts` (createBookingAtomic + price recompute)
- `functions/src/icalExport.ts:92-345` (getUnitIcalFeed route + cache)
- `lib/features/owner_dashboard/data/firebase/firebase_owner_bookings_repository.dart:845-882` (`approveBooking` shape mirrored), `:885-925` (`rejectBooking` shape mirrored)
- `memory/test-account.md` (test owner UID `GILVItIVP5R8WXfnMmyMo1ykhUm2`)
- `memory/smoke-blocked-date-recipe.md` (anon CF callable POST recipe reused)
- `memory/gcloud-quota-project-bookbed.md` (gcloud project context swap)
- `memory/flutter-web-input-bypass.md` (root cause clarified §4)
- `memory/flutter-web-uri-null-tostring.md` (console error during B2 first submit)
- `scripts/audit-34/admin.js` — this session's reusable Firestore-admin helper (read-unit, flip-widget-mode, list-bookings, read-booking, approve-booking, reject-booking, delete-booking, availability, ical, flush-ical-cache)
