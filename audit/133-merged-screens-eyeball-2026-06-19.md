# audit/133 — Merged-screens verification eyeball (main `ec9be53b`) — 2026-06-19

**Scope:** Live + code verification of the 3 most-recently-merged owner screens on `main` @ `ec9be53b` — two of which were merged **UNVERIFIED**. **No code changed this session**; this is a verification record + open-item ledger feeding the owner PROD-deploy decision.

The three:
1. **AI Asistent** streaming + user-avatar (audit/132, `10d7a97c`).
2. **Mjesečni** month-calendar handoff fidelity (audit/130, merge `5e92a0c9`).
3. **Timeline** vertical-scroll wheel fix (`7aa2bd2d`, merge `ec9be53b`) — merged **UNVERIFIED, wheel-only**.

**Method:** `flutter run -d web-server -t lib/main_dev.dart` @ `:8095` (bookbed-dev) — launched via `run_in_background` with a `tail -f /dev/null |` stdin keep-alive (bare `flutter run` self-quits on stdin EOF when detached). Seeded `scripts/seed-mcal-eyeball-dev.js` (5 canonical June bookings under unit **Studio B** = `SEED_rez_smoke_unit_b`). Live-driven via **chrome-devtools** (CanvasKit — Marionette is not wired for Flutter web here) + **2 read-only code-truth agents** (Timeline scroll architecture; AI streaming wiring). Logged in as `bookbed-test@bookbed.io` (owner "BookBed Test", initials **BT**).

---

## 1. AI Asistent — initials ✅ LIVE; streaming code-correct, App-Check-blocked on this profile

| Check | Result |
|---|---|
| User-bubble initials from `enhancedAuthProvider.userModel` (not `"?"`) | ✅ **LIVE** — bubble shows **`BT`** |
| Typing dots → streamed text on first chunk | ✅ **code-correct**; ⚠️ **not observable live here** (App Check) |

- **Initials live-verified.** Sending the iCal-sync question rendered a user bubble with avatar **`BT`** + timestamp. This **closes the eyeball-gate** that audit/132 flagged for the `buildAiMessageBubble` call site ([T1] dispatch test was deferred; wiring was eyeball-only — see [[seam-test-proves-fn-not-wiring]]). Wiring is confirmed wired.
- **Streaming UI = code-correct** (code-truth agent): real `firebase_ai` `_chatSession.sendMessageStream` (`gemini-2.5-flash-lite`), `typing:true` while `streamingText.isEmpty`, data-driven flip dots→text on first chunk (`ai_assistant_screen.dart:809-821`, `ai_chat_provider.dart:411-416`), `_TypingDots` animated indicator, scroll heartbeat untouched. No stray `'...'`/`'?'` call site; `typing`/`userName`/`userAvatarUrl` are `required` (compile-guard).
- **Streaming did NOT run live here.** The full pipeline ran (console: `sendMessage` → blocked-keyword check → **KB loaded 39992 chars** → model created → "sending message to Gemini") then died at the **runtime SDK console error** `[ERROR] AiChat: Gemini error / [app-check/recaptcha-error] AppCheck: ReCAPTCHA error.` (this is a `firebase_app_check` SDK code, **not** an in-repo string). The Gemini call is gated by **App Check**, which can't mint a token on a **clean automation Chrome profile** — code-confirmed `app_check_init.dart:37-46`: no `APP_CHECK_RECAPTCHA_KEY` dart-define → `ReCaptchaV3Provider('placeholder-debug-only')` → `recaptcha/api2/clr` 400, no registered debug token. It surfaced as the **generic "Nešto je pošlo po krivu" error banner** (the App Check error is not a `FirebaseAIException`, so it bypasses the `ai_unavailable` classifier at `ai_chat_provider.dart:489` and hits the generic catch). **Env blocker, not a code regression** — refines [[firebase-ai-appcheck-sim-emulator-403]] (the prior "web works ✓" needs the operator's browser to carry a registered App Check **debug token** OR a real `APP_CHECK_RECAPTCHA_KEY`; a fresh profile fails identically to sim/emulator).
- **PROD impact: none currently** — AI Asistent is dev-only (not deployed).

## 2. Mjesečni (month calendar) — ✅ light + dark + mobile

- **Light (desktop):** all 5 seeded bookings paint with correct status colours and spans — green Ana Kovač 4–7 (Potvrđeno), orange Marko Horvat 9–11 (Na čekanju), purple Iva Novak 13–15 (Završeno, spans wk2→wk3), green Luka Marić 20–24 (spans wk3→wk4), orange Petra Babić 26–28. **Weekend tint** on SUB/NED ✅, **"DOLASCI · 7D"** KPI ✅, **"Xn"** nights on bars ✅, today (19) circled, Studio B default-selected.
- **Dark:** OLED-black shell, dark elevated KPI cards, status colours brightened for dark, weekend tint preserved (audit/127 dark ladder).
- **Mobile 390:** **status dots** on day cells (not spanning bars) + **custom day-agenda below the grid** — code-confirmed `month_calendar_screen.dart`: `isMobile = width<600` (line 175), `_buildDayAgenda` gated by `if(isMobile)` (lines 319-322, handoff `calendar-month.jsx`), `showAgenda:!isMobile` (built-in agenda off on mobile, line 487). `_buildMonthCell` renders the date number always + status **dots MOBILE-only** (lines 694-718, max 4); the count-badge was **intentionally dropped** on desktop/tablet (G1 de-clutter) — the line-611 doc-comment still names a badge but it's no longer rendered. Dots seen live; agenda is the below-fold selected-day list.
- **Eyeball gotcha:** SfCalendar appointments need a **fresh mount** to paint (CanvasKit paint-lag) — navigate away+back, do not just resize ([[owner-month-calendar-live-capture-recipe]]).
- **Verdict: ship-ready.** ("samo vizualna fidelity" per operator.)

