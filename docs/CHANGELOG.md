# BookBed Changelog

All version history from v4.6 to v7.46.

**Last Updated**: 2026-07-18 | **Version**: 7.46

---

**Changelog 7.46** (2026-07-18) — full-screen `/audit` sweep (read-only, no code changed) — **COMPLETE: 48/48 screens + 104/241 components (all primitives); SUMMARY.md + REMEDIATION_PLAN.md shipped, execution started**:

### docs(audit): self-paced `/audit` sweep across all 48 owner/widget/admin screens
Design/UX/technical audit (accessibility, performance, theming, responsive,
anti-patterns; scored 0-4 per dimension, findings tagged P0-P3) run one batch of
6 screens per `/loop` iteration, then the component layer. Deliberately skips the
`ref`/`setState`-after-`await` + raw-`e.toString()` classes already catalogued in
`audit/flutter-patterns-screen-review-2026-07-18.md`. Ledger:
`audit/full-screen-sweep-2026-07-18/FINDINGS.md`; progress in `PROGRESS.md`;
final `SUMMARY.md` on completion. Read-only — no source touched.

**Systemic patterns (recurring ≥5 screens):** `BbInput` exposes no
`textInputAction`/`focusNode`/`autofillHints` → every form screen lacks a
keyboard-submit chain and password-manager autofill (one widget fix closes
login/register/forgot/bank/change-password/property-form); `BbChip` lacks
`Semantics(selected:)`; premium headers hardcode HR eyebrow/title/subtitle;
`Colors.white`-for-on-primary everywhere (`BBColorSet.onPrimary` token gap);
EN-only validators (`profile_validators`/`password_validator`); legal-cluster FAB
missing `semanticLabel` + `BbSectionHeader` missing `header:true`; breakpoint
drift (1024/1440/900/800/700/1100 vs canonical 1200); custom-tappable/icon-only/
decorative widgets without `Semantics`/`ExcludeSemantics`;
`ThemeData`/`BackdropFilter`/`Opacity` built in `build()` without
`RepaintBoundary`; `textTertiary` (light `#718096` on `#FFF`) +
`BbAdminDarkTokens.textTertiary` (`0x66FFFFFF` on `#2A2342`) fail WCAG AA;
**flat-chrome regression** — `profile_screen` applies `rd.heroGradient` to
structural chrome ×4 and `profile_image_picker` a diagonal gradient (both retired
2026-06-16); `property_form` uses zero BB* tokens.

**Notable single findings:** P0 — `owner_booking_detail` `_RoundIconButton.onPressed`
declared + passed but never wired to an `InkWell` → mail/call buttons are dead
taps. Lowest-scoring screens: `month_calendar` / `activity_log` /
`stripe_connect_setup` (10/20).

---

**Changelog 7.45** (2026-07-18) — CI was red two independent ways, both masked:

### P1 fix(ci): regenerate functions lockfile so `npm ci` stops failing on linux (#958)
Every PR — **including doc-only ones** — failed `Validate Firestore Rules` and
`Test Cloud Functions` at the install step with
`Missing: @emnapi/core@1.11.2 from lock file`.
The lock nested `@emnapi/{core,runtime,wasi-threads}` under
`@unrs/resolver-binding-wasm32-wasi`, an **optional platform dep that never
installs on darwin** — so that subtree was recorded but never reconciled against
a real install. Linux hoists those to top level, computes a different ideal tree
than the lock describes, and refuses. Fixed by a full regen
(`rm package-lock.json && npm install --package-lock-only`); `package.json`
untouched, so no dependency version moved. All jobs green on the fix PR,
including the two that had been failing.
**The move that localized it:** #956 was doc-only and failed the same step. A
CHANGELOG-only diff cannot break `npm ci` — that one observation ruled out every
diff under review. **Darwin cannot reproduce this**: both
`npm install --package-lock-only` and `--os=linux --cpu=x64` produce a zero-line
diff against the broken lock, so they are not diagnostics here. Only CI could
verify, and the PR was landed as a candidate rather than as an asserted fix.

### P1 chore(widget): drop the two imports #953 left behind (#955)
CI runs `flutter analyze --no-fatal-infos` — **warnings are still fatal**. #953
moved the calendar's availability-error copy into `availability_error_l10n.dart`,
removing the last `WidgetConstants` reference from `month_calendar_widget` and
`year_calendar_widget`; the imports stayed. Main had been analyze-red since,
**masked because the next PR (#954) was doc-only and the paths filter skipped the
Flutter job entirely** — a green main run does not mean the job ran. Proof of
causation: after this merged, `Run Tests` flipped FAILURE→SUCCESS on two open PRs
with no other change.

### test(rules): let the emulator suite find its own port (#957)
Every file in `functions/test/firestore_rules/` pinned
`host: "127.0.0.1", port: 8080` alongside the port already in `firebase.json`.
When anything else holds 8080 the suite fails **227 cells** with
`TypeError: Cannot read properties of undefined (reading 'cleanup')` —
`initializeTestEnvironment` throws, `testEnv` stays undefined, every `afterAll`
dies on it. It reads exactly like a catastrophic rules regression and is a setup
failure. Dangerous signal for the security gate. Deleting the two lines lets the
SDK fall back to `FIRESTORE_EMULATOR_HOST`, which `emulators:exec` already
exports; the port now lives in one place. **28 lines deleted, nothing added.**
Verified on a NON-default port (8099, since 8080 was occupied by an unrelated
process): 16/16 suites, 245 passed, 6 skipped — where the old pins gave 14 suites
red.

### docs: the "3 red cells on main" note was fixed two PRs later (#956)
`CLAUDE.md` (runda 22) and CHANGELOG 7.43 both still warned that
`bookings_premium_kpi_count_test.dart` fails 3 cells on clean main and is "not
yet diagnosed". It was repaired by **#945**, which landed after the note was
written. Re-verified green before editing: the file alone 3/3, full suite
1945/1945.

### Suite state at `1a65b20f`
Flutter **1945/1945** · functions jest **508/508** (29 suites) · Firestore rules
**245/251** (6 pre-existing skips) · `flutter analyze` **0 errors, 0 warnings**.

### Ops note
The lockfile regen first died on `npm error nospc` — disk was at **127 MiB free,
100% full**. Reclaimed ~4.7 GiB of pure caches (npm cache, Xcode DerivedData,
Cursor/Chrome updater staging). **Simulators and `~/.gradle/caches` deliberately
untouched** — two sims were booted by parallel sessions, and Gradle re-download
is a real cost. Disk remains tight at ~1.8 GiB.

**Changelog 7.44** (2026-07-17) — autonomous bug-hunt loop, 6 iterations:

### P2 fix(a11y): dark tertiary text fell under WCAG AA after the audit/127 ladder (#951)
audit/127 widened the dark ladder (#0B0B0D→#141414, cards #1E1E1E, variant
#2A2A2A) so panels would lift off the shell — deliberate and correct. But the
TEXT tiers were never re-measured against the newly LIGHTER surfaces, and
`textTertiaryDark` (#718096) silently dropped to **4.15:1 on #1E1E1E** (BbCard's
fill via `c.surface`) and **3.57:1 on #2A2A2A**, under the 4.5:1 floor for the
12px/w400 captions that use it (live pairing: `notification_settings_screen`).
`#718096` → `#8592A5`: the **minimum** lift along the same slate hue that clears
4.5:1 on the lightest surface tertiary lands on. A computed constraint minimum,
not a design opinion — trivially revertible. `#333333` excluded on purpose
(buttonPrimaryHover + a shadow tier, not a text backdrop); light mode untouched.
The test guards the **relationship** — every text tier × every dark surface — so
lightening a surface again fails by name, plus a cell pinning tertiary stays
dimmer than secondary. **20 dark goldens regenerated, ZERO light** — exactly as
narrow as intended.

### P2 fix(auth): #933 fixed the login guard and missed its registration twin (#952)
`checkCloudRegistrationRateLimit` is the exact twin of the login guard #933
fixed — same file, **two methods below it**, same documented "fail-open for
availability" catch, no `.timeout()`. So the fail-open was dead code and a hung
callable hung registration. `_kAuthGuardTimeout` was already in that file,
added by #933 and never applied here. Mirrors the login twin including the
explicit `on TimeoutException` branch (the catch is typed to
`FirebaseFunctionsException`; a bare `.timeout()` would escape it and show an
error instead of failing open).
Also `sendPasswordResetEmail`: unbounded, while `forgot_password_screen` clears
`_isLoading` only in its try/catch — a hang means a permanent spinner **on the
path taken by someone who already cannot log in**. Bounded via the repo's
existing `withCloudFunctionTimeout`.
Test is a source scan deliberately: both methods build their own
`FirebaseFunctions.instanceFor(...)` inline and the register harness overrides
the method to a no-op, so no test can drive the real callable without
refactoring the auth path. **Class now converged** — the sharp-shape grep
returns only #933's own fix.

### P1 fix(widget): the calendar knew WHY dates failed and said "booked" (#953)
The checker already reports the reason (`errorCode` + `conflictDate` /
`icalSource`) and `widget_translations.dart` already carries a parameterised
string for EVERY code, in all 4 languages — all with **zero consumers**. Both
calendars collapsed every outcome into the generic "already booked".
Not cosmetic: *"Dolazak nije moguć na datum 20. kol"* tells a guest to **shift
one day**; *"Već rezervirano"* tells them to **give up** — on dates the owner
would happily sell. Wrong action, lost booking.
#935 wired ONE code (`checkError`) and left five dormant. New
`availability_error_l10n.dart` maps every code, consuming detail the result
already carries; degrades to the generic line when a code arrives without its
detail. RED→GREEN: 5 of 10 cells fail against the #935-era partial mapping.

### chore(brain): rebuild .brain index for the 7.43 docs (#950)
The index predated the 7.43 doc merges, so those sections weren't retrievable.
⚠ `brain-index.json` is **git-tracked** — rebuilding in the shared checkout
dirties the tree and blocks the next ff-merge. Rebuild via worktree + PR.

### Verified clean — 0 findings (do NOT re-audit without new evidence)
- **Stripe webhook** — read end to end. Two hypotheses killed firsthand: dedup
  does NOT lose events on retry (every handler that can 500 carries a
  compensating `eventRef.delete()`), and a failed placeholder cleanup does NOT
  leak blocked dates (`stripe_pending_expires_at` makes it inert and BOTH
  readers honour it). Only finding is P4: `handleCheckoutSessionExpired` reports
  `placeholder_cleaned` even when the delete failed — Stripe ignores the body.
  **Dev Stripe live-testing is BLOCKED** on three operator-owned fronts (no
  Stripe config on any dev unit; Connect fixture stuck at hCaptcha F-70-02 —
  audit/70 proved both CDP *and* a human fail; MCP unauthenticated).
- **Notifications** — bell count is a server-side stream (audit/141).
  **F-T3-01 re-verified and CLOSED** after 39 days as a false open: the silent
  dismissal now surfaces a snackbar on BOTH paths, and the "3× retry" was screen
  re-entry (now four guards), not a retry — `_findBookingById` is a 2-strategy
  fallback chain run once. Quiet-hours is sound AND wired (`fcmService:105` →
  `shouldSendPushNotification` → `isQuietNow`), midnight-wrap correct, 12/12.
- **`.take(n)` as a count** (#924 class) — all 6 sites clean. `smart_booking_tooltip`
  and `booking_action_menu` both carry an honest `tooltipMoreConflicts(length-3)`;
  calendar dots are decoration (the tap-through agenda is the truth path).
- **`orderBy` as a silent filter** (#889 class) — all 9 fields checked against
  model nullability AND PROD data. `daily_prices`: **2587/2587 carry a valid
  `date` Timestamp**. Re-confirms that `icalExport.ts:254`'s `orderBy("check_in")`
  is the mechanism excluding the 4 string-date bookings — still no live impact.
- **Latent, measured not guessed**: notifications list is `.limit(100)` while the
  unread count is unlimited — but **PROD max is 83, nobody over 100**, and
  `markAllAsRead` queries all unread so the badge always clears. Re-check when an
  owner crosses 100.

**Lesson (three instances in one campaign): a fix does not close its class.**
#948 fixed the single-status path and left the "Sve" tab; #952 fixed login and
left registration two methods below it; #953 wired 1 of 6 error codes. Every one
was caught by **running the grep, not trusting memory** — and #948 additionally
by checking the fix sat on the path that actually executes
(`PaginatedBookingsNotifier` had zero consumers).

---

**Changelog 7.43** (2026-07-16):

### fix(owner): #946 was half a fix — the live notifier and "Sve" tab (#948)
Found by actually running the grep #946's own memory prescribes (`hasMore:
false` + a client-side filter above it) instead of assuming one fix closed the
class. It didn't:
- **The provider half of #946 went into dead code.**
  `PaginatedBookingsNotifier` has **zero consumers** — `owner_bookings_screen`
  drives `WindowedBookingsNotifier`. #946's repository half is shared and did
  help; its paging loop did nothing.
- **The "Sve" tab — the DEFAULT view — has its own copy of the bug.**
  `_getOwnerBookingsPaginatedAllStatuses` computes `hasMore` from the raw doc
  counts and then discards it on `if (allBookings.isEmpty)`. The single-status
  twin was fixed and the most-used tab left dead-ending.
Now treated on the paths that actually run: the AllStatuses method returns the
cursor it already computed; `WindowedBookingsNotifier.loadMoreBottom` trusts the
repository's `hasMore` instead of forcing `hasMoreBottom: false` on an empty
page; `loadFirstPage` gets the bounded `_fillEmptyFilteredWindow`. The loop
lives only in `loadFirstPage` — it drives `loadMoreBottom`, so calling it there
recurses (the same mistake #946 caught in review).
RED→GREEN: the new "Sve" cell fails against the unfixed repository.
owner_dashboard 269/269.
**Lesson recorded** in `client-filter-over-paginated-page.md`: before declaring
a bug class closed, run the grep — and check the fix sits on the path that
actually executes (`grep -rn "<Notifier>" lib/`; zero consumers = dead code).

### P1 fix(owner): filtering bookings by property could dead-end on "no bookings" (#946)
Found by hunting #939's pattern elsewhere. Property and date filters run
CLIENT-SIDE over each 20-row page — Firestore cannot express them beside
`orderBy('created_at')` (an inequality must match the first orderBy), so that
part is a real constraint, not laziness. The bug was the answer when a page
filtered to nothing:
`if (bookings.isEmpty) return PaginatedBookingsResult(bookings: [], hasMore: false);`
A page where every row failed the filter says NOTHING about later pages — this
threw the live cursor away and declared the set finished. An owner with two
properties, filtering by the one whose bookings sit past row 20, saw **"no
bookings" for a property that has them**. Worse than #939: that one hid the
Load-more button; this one lied about `hasMore`, stopping infinite scroll dead.
**Two halves, either alone insufficient:** the repository hands back the real
cursor, and the provider's `_fillEmptyFilteredPage` keeps paging while the list
is empty and the cursor is live — paging is scroll-driven and an empty list
cannot be scrolled, so nothing would ever ask for page 2. Bounded at 5 fetches.
⚠ The loop lives only in the provider; an early draft also called it from
`loadMore()`, which drives it — that recursed.
Owner's **status** filter is server-side (`:248`) and was always correct.
RED→GREEN against the real repository via `fake_cloud_firestore`.
owner_dashboard 268/268. Memory: `client-filter-over-paginated-page.md`.

### Stripe webhook reviewed — sound, zero findings
`handleStripeWebhook` read end to end; **no bugs**. Two hypotheses killed
firsthand: (1) *dedup loses events on retry* — no, every handler that can 500
carries a compensating `eventRef.delete()`, so Stripe's retry re-processes;
(2) *a failed placeholder cleanup leaks blocked dates* — no,
`stripe_pending_expires_at` makes the placeholder inert and BOTH readers honour
it (`createStripeCheckoutSession:588`, `availability.ts:227`). Only finding is
P4: `handleCheckoutSessionExpired` reports `status: "placeholder_cleaned"` even
when the delete failed — harmless, Stripe ignores the body.
**Dev Stripe live-testing is BLOCKED** on three fronts, all needing the
operator: no Stripe config on any dev unit, the Connect fixture
`acct_1Tc037PnKJAl9q6s` is stuck at hCaptcha (F-70-02 — audit/70 proved both
CDP *and* a real human in a normal browser are defeated), and the Stripe MCP is
unauthenticated. Don't re-attempt. Memory:
`stripe-webhook-review-2026-07-16.md`.

### fix(owner): in-stay bookings offered the owner no action at all (#942)
A guest **currently staying** fell through both lifecycle gates —
`complete` required `isPast`, `cancel` required `isUpcoming` (via
`canBeCancelled`) — so from check-in day to check-out there was no
early-departure and no no-show path, only Poruka/Uredi.
`detailActionVisibility`'s own docstring claimed it *"guarantees no confirmed
booking is ever action-stranded (past → complete, upcoming → cancel)"*, quietly
excluding the in-stay window it never named. Both bounds now hinge on the
stay's own edges: `complete: confirmed && !isUpcoming` (the stay has STARTED),
`cancel: status.canBeCancelled && !isPast` (the stay has NOT FINISHED).
Upcoming/past behaviour unchanged.
**Reverses a deliberate pin, on an explicit operator decision.** The old cell
asserted "neither complete nor cancel" mid-stay, reasoning *"not stranded:
Poruka + Uredi remain available"* — a reading of "stranded" meaning
actions-exist rather than lifecycle-actions-exist. Cell kept and inverted, plus
a check-in-today boundary cell for the moment the old gate flipped shut.
RED→GREEN: 3 cells fail without the change.

### fix(auth): password errors English-only, and the ARB stated the wrong rule (#943)
`PasswordValidator` is a static utility with no `BuildContext`, so it returned
English prose — a Croatian owner read "One uppercase letter" on register/login/
change-password (the requirement list renders straight from it). And the string
meant for this stated the wrong rule: `passwordTooShort` claimed "at least **6**
characters" in both ARBs while `minLength = 8`. Dormant (zero consumers) so it
misled nobody yet — same dormant-string class as #935/#937.
Fixed in the shape those landed on: **the validator returns codes, the screen
translates.** New `password_error_l10n.dart` maps `PasswordError` →
`AppLocalizations`, with a checklist variant so `tooShort` reads "At least 8
characters" in the strength meter and a full sentence as a field error.
⚠ **The legacy `String?` API stays English on purpose** —
`enhanced_auth_email.dart:327` does `throw passwordError` on a non-UI path; an
early draft returning `code.name` there would have thrown **"tooShort"** at the
user. Caught pre-merge; `_englishFor` keeps that path a sentence. SF-006
sequential/repeating guards and the common-password blacklist untouched.
+11/-1 per ARB (a JSON round-trip reformatted all 780 lines — reverted, patched
surgically). core + l10n + auth suites 339/339.

### ~~Known: 3 red cells on main (pre-existing)~~ — CLOSED by #945
`bookings_premium_kpi_count_test.dart` failed 3 cells on clean `origin/main`
(mobile 2-KPI, tablet/desktop 4-KPI, narrow-width overflow), red since #924.
**Repaired by #945 (`a2a43910`), which landed after this note was written.**
Re-verified green 2026-07-18: the file alone is 3/3 and the full suite is
1945/1945.

### P1 fix(admin): Users list stranded owners behind an active filter (#939)
Filtering/search is **client-side** over the rows loaded so far (20/page), while
the status-tab badges are **real server-side `.count()` aggregates** over the
whole collection. So `showLoadMore = hasMore && !_hasActiveFilters` hid the ONLY
control that pulls further pages exactly when it was needed — and
`if (filtered.isEmpty) return const _EmptyState()` early-returned before the
flag was even consulted. Live on dev: tab **"Suspended 1"** → **"No users
found"**, no Load-more anywhere in the a11y tree. The badge told the truth; the
rows were partial. Same class as #924, inverted.
Fixed, plus an honest empty state: "No matches in the loaded users" + a
Load-more action instead of a flat "No users found".
**Review note:** the fix originally shipped behind
`shouldShowLoadMore({hasMore, hasActiveFilters}) => hasMore` — a predicate
ignoring half its inputs, i.e. `identity()` behind a named seam, with 4 test
cells proving that identity returns its input. Its own PR notes recorded that
seam going green *while the screen still dead-ended*
(`seam-test-proves-fn-not-wiring`) — the evidence it earned nothing. Inlined to
`notifier.hasMore` with the WHY comment at the call site; kept the `_EmptyState`
widget test, which does bite (reverting the pre-fix body fails it). +180 → +129.

### docs: admin.md claimed no DEV entry point exists — it does (#940)
`.claude/rules/admin.md` said *"No DEV entry point exists — DEV admin reuses the
PROD entrypoint with the dev Firebase config"*. Both halves wrong:
`lib/admin_main_dev.dart` exists, sets `Environment.development`, and carries a
`kDebugMode` project-ID assert. **Actively dangerous, not merely stale** —
following it points admin at `rab-booking-248fc` and skips the assert that
exists to catch exactly that. Same doc-drift class as #931.

### Admin dashboard tile gap — dev-data artifact, NOT a live bug (P3, no fix)
An agent reported "Total 31 vs 29+0+0 — 2 owners in no tile", which reads
alarming. It was measuring **its own seeded dev users**. Verified firsthand:
**PROD is clean — 23 owners, every one with a valid `accountType`, tiles sum to
exactly 23, zero unaccounted.** Dev shows 6 owners / tiles=4 only because the
dev DB holds seed garbage: one doc with no `accountType`, one with
`accountType: 'active'` (a *status* value mistaken for a type). The reported
cause (`enterprise` uncounted) is also wrong — `enterprise` is "Business tier
(future use)" and **nothing writes it**; it exists only in the enum and the
badge switch. So: theoretical fragility, no live impact, no fix.
`user_model.dart:28-45` fail-open unknown→`trial` is deliberate and
security-correct (lowest tier).
Verified sound: every admin repository count is a real `.count()` aggregate, not
a `.take(n)` preview — no #924 on the dashboard; `setLifetimeLicense` writes
`accountType:'lifetime'`, matching its tile.

### fix(widget): guest-cancel snackbar showed the server's English to every locale (#937)
`guestCancelBooking` returns an English-only `message` — it serves logs and API
clients. The /view screen echoed it verbatim:
`message: data['message'] ?? tr.bookingCancelledSuccessfully`. Since
`data['message']` is always present, the `??` fallback **never fired** and
`bookingCancelledSuccessfully` — translated into all 4 widget languages, a near
word-for-word match of the CF's English — was dead. A Croatian guest cancelling
from /view read *"Booking cancelled successfully. You will receive a
confirmation email shortly."*
Same on the rejection path, where the fallback was actively worse
(`failedToCancelBooking('cancellation_disabled')` would leak a raw enum), so a
proper `errorGuestCancelDisabled` string was added in all 4 languages.
The CF already returns a machine-readable `reason` — that is what the client
localizes off now. **Same shape as #935: the server sends a code AND prose; the
client's job is to translate the code, not display the prose.** Server
untouched — the English `message` is still right for logs/API.
RED→GREEN seam test · widget + l10n suites 804/804. Widget deploy needed.

### Sweep: guest-facing messages that lie or leak (converged)
#935 was the 4th instance of this family (#904 raw exception to guest, #901
message pointing at a nonexistent feature, #874 error leak), so the class got a
deliberate sweep. It found **one** more — #937 — and cleared the rest:
- `ical_sync_settings_screen.dart:901/1611` — **not the same bug**: the success
  path already localizes via `l10n.icalSyncSuccess()`; the error path surfaces
  the server's diagnostic ("URL must have a hostname") to a technical owner,
  which is defensible.
- `admin_users_repository.dart:220/287` — internal console, `'Status updated'`
  is fine.
Sweep considered closed for guest-facing surfaces.

### P1 fix(widget): "already booked" shown when the availability check FAILS (#935)
The availability check fails **closed** when `getUnitAvailability` is
unreachable — correct, we must never let a booking through over a window we
couldn't verify. But the guest was told *"Cannot select dates. There are already
booked dates in this range."* That is a **lie about free dates**: the guest sees
a fully available unit as fully booked and walks away.
**Not hypothetical** — during the 2026-07-13 index-drift outage
`getUnitAvailability` returned INTERNAL on every call; every guest picking dates
that day would have been told the property was booked.
The fix was **already 90% written and never wired**: `AvailabilityErrorCode
.checkError` existed with zero consumers, `AvailabilityCheckResult.error()` set
it correctly, `errorAvailabilityCheck` was translated into all 4 languages and
never shown, and `checkAvailabilityDetailed()` had zero callers because it was
missing from `IBookingCalendarRepository` — unreachable from the provider layer.
The class docstring literally says "The UI layer maps error codes to localized
messages." This finishes that wiring rather than adding anything new.
Untouched: the local `_hasBlockedDatesInRange` path keeps the "already booked"
message — there the claim is TRUE (it read real blocked data).
Seam test: a throwing availability repo must yield `checkError`, never
`bookingConflict`. analyze 0 errors · widget suite 793/793. Widget deploy needed.
**Lesson:** dormant infrastructure (a translated string with no consumer, an
error code with no reader, a method absent from its interface) is *unfinished
wiring*, not dead code — find what the author intended before adding new.

### Dev-first workflow (operator directive, 2026-07-16)
Test on `bookbed-dev` **first**, PROD second. Runda 19 was the first dev-first
round and immediately surfaced #935.
⚠ A locally-served build (`python3 -m http.server`) pointed at the **deployed**
dev CF is CORS-blocked by design: `corsAllowlist.ts` pushes `LOCAL_DEV_ORIGINS`
(localhost:5000/5001/8080) **only when `isEmulator`**. Use the emulator, or
deploy to `bookbed-widget-dev.web.app` (allowlisted). Memory:
`dev-first-then-prod.md`.

### P1 fix(auth): login hangs forever when a pre-sign-in guard stalls (#933)
Found during PROD booking-detail testing: a profile holding a stale session
showed a permanent "Učitavanje…" overlay with disabled buttons and **zero**
`identitytoolkit` requests — the login never even attempted. Three awaits had no
timeout (`enhanced_auth_email.dart:31` checkLoginRateLimit, `rate_limit_service
.dart:120` getLoginLockoutStatus, `enhanced_auth_email.dart:54` setPersistence),
all feeding a `Future.wait` that `_handleLogin` awaits unguarded.
**The point:** both call sites already *documented* a "fail-open" intent and
carried a catch to implement it — but a catch only fires on a **throw**. Against
a call that never returns, the fail-open was **dead code**. Same class as #909
(CSP-blocked App Check token held sign-in forever). Fix = 5s ceiling per guard,
each failing open into its existing path. `checkLoginRateLimit` needed an
explicit `on TimeoutException` branch — its catch is typed to
`FirebaseFunctionsException`, so a bare `.timeout()` would have escaped to the
outer handler and shown the user an error instead of failing open.
Not a security regression: the throw-path already failed open, the guards are
advisory (Firebase Auth enforces server-side), and an attacker controls their own
client anyway. RED→GREEN seam test; `test/core` 308/308.
Memory: `fail-open-catch-is-dead-against-hang.md`.

### Owner booking-detail screen — verified clean (runda 18)
Cancel-confirmed full loop works (reason dialog + guest-email checkbox →
`cancelled`/`cancellation_reason`/`cancelled_by=owner` persisted, action row
collapses, activity timeline logs). `_TabletGrid` 2-col at 768 no overflow;
desktop 1440 clean; 60-char guest name ellipsizes (audit/128 robustness holds).
Note there is no `rejected` status — reject maps to `cancelled` +
`rejection_reason`.

### Findings left unfixed (runda 18)
- **P2 bookings without `booking_reference` render the raw Firestore ID**
  (`Rezervacija #9lLWi9fr…` instead of `#BK-…`) — hits manual/`source:admin`
  bookings; the CF auto-heals a missing ref but only on the CF path.
- **P2 "Premjesti" is not on the booking-detail screen** — reachable only via
  long-press on the Timeline calendar (`timeline_calendar_widget.dart:1586`), an
  invisible affordance, effectively undiscoverable on desktop web.
- **P3 `password_validator.dart` has 10 hardcoded English strings** in a Croatian
  UI. l10n keys already exist (`passwordRequired` = "Molimo unesite lozinku") but
  `passwordTooShort` says "6 characters" while the validator enforces a different
  length → needs intent + threading context through 7 call sites of a static
  utility. Refactor, not a quick win.
- **Cancel gate excludes in-stay guests** — `canBeCancelled = confirmed &&
  isUpcoming` with strict `checkIn.isAfter(today)`, and `complete` needs `isPast`
  (`booking_model.dart:184-194`), so a currently-staying guest gets neither → no
  path for early departure / no-show. Needs intent.
- **PROD data, not code:** both cover photos on unit `Rab apartman 1` (gMIO) are
  developer screenshots from Dec 2025 (same session as the string-date fossils);
  one shows a red Stripe `FAILED_PRECONDITION` banner, the dev console, and the
  operator's own test email + phone in the form. The Storage URL serves HTTP 200
  with no auth. It is the operator's own test account on their own test property
  — not a customer listing. Deletion left to the operator.

### fix: reject email now carries a "Pregledaj rezervaciju" link (#929)
Operator gave the intent on a P3 open since runda 13: a rejected guest received
an email with **zero links** — no way to view the booking they had just been
refused. Same class as #905 (pending email had the same hole). The rejection
branch of `onBookingStatusChange` now generates a fresh access token before
sending (the plaintext token only exists at generation time), and
`sendBookingRejectedEmail` accepts `accessToken` + `propertyId`, building the URL
through the existing `generateViewBookingUrl` path. Approve rotates the token by
design; reject did not, so a fresh one is minted here.
⚠ Trap: `safeToDate` throws on `check_out: undefined`, which silently killed the
email before it sent (2 existing bookingManagement cells failed with
"Number of calls: 0") — guarded with a 1-year fallback expiry.
4-cell `rejectedEmailViewLink.test.ts`; jest 507/507. CF deploy required.

### fix(widget): guest picker capped at max_guests instead of max_total_capacity (#929)
Operator intent resolved a runda-12 product question: **`max_guests` is standard
occupancy, not a hard limit.** The widget capped guests at `max_guests` (W55g=4)
while the unit and server accept `max_total_capacity` (=6) — guests of 5-6 could
not book at all through the widget (lost bookings). One-liner: pass
`maxTotalCapacity` to `GuestCountPicker`, which already had
`maxTotalCapacity ?? maxGuests` wired internally but was never fed it. The
extra-bed fee threshold stays at `max_guests` (that's what standard occupancy
means). Widget deploy required.

### fix(ical): import sync never invalidated the export cache (#930)
An iCal import sync creates and deletes availability blocks but never flushed the
export cache — the feed kept serving the pre-sync snapshot for the full 300s TTL.
`invalidateIcalCache` was already wired into both booking paths (atomicBooking
create, bookingManagement status change) but had **zero call sites in
`icalSync.ts`**. One call in `syncSingleFeed` after the metadata update closes it.
This was deferred in 2026-05 on the reasoning "OTAs poll ≥15min so the lag is
invisible" — true for OTAs, but not for the **owner**, who syncs and immediately
opens the export URL to check. Confirmed live on PROD.
RED→GREEN seam test (fails without the src change); jest 508/508. CF deploy required.

### docs: syncIcalFeedNow region drift — an active trap (#931)
`.claude/rules/cloud-functions.md` listed `syncIcalFeedNow` under eu-west1. It is
**us-central1** (`gcloud describe` on eu-west1 → 404). Its scheduled twin
`scheduledIcalSync` *is* eu-west1, which is where the confusion came from. The
Dart client calls it via `FirebaseFunctions.instance` (us-central1) and works —
anyone "fixing" the client to match the doc would have broken a working call.
All 16 functions in the list re-verified against PROD; the other 15 are correct.

### Findings left unfixed (deliberate, runda 17)
- **4/57 PROD bookings store `check_in` as an ISO string, not a Timestamp** — the
  export's range filter never matches them (Firestore orders by type), so 3
  confirmed bookings are invisible to the feed. Root cause is already **closed**
  (today's `createBookingAtomic` normalizes via `validateAndConvertBookingDates`;
  no Dart string-write path exists). All 4 are Dec-2025 `source=widget` fossils
  predating the #578 direct-write sweep, all Jan 2026 = outside the 90-day export
  window → **no live impact**. Backfill is optional hygiene, needs GO.
- **Export token cannot be rotated or revoked** (P2 security, feature-sized): the
  URL gets pasted into Airbnb/Booking/Google Calendar, is generate-once, and has
  no regenerate UI — a leak means permanent occupancy read access; the only
  recourse is disabling `ical_export_enabled`, which kills every channel at once.
- Double-`@` UID on re-exported imported events (RFC 5545 tolerates it, P3);
  in-memory per-instance export rate limit; orphan `ical_events` reachable because
  `deleteIcalFeed` cascades client-side.

---

**Changelog 7.42** (2026-07-14):

### P1: owner's require-email-verification was client-only — server enforcement (#923, PROD)
`require_email_verification` gated only the widget form's Send button;
`createBookingAtomic` never checked it (it loaded `widget_settings` for
stripe/bank/ical/mode, not `email_config`). A direct callable to a verif-ON unit
with a never-verified email booked successfully — same client-only-guard class as
#903 (advance window) and #906 (max-stay). New pure `emailVerificationGuard.ts`
(`hashEmailForVerification` byte-identical to `emailVerification.ts` hashEmail;
`isEmailVerificationValid` mirrors `checkEmailVerificationStatus` =
verified && ≤expiresAt) + guard in atomicBooking STEP 1.5 after widget_settings
load: reads `email_verifications/{sha256(email)}`, rejects `failed-precondition`
if not verified/fresh. 11-cell test; functions jest 503/503. Live 3-way:
unverified verif-ON unit → REJECT, verif-OFF unit → SUCCESS (no regression),
seeded-verified → SUCCESS. `email_verifications` rules stay `read/write:if false`.
FROZEN 2-doc write untouched. Memory: `widget-full-e2e-2026-07-13.md` (runda 14).

### fix(owner): "Na čekanju" KPI tile hard-capped at 4 pending (#924, PROD)
The Rezervacije "Na čekanju" tile read `pendingPreview.length`, but
`_pendingPreviews()` ends `.take(4)` (a priority-queue preview, not a count) — an
owner with 5+ pending saw "4", silently plateaued. `rezervacijeKpiProvider` now
counts ALL pending (`collectionGroup owner_id + status==pending`, unit-filtered,
no date-window since pending needs action regardless of date; small sets → cheap
filtered get()); tile shows `kpi.pendingTotal`, falling back to preview-length
(≤4) only while the aggregate loads (never flashes 0). Priority-queue cards + AI
nudge keep `.take(4)`. `RezKpi.pendingTotal` through computeRezKpi, +2 test cells
(8/8), analyze clean, query live-verified (no new composite index). Live wiring
proof: seeded 5 pending → real login → tile "NA ČEKANJU 5" (was 4). Memory:
`widget-full-e2e-2026-07-13.md` (runda 16).

---

**Changelog 7.41** (2026-07-13):

### P0: owner/admin web email-password login hung forever — web App Check skip (#909, PROD)
On `app.bookbed.io`, entering email+password and pressing Prijava showed
"Učitavanje…" forever — `signInWithEmailAndPassword` never reached the network.
`AppCheckInit.activate` on web used `ReCaptchaV3Provider('placeholder-debug-only')`;
the reCAPTCHA script is CSP-blocked (no `www.google.com` in script-src), the App
Check token never mints, and the Auth SDK holds the sign-in waiting for it.
Isolation proof: `FIREBASE_APPCHECK_DEBUG_TOKEN=true` (debug provider, no
reCAPTCHA) let the same login complete. App Check is enforced on NO callable +
Firestore/Storage App Check off → placeholder web token protected nothing.
`AppCheckInit` now SKIPS web activation when no real `APP_CHECK_RECAPTCHA_KEY`
is set; mobile (Play Integrity / DeviceCheck) untouched. Owner+admin web
redeployed; verified live end-to-end: real login lands on `/owner/overview` with
no debug token. To enable web App Check later: real key + CSP allow + enforcement
TOGETHER (Option B). Memory: `owner-login-appcheck-hang-2026-07-13.md`.

### PROD outage: getUnitAvailability INTERNAL globally — Firestore index drift (same day)
Live Firestore was missing composite indexes present in `firestore.indexes.json`
(`bookings (unit_id,status,check_out)` collectionGroup + `ical_events
(unit_id,end_date)`), likely sync-deleted by a stale parallel-session
`deploy --only firestore:indexes`. FAILED_PRECONDITION was re-wrapped by the CF
catch as INTERNAL, hiding the cause; unmasked by running the raw query via admin
SDK in Node. Fix: redeploy indexes from source. NOT a code bug (revert proved it).
Memory: `firestore-index-drift-outage-2026-07-13.md`.

### fix(widget): /view header language selector — globe + code instead of raw flag emoji (#910, PROD)
The My Booking header language button was a bare 🇬🇧 flag emoji — degrades to
"GB" fallback letters on platforms without flag-emoji fonts (Windows Chrome), no
dropdown affordance, inconsistent with the calendar toolbar. Now `Icons.language`
+ uppercase code + caret (same handoff pattern as `calendar_combined_header_widget`);
language dialog unchanged. Live-verified desktop+mobile (SW-cache purge needed to
see it on previously-visited browsers).

### fix(owner): Rezervacije KPI strip lied — honest month/7-day windows (#911, PROD)
"Potvrđeno (mj.)"/"Zarada (mj.)" were fed by UnifiedDashboardNotifier whose window
is the Pregled preset (default LAST 7 days, backward-looking on check_in) — a
booking confirmed today with a check-in later this month read 0/€0; "Nadolazeći —
sljedećih 7 dana" was actually a 14-day query incl. pending. New
`rezervacije_kpi_provider` computes exactly the labeled windows (calendar month
for confirmed|completed count+revenue; [now,+7d) for confirmed|pending upcoming),
invalidated after Odobri/Odbij; pure `computeRezKpi` + 6-cell test. Live: 1/€750/1
where the old strip showed 0/€0/2. Sparklines remain dashboard trend data.

### E2E runda 13 — full owner flow through the REAL UI (first time, post-#909)
Widget booking (chrome-devtools a11y click/type) → pending email with view button
(#905 ✓) → real owner UI login → Odobri → confirmed + approval email (token
rotates) → email button → /view Confirmed → widget calendar half-day
check-in/out cells; second booking proved TURNOVER through the UI (check-in on
another guest's check-out day); Odbij → cancelled → /view Cancelled (pending
token still valid — reject doesn't rotate) → calendar freed. Reported, not fixed:
rejected email has NO links (class of #905, P3 product call); `createBookingAtomic`
returns "Booking confirmed." message for PENDING bookings; "Na čekanju" tile counts
from the paginated windowed list (undercount past 20 pending). Test bookings
deleted from PROD.

---

**Changelog 7.40** (2026-07-10):

### Admin Users status TAB-COUNTS — data-honest omit built end-to-end (audit/admin-users-tabcounts)
The handoff `admin-users.jsx` `AU_TABS` status tabs (All / Active / Trial /
Suspended) with live count badges were omitted by #860/#864 (needed aggregation).
Now real, DEV-ONLY (bookbed-dev), no PROD, no callable/rules change:
- **Counts:** new `AdminUsersRepository.getStatusCounts()` — 5 Firestore `.count()`
  aggregates (same proven pattern as `getDashboardStats`) over the whole `users`
  collection, NOT a partial page count; a failed query drops its key (no fabricated
  0). New `ownerStatusCountsProvider`.
- **Model:** `UserModel.accountStatus` (`String?`, raw — no enum coercion) added so
  the loaded list can filter by lifecycle status; regenerated freezed/g (one field).
- **UI:** `_StatusTabs` row above the search input (BbChip `tab` variant + count
  badge, dark console tokens), single-select nav tab (default All) wired into the
  existing filter/clear state. `trial_expired` folds into the Trial tab (badge sums
  both, filter matches both). Preserves #860 pagination/cards, #862 search, #864
  master-detail, #765 overflow.
- **Verify:** analyze 0; new `users_list_status_tabs_test` 12 cells; admin suite 33
  green; full `flutter test` +1769 green; seam-golden eyeball renders All 248 /
  Active 210 / Trial 26 / Suspended 12. No golden baselines touch this screen.

---

**Changelog 7.39** (2026-07-10):

### Notification Quiet Hours (Tihi sati) — data-honest omit built end-to-end (audit/quiet-hours)
The handoff "Tihi sati" push-suppression control was previously omitted (no model,
no enforcement). Now a full vertical slice, DEV-ONLY (bookbed-dev), enforcement
included so the toggle actually suppresses:
- **Model:** new freezed `QuietHours {enabled, start:'HH:mm', end:'HH:mm',
  timezone}` nested in `NotificationPreferences` (default OFF, 22:00→07:00,
  Europe/Zagreb), persisted at `users/{uid}/data/preferences`; copyWith on the
  nested config (never reconstructed).
- **Enforcement (PUSH ONLY):** `functions/src/notificationPreferences.ts`
  `shouldSendPushNotification` now suppresses push during the window via new pure
  predicates `isQuietNow`/`isWithinQuietWindow`/`nowMinutesInTz`
  (DST-correct via `Intl.DateTimeFormat`, cross-midnight aware, fail-open on
  disabled/malformed). Email + in-app/DB records untouched — nothing lost.
- **UI:** "Tihi sati" card in `notification_settings_screen.dart` — enable switch
  + native TimePicker start/end fields (12px inputs) gated on enabled, cross-
  midnight hint; saves via existing repo + `ref.invalidate`.
  `@visibleForTesting buildQuietHoursCard` seam.
- **Rules:** no change needed (owner already writes `data/preferences`);
  4-case `quiet_hours_prefs.test.ts` proves owner-write ALLOW / stranger DENY /
  blocklist still bites.
- **l10n:** 8 `quietHours*` keys (en+hr).
- **Verify:** analyze 0 net-new; flutter test 1757 green (golden unchanged — no
  seam for this screen); CF jest 475/24; rules emulator 245/16; CF unit 12/12.
  Live web eyeball bookbed-dev. FROZEN: none. Not deployed (DEV-ONLY).

---

**Changelog 7.38** (2026-07-10):

### Owner Subscription — trial progress bar wired to real data (audit/trial-progress-bar)
`subscription_screen.dart` `_TrialHero` had hardcoded fake trial numbers
(`14/12/'10. lipnja 2026.'`). Now a `ConsumerWidget` gated on `trialStatusProvider`,
DERIVING days from the already-persisted `trialStartDate`+`trialExpiresAt`
(zero schema/CF/rules change): new `TrialStatus.totalTrialDays` +
`getDaysElapsed({now})` (clamped). Honest hide (`SizedBox.shrink()`) when not in
trial / bounds unpersisted. `@visibleForTesting TrialBarData.fromTrialStatus` +
`buildTrialHeroForTest` seam; 8-cell `trial_hero_test` (derivation clamp/null +
visual). 4 new l10n keys (en+hr), HR date via `DateFormat('d. MMMM yyyy')`.
analyze 0 net-new, full suite green, golden unchanged. Live web eyeball on
bookbed-dev (real trial user) confirmed "29 od 30 dana preostalo · Završava
9. kolovoza 2026". Dev-only, no deploy; FROZEN: none.

---

**Changelog 7.37** (2026-07-10):

### Overnight design-fidelity campaign — 15 iterations, owner + widget + admin (audit/overnight-fidelity-2026-07-10)
Page-by-page handoff fidelity sweep (`BookBed Design.html` / `*-premium.jsx` / `*.jsx` as the visual TARGET, not token-hygiene), fix-as-you-go across 15 PRs (#840–#854). Every change dev-only, no deploy; FROZEN fences (Cjenovnik grid, publish flow, timeline dimensions, booking widget submit) untouched throughout.

**Owner:**
- **#840** (`da0515e0`) — Subscription (Pretplata) cheap-wins: back-nav, Pro-card border, dialog l10n (audit/149).
- **#843** (`df9be9d5`) — auth recovery cluster: RecCard icon-tile + handoff-xl card radius (login/register/recovery).
- **#844** (`67fe8cd3`) + **#851** (`912f1e96`) — profile hub `BookBed Pro` card benefits grid + €19 price + l10n remainder (audit/135 S3); iCal FeedCard footer bar folded into #851.
- **#841** (`d492a332`) — iCal sync-settings hero flattened to a flat status card (flat-chrome enforcement per CHANGELOG 7.23/audit/126).
- **#842** (`72a79fa2`) — embed/owner docstring flatten (stale TIP-1 gradient text removed) + embed guide **data-honesty** verdict (no invented feature).
- **#845** (`a5a663d1`) + **#854** (`40cad472`) — unit-hub master panel: fidelity vs `units.jsx`, then PropertyTree **flat-row** rework (`ExpansionTile`→flat `Row` `[chevron][icon][name Expanded][count][edit][delete][add]`, closing the long-name vertical-wrap band-aid from #850).
- **#849** (`c11c1a71`) — 5 owner `AlertDialog` confirms → `BbDialog`.
- **#850** (`85301145`) — deferred-backlog mop-up: units title one-line, iCal Uvoz/Izvoz direction badge, admin env pill (reads REAL env).

**Widget (guest-facing):**
- **#846** (`ec71d98e`) — mint-accent success mark + deposit band fidelity (confirmation/deposit).
- **#847** (`e96bb8f7`) — mint selection ladder on calendar + guest-form quick wins (values-only, zero structural painter edits).
- **#853** (`eef254f3`) — guest-form input radius **8→12px** per handoff (`buildDecoration()`/theme-level; the canonical 12px input-radius standard).

**Admin:**
- **#848** (`8d4bed10`) — dark-console nav chrome wired to `BbAdminDarkTokens` (shell fidelity, deep-purple).

**Key decisions:**
- **Flat-chrome enforcement** — every hero/gradient straggler flattened to solid fills (do NOT re-add TIP-1 gradient stops).
- **Data-honesty skips** — features with no backing field/backend (embed guide extras, live-chat, helpful-vote) omitted rather than faked.
- **CanvasKit login unlock** — post-login programmatic access via `flt-semantics-placeholder` click enabled the iter-13 live-verification sweep (#852, `370d2e52`, doc-only attestation of #840–#851).
- **Input radius 12** — widget guest-form corners standardized to 12px (matches owner input convention).

**Verification:** full suite **1697 green** (`All tests passed!`); golden **56/56** green (no widget golden — all owner-side, zero collateral re-bless). `flutter analyze` 0 net-new, `dart format` clean, `flutter build web --no-tree-shake-icons` clean per PR. Live web eyeball on `main_dev` per fidelity iteration. Dev-only — PROD deploy batch deferred.

---

**Changelog 7.36** (2026-06-22):

### Owner/pre-auth — FAQ E-pošta CTA + accordion active-state · Legal box-driven 2-col (audit/145 + /146)
- **Folded in the 2026-06-22 CHANGELOG reconcile** — work merged 2026-06-21 (`dad72d7c`, #780); shipped without its own version entry.
- **FAQ (audit/145, buildable gaps; colour settled by 126/127):** the contact-support card gains an **E-pošta `mailto:` CTA** (`info@bookbed.io`, mirroring the `url_launcher` precedent in about/profile); each accordion is now a stateful `_FaqExpansionCard` whose leading category disc flips to **filled-primary + white icon while expanded** (handoff active-state, via `ExpansionTile.onExpansionChanged`). Live-chat (D2) + helpful-vote row (D1) stay omitted — no backend, data-honest.
- **Legal (audit/146, LG1 option B — terms/privacy/cookies uniformly):** the two-column-reader threshold stays **900** (named `_kLegalTwoColMin`, **NOT** migrated to the 1200 device-class breakpoint — sidebar 240 + gap 48 + doc fit the 980 clamp from 900px up = content-fit reflow; 1200 would drop the 2-col reader on iPad-landscape 1024). Decision moved from `MediaQuery…size.width` → `LayoutBuilder constraints.maxWidth` (true box-driven reflow). `LegalTabsRow` pushReplacement nav contract untouched; "Preuzmi PDF" omitted — no generator, data-honest.
- **Breakpoint hygiene:** FAQ body-column gates named `_kFaqDesktopColMin` (1024) / `_kFaqTabletColMin` (600) — box-reads, intentionally not migrated to 1200 (audit/breakpoint-decide §durable-rule, CHANGELOG 7.32).
- **FROZEN fence — 0 touch.** Dev-only.

---

**Changelog 7.35** (2026-06-22):

### Owner — Notifications inbox premium chrome: header + count + mark-all + filter chips (audit/141)
- **Folded in the 2026-06-22 CHANGELOG reconcile** — work merged 2026-06-21 (`0d36f1db`, #781); shipped without its own version entry. (`notifications_screen` = the inbox/list; `notification_settings` was audit/135.)
- **In-body premium header** (`CommonAppBar.showTitle:false` on wide per audit/126 §2A): "Obavještenja" + "X nepročitano · ukupno Y" caption; on mobile the AppBar keeps the title + owns the mark-all action (`done_all`).
- **Count** → `unreadNotificationsCountProvider` (X) + total (Y), with a local-tally fallback while the stream loads. **Mark-all-read** → `NotificationActions.markAllAsRead(ownerId)` (header button on wide / AppBar action on mobile; shown only when unread > 0).
- **Data-honest filter chips:** Sve / Nepročitano / Rezervacije (`booking*`) / Plaćanja (`paymentReceived`) / Sustav (`system`) — no review/sync/rating categories invented (no backend); empty filter → inline no-results. Header + chips ride as the leading `ListView` item (scroll with the inbox, preserve `RefreshIndicator`); selection mode unchanged.
- **l10n:** +9 keys × en+hr (gen-l10n regenerated). New inbox-chrome test (wiring: count + 5 chips + chip-narrows-list; no-overflow render mobile/tablet/desktop × light/dark — best-effort PNG, NOT a golden baseline). analyze 0 net-new, suite +8 green, build web clean. **FROZEN: none.** Dev-only.

---

**Changelog 7.34** (2026-06-22):

### Widget — localize 3 guest-facing English strings in FROZEN `booking_widget_screen.dart` → WidgetTranslations (4-lang)
- **Folded in the 2026-06-22 CHANGELOG reconcile** — work merged 2026-06-20 (`6854f11f`, #768); its rescue-branch draft was mis-headed **7.32** (collided with the breakpoint #775=7.32 already on main) → re-numbered **7.34** here.
- **Problem:** the FROZEN `booking_widget_screen.dart` shipped **English** error/confirm text to paying guests of HR/DE/IT owners on the public, no-auth `view.bookbed.io` widget — two defensive submit toasts ("Property ID is missing" / "Owner ID is missing") and the entire price-change `AlertDialog` (title + body + Cancel/Continue). None were routed through the widget's existing 4-language `WidgetTranslations` (System B).
- **Scope (operator-approved whole-dialog):** 6 string-only expression swaps in the FROZEN screen → `WidgetTranslations.of(context, ref).<key>` (the inline idiom already in this file at lines 1039/3437), plus **two unavoidable `const` drops** on the dialog buttons (a `const Text` can't hold a runtime value — the only non-string tokens touched).
- **+6 keys** in `widget_translations.dart` (hr/en/de/it each): `propertyIdMissing`, `ownerIdMissing`, `priceUpdatedTitle`, `priceUpdatedConfirm(oldPrice,newPrice)`, `cancel`, `continueLabel`. **EN output byte-identical** to the removed literals (`priceUpdatedConfirm` keeps the call-site `.toStringAsFixed(2)`; € + labels live in the key).
- **FROZEN fence — 0 logic touch:** booking submit flow / defensive `return`s / `showDialog` / `Navigator.of(dialogContext).pop(true/false)` / `finalCalculation` recompute all unchanged. Frozen-file diff eyeballed = only the 6 swaps + 2 `const` drops.
- **Verifikacija:** `flutter analyze` **0 net-new** · `dart format` · **full suite +1587 green** · `flutter build web --no-tree-shake-icons` clean. **Layer-1** throwaway EN byte-identical + 4-lang resolve test **10/10**. **Layer-2** golden harness (dialog + toasts × 4 langs × mobile/desktop × light/dark, Inter-loaded) — legible, correct diacritics + €, **no overflow** incl. German. Both throwaway (deleted pre-commit). **Merged main `6854f11f` (#768).**
- **Deploy: HELD (not live).** A CI-equivalent PROD widget bundle was built + locally smoke-tested (boots, icons render, console clean, **App Check NOT activated**, DE l10n live) but **NOT deployed** (CI GitHub-billing-blocked; manual deploy held per operator). `view.bookbed.io` still serves `2ee8d838` → guests still see English on these guarded paths until a widget hosting deploy.

---

**Changelog 7.33** (2026-06-21):

### Widget — Localize guest-facing `PopupBlockedDialog` to 4 langs (System B; audit/l10n-hardcoded-strings-sweep-2026-06-20)
- **Recon-first:** `popup_blocked_dialog.dart` (the dialog a paying guest sees mid-checkout when the browser blocks the Stripe payment popup) was **100% hardcoded English** — flagged by the l10n hardcoded-strings sweep. The surface uses **System B** (`WidgetTranslations.of(context, ref) → tr.*`, NOT `AppLocalizations`/`context.l10n`). The dialog is **currently unwired** (`booking_widget_screen.dart` auto-redirects ~L3738–3760 instead of `showDialog`); wiring is a separate FROZEN-file task → out of scope here.
- **l10n (11 keys, all 4 langs hr/de/it/en):** `popupBlockedTitle`, `popupBlockedBody`, `popupOpenPayment`(+`Desc`), `popupCopyLink`(+`Desc`), `popupTryAgain`(+`Desc`), `popupCancel`, `popupLinkCopied`, `popupCopyFailed` — new `POPUP BLOCKED DIALOG` section in `widget_translations.dart`. All 11 literals (title / body / 3 option title+desc pairs / cancel / 2 copy snackbars) → `tr.*`.
- **Async-safety:** `_handleCopyLink` now takes the resolved `WidgetTranslations` (was an **unused** `WidgetRef`) — resolving l10n off `context`/`ref` AFTER the clipboard `await` is the use-context-when-possibly-unmounted footgun; `tr` captured before the gap sidesteps it.
- **`popupCancel` (not generic `cancel`):** #768 landed an identical generic `cancel` on main after this branch forked → reusing the name = a duplicate-getter compile break that a *textually*-clean merge hides. Kept dialog-local; values match (Odustani/Abbrechen/Annulla/Cancel) so it can collapse to `cancel` in a later hygiene pass. Verified **rebase-clean onto current main, zero getter collisions** (`cancel` + `popupCancel` coexist).
- **FROZEN fence — 0 touch:** `booking_widget_screen.dart` (Navigator.push confirmation / 18 silent-guards) untouched; no NIKADA surface edited. Dialog stays **unwired** — the live `lang=de` wrap/overflow eyeball (German option descriptions run long vs the fixed `SizedBox(width: 400)`) is the future wiring task, not this l10n swap.
- **Coverage:** new `popup_blocked_dialog_l10n_test.dart` — pumps the real dialog in all 4 langs (every visible string resolves + no English literal leaks in hr/de/it) + translation-map completeness. The +11 keys (all 4-lang) pass P7's now-on-main `widget_translations_coverage_test`; ARB no-dup guard stays 0.
- **Verifikacija:** rebased clean onto current post-P7 `origin/main`; `flutter analyze` **0 net-new** · `dart format` · P7 l10n guards green with +11 keys (4-lang) + no-dup **0** · full suite green · `flutter build web --no-tree-shake-icons` clean. Pushed `fix/widget-l10n-guest`. Dev-only.

---

**Changelog 7.32** (2026-06-20):

### Design system — canonical desktop breakpoint = 1200 (decision + Foundation) (audit/breakpoint-decide-2026-06-20)
- **Decision (doc-only, SHIPPED `ead8e25e` / #766):** resolved three competing breakpoint systems — `Breakpoints` (desktop=1024, 38 refs, powers `context.isDesktop`), `BBBreakpoint` (wide=1440, 6 refs), `ResponsiveBreakpoints` (desktop=1200, 6 refs) — none of which matched the documented 1200 convention. Banked **1200 px** as the single canonical desktop breakpoint; single source of truth `lib/core/constants/breakpoints.dart` (the other two delegate in a later codemod). Migration is **additive** — legacy `Breakpoints.desktop=1024` flips in a separate Final codemod, not in place. Resolves the §1 "breakpoint-system unification" deferral from audit/responsive-overflow-a11y (CHANGELOG 7.31).
- **The durable rule (prevents re-drift):** classify each width comparison by what it READS — **device-class pivots** (`MediaQuery`/`screenWidth`, gate padding/typography) migrate to 1200; **content-fit reflows** (`LayoutBuilder constraints.maxWidth`, gate column-count/wrap) keep their value and just get a named local const. Content clamps (`maxWidth:1000/1100`) → unify to `BBContentMaxWidth=1200`. Intentional keeps: calendar 900, widget 1024, subscription/booking_detail 720.
- **Foundation (SHIPPED `decb3be8` / #769, zero behavior change):** added `Breakpoints.desktopWide = 1200` + `Breakpoints.isDesktopWide(context)` as the single source new/migrated screens gate on (legacy `desktop=1024` untouched — additive). Fixed the lying `context_extensions.dart` `isTablet`/`isDesktop` docstrings (claimed desktop `>= 1440`; the code has always fired at `>= 1024`).
- **Risk made explicit:** today `tablet == desktop == 1024` (no live tablet tier); moving to 1200 makes the 1024–1199 band hit each screen's tablet branch for the first time → every per-screen migration needs a ~1100px eyeball.
- **Verifikacija:** `flutter analyze` **0 net-new** (changed files clean) · `dart format` · **full suite 1581 green** · `flutter build web --no-tree-shake-icons` clean. Dev-only. Deferred: per-screen migrations (ride design passes — stripe/138, ical/140, embed/137) + Final codemod (flip legacy `desktop`→1200, re-point `context.isDesktop`, eyeball all 38 `context.isDesktop` consumers @ ~1100px). (Renumber if a sibling parallel branch claims 7.32.)

---

**Changelog 7.31** (2026-06-20):

### Admin + Owner — responsive RenderFlex-overflow P0/P1 fixes (audit/responsive-overflow-a11y-2026-06-20 §2)
- **Recon-first:** the P5 responsive/overflow/a11y sweep's §2 ledger flagged 3 confirmed RenderFlex overflows — 1 P0 (admin) + 2 P1 (owner, same file). Both fixed here as deterministic, test-gated, layout-only changes (no l10n/restyle — admin l10n is audit/147).
- **P0 — admin Users-list `DataTable` horizontal overflow (SHIPPED `8828e620` / #765):** the 5-col table sat in a vertical-only `SingleChildScrollView`, so in the 800–1100px window its intrinsic width painted the overflow stripe. Wrapped in `LayoutBuilder` → horizontal `SingleChildScrollView` → `ConstrainedBox(minWidth: constraints.maxWidth)` — scrolls when content exceeds the viewport, **fills the card on wide screens** (no left-float). Outer vertical scroll + the `<800` card fallback unchanged. New `users_list_overflow_test` (780/900/1100/1440) via a `@visibleForTesting buildUsersTableForTest` seam; **RED→GREEN** (the seam isolates `_UsersTable` so `_buildBody`'s filter-chip scroll can't satisfy the assertion vacuously).
- **P1 — `booking_action_menu` name Texts wrap (`#771`):** guest / platform / unit names sat in width-bounding `Expanded`s with no `maxLines`/`overflow` → a long name wrapped to 2–3 lines and broke the compact bottom-sheet header. Added `maxLines: 1, overflow: TextOverflow.ellipsis` to the **6 bounded user-content name Texts** (`BookingActionBottomSheet` header guest/platform/dates/"Manage on {source}" + `BookingMoveToUnitMenu` guest + user-defined unit name). Unbounded `Row(min)` chips/badge left as-is (ellipsis is a no-op without a width bound → separate `Flexible` pass). New `booking_action_menu_overflow_test` (both classes public → direct pump; `BookingMoveToUnitMenu` via `allOwnerUnitsProvider` override); **RED→GREEN both groups**.
- **FROZEN fence — 0 touch:** neither file is a NIKADA surface; Timeline z-index / `timeline_dimensions` / calendar repo untouched.
- **Verifikacija:** `flutter analyze` **0 net-new** · `dart format` · **full suite +1583 green** · `flutter build web --no-tree-shake-icons` clean. Auth-free golden eyeballs (admin table scroll/fill @800/1100/1440; menu guest name "Maximiliana-K…" single-line @360). Dev-only. (Renumber if a sibling parallel branch claims 7.31.)

---

**Changelog 7.30** (2026-06-20):

### Owner — Unit Wizard progress-bar §F polish: on-palette success token + active-step glow (audit/134, scope F)
- **Recon-first (audit/134 §F):** the last un-applied SAFE component from the §5 ledger (B+A shipped #761; C is FROZEN-gated; D/E/G/H low-value). The §4 fingerprint scoped the wizard-chrome debt to **"1 hardcoded color"** → a single-file polish, **not** a stepper re-layout.
- **1-color hygiene:** retired the off-palette bright Material green (`#66BB6A`) literal in `wizard_progress_bar.dart` → theme-aware system success/confirmed token (`BBColor.of(context).success` = `#2E7D5B` / `#4FAE7F`) on completed nodes + labels + connectors **and** the mobile `LinearProgressIndicator`. Same "done = green" semantic, now on-palette (matches the Confirmed status badge).
- **Handoff polish:** the **current** step node gains the `--bb-shadow-purple-sm` glow (`BBShadow.purpleGlow`) per the `wizard.jsx` stepper — subtle active-step lift.
- **Deliberately NOT replicated (handoff = design meta / data-honesty):** the stepper **"FROZEN" badge** (design-doc annotation marking the locked publish flow, not user UI); **"Skica spremljena"** autosave caption (draft is in-memory until publish → would fabricate state); step-1 **"Odustani"** (CommonAppBar back already closes the pushed route); and the horizontal re-layout / bare-number nodes / mobile discrete-segment bar (beyond §F scope — the icon-led 3-tone treatment reads done/current/pending more clearly and is kept).
- **FROZEN fence — 0 touch:** Wizard `_publishUnit` 2-doc serial write · `CommonAppBar` unification (audit/124–126) · step-content / `UnitModel`.
- **Coverage:** new `wizard_progress_bar_test.dart` — **42 cells** (7 breakpoints × light/dark × 3 step-states) asserting no overflow + clean token resolve across **both** render branches (compact < 600 / full stepper ≥ 600).
- **Verifikacija:** `flutter analyze` **0** · `dart format` · render/overflow **42/42** · `flutter build web --no-tree-shake-icons` clean. **Live eyeball** (bookbed-dev `:8097`, operator-gated light+dark+mobile). **Dev-only → not deployed.** FROZEN: none.

---

**Changelog 7.29** (2026-06-20):

### Owner — Settings cheap-wins: widget_advanced AppBar unification + notif l10n (audit/135, scope cheap-wins)
- **Recon-first (audit/135):** code-first fidelity diff of the audit/129-deferred settings screens (S3 hub + S4 forms + no-handoff screens). Verdict: cluster largely DONE; 2 agent-flagged "gaps" were **false** (identity-chip + public-profile = no feature → data-honest omissions; `change_password` "missing SReqList" = already present in `_PasswordStrengthMeter`). Real work = a cheap-wins bundle + one heavy item (S3 Pro-card grid, deferred).
- **`widget_advanced_settings_screen`:** all 4 raw `AppBar(title: Text(...))` → `CommonAppBar` (`leadingIcon: arrow_back` / `onLeadingIconTap: pop`; main-branch save `actions` kept) + import. Closes the audit/126+129 chrome-unification debt. **Embed-safe (code-verified):** all 4 sit behind the `if (!widget.showAppBar) return <bare content>` guards — the screen is uniquely embedded headless in the hub Napredno tab (`showAppBar:false`) → no double-header. Chrome-only; widget-config logic (subdomain regex / App-Check) untouched.
- **`notification_settings_screen`:** hardcoded HR banner string → new l10n key `notificationSettingsBannerInfo` (en+hr). Visually neutral. (Magic sizes 36/13/10 match the handoff + have no exact token → left to avoid pixel drift.)
- **DROPPED `edit_profile` 2-col name grid** — the screen uses a single full-name field (`_displayNameController`), not first/last; a 2-col grid = splitting one field into two = data-model + validation + save/UX + existing-name migration. Feature, not cheap fidelity. Deferred (likely permanent).
- **Verifikacija:** `flutter analyze` **0 net-new** · `dart format` · full suite **+1535 green** · `flutter build web --no-tree-shake-icons` clean. Embed-check (code) confirms standalone-only AppBar. Live-render skipped (budget-lean; changes = neutral l10n + canonical `CommonAppBar`). **Dev-only → not deployed.** FROZEN: none (widget_advanced chrome-only; FROZEN-adjacent config untouched). Deferred: S3 Pro-card benefits grid (heavy, 1503 LOC) until budget reset.

---

**Changelog 7.28** (2026-06-19):

### Owner — Unit Hub "Osnovno" tab premium fidelity + dialog Bb-migration (audit/134, scope B+A)
- **Recon-first (audit/134):** Unit Hub is the **most FROZEN-saturated owner screen** (hosts the FROZEN Cjenovnik pricing grid + Wizard publish). A FROZEN-intersection map drew the SAFE/FROZEN boundary per component; scope locked to **B (Osnovno tab) + A (shell confirm)** via a 7-question alignment interview. **Master panel deferred** to its own pass (≈870-line interactive selection/nav/delete surface, no tile-level handoff).
- **B — Osnovno tab → `units.jsx`:** `_buildBasicInfoTab` rebuilt — desktop gallery (cover + 2×2 of `unit.images`) → header (`unit.name` + subtitle + **Kopiraj** [duplicate] + **Uredi**) → 2-col `BbCard` Informacije/Kapacitet (desktop+tablet 2-col, mobile stacked) → full-width Cijena `BbCard` (emphasized **PriceTile** grid + extra-fee rows + tappable **Cjenovnik banner**). Hand-rolled `_buildInfoCard`/`_buildDetailRow` (AnimatedContainer/BoxDecoration) replaced by `BbCard` + handoff primitives: `_osnovnoCardHeader` (32px primary-tint badge), `_kvRow` (uppercase label; stack-mode for the OPIS prose; status → `BbStatusBadge`), `_priceTile`, `_buildUnitGallery`/`_galleryTile` (`Image.network` + `errorBuilder`).
- **Data honesty:** Vidljivost + Polog **dropped** — no backing field on `UnitModel` (verified); rendering them would fabricate data. Extra-bed/pet fees kept as KV rows (preserve current data).
- **Dialogs:** 3× `AlertDialog` → `BbDialog` (delete logic + bool returns preserved; deletes `destructive`; 2 dead `theme` locals dropped).
- **l10n:** +`unitHubCopy` / `unitHubBasicDataSubtitle` / `unitHubAdvancedPricingHint` (en + hr).
- **FROZEN fence — 0 touch:** Cjenovnik content / `price_list_calendar_widget` / `_buildSaveButton` brand-purple gradient / Wizard `_publishUnit` 2-doc serial write / Navigator.push confirmation. Banner = local `_tabController.animateTo(1)` only (never reads/writes Cjenovnik).
- **Verifikacija:** `flutter analyze` **0 net-new** (my file clean; 3 self-introduced redundant-default infos fixed) · `dart format` · **full suite +1535 green** · `flutter build web --no-tree-shake-icons` **clean**. **Live render** (bookbed-dev `:8094`, `scripts/seed-osnovno-eyeball-dev.js` [untracked dev aid], chrome-devtools/CanvasKit): Osnovno **all 6 — desktop/tablet/mobile × light/dark**, faithful to handoff, no overflow, dark = `#000` page + `#1E1E1E` cards (audit/127 ladder). **Interaction-verified LIVE** (not code-claims): banner tap flips selected tab to Cjenovnik (content untouched); `BbDialog` **Odustani** leaves the unit / **Obriši** deletes it (**Firestore `exists:false` confirmed**). **Dev-only → not deployed.** FROZEN: none. (Sibling 130/timeline merged off the 7.26-base without a version bump; 7.28 = next free after 7.27.)

---

**Changelog 7.27** (2026-06-18):

### Owner — AI Assistant premium fidelity + subtle motion (audit/132, S1+S2+S3, R1=tablet-fold)
- **Recon-first (audit/132):** `ai_assistant_screen.dart` already premium-composed against its dedicated handoff (`design_handoff/source/ai-assistant.jsx`, 4 owner artboards) — a BEYOND-color fidelity + motion pass (127 did the palette). FROZEN-clean: client-only chat, **streaming heartbeat (`copyWith`→`ref.listen`→`animateTo`) byte-untouched**; all motion is additive render-layer only.
- **S1 (cheap fidelity):** radial-glow mascot hero unified across empty-state + consent + quick-reply (`_AiHeroIllustration`); assistant-bubble avatar 32→24 (handoff); suggestion chips 5→**4/3/2** by width (`Wrap`-safe); composer `minLines` desktop 2 / else 1; desktop chat-list panel 320→300; **breakpoint alignment** — bubble + premium header now switch at the layout `_kDesktopBp` (1200) not 600, so **768 folds coherently to mobile**; 5 stray literals named as in-file `_k*` consts (not `BBSpace.xs2`, deprecated-on-use).
- **S2 (user-bubble avatar):** owner name from `enhancedAuthProvider.userModel` (clean synchronous read mirroring `OwnerAppDrawer`; no new plumbing) → `BbAvatar` initials (owner photo via `avatarUrl` when set) on the right of user bubbles. `buildAiMessageBubble` gains optional `userName`/`userAvatarUrl` — backward-compatible, test seam preserved.
- **S3 (subtle motion; design-to-system, handoff specs none):** animated 3-dot typing indicator replaces the static `'...'` pre-first-chunk (`_TypingDots`); send-button idle↔spinner cross-fade + colour transition (`AnimatedSwitcher`/`AnimatedContainer`); chat-list loading skeleton (`BBSkeleton.listRow`) replaces the bare spinner; suggestion-chip staggered fade+rise on mount (`_StaggeredChips`). All reduced-motion aware.
- **R1 (accepted):** tablet **folds to mobile** — no distinct tablet tier built; below 1200 (incl. 768) renders the mobile single-pane path coherently. `attach_file` composer kept omitted (text-only Gemini); desktop breadcrumb out of scope (audit/126 §2B).
- **Hardening:** `buildAiMessageBubble`'s `typing`/`userName`/`userAvatarUrl` made **required** named params after a live-unwired call site (`_buildMessageList` called the 2-arg form → static `'...'` + `"?"` avatar) slipped past analyze + build + the 14/14 seam test; now it's a compile error. The full-screen pump that would test the call site is blocked by `enhancedAuthProvider` (StateNotifier) so [T1] is deferred and the wiring is eyeball-gated — see memory `seam-test-proves-fn-not-wiring`.
- **Verifikacija:** `flutter analyze` **0 net-new** (3 changed files clean; 97 pre-existing infos in unrelated widget/util files) · `dart format` · `ai_assistant_premium_test` **14/14** (seam + user-avatar path, 6 bp × 2 themes) · **full suite +1535 green** · `flutter build web --no-tree-shake-icons` **clean**. **Live dev smoke (render):** **iOS sim + Android Pixel_8** (Marionette, dev) — render ✓: S2 'BT' owner-avatar live on user bubbles, 2 mobile chips, header, markdown bubbles. Web `:8093` render eyeballed. **Streaming dots→text live-verification: DEFERRED — testing stopped before the dedicated browser smoke.** The streaming render-path is wired + code-verified (call-site fix; heartbeat byte-untouched), but the live animation is unconfirmed (CanvasKit blocks agent web-automation; native sim/emulator streaming blocked by `firebase_ai` **App Check 403** "App attestation failed"). **Dev-only → any streaming issue is a fix-forward.** **Merged to main `10d7a97c` (fast-forward); not deployed (dev-only per operator).** FROZEN: none. (Sibling branches design/130 + fix/timeline also off 7.26-base — renumber if 7.27 collides.)

---

**Changelog 7.26** (2026-06-17):

### Owner — Settings cluster recon + bank_account flat-bg hygiene (audit/129, S2)
- **Recon (audit/129):** "owner Settings" is a **CLUSTER of 9 screens** (no single file), reached from the `profile_screen` hub — and **all already Bb*-migrated** (hex=0, mostly `context.gradients`). Not a migration job. Handoffs exist: `settings.jsx` (Uredi profil / Promijeni lozinku / Postavke obavijesti) + `profile-premium.jsx` (hub).
- **S2 (applied):** `bank_account_screen` body `Container(color: rd.shellBg)` → `context.gradients.pageBackground` (canonical flat-palette source, audit/126 pattern). **Visually neutral** — `rd.shellBg` (light `#F0F1F5` / dark OLED `#000`) is byte-identical to `pageBackground`, so the bg was always correct; this is **untokenized-but-correct hygiene, NOT a wrong-bg bug**. `rd` preserved (used 3× elsewhere).
- **S1 DROPPED — recon false positive:** `widget_advanced_settings` was flagged "legacy (hand-rolled `Container(gradient)+Material+InkWell+Icons.check`)" — but precise **non-comment** grep = **0 hits**. The flagged chrome is documented-as-already-replaced in COMMENTS (hand-rolled gradient → `BbButton`; purple header slab → `c.surface` per audit/120). The screen is already flat + Bb-tokenized. Recon misread comments as current code; caught at apply.
- **Verifikacija:** `flutter analyze` 0 · `dart format` · **full test suite green** · `flutter build web --no-tree-shake-icons` clean. Render bank_account light+dark + live `:8091` dark eyeball.

---

**Changelog 7.25** (2026-06-17):

### Owner — Booking detail premium fidelity + hygiene + overflow-robustness (audit/128)
- **Recon-first:** `owner_booking_detail_screen.dart` was already premium-composed against its dedicated handoff (`booking-detail.jsx §201`) — light fidelity+hygiene pass, not a redesign. No hero wash to flatten (scrims/status-tints/accent-rail all "kept on purpose"). Sequenced behind audit/127 so `pageBackground` carries the flat ladder.
- **F1 — destructive-soft (×3):** Odbij / Otkaži rezervaciju / mobile-sticky Odbij `BbButtonVariant.destructive`→`destructiveSoft` (error-tint pink) per handoff. Variant-only — gate logic untouched.
- **§2 — dead `shellBg` removed:** the body `Container(color: rd.shellBg)` covered the Scaffold's `context.gradients.pageBackground` in the data path (dead paint). Dropped it → inherits the flat palette (light `#F0F1F5` / dark OLED `#000`). **Visually neutral** (old shellBg values == post-127 pageBackground), now single-source per audit/126.
- **§3 — hygiene:** magic numbers → named consts (`_kContentMaxWidth`/`_kSidebarWidth`/`_kKvLabelWidth`/cover heights); off-grid `14`→`_kMobileGap`=12 (`BBSpace.xs2` is **deprecated-on-use** → in-file const instead); 2×`dynamic booking`→`BookingModel` + redundant `as` casts dropped.
- **F6 — tablet 2-col (`_TabletGrid`):** handoff `BookingDetailTablet` (full-width cover/pending/guest, then 2-col stay·notes·activity | status·price·meta — kept notes/activity/meta, data over mock). Engages ≥`_kTabletGridMinWidth`=**720** (600–719 stays wide single column; 293px columns were cramped, handoff tablet = 768).
- **Robustness (surfaced by the new overflow test, pre-existing latent overflows, 0 visual change for real content):** `_BDCover` property eyebrow → `Flexible`+ellipsis; `_TimelineRow` text → `Expanded`+ellipsis; the 720 threshold.
- **Test:** new `owner_booking_detail_layout_test.dart` — pumps the real layouts via `@visibleForTesting buildBookingDetailContentForTest` across 8 breakpoints × light/dark × normal/long-string + 4 status variants = **44 cells**, `takeException` overflow gate. `detailActionVisibility` + its 5-case gate test **preserved** (move-not-delete). Navigator.push confirm (FROZEN, widget tree) untouched.
- **Verifikacija:** `flutter analyze` **0** · `dart format` · gate **5/5** · overflow **44/44** · live Flutter light render (desktop + tablet) — F1 soft-pink + F6 2-col + layout fidelity confirmed. Dark = 127 token ladder (already verified). **Deferred:** owner PROD deploy batch (still 0 in PROD); F3 notif bell; l10n debt (≈40 hardcoded HR strings).

---

**Changelog 7.24** (2026-06-16):

### Owner — Handoff surface ladder adoption + dark-depth widen for flat chrome (audit/127, branch `design/127-handoff-palette-apply`)
- **audit/127 (READ-ONLY audit → APPLY):** first pass to systematize the owner color/surface/background **SYSTEM** (light+dark) vs handoff. Found the **3-system Frankenstein** — `app_gradients` painted off-palette (`#ECEDF2`/`#1A1A1A`/`#2D2D2D`) while `app_theme` + `rd.*` already matched handoff → page bg, cards, borders disagreed; dark had **inverted elevation** (page `#1A1A1A` lighter than the `#0B0B0D`/`#121212` panels/cards on it; the `#2D2D2D` "cards dissolved" hack was the tell). Doc + 6 handoff renders (Pregled/Rezervacije/Kalendar light+dark) bundled on the branch.
- **Part 1 — handoff ladder (VALUES only, FLAT kept):** light page/shell `#ECEDF2`→**`#F0F1F5`** (convergence value — Material scaffold + `rd.shellBg` already use it), card `#FBFBFD`→`#FFFFFF`, border warm `#E0DCE8`/`#35323D`→cool `#E2E8F0`/`#2D3748`, input→surface-variant; dark page `#1A1A1A`→**`#000`** (OLED). **Un-inverts elevation** (page now darkest).
- **Part 2 — dark-depth widen (the catch):** flat chrome renders **NO box-shadow**, so the handoff's tight dark steps (`#000`/`#0B0B0D`/`#121212`, Δ≈11) left the **panel dead on the gutter** (live-confirmed). Lightness replaces the missing shadow → **widened dark ladder:** page `#000` → panel **`#141414`** (`rd.panelBg`) → card **`#1E1E1E`** (`surfaceDark`) → variant **`#2A2A2A`** → elevated **`#333333`** (dialogs). Rippled: divider `#1E1E1E`→`#2A2A2A` (else vanishes on the lifted card), popup/menu `#0B0B0D`→`#1E1E1E` (else sinks below cards), `app_colors` elevation0-4 overlay ladder lifted above the new base. **LIGHT unchanged** (the white step separates without shadow). Operator-picked "A" depth from a 3-way flat swatch, live-confirmed (panel floats in real Pregled).
- **Principle (saved):** flat/shadowless dark themes need WIDER lightness steps than shadow-based designs — don't copy a shadow-based design's tight dark tones verbatim into a flat theme.
- **Scope:** 5 files (`bb_redesign_tokens`/`tokens`/`app_colors`/`app_gradients`/`app_theme`) + `bb_card_test` literal re-pointed `#121212`→`#1E1E1E` (coverage moved, **not deleted**). 0 FROZEN. audit/127 doc carries §7 dark-depth addendum.
- **Verifikacija:** `flutter analyze` **0 net-new** · `dart format` · full `flutter test` **green** (1 pinned-hex re-point) · `build web --no-tree-shake-icons` clean · grep panel `#0B0B0D` retired, monotonic `#000<#141414<#1E1E1E<#242424<#2A2A2A<#2E2E2E<#333333`. **Live owner dev (bookbed-dev) light+dark sweep:** Pregled/Rezervacije/Timeline/drawer/Cjenovnik — cards lift, panel floats, un-inverted; Cjenovnik grid border `#2D3748` on `#1E1E1E` reads (source+live verified). Pre-merge: origin/main no drift, no theme-file overlap.
- **Deferred:** owner PROD deploy (batch — Pregled+Rezervacije+Timeline+Mjesečni+global-chrome+AI+**palette+dark-depth**, all dev-only, **0 in PROD**).

---

**Changelog 7.23** (2026-06-16):

### Owner — Chrome FLATTEN: retire TIP-1 gray gradients + premium hero washes → flat (operator reversal; audit/126 §flatten)
- **Operator reversed the TIP-1 gradient preference** → flat clean colors. Killed the two opposite-direction gray shell gradients (page `topLeft→bottomRight`, section `topRight→bottomLeft`) — the exact thing flagged. `flat = handoff` (`--bb-bg` was always flat).
- **Central token (`app_gradients.dart`, 5 values):** `pageBackground`/`sectionBackground` now render flat (both stops equal) → all ~56 consumers flip, **zero call-site churn**. Split base/raised 2-tone: light shell `#ECEDF2` / raised `#FFFFFF` + card `#FBFBFD`; dark shell `#1A1A1A` / raised + card `#2D2D2D`. **Dark dissolve-trap fixed:** card `#0B0B0D` (darker than shell → cards sank) → `#2D2D2D` (one step above shell). 0 new hex (all values user-curated/pre-existing). `gradient_extensions.dart` doc retoned.
- **Hero washes flattened (Fork 2, operator-ruled from live render):** `_PregledAiInsight` (Pregled) + Rezervacije priority header (`bookings_premium_header`) purple/tertiary→mint low-alpha washes → flat `c.surfaceVariant` (border + shadow define; **purple icon tiles kept** = only brand accent). Sweep proof: mint-wash signature now **0** in owner chrome. **Kept** (different class, not the flagged murk): chart/progress data-viz fills, 4px amber priority rail, drag/drop, status/error chips, dialog headers, fade scrims.
- **Trial banner:** cream/amber + red gradients → flat tint; **EN→HR** strings ("Your trial ends in N days" → "Probno razdoblje istječe za N dana", "tomorrow!" → "sutra!", expired copy + "Upgrade" → "Nadogradi"). ⚠ banner bypasses l10n (hardcoded) → proper keys flagged for an l10n sweep.
- **RenderFlex overflow fixed (live-found):** Rezervacije `_Fact` chip Row had an unflexible `Text` → a long property·unit name overflowed the Wrap inside the *constrained* priority card (`+114px @≈1352`, ErrorBoundary "Oops"). Fix = `Flexible` + ellipsis; pre-existing (the ledger responsive test missed it — it pumps the *ledger*, not this header). New `@visibleForTesting buildBookingFactForTest` seam + `bookings_premium_header_fact_overflow_test` (8 constrained widths × light/dark = 16 cells).
- **Verifikacija:** `flutter analyze` 0 net-new (5 files clean) · `dart format` · full `flutter test` **1495 pass** (+16 overflow cells) · `build web --no-tree-shake-icons` clean · grep 0 mint-wash remain · scope = 5 lib + 1 test, **0 FROZEN**. **Live web (bookbed-dev) light:** Pregled (AI card flat + purple icon, trial banner flat + HR, flat shell) + Rezervacije (renders clean, long fact ellipsizes, header flat); **dark = golden harness** (AI card flat on `#1A1A1A`, cards distinct).
- **Deferred:** broader flatten of remaining accent gradients (status/dialog/property-card chips — out of scope, several carry meaning); l10n keys for the trial banner; owner PROD deploy (batch).

---

**Changelog 7.22** (2026-06-16):

### Owner — AI Assistant premium fidelity (`ec78235b`, audit/124 §ai-assistant)
- Premium fidelity pass na AI Assistant ekran (handoff `ai-assistant.jsx`) — chat shell stiliziran; AI je **LIVE Gemini** (`firebase_ai`) pa NIJE fabrikovan nikakav output; `_PregledAiInsight` (flagged placeholder) **netaknut** (data-honesty).
- **Double-header ubijen:** `showTitle:false` na 3 brancha (desktop split, mobile chat-list, active-chat) — in-body header nosi naslov, AppBar zadržava hamburger + "Novi razgovor". Consent ekran zadržava AppBar naslov (nema in-body hero → nema dupliranja).
- **Bubbles → handoff flat:** solid `primary` user / `surface`+border asistent, tail corner `BBRadius.xs` (TR user / TL asistent), 32px brand avatar, 11px timestampovi (real `message.timestamp`), 70/78% max-width (bio raw gradient + 28px).
- **`AiConversationHeader` (novo):** brand avatar + chat naslov + "BookBed AI · trenutno aktivan" + copy/delete akcije. Copy = clipboard zadnjeg asistent-odgovora (+ SnackBar), delete → postojeći `deleteChat` kroz premium **`BbDialog`** (zamijenjen native `AlertDialog`).
- **Composer → bordered pill** (radius md) + solid-primary send krug + disclaimer footer (`aiAssistantDisclaimer`). Attach-ikona IZOSTAVLJENA (nema upload feature = nema inert kontrole); user-avatar izostavljen (model je role-only).
- **Empty/welcome:** radial primary hero iza ilustracije + brand avatar + 5 ✦ suggestion chipova (`aiAssistantChip*`) + Image `errorBuilder` (offline asset-fail hardening). **Consent restyle = VIZUALNO SAMO** (icon tiles + eyebrow/H1 + tokenizovana kartica); grant/deny logika (`PopScope`, `_acceptConsent`→`grantAiChatConsent`, provider gate) **0 linija mijenjana**.
- **Token hygiene:** 0 `Color(0x`, 0 raw literala (named-const blok), `AppShadows`→`BBShadow`, `colorScheme`→`BBColor`; TIP-1 page-bg gradient potvrđen netaknut.
- **Test seam:** `@visibleForTesting buildAiMessageBubble` (top-level, provider-free) + novi `ai_assistant_premium_test` (12 overflow ćelija 360/414/768 × light+dark + conversation-header chrome + `AiBrandAvatar` asset-fail fallback). 2 nova l10n ključa (`aiAssistantCopyLast`/`aiAssistantMessageCopied`).
- **Verifikacija:** `flutter analyze` 0 net-new (3 AI fajla čista) · `dart format` · full `flutter test` **1475 pass** (+14) · `build web --no-tree-shake-icons` clean · grep 0-hex/0-literal · scope = 2 dart + 4 l10n + 1 test (0 shared/FROZEN; `CommonAppBar` widget NETAKNUT — samo `showTitle:false` call-sites). **Live web Marionette na bookbed-dev:** desktop light+dark (bubbles/header/composer/delete BbDialog/welcome+chips, nema double-header), consent gate restyled + **grant verifikovan end-to-end** (logout→login→consent→accept→chats), logout robustan (real-tap clean confirm, zero "Oops" — raniji ErrorBoundary bio Marionette `scroll_to`). Mobile/tablet = test-proven (12 ćelija).
- **Deferred:** owner PROD deploy (batch s Pregled/Rezervacije/Timeline/Mjesečni/global-chrome — **6 changes, prezreo**); mobile live-resize pixel-potvrda (test-covered).

---

**Changelog 7.21** (2026-06-16):

### Owner — Global chrome fidelity: page-bg gradient migration + double-header kill + drawer tokenize (`696f004c`, audit/126)
- Shared/global chrome pass (audit/126 decisions **1B + 2A + 3A**) — touches every owner screen, so verified with an **all-screen light+dark sweep**, not single-screen. Own worktree, dev-only, 0 FROZEN.
- **1B — page bg:** 4 straggler screens (profile, about, owner_booking_detail, ical_sync) migrated off legacy flat `rd.shellBg` → `context.gradients.pageBackground` (the TIP-1 token already on 19 screens). `embed_widget_guide` **skipped** — recon found it already gradient (audit/126's "transparent outlier" was a misread of the help bottom-sheet modal). owner_booking_detail Scaffold → `Colors.transparent` + body gradient `Container`; 2 now-dead `rd` locals removed. Token consistency = goal (stop bypassing the token); inner shellBg content panel left → owner_booking_detail full premium pass.
- **2A — double-header:** additive `bool showTitle = true` on `CommonAppBar` (title renders only when true → **~29 non-premium screens untouched**); `showTitle:false` on the 4 premium screens (Pregled/Rezervacije/Timeline/Mjesečni) → in-body premium header owns the title, AppBar keeps hamburger + actions (Mjesečni Today + view-toggle). Kills the literal "Month Calendar"+"KALENDAR" dup. Handoff-mobile keeps a bar title; operator chose full strip (reads clean = dissolve-chrome intent; breadcrumb **2B deferred**).
- **3A — drawer tokenize:** `OwnerAppDrawer` `theme.colorScheme.onSurface`→`BBColor.textPrimary` (18×) + `colorScheme.primary`→`BBColor.primary` (1×) — **byte-identical** to the colorScheme slots (both wired to `AppColors.textPrimary*` / `primary*`), so cosmetic-neutral. Left `colorScheme.danger`, amber notif badge (Material named const), `lightPurple` named const, `rd.*`. One orphaned `theme` local removed.
- **Tests:** new `common_app_bar_test` locks the contract (default shows title / `showTitle:false` hides it, leading+actions stay); `calendar_chrome_responsive_test` gains an assertion that the title renders in the in-body header (coverage **moved**, not dropped).
- **Verifikacija:** `flutter analyze` 0 net-new (98 pre-existing `info` lints, all untouched files) · `dart format` · full `flutter test` **1461 pass** · `build web --no-tree-shake-icons` clean · scope = 10 lib + 2 test, **0 FROZEN**. **Live web light+dark** (bookbed-dev): non-premium title present (Obavještenja/Profil), premium title-less + no double-header (Pregled/Mjesečni), Mjesečni actions kept, migrated bg gradient, drawer unchanged + badges intact (red danger + amber).
- **Deferred:** **2B** breadcrumb appbar (desktop breadcrumb + mobile title) · **3B** persistent desktop sidebar + tablet rail (VERY HIGH — every Scaffold → Row[rail, content]) · owner_booking_detail inner-panel toning (rides its full premium pass) · owner PROD deploy (batch s Pregled/Rezervacije/Timeline, čeka GO).

---

**Changelog 7.20** (2026-06-16):

### Owner — Timeline/Kalendar premium chrome fidelity (`b9656008`)
- Premium CHROME pass **OKO** zamrznutog grid-a (handoff `calendar-premium.jsx`); cell geometrija (`timeline_dimensions.dart` 50/42/100/60px) + `firebase_booking_calendar_repository` + grid-render widgeti + z-index **bajt-identični** — samo chrome okolo dirnut. (Za razliku od Rezervacija, FROZEN je ovdje realan → halt-za-review prije koda.)
- **Dodano:** `_PremiumCalendarHeader` (eyebrow `<Mjesec> <god> · N jedinica` + "Kalendar" H1), `_CalendarViewSwitch` (Timeline∣Mjesečni segmented → `context.go(OwnerRoutes.calendarMonth)` — postojeći month screen, NIJE nova feature), `_CalendarGridCard` (legenda + grid u jednom bordered/rounded/soft-shadow surfaceu: `DecoratedBox` border+shadow **IZVAN** `ClipRRect`, grid u `Expanded` → bounded height + scroll/sticky/z-index netaknuti), status legenda → rounded-full **pill badgevi** sa status-tintovima, FAB → solid-primary **krug** + purple glow.
- **`calendar_top_toolbar` token cleanup:** 16 hardcoded hex (`#252530`/`#2D2D3A`/`#F5F5FA`/`#3D3D4A`/`#E8E8F0`/`#F8F8FA`) + `Colors.red.shadeXXX` → `BBColor.of(context)` (surface/surfaceVariant/border/error); mrtvi `isDark` thread izbačen. **0 `Color(0x`** u oba chrome fajla (preostalo = `AppColors.*` named tokeni + `Colors.transparent`/on-accent `white`).
- **Test seam:** `OwnerTimelineCalendarScreen.buildChromeForTest` (`@visibleForTesting` na **WIDGETU** ne State-u → pristupačan iz testa; grid → sized placeholder, provider-free) + `calendar_chrome_responsive_test` (overflow 8 ćelija: 390/768/1440/2560 × light/dark).
- **Verifikacija:** `flutter analyze` 0 · full `flutter test` **~1451 pass** · `build web --no-tree-shake-icons` clean · grep 0-hex · scope = 2 chrome fajla + 1 test (FROZEN fajlovi NISU u diffu). **Live web light+dark** na bookbed-dev (real seed: header "4 JEDINICE", KPI 4%/1/4/29, conflict ⚠5 iz overlapping seeda, grid vizuelno identičan; dark title bright #E2E8F0).
- **Phase 0 dev reset:** obrisan "iOS Test Vila" (`SEED_test_owner_property_01`) + reseed rez_smoke (vraća tap-by-name iz §lean-ledger napomene). ⚠ Gotcha: seed `--delete` briše property doc → async `onPropertyDeleted` cleanup **race-uje** reseed i pobriše units; reseeding **bez** brisanja property doc-a (idempotent merge) ostavlja units.
- **Live-eyeball gotcha:** `flutter run -d chrome … &` + run_in_background = double-background → dev server umre mid-session → asset `ERR_CONNECTION_REFUSED` cascade (lažni "Oops"/ListTile collapse, **NIJE** regresija). Launch via run_in_background SAMO (bez inner `&`). MCP CanvasKit login: klik `flt-semantics-placeholder` → snapshot izloži textbox uid-ove → fill+click.
- **Deferred:** owner PROD deploy (batch s Pregled+Rezervacije, čeka GO); **ListTile asset-fail robustness gap** = zaseban prod PR (assets nedostupni → AI-assistant/empty-state ListTile "leading consumes entire tile width" — prod-relevantno, NE bundlano u timeline); Mjesečni month-cal = vlastiti chrome pass.

---

**Changelog 7.19** (2026-06-15):

### Owner — Rezervacije premium fidelity: lean ledger (handoff RZPLedger) + gate-fix (`420b48ed`)
- Feature-rich card-list + card/table toggle zamijenjen **lean read-only ledgerom** (handoff `rezervacije-premium.jsx` RZPLedger): desktop 7-kolonska grid tabela (Gost/Objekt/Termin/Plaćanje/Iznos/Status/chevron) + tablet/mobile compact redovi (RZPMobileRow), inline payment-progress, status badgevi, count footer. Redovi read-only → tap u detalj. **−2451 net linija** (16 fajlova).
- **Akcije premještene (namjerna workflow promjena):** approve/reject ostaju u pending-queue (gore, netaknut); **complete/cancel rehoman u detalj** (`owner_booking_detail_screen.dart`) da lean redovi ne strand-uju akciju. Gating izdvojen u `detailActionVisibility` (`@visibleForTesting`, konzumiran u `build()`): confirmed-past→Završi, confirmed-upcoming→Otkaži, in-progress→nijedno (samo Poruka/Uredi), pending→approve/reject. Nijedan confirmed nije bez akcije.
- **Novi `bookings_ledger.dart`** (pure + testabilan): `BookingsLedger` + `BookingsLedgerEntry` (normalizuje `OwnerBooking` + iCal evente; imported = read-only `—` cijena/iznos, bez detail rute). Overbooking banner očuvan; Filteri → postojeći dialog; **Sortiraj deferovan/skriven** (windowed sort zavaravajuć — server-sort follow-up). Sync/FAQ token-hygiene (keep layout).
- **Mrtvi kod:** 10 orphan widgeta obrisano (table view, imported list, 7 booking-card dijelova, imported card) + dead `BookingsPremiumLedgerFooter` — repo-wide grep zero importera.
- **Token higijena:** 0 hardcoded boja; 0 raw spacing/radius/fontSize literala u ledger + screen (BB* tokeni + named `_k*` consts). `build web` **mora `--no-tree-shake-icons`** (bb_icon dynamic IconData; CI/deploy parity).
- **Testovi:** `bookings_ledger_responsive_test` (overflow 8 breakpointa × light/dark + empty) + `owner_booking_detail_actions_test` (gate-fix gating, 4 stanja). `flutter analyze` 0 net-new · full `flutter test` **1443 pass** · `build web --no-tree-shake-icons` clean · scope = samo Rezervacije + detail + 2 testa (bez shared/FROZEN).
- **Dev smoke (Android Impeller, Marionette/adb, ref-verified):** gate-fix **4/4 PASS** — Ivan `#BB-SMOKE-02` upcoming→Otkaži · Luka `#BB-SMOKE-03` past→Završi · Marko `#BB-SMOKE-04` in-progress→nijedno · Petra `#BB-SMOKE-01` pending→approve→Potvrđeno end-to-end. Seed `scripts/seed-rezervacije-smoke-dev.js` (20 bookinga + 2 iCal state-matrix; `--delete` wipe). Napomena: dev test-account ima 3 seed generacije s kolidirajućim imenima → tap po unique iznosu + verify detail `#ref`.
- **Deferred:** owner PROD deploy (batchan s Pregled `07a9caf7`, čeka GO); booking detail screen = vlastiti fidelity pass (mješovita higijena — gate-fix dodaci token-clean, ostatak pre-existing literali); live web/iOS phone eyeball.

---

**Changelog 7.18** (2026-06-15):

### Owner — Pregled (Dashboard) premium fidelity + hero chart + responsive harden (`07a9caf7`)
- Pregled je već bio na premium design sistemu (audit/124); ovaj rad ga dovodi na **handoff fidelity** + dodaje labeled chart, uz potpunu token-higijenu. Single atomic commit (`dashboard_overview_tab.dart` + novi responsive test).
- **Hero chart:** sparkline → labeled revenue chart — date/week x-osa (LinearScale `formatter` + `tickCount`) + €-osa; popravlja staru index-only osu (0,1,2 → datumi/sedmice). Single-series; prev-period ghost linija + legenda **deferred** (treba provider serija).
- **Fidelity vs handoff:** occupancy row→**centrirana kolona**; KPI **delta chipovi** (spark-derived) + 4-across/2×2; deposits inline "/ €expected", bez icon-boxa; channels plain donut header (bez tint-boxa); hero **1.85fr** / arrivals **1.4fr** grid; panel padding + uniform gap ritam.
- **Token higijena:** 0 hardcoded boja (mint → `rd.mintWidget`); **0 raw spacing/font/radius literala** (BB* tokeni + named in-file `_k*` consts; izbjegnut deprecated `BBSpace.xs2`/`BBRadius.xs2`).
- **Preview chart dedup:** obrisan `_RevenueChart` + mrtvi helperi/importi → preview osa popravljena uzgred.
- **Test harness:** `buildPanelForTest` `@visibleForTesting` seam dijeli živu section-listu (`_pregledPanelChildren`, bez drift-a); overflow matrica mobile→4K × light/dark (8/8). Live seed: `scripts/seed-pregled-premium-dev.js`.
- **Verifikacija:** `flutter analyze` 0 · full `flutter test` **1421 pass** · `build web` clean · grep proofs (0 hex / 0 raw literala) · **live: web (CanvasKit) + iOS/Android (Impeller) + dark** — prave Material Symbols ikone, sane brojevi, occupancy/chart ok na mobilu, iOS safe-area, nula overflowa. FROZEN netaknut.
- **Deferred (sljedeći PR-ovi):** hero prev-period ghost+legenda; occupancy "+8 pp vs prošli mjesec"; header "Izvezi" export; avg-rating realna vrijednost (reviews provider). Van scope-a spazeno live: TrialBanner + login validacija renderuju engleski string (l10n gap).

### Deploy — `scripts/deploy_prod.sh` hardening committed (bilo "pending" u 7.17)
- Finalizovan deploy-hygiene rad iz 7.17: source `.env.production` + **fail-close prazan `SENTRY_DSN`**; build sva 3 surfacea uklj. **admin** (prije izostao); `--no-tree-shake-icons` (bb_icon dynamic IconData); `bookbed-overlay.js` re-copy+verify poslije widget builda; deploy **hosting-only** (bez functions → izbjegava CF IAM-strip). `STRIPE_*` nikad u `--dart-define`.

---

**Changelog 7.17** (2026-06-15):

### Widget — App Check "eternal shimmer" P0 (SHIPPED PROD: `2ee8d838` widget + `9cd2d2de` staging-parity)
- **Root cause** (console-proven + in-browser A/B): `widget_main.dart` `AppCheckInit.activate` → `ReCaptchaV3Provider('placeholder-debug-only')` učitava `www.google.com/recaptcha/api.js` → **CSP-blocked** (nema `www.google.com` u widget `script-src`) → App Check token se nikad ne izda → Firebase SDK gejtuje **I** Firestore listene **I** callable pozive na tom tokenu → **0 firestore + 0 cloudfunctions** → 10s timeout → offline → vječni calendar skeleton. A/B: bez App Check `onSnapshot` 459ms/1 doc; sa App Check 10s/0 doc.
- **Fix:** uklonjen `AppCheckInit.activate` iz sva 3 widget entry-ja (`widget_main.dart` + `_dev` + `_staging`); submit/booking kod netaknut. App Check `enforceAppCheck:false` svuda gdje widget zalazi → bio čista liability na public no-auth surfaceu. `forceLongPolling` zadržan kao embed hardening (NIJE fix — bio no-op za ovaj bug).
- **owner/admin entries (`main.dart`/`admin_main.dart`) ZADRŽAVAJU `AppCheckInit.activate`** (njihov CSP ima `www.google.com`). NE uklanjati.
- **Deploy:** PROD widget na `view.bookbed.io` (`hosting:widget` only); jasko live smoke (fresh isolated): kalendar + €50 cijene + availability render, console **0 errors**, `Listen/channel` → 200, `getUnitAvailability` (eu-west1) → 200. Booking E2E dokazan na dev-u (bank_transfer createBookingAtomic→booking→availability→cleanup).
- **Re-enable App Check kasnije = Option B bundle** (sve zajedno): realni `APP_CHECK_RECAPTCHA_KEY` (`--dart-define`) + `https://www.google.com` u widget CSP (`firebase.json`) + flip enforcement. Guard: CLAUDE.md NIKADA tabela + `.claude/rules/widget.md` + memorija `frozen-calendar-optimized-stream-permission-denied`.

### Deploy hygiene — `scripts/deploy_prod.sh` hardening (working-tree, pending commit)
- Source `.env.production` + **fail-close na prazan `SENTRY_DSN`** (ranije nijedan script nije sourceao DSN → Sentry-blind PROD build); build sva 3 surfacea (owner=`main_prod`, widget, **admin** — admin build je prije FALIO/izostao → admin servirao stale bytes); `--no-tree-shake-icons` (bb_icon dynamic IconData); **`bookbed-overlay.js` cp + verify** poslije widget builda (`-o` prebriše dir → bez ovog iframe scroll regresira); deploy **hosting-only** `:owner,:widget,:admin` (bez functions → izbjegava CF Cloud-Run IAM-strip); restore dev alias na kraju. `STRIPE_SECRET_KEY` nikad u `--dart-define` (server-only).

---

**Changelog 7.16** (2026-06-12):

### Security — audit/125 sweep + SF-084 LOW fix wave (PR #731)
- Dva passa: /vibe-security delta (clean) + full 165+-check re-run (6 agenata, HUGE strategija): **0 CRIT/HIGH/MED novih, 5 LOW**. Dvije agent-tvrdnje ubijene firsthand verifikacijom (migrateTrialStatus auth = false positive; "10 funkcija bez RL" naduvano).
- **SF-084 fixes** (`b37f1eba`): SF-080 extension — units + additional_services create/update trial-gated (kanonski + CG blok, permissive-union mirror; delete = cleanup off-ramp); `widget_secrets.updated_at` request.time bind when-written (mirror F-107-16, zero client change); Firestore-backed rate limits na 4 booking-action callable-a (30/min shared) + 2 admin callable-a (20/min).
- Deferred: uuid moderates → `firebase-admin@14` major (F-107-07/08, vulnerable buf path nekorišten); Node 20→22 prije Oct 2026 EOL.
- Verifikacija: rules emulator 196 pass (+14 ćelija), jest 463/463 (+1), tsc clean; rules dev-deployani. PROD pickup: rules + 6 CF na sljedećem deploy wave-u.

### CI
- **paths-filter v4 regresija**: dependabot v3→v4 bump (`65d2d393`) ruši detect-changes job na svakom PR-u ("Resource not accessible by integration") → heavy skip + coverage cancel kaskada (ista klasa kao #728 "2s infra fail"). Fix: eksplicitni `permissions: pull-requests: read` na job.

---

**Changelog 7.15** (2026-06-11, popodne/veče):

### Security — SF-083 ledger-residual closure wave (audit/123 §4)
- audit/99 + audit/107 apsorbovani u **audit/123 §4 = kanonski open ledger** (izvorni docs obrisani; F-107-17 ubijen kao false positive — rules `matches()` je whole-string).
- CLOSED: F-86-01 (availability exclusive end, t3 live-verified), F-86-02 (CG range bounds + 2 composita; **PROD: indexes PRIJE CF-a**), F-99-03 (user_profiles Stripe mirror), F-99-10 (9× `HttpsError` swap; refgen namjerno bare `Error`), F-99-16 (FCM SW bookingId guard), F-107-10 (region pin), F-107-13 (legacy ical_feeds blok → `false`; 0 docs oba env-a), F-107-16 (full fix: client serverTimestamp + rules bind).
- DEFERRED s nalazom: F-107-14 — signup payload šalje `'role'` (već deny) a registracija radi → mrtvi klijentski write-path; `hasOnly` bi srušio signup dok se ne raščisti.
- Verifikacija: jest 462/462, emulator rules 12/12 suita / 182 pass (+10 ćelija), edge t2/t3 live na novim indexima; dev deploys (5 CF + rules + indexes). SF-082 (sibling): iCal CR-escape + ai_usage delete-reset guard.

### Maintenance
- **Docs prune passovi 5–10**: audit/ 27→6 + docs/ čišćenje (svaki delete verify-then-delete: live Stripe webhook GET, PROD backfill dry-run re-run = 24/24 canonical, trial-gate PR-ovi merged-check, edge suite full live re-run zelen). TODO.md prepisan 641→75 živih linija; CHANGELOG 7.14 konsolidovani unos; CLAUDE_MCP_TOOLS + ICAL_SYNC_ARCHITECTURE penzionisani.
- **F-CUT-01 recidiv**: dependabot batch regenerisao lock pod npm 11 → svi CF deployi pali; fix `npx npm@10 install` + trajni guard u TODO.
- **Main-reset incident**: origin/main force-vraćen 8 dana unazad uz branch-switch ispod sesije; oporavak čistim fast-forwardom (21 commit), klasa dokumentovana u parallel-session protokolu.
- **GH Actions štednja** (operator direktiva): batch commits, JEDAN push po radnoj cjelini; lokalna verifikacija (jest/emulator/analyze/dev-smoke) je gate.

---

**Changelog 7.14**: consolidated 2026-05-30 → 2026-06-11 (detalji: CLAUDE.md audit index + git history; 7.04–7.13 nisu dobili zasebne unose):

### Security
- **audit/99 sweep + same-day wave** (2026-05-30/31): F-99-01 bookings `affectedKeys` deny (PR #609) + H-1 returnUrl `new URL()` host-only + 5 MED/LOW fixes, dev-deployed; residual ledger u audit/99 (8 LOW/INFO deliberate deferrals).
- **audit/107 top findings CLOSED** (2026-06-11 verify): F-107-01 widget_secrets `hasOnly` rules + F-107-02 CORS na 5 callables (PR #720), F-107-03 widget CSP; F-101-03 L2 `enforceRateLimit` (Firestore-backed, instance-global) na 3 hot anonimna callable-a + loginLockout/atomicBooking/stripePayment.
- **audit/123 full sweep** (2026-06-11): 165+ checks, 9 agenata + gitleaks history + semgrep + npm audit → 0 CRIT/HIGH novih; same-day fix wave F-123-01 (payment bounds + deposit≤total + throw-on-fee-anomaly), F-123-02 (iCal SUMMARY/DESCRIPTION sanitize), F-123-04 (5MB feed cap), F-123-06/07 (CORS intent + Connect rate limits). SF-081 ledger entry s PROD-pickup checklistom.
- F-92-01 iCal empty-token bypass FULLY CLOSED (data backfill + live verify); F-98-01 legacy ical_feeds stats deny + emulator cells.

### Production
- **PROD cutover** (2026-05-31, audit/102): CFs+regrant 35/35, indexes no-drift, rules+storage smoke 4/4, SF-067 IAM confirmed.

### Features / Design
- **Owner redesign waves**: premium Pregled (hero/radial/AI insight, PR #675-677), purple-chrome retirement 46 fajlova (audit/120), handoff color audit 16 stranica oba theme-a (audit/121) — token root-fix `surfaceDark #121212`, dark lifts, KPI strip handoff order + NOVI GOSTI (`distinctGuests`), arrivals card + desktop grid (`cd108f21`).
- **Admin responsive shell** (audit/122): 260px sidebar ≥1100 / 72px rail 800–1100 / drawer <800 + dashboard breakpoints.

### Maintenance
- **53 open PR-ova riješeno na nulu** (2026-06-11): real work merged (uklj. Jules swarm konsolidacija s atribucijom), security-regresije odbijene s obrazloženjem po klasi.
- **Docs prune 5 pass-ova**: audit/ 149→27 + docs/ 11 superseded fajlova obrisano (sve verificirano prije brisanja; recovery: `git log --diff-filter=D`).
- CI: `validate-firestore-rules` job sada vrti emulator rules suite (159 testova).

---

**Changelog 7.03**: audit/89 F-86-01 closure — CORS allowlist on 8 framework-default callables (SF-062, 2026-05-29):

### Security
- **PR #565 — `cors: getCorsAllowlist()` on 8 framework-default callables (SF-062, P1)**: closes the audit/79 §3 #4 / audit/84 PR #559 carryover. 8 callables left on Firebase Functions v2 reflective-`Origin` default — verified pre-fix on bookbed-dev that `OPTIONS -H "Origin: https://evil.test"` echoed attacker origin back as ACAO. Wired `cors: getCorsAllowlist()` (helper from SF-060) preserving every existing opt. Targets per region:
  - **us-central1**: `createBookingAtomic`, `createStripeCheckoutSession`, `guestCancelBooking` (payment hot-path), `checkSubdomainAvailability`
  - **europe-west1**: `deleteUserAccount`, `recordLoginFailure`, `getLoginLockoutStatus`, `clearLoginAttempts`
- **Test mocks (NOT a regression)**: `test/stripePayment.test.ts` + `test/guestCancelBooking.test.ts` mocked `firebase-functions/params` exposing only `defineSecret` + `defineString`. Pre-fix `onCall(opts, …)` skipped the `Expression` instance-check fast-path (`"cors" in opts === false`); post-fix, the lib hits `opts.cors instanceof params_1.Expression` at module load. Mocks extended with `Expression: class Expression {}` to keep the array path reachable. 387/387 jest + 46/46 rules-jest still green.

### Verification
- `npm run build` → 0 tsc errors
- `npm test` → 19 suites / 387 tests pass
- `npm run test:rules` → 4 suites / 46 tests pass
- Dev deploy + IAM re-grant on both regions per `[[cf-deploy-cors-shape-iam-strip]]`
- 34-cell smoke matrix on bookbed-dev (8 OPTIONS × 3 origins evil/owner/widget + 9 widget-origin cells incl wildcard regex `*.view.bookbed.io` + 1 functional `POST` proving end-to-end callable execution post-CORS gate) → all GREEN. `Vary: Origin, Access-Control-Request-Headers` present on every response.

### Operational notes baked into memory
- **Cloud Run service-name lowercase normalization**: on bookbed-dev, the underlying Cloud Run services for Firebase v2 callables are lowercase (`createbookingatomic`, not `createBookingAtomic`). IAM re-grant loop with camelCase names returned `NOT_FOUND` for all 8 on first attempt. Use `gcloud run services list --region=<r>` to confirm the actual service name before scripting the IAM loop. May or may not hold on PROD — verify before PROD cutover.
- audit/89 §5 "Stale-`node_modules` gotcha": fresh-clone build of `functions/` reported 4 `tsc` errors against `Stripe.Stripe` namespace — `stripe@19.1.0` resolved on-disk vs `^22.2.0` in `package.json`. PR #503 (audit/78) merged the bump + adapt content together; carry-forward node_modules masked it. `npm install` resolves. Symmetric to the `flutter pub get` pub-cache desync trap (CLAUDE.md TOOLING GOTCHA).

### Out of scope (deferred)
- **PROD deploy + IAM re-grant on `rab-booking-248fc`** — manual gate per the same `[[cf-deploy-cors-shape-iam-strip]]` recipe; ~60 s degraded window expected post-cors-shape-flip. Memory `[[f86-01-cors-allowlist-gap-8-callables]]` flips DEV-CLOSED → ✅ post-PROD.

### Refs
- audit/89-f86-01-cors-fix.md
- PR #565 (`fix/f86-01-cors-8-callables`)
- SF-062 (`docs/SECURITY_FIXES.md`)
- memory: `[[f86-01-cors-allowlist-gap-8-callables]]`, `[[oncall-default-cors-reflective]]`, `[[cf-deploy-cors-shape-iam-strip]]`

---

**Changelog 7.02**: audit/84 security sweep — CSP, IP-geo CF, logout wipe, CORS allowlist (2026-05-29):

### Security
- **PR #557 — CSP owner + admin hosting (SF-057, MED)**: restrictive Content-Security-Policy added to owner (`app.bookbed.io`) + admin (`bookbed-admin.web.app`) `firebase.json` blocks. Widget keeps `frame-ancestors *` (embed contract). `worker-src 'self' blob:` included for Flutter CanvasKit. Closes audit/58 M-09 deferred + audit/79 §3 #2 + #6.
- **PR #558 — IP-geo CF + multi-store logout wipe (SF-058 + SF-059, HIGH + MED)**: new `getClientGeolocation` callable (europe-west1) replaces client-side `ipapi.co` + `ipwhois.app` calls on every login/signup; IP never leaves server (F-58c-13 CLOSED). `signOut()` now wipes `sessionStorage` + `localStorage` + cookies + optional `location.reload()` on `kIsWeb` via conditional import (F-58c-14 CLOSED). 3 callsites in `enhanced_auth_provider.dart` API-surface compat.
- **PR #559 — `cors: true` → explicit allowlist (SF-060, MED partial)**: new `functions/src/utils/corsAllowlist.ts` exporting `getCorsAllowlist(): (string | RegExp)[]`; 10 explicit `cors: true` occurrences across 5 files (availability, bookingActions ×4, emailVerification ×3, passwordReset, getClientGeolocation) swapped to `cors: getCorsAllowlist()`. PROD allowlist gates Origin to app/view/admin + canonical `*.web.app` / `*.firebaseapp.com` + tenant `{tenant}.view.bookbed.io` regex. Per-env append via `GCP_PROJECT`. Closes audit/58 F-58-07 partial (framework-default reflective CORS on other callables remains follow-up).

### Out of scope (deferred follow-ups)
- **SF-061 — App Check enforcement on `createStripeCheckoutSession` + `getUnitAvailability`** (audit/79 §3 #1): blocked on client `FirebaseAppCheck.instance.activate(...)` callsite — pub dep loaded but never activated, so verified-rate gate guaranteed 0%. Flipping `enforceAppCheck: true` would block all legit traffic. Prereq: provision reCAPTCHA Enterprise key + add client init per surface, wait 7d for verified-rate stabilization, then flip.
- Broader `cors:` sweep on framework-default callables (audit/79 §3 #4 carryover) — out of SF-060 scope.

### Operational notes baked into memory
- **`cf-deploy-cors-shape-iam-strip`** — Firebase v2 onCall deploy where `cors` flips between `true` and array/RegExp strips Cloud Run `allUsers/invoker` IAM on PROD. ~60s degraded window observed 2026-05-29 15:11–15:13 UTC during SF-060 deploy. Always re-grant post-deploy via `gcloud run services add-iam-policy-binding` loop. PROD recovered green; no failed-booking reports.
- Worktree CF deploys need manual `cp functions/.env*` from main working tree (gitignored, not propagated by `git worktree add`).

### Refs
- audit/84 (full sweep notes), audit/79 §3 (origin findings)
- PR #557, #558, #559 (merged 2026-05-29)
- SF-057, SF-058, SF-059, SF-060, SF-061 deferred (`docs/SECURITY_FIXES.md`)
- `memory/cf-deploy-cors-shape-iam-strip.md`

---

**Changelog 7.01**: PR #515 — Sentry DSN externalized to env var + bookbed-dev redeploy (2026-05-27):

### Security
- **PR #515 — Sentry DSN env-var cherry-pick (LOW)**: hardcoded DSN string removed from `functions/src/sentry.ts` (replaced with `defineString("SENTRY_DSN", {default: ""})`) and `lib/widget_main.dart` + `lib/core/config/environment.dart` (replaced with `String.fromEnvironment('SENTRY_DSN')`). CI workflow `deploy-widget.yml` + 2 deploy scripts now pass `--dart-define=SENTRY_DSN=${SENTRY_DSN}`. Jest mocks for `firebase-functions/params` updated to stub `defineString` alongside existing `defineSecret`. Originally a sibling-branch cherry-pick (Jules-generated `73945333`), bundled to main with the mock fix.
- **bookbed-dev CF redeploy**: `firebase deploy --only functions --project=bookbed-dev` ran post-merge with `functions/.env.bookbed-dev` provisioning `SENTRY_DSN`. Verified end-to-end via `gcloud functions describe getUnitAvailability` (env var bound) + `gcloud logging read` (0 skip-init messages, 5+ `"Sentry initialized for Cloud Functions"` success logs at 06:44Z).
- **3 orphan CFs deleted** on `bookbed-dev`: `clearLoginAttempts`, `getLoginLockoutStatus`, `recordLoginFailure` (europe-west1) — leftover from PR #512 SF-038/048 anon-DoS rewrite that source-removed them but Firebase deploy doesn't auto-delete. Surfaced because `CI=true firebase deploy` is non-interactive. See SF-053.

### Out of scope (follow-up PRs)
- **SF-052** — Sentry lazy init: `sentryDsn.value()` is called at module-load → triggers `params.SENTRY_DSN.value() invoked during function deployment` WARNING + false-positive `"Sentry DSN not provided"` INFO during deploy analysis. Runtime unaffected. Fix: move `.value()` into `withSentry()` wrapper. See SF-052.
- **SF-053** — CF orphan sweep automation: pre-deploy sweep recipe documented; CI guard candidate (`tool/check-cf-orphans.sh`). Run sweep on `rab-booking-248fc` BEFORE next PROD CF deploy. See SF-053.
- **PROD env file NOT yet set**: `functions/.env.rab-booking-248fc` requires `SENTRY_DSN` provisioning BEFORE next PROD CF deploy, else PROD Sentry init silently no-ops (defaults to empty string → `"Sentry DSN not provided"`).

### Refs
- PR #515 (merge `f871cc86`, 2026-05-27)
- SF-052, SF-053 (`docs/SECURITY_FIXES.md`)
- `memory/sentry-cf-deploy-time-value-warning.md`, `memory/firebase-cf-orphan-survival-class.md`

---

**Changelog 7.00**: Security sprint — SF-038 + SF-046..SF-048 + audit/52 F-52-03 re-classification (2026-05-26):

### Security
- **SF-038 — Stripe webhook event.id dedup (HIGH)**: `handleStripeWebhook` now records each `event.id` in `stripe_webhook_events/{eventId}` Firestore doc via transactional `runTransaction`. Re-deliveries (Stripe retry on 5xx) detect `snap.exists` and short-circuit with `{status: "duplicate"}`. 30-day TTL via `expiresAt` field. Closes audit/50 F-50-03 + audit/52 Q11. Operator: set Firestore TTL policy on `expiresAt` post-deploy.
- **SF-046 — App Check audit-only on widget CFs (MED)**: `getUnitAvailability` + `createStripeCheckoutSession` accept `consumeAppCheckToken: true` while `enforceAppCheck: false` — telemetry mode. Full enforcement deferred to follow-up after `RECAPTCHA_SITE_KEY` provisioning + Flutter/web client App Check init.
- **SF-047 — subdomainService auth gate + rate limit (MED)**: `checkSubdomainAvailability` + `generateSubdomainFromName` now require `request.auth` + per-uid `checkRateLimit` (30 calls / 5 min). Originally part of #509 branch tip but dropped by squash-merge; re-included in this PR alongside the CI guard script + workflow step.
- **SF-048 — deleteUserAccount per-uid cooldown (LOW)**: 1 call per 5 min per uid. Prevents accidental double-clicks and concurrent cascade corruption.
- **F-52-03 re-classified P0 → P3 deferred**: Stripe Dashboard `acct_1SIsGkBomKO7vDr0` (bookbed.io live) confirmed 0 subscription products via MCP `list_products`; Flutter call-graph audit confirms 0 consumers of `SubscriptionRepository.createCheckoutSession` outside the repo file itself; `_showUpgradeDialog` is "Pro subscription coming soon!" canary; mobile redirects to `app.bookbed.io` via `url_launcher` (App Store Reader-App pattern). Fail-CLOSED at `stripeSubscription.ts:51` is correct posture. CI guard `scripts/check-no-stray-stripe-ui.sh` enforces reopen triggers (canary text + stray callers). SF-037 → P3 Deferred.

### Out of scope (follow-up PRs)
- **SF-045 / F-50-02 (CRITICAL)** — `loginAttempts/{email}` anon DoS — full refactor (rules lock + new `recordLoginAttempt` callable + Dart `RateLimitService` rewrite + 5 callsite sweep in `enhanced_auth_provider.dart`) deferred to dedicated PR to keep this sprint reviewable.
- **SF-039 (P1)** — `idempotencyKey` sweep on remaining 6 Stripe write calls (`checkout.sessions.create` ×2, `customers.create`, `accounts.create`, `accountLinks.create`, `billingPortal.sessions.create`). Hotfix #508 closed `refunds.create` only.
- **App Check full enforcement** — follow-up after `RECAPTCHA_SITE_KEY` provisioning + client init.

### Refs
- audit/50 (F-50-03), audit/52 (F-52-03 re-class)
- PR #508 (F-52-01 + F-52-02 — merged 2026-05-26)
- PR #509 (audit/52 doc — merged 2026-05-26)

---

**Changelog 6.98**: PR #481 — audit/38 security sprint (role escalation + secrets exfil + price allowlist) (2026-05-26):

### Security
- **F-50-01 — Stripe priceId allowlist**: subscription creation now fail-CLOSED on unknown `priceId`s. Env-var-driven (`ALLOWED_SUBSCRIPTION_PRICE_IDS`); empty env → "Subscription pricing is not configured" rejection. Closes audit/50 F-50-01. See SF-027.
- **Role escalation prevention**: `firestore.rules` now blocks `role`/`isAdmin` self-writes on `users/{uid}` (top-level) update/create. Admin bypass preserved for promotion flows. See SF-028.
- **Stripe `secret_key` exfil migration**: `guestCancelBooking` no longer reads per-owner Stripe secret keys from Firestore. Refunds now route through Connect Direct Charges (platform key + `{stripeAccount: ownerStripeAccountId}` header). Connect account ID sourced from `users/{ownerId}.stripe_account_id` (non-secret). See SF-032.
- **iCal token migration**: `widget_secrets` subcollection now the canonical store for iCal export tokens; `widget_settings` retained as fallback (dual-read pattern). See SF-021 progress.
- **Resend API key removal**: `email_notification_config.resend_api_key` field removed from model and Firestore. CFs read `process.env.RESEND_API_KEY` only (provisioned via `defineSecret('RESEND_API_KEY')`). See SF-033.

### Changed
- `guestCancelBooking` refund path: Connect Direct Charges via platform key (was per-owner secret key) — see SF-032.
- `email_notification_config.dart` model: `resend_api_key` field removed — see SF-033.

### Added (test infrastructure)
- **PR #496**: regression tests for #481 — `functions/test/firestore_rules/users.test.ts` (role escalation, 4 cases, emulator-backed) + `functions/test/guestCancelBooking.test.ts` (Direct Charges refund, 4 cases). Both files were intended to land with #481 but were missed during squash-merge; recovered from local disk and committed post-merge.
- **PR #497**: re-runnable F-50-01 allowlist gate-logic smoke script (`functions/scripts/smoke-allowlist.js`, 4 cases, pure-logic, no Stripe API). Useful for the upcoming prod-env provisioning step.

### Deferred (operator action)
- **PROD env vars NOT yet set**: `ALLOWED_SUBSCRIPTION_PRICE_IDS` and `ICAL_TOKEN_PEPPER` must be provisioned in `functions/.env.rab-booking-248fc` BEFORE CF deploy, else subscription flow fail-CLOSES and iCal export 500s.
- **PROD CF + rules deploy lag**: `deploy-widget.yml` auto-deployed the new widget bundle to PROD on the squash to main, but CF + rules deploy did NOT auto-fire. PROD currently runs new widget code against old CFs + old rules. F-50-01 enforcement, role escalation prevention, and Connect Direct Charges refund are **NOT yet live on PROD**. Operator action required per hard rule #3 (CF → widget → rules order — already partially violated by the widget auto-trigger).

---

**Changelog 6.97**: audit/40 — FINDING-iOS-02 root cause + seed field-name fix (worktree, NOT pushed) (2026-05-24):

- **audit/40 written** (`audit/40-finding-ios-02-investigation.md`, ~14 KB, 6 sections + 2 appendices). Renumbered from audit/38 to avoid collision with the pre-existing `audit/38-pr462-env-prereq.md` (different topic — Stripe env vars). Worktree-only commit on `investigate/finding-ios-02` (commits `7eda87d4` → `97f31f38` → `4b087b09`), NOT pushed.
- **Root cause identified at the Firestore boundary, not in code.** Owner Rezervacije list rendered empty on the iOS marionette smoke (audit/36 §D3, FINDING-iOS-02) despite the drawer pending-count badge correctly showing 1+. Both queries share `collectionGroup('bookings').where('owner_id', '==', UID).where('status', '==', 'pending')` — the only divergence is a single `.orderBy('check_in', asc)` clause on the list path (`firebase_owner_bookings_repository.dart:1263` for pending in "All" filter, plus three non-pending branches). Firestore evaluates `orderBy(field)` by **excluding documents that lack the field** — the seeded docs were written with the wrong field names `check_in_date`/`check_out_date` (Timestamps with the wrong key), so the orderBy silently filtered them all out. Badge stream omits orderBy → still matched via where clauses alone.
- **Hypotheses ruled out** (per audit/36 FINDING-iOS-02 diagnosis hints): provider_id requirement, payment_status filter, stale `keepAlive: true` Riverpod cache, "selected property" context, T11c subcollection migration, legacy top-level `/bookings` path. None of those candidates ran a divergent query — the list query simply returned 0 docs at the Firestore level before any client filtering. Cross-platform, NOT iOS-specific.
- **Bonus**: audit/36 §D6 "Nedavne Aktivnosti populates with seed booking after swipe-down" was a misobservation. `recentOwnerBookings` routes through the same `_getOwnerBookingsPaginatedAllStatuses` → `orderBy('check_in', asc)` on all four status sub-queries — all returned 0 against the broken seed data (verified via Query E mirror script). `RecentActivityWidget` has no fallback content (empty state on `activities.isEmpty`).
- **Test-env side effect (resolved by same fix)**: `atomicBooking.ts:743-744` overlap-detection query is `.where('check_in', '<', X).where('check_out', '>', Y)`. Against the broken seed docs it also returned 0 — so duplicate-overlap bookings could currently slip through on the affected test owner until backfill landed. Production unaffected (canonical writes via `atomicBooking.ts:1088-1089` always use `check_in`).
- **Fix branch `fix/seed-checkin-field-name`** (worktree-only, commits `be93449a` → `82b709b2`, NOT pushed):
  - `scripts/seed-bookbed-dev.js:129-130`: 2-line rename `check_in_date`/`check_out_date` → `check_in`/`check_out` (Timestamp value unchanged).
  - `audit/migrations/40-backfill-checkin-field.js` (new, ~110 lines): idempotent rename-keys-in-place backfill. Dry-run default, `--apply` commits. Refuses to run against `rab-booking-248fc` (project-id guard — prod data already canonical). Only updates docs with `check_in_date` AND lacking `check_in`, so re-runnable; same pattern available for bookbed-staging onboarding.
- **Backfill applied to bookbed-dev**: dry-run 5 docs targeted (4 test-owner + 1 `SEED_property_dev_01`); `--apply` wrote 5 docs in 1 batch. Post-fix live query: Query C (list pending) 0 → **1**; `_getOwnerBookingsPaginatedAllStatuses` mirror (covers `recentOwnerBookings`): pending=1, confirmed=1, completed=2, cancelled=0 → **4 total**. List + badge + Nedavne Aktivnosti now reconcile.
- **P3 follow-up logged in §5 (separate PR)**: cosmetic `.name` → `.value` normalization at `firebase_owner_bookings_repository.dart:1107` (`BookingStatus.pending.name`). Same string today but a future-proofing footgun if a status is added whose Dart enum name diverges from its declared `.value`.
- **Defensive `orderBy` fallback explicitly out of scope**: would entrench non-canonical schema in queryable behavior — same drift class that let the original seed bug persist undetected. Wording softened from "explicitly rejected" → "out of scope" to leave room for unrelated revisits (e.g. migration-window dual-write).
- **iOS smoke (audit/36 §D3 resume) ready** — once `fix/seed-checkin-field-name` is pushed/merged + plist swapped to dev variant, repro should show 4 booking entries.
- **NOT pushed**: both `investigate/finding-ios-02` (audit doc) and `fix/seed-checkin-field-name` (code + migration) are isolated worktree branches awaiting operator review/push decision.

---

**Changelog 6.96**: audit/38 — PR #462 env prereq verification + operator helper script (2026-05-24):

- **audit/38 written** (`audit/38-pr462-env-prereq.md`, ~9 KB with appendix). Verifies that PR #462's deny-all-on-empty allowlist consumer (`functions/src/stripeSubscription.ts:43-58`) will break post-merge CF deploy unless operator first sets `ALLOWED_SUBSCRIPTION_PRICE_IDS` per-env. State on `main` 2026-05-24:
  - `functions/.env:13` → `ALLOWED_SUBSCRIPTION_PRICE_IDS=` (empty placeholder from 2026-05-21 widget-secrets-exfil setup; confirmed via `grep -n`).
  - `functions/.env.bookbed-dev` → does NOT exist; no per-env override on dev.
  - `functions/.env.rab-booking-248fc` → key absent; falls through to empty `.env`.
  - **Prod CF env binding** confirms deployed state: `gcloud functions describe createSubscriptionCheckoutSession --project=rab-booking-248fc --region=us-central1 --format="value(serviceConfig.environmentVariables)"` returns `ALLOWED_SUBSCRIPTION_PRICE_IDS=` (empty value already in prod CF env from 2026-05-21 deploy). Pre-PR-#462 code accepted any priceId so empty did no harm; post-PR-#462 code rejects everything when empty → outage on first checkout.
- **PR #462 description corrected** via `gh pr edit 462 --body-file`. Replaced false "should already be set on both" claim with verified 2026-05-24 state + audit/38 link + explicit operator BLOCKER. Strengthened Test plan checkbox: "**BLOCKER — Operator** Create Stripe Prices (test mode + live mode) → populate `.env.bookbed-dev` + `.env.rab-booking-248fc` + clear empty `.env` default."
- **Memory updated** (`memory/widget-secrets-exfil-deploy-prereqs.md`) — appended 2026-05-24 verification section invalidating earlier "acceptable for dev where subscriptions aren't tested" stance. PR #462 turns the empty placeholder into an active outage on first checkout, regardless of whether dev tests subscriptions.
- **Appendix audit on remaining 2 widget-secrets-exfil env items:**
  - `RESEND_API_KEY` → ✅ ALREADY set on both. Dev: secret version 3 bound to `createBookingAtomic` (and 13 other CFs). Prod: secret version 2 bound. Verified via `gcloud functions describe createBookingAtomic --format="value(serviceConfig.secretEnvironmentVariables)"`. Not a PR #462 blocker.
  - `ICAL_TOKEN_PEPPER` → consumer not yet on main (lives on unmerged `hotfix/widget-secrets-exfil`). Not a PR #462 blocker; will become a blocker when widget-secrets-exfil merges.
- **`tool/setup-pr462-env.sh` (new, ~220 lines)** — operator helper script. Defensive bash 3+ (macOS compatible). Prompts for test+live Price IDs (comma-separated), validates `price_*` format via regex, detects cross-account contamination (test ID in live list → abort), creates `.env.bookbed-dev`, updates `.env.rab-booking-248fc` (idempotent — replaces existing `ALLOWED_*` line), comments out empty default in `.env`, writes `.bak` backups, prints next-step deploy + smoke + rollback commands. Bash syntax verified (`bash -n`).
- **`.claude/rules/stripe.md` augmented** — new "Subscription Flow" section at bottom covers `ALLOWED_SUBSCRIPTION_PRICE_IDS` per-env setup, no-cross-mode warning, helper script reference, region drift caveat (us-central1 default vs europe-west1 norm — P3 `audit/24`).
- **Extra finding (logged)** — prod `createSubscriptionCheckoutSession` runs in `us-central1`, not `europe-west1`, because `stripeSubscription.ts` does not declare a region (uses firebase-functions v2 default). Region drift, out of PR #462 scope. Cross-referenced in `audit/38` Appendix + `.claude/rules/stripe.md` Subscription Flow section.
- **PR #462 gate verification** (worktree `/private/tmp/bb-hotfix-g`): `npm run build` → 0 errors. `npm run test:rules` → 30/30 (incl. 6 new role-field tests). `npm test` → 161/165 (4 failures all in `stripeConnect.test.ts`, pre-existing on main, message-string mismatches not regressions). `flutter analyze` → No issues found. Only env BLOCKER + Actions billing remain.
- **Operator next step** — `tool/setup-pr462-env.sh` (after creating Stripe subscription products in test + live Dashboards). Subscription products NOT yet configured per operator report 2026-05-24.

---

**Changelog 6.95**: audit/34 §5 fix — `emails_sent.*` parity on booking create (PR #472) (2026-05-24):

- **PR #472 opened** (`fix/audit-34-emails-sent-create-tracking`, base `main`, commit `3d74240d`). Closes audit/34 §5: `createBookingAtomic` sends 4 initial emails on the create path but wrote ZERO `emails_sent.*` keys. After this PR, all 4 keys (`pending_request`, `pending_owner_notification`, `confirmation`, `owner_notification`) are persisted on the booking doc with `{sent_at, email, booking_id, provider_id}`. `provider_id: null` for now — `sendEmailWithRetry` returns `Promise<void>` on main; PR-B (`fix/audit-26-prb-provider-id`, commit `2b951623`, audit/26 §5) will flip these to real Resend ids once it lands.
- **Premise correction (logged in PR body + memory).** Original audit/34 §5 fix recipe assumed `onBookingCreated` trigger sends the emails. It does not — `bookingManagement.ts:209-218` explicitly delegates initial emails to `atomicBooking.ts` ("DO NOT send duplicate emails here"). Real send sites: `atomicBooking.ts:1248-1399` (4 `sendEmailWithRetry` wrappers). Fix moved to where the sends actually live; user confirmed via question prompt (atomicBooking.ts / `provider_id: null` / all 4 sites).
- **Implementation**: new `persistEmailSent()` helper in `utils/bookingHelpers.ts` — read-checks injected `existing` snapshot (idempotency parity with canonical `onBookingStatusChange` pattern at `bookingManagement.ts:283`), swallows write errors (tracking failures must NOT break booking flow). One cached `bookingRef.get()` at top of email try-block, 4 `persistEmailSent()` calls after each `logSuccess`. `EmailSent` interface extended with optional `provider_id`; `BookingEmailTracking` gains `pending_owner_notification` + `owner_notification` keys.
- **Tests**: 2 new in `atomicBooking.test.ts` covering all 4 keys with `provider_id: null` assertion (pending flow asserts `pending_request` + `pending_owner_notification`; auto-confirmed flow asserts `confirmation` + `owner_notification`). Existing happy-path mock chain extended by 1 `mockResolvedValueOnce({data:()=>({})})` slot for the new `bookingRef.get()`. Result: `npm run build` clean, `npm test` 163 pass + 4 pre-existing `stripeConnect` failures (unrelated, expected per brief), `npm run test:rules` 24/24.
- **Diff stat**: 3 files, +221/-2 — `utils/bookingHelpers.ts` (+44), `atomicBooking.ts` (+51 — cached snapshot + 4 site writes), `test/atomicBooking.test.ts` (+128).
- **Scope NOT covered**: Stripe-paid path (`stripePayment.ts:~1300`) emits `confirmation` + `owner_notification` from the webhook handler, NOT from the callable. Same observability gap, different trigger. Tracked separately. Also `provider_id` capture itself — see PR-B (audit/26 §5).
- **Brief's "trigger retry idempotency" framing inapplicable**: callables don't auto-retry like Firestore triggers do. The read-before-write check is kept as (a) parity with the canonical status-change pattern, (b) double-submit guard, (c) defense-in-depth if a future change reroutes these sends through a real trigger. Documented in PR body.
- **Memory**: `onbookingcreated-no-email-tracking.md` updated with premise correction + PR #472 reference; cross-link to audit/26 §5 PR-B.

---

**Changelog 6.94**: audit/32 N1 fix — widget locale wiring (PR #471) (2026-05-24):

- **PR #471** (`fix/audit-32-widget-locale-wiring`, commit `efab0bdc`) closes audit/32 N1 partial: widget month-header (`MonthCalendarWidget`) + date-range pill (`CompactPillSummary`) rendered EN in HR mode despite `?lang=hr` switch.
- **Root cause:** two parallel locale bugs.
  1. All 3 widget entry points (`lib/widget_main.dart` + `_dev` + `_staging`) built `MaterialApp.router` without `locale:` / `supportedLocales:` / `localizationsDelegates:`. `languageProvider` (`lib/features/widget/presentation/providers/language_provider.dart:22`) parsed `?lang=` correctly, but `Localizations.localeOf(context)` read MaterialApp's locale (default `en_US`) — so `month_calendar_widget.dart:215` `DateFormat.yMMM(locale.toString())` ignored the URL switch.
  2. `compact_pill_summary._DateRangeSection._dateFormat` was `static final DateFormat('MMM dd, yyyy')`. `DateFormat` captures locale at construction (intl: `_locale = canonicalizedLocale(locale ?? Intl.defaultLocale ?? systemLocale)`); static field → evaluated once at class load → locale locked to system EN forever, even after `Intl.defaultLocale` changed.
- **Fix:** 3 entry points wire `locale: Locale(ref.watch(languageProvider))` + `supportedLocales: [hr, en, de, it]` + `GlobalMaterialLocalizations` delegates. `_DateRangeSection._formatDate()` constructs per call with explicit `translations.locale.languageCode`.
- **Test churn:** `compact_pill_summary_test.dart` + `pill_bar_content_test.dart` add `setUpAll(() async => await initializeDateFormatting())` — production `main()` does this; bare flutter_test does not, so per-call `DateFormat(pattern, localeCode)` throws `LocaleDataException` without the symbols loaded.
- **Verification:** `flutter analyze` repo-wide 0 issues; 8/8 compact_pill tests + pill_bar tests green. Pre-existing failures in `test/features/widget/data/helpers/availability_checker_test.dart`, `booking_price_calculator_test.dart`, `firebase_booking_calendar_repository_test.dart` reproduce on `main@ae1b18f3` — unrelated, out of scope.
- **Out of scope (follow-up sweep):** same `DateFormat(pattern)` no-locale class at `payment_info_card.dart:245`, `booking_summary_card.dart:148/159`, `year_calendar_widget.dart:414`. Filed in PR body.
- **Memory:** [dateformat-static-locale-trap.md](../) added — `static final _fmt = DateFormat(...)` is a footgun; Intl.defaultLocale doesn't propagate.
- **Audit/32 status:** doc itself lives only on `doc/audit-32-smoke-h` (PR #464, not yet merged to main); CLAUDE.md references it but file is not on main. N1 finding now structurally fixed regardless of doc-merge status.

---

**Changelog 6.93**: 5 audit doc PRs (#464/#465/#466/#468/#469) pushed + main pushed; CI BLOCKED on GitHub Actions billing (2026-05-24):

- **5 doc-only PRs opened + pushed** for audit/32/34/35/36/37 smoke reports. Branches: `doc/audit-32-smoke-h` (PR #464 — TIER 4 widget UI smoke), `doc/audit-34-lifecycle-smoke` (PR #465 — booking lifecycle E2E BB+CC), `doc/audit-35-auth-smoke` (PR #466 — auth flows register/verify/reset), `doc/audit-36-ios-smoke` (PR #468 — iOS owner marionette), `doc/audit-37-admin-smoke` (PR #469 — Admin Dashboard pre-check + DEV probe). All 5 carry `documentation` label. PR #467 (`fix/audit-33-admin-dev`) noted as dependency in audit/37 body.
- **`main` pushed** (`8aa0940a..31d504b5`) — 5 local commits flushed to origin. Breaks the "operator-gated push" convention from 6.91 §51 (operator-approved via /effort=max prompt). Commits included: CLAUDE.md index entries for audit/32/34/35/36/37/38/39, version bumps 7.7→7.9, audit/35 F-Auth-D1/D2 closure note (6.91), audit/38 PR #462 env prereq doc, audit/39 Flutter Engine keyboard converter (6.92).
- **CI BLOCKED — GitHub Actions billing failure.** All 5 PRs returned `conclusion: FAILURE` within 1-3 s on 3 jobs (`Run Tests`, `Test Cloud Functions`, `Validate Firestore Rules`) with annotation: *"The job was not started because recent account payments have failed or your spending limit needs to be increased."* Build/coverage/bundle-size jobs `SKIPPED` as dependents. PR #468 has no run yet — will trigger after billing unblocks. Operator action required outside Claude scope: GitHub → org settings → **Billing & plans** → resolve failed payment OR raise Actions spending limit. Re-run via `gh run rerun <id>` for runs `26356860746` (#464) + equivalents on #465/#466/#469; #468 auto-triggers.
- **State at handoff**: working tree clean (`.mcp.json` + `jest_dx/` pre-existing untracked, out of scope). Memory updates landed (marionette-ios-gotchas, dev-hosting-prod-bundling-class, prod-auth-smoke, onbookingcreated-no-email-tracking). Safe to clear chat — all persisted (GitHub PRs + local commits + memory).

---

**Changelog 6.92**: audit/39 — N4 root cause investigation (Flutter Engine keyboard converter) (2026-05-24):

- **audit/39 written** (`audit/39-n4-flutter-keyboard-converter-2026-05-24.md`). Closes audit/33 §4.4 N4 (`Cannot read properties of null (reading 'toString')` on owner login page) as **SAFETY-CLAUSE NO-FIX**: trace is 100% Flutter Engine framework code, not BookBed.
- **Reproduction**: load `https://bookbed-owner-dev.web.app/` in Chrome + hook `window.onerror` + dispatch synthetic keystroke via DevTools `Input.dispatchKeyEvent` (`chrome-devtools type_text` in this run). Crash fires during text-input handling; characters do NOT land in the focused field (CanvasKit input bridge crashes pre-forward), so fields stay at placeholder — error is observable only via console hook, no visible UI symptom.
- **Stack trace**: leaf at `main.dart.js:63315:3` (`bax.$0`), full 10-frame call stack documented in audit/39 §4 (all `bav.*` / `bas`/`bat` keyup-keydown / `nv.bi` HashMap.forEach — pure Flutter Engine).
- **Source line read** direct from deployed bundle (`main.dart.js:63310-63315`): `lookupTable[event.key]?[event.location]!` (dart2js emits `q.toString` for the `!` null-assertion). When `(event.key, event.location)` tuple's row has no entry at that location index, `q==null` and JS throws `TypeError: Cannot read properties of null (reading 'toString')`.
- **Upstream**: pattern lives at `flutter/lib/web_ui/lib/src/engine/keyboard_binding.dart` + `key_map.g.dart` (`kWebToLogicalKey`). Real keyboards always set `event.location` correctly (0..3); synthetic inputs from DevTools automation / extensions / autofill heuristics / virtual keyboards can dispatch unusual values that miss the lookup. No upstream fix yet identified; audit/39 §8 ranks mitigations (do-nothing → upstream-watch → SDK upgrade → wrap-listener-last-resort).
- **CHANGELOG 6.68 pattern does NOT apply.** That fix coerced `Uri(queryParameters: {nullable: x})` in widget `booking_view_screen.dart`. Memory `flutter-web-uri-null-tostring.md` already warned not to conflate login-submit crashes with the Uri pattern — substantiated. `grep -rn "queryParameters" lib/features/auth/` → 0 results.
- **Bonus finding (audit/39 §9)** — service-worker stale-bundle long-tail on audit/33 N1: first probe of the (already-fixed) dev hosting returned `firebase_core.getApps()[0].options.projectId === "rab-booking-248fc"` (PROD); after explicit SW unregister + `caches.delete()` + `indexedDB.deleteDatabase()` + reload → `projectId === "bookbed-dev"`. Audit/33 deploy fix IS live, but past visitors keep writing to PROD until their SW updates. Doc-only follow-up recommended (audit/33 §6.1 note + `.claude/rules/hosting-build.md` SW-cache note).
- **Trigger mismatch caveat**: audit/33 §4.4 claimed "initial load BEFORE login attempt" but captured no stack trace, only message text — that attribution is unverified to match this investigation's synthetic-input repro. Documented in audit/39 §2; do not assume full closure beyond what the stack trace shows.
- **Deliverables**: 1 audit/39 doc-only file. Zero BookBed code change. Zero PR. Tasks 1+2+3+4 completed; task 5 ("apply fix + PR") deleted per safety clause.

---

**Changelog 6.91**: audit/33 deploy contamination fix merged + audit/37 admin smoke gap + admin DEV extension (2026-05-24):

- **audit/33 merged to main** (merge commit `ae1b18f3`, FF + non-FF). Two upstream branches landed: `doc/audit-33-owner-smoke` (commits `e21e28eb` + `9a2e566e`) ships the smoke report itself, and `fix/audit-33-deploy-contamination` (commit `b1b22344`) ships the 3-part structural fix. Net contents now on main:
  - `audit/33-owner-dashboard-web-smoke-2026-05-24.md` (387 lines) — P1 finding F-OwnerDashboard-001: `bookbed-owner-dev.web.app` was deploying builds with PROD `firebase_options.dart` bundled → Firestore writes silently landed in `rab-booking-248fc` instead of `bookbed-dev`. Auth attempt during smoke triggered 2 unintended PROD writes (`/Write/channel`) before halt.
  - `lib/owner_main_dev.dart` augmented — `EnvironmentConfig.setEnvironment(Environment.development)` + `kDebugMode` project-ID assert (mirrors `widget_main_dev.dart` pattern; crashes on boot if PROD bundled).
  - `.claude/rules/hosting-build.md` rewritten Build commands block — per-env table (DEV/STAGING/PROD × owner/widget/admin), entry-point matrix, explicit "NIKADA NE BUILDAJ `--target lib/main.dart` ZA DEV/STAGING" footgun, post-deploy verification recipe (DevTools Network → confirm Firestore project ID).
  - `tool/deploy-dev.sh` (new, 142 lines) — manual deploy wrapper for owner + widget DEV. Build-time contamination guard: `grep firebase_options_dev "$ENTRY"` refuses to deploy if entry imports wrong options. Mirrors `deploy-widget.yml` CI for widget overlay/embed copy. Reminds operator to verify project ID in DevTools post-deploy.

- **audit/37 admin smoke** — committed to `doc/audit-37-admin-smoke` (commits `877cddad` → `7bd49d73` → `fd2b14db`), **NOT yet merged**. 3 sections of findings:
  - §3 #E1 + theme observation: PROD admin login renders; smoke blocked at #E1 because no admin Firebase custom-claim account exists in memory.
  - §4b DEV admin probe (post-Path C precheck): `bookbed-admin-dev.web.app` site exists per `firebase hosting:sites:list` but serves a **stale build** (pre-Jan-26 — title "BookBed Admin"/"Login" vs current source "Welcome Back"/"Sign In"). PROD admin shows `© 2024` footer despite source using `DateTime.now().year` since `bd329688` (2026-05-22) → PROD build also stale.
  - §6 Path C: redeployment + admin claim provisioning recipe. Originally would have re-introduced the audit/33 contamination on the admin surface — see admin-DEV-extension bullet below.
  - `.claude/rules/admin.md` augmented on the same branch: per-env hosting table (PROD/DEV/STAGING URL → site → project), deploy commands, stale-build hazard callout, audit/30 `isAdminFromFirestore()` Firestore-role escape note + PR #462 mitigation reference, smoke-account requirements.

- **admin DEV extension** — committed to `fix/audit-33-admin-dev` (commit `2f7189e9`), **NOT yet merged**. Closes the audit/37 → audit/33 chained dependency:
  - `lib/admin_main_dev.dart` (new) — mirrors `owner_main_dev.dart` env-assert pattern: `EnvironmentConfig.setEnvironment(Environment.development)` + `kDebugMode` project-ID assert + `DevFirebaseOptions`. Title `BookBed Admin (Dev)`, locale hr, themeMode dark (parallel to `admin_main_staging.dart`).
  - `tool/deploy-dev.sh` — admin case now wired alongside owner + widget. Same build-time contamination guard. Header + usage + case-block updated.
  - `.claude/rules/hosting-build.md` — Dart entrypoints table row "admin DEV: MISSING (TODO)" replaced with `lib/admin_main_dev.dart`. Resolved-footgun note cross-references audit/37.
  - Operator can now run `tool/deploy-dev.sh admin` to safely refresh `bookbed-admin-dev.web.app`. Required prerequisite before re-running audit/37 #E1–#E6 against the DEV admin URL.

- **Coverage delta** — main now reflects audit/33 P1 resolution. Admin surface contamination class (same root cause, different hosting target) tracked but unmerged. audit/37 Path C re-run gated on: (1) merge `fix/audit-33-admin-dev`, (2) run `tool/deploy-dev.sh admin`, (3) verify Firestore project ID in DevTools, (4) provision admin custom claim on `bookbed-dev`.

- **audit/35 follow-up — PR #470 opened** (`fix/audit-35-displayname-cooldown`, commit `bad97caa`, pushed to origin). Closes F-Auth-D1 + F-Auth-D2 from the auth-flows smoke:
  - **F-Auth-D1 (MED) — displayName digit-strip.** `lib/shared/utils/validators/input_sanitizer.dart` `sanitizeName()` allow-list regex `[^\p{L}\s'\-]` → `[^\p{L}\p{N}\s'\-]`. Names with embedded/trailing digits (audit example: "BB Smoke C1") now persist verbatim. Defence-in-depth unchanged: `_htmlTagPattern` strips HTML, `_controlCharPattern` strips control chars, and `containsDangerousContent()` detector still flags XSS/SQLi separately. Injection chars (`< > ; / \ " = ( ) { } & $` etc.) are still removed by the allow-list. Side-effect: `lib/features/widget/domain/use_cases/submit_booking_use_case.dart:117` (widget guest name) also keeps digits — desirable (apartment numbers etc.).
  - **F-Auth-D2 (LOW) — cooldown drift correction.** UI value in `email_verification_screen.dart` (`_startInitialCooldown`/`_startCooldown`) is and always was 60 s (matches Firebase Auth `sendEmailVerification()` internal rate-limit window). CHANGELOG 6.44 text "30-second initial cooldown" corrected to "60-second" with explicit audit/35 footnote (no code change).
  - **Tests:** 52/52 green in `test/shared/utils/validators/input_sanitizer_test.dart`. Added 2 regression tests (`preserves digits in name`, `preserves Unicode digits across scripts`); updated 1 stale assertion (`removes script tags but preserves letters` → `…letters/digits`; input `John<script>alert(1)</script>Doe` now yields `Johnalert1Doe` rather than `JohnalertDoe`).
  - **Verify:** `flutter analyze` on touched files = 0; repo baseline 1449 pre-existing untouched.

- **No pushes** for audit/33 + audit/37 + admin-DEV work above. All 5 new commits (`ae1b18f3`, `2f7189e9`, `877cddad`, `7bd49d73`, `fd2b14db`) local-only per task convention. audit/35 follow-up PR #470 IS pushed (operator-requested).

---

**Changelog 6.90**: CLAUDE.md index backfill + audit/28 supersede note — Terminal F doc-refresh recovery (2026-05-24):

- **CLAUDE.md index — audit/27 line added** (audit/27 doc landed in commit `dffaa0e3` 2026-05-23 but index entry was missed). Bundle deferred from 6.89 per its bullet "CLAUDE.md index update bundled separately to avoid colliding with concurrent agent's audit/27 entry + audit/28 A2 supersede annotation". Slot 27 → audit/27-bb-e2e-cc-reject.md.
- **audit/28 §3.4 added — Option A landed via PR #462** — dormant-5 deletion (5 templates + 5 emailService.ts wrappers + 5 email/index.ts exports) is in `hotfix/role-escalation-deploy-unblock` (Terminal G atomic multi-fix). Verified `gh pr diff 462 --name-only`: all 5 dormant template files present. Terminal F's draft branch `chore/delete-dormant-5-email-templates` (commit `0e49f254`, never pushed) dropped via `git branch -D`. PR-B scope shrinks 18 → 13 templates. tsc + Jest verification (161/4, 4 pre-existing-on-main in `stripeConnect.test.ts`) preserved in `memory/dormant-5-email-templates.md`.
- **audit/28 §1 exec summary annotated** — A2 row now shows "resolved via PR #462" with §3.4 ref.
- **Multi-agent race §5/§6 — working-tree race** (uncommitted edit loss) — distinct from the §1-§4 commit-time class. Race fires BEFORE `git add` is reached, during plain edit-then-think pause; another agent's `git checkout` discards uncommitted working-tree edits. Triple-guard pattern protects commits but NOT plain edits. **Mitigation: `/tmp/bb-<task>` worktree-by-default for multi-agent sessions.** Doc recovery this commit used `git worktree add -b docs-refresh-tmp /tmp/bb-docs origin/main` — isolated from OG repo's working tree; zero risk to other agents' WIP. Pattern memorialized as §5/§6 in `memory/multi-agent-git-race.md`.
- **Memory updated** — `memory/dormant-5-email-templates.md` "Delete-safety verified" section retained (memory dir is outside repo, race-immune). `memory/multi-agent-git-race.md` §5/§6 entry added with worktree mitigation pattern.

---

**Changelog 6.89**: iCal export cache invalidation — PR #461 (2026-05-24):

- **PR #461 opened** (`fix/ical-cache-invalidation`, commits `b71fa0e8` + `6a00abbf`) — resolves `widget_settings.ical_cache_*` 5-min TTL stale-feed problem. `icalExport.ts:318-324` wrote 4 cache fields with no flush trigger; owner pulling feed URL within 5 min after a booking change saw stale data. Helper `invalidateIcalCache(propertyId, unitId)` at `functions/src/utils/icalCache.ts` deletes all 4 cache fields with `FieldValue.delete()`. Non-fatal: NOT_FOUND swallowed for units without `widget_settings`; any other error logged as `logWarn` and ignored — next feed read regenerates regardless.
- **4 call sites wired** — `atomicBooking.createBookingAtomic` (synchronous pre-return flush, closes async-trigger lag window before client polls); `onBookingCreated` (every fire, covers Stripe-instant early-return path); `onBookingStatusChange` extended gate fires on `before.status !== after.status` OR `toMillisOrZero(check_in/check_out)` diff (covers owner calendar drag-edits that preserve status). `autoCancelExpiredBookings` schedule cascades via `onBookingStatusChange`. Self-retriggers (`access_token`, `emails_sent.*`, `booking_reference` auto-heal) preserve both status + dates so no write storm.
- **Deferred — `icalSync.ts` external-import path** — `syncSingleFeed` writes `ical_events` docs that appear in feed but no invalidation. Concurrent agent has uncommitted `audit/31` SSRF + log-leak edits on the same file; folding mine = staging confusion. **Low value in isolation:** the only consumer affected is another aggregator polling the BookBed export, and per Critical Learning #7 most aggregators also poll ≥15 min so 5-min lag is invisible. Follow-up ~5 lines after `insertNewEventsWithEchoDetection` at `:386-388`, lands post-audit/31.
- **Multi-agent race recurrence (4th this session class)** — branch silently swapped TWICE during PR #461 work: once during `utils/icalCache.ts` Write (landed on main as untracked, moved to `/tmp` + restored on fix branch), once recovered via `[ "$(git branch --show-current)" = "fix/..." ] || exit 1` guard. New nuance: **file-Write tools race the same way `git add` does** — destination branch can swap between read-current-state and write-new-content. `memory/multi-agent-git-race.md` pattern reinforced.
- **Verification** — `npx tsc --noEmit` clean across 3 changed files; `npx eslint` 0 new violations (pre-existing 166 errors all legacy); `npx jest test/bookingManagement.test.ts` 4/4 pass; dart format hook green both commits. Manual smoke deferred to post-merge dev deploy (curl feed URL within 30s of create/status-flip/date-edit).
- **audit/30 added** ([`audit/30-ical-cache-invalidation.md`](../audit/30-ical-cache-invalidation.md)) — full rationale, coverage matrix, self-retrigger isolation analysis, deferred scope reasoning, race recovery notes. Slots 29 + 30 were free pre-write (29 originally taken by parallel-session security-audit file later renamed to 31).
- **Memory updated** — `memory/ical-cache-no-invalidation.md` marked SHIPPED with PR #461 ref + coverage table + open-scope notes. CLAUDE.md index update bundled separately to avoid colliding with concurrent agent's audit/27 entry + audit/28 A2 supersede annotation.

---

**Changelog 6.88**: Tier 4 Resend + Sentry baseline — audit/28 static + handoff (2026-05-23):

- **audit/28 landed** (commit `8e6b0f41`) — Tier 4 Resend email delivery + Sentry baseline. Static analysis pass + creds-gated dynamic verification scripts. **4 net-new findings (LOW)**: (A1) SPF on `bookbed.io` does not include `_spf.resend.com` — Resend mail passes DMARC via DKIM-only alignment + `p=none` policy, so this is a deliverability optimization not a correctness bug; 5-min DNS edit improves inbox placement. (A2) **5 V2 templates DORMANT** — `owner-cancellation`, `refund-notification`, `check-in-reminder`, `check-out-reminder`, `payment-reminder` have full code but no deployed CF caller; reminders moved to push path via `scheduledPushNotifications.ts`; cancel/refund missing as product feature. (A3) `audit/26` claim "21 v2 templates" mismatches actual 18 unique `sendXxxEmailV2` exports — likely off by aliases (`sendBookingCancellationEmail` = `sendGuestCancellationEmail` etc.); reframed softly. (A4) Sender domain is `bookings@bookbed.io`, not `book-bed.com` (terminology drift in task scope text only).
- **Mid-session wrapper-migration overlap** — commits `643403d6` + `3db8e76e` on `chore/migrate-email-templates-through-wrapper` (not yet merged to main) routed all 18 V2 templates through `sendEmailWithValidation` + added CRLF/recipient guards. `audit/28` §2.1 documents that the templates STILL discard the wrapper's returned message id (template exports remain `Promise<void>`), so `provider_id` reaches `emails_sent.*` writes from 0/18 templates today. PR-B remaining scope shrinks: 18 template signature edits + 15 `emailService.ts` wrapper edits + 3 `emails_sent.*` write sites + 1 interface field.
- **Three creds-gated scripts dropped** (`scripts/trigger-6-spot-check.js`, `scripts/resend-verify-spot-check.js`, `scripts/sentry-baseline.js`). Schema verified against `atomicBooking.ts:100-119` (camelCase fields) + `bookingManagement.ts:278/362` (`approved_at`/`rejection_reason` email-send guards). All three refuse prod (`rab-booking-248fc` or prod-looking Sentry org slugs). ADC-authenticated, idempotent. Handoff commands documented in audit/28 §8.
- **Branch race recurrence** (3rd this session class) — branch silently swapped from `main` to `chore/migrate-email-templates-through-wrapper` after `git status` confirmed clean main at session start. Caught at the final `git status --short` pre-commit (showed `chore/migrate-...` branch). Recovery: `git reset HEAD` to unstage → `git checkout main` (working-tree mods carry across cleanly because untracked + CLAUDE.md edit has identical surrounding context) → re-stage + commit on main with inline `[ "$(git branch --show-current)" = "main" ]` guard. No reflog rescue needed.
- **Memory entries added**: `dormant-5-email-templates.md`, `spf-gap-bookbed-io.md`. MEMORY.md index updated.
- **CLAUDE.md index updated** — added audit/28 entry. Previous tail `audit/26` is now `audit/28` (audit/27 slot taken by parallel-session `27-bb-e2e-cc-reject.md` that left an untracked file in working tree; renamed mine to audit/28 to resolve the collision). Version bumped 7.4 → 7.5.

---

**Changelog 6.87**: audit/23 PR-1 opened + B demoted to P3 post-census (2026-05-23) — **header drift fix 2026-05-23**: PR #450 was OPEN at write-time, "shipped" was incorrect; awaits merge:

- **PR #450 opened** (`fix/widget-counter-persist-badge-host`, commit `8c13e46d`) — audit/23 items A + C bundled together (same file `booking_widget_screen.dart`). **A:** `onAdultsChanged` / `onChildrenChanged` / `onPetsChanged` now call `_saveFormData()` after setState, mirroring the date picker (`:2398`) + pill bar (`:2788/:2799`) pattern. Counter selection survives iframe refresh instead of falling back to defaults (`adults:2, children:0, pets:0`). **A.1 sub-fix:** `PersistedFormData` gains a `pets` field (constructor + `toJson` + `fromJson` with `?? 0` default); restore path clamps to `_unit.maxPets` and respects `allowsPets` (mirrors the existing `maxGuests` clamp). **C:** `_PoweredByBadge` URL routes through `EnvironmentConfig.marketingHost` per the T13 host-literal centralization convention (`audit/08`, `.claude/rules/widget.md`). No runtime change today (`marketingHost === 'bookbed.io'` across all envs) — consistency-only. Net diff: 16 ins / 2 del across 2 files. `flutter analyze` 0 issues. Dart format hook green.
- **Item B demoted P1 → P3** — Terminal FF census (CHANGELOG 6.86) returned **0 `in_progress` bookings** on both `bookbed-dev` (1 total, status `cancelled`) AND `rab-booking-248fc` (58 total: 29 `completed`, 19 `cancelled`, 10 `confirmed`). Deprecated top-level `/bookings/{id}` empty on both. No observed surface for the parity drift across `availability.ts:153` / `atomicBooking.ts:742` / `stripePayment.ts:604` — code-hygiene fix only, no migration risk. `audit/23` status footer updated to reflect. PR-2 reduces to Item D solo (`calculateBookingNights` same-civil-day validator, P2/XS).
- **Branch race recurrence (new recovery pattern)** — `git add` succeeded on `fix/widget-counter-persist-badge-host`; parallel terminal then swapped HEAD back to `main` (3 new commits arrived: audit/22 Q2/Q3/Q4 resolutions + audit/25 + audit/26). My chained guard `[ "$(git branch --show-current)" = "fix/..." ] || exit 1` aborted commit cleanly. **Recovery:** `git reset HEAD <files>` to unstage from main → `git checkout fix/...` (working-tree mods follow, since they were unstaged) → restage + commit with same guard inline. No reflog rescue needed because changes never reached commit on the wrong branch. New nuance added to `memory/multi-agent-git-race.md` 2026-05-23 §3.
- **audit/23 status footer updated** — PR-1 marked OPEN (PR #450 pending merge), B demotion noted, PR-2 scope reduced.
- **CLAUDE.md index updated** — added audit/25 (E2E test catalog) + audit/26 (BB E2E findings: owner direct-write bypass + `provider_id` gap). Previous tail `audit/24` is now `audit/26`.

---

**Changelog 6.86**: audit/22 Q4 resolved against PROD + FF in_progress census (2026-05-23):

- **audit/22 §8 Q4 resolved** (commit `fd450c31`) — ran `functions/scripts/normalize-booking-nights.js` dry-run directly against `rab-booking-248fc` (read-only). Result: **K = 4 bookings to update**. Scanned 10 confirmed-eligible bookings out of 58 total CG bookings; 4 drifting `check_in` + 4 drifting `check_out` (same 4 docs). All drifters are summer-2026 confirmed bookings with timestamps stored at `22:00:00.000Z day N-1` (= midnight Zagreb CEST UTC+2); normalize snaps to `00:00:00.000Z day N` per the new write-time invariant (`dateValidation.ts` STEP 6). §3.6 prod `--force` is now well-characterized: at most 4 doc updates, single 400-batch, sub-second commit. Full DRY-RUN log force-added past `*.log` gitignore at `audit/migrations/2026-05-23-prod-sf026-normalize-DRYRUN.log` (same convention as `2026-05-21-prod-wave0-cleanup.log`).
- **Dev SF-026 dry-run impossible** — `bookbed-dev` has 1 booking total, status `cancelled`, which the script's status filter (`{confirmed, pending_payment, awaiting_owner_decision}`) excludes. Direct prod dry-run was the only viable Q4 answer path. Acceptable because operation is read-only.
- **PROD booking status census (Terminal FF)** — `collectionGroup('bookings')` filtered by `status='in_progress'` returns **0** on both `bookbed-dev` AND `rab-booking-248fc`. Histogram: dev `{cancelled: 1}` (1 total); prod `{completed: 29, cancelled: 19, confirmed: 10}` (58 total). Deprecated top-level `/bookings/{id}` collection empty on both projects. **Triage signal**: any backlog item B gated on the existence of `in_progress` bookings demotes to P3 (no migration risk, no observed surface). Single-field CG-on-status query failed with `FAILED_PRECONDITION` (no exemption set on either project); workaround = fetch all + filter in memory (same pattern as the normalize script).
- **Multi-agent git race — branch-swap recurrence** — branch silently swapped from `main` to `fix/widget-counter-persist-badge-host` between my `git status` check and `git commit`. The branch guard `[ "$(git branch --show-current)" = "main" ] && git commit ...` correctly aborted via short-circuit (exit code 1), but the subsequent diagnostic bare `git commit` then landed `fd450c31` on the wrong branch. **Recovery**: `git checkout main` → `git merge --ff-only fd450c31` (fast-forward worked because the bad branch was created from main HEAD with my commit as its sole delta) → `git update-ref refs/heads/fix/widget-counter-persist-badge-host 2fb93480` to restore the other agent's branch starting point → `git push origin main`. Lib working-tree mods (`booking_widget_screen.dart` + `form_persistence_service.dart`, owned by other agent) left untouched. New nuance documented in `memory/multi-agent-git-race.md` Addendum 2026-05-23.
- **audit/22 still open** — §8 Q1 (deploy window), Q5 (operator ack of coexisting-contract transient), Q6 (reconstruct `audit/06-availability-cf-design.md` or accept audit/22+SF-019 as canonical). All operator decisions. No further automated work I can do on those.
- **audit/24 landed** (commit `1eee771d`, Terminal CC) — P3 backlog investigations from `audit/21` §Outstanding: (1) `getUnitIcalFeed` region — clarifies audit/21's "docstring claims europe-west1" framing is inaccurate (no such docstring exists; only runtime-region question is real); recommends demote to "won't fix" because the endpoint is background-polled (12–24h Google Calendar cadence) so +120ms RTT is invisible to humans and CF region is immutable post-create (B2 dual-deploy migration cost >> benefit); (2) `getUnitAvailability` unknown-unit `logWarn` — recommends **promote P3 → P2**, cheap property-doc-exists check + per-IP warn-rate-limit (1/IP/hour) to close keyspace-scan abuse-detection gap without flooding Cloud Logging; write path remains gated separately by `atomicBooking.ts:743` overlap check + `widget_settings` token, so not security-critical; (3) `.claude/rules/hosting-build.md` `--release`-only rule — single Terminal E `assembleDebug` success is weak evidence against an intermittent `firebase_storage` Kotlin-before-Java compile-order bug; keep rule, soften prose to "default to --release."
- **audit/22 Q2 + Q3 resolved** (commit `2fb93480`, Terminal HH). Q2: `bookbed-widget.web.app/` HEAD returned `last-modified: Thu, 21 May 2026 18:50:32 GMT` + bootstrap.js etag `153608da33...` — confirmed **pre-T11c** (T11c merged 2026-05-22), §3.3 rebuild + redeploy IS required; DEV equivalent `last-modified: Fri, 22 May 2026 17:37:07 GMT` + etag `e71fa54a52...` corroborates different bundle. Q3: `firebase` CLI exposes no `:rules:get` subcommand (verified against `firebase --help` top-level + `firebase firestore --help`); working method is **Firebase Rules REST API** two-call flow (`GET /v1/projects/$P/releases/cloud.firestore` → `rulesetName` → `GET /v1/$rulesetName` → `source.files[0].content`) with `Authorization: Bearer $(gcloud auth print-access-token)` + **`X-Goog-User-Project: $PROJECT` header** (without it API errors `403 SERVICE_DISABLED` even with valid token); verified end-to-end against `bookbed-dev` ruleset `e319e00c-2d8b-4324-8e97-4cd5a7590c3c` updateTime `2026-05-22T17:16:47Z`. Full pre-flight commands (Firestore + Storage rules) now embedded in audit/22 §2 backup-rules item.
- **CLAUDE.md index updated** — added audit/22, audit/23, audit/24 to the "Dodatni dokumenti" list. The previous tail `audit/21` is now `audit/24`. Future-Claude sessions will surface these on every cold-start without grep.

---

**Changelog 6.85**: Test-debt cleanup + mobile-smoke unblocker + sprint close-out — 2 PRs opened, audit/20+21 landed (2026-05-23):

- **PR #448 opened** (`chore/test-debt-cleanup-audit-19`, commit `252d3350`) — aligns test fixtures with T11c (`ab6bdb3d`) + SF-022 (`319f7d0f`) contract changes. Cluster 1 (Flutter, 3 files, 30 sites): seed `_FakeAvailabilityRepository.windows` for booking-overlap assertions post-T11c; new `_FakeAvailabilityRepository extends FirebaseAvailabilityRepository` with mocktail-stubbed `FirebaseFunctions` for the calendar repo tests (constructor takes concrete class, not interface). Cluster 2 (Jest, 4 matchers): flip `rejects.toThrow` from wrapped `internal` to original `not-found` / `failed-precondition` classes. +1 defensive test asserting `isAvailable=false` when CF fetch throws (regression guard for commit `99ac6124` fail-CLOSED restore). **Pre-fix: 30 flutter + 4 jest fails. Post-fix: 1101/1101 + 165/165 green.** Test-only. No production code touched. Diagnosis in `audit/19-test-failures-diagnosis.md`.
- **PR #449 opened** (`chore/seed-test-owner-mode`, commits `b4a69837` + `5396b412`) — dev-infra housekeeping via `git worktree` to isolate from active sibling branches. (1) `.gitignore jest_dx/` — Jest worker/transform cache that lands in repo root. (2) `scripts/seed-bookbed-dev.js --test-owner` mode adds Auth SDK `emailVerified=true` for `bookbed-test@bookbed.io`, `/users/{UID}` owner row for `GILVItIVP5R8WXfnMmyMo1ykhUm2`, 1 active property + unit + (optional) sample booking. Idempotent (`set({merge:true})`). Unblocks mobile smoke checklist Steps 3-6 on iOS + Android — test account previously hit `requiresOnboarding` gate. Script has no `--dry-run` flag; not executed against bookbed-dev from this terminal (no-deploys rule).
- **audit/20-error-boundary-narrowing.md** committed (`3ba4fbab`, Terminal K) — ErrorBoundary widget catches Marionette VM-extension exceptions (and likely any `dart:developer`-routed exception) and surfaces them as user-visible "Oops! Something went wrong" screen. Observed twice in Android smoke session. **Fix queued for next sprint**, no production functional impact.
- **audit/21-sprint-summary-2026-05-22-23.md** committed (`f4b19ad6`) — sprint close-out: sessions/terminals matrix (A–K), 3 PRs opened, **backend availability fail-CLOSED triple-verified** (rules layer + CF server overlap + CF window emission empirical + client fail-CLOSE on throw — all four green), iOS + Android mobile smoke results (pre/post seed-script unblock), bugs triaged (ErrorBoundary real, Supabase DNS storm false-positive from emulator cross-contamination, Marionette matcher quirk), outstanding work tier-grouped.
- **Recommended merge order** (post billing fix): `#449 → #448 → #447` — housekeeping → green baseline → Wave 5 Phase 1 against clean test baseline.
- **CI billing wall still active** — all 3 PRs blocked at `Run Tests` / `Test Cloud Functions` / `Validate Firestore Rules` (same root cause flagged in 6.81/6.83). Single manual unblocker.
- **Git hygiene** — one stash dropped this session (`d0e9e2ae`, seed-script WIP that became `5396b412` on `chore/seed-test-owner-mode`). Sanity-checked byte-equal against PR HEAD before drop. Stash list now empty.
- **No production code changed in this CHANGELOG window.** All Flutter/CF source untouched. iOS `GoogleService-Info.plist` + Android `google-services.json` both confirmed prod (`rab-booking-248fc`) at session end.

---

**Changelog 6.84**: CF live-test verification on bookbed-dev — `getUnitAvailability` + `getUnitIcalFeed` empirical contract proof (2026-05-23):

- **`getUnitAvailability` (eu-west1, callable)** — 5 cases against SEED unit. Happy authed → HTTP 200, 4.2 s cold / 150 ms warm. Anonymous → HTTP 200 (DESIGN — `availability.ts:8` widget public; not unauthenticated error). Non-existent unit → HTTP 200 `windows: []` (fail-OPEN-shaped; mitigated downstream by `widget_settings` lookup on booking submit; CF should `logWarn` unknown unit). Missing `propertyId` → 400 `INVALID_ARGUMENT`. `endDate < startDate` → 400 `INVALID_ARGUMENT`. **No stack traces leaked.**
- **Response shape note** — actual contract is `{unitId, windows[], generatedAt, cacheHint}` (no `success` or `blocks`). Real Dart caller is `FirebaseAvailabilityRepository`.
- **`getUnitIcalFeed` (us-central1, NOT eu-west1, onRequest)** — `firebase functions:list` confirms us-central1 deployment. No `region:` in `onRequest` opts → default. Already inventoried in `audit/11-cloudfunctions-inventory.md` P3 (hot-path EU latency cost +120 ms). 7 cases: OPTIONS preflight → 204 CORS `*`; HEAD → 403 (reaches token check past method gate — learning #17 HEAD-allowed holds); GET bogus token → 403 `Invalid token`; GET non-existent property → 404 `Unit not found` (fail-CLOSED ✓); GET malformed path → 400 `Invalid URL format. Expected: /{propertyId}/{unitId}/{token}`; GET `token.ics` → 403 (`.ics` strip works); POST → 405 `Method Not Allowed`. No RFC 5545 wellformed validation done — SEED fixture lacks owner-configured `ical_export_token` and `widget_settings` rows.
- **Sentry expectation** — all errors above are HttpsError client-fault codes (`invalid-argument`, `out-of-range`) or non-CF HTTP error responses → `sentry.ts:57-76` `beforeSend` filter drops them. **Zero new Sentry events should appear from this run.** Direct dashboard verification unavailable from this env.
- **Terminal G — known-block round-trip on `ical_events`** — wrote manual `ical_event` doc to `properties/SEED_property_dev_01/units/SEED_unit_dev_01/ical_events/{auto-id}` via Admin SDK + ADC (`start_date`/`end_date` Timestamps = Europe/Zagreb 2026-06-15 / 2026-06-20, source `manual`, status `confirmed`). Called CF with June 1-30 window. Response `windows: [{start: 2026-06-14T22:00:00.000Z, end: 2026-06-19T22:00:00.000Z, source: "ical_external", platform: "manual"}]` — **exact match.** Cleanup re-verified ical_events count = 0. Backend chain confirmed end-to-end on a write that exercises every read path in `availability.ts:197-211`.
- **Field-name canonicalization audit (informational, P3)** — `availability.ts:201-202` reads `start_date` / `end_date` from `ical_events`. Sole Firestore writer is `icalSync.ts:857-858` and it uses the canonical names. All other matches in the codebase are reads of the canonical names, in-memory map construction in `firebase_booking_calendar_repository.dart:96-97` (NOT a Firestore write), or writes to the distinct `ical_feeds` collection in `ical_feed.dart:329-330` (canonical anyway). **No invisible-block bug exists.**
- **Methodology** — sandbox HTTP calls via `ctx_execute`, Identity Toolkit `signInWithPassword` for ID tokens, callable wire format `{data: {...}}`, no writes to bookings/payments/auth.

---

**Changelog 6.83**: Repo hygiene — 29-stash drop + Dependabot transitive batch merge (11) + branch cleanup (12) (2026-05-22 evening):

- **Stashes 32 → 3** in this session (sibling agent then dropped the remaining 3 per CHANGELOG 6.81 — final state 0). Descending-index drop sequence (highest first) preserves stable numbering across each `git stash drop`. Class A merged-work race debris (17) + Class B Wave 0 debris (9) + Class E ancient-mvp obsolete (3) → all dropped this session. Class C (T11c sibling `1eb3b205`) + Class D (jules-audit `4151b352`, diagonal-gradients `d0e71b62`) preserved here; later dropped by sibling per 6.81 operator decision. Full classification in `audit/18-stash-classification-2026-05-22.md` Addendum 2026-05-23.
- **Dependabot transitives — 11 squash-merged, 1 closed**: PRs #309 flatted, #314 handlebars, #316 node-forge, #319 path-to-regexp, #327 fast-xml-parser, #328 lodash, #369 ajv, #412 @protobufjs/utf8, #414 picomatch, #415 brace-expansion, #416 minimatch (3.1.2 → 9.0.9 major-skip-safe via lockfile-only transitive). Each batch validated locally before next: `flutter analyze`=0, `npm run build`=0. #281 minimatch 3.1.5 closed as superseded by #416, remote branch deleted. Per `audit/18-dependabot-triage-2026-05-22.md` Addendum 2026-05-23.
- **Branches 14 → 2 non-main local**: deleted 12 merged-into-main (`fix/sf-026-booking-count-dst`, `docs/wave3-cleanup-fix-and-deferred`, `chore/cleanup-stash-dependabot-test-debt-2026-05-22`, `fix/icalpii-family-rules-and-cf`, `fix/auth-race-and-indexes-cleanup`, `chore/ci-enable-android-build`, `fix/ios-firebase-env-hardening`, `fix/sentry-dart-env-and-seed`, `fix/sentry-env-detection`, `chore/merge-trial-v2-winner`, `chore/kill-comeback-reminder`, `chore/kill-booking-airbnb-integration`). Preserved `refactor/booking-widget-phase1` (active sibling) + `hotfix/widget-secrets-exfil` (unmerged).
- **Dev servers**: widget session on port 8766 preserved (active 6h+ runtime). Ports 5556/8080/8081/8082 already free.
- **Multi-agent race observed**: working tree silently flipped from `main` to `refactor/booking-widget-phase1` mid-session during `git pull` (sibling checkout). Two new stashes appeared during execution (`smoke-447-temp-78094` + WIP-on-main). Recovered via `git checkout main`. Per `memory/multi-agent-git-race.md`.
- **Pre-existing CI failure on main, not caused by this work**: `Run Tests` / `Test Cloud Functions` / `Validate Firestore Rules` red since `ac225b3d` (2026-05-22 16:49Z, env/billing wall — same root cause flagged in 6.81). All 11 merged dependabot PRs had SUCCESS on those jobs at PR time. User ack'd "Continue — env CI issue".

---

**Changelog 6.82**: T11c dev cutover finalized — `daily_prices` index + widget bundle redeploy (2026-05-22):

- **PR #446 merged** (`3b810b2d`, `--merge` not `--squash` to preserve the 4-commit chain). CHANGELOG conflict 6.79 vs 6.80 resolved by keeping both entries with 6.80 first (newer).
- **Dev deploy 1 — rules + CF** (`firestore.rules` + `getUnitAvailability` to `bookbed-dev`). Initial smoke split: anon CG `bookings` `runQuery` → **403 PERMISSION_DENIED** ✅; `getUnitAvailability` (europe-west1) → **500 INTERNAL** ❌ with `FAILED_PRECONDITION: query requires an index` for `daily_prices` (`available + date`). Pre-existing infra gap, NOT a T11c regression — surfaced because smoke now exercises the full CF codepath end-to-end (SF-023 smoke never hit a non-empty plan).
- **Dev deploy 2 — widget bundle.** Bundle on `bookbed-widget-dev.web.app` was 2026-05-18 (pre-SF-023, pre-T11c). Rebuilt via `flutter build web --release --target lib/widget_main_dev.dart` + `firebase deploy --only hosting:widget --project bookbed-dev`. Served SHA `98d40d2c…` confirmed matching local `flutter_bootstrap.js`. `web/bookbed-overlay.js` copied to `build/web_widget/` per the changelog 6.65 deploy step.
- **Dev deploy 3 — index fix** (commit `a1fe3633`). Added `daily_prices` COLLECTION composite (`available` ASC + `date` ASC) to `firestore.indexes.json`. CG indexes don't help subcollection queries (per `.claude/rules/firestore.md`); CF query at `functions/src/availability.ts:156-166` uses subcollection path so needs COLLECTION-scope coverage. Index built `READY` after ~80 s; CF still 500'd "index currently building" for ~30 s after `READY` state — **propagation buffer recorded in `docs/TODO.md` prod cutover steps**. Final retry: HTTP 200 with `{result: {unitId: SEED_unit_dev_01, windows: [], cacheHint: 30}}`.
- **Docs** — `docs/SECURITY_FIXES.md` SF-019 "Dev deploy 2026-05-22" subsection rewritten from "(partial)" to complete (commit `d3875e6e`); `docs/TODO.md` T11c status line + prod cutover checklists updated with the `daily_prices` index step + propagation buffer; this CHANGELOG entry.
- **PR #447 status (separate)** — Phase 1 widget refactor: 0 reviews, mergeable UNKNOWN, CI failed at GH billing wall (`The job was not started because recent account payments have failed`) — not a logic failure. Smoke + rebase done by sibling agent per entry 6.81. Merge gated on Actions billing resolution.
- **Multi-agent race** — one branch swap mid-session (`main` → `refactor/booking-widget-phase1` between `git add` and `git commit`); first SECURITY_FIXES.md commit landed on wrong branch with empty diff. Recovered via re-edit + atomic `[ $(branch) = main ]` chain on stage/commit/push.

---

**Changelog 6.81**: PR #447 smoke verification + rebase + session-end cleanup (2026-05-23):

- **PR #447 smoke** — Flow A (form persistence round-trip) + Flow B (zoom controls + rotate overlay) verified end-to-end via Chrome DevTools Protocol against `bookbed-dev`. Comment posted: `https://github.com/DanLika/rab_booking/pull/447#issuecomment-4521868516`. Calendar rendering required PR 447 to be rebased onto current `main` (it predated the T11c availability migration + the `daily_prices` index fix `a1fe3633`).
- **Rebase + force-push** — rebased `refactor/booking-widget-phase1` onto `main` in an isolated worktree (`smoke/pr447-rebased` @ `a4d7f09b`). 9/9 commits applied cleanly; only conflict was `docs/CHANGELOG.md` (6.78 vs 6.79+6.80 entries), resolved by keeping all three. Force-pushed `cb5cf7f6...a4d7f09b` onto `refactor/booking-widget-phase1` with `--force-with-lease`.
- **CI gate stuck** — re-triggered CI run `26307066384` blocked at scheduler with "The job was not started because recent account payments have failed or your spending limit needs to be increased." All 3 unit/CF/rules jobs hit the billing wall in 2s; build jobs skipped. Per the merge gate (CI green) the merge is on hold until Actions billing is resolved.
- **Side finding (pre-existing on main, NOT a PR 447 regression)** — `onAdultsChanged` / `onChildrenChanged` / `onPetsChanged` handlers in `booking_widget_screen.dart:2765-2782` only call `setState`, never `_saveFormData()` — unlike the text controllers which register `_saveFormDataDebounced` listeners (lines 262-266). `git diff main..HEAD` over that region is empty → identical on `main`. Guest counter changes silently drop from the persistence cache. Filed in `docs/TODO.md` for follow-up.
- **CDP smoke methodology** — full UI-driven A1–A12 (calendar tap May 29 → month-nav → tap June 1 → "Reserve" → fill `<input>` via `Input.dispatchMouseEvent` focus + `Input.insertText`, no JS-side `.value=` shortcut → reload → verify restore). All 15 payload fields byte-identical pre/post reload; only `timestamp` re-stamped (by-design 24 h cache-freshness marker per `PersistedFormData.isExpired`).
- **gitignore: node-compile-cache** (commit `0f6cf77f`) — added `node-compile-cache/` (Node v25 JIT artifacts, 580 files in `v25.1.0-arm64-392347a2-501/`). Was polluting IDE "changes" counter with 581 entries (580 cache files + the lockfile metadata diff). Lockfile metadata diff (peer-flag additions only — no version/integrity/package changes) reverted.
- **Stash cleanup** — 4 stale stashes dropped per operator decision: SF-019 docs WIP `98624432`, T11c availability_checker WIP `1eb3b205`, Jules audit prompts `4151b352`, diagonal-gradient mvp WIP `d0e71b62`. Recoverable for ~90 days via `git fsck --unreachable` + `git stash apply <sha>`.
- **Worktree cleanup** — `/tmp/pr447-wt` removed; `smoke/pr447-rebased` branch ref preserved as safety net at `a4d7f09b` (drops after PR 447 merges). Cursor IDE worktrees in `~/.cursor/worktrees/` untouched.
- **Branch sync** — local `refactor/booking-widget-phase1` reset to `origin/refactor/booking-widget-phase1` via `git update-ref` (was at pre-rebase tip `cb5cf7f6`, now matches origin `a4d7f09b`). `hotfix/widget-secrets-exfil` left as-is at [ahead 2] per operator (active work, unpushed).
- **Memory** — `memory/flutter-web-input-bypass.md` updated with raw-CDP driving recipe (`Input.insertText` after focus-click), the **READ-direction** sync gap (DOM `input.value` reads `""` even when field is visually populated — CanvasKit renders to canvas, DOM input is focus-proxy only; **always verify form state via screenshot**), and shared_preferences_web localStorage double-encoding format.
- **Multi-agent race observed** — main working tree silently flipped from `refactor/booking-widget-phase1` back to `main` twice during the smoke session despite no checkout from this agent. `git worktree list` showed 5 active Cursor worktrees + my temp worktree. Defensive `[ "$(git branch --show-current)" = "main" ] || exit 1` guard before every `git commit` + `git push` prevented stray landings.

---

**Changelog 6.80**: SF-026 — booking night count UTC midnight Zagreb-civil-day normalization (2026-05-22):

- **SF-026 landed** (branch `fix/sf-026-booking-count-dst`, commits `5f747740` core + `0a6a6570` merge + `dc554396` migration index fix + `ff39fa8d` smoke script). Closes the audit/18 finding (Option B per recommendation).
- **Server STEP 6 normalization** — `functions/src/utils/dateValidation.ts` now wraps `check_in`/`check_out` Timestamps via new `normalizeToZagrebCivilDayUTC()` helper before persist. Civil day extracted via `Intl.DateTimeFormat('en-CA', {timeZone: 'Europe/Zagreb'})` → UTC midnight of that day. Preserves "day the guest selected" through Zagreb display (naive `getUTCDate()` extraction would have shifted Zagreb-originated bookings backward 1 day — caught by advisor pre-commit).
- **Standardized derivation** — TS `verifyBookingAccess` + `getBookingByStripeSession` migrated off inline `Math.ceil(/86_400_000)` to canonical `calculateBookingNights()`. Dart sites: email service uses `booking.numberOfNights`; widget + form-state use `DateNormalizer.nightsBetween()` (UTC-normalized floor). With normalized inputs, floor and ceil yield same N — no more DST off-by-one.
- **Backfill script** — `functions/scripts/normalize-booking-nights.js`, dry-run default, `--force` opt-in. Scans `collectionGroup('bookings')` filtered client-side (no Firestore index required) for `confirmed | pending_payment | awaiting_owner_decision`, rewrites Timestamps where they differ from normalized.
- **Smoke script** — `functions/scripts/smoke-sf026-dev.js` confirms the bug pattern on bookbed-dev's seed booking: `check_in 2026-06-17T15:00:00Z` / `check_out 2026-06-20T11:00:00Z` → Dart floor=2 vs TS ceil=3 (off-by-one). Status=cancelled, out of migration scope, but proves audit/18 diagnosis on live data.
- **Tests** — `functions/test/dateValidation.test.ts` 13/13 green: Zagreb summer/winter midnight ulaz, DST spring-forward (2026-03-29) → 4 nights, DST fall-back (2026-10-25) → 2 nights, long booking across both transitions → 240 nights, single-night, idempotency, validation guards.
- **Deploy** — `bookbed-dev` deployed (background task `bzx1w2bql` exit 0). Prerequisite: deleted 2 pre-existing orphan CFs blocking non-interactive mode (`comebackReminder(europe-west1)`, `sendOwnerEmail(us-central1)`; both per audit/11 inventory). Prod cutover + `--force` migration pending operator approval.
- **Behavior change (filed, not fixed)** — same-Zagreb-civil-day check-in + check-out (different clock times within one day) now throws "< 1 night" in `calculateBookingNights()` whereas pre-fix it returned 1 via `Math.ceil(0.x)`. Widget picker constrains to whole dates so unreachable today; admin/script paths could trip it later.
- **Verification** — `cd functions && npm run build` 0 errors; `flutter analyze` 0 issues; 13/13 SF-026 tests + 161/165 functions suite (4 pre-existing `stripeConnect` failures unrelated); 1079/1100 flutter tests (21 pre-existing test-debt failures per commit `55981882`, unrelated).
- **Multi-agent race** — 2+ branch swaps during session (`refactor/booking-widget-phase1`, `fix/t11c-proper-bookings-migration`). Recovered via cherry-pick + explicit-staging. Race-debris and another agent's iOS plist swap preserved in stash + working tree.
- **Docs** — `docs/SECURITY_FIXES.md` SF-026 entry added; `docs/TODO.md` SF-026 row flipped to DONE.

---

**Changelog 6.79**: T11c proper CLOSED — bookings clause 1 locked + widget CF migration (2026-05-22):

- **T11c proper landed** (PR #446, branch `fix/t11c-proper-bookings-migration`, commits `ab6bdb3d` + `64b14bf0`). Closes SF-019 → T11c. Last anonymous read surface on the `bookings` collection-group is now closed.
- **Widget migration** — 5 anonymous-context sites migrated from `collectionGroup('bookings').snapshots()` to the `getUnitAvailability` callable:
  - `lib/features/widget/data/repositories/firebase_booking_calendar_repository.dart` — 4 streams (lines 107, 245, 386, 496) collapsed into single `_streamBlockedEvents` that demultiplexes CF windows by `source` (booking + ical_external + manual_block). Bookings synthesized into minimal `BookingModel(status: confirmed)` — privacy-driven loss of pending/confirmed visual distinction in widget calendar (accepted trade-off).
  - `lib/features/widget/data/helpers/availability_checker.dart` — `_checkBookings()` direct CG query replaced with `_fetchAvailabilityWindows()` + per-source overlap helpers. Bookings + iCal now share one CF round-trip.
- **Rules tightening** — clause 1 (`unit_id`+`status` public read) removed from all 3 surfaces (`firestore.rules`): subcollection `properties/{p}/units/{u}/bookings/{id}`, collection-group `{path=**}/bookings/{id}`, and deprecated top-level `/bookings/{id}`.
- **Tests** — 24/24 rules tests pass. 2 "STILL ALLOWS" / "ALLOWED" assertions in `functions/test/firestore_rules/bookings.test.ts` flipped to `assertFails` as clause-1 regression guards. Test suite description renamed from `bookings rule (T11-hotfix-partial)` to `bookings rule (T11c closed)`.
- **UX trade-off** — realtime `.snapshots()` for bookings sacrificed; widget now polls every 30 s via `FirebaseAvailabilityRepository._defaultPollInterval` (same cadence already in place for iCal blocks after SF-023).
- **CLAUDE.md NIKADA NE MIJENJAJ** — bookings clause-1 row flipped from "INTENTIONALLY public until T11c proper lands" to "✅ T11c CLOSED 2026-05-22" with pointer to `ab6bdb3d`. The `firebase_booking_calendar_repository.dart` row stays (file still has no unit tests; T11c only made the touched flows simpler, not safer to broadly refactor).
- **Verification** — `flutter analyze` 0 issues; `cd functions && npm run build` 0 errors; `cd functions && npm run test:rules` 24/24 pass.
- **Multi-agent race** — 4+ branch swaps during session per `memory/multi-agent-git-race.md`. Recovered via chained stash/checkout/pop/commit with abort safety. Both T11c commits (code + docs) intact on the branch.
- **Deploy** — pending PR #446 review. Dev rollout via `firebase deploy --only firestore:rules,functions:getUnitAvailability --project bookbed-dev`. Prod cutover separate. No push to origin/main yet.
- **Note** — claims version 6.79 (not 6.78) because PR #447 (Phase 1 widget refactor) already claims 6.78. Whichever PR merges second will resolve sequencing in the merge.

---

**Changelog 6.78**: Booking widget refactor Phase 0+1 — agent-log cleanup + pure-helper extraction (2026-05-22):

- **Audit doc**: `audit/12-booking-widget-refactor-plan.md` (339 lines) catalogues `booking_widget_screen.dart` (4811 LOC god-screen), proposes 21-unit split across 5 phases with risk per extraction, sibling-overlap check, 10 open decisions. Section-8 questions 1-3 resolved this PR (agent-log: delete; BookingFormState: ChangeNotifier; tests: service-layer only).
- **Phase 0 — agent-log instrumentation removed** (`08973bc9`): 18 `// #region agent log … // #endregion` blocks deleted (–419 LOC). Debug session closed; per `.claude/rules/widget.md` the silent-guard rule applies to messaging callbacks (postMessage / BroadcastChannel / PaymentBridge) and those remain intact.
- **Phase 1 extractions (5 new helpers)**:
  - `presentation/helpers/booking_widget_url_helpers.dart` — 5 static defense-in-depth validators (`sanitizeId`, `isValidBookingReference`, `isValidFirestoreId`, `isValidStripeSessionId`, `safeErrorToString`). Public functions; 9 screen call sites rewritten. **34-case unit test**.
  - `presentation/helpers/booking_widget_url_intent.dart` — sealed `BookingUrlIntent { FreshLoad, StripeReturnSession, LegacyStripeReturn, DirectBookingReturn }` + `parseInitialUrlIntent(Uri)`. Replaces 64 lines of inline URL inspection in `initState` with a single switch. Priority preserved: legacy > stripe-session > direct > fresh. **16-case unit test**.
  - `presentation/helpers/iframe_height_reporter.dart` — encapsulates `_contentKey` + `_lastSentHeight` + post-frame `sendIframeHeight`. Disposed flag pattern bails after teardown.
  - `presentation/helpers/zoom_control_state.dart` — owns `TransformationController` + viewer key + scale + centered-zoom matrix math + scroll-wheel pan. Side-effect fix: now disposes the controller (pre-existing leak in screen).
  - `presentation/widgets/powered_by_badge.dart` — file-private `_PoweredByBadge` promoted to public `PoweredByBadge`. Hardcoded `https://bookbed.io` preserved (audit Q7 punted to follow-up).
- **`BookingFormState` promoted to `ChangeNotifier`** (`a3acc3f7`): every mutable field becomes a private backing field + getter + value-equality-guarded setter that fires `notifyListeners()`. `dispose()` chains `super.dispose()`. `resetState()` writes to private fields and notifies exactly once. New factory methods `toPersistedFormData({unitId, propertyId})` + `applyFromPersisted(PersistedFormData)` collapse 57 LOC of (de)serialization in the screen. **23-case unit test**.
- **`booking_widget_screen.dart` LOC**: 4811 → 4126 (–685, –14%). 22 delegating getters/setters from prior Dec-2025 refactor (`bdd16fa0`) untouched — composers in follow-up phases will replace them.
- **Tests added (73 cases across 3 files)**: pure-function tests only per execution plan; no widget tests. CI gate (`flutter test --coverage` in `.github/workflows/ci.yml`) covers them automatically.
- **Multi-agent race observed**: branch `refactor/booking-widget-phase1` hijacked once by parallel agent who used it for SF-026 migration work and cherry-picked to main. Recovered via surgery: `git branch -D` polluted ref + `git branch -f` restore of `fix/t11c-proper-bookings-migration` + cherry-pick of audit-doc commit onto fresh refactor branch from current main. Branch swapped under foot ~6 times mid-edit; defensive `[ "$(git branch --show-current)" = "..." ] || exit 1` guard before every `git add` + `git commit` prevented stray landings.
- **Verification**: repo-wide `dart format --set-exit-if-changed .` clean (650 files). Repo-wide `flutter analyze --no-fatal-infos` clean (0 issues). Test parity vs `main` (via `git worktree add /tmp/bookbed-main-snapshot main`): main = `+640 -21` after build_runner, refactor branch = `+713 -21`; **same 21 pre-existing failures** (`daily_price_model.freezed.dart`-class), pass-count delta exactly = 73 new test cases I added. **No new regressions.**
- **Mandatory smoke deferred** (per execution plan §Verification): 8 web flows + 4 iOS-dev flows must run before PR open / merge. Cannot be run from automated session — flagged for follow-up.
- **Deploy**: none. Refactor only; no production surface changed.
- **Commits**: `074c2652` (audit doc), `08973bc9` (Phase 0 agent-log delete), `eaabf7ce` (URL helpers), `84a1d906` (URL intent), `a3acc3f7` (BookingFormState ChangeNotifier), `2243a6e7` (IframeHeightReporter), `3ac4af3b` (ZoomControlState), `4b01e033` (PoweredByBadge). Branch `refactor/booking-widget-phase1` — NOT pushed.
- **Follow-ups queued in `docs/TODO.md`**: Phase 2-5 of audit/12 — leaf composers (error screen, overlays, dialogs), state notifiers (validation, payment messaging — BLOCKING risk), Stripe pipeline domain services.

---

**Changelog 6.77**: T11c progress note + booking count audit + audit gitignore whitelist (2026-05-22):

- **T11c progress documented** (`docs/SECURITY_FIXES.md` line 1350, new "T11c progress update 2026-05-22" subsection under SF-019): captures the split status of T11c after SF-023 landed the `getUnitAvailability` CF half. Lists the 5 anonymous-context widget sites that still issue direct `collectionGroup('bookings').where('unit_id', '==', …).where('status', 'in', …)` and therefore block clause-1 removal — 4 streams in `firebase_booking_calendar_repository.dart:107/245/386/496` (`.snapshots()` realtime) + 1 one-shot in `availability_checker.dart:257` (booking-submit gate). Documents the 6-step migration plan + the realtime → ~30s polling UX regression that ships with it. Closes the doc gap that made T11c look ready to land when it wasn't (CF deployed but widget reads not migrated).
- **Booking night/guest count source-of-truth audit** (`audit/18-booking-count-audit.md`, 170 lines, doc-only): maps every persisted vs derived field on the booking doc and the 12 derivation sites (6 Dart `.difference().inDays` floor + 6 TS `Math.ceil(/86_400_000)` ceil). Booking schema persists `check_in`/`check_out` Timestamps + `guest_count` only — no `nights`, no adults/children split. Floor vs ceil agree today because timestamps come from a date picker (midnight-aligned), but DST-straddling bookings produce off-by-one disagreement (Dart `.inDays` truncates 23h day to N-1, TS `Math.ceil` rounds to N). Recommends Option B as minimum fix: in `functions/src/utils/dateValidation.ts` STEP 6, persist the existing `checkInMidnight` UTC-normalized variant (already computed for past-date validation) instead of the raw client Date. Tracked as SF-026 candidate in `docs/TODO.md`.
- **`.gitignore` audit/**/*.md whitelist** (commit `70c91f8e`): `*.md` rule on line 73 was implicitly blocking new files under `audit/`; the existing whitelist covered `README.md`, `CLAUDE.md`, `SECURITY.md`, `.claude/**/*.md`, `docs/**/*.md`, `assets/kb/*.md`, but not `audit/**/*.md`. Required `git add -f audit/18-booking-count-audit.md` for this PR. Added `!audit/**/*.md` (with comment) so future audit files no longer trip the same gotcha.
- **Multi-agent race — stash absorption pattern observed**: terminals A, B, and C all active. My first staged commit was absorbed into terminal A's commit `a1276a8a` (`docs: cross-reference SF-023+SF-025 + audit/17`) because their commit fired against the shared index after my `git add` but before my `git commit`. Net result intact (both audit/18 and the T11c progress section are inside `a1276a8a`); commit message understates scope. Different failure mode than the branch-swap pattern documented in `memory/multi-agent-git-race.md` — here HEAD stayed on `main` but a parallel agent's `git commit` consumed both their staged files AND mine. Memory file updated with the new lesson.
- **Verification skipped** (doc-only): no `functions/`, `firestore.rules`, or `lib/` changes → `npm run build` / `npm run test:rules` / `flutter analyze` / `flutter test` not run. Pre-commit `dart format` passed on the gitignore commit (642 files, 0 changed).
- **Deploy**: none. T11c proper deferred to follow-up PR (5 widget sites + clause drop + rules-test flip). SF-026 (Timestamp normalization) deferred to its own PR. No rules deploy, no CF deploy.
- **Commits**: `a1276a8a` (combined-with-terminal-A: cross-reference SF-023+SF-025 + audit/17 + T11c progress + audit/18) and `70c91f8e` (gitignore audit whitelist) on `main`. Pushed `b4eccec1..70c91f8e` to `origin/main`.

---

**Changelog 6.76**: Cleanup tasks — test debt + dependabot/stash triage docs + build-runner rule (2026-05-22):

- **Test debt — `availability_checker_test.dart` iCal callable mock**: post-SF-023, `_checkIcalEvents` routes through the `getUnitAvailability` callable via `FirebaseAvailabilityRepository`, so the old direct `fakeFirestore.collection('ical_events')` seed pattern no longer wired up. New `_FakeAvailabilityRepository implements IAvailabilityRepository` lives inline in the test file; iCal-specific tests now drive canned `AvailabilityWindow[]` directly. 40/40 tests pass.
- **New interface — `IAvailabilityRepository`** (`lib/features/widget/domain/services/i_availability_repository.dart`): minimal abstract with `fetchAvailability(...)`. `FirebaseAvailabilityRepository` now `implements` it (no behavior change). `AvailabilityChecker` field + constructor param re-typed to the interface so tests can inject a fake without booting Firebase. Calendar repository untouched (frozen per CLAUDE.md NIKADA NE MIJENJAJ).
- **`.claude/rules/build-runner.md` new + CLAUDE.md row**: fresh-clone `--delete-conflicting-outputs` recipe, regen triggers, distinguishing pub-cache desync from build_runner errors. Scoped to `pubspec.yaml`, `build.yaml`, `analysis_options.yaml`, `**/*.g.dart`. Version bumped 7.2 → 7.3.
- **Audit deliverables (execution deferred)**:
  - `audit/18-stash-classification-2026-05-22.md` — all 29 git stashes inventoried by SHA, classified DROP/INVESTIGATE/KEEP. Drops deferred to a quiet window: stash count grew 18 → 21 → 29 mid-session as sibling agents stashed concurrently, making index-based `git stash drop stash@{N}` race-prone (advisor flag).
  - `audit/18-dependabot-triage-2026-05-22.md` — 27 open dependabot branches classified against current `pubspec.yaml` + `functions/package.json` versions. Caught 4 MAJOR bumps the spec's mechanical "auto-merge patch+minor" would have merged: `eslint 8→10`, `stripe 19→20`, `package_info_plus 8→9`, `flutter_secure_storage 9→10`. Merges + PR closes deferred (CI watch impractical mid-race; destructive shared-state ops need user OK).
- **Multi-agent race observed**: stash count 18 → 21 → 29 in minutes, `.git/index.lock` briefly held by sibling, working tree mutated 3x with different file sets, branch swapped main↔cleanup mid-session, origin received independent pushes during fetch. Recovery: snapshotted stash SHAs upfront, cherry-picked sibling's `70c91f8e` (audit/**/*.md gitignore whitelist) onto cleanup branch to un-ignore audit deliverables, verified branch right before commit.
- **Verification**: `dart analyze` on the 4 touched files → no issues. `flutter test test/features/widget/data/helpers/availability_checker_test.dart` → 40/40 green. Pre-commit `dart format` clean (642 files, 0 changed).
- **Commits**: `55981882 chore: cleanup tasks…` on `chore/cleanup-stash-dependabot-test-debt-2026-05-22`, merged to `main` as `b6cd8f4a` and pushed to origin (`70c91f8e..b6cd8f4a`).
- **Known noise**: history contains both `70c91f8e` (sibling whitelist commit) and `cf1546a0` (cleanup-branch cherry-pick of the same diff). Idempotent — the +2 lines applied once; the duplicate is cosmetic in `git log` only. Squashable via interactive rebase + force-push if desired (force-push to `main` warned per CLAUDE.md).

---

**Changelog 6.75**: Widget price-row overflow + admin footer year (2026-05-22):

- **PriceRowWidget overflow fix** (`lib/features/widget/presentation/widgets/booking/price_row_widget.dart:43-91`): the row used `Row(mainAxisAlignment: spaceBetween, children: [Text(label), Text(amount)])` with no `Flexible`/`Expanded` wrapping on either side, so at ≤320px widths Croatian labels (e.g. `"Smještaj (5 noći)"`) + total amount visually clipped the right edge — the price `"€120.00"` rendered as `"€12"`. Wrapped label in `Flexible(child: Text(..., maxLines: 2, overflow: TextOverflow.ellipsis))` and amount in `Flexible(child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerRight, child: Text(...)))`. Label gives way first (ellipsis); amount scales down before clipping. Affects every `PriceRowWidget` caller — `PriceBreakdownWidget` (room price, extra guest fees, pet fees, additional services, total) which surfaces inside `CompactPillSummary` (mobile pill) and `PillBarContent._buildWideScreenLayout` (desktop split-pane).
- **Admin footer year dynamic** (`lib/features/admin/presentation/screens/admin_login_screen.dart:390`): `'© 2024 BookBed Inc. All rights reserved.'` → `'© ${DateTime.now().year} BookBed Inc. All rights reserved.'`. Copyright now self-updates each calendar year.
- **Deferred** (audit doc `audit/07-chrome-smoke-test.md` is missing from the repo, so the source descriptions and screenshots cannot be cross-checked):
  - Task 1 — Login CanvasKit text input sync gap (`enhanced_login_screen.dart`). `PremiumInputField` already has `autocorrect:false`, `enableSuggestions:false`; `_handleLogin` snapshots controllers into locals before async. No defect visible in code without primary repro.
  - Task 3 — Owner dashboard mobile heading truncation ("Nedav…", "Rezer…", "Fi…"). `RecentActivityWidget` already uses `AutoSizeText`/`minFontSize:14`; `_buildChartHeader` uses `Expanded`. No truncating widget located.
  - Task 4 partial — Admin "Em…" placeholder. Only `labelText:'Email Address'` and `hintText:'admin@bookbed.io'` candidates; neither obviously truncates without screenshots.
  - All three carried over to `docs/TODO.md`.
- **Verification**: `flutter analyze` on changed files → 0 issues. Pre-commit hook ran `dart format` → 641 files clean (0 changed).
- **Multi-agent git race encountered**: mid-task another agent twice swapped branch out from under me (`fix/widget-price-row-and-admin-footer-year` → `main` → `audit/booking-count-audit`), reverting working-tree edits once. Recovered by re-applying edits then stashing race-debris (other agents' `CLAUDE.md`, `.claude/rules/auth.md`, `.claude/rules/firestore.md`, `docs/CHANGELOG.md`, `docs/SECURITY_FIXES.md`). Sibling-agent leftovers preserved as `stash@{0}` and `stash@{1}` for their owners. Per `memory/multi-agent-git-race.md`: verified `git branch --show-current` immediately before `git add` and `git commit`.
- **Commits**: `bd329688 fix(ui): widget price row overflow + admin footer year` on `fix/widget-price-row-and-admin-footer-year`, merged to `main` as `a6374c35`. No origin push, no deploy.
- **Audit**: `audit/19-wave3-cleanup.md` (new).

---

**Changelog 6.74**: Cold-boot auth-race guard + dead CG index prune (2026-05-22):

- **Auth-race guard** (`lib/features/owner_dashboard/presentation/providers/owner_properties_provider.dart:52-67`): `propertyById` now awaits `enhancedAuthProvider.isLoading` before issuing the Firestore read. Previously, cold-boot deep links (e.g. `bookbed://owner/property/<id>`) fired the read before Firebase Auth had restored the session; Firestore rules then rejected the unauth read and Pigeon surfaced a noisy `FirebaseFirestoreHostApi.documentReferenceGet` stacktrace in logcat. The provider now holds in `AsyncLoading` until auth settles, so `PropertyEditLoader` (`lib/core/config/router_owner.dart:784`) keeps showing `UniversalLoader` instead of flashing. `ref.watch(enhancedAuthProvider)` (not `ref.read`) also satisfies the provider-cache-security rule in `.claude/rules/auth.md`. Scope deliberately limited to `propertyByIdProvider`; `unitByIdAcrossPropertiesProvider` left untouched — same shape but not flagged in audit/16-android.
- **2 dead CG indexes pruned** (`firestore.indexes.json`): removed `booking_services{booking_id+created_at}` (`COLLECTION_GROUP`) — zero `booking_services` refs anywhere in `lib/` / `functions/src/`; and `securityEvents{userId+timestamp}` (`COLLECTION_GROUP`) — collection used only as `users/{uid}/securityEvents` subcollection, never via `collectionGroup()`. 66 → 64 indexes. Firebase deploy reports "2 indexes defined in project not in file" — server-side orphans, harmless, not regenerated on subsequent deploys; `--force` deletion not in scope.
- **Verification**: `flutter analyze owner_properties_provider.dart` → 0 issues. `cd functions && npm run test:rules` → 28/28 green (2 suites). Pre-commit `dart format` clean (639 files, 0 changed).
- **Deploy**: indexes deployed to `bookbed-dev` only via `firebase deploy --only firestore:indexes --project bookbed-dev`. Prod untouched. No `git push`.
- **Multi-agent race encountered**: mid-task another agent repeatedly swapped working branch (`hotfix/widget-secrets-exfil`, `fix/t11c-proper-and-booking-count-audit`); fix-commit recovered via `git stash` + branch checkout + pop. Sibling-agent leftovers preserved in `git stash list`.
- **Docs**: `.claude/rules/auth.md` (new "Cold-boot auth-race guard" section with canonical pattern), `.claude/rules/firestore.md` (new "Dead indexes pruned" section logging the removals + verification command).
- **Commit**: `84163b6c` on `fix/auth-race-and-indexes-cleanup`, merged to `main` as `7cb0bac2`. Docs landed via `docs/auth-race-update` separately.

---

**Changelog 6.73**: CF error-class hygiene + dead callsite removal + audit/16 (2026-05-22):

- **6 catch-promote-internal sites fixed** (`functions/src/emailVerification.ts:464`, `stripeSubscription.ts:148`, `icalSync.ts:273`, `stripeConnect.ts:95, 179, 235`): added `if (error instanceof HttpsError) throw error;` guard at the top of each catch block. Prevents the handler's own client-fault HttpsErrors (`invalid-argument`, `not-found`, `failed-precondition`) from being unconditionally rewrapped as `internal`. Primary site `checkEmailVerificationStatus` previously returned HTTP 500 + `INTERNAL` for missing-email input; post-deploy returns HTTP 400 + `INVALID_ARGUMENT`. Five sibling sites in stripeSubscription/icalSync/stripeConnect had the same shape, all fixed. Secondary effect: Sentry noise drop, since `beforeSend` (v6.71) only filters client-fault HttpsErrors, not the over-promoted `internal` ones.
- **Dead Flutter callsite removed** (`lib/core/services/security_events_service.dart`): `_sendSuspiciousActivityEmail` method + `cloud_functions` import deleted. The backing CF `securityEmail.ts` was removed in commit `4cb5a391`; every new-device or new-location login was triggering `functions/not-found` in the Flutter client. Suspicious-login detection still writes to `security_events` Firestore collection unchanged — the audit trail is preserved.
- **3 new rules tests** (`functions/test/firestore_rules/bookings.test.ts`): clause-1 (`unit_id + status`) shape boundary — positive (both fields → unauth ALLOWED, T11c-pending widget path), `unit_id` alone (unauth DENIED), `status` alone (unauth DENIED). `npm run test:rules` 11/11 green.
- **Audit added**: `audit/16-cf-smoke-and-rules.md` — full 38-CF HTTP smoke matrix (callable + request endpoints, region-aware URLs, body-inspection verdict), rules-suite extension, perf baseline for 10 hot CFs. Live deployed-rules diff blocked on IAM (no `serviceUsageConsumer` on `bookbed-dev`); flagged as P3 followup.
- **Anti-pattern sweep**: 16 candidate `HttpsError("internal", …)` sites triaged across 12 files; 10 already had the guard or were no-anti-pattern (bare throws, no inner HttpsError in try). 6 TRUE POSITIVES fixed (above).
- **Co-existing in-flight (not part of this changelog)**: `functions/src/logger.ts` has uncommitted local modifications adding a centralized `CLIENT_FAULT_HTTPS_CODES` allowlist + `logError` downgrade to `WARN` for client-fault HttpsErrors. Complementary defense-in-depth at the logging layer; not authored by 6.73, untouched.
- **Verification**: `cd functions && npm run build` clean; `cd functions && npm run test:rules` 11/11; `flutter analyze` 0 new issues (1 pre-existing `marionette_flutter` dev import).
- **TODO.md**: P0.3 (dead callsite) marked done. P0.1 + P0.2 (prod deploys of `getBookingByStripeSession` + `sendOwnerEmail`) still pending — require explicit deploy authorization.
- **Security log**: `docs/SECURITY_FIXES.md` — added SF-022 entry covering both the catch-promote fix and dead callsite removal.
- **NOT shipped**: code on `main` working tree, NO commit, NO deploy. Awaiting user review.

---

**Changelog 6.72**: Sentry Dart env detection + iOS Firebase project contamination hardening + Wave 0 PROD cleanup (2026-05-21):

- **Sentry Dart env detection** (`lib/core/utils/sentry_env.dart` new; `lib/widget_main.dart:115`, `lib/main.dart:499` edited): mirrors yesterday's `functions/src/sentry.ts detectEnvironment()` (audit/11) on the Flutter side. Reads `Firebase.app().options.projectId` at runtime instead of the hardcoded `'production'` literal. Maps `bookbed-dev` → `development`, `bookbed-staging` → `staging`, `rab-booking-248fc` → `production`, anything else → `unknown`. Uses runtime project ID rather than `EnvironmentConfig.firebaseProjectId` because `widget_main.dart` never calls `setEnvironment` (audit/13).
- **iOS Firebase contamination hardening** (`lib/widget_main_staging.dart` new; 6 entry points edited): adds `kDebugMode` projectId asserts after every `Firebase.initializeApp` in `main.dart`, `main_dev.dart`, `main_staging.dart`, `main_prod.dart`, `widget_main.dart`, `widget_main_dev.dart`, and the new `widget_main_staging.dart`. Crashes early in debug if entry-point ↔ Firebase project mismatch. Defense against the Wave 0 root cause: `ios/Runner/GoogleService-Info.plist` hardcoded to PROD + default `flutter run` picks `lib/main.dart` (PROD options) + no native `FirebaseApp.configure()` → silent contamination on iOS dev testing. Documented in `.claude/rules/ios-development.md` (new) and referenced from `CLAUDE.md` Path-Scoped Rules table.
- **Deploy script fixes** (`scripts/deploy_dev.sh:10`, `scripts/deploy_staging.sh:10`): widget build target swapped from `lib/widget_main.dart` (PROD options) to `lib/widget_main_dev.dart` / `lib/widget_main_staging.dart`. Closes the dev/staging widget → prod Firebase exposure surface (audit/14). Scripts have been broken since `widget_main_dev.dart` was added 2026-01-10 (`a85a33f5`).
- **Sentry Dart fix deploy** (2026-05-21 ~20:50 UTC): owner+widget deployed to PROD via `firebase deploy --only hosting:owner,hosting:widget --project rab-booking-248fc`. Static-verified all 3 project ID literals + 4 env labels present in deployed `main.dart.js`. Runtime Sentry envelope verification structurally blocked by app's `PlatformDispatcher.instance.onError` swallower (`lib/main.dart:295-310`) which catches all uncaught errors and calls `LoggingService.log` (not `logError` → does not forward to Sentry). Code+static verify accepted by user.
- **Staging owner deploy** (2026-05-21 ~20:30 UTC): owner deployed to `bookbed-owner-staging.web.app` via `firebase deploy --only hosting:owner --project bookbed-staging` to validate the helper before prod cutover.
- **Wave 0 PROD contamination cleanup** (2026-05-21 ~20:23 UTC): deleted via `scripts/cleanup-prod-wave0-orphans.js --skip-stripe-check --execute`:
  - Auth user `wave0-smoke-202605181440@bookbed.test` (UID `qoN6aykKwqZI4n9REgqXfEFG8KM2`)
  - Firestore `users/qoN6...` doc
  - `properties/6VCCLt8rnSokrIani9oU` "Wave Test Vila" + nested `units/seg85UhyMQM8hw7ZpLhq` "Apartman A" + `widget_settings/seg85UhyMQM8hw7ZpLhq` (latter was a subcollection-walk surprise — earlier audits had missed it)
  - Total PROD properties 14 → 13. Verification rerun: all artifacts absent.
  - **Stripe Connect `acct_1TYSMdPWhhVc6lN0` NOT dissolved by this run** — `--skip-stripe-check` flag bypasses precheck. Account remains active in BookBed live mode; orphan record now (no linked Firestore user). Manual dissolution still required via Stripe Dashboard.
- **Audit artifacts added**: `audit/12-widget-e2e-dev.md` (partial widget E2E smoke, browser-drive blocked by missing Chrome DevTools MCP), `audit/13-sentry-dart-fix.md` (Sentry Dart fix narrative + verification posture), `audit/14-deploy-scripts-mismatch.md` (deploy script audit + Wave 0 contamination discovery), `audit/15-prod-contamination-deep-check.md` (Stripe Connect / FCM / OAuth deep check + cleanup execution log). Migration log: `audit/migrations/2026-05-21-prod-wave0-cleanup.log`.
- **Commits**: `c8d0bf8f fix(sentry): detect Dart-side env from Firebase project ID`, `0357f80d Merge: Sentry Dart env detection`, `6d8dbad5 fix(env): iOS Firebase project contamination hardening`, `3986962f Merge: iOS Firebase env hardening + cleanup script (gated)` on `main`.
- **Branch**: `fix/sentry-dart-env-and-seed` and `fix/ios-firebase-env-hardening` merged into `main` via `--no-ff`, both pushed to origin.
- **NOT yet shipped**: dev + staging widget redeploys with the new env-correct entry points. Next ticket. Awaiting user manual Stripe Connect dissolution before declaring Wave 0 cleanup fully complete.

---

**Changelog 6.71**: Sentry HttpsError noise filter + prod orphan-function cleanup (2026-05-21):
- **Filter** (`functions/src/sentry.ts`): added `beforeSend` to `Sentry.init` that drops events where the original exception is an `HttpsError` with a client-fault `code`. Dropped codes: `invalid-argument`, `unauthenticated`, `permission-denied`, `not-found`, `already-exists`, `failed-precondition`, `out-of-range`, `resource-exhausted`, `cancelled`. Server-fault codes (`internal`, `unknown`, `data-loss`, `unavailable`, `deadline-exceeded`, `aborted`) still report.
- **Why**: Sentry's `@sentry/node` firebase otel auto-instrumentation (`mechanism: auto.firebase.otel.functions`) captures every thrown `HttpsError` from `onCall` handlers, including 4xx-equivalent client mistakes. Three noisy issues in Sentry (FLUTTER-6C `getBookingByStripeSession` `invalid-argument`, FLUTTER-6E `verifyBookingAccess` `invalid-argument`, FLUTTER-6G `verifyBookingAccess` `permission-denied`) were all of this class.
- **Discriminator**: `err.httpErrorCode !== undefined && typeof err.code === "string" && clientFaultCodes.has(err.code)`. The `httpErrorCode` field is unique to firebase-functions `HttpsError` (set by `errorCodeMap[code]` in `https.js:81`) so non-Firebase errors with a `.code` string (Firestore errors etc.) are not falsely dropped.
- **Deploy**: dev (`bookbed-dev`) commit 8c9ebf1d on `hotfix/widget-secrets-exfil` (deployed in-place); prod (`rab-booking-248fc`) via cherry-pick onto `main` (commit 16224575 → origin/main), then `firebase deploy --only functions --project production`.
- **Prod orphan-function cleanup**: 5 functions still live on prod but already deleted from source (commits `ebddecaf feat(kill): remove comebackReminder` + `c3465034 feat(kill): remove Booking.com + Airbnb OAuth integration`). Dev had already pruned these; prod was out of sync. Deleted via `firebase functions:delete <name> --project production --force --region <region>`:
  - `comebackReminder` (europe-west1)
  - `handleAirbnbOAuthCallback`, `initiateAirbnbOAuth` (us-central1)
  - `handleBookingComOAuthCallback`, `initiateBookingComOAuth` (us-central1)
- **Branch**: `fix(sentry)` commit lives on both `hotfix/widget-secrets-exfil` (original) and `main` (cherry-pick).
- **Future**: when `hotfix/widget-secrets-exfil` lands on prod, no Sentry-filter conflict — the same file change is already on prod. Cherry-pick will reconcile cleanly.
- **NOT shipped on prod yet**: the rest of the `hotfix/widget-secrets-exfil` branch (widget_secrets split, `ICAL_TOKEN_PEPPER`, `ALLOWED_SUBSCRIPTION_PRICE_IDS`, `RESEND_API_KEY` allowlist enforcement). Three per-env prereqs required first — see `memory/widget-secrets-exfil-deploy-prereqs.md`.

---

**Changelog 6.70**: Wave 0 promote wrap-up (2026-05-18):
- **Scope**: 8 Wave 0 branches (T7/T8/T10/T11/T12) + 3 post-test fixes (null.toString hardening, ErrorBoundary reset + AI chat UX, env-url centralization) merged to `main`. Tags `pre-wave0-promote` (`eadec3cc`) and `post-wave0-stable` (`a480e5f3`) pushed to origin.
- **Stripe SSRF allowlist made env-aware** (`functions/src/stripePayment.ts`): `const ALLOWED_RETURN_DOMAINS` → `function getAllowedReturnDomains()`. Reads `process.env.GCP_PROJECT` / `GCLOUD_PROJECT` / `FUNCTIONS_EMULATOR`; appends `bookbed-widget-dev.web.app` + `bookbed-owner-dev.web.app` for dev, `bookbed-widget-staging.web.app` + `bookbed-owner-staging.web.app` for staging. Two callers updated (`isAllowedReturnUrl()`, security-log branch). `ALLOWED_WILDCARD_DOMAINS` untouched. Deployed to `bookbed-dev` only (`createStripeCheckoutSession(us-central1)`); prod (`rab-booking-248fc`) and staging untouched.
- **Jest config pre-existing fragility patched**: `functions/jest.config.js` now has `testPathIgnorePatterns: ["/node_modules/", "<rootDir>/test/firestore_rules/"]` so plain `npm test` skips the emulator-required suite (152/152). `functions/package.json` `test:rules` script adds CLI `--testPathIgnorePatterns=/node_modules/` to override the config-level ignore and re-include rules (8/8 with emulator). Don't change either side without testing both.
- **Conflicts resolved during merges** (6 total across 3 merges):
  - `fix/null-tostring-hardening`: 1 — `docs/TODO.md` (both sides added independent sections; kept both, null-tostring-related first).
  - `fix/error-boundary-and-chat-ux`: 3 — `CLAUDE.md` (kept context-mode section + v7.1 bump), `docs/CHANGELOG.md` (dropped redundant "Reserved v6.67" placeholder), `ai_chat_provider.dart` (dropped orphan `final errorMsg = e.toString();` left by T7).
  - `fix/environment-url-centralization`: 2 — `.claude/rules/widget.md` (dropped obsolete "Brittle host check" + "Hardcoded literals" sections, kept "Silent debug guards", took post-fix "Host comparisons"), `docs/CHANGELOG.md` (env-url entry bumped from claimed 6.67 → 6.69 to avoid collision with error-boundary 6.67).
- **Resmoke** (Phase 4, against `bookbed-dev`):
  - CF probes — `getBookingByStripeSession`: 404 ✓, `verifyBookingAccess`: 404 ✓, `createStripeCheckoutSession`: 400 INVALID_ARGUMENT ✓ (no 500 from SSRF regression).
  - Live rules regression — `stripe_session_id` query 403 ✓, `booking_reference` query 403 ✓, `unit_id+status` query 200 ✓ (T11c-deferred, intentional).
  - `flutter analyze` 0, `flutter test` 1100/1100, `npm test` 152/152, `npm run test:rules` 8/8.
- **Outstanding** (deferred to Wave 1):
  - 12 branches awaiting archive-and-delete (8 Wave 0 + 1 test/wave0-integration + 3 helper branches created mid-promote: `fix/stripe-dev-allowlist`, `chore/jest-exclude-rules-from-default`, `chore/jest-rules-script-fix`).
  - 9 stashes awaiting triage (`stash@{0}-{8}` Wave 0-era; full table in `audit/09-wave0-promote-report.md`).
  - Prod cutover (`rab-booking-248fc`) — Wave 0 changes are dev-only until separate prod deploy.
  - Stripe allowlist proper env-var refactor (forward-looking — current pattern is project-id-conditional).
  - T11c (drop `unit_id+status` clause) blocked on `getUnitAvailability` Cloud Function.
- **Audit doc**: `audit/09-wave0-promote-report.md` (committed `31c47c78`).
- **Multi-agent git race surfaced**: 5+ parallel claude sessions on host caused branch swaps during pre-flight. Documented in MEMORY → `wave0-promote-2026-05-18.md`. Future promote runs should serialize via external mutex.

---

**Changelog 6.69**: Environment URL Centralization (T13):
- **`EnvironmentConfig` API extended** (`lib/core/config/environment.dart`):
  - New getters: `widgetHost`, `dashboardHost`, `marketingHost`, `isWidgetHost()`, `isMarketingHost()`.
  - Dev `widgetBaseUrl`: `http://localhost:5000` → `https://bookbed-widget-dev.web.app` (real Firebase Hosting site, no emulator dependency).
  - Dev `dashboardBaseUrl`: `http://localhost:5001` → `https://bookbed-owner-dev.web.app`.
  - `marketingHost` returns `'bookbed.io'` for all envs (no dev/staging marketing hosting target exists in `firebase.json`).
- **6 prod-path callsites refactored** (replaced `view.bookbed.io` / `app.bookbed.io` literals with `EnvironmentConfig` getters):
  - `widget/subdomain_service.dart:51` — host-skip check
  - `widget/booking_view_screen.dart:107` — host-skip check
  - `widget/booking_widget_screen.dart:4036` — marketing-domain rewrite (uses `isMarketingHost()`)
  - `owner_dashboard/embed_widget_guide_screen.dart` — removed `_subdomainBaseDomain` const + 3 usages
  - `owner_dashboard/embed_code_generator_dialog.dart` — removed duplicate `_defaultWidgetBaseUrl` + `_subdomainBaseDomain` consts + 3 usages
  - `subscription/subscription_screen.dart` — removed `_webDashboardUrl` const, snackbar copy now interpolates `dashboardHost`
- **Latent staging bug fixed**: `host.startsWith('view.')` in `subdomain_service.dart:51` + `booking_view_screen.dart:107` would have parsed `'staging'` as a client subdomain on staging widget host. Replaced with `host == EnvironmentConfig.widgetHost`.
- **Stays hardcoded** (intentional): iCal UID `@bookbed.io` (RFC 5545 stable identifier), embed-snippet HTML for owner paste targets.
- **Follow-up**: `functions/src/stripePayment.ts` SSRF allowlist keyed on `.view.bookbed.io` — dev Stripe `returnUrl` now resolves to `bookbed-widget-dev.web.app` and will fail SSRF check. Backend env (`functions/.env.bookbed-dev`) needs `WIDGET_ALLOWED_HOSTS` extended.
- **Branch**: `fix/environment-url-centralization`.
- **Audit doc**: `audit/08-environment-url-centralization.md`.
- **Closes**: `audit/04c-hardcoded-urls.md` §3.1 (M7) + `audit/07-ios-smoke-test.md` "Hardcoded prod URLs".

---

**Changelog 6.68**: `null.toString()` hardening in widget URL building (2026-05-18):

- **Root cause** (`audit/08-null-tostring-fix.md`): `Uri()` constructor's `queryParameters` encoder calls `.toString()` on every value. In Flutter web (dart2js / CanvasKit) this becomes literal `null.toString()` at the JS layer and throws `TypeError: Cannot read properties of null (reading 'toString')`. Dart's sound null safety does not catch this because `Uri()` accepts `Map<String, dynamic>`.
- **Fix** (`lib/features/widget/presentation/screens/booking_view_screen.dart:191-198, 235-242`): coerce nullable `widget.bookingRef` / `widget.email` with `?? ''` before passing to `Uri.queryParameters`. The `if (widget.token != null) 'token': widget.token` collection-if pattern is preserved (Dart's flow analysis correctly narrows inside the if body).
- **Scope confirmed clean** via grep: `booking_widget_screen.dart`, `booking_confirmation_screen.dart`, `enhanced_login_screen.dart` — all `.toString()` and `jsonEncode` call sites already guarded by previously-merged T8 silent-catches work (e.g. `_safeErrorToString` helper at `booking_widget_screen.dart:131-143`).
- **Validation**: `flutter analyze` clean, `flutter test` 1100/1100, jest 152/152.
- **Out of scope**: Wave 0 smoke test also reported login-form submit crash with the same JS error type; that one is **CanvasKit text-input sync** (different bug class — TextEditingController drifts from DOM `<input>` value), tracked separately. Widget `additional_services` failed-precondition trigger was already closed by the dev composite-index deploy.

---

**Changelog 6.67**: Error-handling UX fixes (Wave 0 smoke follow-up):
- **Sticky ErrorBoundary** (`lib/core/error_handling/error_boundary.dart`):
  - `_tryAgain` / `_navigateToHome` only navigated — they never cleared the cached `_errorDetails`, so the boundary kept repainting the error widget even after the user "recovered". Reported in `audit/07-ios-smoke-test.md` issue #1.
  - Fix: new private `_resetErrorBoundary(context)` walks up with `findAncestorStateOfType<_ErrorBoundaryState>()` and nulls `_errorDetails` via `setState`. Both action handlers call it first. `mounted` guard inside.
- **Raw Gemini error leak in AI chat** (`lib/features/owner_dashboard/presentation/providers/ai_chat_provider.dart`, `…/screens/guides/ai_assistant_screen.dart`):
  - When Vertex AI is disabled on a project (`firebasevertexai.googleapis.com` off), the SDK throws `ServiceApiNotEnabled` with a full GCP error message including project number + console URL. The notifier was setting `state.error = 'DEBUG: $errorMsg'` and the UI banner had a fall-through that displayed it verbatim. Reported in `audit/07-chrome-smoke-test.md` line 539 ("Gemini call — FAIL").
  - Fix: new `_classifyGeminiError(Object e)` maps any `FirebaseAIException` (incl. `ServiceApiNotEnabled`, `QuotaExceeded`, `UnsupportedUserLocation`, `ServerException`, `InvalidApiKey`) to sentinel `'ai_unavailable'`, with string-match fallback on `permission_denied | has not been used | unavailable | resource_exhausted` for raw GCP errors that didn't get wrapped. Everything else → `'ai_error'`. UI banner branches on `'ai_unavailable'` → `l10n.aiAssistantUnavailable`. Unknown sentinels now fall back to the localized generic string instead of rendering raw exception text.
  - Full exception still routed to `LoggingService.logError` for Sentry/Crashlytics.
  - One stray `print('[AiChat] ERROR: $e')` in the same catch block removed (was leaking raw error to dev console). 13 other unrelated `print(` calls in `_aiModelProvider` / `sendMessage` instrumentation remain on `main` — separate cleanup.
- **New l10n keys** (`lib/l10n/app_en.arb`, `lib/l10n/app_hr.arb`):
  - `aiAssistantUnavailable` — "AI Assistant is temporarily unavailable. Please try again in a moment." / "AI Asistent trenutno nije dostupan. Pokušajte ponovno za nekoliko trenutaka."
  - `flutter gen-l10n` regenerated `app_localizations*.dart`.
- **StateNotifier deviation**: source prompt suggested routing l10n through `AppLocalizations.of(context)` inside the provider. `StateNotifier` has no `BuildContext`, so the provider sets a sentinel and UI does the lookup — same outcome, correct layering. Documented in `audit/08-error-handling-fixes.md`.
- **Verification**: `flutter analyze` = 0 issues, `flutter test` = 1100 tests pass. Runtime (Marionette / chrome-devtools) verification deferred — no live sim / widget server in this session.
- **Branch**: `fix/error-boundary-and-chat-ux` (NOT pushed, NOT merged).
- **Audit doc**: `audit/08-error-handling-fixes.md`.

---

**Changelog 6.66**: Echo Detection Timezone Fix + Interval Subtraction:
- **Timezone Bug in `generateNightSet()`** (`echoDetection.ts`):
  - `setUTCHours(0,0,0,0)` + `toISOString()` produced wrong date for bookings stored at 22:00 UTC (= midnight Zagreb CEST)
  - Example: Aug 17 booking at `2026-08-16T22:00:00Z` → normalized to `"2026-08-16"` instead of `"2026-08-17"`
  - Caused 13/14 containment instead of 14/14 → false 1-night "new" range → **overbooking on Timeline Calendar**
  - Fix: `toLocaleDateString('en-CA', {timeZone: 'Europe/Zagreb'})` with fallback, noon-UTC iteration (DST-safe)
- **Interval Subtraction (`save_trimmed`)** (`echoDetection.ts`):
  - New `RecommendedAction`: `save_trimmed` — imports ONLY genuinely new date ranges from aggregator events
  - `groupConsecutiveNights()` + `isNextDay()` — groups unblocked nights into contiguous ranges
  - Overrides `flag_review` when containment detects partial overlap (trimming is more precise than flagging)
- **New Tests** (`echoDetection.test.ts`):
  - Timezone offset test: booking at 22:00 UTC vs VEVENT at 06:00 UTC → same Zagreb date → `auto_skip`
  - Zagreb YYYY-MM-DD format sanity check
  - 8 interval subtraction tests (real-world Adriagate, 100% containment, 0% overlap, multiple ranges, turnover days, save_trimmed priority)

---

**Changelog 6.65**: AI Branch Audit #2 — Cherry-picked Bug Fixes from 3 Branches:
- **4 branches audited** (`fix-memory-resource-leaks`, `audit-ci-cd-updates`, `audit-auth-user-management`, `audit-monthly-architecture-audit`):
  - All 4 had same regressions: dependency downgrades, SF-008 removal, accountType sync removal, firestore rules rollback, docs rollback — all skipped
- **Apple Sign-In Name Propagation Fix** (`enhanced_auth_provider.dart`):
  - **REAL BUG** confirmed by Firestore data — native iOS Apple Sign-In users had empty `first_name`/`last_name`
  - Root cause: `appleCredential.givenName`/`familyName` available from Apple SDK but never passed to `_createUserProfile()`
  - Firebase does NOT auto-set `displayName` from native OAuthCredential flow (confirmed: both Apple users had `displayName: null`)
  - Fix: Added `firstName`/`lastName` params to `_createUserProfile()`, capture from `appleCredential`, fallback to `displayName` parsing
  - `displayName` now constructed from names if Firebase doesn't set it
- **AI Chat StateNotifier Mounted Checks** (`ai_chat_provider.dart`):
  - Added `if (!mounted) break/return` at 4 points during streaming response
  - Prevents "Bad state: Tried to use StateNotifier after dispose" if user navigates away during AI streaming
- **TextEditingController Disposal** (`email_verification_screen.dart`):
  - Wrapped both `showDialog` calls in `try/finally` with `controller.dispose()`
  - Minor memory leak fix — controllers created in methods weren't disposed
- **Widget Deploy Pipeline Fix** (`deploy-widget.yml`):
  - Added `cp web/bookbed-overlay.js build/web_widget/` step before Firebase deploy
  - Fixes MEMORY #21 critical deploy bug — overlay.js was never included in CI deploys
  - Without this, iframe scroll-trap fix didn't work on external sites after CI deploy
- **Navigator.Pop → Safe GoRouter Pattern** (`admin_shell_screen.dart`, `unit_form_screen.dart`):
  - Replaced `Navigator.of(context).pop()` with `context.canPop()` + `context.pop()` + fallback `context.go()`
  - 4 places in admin drawer + 1 in unit form save — prevents crash when no previous route on stack
- **Sentry/Logging Improvements** (5 provider files):
  - `calendar_drag_drop_provider.dart` — stackTrace added to move/undo catch blocks
  - `overbooking_detection_provider.dart` — `debugPrint` → `LoggingService.logInfo/logError`
  - `owner_bookings_provider.dart` — error logging for fetch booking by ID
  - `unified_bookings_provider.dart` — error logging for iCal events fetch (was empty `catch (_)`)
  - `platform_connections_provider.dart` — try/catch with logging + rethrow for remove connection
- **Key files**: `enhanced_auth_provider.dart`, `ai_chat_provider.dart`, `email_verification_screen.dart`, `deploy-widget.yml`, `admin_shell_screen.dart`, `unit_form_screen.dart`

**Changelog 6.64**: AI Branch Audit — Cherry-picked Security & CI Fixes:
- **CI Fix** (`.github/workflows/ci.yml`):
  - Disabled CodeQL Analysis job (requires GitHub Advanced Security — not available on private repos)
  - Changed Trivy security scan from SARIF upload to table output (SARIF upload also requires Code Scanning)
  - Both jobs were failing on every CI run — now skipped cleanly
- **EMAIL_SYSTEM.md** — Added `trial-expired.ts` and `trial-expiring-soon.ts` to template table and directory tree (existed since Feb 3 but were missing from docs, count 16→18)
- **Stripe accountType sync** (`functions/src/stripePayment.ts`):
  - Added `accountType: "premium"` to subscription activation webhook
  - Prevents accountStatus/accountType desync (MEMORY.md #23) when owner subscribes
  - Currently inactive code path (subscriptions not yet enabled), but ready for future
- **SF-008 server-side completion** (`functions/src/atomicBooking.ts`):
  - Added 1000 char limit on booking notes server-side
  - Client-side validation existed, server-side was missing
- **Firestore rules** (`firestore.rules`):
  - Added explicit `allow read, write: if false` for `oauth_states` and `sync_failures` collections
  - Both are Cloud Functions-only collections (Admin SDK bypasses rules)
  - Makes implicit default-deny explicit and documented
- **8 AI branches audited** (Jules/Sentinel/Bolt monthly audit Feb 2026):
  - All had dependency downgrades (branch forked before `3a29695c` bump) — skipped
  - All had same CI fix — applied once
  - Skipped: UTC timezone changes (theoretical), min-stay gap re-add (would revert `42157fa2`), auto-cancel refactor (risky rename), FCM push feature (new feature), Navigator.pop fixes (saved as TODO)
- **Key files**: `ci.yml`, `stripePayment.ts`, `atomicBooking.ts`, `firestore.rules`, `EMAIL_SYSTEM.md`

**Changelog 6.63**: Scroll Overlay v5, iCal HEAD Fix & Conflict Badge UI:
- **Scroll Overlay v5 — Universal iframe scroll-trap fix** (`web/bookbed-overlay.js`):
  - External JS served at `view.bookbed.io/bookbed-overlay.js` — host pages add single `<script>` tag
  - Auto-detects BookBed iframes (`src*="view.bookbed.io"`), no wrapper divs needed
  - Uses `position:fixed` + `getBoundingClientRect()` — works in any DOM structure (WordPress, React, Tailwind, etc.)
  - Guard div on `<body>` with RAF-throttled scroll/resize sync
  - Desktop only (`pointer: fine` media query) — mobile/touch unaffected
  - Click to interact → mouseleave restores scroll protection (Google Maps pattern)
  - MutationObserver watches for dynamically added iframes (SPA support)
  - **Previous versions failed**: v2 caused iframe reload (DOM move), v3 left iframe non-interactive, v4 wrong positioning with `offsetTop` in nested containers
- **iCal Export HEAD Request Fix** (`functions/src/icalExport.ts`):
  - iCal validators send HEAD requests to check content-type before GET
  - Was rejected with 405 Method Not Allowed — now allows HEAD alongside GET
  - Deployed to production
- **Calendar Conflict Badge** (`calendar_top_toolbar.dart`, `owner_app_drawer.dart`):
  - Conflict badge extracted from popup menu to standalone badge next to overflow menu icon
  - Always visible when conflicts exist (not hidden in dropdown)
  - Conflict count badge added to Calendar expansion tile in drawer
  - Uses `overbookingConflictCountProvider` for real-time count
- **Embed Guide — Scroll Protection Section** (`embed_widget_guide_screen.dart`):
  - "For Developers" section now includes scroll protection script tag with copy button
  - Explains the overlay pattern and provides the `<script>` tag to copy
- **.gitignore KB File Exception**: Fixed `assets/kb/bookbed_knowledge_base.md` being gitignored by `*.md` rule — CI fix
- **Version bump**: 1.0.9+18 deployed to Play Store
- **Key files**: `web/bookbed-overlay.js`, `calendar_top_toolbar.dart`, `owner_app_drawer.dart`, `icalExport.ts`

**Changelog 6.62**: AI Assistant Redesign, KB Consolidation & Quick Edit Delete:
- **AI Assistant UI Redesign** (`ai_assistant_screen.dart`):
  - New glassmorphism illustration, redesigned chat bubbles with gradients/shadows
  - Desktop split view with chat list + active chat panel
  - Streaming fix: duplicate bubbles resolved (new list per state update)
  - Empty state: illustration/title/subtitle/New Chat button grouped in same Column
  - Consent screen with privacy items before first use
- **AI Knowledge Base Consolidation**:
  - Removed 8 separate chatbot KB files (`docs/AI_Chatbot_Instructions/`)
  - Consolidated into single `assets/kb/bookbed_knowledge_base.md` (gitignored, in pubspec assets)
  - Professional tone ("BookBed tim" instead of personal references)
  - Added Section 10: AI Assistant documentation
  - Removed specific web dev pricing (directs to consultation instead)
  - Contact emails: `info@book-bed.com` for support, `dusko@book-bed.com` for web dev only
- **AI Provider Cleanup** (`ai_chat_provider.dart`):
  - Removed hardcoded predefined answers and blocked keywords
  - Consolidated to unified KB-driven approach
  - Switched from `FirebaseAI.vertexAI()` to `FirebaseAI.googleAI()` (Gemini Developer API)
  - Model: `gemini-2.5-flash-lite` (cheapest, replaces retired 2.0-flash-lite)
- **Booking Quick Edit Delete Button** (`booking_inline_edit_dialog.dart`):
  - Added red "Delete" button to footer alongside Cancel/Save
  - Mobile: Delete + Cancel side by side below Save button
  - Desktop: Delete left-aligned, Cancel + Save right-aligned
  - Uses shared `CalendarBookingActions.deleteBooking()` with confirmation dialog
- **Localization**: Updated EN/HR strings for AI chatbot consent and UI changes
- **Key files**: `ai_assistant_screen.dart`, `ai_chat_provider.dart`, `booking_inline_edit_dialog.dart`, `assets/kb/bookbed_knowledge_base.md`

**Changelog 6.61**: AI Chatbot, Timeline Scroll Sync Fix & Booking Card Improvements:
- **AI Assistant Chatbot** (`ai_assistant_screen.dart`, `ai_chat_provider.dart`):
  - Gemini 2.5 Flash Lite via Firebase AI Logic (`FirebaseAI.googleAI()`)
  - Knowledge base loaded from `assets/kb/bookbed_knowledge_base.md`
  - Predefined answers for common questions (pricing, Stripe, iCal, widget, units)
  - Blocked keywords filter for off-topic technical questions
  - GDPR consent stored in Firestore (`users/{uid}/data/ai_consent`)
  - Chat history in Firestore (`users/{uid}/ai_chats/{chatId}`)
  - Daily message limit: 30 messages per day
  - Streaming responses with real-time UI updates
  - Language detection (HR/EN) for responses
  - Firestore rules deployed for `ai_chats` subcollection
- **Timeline Calendar Scroll Sync Fix** (`timeline_calendar_widget.dart`, `owner_timeline_calendar_screen.dart`):
  - Split `_updateVisibleRange()`: date reporting runs ALWAYS (except TELEPORT), window management gated by flags
  - Removed `_isProgrammaticNavigation` from parent — `forceScrollKey` prevents feedback loop
  - Auto-extend forward when scrolling near end of visible window
  - Debug log cleanup: removed 68+ print statements
- **Month Calendar Fixes** (`month_calendar_screen.dart`):
  - FittedBox fix: replaced with Flexible + TextOverflow.ellipsis per text widget
  - DRY `_getBookingColor` as static method (reused by `_BookingDataSource`)
  - DateTime negative difference: `.clamp(0, 9999)` in booking_inline_edit_dialog
- **Booking Card Header** (`booking_card_header.dart`):
  - Status badge AND booking reference both fully visible
  - Replaced `Spacer()` with `SizedBox(width: 8)` gap
  - Badge: `Flexible(flex: 0)`, Reference: `Expanded` + `Align(centerRight)`
  - Removed unused `importedGuestName` parameter
- **Imported Reservation Visibility** (`booking_action_menu.dart`, `smart_booking_tooltip.dart`):
  - Platform name prominently displayed in purple header (16px bold white)
  - "Manage on" text enlarged from 12→14px with w600 weight
  - External booking badge enlarged in tooltip (icon 14px, text 12px, w700)
- **Dependencies**: `firebase_app_check` upgraded `^0.3.1+6` → `^0.4.1+4`
- **Key files**: `ai_chat_provider.dart`, `ai_assistant_screen.dart`, `ai_chat_repository.dart`, `ai_chat.dart`

**Changelog 6.60**: Security Hardening, Code Quality & Test Coverage:
- **IP-Based Rate Limiting on 4 Endpoints** (Cloud Functions):
  - Created shared `functions/src/utils/ipUtils.ts` — `getClientIp()` + `hashIp()` (SHA-256)
  - `emailVerification.ts`: 10 req/hr per IP (send verification code)
  - `passwordReset.ts`: 5 req/hr per IP (password reset email)
  - `verifyBookingAccess.ts`: 30 req/hr per IP (booking lookup)
  - `icalExport.ts`: 60 req/hr per IP (iCal feed requests, returns 429)
  - `authRateLimit.ts`: Refactored to use shared `ipUtils.ts` (was inline)
  - All use in-memory `checkRateLimit()` — resets on cold start, per-instance
  - Fixed missing `logWarn` imports in `emailVerification.ts` and `passwordReset.ts`
- **print() → LoggingService Migration** (Flutter):
  - `analytics_service.dart`: Full rewrite — all 20+ `print()` → `LoggingService.logDebug()`
  - `firebase_owner_bookings_repository.dart`: Warning log for failed booking parse
  - `email_verification_dialog.dart`: 8x `print()` → `LoggingService.logDebug/logError()`
  - Errors now include stack traces and go to Sentry automatically
- **Test Coverage** (manually copied from `test-coverage-improvement` branch):
  - `atomicBooking.test.ts`: 6 tests — validation, pricing, permissions
  - `authRateLimit.test.ts`: 5 tests — login/registration rate limiting (updated for SHA-256 hash)
  - `bookingManagement.test.ts`: 6 tests — CRUD operations
  - `passwordHistory.test.ts`: 6 tests — password history checks
  - `stripePayment.test.ts`: +8 lines — mock logger (fixes test isolation)
  - All 115 tests passing
- **UI Fix**: Removed unit icons from iCal Export page unit list (cleaner layout)
- **Branches Analyzed & Skipped**:
  - `security-scan-2025-02-03`: Encryption improvement (random IV) — useful but rollback risk
  - `security-scan-2025-02-03`: iCal notes removal — dead code (already removed in 6.56 GDPR)

**Changelog 6.59**: Syncfusion Month Calendar with Custom Cell Builder:
- **New Screen** (`calendar/month_calendar_screen.dart`):
  - Syncfusion Flutter Calendar with Month + Schedule views (2-view toggle)
  - Custom `monthCellBuilder` — date number (top-left), booking count badge (top-right), status dots (bottom)
  - Today highlight with `CircleAvatar`, leading/trailing month dates faded
  - Min/max date boundaries (1 year back, 2 years forward)
  - Unit filter dropdown with `InputDecorationHelper` styling
  - Status legend bar (confirmed/pending/completed/cancelled)
  - Custom `appointmentBuilder` with platform icons and conflict warnings
  - Schedule view with detailed appointment cards (guest name, unit, nights, status badge)
  - Tap appointment → `BookingInlineEditDialog`, tap empty date → `BookingCreateDialog`
  - Skeleton loader while data loads
- **Drawer Navigation** (`owner_app_drawer.dart`):
  - Calendar now uses expandable `_PremiumExpansionTile` with two sub-items:
    - Timeline Calendar (`/owner/calendar/timeline`)
    - Month Calendar (`/owner/calendar/month`)
- **Router** (`router_owner.dart`):
  - Added `OwnerRoutes.calendarMonth = '/owner/calendar/month'`
  - Added GoRoute with fade transition for `MonthCalendarScreen`
- **Dependencies**: `syncfusion_flutter_calendar: ^28.2.6` added to `pubspec.yaml`
- **Key files**: `month_calendar_screen.dart`, `router_owner.dart`, `owner_app_drawer.dart`

**Changelog 6.58**: Dynamic iCal Export URLs from Firestore Feeds:
- **Dynamic Platform Dropdown** (`ical_export_list_screen.dart`):
  - Replaced hardcoded 5-platform list with dynamic URLs from user's actual iCal import feeds
  - Dropdown selector auto-generates `?exclude=` URL per platform
  - Generic "Other / Google Calendar" option always available (no exclude param)
  - Deduplication by exclude value (2 Booking.com feeds → 1 URL card)
  - `_sanitizeSource()` mirrors Cloud Functions `sanitizeSource()` exactly
- **Dialog Redesign**:
  - Custom `Dialog` with dark/light theme support (was `AlertDialog`)
  - Uses `DropdownButton` (not `DropdownButtonFormField` — causes `child!.hasSize` crash in `Flexible > SingleChildScrollView`)
  - `StatefulBuilder` for local state, `icalFeedsStreamProvider.future` for async data
  - Platform icons/colors derived from `IcalFeed.platform` and `customPlatformName`
- **Documentation Sections Improved**:
  - Benefits: removed repetition (was 4 overlapping points → 4 distinct: Calendar Sync, Platform Sync, Auto Updates, Reminders)
  - Steps: rewritten for dropdown flow (was describing old all-cards-at-once UI)
  - Dialog texts: consolidated `platformUrlDesc` and `hubSpokeNote` (were saying the same thing)
  - Hero card: fixed bug showing "no units" text even when units exist (new `icalExportHeroDesc` key)
- **Key files**: `ical_export_list_screen.dart`, `app_en.arb`, `app_hr.arb`

**Changelog 6.57**: iCal Echo Detection Engine with Containment Analysis:
- **Echo Detection Engine** (`functions/src/utils/echoDetection.ts`):
  - 5-factor weighted scoring: Date Match (25%), Duration Match (25%), Export Correlation (25%), Platform Re-export (15%), Temporal (10%)
  - Export correlation INFERRED from existing data (no separate tracking needed): native booking + known re-exporter = 1.0
  - Confidence thresholds: >=95% auto-skip, 85-94% flag for review, <85% save as unique
  - **Containment analysis** for merged echoes (N:1 matching): detects when aggregator merges N adjacent bookings into 1 VEVENT
  - Checks if 100% of incoming nights are already blocked by union of existing bookings
  - Interval union matching verifies contiguous booking chain coverage
  - Safety: only runs for aggregator sources when 1:1 matching gives <95%
- **Platform Classification** (`functions/src/utils/platformClassification.ts`):
  - Authoritative: Booking.com, Airbnb (safe, no re-export)
  - Aggregator: Adriagate (re-exports, merges blocks), Holiday-Home (re-exports + corrupts dates)
  - Atraveo: aggregator with `&dontincludeimported=1` opt-out
- **Hub-and-Spoke Export** (`icalExport.ts`):
  - Per-channel filtered re-export using `?exclude=` query parameter
  - Each platform receives events from OTHER platforms, not its own
  - Prevents circular sync while maintaining full availability visibility
- **Import Controls** (`icalSync.ts`, `ical_feed.dart`):
  - `importEnabled` field for export-only mode (disable import for echo-prone platforms)
  - Echo detection integrated into import pipeline: analyzeEvent() called per event
  - Echo detection fields stored on ical_events: `echo_confidence`, `echo_reason`, `status`
  - Sync interval default changed from 30 to 15 minutes
- **Flutter UI** (`ical_sync_settings_screen.dart`, `ical_export_list_screen.dart`):
  - Import toggle in Add/Edit Feed dialog with explanatory note
  - Per-platform export URL cards with `?exclude=` parameter
  - Orange "Import disabled" indicator in feed list
  - ical_events filtering added to calendar/availability consumer files
- **Verified in production**: Adriagate simple echo auto-skipped at 100% confidence, merged blocks with native Adriagate bookings correctly imported

**Changelog 6.56**: iCal Sync Improvements — Custom Platform Names, GDPR Export, 15-min Sync:
- **Custom Platform Name for iCal Import** (`ical_feed.dart`, `ical_sync_settings_screen.dart`):
  - When selecting "Other" platform, user can now enter custom name (e.g., "Adriagate", "Smoobu")
  - New `customPlatformName` field in `IcalFeed` model, stored as `custom_platform_name` in Firestore
  - New `platformDisplayName` getter returns custom name if set, otherwise default enum display name
  - New localization strings: `icalCustomPlatformName`, `icalCustomPlatformNameHint`, `icalCustomPlatformNameRequired`
- **iCal Export GDPR Compliance** (`icalExport.ts`):
  - **REMOVED** guest PII from iCal export (industry standard: Airbnb, Booking.com, agencies all hide guest info)
  - `SUMMARY` changed from `"Booking: John Smith - Unit"` → `"Reserved"`
  - `DESCRIPTION` changed to minimal: `"{unitName}\nManaged by BookBed"` (no guest name, email, phone, price)
  - Removed unused `buildDescription()` function
- **iCal Sync Interval** (`icalSync.ts`):
  - Changed scheduled sync from **60 minutes → 15 minutes** for faster availability updates
  - Applies to all platforms: Booking.com, Airbnb, Adriagate, and other iCal sources
- **SF-002 REVISED - iCal URL Validation** (`icalSync.ts`):
  - **CHANGED** from whitelist to blocklist approach
  - Whitelist was too restrictive - hundreds of iCal providers exist (agencies, PMS, calendars)
  - Now: Block dangerous addresses (localhost, internal IPs, cloud metadata) but allow any public domain
  - Security maintained via: blocklist + HTTPS requirement + iCal content validation (`BEGIN:VCALENDAR`)

**Changelog 6.55**: Email Date Timezone Analysis — `timeZone: "Europe/Zagreb"` Sufficient:
- **Investigation**: User reported email dates showing -1 day offset (August 6 instead of August 7)
- **Root Cause**: `timeZone: "Europe/Zagreb"` parameter was added on Feb 3, 2026 (commit `fc9565ac`) but Cloud Functions were not deployed after that commit
- **Analysis Result**: The `timeZone` parameter in `toLocaleDateString()` is SUFFICIENT by itself:
  - Cloud Functions run in UTC timezone
  - `timeZone: "Europe/Zagreb"` correctly converts any UTC instant to Zagreb local date
  - No additional +12h normalization needed (would cause +1 day bug for times > 12:00 UTC)
- **Deployed**: Cloud Functions with existing `timeZone: "Europe/Zagreb"` fix
- **Worldwide Compatibility**: Zagreb timezone is correct for Croatian properties. USA users see Croatian check-in date (correct behavior for booking systems)
- **Future TODO**: For international properties, add `property.timezone` field and use it in `formatDate(date, propertyTimezone)`

**Changelog 6.54**: iCal Export Timezone Bug Fix — All Dates Shifted -1 Day:
- **ROOT CAUSE**: `truncateTime()` and `formatDate()` used `getUTCDate()` on Firestore dates stored as midnight local time (UTC+2)
  - Firestore: `May 28, 2026 at 00:00 UTC+2` → JS Date: `May 27, 22:00 UTC` → `getUTCDate()` = **27** (WRONG!)
  - ALL booking dates and gap blocks were shifted back by exactly 1 day in the iCal feed
  - Booking.com/Airbnb saw wrong availability dates
- **Fix** (`icalExport.ts`):
  - `truncateTime()`: Added +12h before `setUTCHours(0,0,0,0)` — ensures correct calendar date for any timezone (UTC-12 to UTC+14)
  - `generateBookingEvent()`: check_in/check_out now go through `truncateTime()` before `formatDate()`
  - Blocked days mapping: `daily_prices` dates normalized via `truncateTime()`
  - `generateBlockedEvent()`: range dates truncated, uses `setUTCDate()` for +1 day arithmetic
  - `calculateMinStayGapBlocks()`: `setDate()` → `setUTCDate()` for consistent UTC arithmetic
- **Verified**: All 5 bookings + 3 gap blocks + 2 off-season blocks now match Firestore exactly
- **Key Learning**: Firestore Timestamp `.toDate()` returns UTC representation — midnight in UTC+2 = 22:00 previous day in UTC. Always add 12h before extracting calendar date.

**Changelog 6.53**: Apple Sign-In iPad App Store Rejection Fix (Guideline 2.1):
- **ROOT CAUSE**: `CODE_SIGN_ENTITLEMENTS` was missing from `project.pbxproj`
  - `Runner.entitlements` existed on disk with correct `com.apple.developer.applesignin` capability
  - But it was NOT linked in Xcode project — binary had no Apple Sign-In entitlement embedded
  - Caused Sign in with Apple to fail on reviewer's iPad Pro 11-inch (M4) running iPadOS 26.2
- **Fix** (`ios/Runner.xcodeproj/project.pbxproj`):
  - Added `PBXFileReference` for `Runner.entitlements` (ID: `BBENTITLE001`)
  - Added `Runner.entitlements` to Runner group children
  - Added `CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;` to all 3 build configs (Debug, Profile, Release)
- **Fix** (`ios/Runner/Info.plist`):
  - Added `GIDClientID` key required by `google_sign_in` v6+ (discovered via Context7 MCP)
  - Value matches `CLIENT_ID` from `GoogleService-Info.plist`
- **Verified**: `flutter build ios --release --no-codesign` passes (71.2MB)
- **Cross-platform verification**: All auth configs verified for iOS, iPad, Android, and Web
- **Key Learning**: Entitlements file MUST be referenced in `project.pbxproj` — having it on disk alone is not enough

**Changelog 6.52**: Bookings Page Performance Optimization & Guide Update:
- **Optimization: Removed Client-Side Sorting** (`owner_bookings_provider.dart`):
  - Removed redundant `.sort()` calls in `WindowedBookingsNotifier` and `PaginatedBookingsNotifier`.
  - Reliance on Firestore's `orderBy` prevents UI jumps during progressive loading.
- **Optimization: Scroll Debounce** (`owner_bookings_screen.dart`):
  - Added 100ms debounce to scroll listener to reduce CPU load and prevent rapid-fire data requests.
  - Updated scroll thresholds (90%) for proactive background loading.
- **Embed Widget Guide Update** (`embed_widget_guide_screen.dart`):
  - Added "For Developers" section with styling customization info and security warnings about the src URL.
  - Updated English and Croatian localizations for the developer guide.

**Changelog 6.51**: iCal Export Critical Fixes — Same-Day Turnover & Min-Stay Gap Blocking:
- **DTEND Off-by-One Fix** (`icalExport.ts` → `generateBookingEvent`):
  - **Problem**: Added +1 day to check_out, blocking check-out day for new check-ins (no same-day turnover)
  - **Fix**: Set `DTEND = check_out` (no +1). In iCal, DTEND is exclusive, so check-out day is now free
  - Example: Booking 1-5 July → DTSTART=1, DTEND=5 → blocks nights 1,2,3,4; July 5 free for check-in
- **Min-Stay Gap Blocking** (`icalExport.ts` → `calculateMinStayGapBlocks`):
  - Detects gaps between bookings/blocks shorter than unit's `min_stay_nights`
  - These gaps are exported as "Not Available" (VEVENT with TRANSP:OPAQUE)
  - Prevents OTAs from accepting reservations that violate min-stay rules
- **Verified**: Same iCal feed works for Booking.com, Airbnb, VRBO, Google Calendar, etc. (RFC 5545 standard)

**Changelog 6.50**: Widget UI Fixes, iOS Compatibility & Email Terminology:
- **Additional Services Widget — Neutral Colors** (`additional_services_widget.dart`):
  - **Problem**: Widget booking form used green (`statusAvailableBorder`/`statusAvailableBackground`) colors — green is reserved for calendar availability status
  - **Fix**: Replaced with neutral minimalist colors:
    - Section container: `backgroundPrimary` (white/black)
    - Selected item: `backgroundSecondary` (#FAFAFA/#0A0A0A), border: `borderStrong`
    - Unselected item: `backgroundPrimary`, border: `borderDefault`
  - **Dark Mode Checkbox Fix**: Added explicit `activeColor: colors.textPrimary`, `checkColor: colors.backgroundPrimary`, `side: BorderSide(color: colors.textSecondary)`
  - **Price Breakdown**: Removed green color override from Additional Services row in `price_breakdown_widget.dart`
- **iOS Profile Image Upload Fix** (`storage_service.dart`, `profile_image_picker.dart`):
  - **Problem**: iOS HEIC format rejected by `_allowedExtensions` validation; `image_picker` converts bytes to JPEG but `XFile.name` retains `.heic` extension
  - **Fix**: Added `'heic'`/`'heif'` to allowed extensions, fixed upload path to `'users/$userId/profile/profile.jpg'`
  - Added `LoggingService.logError()` with stackTrace in `ProfileImagePicker` catch block
- **iOS Help & Support mailto: Fix** (`profile_screen.dart`):
  - **Problem**: `canLaunchUrl` returns false for `mailto:` on iOS without Mail configured
  - **Fix**: Replaced `canLaunchUrl` guard with try-catch around `launchUrl`
- **Email Terminology: "kapara" → "avans"** (4 Cloud Functions files):
  - Changed across: `payment-reminder.ts`, `booking-confirmation.ts`, `owner-notification.ts`, `template-helpers.ts`
  - **Bug Fix**: `booking-confirmation.ts` said "u roku od 3 dana" — fixed to "u roku od 7 dana" (actual payment deadline)
- **Max Guests Widget Fix** (`booking_widget_screen.dart`):
  - **Problem**: Guest count picker used `effectiveMaxCapacity` (includes extra beds) instead of `maxGuests` (Unit Hub Step 2 value)
  - **Fix**: Changed 5 references from `effectiveMaxCapacity` to `maxGuests`; removed `maxTotalCapacity` param from `GuestCountPicker`
  - Server-side (`atomicBooking.ts`) validates against `max_total_capacity` (more permissive) — no conflict
  - **Verified**: Booking log confirmed `guestCount: 4` (previously 6)

**Changelog 6.49**: iCal Export Compatibility & Booking.com Restriction FAQ:
- **iCal Export — `.ics` URL support** (`icalExport.ts`):
  - Token parsing now strips `.ics` extension: `pathParts[2].replace(/\.ics$/i, "")`
  - Allows calendar apps that require URL ending in `.ics` to work correctly
- **iCal Export — Pending → CONFIRMED** (`icalExport.ts`):
  - `mapBookingStatus("pending")` now returns `CONFIRMED` instead of `TENTATIVE`
  - Pending bookings block dates in our system — exporting as TENTATIVE allowed OTAs to ignore them
  - Airbnb only reliably imports CONFIRMED events; TENTATIVE may cause double-bookings
- **Booking.com iCal Import (February 2026 UPDATE)**:
  - ~~Previous info about URL restrictions was incorrect~~
  - Booking.com **DOES ACCEPT** custom PMS URLs including `cloudfunctions.net`
  - Successfully tested with `?exclude=booking_com` query parameter
  - Status: "U redu" (OK) in Booking.com Extranet after import
  - No workaround needed - direct import works
- **New FAQ entries** (EN + HR):
  - `icalExportFaq4Q/4A`: "Can I add this URL directly to Booking.com?" → Explains restriction + workaround
  - `ownerFaqIcal5Q/5A`: "Can I export BookBed calendar to Booking.com?" → Same info in main FAQ
  - Fixed `icalExportFaq1A`: Removed misleading "Booking.com syncs every 15-60 min"
- **FAQ Screen** (`faq_screen.dart`): Added both new FAQ items to iCalSync category

**Changelog 6.48**: Unit Wizard Reorganization, Services Display, Live Preview & UI Cleanup:
- **Unit Wizard Step 2 — Extra Beds, Pets & Additional Services**:
  - Extra Beds and Pets expandable sections moved from Step 3 (Pricing) to Step 2 (Capacity)
  - New "Additional Services" expandable section in Step 2 with full CRUD (add/edit/delete)
  - Services stored in Firestore via `AdditionalServiceModel` + `firebase_additional_services_repository`
  - Add service dialog: name, price, pricing type (per booking/per night/per guest/per guest per night), availability toggle
  - Services only available after unit is saved (unitId required for Firestore path)
- **Step 4 Review — Additional Services Display**:
  - New `_buildServicesCard()` using `FutureBuilder` to load services from Firestore
  - Shows service name + formatted price (e.g., "€5.00 per night")
  - Only appears when `unitId != null` and services exist
  - Displayed in both desktop (2x2 grid) and mobile (stacked) layouts
- **Unit Hub Basic Tab — Additional Services Section**:
  - Same `FutureBuilder` pattern with `ValueKey('services_${unitId}')` for unit change rebuild
  - Uses existing `_buildInfoCard` + `_buildDetailRow` helpers for consistent styling
- **Per-Day Override Fields Removed from Pricing Calendar**:
  - Removed 4 per-day override TextFormFields: `minNightsOnArrival`, `maxNightsOnArrival`, `minDaysAdvance`, `maxDaysAdvance`
  - Removed "Advanced Options" ExpansionTile, controllers, validation, parsing, disposal
  - Model fields kept nullable for backward compatibility — existing Firestore data won't break
  - Server/widget validation code unchanged — gracefully falls back to global settings when null
  - Removed ~16 localization keys (labels, hints, validation errors)
- **Embed Widget Guide — Live Preview Feature**:
  - Replaced "Test Your Widget" link with unit dropdown + "Preview Live" button
  - Dropdown uses `DropdownButtonFormField<UnitModel>` with property grouping for multi-property owners
  - Auto-selects first unit, opens `https://view.bookbed.io/?property={id}&unit={id}` directly
  - Dark theme dropdown fix: uses `InputDecorationHelper` for consistent `dropdownColor`, `borderRadius`, `fillColor`
  - New localization keys: `embedGuideSelectUnitHint`, `embedGuidePreviewLive` (EN + HR)
- **Drawer Cleanup** (`owner_app_drawer.dart`):
  - Removed `imagePath` property from `_DrawerItem`, `_DrawerItemWithBadge`, `_DrawerSubItem`
  - Deleted 6 drawer icon PNG assets (`assets/images/drawer_icons/`)
  - Removed `assets/images/drawer_icons/` from `pubspec.yaml` assets list
  - All drawer items now use Material Icons exclusively (simpler, consistent)
- **Offline Indicator Improvement** (`offline_indicator.dart`):
  - Converted from `ConsumerWidget` to `ConsumerStatefulWidget`
  - New "Ponovo povezano" (Back online) green banner on reconnection
  - Auto-hides after 2 seconds via `Timer`
  - Tracks `_wasOffline` / `_showReconnected` states
- **Booking Confirmation Timestamp**:
  - Added `approved_at: FieldValue.serverTimestamp()` when owner confirms a booking
  - Stored alongside existing `updated_at` field

**Changelog 6.47**: Google Sign-In Native SDK & Email Verification Fixes:
- **Google Sign-In Native SDK** (`enhanced_auth_provider.dart`):
  - **Problem**: Error "Failed to generate/retrieve public encryption key for Generic IDP flow" na Android native app
  - **Root Cause**: App koristio `signInWithProvider(GoogleAuthProvider())` - Generic IDP flow koji ne radi na Android native
  - **Fix**: Dodan `google_sign_in: ^6.2.2` paket za native mobile Google Sign-In
  - `signInWithGoogle()` sada koristi `GoogleSignIn().signIn()` za mobile (Android/iOS)
  - Web flow NEPROMIJENJEN - i dalje koristi `signInWithPopup(GoogleAuthProvider())`
  - Apple Sign-In NEPROMIJENJEN - i dalje koristi `signInWithProvider(OAuthProvider('apple.com'))`
  - **Files**: `pubspec.yaml`, `ios/Runner/Info.plist` (reversed client ID URL scheme), `enhanced_auth_provider.dart`
- **Email Verification Resend Network Error** (`email_verification_screen.dart`):
  - **Problem**: Resend dugme pokazivalo raw exception umjesto user-friendly poruke za network errore
  - **Fix**: Dodan network/socket/timeout/connection check u catch blok - sada prikazuje `errorNetworkFailed`
- **Email Verification Polling Error** (`enhanced_auth_provider.dart`):
  - **Problem**: Nakon verifikacije emaila, background polling pokazivao "Greska u mrezi" iako je email vec verified
  - **Root Cause**: `user.reload()` uspije (emailVerified=true), ali `getIdToken(true)` ili Firestore update fail-a, exception se rethrow-a
  - **Fix**: U catch bloku `refreshEmailVerificationStatus()`, ako je email vec verified, pokusaj `_loadUserProfile()` i vrati se bez errora
- **Google Reauth Native Fix** (`enhanced_auth_provider.dart`):
  - **Problem**: `reauthenticateWithGoogle()` koristio Generic IDP flow - ne radi na Android za brisanje accounta
  - **Fix**: `reauthenticateWithGoogle()` sada koristi native `GoogleSignIn` SDK na mobilnim platformama
- **Google Sign-In Account Picker** (`enhanced_auth_provider.dart`):
  - **Problem**: Google Sign-In automatski birao zadnji koristen account bez prikaza account pickera
  - **Fix**: Dodan `googleSignIn.signOut()` prije `signIn()` u `signInWithGoogle()` i `reauthenticateWithGoogle()`
  - `signOut()` briše kesirani account iz Google SDK-a, ali NE odlogovava iz Firebase Auth
- **Change Email Dialog Button Overlap** (`email_verification_screen.dart`):
  - **Problem**: Gumbi "Odustani" i "Promijeni e-poštu" se preklapali na manjim ekranima
  - **Fix**: Omotan `content` u `SingleChildScrollView` - sadržaj se scroll-a umjesto da se gumbi preklapaju

**Changelog 6.46**: Timeline Calendar Fixed Dimensions & UI Fixes:
- **Timeline Calendar — Fixed Cell Dimensions** (`timeline_dimensions.dart`):
  - **Problem**: Parallelogram booking blocks don't align correctly across different screen sizes. Responsive breakpoint-based sizing creates different cell widths per device, making positioning impossible to fix for all breakpoints simultaneously.
  - **Solution**: Replaced ALL responsive dimension calculations with fixed constants based on mobile 360px values. Timeline is horizontally scrollable, so wider screens simply show more days with the same cell size.
  - **Fixed values**: dayWidth=50px, rowHeight=42px, columnWidth=100px, headerHeight=60px
  - **Result**: Mobile ~5 days visible, Tablet ~12 days, Desktop ~25 days (scroll for more)
  - **Files**: `timeline_dimensions.dart` (single source of truth for all 11 timeline consumer files)
- **Booking Block Positioning Fix** (`timeline_grid_widget.dart`):
  - **Problem**: Parallelogram left edge bled into previous day (e.g., booking starting Feb 1 visible in Jan 31)
  - **Root Cause**: `- skewOffset/2` shift (23px) pushed bottom-left corner of parallelogram into previous day
  - **Fix**: Removed the shift — container left = `daysSinceFixedStart * dayWidth` (no offset)
  - Bottom-left corner now aligns with check-in day's left column boundary
  - Turnover gaps between adjacent bookings remain correct (4px)
- **Timeline Components — Fixed Compact Sizing**:
  - `timeline_unit_name_cell.dart`: Replaced responsive font/padding with fixed compact values (12px/10px fonts, 6px horizontal padding). Fixes 2px overflow from 42px row height.
  - `timeline_date_header.dart`: Month header font fixed at 11px, day header circle 24px, font 12px, padding 6px. No more responsive breakpoints.
  - `timeline_summary_cell.dart`: Hardcoded narrow layout (`isNarrow: true`) since dayWidth is always 50px.
- **Login Screen RenderFlex Overflow Fix** (`enhanced_login_screen.dart`):
  - **Problem**: 6.1px overflow in Remember Me row on narrow screens
  - **Fix**: Changed inner text to `Flexible`, compact padding on forgot password button
- **Error Boundary Fixes** (`error_boundary.dart`):
  - Fixed 25px button overflow: Changed `Row` with `Expanded` to `Wrap` with fixed-width `SizedBox(170)`
  - Fixed Navigator error: GoRouter as primary navigation, global navigator key as fallback
- **Social Login Icon Fallback** (`social_login_button.dart`):
  - Added `errorBuilder` to Google and Apple brand icons — shows Material icon if asset fails to load

**Changelog 6.45**: Android Property Form Navigation Crash Fix:
- **Problem**: App crashed on Android (release mode) when clicking "Add Property" after completing registration
- **Root Cause**: `Navigator.of(context).pop()` used in `property_form_screen.dart` crashes when:
  - User is directed to property form directly after registration (no previous route on stack)
  - Navigation was managed by GoRouter, not Navigator
- **Fix** (`property_form_screen.dart:1229-1239`):
  ```dart
  // OLD (crashes):
  Navigator.of(context).pop();

  // NEW (safe):
  if (context.canPop()) {
    context.pop();
  } else {
    context.go('/owner/properties');
  }
  ```
- **Android-specific**: Issue only appeared in Android release mode, not iOS
- **Pattern**: Always use `context.canPop()` check with GoRouter fallback instead of raw `Navigator.pop()`

**Changelog 6.44**: Email Verification Flow Fixes:
- **Email Verification Bypass Fix** (`enhanced_auth_provider.dart`):
  - **Problem**: After registration, user was redirected to dashboard instead of email verification page
  - **Root Cause**: `_createUserProfile()` overwrote auth state without `requiresEmailVerification` flag
  - **Fix**: Added email verification check in `_createUserProfile()`:
    ```dart
    final requiresVerification = !isSocialSignIn &&
        AuthFeatureFlags.requireEmailVerification &&
        !firebaseUser.emailVerified;
    state = state.copyWith(
      userModel: userModel,
      requiresEmailVerification: requiresVerification,
    );
    ```
- **Email Change Resend Fix** (`email_verification_screen.dart`, `enhanced_auth_provider.dart`):
  - **Problem**: After changing email, "Resend" button sent verification to OLD email
  - **Root Cause**: `updateEmail()` updated Firestore but not `userModel` in memory
  - **Fix**: `updateEmail()` now also updates `userModel.email` in state
  - Added `resendEmailChangeVerification()` method for re-sending to new email
- **Password Dialog for Email Change Resend** (`email_verification_screen.dart`):
  - **Problem**: `verifyBeforeUpdateEmail()` requires recent authentication
  - **Fix**: Added `_showResendPasswordDialog()` that prompts for password before resending
  - Extracted `_startCooldown()` helper method for code reuse
- **Initial Cooldown on Email Verification Screen**:
  - Added 60-second initial cooldown when screen opens (matches Firebase Auth `sendEmailVerification()` internal rate-limit window)
  - Prevents Firebase rate limit errors when user immediately clicks resend after registration
  - **Correction 2026-05-24 (audit/35 F-Auth-D2)**: prior text in this entry said "30-second"; the actual shipped value has always been 60 s (`email_verification_screen.dart` `_startInitialCooldown`/`_startCooldown`). Doc fixed; behavior unchanged.
- **RenderFlex Overflow Fix** (`logout_tile.dart`, `premium_list_tile.dart`):
  - Added `maxLines: 1` and `overflow: TextOverflow.ellipsis` to title and subtitle Text widgets
  - Fixes overflow on iOS simulator with long text
- **Button Color Fix** (`email_verification_screen.dart`):
  - Added `foregroundColor: Colors.white` to ElevatedButton style in change email dialog
  - Fixes dark text on dark theme

**Changelog 6.43**: Security Hardening & CI Upgrades:
- **Security Fix - Encryption Key Validation** (`functions/src/bookingComApi.ts`):
  - **Problem**: Hardcoded fallback encryption key could be used if `ENCRYPTION_KEY` env var not set
  - **Fix**: New `getEncryptionKey()` helper function with fail-fast validation
  - Throws `HttpsError("internal")` if key is missing or uses default value
  - Prevents accidental use of insecure fallback in production
  ```typescript
  function getEncryptionKey(): string {
    const encryptionKey = process.env.ENCRYPTION_KEY;
    if (!encryptionKey || encryptionKey === "default-key-change-in-production") {
      throw new HttpsError("internal", "ENCRYPTION_KEY is not configured.");
    }
    return encryptionKey;
  }
  ```
- **GitHub Actions Upgrades** (`.github/workflows/ci.yml`, `deploy-widget.yml`):
  - `actions/checkout@v4` → `@v6`
  - `actions/upload-artifact@v4` → `@v6`
  - `actions/setup-node@v4` → `@v6`
  - `codecov/codecov-action@v4` → `@v5`
  - All versions tested compatible with `ubuntu-latest` runners
- **iCal Two-Way Sync Verification**:
  - Confirmed `icalExport.ts` correctly exports both bookings AND blocked days
  - Firestore index exists for `daily_prices` collection group query (`unit_id` + `available` + `date`)
  - Blocked days from `daily_prices` where `available=false` are exported as "Not Available" VEVENT entries
  - This prevents Booking.com/Airbnb from showing manually blocked days as available

**Changelog 6.42**: Dialog UI Standardization (Delete Account & Booking Overlap Warning):
- **Delete Account Dialog** (`delete_account_dialog.dart`):
  - Migrated from `AlertDialog` to custom `Dialog` widget matching app design system
  - Added gradient background using `context.gradients.sectionBackground`
  - New header with red (`AppColors.error`) background, warning icon, and close button
  - Footer with `AppColors.dialogFooterDark/Light` and section dividers
  - Proper shadows using `AppShadows.elevation4Dark/elevation4`
  - Responsive sizing using `ResponsiveDialogUtils`
  - Works correctly in both light and dark mode
- **Booking Overlap Warning Dialog** (`booking_create_dialog.dart`):
  - Same migration from `AlertDialog` to custom `Dialog` widget
  - Consistent red header for warning state
  - Theme-aware conflict cards that adapt to dark/light mode
  - Uses `AppColors.error` with proper opacity for conflict highlighting
  - Responsive sizing and proper footer styling
- **Pattern for Warning/Error Dialogs**:
  - Header: `AppColors.error` background with white icon and text
  - Content: `context.gradients.sectionBackground` with theme-aware elements
  - Footer: `AppColors.dialogFooterDark/Light` with section divider border
  - Use `ResponsiveDialogUtils` for width, padding, and height constraints

**Changelog 6.41**: Platform Icons & Booking Details Dialog v2:
- **Platform Logo Images** (`lib/shared/widgets/platform_icon.dart`):
  - Added actual logo images for Booking.com, Airbnb, and other platforms
  - Images stored in `assets/images/platforms/`
  - Circular clipped images with fallback to letters if image fails to load
  - Better visual recognition of booking sources in timeline calendar
- **Booking Details Dialog v2** (`booking_details_dialog_v2.dart`):
  - New improved booking details dialog with better UX
  - Enhanced layout and information display
- **Social Login Icons**: Updated Apple and Google login button icons

**Changelog 6.40**: iCal Import Date Fix & Booking Sorting Improvements:
- **iCal Import Date Fix** (`functions/src/icalSync.ts`):
  - **Problem**: Imported bookings showed as "new" because `created_at` was set to import time
  - **Fix**: Extract original booking date from iCal CREATED/DTSTAMP fields
  - Priority: CREATED > DTSTAMP > startDate (fallback)
  - Imported bookings now sort correctly by their original creation date
- **Navigator Context Fix** (`ical_sync_settings_screen.dart`):
  - **Problem**: "Navigator context not ready" error when editing Airbnb iCal events
  - **Root Cause**: `_checkPlatformMismatch()` called during `initState()` before widget mounted
  - **Fix**: Wrapped call in `WidgetsBinding.instance.addPostFrameCallback()`
- **Booking Sorting Change** (All filter):
  - Changed from `created_at DESC` to `check_in ASC` (soonest first)
  - More operationally relevant: owner sees upcoming bookings first
  - Pending bookings still appear first, then sorted by check-in date
  - Files: `firebase_owner_bookings_repository.dart`, `owner_bookings_provider.dart`, `unified_bookings_provider.dart`
- **Permission-Denied Fix** (`_findBookingById`):
  - Added try-catch for Strategy 2 and 3 to handle permission errors gracefully
  - Prevents crashes when booking not found in expected collections
- **UI Improvements**:
  - Month names in pricing calendar dropdown now localized (Croatian)
  - Embed widget guide header matches export reservations page style
  - Send email dialog buttons use AutoSizeText with maxLines=1

**Changelog 6.39**: Lifetime License Admin Feature:
- **NEW FEATURE**: Admin can grant/revoke lifetime licenses from Admin Dashboard
- **UserModel Changes** (`user_model.dart`):
  - Added `AccountType.lifetime` enum value (trial, premium, enterprise, **lifetime**)
  - Added `lifetimeLicenseGrantedAt` and `lifetimeLicenseGrantedBy` audit fields
  - Added helper getters: `isLifetimeLicense`, `effectiveAccountType`, `hasPremiumAccess`
- **Cloud Function** (`functions/src/admin/setLifetimeLicense.ts`):
  - Callable function for granting/revoking lifetime licenses
  - Security: Checks `isAdmin` custom claim on Firebase Auth token
  - Auditing: Logs all changes to `security_events` collection
  - Validation: Checks user exists, validates boolean `grant` parameter
- **Firestore Security Rules** (`firestore.rules`):
  - Protected fields: `lifetime_license_granted_at`, `lifetime_license_granted_by`
  - Users cannot modify these fields directly (only via Cloud Function)
- **Admin Dashboard UI** (`user_detail_screen.dart`):
  - New "Lifetime License" card with purple theme
  - Shows "ACTIVE" badge when license is granted
  - Displays grant date and admin who granted
  - Grant/Revoke buttons with confirmation dialog
  - Success/error message display
- **Dashboard Stats** (`admin_users_repository.dart`):
  - Added `lifetimeUsers` count to dashboard stats
- **Bug Fix** (`users_list_screen.dart`):
  - Added `AccountType.lifetime` case to switch statement (was causing non-exhaustive error)

**Changelog 6.38**: Timeline Calendar Visual Centering & Same-Day Turnover Support:
- **Visual Centering Fix** (`timeline_grid_widget.dart`):
  - **Problem**: Booking blocks appeared shifted right by ~half a day on timeline calendar
  - **Root Cause**: Parallelogram shape has `skewOffset ≈ dayWidth`, meaning top-left corner starts almost one full day right of container edge
  - **Fix**: Shift bookings left by `skewOffset / 2` so visual center aligns with day column boundaries
  - **Code**: `final left = (daysSinceFixedStart * dayWidth - skewOffset / 2).floorToDouble();`
- **Same-Day Turnover Support** (booking move operations):
  - **Problem**: Admin bookings couldn't be moved to turnover days (checkout == checkin), but Widget bookings could
  - **Root Cause**: Dates weren't normalized to midnight before overlap comparison, causing time component differences
  - **Fix** (`booking_model.dart`, `booking_action_menu.dart`, `timeline_booking_stacker.dart`):
    - `datesOverlap()` now normalizes all dates to midnight before comparison
    - Uses strict inequality (`isBefore`/`isAfter`) which allows checkout == checkin
    - `booking_action_menu` normalizes dates before calling `areDatesAvailable()`
    - `timeline_booking_stacker` uses normalized dates for stack level assignment
  - **Example**: Booking A (May 1-5) does NOT overlap with Booking B (May 5-10)
- **Repository Improvements** (`firebase_booking_repository.dart`):
  - `getOverlappingBookings()` now excludes completed bookings (only pending/confirmed block dates)
  - `deleteBooking()` accepts optional `booking` param to avoid permission issues with collectionGroup queries

**Changelog 6.37**: Timeline Calendar TELEPORT Bug Fixes:
- **Problem 1**: Clicking dates more than ~3 months away in date picker didn't work reliably
  - Sometimes jumped correctly, sometimes stayed in place or jumped to wrong date
- **Root Cause 1**: Timeline calendar uses 90-day "windowed" view for performance
  - When target date is outside visible window, animated scroll couldn't reach it
  - Recursive `_scrollToDate` calls caused race conditions
  - `_extendDateRangeIfNeeded` during scroll caused additional conflicts
- **Fix 1** (`timeline_calendar_widget.dart`):
  - **TELEPORT approach**: For far jumps (target outside visible window):
    1. Set `_isProgrammaticScroll = true` to block scroll listener updates
    2. Rebuild window around target date (set `_visibleStartIndex`, `_forceVisibleStartIndex = true`)
    3. Use `jumpTo()` (instant) instead of `animateTo()` (no race conditions)
    4. Reset flag after 500ms via Timer
  - Two TELEPORT blocks: one for range extension (past/future dates), one for far jumps within existing range
  - **Disabled `_extendDateRangeIfNeeded`**: No longer needed - TELEPORT handles range extension
- **Problem 2**: After TELEPORTing to distant dates and manually scrolling back, reservations disappeared
  - User reported: TELEPORT to May, scroll back towards January → reservations vanish
- **Root Cause 2**: TELEPORT scroll position calculation was missing `offsetWidth`
  - Content structure: `[SizedBox(offsetWidth)] + [day cells]`
  - TELEPORT calculated: `(newWindowTargetDay * dayWidth) - (viewport * 0.25)` ≈ 1550px
  - Should have been: `offsetWidth + (newWindowTargetDay * dayWidth) - (viewport * 0.25)` ≈ 19550px
  - Without `offsetWidth`, scroll landed in the spacer instead of the actual day cells
- **Fix 2** (`timeline_calendar_widget.dart` lines ~860 and ~970):
  ```dart
  // BUG FIX: Must include offsetWidth in scroll calculation!
  final offsetWidth = _visibleStartIndex * dimensions.dayWidth;
  final scrollInNewWindow =
      offsetWidth +
      (newWindowTargetDay * dimensions.dayWidth) -
      (dimensions.visibleContentWidth * 0.25);
  ```
- **Key insight**: Flag-based protection (`_isProgrammaticScroll`) must be set BEFORE `setState()` and reset AFTER scroll completes
- **Testing**: Confirmed working - TELEPORT + manual scroll back no longer causes reservations to disappear

**Changelog 6.36**: Calendar Timeline Booking Move Fixes:
- **UI Not Refreshing After Booking Move** (main fix):
  - **Problem**: After moving booking between units via drag-drop or menu, changes only visible after full app refresh
  - **Root Cause**: Only `calendarBookingsProvider` was invalidated, but UI watches `timelineCalendarBookingsProvider` (filtered provider)
  - **Fix** (`calendar_drag_drop_provider.dart`, `booking_action_menu.dart`):
    - Added `ref.invalidate(timelineCalendarBookingsProvider)` alongside `calendarBookingsProvider`
    - MUST invalidate BOTH: base provider AND filtered provider that UI watches
- **"Cannot use ref after widget disposed" Error**:
  - **Problem**: Error appeared after clicking "Move to" menu item
  - **Root Cause**: `Navigator.pop(context)` called BEFORE `_moveBookingToUnit()`, so `ref.invalidate()` executed after widget disposal
  - **Fix** (`booking_action_menu.dart`):
    - Execute move operation FIRST (while dialog still open)
    - Close dialog AFTER operation completes with `if (mounted && context.mounted)` check
    - Changed `_moveBookingToUnit` return type from `void` to `bool` for proper flow control
- **Provider Invalidation Pattern** (Important for future reference):
  ```dart
  // CORRECT - invalidate both base AND filtered providers
  ref.invalidate(calendarBookingsProvider);        // base provider
  ref.invalidate(timelineCalendarBookingsProvider); // filtered provider UI watches
  ```

**Changelog 6.35**: Web Push Notifications (FCM):
- **NEW FEATURE**: Push notifications za Owner Dashboard (web)
- **Components Created**:
  - `fcm_service.dart` - Flutter FCM service sa VAPID key, token management
  - `fcm_navigation_handler.dart` - Foreground snackbar + navigation handling
  - `firebase-messaging-sw.js` - Service Worker za background notifications
  - `fcmService.ts` - Cloud Functions za slanje push notifikacija
- **Token Storage**: `users/{userId}/data/fcmTokens` (Map format, supports multiple devices)
- **Integration** (`atomicBooking.ts`):
  - `sendPendingBookingPushNotification()` za pending bookinge
  - `sendBookingPushNotification()` za confirmed/updated/cancelled
- **Bug Fix**: "No GoRouter found in context" - SnackBar action koristi `ref.read(ownerRouterProvider).go()` umjesto `context.go()`
- **Foreground**: Shows snackbar with "View" button → navigates to booking
- **Background**: Service Worker shows system notification with click-to-open

**Changelog 6.34**: Weekend Pricing Display & UX Improvements:
- **Weekend Pricing in Widget Calendar** (main feature):
  - **Problem**: Weekend pricing showed correctly in owner dashboard but NOT in embedded widget calendar
  - **Root Cause**: Widget calendar only showed prices in hover tooltips (desktop-only), mobile users couldn't see prices
  - **Fix** (`month_calendar_widget.dart`, `year_calendar_widget.dart`):
    - Added `_buildDayCellContent()` helper with price display directly in calendar cells
    - Price hierarchy: custom daily price → weekend base price → base price
    - Year calendar: price only shows when cellSize >= 24px (responsive)
- **Registration Form UX Fix** (`enhanced_register_screen.dart`):
  - **Problem**: Button disabled on any validation failure without showing why
  - **Fix**: Button only disabled when fields are EMPTY. Validation errors shown on submit click
  - Better UX: users see exactly what needs fixing
- **Unit Hub Race Condition Fix** (`unified_unit_hub_screen.dart`):
  - **Problem**: Auto-selection failed when units loaded before properties (empty properties list)
  - **Fix**: Added guard `if (properties.isEmpty) return;` in `_handleUnitsChanged()`
  - Added `ref.listen` for properties changes to re-trigger auto-selection
- **Booking Details Dialog** (`booking_details_dialog.dart`):
  - Responsive spacing improvements for small screens
  - Payment method and payment option display added
- **Unit Wizard Simplified**: Reduced from 5 steps to 4 steps (removed Photos step - photos added via Unit Hub)

**Changelog 6.33**: Force Update System (Android) - IMPLEMENTED:
- **NEW FEATURE**: App version control sa force/optional update dialogs
- **Components Created**:
  - `AppConfig` model (freezed) - Firestore config za verzije
  - `VersionCheckService` - Version comparison logic (semantic versioning)
  - `ForceUpdateDialog` - Non-dismissible dialog za kritične update-e
  - `OptionalUpdateDialog` - Dismissible dialog, podseća svakih 24h
  - `VersionCheckWrapper` - Widget za automatic version checking
- **Integration** (`main.dart`):
  - VersionCheckWrapper wrap-uje GlobalNavigationOverlay
  - Check-uje verziju na app start i app resume
- **Firestore**:
  - Collection: `app_config/{platform}` (android, ios)
  - Security rules: Read za authenticated usere, write samo Admin SDK
- **Localization**: 10 novih stringova (EN + HR) za update dialogs
- **Documentation**: `docs/FORCE_UPDATE_SETUP.md` - setup instrukcije
- **Testing Required**: Kreirati test `app_config/android` dokument u Firestore
- **Next Release**: Force update će biti aktivan tek u 1.0.3+ (trenutno 1.0.2+6)

**Changelog 6.32**: Email Verification Network Error Fix (v1.0.2+6):
- **CRASH FIX**: Network errors during email verification no longer crash the app
- **Problem**: When checking email verification status, network failures (timeout, no connection) caused app crash
- **Root Cause**: `User.reload()` in `refreshEmailVerificationStatus()` had no error handling
- **Fix** (`enhanced_auth_provider.dart:781-806`):
  - Added try-catch around `user.reload()` to catch and log network errors
  - Error is rethrown for caller to handle gracefully
- **Fix** (`email_verification_screen.dart:55-75`):
  - Added try-catch around `_checkVerificationStatus()` call
  - Shows user-friendly error message: "Network error. Please check your internet connection"
  - User can retry manually or when app resumes
- **Result**: Graceful degradation instead of crash, better UX for poor network conditions
- **Version**: Bumped to 1.0.2+6 for Google Play release

**Changelog 6.31**: Admin Dashboard Documentation & Fixes:
- **Admin Dashboard Section Added** to CLAUDE.md:
  - URL: `https://bookbed-admin.web.app`
  - Entry point, screens, shell navigation documented
  - Firestore rules for admin access documented
  - Admin providers and repository patterns documented
- **Firestore Rules Fix** (`firestore.rules`):
  - Added `isAdmin() || isAdminFromFirestore() ||` to bookings collection group rules
  - Fixes: Admin couldn't see user's bookings count (permission-denied)
- **UI Fixes** (`admin_shell_screen.dart`, `users_list_screen.dart`):
  - Removed theme toggle from AppBar (kept only in drawer)
  - Fixed refresh button on Users page (moved to content row)
- **Hosting Targets Updated**: Added `admin` target for `bookbed-admin.web.app`

**Changelog 6.30**: Safari Web Compatibility Fixes:
- **Flutter Loader TypeError Fix** (`web/index.html`):
  - **Problem**: `TypeError: _flutter.loader.load is not a function` on Chrome & Safari
  - **Root Cause**: `flutter_bootstrap.js` adds `loader` as nested property on `_flutter` object
  - **Original Approach**: `Object.defineProperty` only intercepted initial `_flutter` assignment, not nested `loader`
  - **Fix**: JavaScript `Proxy` with `set` trap to intercept all property assignments including `loader`
  - **Renderer Fallback**: Check `buildConfig.builds` before injecting renderer config
  - Prevents "FlutterLoader could not find a build compatible" error
- **Safari Firebase Init Error Fix** (`main.dart`, `widget_main.dart`, `widget_main_dev.dart`):
  - **Problem**: `Null check operator used on a null value` during Firebase initialization on Safari
  - **Root Cause**: `Firebase.apps` getter throws on Safari when SDK hasn't fully initialized
  - **Fix**: Wrapped `Firebase.apps.isEmpty` in nested try-catch:
    ```dart
    bool needsInit = true;
    try {
      needsInit = Firebase.apps.isEmpty;
    } catch (_) {
      // Safari throws - assume needs init
      needsInit = true;
    }
    if (needsInit) await Firebase.initializeApp(...);
    ```
  - Applied to: Owner app (`main.dart`), Widget production (`widget_main.dart`), Widget dev (`widget_main_dev.dart`)
- **Removed Firebase Compat SDK Pre-initialization**:
  - Commented out `firebase-app-compat.js` and related SDK scripts in `index.html`
  - Was causing conflicts with Flutter's modular Firebase SDK
- **Files Modified**:
  - `web/index.html`: Proxy-based loader interception, renderer fallback, removed compat SDK
  - `lib/main.dart`: Safari-safe Firebase init with detailed logging
  - `lib/widget_main.dart`: Added `_initializeFirebaseSafely()` helper
  - `lib/widget_main_dev.dart`: Added `_initializeFirebaseSafelyDev()` helper
- **Result**: Both Owner Dashboard and Widget now work on Safari (tested on macOS Safari)

**Changelog 6.29**: App Store Submission Preparation & UI Fixes:
- **iOS Deployment Target Fix**:
  - Problem: Runner.xcodeproj targetao iOS 13.0, Podfile zahtijevao iOS 15.0
  - Fix: Ažurirane sve 3 instance `IPHONEOS_DEPLOYMENT_TARGET` na 15.0
  - Rezultat: `flutter build ios --release` sada prolazi
- **Subscription Screen Simplification**:
  - Problem: `trialStatusProvider` uzrokovao Firestore permission error
  - Fix: Uklonjena Firestore zavisnost, screen sada samo pokazuje web redirect button
  - Novi l10n: `subscriptionWebOnlyTitle`, `subscriptionWebOnlyMessage`, `subscriptionContinueToWeb`
  - App Store compliance: Subscription management na webu, ne u app-u
- **Stripe Loading Animation Fix**:
  - Problem: Currency simboli (€, $, £) se pomjerali ~640px umjesto 20px
  - Uzrok: `slideY(end: -20)` koristi widget height multiplier, ne pixele
  - Fix: Promijenjeno na `moveY(end: -20)` koji koristi apsolutne pixele
- **Unit Hub Menu Button Styling**:
  - Zamijenjen plain `IconButton` sa styled button (container, border, SmartTooltip)
  - Konzistentno sa calendar toolbar button stilom
- **App Store Audit**: Verified Sign in with Apple, ATT compliance, ATS, FCM config

**Changelog 6.28**: Dashboard Metrics Fix - Exclude Pending Bookings:
- **Problem**: Dashboard Revenue, Bookings Count, i Occupancy Rate uključivali pending bookinge
- **Izvor**: `fix/dashboard-metrics-6709532682132730445` branch (Jules AI)
- **Fix** (`unified_dashboard_provider.dart`):
  - Kreiran `confirmedAndCompletedBookings` filter
  - Revenue, bookingsCount, occupancyRate koriste samo confirmed/completed
  - **POBOLJŠANJE**: Charts (revenueHistory, bookingHistory) također filtrirani
- **Rezultat**: Summary metrike i chart totali sada konzistentni
- **Napomena**: Upcoming Check-ins i dalje uključuje pending (očekivano ponašanje)

**Changelog 6.27**: Logo Asset Implementation & FCM Push Notifications:
- **Logo Asset System**:
  - Nova `logo-light.avif` slika u `assets/images/`
  - Kreiran `BookBedLogo` widget (`lib/shared/widgets/bookbed_logo.dart`)
  - **Dark Mode Support**: Automatska inverzija boja putem `ColorFilter.matrix`
  - `AuthLogoIcon` ažuriran da koristi `Image.asset` umjesto `CustomPaint`
  - Uklonjena stara `_LogoPainter` klasa
  - Fallback na `Icons.home_work_outlined` ako asset ne učita
- **FCM Push Notifications** (Phase 2):
  - Integrirano u `atomicBooking.ts` za pending i confirmed bookinge
  - `sendBookingPushNotification()` sada prima opcionalne `checkInDate`/`checkOutDate` parametre
  - `sendPendingBookingPushNotification()` za pending bookinge
  - In-app notifikacije putem `createBookingNotification()`
  - Non-blocking izvršenje sa `.catch()` error handling
- **Modified Files**:
  - `pubspec.yaml`: Dodana `assets/images/` folder
  - `lib/shared/widgets/bookbed_logo.dart`: Novi widget
  - `lib/features/auth/presentation/widgets/auth_logo_icon.dart`: Image.asset + dark mode
  - `lib/core/widgets/owner_app_loader.dart`: Koristi `AuthLogoIcon`
  - `lib/features/widget/presentation/widgets/common/bookbed_loader.dart`: Koristi `AuthLogoIcon`
  - `functions/src/atomicBooking.ts`: FCM integracija
  - `functions/src/fcmService.ts`: Ažurirani parametri funkcije

**Changelog 6.26**: Security Audit Complete (SF-001 through SF-017):
- **Analizirani branchevi**: 12 AI agent brancheva (Google Jules, Sentinel, Bolt, Palette)
- **Implementirano**: 17 sigurnosnih ispravki (2 CRITICAL, 1 HIGH, ostalo Low/Medium)
- **Odbijeno**: 1 (SF-003 - mikro-optimizacija bez koristi)
- **Duplikati preskočeni**: 1 (sentinel/fix-pii-leak-calendar - već riješeno u SF-014)

**CRITICAL fixes:**
- **SF-007**: Uklonjena mogućnost spremanja lozinke u SecureStorage ("Remember Me" sada sprema samo email)
- **SF-011**: Dodan `service-account-key.json` u `.gitignore` (sprječava slučajno commitanje Firebase admin credentials)

**HIGH fix:**
- **SF-014**: Spriječeno izlaganje PII podataka (ime, email, telefon gosta) u public booking widget kalendaru

**Ostale ispravke:**
- SF-001: Owner ID validacija u booking creation (server-side)
- SF-002: SSRF prevencija u iCal sync (whitelist enabled)
- SF-004: IconButton hover/splash feedback
- SF-005: Phone number validacija
- SF-006: Sequential character password check (slova + brojevi)
- SF-008: Booking notes length limit (1000 chars)
- SF-009: Error handling info leakage prevention
- SF-010: Year calendar race condition fix
- SF-012: Secure error handling & email sanitization
- SF-013: Haptic feedback on password toggle
- SF-015: DebouncedSearchField ValueNotifier optimization
- SF-016: AnimatedGradientFAB ValueNotifier optimization
- SF-017: Password visibility toggle tooltips (accessibility)

**Dokumentacija**: Sve ispravke detaljno dokumentirane u `docs/SECURITY_FIXES.md`

**Changelog 6.25**: Security Fixes (SF-001, SF-002):
- **SF-001: Owner ID Validation in Booking Creation** (`atomicBooking.ts`):
  - **Problem**: `ownerId` parametar dolazio direktno iz klijentskog zahtjeva bez validacije
  - **Fix**: Sada se `owner_id` dohvaća iz property dokumenta u Firestore-u (server-side validacija)
  - **Benefit**: Sprječava maliciozne korisnike da postave pogrešan `owner_id`
- **SF-002: SSRF Prevention in iCal Sync** (`icalSync.ts`):
  - **Problem**: Whitelist validacija za iCal URL-ove bila zakomentirana - server dopuštao bilo koji URL
  - **Fix**: Omogućena whitelist validacija - samo poznate booking platforme (Booking.com, Airbnb, Google Calendar, etc.)
  - **Breaking Change**: URL-ovi koji nisu na whitelisti sada se blokiraju
  - **Otkrio**: Google Sentinel (automated security scan)
- **Nova dokumentacija**: `docs/SECURITY_FIXES.md` - prati sve sigurnosne ispravke s detaljima

**Changelog 6.24**: Embed Code URL Fix - Remove Subdomain Prefix:
- **Problem**: Embed kod generirao URL sa property subdomain prefiksom (npr. `jasko-apartments.view.bookbed.io`)
  - Subdomene nisu uvijek konfigurirane u Firebase Hosting
  - Property name se koristio kao subdomain, što ne odgovara stvarnoj konfiguraciji
- **Fix**: Embed kod sada uvijek koristi `view.bookbed.io` bez prefiksa
  - Property i Unit ID parametri su dovoljni za identifikaciju
  - Subdomene su opcionalne i koriste se samo za slug URL-ove (shareable links)
- **Izmijenjeni fajlovi**:
  - `embed_code_generator_dialog.dart`: `_iframeEmbedCode` sada koristi `_defaultWidgetBaseUrl`
  - `embed_widget_guide_screen.dart`: `_generateEmbedCode` sada koristi fiksni `view.bookbed.io`
- **Rezultat**: Embed kod radi na svim sajtovima bez potrebe za konfiguracijom subdomene

**Changelog 6.23**: flutter_animate Migration Phase 2-5 Complete:
- **Migrated Files** (AnimationController → flutter_animate):
  - `auth_logo_icon.dart`: Scale pulse + glow opacity animation
  - `booking_details_screen.dart`: Fade-in entrance animation
  - `booking_confirmation_screen.dart`: Fade-in entrance animation
  - `confirmation_header.dart`: Scale animation for success icon
  - `error_boundary.dart`: Float + rotate animation for error illustration
  - `year_calendar_skeleton.dart`: Shimmer effect
  - `month_calendar_skeleton.dart`: Shimmer effect
- **Critical Bug Fix - Parallel Animations**:
  - **Problem**: flutter_animate chains `.effect1().effect2()` run sequentially by default
  - **Original behavior**: Single AnimationController = simultaneous animations
  - **Fix**: Added `delay: Duration.zero` to second effect for parallel execution
  - Affected: `auth_logo_icon.dart` (scale + glow), `error_boundary.dart` (moveY + rotate)
- **Radians to Turns Conversion**:
  - flutter_animate `.rotate()` uses turns (1 turn = 360°), not radians
  - Formula: `radians / (2 * pi)` → turns (e.g., `0.05 rad / 6.283 ≈ 0.008 turns`)
- **Files NOT Migrated** (patterns incompatible with flutter_animate):
  - `owner_app_loader.dart`, `bookbed_loader.dart`, `bookbed_branded_loader.dart`: Custom `Alignment(-1 → 2)` animation
  - `connectivity_banner.dart`: Event-driven `forward()`/`reverse()` control
  - `enhanced_login_screen.dart`: Programmatic shake animation
  - `animated_success.dart`: Complex programmatic control with external trigger
- **Code Reduction**: ~55% average across migrated files (removed dispose, initState, AnimationController boilerplate)

**Changelog 6.22**: flutter_animate Migration & Dependency Cleanup:
- **Removed 12 Unused Packages** from pubspec.yaml:
  - `easy_localization` - projekt koristi `intl` umjesto toga
  - `photo_view` - nikad implementirano
  - `visibility_detector`, `step_progress_indicator` - nekorišteno
  - `flutter_map`, `flutter_map_marker_cluster`, `geolocator`, `geocoding`, `latlong2` - mape neće biti
  - `scrollable_positioned_list`, `flutter_dotenv`, `universal_io`, `vector_math` - nekorišteno
- **Moved `fake_cloud_firestore`** iz dependencies u dev_dependencies (test-only paket)
- **Kept for future use**: `pdf`, `printing` (fakture/izvještaji), `flutter_animate` (animacije)
- **flutter_animate Migration Phase 1 Complete**:
  - Created `flutter_animate_extensions.dart` - helper methods za AnimationTokens integraciju
  - Migrated `AnimatedEmptyState`: StatefulWidget (135 lines) → StatelessWidget (50 lines) = 63% reduction
  - Migrated `StaggeredEmptyState`: StatefulWidget (164 lines) → StatelessWidget (70 lines) = 57% reduction
  - Total: 299 → 120 lines = **60% code reduction**
  - Zero breaking changes - API remains identical
  - Benefits: No AnimationController disposal needed, no memory leak risk, simpler code

**Changelog 6.21**: Stripe Connect Return URL Routing Fix:
- **Sentry Error Fix**: `permission-denied` errors on `/owner/stripe-return` route
  - **Problem**: After completing Stripe Connect onboarding, Stripe redirects to `/owner/stripe-return`
  - **Root Cause**: Route was never defined in GoRouter, causing 404 fallback and race conditions with auth state
  - **Fix** (`router_owner.dart`):
    - Added `stripeReturn = '/owner/stripe-return'` and `stripeRefresh = '/owner/stripe-refresh'` route constants
    - Added GoRoute handlers that redirect to `OwnerRoutes.stripeIntegration` (`/owner/integrations/stripe`)
  - **Result**: Owner returns to Stripe Integration page after onboarding, where `_loadStripeAccountInfo()` fetches updated status
- **Note**: This fix only affects owner Stripe Connect flow (account linking), NOT widget Stripe payments

**Changelog 6.20**: Bank Account Routing Fix & Bottom Sheet Standardization:
- **Bank Account 404 Routing Fix** (`bank_account_screen.dart`):
  - **Problem**: Navigating Unit Hub → Widget Settings → Bank Transfer → Bank Account → Save caused 404 error
  - **Root Cause**: Hardcoded route string `/owner/integrations/payments` instead of route constant
  - **Fix**: Added `router_owner.dart` import and changed all 3 navigation points to use `OwnerRoutes.unitHub`
  - Lines affected: 121 (after save), 271 (cancel button), 319 (discard dialog)
  - Uses `context.canPop() ? context.pop() : context.go(OwnerRoutes.unitHub)` pattern
- **Bottom Sheet Height Standardization** (`notification_settings_bottom_sheet.dart`):
  - **Problem**: Notification Settings used fixed 600px height while Language/Theme used dynamic percentage
  - **Fix**: Changed to use `ResponsiveSpacingHelper.getBottomSheetMaxHeightPercent(context)`
  - All bottom sheets now use consistent responsive heights:
    - Landscape Mobile: 80% of screen
    - Portrait Mobile: 70% of screen
    - Tablet/Desktop: 60% of screen
- **Serbian to Croatian Localization Fixes** (`app_hr.arb`):
  - Fixed remaining Ekavian (Serbian) words to Ijekavian (Croatian)
  - Examples: "Ocene"→"Ocjene", "Sinhronizuj"→"Sinkroniziraj", "nalog"→"račun", etc.
- **SelectableText for Booking Details**:
  - Booking ID, guest email, and phone number now copyable via long-press
  - Added to `booking_card_header.dart` and `booking_card_guest_info.dart`

**Changelog 6.19**: Bookings Page UX Improvements & Automatic Status Updates:
- **Booking ID Display Fix** (`booking_card_header.dart`, `booking_details_dialog.dart`):
  - Changed from truncated document ID (`#abc123xy`) to user-friendly `booking_reference` (e.g., `BK-2024-001234`)
  - Fallback to document ID if `booking_reference` is null
  - Booking ID now copyable via SelectableText (from previous changelog)
- **iCal Bookings Already Displayed**:
  - Confirmed: NO source filter in repository - iCal bookings automatically shown
  - Table View already has "Source" column with platform badges (Widget, Booking.com, Airbnb, iCal)
  - Timeline Calendar already has platform icon in top-right corner
  - No changes needed - feature already works correctly
- **Email Template Duplicate Greeting Fixed** (`send_email_dialog.dart`):
  - **Problem**: "Poštovani {name}," appeared TWICE - once in Flutter template, once in Cloud Functions
  - **Fix**: Removed greeting from Flutter `getMessage()` method (lines 50-95)
  - Cloud Functions `generateGreeting()` already adds "Poštovani/a {name}," automatically
  - Affects all email templates: confirmation, reminder, cancellation, custom
- **Automatic Booking Status Updates** - NEW scheduled Cloud Function:
  - **Created**: `completeCheckedOutBookings.ts` - auto-completes bookings after checkout
  - **Schedule**: Daily at 2:00 AM (Zagreb timezone) - configurable via `AUTOCOMPLETE_SCHEDULE` env var
  - **Query**: `.where("status", "in", ["confirmed", "pending"]).where("check_out", "<", today)`
  - **Filters OUT**: External/iCal bookings (source: booking_com, airbnb, ical, external) and ID prefix `ical_`
  - **Batch Processing**: 400 docs/batch, max 5000 docs/run, error recovery with individual fallback
  - **Updates**: Sets `status: "completed"` and `updated_at: now()`
  - **Export**: Added to `index.ts` for deployment
  - **Firestore Index**: Added composite index `status` (ASC) + `check_out` (ASC) for collection group query
  - **Logging**: Structured logs with success/failure counts, duration tracking
  - **Benefits**: Owners get accurate historical data without manual status updates

**Changelog 6.18**: Dashboard Rolling Window Periods & Chart Improvements:
- **Period Calculations Changed to Rolling Windows**:
  - **Problem**: Period računanja bila kalendarska (1. dec - 21. dec), što daje nekonzistentne rezultate
    - "Prošlo tromjesečje" pokazivalo MANJE podataka nego "Ovaj mjesec" (nelogično)
    - Periodi nisu bili dinamički - morali se ručno mijenjati svaki dan
  - **Fix**: Rolling windows sa `today minus X dana` logikom
    - `last7Days()`: zadnjih 7 dana (bilo: prošli tjedan)
    - `last30Days()`: zadnjih 30 dana (bilo: kalendarski mjesec)
    - `last90Days()`: zadnjih 90 dana (bilo: kalendarski tromjesečje)
    - `last365Days()`: zadnjih 365 dana (bilo: kalendarskih 12 mjeseci)
  - **Rezultat**: Period sa više dana UVIJEK ima više/jednako podataka
- **Default Period**: Promijenjen sa `currentMonth()` na `last7Days()`
- **Choice Chip Labele Ažurirane**:
  - "Prošli tjedan" → "Zadnjih 7 dana" / "Last 7 days"
  - "Ovaj mjesec" → "Zadnjih 30 dana" / "Last 30 days"
  - "Prošlo tromjesečje" → "Zadnjih 90 dana" / "Last 90 days"
  - "Prošla godina" → "Zadnjih 365 dana" / "Last 365 days"
- **Chart Interakcije Pojednostavljene**:
  - Uklonjen zoom (scroll to zoom) - `horizontalRangeUpdater` removed iz `RectCoord`
  - Dodane vrijednosti na chartovima:
    - Revenue chart: €XXX prikazano iznad svake tačke
    - Bookings chart: broj rezervacija prikazano iznad svakog bara
  - Zadržani hover tooltips za detalje
- **Modified Files**:
  - `unified_dashboard_data.dart`: novi factory methods za rolling windows
  - `unified_dashboard_provider.dart`: `setPreset()` ažuriran za nove periode
  - `dashboard_overview_tab.dart`: chart labels sa vrijednostima, uklonjeni zoom eventi
  - `app_en.arb`, `app_hr.arb`: nove lokalizacije za choice chips

**Changelog 6.17**: Calendar Provider Cache Security Fix & Remember Me Feature:
- **CRITICAL SECURITY FIX - Calendar showing other owner's units**:
  - **Problem**: Owner A logs out, Owner B logs in → sees Owner A's units in Calendar Timeline
  - **Root Cause**: `keepAlive: true` providers cached previous user's data
    - `ownerPropertiesCalendarProvider` and `allOwnerUnitsProvider` used `FirebaseAuth.instance.currentUser`
    - Provider never invalidated on user change because `keepAlive: true` prevents disposal
  - **Fix** (`owner_calendar_provider.dart:20-24`):
    - Changed from `FirebaseAuth.instance.currentUser?.uid` to `ref.watch(enhancedAuthProvider)`
    - Now watches auth state changes → auto-invalidates on login/logout
    - New user gets fresh data, not cached data from previous user
  - **Key Learning**: `keepAlive: true` providers MUST watch auth state if they depend on current user
- **Remember Me / Auto-fill Feature** (AUTH_LOADING_STATES_PLAN.md):
  - Added `flutter_secure_storage: ^9.0.0` dependency
  - New `SecureStorageService` singleton (`lib/core/services/secure_storage_service.dart`)
  - New `SavedCredentials` freezed model (`lib/features/auth/models/saved_credentials.dart`)
  - Login screen auto-fills credentials if "Remember Me" was enabled
  - Credentials saved on successful login (if Remember Me checked)
  - Credentials cleared on logout
  - Platform-specific encryption: Android EncryptedSharedPreferences, iOS Keychain
- **Improved Auth Error Messages**:
  - New localization keys: `authErrorWrongPassword`, `authErrorUserNotFound`, `authErrorInvalidEmail`, etc.
  - Croatian and English translations
  - Generic fallback: `authErrorGeneric` for unmapped errors

**Changelog 6.16**: Stripe Live Payment Tested & Payment Method Display:
- **Stripe Live Payment Successfully Tested**:
  - First live transaction: €0.60 deposit payment
  - Webhook correctly updated booking status to `confirmed`
  - Email confirmation sent to guest
  - Stripe Connect Standard model working: money goes directly to owner
- **Payment Method Display in Booking Details** (`booking_details_dialog.dart`):
  - Added "Payment Method" row: Stripe, Bank Transfer, Cash, Other, Not specified
  - Added "Payment Option" row: Deposit, Full Payment
  - New localization strings in `app_en.arb`, `app_hr.arb`
  - Owners can now see how guests attempted to pay
- **Stripe Minimum Amount Fix** (`stripePayment.ts`):
  - Stripe requires minimum €0.50 for Checkout Sessions
  - Added validation: `Math.max(rawDepositCents, 50)`
  - Small deposits auto-adjusted to €0.50 minimum
- **iCal Import Testing**:
  - Created test iCal files for Booking.com and Airbnb formats
  - Overbooking detection confirmed working (33 conflicts displayed)
- **Timeline Calendar Position Fix**:
  - Fixed UTC vs LOCAL timezone mismatch in booking position calculation
  - `timeline_grid_widget.dart`, `timeline_booking_block.dart` now use `DateTime.utc()`
- **Booking Move Feature Fix** (`firebase_booking_repository.dart`):
  - Fixed `updateBooking()` to handle unit changes with atomic Firestore batch
  - Delete from old path + create at new path in single transaction

**Changelog 6.15**: Stripe Live Mode Setup & Mobile URL Fix:
- **Stripe Live Mode Activated**:
  - Firebase secrets updated: `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET` (Live keys)
  - Webhook endpoint: `https://us-central1-rab-booking-248fc.cloudfunctions.net/handleStripeWebhook`
  - Events: `checkout.session.completed`, `checkout.session.expired`
  - Platform profile completed in Stripe Dashboard
- **Mobile App URL Fix** (`stripe_connect_setup_screen.dart`):
  - **Problem**: `Uri.base` returns empty string on native Android/iOS apps
  - **Error**: "Not a valid URL" when connecting Stripe account from mobile app
  - **Fix**: Added fallback to `https://app.bookbed.io` for Stripe Connect return/refresh URLs
  - Mobile apps now correctly redirect back to owner dashboard after Stripe onboarding

**Changelog 6.14**: Smart Price Mismatch Alerting - completed above

**Changelog 6.13**: Widget Embed Code & Month Display Fix:
- **Iframe Embed Code Improvement**:
  - Embed kod sada koristi `view.bookbed.io` domenu (ne `bookbed.io`)
  - Direktan iframe umjesto script-based embed.js
  - Responsive visina sa `aspect-ratio: 1/1.4; min-height: 500px; max-height: 850px;`
  - Owner samo kopira i zalijepi - radi na bilo kojem sajtu
  - Fajlovi: `embed_code_generator_dialog.dart`, `embed_widget_guide_screen.dart`
- **Month/Year Display Always Visible**:
  - **Problem**: U embedded widgetu, mjesec/godina ("Dec 2025") se nije prikazivalo na uskim iframe-ovima
  - **Uzrok**: `isTinyScreen < 360px` check sakrivao tekst, ali iframe može biti uži od device-a
  - **Fix** (`month_calendar_widget.dart:217-230`):
    - Mjesec/godina se UVIJEK prikazuje (uklonjen `if (!isTinyScreen)` check)
    - Na malim ekranima koristi manji font (`fontSizeXS`) umjesto skrivanja
    - Korisnik uvijek zna koji mjesec gleda

**Changelog 6.12**: Timeline Calendar Scroll Fixes & Turnover Visibility:
- **Scroll Bounce-Back Fix** (Android weak swipe issue):
  - **Problem**: Weak swipes on Timeline Calendar would bounce back instead of scrolling
  - **Root Cause**: `ClampingScrollPhysics.createBallisticSimulation()` returns `null` for low-velocity gestures
  - **Fix**: New `TimelineSnapScrollPhysics` class (`timeline_snap_scroll_physics.dart`):
    - Custom `createBallisticSimulation()` that ALWAYS returns a snap simulation
    - Critically damped spring (no oscillation) for smooth stop at day boundary
    - Low `minFlingVelocity` (10.0) to capture weak Android swipes
- **Feedback Loop Fix** (auto-scroll backwards/forwards):
  - **Problem**: Calendar auto-scrolled continuously after user swipe
  - **Root Cause**: `_updateVisibleRange` → parent updates → `didUpdateWidget` → scroll → loop
  - **Fix** (`timeline_calendar_widget.dart`):
    - Report CENTER of visible range instead of START (prevents position drift)
    - `didUpdateWidget` only scrolls when `forceScrollKey` changes (explicit user action)
    - Increased skip threshold from `visibleWidth/4` to `visibleWidth/2`
- **Toolbar Navigation Fix**:
  - Previous/Next/DatePicker buttons now increment `forceScrollKey++`
  - Required after feedback loop fix to trigger scroll in `didUpdateWidget`
- **Turnover Day Visibility** (`skewed_booking_painter.dart`):
  - Increased `turnoverGap` from 2px to 4px
  - Added 50% opacity diagonal separator lines on check-in/check-out edges
  - Turnover days now clearly visible in Timeline Calendar

**Changelog 6.11**: Flutter Animation Widget Library:
- **New animation widgets** (`lib/shared/widgets/animations/`):
  - `AnimatedEmptyState`: Fade+scale entrance for empty state screens
  - `AnimatedContentSwitcher`: Smooth skeleton→content crossfade transitions
  - `AnimatedCheckmark`: Custom painted checkmark with draw animation
  - `SuccessOverlay`: Full-screen success celebration overlay
  - `HoverScaleCard`, `HoverListTile`: Desktop hover effects with scale+shadow
  - `AnimatedCardEntrance`: Staggered fade+slide entrance for lists
  - `AnimatedDialog`: Scale/slide-up dialog entrance helpers
  - `AnimatedButton`: Press feedback micro-interactions
- **Applied animations**:
  - `owner_bookings_screen.dart`: AnimatedEmptyState for no bookings
  - `notifications_screen.dart`: Staggered empty state with 3 animation controllers
  - `unified_unit_hub_screen.dart`: AnimatedEmptyState for no units
  - `dashboard_overview_tab.dart`: AnimatedEmptyState for chart empty states
  - `lazy_calendar_container.dart`: AnimatedContentSwitcher for skeleton→calendar fade
- **Removed unused packages**: `lottie: ^3.1.0`, `confetti: ^0.8.0` from pubspec.yaml
- **Implementation plan**: `docs/research/ANIMATION_IMPLEMENTATION_PLAN.md`

**Changelog 6.10**: iCal Export Permission-Denied Bug Fix + Missing Index:
- **iCal Export Bug**:
  - **Problem**: iCal export failed with `permission-denied` error when generating .ics files
  - **Root Cause**: `fetchUnitBookings()` query used only `unit_id` filter, but Firestore security rules (Case 3) require `unit_id` + `status` for collection group queries
  - **Fix** (`firebase_booking_repository.dart:13-35`):
    - Added `status` whereIn filter to `fetchUnitBookings()` query
    - Now fetches only `pending`, `confirmed`, `completed` bookings (excludes `cancelled`)
    - Matches security rule Case 3: `('unit_id' in resource.data && 'status' in resource.data)`
  - **Cleanup** (`ical_export_service.dart`):
    - Removed redundant client-side status filtering (now done at query level)
    - Removed unused `enums.dart` import
- **Missing Firestore Index**:
  - **Problem**: `syncReminders.ts` Cloud Function failed with `FAILED_PRECONDITION: The query requires an index`
  - **Query**: `.where("created_at", ">=", ...).where("status", "in", [...])`
  - **Fix**: Added composite index `status` ASC + `created_at` ASC to `firestore.indexes.json` (lines 154-160)
  - **Note**: When combining range (`>=`) and equality/whereIn filters, equality fields must come FIRST in the index

**Changelog 6.9**: Platform Source Display for External Bookings:
- **PlatformIcon Widget** (`lib/shared/widgets/platform_icon.dart`):
  - Reusable widget za prikaz platforme bookinga
  - Ikone: **B** (plava #003580) = Booking.com, **A** (crvena #FF5A5F) = Airbnb, **W** (ljubičasta #7C3AED) = Direct, **🔗** (narandžasta) = iCal/External
  - Static helpers: `getDisplayName(source)`, `shouldShowIcon(source)`
- **Timeline Booking Blocks** (`timeline_booking_block.dart`):
  - Platform ikona u gornjem desnom uglu za external bookinge
  - Automatski offset (28px) ako postoji conflict warning ikona
- **Booking Details Dialog** (`booking_details_dialog.dart`):
  - Dodano "Izvor/Source" polje u Guest Information sekciju
  - Prikazuje se samo za `isExternalBooking` bookinge
  - Nova `_DetailRowWithWidget` klasa za custom child widgets
- **Conflict Messages**:
  - Snackbar u `owner_timeline_calendar_screen.dart` sada prikazuje platformu: "Guest (Booking.com)"
  - `_ConflictWarningBanner` u tooltipima već prikazuje platformu za svaki konflikt
- **Lokalizacija**: `ownerDetailsSource` - "Source" (EN) / "Izvor" (HR)

**Changelog 6.8**: Comprehensive Sentry Integration:
- **Flutter LoggingService** (`logging_service.dart`):
  - `logError()` sada šalje na Sentry via `captureException()` (fire-and-forget, non-blocking)
  - Novi `logNavigation()` method za breadcrumbs
  - `setUser()` za user identification (owner uid + email)
  - `clearUser()` poziva se na logout
- **Flutter NavigatorObserver** (`sentry_navigator_observer.dart`):
  - Automatski logira sve navigacije kao Sentry breadcrumbs
  - Dodano u `router_owner.dart` i `router_widget.dart`
  - Prati: push, pop, replace, remove akcije
- **Cloud Functions logger.ts**:
  - `logError()` automatski šalje na Sentry via `captureException()`
  - Svi errori sada imaju user context ako je `setUser()` pozvan
- **Cloud Functions setUser()** dodano na 17 funkcija:
  - `atomicBooking.ts`, `stripePayment.ts`, `stripeConnect.ts`
  - `icalSync.ts`, `guestCancelBooking.ts`, `verifyBookingAccess.ts`
  - `customEmail.ts`, `resendBookingEmail.ts`, `updateBookingTokenExpiration.ts`
  - `subdomainService.ts`, `emailVerification.ts` (sve 3 funkcije)
  - `airbnbApi.ts`, `bookingComApi.ts`, `passwordHistory.ts` (2 funkcije)
  - `passwordReset.ts`, `revokeTokens.ts`
- Guest/unauthenticated actions koriste: `setUser(null, email)` pattern
- **SKIP**: `authRateLimit.ts` - poziva se PRIJE autentikacije (nema user ID)

**Changelog 6.7**: Clipboard API Error Handling:
- **Problem**: Clipboard.setData() može baciti exception na nekim browserima (Safari u iframe-u)
- **Fix**: Dodano try-catch na sve Clipboard operacije u widget fajlovima:
  - `popup_blocked_dialog.dart`: Pokazuje error snackbar ako kopiranje ne uspije
  - `booking_reference_card.dart`: Tihi fail (referenca je vidljiva na ekranu)
  - `bank_transfer_instructions_card.dart`: Tihi fail (podaci su vidljivi na ekranu)
- **Pattern za buduće Clipboard operacije**:
  ```dart
  try {
    await Clipboard.setData(ClipboardData(text: value));
    if (context.mounted) {
      // Show success
    }
  } catch (e) {
    // Clipboard API can fail on some browsers (e.g., Safari in iframe)
    // Handle gracefully
  }
  ```

**Changelog 6.14**: Smart Price Mismatch Alerting (False Positive Fix):
- **Problem**: Sentry dobivao HIGH severity alert za SVAKI price mismatch, čak i za benigne scenarije:
  - Cached prices na klijentu (€2-5 razlika je normalna)
  - Floating-point rounding (< €0.10 je bezopasno)
  - Owner promijenio cijenu dok je korisnik bio na stranici
- **Rješenje**: Smart threshold u `priceValidation.ts` (line 287-325):
  - Sentry alert SAMO za sumnjive mismatche: `difference > €10` ILI `percentageDifference > 5%`
  - Male razlike (€0.01-10) se loguju u Cloud Logs, ali NE šalju na Sentry
  - Booking i dalje USPIJEVA sa server-calculated cijenom u oba slučaja
- **Stripe Fee clarification**:
  - Stripe fee (1.4% + €0.25) se **SKIDA SA OWNER-A**, ne dodaje se na cijenu
  - Korisnik plaća: `totalPrice = roomPrice + servicesTotal`
  - Owner dobija: `totalPrice - stripeFee` (npr. 170€ → 167.73€)
  - `servicesTotal` parametar se UVIJEK šalje sa klijenta na server za validaciju

**Changelog 6.6**: Security Helper Integration - All Helpers Now Active:
- **logRateLimitExceeded() integration**:
  - `authRateLimit.ts`: Login and registration rate limit events (severity: medium)
  - `atomicBooking.ts`: Widget booking rate limit events
  - `bookingAccessToken.ts`: Token verification rate limit events
  - All rate limit blocks now logged to Firestore + Cloud Logging
- **logPriceMismatch() integration**:
  - `priceValidation.ts`: Price manipulation detection (severity: high → Sentry alert)
  - Logs: unitId, clientPrice, serverPrice, difference, propertyId, dates
- **Security monitoring coverage complete**:
  - All helper functions from `securityMonitoring.ts` now actively used
  - Events flow: Firestore `security_events` + Cloud Logging + Sentry (critical/high)

**Changelog 6.5**: Cloud Functions Performance & Security Monitoring:
- **bookingLookup.ts Strategy 2 optimization**:
  - Problem: O(N×M) sequential queries (~5s for 100 properties × 10 units)
  - Solution: Parallel queries using `Promise.all()` (~500ms for same data)
  - Step 1: Fetch all units for all properties in parallel
  - Step 2: Build list of all booking paths to check
  - Step 3: Check all booking paths in parallel
  - Performance improvement: ~10x faster for comprehensive search fallback
- **Sentry integration for security monitoring**:
  - Critical events (`severity: "critical"`) now sent to Sentry as `fatal` level
  - High severity events (`severity: "high"`) sent as `error` level
  - Enables real-time alerting via Sentry dashboard/email for security incidents
  - Events tracked: webhook signature failures, price mismatch, suspicious bookings
  - Import: `import {captureMessage} from "../sentry";`

**Changelog 6.4**: Timeline Calendar Performance & Navigation Fixes:
- **Month navigation buttons requiring 2 clicks**: Fixed by canceling animation instead of skipping
- **FAB shadow invisible on hover**: `0.5.toInt() = 0` → `(0.5 * 255).toInt()`
- **Excessive rebuilds during scroll**: Dynamic threshold (30 days during animation vs 10 days normally)
- **_getDateRange() optimization**: Added `_cachedFullDateRange` caching (1460 objects generated once)
- **Scroll retry logging**: Simplified to reduce console spam

**Changelog 6.3**: Platform Connections Security Rules & Price Calendar Validation:
- **Permission-denied bug fix za "Označi kao dostupno" bulk akciju**:
  - Problem: Bulk update uspije ("Batch commit successful"), ali permission-denied error se pojavi
  - Uzrok: `platformConnectionsForUnitProvider` query na `platform_connections` kolekciju PRIJE bulk update-a
  - `platform_connections` kolekcija NIJE IMALA Firestore security rules definirana
  - Fix: Dodana nova sekcija u `firestore.rules`:
    ```javascript
    match /platform_connections/{connectionId} {
      allow read: if isResourceOwner();
      allow create: if canCreateAsOwner();
      allow update, delete: if isResourceOwner();
    }
    ```
- **Cross-validacija za min/max polja u price calendar edit dialogu**:
  - Min noći ne može biti veće od max noći
  - Min dana unaprijed ne može biti veće od max dana unaprijed
  - Pokazuje warning snackbar ako korisnik unese nelogičnu kombinaciju
  - Nove lokalizacije: `priceCalendarMinNightsCannotExceedMax`, `priceCalendarMinAdvanceCannotExceedMax`

**Changelog 6.2**: Widget UI Polish & Form Component Alignment:
- **Form component heights ujednačene na 50px**:
  - Verify button: 49px → 50px
  - Verified badge: 51px → 50px
  - Country dropdown: 50px (već bilo OK)
  - TextFormField: ~50px (contentPadding 14px vertical)
- **Skraćeni tekstovi za bolji UX**:
  - "Verify Email" → "Verify" (svi jezici)
  - "Credit Card (Stripe)" → "Credit Card"
  - "Continue to Bank Transfer" → "Bank Transfer"
  - Calendar-only banner: uklonjena druga rečenica o kontaktiranju vlasnika
- **Padding/spacing poboljšanja**:
  - Booking pill bar: dodano 8px horizontalnog paddinga na mobile
  - Month calendar mobile: padding smanjen sa 16px na 8px (left/right)
  - Header content centriran sa jednakim left/right paddingom
  - Info banner: 8px top padding, Contact pill bar: 8px bottom padding (calendar-only mode)
- **Header ikone**: responsive sizing za tiny screens (<360px) - ikone 18px umjesto 20px
- **Contact pill bar**: uklonjen text underline iz kontakt linka

**Changelog 6.1**: Cloud Functions FieldPath.documentId Bug Fix:
- **CRITICAL BUG FIX**: `FieldPath.documentId()` NE RADI sa `collectionGroup()` queries
  - Error: `When querying a collection group and ordering by FieldPath.documentId(), the corresponding value must result in a valid document path`
  - Firestore očekuje PUNI PUT dokumenta (npr. `properties/xxx/units/yyy/bookings/zzz`), ne samo ID (`zzz`)
- **Nova helper funkcija**: `functions/src/utils/bookingLookup.ts`
  - `findBookingById(bookingId, ownerId?)` - tri strategije:
    1. Query po `owner_id` polju (brzo ako je owner poznat)
    2. Comprehensive search kroz sve properties/units (sporije ali uvijek radi)
    3. Fallback na legacy `bookings` collection
  - `findBookingByReference(bookingReference)` - query po `booking_reference` polju
- **Popravljene Cloud Functions**:
  - `resendBookingEmail.ts` - koristi `findBookingById`
  - `customEmail.ts` - koristi `findBookingById`
  - `guestCancelBooking.ts` - koristi `findBookingById`
  - `twoWaySync.ts` - koristi `findBookingById`
  - `updateBookingTokenExpiration.ts` - koristi `findBookingById`
- **Dodan Firestore index**: `owner_id` single-field index za `bookings` collection group
- **PRAVILO**: Nikada ne koristi `FieldPath.documentId()` sa `collectionGroup()` - uvijek query po custom polju

**Changelog 6.0**: Widget Hybrid Loading & Native Splash Update:
- **Hybrid Progressive Loading**: Widget UI prikazuje se ODMAH sa skeleton kalendarom
  - Uklonjeno: BookBed Loader iz `booking_widget_screen.dart`
  - `LazyCalendarContainer` prikazuje skeleton dok se podaci učitavaju
  - `hideNativeSplash()` poziva se u `widget_main.dart` initState
  - Loading vrijeme smanjeno sa ~10-14s na ~4s
- **Native Splash minimalistički dizajn**: Crno-bijela shema umjesto ljubičaste
  - Light mode: `#000000` progress bar, `rgba(0,0,0,0.2)` track
  - Dark mode: `#FFFFFF` progress bar, `rgba(255,255,255,0.2)` track
  - Usklađeno sa BookBed Loader bojama
- **Obrisani fajlovi** (više se ne koriste):
  - `loading_screen.dart`, `smart_loading_screen.dart`, `smart_progress_controller.dart`
  - `loading_screen_test.dart`
- **InteractiveViewer (zoom) testiran i UKLONJEN**:
  - Zoom na kalendaru (1x-2x) testirano ali odlučeno da nije potrebno
  - Responsive dizajn + OS-level zoom već zadovoljavaju accessibility potrebe

**Changelog 5.9**: Booking Dialog Race Condition Fix:
- **Problem**: Booking details dialog otvarao se 2-3 puta kada korisnik navigira sa notifications page na bookings page
- **Uzrok**: Async race condition između `setState()`, `router.go()` i `addPostFrameCallback()`
- **Fix** (`owner_bookings_screen.dart`):
  1. Uklonjen `!_isLoadingInitialBooking` check koji je blokirao dialog opening
  2. URL query params čiste se PRIJE resetovanja state flags-a (ne poslije)
  3. Dodani `!_dialogShownForBooking` checks na SVE putanje koje setuju `_pendingBookingToShow`
  4. `_pendingBookingToShow = null` postavlja se odmah nakon što se `_dialogShownForBooking = true` setuje
  5. Dodatni guard za `pendingBookingIdProvider` setting iz URL-a
- **Ključni princip**: Redoslijed cleanup-a je kritičan - URL mora biti očišćen PRIJE nego što se resetuju flags-ovi

**Changelog 5.8**: Analytics Security Rules Fix:
- **Problem**: Analytics page vraćala `permission-denied` error za `collectionGroup('bookings')` query
- **Uzrok**: Firestore security rules nisu dozvoljavale authenticated korisnicima query po `unit_id` + `check_in`
- **Fix**: Dodana nova rule u `firestore.rules` za analytics queries (Case 2)
- Dodano `print()` logging u analytics provider/repository za debug u release mode
- Index `bookings: unit_id + check_in` (Collection Group) već postojao - problem bio samo u rules

**Changelog 5.7**: Bug Fixes & Error Boundaries:
- ErrorBoundary wrapperi dodani na Loader widgete u `router_owner.dart` (PropertyEditLoader, UnitEditLoader, UnitPricingLoader, WidgetSettingsLoader)
- Warning dialogs integrirani: `UpdateBookingWarningDialog` u edit_booking_dialog, `UnblockWarningDialog` u price_list_calendar
- Timezone fix: `DateNormalizer.normalize()` u validateAdvanceBooking umjesto lokalnog DateTime
- Language fallback: `🌐` globe emoji za nepoznate jezike umjesto hardcoded `🇭🇷`
- Skeleton loader: named constants umjesto magic numbers u month_calendar_skeleton
- Async timeouts utility već postoji (`async_utils.dart`, `timeout_constants.dart`) - dokumentirano

**Changelog 5.6**: PWA install button i connectivity banner widgeti, JS/Dart interop za PWA install prompt.

**Changelog 5.5**: Email System Reorganization:
- Payment deadline: 3 dana → **7 dana** (atomicBooking.ts:870)
- Check-in reminder: 1 dan → **7 dana** prije
- Payment reminder: **Dan 6** (1 dan prije isteka)
- Uklonjeni `-v2` suffix iz template imena
- Premješteni template-i iz `version-2/` u `templates/`
- Uklonjen `suspicious-activity.ts` (TODO za budućnost)
- Nova dokumentacija: `EMAIL_SYSTEM.md`

**Changelog 5.4**: Stripe Security Improvements implementirane:
- Rate limiting na `createStripeCheckoutSession` (10 req/5min per IP)
- Stripe Connect account verification (`charges_enabled`, `card_payments`, `transfers`)
- Security monitoring (`securityMonitoring.ts`) - logira kritične security evente
- Firestore rules za bookings: selektivni pristup (owner, widget calendar, Stripe polling, booking view)
- Error message cleanup - generičke poruke za klijente, detalji samo u logovima

**Changelog 5.3**: Owner email UVIJEK se šalje za svaki booking (Bug Archive #2) - `forceIfCritical=true` u atomicBooking.ts. Dok nema push notifications, owner ne smije propustiti rezervaciju.

**Changelog 5.2**: Keyboard fix threshold usklađivanje (JS/Dart 12%/15%), window.resize fallback, EPC QR validacija sa currency parametrom.

**Changelog 5.1**: Dodana Firestore indexi sekcija, browser_detection conditional imports, upozorenje o dart:js_interop.

**Changelog 5.0**: Firestore collection group query bug fix - NE koristiti FieldPath.documentId sa collectionGroup(), dodano sessionId u cross-tab messaging.

**Changelog 4.9**: Android Chrome keyboard dismiss fix (Flutter #175074) - JavaScript "jiggle" method + Dart mixin za sve forme.

**Changelog 4.8**: Widget snackbar boje usklađene sa calendar statusima.

**Changelog 4.7**: Multi-platform build dokumentacija - Android release mode, conditional imports, dependency verzije.

**Changelog 4.6**: URL slug sistem za clean URLs (`/apartman-6` umjesto query params).

---

## Changelog 5.9: Performance & Security Optimizations (2026-01-13)

**Portirane optimizacije iz feature brancheva:**

### Performance
| Optimizacija | Datoteke | Korist |
|--------------|----------|--------|
| `keepAlive: true` calendar provider | `owner_calendar_provider.dart` | Nema re-fetch pri navigaciji |
| 3m/9m date range (umjesto 12m/12m) | `owner_calendar_provider.dart` | ~75% manje Firestore reads |
| `unitToPropertyMap` passthrough | `firebase_owner_bookings_repository.dart` | Eliminira N+1 queries za iCal |
| `aggregate(sum())` za revenue | `firebase_revenue_analytics_repository.dart` | 1 query umjesto 100+ reads |
| `collectionGroup.count()` | `admin_users_repository.dart` | N+1 → 1 query |
| Skip redundant profile fetch | `enhanced_auth_provider.dart` | Nema double-fetch na login |
| Memory cache za rate limit | `rate_limit_service.dart` | Manje Firestore reads za locked accounts |

### Security
| Fix | Datoteke | Opis |
|-----|----------|------|
| owner_id integrity check | `firestore.rules` | Sprječava fake owner_id injection |
| Log redaction (GDPR) | `logging_service.dart` | Redaktira passworde, tokene, API keys |
| Token masking | `ical_export_service.dart` | Maskira Firebase Storage tokene |

**Preskočene grane:** `bolt-optimize-booking-retrieval` (pagination rizik), `bolt-property-global-store` (veliko refaktoriranje), `jules/security-audit-fixes` (XSS već riješen), `chore/weekly-dependency-updates` (ručno updatati).
