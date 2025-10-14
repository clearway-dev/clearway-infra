-- ClearWay Sample Data
-- Purpose: Provide test data for development and demonstration

-- ==============================================
-- SAMPLE SENSORS
-- ==============================================

INSERT INTO sensors (id, device_id, description, vehicle_width, is_active) VALUES
    ('11111111-1111-1111-1111-111111111111', 'SENSOR_001', 'Honda Civic - Test Vehicle 1', 1.75, true),
    ('22222222-2222-2222-2222-222222222222', 'SENSOR_002', 'Toyota Corolla - Test Vehicle 2', 1.78, true),
    ('33333333-3333-3333-3333-333333333333', 'SENSOR_003', 'Ford Transit Van - Test Vehicle 3', 2.08, true),
    ('44444444-4444-4444-4444-444444444444', 'SENSOR_004', 'VW Golf - Test Vehicle 4', 1.79, true),
    ('55555555-5555-5555-5555-555555555555', 'SENSOR_005', 'Tesla Model 3 - Test Vehicle 5', 1.85, false);

-- ==============================================
-- SAMPLE SESSIONS
-- ==============================================

-- Active sessions (no end_time)
INSERT INTO sessions (id, sensor_id, start_time, end_time, measurement_count) VALUES
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111', 
     CURRENT_TIMESTAMP - INTERVAL '2 hours', NULL, 0);

-- Completed sessions
INSERT INTO sessions (id, sensor_id, start_time, end_time, measurement_count) VALUES
    ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '11111111-1111-1111-1111-111111111111',
     CURRENT_TIMESTAMP - INTERVAL '1 day', CURRENT_TIMESTAMP - INTERVAL '1 day' + INTERVAL '3 hours', 0),
    ('cccccccc-cccc-cccc-cccc-cccccccccccc', '22222222-2222-2222-2222-222222222222',
     CURRENT_TIMESTAMP - INTERVAL '2 days', CURRENT_TIMESTAMP - INTERVAL '2 days' + INTERVAL '2 hours', 0),
    ('dddddddd-dddd-dddd-dddd-dddddddddddd', '33333333-3333-3333-3333-333333333333',
     CURRENT_TIMESTAMP - INTERVAL '3 days', CURRENT_TIMESTAMP - INTERVAL '3 days' + INTERVAL '4 hours', 0);

-- ==============================================
-- SAMPLE ROAD SEGMENTS (OpenStreetMap data)
-- ==============================================
-- Using realistic coordinates for Prague, Czech Republic

INSERT INTO road_segments (id, osm_id, name, road_type, geom, municipality, region) VALUES
    (
        'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee',
        'way/123456789',
        'Václavské náměstí',
        'primary',
        ST_GeomFromText('LINESTRING(14.4266 50.0806, 14.4280 50.0820)', 4326),
        'Praha 1',
        'Prague'
    ),
    (
        'ffffffff-ffff-ffff-ffff-ffffffffffff',
        'way/234567890',
        'Karlovo náměstí',
        'secondary',
        ST_GeomFromText('LINESTRING(14.4190 50.0750, 14.4210 50.0765)', 4326),
        'Praha 2',
        'Prague'
    ),
    (
        'gggggggg-gggg-gggg-gggg-gggggggggggg',
        'way/345678901',
        'Národní třída',
        'primary',
        ST_GeomFromText('LINESTRING(14.4150 50.0810, 14.4180 50.0820)', 4326),
        'Praha 1',
        'Prague'
    ),
    (
        'hhhhhhhh-hhhh-hhhh-hhhh-hhhhhhhhhhhh',
        'way/456789012',
        'Vinohradská',
        'tertiary',
        ST_GeomFromText('LINESTRING(14.4400 50.0780, 14.4450 50.0790)', 4326),
        'Praha 3',
        'Prague'
    ),
    (
        'iiiiiiii-iiii-iiii-iiii-iiiiiiiiiiii',
        'way/567890123',
        'Pražský okruh',
        'motorway',
        ST_GeomFromText('LINESTRING(14.5000 50.1000, 14.5100 50.1050)', 4326),
        'Praha',
        'Prague'
    );

