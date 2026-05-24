# audit/35 — Auth Flows Smoke (Tier 4) 2026-05-24

**Branch**: `doc/audit-35-auth-smoke` (worktree-only, no push)
**Target**: `https://bookbed-owner-dev.web.app` — **PROD-bundled** (audit/33 §2, memory `test-account-prod.md`)
**Project**: `rab-booking-248fc` (PROD)
**Method**: chrome-devtools MCP + Firebase JS SDK introspection
**Test artifacts**: Tagged for cleanup — see §6 "test artifact created by Duško smoke — safe to delete"

---

## §1 — Throwaway Inbox Approach

Per user direction (pre-flight Q1): **Mailinator for flow + Gmail alias only for C2**.

| Account | Email | Purpose |
|---|---|---|
| C1 / C4 / C5 | `bbsmoke-c1-1779610255@mailinator.com` | Mailinator public inbox; reused for resend cooldown + password reset |
| C2 / C3 | `zgembokrkan+bbsmokec2-1779610255@gmail.com` | Gmail plus-alias of existing PROD test owner; delivers to `zgembokrkan@gmail.com` inbox |

**Why split:** Mailinator public inbox readable via `https://www.mailinator.com/v4/public/inboxes.jsp?to=<user>` without auth — fast iteration. Gmail required only to satisfy audit/28 §5.3 Authentication-Results capture (deferred — see §5).

**Rationale for PROD target despite mutations:** User answered "Proceed on PROD with safety + tagging" to pre-flight Q2 after audit/33 PROD-bundling regression surfaced. Mutations restricted to user creation + password reset; no Stripe Connect / subscription / booking touches.

---

## §2 — Checkpoint Results Summary

| CP | Result | Notes |
|---|---|---|
| C1 Register Mailinator | ✓ | UID `jXt4S6TvYxUPUaYitJBYmSj3mnr2`; verify email sent via Firebase native |
| C2 Register Gmail | ✓ partial | UID `uRutRjNEtrexEz4vtdSM1DmHB6q2`; Auth-Results capture **DEFERRED** (user clicked verify link before pasting headers) |
| C3 Verify link click | ✓ | `emailVerified=true` confirmed via `user.reload()`; auto-redirect to `/#/owner/overview` |
| C4 Resend cooldown | ✓ | Cooldown **60s** (not 30s per CHANGELOG 6.44 — discrepancy) |
| C5 Password reset | ✓ | Old pwd rejected (`auth/invalid-credential`); new pwd login OK; `emailVerified` auto-flipped to `true` |
| C6 Cleanup | ✓ | UIDs documented (§6); no admin-SDK deletion per user direction |

---

## §3 — Per-Checkpoint Detail

### §3.1 — C1 Register (Mailinator)

**Form input**:
- Name: `BB Smoke C1` → stored as **`BB Smoke C`** (lost the `1`) — see §4 Finding F-Auth-D1
- Email: `bbsmoke-c1-1779610255@mailinator.com`
- Password: `BookBedSmoke2026!` (later changed in C5)
- ToS + Privacy: checked; marketing: unchecked

**Network trace** (post-submit):

1. `POST europe-west1-rab-booking-248fc.cloudfunctions.net/checkRegistrationRateLimit` — 200
   - Request body: `{"data":{"email":"bbsmoke-c1-1779610255@mailinator.com"}}`
   - Response: `{"result":{"allowed":true}}`
   - **Response headers**: NO `X-RateLimit-Limit / -Remaining / -Reset / Retry-After` — confirms audit/31 MED-2 (decision is opaque from response headers; client cannot see remaining quota).
2. `POST identitytoolkit.googleapis.com/v1/accounts:signUp` — 200
   - UID: `jXt4S6TvYxUPUaYitJBYmSj3mnr2`
   - `email_verified: false` in JWT
3. `POST identitytoolkit.googleapis.com/v1/accounts:update` — 200 (sets displayName)
4. `POST identitytoolkit.googleapis.com/v1/accounts:sendOobCode` — 200 (`requestType: VERIFY_EMAIL`)

**UI redirect**: `/#/register` → `/#/email-verification`. Resend button "Ponovno pošalji za 59s" (disabled).

**Console**: no errors during flow.

---

### §3.2 — C2 Register (Gmail plus-alias)

