# audit/25 — Comprehensive E2E test catalog

**Date:** 2026-05-23
**Scope:** Reference document for parallel E2E test sessions on `bookbed-dev`. Maps every user-facing surface, every end-to-end flow, every catalogable edge case, the required fixture set, the parallel-execution protocol, and the post-run cleanup.
**Mode:** Doc only — no test execution. Grounded in current `main` (HEAD `e09eec9f`).
**Predecessors:** `audit/12-widget-e2e-dev.md` (single-flow widget smoke), `audit/16-cf-smoke-and-rules.md` (CF curl matrix), `audit/16-ios-regression-full.md` + `audit/19-wave3-cleanup.md` (mobile regression scaffolding), `memory/wave0-test-findings.md` (Marionette gotchas), `memory/test-account.md` (dev test creds).

> **Reading order before running**: this doc → `.claude/rules/cloud-functions.md` (CF region + logger conventions) → `memory/test-account.md` (working dev creds) → `memory/smoke-blocked-date-recipe.md` (anon CF call recipe). Per-flow detail lives in the cross-referenced rule files; this doc is the index.

---

## 1. Surfaces under test

| Surface | Layer | Tech | Project | Region | Smoke vector |
|---|---|---|---|---|---|
| Widget (web) | guest-facing | Flutter Web (`widget_main_dev.dart`) inside iframe | `bookbed-dev` | hosting target `widget` → `bookbed-widget-dev.web.app` | Chrome + DevTools; URL `?property=...&unit=...` |
| Owner app — iOS | owner-facing | Flutter native (`main_dev.dart`) | `bookbed-dev` | n/a | iOS simulator + `flutter run --target lib/main_dev.dart`; plist swap per `.claude/rules/ios-development.md` |
| Owner app — Android | owner-facing | Flutter native (`main_dev.dart`) | `bookbed-dev` | n/a | emulator/device + `flutter run --release --target lib/main_dev.dart`; google-services swap per `.claude/rules/android-development.md`; debug-build bug → `--release` mandatory |
| Owner app — Web (desktop) | owner-facing | Flutter Web (`main_dev.dart`) | `bookbed-dev` | hosting target `owner` → `bookbed-owner-dev.web.app` | Chrome (desktop layout ≥1200px) |
| Cloud Functions — interactive | backend callables | TypeScript v2 `onCall` | `bookbed-dev` | `europe-west1` (`getUnitAvailability`, `scheduledIcalSync`) + `us-central1` (most others — see `audit/11-cloudfunctions-inventory.md`) | `curl` with Firebase ID token; recipe `memory/smoke-blocked-date-recipe.md` |
| iCal public endpoint | external sync | TS `onRequest` (`icalExport.ts`) | `bookbed-dev` | `us-central1` (region drift documented `audit/24` §1) | `curl https://us-central1-bookbed-dev.cloudfunctions.net/getUnitIcalFeed/...` |
| Stripe webhook | payment side effect | TS `onRequest` (`stripePayment.ts:878 handleStripeWebhook`) | `bookbed-dev` | `us-central1` | Stripe CLI `stripe listen --forward-to ...` (test-mode key); observe `event.type` switch (lines 917–1387) |
| Resend email | guest/owner notification side effect | API send via `emailService.ts` | n/a | global | **NO webhook handler in repo** — verify via Resend dashboard observation (`grep -rln 'resend.*webhook'` returns empty); bounce/delivery state polled visually |
| FCM push | owner mobile notification side effect | TS `fcmService.ts` send-to-token | `bookbed-dev` | `us-central1` | mobile app foregrounded + observe notification banner |
| Firestore (`bookbed-dev`) | state | Admin SDK | `bookbed-dev` | europe-west1 | `scripts/seed-bookbed-dev.js`; Firebase Console; Admin SDK ad-hoc node script per `memory/smoke-blocked-date-recipe.md` |
| Sentry | observability | DSN-tagged events | shared org | global | dashboard filter `environment=development`; pre/post counts |

**Region-mismatch caveat**: `getUnitAvailability` (interactive widget calendar) is `europe-west1`; `createBookingAtomic` (interactive widget submit) per `audit/11` + `audit/24` §1 footnote is `us-central1`. Cross-region jump on the SAME end-user flow. EU clients eat one ~120 ms RTT cost on the booking submit step. Performance gripe, not a correctness issue. Test plan does not need to gate on this, but `audit/24` recommends factoring this when timing-sensitive tests run on slow connections.

---

## 2. End-to-end flow matrix

Every flow is documented with: **Trigger** → **Steps (numbered)** → **Observable side effects** → **Failure modes / what to watch**. Cross-references to source line numbers reflect `main` at `e09eec9f`.

### 2.1 Direct booking flow — calendar-only, no payment

**Trigger:** Guest opens widget URL with `?property=&unit=` (no `confirmation=`), selects dates, fills guest form, hits submit. Widget unit configured with `paymentMethod='none'` and `bookingMode='pending'` or `'instant'` (no Stripe).

