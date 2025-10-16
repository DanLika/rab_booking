-- ============================================================================
-- MIGRATION: Realtime & Storage Setup
-- Created: 2025-01-16
-- Description: Enable realtime subscriptions and configure storage buckets
-- ============================================================================

-- ============================================================================
-- 1. ENABLE REALTIME FOR TABLES
-- ============================================================================

-- Enable realtime for bookings (owners see new bookings instantly)
ALTER PUBLICATION supabase_realtime ADD TABLE public.bookings;

-- Enable realtime for payments (track payment status updates)
ALTER PUBLICATION supabase_realtime ADD TABLE public.payments;

-- Enable realtime for properties (see property updates in real-time)
ALTER PUBLICATION supabase_realtime ADD TABLE public.properties;

-- Enable realtime for units (availability changes)
ALTER PUBLICATION supabase_realtime ADD TABLE public.units;

COMMENT ON PUBLICATION supabase_realtime IS 'Real-time data synchronization for frontend';

-- ============================================================================
-- 2. STORAGE BUCKETS SETUP (via SQL)
-- ============================================================================

-- Note: Storage buckets are typically created via Supabase Dashboard or CLI
-- But we can insert into storage.buckets table directly

-- Insert property images bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'property-images',
  'property-images',
  true, -- Public bucket (images can be accessed without auth)
  10485760, -- 10 MB file size limit
  ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;

-- Insert user avatars bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'avatars',
  'avatars',
  true, -- Public bucket
  2097152, -- 2 MB file size limit
  ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- 3. STORAGE POLICIES
-- ============================================================================

-- Property Images: Anyone can read, only owners can upload/update/delete
CREATE POLICY "property_images_select_all"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'property-images');

CREATE POLICY "property_images_insert_authenticated"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'property-images'
    AND auth.uid() IS NOT NULL
  );

CREATE POLICY "property_images_update_owner"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'property-images'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "property_images_delete_owner"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'property-images'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

-- Avatars: Anyone can read, users can upload/update their own
CREATE POLICY "avatars_select_all"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'avatars');

CREATE POLICY "avatars_insert_own"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'avatars'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "avatars_update_own"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'avatars'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "avatars_delete_own"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'avatars'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

-- ============================================================================
-- 4. REALTIME FILTER EXAMPLES (for reference)
-- ============================================================================

-- In your Flutter app, you can subscribe to changes like this:
--
-- // Subscribe to all bookings for a specific guest
-- supabase
--   .from('bookings')
--   .stream(primaryKey: ['id'])
--   .eq('guest_id', userId)
--   .listen((data) { /* handle updates */ });
--
-- // Subscribe to all bookings for properties owned by user
-- supabase
--   .from('bookings')
--   .stream(primaryKey: ['id'])
--   .listen((data) {
--     // Filter on client side or use RPC function
--   });
--
-- // Subscribe to payment status changes for a booking
-- supabase
--   .from('payments')
--   .stream(primaryKey: ['id'])
--   .eq('booking_id', bookingId)
--   .listen((data) { /* update UI */ });
