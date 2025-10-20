-- Create recently_viewed table for tracking user property views
CREATE TABLE IF NOT EXISTS recently_viewed (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  property_id UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
  viewed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- Ensure one entry per user-property pair
  UNIQUE(user_id, property_id)
);

-- Index for fast queries ordered by most recent
CREATE INDEX idx_recently_viewed_user_time
  ON recently_viewed(user_id, viewed_at DESC);

-- Index for property lookups
CREATE INDEX idx_recently_viewed_property
  ON recently_viewed(property_id);

-- RLS Policies
ALTER TABLE recently_viewed ENABLE ROW LEVEL SECURITY;

-- Users can view their own recently viewed properties
CREATE POLICY "Users can view their own recently viewed"
  ON recently_viewed
  FOR SELECT
  USING (auth.uid() = user_id);

-- Users can insert their own views
CREATE POLICY "Users can insert their own views"
  ON recently_viewed
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can update their own views (refresh timestamp)
CREATE POLICY "Users can update their own views"
  ON recently_viewed
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Users can delete their own views
CREATE POLICY "Users can delete their own views"
  ON recently_viewed
  FOR DELETE
  USING (auth.uid() = user_id);

-- Function to update viewed_at timestamp on conflict
CREATE OR REPLACE FUNCTION update_recently_viewed_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.viewed_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update timestamp when same property is viewed again
CREATE TRIGGER update_recently_viewed_timestamp_trigger
  BEFORE UPDATE ON recently_viewed
  FOR EACH ROW
  EXECUTE FUNCTION update_recently_viewed_timestamp();

-- Comment
COMMENT ON TABLE recently_viewed IS 'Tracks user property views for Recently Viewed feature';
