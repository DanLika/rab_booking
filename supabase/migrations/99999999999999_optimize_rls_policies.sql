-- ============================================================================
-- SUPABASE RLS POLICY OPTIMIZATION
-- ============================================================================
-- Issue: auth.<function>() is re-evaluated for EACH ROW (slow at scale)
-- Solution: (select auth.<function>()) is evaluated ONCE per query (fast)
--
-- Impact: 10-100x performance improvement on queries with many rows
-- ============================================================================

-- ============================================================================
-- 1. USERS TABLE - Optimize RLS Policies
-- ============================================================================

-- Drop existing policies
DROP POLICY IF EXISTS users_select_own ON public.users;
DROP POLICY IF EXISTS users_insert_authenticated ON public.users;
DROP POLICY IF EXISTS users_update_own ON public.users;

-- Recreate with optimized auth function calls
CREATE POLICY users_select_own ON public.users
  FOR SELECT
  USING (id = (select auth.uid()));  -- Optimized: evaluated once!

CREATE POLICY users_insert_authenticated ON public.users
  FOR INSERT
  WITH CHECK (id = (select auth.uid()));  -- Optimized: evaluated once!

CREATE POLICY users_update_own ON public.users
  FOR UPDATE
  USING (id = (select auth.uid()))  -- Optimized: evaluated once!
  WITH CHECK (id = (select auth.uid()));  -- Optimized: evaluated once!

-- ============================================================================
-- 2. PROPERTIES TABLE - Optimize RLS Policies
-- ============================================================================

-- Drop existing policies
DROP POLICY IF EXISTS properties_select_own ON public.properties;
DROP POLICY IF EXISTS properties_insert_own ON public.properties;
DROP POLICY IF EXISTS properties_update_own ON public.properties;
DROP POLICY IF EXISTS properties_delete_own ON public.properties;

-- Recreate with optimized auth function calls
CREATE POLICY properties_select_own ON public.properties
  FOR SELECT
  USING (
    owner_id = (select auth.uid()) OR  -- Optimized: evaluated once!
    is_active = true  -- Public properties visible to all
  );

CREATE POLICY properties_insert_own ON public.properties
  FOR INSERT
  WITH CHECK (owner_id = (select auth.uid()));  -- Optimized: evaluated once!

CREATE POLICY properties_update_own ON public.properties
  FOR UPDATE
  USING (owner_id = (select auth.uid()))  -- Optimized: evaluated once!
  WITH CHECK (owner_id = (select auth.uid()));  -- Optimized: evaluated once!

CREATE POLICY properties_delete_own ON public.properties
  FOR DELETE
  USING (owner_id = (select auth.uid()));  -- Optimized: evaluated once!

-- ============================================================================
-- 3. UNITS TABLE - Optimize RLS Policies
-- ============================================================================

-- Drop existing policies
DROP POLICY IF EXISTS units_select_own ON public.units;
DROP POLICY IF EXISTS units_insert_own ON public.units;
DROP POLICY IF EXISTS units_update_own ON public.units;
DROP POLICY IF EXISTS units_delete_own ON public.units;

-- Recreate with optimized auth function calls
CREATE POLICY units_select_own ON public.units
  FOR SELECT
  USING (
    property_id IN (
      SELECT id FROM public.properties
      WHERE owner_id = (select auth.uid())  -- Optimized: evaluated once!
    )
    OR is_available = true  -- Public units visible to all
  );

CREATE POLICY units_insert_own ON public.units
  FOR INSERT
  WITH CHECK (
    property_id IN (
      SELECT id FROM public.properties
      WHERE owner_id = (select auth.uid())  -- Optimized: evaluated once!
    )
  );

CREATE POLICY units_update_own ON public.units
  FOR UPDATE
  USING (
    property_id IN (
      SELECT id FROM public.properties
      WHERE owner_id = (select auth.uid())  -- Optimized: evaluated once!
    )
  )
  WITH CHECK (
    property_id IN (
      SELECT id FROM public.properties
      WHERE owner_id = (select auth.uid())  -- Optimized: evaluated once!
    )
  );

CREATE POLICY units_delete_own ON public.units
  FOR DELETE
  USING (
    property_id IN (
      SELECT id FROM public.properties
      WHERE owner_id = (select auth.uid())  -- Optimized: evaluated once!
    )
  );

-- ============================================================================
-- 4. BOOKINGS TABLE - Optimize RLS Policies (if they exist)
-- ============================================================================