**Form input**:
- Name: `BB Smoke C2 Gmail` → stored as **`BB Smoke C Gmail`** (lost the `2`) — same bug as C1
- Email: `zgembokrkan+bbsmokec2-1779610255@gmail.com`
- Password: `BookBedSmoke2026!`

**Network**:
1. `checkRegistrationRateLimit` — `{allowed:true}`, again NO rate-limit headers
2. `accounts:signUp` — 200, UID `uRutRjNEtrexEz4vtdSM1DmHB6q2`, timestamp `2026-05-24T08:20:56Z`
3. `accounts:sendOobCode` — 200 at `08:20:59Z`

**Auth-Results header capture for audit/28 §5.3**: **DEFERRED**. User confirmed verification clicked through (response "verifikovano"), but the raw `Authentication-Results:` block from Gmail "Show original" was not pasted before the link was clicked. Re-run option available — see §5 follow-up.

---

### §3.3 — C3 Verify Link Click (Gmail)

Verification handled in user's own browser (Gmail web UI), not in the MCP-controlled Chrome session.

**Server-side propagation confirmed in MCP session** without any extra interaction: the email-verification screen auto-redirected to `/#/owner/overview` (auth state listener picked up `emailVerified=true` flip on next idToken refresh / `onAuthStateChanged`).

**SDK introspection** post-redirect:
```json
{
  "uid": "uRutRjNEtrexEz4vtdSM1DmHB6q2",
  "email": "zgembokrkan+bbsmokec2-1779610255@gmail.com",
  "emailVerified": true,
  "displayName": "BB Smoke C Gmail",
  "providerData": [{"pid":"password","email":"zgembokrkan+bbsmokec2-1779610255@gmail.com"}],
  "creationTime": "Sun, 24 May 2026 08:20:56 GMT",
  "lastSignInTime": "Sun, 24 May 2026 08:20:56 GMT"
}
```

**Console errors**: none during redirect.

**Dashboard render**: "Pregled" heading + "Dobrodošli, BB!" greeting (first-letter avatar). Placeholder dashboard metrics shown (€12500 / 45 bookings / 85.5%) — those are demo values for empty new account, not real data.

---

### §3.4 — C4 Resend Cooldown

Tested on the C1 account (still on email-verification screen post-C1):

| Action | Time (UTC) | Result |
|---|---|---|
| Initial `sendOobCode` | 08:16:10 | reqid=100, 200 OK |
| Click "Ponovno pošalji za 2s" (disabled) | ~08:17:20 | No network call fired (button blocked, no-op) |
| Cooldown elapsed → button text "Ponovno pošalji" | 08:17:22 | enabled |
| Click resend | 08:17:23 | reqid=155, `sendOobCode` 200 OK |
| Cooldown reset to "Ponovno pošalji za 55s" | 08:17:23 | UI re-armed |

**Interval between sends**: 73 seconds. Confirms client-side cooldown is enforced (no spam request even when underlying API would accept). Resend after cooldown succeeds with no error.

**⚠ Discrepancy**: CHANGELOG 6.44 documents cooldown as **30s**; actual UI counts down from **60s** (saw initial "59s" + post-resend "55s" with several seconds of capture latency between). Either CHANGELOG entry is stale or implementation was changed without doc update. **Action**: source check `_resendCooldownSeconds` constant in `email_verification_screen.dart` (or whatever the equivalent file is).

---

### §3.5 — C5 Password Reset

Substituted C1 Mailinator account in place of `bookbed-test@bookbed.io` because the test account lives on `bookbed-dev` (project `bookbed-dev`) and we are smoking PROD (`rab-booking-248fc`).

**Trigger**:
- "Zaboravili lozinku?" modal on `/#/login` (no separate route — inline UI)
- Email: `bbsmoke-c1-1779610255@mailinator.com`
- Click "Pošalji link za reset"

**Network**:
- `POST us-central1-rab-booking-248fc.cloudfunctions.net/sendPasswordResetEmail` — 200
- Response: `{"result":{"success":true,"message":"Password reset email sent successfully"}}`
- **Response headers**: again no `X-RateLimit-*`
- **Region**: `us-central1` (NOT `europe-west1` like `checkRegistrationRateLimit` — see audit/11 region-split note)
- **No `accounts:sendOobCode` call from client** — the CF generates the OOB code admin-side and sends via Resend; this differs from C1/C2 verify-email which goes via Firebase native + `noreply@rab-booking-248fc.firebaseapp.com`

