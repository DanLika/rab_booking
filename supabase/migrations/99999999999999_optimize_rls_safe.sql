-- ============================================================================
-- SUPABASE RLS POLICY OPTIMIZATION - SAFE VERSION
-- ============================================================================
-- This version checks if tables exist before modifying policies
-- Safe to run even if some tables don't exist yet
-- ============================================================================

-- ============================================================================
-- PART 1: DROP ALL EXISTING POLICIES (ONLY IF TABLE EXISTS)
-- ============================================================================

-- Users table
DO $$ BEGIN
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'users') THEN
    DROP POLICY IF EXISTS users_select_own ON public.users;
    DROP POLICY IF EXISTS "Anyone can read user public data" ON public.users;
    DROP POLICY IF EXISTS users_insert_authenticated ON public.users;
    DROP POLICY IF EXISTS users_update_own ON public.users;
    DROP POLICY IF EXISTS "Users can update own data" ON public.users;
  END IF;
END $$;

-- Properties table
DO $$ BEGIN
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'properties') THEN
    DROP POLICY IF EXISTS properties_select_own ON public.properties;
    DROP POLICY IF EXISTS properties_select_active ON public.properties;
    DROP POLICY IF EXISTS properties_insert_own ON public.properties;
    DROP POLICY IF EXISTS properties_update_own ON public.properties;
    DROP POLICY IF EXISTS properties_delete_own ON public.properties;
  END IF;
END $$;

-- Units table
DO $$ BEGIN
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'units') THEN
    DROP POLICY IF EXISTS units_select_own ON public.units;
    DROP POLICY IF EXISTS units_select_available ON public.units;
    DROP POLICY IF EXISTS units_insert_own ON public.units;
    DROP POLICY IF EXISTS units_update_own ON public.units;
    DROP POLICY IF EXISTS units_delete_own ON public.units;
  END IF;
END $$;

-- Bookings table
DO $$ BEGIN
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'bookings') THEN
    DROP POLICY IF EXISTS bookings_select_own ON public.bookings;
    DROP POLICY IF EXISTS bookings_guest_select_own ON public.bookings;
    DROP POLICY IF EXISTS bookings_owner_select_own_properties ON public.bookings;
    DROP POLICY IF EXISTS bookings_admin_all ON public.bookings;
    DROP POLICY IF EXISTS bookings_insert_own ON public.bookings;
    DROP POLICY IF EXISTS bookings_insert_guest ON public.bookings;
    DROP POLICY IF EXISTS bookings_update_own ON public.bookings;
    DROP POLICY IF EXISTS bookings_update_own_pending ON public.bookings;
    DROP POLICY IF EXISTS bookings_update_property_owner ON public.bookings;
    DROP POLICY IF EXISTS bookings_delete_own ON public.bookings;
  END IF;
END $$;

-- Reviews table
DO $$ BEGIN
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'reviews') THEN
    DROP POLICY IF EXISTS reviews_select_all ON public.reviews;
    DROP POLICY IF EXISTS reviews_insert_own ON public.reviews;
    DROP POLICY IF EXISTS "Users can create reviews for their bookings" ON public.reviews;
    DROP POLICY IF EXISTS reviews_update_own ON public.reviews;
    DROP POLICY IF EXISTS "Users can update their own reviews" ON public.reviews;
    DROP POLICY IF EXISTS "Property owners can add host responses" ON public.reviews;
    DROP POLICY IF EXISTS reviews_delete_own ON public.reviews;
    DROP POLICY IF EXISTS "Users can delete their own reviews" ON public.reviews;
  END IF;
END $$;

