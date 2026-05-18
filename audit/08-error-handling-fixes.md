# Error-handling UX fixes

**Branch:** `fix/error-boundary-and-chat-ux` (off `main`, do not push)
**Date:** 2026-05-18
**Scope:** Two UI-only error-handling fixes surfaced during Wave 0 smoke.

| # | Bug | File | Surfaced in |
|---|---|---|---|
| 1 | `ErrorBoundary` never reset `_errorDetails` — error widget stuck after "Try Again" / "Go Home" | `lib/core/error_handling/error_boundary.dart` | `audit/07-ios-smoke-test.md` → *Issues discovered (out of Wave 0 scope) #1* |
| 2 | Raw Gemini exception (e.g. Vertex AI API disabled) rendered verbatim in AI chat error banner | `lib/features/owner_dashboard/presentation/providers/ai_chat_provider.dart`, `…/screens/guides/ai_assistant_screen.dart`, `lib/l10n/app_{en,hr}.arb` | `audit/07-chrome-smoke-test.md` → *"Gemini call — FAIL"* paragraph (`Firebase AI Logic API has not been used in project 733027606474 before or it is disabled.`) |

> Cross-reference note: the source prompt referenced "iOS smoke Phase 2 bug" and "chrome smoke issue #8". The actual citations are as above — iOS smoke has no Phase 2 section; chrome smoke issue #8 is the guest-cancel BLOCKED entry, not the Gemini failure. Cited verbatim here to avoid propagating the wrong numbering.

---

## Bug 1 — `ErrorBoundary` state reset

### Root cause

`_DefaultErrorWidgetState` lives inside a child of `_ErrorBoundaryState`. The boundary keeps `_errorDetails` on the **parent** state. The action buttons (`_tryAgain`, `_navigateToHome`) only invoked router navigation — they never cleared `_errorDetails`. Because GoRouter is declarative and the boundary widget stays mounted as the parent of the navigated route, `_errorDetails != null` continued to short-circuit `build`, so the error UI repainted every frame even after the user navigated away.

### Fix

Added a private `_resetErrorBoundary(context)` helper that walks up the tree with `findAncestorStateOfType<_ErrorBoundaryState>()` and nulls `_errorDetails` via `setState`. Both action handlers call it as their first statement. The `mounted` guard inside `_resetErrorBoundary` is the safety net — boundary disposes during navigation are possible and must not throw.

### Before / after (diff)

```diff
   void _navigateToHome(BuildContext context) {
+    _resetErrorBoundary(context);
     // Primary: GoRouter (most reliable with GoRouter-based apps)
     try {
       final router = GoRouter.maybeOf(context);
       ...

   void _tryAgain(BuildContext context) {
+    _resetErrorBoundary(context);
     // Primary: GoRouter pop
     try {
       ...
   }
+
+  /// Clears the cached error so the boundary re-renders its child instead of
+  /// the error widget on the next frame. Without this, "Try Again" / "Go Home"
+  /// navigate but the boundary keeps painting the error UI.
+  void _resetErrorBoundary(BuildContext context) {
+    final state = context.findAncestorStateOfType<_ErrorBoundaryState>();
+    if (state != null && state.mounted) {
+      // ignore: invalid_use_of_protected_member
+      state.setState(() => state._errorDetails = null);
+    }
+  }
 }
```

There is no retry-count gating on `_tryAgain` in the existing code; nothing to preserve.

### Verification

- `flutter analyze` → 0 issues on this file.
- `flutter test` → 1100 tests pass; no `error_boundary` regression.
- Closes `audit/07-ios-smoke-test.md` → *Issues discovered (out of Wave 0 scope) #1*.

---

## Bug 2 — AI chat: friendly fallback for raw Gemini errors

### Root cause

`AiChatNotifier.sendMessage` wraps the Gemini call in `try/catch`. The catch arm was setting `state.error = 'DEBUG: ${e.toString()}'`, and `_buildErrorBanner` in `ai_assistant_screen.dart` had a fall-through branch that displayed any non-sentinel `state.error` verbatim. Result: when Vertex AI is disabled on a project, the user sees the full GCP error text — including project number, console URL, retry hint — in the chat error banner.

Side-finding (cleaned up in the same edit): a `print('[AiChat] ERROR: $e')` directly above the offending state assignment was logging the raw error to the dev console with an `// ignore: avoid_print` suppression. Removed in the same hunk because it served the same DEBUG-leak purpose as the UI string.

The T7 smoke audit (`audit/07-ios-smoke-test.md`) had claimed `grep "print(" lib/.../ai_chat_*` = 0 hits, but `main` currently carries 13 unrelated `print(` calls in this file (introduced after the T7 run — `_aiModelProvider`, `sendMessage` instrumentation, etc.). Those are **out of scope for this PR** and remain in place; only the one in the error path was removed.

### Fix

1. **Provider** (`ai_chat_provider.dart`): introduce `_classifyGeminiError(Object e)` that maps any `FirebaseAIException` subtype (`ServiceApiNotEnabled`, `QuotaExceeded`, `UnsupportedUserLocation`, `ServerException`, `InvalidApiKey`) to the sentinel `'ai_unavailable'`, with a string-match fallback on `permission_denied | has not been used | unavailable | resource_exhausted` for raw GCP errors that didn't get wrapped. Everything else → `'ai_error'`. Full error still goes through `LoggingService.logError` for Sentry/Crashlytics.
2. **UI** (`ai_assistant_screen.dart`): handle the new sentinel in `_buildErrorBanner` → `l10n.aiAssistantUnavailable`. The previous fall-through branch (`message = chatState.error ?? l10n.aiAssistantError`) is removed — unknown sentinels now resolve to the generic localized string instead of being rendered raw.
3. **l10n**: add `aiAssistantUnavailable` to `app_en.arb` + `app_hr.arb`; `flutter gen-l10n` regenerated `app_localizations*.dart`.

