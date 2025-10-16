-- ============================================================================
-- MIGRATION: Functions & Triggers
-- Created: 2025-01-16
-- Description: Database functions, triggers, and business logic
-- ============================================================================

-- ============================================================================
-- 1. AUTO-UPDATE TIMESTAMP TRIGGER
-- ============================================================================

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION public.handle_updated_at() IS 'Automatically updates updated_at column on row modification';

-- Apply trigger to all tables with updated_at
CREATE TRIGGER set_updated_at
  BEFORE UPDATE ON public.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER set_updated_at
  BEFORE UPDATE ON public.properties
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER set_updated_at
  BEFORE UPDATE ON public.units
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER set_updated_at
  BEFORE UPDATE ON public.bookings
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER set_updated_at
  BEFORE UPDATE ON public.payments
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ============================================================================
-- 2. AVAILABILITY CHECKING FUNCTIONS
-- ============================================================================

-- Check if unit is available for given date range
CREATE OR REPLACE FUNCTION public.is_unit_available(
  p_unit_id UUID,
  p_check_in DATE,
  p_check_out DATE,
  p_exclude_booking_id UUID DEFAULT NULL
)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN NOT EXISTS (
    SELECT 1 FROM public.bookings
    WHERE unit_id = p_unit_id
    AND status IN ('confirmed', 'pending')
    AND (p_exclude_booking_id IS NULL OR id != p_exclude_booking_id)
    AND NOT (check_out <= p_check_in OR check_in >= p_check_out)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION public.is_unit_available IS 'Check if unit is available for booking in given date range';

-- Get overlapping bookings for a unit
CREATE OR REPLACE FUNCTION public.get_overlapping_bookings(
  p_unit_id UUID,
  p_check_in DATE,
  p_check_out DATE
)
RETURNS SETOF public.bookings AS $$
BEGIN
  RETURN QUERY
  SELECT * FROM public.bookings
  WHERE unit_id = p_unit_id
  AND status IN ('confirmed', 'pending')
  AND NOT (check_out <= p_check_in OR check_in >= p_check_out)
  ORDER BY check_in;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION public.get_overlapping_bookings IS 'Get all bookings that overlap with given date range';

-- ============================================================================
-- 3. BOOKING PRICE CALCULATION
-- ============================================================================

-- Calculate total price for a booking
CREATE OR REPLACE FUNCTION public.calculate_booking_price(
  p_unit_id UUID,
  p_check_in DATE,
  p_check_out DATE
)
RETURNS DECIMAL(10, 2) AS $$
DECLARE
  v_price_per_night DECIMAL(10, 2);
  v_nights INTEGER;
  v_total DECIMAL(10, 2);
BEGIN
  -- Get unit price
  SELECT price_per_night INTO v_price_per_night
  FROM public.units
  WHERE id = p_unit_id;

  IF v_price_per_night IS NULL THEN
    RAISE EXCEPTION 'Unit not found: %', p_unit_id;
  END IF;

  -- Calculate number of nights
  v_nights := p_check_out - p_check_in;

  IF v_nights <= 0 THEN
    RAISE EXCEPTION 'Invalid date range: check_out must be after check_in';
  END IF;

  -- Calculate total
  v_total := v_price_per_night * v_nights;

  RETURN v_total;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION public.calculate_booking_price IS 'Calculate total booking price based on unit price and number of nights';

-- Calculate advance payment (20%)
CREATE OR REPLACE FUNCTION public.calculate_advance_payment(
  p_total_price DECIMAL(10, 2)
)
RETURNS DECIMAL(10, 2) AS $$
BEGIN
  RETURN ROUND(p_total_price * 0.20, 2);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

COMMENT ON FUNCTION public.calculate_advance_payment IS 'Calculate 20% advance payment amount';

-- ============================================================================
-- 4. BOOKING VALIDATION TRIGGER
-- ============================================================================

-- Validate booking before insert/update
CREATE OR REPLACE FUNCTION public.validate_booking()
RETURNS TRIGGER AS $$
DECLARE
  v_unit_max_guests INTEGER;
  v_unit_min_stay INTEGER;
  v_nights INTEGER;
BEGIN
  -- Calculate number of nights
  v_nights := NEW.check_out - NEW.check_in;

  -- Check date validity
  IF v_nights <= 0 THEN
    RAISE EXCEPTION 'Invalid booking dates: check_out must be after check_in';
  END IF;

  -- Get unit constraints
  SELECT max_guests, min_stay_nights
  INTO v_unit_max_guests, v_unit_min_stay
  FROM public.units
  WHERE id = NEW.unit_id;

  -- Check guest count
  IF NEW.guest_count > v_unit_max_guests THEN
    RAISE EXCEPTION 'Guest count (%) exceeds unit capacity (%)', NEW.guest_count, v_unit_max_guests;
  END IF;

  -- Check minimum stay
  IF v_nights < v_unit_min_stay THEN
    RAISE EXCEPTION 'Booking duration (% nights) is less than minimum stay (% nights)', v_nights, v_unit_min_stay;
  END IF;

  -- Check availability (only for new bookings or date changes)
  IF (TG_OP = 'INSERT') OR (NEW.check_in != OLD.check_in OR NEW.check_out != OLD.check_out) THEN
    IF NOT public.is_unit_available(NEW.unit_id, NEW.check_in, NEW.check_out, NEW.id) THEN
      RAISE EXCEPTION 'Unit is not available for selected dates';
    END IF;
  END IF;

  -- Auto-calculate total price if not set
  IF NEW.total_price IS NULL OR NEW.total_price = 0 THEN
    NEW.total_price := public.calculate_booking_price(NEW.unit_id, NEW.check_in, NEW.check_out);
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION public.validate_booking IS 'Validate booking constraints before insert/update';

-- Apply validation trigger
CREATE TRIGGER validate_booking_before_insert
  BEFORE INSERT ON public.bookings
  FOR EACH ROW EXECUTE FUNCTION public.validate_booking();

CREATE TRIGGER validate_booking_before_update
  BEFORE UPDATE ON public.bookings
  FOR EACH ROW EXECUTE FUNCTION public.validate_booking();

-- ============================================================================
-- 5. PROPERTY RATING UPDATE TRIGGER
-- ============================================================================

-- Function to update property rating (will be called when reviews are added)
CREATE OR REPLACE FUNCTION public.update_property_rating(
  p_property_id UUID,
  p_new_rating DECIMAL(3, 2)
)
RETURNS VOID AS $$
DECLARE
  v_current_rating DECIMAL(3, 2);
  v_current_count INTEGER;
  v_new_count INTEGER;
  v_updated_rating DECIMAL(3, 2);
BEGIN
  -- Get current rating and count
  SELECT rating, review_count
  INTO v_current_rating, v_current_count
  FROM public.properties
  WHERE id = p_property_id;

  -- Calculate new rating
  v_new_count := v_current_count + 1;
  v_updated_rating := ROUND(
    ((v_current_rating * v_current_count) + p_new_rating) / v_new_count,
    2
  );

  -- Update property
  UPDATE public.properties
  SET
    rating = v_updated_rating,
    review_count = v_new_count
  WHERE id = p_property_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION public.update_property_rating IS 'Update property average rating when new review is added';

-- ============================================================================
-- 6. HELPER FUNCTIONS FOR QUERIES
-- ============================================================================

-- Get property bookings (for owner dashboard)
CREATE OR REPLACE FUNCTION public.get_property_bookings(p_property_id UUID)
RETURNS SETOF public.bookings AS $$
BEGIN
  RETURN QUERY
  SELECT b.*
  FROM public.bookings b
  JOIN public.units u ON u.id = b.unit_id
  WHERE u.property_id = p_property_id
  ORDER BY b.check_in DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION public.get_property_bookings IS 'Get all bookings for a property';

-- Get owner bookings (all properties owned by user)
CREATE OR REPLACE FUNCTION public.get_owner_bookings(p_owner_id UUID)
RETURNS SETOF public.bookings AS $$
BEGIN
  RETURN QUERY
  SELECT b.*
  FROM public.bookings b
  JOIN public.units u ON u.id = b.unit_id
  JOIN public.properties p ON p.id = u.property_id
  WHERE p.owner_id = p_owner_id
  ORDER BY b.check_in DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION public.get_owner_bookings IS 'Get all bookings for properties owned by a user';

-- Search properties by text
CREATE OR REPLACE FUNCTION public.search_properties(p_query TEXT)
RETURNS SETOF public.properties AS $$
BEGIN
  RETURN QUERY
  SELECT *
  FROM public.properties
  WHERE is_active = true
  AND to_tsvector('english', name || ' ' || COALESCE(description, '') || ' ' || location) @@ plainto_tsquery('english', p_query)
  ORDER BY rating DESC, review_count DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION public.search_properties IS 'Full-text search for properties';

-- ============================================================================
-- 7. AUTO-CREATE USER PROFILE ON SIGNUP
-- ============================================================================

-- Automatically create user profile when auth user is created
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, role)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'role', 'guest')
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION public.handle_new_user IS 'Automatically create user profile on signup';

-- Trigger on auth.users insert
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
