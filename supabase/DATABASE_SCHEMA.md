# Database Schema - Rab Booking

## Entity Relationship Diagram (ERD)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           RAB BOOKING DATABASE SCHEMA                        │
└─────────────────────────────────────────────────────────────────────────────┘

┌──────────────────────┐
│   auth.users         │  (Supabase Auth - managed by Supabase)
│──────────────────────│
│ id (UUID) PK         │
│ email                │
│ encrypted_password   │
│ email_confirmed_at   │
│ raw_user_meta_data   │
│ created_at           │
└──────────────────────┘
          │
          │ 1:1 (auto-created via trigger)
          │
          ▼
┌──────────────────────┐
│   public.users       │  (User Profiles)
│──────────────────────│
│ id (UUID) PK ────────┼──> references auth.users(id) ON DELETE CASCADE
│ email ✓              │
│ first_name           │
│ last_name            │
│ phone_number         │
│ avatar_url           │
│ role ✓               │  guest | owner | admin
│ is_active ✓          │
│ created_at ✓         │
│ updated_at ✓         │
└──────────────────────┘
          │
          │ 1:N (owner_id)
          ▼
┌──────────────────────┐
│  public.properties   │  (Vacation Properties)
│──────────────────────│
│ id (UUID) PK         │
│ owner_id (UUID) ─────┼──> references public.users(id) ON DELETE CASCADE
│ name ✓               │
│ description          │
│ location ✓           │
│ latitude             │  DECIMAL(10, 8)
│ longitude            │  DECIMAL(11, 8)
│ amenities            │  TEXT[] (wifi, parking, pool, etc.)
│ images               │  TEXT[] (URLs)
│ cover_image          │
│ rating               │  DECIMAL(3, 2) DEFAULT 0.0
│ review_count         │  DEFAULT 0
│ is_active ✓          │
│ created_at ✓         │
│ updated_at ✓         │
└──────────────────────┘
          │
          │ 1:N (property_id)
          ▼
┌──────────────────────┐
│    public.units      │  (Bookable Units)
│──────────────────────│
│ id (UUID) PK         │
│ property_id (UUID) ──┼──> references public.properties(id) ON DELETE CASCADE
│ name ✓               │
│ description          │
│ price_per_night ✓    │  DECIMAL(10, 2) > 0
│ max_guests ✓         │  DEFAULT 2
│ bedrooms             │
│ bathrooms            │
│ area_sqm             │
│ images               │  TEXT[]
│ is_available ✓       │
│ min_stay_nights      │  DEFAULT 1
│ created_at ✓         │
│ updated_at ✓         │
└──────────────────────┘
          │
          │ 1:N (unit_id)
          ▼
┌──────────────────────┐                    ┌──────────────────────┐
│  public.bookings     │  (Reservations)    │   public.users       │
│──────────────────────│                    │  (guest)             │
│ id (UUID) PK         │                    └──────────────────────┘
│ unit_id (UUID) ──────┼──> references public.units(id)                 ▲
│ guest_id (UUID) ─────┼────────────────────────────────────────────────┘
│ check_in ✓           │  DATE              references public.users(id)
│ check_out ✓          │  DATE
│ status ✓             │  pending | confirmed | cancelled | completed
│ total_price ✓        │  DECIMAL(10, 2)
│ paid_amount ✓        │  DECIMAL(10, 2) DEFAULT 0.0
│ guest_count ✓        │
│ notes                │
│ created_at ✓         │
│ updated_at ✓         │
│ CHECK: check_out > check_in
└──────────────────────┘
          │
          │ 1:N (booking_id)
          ▼
┌──────────────────────┐
│  public.payments     │  (Payment Transactions)
│──────────────────────│
│ id (UUID) PK         │
│ booking_id (UUID) ───┼──> references public.bookings(id) ON DELETE CASCADE
│ amount ✓             │  DECIMAL(10, 2)
│ currency ✓           │  DEFAULT 'EUR'
│ payment_type ✓       │  advance | balance | full | refund
│ payment_method       │  card | bank_transfer | cash
│ stripe_payment_intent_id
│ status ✓             │  pending | processing | succeeded | failed | cancelled
│ paid_at              │
│ created_at ✓         │
│ updated_at ✓         │
└──────────────────────┘