-- ==============================================
-- SAMPLE RAW MEASUREMENTS
-- ==============================================

-- Measurements from session bbbbbbbb (completed session on Václavské náměstí)
INSERT INTO raw_measurements (session_id, measured_at, latitude, longitude, distance_left, distance_right, is_valid) VALUES
    -- Good measurements
    ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', CURRENT_TIMESTAMP - INTERVAL '1 day', 50.0806, 14.4266, 3.2, 3.5, true),
    ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', CURRENT_TIMESTAMP - INTERVAL '1 day' + INTERVAL '5 seconds', 50.0808, 14.4268, 3.3, 3.4, true),
    ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', CURRENT_TIMESTAMP - INTERVAL '1 day' + INTERVAL '10 seconds', 50.0810, 14.4270, 3.1, 3.6, true),
    ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', CURRENT_TIMESTAMP - INTERVAL '1 day' + INTERVAL '15 seconds', 50.0812, 14.4272, 3.4, 3.3, true),
    ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', CURRENT_TIMESTAMP - INTERVAL '1 day' + INTERVAL '20 seconds', 50.0814, 14.4274, 3.2, 3.5, true),
    
    -- Invalid measurement (sensor error)
    ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', CURRENT_TIMESTAMP - INTERVAL '1 day' + INTERVAL '25 seconds', 50.0816, 14.4276, 0.1, 0.1, false);

-- Measurements from session cccccccc (Karlovo náměstí)
INSERT INTO raw_measurements (session_id, measured_at, latitude, longitude, distance_left, distance_right, is_valid) VALUES
    ('cccccccc-cccc-cccc-cccc-cccccccccccc', CURRENT_TIMESTAMP - INTERVAL '2 days', 50.0750, 14.4190, 2.8, 2.9, true),
    ('cccccccc-cccc-cccc-cccc-cccccccccccc', CURRENT_TIMESTAMP - INTERVAL '2 days' + INTERVAL '5 seconds', 50.0752, 14.4192, 2.7, 3.0, true),
    ('cccccccc-cccc-cccc-cccc-cccccccccccc', CURRENT_TIMESTAMP - INTERVAL '2 days' + INTERVAL '10 seconds', 50.0754, 14.4194, 2.9, 2.8, true),
    ('cccccccc-cccc-cccc-cccc-cccccccccccc', CURRENT_TIMESTAMP - INTERVAL '2 days' + INTERVAL '15 seconds', 50.0756, 14.4196, 2.8, 2.9, true);

-- Measurements from session dddddddd (Pražský okruh - motorway)
INSERT INTO raw_measurements (session_id, measured_at, latitude, longitude, distance_left, distance_right, is_valid) VALUES
    ('dddddddd-dddd-dddd-dddd-dddddddddddd', CURRENT_TIMESTAMP - INTERVAL '3 days', 50.1000, 14.5000, 5.5, 5.8, true),
    ('dddddddd-dddd-dddd-dddd-dddddddddddd', CURRENT_TIMESTAMP - INTERVAL '3 days' + INTERVAL '5 seconds', 50.1005, 14.5010, 5.6, 5.7, true),
    ('dddddddd-dddd-dddd-dddd-dddddddddddd', CURRENT_TIMESTAMP - INTERVAL '3 days' + INTERVAL '10 seconds', 50.1010, 14.5020, 5.4, 5.9, true),
    ('dddddddd-dddd-dddd-dddd-dddddddddddd', CURRENT_TIMESTAMP - INTERVAL '3 days' + INTERVAL '15 seconds', 50.1015, 14.5030, 5.7, 5.6, true);

