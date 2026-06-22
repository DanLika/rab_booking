# Widget live-smoke checklist (manual, dev)

Manual end-to-end smoke of the public booking widget. The golden net + the rules
(#789) + CF (#790) pen-tests cover the static/logic layers; **this catches the
live, render-time, cross-origin, and real-world-flow gaps a terminal can't drive**
(synthetic events stop at Flutter's accessibility shadow — run this by hand).

> **Env: `bookbed-dev` only.** Run each row, fill **Actual** + **P/F**.
>
> **App Check (dev): audit-style, NOT off, NOT enforced.** Verified in code:
> the widget client does **not** activate App Check (`widget_main_dev.dart:75`
> "intentionally NOT activated" → no token minted); the widget-facing CFs use
> `consumeAppCheckToken: true` + `enforceAppCheck: false` (`availability.ts:133`)
> → they validate a token *if present* but do **not** reject missing ones. So the
> widget loads without a recaptcha hang on dev. **⚠ This smoke does NOT cover prod
> App Check enforcement** — flipping `enforceAppCheck: true` (gated behind the web
> CSP pre-flight / Option B) is a separate risk; a prod 403-token hang would not
> surface here.

## 0. Pre-flight
| # | Step | Expected | Actual | P/F |
|---|---|---|---|---|
|0.1| Seed dev: 1 property, 3 units (one per tier), owner `accountStatus:active`, daily_prices set, one unit with a Stripe-connected owner | seed lands, no rules denials | | |
|0.2| Open `view.bookbed.io/?property=…&unit=…` in **fresh incognito** (clears SW cache) | widget paints < 3s, no eternal skeleton, console clean | | |
|0.3| Hard-refresh on a warm SW | no stale-SW white screen | | |

## 1. Load & chrome — per **platform × locale**
Matrix: **Chrome (`flutter run -d chrome`) × iOS sim**, **HR × EN** (`?lang=hr` / `?lang=en`).
| # | Step | Expected | Actual | P/F |
|---|---|---|---|---|
|1.1| Header / calendar / price chrome renders | correct, no tofu / overflow | | |
|1.2| All visible strings localized | HR fully translated incl. dialogs/toasts, no English leak | | |
|1.3| Diacritics (š/č/ć/ž/đ) + € | sharp | | |

## 2. Tier A — calendar-only
| # | Step | Expected | Actual | P/F |
|---|---|---|---|---|
|2.1| Browse months; past dates disabled | past greyed, no select | | |
|2.2| Select range → no booking CTA (calendar-only mode) | availability shown, no submit | | |

## 3. Tier B — reservation, no payment (`booking_pending`)
| # | Step | Expected | Actual | P/F |
|---|---|---|---|---|
|3.1| Select valid range, fill guest form, submit | "pending / awaiting owner approval", **no** payment step | | |
|3.2| Owner dashboard shows the pending booking | appears, status pending | | |
|3.3| Submit with **0 nights** / **past date** (devtools date hack) | rejected with message (SF-026; matches CF probes a/c) | | |

## 4. Tier C — Stripe card (`booking_instant`)
| # | Step | Expected | Actual | P/F |
|---|---|---|---|---|
|4.1| Select range → Stripe checkout (TEST card `4242…`) | redirects/embeds Stripe, amount in **EUR** = server price | | |
|4.2| Complete payment | booking confirmed, owner notified, calendar blocks the dates | | |
|4.3| **Abandon** checkout / hit back | no **confirmed** booking. **OPEN QUESTION — inspect the pending placeholder: does it expire (TTL / `cleanupExpiredPendingBookings`) or block the dates indefinitely?** If no expiry → abandoned checkouts dead-block dates = real bug. Record actual behaviour, do not assume pass. | | |

## 5. iCal external blocks
| # | Step | Expected | Actual | P/F |
|---|---|---|---|---|
|5.1| Seed feeds: Booking.com + Airbnb + Adriagate with overlapping blocks | feeds sync | | |
|5.2| Widget calendar reflects all 3 sources' blocked dates | blocked, not bookable | | |
|5.3| Turnover edge: checkout day = next checkin day | **interval-subtract correct** — same-day turnover bookable, no off-by-one | | |
|5.4| **Adriagate merged adjacent events** (back-to-back blocks that share a boundary) | interval-subtract treats the merged span as one block, **not a false-positive gap/error**. NB: pro channel managers do NOT export computed min-stay gap blocks — OTAs enforce min-stay themselves — so a "gap" between merged events is normal, not missing data. | | |

## 6. (j) price-tamper — live confirmation of the CF finding 🟡
> Code finding (#790): `atomicBooking.ts` L673-702 **catches and swallows** the
> `priceValidation` "Price mismatch — please refresh" throw (L385) and overrides
> to the server price. Revenue-safe; **dispute-exposed** (silent). Open steer.

| # | Step | Expected | Actual | P/F |
|---|---|---|---|---|
|6.1| Intercept the booking call (devtools), send `totalPrice` **far below** server (e.g. €1 for a €200 stay) | booking succeeds; persisted/charged = **server €200** (manipulation fails) | | |
|6.2| **Observe the guest UX on the override** | ⚠ booking proceeds at €200 with **NO "price changed" prompt** (silent override) | | |
|6.3| **Stale-UI sim** (the realistic trigger): open widget, change the owner's price in another tab, then book at the old price | guest is silently booked/charged the NEW server price with no signal → **live evidence for the A-vs-B dispute steer** | | |

## 7. Embed modes
| # | Step | Expected | Actual | P/F |
|---|---|---|---|---|
|7.1| Standalone `view.bookbed.io/…` | full flow works (covered above) | | |
|7.2| `iframe` overlay (`bookbed-overlay.js`) on a **Netlify template demo** owner site | loads in iframe; **console clean of CSP violations — esp. `*.gstatic.com` CanvasKit WASM load** (recent CSP `connect-src` fix); **widget→host `postMessage` works cross-origin** (auto-height resize + completion redirect cross the origin boundary); returns to host page | | |

## 8. Tier-gating (deferred feature — confirm current behaviour, don't assume)
| # | Step | Expected | Actual | P/F |
|---|---|---|---|---|
|8.1| On a **calendar-only (Tier A)** unit, force a booking-submit call via devtools (Tier B/C payload) | **Record actual:** does the CF/rules layer reject the tier-mismatch, or does the booking go through? Tier gating is *deferred until real usage* — this confirms whether a Tier-A unit can be coerced into a paid/reservation booking it isn't configured for. | | |

## 9. Responsive mid-widths (golden net doesn't cover these)
| # | Step | Expected | Actual | P/F |
|---|---|---|---|---|
|9.1| Drag-resize Chrome through 600–900px and 900–1200px bands | no overflow stripes; calendar/form reflow cleanly at the in-between widths | | |
|9.2| iOS sim rotate portrait↔landscape | reflows, no clipped CTA | | |

---
**Sign-off:** date · build SHA · tester · overall PASS/FAIL · any **(j) dispute** observations (6.2/6.3) · any **4.3 placeholder-expiry** / **8.1 tier-gating** findings.
