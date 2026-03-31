-- ClearWay: Populate cleaned_measurements from raw_measurements.
-- Processes all raw rows that don't yet have a cleaned counterpart.
-- Uses batch → session → vehicle chain to resolve vehicle width.

DO $$
DECLARE
    DEFAULT_QUALITY_SCORE FLOAT := 0.90;
    CLEANED_COUNT INTEGER;
BEGIN
    INSERT INTO cleaned_measurements (
        raw_measurement_id,
        cleaned_width,
        quality_score,
        cluster_id,
        geom
    )
    SELECT
        rm.id AS raw_measurement_id,
        calculate_road_width(rm.distance_left, rm.distance_right, v.width) AS cleaned_width,
        DEFAULT_QUALITY_SCORE AS quality_score,
        NULL AS cluster_id,
        ST_SetSRID(ST_MakePoint(rm.longitude, rm.latitude), 4326) AS geom
    FROM raw_measurements rm
    JOIN batches b   ON rm.batch_id   = b.id
    JOIN sessions s  ON b.session_id  = s.id
    JOIN vehicles v  ON s.vehicle_id  = v.id
    WHERE NOT EXISTS (
        SELECT 1 FROM cleaned_measurements cm WHERE cm.raw_measurement_id = rm.id
    );

    GET DIAGNOSTICS CLEANED_COUNT = ROW_COUNT;

    RAISE NOTICE '============================================';
    RAISE NOTICE 'fill_cleaned_data complete';
    RAISE NOTICE 'Inserted into cleaned_measurements: %', CLEANED_COUNT;
    RAISE NOTICE '============================================';
END $$;
