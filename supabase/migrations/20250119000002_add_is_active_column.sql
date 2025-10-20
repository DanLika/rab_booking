-- Add is_active column to properties table if it doesn't exist
-- Migration: 20250119000002_add_is_active_column.sql
-- Date: 2025-10-19
-- Purpose: Fix 406 errors by ensuring is_active column exists in properties table

-- Add column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'properties' AND column_name = 'is_active'
    ) THEN
        ALTER TABLE properties
        ADD COLUMN is_active BOOLEAN NOT NULL DEFAULT true;

        RAISE NOTICE 'SUCCESS: Column is_active added to properties table';
    ELSE
        RAISE NOTICE 'INFO: Column is_active already exists in properties table';
    END IF;
END $$;

-- Set all existing properties to active by default
UPDATE properties
SET is_active = true
WHERE is_active IS NULL;

-- Verify the column was added
DO $$
DECLARE
    column_exists BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'properties' AND column_name = 'is_active'
    ) INTO column_exists;

    IF column_exists THEN
        RAISE NOTICE 'VERIFICATION: is_active column exists in properties table ✓';
    ELSE
        RAISE EXCEPTION 'ERROR: Failed to create is_active column';
    END IF;
END $$;

-- Show column details
SELECT
    column_name,
    data_type,
    column_default,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'properties' AND column_name = 'is_active';

-- Show sample data
SELECT id, name, is_active
FROM properties
LIMIT 5;
