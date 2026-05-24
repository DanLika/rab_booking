# audit/39 — N4 root-cause investigation: Flutter Engine keyboard converter null-toString

**Date:** 2026-05-24
**Investigator:** Claude Code (chrome-devtools MCP)
**Trigger:** User request to trace audit/33 §4.4 N4 — `Uncaught TypeError: Cannot read properties of null (reading 'toString')` on `bookbed-owner-dev.web.app` login page
**Status:** SAFETY-CLAUSE NO-FIX. Root cause is in Flutter Engine (framework), not BookBed code.

---

## 1. TL;DR

- **Reproduced** a stack trace matching audit/33 §4.4 N4 error message.
- **Root cause** is in Flutter Engine's web keyboard converter at the equivalent of `flutter/lib/web_ui/lib/src/engine/keyboard.dart` — `lookupTable[event.key][event.location]!` returns null when the location index has no logical-key entry, and Dart's `!` null-assertion compiles to `q.toString` in dart2js, which throws.
- **Frames are 100% Flutter framework code** (`A.bav` = KeyboardConverter, `A.bas`/`A.bat` = keyup/keydown listeners, `nv.bi` = HashMap iterator). Zero BookBed application code in the trace.
- **Per audit/33 safety constraint** ("If error traces to non-BookBed code → document, don't fix"): no BookBed code change written. No PR.
- **CHANGELOG 6.68's null.toString hardening pattern does NOT apply** — that fix was for `Uri(queryParameters: {nullable: x})` in the widget; this is a different bug class. Memory `flutter-web-uri-null-tostring.md` already warned: *"Login submit crashes in the smoke test were a separate bug class — CanvasKit text-input sync gap, not this pattern. Do not conflate."* Confirmed.

---

## 2. Trigger mismatch — flag, do not paper over

- **Audit/33 §4.4 claims** N4 fired "during initial load BEFORE any login attempt" on `bookbed-owner-dev.web.app` in fresh incognito.
- **This investigation** could only reproduce the error via Chrome DevTools `Input.dispatchKeyEvent` (`type_text`) — a synthetic keyboard event injected by automation.
- **Audit/33 did NOT capture a stack trace** — only the error message text from `list_console_messages`. The "before login attempt" attribution was inferred from msgid ordering, not from a timestamp.
- **Therefore:** the audit/33 N4 trigger condition is **unverified** to match this investigation's repro. Possible alternative triggers for audit/33's initial-load capture:
  - Chrome password-autofill probe (note `[DOM] Password forms should have username fields` console verbose hint observed during this investigation — autofill heuristic ran)
  - Browser extension synthetic input
  - Service worker activation cycle dispatching events
  - msgid ordering misattribution (N4 may have fired AFTER the Prijava click, with the 400 from Firebase Auth)
- **Real-user impact:** physical-keyboard `KeyboardEvent.location` values are always well-defined (0=standard, 1=left, 2=right, 3=numpad). The bug requires a `location` value the lookup table has no entry for. Synthetic events from DevTools / extensions / autofill / IME can dispatch with unusual location values. Real users typing on a real keyboard are unlikely to hit this — but accessibility tooling, virtual keyboards, or assistive tech might.

---

## 3. Reproduction recipe

```
1. Open https://bookbed-owner-dev.web.app/ in Chrome (DevTools open).
2. (Recommended) Clear service worker + cache + IDB to force fresh bundle:
   - DevTools → Application → Service Workers → Unregister
   - DevTools → Application → Clear storage → Clear site data
   - Reload.
3. Hook error capture in console:
   window.__err=[]; window.onerror=(m,s,l,c,e)=>{window.__err.push({m,s,l,c,stack:e?.stack}); return false;};
4. Wait for login screen to render.
5. With email/password fields focused, dispatch `type_text` via chrome-devtools MCP
   OR paste arbitrary characters via Chrome's Input.dispatchKeyEvent.
6. Observe `window.__err` populated with TypeError + main.dart.js:63315:3 source.
```

In this investigation, step 5 used `chrome-devtools MCP type_text "bookbed-test@bookbed.io"`. Crash fired during the first/early character dispatch — characters did NOT land in either Email or Lozinka field (CanvasKit input bridge crashed before forwarding to TextEditingController), so the fields remained at placeholder state. The crash is therefore observable from outside the Flutter app via window.onerror but **does not visibly affect form rendering** — only blocks the input it was processing.

---

## 4. Stack trace (verbatim)

