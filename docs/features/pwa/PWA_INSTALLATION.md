# 📱 PWA Instalacija - Uputstva za korisnike

BooBed aplikacija je dostupna kao **Progressive Web App (PWA)**, što znači da je možete instalirati na svoj telefon ili tablet i koristiti je kao običnu aplikaciju.

## ✅ Prednosti PWA instalacije

- ✅ **Radi offline** - osnovne funkcionalnosti rade i bez interneta
- ✅ **Brže učitavanje** - aplikacija se cache-uje lokalno
- ✅ **Izgleda kao native app** - ikona na home screen-u
- ✅ **Automatski update** - nova verzija se preuzima automatski
- ✅ **Google i Apple Sign-In rade normalno** - sve autentifikacije funkcioniraju

---

## 📲 Kako instalirati na Android (Chrome)

1. Otvori aplikaciju u **Chrome browseru** (ne Firefox ili drugi)
2. Klikni na **menu ikonu** (tri tačke ⋮) u gornjem desnom uglu
3. Izaberi **"Install app"** ili **"Add to Home Screen"**
4. Potvrdi instalaciju
5. Aplikacija će se pojaviti na home screen-u sa BooBed ikonom

**Alternativno:**
- Chrome će automatski prikazati banner "Install BooBed" kada otvoriš aplikaciju
- Klikni na "Install" u banneru

---

## 🍎 Kako instalirati na iPhone/iPad (Safari)

**VAŽNO:** Na iOS-u moraš koristiti **Safari** browser (ne Chrome)!

1. Otvori aplikaciju u **Safari browseru**
2. Klikni na **Share ikonu** (⬆️ strelica gore) na dnu ekrana
3. Skroluj dole i izaberi **"Add to Home Screen"**
4. Promijeni ime ako želiš (opcionalno)
5. Klikni **"Add"** u gornjem desnom uglu
6. Aplikacija će se pojaviti na home screen-u

**Napomena:** Na iOS-u aplikacija će se otvoriti u Safari-u, ali će izgledati kao standalone aplikacija (bez browser UI-a).

---

## 🖥️ Kako instalirati na Desktop (Chrome/Edge)

1. Otvori aplikaciju u **Chrome** ili **Microsoft Edge** browseru
2. Klikni na **instalacijsku ikonu** (➕) u address bar-u (desno od URL-a)
3. Ili klikni na **menu** (⋮) → **"Install BooBed"**
4. Potvrdi instalaciju
5. Aplikacija će se otvoriti u zasebnom prozoru bez browser UI-a

---

## 🔄 Kako ažurirati aplikaciju

Aplikacija se **automatski ažurira** kada postoji nova verzija. Ne moraš ništa raditi!

Ako želiš ručno provjeriti update:
- **Android:** Zatvori i ponovo otvori aplikaciju
- **iOS:** Zatvori aplikaciju iz switchera i ponovo je otvori
- **Desktop:** Zatvori aplikaciju i ponovo je otvori

---

## ❓ Često postavljana pitanja

### Da li će Google Sign-In raditi?
✅ **Da!** Google Sign-In radi potpuno normalno u PWA instalaciji.

### Da li će Apple Sign-In raditi?
✅ **Da!** Apple Sign-In radi normalno na iOS uređajima u PWA instalaciji.

### Da li će push notifikacije raditi?
⚠️ **Na iOS-u:** Push notifikacije rade tek od iOS 16.4+ u PWA aplikacijama.
✅ **Na Android-u:** Push notifikacije rade normalno.

### Da li će aplikacija raditi offline?
✅ **Djelomično** - osnovne funkcionalnosti (pregled rezervacija, cache-ovani podaci) rade offline. Za nove rezervacije ili sync podataka potreban je internet.

### Mogu li koristiti aplikaciju bez instalacije?
✅ **Da!** Možeš koristiti aplikaciju direktno u browseru bez instalacije. Instalacija je opcionalna i daje bolje performanse.

---

## 🐛 Rješavanje problema

### Ne vidim "Install" opciju
- **Android:** Provjeri da li koristiš Chrome browser
- **iOS:** Provjeri da li koristiš Safari browser (ne Chrome)
- Provjeri da li je aplikacija dostupna preko HTTPS (ne HTTP)

### Aplikacija se ne instalira
- Provjeri internet konekciju
- Pokušaj ponovo nakon nekoliko sekundi
- Očisti cache browsera i pokušaj ponovo

### Aplikacija ne radi offline
- Provjeri da li je service worker aktivan (Chrome DevTools → Application → Service Workers)
- Pokušaj ponovno instalirati aplikaciju

---

## 📞 Podrška

Ako imaš problema sa instalacijom ili korištenjem PWA aplikacije, kontaktiraj nas na support@bookbed.io

