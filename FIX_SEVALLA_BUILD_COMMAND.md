# ⚠️ FIX: Sevalla Build Command - HITNO!

**Problem**: Build command je još uvek `flutter build web --release` umesto `npm run build`

**Tvoj log pokazuje**:
```
Build Command: flutter build web --release  ← POGREŠNO!
```

**Trebalo bi**:
```
Build Command: npm run build  ← ISPRAVNO!
```

---

## 🔧 KAKO DA PROMENIŠ (Korak-po-Korak)

### Metoda 1: Kroz Sevalla Web Interface

#### Korak 1: Login na Sevalla
```
URL: https://sevalla.com
Login sa svojim nalogom
```

#### Korak 2: Pronađi Projekat
```
Dashboard → Pronađi: rabbooking-gui6m
Klikni na projekat da ga otvoriš
```

#### Korak 3: Otvori Settings
```
U projekat meniju, klikni:
⚙️ Settings (ili Configuration, ili Build Settings)
```

Možeš videti tab-ove:
- General
- **Build & Deploy** ← OVAJ!
- Environment Variables
- Domains
- etc.

#### Korak 4: Pronađi Build Configuration

Trebalo bi da vidiš formu sa poljima:

```
┌─────────────────────────────────────────┐
│ Framework Detection:                    │
│ ○ Auto-detect                          │
│ ○ Static Site                          │
│ ● Custom ← izaberi ovo!               │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│ Build Command:                          │
│ ┌─────────────────────────────────────┐│
│ │ flutter build web --release ← OBRIŠI││
│ └─────────────────────────────────────┘│
└─────────────────────────────────────────┘

PROMENI U:

┌─────────────────────────────────────────┐
│ Build Command:                          │
│ ┌─────────────────────────────────────┐│
│ │ npm run build        ← UNESI OVO!  ││
│ └─────────────────────────────────────┘│
└─────────────────────────────────────────┘
```

#### Korak 5: Proveri Ostale Settings

**Install Command**:
```
npm install  ← Ostavi ovako (default)
```

**Output Directory** (ili **Publish Directory**):
```
build/web  ← VAŽNO!
```

**Node Version**:
```
20.x  ← ili 20 (mora biti set!)
```

**Root Directory**:
```
/  ← ili prazno
```

#### Korak 6: Save i Redeploy

1. **Klikni** "Save" ili "Update Settings"
2. **Idi na** Deployments tab
3. **Klikni** "Redeploy" ili "Trigger New Deployment"
4. **Prati** build log

---

## 🎯 ŠTA ĆE SE DESITI NAKON PROMENE

### Stari Build Process (NE RADI):
```
1. npm install
   ✓ Instalira npm dependencies (nema ih)
   ✓ Pokreće postinstall: flutter pub get
2. flutter build web --release  ← FAILA jer flutter nije instaliran!
   ❌ flutter: command not found
```

### Novi Build Process (RADI):
```
1. npm install
   ✓ Instalira npm dependencies (nema ih)
   ✓ Pokreće postinstall: flutter pub get
2. npm run build  ← Poziva script iz package.json
   ✓ package.json script: "build": "flutter build web --release"
   ✓ Flutter build se pokreće
   ✓ Generiše build/web/
3. Deploy build/web/ → Live site
   ✓ https://rabbooking-gui6m.sevalla.page
```

---

## ⚠️ VAŽNO: Flutter SDK Problem

**Problem**: Sevalla možda **NEMA Flutter SDK** instaliran!

Ako i nakon promene build command-a vidiš error:
```
flutter: command not found
```

**Rešenje**: Dodaj Flutter installation script

### Opcija A: Inline Flutter Install (u Build Command)

Promeni Build Command u:

```bash
curl -O https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.0-stable.tar.xz && tar xf flutter_linux_3.24.0-stable.tar.xz && export PATH="$PATH:`pwd`/flutter/bin" && flutter --version && flutter pub get && flutter build web --release
```

**OVO JE DUGAČKO, ali radi!**

### Opcija B: Kreiraj build.sh Script

**1. Kreiraj fajl `build.sh` u root-u projekta:**

