-- Migration: V003__add_stations.sql
-- Description: Add stations table for emergency dispatch locations
--   (fire stations, ambulance bases, police stations) used as
--   route start presets in the routing feature.
--   Note: init/001_schema.sql previously referenced this as "target_stations"
--   which was incorrect — the model and API use "stations".

-- Rollback:
-- DROP TABLE IF EXISTS stations;

CREATE TABLE IF NOT EXISTS stations (
    id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name         VARCHAR(255) NOT NULL,
    type         VARCHAR(50),
    address      VARCHAR(500),
    lat          DOUBLE PRECISION NOT NULL,
    lon          DOUBLE PRECISION NOT NULL,
    notes        TEXT,
    created_at   TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE stations IS 'Emergency service dispatch stations (fire, police, ambulance) used as route start presets';
COMMENT ON COLUMN stations.type IS 'One of: fire_station, police, hospital, rescue, other';
COMMENT ON COLUMN stations.notes IS 'Deduplication key, e.g. hzs:plzen-stred or osm:node/12345';
