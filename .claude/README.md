# Claude Code Configuration

Ovaj direktorijum sadrži konfiguraciju za Claude Code AI asistenta koji poboljšava produktivnost razvoja.

## 📁 Fajlovi

### `project.md`
- **Šta radi**: Daje Claude-u kontekst o projektu (arhitektura, komande, patterns)
- **Rezultat**: Claude bolje razume projekat i daje preciznije odgovore
- **Automatsko**: Claude čita ovaj fajl na početku svake sesije

### `extensions-info.md`
- **Šta radi**: Detaljni guide za sve instalirane VS Code ekstenzije
- **Sadržaj**: Kako Claude koristi GitLens, Error Lens, TODO Tree, Flutter ekstenzije
- **Korisno za**: Razumijevanje integracije ekstenzija

### `start-widget.sh`
- **Šta radi**: Brzo pokreće widget server na port 8081
- **Upotreba**:
  ```bash
  ./.claude/start-widget.sh          # Normalno pokretanje
  ./.claude/start-widget.sh --clean  # Sa flutter clean
  ```

### `check-todos.sh`
- **Šta radi**: Pronalazi sve TODO, FIXME, BUG, OPTIMIZE komentare
- **Upotreba**:
  ```bash
  ./.claude/check-todos.sh
  ```

### `analyze-errors.sh` ⭐ NOVO
- **Šta radi**: Analizira sve greške i kategorizuje ih po tipu
- **Rezultat**: Claude odmah vidi pattern grešaka (missing imports, type errors, null safety)
- **Upotreba**:
  ```bash
  ./.claude/analyze-errors.sh
  ```
- **Claude koristi**: Za brzu dijagnozu problema

### `profile-performance.sh` ⭐ NOVO
- **Šta radi**: Pronalazi performance bottlenecks (non-const widgets, veliki build metodi)
- **Rezultat**: Claude identifikuje performance probleme proaktivno
- **Upotreba**:
  ```bash
  ./.claude/profile-performance.sh
  ```
- **Claude koristi**: Prije optimizacije ili kad app sporo radi

### `bug-template.md` ⭐ NOVO
- **Šta radi**: Template za strukturirano prijavljivanje bugova
- **Rezultat**: Claude dobija sav potreban context odmah, brže rešavanje
- **Kada koristiti**: Kad imaš bug koji Claude treba da ispravi

### `firebase-tools.sh` ⭐ NOVO
- **Šta radi**: Interaktivni meni za Firebase operacije
- **Opcije**: Start emulators, validate rules, deploy, test
- **Upotreba**:
  ```bash
  ./.claude/firebase-tools.sh
  ```
- **Claude koristi**: Za brzo Firebase deployment i testing

### `start-emulators.sh` ⭐ NOVO
- **Šta radi**: Brzo pokreće Firebase Emulators (Firestore + Functions + Hosting)
- **Upotreba**:
  ```bash
  ./.claude/start-emulators.sh
  ```
- **Claude koristi**: Za lokalno testiranje prije deployment-a

### `supabase-tools.sh` ⭐ NOVO
- **Šta radi**: Interaktivni meni za Supabase operacije
- **Opcije**: Start local, migrations, reset DB, push/pull
- **Upotreba**:
  ```bash
  ./.claude/supabase-tools.sh
  ```
- **Claude koristi**: Za Supabase development i migration management

### `live-test.sh` ⭐ NOVO
- **Šta radi**: Live testing workflow automation
- **Scenariji**: Full stack, multi-browser, mobile emulator, production-like
- **Upotreba**:
  ```bash
  ./.claude/live-test.sh
  ```
- **Claude koristi**: Za automated testing setups

### `hooks/after-edit.sh`
- **Šta radi**: Automatski pokreće `flutter analyze` nakon što Claude edituje .dart fajl
- **Rezultat**: Greške se odmah hvataju, brže ispravljanje
- **Automatsko**: Aktivira se svaki put kad Claude koristi Edit tool

---

## 🔬 Kako Error Lens i GitLens Pomažu Claude-u

### **Error Lens: Inline Error Detection**

**Bez Error Lens:**
```dart
// Claude čita fajl - vidi samo kod!
color: colors.statusPastReservation,  // Bug, ali Claude NE ZNA
```
Claude: "Fajl izgleda OK."

**Sa Error Lens:**
```dart
// Claude čita fajl - vidi greške INLINE!
color: colors.statusPastReservation,  ⚠️ The getter 'statusPastReservation' isn't defined
```
Claude: "Vidim! Dodajem getter u color_tokens.dart..."

