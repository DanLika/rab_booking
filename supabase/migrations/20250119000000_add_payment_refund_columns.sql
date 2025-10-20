-- Migration: Add payment_status and refund columns
-- Description: Adds payment tracking and refund functionality to bookings and payments tables
-- Date: 2025-01-19

-- ============================================================================
-- 1. Add payment_status column to bookings table
-- ============================================================================

-- Add payment_status column to track payment state separately from booking status
ALTER TABLE bookings
ADD COLUMN IF NOT EXISTS payment_status TEXT DEFAULT 'pending';

-- Add comment explaining the column
COMMENT ON COLUMN bookings.payment_status IS 'Payment status: pending, paid, failed, canceled, refunded';

-- Add cancellation tracking columns if they don't exist
ALTER TABLE bookings
ADD COLUMN IF NOT EXISTS cancellation_reason TEXT,
ADD COLUMN IF NOT EXISTS cancelled_at TIMESTAMPTZ;

-- Add comments
COMMENT ON COLUMN bookings.cancellation_reason IS 'Reason provided by user for cancellation';
COMMENT ON COLUMN bookings.cancelled_at IS 'Timestamp when booking was cancelled';

-- ============================================================================
-- 2. Update payments table for refund tracking
-- ============================================================================

-- Add refund tracking columns
ALTER TABLE payments
ADD COLUMN IF NOT EXISTS refund_amount INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS refund_id TEXT,
ADD COLUMN IF NOT EXISTS refunded_at TIMESTAMPTZ;

-- Add payment method tracking
ALTER TABLE payments
ADD COLUMN IF NOT EXISTS payment_method TEXT;

-- Add stripe payment intent ID if not exists
ALTER TABLE payments
ADD COLUMN IF NOT EXISTS stripe_payment_intent_id TEXT;

-- Add comments
COMMENT ON COLUMN payments.refund_amount IS 'Amount refunded in cents (if applicable)';
COMMENT ON COLUMN payments.refund_id IS 'Stripe refund ID (if refund was processed)';
COMMENT ON COLUMN payments.refunded_at IS 'Timestamp when refund was processed';
COMMENT ON COLUMN payments.payment_method IS 'Payment method used (card, etc.)';
COMMENT ON COLUMN payments.stripe_payment_intent_id IS 'Stripe Payment Intent ID';

-- ============================================================================
-- 3. Update existing records with default payment_status
-- ============================================================================

-- Set payment_status based on current booking status
UPDATE bookings
SET payment_status = CASE
  WHEN status = 'confirmed' THEN 'paid'
  WHEN status = 'payment_failed' THEN 'failed'
  WHEN status = 'cancelled' THEN 'canceled'
  WHEN status = 'refunded' THEN 'refunded'
  ELSE 'pending'
END
WHERE payment_status = 'pending';

-- ============================================================================
-- 4. Create index for payment_status queries
-- ============================================================================

-- Index for filtering bookings by payment status
CREATE INDEX IF NOT EXISTS idx_bookings_payment_status
ON bookings(payment_status);

-- Index for finding payments by payment intent
CREATE INDEX IF NOT EXISTS idx_payments_stripe_payment_intent_id
ON payments(stripe_payment_intent_id);

-- Index for finding refunded payments
CREATE INDEX IF NOT EXISTS idx_payments_refunded_at
ON payments(refunded_at)
WHERE refunded_at IS NOT NULL;

-- ============================================================================
-- 5. Add constraint to validate payment_status values
-- ============================================================================

-- Add check constraint for valid payment_status values
ALTER TABLE bookings
DROP CONSTRAINT IF EXISTS bookings_payment_status_check;

ALTER TABLE bookings
ADD CONSTRAINT bookings_payment_status_check
CHECK (payment_status IN ('pending', 'paid', 'failed', 'canceled', 'refunded'));

-- ============================================================================
-- 6. Update RLS policies if needed
-- ============================================================================

-- No RLS changes needed - existing policies cover the new columns

-- ============================================================================
-- Migration complete
-- ============================================================================

-- Verify the changes
DO $$
BEGIN
  -- Check if payment_status column exists
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_name = 'bookings'
    AND column_name = 'payment_status'
  ) THEN
    RAISE NOTICE '✅ payment_status column added to bookings table';
  ELSE
    RAISE EXCEPTION '❌ Failed to add payment_status column';
  END IF;

  -- Check if refund columns exist
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_name = 'payments'
    AND column_name = 'refund_amount'
  ) THEN
    RAISE NOTICE '✅ Refund columns added to payments table';
  ELSE
    RAISE EXCEPTION '❌ Failed to add refund columns';
  END IF;

  RAISE NOTICE '🎉 Migration completed successfully!';
END $$;
