-- Performance Optimization Indexes
-- Migration: 004_performance_indexes
-- Description: Add indexes for common queries to improve performance

-- ============================================================================
-- PROPERTIES TABLE INDEXES
-- ============================================================================

-- Composite index for location-based searches with status filter
-- Speeds up queries like: "Find all published properties in Rab"
CREATE INDEX IF NOT EXISTS idx_properties_location_status
ON properties(location, status);

-- Index for price range queries
-- Speeds up queries like: "Find properties between $100-$300 per night"
CREATE INDEX IF NOT EXISTS idx_properties_price
ON properties(price_per_night);

-- Partial index for published properties only
-- Reduces index size by only indexing published properties
-- Speeds up homepage and search queries
CREATE INDEX IF NOT EXISTS idx_properties_published
ON properties(created_at DESC)
WHERE status = 'published';

-- Index for owner queries
-- Speeds up owner dashboard: "Show all my properties"
CREATE INDEX IF NOT EXISTS idx_properties_owner_id
ON properties(owner_id);

-- Full-text search index for property names and descriptions
-- Enables fast text search: "villa beach sea view"
CREATE INDEX IF NOT EXISTS idx_properties_search
ON properties USING GIN (
  to_tsvector('english', COALESCE(name, '') || ' ' || COALESCE(description, ''))
);

-- Index for featured properties
-- Speeds up homepage featured properties query
CREATE INDEX IF NOT EXISTS idx_properties_featured
ON properties(is_featured, created_at DESC)
WHERE status = 'published' AND is_featured = true;

-- ============================================================================
-- UNITS TABLE INDEXES
-- ============================================================================

-- Index for property-unit relationship
-- Speeds up queries: "Show all units for this property"
CREATE INDEX IF NOT EXISTS idx_units_property_id
ON units(property_id);

-- Composite index for available units by property
-- Speeds up booking queries: "Show available units for this property"
CREATE INDEX IF NOT EXISTS idx_units_property_status
ON units(property_id, status)
WHERE status = 'available';

-- Index for max guests filter
-- Speeds up queries: "Find units that fit 4 guests"
CREATE INDEX IF NOT EXISTS idx_units_max_guests
ON units(max_guests);

-- ============================================================================
-- BOOKINGS TABLE INDEXES
-- ============================================================================

-- Composite index for date range queries
-- Critical for availability checks: "Is this property available from X to Y?"
CREATE INDEX IF NOT EXISTS idx_bookings_dates
ON bookings(check_in, check_out);

-- Index for property bookings
-- Speeds up queries: "Show all bookings for this property"
CREATE INDEX IF NOT EXISTS idx_bookings_property_id
ON bookings(property_id);

-- Index for unit bookings
-- Speeds up queries: "Show all bookings for this unit"
CREATE INDEX IF NOT EXISTS idx_bookings_unit_id
ON bookings(unit_id);

-- Index for user bookings
-- Speeds up user dashboard: "Show my bookings"
CREATE INDEX IF NOT EXISTS idx_bookings_user_id
ON bookings(user_id, created_at DESC);

-- Composite index for active bookings
-- Speeds up queries: "Show all confirmed/pending bookings"
CREATE INDEX IF NOT EXISTS idx_bookings_status_dates
ON bookings(status, check_in, check_out)
WHERE status IN ('confirmed', 'pending');

-- Index for upcoming bookings
-- Speeds up queries: "Show upcoming bookings"
CREATE INDEX IF NOT EXISTS idx_bookings_upcoming
ON bookings(check_in)
WHERE check_in >= CURRENT_DATE AND status = 'confirmed';

-- ============================================================================
-- PAYMENTS TABLE INDEXES
-- ============================================================================

-- Index for booking payments
-- Speeds up queries: "Show payment for this booking"
CREATE INDEX IF NOT EXISTS idx_payments_booking_id
ON payments(booking_id);

-- Index for user payments
-- Speeds up user payment history: "Show my payment history"
CREATE INDEX IF NOT EXISTS idx_payments_user_id
ON payments(user_id, created_at DESC);

-- Index for payment status
-- Speeds up admin queries: "Show all pending payments"
CREATE INDEX IF NOT EXISTS idx_payments_status
ON payments(status, created_at DESC);