════════════════════════════════════════════════════════════════════════════════
STORAGE BUCKETS
════════════════════════════════════════════════════════════════════════════════

storage.buckets:
├── property-images/
│   └── {owner-uuid}/
│       ├── {property-uuid}/
│       │   ├── cover.jpg
│       │   ├── photo1.jpg
│       │   └── photo2.jpg
│       └── {unit-uuid}/
│           └── photo1.jpg
│
└── avatars/
    └── {user-uuid}/
        └── avatar.jpg

```

---

## Table Relationships

### 1. Users → Properties (1:N)
- **Relationship**: One user (owner) can have multiple properties
- **Foreign Key**: `properties.owner_id` → `users.id`
- **Cascade**: ON DELETE CASCADE (if owner deleted, all properties deleted)
- **RLS**: Owners can only CRUD their own properties

### 2. Properties → Units (1:N)
- **Relationship**: One property can have multiple bookable units
- **Foreign Key**: `units.property_id` → `properties.id`
- **Cascade**: ON DELETE CASCADE (if property deleted, all units deleted)
- **RLS**: Property owners can manage units

### 3. Units → Bookings (1:N)
- **Relationship**: One unit can have multiple bookings (at different times)
- **Foreign Key**: `bookings.unit_id` → `units.id`
- **Cascade**: ON DELETE CASCADE (if unit deleted, bookings deleted)
- **Validation**: Trigger prevents overlapping confirmed/pending bookings

### 4. Users → Bookings (1:N)
- **Relationship**: One user (guest) can have multiple bookings
- **Foreign Key**: `bookings.guest_id` → `users.id`
- **Cascade**: ON DELETE CASCADE (if guest deleted, bookings deleted)
- **RLS**: Guests can only view/manage their own bookings

### 5. Bookings → Payments (1:N)
- **Relationship**: One booking can have multiple payment transactions
- **Foreign Key**: `payments.booking_id` → `bookings.id`
- **Cascade**: ON DELETE CASCADE (if booking deleted, payments deleted)
- **Business Rule**: First payment is 20% advance, final payment is balance

---

## Key Constraints & Business Rules

### Bookings
```sql
-- Date validation
CHECK (check_out > check_in)

-- Availability validation (via trigger)
TRIGGER validate_booking_before_insert
  - Checks no overlapping confirmed/pending bookings
  - Validates guest_count <= unit.max_guests
  - Validates nights >= unit.min_stay_nights
  - Auto-calculates total_price if NULL
```

### Units
```sql
-- Price validation
CHECK (price_per_night > 0)
```

### Payments
```sql
-- Valid payment types
payment_type: advance | balance | full | refund

-- Valid payment statuses
status: pending | processing | succeeded | failed | cancelled
```

---

## Indexes (Performance Optimization)

### Critical Indexes

```sql
-- Fast booking availability queries
CREATE INDEX idx_bookings_availability
  ON public.bookings(unit_id, status, check_in, check_out)
  WHERE status IN ('confirmed', 'pending');

-- Property search by location
CREATE INDEX idx_properties_location
  ON public.properties USING gin(to_tsvector('english', location));

-- Property search by name/description
CREATE INDEX idx_properties_search
  ON public.properties USING gin(
    to_tsvector('english', name || ' ' || COALESCE(description, ''))
  );

-- Owner's properties lookup
CREATE INDEX idx_properties_owner
  ON public.properties(owner_id)
  WHERE is_active = true;

-- Guest's bookings lookup
CREATE INDEX idx_bookings_guest
  ON public.bookings(guest_id, status, check_in DESC);

-- Unit's bookings lookup
CREATE INDEX idx_bookings_unit
  ON public.bookings(unit_id, status, check_in);

-- Booking payments lookup
CREATE INDEX idx_payments_booking
  ON public.payments(booking_id, status);
