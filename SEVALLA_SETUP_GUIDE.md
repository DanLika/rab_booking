# 🚀 Sevalla Setup Guide - Korak po Korak

**RAB Booking - Flutter Web Deployment**

---

## 📋 Preduslovi

Pre nego što počneš:

- ✅ Flutter web build završen (`build/web` folder postoji)
- ✅ Supabase account i project kreiran
- ✅ Stripe account (production keys)
- ✅ Sevalla account kreiran

---

## KORAK 1: Popuni Production Keys

### 1.1 Otvori `lib/core/config/web_config.dart`

### 1.2 Pronađi svoje Supabase keys

**Gdje**: https://app.supabase.com/project/_/settings/api

Kopiraj:
- **Project URL** → `supabaseUrl`
- **anon/public key** → `supabaseAnonKey`

### 1.3 Pronađi svoje Stripe keys

**Gdje**: https://dashboard.stripe.com/apikeys

⚠️ **VAŽNO**: Koristi **PRODUCTION** keys (pk_live_...), NE test keys (pk_test_...)!

Kopiraj:
- **Publishable key** → `stripePublishableKey`

### 1.4 Ažuriraj web_config.dart

```dart
class WebConfig {
  // ZAMENI OVE VREDNOSTI SA SVOJIM!
  static const String supabaseUrl = 'https://tvoja-project-id.supabase.co';
  static const String supabaseAnonKey = 'tvoj_anon_key_ovde';
  static const String stripePublishableKey = 'pk_live_tvoj_production_key';
}
```

### 1.5 Sačuvaj fajl

---

## KORAK 2: Rebuild Flutter Web

Sada kada si ažurirao keys, moraš ponovo da build-uješ aplikaciju:

```bash
flutter build web --release
```

⏱️ **Vreme**: ~3 minuta

---

## KORAK 3: Sevalla Git Deployment Setup

### 3.1 Push na GitHub (ako već nisi)

```bash
git add .
git commit -m "feat: Configure production keys for web deployment"
git push origin main
```

### 3.2 Login na Sevalla

Idi na: **https://sevalla.com**

### 3.3 Kreiraj New Site

1. Klikni **"Static Site Hosting"**
2. Klikni **"Create New Site"** ili **"New Project"**
3. Izaberi **"Import from Git"** (ili "Connect Git Repository")

### 3.4 Poveži GitHub

1. Klikni **"Connect GitHub"** (ili "Authorize")
2. Autorizuj Sevalla pristup GitHub-u
3. Izaberi repository: **`rab_booking`**
4. Izaberi branch: **`main`**

---

## KORAK 4: Configure Build Settings

**VAŽNO**: Tačno unesi ove vrednosti!

### Build Settings:

| Setting | Vrednost | Napomena |
|---------|----------|----------|
| **Build command** | `flutter build web --release` | Tačno kako je napisano |
| **Node version** | `20.x` | Obavezno! (ili 18.x) |
| **Root directory** | `/` | Samo slash ili ostavi prazno |
| **Publish directory** | `build/web` | Output folder |
| **Index file** | `index.html` | Default stranica |
| **Error file** | `index.html` | Za SPA routing |

### Screenshot primer:

```
┌─────────────────────────────────────────────┐
│ Build command:    flutter build web --release │
│ Node version:     20.x                        │
│ Root directory:   /                           │
│ Publish dir:      build/web                   │
│ Index file:       index.html                  │
│ Error file:       index.html                  │
└─────────────────────────────────────────────┘
```

---

## KORAK 5: Environment Variables

⚠️ **NAPOMENA**: Environment variables na Sevalla **NE RADE** za Flutter web runtime!

**Razlog**: Flutter web NE može čitati server-side environment variables tokom runtime-a.

**Rešenje**: Već smo rešili u Koraku 1 (hardkodovali smo keys u `web_config.dart`)

**Zbog toga PRESKOČI ovaj korak** - ne moraš unositi environment variables na Sevalla!

---

## KORAK 6: Deploy!

### 6.1 Klikni "Deploy" ili "Create Site"