**Email landed in Mailinator inbox**:
- From: `BookBed <bookings@bookbed.io>`
- Sending IP: `54.240.6.247` (`a6-247.smtp-out.eu-west-1.amazonses.com`)
- Confirms route: **Resend → AWS SES eu-west-1 → recipient**
- Two DKIM signatures present:
  - `s=resend; d=bookbed.io` (Resend signing customer domain via CNAME-published key)
  - `s=shh3fegwg5fppqsuzphvschd53n6ihuv; d=amazonses.com` (AWS SES signing its own domain)
- Action URL: `https://rab-booking-248fc.firebaseapp.com/__/auth/action?mode=resetPassword&oobCode=<REDACTED_OOB>&apiKey=<REDACTED_FIREBASE_WEB_KEY>&continueUrl=https%3A%2F%2Fapp.bookbed.io%2Fforgot-password&lang=en` (Firebase Web API key is public-by-design but redacted to keep this doc clean of secret-scan hits; OOB single-use + 60min TTL, already consumed)
- Validity: 60 minutes (per email body)

**Reset completion** (bypassed Firebase hosted action page; used SDK directly):
```js
await firebase_auth.verifyPasswordResetCode(auth, oobCode); // oobCode extracted from email; redacted
// → 'bbsmoke-c1-1779610255@mailinator.com'
await firebase_auth.confirmPasswordReset(auth, oobCode, 'BookBedReset2026!');
// → success
```

**Login verification**:
- Old password (`BookBedSmoke2026!`) → `auth/invalid-credential` ✓ (rejected as expected)
- New password (`BookBedReset2026!`) → signed in OK as UID `jXt4S6TvYxUPUaYitJBYmSj3mnr2`
- `emailVerified=true` — **auto-flipped by Firebase** on `confirmPasswordReset` (standard behavior: clicking the reset link proves email ownership, so the account is auto-verified). Not a bug — worth documenting because it means a password reset is a SECOND path to verification beyond the explicit verify-email link.

**`security_events` Firestore doc write**: NOT directly verifiable from client (`getDocs` on `security_events`, `users/{uid}/security_events`, and top-level filtered by `user_id` / `uid` all returned `permission-denied`). Writes occurred (multiple Firestore write channels seen in network panel post-reset), but rule-level read protection means client-side proof requires admin SDK. **Action**: admin-side spot-check via `gcloud firestore` or Firebase Console.

---

## §4 — Findings

### F-Auth-D1 — DisplayName digit stripping (NEW) — ✅ RESOLVED PR #470

**Severity**: MED (data integrity / UX)
**Reproduction**:
- Input `BB Smoke C1` → stored as `BB Smoke C` (1 stripped)
- Input `BB Smoke C2 Gmail` → stored as `BB Smoke C Gmail` (2 stripped)
- Verified via post-register Firebase Auth `currentUser.displayName` + Mailinator email body ("Hello BB Smoke C,")

**Pattern**: Digits in the trailing position of the name get dropped. Pattern looks like a regex-strip during validation or sanitization (likely `[a-zA-Z\s]+` filter on submit). Not a length truncation — middle digits (`Gmail` after the C2) would have been kept if it was simple `.substring(0, 16)`.

**Impact**: Owners with digits in their name (e.g. business names "Property2 Ltd", "M3 Holdings", surnames "O'Brien-3") will see corrupted display name in dashboard greeting + outgoing emails. No data loss in Firestore `users` doc — needs separate check whether `users/{uid}.full_name` also stripped or whether only the Auth displayName is.

**Source to investigate**: registration form validator/sanitizer in `lib/features/auth/presentation/screens/register_screen.dart` (or equivalent). Look for digit-rejecting regex on the name field's `onChange` / `validator`.

**Root cause (2026-05-24 follow-up):** Lives in `lib/shared/utils/validators/input_sanitizer.dart` `InputSanitizer.sanitizeName()` (called from `enhanced_register_screen.dart:135-137` between form-submit and provider call). Allow-list regex was `[^\p{L}\s'\-]` — `\p{L}` matches Unicode letters but NOT digits, so any digit was stripped repo-wide for both owner name and widget guest name (`submit_booking_use_case.dart:117`).

