# Pre-Implementation Checklist

## 📋 Šta treba provjeriti prije implementacije

### 1. SOFTWARE INSTALACIJE

#### Flutter SDK
```bash
# Provjeri da li je Flutter instaliran
flutter --version

# Trebalo bi da bude verzija 3.24.0 ili novija
# Ako nije instaliran, preuzmi sa: https://flutter.dev/docs/get-started/install
```

#### Dart SDK
```bash
# Provjeri Dart verziju (dolazi sa Flutter-om)
dart --version

# Trebalo bi da bude verzija 3.5.0 ili novija
```

#### Git
```bash
# Provjeri da li je Git instaliran
git --version

# Ako nije, preuzmi sa: https://git-scm.com/downloads
```

#### VS Code Extensions
Instaliraj ove ekstenzije u VS Code:
- **Flutter** (Dart-Code.flutter)
- **Dart** (Dart-Code.dart-code)
- **Prettier - Code formatter** (esbenp.prettier-vscode)
- **Error Lens** (usernamehw.errorlens)
- **GitLens** (eamodio.gitlens)
- **Thunder Client** (rangav.vscode-thunder-client) - za testiranje API-ja

#### Android Studio / Xcode (za mobile development)

**Za Android:**
```bash
# Provjeri da li je Android SDK instaliran
flutter doctor -v

# Instalacija: https://developer.android.com/studio
```

**Za iOS (samo macOS):**
```bash
# Provjeri da li je Xcode instaliran
xcode-select --version

# Instalacija preko App Store
```

#### Chrome (za Web development)
```bash
# Flutter koristi Chrome za web development
# Provjeri da li je instaliran
```

---

### 2. FLUTTER DOCTOR - DIJAGNOSTIKA

Pokreni Flutter doctor da provjeriš šta nedostaje:

```bash
cd C:\Users\W10\dusko1\rab_booking
flutter doctor -v
```

**Očekivani output:**
```
[✓] Flutter (Channel stable, 3.24.0, on Windows 10)
[✓] Android toolchain - develop for Android devices
[✓] Chrome - develop for the web
[✓] Visual Studio Code (version 1.95.0)
[✓] Connected device (3 available)
[✓] Network resources
```

**Ako vidiš [✗] bilo gdje:**
- Prati instrukcije koje Flutter doctor prikaže
- Instaliraj nedostajuće komponente

---

### 3. SUPABASE SETUP

Prije implementacije, kreiraj Supabase projekat:

1. **Idi na:** https://supabase.com
2. **Kreiraj novi projekat:**
   - Organization: Kreiraj novu ili koristi postojeću
   - Project Name: `rab-booking-dev`
   - Database Password: **Sačuvaj ovo!**
   - Region: `Central EU (Frankfurt)` - najbliži regiji

3. **Kopiraj credentials:**
   - Project URL: `https://xxxxx.supabase.co`
   - Anon (public) key: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`
   - Service role key: **Čuvaj ovo sigurno!**

4. **Sačuvaj u .env fajl** (kreiraćemo kasnije)

---

### 4. STRIPE SETUP (za payment integration)

1. **Kreiraj Stripe nalog:** https://stripe.com
2. **Prebaci na Test mode** (toggle u gornjem desnom uglu)
3. **Kopiraj keys:**
   - Publishable key: `pk_test_...`
   - Secret key: `sk_test_...` (čuvaj sigurno!)

---

### 5. GITHUB REPOSITORY SETUP

#### Kreiraj novi GitHub repository:

```bash
# 1. Idi na https://github.com/new
# 2. Repository name: rab_booking
# 3. Description: Flutter booking app for island Rab vacation rentals
# 4. Private/Public: Odaberi prema želji
# 5. NE dodavaj README, .gitignore, ili license (već postoje)
# 6. Klikni "Create repository"
```

#### Poveži lokalni projekat sa GitHub-om:

```bash
cd C:\Users\W10\dusko1\rab_booking

# Dodaj remote origin
git remote add origin https://github.com/YOUR_USERNAME/rab_booking.git

# Provjeri trenutni status
git status

# Commit početnog stanja (ako nije već)
git add .
git commit -m "Initial project setup with 20 prompts"

# Push na GitHub
git push -u origin main
```

**Ako branch nije `main` nego `master`:**
```bash
git branch -M main
git push -u origin main
```

---

### 6. VS CODE WORKSPACE SETUP

Kreiraj VS Code workspace settings:

```bash
# Otvori projekat u VS Code
code C:\Users\W10\dusko1\rab_booking
```

**Kreiraj `.vscode/settings.json`:**
```json
{
  "dart.flutterSdkPath": "C:\\flutter",
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll": true
  },
  "[dart]": {
    "editor.formatOnSave": true,
    "editor.formatOnType": true,
    "editor.selectionHighlight": false,
    "editor.suggest.snippetsPreventQuickSuggestions": false,
    "editor.suggestSelection": "first",
    "editor.tabCompletion": "onlySnippets",
    "editor.wordBasedSuggestions": false
  },
  "dart.lineLength": 100,
  "files.associations": {
    "*.dart": "dart"
  }
}
```

**Kreiraj `.vscode/launch.json`:**
```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Development",
      "request": "launch",
      "type": "dart",
      "args": ["--dart-define=ENV=development"]
    },
    {
      "name": "Production",
      "request": "launch",
      "type": "dart",
      "args": ["--dart-define=ENV=production"]
    }
  ]
}
```

---

### 7. .gitignore PROVJERA

Provjeri da `.gitignore` sadrži:

```gitignore
# Flutter/Dart
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies
.packages
.pub-cache/
.pub/
build/
*.g.dart
*.freezed.dart