```
Uncaught TypeError: Cannot read properties of null (reading 'toString')
    at bax.$0 (https://bookbed-owner-dev.web.app/main.dart.js:63315:3)
    at cgQ.$0 (https://bookbed-owner-dev.web.app/main.dart.js:63173:27)
    at baA.$2 (https://bookbed-owner-dev.web.app/main.dart.js:63335:12)
    at nv.bi (https://bookbed-owner-dev.web.app/main.dart.js:71200:18)
    at bav.buK (https://bookbed-owner-dev.web.app/main.dart.js:63269:9)
    at bav.mh (https://bookbed-owner-dev.web.app/main.dart.js:63281:7)
    at bas.$1 (https://bookbed-owner-dev.web.app/main.dart.js:63203:15)
    at bat.$1 (https://bookbed-owner-dev.web.app/main.dart.js:63209:42)
    at d2E (https://bookbed-owner-dev.web.app/main.dart.js:8611:29)
    at https://bookbed-owner-dev.web.app/main.dart.js:8602:43
```

No sourcemap was found on hosting (`GET main.dart.js.map → 200 + 29168 bytes of SPA index.html fallback`). Symbol attribution below is reasoned from the surrounding dart2js output.

---

## 5. Source line analysis

main.dart.js lines 63310-63325 (read directly from the deployed bundle):

```js
63310: if(B.a_z.ai(0,r.key)){l=r.key
63311:   l.toString
63312:   l=B.a_z.h(0,l)                          // lookupTable[event.key]
63313:   q=l==null?null:l[J.bE(r.location)]      // ← row[event.location], can be undefined→null
63314:   q.toString                              // ← Dart's `!` operator: crashes if q==null
63315:   return q
```

This is a verbatim transcription of dart2js output for:

```dart
// Sketch (Dart-side, paraphrased from dart2js patterns):
if (kLookup.containsKey(event.key)) {
  final keyName = event.key!;                   // 63311 — guarded by containsKey above
  final row = kLookup[keyName];                  // 63312
  final result = row?[event.location];           // 63313
  return result!;                                 // 63314 — crashes here on null
}
```

`B.a_z` is a constant `Map<String, List<LogicalKeyboardKey?>>` (the keyboard-event → logical-key lookup table). For some `(event.key, event.location)` tuples the entry exists at row level but the location index returns `null` (or out-of-bounds → `undefined`). The Dart `!` (force unwrap) on the result becomes `obj.toString` in dart2js — the implicit toString call that documents the null-check intent. With `obj==null`, JS throws the observed TypeError.

**Caller stack (reasoned attribution):**
- `bat.$1` (63209) — `keydown` event listener registered via `v.G.window.addEventListener("keydown", s, !0)` (63176)
- `bas.$1` (63203) — `keyup` event listener (63177)
- `bav.mh` (63281) — event handler entry (`KeyboardConverter`-like)
- `bav.buK` (63269) — keyData processor
- `nv.bi` (71200) — HashMap.forEach (Dart-collection iteration; consumed by `b.$2(r.a, r.b)` against each map entry)
- `baA.$2` (63335) — per-entry handler `$2(a, b)`
- `cgQ.$0` (63173) — lazy memoized initializer (`return r==null ? s.a=this.b.$0() : r`)
- `bax.$0` (63315) — the leaf that runs `lookup[key][location]!`

The `nv.bi` frame at line 71200 is a HashMap.forEach against the converter's pressed-key map (`s.r` modification-counter check at 71200 line `if(q!==s.r)throw A.j(A.e5(s))` matches Dart's `ConcurrentModificationError` check). Iteration over the pressed-key map dispatches each entry into the bug site.

These class/method shapes match the public Flutter Engine code at:
- `flutter/lib/web_ui/lib/src/engine/keyboard_binding.dart` — KeyboardBinding + KeyboardConverter
- `flutter/lib/web_ui/lib/src/engine/key_map.g.dart` — generated `kWebToLogicalKey` lookup

The exact upstream source line will move depending on Flutter Engine version, but the pattern is `kWebToLogicalKey[event.key]?[event.location]!`.

---

## 6. Why CHANGELOG 6.68 hardening pattern does not apply

- 6.68 fix: `Uri(queryParameters: { 'ref': nullableString ?? '' })` — coerce nullable map values before passing into `Uri.queryParameters`. Scope: widget `booking_view_screen.dart` lines 195-200, 240-245. Both call sites verified clean today via re-read.
- N4 fix surface: Flutter Engine internal. No BookBed-side `Uri(...)` involvement. `grep -rn "queryParameters" lib/features/auth/` → 0 results.
- Memory `flutter-web-uri-null-tostring.md` already explicitly distinguishes the two bug classes. Do not conflate.

