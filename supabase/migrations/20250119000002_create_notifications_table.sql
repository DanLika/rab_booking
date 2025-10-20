-- Create notifications table
-- This table stores all user notifications (booking updates, messages, system alerts)

CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  -- Notification content
  type VARCHAR(50) NOT NULL CHECK (type IN (
    'booking_confirmed',
    'booking_cancelled',
    'booking_reminder',
    'review_received',
    'review_request',
    'payment_success',
    'payment_failed',
    'message_received',
    'property_approved',
    'property_rejected',
    'system_alert'
  )),
  title VARCHAR(255) NOT NULL,
  body TEXT NOT NULL,

  -- Related entity (e.g., booking_id, property_id)
  related_entity_type VARCHAR(50),  -- 'booking', 'property', 'review', 'message'
  related_entity_id UUID,

  -- Action URL (deep link to relevant screen)
  action_url VARCHAR(500),

  -- Metadata (JSON for additional data)
  metadata JSONB DEFAULT '{}'::jsonb,

  -- Status
  is_read BOOLEAN NOT NULL DEFAULT false,
  read_at TIMESTAMPTZ,

  -- Timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ,  -- Optional expiration for temporary notifications

  -- Indexes
  CONSTRAINT notifications_user_id_idx CHECK (user_id IS NOT NULL)
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user_id_created_at ON notifications(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_user_id_is_read ON notifications(user_id, is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications(type);
CREATE INDEX IF NOT EXISTS idx_notifications_related_entity ON notifications(related_entity_type, related_entity_id);
CREATE INDEX IF NOT EXISTS idx_notifications_expires_at ON notifications(expires_at) WHERE expires_at IS NOT NULL;

-- Add comments for documentation
COMMENT ON TABLE notifications IS 'Stores user notifications for bookings, messages, and system alerts';
COMMENT ON COLUMN notifications.type IS 'Type of notification (booking_confirmed, review_received, etc.)';
COMMENT ON COLUMN notifications.related_entity_type IS 'Type of related entity (booking, property, review, message)';
COMMENT ON COLUMN notifications.related_entity_id IS 'ID of the related entity';
COMMENT ON COLUMN notifications.action_url IS 'Deep link URL to navigate to relevant screen';
COMMENT ON COLUMN notifications.metadata IS 'Additional JSON metadata for the notification';
COMMENT ON COLUMN notifications.expires_at IS 'Optional expiration timestamp for temporary notifications';

-- Enable Row Level Security
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- RLS Policies

-- Users can read their own notifications
CREATE POLICY "Users can read their own notifications"
  ON notifications
  FOR SELECT
  USING (auth.uid() = user_id);

-- Users can update (mark as read) their own notifications
CREATE POLICY "Users can update their own notifications"
  ON notifications
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Users can delete their own notifications
CREATE POLICY "Users can delete their own notifications"
  ON notifications
  FOR DELETE
  USING (auth.uid() = user_id);

-- System can insert notifications for any user (service role key only)
CREATE POLICY "Service role can insert notifications"
  ON notifications
  FOR INSERT
  WITH CHECK (true);

-- Function to automatically set read_at timestamp
CREATE OR REPLACE FUNCTION set_notification_read_at()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.is_read = true AND OLD.is_read = false THEN
    NEW.read_at = NOW();
  END IF;
  IF NEW.is_read = false THEN
    NEW.read_at = NULL;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to set read_at when is_read changes to true
DROP TRIGGER IF EXISTS trigger_set_notification_read_at ON notifications;
CREATE TRIGGER trigger_set_notification_read_at
  BEFORE UPDATE ON notifications
  FOR EACH ROW
  EXECUTE FUNCTION set_notification_read_at();

-- Function to delete expired notifications (call via cron job)
CREATE OR REPLACE FUNCTION delete_expired_notifications()
RETURNS void AS $$
BEGIN
  DELETE FROM notifications
  WHERE expires_at IS NOT NULL
    AND expires_at < NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to mark all notifications as read for a user
CREATE OR REPLACE FUNCTION mark_all_notifications_as_read(p_user_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE notifications
  SET is_read = true, read_at = NOW()
  WHERE user_id = p_user_id
    AND is_read = false;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get unread notification count
CREATE OR REPLACE FUNCTION get_unread_notification_count(p_user_id UUID)
RETURNS INTEGER AS $$
BEGIN
  RETURN (
    SELECT COUNT(*)::INTEGER
    FROM notifications
    WHERE user_id = p_user_id
      AND is_read = false
      AND (expires_at IS NULL OR expires_at > NOW())
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permissions on functions
GRANT EXECUTE ON FUNCTION set_notification_read_at() TO authenticated;
GRANT EXECUTE ON FUNCTION delete_expired_notifications() TO service_role;
GRANT EXECUTE ON FUNCTION mark_all_notifications_as_read(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_unread_notification_count(UUID) TO authenticated;

-- Create a view for unread notifications count per user
CREATE OR REPLACE VIEW user_unread_notifications_count AS
SELECT
  user_id,
  COUNT(*)::INTEGER as unread_count
FROM notifications
WHERE is_read = false
  AND (expires_at IS NULL OR expires_at > NOW())
GROUP BY user_id;

-- Grant select on view
GRANT SELECT ON user_unread_notifications_count TO authenticated;

-- Enable realtime for notifications table
-- This allows clients to subscribe to notification changes via Supabase Realtime
ALTER PUBLICATION supabase_realtime ADD TABLE notifications;

COMMENT ON VIEW user_unread_notifications_count IS 'View showing unread notification count per user';
