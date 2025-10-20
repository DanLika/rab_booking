-- Migration: Rename price_per_night to base_price in units table
-- Date: 2025-01-19
-- Reason: Align database schema with Flutter application
-- The app uses @JsonKey(name: 'base_price') but database still has price_per_night

-- Step 1: Rename the column in units table
ALTER TABLE units
RENAME COLUMN price_per_night TO base_price;

-- Step 2: Verify the column was renamed successfully
DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_name = 'units'
      AND column_name = 'base_price'
  ) THEN
    RAISE NOTICE 'SUCCESS: Column renamed to base_price';
  ELSE
    RAISE EXCEPTION 'FAILED: Column base_price not found';
  END IF;
END $$;

-- Step 3: Update any RLS policies that reference the old column name (if any)
-- Note: Review existing RLS policies to ensure they don't use old column name

-- Step 4: Display current schema for verification
SELECT
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_name = 'units'
ORDER BY ordinal_position;
