# audit/27 — BB E2E CC reject flow (test execution)

**Date:** 2026-05-23
**Scope:** TIER 4 E2E test execution of the CC reject flow (audit/25 §2.8 reject path: pending → cancelled + rejection_reason → calendar release → re-book same dates).
**Mode:** Test execution on `bookbed-dev`. No code changes. No prod touched.
**Predecessors:** `audit/25-e2e-test-catalog.md` (flow inventory), `audit/26-bb-e2e-findings.md` (direct-write bypass class + provider_id gap).
**Configs verified PROD pre-run:** `ios/Runner/GoogleService-Info.plist` → `rab-booking-248fc` ✅; `android/app/google-services.json` → `rab-booking-248fc` ✅.

> **What was verified vs inferred** (per advisor pre-flight): Resend send success = inferred from `emails_sent.rejection` key SET (CF writes that key only after `sendBookingRejectedEmail` returns success, per `bookingManagement.ts:402-409`). Actual Resend message ID NOT retrievable (no API access this session). Sentry breadcrumb UNVERIFIED (no dashboard access). iCal regen check BLOCKED by widget_settings path mismatch (see §5).

---

## 1. Result matrix

| # | Step | Expected | Actual | Status | Notes |
|---|---|---|---|---|---|
| 0 | Pre-flight: branch + env + PROD configs | main, clean, both configs `rab-booking-248fc` | ✅ all three | ✅ | — |
| 1 | Probe `getUnitAvailability` on `SEED_test_owner_*` (Jun–Aug) | 200 + `windows: []` (empty unit) | 200, `windows: []` | ✅ | Anon callable, eu-west1 |
| 2 | Fixture sanity (admin SDK direct read) | property+unit exist, owned by `GILVItIVP5R8WXfnMmyMo1ykhUm2` | property+unit ✅, `widget_settings/SEED_test_owner_unit_01` exists at `properties/{pid}/widget_settings/{unitId}` (NOT under `units/`) | 🟡 | audit/26 §7 fixture-gap claim "widget_settings doc not seeded" is **PATH-INVERTED** — see §4 |
| 3 | Create pending booking via direct firebase-admin write to subcoll path | doc lands, `onBookingCreated` fires | doc `W8NIgbJJYlVsRu6z1A6F` created at `properties/.../units/.../bookings/{id}`; ref `BK-CC9547181785`; status=pending; 2026-07-22T12Z → 2026-07-25T12Z (3 nights) | ✅ | direct-write bypass: no overlap check, no SF-026 normalization on create — matches audit/26 §2.2 "Add manual booking" row |
| 4 | CF sees booking as block | `windows[]` with one `source: "booking"` window matching dates | `[{start: 2026-07-22T12:00:00Z, end: 2026-07-25T12:00:00Z, source: "booking"}]` after ~4s propagation | ✅ | `collectionGroup("bookings") where status in [pending, confirmed]` query landed the doc |
| 5 | Owner reject (direct firestore update mirroring `firebase_owner_bookings_repository.dart:885`) | status→cancelled, rejection_reason set, rejected_at set | All set; trigger `onBookingStatusChange` fires | ✅ | Update latency 243ms; trigger fired within first 2s poll |
| 6 | `emails_sent.rejection` key SET on booking doc | `{sent_at, email, booking_id}` written by `bookingManagement.ts:402-409` | `{booking_id: W8NIgbJJYlVsRu6z1A6F, email: bookbed-test+ccreject@..., sent_at: 2026-05-23T14:40:30Z}` | ✅ | **NO `provider_id`** — confirms audit/26 Finding #1 (Resend SDK id discarded) |
| 7 | Calendar release: CF `windows` empty for same range | `windows: []` | `windows: []` after 2s | ✅ | `status: cancelled` not in `[pending, confirmed]` query filter |
| 8 | iCal regen check (`getUnitIcalFeed`, us-central1) | feed includes pending booking VEVENT before reject, excludes it after | Pre-create: 1 VEVENT (placeholder only); Post-create: 1 VEVENT (`SUMMARY:Reserved`, UID `booking-LrE03y89IZbn09gjsEoH@bookbed.io`); Post-reject: back to placeholder; Post-delete: placeholder. Full pre→create→reject→delete cycle verified by force-flushing `ical_cache_content` between each probe. | ✅ | `getUnitIcalFeed` is the correct CF name (not `icalExport` as in audit/25 §2.4). NEW finding §7: NO trigger flushes the 5min `ical_cache_content` on booking writes — feed lags up to 5min in prod. |
| 9 | Re-book same dates as new guest via real CF widget path (`createBookingAtomic`, us-central1) | 200 + new pending booking, no overlap error | 200, `bookingId: Jba8l3AaWH3mno1PKlXQ`, ref `BK-JBA8L3AAWH3M`, status=pending, totalPrice=**330** (server-computed; we sent 300 client-side — server price wins, weekend differential applied for Jul 24 Friday weekend day) | ✅ | Required `widget_mode` flip booking_instant → booking_pending → restore (unit lacks bank_transfer config; only stripe_config.enabled=true; instant mode rejects paymentMethod=none — see §3) |
| 10 | Cleanup: delete both bookings, verify windows empty, verify widget_mode restored | both deleted, `windows: []`, widget_mode=booking_instant | All ✅ | ✅ | CG sweep on `source` field 9-FAILED_PRECONDITION (missing single-field exemption) — see §6 |
| 11 | Price-mismatch alerting (server-side instrumentation positive confirmation) | client `totalPrice: 300` vs server-recomputed `330` fires WARNING + INFO log chain | `[Security:HIGH] price_mismatch_detected` WARNING + `[PriceValidation] Price mismatch detected` WARNING + `[AtomicBooking] Price mismatch - using server-calculated price` INFO all logged at 2026-05-23T14:42:54Z, execution_id `igk4ll31eb3d` | ✅ | full payload in §8 — these SHOULD also land in Sentry (not HttpsError, so the client-fault filter in `.claude/rules/cloud-functions.md` doesn't drop them) |

**Header verdict:** ✅ reject lifecycle works as documented in audit/25 §2.8. ✅ iCal regen verified end-to-end (force-flush technique). ✅ price-mismatch alerting verified. 🟡 spots are docs/scope gaps, not regressions.

---

## 2. Cross-ref to audit/26 §2.2 — direct-write paths observed

Reject lifecycle covered TWO of audit/26's catalogued direct-write surfaces in a single run:

| audit/26 §2.2 row | This run hit it? | Evidence |
|---|---|---|
| 1 (Add manual booking — `BookingRepository.createBooking` → bare `.add()`) | ✅ (simulated via admin SDK on same path) | Step 3: pending booking lands without `createBookingAtomic` overlap check or SF-026 nights normalization. Same risk class. |
| Status change (action menu) — `calendar_booking_actions.dart:127` ⚠️ lower-risk sibling | ✅ (simulated via `bookingDoc.reference.update` matching `firebase_owner_bookings_repository.dart:885`) | Step 5: direct `status: cancelled` write; trigger fires correctly on the units-subcollection path |

**No NEW direct-write paths surfaced** beyond audit/26 §2.2 inventory.

---

## 3. New observation — widget_mode coupling blocks the no-payment re-book

Re-book step (9) had to flip `widget_mode: booking_instant → booking_pending → booking_instant` because:

- `SEED_test_owner` unit's `widget_settings`: `widget_mode=booking_instant`, `stripe_config.enabled=true`, `bank_transfer_config=undefined`.
- `createBookingAtomic` `atomicBooking.ts:378-407` rejects (`PERMISSION_DENIED`) the combo `widget_mode=booking_instant` × `paymentMethod=none` with message: `"Payment required for instant bookings. Please select Stripe or Bank Transfer."`
- To exercise the cancelled-then-rebook path without dragging in Stripe (no test-mode Connect account on this owner per audit/26 §7), short flip + restore was used.

This is **not a bug** — it's the intended audit/25 §4.3 "missing Stripe Connect account" fixture gap. But it means: a parallel test runner who wants to exercise the real widget submit path on `SEED_test_owner_unit_01` without payment **must** flip widget_mode, then restore.

**Suggestion for future seed work:** add a `widget_mode=booking_pending` variant unit (e.g. `SEED_test_owner_unit_02`) so the no-payment path is testable without mutating the live booking_instant unit. Fold into the fixture micro-PR catalogued at audit/26 §7.

---

## 4. audit/26 §7 fixture-gap correction — `widget_settings` path

audit/26 §7 row 2 reads: *"`widget_settings/SEED_test_owner_unit_01` doc not seeded — EE (iCal E2E) flow blocked — `getUnitIcalFeed` 404s. XS — add minimal widget_settings seed."*

**This run verified the doc IS present**, at the canonical path: `properties/SEED_test_owner_property_01/widget_settings/SEED_test_owner_unit_01`. Keys: `min_days_advance, ical_export_token, owner_id, widget_mode, max_days_advance, created_at, language, property_id, cancellation_deadline_hours, ical_export_enabled, allow_guest_cancellation, allow_pay_on_arrival, currency, weekend_days, min_nights, stripe_config, updated_at`. `ical_export_token` is populated; `ical_export_enabled=true`.

→ If `getUnitIcalFeed` is still 404'ing, the cause is somewhere else (region drift, token regeneration, route shape). Recommend audit/26 §7 row 2 be **edited or struck** and a fresh investigation opened against `functions/src/icalExport.ts` + the dev URL the EE flow consumed.

---

## 5. NEW finding — `nights` field never written by `createBookingAtomic` either

audit/26 §6 (Finding #5) framed the missing `nights` field as a **direct-write-only** issue, asserting *"Auto-resolves if PR-A lands: `createBookingAtomic`/`updateBookingAtomic` compute nights via `calculateBookingNights`."*

This run's evidence:

- Booking B2 (`Jba8l3AaWH3mno1PKlXQ`) was created via the real CF path (`createBookingAtomic`, 200 success, full payment validation + price recompute landed).
- Direct admin read of the persisted doc: `nights: undefined`. All other expected fields present (`access_token`, `booking_reference`, `total_price: 330`, etc.).
- Source grep: `grep -n "nights: " functions/src/atomicBooking.ts` returns hits only at lines 599 and 622 — **both inside log objects** (`captureMessage` / `logSuccess` params), NOT inside the booking doc write.

**Implication for audit/26 PR-A:** Finding #5 does NOT auto-resolve from routing owner edits through CF — the CF itself doesn't write the field. PR-A must explicitly add `nights: calculateBookingNights(checkIn, checkOut)` to the doc-write payload in both `createBookingAtomic` (existing) and `createOwnerBookingAtomic` / `updateBookingAtomic` (new). Otherwise the gap persists on every BookBed-native booking, not just owner direct writes.

Severity: same (LOW UX — Dart `BookingModel.fromJson` falls back to calculated value), but scope is BROADER than audit/26 §6 implies.

---

## 6. Empirical confirmation — audit/26 §7 row 3 (CG index exemption needed)

During cleanup, the CG sweep `db.collectionGroup('bookings').where('source','==','manual_test_CC_reject').get()` crashed with:

```
9 FAILED_PRECONDITION: The query requires a COLLECTION_GROUP_ASC index for collection bookings and field source.
You can create it here: https://console.firebase.google.com/v1/r/project/bookbed-dev/firestore/indexes?create_exemption=...
```

→ audit/26 §7 row 3 (*"Cleanup CG sweep on bookings.source needs Firestore index exemption — XS — add single-field exemption on bookings.source"*) is **empirically validated**. Recommend ship as part of the fixture micro-PR.

Workaround applied this run: deleted by known doc IDs.

---

## 7. NEW finding — `getUnitIcalFeed` cache never invalidated on booking mutations

`icalExport.ts` ships a 5-minute Firestore-backed cache (`widget_settings.ical_cache_content`, TTL `ICAL_CONFIG.CACHE_TTL_SECONDS=300`). Grep result:

```
$ grep -rn "ical_cache_content\b" functions/src/
functions/src/icalExport.ts:169    const cachedContent = widgetSettings.ical_cache_content;
functions/src/icalExport.ts:320    ical_cache_content: icalContent,
```

Only two references — both inside `icalExport.ts` itself. Neither `bookingManagement.ts` (onBookingCreated / onBookingStatusChange) nor `atomicBooking.ts` writes / deletes `ical_cache_content`. Consequence: after any booking is created, approved, rejected, or cancelled, the public iCal feed continues serving the stale snapshot for up to 5 minutes.

**Why this matters:** external platforms (Airbnb, Booking.com, Google Cal) typically poll iCal feeds on cadences ≥ 15 min, so the 5-min lag is usually invisible to them. But:

- A guest who just got rejected, then tries to re-book the dates instantly on the same widget, may briefly see the cached state (their old booking still marked "Reserved") if the widget reads via iCal anywhere. The widget primarily reads `getUnitAvailability` (which IS live, no cache), so this is a low-impact gap today.
- Owner pulling the feed URL to manually verify a fresh booking landed → sees stale content for up to 5 min, which is confusing UX.

**Suggested fix (~5 lines):** add `ical_cache_content`, `ical_cache_generated_at`, `ical_cache_etag` to `FieldValue.delete()` calls inside `onBookingCreated` and `onBookingStatusChange` (and likely on booking-doc deletion via separate trigger). XS effort.

Empirically verified during this run by force-flushing the cache between every probe to capture the create / reject / delete deltas (table row 8 above).

---

## 8. NEW finding — price-mismatch alerting is correctly instrumented (positive confirmation)

Step 9's intentional client-vs-server price discrepancy (`totalPrice: 300` sent, server computed 330 from base + weekend differential on Jul 24) DID fire the alerting chain. From `gcloud logging read --project=bookbed-dev` filter on `resource.type="cloud_run_revision"`, service `createbookingatomic`, freshness 2h:

| Timestamp (UTC) | Severity | Message | Payload |
|---|---|---|---|
| 2026-05-23T14:42:54.359Z | WARNING | `[PriceValidation] Price mismatch detected` | clientPrice=300, unitId=SEED_test_owner_unit_01 |
| 2026-05-23T14:42:54.360Z | **WARNING** | **`[Security:HIGH] price_mismatch_detected`** | clientPrice=300, serverPrice=330, propertyId=SEED_test_owner_property_01, unitId=SEED_test_owner_unit_01 |
| 2026-05-23T14:42:54.362Z | INFO | `[AtomicBooking] Price mismatch - using server-calculated price` | clientPrice=300, unitId=SEED_test_owner_unit_01 |

Execution ID `igk4ll31eb3d`, region `us-central1`, runtime nodejs20.

**Per `.claude/rules/cloud-functions.md` HttpsError client-fault filter:** none of these are `HttpsError` throws (they're `logWarn`/`captureMessage` calls), so the filter doesn't drop them — these SHOULD land in Sentry under `environment=development`. Cannot confirm Sentry receipt without dashboard access, but the captureMessage chain is in place.

→ Affirmative test: server-side price-tampering alerting is working as designed. No gap here.

---

## 9. Telemetry capture

| Surface | What was capturable | What was NOT |
|---|---|---|
| Resend message IDs | NOT retrievable from this session (no API key access). Indirect signal: `emails_sent.rejection.sent_at: 2026-05-23T14:40:30.978Z` proves send returned success (the CF only writes that key in the success branch — `bookingManagement.ts:404-409`). | actual `provider_id` (also missing from the doc itself per audit/26 Finding #1) |
| Sentry breadcrumb / transaction ID | NOT captured (no dashboard access). Per `.claude/rules/cloud-functions.md` HttpsError client-fault filter, no Sentry signal expected on the happy path (only 5xx-class errors send). | — |
| FCM push | NOT verified (no mobile device active during this run). Owner notification email path IS implied to have fired via the parallel `onBookingCreated` trigger for B1 — but no probe captured it. | actual push delivery |
| Firestore audit trail | ✅ both `created_at` and `updated_at` server-timestamped; `rejected_at` set; `emails_sent.rejection.sent_at` set | — |

---

## 10. Visual/UI anomalies — none (test was admin SDK + CF HTTP only, no UI driven)

No screenshots captured because no UI was driven. Substantive findings are in §5 (nights field), §7 (iCal cache), §8 (price-mismatch trace) — all observable in logs/firestore state, not screen-recorded.

---

## 11. Open items deferred (out of scope for this run, NOT to fix here)

| Item | Disposition | Reason |
|---|---|---|
| Direct-write bypass paths (audit/26 §2.2 inventory) | PR-A scope | Per audit/26 §9 — separate PR group |
| `provider_id` capture from Resend (audit/26 Finding #1) | PR-B scope | Same — separate PR group |
| `nights` field not written by CF (this run §5) | Extend PR-A scope | New scope-expansion datapoint for audit/26 §6 — audit/26 §6 patched inline (see §12 below) |
| iCal cache never flushed on booking mutations (this run §7) | New micro-PR or fold into PR-A | XS-effort cache-flush in two trigger handlers |
| widget_mode-coupled re-book friction (§3) | Fixture micro-PR | Same micro-PR as audit/26 §7 |
| `widget_settings` path correction in audit/26 §7 row 2 (§4) | Doc edit on audit/26 | One-line correction (not applied this session — separate doc-only PR if owner wants) |
| CG index exemption on `bookings.source` (§6) | Fixture micro-PR | empirically validated audit/26 §7 row 3 |

## 12. Doc-only patch — note inside audit/26 §6

Recommend adding the following sentence to audit/26 §6 immediately after "Auto-resolves if PR-A lands":

> **2026-05-23 correction (per audit/27 §5):** the auto-resolve assertion is incorrect. `createBookingAtomic` itself does not write `nights` either — `nights:` only appears at `atomicBooking.ts:599` and `:622` inside log/captureMessage objects, never in the booking-doc payload. PR-A must explicitly add `nights: calculateBookingNights(checkIn, checkOut)` to all atomic-booking write paths.

Doc-only — no code change. Author of audit/27 (this run) recommends but did not apply; touching audit/26 in-line is at PR review discretion.

---

## 13. Cleanup verified

- Both test bookings (B1 `W8NIgbJJYlVsRu6z1A6F`, B2 `Jba8l3AaWH3mno1PKlXQ`) deleted from `properties/SEED_test_owner_property_01/units/SEED_test_owner_unit_01/bookings/`.
- Final `getUnitAvailability` probe (Jul 1 – Aug 15): `windows: []` ✅.
- `widget_settings.widget_mode` restored to `booking_instant` ✅ (verified post-restore read).
- No `email_verifications` docs touched.
- No Stripe sessions created.
- No external iCal feeds added/modified.
- Pre-existing `properties/SEED_test_owner_property_01/bookings/SEED_test_owner_booking_01` (root, NOT subcollection) — left untouched; predates this run, unrelated to reject trigger path.

---

## 14. References

- `audit/25-e2e-test-catalog.md` §2.4 (iCal export route name correction — `getUnitIcalFeed` not `icalExport`), §2.8 (edit booking → reject path)
- `audit/26-bb-e2e-findings.md` §2.2 (direct-write inventory), §5 (provider_id), §6 (nights — needs §12 patch), §7 (fixture gaps — row 2 path inverted, row 3 confirmed)
- `functions/src/bookingManagement.ts:258-410` (`onBookingStatusChange` reject branch)
- `functions/src/atomicBooking.ts:54-414` (createBookingAtomic + widget_mode validation), `:595-625` (nights logged but not persisted)
- `functions/src/availability.ts:113-185` (anon `getUnitAvailability` schema + query)
- `functions/src/icalExport.ts:92-345` (`getUnitIcalFeed` route + 5min cache without invalidation hooks), `:225` (status query `["confirmed","pending","completed"]`)
- `lib/features/owner_dashboard/data/firebase/firebase_owner_bookings_repository.dart:885-925` (FROZEN `rejectBooking` shape mirrored)
- `.claude/rules/cloud-functions.md` (HttpsError client-fault filter — relevant to §8 captureMessage chain)
- `memory/smoke-blocked-date-recipe.md` (anon CF call + ADC override pattern reused)
- `memory/test-account.md` (dev test owner UID `GILVItIVP5R8WXfnMmyMo1ykhUm2`)