```

---

## Database Functions

### 1. Availability Checking
```sql
public.is_unit_available(unit_id, check_in, check_out, exclude_booking_id)
→ BOOLEAN
```
Returns TRUE if unit is available for given date range.

### 2. Price Calculation
```sql
public.calculate_booking_price(unit_id, check_in, check_out)
→ DECIMAL(10, 2)
```
Calculates total price: (check_out - check_in) * price_per_night

```sql
public.calculate_advance_payment(total_price)
→ DECIMAL(10, 2)
```
Returns 20% of total_price (advance payment amount).

### 3. Search & Queries
```sql
public.search_properties(query_text)
→ SETOF properties
```
Full-text search across name, description, location.

```sql
public.get_property_bookings(property_id)
→ SETOF bookings
```
Returns all bookings for a property (for owner dashboard).

```sql
public.get_owner_bookings(owner_id)
→ SETOF bookings
```
Returns all bookings for all properties owned by user.

---

## Triggers

### 1. Auto-update Timestamp
```sql
TRIGGER set_updated_at BEFORE UPDATE
→ Automatically sets updated_at = NOW()
```
Applied to: users, properties, units, bookings, payments

### 2. Booking Validation
```sql
TRIGGER validate_booking_before_insert/update
→ Validates dates, guest count, minimum stay, availability
→ Auto-calculates total_price
```

### 3. Auto-create User Profile
```sql
TRIGGER on_auth_user_created AFTER INSERT ON auth.users
→ Automatically creates public.users profile
→ Sets role from metadata or defaults to 'guest'
```

---

## Row Level Security (RLS) Summary

### Users Table
- ✅ Users can SELECT/UPDATE their own profile
- ✅ Admins can SELECT all users

### Properties Table
- ✅ Anyone can SELECT active properties
- ✅ Owners can SELECT/INSERT/UPDATE/DELETE their own properties
- ✅ Admins have full access

### Units Table
- ✅ Anyone can SELECT units of active properties
- ✅ Property owners can CRUD units of their properties

### Bookings Table
- ✅ Guests can SELECT their own bookings
- ✅ Property owners can SELECT bookings for their units
- ✅ Guests can INSERT bookings for themselves
- ✅ Guests can UPDATE their pending bookings
- ✅ Property owners can UPDATE bookings for their properties
- ✅ Admins have full access

### Payments Table
- ✅ Guests can SELECT payments for their bookings
- ✅ Property owners can SELECT payments for their properties
- ✅ System (service role) can INSERT payments
- ✅ Admins have full access

---

## Realtime Subscriptions

Enabled for:
- ✅ `bookings` - Owners see new bookings instantly
- ✅ `payments` - Payment status updates in real-time
- ✅ `properties` - Property updates sync across clients
- ✅ `units` - Availability changes update live

---

## Data Flow Examples

### Example 1: Guest Creates Booking

```
1. Guest fills booking form (unit, dates, guest count)
2. Frontend calls: calculate_booking_price(unit_id, check_in, check_out)
3. Frontend displays: "Total: €700 | Advance (20%): €140"
4. Guest proceeds to Stripe payment
5. Stripe processes €140 advance payment
6. Frontend inserts booking:
   INSERT INTO bookings (unit_id, guest_id, check_in, check_out, total_price, paid_amount)
   VALUES (unit_id, auth.uid(), check_in, check_out, 700, 140)
7. TRIGGER validate_booking runs:
   - Checks dates valid ✓
   - Checks guest_count <= max_guests ✓
   - Checks nights >= min_stay_nights ✓
   - Calls is_unit_available() ✓
   - Returns NEW (booking saved)
8. TRIGGER set_updated_at sets created_at/updated_at
9. RLS policy bookings_insert_guest allows (auth.uid() = guest_id) ✓
10. Booking saved with status='pending'
11. Edge Function inserts payment record
12. Owner receives realtime notification via supabase.from('bookings').stream()
```

### Example 2: Owner Views Bookings

```
1. Owner opens dashboard
2. Frontend calls: get_owner_bookings(owner_id)
3. Function returns all bookings joined with units/properties
4. RLS policy bookings_select_property_owner allows access ✓
5. Frontend displays bookings grouped by property
6. Owner subscribes to realtime:
   supabase.from('bookings').stream().listen()
