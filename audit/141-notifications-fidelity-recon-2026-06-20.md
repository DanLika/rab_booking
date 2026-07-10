# audit/141 — Notifications (inbox) fidelity recon

**Date:** 2026-06-20 · **Status:** RECON ONLY — read-only, **no code changed**. Every row below is a separate future GO.
**Anchor:** `origin/main` `feae40fe` (#771). **Terminal:** recon-w1 (Wave-1 cheap cluster).
**Scope:** LAYOUT / COMPOSITION / DATA only. Color/chrome already settled by audit/126 (global chrome) + audit/127 (palette/surface) — **out of scope**.

---

## Screen ↔ handoff mapping (decided first)

| Handoff | Maps to | NOT |
|---------|---------|-----|
| `design_handoff/source/notifications.jsx` (376 LOC) — *"Typed categories · inline actions · mark-all-read · empty/loading"* = the **inbox/list** | `lib/features/owner_dashboard/presentation/screens/notifications_screen.dart` (803 LOC) | `notification_settings_screen.dart` (preferences toggles — already touched audit/135 §banner-l10n). The settings screen is **not** part of this handoff. |

Supporting code read: `providers/notifications_provider.dart`, `domain/models/notification_model.dart`.

---

## Current-state map (code @ `feae40fe`)

- `CommonAppBar(title, leading: menu→drawer)`; selection-mode swaps to a dedicated **primary-colored `AppBar`** (close / select-all / delete-selected / overflow→delete-all).
- Body = `context.gradients.pageBackground` + `Stack`, `notificationsAsync.when(data/loading/error)`.
- **data** → `BBContentMaxWidth(maxWidth: 1100)` (`:200`) + `RefreshIndicator` + `ListView.builder` over `groupedNotificationsProvider`. Each group = `BbSectionHeader(dateKey, count, h3)` then **one `BbCard` per notification**.
- `_NotificationRow`: `BbCard(accentLeft if unread)`, 40px tone-tinted icon disc, title (w700 if unread) + relative time (tabular) + 8px unread dot, 2-line body, **inline approve/reject** (`success` + `destructiveSoft`) ONLY for `bookingCreated` + `bookingId` (audit/114 F3), chevron when no action.
- FAB `checklist` → selection mode (when not selecting & list non-empty). Swipe-to-dismiss → delete (`Dismissible`, endToStart).
- Empty: `BbEmptyState(notifications_off)` animated, **no CTA**. Error: disc + retry. Loading: `SkeletonLoader.notificationsList`.

## Handoff ground-truth (`notifications.jsx`)

- **Desktop 2-col grid `1fr 320px`**: LEFT = **header row** [`h1` "Obavještenja" + caption "3 nepročitano · ukupno 8" + buttons **Označi sve kao pročitano** (tertiary, done_all) / **Odaberi** (secondary, checklist)] → **NotifFilters** → NotifList. RIGHT 320px = STANJA·LOADING + STANJA·EMPTY previews.
- **NotifFilters** chip row: Sve(8) / Nepročitano(dot,3) / Rezervacije / Plaćanja / Sustav.
- **NotifList** grouped (Danas / Jučer / Ovaj tjedan): `NotifGroupLabel` = pill badge (uppercase, primary-tint) + trailing flex divider line; **each group in ONE `BBCard(padded=false)`** with row dividers.
- **NotifRow**: unread → tint bg + 3px left bar; 40 tone disc; title + relative time (`title={fullTime}` tooltip); body; **action button** (Odobri / Ocijeni, iconRight `arrow_forward`) per `n.action`; chevron when none.
- Mobile: appbar(done_all) + filters(sm) + list(4, compact) + **bulk-select FAB** (checklist, purple). Tablet: rail + appbar(done_all + tune) + filters(sm) + list(5, compact).

---

## Diff ledger

| ID | Sev | Type | Finding | Recommendation |
|----|-----|------|---------|----------------|
| **N1** | High | LAYOUT/COMP | **No in-body premium header.** Handoff desktop shows `h1` "Obavještenja" + "X nepročitano · ukupno Y" count line in-body; code shows the title only in `CommonAppBar`, no count. Every sibling premium owner screen (Pregled/Rezervacije/FAQ) carries the eyebrow+display hero — notifications is the lone holdout. | Add premium header (eyebrow OBAVJEŠTENJA + display + count subtitle). **Count is buildable**: `unreadNotificationsCountProvider` (`provider:28`) + `allNotifications.length`. |
| **N2** | High | COMP | **Mark-all-read action absent.** Handoff header button "Označi sve kao pročitano". Code never surfaces it **even though `NotificationActions.markAllAsRead(ownerId)` already exists** (`provider:117`). Capability built, UI unwired. | Wire a mark-all-read control (header on desktop, appbar `done_all` on mobile/tablet, per handoff). **Not a new feature.** |
| **N3** | Med | COMP | **No filter chips.** Handoff `NotifFilters` [Sve / Nepročitano / Rezervacije / Plaćanja / Sustav] on all breakpoints; code has none. Filter data exists (`type` enum + `isRead`). | Add a client-side filter chip row. Map: Rezervacije→`booking*` types, Plaćanja→`paymentReceived`, Sustav→`system`, Nepročitano→`!isRead`. Buildable. |
| **N4** | Low | LAYOUT | **Group-label styling.** Handoff = pill badge (primary-tint, uppercase) + trailing divider line; code = `BbSectionHeader(h3)` + count. | Optional: adopt the pill+divider treatment for fidelity, or keep section-header (consistent with other screens). Operator call. |
| **N5** | Low | INT | **Per-item cards vs one-card-per-group.** Handoff wraps each group in ONE `BBCard(padded=false)` w/ dividers; code uses a separate `BbCard` per row — same intentional drift as FAQ (per-item-card mandate). | Keep (INT). |
| **N6** | Low | LAYOUT | **Empty-state CTA missing.** Handoff `NotifEmptyState` has primary "Postavke obavijesti" (tune) → notification settings. Code `BbEmptyState` has no action. | Add the CTA → push `notification_settings_screen` (exists). Buildable. |
| **N7** | — | NOTE | **Desktop right 320px state-preview sidebar = artboard-only** (LOADING/EMPTY shown side-by-side for design review). NOT runtime UI — code correctly omits. | No action — do **not** build a permanent preview column. |
| **N8** | Low | LAYOUT | **Relative-time tooltip.** Handoff time cell has `title={fullTime}` hover tooltip; code has none. | Optional `Tooltip` on the time text; low value on touch. |
| **N9** | — | code-ahead | Code adds swipe-to-delete, multi-select mode, delete-all, `RefreshIndicator`, and inline approve **AND** reject (handoff shows a single generic action). Richer than handoff. | Keep. |

## Data-honesty (flag handoff fields the model lacks — do NOT invent)

| ID | Handoff field | Model reality | Verdict |
|----|---------------|---------------|---------|
| **D1** | "Ocijeni" action + "Rezervacija završena" / "Nova ocjena 5,0★" rows (types `completed`/`review`) | `NotificationType` = {bookingCreated, bookingUpdated, bookingCancelled, paymentReceived, system} — **no completed/review type; no guest-rating feature anywhere** | **Omit — honest.** Don't invent a rating flow. |
| **D2** | "Booking.com sinkronizacija" sync-result row (type `sync`) | No `sync` `NotificationType`; sync runs server-side with no per-sync notification doc | **Omit — honest.** |
| **D3** | "Ovaj tjedan" single bucket | Code groups Danas / Jučer / `<weekday>` / `<d.m.y>` (`provider:60-70`) — finer granularity, can emit many headers | Minor divergence; code is more precise. *Optional* tidy-up: collapse >2-day into "Ovaj tjedan" / "Ranije". Cosmetic. |
| **D4** | `system` tone = `info` | Code `system` → `primary` tone (`:595`) | **Color-domain** — out of 141 scope (127 done). Noted only. |

## Breakpoint (per breakpoint-decide discriminator)

Only surface = `BBContentMaxWidth(maxWidth: 1100)` (`:200`) — a **content-max-width clamp** (different axis per the discriminator, §47) → unify to the `BBContentMaxWidth` default (1200) as **hygiene** if/when the screen is touched. **No device-class pivot exists on this screen** (there is no desktop layout switch to migrate). Low priority; fold into the apply PR.

---

## Recommendation / packaging

- **Headline = N1 + N2** (premium header + mark-all-read): both **buildable from existing providers**, high visual payoff, low risk.
- **Next tier = N3** (filter chips): medium effort, purely client-side.
- **Polish = N4 / N6 / N8.** Bundle all as one "notifications premium fidelity" apply PR; fold the 1100→1200 clamp hygiene in. Eyeball **600 / 900 / 1100 / 1300, light + dark**.

## FROZEN

None on this screen. audit/114 F3 inline approve/reject logic = **move-not-delete** if the row is refactored (preserve the type+bookingId gate + best-effort markAsRead swallow).

## Gates

Read-only recon — no code, gates **n/a**. A resulting fix PR runs the standard ladder (`dart format` · `flutter analyze` 0 net-new · `flutter test` · `flutter build web --no-tree-shake-icons`) + the band eyeball.
