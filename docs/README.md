# BookBed Documentation

**Last Updated**: 2026-06-11 (pruned + reindexed — stale Dec-2025/Jan-2026 planning docs deleted; recover via `git log --diff-filter=D -- docs/`)

> Glavni operativni indeks je [CLAUDE.md](../CLAUDE.md) (audit log + kritične sekcije). Path-scoped pravila: `.claude/rules/`. Sigurnosni i sesijski nalazi: `audit/`.

## Top-level

- [SECURITY_FIXES.md](./SECURITY_FIXES.md) — sve sigurnosne ispravke (SF-001+), živi dokument
- [CHANGELOG.md](./CHANGELOG.md) — povijest verzija
- [TODO.md](./TODO.md) — neaktivni planning itemi (izvučeno iz CLAUDE.md)
- [setup.md](./setup.md) — lokalni dev/test/deploy setup
- [ICAL_SYNC_ARCHITECTURE.md](./ICAL_SYNC_ARCHITECTURE.md) — iCal sync arhitektura
- [FREE_TRIAL_IMPLEMENTATION.md](./FREE_TRIAL_IMPLEMENTATION.md) — trial sustav (detalji u `features/free-trial/`)
- [FORCE_UPDATE_SETUP.md](./FORCE_UPDATE_SETUP.md) — force-update mehanizam
- [STORE_SUBMISSION_GUIDE.md](./STORE_SUBMISSION_GUIDE.md) — App Store / Play submission
- [ANDROID_ADAPTIVE_ICON.md](./ANDROID_ADAPTIVE_ICON.md)
- [widget_firestore_single_field_indexes.md](./widget_firestore_single_field_indexes.md)

## Direktoriji

| Dir | Sadržaj |
|---|---|
| `features/` | Feature dokumentacija: `email-templates/` (EMAIL_SYSTEM.md), `free-trial/`, `overbooking-detection/`, `pwa/`, `stripe/` (integracija + debug guide), `analytics/` |
| `security/` | Modul-level sigurnosne analize (atomicBooking, emailVerification, inputSanitization, opća) |
| `testing/` | Test planovi + widget test matrice (browseri, zoom, legacy sites) + `test-calendar.ics` fixture |
| `user-guide/` | Korisnička dokumentacija (getting-started, calendar, payments, pricing, properties, settings, widget, troubleshooting) |
| `bugs/` | [consolidated-bugs-archive.md](./bugs/consolidated-bugs-archive.md) — povijesni bug fix-evi s code primjerima |
| `setup/` | `deployment/SUBDOMAIN_SETUP.md` |
| `cloud-mcp-tools/` | [CLAUDE_MCP_TOOLS.md](./cloud-mcp-tools/CLAUDE_MCP_TOOLS.md) — MCP serveri, slash commands |
| `widgets/` | UNIVERSAL_LOADER_GUIDE.md |
