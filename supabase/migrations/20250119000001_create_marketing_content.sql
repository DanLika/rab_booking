-- Marketing Content Tables for Dynamic Home Page
-- Created: 2025-10-19
-- Purpose: Replace hardcoded data with database-driven content

-- =====================================================
-- 1. POPULAR DESTINATIONS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS popular_destinations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  location TEXT NOT NULL,
  description TEXT,
  image_url TEXT NOT NULL,
  property_count INT DEFAULT 0,
  display_order INT DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for active destinations
CREATE INDEX idx_popular_destinations_active
ON popular_destinations(is_active, display_order);

-- =====================================================
-- 2. HOW IT WORKS STEPS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS how_it_works_steps (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  step_number INT NOT NULL UNIQUE,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  icon_name TEXT NOT NULL, -- Flutter icon identifier (e.g., 'search', 'calendar_today')
  is_active BOOLEAN DEFAULT true,
  display_order INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for active steps
CREATE INDEX idx_how_it_works_active
ON how_it_works_steps(is_active, step_number);

-- =====================================================
-- 3. TESTIMONIALS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS testimonials (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  customer_name TEXT NOT NULL,
  customer_avatar_url TEXT,
  customer_location TEXT NOT NULL,
  rating DECIMAL(2,1) CHECK (rating >= 0 AND rating <= 5) NOT NULL,
  quote TEXT NOT NULL,
  property_stayed_at TEXT,
  stay_date DATE,
  is_featured BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true,
  display_order INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for featured testimonials
CREATE INDEX idx_testimonials_featured
ON testimonials(is_featured, is_active, display_order);

-- =====================================================
-- 4. NEWSLETTER SUBSCRIBERS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS newsletter_subscribers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email TEXT NOT NULL UNIQUE,
  subscribed_at TIMESTAMPTZ DEFAULT NOW(),
  is_active BOOLEAN DEFAULT true,
  unsubscribed_at TIMESTAMPTZ
);

-- Index for active subscribers
CREATE INDEX idx_newsletter_subscribers_active
ON newsletter_subscribers(is_active);

-- =====================================================
-- 5. ROW LEVEL SECURITY (RLS)
-- =====================================================

-- Enable RLS
ALTER TABLE popular_destinations ENABLE ROW LEVEL SECURITY;
ALTER TABLE how_it_works_steps ENABLE ROW LEVEL SECURITY;
ALTER TABLE testimonials ENABLE ROW LEVEL SECURITY;
ALTER TABLE newsletter_subscribers ENABLE ROW LEVEL SECURITY;

-- Public read access to active marketing content
CREATE POLICY "Public can view active destinations"
  ON popular_destinations FOR SELECT
  USING (is_active = true);

CREATE POLICY "Public can view active how it works steps"
  ON how_it_works_steps FOR SELECT
  USING (is_active = true);

CREATE POLICY "Public can view featured testimonials"
  ON testimonials FOR SELECT
  USING (is_active = true);

-- Admin-only write access (users with role 'admin')
CREATE POLICY "Admins can manage destinations"
  ON popular_destinations FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role = 'admin'
    )
  );

CREATE POLICY "Admins can manage how it works steps"
  ON how_it_works_steps FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role = 'admin'
    )
  );

CREATE POLICY "Admins can manage testimonials"
  ON testimonials FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.id = auth.uid()
      AND users.role = 'admin'
    )
  );

-- Anyone can subscribe to newsletter
CREATE POLICY "Anyone can subscribe to newsletter"
  ON newsletter_subscribers FOR INSERT
  WITH CHECK (true);

-- =====================================================
-- 6. SEED DATA
-- =====================================================

-- Popular Destinations
INSERT INTO popular_destinations (name, location, description, image_url, property_count, display_order) VALUES
('Rab Old Town', 'Rab, Croatia', 'Historic medieval town with stunning architecture', 'https://images.unsplash.com/photo-1588453251771-cd19dc5d75f4?w=800', 45, 1),
('Lopar Beach', 'Lopar, Rab', 'Sandy paradise perfect for families', 'https://images.unsplash.com/photo-1559827260-dc66d52bef19?w=800', 32, 2),
('Kampor Bay', 'Kampor, Rab', 'Peaceful cove with crystal clear waters', 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800', 28, 3),
('Barbat Waterfront', 'Barbat, Rab', 'Charming coastal village with local cuisine', 'https://images.unsplash.com/photo-1506929562872-bb421503ef21?w=800', 19, 4);

-- How It Works Steps
INSERT INTO how_it_works_steps (step_number, title, description, icon_name, display_order) VALUES
(1, 'Search & Discover', 'Browse through our curated selection of premium properties on Rab Island', 'search', 1),
(2, 'Book Securely', 'Choose your dates and complete your booking with secure payment', 'calendar_today', 2),
(3, 'Enjoy Your Stay', 'Check in and enjoy your perfect vacation rental experience', 'beach_access', 3);

-- Testimonials
INSERT INTO testimonials (customer_name, customer_avatar_url, customer_location, rating, quote, property_stayed_at, stay_date, is_featured, display_order) VALUES
('Maria Schmidt', 'https://i.pravatar.cc/150?img=1', 'Berlin, Germany', 5.0, 'Absolutely stunning property! The view was breathtaking and the host was incredibly accommodating. We will definitely be back!', 'Villa Sunset', '2024-07-15', true, 1),
('John & Sarah Williams', 'https://i.pravatar.cc/150?img=5', 'London, UK', 5.0, 'Perfect family vacation! The apartment was spacious, clean, and perfectly located. The kids loved the nearby beach!', 'Apartment Mare Blu', '2024-08-10', true, 2),
('Luca Rossi', 'https://i.pravatar.cc/150?img=12', 'Milan, Italy', 4.5, 'Beautiful location and great amenities. The property exceeded our expectations in every way. Highly recommended!', 'Villa Adriatic', '2024-06-22', true, 3),
('Anna Kowalski', 'https://i.pravatar.cc/150?img=9', 'Warsaw, Poland', 5.0, 'The best vacation rental experience we have ever had! Everything was perfect from check-in to check-out.', 'Studio Paradise', '2024-09-05', true, 4);

-- =====================================================
-- 7. UPDATED_AT TRIGGER
-- =====================================================

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to all marketing content tables
CREATE TRIGGER update_popular_destinations_updated_at
  BEFORE UPDATE ON popular_destinations
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_how_it_works_steps_updated_at
  BEFORE UPDATE ON how_it_works_steps
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_testimonials_updated_at
  BEFORE UPDATE ON testimonials
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- MIGRATION COMPLETE
-- =====================================================