-- Index for Stripe payment intents
-- Speeds up webhook processing
CREATE INDEX IF NOT EXISTS idx_payments_stripe_payment_intent_id
ON payments(stripe_payment_intent_id)
WHERE stripe_payment_intent_id IS NOT NULL;

-- ============================================================================
-- REVIEWS TABLE INDEXES
-- ============================================================================

-- Index for property reviews
-- Speeds up queries: "Show all reviews for this property"
CREATE INDEX IF NOT EXISTS idx_reviews_property_id
ON reviews(property_id, created_at DESC);

-- Index for user reviews
-- Speeds up queries: "Show all reviews by this user"
CREATE INDEX IF NOT EXISTS idx_reviews_user_id
ON reviews(user_id, created_at DESC);

-- Composite index for approved reviews with rating
-- Speeds up queries: "Show high-rated reviews"
CREATE INDEX IF NOT EXISTS idx_reviews_approved_rating
ON reviews(property_id, rating DESC, created_at DESC)
WHERE status = 'approved';

-- ============================================================================
-- USERS TABLE INDEXES
-- ============================================================================

-- Index for email lookups (if not already created as unique)
CREATE INDEX IF NOT EXISTS idx_users_email
ON users(email);

-- Index for user roles
-- Speeds up admin queries: "Show all property owners"
CREATE INDEX IF NOT EXISTS idx_users_role
ON users(role);

-- ============================================================================
-- FAVORITES TABLE INDEXES
-- ============================================================================

-- Composite index for user favorites
-- Speeds up queries: "Show my favorite properties"
CREATE INDEX IF NOT EXISTS idx_favorites_user_property
ON favorites(user_id, property_id);

-- Reverse index for property favorites count
-- Speeds up queries: "How many users favorited this property?"
CREATE INDEX IF NOT EXISTS idx_favorites_property_id
ON favorites(property_id);

-- ============================================================================
-- QUERY EXAMPLES USING THESE INDEXES
-- ============================================================================

-- Example 1: Full-text search for properties
-- Uses: idx_properties_search
/*
SELECT * FROM properties
WHERE to_tsvector('english', name || ' ' || description)
      @@ to_tsquery('english', 'villa & beach')
  AND status = 'published';
*/

-- Example 2: Check availability for a date range
-- Uses: idx_bookings_dates, idx_bookings_property_id
/*
SELECT * FROM bookings
WHERE property_id = '123'
  AND status IN ('confirmed', 'pending')
  AND (
    (check_in >= '2025-06-01' AND check_in < '2025-06-10')
    OR (check_out > '2025-06-01' AND check_out <= '2025-06-10')
    OR (check_in <= '2025-06-01' AND check_out >= '2025-06-10')
  );
*/

-- Example 3: Search properties by location and price
-- Uses: idx_properties_location_status, idx_properties_price
/*
SELECT * FROM properties
WHERE location = 'Rab'
  AND status = 'published'
  AND price_per_night BETWEEN 100 AND 300
ORDER BY created_at DESC
LIMIT 20;
*/

-- Example 4: Get user's upcoming bookings
-- Uses: idx_bookings_user_id
/*
SELECT * FROM bookings
WHERE user_id = '123'
  AND check_in >= CURRENT_DATE
  AND status = 'confirmed'
ORDER BY check_in ASC;
*/

-- Example 5: Featured properties for homepage
-- Uses: idx_properties_featured
/*
SELECT * FROM properties
WHERE status = 'published'
  AND is_featured = true
ORDER BY created_at DESC
LIMIT 10;
*/

-- ============================================================================
-- INDEX MAINTENANCE NOTES
-- ============================================================================

-- To analyze index usage in Supabase:
-- SELECT schemaname, tablename, indexname, idx_scan, idx_tup_read, idx_tup_fetch
-- FROM pg_stat_user_indexes
-- ORDER BY idx_scan DESC;

-- To check index size:
-- SELECT schemaname, tablename, indexname, pg_size_pretty(pg_relation_size(indexrelid))
-- FROM pg_stat_user_indexes
-- ORDER BY pg_relation_size(indexrelid) DESC;

-- To find unused indexes:
-- SELECT schemaname, tablename, indexname
-- FROM pg_stat_user_indexes
-- WHERE idx_scan = 0
-- AND indexrelname NOT LIKE 'pg_toast%';