**Steps:**
1. Browser loads `bookbed-widget-dev.web.app/?property=SEED_test_owner_property_01&unit=SEED_test_owner_unit_01`. `BookingWidgetScreen` (`lib/features/widget/presentation/screens/booking_widget_screen.dart`) parses query params, calls `_sanitizeId()` + `_isValidFirestoreId()` defense-in-depth (regex `^[A-Za-z0-9]{20}$`).
2. Widget calls `getUnitAvailability` callable (`europe-west1`) anonymous (post-T11c — see CLAUDE.md NIKADA NE MIJENJAJ table + `audit/06-availability-cf-design.md` referenced from `docs/SECURITY_FIXES.md` SF-019). Receives `windows: AvailabilityWindow[]` with `source ∈ {booking, manual_block, ical_external}`. Refreshes at 30 s poll interval (`FirebaseAvailabilityRepository._defaultPollInterval`) — no realtime `.snapshots()` for bookings anymore.
3. User selects 2 calendar cells → `checkIn` + `checkOut` populate in `BookingFormState` (`lib/features/widget/state/booking_form_state.dart:35-38`). `nights = DateNormalizer.nightsBetween(in, out)`.
4. User clicks "Book now" / "Continue". `showGuestForm` flips true. Form: `firstName`, `lastName`, `email`, `phoneWithCountryCode`, `adults` (default 1), `children` (default 0), `pets` (default 0), `notes`, `taxLegalAccepted` (must be true to submit).
5. Email OTP gate (see flow 2.10) gates submit if widget unit requires it. `emailVerified` must be true.
6. Submit triggers `SubmitBookingUseCase` (`lib/features/widget/domain/use_cases/submit_booking_use_case.dart`). For non-Stripe path, calls `createBookingAtomic` callable (`functions/src/atomicBooking.ts:54`, `us-central1`).
7. CF runs transaction: rate-limit by IP-hash (DoS protection, `MAX_BOOKING_NIGHTS=365`); `validateAndConvertBookingDates`; `validateBookingPrice` (re-computes price server-side from `daily_prices` — client price is advisory, server price wins); availability check against bookings `status ∈ {pending, confirmed, in_progress}` (see `audit/23` §B for the 3-status parity discussion).
8. On success: writes booking doc `properties/{pid}/bookings/{bid}` with `status='pending'` (instant mode) or `status='pending'` (manual approval mode) — both modes start `pending`; difference is whether owner action is required to flip to `confirmed`. Booking reference generated by `bookingReferenceGenerator.generateBookingReference()` (format `BK-{12_ALPHANUMERIC}` — see widget regex `^BK-[A-Za-z0-9]{12}$`).
9. `onBookingCreated` Firestore trigger (`bookingManagement.ts:162`) fires: sends `pending-owner-notification.ts` email to owner via Resend (`emailService.ts:82` `new Resend(apiKey)`); creates FCM push to owner mobile (`fcmService.ts`); creates in-app notification doc.
10. Guest receives `pending-request.ts` or `booking-confirmation.ts` email (depending on unit mode). URL in email includes `lang=hr|en|de|it` per `emailService.ts:319-328` `generateViewBookingUrl(language)`.
11. Widget redirects guest to in-screen confirmation card with booking reference + "view booking" link → `/view?ref=BK-...&email=...&token=...` (token-gated `BookingViewScreen`).

**Observable side effects:**
- Firestore: 1 new doc under `properties/{pid}/bookings/`
- Firestore: 1 new doc under `users/{ownerUid}/notifications/`
- Resend dashboard: 2 messages sent (guest + owner) within ~3 s
- FCM: 1 push delivered to owner mobile (if token registered)
- Sentry: 0 events expected (only on error)
- Widget UI: redirects to confirmation card (NOT a route change; same `BookingWidgetScreen` with `confirmation` query param synthesized)

**Failure modes:**
- Cookie consent: **NO cookie consent banner in widget** (grep returned no matches; only false-positive IT translation "consentito"). Not a blocker.
- Cart persistence: `BookingFormState` is **in-memory only** — F5 mid-flow wipes the form. No localStorage shadow. Verify by reload before submit.
- Multi-tab race: two tabs same dates same unit — second submit fails with `HttpsError unavailable` from `createBookingAtomic` transaction conflict (Firestore transactional read of overlapping bookings). Verify error toast and UI re-fetches `getUnitAvailability`.
- Network drop mid-submit: `isProcessing=true` lock prevents double-submit on retry tap; on connection restore, submit retries OR shows error toast. If CF received submit before network died, idempotency is NOT explicit — risk of duplicate booking creation. Test by killing network just before Continue tap.
- iOS keyboard reflow defeats Marionette coord-tap (per `memory/test-account.md`) — for iOS automated runs use `enter_text` over `tap` for form fields.

---

### 2.2 Stripe payment booking flow

**Trigger:** Guest selects dates on widget where unit `paymentMethod='stripe'` and `paymentOption='deposit'` (default 20% — `stripe_payment_config.dart:33`) or `'full'`.

**Steps:**
1. Steps 2.1.1–2.1.5 identical (calendar + guest form + email OTP gate).
2. Submit calls `createStripeCheckoutSession` (`stripePayment.ts:133`, `us-central1`). CF:
   - Validates return URL against `getAllowedReturnDomains()` (whitelist + `*.view.bookbed.io` wildcard) AND `isAllowedReturnUrl()` split-based validation (prevents "evil-bookbed.io" endsWith bypass — `stripePayment.ts` lines below `ALLOWED_WILDCARD_DOMAINS`).
   - Server-recomputes price from `daily_prices` (line 444 "Client may send locked price (€102.00) but server calculates" — never trust client price).
   - Computes deposit via `calculateDeposit(totalAmount)` (cent-based, matches Dart `payment_config_base.dart:20`).
   - Creates Stripe `checkout.Session` (test-mode key from `stripeSecretKey` secret).
   - Writes booking doc with `status='in_progress'` (or stays pending until webhook completes — verify via cutover plan SF-019 wording).
3. CF returns `session.url`. Widget redirects (top-level via `window.location` per `web/bookbed-overlay.js` integration) to `https://checkout.stripe.com/c/pay/cs_test_...`.
4. Guest pays with `4242 4242 4242 4242` (no 3DS) or `4000 0027 6000 3184` (forces 3DS challenge).
5. Stripe POSTs webhook to `handleStripeWebhook` (`stripePayment.ts:878`, `us-central1`). Verifies `stripe-signature` header via `stripe.webhooks.constructEvent` with `STRIPE_WEBHOOK_SECRET`. Logs `logWebhookSignatureFailure` on failure (security monitoring).
6. Handles event:
   - `checkout.session.completed` (line 1116) → flips booking `status='confirmed'`, fires `booking-confirmation.ts` email (guest) + `booking-approved.ts` email (owner notification) + FCM push.
   - `checkout.session.expired` (line 975) → flips booking `status='cancelled'`, sends owner notification.
   - `charge.refunded` (line 917) → sends `refund-notification.ts`.
   - `invoice.paid` (line 1066) → subscription path; not booking-relevant.
   - `customer.subscription.deleted` (line 1025) → subscription cancellation.
   - **Any other event type** (line 1386–1387) → logged as "Unhandled event type" and silently dropped. No alert.
