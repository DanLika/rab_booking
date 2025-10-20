-- Create saved_searches table for storing user saved search filters
CREATE TABLE IF NOT EXISTS public.saved_searches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  filters JSONB NOT NULL,
  notification_enabled BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

  -- Ensure reasonable limits
  CONSTRAINT name_length CHECK (char_length(name) >= 1 AND char_length(name) <= 100)
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_saved_searches_user_id ON public.saved_searches(user_id);
CREATE INDEX IF NOT EXISTS idx_saved_searches_created_at ON public.saved_searches(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_saved_searches_notification_enabled ON public.saved_searches(notification_enabled) WHERE notification_enabled = true;

-- Enable RLS
ALTER TABLE public.saved_searches ENABLE ROW LEVEL SECURITY;

-- RLS Policies

-- Users can view their own saved searches
CREATE POLICY "Users can view their own saved searches"
  ON public.saved_searches
  FOR SELECT
  USING (auth.uid() = user_id);

-- Users can insert their own saved searches
CREATE POLICY "Users can insert their own saved searches"
  ON public.saved_searches
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can update their own saved searches
CREATE POLICY "Users can update their own saved searches"
  ON public.saved_searches
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Users can delete their own saved searches
CREATE POLICY "Users can delete their own saved searches"
  ON public.saved_searches
  FOR DELETE
  USING (auth.uid() = user_id);

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION update_saved_searches_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER saved_searches_updated_at
  BEFORE UPDATE ON public.saved_searches
  FOR EACH ROW
  EXECUTE FUNCTION update_saved_searches_updated_at();

-- Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON public.saved_searches TO authenticated;

-- Add helpful comment
COMMENT ON TABLE public.saved_searches IS 'Stores user saved search filters for quick access and notifications';
COMMENT ON COLUMN public.saved_searches.filters IS 'JSONB column storing SearchFilters model data';
COMMENT ON COLUMN public.saved_searches.notification_enabled IS 'Whether user wants notifications for new properties matching this search';