7. New booking arrives → UI updates instantly
```

### Example 3: Search Properties

```
1. Guest types "beach villa rab"
2. Frontend calls: search_properties('beach villa rab')
3. Function uses full-text search (GIN index)
4. Returns active properties matching query
5. RLS policy properties_select_active allows ✓
6. Frontend displays results sorted by rating
```

---

## Storage Structure

### Property Images
```
property-images/{owner-uuid}/{property-uuid}/cover.jpg
property-images/{owner-uuid}/{property-uuid}/photo1.jpg
property-images/{owner-uuid}/{unit-uuid}/photo1.jpg
```

**RLS Policies:**
- Anyone can SELECT (public bucket)
- Only authenticated users can INSERT
- Only file owner can UPDATE/DELETE (checks folder name matches auth.uid())

### User Avatars
```
avatars/{user-uuid}/avatar.jpg
```

**RLS Policies:**
- Anyone can SELECT (public bucket)
- Users can INSERT/UPDATE/DELETE only their own avatar

---

## Migration History

| Migration | Description |
|-----------|-------------|
| 20250116000001 | Initial schema (tables, indexes) |
| 20250116000002 | Row Level Security policies |
| 20250116000003 | Functions, triggers, business logic |
| 20250116000004 | Realtime subscriptions, storage buckets |

---

## Future Enhancements (Planned)

### Phase 2
- [ ] `reviews` table (guest reviews for properties)
- [ ] `favorites` table (saved properties)
- [ ] `messages` table (guest-owner communication)
- [ ] `notifications` table (booking alerts, reminders)

### Phase 3
- [ ] `pricing_rules` table (seasonal pricing, discounts)
- [ ] `availability_rules` table (blocked dates, special availability)
- [ ] `property_features` table (detailed amenities)

---

## Backup & Recovery

### Automated Backups (Supabase)
- Daily automated backups (last 7 days)
- Point-in-time recovery available

### Manual Backup
```bash
# Dump schema + data
pg_dump -h db.fnfapeopfnkzkkwobhij.supabase.co \
  -U postgres \
  -d postgres \
  --clean --if-exists \
  > backup_$(date +%Y%m%d).sql

# Restore
psql -h db.fnfapeopfnkzkkwobhij.supabase.co \
  -U postgres \
  -d postgres \
  < backup_20250116.sql
```

---

## Performance Monitoring Queries

### Table Sizes
```sql
SELECT
  schemaname,
  tablename,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

### Index Usage
```sql
SELECT
  schemaname,
  tablename,
  indexname,
  idx_scan AS index_scans,
  idx_tup_read AS tuples_read,
  idx_tup_fetch AS tuples_fetched
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
ORDER BY idx_scan DESC;
```

### Slow Queries (if pg_stat_statements enabled)
```sql
SELECT
  query,
  calls,
  mean_exec_time,
  total_exec_time
FROM pg_stat_statements
WHERE query NOT LIKE '%pg_stat_statements%'
ORDER BY mean_exec_time DESC
LIMIT 10;
```

---

## Security Best Practices

1. ✅ **RLS Enabled**: All tables have Row Level Security enabled
2. ✅ **Service Role Protection**: Payment creation restricted to service role
3. ✅ **Cascade Deletes**: Proper ON DELETE CASCADE for data integrity
4. ✅ **Validation Triggers**: Business rules enforced at database level
5. ✅ **No SQL Injection**: Using parameterized queries via Supabase client
6. ✅ **Storage RLS**: File uploads restricted by folder ownership
7. ✅ **Role-based Access**: guest, owner, admin roles with different permissions

---

## Additional Documentation

- **Full Setup Guide**: `supabase/README.md`
- **Seed Data**: `supabase/seed/seed_test_data.sql`
- **Migration Files**: `supabase/migrations/`