# Environment variables - VAŽNO!
.env
.env.local
.env.development
.env.production
.env.staging

# IDE
.vscode/
.idea/
*.iml
*.ipr
*.iws

# macOS
.DS_Store

# Coverage
coverage/
*.lcov

# Android
*.jks
*.keystore
android/key.properties

# iOS
ios/Pods/
ios/.symlinks/
ios/Flutter/Flutter.framework
ios/Flutter/Flutter.podspec
```

---

### 8. PROVJERA STRUKTURE PROJEKTA

Prije nego počneš, provjeri da projekat ima ovu strukturu:

```
rab_booking/
├── lib/
│   ├── main.dart
│   └── (ostalo će biti kreirano tokom implementacije)
├── test/
├── android/
├── ios/
├── web/
├── pubspec.yaml
├── .gitignore
├── README.md (postoji ali prazan - biće update-ovan)
└── prompt_01.txt do prompt_20.txt ✓
```

---

### 9. PREPORUKE ZA IMPLEMENTACIJU

#### Redoslijed izvršavanja promptova:

1. **Prompt 01** - Roadmap (pregledaj prvo)
2. **Prompt 02** - Project setup & folder structure
3. **Prompt 03** - Design system (theme, colors, typography)
4. **Prompt 04** - Data models
5. **Prompt 05** - Supabase database schema & migrations
6. **Prompt 06** - Navigation & routing
7. **Prompt 07-09** - UI screens (Home, Search, Property details)
8. **Prompt 10** - Booking calendar
9. **Prompt 11** - Authentication
10. **Prompt 12** - Owner dashboard
11. **Prompt 13** - Payment integration
12. **Prompt 14-15** - Shared widgets & responsive layout
13. **Prompt 16** - Error handling
14. **Prompt 17** - Testing
15. **Prompt 18** - Performance optimization
16. **Prompt 19** - Deployment & DevOps
17. **Prompt 20** - Documentation

#### Kako izvršavati prompte:

**Opcija 1 - Jedan po jedan (preporučeno za početak):**
```bash
# Windows Command Prompt
type prompt_02.txt | claude-code

# PowerShell
Get-Content prompt_02.txt | claude-code

# Git Bash
cat prompt_02.txt | claude-code
```

**Opcija 2 - VS Code Terminal (preporučeno):**
- Otvori terminal u VS Code (Ctrl + `)
- Kopiraj sadržaj prompt fajla
- Pošalji claude-code u chat

#### Nakon svakog prompta:

1. **Provjeri da kod kompajlira:**
```bash
flutter analyze
```

2. **Provjeri da nema grešaka:**
```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

3. **Commit promjene:**
```bash
git add .
git commit -m "Implement: [naziv prompta]"
git push origin main
```

---

### 10. TESTIRANJE TOKOM DEVELOPMENTA

#### Pokreni app na različitim platformama:

**Web (najbrže za testiranje):**
```bash
flutter run -d chrome
```

**Android emulator:**
```bash
flutter run -d android
```

**Windows desktop:**
```bash
flutter run -d windows
```

**iOS simulator (samo macOS):**
```bash
flutter run -d ios
```

#### Hot reload tokom development:
- Pritisnite `r` u terminalu za reload
- Pritisnite `R` za hot restart
- Pritisnite `q` za quit

---

### 11. BACKUP STRATEGIJA

#### Prije svake veće implementacije:

```bash
# Kreiraj backup branch
git checkout -b backup-before-prompt-XX
git push origin backup-before-prompt-XX

# Vrati se na main
git checkout main
```

#### Ako nešto pođe po zlu:

```bash
# Vrati se na prethodni commit
git reset --hard HEAD~1

# Ili vrati se na backup branch
git checkout backup-before-prompt-XX
```

---

## ✅ FINALNA CHECKLIST PRIJE IMPLEMENTACIJE

- [ ] Flutter SDK instaliran (3.24.0+)
- [ ] Dart SDK instaliran (3.5.0+)
- [ ] Git instaliran
- [ ] VS Code instaliran sa Flutter/Dart ekstenzijama
- [ ] `flutter doctor` ne pokazuje kritične greške
- [ ] Android Studio / Xcode instaliran (ako trebaš mobile development)
- [ ] Chrome instaliran (za web development)
- [ ] Supabase nalog kreiran i projekat setup
- [ ] Stripe nalog kreiran (test mode)
- [ ] GitHub repository kreiran
- [ ] Lokalni projekat povezan sa GitHub remote
- [ ] `.vscode/settings.json` kreiran
- [ ] `.gitignore` provjerio
- [ ] Sve 20 prompt fajlova spremno
- [ ] Backup strategija razumljena
- [ ] Redoslijed implementacije jasan

---

## 🚀 SPREMNI ZA IMPLEMENTACIJU!

Kada je sve ✓, možeš početi sa:

```bash
type prompt_02.txt | claude-code
```

**Sretno! 🎉**