**Fix shipped:** PR #470 (`fix/audit-35-displayname-cooldown`, commit `bad97caa`) — regex extended to `[^\p{L}\p{N}\s'\-]`. `\p{N}` covers ASCII digits + Arabic-Indic + Devanagari etc. Defence-in-depth unchanged: `_htmlTagPattern` strips HTML, `_controlCharPattern` strips control chars, injection chars (`< > ; / \ " = ( ) { } & $`) still removed by allow-list, `containsDangerousContent()` still flags XSS/SQLi. Tests 52/52 green incl. 2 new regression cases (`preserves digits in name`, `preserves Unicode digits across scripts`) + 1 stale assertion updated (`'John<script>alert(1)</script>Doe'` now yields `'Johnalert1Doe'` not `'JohnalertDoe'`).

**Post-deploy verify:** register `Test User2` on `bookbed-owner-dev.web.app` → Firestore `users/{uid}.full_name` == `Test User2` + `firebase.auth().currentUser.displayName` == `Test User2` + Mailinator email body greets `Hello Test User2,`.

---

### F-Auth-D2 — Cooldown UI / CHANGELOG mismatch (NEW) — ✅ RESOLVED PR #470 (doc-only)

**Severity**: LOW (doc drift)
- CHANGELOG 6.44 documents resend cooldown as **30s**
- Actual UI counts down from **60s**

Either implementation drifted or docs are stale. Source check `_resendCooldownSeconds` or similar constant.

**Source verdict (2026-05-24 follow-up):** UI is canonical and always was 60 s. `email_verification_screen.dart` `_startInitialCooldown` (line 48) and `_startCooldown` (line 290) both `_resendCooldown = 60;`. Matches Firebase Auth `sendEmailVerification()` internal rate-limit window (~60 s) — picking 30 s would have produced consistent rate-limit errors. **Conclusion:** CHANGELOG entry 6.44 was wrong since 2026-02 ship date; behaviour unchanged.

**Fix shipped:** PR #470 — `docs/CHANGELOG.md` entry 6.44 corrected to "60-second" with explicit audit/35 footnote. No code change.

---

### F-Auth-D3 — Rate-limit headers absent on custom auth CFs (CONFIRMS audit/31 MED-2)

Both `checkRegistrationRateLimit` (eu-west1) and `sendPasswordResetEmail` (us-central1) return standard Firebase Google-Frontend headers only. No `X-RateLimit-*` or `Retry-After`. Clients cannot programmatically determine remaining quota or back-off interval — the only signal is the response `{allowed:false}` (which we did NOT trigger in this smoke — see follow-up).

**Carries over**: investigate `functions/src/auth/checkRegistrationRateLimit.ts` + `functions/src/auth/sendPasswordResetEmail.ts` (or equivalents) and consider attaching headers via `res.setHeader('X-RateLimit-Remaining', ...)`.

---

### F-Auth-D4 — Email routing split (DOCUMENT)

| Email type | Sender | Infra | DKIM domain |
|---|---|---|---|
| Verify email (initial + resend) | `noreply@rab-booking-248fc.firebaseapp.com` | Firebase native (Google) | `firebaseapp.com` (Google-signed) |
| Password reset | `bookings@bookbed.io` | Custom CF → Resend → AWS SES eu-west-1 | `bookbed.io` (Resend-signed) + `amazonses.com` |

**Implication**: SPF and DKIM alignment checks differ between the two flows. Audit/28 §3.3 SPF gap on `bookbed.io` (Resend not yet in SPF include) affects ONLY password reset / transactional templates — NOT the verify email path. That gap is contained.

---

### F-Auth-D5 — Lookup polling spam (OBSERVATION)

`identitytoolkit.googleapis.com/v1/accounts:lookup` called **50+ times** during a ~10-minute session, far in excess of what the user actions warrant. Likely Firebase Auth's internal idToken refresh + `onAuthStateChanged` listener combined with multiple Riverpod providers that watch auth state independently.

**Severity**: LOW (no functional bug; Google likely caches server-side). Worth profiling if quota becomes a concern at scale, or if multiple providers can share a single auth-state stream.

---

### F-Auth-D6 — Password reset → emailVerified auto-flip (CORRECT, document)

Firebase Auth flips `emailVerified=true` when `confirmPasswordReset` succeeds — clicking the reset link counts as ownership proof. The C1 Mailinator account ended the smoke `emailVerified=true` despite never having had its verify-email link clicked. This is standard Firebase behavior and the documented design, NOT a bug.

