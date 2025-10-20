-- Create saved_searches table for saving user search criteria
CREATE TABLE IF NOT EXISTS saved_searches (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  filters JSONB NOT NULL,
  notification_enabled BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for fast user queries
CREATE INDEX idx_saved_searches_user
  ON saved_searches(user_id, created_at DESC);

-- RLS Policies
ALTER TABLE saved_searches ENABLE ROW LEVEL SECURITY;

-- Users can view their own saved searches
CREATE POLICY "Users can view their own saved searches"
  ON saved_searches
  FOR SELECT
  USING (auth.uid() = user_id);

-- Users can insert their own saved searches
CREATE POLICY "Users can insert their own saved searches"
  ON saved_searches
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can update their own saved searches
CREATE POLICY "Users can update their own saved searches"
  ON saved_searches
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Users can delete their own saved searches
CREATE POLICY "Users can delete their own saved searches"
  ON saved_searches
  FOR DELETE
  USING (auth.uid() = user_id);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_saved_searches_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update timestamp on update
CREATE TRIGGER update_saved_searches_timestamp
  BEFORE UPDATE ON saved_searches
  FOR EACH ROW
  EXECUTE FUNCTION update_saved_searches_updated_at();

-- Comment
COMMENT ON TABLE saved_searches IS 'Stores user saved search criteria with filters';
COMMENT ON COLUMN saved_searches.filters IS 'JSONB containing SearchFilters model as JSON';
COMMENT ON COLUMN saved_searches.notification_enabled IS 'Whether to notify user when new properties match this search';
