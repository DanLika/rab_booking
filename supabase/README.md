# Supabase Database Setup
## Rab Booking - Database Migrations & Management

This folder contains all database migrations, seed data, and documentation for the Supabase backend.

---

## 📁 Folder Structure

```
supabase/
├── migrations/                    # SQL migration files
│   ├── 20250116000001_initial_schema.sql
│   ├── 20250116000002_row_level_security.sql
│   ├── 20250116000003_functions_and_triggers.sql
│   └── 20250116000004_realtime_and_storage.sql
├── seed/                          # Test/seed data
│   └── seed_test_data.sql
└── README.md                      # This file
```

---

## 🚀 Quick Start (Manual Setup)

### Option 1: Run via Supabase Dashboard (EASIEST)

1. **Go to SQL Editor**: https://supabase.com/dashboard/project/fnfapeopfnkzkkwobhij/sql

2. **Run migrations in order**:
   ```
   1. 20250116000001_initial_schema.sql
   2. 20250116000002_row_level_security.sql
   3. 20250116000003_functions_and_triggers.sql
   4. 20250116000004_realtime_and_storage.sql
   ```

3. **Create test users** (via Auth > Users):
   - Guest: test@example.com
   - Owner: owner@example.com
   - Admin: admin@example.com

4. **Run seed data** (optional):
   - Open `seed/seed_test_data.sql`
   - Replace `OWNER_UUID_HERE` and `GUEST_UUID_HERE` with real UUIDs from step 3
   - Run in SQL Editor

---

### Option 2: Use Supabase CLI (RECOMMENDED for production)

#### 1. Install Supabase CLI

**macOS/Linux:**
```bash
brew install supabase/tap/supabase
```

**Windows (Scoop):**
```powershell
scoop bucket add supabase https://github.com/supabase/scoop-bucket.git
scoop install supabase
```

**Windows (Manual):**
Download from: https://github.com/supabase/cli/releases

#### 2. Login to Supabase

```bash
supabase login
```

This will open a browser to authenticate.

#### 3. Link Local Project to Remote

```bash
cd C:\Users\W10\dusko1\rab_booking
supabase link --project-ref fnfapeopfnkzkkwobhij
```

Enter your database password when prompted: `RabBooking.db`

#### 4. Apply Migrations to Remote

```bash
supabase db push
```

This will apply all migrations in `supabase/migrations/` to your remote database.

#### 5. Verify Migrations

```bash
supabase db diff
```

Should show "No changes detected" if migrations were applied successfully.

---

## 🗄️ Database Schema

### Tables

| Table | Description | Key Features |
|-------|-------------|--------------|
| **users** | User profiles (extends auth.users) | Roles: guest, owner, admin |
| **properties** | Vacation rental properties | Location, amenities, rating |
| **units** | Bookable units within properties | Price, capacity, availability |
| **bookings** | Guest reservations | Dates, status, payment tracking |
| **payments** | Payment transactions | Stripe integration, 20% advance |

### Relationships

```
users (1) ──< properties (N)
properties (1) ──< units (N)
units (1) ──< bookings (N)
users (1) ──< bookings (N)
bookings (1) ──< payments (N)
```

---

## 🔐 Row Level Security (RLS)

All tables have RLS enabled with the following policies:

### Users
- ✅ Can view their own profile
- ✅ Can update their own profile
- ✅ Admins can view all users

### Properties
- ✅ Anyone can view active properties
- ✅ Owners can CRUD their own properties
- ✅ Admins have full access

### Units
- ✅ Anyone can view units of active properties
- ✅ Property owners can manage their units

### Bookings
- ✅ Guests can view/update their own bookings
- ✅ Property owners can view/update bookings for their properties
- ✅ Admins have full access

### Payments
- ✅ Users can view payments for their bookings
- ✅ Property owners can view payments for their properties
- ✅ System (service role) can create payments

---

## ⚡ Functions & Triggers

### Automatic Triggers

1. **Auto-update `updated_at`**: Automatically updates timestamp on row modification
2. **Auto-create user profile**: Creates user profile when auth user signs up
3. **Booking validation**: Validates dates, availability, guest count on insert/update

### Helper Functions

```sql
-- Check unit availability
SELECT public.is_unit_available(
  'unit-uuid',
  '2025-07-01'::DATE,
  '2025-07-07'::DATE
);

-- Calculate booking price
SELECT public.calculate_booking_price(
  'unit-uuid',
  '2025-07-01'::DATE,
  '2025-07-07'::DATE
);

-- Calculate advance payment (20%)
SELECT public.calculate_advance_payment(1000.00);
-- Returns: 200.00

-- Search properties
SELECT * FROM public.search_properties('beach villa rab');

-- Get property bookings (for owner)
SELECT * FROM public.get_property_bookings('property-uuid');

-- Get all owner bookings
SELECT * FROM public.get_owner_bookings('owner-uuid');
```

---

## 🌐 Realtime Subscriptions

Realtime is enabled for:
- ✅ `bookings` - New bookings appear instantly for owners
- ✅ `payments` - Payment status updates in real-time
- ✅ `properties` - Property updates sync across clients
- ✅ `units` - Availability changes update live

### Flutter Example

```dart
// Subscribe to user's bookings
supabase
  .from('bookings')
  .stream(primaryKey: ['id'])
  .eq('guest_id', userId)
  .listen((data) {
    // Update UI with new bookings
  });

// Subscribe to property bookings (owner)
final stream = supabase
  .rpc('get_owner_bookings', params: {'p_owner_id': ownerId})
  .asStream();
```

