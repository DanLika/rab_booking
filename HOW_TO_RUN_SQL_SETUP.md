# How to Run Supabase SQL Setup

## 📋 Brze Upute

Imate SQL skriptu spremnu: `supabase_initial_setup.sql`

Evo kako da je pokrenete:

---

## Metoda 1: Supabase SQL Editor (PREPORUČENO)

### Korak 1: Otvori SQL Editor

1. Idi na: https://supabase.com/dashboard/project/fnfapeopfnkzkkwobhij
2. U lijevom sidebar-u klikni: **SQL Editor** (⚡ ikona)

### Korak 2: Kopiraj SQL Skriptu

1. Otvori file: `C:\Users\W10\dusko1\rab_booking\supabase_initial_setup.sql`
2. **Selektuj SVE** (Ctrl+A)
3. **Kopiraj** (Ctrl+C)

### Korak 3: Paste i Run

1. U Supabase SQL Editor klikni **"New query"**
2. **Paste** SQL skriptu (Ctrl+V)
3. Klikni **"Run"** (ili Ctrl+Enter)

### Korak 4: Čekaj...

- Skripta će se izvršiti **1-2 minute**
- Vidjećeš output u donjem dijelu ekrana
- Na kraju bi trebalo da vidiš tablicu sa brojem tabela

### Korak 5: Verify

U output-u bi trebalo da vidiš:

```
tablename    | schemaname
-------------|------------
bookings     | public
payments     | public
properties   | public
units        | public
users        | public
```

✅ **Ako vidiš ove tabele → USPJEŠNO!**

---

## Metoda 2: Supabase CLI (Alternativno)

Ako imate Supabase CLI instaliran:

```bash
cd C:\Users\W10\dusko1\rab_booking

# Link to remote project
supabase link --project-ref fnfapeopfnkzkkwobhij

# Run migrations
supabase db push
```

---

## Šta Skripta Radi?

1. ✅ Kreira **5 tabela**: users, properties, units, bookings, payments
2. ✅ Postavlja **RLS policies** (Row Level Security)
3. ✅ Kreira **indexes** za brže upite
4. ✅ Dodaje **triggers** za auto-update timestamp-a
5. ✅ Kreira **functions** za:
   - Provjeru dostupnosti unit-a
   - Kalkulaciju cijene bookinga
6. ✅ Omogućava **Realtime subscriptions**

---

## Verify Setup

Nakon što pokrenete skriptu, provjerite:

### 1. Table Editor

1. U Supabase Dashboard → **Table Editor**
2. Trebalo bi da vidite 5 tabela:
   - `users`
   - `properties`
   - `units`
   - `bookings`
   - `payments`

### 2. Database Schema

Klikni na svaku tabelu i provjeri kolone:

**users:**
- id, email, name, phone, role, avatar_url, created_at, updated_at

**properties:**
- id, owner_id, name, description, location, price_per_night, images, amenities, status, ...

**units:**
- id, property_id, name, price_per_night, max_guests, ...

**bookings:**
- id, unit_id, property_id, guest_id, check_in, check_out, total_price, status, ...

**payments:**
- id, booking_id, amount, currency, payment_type, status, stripe_payment_intent_id, ...

---

## Troubleshooting

### Problem: "permission denied for schema public"

**Rješenje:**
```sql
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO authenticated;
```

### Problem: "relation already exists"

**Rješenje:** Tabele već postoje. Ili:
1. Drop i ponovo kreiraj
2. Ili preskoči taj dio

### Problem: "syntax error"

**Rješenje:** Provjerite da ste kopirali cijelu skriptu bez modifikacije.

---

## Nakon Setup-a

✅ Kada završite, javite mi i možemo:

1. **Kreirati Storage bucket** za slike
2. **Testirati konekciju** iz Flutter app-a
3. **Kreirati test podatke** (sample properties)
4. **Krenuti sa Prompt 02**!

---

**Sretno! 🚀**
