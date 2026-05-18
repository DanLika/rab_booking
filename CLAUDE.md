# Claude Code - Project Documentation

**BookBed** - Booking management platforma za property owner-e.

**Dodatni dokumenti:**
- [CLAUDE_BUGS_ARCHIVE.md](./docs/bugs-archive/CLAUDE_BUGS_ARCHIVE.md) - Detaljni bug fix-evi sa code examples
- [CLAUDE_WIDGET_SYSTEM.md](./docs/cloud-widget-systems/CLAUDE_WIDGET_SYSTEM.md) - Widget modovi, payment logic, pricing
- [CLAUDE_MCP_TOOLS.md](./docs/cloud-mcp-tools/CLAUDE_MCP_TOOLS.md) - MCP serveri, slash commands
- [EMAIL_SYSTEM.md](./docs/features/email-templates/EMAIL_SYSTEM.md) - Email template-i, payment rok, reminders
- [SECURITY_FIXES.md](./docs/SECURITY_FIXES.md) - Sigurnosne ispravke (SF-001, SF-002, ...)
- [CHANGELOG.md](./docs/CHANGELOG.md) - Svi changelogi v4.6–v6.65
- [TODO.md](./docs/TODO.md) - Planirani zadaci (Website Docs, Admin Controls, Security Fixes)

---

## NIKADA NE MIJENJAJ

| Komponenta | Razlog |
|------------|--------|
| Cjenovnik tab (`unified_unit_hub_screen.dart`) | FROZEN - referentna implementacija |
| Unit Wizard publish flow | 3 Firestore docs redoslijed kritičan |
| Timeline Calendar z-index | Cancelled bookings at base level (drawn first), confirmed on top |
| Calendar Repository (`firebase_booking_calendar_repository.dart`) | 989 linija, duplikacija NAMJERNA - bez unit testova NE DIRATI |
| Owner email u `atomicBooking.ts` | UVIJEK šalje - NE vraćaj conditional check |
| Subdomain validation regex | `/^[a-z0-9][a-z0-9-]{1,28}[a-z0-9]$/` (3-30 chars) |
| `generateViewBookingUrl()` u `emailService.ts` | Email URL logika |
| Navigator.push za confirmation | NE vraćaj state-based navigaciju |
| Timeline Calendar fixed dimensions (`timeline_dimensions.dart`) | FIXED 50/42/100/60px za SVE uređaje — NE vraćaj responsive breakpoints |

---

## STANDARDI

```dart
// Gradients (preferred method)
final gradients = context.gradients;

// Input fields - UVIJEK 12px borderRadius
InputDecorationHelper.buildDecoration()

// Provider invalidation - POSLIJE save-a
await repository.updateData(...);
ref.invalidate(dataProvider);

// Nested config - UVIJEK copyWith
currentSettings.emailConfig.copyWith(requireEmailVerification: false)
// NE: EmailNotificationConfig(requireEmailVerification: false) - gubi polja!

// Provider error handling - UVIJEK graceful degradation
try {
  return await repository.fetchData();
} catch (e, stackTrace) {
  await LoggingService.logError('Provider: Failed', e, stackTrace);
  return []; // ili null - NE throw
}
```

---

## QUICK CHECKLIST

**Prije commitanja:**
- [ ] `flutter analyze` = 0 issues
- [ ] Pročitaj CLAUDE.md ako diraš kritične sekcije
- [ ] `ref.invalidate()` POSLIJE repository poziva
- [ ] `mounted` check prije async setState/navigation

**Responsive breakpoints:**
- Desktop: ≥1200px
- Tablet: 600-1199px
- Mobile: <600px

---

## OBAVEZNO PRIJE COMMITA

**Dart formatiranje** - CI će odbiti PR ako kod nije formatiran:
```bash
dart format .
```

**Za AI agente (Jules, Sentinel, Bolt):** UVIJEK pokreni `dart format .` prije kreiranja commita. CI workflow provjerava formatiranje i odbija neformatirani kod.

---

## TOOLING GOTCHA: `flutter analyze` phantom errors

Ako `flutter analyze` izvijesti **tisuće** `uri_does_not_exist` / `undefined_identifier` / `undefined_method` errora — **NE TRETIRAJ ih kao bug u kodu**. Skoro sigurno je pub-cache desync: `.dart_tool/package_config.json` pokazuje na pakete u `~/.pub-cache/hosted/pub.dev/` koji ne postoje na disku.

**Quick check:**
```bash
ls -d ~/.pub-cache/hosted/pub.dev/firebase_core-* 2>/dev/null
```

**Fix:** `flutter pub get` — re-download missing packages. Nakon toga `flutter analyze` će ponovo davati real signal. Vidi `audit/04b-flutter-analyze-summary.md` za primjer (6053 reported → 0 real).

---

## Path-Scoped Rules (`.claude/rules/`)

Ovi fajlovi se učitavaju SAMO kad radiš na matchujućim fajlovima:

