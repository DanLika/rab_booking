-- ============================================================================
-- Analytics Views and Functions for Owner Dashboard
-- ============================================================================
-- This migration creates optimized views and functions for analytics queries
-- to improve performance and reduce complexity in application code.

-- ============================================================================
-- 1. Property Revenue View
-- ============================================================================
-- Aggregated revenue data per property
CREATE OR REPLACE VIEW property_revenue_view AS
SELECT
    p.id AS property_id,
    p.name AS property_name,
    p.owner_id,
    COUNT(DISTINCT b.id) AS total_bookings,
    COALESCE(SUM(b.total_price), 0) AS total_revenue,
    COALESCE(AVG(b.total_price), 0) AS average_booking_value,
    MIN(b.check_in) AS first_booking_date,
    MAX(b.check_out) AS last_booking_date
FROM properties p
LEFT JOIN bookings b ON p.id = b.property_id
    AND b.status NOT IN ('cancelled', 'pending')
GROUP BY p.id, p.name, p.owner_id;

-- Grant access to authenticated users
GRANT SELECT ON property_revenue_view TO authenticated;

-- ============================================================================
-- 2. Monthly Revenue View
-- ============================================================================
-- Revenue aggregated by month for time-series charts
CREATE OR REPLACE VIEW monthly_revenue_view AS
SELECT
    p.owner_id,
    p.id AS property_id,
    DATE_TRUNC('month', b.check_in) AS month,
    COUNT(b.id) AS booking_count,
    COALESCE(SUM(b.total_price), 0) AS revenue,
    COALESCE(AVG(b.total_price), 0) AS avg_booking_value
FROM properties p
LEFT JOIN bookings b ON p.id = b.property_id
    AND b.status NOT IN ('cancelled', 'pending')
WHERE b.check_in IS NOT NULL
GROUP BY p.owner_id, p.id, DATE_TRUNC('month', b.check_in)
ORDER BY month DESC;

-- Grant access to authenticated users
GRANT SELECT ON monthly_revenue_view TO authenticated;

-- ============================================================================
-- 3. Property Occupancy View
-- ============================================================================
-- Calculate occupancy rates for properties
CREATE OR REPLACE VIEW property_occupancy_view AS
SELECT
    p.id AS property_id,
    p.name AS property_name,
    p.owner_id,
    COUNT(DISTINCT b.id) AS total_bookings,
    SUM(
        CASE
            WHEN b.check_out IS NOT NULL AND b.check_in IS NOT NULL
            THEN EXTRACT(DAY FROM (b.check_out - b.check_in))
            ELSE 0
        END
    ) AS total_booked_days,
    -- Calculate occupancy rate for last 365 days
    ROUND(
        (SUM(
            CASE
                WHEN b.check_out IS NOT NULL AND b.check_in IS NOT NULL
                THEN EXTRACT(DAY FROM (b.check_out - b.check_in))
                ELSE 0
            END
        ) / NULLIF(365.0, 0)) * 100,
        2
    ) AS occupancy_rate_percent
FROM properties p
LEFT JOIN bookings b ON p.id = b.property_id
    AND b.status NOT IN ('cancelled', 'pending')
    AND b.check_in >= CURRENT_DATE - INTERVAL '365 days'
GROUP BY p.id, p.name, p.owner_id;

-- Grant access to authenticated users
GRANT SELECT ON property_occupancy_view TO authenticated;

