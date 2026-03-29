-- V011: Add batches table and replace session_id with batch_id in raw_measurements
--
-- A Batch groups raw measurements from one measurement run within a Session.
-- raw_measurements.session_id is replaced by raw_measurements.batch_id.

-- ==============================================
-- 1. CREATE BATCHES TABLE
-- ==============================================
CREATE TABLE batches (
    id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
    status     VARCHAR(50) NOT NULL DEFAULT 'pending'
                   CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_batches_session_id ON batches(session_id);
CREATE INDEX idx_batches_status     ON batches(status);

CREATE TRIGGER trg_batches_set_updated_at
    BEFORE UPDATE ON batches
    FOR EACH ROW
    EXECUTE FUNCTION trigger_set_updated_at();

COMMENT ON TABLE batches IS 'Groups of raw measurements collected in one measurement run within a session';
COMMENT ON COLUMN batches.status IS 'Processing state: pending | processing | completed | failed';

GRANT SELECT, INSERT, UPDATE, DELETE ON batches TO clearway;

-- ==============================================
-- 2. MIGRATE DATA: create one batch per existing session used in raw_measurements
-- ==============================================
INSERT INTO batches (id, session_id, status, created_at, updated_at)
SELECT DISTINCT
    uuid_generate_v4()                                      AS id,
    rm.session_id,
    'completed'                                             AS status,
    MIN(rm.created_at) OVER (PARTITION BY rm.session_id)   AS created_at,
    CURRENT_TIMESTAMP                                       AS updated_at
FROM raw_measurements AS rm
ON CONFLICT DO NOTHING;

-- ==============================================
-- 3. ADD batch_id TO raw_measurements (nullable first for data migration)
-- ==============================================
ALTER TABLE raw_measurements ADD COLUMN batch_id UUID REFERENCES batches(id) ON DELETE CASCADE;

-- Populate batch_id from the newly created batches
UPDATE raw_measurements AS rm
SET    batch_id = b.id
FROM   batches AS b
WHERE  b.session_id = rm.session_id;

-- Now enforce NOT NULL
ALTER TABLE raw_measurements ALTER COLUMN batch_id SET NOT NULL;

CREATE INDEX idx_raw_measurements_batch_id ON raw_measurements(batch_id);

-- ==============================================
-- 4. DROP session_id FROM raw_measurements
-- ==============================================
DROP INDEX IF EXISTS idx_raw_measurements_session_id;
ALTER TABLE raw_measurements DROP COLUMN session_id;

-- ==============================================
-- 5. RECREATE recent_measurements VIEW
--    (now joins through batches to reach sessions)
-- ==============================================
CREATE OR REPLACE VIEW recent_measurements AS
SELECT
    rm.id,
    b.session_id,
    rm.batch_id,
    rm.measured_at,
    rm.latitude,
    rm.longitude,
    rm.distance_left,
    rm.distance_right,
    rm.is_valid,
    s.sensor_id,
    s.vehicle_id,
    sen.description AS sensor_description,
    v.vehicle_name,
    v.width        AS vehicle_width
FROM raw_measurements AS rm
INNER JOIN batches   AS b   ON rm.batch_id  = b.id
INNER JOIN sessions  AS s   ON b.session_id = s.id
INNER JOIN sensors   AS sen ON s.sensor_id  = sen.id
INNER JOIN vehicles  AS v   ON s.vehicle_id = v.id
WHERE rm.measured_at > CURRENT_TIMESTAMP - INTERVAL '24 hours'
ORDER BY rm.measured_at DESC;
