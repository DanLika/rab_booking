# 🗄️ SUPABASE MIGRATION GUIDE

**Verzija:** 1.0
**Datum:** 24. Oktobar 2025
**Migration File:** `supabase/migrations/20251024_mvp_saas_schema.sql`

---

## 📋 ŠTA ĆEMO URADITI

Ova migracija transformiše Supabase bazu podataka iz **AirBnb kopije** u **multi-tenant SaaS booking platformu**.

### Promjene:

1. ✅ **Kreiramo nove tabele:**
   - `units` - smještajne jedinice (apartmani/sobe)
   - `daily_prices` - cijene po danima
   - `blocked_dates` - blokirani datumi
   - `payment_info` - podaci za uplatu (IBAN)

2. ✅ **Update-ujemo postojeće tabele:**
   - `properties` - dodajemo `owner_id` (multi-tenant!)
   - `bookings` - dodajemo `unit_id`, `advance_amount`, `payment_status`, `source`

3. ✅ **Brišemo nepotrebne tabele:**
   - `favorites`, `reviews`, `saved_searches`, etc.

4. ✅ **Postavljamo RLS policies:**
   - Multi-tenant security (owner vidi samo svoje podatke)
   - Public može vidjeti active units (za embed widget)
   - Public može kreirati booking-e

5. ✅ **Helper funkcije:**
   - `get_unit_calendar_data()` - za Grid Calendar Widget

---

## 🚀 KORAK PO KORAK - IZVRŠAVANJE MIGRACIJE

### **KORAK 1: Otvori Supabase Dashboard**

