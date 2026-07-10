# Widget PROD deploy prep — #768 l10n bundle rebuilt (2026-06-20)

**Why:** #768 (`6854f11f` — *localize 3 guest-facing English strings in FROZEN
booking widget to WidgetTranslations, 4-lang*) is merged to `main`, but
`view.bookbed.io` still serves the old **English-only** bundle: the deploy is
held because CI (`.github/workflows/deploy-widget.yml`) is billing-blocked. This
rebuilds the PROD widget bundle from current `main` so the manual deploy is one
command. **No code was changed** — this is a build-artifact prep.

**Built from:** `main` @ `feae40fe` (origin/main tip; #768 `6854f11f` is an
ancestor). Toolchain: **Flutter 3.38.5 / Dart 3.10.4** (matches CI pin).
**Bundle location:** `build/web_widget` in the main tree
(`/Users/duskolicanin/git/bookbed/build/web_widget`) — the exact path
`firebase.json → hosting:widget.public` reads from, and durable (not `/tmp`).

## Build (byte-for-byte the `deploy-widget.yml` recipe)

```bash
# SENTRY_DSN sourced from .env.production in a subshell (never echoed) — the
# scripts/deploy_prod.sh pattern; fail-closed if empty (was present, len 95).
flutter build web --release --no-tree-shake-icons \
  --target lib/widget_main.dart \
  --dart-define=SENTRY_DSN="$SENTRY_DSN" \
  -o build/web_widget --source-maps --base-href /
cp public/embed.js          build/web_widget/   # iframe embed loader
cp web/bookbed-overlay.js    build/web_widget/   # iframe-scroll overlay (widget.md)
```

Build OK, exit 0, 116.4s, `✓ Built build/web_widget`. embed.js + overlay.js
copied and verified present post-build. (The "Wasm dry run findings" line is a
benign advisory — this is a standard dart2js/CanvasKit build, not Wasm.)

## Verification

| Check | Result |
|---|---|
| **Staleness — the deploy concern** | All 4 langs of the #768 strings live in `main.dart.js`: `Nedostaje ID` ×2 (HR property+owner), `Die Unterkunft-ID fehlt` (DE), `Preis aktualisiert` (DE), `Prezzo aggiornato` (IT). → this is the **fixed** bundle, not stale English. |
| **Bundle structure** | `index.html`, `main.dart.js` (4.1M), `flutter_service_worker.js`, **`embed.js`**, **`bookbed-overlay.js`**, `payment_bridge.js`, `iframe_resizer.js`, assets/canvaskit/icons. 75M total (`.map` not deployed — firebase ignores `**/*.map`). |
| **Secret safety** | `grep -c sk_live main.dart.js` = **0** (only `SENTRY_DSN` dart-defined; `STRIPE_*` never passed). |
| **`flutter analyze`** | 97 issues, **all `info`** (pre-existing: deprecated `medium` radius + test-redundancy lints). **0 net-new** (zero Dart files changed). |
| **`flutter test`** | **`+1583: All tests passed!`** — full suite green (meaningful: CI billing-blocked, merges were local-verified). |
| **App Check clean (code fact)** | `widget_main.dart` references `AppCheckInit.activate` only in **comments** (lines 139/151) — not invoked → no reCAPTCHA request → no eternal-shimmer regression. |
| **Live boot smoke** | Local `127.0.0.1:8099`, headless Chrome. Server log = clean boot: index.html → flutter_bootstrap.js → main.dart.js → SW → AssetManifest, and **every icon font** 200 (MaterialIcons, MaterialSymbols Outlined/Rounded/Sharp, TablerIcons, Cupertino) → icons render, no tofu (`--no-tree-shake-icons` working). Screenshot = BookBed splash at **100%** (logo image + text render, correct font, no error screen). **App Check runtime-clean:** netlog has **0 `recaptcha`** requests. |
| **Smoke caveat** | Post-splash CanvasKit first frame did **not** paint under headless SwiftShader (known env limitation — not a bundle defect; this is live-shipping PROD code). So the full-UI visual + live HR/DE/IT language-switch + dark-mode glance are best done in a real browser → `http://127.0.0.1:8099/`. #768 is l10n-only (no theme impact); #127 dark palette already shipped+verified (audit/127). |
| **CF gates** | **N/A** — zero `functions/` or `firestore.rules` changes (widget l10n is pure client Dart). CF/rules byte-identical to merged-green `feae40fe`. |

## DEPLOY (operator only — needs PROD creds)

The bundle is ready. From the repo root:

```bash
firebase use production && firebase deploy --only hosting:widget
```

Post-deploy: hard-refresh `view.bookbed.io` (`flutter_service_worker.js`
cache-busts via `?v=`), then confirm the booking-widget **price-update dialog**
and **ID-missing toasts** render in HR/DE/IT (not English).