```bash
#!/bin/bash
set -e

echo "📦 Installing Flutter SDK..."
if ! command -v flutter &> /dev/null; then
  curl -O https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.0-stable.tar.xz
  tar xf flutter_linux_3.24.0-stable.tar.xz
  export PATH="$PATH:`pwd`/flutter/bin"
fi

echo "✓ Flutter version:"
flutter --version

echo "📦 Installing dependencies..."
flutter pub get

echo "🔨 Building for web..."
flutter build web --release

echo "✅ Build complete!"
```

**2. Napravi executable:**
```bash
chmod +x build.sh
```

**3. U package.json, promeni build script:**
```json
{
  "scripts": {
    "build": "./build.sh"
  }
}
```

**4. Commit i push:**
```bash
git add build.sh package.json
git commit -m "feat: Add build script with Flutter SDK installation"
git push origin main
```

**5. U Sevalla, build command ostaje:**
```
npm run build
```

---

## 🚀 ALTERNATIVA: Netlify (100% Flutter Support)

Ako Sevalla i dalje ima problema, **Netlify automatski podržava Flutter**!

### Netlify Setup (5 minuta):

1. **Idi na**: https://netlify.com
2. **Sign up** sa GitHub nalogom
3. **New site from Git**
4. **Select repository**: `DanLika/rab_booking`
5. **Build settings**:
   ```
   Build command:    flutter build web --release
   Publish directory: build/web
   ```
6. **Deploy**

**Netlify automatski instalira Flutter SDK** - nema problema!

**Besplatno** za static sites!

---

## 📊 Comparison: Sevalla vs Netlify

| Feature | Sevalla | Netlify |
|---------|---------|---------|
| **Flutter Support** | Manual (needs setup) | ✅ Automatic |
| **Build Time** | 5-10 min (if works) | 3-5 min |
| **Free Tier** | Yes | ✅ Yes (better) |
| **Custom Domain** | Yes | ✅ Yes (easier) |
| **SSL** | Yes | ✅ Yes (auto) |
| **Git Integration** | Yes | ✅ Yes (smoother) |
| **Recommendation** | If you get it working | ⭐ **Easier!** |

---

## 🎯 MOJA PREPORUKA

### Plan A: Probaj da Fixuješ Sevalla (30 min)

1. ✅ Promeni build command u `npm run build`
2. ✅ Redeploy
3. ❓ Ako error: "flutter: command not found"
   - Koristi Opciju B (kreiraj `build.sh` sa Flutter install)

### Plan B: Prebaci na Netlify (15 min) ⭐ PREPORUČUJEM

1. ✅ Netlify ima built-in Flutter support
2. ✅ Zero configuration needed
3. ✅ Brži deployment
4. ✅ Besplatan

**Netlify je LAKŠI za Flutter projekte!**

---

## 📝 Quick Commands za Build.sh Pristup

Ako hoćeš Opciju B (build.sh):

```bash
# Kreiraj build.sh
cat > build.sh << 'EOF'
#!/bin/bash
set -e

echo "📦 Installing Flutter SDK..."
if ! command -v flutter &> /dev/null; then
  curl -O https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.0-stable.tar.xz
  tar xf flutter_linux_3.24.0-stable.tar.xz
  export PATH="$PATH:`pwd`/flutter/bin"
fi

flutter --version
flutter pub get
flutter build web --release
echo "✅ Build complete!"
EOF

# Make executable
chmod +x build.sh

# Update package.json
# (manually edit or use this)
# "build": "./build.sh"

# Commit
git add build.sh package.json
git commit -m "feat: Add Flutter SDK installation in build script"
git push origin main
```

Zatim u Sevalla:
- Build command: `npm run build` (ostaje isto)
- Redeploy

---

## ✅ Finalni Checklist

- [ ] Promeni build command u Sevalla → `npm run build`
- [ ] Redeploy
- [ ] Ako error "flutter: command not found" → Kreiraj `build.sh`
- [ ] Ili razmisli o prebacivanju na **Netlify** (lakše!)

---

## 🆘 Javi Mi Rezultat

Nakon što promeniš build command i redeploy-uješ:

1. **Copy-paste ceo build log** (iz Sevalla)
2. **Reci mi koji error vidiš** (ako ima)
3. **Da li želiš da probam Netlify pristup?** (mogu da ti dam tačne korake)

---

**SLEDEĆI KORAK**: Promeni build command u `npm run build` i redeploy!

Ako ne radi posle toga, probamo Netlify koji 100% radi sa Flutter! 🚀