7. Stripe redirects guest browser to `return_url` (`https://bookbed-widget-dev.web.app/?property=...&unit=...&confirmation=BK-...`). Widget detects `confirmation` query param in `router_owner.dart:347-349` and renders confirmation card.

**Failure modes:**
- Webhook delayed >5 min (Stripe retry semantics: up to 3 days). Booking sits in `in_progress` limbo. `cleanupExpiredPendingBookings.ts` (scheduled) eventually flips orphaned in-progress bookings — verify schedule + threshold.
- 3DS abandoned by guest: Stripe fires `checkout.session.expired` after Session TTL (default 24 h). Until then booking blocks availability. Test by initiating 3DS challenge, closing tab.
- Webhook signature mismatch (wrong secret in env): logged + 400 returned + booking stays `in_progress` forever. Sentry alert via `logWebhookSignatureFailure`.
- Refund partial vs full: only `charge.refunded` handled; partial refunds NOT distinguished from full in current handler — verify behavior or flag as gap.
- Return URL injection: attacker passes malicious `return_url` query — must be blocked by `isAllowedReturnUrl`; test by passing `https://evil-bookbed.io.attacker.com`.

---

### 2.3 Booking with R1 invoice (company order) — **NOT IMPLEMENTED**

**Status:** No widget surface captures OIB or company name; no email template attaches an invoice PDF; no Cloud Function generates R1 invoices.

**Evidence:** `grep -irln 'r1Invoice\|R1Invoice\|companyOIB\|invoice.*generation'` against `lib/features/widget/` + `functions/src/` returns zero matches. Only `oib` hits are owner-side localization keys in `lib/l10n/app_*.arb` (likely owner profile bank/tax form, not guest checkout). `functions/src/email/templates/` contains no `invoice-*.ts` template.

**Test plan:** Do NOT attempt this flow. Flag as **MISSING FLOW** to product owner. If/when implemented, this catalog row updates to cover: capture form (`isCompany`, `companyName`, `OIB`), invoice PDF generation (likely a CF that uses `pdfkit` or similar), email attachment, archival in Firestore + Storage.

---

### 2.4 iCal sync — outbound (BookBed → external platform)

**Trigger:** External platform (Airbnb, Booking.com, Google Calendar) polls the BookBed-published feed URL on its own cadence (Google: 12–24 h; Apple: 15 min–6 h; Outlook: 1–3 h — per `audit/24` §1).

