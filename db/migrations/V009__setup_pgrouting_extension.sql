-- Install pgRouting extension and add topology columns to road_segments.
-- The topology itself (pgr_createTopology) must be run separately via
-- `make setup-routing` after road data has been seeded.

CREATE EXTENSION IF NOT EXISTS pgrouting;

ALTER TABLE road_segments
    ADD COLUMN IF NOT EXISTS seq_id BIGSERIAL,
    ADD COLUMN IF NOT EXISTS source INTEGER,
    ADD COLUMN IF NOT EXISTS target INTEGER;