---

## 📦 Storage Buckets

### property-images
- **Purpose**: Property and unit photos
- **Access**: Public (anyone can view)
- **Upload**: Authenticated owners only
- **Size limit**: 10 MB per file
- **Formats**: JPEG, PNG, WebP

### avatars
- **Purpose**: User profile pictures
- **Access**: Public (anyone can view)
- **Upload**: Authenticated users (their own only)
- **Size limit**: 2 MB per file
- **Formats**: JPEG, PNG, WebP

### Folder Structure

```
property-images/
├── {owner-uuid}/
│   ├── {property-uuid}/
│   │   ├── cover.jpg
│   │   ├── photo1.jpg
│   │   └── photo2.jpg
│   └── {unit-uuid}/
│       └── photo1.jpg

avatars/
└── {user-uuid}/
    └── avatar.jpg
```

---

## 🧪 Testing

### 1. Run Seed Data

```bash
# Via CLI
supabase db reset --linked  # Resets database and applies migrations

# Via Dashboard
# Go to SQL Editor and run seed/seed_test_data.sql
```

**IMPORTANT**: Update UUIDs in seed file before running:
- Replace `OWNER_UUID_HERE` with owner user UUID
- Replace `GUEST_UUID_HERE` with guest user UUID

### 2. Test Queries

```sql
-- Test user creation
INSERT INTO auth.users (email, encrypted_password)
VALUES ('test@example.com', crypt('password123', gen_salt('bf')));
-- Should auto-create profile in public.users

-- Test property creation
INSERT INTO public.properties (owner_id, name, location, ...)
VALUES ('{your-uuid}', 'Test Property', 'Rab, Croatia', ...);

-- Test availability check
SELECT public.is_unit_available(
  '{unit-uuid}',
  CURRENT_DATE,
  CURRENT_DATE + 7
);

-- Test booking validation (should fail if dates overlap)
INSERT INTO public.bookings (unit_id, guest_id, check_in, check_out, ...)
VALUES ('{unit-uuid}', '{guest-uuid}', ..., ...);
```

### 3. Test RLS Policies

```sql
-- As guest (set auth.uid)
SET LOCAL role authenticated;
SET LOCAL request.jwt.claims TO '{"sub": "guest-uuid"}';

-- Try to view properties (should work)
SELECT * FROM public.properties WHERE is_active = true;

-- Try to update someone else's property (should fail)
UPDATE public.properties
SET name = 'Hacked'
WHERE owner_id != 'guest-uuid';
-- Error: new row violates row-level security policy
```

---

## 🔄 Migration Workflow

### Creating New Migrations

```bash
# Create a new migration
supabase migration new add_reviews_table

# Edit the file in supabase/migrations/
# Format: YYYYMMDDHHMMSS_description.sql
```

### Applying Migrations

```bash
# Apply to local database (for testing)
supabase db reset

# Apply to remote database (production)
supabase db push
```

### Rolling Back (if needed)

```bash
# Revert last migration
supabase migration repair --status reverted 20250116000004

# Reset entire database (CAREFUL!)
supabase db reset --linked
```

---

## 📊 Database Monitoring

### Via Supabase Dashboard

1. **Logs**: https://supabase.com/dashboard/project/fnfapeopfnkzkkwobhij/logs/postgres-logs
2. **Database Stats**: https://supabase.com/dashboard/project/fnfapeopfnkzkkwobhij/database/tables
3. **API Usage**: https://supabase.com/dashboard/project/fnfapeopfnkzkkwobhij/settings/api

### Via SQL

```sql
-- Table sizes
SELECT
  schemaname,
  tablename,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Row counts
SELECT
  'users' as table_name, COUNT(*) as rows FROM public.users
UNION ALL
SELECT 'properties', COUNT(*) FROM public.properties
UNION ALL
SELECT 'units', COUNT(*) FROM public.units
UNION ALL
SELECT 'bookings', COUNT(*) FROM public.bookings
UNION ALL
SELECT 'payments', COUNT(*) FROM public.payments;

-- Active connections
SELECT count(*) FROM pg_stat_activity;

-- Slow queries (if logging enabled)
SELECT query, mean_exec_time, calls
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 10;
```

---

## 🚨 Troubleshooting

### Error: "relation does not exist"
- Make sure migrations were applied in order
- Check migration status: `supabase migration list`

### Error: "permission denied for table"
- RLS policies might be blocking access
- Test with service role key (bypasses RLS)
- Check policy conditions

### Error: "duplicate key violates unique constraint"
- Seed data might have been run multiple times
- Reset database: `supabase db reset --linked`

### Can't connect to database
- Verify credentials in `.env.development`
- Check project is not paused (free tier)
- Test connection: `supabase db ping`

---

## 📚 Additional Resources

- **Supabase Docs**: https://supabase.com/docs
- **PostgreSQL Docs**: https://www.postgresql.org/docs/
- **RLS Guide**: https://supabase.com/docs/guides/auth/row-level-security
- **Realtime Guide**: https://supabase.com/docs/guides/realtime
- **Storage Guide**: https://supabase.com/docs/guides/storage

---

## 📝 Notes

- All migrations are idempotent (safe to run multiple times)
- Use `IF NOT EXISTS` and `ON CONFLICT DO NOTHING` for safety
- Always test migrations locally before applying to production
- Keep seed data separate from migrations
- Document schema changes in migration files