Sevalla će sada:
1. Clone-ovati tvoj GitHub repo
2. Instalirati Flutter SDK
3. Pokrenuti `flutter build web --release`
4. Deploy-ovati build/web folder
5. Generisati HTTPS sertifikat

⏱️ **Vreme**: 5-10 minuta (prvi put)

### 6.2 Prati Build Log

Sevalla će prikazati live log. Traži:

✅ **SUCCESS:** `✓ Built build\web`

❌ **GREŠKA:** Ako vidiš error, proveri build settings (Node version!)

---

## KORAK 7: Configure Site Settings

Nakon uspešnog deploya:

### 7.1 Enable HTTPS

1. Idi na **Site Settings** → **SSL/TLS**
2. **Enable HTTPS**: ✅ ON
3. **Force HTTPS Redirect**: ✅ ON
4. Sačekaj 2-3 minuta za SSL sertifikat

### 7.2 Setup SPA Routing (KRITIČNO!)

**Zašto**: Flutter koristi client-side routing. Bez ovoga, direct URL-ovi (npr. `/property/123`) će prikazati 404.

**Kako**:

1. Idi na **Site Settings** → **Redirects** (ili **Rewrites**)
2. Dodaj redirect rule:

**Format 1 (ako Sevalla koristi Nginx)**:
```nginx
location / {
    try_files $uri $uri/ /index.html;
}
```

**Format 2 (ako Sevalla koristi custom redirects)**:
```
/*    /index.html    200
```

**Format 3 (ako Sevalla ima GUI)**:
- Source: `/*`
- Destination: `/index.html`
- Status: `200` (rewrite, ne redirect!)

### 7.3 Enable Caching (Optional, ali preporučeno)

**Assets Cache** (1 godina):
```
/assets/*       max-age=31536000, immutable
/canvaskit/*    max-age=31536000, immutable
/icons/*        max-age=31536000, immutable
*.js            max-age=31536000, immutable
```

**Index.html** (ne keširanje):
```
/index.html     no-cache, no-store, must-revalidate
```

---

## KORAK 8: Test Deployment

### 8.1 Otvori Site URL

Sevalla će ti dati URL: **`https://your-project.sevalla.app`**

### 8.2 Test Checklist

- [ ] **Homepage se učitava** (hero section, search bar)
- [ ] **Scroll animations rade** (featured properties fade-in)
- [ ] **Dark mode radi** (OLED black background)
- [ ] **Navigation radi** (svi menu items)
- [ ] **Direct URL access radi** (npr. direktno idi na /search - ne 404!)
- [ ] **Browser back/forward rade**
- [ ] **Supabase konekcija radi** (login/register funkcionalnost)
- [ ] **Stripe checkout se otvara** (ako imaš production keys)
- [ ] **Images se učitavaju**
- [ ] **Mobile responsive** (testiraj na telefonu)

### 8.3 Test SPA Routing

**VAŽAN TEST**: Otvori konzolu u browser-u (F12) i unesi:

```javascript
window.location.href = '/property/123';
```

**Očekivano**: Flutter app se učitava, NE 404 error!

Ako dobiješ 404 → vrati se na Korak 7.2 i dodaj redirect rule!

---

## KORAK 9: Custom Domain (Optional)

Ako imaš svoj domain (npr. `rab-booking.com`):

### 9.1 Dodaj Domain na Sevalla

1. **Site Settings** → **Domains**
2. Klikni **"Add Custom Domain"**
3. Unesi: `rab-booking.com` i `www.rab-booking.com`

### 9.2 Update DNS (na domain registrar-u)

**A Record** (root domain):
```
Type:  A
Name:  @
Value: [IP address iz Sevalla dashboard-a]
TTL:   3600
```

**CNAME Record** (www subdomain):
```
Type:  CNAME
Name:  www
Value: your-project.sevalla.app
TTL:   3600
```

### 9.3 Sačekaj DNS Propagation

⏱️ **Vreme**: 5-30 minuta (ponekad do 24h)

Proveri status: https://dnschecker.org

### 9.4 SSL za Custom Domain

Sevalla će automatski generisati Let's Encrypt SSL sertifikat nakon DNS propagation-a.

---

## KORAK 10: Auto-Deploy (Bonus)

Već imaš auto-deploy! 🎉