-- Favorites table
DO $$ BEGIN
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'favorites') THEN
    DROP POLICY IF EXISTS favorites_select_own ON public.favorites;
    DROP POLICY IF EXISTS "Users can view own favorites" ON public.favorites;
    DROP POLICY IF EXISTS favorites_insert_own ON public.favorites;
    DROP POLICY IF EXISTS "Users can insert own favorites" ON public.favorites;
    DROP POLICY IF EXISTS favorites_update_own ON public.favorites;
    DROP POLICY IF EXISTS favorites_delete_own ON public.favorites;
    DROP POLICY IF EXISTS "Users can delete own favorites" ON public.favorites;
  END IF;
END $$;

-- Payments table
DO $$ BEGIN
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'payments') THEN
    DROP POLICY IF EXISTS payments_select_own ON public.payments;
    DROP POLICY IF EXISTS payments_select_own_booking ON public.payments;
    DROP POLICY IF EXISTS payments_select_property_owner ON public.payments;
    DROP POLICY IF EXISTS payments_admin_all ON public.payments;
    DROP POLICY IF EXISTS payments_insert_own ON public.payments;
    DROP POLICY IF EXISTS payments_insert_system ON public.payments;
    DROP POLICY IF EXISTS payments_update_own ON public.payments;
    DROP POLICY IF EXISTS payments_delete_own ON public.payments;
  END IF;
END $$;

-- Saved searches table (may not exist)
DO $$ BEGIN
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'saved_searches') THEN
    DROP POLICY IF EXISTS saved_searches_select_own ON public.saved_searches;
    DROP POLICY IF EXISTS saved_searches_insert_own ON public.saved_searches;
    DROP POLICY IF EXISTS saved_searches_update_own ON public.saved_searches;
    DROP POLICY IF EXISTS saved_searches_delete_own ON public.saved_searches;
  END IF;
END $$;

-- Recently viewed table
DO $$ BEGIN
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'recently_viewed') THEN
    DROP POLICY IF EXISTS recently_viewed_select_own ON public.recently_viewed;
    DROP POLICY IF EXISTS "Users can read own recently viewed" ON public.recently_viewed;
    DROP POLICY IF EXISTS recently_viewed_insert_own ON public.recently_viewed;
    DROP POLICY IF EXISTS "Users can insert own recently viewed" ON public.recently_viewed;
    DROP POLICY IF EXISTS recently_viewed_update_own ON public.recently_viewed;
    DROP POLICY IF EXISTS "Users can update own recently viewed" ON public.recently_viewed;
    DROP POLICY IF EXISTS recently_viewed_delete_own ON public.recently_viewed;
    DROP POLICY IF EXISTS "Users can delete own recently viewed" ON public.recently_viewed;
  END IF;
END $$;

-- Notifications table
DO $$ BEGIN
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'notifications') THEN
    DROP POLICY IF EXISTS notifications_select_own ON public.notifications;
    DROP POLICY IF EXISTS notifications_insert_own ON public.notifications;
    DROP POLICY IF EXISTS notifications_update_own ON public.notifications;
    DROP POLICY IF EXISTS notifications_delete_own ON public.notifications;
  END IF;
END $$;

-- Messages table
DO $$ BEGIN
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'messages') THEN
    DROP POLICY IF EXISTS messages_select_own ON public.messages;
    DROP POLICY IF EXISTS "Users can read own messages" ON public.messages;
    DROP POLICY IF EXISTS messages_insert_own ON public.messages;
    DROP POLICY IF EXISTS "Authenticated users can send messages" ON public.messages;
    DROP POLICY IF EXISTS messages_update_own ON public.messages;
    DROP POLICY IF EXISTS "Receivers can update message read status" ON public.messages;
    DROP POLICY IF EXISTS messages_delete_own ON public.messages;
    DROP POLICY IF EXISTS "Senders can delete sent messages" ON public.messages;
  END IF;
END $$;

-- ============================================================================
-- PART 2: CREATE OPTIMIZED POLICIES (ONLY IF TABLE EXISTS)
-- ============================================================================