| Fajl | Path scope | Sadržaj |
|------|-----------|---------|
| `cloud-functions.md` | `functions/src/**/*.ts` | Logger, UTC, rate limiting, Sentry, bookingLookup, FieldPath bug |
| `stripe.md` | `functions/src/stripe*.ts`, `lib/**/stripe*`, `lib/**/payment*` | LIVE MODE, checkout flow, webhook, min amount |
| `calendar.md` | `lib/**/calendar/**`, `lib/**/timeline/**` | DateStatus, turnover, fixed dimensions, repository rules |
| `widget.md` | `lib/features/widget/**`, `lib/widget_main*.dart`, `web/bookbed-overlay.js` | URL slugs, subdomene, snackbar boje, iframe overlay |
| `admin.md` | `lib/features/admin/**`, `lib/admin_main*.dart`, `functions/src/admin/**` | Admin panel, Firestore rules, providers |
| `ui-ux.md` | `lib/**/*.dart` | Design system, animacije, dialogs, skeleton loaders |
| `keyboard-fix.md` | `lib/**/presentation/screens/**`, `web/index.html`, `lib/core/utils/keyboard_dismiss*` | Android mixin, 3 koraka za nove forme |
| `hosting-build.md` | `firebase.json`, `.firebaserc`, `web/**`, `.github/workflows/**`, `android/**`, `ios/**`, `pubspec.yaml` | Domene, build commands, deploy targets, dependency verzije |
| `firestore.md` | `firestore.rules`, `firestore.indexes.json` | Composite vs single-field, collection group, deploy |
| `fcm-pwa.md` | `lib/core/services/fcm_service*`, `web/firebase-messaging-sw.js`, `functions/src/fcmService.ts`, `lib/**/pwa/**` | Push notifikacije, PWA install, service worker |
| `auth.md` | `lib/features/auth/**`, `lib/**/enhanced_auth_provider*`, `functions/src/auth*`, `functions/src/emailVerification*` | Apple/Google Sign-In, email verifikacija, Remember Me, provider cache security |

---

**Last Updated**: 2026-03-02 | **Version**: 7.0

# context-mode — MANDATORY routing rules

You have context-mode MCP tools available. These rules are NOT optional — they protect your context window from flooding. A single unrouted command can dump 56 KB into context and waste the entire session.

## BLOCKED commands — do NOT attempt these

### curl / wget — BLOCKED
Any Bash command containing `curl` or `wget` is intercepted and replaced with an error message. Do NOT retry.
Instead use:
- `ctx_fetch_and_index(url, source)` to fetch and index web pages
- `ctx_execute(language: "javascript", code: "const r = await fetch(...)")` to run HTTP calls in sandbox

### Inline HTTP — BLOCKED
Any Bash command containing `fetch('http`, `requests.get(`, `requests.post(`, `http.get(`, or `http.request(` is intercepted and replaced with an error message. Do NOT retry with Bash.
Instead use:
- `ctx_execute(language, code)` to run HTTP calls in sandbox — only stdout enters context

### WebFetch — BLOCKED
WebFetch calls are denied entirely. The URL is extracted and you are told to use `ctx_fetch_and_index` instead.
Instead use:
- `ctx_fetch_and_index(url, source)` then `ctx_search(queries)` to query the indexed content

## REDIRECTED tools — use sandbox equivalents

### Bash (>20 lines output)
Bash is ONLY for: `git`, `mkdir`, `rm`, `mv`, `cd`, `ls`, `npm install`, `pip install`, and other short-output commands.
For everything else, use:
- `ctx_batch_execute(commands, queries)` — run multiple commands + search in ONE call
- `ctx_execute(language: "shell", code: "...")` — run in sandbox, only stdout enters context

### Read (for analysis)
If you are reading a file to **Edit** it → Read is correct (Edit needs content in context).
If you are reading to **analyze, explore, or summarize** → use `ctx_execute_file(path, language, code)` instead. Only your printed summary enters context. The raw file content stays in the sandbox.

### Grep (large results)
Grep results can flood context. Use `ctx_execute(language: "shell", code: "grep ...")` to run searches in sandbox. Only your printed summary enters context.

## Tool selection hierarchy

1. **GATHER**: `ctx_batch_execute(commands, queries)` — Primary tool. Runs all commands, auto-indexes output, returns search results. ONE call replaces 30+ individual calls.
2. **FOLLOW-UP**: `ctx_search(queries: ["q1", "q2", ...])` — Query indexed content. Pass ALL questions as array in ONE call.
3. **PROCESSING**: `ctx_execute(language, code)` | `ctx_execute_file(path, language, code)` — Sandbox execution. Only stdout enters context.
4. **WEB**: `ctx_fetch_and_index(url, source)` then `ctx_search(queries)` — Fetch, chunk, index, query. Raw HTML never enters context.
5. **INDEX**: `ctx_index(content, source)` — Store content in FTS5 knowledge base for later search.

## Subagent routing

When spawning subagents (Agent/Task tool), the routing block is automatically injected into their prompt. Bash-type subagents are upgraded to general-purpose so they have access to MCP tools. You do NOT need to manually instruct subagents about context-mode.

## Output constraints

- Keep responses under 500 words.
- Write artifacts (code, configs, PRDs) to FILES — never return them as inline text. Return only: file path + 1-line description.
- When indexing content, use descriptive source labels so others can `ctx_search(source: "label")` later.

## ctx commands

| Command | Action |
|---------|--------|
| `ctx stats` | Call the `ctx_stats` MCP tool and display the full output verbatim |
| `ctx doctor` | Call the `ctx_doctor` MCP tool, run the returned shell command, display as checklist |
| `ctx upgrade` | Call the `ctx_upgrade` MCP tool, run the returned shell command, display as checklist |
