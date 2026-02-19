-- Migration: V001__add_target_vehicles.sql
-- Description: Add target_vehicles table for managing IZS and other vehicles
--              whose road passability needs to be checked.

CREATE TABLE IF NOT EXISTS target_vehicles (
    id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name             VARCHAR(255) NOT NULL,
    category         VARCHAR(100),
    width            FLOAT CHECK (width > 0),
    height           FLOAT CHECK (height > 0),
    weight           FLOAT CHECK (weight > 0),
    turning_radius_inner FLOAT CHECK (turning_radius_inner > 0),
    turning_radius_outer FLOAT CHECK (turning_radius_outer > 0 AND turning_radius_outer >= turning_radius_inner),
    created_at       TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at       TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE target_vehicles IS 'IZS and other vehicles whose road passability is evaluated against road segment measurements';
COMMENT ON COLUMN target_vehicles.width IS 'Vehicle width in meters';
COMMENT ON COLUMN target_vehicles.height IS 'Vehicle height in meters';
COMMENT ON COLUMN target_vehicles.weight IS 'Vehicle weight in tonnes';
COMMENT ON COLUMN target_vehicles.turning_radius_inner IS 'Inner turning radius in meters';
COMMENT ON COLUMN target_vehicles.turning_radius_outer IS 'Outer turning radius in meters';

GRANT SELECT, INSERT, UPDATE, DELETE ON target_vehicles TO clearway;

-- Rollback:
-- DROP TABLE IF EXISTS target_vehicles;