-- ============================================================================
-- 1. USERS TABLE
-- ============================================================================
DO $$ BEGIN
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'users') THEN

    CREATE POLICY users_select ON public.users
      FOR SELECT
      USING (
        id = (select auth.uid())
        OR true
      );

    CREATE POLICY users_insert ON public.users
      FOR INSERT
      WITH CHECK (id = (select auth.uid()));

    CREATE POLICY users_update ON public.users
      FOR UPDATE
      USING (id = (select auth.uid()))
      WITH CHECK (id = (select auth.uid()));

    RAISE NOTICE 'Users table policies optimized';
  ELSE
    RAISE NOTICE 'Users table does not exist, skipping';
  END IF;
END $$;

-- ============================================================================
-- 2. PROPERTIES TABLE
-- ============================================================================
DO $$ BEGIN
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'properties') THEN

    CREATE POLICY properties_select ON public.properties
      FOR SELECT
      USING (
        owner_id = (select auth.uid())
        OR is_active = true
      );

    CREATE POLICY properties_insert ON public.properties
      FOR INSERT
      WITH CHECK (owner_id = (select auth.uid()));

    CREATE POLICY properties_update ON public.properties
      FOR UPDATE
      USING (owner_id = (select auth.uid()))
      WITH CHECK (owner_id = (select auth.uid()));

    CREATE POLICY properties_delete ON public.properties
      FOR DELETE
      USING (owner_id = (select auth.uid()));

    RAISE NOTICE 'Properties table policies optimized';
  ELSE
    RAISE NOTICE 'Properties table does not exist, skipping';
  END IF;
END $$;

-- ============================================================================
-- 3. UNITS TABLE
-- ============================================================================
DO $$ BEGIN
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'units') THEN

    CREATE POLICY units_select ON public.units
      FOR SELECT
      USING (
        property_id IN (
          SELECT id FROM public.properties
          WHERE owner_id = (select auth.uid())
        )
        OR is_available = true
      );

    CREATE POLICY units_insert ON public.units
      FOR INSERT
      WITH CHECK (
        property_id IN (
          SELECT id FROM public.properties
          WHERE owner_id = (select auth.uid())
        )
      );

    CREATE POLICY units_update ON public.units
      FOR UPDATE
      USING (
        property_id IN (
          SELECT id FROM public.properties
          WHERE owner_id = (select auth.uid())
        )
      )
      WITH CHECK (
        property_id IN (
          SELECT id FROM public.properties
          WHERE owner_id = (select auth.uid())
        )
      );

    CREATE POLICY units_delete ON public.units
      FOR DELETE
      USING (
        property_id IN (
          SELECT id FROM public.properties
          WHERE owner_id = (select auth.uid())
        )
      );

    RAISE NOTICE 'Units table policies optimized';
  ELSE
    RAISE NOTICE 'Units table does not exist, skipping';
  END IF;
END $$;

-- ============================================================================
-- 4. BOOKINGS TABLE
-- ============================================================================
DO $$ BEGIN
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'bookings') THEN

    CREATE POLICY bookings_select ON public.bookings
      FOR SELECT
      USING (
        user_id = (select auth.uid())
        OR unit_id IN (
          SELECT u.id FROM public.units u
          JOIN public.properties p ON u.property_id = p.id
          WHERE p.owner_id = (select auth.uid())
        )
      );

    CREATE POLICY bookings_insert ON public.bookings
      FOR INSERT
      WITH CHECK (user_id = (select auth.uid()));

    CREATE POLICY bookings_update ON public.bookings
      FOR UPDATE
      USING (
        (user_id = (select auth.uid()) AND status = 'pending')
        OR unit_id IN (
          SELECT u.id FROM public.units u
          JOIN public.properties p ON u.property_id = p.id
          WHERE p.owner_id = (select auth.uid())
        )
      );

    CREATE POLICY bookings_delete ON public.bookings
      FOR DELETE
      USING (user_id = (select auth.uid()));

    RAISE NOTICE 'Bookings table policies optimized';
  ELSE
    RAISE NOTICE 'Bookings table does not exist, skipping';
  END IF;