**Caveat**: any feature gated only on `emailVerified` (e.g. owner onboarding step skip) should NOT assume the user actually saw the verify email. Treat password reset as an alternate verification path.

---

## §5 — audit/28 §5.3 Fill-in (Authentication-Results)

**Status**: **DEFERRED for Gmail**. **CAPTURED for `bookings@bookbed.io` via Mailinator**.

### §5.1 — bookings@bookbed.io → Mailinator (CAPTURED)

Source: Mailinator RAW tab for the C5 password reset email.

```
From:       BookBed <bookings@bookbed.io>
Date:       Sun, 24 May 2026 08:26:49 +0000
Message-ID: <0102019e59180d27-ee5e4cd0-6168-4f15-8a2b-9fd020352428-000000@eu-west-1.amazonses.com>
Sending IP: 54.240.6.247  (a6-247.smtp-out.eu-west-1.amazonses.com)
X-SES-Outgoing: 2026.05.24-54.240.6.247
Feedback-ID: :1.eu-west-1.<id>:...:AmazonSES

DKIM-Signature: v=1; a=rsa-sha256; q=dns/txt; c=relaxed/simple;
                s=resend; d=bookbed.io; t=1779611209;
                h=From:To:Subject:Message-ID:Date:MIME-Version:Content-Type;
                bh=8v9c/vIyVX6eDI1wDgHxBsLAQ0kMYlPcMGadh7BKATg=;
                b=Cp0DH7s5jvFpjMC3BtQAwfuMCcyQBvIc1MXcjjLs0oCrcWeGvptQXOKoLGKwr1my[...]=

DKIM-Signature: v=1; a=rsa-sha256; q=dns/txt; c=relaxed/simple;
                s=shh3fegwg5fppqsuzphvschd53n6ihuv; d=amazonses.com; t=1779611209;
                h=From:To:Subject:Message-ID:Date:MIME-Version:Content-Type:Feedback-ID;
                bh=8v9c/vIyVX6eDI1wDgHxBsLAQ0kMYlPcMGadh7BKATg=;
                b=hXkGyGZz+9bGBs7Horxnn4HaLr9Ouet89fkvQgb/nq2tSkUZvkA6E[...]=
```

**Mailinator does NOT add an `Authentication-Results:` header** — it accepts mail unconditionally and only records what the sender placed in headers. SPF/DKIM/DMARC verdicts from Mailinator's mailserver are NOT exposed. To satisfy audit/28 §5.3, the verdict line must come from Gmail.

### §5.2 — Gmail Authentication-Results (DEFERRED)

User declined / clicked through verify link before pasting headers. **Re-run recipe** for next session:

1. Sign out
2. Register `zgembokrkan+bbauth<NEW_TS>@gmail.com` on `bookbed-owner-dev.web.app`
3. **STOP — do NOT click verify link yet**
4. Open `mail.google.com` → find email FROM `noreply@rab-booking-248fc.firebaseapp.com` (sender shows as "BookBed")
5. Open it → ⋮ menu → "Show original" / "Prikaži izvornik"
6. Copy block beginning with `Authentication-Results: mx.google.com;` (multi-line until blank)
7. Paste into a follow-up audit doc; THEN click verify link to finish flow

### §5.3 — Inference from §5.1 evidence (educated guess pending §5.2)

Given DKIM `d=bookbed.io s=resend` is properly signed and message-id shows valid AWS SES routing, and assuming the SPF record on `bookbed.io` includes Resend's `_spf.resend.com` (or AWS SES include) — the Gmail verdict should be `spf=pass dkim=pass dmarc=pass`. The audit/28 §3.3 finding that Resend is NOT yet in the SPF include suggests `spf=fail` is possible but DMARC alignment via DKIM-only would still pass (DMARC requires SPF OR DKIM aligned, not both). Confirm via §5.2 re-run.

For verify emails (Firebase native, `noreply@rab-booking-248fc.firebaseapp.com`), Google's own infrastructure sends — SPF/DKIM/DMARC are virtually guaranteed `pass` because Google authenticates its own domain end-to-end. Less interesting; still a useful baseline.

---

## §6 — Test Artifacts (for cleanup)

All accounts created on **PROD project `rab-booking-248fc`**. Tagged for cleanup per `memory/test-account-prod.md` safety rule: **"test artifact created by Duško smoke — safe to delete"**.

