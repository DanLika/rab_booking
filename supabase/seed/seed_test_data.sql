-- ============================================================================
-- SEED DATA: Test Data for Rab Booking
-- Created: 2025-01-16
-- Description: Sample data for development and testing
-- ============================================================================

-- IMPORTANT: Run this AFTER creating your first user via Supabase Auth
-- Replace USER_ID_HERE with your actual user UUID from auth.users

-- ============================================================================
-- 1. TEST USERS (manual creation via Supabase Auth Dashboard)
-- ============================================================================

-- User 1: Guest (test@example.com)
-- User 2: Owner (owner@example.com)
-- User 3: Admin (admin@example.com)

-- Create test user profiles (replace UUIDs with real ones)
-- These will be auto-created by the handle_new_user() trigger
-- But we can update them here for testing

-- ============================================================================
-- 2. TEST PROPERTIES
-- ============================================================================

-- Property 1: Luxury Villa in Rab Town
INSERT INTO public.properties (
  id,
  owner_id,
  name,
  description,
  location,
  latitude,
  longitude,
  amenities,
  images,
  cover_image,
  rating,
  review_count,
  is_active
) VALUES (
  '11111111-1111-1111-1111-111111111111'::UUID,
  'OWNER_UUID_HERE'::UUID, -- Replace with real owner UUID
  'Villa Mediteran - Luxury Seafront Property',
  'Stunning 4-bedroom villa with private pool and breathtaking sea views. Located in the heart of Rab Town, just 50m from the beach. Perfect for families and groups seeking a premium vacation experience.',
  'Rab Town, Island of Rab, Croatia',
  44.7604,
  14.7606,
  ARRAY['wifi', 'parking', 'pool', 'air_conditioning', 'kitchen', 'sea_view', 'balcony', 'bbq'],
  ARRAY[
    'https://images.unsplash.com/photo-1568605114967-8130f3a36994',
    'https://images.unsplash.com/photo-1512917774080-9991f1c4c750'
  ],
  'https://images.unsplash.com/photo-1568605114967-8130f3a36994',
  4.8,
  42,
  true
)
ON CONFLICT (id) DO NOTHING;

-- Property 2: Cozy Apartment in Lopar
INSERT INTO public.properties (
  id,
  owner_id,
  name,
  description,
  location,
  latitude,
  longitude,
  amenities,
  images,
  rating,
  review_count,
  is_active
) VALUES (
  '22222222-2222-2222-2222-222222222222'::UUID,
  'OWNER_UUID_HERE'::UUID, -- Replace with real owner UUID
  'Apartments Paradise - Near Paradise Beach',
  'Modern 2-bedroom apartment just 200m from the famous Paradise Beach in Lopar. Fully equipped kitchen, air conditioning, and private parking. Ideal for beach lovers.',
  'Lopar, Island of Rab, Croatia',
  44.8285,
  14.7373,
  ARRAY['wifi', 'parking', 'air_conditioning', 'kitchen', 'beach_access'],
  ARRAY[
    'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267'
  ],
  4.5,
  28,
  true
)
ON CONFLICT (id) DO NOTHING;

-- Property 3: Stone House in Barbat
INSERT INTO public.properties (
  id,
  owner_id,
  name,
  description,
  location,
  latitude,
  longitude,
  amenities,
  images,
  rating,
  review_count,
  is_active
) VALUES (
  '33333333-3333-3333-3333-333333333333'::UUID,
  'OWNER_UUID_HERE'::UUID,
  'Traditional Stone House - Authentic Experience',
  'Charming stone house with modern amenities in the peaceful village of Barbat. Features a garden, outdoor seating area, and is pet-friendly. Perfect for those seeking tranquility.',
  'Barbat, Island of Rab, Croatia',
  44.7889,
  14.7142,
  ARRAY['wifi', 'parking', 'pet_friendly', 'fireplace', 'outdoor_furniture', 'bbq'],
  ARRAY[],
  4.7,
  15,
  true
)
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- 3. TEST UNITS (for the properties above)
-- ============================================================================

-- Villa Mediteran - Unit 1: Main Villa
INSERT INTO public.units (
  id,
  property_id,
  name,
  description,
  price_per_night,
  max_guests,
  bedrooms,
  bathrooms,
  area_sqm,
  images,
  is_available,
  min_stay_nights
) VALUES (
  'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::UUID,
  '11111111-1111-1111-1111-111111111111'::UUID,
  'Entire Villa (4 Bedrooms)',
  'Full villa rental with all 4 bedrooms, private pool, and sea view terrace',
  350.00,
  10,
  4,
  3,
  200.0,
  ARRAY['https://images.unsplash.com/photo-1568605114967-8130f3a36994'],
  true,
  3
)
ON CONFLICT (id) DO NOTHING;

-- Villa Mediteran - Unit 2: Ground Floor Apartment
INSERT INTO public.units (
  id,
  property_id,
  name,
  description,
  price_per_night,
  max_guests,
  bedrooms,
  bathrooms,
  area_sqm,
  is_available,
  min_stay_nights
) VALUES (
  'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'::UUID,
  '11111111-1111-1111-1111-111111111111'::UUID,
  'Ground Floor Apartment (2 Bedrooms)',
  'Separate apartment on ground floor with 2 bedrooms and private entrance',
  180.00,
  5,
  2,
  1,
  80.0,
  true,
  2
)
ON CONFLICT (id) DO NOTHING;

-- Paradise Apartments - Unit 1
INSERT INTO public.units (
  id,
  property_id,
  name,
  description,
  price_per_night,
  max_guests,
  bedrooms,
  bathrooms,
  area_sqm,
  is_available,
  min_stay_nights
) VALUES (
  'cccccccc-cccc-cccc-cccc-cccccccccccc'::UUID,
  '22222222-2222-2222-2111-222222222222'::UUID,
  'Apartment A1',
  'Modern 2-bedroom apartment on 1st floor with balcony',
  120.00,
  4,
  2,
  1,
  65.0,
  true,
  1
)
ON CONFLICT (id) DO NOTHING;

