-- Create analytics tables for tracking user behavior and business metrics
-- This enables advanced analytics dashboard for owners and admins

-- 1. Property Analytics Table
-- Tracks views, favorites, bookings per property
CREATE TABLE IF NOT EXISTS property_analytics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
  date DATE NOT NULL,

  -- Engagement metrics
  views_count INTEGER NOT NULL DEFAULT 0,
  unique_views_count INTEGER NOT NULL DEFAULT 0,
  favorites_count INTEGER NOT NULL DEFAULT 0,
  shares_count INTEGER NOT NULL DEFAULT 0,

  -- Booking metrics
  booking_requests_count INTEGER NOT NULL DEFAULT 0,
  bookings_count INTEGER NOT NULL DEFAULT 0,
  cancellations_count INTEGER NOT NULL DEFAULT 0,

  -- Revenue metrics
  revenue DECIMAL(10, 2) NOT NULL DEFAULT 0,
  avg_booking_value DECIMAL(10, 2) NOT NULL DEFAULT 0,

  -- Search metrics
  search_appearances_count INTEGER NOT NULL DEFAULT 0,
  search_clicks_count INTEGER NOT NULL DEFAULT 0,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- Unique constraint for property + date
  UNIQUE(property_id, date)
);

-- 2. User Analytics Table
-- Tracks user behavior and engagement
CREATE TABLE IF NOT EXISTS user_analytics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  date DATE NOT NULL,

  -- Session metrics
  sessions_count INTEGER NOT NULL DEFAULT 0,
  session_duration_seconds INTEGER NOT NULL DEFAULT 0,

  -- Search metrics
  searches_count INTEGER NOT NULL DEFAULT 0,
  properties_viewed_count INTEGER NOT NULL DEFAULT 0,

  -- Booking metrics
  bookings_created_count INTEGER NOT NULL DEFAULT 0,
  bookings_completed_count INTEGER NOT NULL DEFAULT 0,
  bookings_cancelled_count INTEGER NOT NULL DEFAULT 0,

  -- Spending metrics
  total_spent DECIMAL(10, 2) NOT NULL DEFAULT 0,
  avg_booking_value DECIMAL(10, 2) NOT NULL DEFAULT 0,

  -- Engagement metrics
  reviews_written_count INTEGER NOT NULL DEFAULT 0,
  favorites_added_count INTEGER NOT NULL DEFAULT 0,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  UNIQUE(user_id, date)
);

-- 3. System Analytics Table
-- Tracks overall platform metrics
CREATE TABLE IF NOT EXISTS system_analytics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  date DATE NOT NULL UNIQUE,

  -- User metrics
  new_users_count INTEGER NOT NULL DEFAULT 0,
  active_users_count INTEGER NOT NULL DEFAULT 0,
  total_users_count INTEGER NOT NULL DEFAULT 0,

  -- Property metrics
  new_properties_count INTEGER NOT NULL DEFAULT 0,
  active_properties_count INTEGER NOT NULL DEFAULT 0,
  total_properties_count INTEGER NOT NULL DEFAULT 0,

  -- Booking metrics
  bookings_count INTEGER NOT NULL DEFAULT 0,
  completed_bookings_count INTEGER NOT NULL DEFAULT 0,
  cancelled_bookings_count INTEGER NOT NULL DEFAULT 0,

  -- Revenue metrics
  gross_revenue DECIMAL(10, 2) NOT NULL DEFAULT 0,
  net_revenue DECIMAL(10, 2) NOT NULL DEFAULT 0,
  platform_fees DECIMAL(10, 2) NOT NULL DEFAULT 0,

  -- Search metrics
  total_searches_count INTEGER NOT NULL DEFAULT 0,
  avg_results_per_search DECIMAL(10, 2) NOT NULL DEFAULT 0,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. Events Table (for raw event tracking)
-- Stores individual user events for detailed analytics
CREATE TABLE IF NOT EXISTS analytics_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  session_id UUID,

  -- Event details
  event_type VARCHAR(100) NOT NULL,
  event_name VARCHAR(255) NOT NULL,

  -- Context
  property_id UUID REFERENCES properties(id) ON DELETE SET NULL,
  booking_id UUID REFERENCES bookings(id) ON DELETE SET NULL,

  -- Metadata
  metadata JSONB DEFAULT '{}'::jsonb,

  -- Device/Platform info
  device_type VARCHAR(50),
  platform VARCHAR(50),
  browser VARCHAR(100),

  -- Location
  country VARCHAR(100),
  city VARCHAR(100),

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_property_analytics_property_date ON property_analytics(property_id, date DESC);
CREATE INDEX IF NOT EXISTS idx_property_analytics_date ON property_analytics(date DESC);

CREATE INDEX IF NOT EXISTS idx_user_analytics_user_date ON user_analytics(user_id, date DESC);
CREATE INDEX IF NOT EXISTS idx_user_analytics_date ON user_analytics(date DESC);

CREATE INDEX IF NOT EXISTS idx_system_analytics_date ON system_analytics(date DESC);

