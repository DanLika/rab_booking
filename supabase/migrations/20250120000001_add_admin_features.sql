-- Migration: Add Admin Features
-- Description: Adds last_seen tracking, approval system, and activity logging
-- Date: 2025-01-20

-- ==================== ADD LAST_SEEN TRACKING TO USERS ====================

-- Add last_seen column to users table
ALTER TABLE users
ADD COLUMN IF NOT EXISTS last_seen TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Create index for faster queries on last_seen
CREATE INDEX IF NOT EXISTS idx_users_last_seen ON users(last_seen);

-- Create trigger to automatically update last_seen on user activity
CREATE OR REPLACE FUNCTION update_user_last_seen()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE users
  SET last_seen = NOW()
  WHERE id = NEW.user_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger on bookings table
DROP TRIGGER IF EXISTS trigger_update_last_seen_on_booking ON bookings;
CREATE TRIGGER trigger_update_last_seen_on_booking
  AFTER INSERT OR UPDATE ON bookings
  FOR EACH ROW
  EXECUTE FUNCTION update_user_last_seen();

-- ==================== ADD APPROVAL SYSTEM FOR PROPERTIES ====================

-- Add approval_status column to properties table
ALTER TABLE properties
ADD COLUMN IF NOT EXISTS approval_status TEXT DEFAULT 'pending' CHECK (approval_status IN ('pending', 'approved', 'rejected'));

-- Add columns for approval tracking
ALTER TABLE properties
ADD COLUMN IF NOT EXISTS approved_by UUID REFERENCES users(id),
ADD COLUMN IF NOT EXISTS approved_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS rejection_reason TEXT;

-- Create index for faster queries on approval_status
CREATE INDEX IF NOT EXISTS idx_properties_approval_status ON properties(approval_status);

-- Update existing properties to 'approved' status
UPDATE properties
SET approval_status = 'approved',
    approved_at = created_at
WHERE approval_status IS NULL OR approval_status = 'pending';

-- ==================== CREATE ACTIVITY LOGS TABLE ====================

-- Create activity_logs table for tracking user actions
CREATE TABLE IF NOT EXISTS activity_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  action TEXT NOT NULL,
  resource_type TEXT NOT NULL,
  resource_id TEXT,
  resource_name TEXT,
  metadata JSONB,
  ip_address TEXT,
  user_agent TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_activity_logs_user_id ON activity_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_activity_logs_created_at ON activity_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_activity_logs_resource ON activity_logs(resource_type, resource_id);
CREATE INDEX IF NOT EXISTS idx_activity_logs_action ON activity_logs(action);

-- Enable RLS on activity_logs
ALTER TABLE activity_logs ENABLE ROW LEVEL SECURITY;

-- RLS Policies for activity_logs

-- Admins can view all activity logs
CREATE POLICY "Admins can view all activity logs"
ON activity_logs FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM users
    WHERE users.id = auth.uid()
    AND users.role = 'admin'
  )
);

-- Users can view their own activity logs
CREATE POLICY "Users can view own activity logs"
ON activity_logs FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- System can insert activity logs
CREATE POLICY "System can insert activity logs"
ON activity_logs FOR INSERT
TO authenticated
WITH CHECK (true);

-- ==================== HELPER FUNCTIONS ====================

-- Function to log user activity
CREATE OR REPLACE FUNCTION log_user_activity(
  p_user_id UUID,
  p_action TEXT,
  p_resource_type TEXT,
  p_resource_id TEXT DEFAULT NULL,
  p_resource_name TEXT DEFAULT NULL,
  p_metadata JSONB DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_log_id UUID;
BEGIN
  INSERT INTO activity_logs (
    user_id,
    action,
    resource_type,
    resource_id,
    resource_name,
    metadata
  ) VALUES (
    p_user_id,
    p_action,
    p_resource_type,
    p_resource_id,
    p_resource_name,
    p_metadata
  )
  RETURNING id INTO v_log_id;

  RETURN v_log_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ==================== AUTO-LOGGING TRIGGERS ====================

-- Trigger to log booking creation
CREATE OR REPLACE FUNCTION log_booking_activity()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    PERFORM log_user_activity(
      NEW.user_id,
      'created_booking',
      'booking',
      NEW.id::TEXT,
      NULL,
      jsonb_build_object(
        'unit_id', NEW.unit_id,
        'check_in', NEW.check_in,
        'check_out', NEW.check_out,
        'total_price', NEW.total_price
      )
    );
  ELSIF TG_OP = 'UPDATE' THEN
    PERFORM log_user_activity(
      NEW.user_id,
      'updated_booking',
      'booking',
      NEW.id::TEXT,
      NULL,
      jsonb_build_object(
        'old_status', OLD.status,
        'new_status', NEW.status
      )
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_log_booking_activity ON bookings;
CREATE TRIGGER trigger_log_booking_activity
  AFTER INSERT OR UPDATE ON bookings
  FOR EACH ROW
  EXECUTE FUNCTION log_booking_activity();

-- Trigger to log property creation
CREATE OR REPLACE FUNCTION log_property_activity()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    PERFORM log_user_activity(
      NEW.owner_id,
      'created_property',
      'property',
      NEW.id::TEXT,
      NEW.name,
      jsonb_build_object(
        'location', NEW.location,
        'base_price', NEW.base_price
      )
    );
  ELSIF TG_OP = 'UPDATE' THEN
    IF OLD.approval_status != NEW.approval_status THEN
      PERFORM log_user_activity(
        NEW.owner_id,
        'property_approval_changed',
        'property',
        NEW.id::TEXT,
        NEW.name,
        jsonb_build_object(
          'old_status', OLD.approval_status,
          'new_status', NEW.approval_status,
          'approved_by', NEW.approved_by
        )
      );
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_log_property_activity ON properties;
CREATE TRIGGER trigger_log_property_activity
  AFTER INSERT OR UPDATE ON properties
  FOR EACH ROW
  EXECUTE FUNCTION log_property_activity();

-- ==================== COMMENTS ====================

COMMENT ON TABLE activity_logs IS 'Logs all user activities for admin monitoring and analytics';
COMMENT ON COLUMN users.last_seen IS 'Timestamp of user''s last activity, automatically updated';
COMMENT ON COLUMN properties.approval_status IS 'Status of property approval: pending, approved, or rejected';
COMMENT ON COLUMN properties.approved_by IS 'Admin user who approved or rejected the property';
COMMENT ON COLUMN properties.approved_at IS 'Timestamp when property was approved or rejected';
COMMENT ON COLUMN properties.rejection_reason IS 'Reason for rejection if status is rejected';