**Steps:**
1. Owner copies feed URL from `IcalExportListScreen` (`lib/.../ical/ical_export_list_screen.dart`). Format: `https://us-central1-bookbed-dev.cloudfunctions.net/getUnitIcalFeed/{propertyId}/{unitId}/{token}` (region drift documented `audit/24` §1).
2. Optional: `?exclude=airbnb|booking` filter (hub-and-spoke). `_sanitizeSource()` in Dart MUST match `sanitizeSource()` in `icalExport.ts` (critical learning #10 in `memory/MEMORY.md`). Mismatch → external platform receives no events even though feed exists.
3. External platform fetches URL → `icalExport.ts` validates token via `verifyExportToken()`, looks up bookings `status ∈ {confirmed, in_progress}` ∪ blocked dates + imported iCal events from OTHER platforms (`?exclude=` filter). Returns `text/calendar` body. Caches via `ETag` + `Cache-Control: max-age=300`.
4. DoS bounds: `MAX_BOOKINGS=500`, `MAX_ICAL_EVENTS=500`, `MAX_BLOCKED_DAYS=1000`, `PAST_DAYS=90`, `FUTURE_DAYS=365`.
5. HEAD requests allowed (critical learning #17 — validators send HEAD before GET; previously rejected with 405, fixed Feb-2026).

**Observable side effects:**
- External platform calendar populates within poll interval
- ETag header changes when booking docs change (manual cache-bust requires URL rotation — `regenerateToken` callable if present)

**Failure modes:**
- Token reuse after rotation: old URL returns 403; external platform stops syncing silently. Owner-visible via "last sync" badge in `IcalExportListScreen`.
- Holiday-Home echo loop: Holiday-Home re-exports BookBed feed back into BookBed import (critical learning #7 + memory `ical-sync.md`). Mitigation: `?exclude=holiday-home` filter on the feed Holiday-Home consumes.
- 100 MB feed limit (Google Calendar): if feed > 100 MB, sync silently fails. Verify `MAX_BOOKINGS` keeps response under cap.

---

### 2.5 iCal sync — inbound (external feed → BookBed import)

**Trigger:** `scheduledIcalSync` runs every 15 min (`icalSync.ts:112`, `europe-west1`, timeout 540 s, 512 MiB). Or owner taps "Sync now" → `syncIcalFeedNow` callable (`icalSync.ts:245`).

**Steps:**
1. CF runs `db.collectionGroup('ical_feeds').where('status', 'in', ['active', 'error']).get()` — re-tries error feeds.
2. For each feed: fetch URL via `fetch()`, parse iCal body with `ical.js` or equivalent, extract VEVENTs.
3. For each VEVENT: run `echoDetection.ts` 5-factor score (DTSTAMP proximity, UID containment, date alignment, platform classification, native presence). If `score ≥ threshold` → flag as echo → either `flag_review` (owner manual triage) or `save_trimmed` (containment analysis — see flow 2.6).
4. For non-echo: upsert `properties/{pid}/units/{uid}/ical_events/{uid_hash}` doc. Status set to imported event (NOT a booking).
5. SF-023 rules lockdown (deployed `bookbed-dev` 2026-05-22 per `audit/17`): `ical_events` no longer publicly readable; widget calendar reads via `getUnitAvailability` only.
6. Logs: `[Scheduled iCal Sync] Found feeds to sync, count=N`; per-feed success/error rollup; conflict count if any.

**Failure modes:**
- Feed URL returns HTML (login page, soft-404): parser returns 0 events; feed flips `status='error'`; auto-retried next cycle. Verify via `lastSyncError` field on feed doc.
- VEVENT with no UID: deduplication breaks. `echoDetection.ts` falls back to dtstart+dtend+summary hash — see `memory/audit-findings-2026-05-18.md` (UID stability gotcha).
- DST transition (Mar/Oct EU): iCal `DTSTART;TZID=Europe/Zagreb:20260329T000000` vs UTC `Z` form. Verify Zagreb-civil-day normalization per SF-026 (`dateValidation.ts` STEP 6 + `audit/22` §1).
- Aggregator re-exports own native bookings as merged blocks (Adriagate, Holiday-Home per critical learning #8). Containment analysis in `echoDetection.ts` must skip these. Test flow 2.6.

---

### 2.6 Echo detection — Aggregator re-export of BookBed bookings

**Trigger:** Owner enables import from a platform that re-exports its own feed (Adriagate `import_enabled=true`, Atraveo, Holiday-Home). BookBed creates a confirmed booking; aggregator pulls it; next iCal sync cycle hits BookBed.

**Steps:**
1. Native BookBed booking exists: `properties/{pid}/bookings/BK-ABC` `status='confirmed'` Jul 19–31.
2. Adriagate pulls BookBed iCal feed (hub-and-spoke), re-exports as their own VEVENT, possibly merged with adjacent blocks: Jul 19 – Aug 14 (26 nights, merging blocks A+B+C).
3. `scheduledIcalSync` fetches Adriagate feed → echoDetection:
   - **5-factor score**: DTSTAMP proximity (recent), UID containment (Adriagate UID ⊃ BookBed BK-ABC ref? typically not), date alignment (overlaps), platform classification (Adriagate = `aggregator`), native presence (BK-ABC exists in DB) → high score.
   - **Containment analysis**: Is 100 % of Jul 19 – Aug 14 covered by union of existing BookBed bookings + blocks? If yes → skip import (pure echo). If partial (e.g. Aug 7–14 not covered) → either `save_trimmed` (import only Aug 7–14) or `flag_review`.
4. Decision logged to feed doc + per-VEVENT result doc.

**Failure modes:**
- Containment skipped when it should fire → duplicate block created, calendar shows guest can't book valid date. Verify via `getUnitAvailability` returning `windows[].source='ical_external'` for the wrong range.
- Containment fires when it shouldn't (genuine native Adriagate booking misclassified as echo) → REAL guest blocked, slot leaks. Severe. Audit via feed result docs + cross-check Adriagate dashboard.
- Trimming math off-by-one at day boundary → either over-trim (lose 1 night of real block) or under-trim (1 ghost night). DST boundary specifically exposes this.

---

### 2.7 Manual block (owner-initiated dates blocked)

**Trigger:** Owner opens `OwnerTimelineCalendarScreen` (`/owner/calendar/timeline`) → selects unit row + drags range → "Block" action.

**Steps:**
1. Owner UI calls `BookingService` to write `properties/{pid}/bookings/{auto_id}` doc with `status='confirmed'`, `is_blocked=true` (or equivalent flag — verify field name) and no guest PII. Atomicity via `createBookingAtomic` shared transaction logic (NOT a separate "blocks" collection — they live as zero-price bookings).
2. `onBookingCreated` (`bookingManagement.ts:162`) fires but skips guest email (no guest_email field).
3. Calendar refresh (30 s poll OR realtime owner-side `.snapshots()` — owner reads ARE realtime, only widget reads are polled per T11c).
4. Next `getUnitAvailability` widget call returns `windows[].source='manual_block'` for that range.
5. iCal export feed includes the block (DoS-bounded to 1000 blocked days — `icalExport.ts MAX_BLOCKED_DAYS=1000`).

**Failure modes:**
- Overlap with existing booking: `createBookingAtomic` rejects with availability conflict. Owner sees error toast. Verify the 3-status check (`pending|confirmed|in_progress` per `audit/23` §B).
- Edit-block UI: changing a block range = delete + create OR in-place update? Verify in `booking_inline_edit_dialog.dart` (critical learning #13 — Quick Edit dialog).
- Block deletion: Quick Edit Delete button → Firestore delete → `onBookingStatusChange` (`bookingManagement.ts:258`) fires for completeness but no email sent for blocks.

---

### 2.8 Edit booking — owner changes dates/price/guests

**Trigger:** Owner taps a booking in calendar → opens edit dialog → modifies → save.

**Steps:**
1. Owner UI fetches booking doc, opens edit form. Fields editable: check_in, check_out, price overrides, guest count, status (approve/reject/cancel).
2. On save: client writes to `properties/{pid}/bookings/{bid}` directly (owner-write path; NOT through `createBookingAtomic`). `firestore.rules` `bookings` `update` rule must allow owner.
3. `onBookingStatusChange` (`bookingManagement.ts:258`) trigger fires on `status` change. Sends:
   - `booking-approved.ts` (pending → confirmed)
   - `booking-rejected.ts` (pending → cancelled by owner)
   - `owner-cancellation.ts` (confirmed → cancelled by owner)
   - Re-sends `booking-confirmation.ts` with updated dates (verify trigger logic).
4. iCal export feed regenerates on next external poll (no push to platforms — they pull).
5. Owner calendar refreshes via `.snapshots()`; widget calendar refreshes via next 30 s poll of `getUnitAvailability`.

**Failure modes:**
- Owner edits dates onto a conflicting range: server rule must reject — verify. If client write succeeds because rules don't enforce overlap (rules don't run transactions), data integrity breaks. **Likely gap** — `createBookingAtomic` is the only overlap-safe path; direct owner writes bypass it. Test: owner manually pushes booking A onto same dates as booking B.
- Status flip storm: rapid pending → confirmed → cancelled → pending sequence may fire 4 emails to guest. Verify `onBookingStatusChange` debounces or relies on idempotency.
- Email re-send (Resend `resendBookingEmail.ts`, `resendGuestBookingEmail.ts`): owner taps "Resend confirmation" — verify rate limit on these callables.

---

### 2.9 Multi-language (HR/EN/DE/IT)

**Trigger:** Widget URL with `?lang=de` (or guest browser locale fallback). Owner mobile/web honors `enhanced_auth_provider` locale.

**Steps:**
1. `WidgetTranslations` (`lib/features/widget/presentation/l10n/widget_translations.dart:11`) supports `['hr', 'en', 'de', 'it']`. Default Croatian (`'hr'`). 275 translation strings (`grep -c "String get"`).
2. Widget renders all UI strings (`selectYourDates`, `bookingConfirmation`, error messages) in selected locale.
3. On submit, `paymentMethod`, `paymentOption`, `taxLegalAccepted` strings pass to CF as English enum values — CF does not branch on locale.
4. Email `viewBookingUrl` built via `generateViewBookingUrl(language)` (`emailService.ts:319-328`) — appends `?lang=<code>` if `language ∈ {hr,en,de,it}`. Default omit param if invalid.
5. **Email template text is `hr-HR` hardcoded** for date format (`template-helpers.ts:90 formatDate uses "hr-HR"` ALWAYS). Guest receives `7. kolovoza 2026.` even if `lang=en`. Subject lines + body copy — verify per-template whether locale switching happens (likely it does NOT — most templates appear monolingual Croatian).

**Failure modes:**
- Currency: `formatCurrency` (`template-helpers.ts:76`) hardcoded EUR. No GBP/USD support. Only an issue if non-EUR markets onboard.
- Phone country: widget form uses `phoneWithCountryCode` (`booking_form_state.dart:57`) — country selector defaults likely HR (+385). Verify Italian/German tests select correct country.
- Date format: widget UI may show `07.08.2026.` (HR) vs `8/7/2026` (EN). Email always HR format → mismatch UX. Document as **MISMATCH gap**.
- Email language coverage: walk `functions/src/email/templates/*.ts` — most have no `languageCode` param. Confirm with `grep -n "languageCode\|locale" functions/src/email/templates/*.ts`.

---

### 2.10 Email OTP verification gate (discovered during catalog write)

> Replaces the not-applicable "Geolocation delivery zone" flow — BookBed has no delivery; grep for `delivery_radius` returns zero. This OTP flow IS real and gates flow 2.1/2.2 in current widget builds.

**Trigger:** Widget unit has `widgetSettings.emailConfig.requireEmailVerification=true`. Guest enters email in guest form → "Verify" button.

**Steps:**
1. Widget calls `sendEmailVerificationCode` callable (`emailVerification.ts:56`). CF:
   - Validates email via `validateEmail`, `sanitizeEmail`.
   - Rate-limit: `RESEND_COOLDOWN_SECONDS=60` (per-email), `DAILY_LIMIT=20` (per-IP UTC-day-bucketed via `getUTCDayString`).
   - Generates 6-digit code with `crypto.randomInt(100000, 1000000)`.
   - Stores `email_verifications/{sha256(email)}` with `code_hash`, `expires_at=now+30min`, `attempts=0`.
   - Sends `email-verification.ts` Resend email.
2. Guest receives email, copies code into widget field.
3. Widget calls `verifyEmailCode` callable (`emailVerification.ts:242`). CF compares hashed code, increments `attempts`, fails after `MAX_ATTEMPTS=3`.
4. On success: `BookingFormState.emailVerified=true` (line 100). Submit unblocks.
5. Optional pre-check: `checkEmailVerificationStatus` (`emailVerification.ts:404`) — returns whether email already verified within TTL.

**Failure modes:**
- Email delivery delay > 30 min TTL → code expired. Guest retries; cooldown blocks for 60 s. Bad UX, not a bug.
- Code brute force: 3 attempts → doc locks for TTL window. Verify by trying 999999 three times → 4th attempt rejected.
- Bounced email (typo): no signal to guest from CF (Resend bounce comes later, async). Guest sees "code never arrived" — only Resend dashboard reveals bounce. No webhook handler.
- IP rotation circumvents per-IP limit: yes, expected. Per-email limit (60 s cooldown) is the primary throttle.

---

## 3. Edge cases catalog

| # | Edge | Surface | Detection / what to verify |
|---|---|---|---|
| 3.1 | Same-civil-day check-in/out (0 nights) | Widget calendar | `DateNormalizer.nightsBetween` returns 0 → submit button must disable; CF rejects with `invalid-argument` if bypassed. Audit `audit/18-booking-count-audit.md` and SF-026 normalization. |
| 3.2 | DST spring-forward (last Sunday March, Europe/Zagreb 02:00→03:00) | CF + email | Booking spanning night of `2026-03-29` must compute correct `nights=N`. SF-026 STEP 6 Zagreb-civil-day normalization in `dateValidation.ts` is the fix. Verify booking total still matches `nights * nightlyPrice`. |
| 3.3 | DST fall-back (last Sunday October, 03:00→02:00) | CF + email | Same as 3.2; 25-hour day. iCal export DTSTART/DTEND TZID handling matters here too. |
| 3.4 | Cross-year booking (Dec 30 – Jan 3) | Widget + CF + iCal | `daily_prices` must span year boundary. iCal feed `DTSTART:20251230` / `DTEND:20260103`. |
| 3.5 | Two-tab race on same dates | Widget + `createBookingAtomic` | Tab A submits first → wins. Tab B receives `HttpsError unavailable` via transaction conflict. Widget re-fetches `getUnitAvailability` and shows the now-blocked range. **Race window**: ~200 ms between transaction read and write. |
| 3.6 | Stripe webhook delayed > 5 min | Stripe + booking lifecycle | Booking stuck `in_progress`. `cleanupExpiredPendingBookings.ts` scheduled cleanup eventually flips it. Test by `stripe trigger checkout.session.completed --override --delay=300` (or manually queue). |
| 3.7 | Guest email bounce (hard) | Resend | No retry. Owner-side: only Resend dashboard shows. Guest never sees confirmation. **No bounce-webhook handler in repo** — confirmed gap. |
| 3.8 | Network drop mid-submit | Widget + CF | `isProcessing=true` prevents double-tap (`booking_form_state.dart:113`). On reconnect, no auto-retry; guest manually retries. **No idempotency key passed to `createBookingAtomic`** — risk of duplicate if first submit reached CF before drop. |
| 3.9 | F5 refresh mid-form | Widget | All `BookingFormState` lost (in-memory). No localStorage shadow. Guest must restart from dates. |
| 3.10 | Cookie consent declined | Widget | **No cookie consent banner in current widget** (verified by grep). Not applicable. |
| 3.11 | Owner offline when booking submitted | FCM + email | Booking still creates. FCM push queued by Google for ~28 days. Resend email sends regardless. Owner sees on next app open. |
| 3.12 | Property has multiple units | Widget + owner | Widget URL pins one unit (`?unit=...`); other units invisible to this guest. Owner calendar shows all units side-by-side (timeline view). Test by creating SEED 2-unit property. |
| 3.13 | Min-stay violation | Widget calendar | `unit.minNights` (or unit settings field — verify name). Calendar must disable check-out cells < check-in + min-nights. CF re-validates server-side. |
| 3.14 | Past date selection | Widget | Calendar disables past cells client-side. CF rejects via `validateAndConvertBookingDates` if bypassed. |
| 3.15 | Pet / extra-guest surcharge | Widget pricing breakdown + CF | `BookingFormState.pets` + `adults > unit.maxGuests` triggers per-unit surcharge fields. Test with pets=2 on unit that charges €10/pet/night. Server-recomputes via `priceValidation.ts`. |
| 3.16 | Cleaning fee | Widget + CF + iCal | Fixed-cost line item. Test that bank-transfer-only mode still includes cleaning fee in total. |
| 3.17 | VAT / tourist tax | Email | If unit has `taxConfig` enabled, breakdown line in `booking-confirmation.ts`. Croatian tourist tax (`turistička pristojba`) is per-night per-adult — verify per-adult math. |
| 3.18 | Apostrophe / unicode in guest name | Widget + email | `O'Brien`, `Müller`, `Đorđević`, Cyrillic. `escapeHtml` in `template-helpers.ts:60` must run on all user content. XSS test: try `<script>alert(1)</script>` as first name. |
| 3.19 | Email with `+` alias | Widget + OTP | `test+suite@example.com`. `validateEmail` must accept; `sanitizeEmail` must NOT strip the `+`. OTP doc keyed by `sha256(email)` — verify alias resolves correctly. |
| 3.20 | iCal HEAD request before GET | iCal export | Critical learning #17 — validators send HEAD. Must return 200 with same headers (no body). Test via `curl -I <feed-url>`. |
| 3.21 | Aggregator merges adjacent blocks | iCal sync inbound | Critical learning #8 — Adriagate merges A+B+C into single 26-night VEVENT. Containment analysis decides import/skip per flow 2.6. |
| 3.22 | Holiday-Home truncates blocks (212d→15d) | iCal sync inbound | Critical learning #7 — Holiday-Home import disabled by default. Verify `importEnabled=false` survives sync cycle. |
| 3.23 | Widget URL slug mode | Widget | `https://jasko-rab.view.bookbed.io/apartman-6` (subdomain + slug). Resolves property from subdomain via `subdomainService.ts`; resolves unit from slug. Different code path from `?property=&unit=`. Test both. |
| 3.24 | Subdomain validation regex | Widget | CLAUDE.md NIKADA NE MIJENJAJ: `/^[a-z0-9][a-z0-9-]{1,28}[a-z0-9]$/` (3–30 chars). Test edge: 2 chars, 31 chars, leading/trailing hyphen, uppercase. |
| 3.25 | Return URL injection on Stripe checkout | CF | Attacker passes `return_url=https://evil-bookbed.io.attacker.com`. `isAllowedReturnUrl` split-based validation must reject. Test before any prod cutover. |

---

## 4. Required test data fixtures

### 4.1 What `scripts/seed-bookbed-dev.js` provides today

Per the script docstring (`scripts/seed-bookbed-dev.js:1-21`):

| Path | When | Notes |
|---|---|---|
| `/properties/SEED_property_dev_01` | always | Idempotent `set({merge: true})` |
| `/properties/SEED_property_dev_01/units/SEED_unit_dev_01` | always | Single unit, basic config |
| `/properties/SEED_property_dev_01/bookings/SEED_booking_dev_01` | with `--with-booking` flag | Reconstructed from `audit/07` spec |

Default project: `bookbed-dev`. Refuses to run against `rab-booking-248fc` (line 31).

### 4.2 What the task spec referenced — NOT YET ON MAIN

The task spec named fixtures `SEED_test_owner_property_01` / `SEED_test_owner_unit_01` and a test account `bookbed-test@bookbed.io` / `BookBedTest2026!`. These come from **PR #449 (`chore/seed-test-owner-mode`, commit `5396b412`)** which `audit/22` §1 lists as **NOT yet merged** (held on `refactor/booking-widget-phase1` merge train pending CI billing fix). The branch exists on `origin/chore/seed-test-owner-mode` but is not in `main` at `e09eec9f`.

**Resolution paths (pick one before any parallel run starts):**

1. **Merge PR #449 first.** Adds `--test-owner` flag that creates the named fixtures + UID `GILVItIVP5R8WXfnMmyMo1ykhUm2` for `bookbed-test@bookbed.io` (per `memory/test-account.md`).
2. **Use existing fixtures.** Switch all flows in §2 to `SEED_property_dev_01` / `SEED_unit_dev_01`. Caveat: test owner may not be auth-bindable to those docs without manual ownership rewrite.
3. **Manual seed.** Hand-build the test-owner docs via Firebase Console + Admin SDK script.

### 4.3 Fixtures currently NOT in the seed (require manual provisioning before flow 2.X can run)

| Missing | Required by | Mitigation |
|---|---|---|
| Stripe Connect account linked to test owner in TEST mode | Flow 2.2 (Stripe payment) | Owner must complete Stripe Connect Express onboarding via `stripeConnect.ts createStripeConnectAccount` callable in test mode. Onboarding flow opens hosted page; needs test-mode test data (`000-00-0000` SSN proxy etc). No fixture script automates this today. |
| Multi-unit property fixture | Flow 3.12 | Add second unit doc under `SEED_property_dev_01` manually OR extend seed script. |
| External iCal feed mock host | Flows 2.4, 2.5, 2.6 | No local mock. Real Booking.com/Airbnb feeds cannot be tested deterministically (their re-export cadence is not on our timeline). Workaround: stand up an `ngrok`-tunneled local HTTP server returning a hand-crafted `.ics` body; register that URL as a feed; trigger `syncIcalFeedNow` manually. |
| R1 invoice fixture | Flow 2.3 | N/A — flow not implemented (see §2.3). |
| Test owner unit configured `paymentMethod='bank_transfer'` | Pricing/email coverage | Edit `SEED_test_owner_unit_01.widgetSettings.payment.bankTransfer.enabled=true` post-seed. |
| Email-verification OTP test inbox | Flow 2.10 | Use a Resend test address OR a real inbox the tester controls. No CF-side mock. |
| FCM token registered for owner mobile | Flow 2.1 step 9 push | First app login on a real device registers a token. Required before push verification. |

### 4.4 Sentry baseline

Before run: snapshot Sentry filter `environment=development` event count. After run: re-snapshot. Delta = test-induced events (most flows expect 0).

---

## 5. Test execution protocols (parallel)

### 5.1 Race-safety at Firestore layer

Multiple parallel test sessions on the SAME unit (`SEED_test_owner_unit_01`) are safe at the data layer because:

1. `createBookingAtomic` (`functions/src/atomicBooking.ts:54`) is a Firestore transaction. Two simultaneous bookings on overlapping dates → one wins, other receives `HttpsError unavailable`.
2. `getUnitAvailability` is read-only.
3. iCal sync is single-tenant per feed; parallel test runs do not interfere unless they target the SAME feed doc.

**Required protocol**: each parallel session uses a **distinct non-overlapping date range** on the same unit. Suggested partition:

| Session | Date range | Status start |
|---|---|---|
| A | Day +7 to Day +9 | empty |
| B | Day +14 to Day +16 | empty |
| C | Day +21 to Day +23 | empty |
| D | Day +28 to Day +30 | empty |

(Where `Day +N` means today + N days, Zagreb-civil-day basis per SF-026.)

### 5.2 Git race protocol

`memory/multi-agent-git-race.md` documents the parallel-branch swap risk. For E2E test runs there are **no commits expected** — pure observational tests. If a fix is discovered mid-run, that fix work happens on a NEW branch in a separate session, NOT on the test-run worktree.

### 5.3 Sentry monitoring snapshot

```text
# Before run (Sentry → Issues → filter environment:development → count)
baseline_count = <N>

# After run
post_run_count = <M>

# Expected: M - N == 0 for happy-path; M - N > 0 only for explicitly tested error paths
```

If unexpected delta, dump the new events and triage before clearing fixtures.

### 5.4 Required tools per surface

| Surface | Tool | Setup ref |
|---|---|---|
| Widget (web) | Chrome DevTools + Marionette MCP | `memory/flutter-web-input-bypass.md` for CanvasKit input gotchas |
| Mobile iOS | iOS Simulator + `flutter run` + Marionette MCP | `.claude/rules/ios-development.md` (plist swap mandatory) |
| Mobile Android | Android Emulator + `flutter run --release` + Marionette MCP | `.claude/rules/android-development.md` (google-services swap + `--release` requirement) |
| CF callable | `curl` + ID token via `firebase auth:export` or Admin SDK | `memory/smoke-blocked-date-recipe.md` |
| iCal endpoint | `curl -I` (HEAD) + `curl` (GET) | `audit/12-widget-e2e-dev.md` |
| Stripe | `stripe listen --forward-to <webhook-url>` | Stripe CLI; test-mode key |
| Firestore inspect | Firebase Console + Admin SDK ad-hoc | `memory/smoke-blocked-date-recipe.md` |
| Sentry | Web dashboard | filter `environment=development` |
| Resend | Web dashboard | filter by recipient or `tag=booking` if tagged |

### 5.5 Recommended order of execution

1. Run flow 2.1 (direct booking) — establishes baseline + populates 1 booking doc.
2. Run flow 2.7 (manual block) — verifies owner-write path on a separate date range.
3. Run flow 2.8 (edit booking) — modifies 2.1's booking.
4. Run flow 2.2 (Stripe) — only if Stripe Connect account fixture exists (see §4.3).
5. Run flow 2.10 (email OTP) — independent; can run in parallel with above.
6. Run flow 2.4 + 2.5 (iCal export + import) — slow loops; run last.
7. Run flow 2.6 (echo detection) — requires 2.5 fixture in place.
8. Run flow 2.9 (multi-language) — re-run 2.1 with `?lang=en|de|it`.
9. Edge cases §3 — pick by priority; 3.5 (two-tab race) + 3.18 (XSS) are the highest-value adversarial tests.

---

## 6. Cleanup checklist

After every E2E run (mandatory; each parallel session owns its own cleanup):

- [ ] **Delete all test bookings on the test property.**
  ```bash
  # Admin SDK script — list test owner's bookings created during this session
  # (use createdAt > session_start_timestamp filter)
  GOOGLE_CLOUD_PROJECT=bookbed-dev node -e '
    const admin = require("./functions/node_modules/firebase-admin");
    admin.initializeApp({projectId: "bookbed-dev"});
    const db = admin.firestore();
    db.collectionGroup("bookings")
      .where("created_at", ">", new Date(Date.now() - 3*3600*1000))
      .get().then(snap => {
        console.log("Found", snap.size, "bookings created in last 3h");
        return Promise.all(snap.docs.map(d => d.ref.delete()));
      }).then(() => console.log("Deleted"));
  '
  ```
- [ ] **Verify `getUnitAvailability` returns `windows: []`** for the test date range:
  ```bash
  # Per memory/smoke-blocked-date-recipe.md — anon-callable curl
  curl -X POST \
    "https://europe-west1-bookbed-dev.cloudfunctions.net/getUnitAvailability" \
    -H "Content-Type: application/json" \
    -d '{"data":{"propertyId":"SEED_test_owner_property_01","unitId":"SEED_test_owner_unit_01","from":"2026-06-01","to":"2026-08-31"}}'
  # Expect: windows: [] (or only persistent fixture blocks, not test-run-induced)
  ```
- [ ] **Reset `emailVerified` if test flipped it for the test inbox.** Delete `email_verifications/{sha256(test-email)}` doc.
- [ ] **Cancel orphan Stripe PaymentIntents in test mode.** Stripe Dashboard → Payments → filter `status=requires_payment_method OR requires_confirmation` → cancel each. Confirm no `cs_test_*` sessions left dangling.
- [ ] **Remove temporary iCal feed configs** added during flow 2.5. Delete `properties/{pid}/units/{uid}/ical_feeds/{feedId}` docs created by the test.
- [ ] **Reset feed `status` field** if flow 2.5 left a feed in `status='error'`.
- [ ] **Clear `ical_events` test docs**: `db.collectionGroup('ical_events').where('imported_at','>',session_start).get() → delete`.
- [ ] **Clear notification docs** on owner: `users/{ownerUid}/notifications/` created during session.
- [ ] **Sentry**: confirm `environment=development` event count delta matches expected (0 for happy-path).
- [ ] **Resend**: no required cleanup (emails are immutable history). Just verify no bounce alerts on tester's address.
- [ ] **Mobile FCM**: if test ran on dev device, unregister token via owner profile sign-out (or accept persisted token for next run).

---

## 7. Outstanding gaps to flag to product / engineering

These surfaced during catalog write and are NOT covered by any existing audit doc:

1. **No R1/OIB invoice flow** (§2.3). If Croatian business guests are an addressable market, this is missing.
2. **No Resend bounce webhook** (§3.7 + §1 surfaces table). Hard bounces fail silently.
3. **No idempotency key on `createBookingAtomic`** (§3.8). Retry-after-network-drop can duplicate.
4. **Owner direct write to `bookings` bypasses overlap-check transaction** (§2.8). Only `createBookingAtomic` runs the transactional read; owner edits skip it. Firestore rules cannot enforce overlap (rules don't have query primitives). Risk: owner-induced double-book.
5. **Email templates hardcode `hr-HR` date format** (§2.9). Multi-language coverage is UI-only, not email body.
6. **Region mismatch**: `getUnitAvailability` is `europe-west1`, `createBookingAtomic` is `us-central1` (§1). Same end-user flow crosses regions. `audit/24` §1 documents the iCal sibling case.
7. **`SEED_test_owner_*` fixtures not on `main`** (§4.2). Parallel runs blocked on PR #449 merge OR fixture rename to existing `SEED_property_dev_01` IDs.
8. **No mock external iCal host for deterministic flows 2.4/2.5/2.6** (§4.3).

---

## 8. References

- `CLAUDE.md` — NIKADA NE MIJENJAJ + STANDARDI + path-scoped rules table
- `.claude/rules/cloud-functions.md` — region, logger, rate-limit, FieldPath bug
- `.claude/rules/stripe.md` — checkout flow, webhook, return URL whitelist
- `.claude/rules/calendar.md` — DateStatus, timeline dimensions
- `.claude/rules/widget.md` — URL slugs, subdomains, iframe overlay
- `.claude/rules/firestore.md` — composite vs single-field indexes
- `audit/06-bookings-hotfix-partial.md` + `audit/06-indexes-drift.diff` — booking layer
- `audit/11-cloudfunctions-inventory.md` — full CF inventory (dev/prod), region per function
- `audit/17-sf023-sf025-rules-fix.md` — SF-023 ical_events + SF-025 storage rules
- `audit/18-booking-count-audit.md` — booking-count surface audit
- `audit/22-prod-cutover-plan.md` — combined T11c + SF-023..026 cutover plan
- `audit/23-misc-follow-ups.md` — §B 3-status parity + counter-save bug
- `audit/24-p3-backlog-investigations.md` — region drift, logWarn, build-mode
- `docs/SECURITY_FIXES.md` SF-019..026 — T11c, ical lockdown, storage, normalization
- `memory/test-account.md` — bookbed-test@bookbed.io creds
- `memory/smoke-blocked-date-recipe.md` — anon CF curl + ADC override recipe
- `memory/wave0-test-findings.md` — Marionette iOS gotchas
- `memory/wave-android-smoke-2026-05-23.md` — Android smoke + ErrorBoundary Marionette interaction
- `memory/ical-sync.md` — hub-and-spoke architecture + per-platform behavior