END $$;

-- ============================================================================
-- 5. REVIEWS TABLE
-- ============================================================================
DO $$ BEGIN
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'reviews') THEN

    CREATE POLICY reviews_select ON public.reviews
      FOR SELECT
      USING (true);

    CREATE POLICY reviews_insert ON public.reviews
      FOR INSERT
      WITH CHECK (
        user_id = (select auth.uid())
        AND booking_id IN (
          SELECT id FROM public.bookings
          WHERE user_id = (select auth.uid())
            AND status = 'completed'
        )
      );

    CREATE POLICY reviews_update ON public.reviews
      FOR UPDATE
      USING (
        user_id = (select auth.uid())
        OR EXISTS (
          SELECT 1 FROM public.bookings b
          JOIN public.units u ON b.unit_id = u.id
          JOIN public.properties p ON u.property_id = p.id
          WHERE b.id = reviews.booking_id
            AND p.owner_id = (select auth.uid())
        )
      );

    CREATE POLICY reviews_delete ON public.reviews
      FOR DELETE
      USING (user_id = (select auth.uid()));

    RAISE NOTICE 'Reviews table policies optimized';
  ELSE
    RAISE NOTICE 'Reviews table does not exist, skipping';
  END IF;
END $$;

-- ============================================================================
-- 6. FAVORITES TABLE
-- ============================================================================
DO $$ BEGIN
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'favorites') THEN

    CREATE POLICY favorites_select ON public.favorites
      FOR SELECT
      USING (user_id = (select auth.uid()));

    CREATE POLICY favorites_insert ON public.favorites
      FOR INSERT
      WITH CHECK (user_id = (select auth.uid()));

    CREATE POLICY favorites_delete ON public.favorites
      FOR DELETE
      USING (user_id = (select auth.uid()));

    RAISE NOTICE 'Favorites table policies optimized';
  ELSE
    RAISE NOTICE 'Favorites table does not exist, skipping';
  END IF;
END $$;

-- ============================================================================
-- 7. PAYMENTS TABLE
-- ============================================================================
DO $$ BEGIN
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'payments') THEN

    CREATE POLICY payments_select ON public.payments
      FOR SELECT
      USING (
        booking_id IN (
          SELECT id FROM public.bookings
          WHERE user_id = (select auth.uid())
        )
        OR booking_id IN (
          SELECT b.id FROM public.bookings b
          JOIN public.units u ON b.unit_id = u.id
          JOIN public.properties p ON u.property_id = p.id
          WHERE p.owner_id = (select auth.uid())
        )
      );

    CREATE POLICY payments_insert ON public.payments
      FOR INSERT
      WITH CHECK (
        booking_id IN (
          SELECT id FROM public.bookings
          WHERE user_id = (select auth.uid())
        )
      );

    RAISE NOTICE 'Payments table policies optimized';
  ELSE
    RAISE NOTICE 'Payments table does not exist, skipping';
  END IF;
END $$;

-- ============================================================================
-- 8. SAVED_SEARCHES TABLE (optional)
-- ============================================================================
DO $$ BEGIN
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'saved_searches') THEN

    CREATE POLICY saved_searches_select ON public.saved_searches
      FOR SELECT
      USING (user_id = (select auth.uid()));

    CREATE POLICY saved_searches_insert ON public.saved_searches
      FOR INSERT
      WITH CHECK (user_id = (select auth.uid()));

    CREATE POLICY saved_searches_update ON public.saved_searches
      FOR UPDATE
      USING (user_id = (select auth.uid()))
      WITH CHECK (user_id = (select auth.uid()));

    CREATE POLICY saved_searches_delete ON public.saved_searches
      FOR DELETE
      USING (user_id = (select auth.uid()));

    RAISE NOTICE 'Saved searches table policies optimized';
  ELSE
    RAISE NOTICE 'Saved searches table does not exist, skipping';
  END IF;
