-- ============================================================================
-- MIGRATION: Initial Schema Setup
-- Created: 2025-01-16
-- Description: Create core tables for Rab Booking application
-- ============================================================================

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- For full-text search
CREATE EXTENSION IF NOT EXISTS "postgis"; -- For geospatial queries (optional, for future)

-- ============================================================================
-- 1. USERS TABLE (extends auth.users)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  first_name TEXT,
  last_name TEXT,
  phone TEXT,
  role TEXT NOT NULL DEFAULT 'guest' CHECK (role IN ('guest', 'owner', 'admin')),
  avatar_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE public.users IS 'User profiles extending Supabase auth.users';
COMMENT ON COLUMN public.users.role IS 'User role: guest (book properties), owner (list properties), admin (full access)';

-- ============================================================================
-- 2. PROPERTIES TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.properties (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  owner_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  location TEXT NOT NULL,
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),
  amenities TEXT[] DEFAULT '{}',
  images TEXT[] DEFAULT '{}',
  cover_image TEXT,
  rating DECIMAL(3, 2) DEFAULT 0.0 CHECK (rating >= 0 AND rating <= 5),
  review_count INTEGER DEFAULT 0 CHECK (review_count >= 0),
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE public.properties IS 'Vacation rental properties on Island Rab';
COMMENT ON COLUMN public.properties.amenities IS 'Array of amenity codes (wifi, parking, pool, etc.)';
COMMENT ON COLUMN public.properties.rating IS 'Average rating 0-5 stars';

-- ============================================================================
-- 3. UNITS TABLE (bookable units within properties)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.units (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  property_id UUID NOT NULL REFERENCES public.properties(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  price_per_night DECIMAL(10, 2) NOT NULL CHECK (price_per_night > 0),
  max_guests INTEGER NOT NULL DEFAULT 2 CHECK (max_guests > 0),
  bedrooms INTEGER DEFAULT 1 CHECK (bedrooms >= 0),
  bathrooms INTEGER DEFAULT 1 CHECK (bathrooms >= 0),
  area_sqm DECIMAL(10, 2),
  images TEXT[] DEFAULT '{}',
  is_available BOOLEAN NOT NULL DEFAULT true,
  min_stay_nights INTEGER DEFAULT 1 CHECK (min_stay_nights > 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE public.units IS 'Bookable accommodation units (apartments, rooms, etc.)';
COMMENT ON COLUMN public.units.min_stay_nights IS 'Minimum booking duration in nights';

-- ============================================================================
-- 4. BOOKINGS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.bookings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  unit_id UUID NOT NULL REFERENCES public.units(id) ON DELETE CASCADE,
  guest_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  check_in DATE NOT NULL,
  check_out DATE NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'cancelled', 'completed')),
  total_price DECIMAL(10, 2) NOT NULL CHECK (total_price >= 0),
  paid_amount DECIMAL(10, 2) NOT NULL DEFAULT 0.0 CHECK (paid_amount >= 0),
  guest_count INTEGER NOT NULL DEFAULT 1 CHECK (guest_count > 0),
  notes TEXT,
  payment_intent_id TEXT, -- Stripe payment intent ID
  cancellation_reason TEXT,
  cancelled_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- Constraints
  CONSTRAINT valid_booking_dates CHECK (check_out > check_in),
  CONSTRAINT valid_payment CHECK (paid_amount <= total_price)
);

COMMENT ON TABLE public.bookings IS 'Guest reservations for accommodation units';
COMMENT ON COLUMN public.bookings.paid_amount IS 'Amount paid so far (typically 20% advance)';
COMMENT ON COLUMN public.bookings.total_price IS 'Total booking cost (price_per_night * nights)';

-- ============================================================================
-- 5. PAYMENTS TABLE (optional - for detailed payment tracking)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.payments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  booking_id UUID NOT NULL REFERENCES public.bookings(id) ON DELETE CASCADE,
  amount DECIMAL(10, 2) NOT NULL CHECK (amount > 0),
  currency TEXT NOT NULL DEFAULT 'EUR',
  payment_type TEXT NOT NULL CHECK (payment_type IN ('advance', 'full', 'remaining')),
  payment_method TEXT CHECK (payment_method IN ('card', 'bank_transfer', 'cash')),
  stripe_payment_intent_id TEXT,
  stripe_charge_id TEXT,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'succeeded', 'failed', 'refunded')),
  paid_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE public.payments IS 'Payment transaction records for bookings';
COMMENT ON COLUMN public.payments.payment_type IS 'advance (20%), full (100%), remaining (80%)';

-- ============================================================================
-- 6. INDEXES FOR PERFORMANCE
-- ============================================================================

-- Users indexes
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON public.users(role);

-- Properties indexes
CREATE INDEX IF NOT EXISTS idx_properties_owner_id ON public.properties(owner_id);
CREATE INDEX IF NOT EXISTS idx_properties_location ON public.properties USING GIN (to_tsvector('english', location));
CREATE INDEX IF NOT EXISTS idx_properties_active ON public.properties(is_active);
CREATE INDEX IF NOT EXISTS idx_properties_rating ON public.properties(rating DESC);
CREATE INDEX IF NOT EXISTS idx_properties_coords ON public.properties(latitude, longitude) WHERE latitude IS NOT NULL AND longitude IS NOT NULL;

-- Full-text search index
CREATE INDEX IF NOT EXISTS idx_properties_search ON public.properties
  USING GIN (to_tsvector('english', name || ' ' || COALESCE(description, '') || ' ' || location));

-- Units indexes
CREATE INDEX IF NOT EXISTS idx_units_property_id ON public.units(property_id);
CREATE INDEX IF NOT EXISTS idx_units_available ON public.units(is_available);
CREATE INDEX IF NOT EXISTS idx_units_price ON public.units(price_per_night);

-- Bookings indexes (critical for availability queries)
CREATE INDEX IF NOT EXISTS idx_bookings_unit_id ON public.bookings(unit_id);
CREATE INDEX IF NOT EXISTS idx_bookings_guest_id ON public.bookings(guest_id);
CREATE INDEX IF NOT EXISTS idx_bookings_status ON public.bookings(status);
CREATE INDEX IF NOT EXISTS idx_bookings_check_in ON public.bookings(check_in);
CREATE INDEX IF NOT EXISTS idx_bookings_check_out ON public.bookings(check_out);

-- Composite index for availability queries (most important!)
CREATE INDEX IF NOT EXISTS idx_bookings_availability
  ON public.bookings(unit_id, status, check_in, check_out)
  WHERE status IN ('confirmed', 'pending');

-- Payments indexes
CREATE INDEX IF NOT EXISTS idx_payments_booking_id ON public.payments(booking_id);
CREATE INDEX IF NOT EXISTS idx_payments_status ON public.payments(status);
CREATE INDEX IF NOT EXISTS idx_payments_stripe_intent ON public.payments(stripe_payment_intent_id) WHERE stripe_payment_intent_id IS NOT NULL;