1. Idi na [https://supabase.com/dashboard](https://supabase.com/dashboard)
2. Odaberi svoj projekat (rab-booking)
3. U lijevom menu-u klikni na **SQL Editor**

---

### **KORAK 2: Kreiraj novu Query**

1. Klikni na **New Query** dugme (+ icon)
2. Nazovi ga: `MVP SaaS Migration`

---

### **KORAK 3: Copy-Paste SQL kod**

1. Otvori fajl: `supabase/migrations/20251024_mvp_saas_schema.sql`
2. **Select All** (Ctrl+A) i **Copy** (Ctrl+C)
3. **Paste** (Ctrl+V) u Supabase SQL Editor

---

### **KORAK 4: PRIJE izvršavanja - BACKUP!**

⚠️ **VAŽNO:** Prije izvršavanja migracije, napravi backup podataka!

Ako imaš postojeće podatke u bazama, exportuj ih:

1. U Supabase Dashboard → **Database** → **Tables**
2. Za svaku tabelu sa važnim podacima:
   - Klikni na tabelu → **Download CSV**
3. Sačuvaj CSV fajlove na lokalni disk

---

### **KORAK 5: Izvršavanje Migracije**

1. U SQL Editor-u, **klikni na RUN** (play icon) ili pritisni **Ctrl+Enter**
2. Sacekaj dok se ne izvrsi (može trajati 10-30 sekundi)
3. Trebao bi vidjeti:
   - ✅ "Success. No rows returned"
   - Ili listu tabela na kraju (units, daily_prices, blocked_dates, payment_info)

---

### **KORAK 6: Verifikacija**

Provjeri da li su tabele kreirane:

1. U lijevom menu-u klikni na **Table Editor**
2. Trebao bi vidjeti nove tabele:
   - ✅ `units`
   - ✅ `daily_prices`
   - ✅ `blocked_dates`
   - ✅ `payment_info`

3. Provjeri postojeće tabele:
   - ✅ `properties` - trebale bi imati novi column `owner_id`
   - ✅ `bookings` - trebale bi imati nove columns: `unit_id`, `advance_amount`, `payment_status`, `source`

---

### **KORAK 7: Postavi owner_id za postojeće properties (Ako ih imaš)**

Ako imaš postojeće properties u bazi, moraš da postaviš `owner_id`:

```sql
-- Get your user ID
SELECT id FROM auth.users WHERE email = 'tvoj-email@example.com';

-- Update properties sa tvojim user ID-jem
UPDATE properties
SET owner_id = 'paste-user-id-here'
WHERE owner_id IS NULL;
```

Run ovaj SQL u SQL Editor-u.

---

### **KORAK 8: Test RLS Policies**

Testiraj da li Row Level Security radi:

```sql
-- Test 1: Try to insert property with different owner_id (should fail)
INSERT INTO properties (owner_id, name) VALUES
('00000000-0000-0000-0000-000000000000', 'Test Property');
-- Expected: ERROR: new row violates row-level security policy

-- Test 2: Insert property with your own user ID (should succeed)
INSERT INTO properties (owner_id, name) VALUES
((SELECT auth.uid()), 'My Test Property');
-- Expected: Success
```

---

### **KORAK 9: (Opcionalno) Insert Sample Data**

Za testiranje, možeš insertovati sample podatke:

```sql
-- Get your user ID
DO $$
DECLARE
  my_user_id UUID := (SELECT id FROM auth.users LIMIT 1);
  my_property_id UUID := uuid_generate_v4();
BEGIN
  -- Create sample property
  INSERT INTO properties (id, owner_id, name, city, country) VALUES
  (my_property_id, my_user_id, 'Villa Marina', 'Rab', 'Croatia');

  -- Create sample units
  INSERT INTO units (property_id, name, max_guests, base_price) VALUES
  (my_property_id, 'Apartman 1', 4, 80.00),
  (my_property_id, 'Apartman 2', 2, 60.00),
  (my_property_id, 'Apartman 3', 6, 100.00);

  -- Create sample blocked dates
  INSERT INTO blocked_dates (unit_id, blocked_from, blocked_to, reason)
  SELECT id, '2025-11-01'::DATE, '2025-11-07'::DATE, 'maintenance'
  FROM units WHERE name = 'Apartman 1' LIMIT 1;

  -- Create sample daily prices (premium dates)
  INSERT INTO daily_prices (unit_id, date, price)
  SELECT id, '2025-12-24'::DATE, 150.00
  FROM units WHERE name = 'Apartman 1'
  UNION ALL
  SELECT id, '2025-12-25'::DATE, 150.00
  FROM units WHERE name = 'Apartman 1'
  UNION ALL
  SELECT id, '2025-12-31'::DATE, 200.00
  FROM units WHERE name = 'Apartman 1';

  RAISE NOTICE 'Sample data inserted successfully!';
END $$;
```

---

### **KORAK 10: Test Calendar Function**

Testiraj helper funkciju za kalendar:

```sql
-- Get sample unit ID
SELECT id FROM units LIMIT 1;

-- Test get_unit_calendar_data function
SELECT * FROM get_unit_calendar_data(
  'paste-unit-id-here'::UUID,
  '2025-11-01'::DATE
);

-- Expected: Lista dana za November 2025 sa status (available/booked/blocked) i cijenama
```

---

## ✅ SUCCESS CRITERIA

Migracija je uspješna kada:

1. ✅ Sve nove tabele su kreirane (`units`, `daily_prices`, `blocked_dates`, `payment_info`)
2. ✅ `properties` ima `owner_id` column
3. ✅ `bookings` ima nove columns (`unit_id`, `advance_amount`, `payment_status`, `source`)
4. ✅ RLS policies rade (ne možeš insertovati property sa tuđim owner_id)
5. ✅ `get_unit_calendar_data()` funkcija vraća podatke

---

## ⚠️ TROUBLESHOOTING

### Problem 1: "column owner_id already exists"

**Uzrok:** Migracija je već izvršena prije.

**Rješenje:**
- Provjeri da li kolone već postoje
- Možeš skip-ovati ALTER TABLE komande koje failuju

### Problem 2: "foreign key violation"

**Uzrok:** Pokušavaš insertovati unit sa nepostojećim property_id.

**Rješenje:**
```sql
-- Check existing properties
SELECT id, name FROM properties;

-- Use existing property_id when inserting unit
```

### Problem 3: "RLS policy prevents action"

**Uzrok:** Row Level Security blokira akciju.

**Rješenje:**
- Provjeri da li koristiš pravi user ID
- Za testing, možeš privremeno disable-ovati RLS:
```sql
ALTER TABLE properties DISABLE ROW LEVEL SECURITY;
-- Do your testing
ALTER TABLE properties ENABLE ROW LEVEL SECURITY;
```

---

## 🔄 ROLLBACK (Ako nešto pođe po zlu)

Ako želiš vratiti promjene:

```sql
-- Drop new tables
DROP TABLE IF EXISTS units CASCADE;
DROP TABLE IF EXISTS daily_prices CASCADE;
DROP TABLE IF EXISTS blocked_dates CASCADE;
DROP TABLE IF EXISTS payment_info CASCADE;

-- Remove added columns
ALTER TABLE properties DROP COLUMN IF EXISTS owner_id;
ALTER TABLE properties DROP COLUMN IF EXISTS is_active;

ALTER TABLE bookings DROP COLUMN IF EXISTS unit_id;
ALTER TABLE bookings DROP COLUMN IF EXISTS advance_amount;
ALTER TABLE bookings DROP COLUMN IF EXISTS payment_status;
ALTER TABLE bookings DROP COLUMN IF EXISTS source;

-- Re-add property_id to bookings (if needed)
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS property_id UUID;
```

---

## 📞 SLJEDEĆI KORACI

Nakon uspješne migracije:

1. ✅ Commit migration file u Git
2. ✅ Update Flutter modeli (Unit, DailyPrice, BlockedDate, PaymentInfo)
3. ✅ Kreirati Dart repositories
4. ✅ Nastaviti sa FAZA 3: Refactor Auth

---

**Dokument kreirao:** Claude Code AI
**Datum:** 24. Oktobar 2025