END $$;

-- ============================================================================
-- 9. RECENTLY_VIEWED TABLE
-- ============================================================================
DO $$ BEGIN
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'recently_viewed') THEN

    CREATE POLICY recently_viewed_select ON public.recently_viewed
      FOR SELECT
      USING (user_id = (select auth.uid()));

    CREATE POLICY recently_viewed_insert ON public.recently_viewed
      FOR INSERT
      WITH CHECK (user_id = (select auth.uid()));

    CREATE POLICY recently_viewed_update ON public.recently_viewed
      FOR UPDATE
      USING (user_id = (select auth.uid()))
      WITH CHECK (user_id = (select auth.uid()));

    CREATE POLICY recently_viewed_delete ON public.recently_viewed
      FOR DELETE
      USING (user_id = (select auth.uid()));

    RAISE NOTICE 'Recently viewed table policies optimized';
  ELSE
    RAISE NOTICE 'Recently viewed table does not exist, skipping';
  END IF;
END $$;

-- ============================================================================
-- 10. NOTIFICATIONS TABLE
-- ============================================================================
DO $$ BEGIN
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'notifications') THEN

    CREATE POLICY notifications_select ON public.notifications
      FOR SELECT
      USING (user_id = (select auth.uid()));

    CREATE POLICY notifications_insert ON public.notifications
      FOR INSERT
      WITH CHECK (user_id = (select auth.uid()));

    CREATE POLICY notifications_update ON public.notifications
      FOR UPDATE
      USING (user_id = (select auth.uid()))
      WITH CHECK (user_id = (select auth.uid()));

    CREATE POLICY notifications_delete ON public.notifications
      FOR DELETE
      USING (user_id = (select auth.uid()));

    RAISE NOTICE 'Notifications table policies optimized';
  ELSE
    RAISE NOTICE 'Notifications table does not exist, skipping';
  END IF;
END $$;

-- ============================================================================
-- 11. MESSAGES TABLE
-- ============================================================================
DO $$ BEGIN
  IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'messages') THEN

    CREATE POLICY messages_select ON public.messages
      FOR SELECT
      USING (
        sender_id = (select auth.uid())
        OR recipient_id = (select auth.uid())
      );

    CREATE POLICY messages_insert ON public.messages
      FOR INSERT
      WITH CHECK (sender_id = (select auth.uid()));

    CREATE POLICY messages_update ON public.messages
      FOR UPDATE
      USING (recipient_id = (select auth.uid()))
      WITH CHECK (recipient_id = (select auth.uid()));

    CREATE POLICY messages_delete ON public.messages
      FOR DELETE
      USING (sender_id = (select auth.uid()));

    RAISE NOTICE 'Messages table policies optimized';
  ELSE
    RAISE NOTICE 'Messages table does not exist, skipping';
  END IF;
END $$;

-- ============================================================================
-- PART 3: REMOVE DUPLICATE INDEXES (SAFE)
-- ============================================================================

-- Properties table
DROP INDEX IF EXISTS public.idx_properties_active;

-- Units table
DROP INDEX IF EXISTS public.idx_units_available;

-- ============================================================================
-- SUMMARY
-- ============================================================================
DO $$
DECLARE
  table_count INT;
BEGIN
  SELECT COUNT(*) INTO table_count
  FROM pg_tables
  WHERE schemaname = 'public'
    AND tablename IN ('users', 'properties', 'units', 'bookings', 'reviews',
                      'favorites', 'payments', 'saved_searches', 'recently_viewed',
                      'notifications', 'messages');

  RAISE NOTICE '============================================';
  RAISE NOTICE 'RLS OPTIMIZATION COMPLETE!';
  RAISE NOTICE 'Optimized policies for % tables', table_count;
  RAISE NOTICE '============================================';
END $$;
