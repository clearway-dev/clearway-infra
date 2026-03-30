-- V012: Adapt clusters table for DBSCAN obstacle detection results
--
-- Previously clusters were designed as spatial aggregates linked to road segments.
-- We repurpose the table to store pre-computed DBSCAN results per date so that
-- the API can query them directly instead of running DBSCAN live on every request.
--
-- Changes:
--   - Add stat_date DATE NOT NULL (which date the cluster was computed for)
--   - Add severity VARCHAR NOT NULL (critical / high / medium)
--   - Add cluster_size INT NOT NULL (number of measurements in the cluster)
--   - road_segment_id is kept but no longer required (DBSCAN clusters are not
--     tied to a single road segment)

ALTER TABLE clusters
    ADD COLUMN IF NOT EXISTS stat_date    DATE         NOT NULL DEFAULT CURRENT_DATE,
    ADD COLUMN IF NOT EXISTS severity     VARCHAR(20)  NOT NULL DEFAULT 'medium'
        CHECK (severity IN ('critical', 'high', 'medium')),
    ADD COLUMN IF NOT EXISTS cluster_size INT          NOT NULL DEFAULT 1
        CHECK (cluster_size > 0);

-- Remove the placeholder defaults now that the column exists
ALTER TABLE clusters
    ALTER COLUMN stat_date    DROP DEFAULT,
    ALTER COLUMN severity     DROP DEFAULT,
    ALTER COLUMN cluster_size DROP DEFAULT;

-- Indexes for the new columns
CREATE INDEX IF NOT EXISTS idx_clusters_stat_date ON clusters(stat_date);
CREATE INDEX IF NOT EXISTS idx_clusters_severity  ON clusters(severity);

COMMENT ON COLUMN clusters.stat_date    IS 'Date for which the DBSCAN cluster was computed';
COMMENT ON COLUMN clusters.severity     IS 'Obstacle severity: critical (<2 m), high (2–2.5 m), medium (2.5–3 m)';
COMMENT ON COLUMN clusters.cluster_size IS 'Number of cleaned_measurements that form this cluster';