-- Drop existing policies (both naming conventions)
DROP POLICY IF EXISTS bookings_select_own ON public.bookings;
DROP POLICY IF EXISTS bookings_insert_own ON public.bookings;
DROP POLICY IF EXISTS bookings_insert_guest ON public.bookings;
DROP POLICY IF EXISTS bookings_update_own ON public.bookings;
DROP POLICY IF EXISTS bookings_delete_own ON public.bookings;

-- Recreate with optimized auth function calls
CREATE POLICY bookings_select_own ON public.bookings
  FOR SELECT
  USING (
    user_id = (select auth.uid())  -- Optimized: evaluated once!
    OR unit_id IN (
      SELECT u.id FROM public.units u
      JOIN public.properties p ON u.property_id = p.id
      WHERE p.owner_id = (select auth.uid())  -- Optimized: evaluated once!
    )
  );

CREATE POLICY bookings_insert_guest ON public.bookings
  FOR INSERT
  WITH CHECK (user_id = (select auth.uid()));  -- Optimized: evaluated once!

CREATE POLICY bookings_update_own ON public.bookings
  FOR UPDATE
  USING (
    user_id = (select auth.uid())  -- Optimized: evaluated once!
    OR unit_id IN (
      SELECT u.id FROM public.units u
      JOIN public.properties p ON u.property_id = p.id
      WHERE p.owner_id = (select auth.uid())  -- Optimized: evaluated once!
    )
  );

CREATE POLICY bookings_delete_own ON public.bookings
  FOR DELETE
  USING (user_id = (select auth.uid()));  -- Optimized: evaluated once!

-- ============================================================================
-- 5. REVIEWS TABLE - Optimize RLS Policies (if they exist)
-- ============================================================================

-- Drop existing policies (both naming conventions)
DROP POLICY IF EXISTS reviews_select_all ON public.reviews;
DROP POLICY IF EXISTS reviews_insert_own ON public.reviews;
DROP POLICY IF EXISTS reviews_update_own ON public.reviews;
DROP POLICY IF EXISTS reviews_delete_own ON public.reviews;
DROP POLICY IF EXISTS "Users can create reviews for their bookings" ON public.reviews;
DROP POLICY IF EXISTS "Users can update their own reviews" ON public.reviews;
DROP POLICY IF EXISTS "Users can delete their own reviews" ON public.reviews;

-- Recreate with optimized auth function calls
CREATE POLICY reviews_select_all ON public.reviews
  FOR SELECT
  USING (true);  -- Reviews are public

CREATE POLICY "Users can create reviews for their bookings" ON public.reviews
  FOR INSERT
  WITH CHECK (
    user_id = (select auth.uid())  -- Optimized: evaluated once!
    AND booking_id IN (
      SELECT id FROM public.bookings
      WHERE user_id = (select auth.uid())  -- Optimized: evaluated once!
    )
  );

CREATE POLICY "Users can update their own reviews" ON public.reviews
  FOR UPDATE
  USING (user_id = (select auth.uid()))  -- Optimized: evaluated once!
  WITH CHECK (user_id = (select auth.uid()));  -- Optimized: evaluated once!

CREATE POLICY "Users can delete their own reviews" ON public.reviews
  FOR DELETE
  USING (user_id = (select auth.uid()));  -- Optimized: evaluated once!

-- ============================================================================
-- 6. SAVED_SEARCHES TABLE - Optimize RLS Policies
-- ============================================================================

DROP POLICY IF EXISTS saved_searches_select_own ON public.saved_searches;
DROP POLICY IF EXISTS saved_searches_insert_own ON public.saved_searches;
DROP POLICY IF EXISTS saved_searches_update_own ON public.saved_searches;
DROP POLICY IF EXISTS saved_searches_delete_own ON public.saved_searches;

CREATE POLICY saved_searches_select_own ON public.saved_searches
  FOR SELECT
  USING (user_id = (select auth.uid()));  -- Optimized: evaluated once!

CREATE POLICY saved_searches_insert_own ON public.saved_searches
  FOR INSERT
  WITH CHECK (user_id = (select auth.uid()));  -- Optimized: evaluated once!

CREATE POLICY saved_searches_update_own ON public.saved_searches
  FOR UPDATE
  USING (user_id = (select auth.uid()))  -- Optimized: evaluated once!
  WITH CHECK (user_id = (select auth.uid()));  -- Optimized: evaluated once!

CREATE POLICY saved_searches_delete_own ON public.saved_searches
  FOR DELETE
  USING (user_id = (select auth.uid()));  -- Optimized: evaluated once!

-- ============================================================================
-- 7. RECENTLY_VIEWED TABLE - Optimize RLS Policies
-- ============================================================================

