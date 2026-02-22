-- Migration: V002__update_target_vehicles.sql
-- Description: Redesign target_vehicles table columns to match HZS vehicle spec.
--   - Remove turning_radius_inner, turning_radius_outer, updated_at
--   - Add length, turning_diameter_track, turning_diameter_clearance, stabilization_width
--   - Seed HZS Plzeňský kraj vehicles from official requirements document

-- Rollback:
-- ALTER TABLE target_vehicles DROP COLUMN IF EXISTS length;
-- ALTER TABLE target_vehicles DROP COLUMN IF EXISTS turning_diameter_track;
-- ALTER TABLE target_vehicles DROP COLUMN IF EXISTS turning_diameter_clearance;
-- ALTER TABLE target_vehicles DROP COLUMN IF EXISTS stabilization_width;
-- ALTER TABLE target_vehicles ADD COLUMN turning_radius_inner FLOAT CHECK (turning_radius_inner > 0);
-- ALTER TABLE target_vehicles ADD COLUMN turning_radius_outer FLOAT CHECK (turning_radius_outer > 0);
-- ALTER TABLE target_vehicles ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;
-- DELETE FROM target_vehicles WHERE category = 'hasiči';

-- -----------------------------------------------
-- 1. Drop old columns
-- -----------------------------------------------
ALTER TABLE target_vehicles
    DROP COLUMN IF EXISTS turning_radius_inner,
    DROP COLUMN IF EXISTS turning_radius_outer,
    DROP COLUMN IF EXISTS updated_at;

-- -----------------------------------------------
-- 2. Add new columns
-- -----------------------------------------------
ALTER TABLE target_vehicles
    ADD COLUMN IF NOT EXISTS length                     FLOAT CHECK (length > 0),
    ADD COLUMN IF NOT EXISTS turning_diameter_track     FLOAT CHECK (turning_diameter_track > 0),
    ADD COLUMN IF NOT EXISTS turning_diameter_clearance FLOAT CHECK (turning_diameter_clearance > 0),
    ADD COLUMN IF NOT EXISTS stabilization_width        FLOAT CHECK (stabilization_width > 0);

-- -----------------------------------------------
-- 3. Update column comments
-- -----------------------------------------------
COMMENT ON COLUMN target_vehicles.length IS 'Vehicle length in meters';
COMMENT ON COLUMN target_vehicles.turning_diameter_track IS 'Outer track turning diameter in meters (vnější stopový průměr zatáčení)';
COMMENT ON COLUMN target_vehicles.turning_diameter_clearance IS 'Outer clearance turning diameter in meters (vnější obrysový průměr zatáčení), nullable';
COMMENT ON COLUMN target_vehicles.stabilization_width IS 'Minimum stabilization (outrigger) width in meters (šířka pro patky), nullable';
