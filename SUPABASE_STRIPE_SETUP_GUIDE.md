# Supabase & Stripe Setup Guide

> **Vodič za kreiranje Supabase projekta i Stripe test naloga prije implementacije aplikacije.**

---

## 📋 Table of Contents

1. [Supabase Setup](#1-supabase-setup)
2. [Stripe Setup](#2-stripe-setup)
3. [Credentials Storage](#3-credentials-storage)
4. [Verify Setup](#4-verify-setup)

---

## 1. SUPABASE SETUP

### Korak 1.1: Kreiranje Naloga

1. **Idi na:** https://supabase.com
2. Klikni **"Start your project"** ili **"Sign In"**
3. Odaberi **"Sign up with GitHub"** (preporučeno) ili email

### Korak 1.2: Kreiranje Projekta

1. Nakon logina, klikni **"New Project"**

2. **Popuni podatke:**
   - **Organization:** Ako je novi nalog, klikni "New organization"
     - Organization name: `DanLika` (ili kako želiš)
     - Pricing Plan: **Free** (0$/mjesec)

   - **Project name:** `rab-booking-dev`
   - **Database Password:**
     - Generiši jak password (npr. `RabBooking2025!SecureDB`)
     - **⚠️ SAČUVAJ OVO!** Trebaće ti kasnije

   - **Region:** `Central EU (Frankfurt)` - najbliži Hrvatskoj

   - **Pricing plan:** Free ($0/month)
     - 500MB database
     - 1GB file storage
     - 2GB bandwidth
     - 50MB database size
     - **Dovoljno za development!**

3. Klikni **"Create new project"**

4. **Čekaj 1-2 minute** dok se projekat setup-uje

### Korak 1.3: Kopiraj Credentials

Kada je projekat spreman:

1. Klikni na **Settings** (⚙️ ikona u lijevom sidebar-u)

2. Idi na **API** tab

3. **Kopiraj ove podatke** (trebaće mi ih kasnije):

```
📋 SUPABASE CREDENTIALS (KOPIRAJ OVO):

Project URL: https://[your-project-ref].supabase.co
API Key (anon/public): eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6...
Service Role Key: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6... (SECRET!)
Database Password: [password koji ste kreirali gore]
```

**⚠️ VAŽNO:**
- **anon key** - koristi se u Flutter app-u (public)
- **service_role key** - koristi se za admin operacije (ČUVAJ SIGURNO, NIKAD NE COMMIT-uj)

### Korak 1.4: Instaliraj Supabase CLI (Optional - za kasnije)

```bash
# Windows (PowerShell)
scoop install supabase

# Ili npm
npm install -g supabase

# Provjeri instalaciju
supabase --version
```

### Korak 1.5: Enable Email Authentication

1. U Supabase dashboard → **Authentication** → **Providers**
2. **Email** provider već enabled ✓
3. Scroll down do **Email Templates**
4. Provjeri da su templates ok (možeš customizovati kasnije)

---

## 2. STRIPE SETUP

### Korak 2.1: Kreiranje Naloga

1. **Idi na:** https://stripe.com
2. Klikni **"Sign up"** ili **"Start now"**
3. Popuni:
   - Email: [tvoj email]
   - Full name: [tvoje ime]
   - Country: **Croatia** (ili gdje si)
   - Password: [jak password]

4. Verifikuj email (klikni link u email-u)

### Korak 2.2: Prebaci u Test Mode

1. U Stripe Dashboard, **gornji desni ugao**
2. **Toggle switch:** "Test mode" → **ON** 🟢
3. Vidjećeš "Viewing test data" banner

### Korak 2.3: Kopiraj API Keys

1. U Stripe Dashboard → **Developers** → **API keys**

2. **Kopiraj ove podatke** (trebaće mi ih kasnije):

```
📋 STRIPE CREDENTIALS (KOPIRAJ OVO):

Publishable key: pk_test_51...
Secret key: sk_test_51... (SECRET!)
```

**⚠️ VAŽNO:**
- **Publishable key (pk_test_...)** - koristi se u Flutter app-u (public)
- **Secret key (sk_test_...)** - koristi se u backend funkcijama (ČUVAJ SIGURNO)

### Korak 2.4: Test Card Numbers (za testiranje)

Stripe test mode ima test kartice:

| Kartica | Broj | CVC | Datum | Rezultat |
|---------|------|-----|-------|----------|
| **Success** | 4242 4242 4242 4242 | 123 | 12/34 | ✅ Uspješno plaćanje |
| **Decline** | 4000 0000 0000 0002 | 123 | 12/34 | ❌ Declined |
| **3D Secure** | 4000 0027 6000 3184 | 123 | 12/34 | 🔐 Zahtijeva autentifikaciju |

### Korak 2.5: Webhook Setup (za kasnije)

**Za sada preskoči** - setupovaćemo kada budemo deploy-ali Edge Functions u Supabase.

Kada budemo spremni:
1. Developers → **Webhooks** → **Add endpoint**
2. Endpoint URL: `https://[supabase-project].supabase.co/functions/v1/stripe-webhook`
3. Events: `payment_intent.succeeded`, `payment_intent.payment_failed`

---

## 3. CREDENTIALS STORAGE

### Korak 3.1: Kreiraj `.env` File

**⚠️ OVO JE NAJVAŽNIJI DIO!**

U root folderu projekta (`C:\Users\W10\dusko1\rab_booking\`), kreiraj fajl:

**`.env.development`** (za development)

```env
# Supabase
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SUPABASE_SERVICE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# Stripe
STRIPE_PUBLISHABLE_KEY=pk_test_51...
STRIPE_SECRET_KEY=sk_test_51...

# Environment
ENV=development
```

**⚠️ ZAMIJENI** `xxxxx` i `...` sa pravim vrijednostima koje si kopirao gore!

### Korak 3.2: Verify `.gitignore`

Provjeri da `.gitignore` sadrži:

```gitignore
# Environment variables - NIKAD NE COMMIT-uj!
.env
.env.*
.env.local
.env.development
.env.production
.env.staging
```

### Korak 3.3: Pošalji Mi Credentials (SIGURNO)

**🔐 NAČIN 1: Kopiraj u chat (siguran način):**

Pošalji mi ovaj format:

```
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbG...
SUPABASE_SERVICE_KEY=eyJhbG... (ne moraš za sada)
STRIPE_PUBLISHABLE_KEY=pk_test_51...
STRIPE_SECRET_KEY=sk_test_51... (ne moraš za sada)
```

**🔐 NAČIN 2: Screenshot:**

Napravi screenshot Supabase API settings i Stripe API keys, i upload-uj u chat.

---

## 4. VERIFY SETUP

### Korak 4.1: Test Supabase Connection

U Supabase Dashboard:

1. **SQL Editor** (lijevi sidebar)
2. Klikni **"New query"**
3. Unesi:

```sql
-- Test query
SELECT version();
```

4. Klikni **"Run"** (ili Ctrl+Enter)
5. Trebao bi vidjeti PostgreSQL verziju ✓

### Korak 4.2: Test Stripe Dashboard

1. U Stripe Dashboard → **Payments** → **All payments**
2. Trebalo bi biti prazno (još nema plaćanja)
3. Status: "Viewing test data" ✓

---

## 5. ŠTA DALJE?

✅ Kada završiš gore korake, **pošalji mi**:

1. ✅ **Supabase Project URL** (npr. `https://xxxxx.supabase.co`)
2. ✅ **Supabase Anon Key** (počinje sa `eyJhbG...`)
3. ✅ **Stripe Publishable Key** (počinje sa `pk_test_...`)

**NE TREBAŠ slati:**
- ❌ Service Role Key (za sada)
- ❌ Stripe Secret Key (za sada)

### Ja ću tada:

1. ✅ Kreirati automatizovanu setup skriptu
2. ✅ Setupovati Supabase database schema (tabele, RLS policies)
3. ✅ Kreirati Stripe Edge Function u Supabase-u
4. ✅ Testirati konekciju
5. ✅ Krenuti sa **prompt_02** implementacijom!

---

## 6. FAQ

### Q: Koliko košta Supabase Free tier?
**A:** $0/mjesec! 500MB database, 1GB storage, 2GB bandwidth. Dovoljno za 1-2 godine development-a.

### Q: Šta kada prerastem Free tier?
**A:** Upgrade na Pro tier ($25/mjesec) sa 8GB database i 100GB bandwidth.

### Q: Da li Stripe test mode naplaćuje?
**A:** **NE!** Test mode je potpuno besplatan. Sve transakcije su fake.

### Q: Kada trebam production Stripe nalog?
**A:** Tek kada budeš spreman da prihvataš prava plaćanja. Moraš verifikovati business (dostava dokumentacije).

### Q: Da li mogu promijeniti Database Password kasnije?
**A:** Da, u Supabase Settings → Database → Reset Password.

### Q: Šta ako zaboravim credentials?
**A:** Uvijek možeš ih vidjeti u Supabase/Stripe dashboard-u (Settings → API).

---

## 7. SECURITY BEST PRACTICES

✅ **URADI:**
- ✅ Koristi `.env` file za credentials
- ✅ Dodaj `.env*` u `.gitignore`
- ✅ Koristi različite keys za dev/staging/prod
- ✅ Rotate keys svaka 3-6 mjeseci

❌ **NE RADI:**
- ❌ NIKAD ne commit-uj `.env` file
- ❌ NIKAD ne dijeliš service_role ili secret keys javno
- ❌ NIKAD ne stavi credentials direktno u kod
- ❌ NIKAD ne upload-uj keys na public GitHub repo

---

**🚀 Kada završiš sve gore, javi mi i krećemo sa implementacijom!**

**Autor:** Claude Code
**Datum:** 2025-10-16
**Status:** Ready for setup
