# Claude Code Configuration

Ovaj direktorijum sadrži konfiguraciju za Claude Code AI asistenta koji poboljšava produktivnost razvoja.

## Fajlovi

### `project.md`
- **Šta radi**: Daje Claude-u kontekst o projektu (arhitektura, komande, patterns)
- **Rezultat**: Claude bolje razume projekat i daje preciznije odgovore
- **Automatsko**: Claude čita ovaj fajl na početku svake sesije

### `start-widget.sh`
- **Šta radi**: Brzo pokreće widget server na port 8081
- **Upotreba**:
  ```bash
  ./.claude/start-widget.sh          # Normalno pokretanje
  ./.claude/start-widget.sh --clean  # Sa flutter clean
  ```

### `hooks/after-edit.sh`
- **Šta radi**: Automatski pokreće `flutter analyze` nakon što Claude edituje .dart fajl
- **Rezultat**: Greške se odmah hvataju, brže ispravljanje
- **Automatsko**: Aktivira se svaki put kad Claude koristi Edit tool

## VS Code Settings (../.vscode/settings.json)

Konfigurisano:
- ✅ Auto-approval za sigurne komande (git status, flutter analyze, itd.)
- ✅ Auto-approval za Read, Glob, Grep (bez pitanja)
- ✅ Thinking mode: "interleaved" (bolje rezonovanje)
- ✅ Model: "sonnet" (optimalan balans brzine/kvaliteta)

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
