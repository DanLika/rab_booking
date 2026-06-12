# Claude Code - Project Documentation

**BookBed** - Booking management platforma za property owner-e.

**Dodatni dokumenti:**
- [consolidated-bugs-archive.md](./docs/bugs/consolidated-bugs-archive.md) - Detaljni bug fix-evi sa code examples
- [EMAIL_SYSTEM.md](./docs/features/email-templates/EMAIL_SYSTEM.md) - Email template-i, payment rok, reminders
- [SECURITY_FIXES.md](./docs/SECURITY_FIXES.md) - Sigurnosne ispravke (SF-001..SF-073)
- [CHANGELOG.md](./docs/CHANGELOG.md) - Svi changelogi
- [TODO.md](./docs/TODO.md) - Planirani zadaci

**Audit log** (one-line index; detail in each audit/*.md file). *Pruned 2026-06-11: closed session audits + screenshot artifacts deleted (105MB→1.2MB) — recover any via git history (`git log --diff-filter=D -- audit/`). Kept: rules-referenced, OPEN/🚨 findings, runbooks, specs, recent design chain.*
- [cutover-dryrun-2026-05-30/runbook.md](./audit/cutover-dryrun-2026-05-30/runbook.md) — full ledger + 4a/4b/4c/4d phase logs + IAM re-grant script (2026-05-30)
- ✅ [125-security-audit](./audit/125-security-audit-2026-06-12.md) — delta /vibe-security pass (clean) + full 165+-check re-run (6 agenata, HUGE): 0 CRIT/HIGH/MED novih, 5 LOW; 2 agent false-positives ubijena firsthand verifikacijom. SF-084 fix wave (**PR #731**, merged `a5cd544f`): SF-080 extension — units + additional_services create/update trial-gated (kanonski + CG permissive-union mirror; delete = off-ramp), `widget_secrets.updated_at` request.time bind when-written, Firestore-backed RL na 4 booking-action + 2 admin callable-a. Rules emulator 196 pass (+14), jest 463/463; **PROD pickup ZAVRŠEN** (rules + 6 CF eu-west1, reachability verify svih 6). Usput: CI regresija paths-filter v3→v4 ("Resource not accessible by integration", ista klasa kao #728 "2s infra fail") → `permissions: pull-requests: read` fix; billing block se vratio → local-verified merge. Otvoreno dodano: F-125-04 Node 22 (Oct 2026 EOL), F-125-05 uuid moderates (ride firebase-admin@14, F-107-07/08) (2026-06-12)
- 🔄 [124-owner-page-fidelity](./audit/124-owner-page-fidelity-2026-06-11.md) — IN-FLIGHT page-by-page owner fidelity vs handoff (16 stranica + drawer + app bar, light+dark, fix-as-you-go na `design/124-owner-page-fidelity`): Pregled arrivals card + desktop grid + hero wash, Rezervacije Završene tab + channel tones, Timeline/Mjesečni weekday eyebrows + golden weekends + Uvezene legend, login desktop split; builds on audit/121 token layer (2026-06-11)
- 🟢 [123-security-audit](./audit/123-security-audit-2026-06-11.md) — full 165+-check sweep (9 agents + gitleaks + semgrep + npm audit) + 2 /vibe-security passes: 0 CRIT/HIGH new. Fix wave 1: F-123-01/02/04/06/07 (payment bounds + iCal sanitize + 5MB cap + Connect rate limits; 462/462 jest green). Fix wave 2 (AI/LLM): F-123-AI server-authoritative Gemini daily quota (Firestore `users/{uid}/data/ai_usage` {day,count}, txn-consumed, rules pin day→request.time + monotonic increment so restart/tamper can't reset; replaces client-memory counter) + `ai_chats` messages.size()≤200; new `ai_usage.test.ts` 14 cells, full rules suite 173 pass green. Tier/subscription escalation verified CLOSED first-hand (rules 78-129). **§4 = kanonski open ledger** (99+107 apsorbovani 2026-06-11, izvorni docs obrisani). Same-day residual-closure wave (SF-083): F-86-01/02, F-99-03/10/16, F-107-10/13/16 CLOSED + F-107-17 killed false-positive + F-107-14 deferred-with-finding. Preostalo otvoreno: F-123-03 trial-gate product decision, F-86-03 Stripe-min-floor product decision, F-99-09/12-15 + F-107-05/12/15 deliberate deferrals, firebase-admin/functions major bumps (F-107-07/08), operator App-Check toggle + PROD curl verify (2026-06-11)

---

## NIKADA NE MIJENJAJ

| Komponenta | Razlog |
|------------|--------|
| Cjenovnik tab CONTENT (`unified_unit_hub_screen.dart` — pricing grid + Spremi) | FROZEN - referentna implementacija. Hub screen-shell chrome (premium header above existing layout, theme/AppBar) je additive-OK; FROZEN scope = tab content only. |
| Unit Wizard publish flow | 2-doc serial write (unit → widget_settings, Doc 2 id sourced from Doc 1) — redoslijed kritičan |
| Timeline Calendar z-index | Cancelled bookings at base (drawn first), confirmed on top |
| Calendar Repository (`firebase_booking_calendar_repository.dart`) | 989 linija, duplikacija NAMJERNA - bez unit testova NE DIRATI |
| Owner email u `atomicBooking.ts` | UVIJEK šalje - NE vraćaj conditional check |
| Subdomain validation regex | `/^[a-z0-9][a-z0-9-]{1,28}[a-z0-9]$/` (3-30 chars) |
| `generateViewBookingUrl()` u `emailService.ts` | Email URL logika |
| Navigator.push za confirmation | NE vraćaj state-based navigaciju |
| Timeline Calendar fixed dimensions (`timeline_dimensions.dart`) | FIXED 50/42/100/60px za SVE uređaje — NE vraćaj responsive breakpoints |
| `bookings` read rule — `unit_id+status` clause 1 | ✅ T11c CLOSED 2026-05-22 (commit `ab6bdb3d`). All 3 rule surfaces tightened. Widget calendar + booking-submit route through `getUnitAvailability` callable (eu-west1). Realtime → 30s polling. Privacy-driven: pending/confirmed visual distinction sacrificed. Vidi SF-019 (audit/06 obrisan — git history). |

---

## STANDARDI

```dart
// Gradients
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

**Design tokens (NEW code):**
- Koristi `BB*` iz `lib/core/design/tokens.dart` (`BBSpace`/`BBRadius`/`BBColor`/`BBType`/`BBShadow`) — canonical namespace
- `AppColors`/`AppDimensions`/`AppTypography`/`AppShadows` su source of truth (BB* delegira); **NE** refaktoriraj postojeće call sites in-place — bulk codemod je zaseban PR
- 3 off-scale TODO consts: `BBSpace.xs2=12`, `BBRadius.xs2=8`, svih 9 `BBType.*`
- Detalji: `design_handoff/source/tokens.css` (ground truth) + `audit/80b-token-mapping.md`

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

**Dart formatiranje** - CI odbija PR ako kod nije formatiran:
```bash
dart format .
```

**Za AI agente:** UVIJEK pokreni `dart format .` prije commit-a.

**CI build-android job** (`.github/workflows/ci.yml` Job 3): koristi `./tool/build_aab.sh --release` wrapper — NE `flutter build appbundle` direktno (pukne na flutter_native_splash registry bug). Vidi `.claude/rules/hosting-build.md` + `memory/aab-build-blocker.md`.

---

## TOOLING GOTCHA: `flutter analyze` phantom errors

Ako `flutter analyze` izvijesti **tisuće** `uri_does_not_exist` / `undefined_identifier` / `undefined_method` errora — **NE TRETIRAJ ih kao bug u kodu**. Skoro sigurno je pub-cache desync.

**Quick check:** `ls -d ~/.pub-cache/hosted/pub.dev/firebase_core-* 2>/dev/null`

**Fix:** `flutter pub get`. (Historical proof: 6053 reported → 0 real, audit/04b — pruned, git history.)

---

## Path-Scoped Rules (`.claude/rules/`)

Učitavaju se SAMO kad radiš na matchujućim fajlovima:

| Fajl | Path scope | Sadržaj |
|------|-----------|---------|
| `cloud-functions.md` | `functions/src/**/*.ts` | Logger, UTC, rate limiting, Sentry, bookingLookup, FieldPath bug |
| `stripe.md` | `functions/src/stripe*.ts`, `lib/**/stripe*`, `lib/**/payment*` | LIVE MODE, checkout flow, webhook, min amount |
| `calendar.md` | `lib/**/calendar/**`, `lib/**/timeline/**` | DateStatus, turnover, fixed dimensions, repository rules |
| `widget.md` | `lib/features/widget/**`, `lib/widget_main*.dart`, `web/bookbed-overlay.js` | URL slugs, subdomene, snackbar boje, iframe overlay |
| `admin.md` | `lib/features/admin/**`, `lib/admin_main*.dart`, `functions/src/admin/**` | Admin panel, Firestore rules, providers |
| `ui-ux.md` | `lib/**/*.dart` | Design system, animacije, dialogs, skeleton loaders |
| `keyboard-fix.md` | `lib/**/presentation/screens/**`, `web/index.html`, `lib/core/utils/keyboard_dismiss*` | Android mixin, 3 koraka za nove forme |
| `hosting-build.md` | `firebase.json`, `.firebaserc`, `web/**`, `.github/workflows/**`, `android/**`, `ios/**`, `pubspec.yaml` | Domene, build commands, deploy targets |
| `firestore.md` | `firestore.rules`, `firestore.indexes.json` | Composite vs single-field, collection group, deploy |
| `fcm-pwa.md` | `lib/core/services/fcm_service*`, `web/firebase-messaging-sw.js`, `functions/src/fcmService.ts`, `lib/**/pwa/**` | Push notifikacije, PWA install, SW |
| `auth.md` | `lib/features/auth/**`, `lib/**/enhanced_auth_provider*`, `functions/src/auth*`, `functions/src/emailVerification*` | Sign-In flows, email verifikacija, Remember Me, provider cache security |
| `ios-development.md` | `ios/**`, `lib/main*.dart`, `lib/widget_main*.dart` | GoogleService-Info.plist swap, `--target` requirement, Dart project-ID asserts |
| `android-development.md` | `android/**`, `lib/main*.dart`, `lib/widget_main*.dart`, `tool/build_aab.sh` | google-services.json swap, debug-build `--release`, AAB blocker fix, 16KB page-size |
| `build-runner.md` | `pubspec.yaml`, `build.yaml`, `analysis_options.yaml`, `**/*.g.dart` | Fresh-clone `--delete-conflicting-outputs`, pub-cache desync distinction |

---

**Last Updated**: 2026-06-11 | **Version**: 7.15

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
