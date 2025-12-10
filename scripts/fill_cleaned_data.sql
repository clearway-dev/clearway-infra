-- ClearWay Simulation Pipeline Script (TEMPORARY VERSION FOR FRONTEND BLOCKER)
-- Purpose: Populate cleaned_measurements with ALL raw data, ignoring the 'is_valid' flag.
-- This ensures Jan Vandlíček can start development immediately.

-- Set a standard quality score for all initial clean measurements
DO $$
DECLARE
    DEFAULT_QUALITY_SCORE FLOAT := 0.90;
    CLEANED_SESSION_COUNT INTEGER;
BEGIN
    
    -- 1. INSERT Validated Data into cleaned_measurements
    -- **DOČASNĚ** ZPRACOVÁVÁME VŠECHNA DATA, BEZ OHLEDU NA rm.is_valid.
    
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
        ST_SetSRID(ST_MakePoint(rm.longitude, rm.latitude), 4326) AS geom -- Create PostGIS geometry point
    FROM 
        raw_measurements rm
    JOIN 
        sessions s ON rm.session_id = s.id
    JOIN 
        vehicles v ON s.vehicle_id = v.id
    -- ZPRACOVÁVÁ POUZE DATA, KTERÁ NEBYLA ZATÍM ZAPSAÁNA
    WHERE 
        NOT EXISTS (
            SELECT 1 
            FROM cleaned_measurements cm 
            WHERE cm.raw_measurement_id = rm.id
        );
    
    GET DIAGNOSTICS CLEANED_SESSION_COUNT = ROW_COUNT;

    -- 2. Odstraněno: INSERT Invalid Data (v této dočasné fázi se smazalo všechna data)

    -- 3. Verification Message
    RAISE NOTICE '============================================';
    RAISE NOTICE '✅ Cleaned Data Simulation (Temporary) Complete';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'Records inserted into cleaned_measurements: %', CLEANED_SESSION_COUNT;
    RAISE NOTICE '============================================';
END $$;