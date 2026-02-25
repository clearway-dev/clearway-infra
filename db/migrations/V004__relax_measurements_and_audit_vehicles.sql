-- V004__relax_measurements_and_audit_vehicles.sql
--
-- Changes:
--   1. Drop CHECK constraints from raw_measurements that reject physically
--      invalid sensor readings. The Bronze layer must accept all incoming data
--      (including out-of-range GPS coords and negative distances) so that
--      hardware error rates can be measured. Validity is signalled via the
--      existing is_valid = false flag and handled downstream in the pipeline.
--
--   2. Drop NOT NULL constraints on raw_measurements measured columns so that
--      rows with missing sensor values (GPS fix failure, sensor timeout) are
--      accepted at the Bronze layer instead of being silently dropped by the
--      ingest client or causing a write error.
--
--   3. Add audit columns (created_at, updated_at) to the vehicles table and
--      attach a BEFORE UPDATE trigger to keep updated_at current automatically.

-- ============================================================
-- PART 1: Relax CHECK constraints on raw_measurements
-- ============================================================

-- Allow latitude values outside the physical -90..90 range (hardware glitches)
ALTER TABLE raw_measurements
    DROP CONSTRAINT IF EXISTS raw_measurements_latitude_check;

-- Allow longitude values outside the physical -180..180 range (hardware glitches)
ALTER TABLE raw_measurements
    DROP CONSTRAINT IF EXISTS raw_measurements_longitude_check;

-- Allow negative distance_left readings (sensor malfunction / inverted polarity)
ALTER TABLE raw_measurements
    DROP CONSTRAINT IF EXISTS raw_measurements_distance_left_check;

-- Allow negative distance_right readings (sensor malfunction / inverted polarity)
ALTER TABLE raw_measurements
    DROP CONSTRAINT IF EXISTS raw_measurements_distance_right_check;

-- ============================================================
-- PART 2: Drop NOT NULL on raw_measurements measured columns
-- ============================================================

-- Allow NULL latitude (GPS fix not acquired or sensor timeout)
ALTER TABLE raw_measurements
    ALTER COLUMN latitude DROP NOT NULL;

-- Allow NULL longitude (GPS fix not acquired or sensor timeout)
ALTER TABLE raw_measurements
    ALTER COLUMN longitude DROP NOT NULL;

-- Allow NULL distance_left (ultrasonic sensor timeout / no echo returned)
ALTER TABLE raw_measurements
    ALTER COLUMN distance_left DROP NOT NULL;

-- Allow NULL distance_right (ultrasonic sensor timeout / no echo returned)
ALTER TABLE raw_measurements
    ALTER COLUMN distance_right DROP NOT NULL;

-- ============================================================
-- PART 3: Add audit columns to vehicles
-- ============================================================

ALTER TABLE vehicles
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP;

-- Backfill any existing rows that landed with NULL (defensive, ADD COLUMN DEFAULT
-- already sets them, but kept here for explicitness on non-transactional DDL engines)
UPDATE vehicles
    SET created_at = CURRENT_TIMESTAMP,
        updated_at = CURRENT_TIMESTAMP
WHERE created_at IS NULL;

-- ============================================================
-- PART 4: Trigger to auto-update vehicles.updated_at
-- ============================================================

-- Generic reusable trigger function; safe to create/replace across migrations
CREATE OR REPLACE FUNCTION trigger_set_updated_at()
    RETURNS TRIGGER
    LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_vehicles_set_updated_at ON vehicles;

CREATE TRIGGER trg_vehicles_set_updated_at
    BEFORE UPDATE ON vehicles
    FOR EACH ROW
    EXECUTE FUNCTION trigger_set_updated_at();
