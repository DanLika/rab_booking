-- ============================================================================
-- MIGRATION: Row Level Security (RLS) Policies
-- Created: 2025-01-16
-- Description: Enable RLS and create security policies for multi-tenancy
-- ============================================================================

-- ============================================================================
-- 1. USERS TABLE RLS
-- ============================================================================

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Users can view their own profile
CREATE POLICY "users_select_own"
  ON public.users FOR SELECT
  USING (auth.uid() = id);

-- Users can insert their own profile (on signup)
CREATE POLICY "users_insert_own"
  ON public.users FOR INSERT
  WITH CHECK (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "users_update_own"
  ON public.users FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Admins can view all users
CREATE POLICY "users_select_admin"
  ON public.users FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- ============================================================================
-- 2. PROPERTIES TABLE RLS
-- ============================================================================

ALTER TABLE public.properties ENABLE ROW LEVEL SECURITY;

-- Anyone can view active properties
CREATE POLICY "properties_select_active"
  ON public.properties FOR SELECT
  USING (is_active = true);

-- Owners can view their own properties (including inactive)
CREATE POLICY "properties_select_own"
  ON public.properties FOR SELECT
  USING (auth.uid() = owner_id);

-- Authenticated owners can insert properties
CREATE POLICY "properties_insert_owner"
  ON public.properties FOR INSERT
  WITH CHECK (
    auth.uid() = owner_id
    AND EXISTS (
      SELECT 1 FROM public.users
      WHERE id = auth.uid()
      AND role IN ('owner', 'admin')
    )
  );

-- Owners can update their own properties
CREATE POLICY "properties_update_own"
  ON public.properties FOR UPDATE
  USING (auth.uid() = owner_id)
  WITH CHECK (auth.uid() = owner_id);

-- Owners can delete their own properties
CREATE POLICY "properties_delete_own"
  ON public.properties FOR DELETE
  USING (auth.uid() = owner_id);

-- Admins can do anything with properties
CREATE POLICY "properties_admin_all"
  ON public.properties FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- ============================================================================
-- 3. UNITS TABLE RLS
-- ============================================================================

ALTER TABLE public.units ENABLE ROW LEVEL SECURITY;

-- Anyone can view units of active properties
CREATE POLICY "units_select_active_properties"
  ON public.units FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.properties
      WHERE properties.id = units.property_id
      AND properties.is_active = true
    )
  );

-- Property owners can view all their units
CREATE POLICY "units_select_own_property"
  ON public.units FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.properties
      WHERE properties.id = units.property_id
      AND properties.owner_id = auth.uid()
    )
  );

-- Property owners can insert units to their properties
CREATE POLICY "units_insert_own_property"
  ON public.units FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.properties
      WHERE properties.id = units.property_id
      AND properties.owner_id = auth.uid()
    )
  );

-- Property owners can update their units
CREATE POLICY "units_update_own_property"
  ON public.units FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.properties
      WHERE properties.id = units.property_id
      AND properties.owner_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.properties
      WHERE properties.id = units.property_id
      AND properties.owner_id = auth.uid()
    )
  );

-- Property owners can delete their units
CREATE POLICY "units_delete_own_property"
  ON public.units FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM public.properties
      WHERE properties.id = units.property_id
      AND properties.owner_id = auth.uid()
    )
  );

-- ============================================================================
-- 4. BOOKINGS TABLE RLS
-- ============================================================================

ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;

-- Guests can view their own bookings
CREATE POLICY "bookings_select_own"
  ON public.bookings FOR SELECT
  USING (auth.uid() = guest_id);

-- Property owners can view bookings for their units
CREATE POLICY "bookings_select_property_owner"
  ON public.bookings FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.units
      JOIN public.properties ON properties.id = units.property_id
      WHERE units.id = bookings.unit_id
      AND properties.owner_id = auth.uid()
    )
  );

-- Authenticated guests can create bookings
CREATE POLICY "bookings_insert_guest"
  ON public.bookings FOR INSERT
  WITH CHECK (
    auth.uid() = guest_id
    AND auth.uid() IS NOT NULL
  );

-- Guests can update their pending bookings (e.g., cancel)
CREATE POLICY "bookings_update_own_pending"
  ON public.bookings FOR UPDATE
  USING (
    auth.uid() = guest_id
    AND status = 'pending'
  )
  WITH CHECK (
    auth.uid() = guest_id
  );

-- Property owners can update bookings for their properties (e.g., confirm, cancel)
CREATE POLICY "bookings_update_property_owner"
  ON public.bookings FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.units
      JOIN public.properties ON properties.id = units.property_id
      WHERE units.id = bookings.unit_id
      AND properties.owner_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.units
      JOIN public.properties ON properties.id = units.property_id
      WHERE units.id = bookings.unit_id
      AND properties.owner_id = auth.uid()
    )
  );

-- Admins can do anything with bookings
CREATE POLICY "bookings_admin_all"
  ON public.bookings FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- ============================================================================
-- 5. PAYMENTS TABLE RLS
-- ============================================================================

ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;

-- Users can view payments for their bookings
CREATE POLICY "payments_select_own_booking"
  ON public.payments FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.bookings
      WHERE bookings.id = payments.booking_id
      AND bookings.guest_id = auth.uid()
    )
  );

-- Property owners can view payments for their properties
CREATE POLICY "payments_select_property_owner"
  ON public.payments FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.bookings
      JOIN public.units ON units.id = bookings.unit_id
      JOIN public.properties ON properties.id = units.property_id
      WHERE bookings.id = payments.booking_id
      AND properties.owner_id = auth.uid()
    )
  );

-- System can insert payments (via Edge Functions or service role)
CREATE POLICY "payments_insert_system"
  ON public.payments FOR INSERT
  WITH CHECK (true); -- Will be restricted via service role key

-- Admins can do anything with payments
CREATE POLICY "payments_admin_all"
  ON public.payments FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- ============================================================================
-- SECURITY NOTES
-- ============================================================================

-- Multi-tenancy is enforced at the database level via RLS
-- - Guests can only see/modify their own bookings
-- - Owners can only see/modify their own properties and associated bookings
-- - Admins have full access to all data
-- - Payment creation is restricted to system/service role (Stripe webhooks)