| UID | Email | Display Name (stored) | Verified | Final password |
|---|---|---|---|---|
| `jXt4S6TvYxUPUaYitJBYmSj3mnr2` | `bbsmoke-c1-1779610255@mailinator.com` | `BB Smoke C` | true (via reset) | `BookBedReset2026!` |
| `uRutRjNEtrexEz4vtdSM1DmHB6q2` | `zgembokrkan+bbsmokec2-1779610255@gmail.com` | `BB Smoke C Gmail` | true (via verify link) | `BookBedSmoke2026!` |

Per user direction (pre-flight Q2): **no admin-SDK auto-delete**. Manual cleanup via Firebase Console → Authentication → Users → search by UID/email → delete.

**Also leaves** `users/{uid}` Firestore docs (created by `onUserCreate` CF) which should be deleted by `deleteUserAccount` CF when the Auth user is removed (per CLAUDE.md FieldPath bug fix lineage). Verify in console.

**No other PROD writes** were attempted: no Stripe Connect onboarding, no subscription changes, no property/unit creation, no bookings. Within `test-account-prod.md` safety envelope.

---

## §7 — Cross-references

- `audit/28-tier4-resend-sentry-baseline.md` §5.3 — partially filled (bookings@bookbed.io captured §5.1; Gmail verdict deferred §5.2)
- `audit/31` MED-2 (Rate-limit header absence) — confirmed on TWO CFs (`checkRegistrationRateLimit`, `sendPasswordResetEmail`)
- `audit/33` §2 PROD bundling regression — every signUp request hits `rab-booking-248fc` as expected for the bundling; this smoke incidentally re-confirmed the bundling fact (signUp Authorization header + project_id in JWT both point at PROD)
- `memory/test-account-prod.md` — safety rules applied; no PROD writes outside auth surface
- `memory/spf-gap-bookbed-io.md` — informs §5.3 inference
- CHANGELOG 6.44 — resend cooldown discrepancy F-Auth-D2

---

## §8 — Follow-ups (for backlog)

1. ~~**F-Auth-D1**: investigate name-input sanitizer; fix or document the digit-strip pattern (priority MED, owner-facing UX bug)~~ — ✅ **DONE PR #470** (`bad97caa`): `InputSanitizer.sanitizeName` regex `\p{L}\s'\-` → `\p{L}\p{N}\s'\-`. See §4 F-Auth-D1.
2. ~~**F-Auth-D2**: reconcile CHANGELOG 6.44 (30s) vs actual 60s cooldown — source fix or doc update~~ — ✅ **DONE PR #470** (`bad97caa`): UI 60s canonical; CHANGELOG 6.44 corrected. See §4 F-Auth-D2.
3. **F-Auth-D3**: attach `X-RateLimit-*` headers to `checkRegistrationRateLimit` + `sendPasswordResetEmail` responses; surface remaining quota to client
4. **§5.2 re-run**: capture Gmail `Authentication-Results:` block for `bookings@bookbed.io` (and incidentally for `noreply@firebaseapp.com`) → close audit/28 §5.3
5. **F-Auth-D5**: profile `accounts:lookup` polling rate; consolidate auth-state listeners if multiple Riverpod providers fan out
6. **Server-side verify** `security_events` writes via admin SDK or Console — close §3.5 client-blind spot
7. **Cleanup PROD test users** (UIDs in §6) — manual Firebase Console

---

## §9 — Method notes

- **Flutter web input gotcha** (memory/flutter-web-input-bypass.md) reproduced: chrome-devtools MCP `type_text` worked; `fill`-style + Tab-chain caused field-mis-routing (email → space, phone → password). Recovered via direct-click each field + JS `beforeinput`/`input` event dispatch to clear residual state.
- `Ctrl+A` keyboard selection in Flutter inputs does NOT select content — workaround was `setSelectionRange(0, .length)` + `inp.value = ''` + dispatching `beforeinput inputType: deleteContentBackward` to keep `TextEditingController` in sync.
- Mailinator row click via `subject.parentElement * 8 + .click()` worked; first attempt picked wrong message due to ambiguous text-match; second attempt using direct childNode text equality picked the right row.
- `globalThis.firebase_auth` + `globalThis.firebase_firestore` + `globalThis.firebase_core` exposed by Flutter web Firebase init — enabled SDK-level introspection (verifyPasswordResetCode, confirmPasswordReset, signInWithEmailAndPassword, signOut, currentUser.reload, Firestore getDocs).
