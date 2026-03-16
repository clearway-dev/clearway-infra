-- Build pgRouting topology on the road_segments table.
-- Run AFTER road data has been seeded (make seed-roads).
-- All statements are idempotent and safe to re-run.
--
-- Usage: make setup-routing

-- Tolerance 0.00001 degrees ≈ 1 m — snaps near-touching endpoints.
-- seq_id (bigserial) is used as the edge id because pgRouting requires
-- an integer edge id; road_segments.id is UUID which is not supported.
SELECT pgr_createTopology('road_segments', 0.00001, 'geom', 'seq_id');

CREATE INDEX IF NOT EXISTS road_segments_vertices_geom_idx
    ON road_segments_vertices_pgr USING GIST(the_geom);

CREATE INDEX IF NOT EXISTS road_segments_source_idx
    ON road_segments (source);

CREATE INDEX IF NOT EXISTS road_segments_target_idx
    ON road_segments (target);