-- Measurements from active session aaaaaaaa (recent, no end_time)
INSERT INTO raw_measurements (session_id, measured_at, latitude, longitude, distance_left, distance_right, is_valid) VALUES
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', CURRENT_TIMESTAMP - INTERVAL '30 minutes', 50.0810, 14.4150, 3.0, 3.2, true),
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', CURRENT_TIMESTAMP - INTERVAL '25 minutes', 50.0812, 14.4152, 3.1, 3.1, true),
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', CURRENT_TIMESTAMP - INTERVAL '20 minutes', 50.0814, 14.4154, 3.2, 3.0, true);

-- ==============================================
-- SAMPLE CLEANED MEASUREMENTS
-- ==============================================

-- Clean measurements from session bbbbbbbb
INSERT INTO cleaned_measurements (raw_measurement_id, cleaned_width, quality_score, geom)
SELECT 
    rm.id,
    rm.distance_left + rm.distance_right + s.vehicle_width as cleaned_width,
    0.95 as quality_score,
    ST_SetSRID(ST_MakePoint(rm.longitude, rm.latitude), 4326) as geom
FROM raw_measurements rm
JOIN sessions ses ON rm.session_id = ses.id
JOIN sensors s ON ses.sensor_id = s.id
WHERE rm.session_id = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'
    AND rm.is_valid = true;

-- Clean measurements from session cccccccc
INSERT INTO cleaned_measurements (raw_measurement_id, cleaned_width, quality_score, geom)
SELECT 
    rm.id,
    rm.distance_left + rm.distance_right + s.vehicle_width as cleaned_width,
    0.92 as quality_score,
    ST_SetSRID(ST_MakePoint(rm.longitude, rm.latitude), 4326) as geom
FROM raw_measurements rm
JOIN sessions ses ON rm.session_id = ses.id
JOIN sensors s ON ses.sensor_id = s.id
WHERE rm.session_id = 'cccccccc-cccc-cccc-cccc-cccccccccccc'
    AND rm.is_valid = true;

-- Clean measurements from session dddddddd
INSERT INTO cleaned_measurements (raw_measurement_id, cleaned_width, quality_score, geom)
SELECT 
    rm.id,
    rm.distance_left + rm.distance_right + s.vehicle_width as cleaned_width,
    0.98 as quality_score,
    ST_SetSRID(ST_MakePoint(rm.longitude, rm.latitude), 4326) as geom
FROM raw_measurements rm
JOIN sessions ses ON rm.session_id = ses.id
JOIN sensors s ON ses.sensor_id = s.id
WHERE rm.session_id = 'dddddddd-dddd-dddd-dddd-dddddddddddd'
    AND rm.is_valid = true;

-- ==============================================
-- SAMPLE INVALID MEASUREMENTS
-- ==============================================

INSERT INTO invalid_measurements (raw_measurement_id, rejection_reason)
SELECT 
    id,
    'Sensor error: distances too small, likely obstruction detected'
FROM raw_measurements
WHERE is_valid = false;

-- ==============================================
-- SAMPLE CLUSTERS
-- ==============================================

-- Cluster for Václavské náměstí
INSERT INTO clusters (id, road_segment_id, avg_width, min_width, max_width, measurement_count, geom) VALUES
    (
        'c1c1c1c1-c1c1-c1c1-c1c1-c1c1c1c1c1c1',
        'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee',
        8.45,
        8.05,
        8.75,
        5,
        ST_SetSRID(ST_MakePoint(14.4270, 50.0810), 4326)
    );

-- Cluster for Karlovo náměstí
INSERT INTO clusters (id, road_segment_id, avg_width, min_width, max_width, measurement_count, geom) VALUES
    (
        'c2c2c2c2-c2c2-c2c2-c2c2-c2c2c2c2c2c2',
        'ffffffff-ffff-ffff-ffff-ffffffffffff',
        7.58,
        7.28,
        7.88,
        4,
        ST_SetSRID(ST_MakePoint(14.4195, 50.0755), 4326)
    );