### Deviation from the source prompt

The prompt suggested routing l10n through `AppLocalizations.of(context)` in the provider. A `StateNotifier` has no `BuildContext`, so the provider sets a sentinel and the UI does the lookup — same outcome, correct layering.

### Before / after (diff)

```diff
     } catch (e, stackTrace) {
-      // ignore: avoid_print
-      print('[AiChat] ERROR: $e');
       await LoggingService.logError('AiChat: Gemini error', e, stackTrace);
       …
-      // Show actual error for debugging (TODO: remove after fixing)
-      final errorMsg = e.toString();
       state = state.copyWith(
         currentChat: updatedChat,
         isStreaming: false,
         streamingText: '',
-        error: 'DEBUG: $errorMsg',
+        error: _classifyGeminiError(e),
       );
       _ref.invalidate(aiChatsProvider);
     }
   }
+
+  /// Map a raw Gemini exception to a UI-safe sentinel.
+  String _classifyGeminiError(Object e) {
+    if (e is FirebaseAIException) return 'ai_unavailable';
+    final msg = e.toString().toLowerCase();
+    if (msg.contains('permission_denied') ||
+        msg.contains('has not been used') ||
+        msg.contains('unavailable') ||
+        msg.contains('resource_exhausted')) {
+      return 'ai_unavailable';
+    }
+    return 'ai_error';
+  }
```

```diff
     if (chatState.error == 'daily_limit') {
       message = l10n.aiAssistantDailyLimit;
+    } else if (chatState.error == 'ai_unavailable') {
+      message = l10n.aiAssistantUnavailable;
     } else if (chatState.error == 'ai_error') {
       message = l10n.aiAssistantAiError;
     } else {
-      message = chatState.error ?? l10n.aiAssistantError;
+      // Unknown sentinel — never display raw exception text.
+      message = l10n.aiAssistantError;
     }
```

l10n entries:
```json
// app_en.arb
"aiAssistantUnavailable": "AI Assistant is temporarily unavailable. Please try again in a moment.",
// app_hr.arb
"aiAssistantUnavailable": "AI Asistent trenutno nije dostupan. Pokušajte ponovno za nekoliko trenutaka.",
```

### Verification

- `grep -n "'DEBUG: " lib/features/owner_dashboard/presentation/providers/ai_chat_provider.dart` → 0 hits (the raw-error leak is gone).
- `git diff main -- lib/.../ai_chat_provider.dart` shows exactly one `print(` line removed (the catch-block one) and zero added. The other 13 `print(` calls already in `main` (model-load instrumentation in `_aiModelProvider`, `sendMessage` step logs) are unrelated to this fix and remain — they regressed against T7's "0 prints" claim before this branch was cut, and cleaning them up is a separate scope.
- `flutter analyze` → 0 issues across all changed files.
- `flutter test` → 1100 tests pass.
- `flutter gen-l10n` → `aiAssistantUnavailable` getter present in `app_localizations_en.dart`, `app_localizations_hr.dart`, `app_localizations.dart` (abstract).
- Closes `audit/07-chrome-smoke-test.md` → *"Gemini call — FAIL"* paragraph (raw error no longer reaches the UI; user-facing message is localized; full detail still logged for Sentry).

---

## Runtime verification status (TASK 3)

Marionette / chrome-devtools verification **deferred**. Rationale:

- **ErrorBoundary** — requires provoking an uncaught Flutter framework error mid-app. The cleanest repro (Marionette `tap(text: 'Foo')` against a non-existent label) was the original discovery path in `audit/07-ios-smoke-test.md` and is not available in this terminal (no iOS sim active in this session).
- **AI chat fallback** — requires Vertex AI disabled on `bookbed-dev`, which is the current state. The chrome-smoke run already captured the failure mode at `audit/07-chrome-smoke-test.md` line 539; the fix replaces the displayed string only and is exercised by the unit-level path (sentinel mapping + l10n lookup).

Both fixes are static-only changes (sentinel + l10n + ancestor-state nulling). Test-suite + analyzer verification is sufficient at this layer; the next interactive smoke pass (iOS or Chrome) will pick up the visible behaviour change.

---

## Files changed in this PR

```
lib/core/error_handling/error_boundary.dart                                     | +14 lines (1 method, 2 callsites)
lib/features/owner_dashboard/presentation/providers/ai_chat_provider.dart       | -5, +15 lines
lib/features/owner_dashboard/presentation/screens/guides/ai_assistant_screen.dart | -2, +4 lines
lib/l10n/app_en.arb                                                             | +1 entry
lib/l10n/app_hr.arb                                                             | +1 entry
lib/l10n/app_localizations.dart                                                 | regenerated (abstract getter)
lib/l10n/app_localizations_en.dart                                              | regenerated
lib/l10n/app_localizations_hr.dart                                              | regenerated
```

## Branch / commit policy

Per source prompt: **DO NOT push, deploy, or merge.** Single commit on the fix branch, awaiting reviewer.
