-- V007: Add speed and accuracy_gps to raw_measurements; add created_at to sessions

ALTER TABLE raw_measurements
    ADD COLUMN IF NOT EXISTS speed FLOAT CHECK (speed >= 0),
    ADD COLUMN IF NOT EXISTS accuracy_gps FLOAT CHECK (accuracy_gps >= 0);

COMMENT ON COLUMN raw_measurements.speed IS 'Vehicle speed at time of measurement (m/s), nullable';
COMMENT ON COLUMN raw_measurements.accuracy_gps IS 'GPS horizontal accuracy estimate (meters), nullable';

ALTER TABLE sessions
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;