---

## 7. What was NOT done, and why

- **No BookBed code change.** The trace is 100% framework. Trying to patch the framework via local code is the wrong layer.
- **No PR.** No code mutation to land.
- **No Flutter SDK upgrade attempted.** Out of scope for a single-bug investigation; carries unrelated regression risk.
- **No `flutter_keyboard_visibility` / `physical_keyboard_filter` shim attempted.** Defensive shims that swallow synthetic key events at the JS layer (e.g., wrapping `addEventListener('keydown')` to validate location before forwarding) could mask other framework signals and create a maintenance burden. Don't fight the framework from inside the page.

---

## 8. Mitigation options (ranked, not recommended actions)

1. **Accept as known framework bug; document the user-impact note.** Real keyboard users rarely hit this; synthetic-input automation hits it routinely. The console error is uncaught but does not visibly break the login UI (other than potentially eating the single keystroke that triggered it).
2. **Watch Flutter Engine releases for upstream fix.** File an upstream issue with this reproduction if not already reported. Search `github.com/flutter/flutter` for `keyboard converter null toString event.location` before filing.
3. **Upgrade Flutter SDK when convenient.** A future Flutter version may already have the fix.
4. **(Last resort) Wrap `window.addEventListener('keydown'/'keyup')` in `web/index.html`** to drop synthetic events with malformed `event.location`. High maintenance cost; risk of swallowing legitimate input; only consider if the bug visibly affects real-user flows (which audit data does NOT yet support).

---

## 9. Bonus finding (separate from N4) — Service Worker stale-bundle long-tail

While verifying audit/33 N1 (PROD-contamination) closure, observed:

- First visit to `https://bookbed-owner-dev.web.app/` after `audit/33` deploy fix → `firebase_core.getApps()[0].options.projectId` returned `"rab-booking-248fc"` (PROD). Stale service worker was still serving the pre-fix bundle.
- After explicit `navigator.serviceWorker.getRegistrations().then(rs=>rs.forEach(r=>r.unregister()))` + `caches.keys().then(ns=>ns.forEach(n=>caches.delete(n)))` + `indexedDB.databases().then(dbs=>dbs.forEach(d=>indexedDB.deleteDatabase(d.name)))` + reload → projectId flipped to `"bookbed-dev"`. Audit/33 N1 fix verified working on a fresh bundle load.
- **Implication for audit/33 §6.1:** the fix IS deployed correctly, but any user/test session that visited `bookbed-owner-dev.web.app` BEFORE the deploy will continue to write to PROD until their SW updates. Flutter's `flutter_service_worker.js` cache-busts via `?v=<digest>` query, so a second-load cycle should pick up the new bundle — but in practice the SW activation lifecycle requires the user to close all tabs of the origin OR the SW to detect the update.

**Recommended doc-only follow-up (not in this PR):** add a short SW-cache note to `audit/33-owner-dashboard-web-smoke-2026-05-24.md` §6.1 — "after re-deploy, instruct any past visitor to hard-refresh / clear SW once". Possibly also `.claude/rules/hosting-build.md` should note this pattern for future per-env redeploys after env-mistake fixes.

---

## 10. Cross-refs

- `audit/33-owner-dashboard-web-smoke-2026-05-24.md` §4.4 N4 (this investigation supersedes the "out of scope; flag for backlog" close-out)
- `memory/flutter-web-uri-null-tostring.md` — explicit "do not conflate" warning, now substantiated
- `docs/CHANGELOG.md` v6.68 — Uri.queryParameters hardening (different bug class)
- `memory/dev-hosting-prod-bundling-class.md` — adjacent context for §9 SW-cache finding
- Flutter Engine `flutter/lib/web_ui/lib/src/engine/keyboard_binding.dart` + `key_map.g.dart` — framework source (not vendored locally; reference only)

---

## 11. Verification artifacts

- Stack trace: §4 above.
- Source line read: §5 above (lines 63310-63325 of `main.dart.js` on deployed dev bundle, fetched 2026-05-24).
- Bundle ETag: `8e6ec914c4b007b15dcabd08a538aa0f197663249466cd6ec7a7b86a90f0f472-br` (flutter_bootstrap.js); Last-Modified `Thu, 29 Jan 2026 12:11:06 GMT`.
- projectId verified `bookbed-dev` after SW clear: §9.
- No screenshots — N4 has no visible UI symptom.