-- ============================================================================
-- 4. Owner Analytics Summary Function
-- ============================================================================
-- Function to get comprehensive analytics for an owner within a date range
CREATE OR REPLACE FUNCTION get_owner_analytics_summary(
    p_owner_id UUID,
    p_start_date TIMESTAMPTZ,
    p_end_date TIMESTAMPTZ
)
RETURNS TABLE (
    total_revenue NUMERIC,
    total_bookings BIGINT,
    average_booking_value NUMERIC,
    total_properties BIGINT,
    active_properties BIGINT,
    total_booked_days NUMERIC,
    cancellation_rate NUMERIC,
    average_rating NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    WITH booking_stats AS (
        SELECT
            COALESCE(SUM(b.total_price), 0) AS revenue,
            COUNT(b.id) AS bookings,
            COALESCE(AVG(b.total_price), 0) AS avg_value,
            SUM(
                CASE
                    WHEN b.check_out IS NOT NULL AND b.check_in IS NOT NULL
                    THEN EXTRACT(DAY FROM (b.check_out - b.check_in))
                    ELSE 0
                END
            ) AS booked_days
        FROM bookings b
        INNER JOIN properties p ON b.property_id = p.id
        WHERE p.owner_id = p_owner_id
            AND b.check_in >= p_start_date
            AND b.check_in <= p_end_date
            AND b.status NOT IN ('cancelled', 'pending')
    ),
    cancellation_stats AS (
        SELECT
            COUNT(CASE WHEN b.status = 'cancelled' THEN 1 END)::NUMERIC AS cancelled_count,
            COUNT(b.id)::NUMERIC AS total_count
        FROM bookings b
        INNER JOIN properties p ON b.property_id = p.id
        WHERE p.owner_id = p_owner_id
            AND b.check_in >= p_start_date
            AND b.check_in <= p_end_date
    ),
    property_stats AS (
        SELECT
            COUNT(p.id) AS total_props,
            COUNT(CASE WHEN p.is_active = true THEN 1 END) AS active_props
        FROM properties p
        WHERE p.owner_id = p_owner_id
    ),
    rating_stats AS (
        SELECT
            COALESCE(AVG(r.rating), 0) AS avg_rating
        FROM reviews r
        INNER JOIN properties p ON r.property_id = p.id
        WHERE p.owner_id = p_owner_id
    )
    SELECT
        bs.revenue,
        bs.bookings,
        bs.avg_value,
        ps.total_props,
        ps.active_props,
        bs.booked_days,
        CASE
            WHEN cs.total_count > 0
            THEN ROUND((cs.cancelled_count / cs.total_count) * 100, 2)
            ELSE 0
        END AS cancel_rate,
        rs.avg_rating
    FROM booking_stats bs
    CROSS JOIN cancellation_stats cs
    CROSS JOIN property_stats ps
    CROSS JOIN rating_stats rs;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_owner_analytics_summary TO authenticated;

-- ============================================================================
-- 5. Property Performance Function
-- ============================================================================
-- Get top performing properties for an owner
CREATE OR REPLACE FUNCTION get_top_performing_properties(
    p_owner_id UUID,
    p_start_date TIMESTAMPTZ,
    p_end_date TIMESTAMPTZ,
    p_limit INTEGER DEFAULT 5
)
RETURNS TABLE (
    property_id UUID,
    property_name TEXT,
    revenue NUMERIC,
    booking_count BIGINT,
    occupancy_rate NUMERIC,
    average_rating NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        p.id,
        p.name,
        COALESCE(SUM(b.total_price), 0) AS revenue,
        COUNT(b.id) AS booking_count,
        ROUND(
            (SUM(
                CASE
                    WHEN b.check_out IS NOT NULL AND b.check_in IS NOT NULL
                    THEN EXTRACT(DAY FROM (b.check_out - b.check_in))
                    ELSE 0
                END
            ) / NULLIF(EXTRACT(DAY FROM (p_end_date - p_start_date)), 0)) * 100,
            2
        ) AS occupancy_rate,
        COALESCE(AVG(r.rating), 0) AS average_rating
    FROM properties p
    LEFT JOIN bookings b ON p.id = b.property_id
        AND b.status NOT IN ('cancelled', 'pending')
        AND b.check_in >= p_start_date
        AND b.check_in <= p_end_date
    LEFT JOIN reviews r ON p.id = r.property_id
    WHERE p.owner_id = p_owner_id
    GROUP BY p.id, p.name
    HAVING COUNT(b.id) > 0
    ORDER BY revenue DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_top_performing_properties TO authenticated;

-- ============================================================================
-- 6. Revenue Time Series Function
-- ============================================================================
-- Get revenue data grouped by time period (day, week, month)
CREATE OR REPLACE FUNCTION get_revenue_time_series(
    p_owner_id UUID,
    p_start_date TIMESTAMPTZ,
    p_end_date TIMESTAMPTZ,
    p_interval TEXT DEFAULT 'month' -- 'day', 'week', 'month'
)
RETURNS TABLE (
    period_start TIMESTAMPTZ,
    period_label TEXT,
    revenue NUMERIC,
    booking_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        DATE_TRUNC(p_interval, b.check_in) AS period_start,
        TO_CHAR(DATE_TRUNC(p_interval, b.check_in),
            CASE
                WHEN p_interval = 'day' THEN 'Mon DD'
                WHEN p_interval = 'week' THEN 'Mon DD'
                WHEN p_interval = 'month' THEN 'Mon'
                ELSE 'Mon YYYY'
            END
        ) AS period_label,
        COALESCE(SUM(b.total_price), 0) AS revenue,
        COUNT(b.id) AS booking_count
    FROM bookings b
    INNER JOIN properties p ON b.property_id = p.id
    WHERE p.owner_id = p_owner_id
        AND b.check_in >= p_start_date
        AND b.check_in <= p_end_date
        AND b.status NOT IN ('cancelled', 'pending')
    GROUP BY DATE_TRUNC(p_interval, b.check_in)
    ORDER BY period_start ASC;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_revenue_time_series TO authenticated;

-- ============================================================================
-- 7. Booking Status Distribution View
-- ============================================================================
-- Distribution of booking statuses
CREATE OR REPLACE VIEW booking_status_distribution AS
SELECT
    p.owner_id,
    b.status,
    COUNT(b.id) AS count,
    ROUND(
        (COUNT(b.id)::NUMERIC / NULLIF(SUM(COUNT(b.id)) OVER (PARTITION BY p.owner_id), 0)) * 100,
        2
    ) AS percentage
FROM bookings b
INNER JOIN properties p ON b.property_id = p.id
GROUP BY p.owner_id, b.status;

-- Grant access to authenticated users
GRANT SELECT ON booking_status_distribution TO authenticated;

-- ============================================================================
-- 8. Create indexes for better performance
-- ============================================================================

-- Index on bookings for analytics queries
CREATE INDEX IF NOT EXISTS idx_bookings_analytics
ON bookings(property_id, check_in, status)
WHERE status NOT IN ('cancelled', 'pending');

-- Index on bookings for time-series queries
CREATE INDEX IF NOT EXISTS idx_bookings_checkin_month
ON bookings(DATE_TRUNC('month', check_in));

-- Index on reviews for rating calculations
CREATE INDEX IF NOT EXISTS idx_reviews_property_rating
ON reviews(property_id, rating);

-- ============================================================================
-- Comments for documentation
-- ============================================================================

COMMENT ON VIEW property_revenue_view IS
'Aggregated revenue and booking statistics per property';

COMMENT ON VIEW monthly_revenue_view IS
'Monthly revenue and booking counts for time-series analysis';

COMMENT ON VIEW property_occupancy_view IS
'Property occupancy rates calculated over the last 365 days';

COMMENT ON FUNCTION get_owner_analytics_summary IS
'Comprehensive analytics summary for an owner within a date range';

COMMENT ON FUNCTION get_top_performing_properties IS
'Returns top N performing properties ranked by revenue';

COMMENT ON FUNCTION get_revenue_time_series IS
'Revenue time-series data grouped by day, week, or month';

COMMENT ON VIEW booking_status_distribution IS
'Distribution of booking statuses by owner with percentages';