-- Paradise Apartments - Unit 2
INSERT INTO public.units (
  id,
  property_id,
  name,
  description,
  price_per_night,
  max_guests,
  bedrooms,
  bathrooms,
  area_sqm,
  is_available,
  min_stay_nights
) VALUES (
  'dddddddd-dddd-dddd-dddd-dddddddddddd'::UUID,
  '22222222-2222-2222-2222-222222222222'::UUID,
  'Studio A2',
  'Cozy studio apartment perfect for couples',
  80.00,
  2,
  1,
  1,
  35.0,
  true,
  1
)
ON CONFLICT (id) DO NOTHING;

-- Stone House - Entire House
INSERT INTO public.units (
  id,
  property_id,
  name,
  description,
  price_per_night,
  max_guests,
  bedrooms,
  bathrooms,
  area_sqm,
  is_available,
  min_stay_nights
) VALUES (
  'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee'::UUID,
  '33333333-3333-3333-3333-333333333333'::UUID,
  'Entire Stone House',
  'Traditional stone house with 3 bedrooms and garden',
  150.00,
  6,
  3,
  2,
  120.0,
  true,
  2
)
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- 4. TEST BOOKINGS (replace GUEST_UUID_HERE with real guest UUID)
-- ============================================================================

-- Booking 1: Upcoming booking
INSERT INTO public.bookings (
  id,
  unit_id,
  guest_id,
  check_in,
  check_out,
  status,
  total_price,
  paid_amount,
  guest_count,
  notes
) VALUES (
  '99999999-9999-9999-9999-999999999991'::UUID,
  'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::UUID,
  'GUEST_UUID_HERE'::UUID, -- Replace with real guest UUID
  CURRENT_DATE + INTERVAL '30 days',
  CURRENT_DATE + INTERVAL '37 days',
  'confirmed',
  2450.00,
  490.00, -- 20% advance
  6,
  'Celebrating our anniversary. Would love a bottle of wine on arrival!'
)
ON CONFLICT (id) DO NOTHING;

-- Booking 2: Past booking (completed)
INSERT INTO public.bookings (
  id,
  unit_id,
  guest_id,
  check_in,
  check_out,
  status,
  total_price,
  paid_amount,
  guest_count
) VALUES (
  '99999999-9999-9999-9999-999999999992'::UUID,
  'cccccccc-cccc-cccc-cccc-cccccccccccc'::UUID,
  'GUEST_UUID_HERE'::UUID,
  CURRENT_DATE - INTERVAL '60 days',
  CURRENT_DATE - INTERVAL '53 days',
  'completed',
  840.00,
  840.00, -- Fully paid
  4
)
ON CONFLICT (id) DO NOTHING;

-- Booking 3: Pending booking
INSERT INTO public.bookings (
  id,
  unit_id,
  guest_id,
  check_in,
  check_out,
  status,
  total_price,
  paid_amount,
  guest_count
) VALUES (
  '99999999-9999-9999-9999-999999999993'::UUID,
  'dddddddd-dddd-dddd-dddd-dddddddddddd'::UUID,
  'GUEST_UUID_HERE'::UUID,
  CURRENT_DATE + INTERVAL '15 days',
  CURRENT_DATE + INTERVAL '20 days',
  'pending',
  400.00,
  80.00, -- 20% advance
  2
)
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- 5. TEST PAYMENTS
-- ============================================================================

-- Payment for Booking 1 (advance)
INSERT INTO public.payments (
  id,
  booking_id,
  amount,
  currency,
  payment_type,
  payment_method,
  stripe_payment_intent_id,
  status,
  paid_at
) VALUES (
  '88888888-8888-8888-8888-888888888881'::UUID,
  '99999999-9999-9999-9999-999999999991'::UUID,
  490.00,
  'EUR',
  'advance',
  'card',
  'pi_test_1234567890',
  'succeeded',
  CURRENT_DATE - INTERVAL '10 days'
)
ON CONFLICT (id) DO NOTHING;

-- Payment for Booking 2 (full payment)
INSERT INTO public.payments (
  id,
  booking_id,
  amount,
  currency,
  payment_type,
  payment_method,
  status,
  paid_at
) VALUES (
  '88888888-8888-8888-8888-888888888882'::UUID,
  '99999999-9999-9999-9999-999999999992'::UUID,
  840.00,
  'EUR',
  'full',
  'card',
  'succeeded',
  CURRENT_DATE - INTERVAL '61 days'
)
ON CONFLICT (id) DO NOTHING;

-- Payment for Booking 3 (advance)
INSERT INTO public.payments (
  id,
  booking_id,
  amount,
  currency,
  payment_type,
  payment_method,
  stripe_payment_intent_id,
  status,
  paid_at
) VALUES (
  '88888888-8888-8888-8888-888888888883'::UUID,
  '99999999-9999-9999-9999-999999999993'::UUID,
  80.00,
  'EUR',
  'advance',
  'card',
  'pi_test_0987654321',
  'succeeded',
  CURRENT_DATE - INTERVAL '2 days'
)
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- SEED DATA COMPLETE!
-- ============================================================================

-- Verify data was inserted
SELECT 'Properties: ' || COUNT(*)::TEXT FROM public.properties;
SELECT 'Units: ' || COUNT(*)::TEXT FROM public.units;
SELECT 'Bookings: ' || COUNT(*)::TEXT FROM public.bookings;
SELECT 'Payments: ' || COUNT(*)::TEXT FROM public.payments;