DROP POLICY IF EXISTS recently_viewed_select_own ON public.recently_viewed;
DROP POLICY IF EXISTS recently_viewed_insert_own ON public.recently_viewed;
DROP POLICY IF EXISTS recently_viewed_delete_own ON public.recently_viewed;

CREATE POLICY recently_viewed_select_own ON public.recently_viewed
  FOR SELECT
  USING (user_id = (select auth.uid()));  -- Optimized: evaluated once!

CREATE POLICY recently_viewed_insert_own ON public.recently_viewed
  FOR INSERT
  WITH CHECK (user_id = (select auth.uid()));  -- Optimized: evaluated once!

CREATE POLICY recently_viewed_delete_own ON public.recently_viewed
  FOR DELETE
  USING (user_id = (select auth.uid()));  -- Optimized: evaluated once!

-- ============================================================================
-- 8. NOTIFICATIONS TABLE - Optimize RLS Policies
-- ============================================================================

DROP POLICY IF EXISTS notifications_select_own ON public.notifications;
DROP POLICY IF EXISTS notifications_insert_own ON public.notifications;
DROP POLICY IF EXISTS notifications_update_own ON public.notifications;
DROP POLICY IF EXISTS notifications_delete_own ON public.notifications;

CREATE POLICY notifications_select_own ON public.notifications
  FOR SELECT
  USING (user_id = (select auth.uid()));  -- Optimized: evaluated once!

CREATE POLICY notifications_insert_own ON public.notifications
  FOR INSERT
  WITH CHECK (user_id = (select auth.uid()));  -- Optimized: evaluated once!

CREATE POLICY notifications_update_own ON public.notifications
  FOR UPDATE
  USING (user_id = (select auth.uid()))  -- Optimized: evaluated once!
  WITH CHECK (user_id = (select auth.uid()));  -- Optimized: evaluated once!

CREATE POLICY notifications_delete_own ON public.notifications
  FOR DELETE
  USING (user_id = (select auth.uid()));  -- Optimized: evaluated once!

-- ============================================================================
-- 9. MESSAGES TABLE - Optimize RLS Policies (if exists)
-- ============================================================================

DROP POLICY IF EXISTS messages_select_own ON public.messages;
DROP POLICY IF EXISTS messages_insert_own ON public.messages;
DROP POLICY IF EXISTS messages_update_own ON public.messages;
DROP POLICY IF EXISTS messages_delete_own ON public.messages;

CREATE POLICY messages_select_own ON public.messages
  FOR SELECT
  USING (
    sender_id = (select auth.uid())  -- Optimized: evaluated once!
    OR recipient_id = (select auth.uid())  -- Optimized: evaluated once!
  );

CREATE POLICY messages_insert_own ON public.messages
  FOR INSERT
  WITH CHECK (sender_id = (select auth.uid()));  -- Optimized: evaluated once!

CREATE POLICY messages_update_own ON public.messages
  FOR UPDATE
  USING (sender_id = (select auth.uid()))  -- Optimized: evaluated once!
  WITH CHECK (sender_id = (select auth.uid()));  -- Optimized: evaluated once!

CREATE POLICY messages_delete_own ON public.messages
  FOR DELETE
  USING (sender_id = (select auth.uid()));  -- Optimized: evaluated once!

-- ============================================================================
-- 10. SPATIAL_REF_SYS - Disable RLS (System table)
-- ============================================================================
-- Note: spatial_ref_sys is a PostGIS system table, RLS not needed

-- ============================================================================
-- PERFORMANCE VERIFICATION QUERY
-- ============================================================================
-- Run this to verify optimization:
/*
SELECT
  schemaname,
  tablename,
  policyname,
  CASE
    WHEN definition LIKE '%auth.uid()%' AND definition NOT LIKE '%(select auth.uid())%'
    THEN 'NEEDS OPTIMIZATION'
    ELSE 'OPTIMIZED'
  END as status,
  definition
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;
*/

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON POLICY users_select_own ON public.users IS
  'Optimized: Uses (select auth.uid()) for single evaluation per query';

COMMENT ON POLICY properties_select_own ON public.properties IS
  'Optimized: Uses (select auth.uid()) for single evaluation per query';

COMMENT ON POLICY units_select_own ON public.units IS
  'Optimized: Uses (select auth.uid()) for single evaluation per query';

COMMENT ON POLICY bookings_select_own ON public.bookings IS
  'Optimized: Uses (select auth.uid()) for single evaluation per query';

-- ============================================================================
-- END OF OPTIMIZATION
-- ============================================================================