**→ Claude hvata greške ODMAH, bez da ti moraš pokazati!**

---

### **GitLens: Git Context & History**

**Bez GitLens:**
```
Ti: "Zašto je kalendar sporiji?"
Claude: "Ne znam šta je promenjeno, reci mi..."
```

**Sa GitLens:**
```bash
# Claude automatski pokreće:
git log --oneline -5 month_calendar_widget.dart
git show 991033e  # Vidi tačno šta je dodato
git blame path/to/file.dart  # Vidi ko je editovao
```
Claude: "Vidim! Commit 991033e je dodao Opacity widget bez const. Optimizujem..."

**→ Claude pronalazi ROOT CAUSE sam!**

---

## 🎯 VS Code Konfiguracije

### `../.vscode/settings.json` (Glavni Settings)
**Claude Code:**
- ✅ Auto-approval za 30+ sigurnih komandi (git, flutter, dart)
- ✅ Auto-approval za Read, Glob, Grep tools
- ✅ Thinking mode: "interleaved" (bolje rezonovanje)
- ✅ Model: "sonnet" (optimalan balans brzine/kvaliteta)

**Flutter & Dart:**
- ✅ Auto-format on save (80/120 char rulers)
- ✅ Hot reload on save (uvijek)
- ✅ DevTools auto-open (browser mode)
- ✅ CanvasKit web renderer (najbolji za UI)
- ✅ Widget Inspector integration
- ✅ Code completion improvements
- ✅ LSP enabled (brži analysis)
- ✅ Multi-core analysis (4 CPU-a)

**Ekstenzije:**
- ✅ GitLens (git history, blame inline)
- ✅ Error Lens (greške inline)
- ✅ TODO Tree (TODO/FIXME tracking)
- ✅ Firestore Explorer integration

### `../.vscode/launch.json` (Debug Konfiguracije)
Pritisni **F5** ili **Cmd+Shift+D** za brzo pokretanje:

**Single Instance:**
- 🚀 Widget (Chrome - Port 8081) - Standardno
- 🎨 Widget (Chrome - Port 8082) - Drugi port
- ⚡ Widget (Profile Mode) - Performance testing
- 🏭 Widget (Release Mode) - Production build
- 🧪 Widget (HTML Renderer) - Legacy mode
- 🔧 Widget (DevTools Auto-Open) - Sa DevTools
- 📱 Widget (macOS Desktop) - Desktop app

**Multi-Instance:**
- 🔥 Multi-Port (8081 + 8082) - Dva instance odjednom

### `../.vscode/tasks.json` (Build Tasks)
Pritisni **Cmd+Shift+B** za brze taskove:

- 🧹 Flutter Clean
- 📦 Flutter Pub Get
- 🔍 Flutter Analyze
- 🧪 Flutter Test (All)
- ✨ Dart Format (All)
- 🔧 Dart Fix (Apply)
- 🏗️ Build Web (Release)
- 📊 DevTools (Open)
- 🚀 Quick Start Widget (Port 8081)
- 🧼 Clean + Pub Get + Analyze (kombinovano)

### `../.vscode/extensions.json` (Preporučene Ekstenzije)
Lista MUST-HAVE ekstenzija za tim:
- Dart & Flutter (obvezno)
- Claude Code AI
- GitLens, Error Lens, TODO Tree
- Flutter helpers (Riverpod snippets, Flutter color)
- Firebase & Database tools

### `../.vscode/flutter-shortcuts.md` (Shortcuts Guide)
Kompletan guide sa:
- Keyboard shortcuts tokom debug-a
- DevTools features
- Performance tips
- Testing commands
- Git + Flutter workflow

## Kako Ovo Poboljšava Workflow

### Pre:
1. Claude traži odobrenje za svaki git status
2. Claude traži odobrenje za svaki read file
3. Moraš ručno pokrenuti flutter analyze
4. Claude nema kontekst o projektu

### Posle:
1. Claude automatski pokreće sigurne komande
2. Read/Grep/Glob bez pitanja
3. Greške se automatski provjeravaju nakon edita
4. Claude zna arhitekturu i patterns projekta

## Održavanje

Edituj `project.md` kad:
- Dodaješ nove features ili direktorije
- Mijenjjaš arhitekturu
- Dodaješ nove patterns ili konvencije
- Imaš probleme koje Claude treba da zna

Edituj `.vscode/settings.json` kad:
- Želiš dodati više auto-approved komandi
- Želiš promijeniti default model (sonnet/opus/haiku)
