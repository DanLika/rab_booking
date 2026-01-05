# Claude Code Alati & MCP Serveri

Za glavni CLAUDE.md vidi: [CLAUDE.md](./CLAUDE.md)

---

## MCP Serveri (Aktivni)

| Server | Svrha |
|--------|-------|
| **dart-flutter** | Dart analiza, Flutter widgets, pub.dev |
| **firebase** | Firestore, Auth, Cloud Functions |
| **github** | Issue/PR management |
| **memory** | Perzistentna memorija između sesija |
| **context7** | Dokumentacija biblioteka |
| **stripe** | Payment operacije |
| **flutter-inspector** | Screenshots, errors, Hot Restart |
| **mobile-mcp** | Android/iOS automation |

### dart-flutter vs flutter-inspector

| Zadatak | dart-flutter | flutter-inspector |
|---------|--------------|-------------------|
| Code analysis | `analyze_files` | - |
| Hot Reload | `hot_reload` | - |
| Hot Restart | - | `hot_restart_flutter` |
| Screenshots | - | `view_screenshot` |
| Tests | `run_tests` | - |

**VAŽNO:** Flutter Inspector zahtijeva debug mode na portu 8181:
```bash
flutter run -d chrome --web-port=8181
```

---

## Custom Slash Commands

### Generatori

| Command | Svrha |
|---------|-------|
| `/ui` | Flutter UI komponente (Material 3, Riverpod, responsive) |
| `/firebase` | Repository, model, provider kod |
| `/test` | Unit, widget, integration testovi |

### Stripe Operations

| Command | Svrha |
|---------|-------|
| `/stripe:customer-lookup` | Pronađi kupca po email-u |
| `/stripe:analyze-payments` | Statistika plaćanja |
| `/stripe:create-link` | Kreiraj payment link |
| `/stripe:subscriptions` | Upravljanje pretplatama |
| `/stripe:refund` | Procesiraj refund |

### Utilities

| Command | Svrha |
|---------|-------|
| `/experiment:debug` | Experiment-driven debugging |
| `/pr:resolve-comments` | Rješavanje PR komentara |
| `/misc:summary` | Summary sesije |
| `/new-task` | Analiza kompleksnih taskova |
| `/flutter:code-cleanup` | Dart/Flutter refaktoring |

---

## AI Agenti (18)

Agenti pružaju ekspertizu, MCP serveri izvršavaju akcije.

### Tech Stack

| Agent | Fokus |
|-------|-------|
| `flutter-expert` | Flutter SDK, Riverpod, Material 3 |
| `dart-expert` | Idiomatic Dart, async/await |
| `stripe-expert` | Stripe API, Connect, webhooks |

### Architecture

| Agent | Fokus |
|-------|-------|
| `system-architect` | Skalabilnost, maintainability |
| `backend-architect` | Data integrity, security |
| `frontend-architect` | UX, accessibility |

### Code Quality

| Agent | Fokus |
|-------|-------|
| `refactoring-expert` | Clean code, tech debt |
| `performance-engineer` | Bottlenecks, optimization |
| `security-engineer` | Vulnerabilities, compliance |

---

## Hooks (Auto-akcije)

| Hook | Trigger | Akcija |
|------|---------|--------|
| `dart format` | Nakon Edit | Auto-format |
| `flutter analyze` | Nakon Edit | Provjera grešaka |