CREATE INDEX IF NOT EXISTS idx_analytics_events_user ON analytics_events(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_analytics_events_type ON analytics_events(event_type, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_analytics_events_property ON analytics_events(property_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_analytics_events_created_at ON analytics_events(created_at DESC);

-- Enable Row Level Security
ALTER TABLE property_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE system_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE analytics_events ENABLE ROW LEVEL SECURITY;

-- RLS Policies for property_analytics
-- Property owners can read their own property analytics
CREATE POLICY "Property owners can read their analytics"
  ON property_analytics
  FOR SELECT
  USING (
    property_id IN (
      SELECT id FROM properties WHERE owner_id = auth.uid()
    )
  );

-- Admins can read all property analytics
CREATE POLICY "Admins can read all property analytics"
  ON property_analytics
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Service role can insert/update property analytics
CREATE POLICY "Service role can manage property analytics"
  ON property_analytics
  FOR ALL
  USING (true)
  WITH CHECK (true);

-- RLS Policies for user_analytics
-- Users can read their own analytics
CREATE POLICY "Users can read their own analytics"
  ON user_analytics
  FOR SELECT
  USING (user_id = auth.uid());

-- Admins can read all user analytics
CREATE POLICY "Admins can read all user analytics"
  ON user_analytics
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Service role can manage user analytics
CREATE POLICY "Service role can manage user analytics"
  ON user_analytics
  FOR ALL
  USING (true)
  WITH CHECK (true);

-- RLS Policies for system_analytics
-- Only admins can read system analytics
CREATE POLICY "Admins can read system analytics"
  ON system_analytics
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Service role can manage system analytics
CREATE POLICY "Service role can manage system analytics"
  ON system_analytics
  FOR ALL
  USING (true)
  WITH CHECK (true);

-- RLS Policies for analytics_events
-- Users can read their own events
CREATE POLICY "Users can read their own events"
  ON analytics_events
  FOR SELECT
  USING (user_id = auth.uid());

-- Property owners can read events for their properties
CREATE POLICY "Property owners can read property events"
  ON analytics_events
  FOR SELECT
  USING (
    property_id IN (
      SELECT id FROM properties WHERE owner_id = auth.uid()
    )
  );

-- Admins can read all events
CREATE POLICY "Admins can read all events"
  ON analytics_events
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Service role can manage events
CREATE POLICY "Service role can manage events"
  ON analytics_events
  FOR ALL
  USING (true)
  WITH CHECK (true);

-- Trigger to auto-update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_property_analytics_updated_at ON property_analytics;
CREATE TRIGGER update_property_analytics_updated_at
  BEFORE UPDATE ON property_analytics
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_user_analytics_updated_at ON user_analytics;
CREATE TRIGGER update_user_analytics_updated_at
  BEFORE UPDATE ON user_analytics
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_system_analytics_updated_at ON system_analytics;
CREATE TRIGGER update_system_analytics_updated_at
  BEFORE UPDATE ON system_analytics
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Helper functions for analytics

-- Function to track property view
CREATE OR REPLACE FUNCTION track_property_view(
  p_property_id UUID,
  p_user_id UUID DEFAULT NULL,
  p_session_id UUID DEFAULT NULL
)
RETURNS void AS $$
BEGIN
  -- Insert event
  INSERT INTO analytics_events (user_id, session_id, event_type, event_name, property_id)
  VALUES (p_user_id, p_session_id, 'property', 'view', p_property_id);

  -- Update daily analytics
  INSERT INTO property_analytics (property_id, date, views_count, unique_views_count)
  VALUES (p_property_id, CURRENT_DATE, 1, CASE WHEN p_user_id IS NOT NULL THEN 1 ELSE 0 END)
  ON CONFLICT (property_id, date)
  DO UPDATE SET
    views_count = property_analytics.views_count + 1,
    unique_views_count = property_analytics.unique_views_count + CASE WHEN p_user_id IS NOT NULL THEN 1 ELSE 0 END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get property analytics summary
CREATE OR REPLACE FUNCTION get_property_analytics_summary(
  p_property_id UUID,
  p_start_date DATE,
  p_end_date DATE
)
RETURNS TABLE (
  total_views BIGINT,
  total_bookings BIGINT,
  total_revenue NUMERIC,
  avg_booking_value NUMERIC,
  conversion_rate NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    SUM(views_count)::BIGINT as total_views,
    SUM(bookings_count)::BIGINT as total_bookings,
    SUM(revenue)::NUMERIC as total_revenue,
    AVG(avg_booking_value)::NUMERIC as avg_booking_value,
    CASE
      WHEN SUM(views_count) > 0
      THEN (SUM(bookings_count)::NUMERIC / SUM(views_count)::NUMERIC * 100)
      ELSE 0
    END as conversion_rate
  FROM property_analytics
  WHERE property_id = p_property_id
    AND date BETWEEN p_start_date AND p_end_date;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION track_property_view TO authenticated, anon;
GRANT EXECUTE ON FUNCTION get_property_analytics_summary TO authenticated;

-- Comments
COMMENT ON TABLE property_analytics IS 'Daily analytics per property';
COMMENT ON TABLE user_analytics IS 'Daily analytics per user';
COMMENT ON TABLE system_analytics IS 'Daily system-wide analytics';
COMMENT ON TABLE analytics_events IS 'Raw event tracking for detailed analytics';