-- Cluster for Pražský okruh (motorway)
INSERT INTO clusters (id, road_segment_id, avg_width, min_width, max_width, measurement_count, geom) VALUES
    (
        'c3c3c3c3-c3c3-c3c3-c3c3-c3c3c3c3c3c3',
        'iiiiiiii-iiii-iiii-iiii-iiiiiiiiiiii',
        13.48,
        13.08,
        13.88,
        4,
        ST_SetSRID(ST_MakePoint(14.5015, 50.1010), 4326)
    );

-- ==============================================
-- SAMPLE SEGMENT STATISTICS
-- ==============================================

-- Statistics for last 7 days for Václavské náměstí
INSERT INTO segment_statistics (segment_id, stat_date, avg_width, min_width, max_width, measurements_count) VALUES
    ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', CURRENT_DATE - INTERVAL '1 day', 8.45, 8.05, 8.75, 5),
    ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', CURRENT_DATE - INTERVAL '2 days', 8.52, 8.15, 8.80, 3),
    ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', CURRENT_DATE - INTERVAL '3 days', 8.38, 8.00, 8.70, 4);

-- Statistics for Karlovo náměstí
INSERT INTO segment_statistics (segment_id, stat_date, avg_width, min_width, max_width, measurements_count) VALUES
    ('ffffffff-ffff-ffff-ffff-ffffffffffff', CURRENT_DATE - INTERVAL '2 days', 7.58, 7.28, 7.88, 4),
    ('ffffffff-ffff-ffff-ffff-ffffffffffff', CURRENT_DATE - INTERVAL '4 days', 7.62, 7.32, 7.92, 3);

-- Statistics for Pražský okruh
INSERT INTO segment_statistics (segment_id, stat_date, avg_width, min_width, max_width, measurements_count) VALUES
    ('iiiiiiii-iiii-iiii-iiii-iiiiiiiiiiii', CURRENT_DATE - INTERVAL '3 days', 13.48, 13.08, 13.88, 4),
    ('iiiiiiii-iiii-iiii-iiii-iiiiiiiiiiii', CURRENT_DATE - INTERVAL '5 days', 13.52, 13.12, 13.92, 5);

-- ==============================================
-- VERIFICATION
-- ==============================================

-- Display summary of sample data
DO $$
DECLARE
    sensor_count INTEGER;
    session_count INTEGER;
    raw_count INTEGER;
    cleaned_count INTEGER;
    invalid_count INTEGER;
    segment_count INTEGER;
    cluster_count INTEGER;
    stats_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO sensor_count FROM sensors;
    SELECT COUNT(*) INTO session_count FROM sessions;
    SELECT COUNT(*) INTO raw_count FROM raw_measurements;
    SELECT COUNT(*) INTO cleaned_count FROM cleaned_measurements;
    SELECT COUNT(*) INTO invalid_count FROM invalid_measurements;
    SELECT COUNT(*) INTO segment_count FROM road_segments;
    SELECT COUNT(*) INTO cluster_count FROM clusters;
    SELECT COUNT(*) INTO stats_count FROM segment_statistics;
    
    RAISE NOTICE '============================================';
    RAISE NOTICE 'ClearWay Sample Data Loaded Successfully';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'Sensors: %', sensor_count;
    RAISE NOTICE 'Sessions: %', session_count;
    RAISE NOTICE 'Raw measurements: %', raw_count;
    RAISE NOTICE 'Cleaned measurements: %', cleaned_count;
    RAISE NOTICE 'Invalid measurements: %', invalid_count;
    RAISE NOTICE 'Road segments: %', segment_count;
    RAISE NOTICE 'Clusters: %', cluster_count;
    RAISE NOTICE 'Segment statistics: %', stats_count;
    RAISE NOTICE '============================================';
    RAISE NOTICE 'Active sessions: %', (SELECT COUNT(*) FROM sessions WHERE end_time IS NULL);
    RAISE NOTICE 'Total road width data points: %', cleaned_count;
    RAISE NOTICE '============================================';
END $$;
