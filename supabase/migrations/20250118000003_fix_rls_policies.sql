-- ============================================================================
-- MIGRATION: Fix RLS Policies for Anonymous Access
-- Created: 2025-01-18
-- Description: Resolve 500 errors by allowing anonymous browsing of properties
-- ============================================================================

-- This migration fixes critical RLS policy issues that prevented:
-- 1. Anonymous users from browsing properties (500 errors)
-- 2. Guests from viewing property details in "My Bookings" (400 errors)
-- 3. Proper multi-tenant isolation while allowing public discovery

-- ============================================================================
-- 1. DROP CONFLICTING POLICIES
-- ============================================================================

-- Properties: Remove old SELECT policies (will be replaced with better ones)
DROP POLICY IF EXISTS "properties_select_active" ON public.properties;
DROP POLICY IF EXISTS "properties_select_own" ON public.properties;

-- Units: Remove old SELECT policies
DROP POLICY IF EXISTS "units_select_active_properties" ON public.units;
DROP POLICY IF EXISTS "units_select_own_property" ON public.units;

-- Bookings: Remove old SELECT policies (rename for clarity)
DROP POLICY IF EXISTS "bookings_select_own" ON public.bookings;
DROP POLICY IF EXISTS "bookings_select_property_owner" ON public.bookings;

-- ============================================================================
-- 2. CREATE FIXED PROPERTIES POLICIES
-- ============================================================================

-- Policy 1: Public (anonymous + authenticated) can view ALL active properties
-- This is the KEY FIX for 500 errors on home/search pages
CREATE POLICY "properties_public_select_active"
    ON public.properties FOR SELECT
    USING (is_active = true);

-- Policy 2: Property owners can view their own properties (including inactive)
-- Allows property management dashboard
CREATE POLICY "properties_owner_select_own"
    ON public.properties FOR SELECT
    USING (auth.uid() = owner_id);

-- Policy 3: Authenticated users can view properties they have booked
-- This FIXES 400 errors on "My Bookings" page (allows JOIN)
CREATE POLICY "properties_guest_select_booked"
    ON public.properties FOR SELECT
    USING (
        auth.uid() IN (
            SELECT b.guest_id
            FROM public.bookings b
            INNER JOIN public.units u ON b.unit_id = u.id
            WHERE u.property_id = properties.id
        )
    );

-- ============================================================================
-- 3. CREATE FIXED UNITS POLICIES
-- ============================================================================

-- Policy 1: Public (anonymous + authenticated) can view units of active properties
-- Allows browsing unit details, pricing, availability
CREATE POLICY "units_public_select_active"
    ON public.units FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.properties p
            WHERE p.id = units.property_id
            AND p.is_active = true
        )
    );

-- Policy 2: Property owners can view all their units
-- Property management dashboard
CREATE POLICY "units_owner_select_own"
    ON public.units FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.properties p
            WHERE p.id = units.property_id
            AND p.owner_id = auth.uid()
        )
    );

-- Policy 3: Authenticated users can view units they have booked
-- Allows JOIN in "My Bookings" page
CREATE POLICY "units_guest_select_booked"
    ON public.units FOR SELECT
    USING (
        auth.uid() IN (
            SELECT guest_id
            FROM public.bookings
            WHERE unit_id = units.id
        )
    );

-- ============================================================================
-- 4. CREATE FIXED BOOKINGS POLICIES
-- ============================================================================

-- Policy 1: Guests can view their own bookings
-- Renamed for clarity (was "bookings_select_own")
CREATE POLICY "bookings_guest_select_own"
    ON public.bookings FOR SELECT
    USING (auth.uid() = guest_id);

-- Policy 2: Property owners can view bookings for their properties
-- Renamed for clarity (was "bookings_select_property_owner")
CREATE POLICY "bookings_owner_select_own_properties"
    ON public.bookings FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.units u
            INNER JOIN public.properties p ON p.id = u.property_id
            WHERE u.id = bookings.unit_id
            AND p.owner_id = auth.uid()
        )
    );

-- ============================================================================
-- 5. GRANT TABLE-LEVEL PERMISSIONS
-- ============================================================================

-- THIS IS CRITICAL: Without these GRANTs, policies won't work for anonymous users

-- Grant SELECT to anonymous users (for public browsing)
GRANT SELECT ON public.properties TO anon;
GRANT SELECT ON public.units TO anon;

-- Grant SELECT to authenticated users (redundant but explicit)
GRANT SELECT ON public.properties TO authenticated;
GRANT SELECT ON public.units TO authenticated;

-- Grant ALL to authenticated users for bookings
GRANT ALL ON public.bookings TO authenticated;

-- ============================================================================
-- 6. VERIFICATION QUERIES
-- ============================================================================

-- Verify properties policies
SELECT
    policyname,
    roles,
    cmd,
    qual
FROM pg_policies
WHERE tablename = 'properties'
AND schemaname = 'public'
ORDER BY policyname;

-- Verify units policies
SELECT
    policyname,
    roles,
    cmd,
    qual
FROM pg_policies
WHERE tablename = 'units'
AND schemaname = 'public'
ORDER BY policyname;

-- Verify bookings policies
SELECT
    policyname,
    roles,
    cmd,
    qual
FROM pg_policies
WHERE tablename = 'bookings'
AND schemaname = 'public'
ORDER BY policyname;

-- Verify table grants
SELECT
    grantee,
    privilege_type
FROM information_schema.table_privileges
WHERE table_schema = 'public'
AND table_name IN ('properties', 'units', 'bookings')
AND grantee IN ('anon', 'authenticated')
ORDER BY table_name, grantee, privilege_type;

-- ============================================================================
-- ROLLBACK INSTRUCTIONS
-- ============================================================================

-- To rollback this migration:
-- 1. DROP the new policies:
--    DROP POLICY "properties_public_select_active" ON public.properties;
--    DROP POLICY "properties_owner_select_own" ON public.properties;
--    DROP POLICY "properties_guest_select_booked" ON public.properties;
--    DROP POLICY "units_public_select_active" ON public.units;
--    DROP POLICY "units_owner_select_own" ON public.units;
--    DROP POLICY "units_guest_select_booked" ON public.units;
--    DROP POLICY "bookings_guest_select_own" ON public.bookings;
--    DROP POLICY "bookings_owner_select_own_properties" ON public.bookings;
--
-- 2. Re-apply original policies from:
--    supabase/migrations/20250116000002_row_level_security.sql
--
-- 3. REVOKE grants:
--    REVOKE SELECT ON public.properties FROM anon;
--    REVOKE SELECT ON public.units FROM anon;

-- ============================================================================
-- SUCCESS CRITERIA
-- ============================================================================

-- After running this migration, verify:
-- ✅ Anonymous users can view active properties (no 500 errors)
-- ✅ Anonymous users can view units of active properties
-- ✅ Authenticated users can view their bookings with property details (no 400 errors)
-- ✅ Owners can still manage their properties
-- ✅ Multi-tenancy is maintained (no data leakage)

-- ============================================================================
-- WHAT THIS FIXES
-- ============================================================================

-- ✅ 500 errors on home page (featured properties loading)
-- ✅ 500 errors on search page (property listing)
-- ✅ 400 errors on bookings page (JOIN bookings → units → properties)
-- ✅ Anonymous users can browse properties without login
-- ✅ Authenticated users can see property details in "My Bookings"
-- ✅ Property owners can manage their properties
-- ✅ Multi-tenant isolation maintained

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================
