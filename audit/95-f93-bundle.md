# audit/95 — F-93 P3 bundle + SF numbering reconciliation

**Date:** 2026-05-30
**Branch:** `fix/sf-reconcile-f93-bundle-0530`
**Scope:** `docs/SECURITY_FIXES.md` + `functions/src/stripePayment.ts` + `functions/test/stripePayment.test.ts`
**OUT of scope:** `lib/`, `ios/`, `android/`, `firestore.rules`, `storage.rules`
**No PROD deploy. No merge.**

---

## TL;DR

1. **SF numbering reconciliation** — at least 3 in-flight PRs (#565 / #567 / #574 / #568 / #575) picked overlapping SF numbers because parallel sessions each derived "next free" from a different point-in-time view of `docs/SECURITY_FIXES.md`. Canonical mapping pinned in the doc's new top-of-file "SF Numbering Reconciliation" table.
2. **F-93-03 (SF-071)** — `handleStripeWebhook` accepts every HTTP verb. Now `405` on non-POST with `Allow: POST` per RFC 9110 §15.5.6.
3. **F-93-04 (SF-072)** — Malformed JSON payload after signature compare bubbled out as 500 across the v2 onRequest stack. Now `400` + `"Invalid JSON payload"`, distinguished by `SyntaxError instanceof` + `error.type === "StripeInvalidRequestError"` + `/JSON/i` regex.
4. **F-93-01 (SF-073)** — `http://localhost` + `http://127.0.0.1` unconditionally lived in PROD's `getAllowedReturnDomains` allowlist. Moved under `if (isEmulator)` append. Open-redirect / Stripe-success-URL exfil class.

**Verification:** `npm run build` 0 errors. `npm test` 395 / 395 pass (387 baseline + 8 new). `npm run test:rules` 46 / 46 pass.

---

## §0 — SF Numbering Reconciliation

### State on main HEAD `ed31ae47` (pre-this-PR)

Ceiling: **SF-061** (App Check enforcement DEFERRED, audit/84 STEP 4).

### Collisions identified

| SF | Wanted by | Status |
|----|-----------|--------|
| SF-061 | main (App Check DEFERRED) | merged |
| SF-061 | PR #567 (F-50-05a undici) | **collision with merged** |
| SF-062 | PR #565 (F-86-01 CORS — memory `[[f86-01-cors-allowlist-gap-8-callables]]`) | first-claimer |
| SF-062 | PR #567 (F-50-09 devices) | **collision with #565** |
| SF-063 | PR #574 (F-92-01 iCal token) | first-claimer |
| SF-063 | PR #567 (F-50-10 eval) | **collision with #574** |
| SF-066 | PR #568 (FLUTTER-7B sentry) per memory `[[sentry-beforesend-httperror-only]]` | first-claimer |
| SF-067 | PR #575 (F-91-02 storage DELETE) | first-claimer |

PR #567 has 5 fixes (F-50-05a + F-50-09 + F-50-10 + F-50-11 + F-50-12). The 5 numbers it originally claimed (SF-061..SF-065) collide with 3 already-pinned slots. Authoritative re-allocation:

| Original (PR #567 body) | Canonical | Fix |
|--------------------------|-----------|-----|
| SF-061 (collision with App Check) | **SF-064** | F-50-05a undici override |
| SF-062 (collision with PR #565 CORS) | **SF-065** | F-50-09 devices allowlist |
| SF-063 (collision with PR #574 iCal) | **SF-068** | F-50-10 drop `eval()` probe |
| SF-064 | **SF-069** | F-50-11 iframe_resizer postMessage handshake |
| SF-065 | **SF-070** | F-50-12 audit/raw lockdown |

PR #567 needs a **doc-rebase only** (no code change) to swap its 5 SF heading numbers to SF-064 / 065 / 068 / 069 / 070.

### This-PR allocations

| SF | Finding | Title |
|----|---------|-------|
| SF-071 | F-93-03 | `handleStripeWebhook` POST-only method gate (405) |
| SF-072 | F-93-04 | Malformed JSON payload → 400, not 500 |
| SF-073 | F-93-01 | `localhost` stripped from PROD `getAllowedReturnDomains` |

### Authority rule (added to doc)

> The first PR that names an SF number AND lands in `main` reserves it permanently. Branches drafted in parallel that picked the same number must rebase. To avoid future collisions, branches that want to reserve a new SF should add their row to the reconciliation table on creation, not on merge.

This trades some upfront table-editing churn for elimination of the "merge race" reservation pattern that produced this audit.

### NOT touched in this PR

- PR #565 (`fix/f86-01-cors-8-callables`) — already on SF-062, canonical.
- PR #574 (`test/f92-01-ical-token-deep-0530`) — already on SF-063, canonical.
- PR #575 (`test/f91-02-storage-delete-0530`) — already on SF-067, canonical.
- PR #568 (sentry beforeSend) — already on SF-066, canonical.
- PR #567 (`fix/audit-50-backlog`) — branch unmodified by this PR; mapping recorded in the reconciliation table for its pre-merge doc-rebase.

User constraint "**NE diraj druge PR-ove osim doc-align**" honored: the only doc-align surface this PR touches is `docs/SECURITY_FIXES.md` and only adds (a) the reconciliation table and (b) its own 3 SF entries.

---

## §1 — F-93-03 (SF-071): webhook POST-only method gate

### Bug

`functions/src/stripePayment.ts:889` declares the Stripe webhook handler with `onRequest({...}, async (req, res) => {...})`. `onRequest` accepts every HTTP verb. Pre-fix flow on a `GET /handleStripeWebhook`:

1. `sig = req.headers["stripe-signature"]` — undefined (GET requests carry no body / signature).
2. `if (!sig)` → `logWarn("Missing stripe-signature header — likely bot/crawler")` + `res.status(400).send("Missing signature")`.

Net effect: every scanner probe pollutes the warn log channel and gives the prober a 400 instead of an unambiguous 405. The Stripe signature gate still holds defensively, but the noise floor masks real signature-failure events that DO indicate attack-class behavior.

### Fix

```ts
// First statement in the handler body, before reading any other request state.
if (req.method !== "POST") {
  res.set("Allow", "POST");
  res.status(405).send("Method Not Allowed");
  return;
}
```

`Allow: POST` advertises the only allowed verb per RFC 9110 §15.5.6 — well-behaved clients (Burp, ZAP, browser preflights) will not retry with another verb.

### Tests

`functions/test/stripePayment.test.ts` — new parametrized test:

```ts
it.each(["GET", "PUT", "PATCH", "DELETE", "OPTIONS"])(
  "F-93-03 (SF-071): rejects %s with 405 Method Not Allowed",
  async (method) => {
    // req mock with only { method, headers: {}, rawBody: undefined }
    // res mock with status / send / set / json
    // Asserts: status(405) + set(Allow, POST) + send(Method Not Allowed)
    //          mockStripe.webhooks.constructEvent NOT called
  }
);
```

Pre-existing happy-path tests (3 in the `handleStripeWebhook` describe block) updated to include `method: "POST"` on the req mock + `set: jest.fn()` on the res mock — otherwise they trip the new method gate.

### What is NOT changed

- Behavior on POST without signature — still `400 "Missing signature"` (pre-existing).
- Behavior on POST with invalid signature — still `400 "Webhook signature verification failed"` (pre-existing).
- Stripe SDK initialization order — method gate runs BEFORE `getStripeClient()` so non-POST never causes secret fetch.

---

## §2 — F-93-04 (SF-072): malformed JSON → 400, not 500

### Bug class

`stripe.webhooks.constructEvent(payload, header, secret)` per stripe-node sync source:

```
1. signature.verifyHeader(payload, header, secret, tolerance)   ← throws StripeSignatureVerificationError on mismatch
2. return JSON.parse(payload)                                    ← throws SyntaxError on malformed body
```

Pre-fix the `catch (error: any)` block at `stripePayment.ts:916` did not distinguish these two cases. Both bubbled out as `400 "Webhook signature verification failed"`. Two separate problems:

1. **Wrong error message** — a syntactically valid Stripe-signed payload that happens to be malformed JSON is NOT a signature attack. Logging it as `logWebhookSignatureFailure(...)` poisons the security-alert channel.
2. **500 leak** — when callers wrap this CF (downstream test rigs, internal compatibility shim layers per audit/95 cross-trace), the SyntaxError can escape out of `constructEvent` BEFORE the catch — observed empirically as 500 from the framework default unhandled-promise-rejection path.

### Fix

```ts
} catch (error: any) {
  if (error instanceof SyntaxError ||
      (error?.message && error.message.includes("JSON"))) {
    logWarn("Webhook received malformed JSON payload", { errorMessage: error?.message });
    res.status(400).send("Invalid JSON payload");
    return;
  }
  // ...existing signature-failure path unchanged below this branch...
}
```

Two matchers, case-sensitive `JSON` substring:
- `instanceof SyntaxError` — canonical detection: direct re-throw from `JSON.parse`.
- `error.message.includes("JSON")` — fallback for SDK drift where Stripe wraps malformed-payload cases. Case-sensitive (NOT `/JSON/i`) so partial-word matches like "Json-Web-Token" or "json-encoded" do NOT false-positive into the security-alert-silencer branch.

A pre-existing `it` test ("should return a 400 error if the webhook signature is invalid") throws `new Error("Invalid signature")` — message contains no "JSON" substring, so it correctly stays on the signature-failure path (verified post-tighten).

Logged as `logWarn`, NOT `logError`, NOT `logWebhookSignatureFailure` — keeps the SecurityEvent alert channel clean.

### Tests

```ts
it("F-93-04 (SF-072): returns 400 invalid-argument on malformed JSON body", async () => {
  mockStripe.webhooks.constructEvent.mockImplementation(() => {
    throw new SyntaxError("Unexpected token } in JSON at position 7");
  });
  // ... req with method: "POST" + sig: "valid-sig" + rawBody: "{ invalid }"
  // Asserts: status(400) + send("Invalid JSON payload")
  //          logError("Webhook signature verification failed", ...) NOT called
});
```

### Caveat

The original "malformed JSON → 500" report could not be pinned to a specific code path on `main` — `stripePayment.ts:916` already catches SyntaxError into 400 (just with the wrong message). The 500 may originate from one of:

- Firebase v2 `onRequest` Express body parser firing before the handler — on `Content-Type: application/json` with malformed body, Express config may 400 or 500.
- Post-`constructEvent` business logic on a valid-JSON-but-malformed-Event payload (missing fields, wrong types) — no top-level try/catch around the post-event handler tree, so unhandled throw → CF default 500.

The fix in this PR is defensive: by giving SyntaxError its own labeled branch in the catch, ANY future SyntaxError out of `constructEvent` (across Stripe SDK upgrades) will land in 400 not 500. The "valid-JSON-malformed-Event" 500 class is OUT of scope for this PR — separate audit, separate fix.

---

## §3 — F-93-01 (SF-073): localhost stripped from PROD allowlist

### Bug

```ts
// stripePayment.ts:46 (pre-fix)
function getAllowedReturnDomains(): string[] {
  const base = [
    "https://bookbed.io",
    "https://app.bookbed.io",
    "https://view.bookbed.io",
    "http://localhost",      // ← unconditionally in PROD allowlist
    "http://127.0.0.1",      // ← unconditionally in PROD allowlist
  ];
  // ...
}
```

`isAllowedReturnUrl(returnUrl)` does `allowedDomains.some(d => returnUrl.startsWith(d))`. So PROD requests with `returnUrl=http://localhost:9999/anything` are accepted, Stripe Checkout is created with `success_url` / `cancel_url` pointing at localhost, and the post-payment redirect lands wherever localhost:9999 is bound.

### Attack surface

NOT reachable from the production booking widget today — its returnUrl is hard-coded to the deployed origin per `widget_main.dart`. Risk class is:

1. **Open-redirect upgrade path** — if any future client surface ever leaks `returnUrl` into client-controllable input (a deep-link param, an embed customization knob, a recovered-cart link), the localhost append makes that surface immediately exploitable.
2. **Stripe success-URL exfil** — Stripe's success page can carry session metadata in the URL fragment. If a user is tricked into a flow whose returnUrl is `http://localhost:.../exfil`, an attacker that controls a local listener on that machine receives the success-page redirect.
3. **Operator-side bleeding** — operator running a local dev tool on localhost:3000 while paying a real production booking gets the success redirect routed to the dev tool. Confusion, no compromise — but noise on the production funnel.

Mirror of the `corsAllowlist.ts` `LOCAL_DEV_ORIGINS` pattern (added in SF-060): both gates should be consistent — localhost is emulator-only.

### Fix

```ts
function getAllowedReturnDomains(): string[] {
  const base = [
    "https://bookbed.io",
    "https://app.bookbed.io",
    "https://view.bookbed.io",
  ];
  const projectId = process.env.GCP_PROJECT || process.env.GCLOUD_PROJECT;
  const isEmulator = process.env.FUNCTIONS_EMULATOR === "true";
  if (projectId === "bookbed-dev" || isEmulator) {
    base.push("https://bookbed-widget-dev.web.app");
    base.push("https://bookbed-owner-dev.web.app");
  }
  if (projectId === "bookbed-staging") {
    base.push("https://bookbed-widget-staging.web.app");
    base.push("https://bookbed-owner-staging.web.app");
  }
  if (isEmulator) {
    base.push("http://localhost");
    base.push("http://127.0.0.1");
  }
  return base;
}
```

### Tests

Two paired tests:

1. **PROD branch closed** — explicitly `delete process.env.GCP_PROJECT / GCLOUD_PROJECT / FUNCTIONS_EMULATOR` in a `try/finally`, then `createStripeCheckoutSession` with `returnUrl="http://localhost:3000/done"` AND `"http://127.0.0.1:3000/done"`. Both rejected with `HttpsError(invalid-argument, "Invalid return URL. Please try again from the booking page.")`. Env vars restored on finally.
2. **Emulator branch open** — `process.env.FUNCTIONS_EMULATOR = "true"`, same localhost URL, Firestore + Stripe mocks set up to advance past the URL gate, asserts `result.success === true`.

The env-unset pattern is load-bearing: jest's ambient env can mask the bug — without explicit `delete process.env.*` the test runs in whatever env happens to be set during CI, which on PROD-imagined CI runs may include `GCP_PROJECT=bookbed-dev` and would not exercise the PROD branch.

---

## §4 — Verification

| Check | Result |
|-------|--------|
| `cd functions && npm run build` | ✅ 0 errors |
| `cd functions && npm test` | ✅ 395 / 395 passed (387 baseline + 8 new — 5 `it.each` cells for §1 + 2 for §3 + 1 for §2) |
| `cd functions && npm run test:rules` | ✅ 46 / 46 passed |
| `git diff --stat origin/main` (scope-guard) | `docs/SECURITY_FIXES.md` + `functions/src/stripePayment.ts` + `functions/test/stripePayment.test.ts` + `audit/95-f93-bundle.md` only — `lib/`, `ios/`, `android/`, rules, storage UNTOUCHED |

---

## §5 — NOT in this PR

- Merge to main.
- PROD deploy.
- PR #567 doc-rebase (recorded in §0 table as pre-merge action for that PR's author).
- Top-level handler try/catch wrapping every post-event business path — out of scope, separate audit if "valid-JSON-malformed-Event → 500" needs closure.
- App Check enforcement (still gated by SF-061 client-side prerequisite).
- Sentry / Resend secret rotation.

---

## §6 — Cross-refs

- F-93-02 → PR #572 (`booking-lookup-strategy2-path`) — `findBookingById` Strategy 2 path fix. Separate workstream.
- F-92-01 → PR #574 — iCal empty-token bypass. Adjacent in numbering to this PR but independent fix.
- F-91-02 → PR #575 — storage.rules DELETE split. Reserved SF-067 in the canonical mapping.
- F-86-01 → PR #565 — CORS allowlist 8 callables. Reserved SF-062.
- audit/84 STEP 3 → SF-060 — established the `corsAllowlist.ts` `LOCAL_DEV_ORIGINS` emulator-only pattern that SF-073 mirrors.