## 3. Timeline — renders ✅; wheel-fix code-correct + arch-sufficient; touch-drag gap (the open risk)

- **Renders correctly:** June bookings as angled turnover bars (green Luka 20–24, orange Petra 26–28), today (19) column highlighted, full premium chrome (Timeline∣Mjesečni switch, KPI strip, search/refresh/Filteri/today/Obavijesti 9+/statistika/hide-empty toolbar, legend incl. **Uvezene** pill, FAB).
- **Heads-up (not the merged change):** Timeline **opens on srpanj (July, empty window)** — `‹` (Prethodni mjesec) once → **lipanj (June)** where the bookings are. The code's default `initialScrollToDate` is **today, June 19** (`owner_timeline_calendar_screen.dart:184`/`:544`), so this is an unexplained **first-paint horizontal-scroll offset**, NOT a wrong default range; pre-existing, low priority.

**Presuda — page vs grid scroll, wheel-hook vs restructure** (code-truth agent on `timeline_calendar_widget.dart`):
- **Only the calendar grid scrolls; the page is FIXED** (Scaffold body is a `Column`, grid is the sole `Expanded` scroll region — no page-level scroll view).
- **Root cause:** the vertical SCV is **nested inside** the horizontal SCV (`TimelineSnapScrollPhysics`), so the outer horizontal `Scrollable` claims the wheel `PointerSignal`; vertical wheel deltas never reach the inner viewport.
- **The fix** (`_handleTimelinePointerSignal`, `timeline_calendar_widget.dart:1655-1668`): `Listener(onPointerSignal:)` forwards the dominant-vertical wheel delta to `_verticalScrollController.jumpTo(pixels+dy)` **clamped, applied once (1× — no scaling/double-apply)**; horizontal-dominant wheels (`dy ≤ dx`) pass through (day-scroll preserved); the unit-name column follows via the existing `_verticalScrollController ↔ _unitNamesScrollController` sync listener.
- **VERDICT: the wheel-hook is SUFFICIENT for the wheel path — NO parent-scroll restructure needed.** A restructure would require de-nesting the two-axis SCVs, i.e. touching the **FROZEN** grid (`timeline_dimensions` / cell-geometry / repo) — forbidden and higher-risk. `Listener.onPointerSignal` is a passive observer (doesn't compete in the gesture arena), so no nested-scroll conflict and horizontal day-scroll is untouched. Keep the hook.

**Two caveats (open):**
1. **Wheel sync + 1× speed: NOT live-verifiable here.** Synthetic `wheel` events dispatched over the grid moved nothing (re-confirms [[flutter-web-scroll-not-automatable]] — synthetic wheel never reaches Flutter's pipeline). Needs a **real mouse-wheel/trackpad** eyeball: grid rows + frozen unit column scroll together, 1×, horizontal day-pan still works.
2. **Touch-drag is NOT addressed by this fix.** The `Listener` catches only `PointerSignalEvent` (wheel). Touch/trackpad **drag** (`PointerMove` via the gesture arena) is still claimed by the outer horizontal Scrollable; the commit notes drag was reportedly also affected and is left untouched + unverified. **Verify vertical touch-drag on a real touch device**; if broken it needs a **separate** fix (still without de-nesting the FROZEN grid).

---

## Verdicts & open items

| Screen | Verdict | Open before "closed" |
|---|---|---|
| Mjesečni | ✅ ship-ready (light+dark+mobile) | — |
| AI Asistent | code-correct; initials ✅ live; streaming env-blocked on clean profile | confirm streaming on operator Chrome (registered debug token) or register a dev debug token; **dev-only → not in PROD scope** |
| Timeline wheel-fix | code-correct + architecturally sufficient (no restructure) | **physical wheel eyeball** + **touch-device drag check**; touch-drag gap = parallel fix if broken |

**PROD-deploy decision input:** Mjesečni clears. Timeline wheel-fix is sound in code but its two dynamic behaviors (wheel, touch-drag) are unverified by automation — gate on the operator's physical input check. AI is dev-only (out of PROD scope this round).

## Method gotchas (chrome-devtools CanvasKit live-drive)

- **Login:** CanvasKit a11y tree is empty until the **"Enable accessibility"** placeholder is clicked (programmatic `.click()` if the off-screen 1px node won't take a normal click) — then form fields become addressable.
- **Flutter password field append-bug:** `fill_form` + `Meta+A` does **not** select-all inside Flutter's text field; `type_text` then **appends** → wrong password. Fix: set the active hidden `<input>.value` directly + dispatch an `InputEvent('input')` so Flutter's text-editing strategy adopts the corrected value.
- **SfCalendar paint-lag:** appointments aren't in the a11y tree and don't paint on first layout — **fresh-mount** (route away+back) + `wait_for` a known string, then screenshot.
- **Scroll is not automatable** (wheel/drag) — see [[flutter-web-scroll-not-automatable]]. Taps are.
