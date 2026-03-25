-- Index on segment_statistics.stat_date speeds up all date-filtered queries
-- (map bbox endpoint, export, dashboard, routing) from full table scan to index seek.
CREATE INDEX IF NOT EXISTS idx_segment_statistics_stat_date
    ON segment_statistics (stat_date);