**Kako radi**:
1. Svaki put kada push-uješ na `main` branch
2. Sevalla automatski detektuje promene
3. Pokreće build i deploy

**Test**:
```bash
# Napravi malu izmenu
echo "# Test" >> README.md
git add README.md
git commit -m "test: Auto-deploy test"
git push origin main
```

Idi na Sevalla dashboard → vidi kako se build automatski pokreće!

---

## ✅ Gotovo!

Tvoja RAB Booking aplikacija je sada LIVE! 🎉

**URL**: https://your-project.sevalla.app (ili tvoj custom domain)

---

## 🐛 Troubleshooting

### Problem 1: Build Failed - "Node version required"

**Greška**: `Node version is required`

**Rešenje**: U build settings, dodaj:
```
Node version: 20.x
```

---

### Problem 2: 404 na Refresh

**Greška**: Kada refre

šujem stranicu `/property/123`, dobijem 404

**Rešenje**: Dodaj SPA redirect rule (Korak 7.2)

---

### Problem 3: "SUPABASE_URL is not set"

**Greška**: App se ne povezuje sa Supabase

**Rešenje**:
1. Proveri `lib/core/config/web_config.dart` - da li su keys popunjeni?
2. Da li si ponovo build-ovao aplikaciju? (`flutter build web --release`)
3. Da li si push-ovao na GitHub?

---

### Problem 4: Stripe Checkout ne radi

**Greška**: Stripe checkout ne otvara ili prikazuje error

**Rešenje**:
1. Proveri da koristiš **production** keys (`pk_live_...`), ne test (`pk_test_...`)
2. Dodaj tvoj Sevalla domain na Stripe dashboard whitelist:
   - Stripe Dashboard → Settings → Checkout settings
   - Dodaj: `https://your-project.sevalla.app`

---

### Problem 5: Assets ne učitavaju (images, fonts)

**Greška**: Slike ne prikazuju, fontovi ne rade

**Rešenje**:
1. Proveri da je Publish directory: `build/web` (ne `build` ili `web`)
2. Rebuild aplikaciju: `flutter build web --release`
3. Redeploy na Sevalla

---

### Problem 6: "Failed to load .env file"

**Greška**: Vidiš error u konzoli o .env fajlovima

**Rešenje**: Ovo je **normalno** za web builds! Flutter web ne koristi .env fajlove, koristi `web_config.dart`. Ignoriši ovu poruku.

---

## 📞 Kontakt & Support

### Sevalla Support
- **Email**: support@sevalla.com
- **Docs**: https://sevalla.com/docs
- **Forum**: https://forum.sevalla.com

### Supabase Support
- **Docs**: https://supabase.com/docs
- **Discord**: https://discord.supabase.com

### Stripe Support
- **Docs**: https://stripe.com/docs
- **Support**: https://support.stripe.com

---

## 📚 Related Documentation

- `SEVALLA_BUILD_COMPLETE.md` - Build status i detalji
- `SEVALLA_DEPLOYMENT_GUIDE.md` - Detaljno deployment uputstvo
- `lib/core/config/web_config.dart` - Production konfiguracija

---

## 🎯 Quick Reference Card

**Sevalla Build Settings** (štampaj i drži pored sebe):

```
┌─────────────────────────────────────────────┐
│ Build command:    flutter build web --release │
│ Node version:     20.x                        │
│ Root directory:   /                           │
│ Publish dir:      build/web                   │
│ Index file:       index.html                  │
│ Error file:       index.html                  │
│                                               │
│ SPA Redirect:     /*  →  /index.html  (200)   │
│ HTTPS:            ✅ Enabled                  │
│ Force HTTPS:      ✅ Enabled                  │
└─────────────────────────────────────────────┘
```

**Supabase Keys Location**:
```
https://app.supabase.com/project/_/settings/api
```

**Stripe Keys Location**:
```
https://dashboard.stripe.com/apikeys
```

---

**Deployment kreiran**: October 20, 2025
**Status**: ✅ Ready for production
**Framework**: Flutter 3.35.6
**Platform**: Sevalla Static Site Hosting

🚀 **Sretno sa deployment-om!**
