# Android USB Debugging Setup Guide

> **Vodič za povezivanje Android telefona sa računarom radi live testiranja aplikacije.**

---

## 📋 Table of Contents

1. [Omogući Developer Options](#1-omogući-developer-options)
2. [Omogući USB Debugging](#2-omogući-usb-debugging)
3. [Poveži Telefon sa Računarom](#3-poveži-telefon-sa-računarom)
4. [Verify Connection](#4-verify-connection)
5. [Run App na Telefonu](#5-run-app-na-telefonu)
6. [Live Reload (Hot Reload)](#6-live-reload-hot-reload)
7. [Troubleshooting](#7-troubleshooting)

---

## 1. Omogući Developer Options

### Za većinu Android telefona:

1. **Otvori Settings** (Postavke)
2. **Scroll down** do **"About phone"** ili **"O telefonu"**
3. **Tap 7 puta** na **"Build number"** ili **"Broj verzije"**
4. Vidjećeš poruku: _"You are now a developer!"_ ili _"Sada ste programer!"_

### Alternativni putevi (zavisno od proizvodjača):

**Samsung:**
- Settings → About phone → Software information → Build number (tap 7x)

**Xiaomi/Redmi (MIUI):**
- Settings → About phone → MIUI version (tap 7x)

**Huawei:**
- Settings → About phone → Build number (tap 7x)

**OnePlus:**
- Settings → About phone → Build number (tap 7x)

---

## 2. Omogući USB Debugging

1. **Vrati se u Settings** (Postavke)
2. **Scroll down** i pronađi **"Developer options"** ili **"Opcije za programere"**
   - Obično je u **System → Advanced → Developer options**
3. **Omogući Developer Options** (toggle na ON)
4. **Pronađi i omogući:**
   - ✅ **"USB debugging"** → ON
   - ✅ **"Install via USB"** → ON (ako postoji)
   - ✅ **"USB debugging (Security settings)"** → ON (ako postoji)

5. **Optional (preporučeno za brži development):**
   - ✅ **"Stay awake"** → ON (ekran neće gasiti dok je na punjenju)
   - ✅ **"Select USB Configuration"** → **"MTP (Media Transfer Protocol)"**

---

## 3. Poveži Telefon sa Računarom

### Korak 3.1: USB Kabel

1. **Koristi originalni USB kabel** (ako imaš) - neki kabli samo pune, ne prenose podatke
2. **Poveži telefon** sa računarom

### Korak 3.2: Odaberi USB Mode

Kada povežeš telefon, pojavljuje se notifikacija:

1. **Tap na notifikaciju** "USB charging this device"
2. **Odaberi:** **"File Transfer / Android Auto"** ili **"MTP"**
   - **NE birај** "Charging only"

### Korak 3.3: Prihvati USB Debugging Dialog

Na telefonu će se pojaviti dialog:

```
Allow USB debugging?
The computer's RSA key fingerprint is:
XX:XX:XX:XX...

[ ] Always allow from this computer
[Cancel] [OK]
```

1. **✅ Štikliraj** "Always allow from this computer"
2. **Tap "OK"**

---

## 4. Verify Connection

### Korak 4.1: Provjerи da Windows vidi telefon

**Otvori Windows Explorer:**
- Trebalo bi da vidiš svoj telefon kao uređaj (npr. "Samsung Galaxy A52")

### Korak 4.2: Provjerи da Flutter vidi telefon

**Otvori Command Prompt ili PowerShell:**

```bash
cd C:\Users\W10\dusko1\rab_booking

flutter devices
```

**Trebalo bi da vidiš:**

```
3 devices connected:

SM G991B (mobile)        • 1234567890ABCDEF • android-arm64 • Android 13 (API 33)
Chrome (web)             • chrome           • web-javascript • Google Chrome 120.0
Windows (desktop)        • windows          • windows-x64    • Microsoft Windows 10
```

**Tvoj telefon** će biti prikazan sa:
- Naziv modela (npr. "SM G991B")
- Serial number (npr. "1234567890ABCDEF")
- Platform: **android-arm64**
- Android verzija

✅ **Ako vidiš svoj telefon → USPJEŠNO POVEZANO!**

---

## 5. Run App na Telefonu

### Korak 5.1: Run from Command Line

```bash
cd C:\Users\W10\dusko1\rab_booking

# Run app na telefonu
flutter run

# Ili specifično na Android (ako imaš više uređaja)
flutter run -d android
```

### Korak 5.2: Run from VS Code

1. **Otvori VS Code**
2. **Otvori projekat:** `C:\Users\W10\dusko1\rab_booking`
3. **U donjem desnom uglu** klikni na **"No Device Selected"**
4. **Odaberi svoj telefon** iz liste (npr. "SM G991B")
5. **Pritisni F5** ili klikni **"Run → Start Debugging"**

### Korak 5.3: Šta će se desiti

1. **Flutter će build-ovati app** (prvi put 2-3 minute)
2. **Install će APK na telefon**
3. **App će se automatski pokrenuti**
4. **Console će prikazati logs**

---

## 6. Live Reload (Hot Reload)

### 🔥 Hot Reload - INSTANT Promjene

Dok app radi na telefonu:

1. **Promijeni bilo šta u kodu** (npr. promijeni tekst, boju)
2. **Pritisni `r` u terminalu** ili **Command/Ctrl + S** u VS Code
3. **Promjene će se INSTANT prikazati** na telefonu (< 1 sekunda)

**Primjer:**

```dart
// lib/main.dart
Text('Hello World')  // Promijeni ovo
Text('Bok, Rab!') // U ovo

// Pritisni 'r' → Instant update na telefonu!
```

### 🔁 Hot Restart - Full Restart

Ako hot reload ne radi (npr. promijenio si model class):

1. **Pritisni `R` (veliko R) u terminalu**
2. **Ili Command/Ctrl + Shift + F5** u VS Code

### ⛔ Stop App

- **Pritisni `q` u terminalu** da zaustavi app

---

## 7. Troubleshooting

### Problem 1: "No devices found"

**Rješenje:**

```bash
# 1. Provjerи USB Debugging je enabled
# 2. Disconnect i reconnect USB kabel
# 3. Restart adb server

flutter doctor

# Ako ne radi, restart adb:
adb kill-server
adb start-server
adb devices
```

### Problem 2: "Unauthorized device"

**Rješenje:**

1. **Disconnect USB kabel**
2. Na telefonu: Developer Options → **"Revoke USB debugging authorizations"**
3. **Reconnect USB kabel**
4. **Prihvati ponovo** USB debugging dialog

### Problem 3: "Device offline"

**Rješenje:**

```bash
adb kill-server
adb start-server
adb devices
```

### Problem 4: Telefon se ne pojavljuje u flutter devices

**Provjeri:**

1. ✅ USB Debugging enabled?
2. ✅ USB mode = "File Transfer" ili "MTP"?
3. ✅ USB debugging dialog prihvaćen?
4. ✅ USB kabel radi? (probaj drugi)
5. ✅ USB port radi? (probaj drugi)

**Install Google USB Driver (ako Windows ne vidi telefon):**

```bash
# Otvori Android Studio
# Tools → SDK Manager → SDK Tools tab
# ✅ Štikliraj "Google USB Driver"
# Klikni "Apply"
```

### Problem 5: "Waiting for another flutter command to release the startup lock"

**Rješenje:**

```bash
# Delete lock file
del C:\Users\W10\AppData\Local\Temp\flutter_tools_*\flutter_tool.lock
```

### Problem 6: Build Failed - "Gradle task assembleDebug failed"

**Rješenje:**

```bash
cd android
.\gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

---

## 8. Android Device Requirements

### Minimum Requirements:

- **Android verzija:** 5.0 (API 21) ili novija
- **RAM:** 2GB+ (preporučeno 4GB+)
- **Storage:** 100MB+ slobodnog prostora
- **USB Debugging:** Mora biti omogućen

### Supported Phones (testovano):

✅ Samsung (Galaxy S, A, Note serije)
✅ Xiaomi/Redmi (MIUI)
✅ OnePlus
✅ Google Pixel
✅ Huawei (stariji modeli sa Google Play)
✅ Motorola
✅ Nokia
✅ Oppo/Realme

---

## 9. Multiple Devices

Ako imaš više uređaja povezanih (telefon + emulator):

```bash
# List all devices
flutter devices

# Run on specific device
flutter run -d 1234567890ABCDEF  # Serial number

# Run on Android (bilo koji Android device)
flutter run -d android

# Run on Windows
flutter run -d windows

# Run on Chrome
flutter run -d chrome
```

---

## 10. Performance Tips

### Za brži development:

1. **Stay Awake**: Developer Options → Stay awake → ON
2. **Disable Animations**: Developer Options → Window/Transition/Animator scale → 0.5x ili OFF
3. **Use Profile Mode** za testiranje performance:
   ```bash
   flutter run --profile
   ```

4. **Enable Dart DevTools:**
   ```bash
   flutter run
   # U terminalu će biti link: "Dart DevTools at http://127.0.0.1:9100"
   # Otvori u browser-u
   ```

---

## 11. Wireless Debugging (Android 11+)

Ako ne želiš kabel:

1. **Poveži telefon i računar na isti WiFi**
2. **Developer Options → Wireless debugging → ON**
3. **Tap "Pair device with pairing code"**
4. **U računaru:**
   ```bash
   adb pair 192.168.1.100:12345
   # Unesi pairing code sa telefona

   adb connect 192.168.1.100:12345
   flutter devices
   ```

---

## 12. Screen Mirroring (Optional)

Za prezentacije ili demo:

**scrcpy** - besplatan tool za screen mirroring:

```bash
# Download: https://github.com/Genymobile/scrcpy/releases
# Extract i pokreni:
scrcpy.exe

# Telefon ekran će biti prikazan na računaru!
```

---

## ✅ CHECKLIST - Da li si spreman?

- [ ] Developer Options enabled na telefonu
- [ ] USB Debugging enabled
- [ ] Telefon povezan USB kablom
- [ ] USB mode = "File Transfer" ili "MTP"
- [ ] USB debugging dialog prihvaćen ("Always allow")
- [ ] `flutter devices` pokazuje tvoj telefon
- [ ] `flutter run` uspješno instališe app

**Kada je sve ✅ → Spreman si za live testiranje! 🚀**

---

**Autor:** Claude Code
**Datum:** 2025-10-16
**Status:** Ready for USB debugging
