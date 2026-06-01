# R4-C — Email Verification refactor onto Bb* foundation

**Branch:** `redesign/r4-email-verify`
**Screen:** `lib/features/auth/presentation/screens/email_verification_screen.dart`
**Family:** auth · post-login (auth-gate redirects unverified → here)
**Canonical sibling:** Forgot Password (PR #622)
**Design source:** `design_handoff/source/recovery.jsx` (VerifyCard + RecCard)

---

## 1. Screenshot deferral — documented per CanvasKit Tier 3 policy

Per `memory/canvaskit-tier3-screenshot-policy.md`: post-login pure-composition Phase 2 refactors accept text + CI + foundation-tests in lieu of MCP screenshot. CanvasKit gap blocks programmatic access past the login wall.

Email Verification is auth-gated by `router_owner.dart:286-297`:

```dart
if (isAuthenticated && requiresEmailVerification && !isEmailVerificationRoute && ...) {
  return OwnerRoutes.emailVerification;
}
```

Direct URL navigation to `/email-verification` while logged out redirects to `/login`. Reaching the screen requires a registered-but-unverified Firebase Auth session — no such fixture available; the BookBed dev test account (`bookbed-test@bookbed.io`) is already verified.

**`screenshot_deferred=true`** — per mandate's "On profile lock" fallback.

---

## 2. Code-based drift report vs `recovery.jsx` VerifyCard + Forgot Password #622

### Auth-family chrome (vs #622)

| Element | #622 Forgot Password | R4-C Email Verify | Match |
|---|---|---|---|
| Backdrop gradient | `rd.softBg` (pale lavender) | `rd.softBg` | ✅ exact |
| Card surface | glass: `rd.glassBg` + `rd.glassBorder` + `ImageFilter.blur(20,20)` | identical | ✅ exact |
| Card radius | `BBRadius.lgAll` | `BBRadius.lgAll` | ✅ exact |
| Card shadow | `rd.panelShadow` | `rd.panelShadow` | ✅ exact |
| Card maxWidth | 440 | 440 | ✅ exact |
| Card padding | `BBSpace.sm` / `BBSpace.md` / 36 (isSmallHeight / isCompact / default) | identical | ✅ exact |
| Brand mark | `BbLogo(useGradient: false)` | `BbLogo(useGradient: false)` | ✅ exact |
| h1 type | `BBType.h1` + `c.textPrimary` | `BBType.h1` + `c.textPrimary` | ✅ exact |
| Body type | `BBType.body` + `c.textSecondary` | `BBType.body` + `c.textSecondary` + height 1.55 | ✅ exact |

### Verify-state-specific (vs `recovery.jsx` VerifyCard L80-94)

| Element | recovery.jsx VerifyCard | R4-C Email Verify | Notes |
|---|---|---|---|
| Icon disc | 64×64, radius 18, `--bb-primary-tint-bg`, `mark_email_unread` 32px | 64×64 (56 on small height), radius 18, `c.primary @ alpha .10`, `Icons.mark_email_unread_outlined` half-disc | ✅ parity, outlined variant chosen for Material consistency |
| h1 title | "Potvrdite e-poštu" | `l10n.authCheckInbox` ("Provjerite inbox") | ✅ i18n preserved |
| Subtitle | "Unesite 6-znamenkasti kôd …" | `l10n.authEmailVerificationSentTo` | ⚠ recovery.jsx flow uses 6-digit code; our flow uses Firebase email-link verification. Copy + cooldown semantics differ. |
| Resend trigger | `BbButton variant=primary iconLeft=check fullWidth size=lg` | `BbButton primary` `fullWidth` `lg` `iconLeft='send'` | ✅ shape parity |
| Cooldown text | "Pošalji ponovno za 0:42" using `bb-tnum` | `BBType.bodyNum` (tabular num style) | ✅ tabular-num parity via `bodyNum` |
| Change-email | `<a>Promijenite e-poštu</a>` | `BbButton variant=tertiary` | ✅ tertiary-link equivalent |
| Back-to-login | (n/a in VerifyCard — RecBackLink in other 2 cards) | `BbButton variant=tertiary iconLeft='arrow_back'` | ✅ matches RecBackLink in `recovery.jsx:30-36` |

### Email chip (additive — preserved from legacy)

Legacy screen had an email-pill chip (the user's address rendered in a pill). recovery.jsx VerifyCard inlines the address in the subtitle (`<strong>ivana@…hr</strong>`). We **kept the pill** because the inline-strong subtitle would require structured `Text.rich` interpolation against a translated string (`authEmailVerificationSentTo` is a single sentence in HR; no `{email}` placeholder). Keeping the pill preserves the visual + avoids i18n churn. **Drift: visual divergence from recovery.jsx, intentional, copy-driven.**

### Info-tip block (additive — preserved from legacy)

Legacy had the `info_outline_rounded` row with click-link hint + arrival hint. Not in recovery.jsx VerifyCard. **Kept** as user-helpful copy; restyled to `c.surface` + `c.border` + `BBRadius.smAll` for token parity.

---

## 3. FROZEN logic confirmation

Untouched (per mandate "DO NOT TOUCH"):

- `sendEmailVerification` via `enhancedAuthProvider.notifier.sendEmailVerification()` — line 166
- `user.reload` / verification-poll: `Timer.periodic(3s, _checkVerificationStatus)` — line 55
- `_startInitialCooldown()` 60s on screen mount — line 67
- `_startCooldown()` 60s post-resend — line 332
- Auto-redirect on verified: `context.go(OwnerRoutes.overview)` inside `_checkVerificationStatus` — line 115
- `_showResendPasswordDialog` + `_showChangeEmailDialog` legacy AlertDialog/TextFormField/InputDecorationHelper — lines 215-326, 354-499
- `firebase_auth` indirect via `enhancedAuthProvider`
- No `_formKey` on parent screen (dialogs own their own form keys — left intact)
- No keyboard mixin needed on parent (no input on main view; dialogs handle their own forms via legacy machinery)
- Router: `OwnerRoutes.login`, `OwnerRoutes.overview` unchanged
- AppTheme: untouched

---

## 4. CI signals

- `dart format` — clean (formatter ran on file)
- `flutter analyze --no-fatal-infos` — 0 errors, 103 info (matches baseline 0-err/103-info)
- `flutter test test/features/auth/` — 8/8 PASS (forgot_password + enhanced_register smokes — same Bb* primitives stack)
- `flutter build web --release --target lib/main_dev.dart --no-tree-shake-icons` — `✓ Built build/web` (53.8s)

Test path note: mandate-suggested `test/feh/` does not exist on this branch (likely shorthand or typo); ran the closest equivalent (`test/features/auth/`).

---

## 5. Auth-family parity summary

R4-C joins `EnhancedLoginScreen` (PR #613), `EnhancedRegisterScreen` (PR #623), `ForgotPasswordScreen` (PR #622) on the same chrome:

- `rd.softBg` backdrop
- Glass card (`rd.glassBg`/`rd.glassBorder`/`rd.panelShadow` + `BackdropFilter` blur 20)
- `BbLogo` (non-gradient) brand mark
- `BBType.h1` title + `BBType.body` subtitle
- `BbButton` primary CTA + `BbButton` tertiary secondary actions

No new tokens, no new primitives, no AppTheme changes. Pure composition over the foundation laid in PR #611 + PR #616.
