-- ClearWay Database Schema
-- Purpose: Store and analyze road width measurements from vehicle sensors

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

DROP TABLE IF EXISTS segment_statistics CASCADE;
DROP TABLE IF EXISTS clusters CASCADE;
DROP TABLE IF EXISTS road_segments CASCADE;
DROP TABLE IF EXISTS invalid_measurements CASCADE;
DROP TABLE IF EXISTS cleaned_measurements CASCADE;
DROP TABLE IF EXISTS raw_measurements CASCADE;
DROP TABLE IF EXISTS sessions CASCADE;
DROP TABLE IF EXISTS sensors CASCADE;
DROP TABLE IF EXISTS vehicles CASCADE;
DROP TABLE IF EXISTS target_vehicles CASCADE;

-- Drop existing tables if they exist (for clean reset)
DROP TABLE IF EXISTS segment_statistics CASCADE;
DROP TABLE IF EXISTS clusters CASCADE;
DROP TABLE IF EXISTS road_segments CASCADE;
DROP TABLE IF EXISTS invalid_measurements CASCADE;
DROP TABLE IF EXISTS cleaned_measurements CASCADE;
DROP TABLE IF EXISTS raw_measurements CASCADE;
DROP TABLE IF EXISTS sessions CASCADE;
DROP TABLE IF EXISTS sensors CASCADE;

-- ==============================================
CREATE TABLE sensors (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_sensors_is_active ON sensors(is_active);

-- ==============================================
-- VEHICLES TABLE
-- ==============================================
CREATE TABLE vehicles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    vehicle_name VARCHAR(100) NOT NULL,
    width FLOAT NOT NULL CHECK (width > 0)
);

-- ==============================================
-- TARGET VEHICLES TABLE
-- ==============================================
-- IZS and other vehicles whose road passability is evaluated
CREATE TABLE target_vehicles (
    id                   UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name                 VARCHAR(255) NOT NULL,
    category             VARCHAR(100),
    width                FLOAT CHECK (width > 0),
    height               FLOAT CHECK (height > 0),
    weight               FLOAT CHECK (weight > 0),
    turning_radius_inner FLOAT CHECK (turning_radius_inner > 0),
    turning_radius_outer FLOAT CHECK (turning_radius_outer > 0 AND turning_radius_outer >= turning_radius_inner),
    created_at           TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at           TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE target_vehicles IS 'IZS and other vehicles whose road passability is evaluated against road segment measurements';
COMMENT ON COLUMN target_vehicles.width IS 'Vehicle width in meters';
COMMENT ON COLUMN target_vehicles.height IS 'Vehicle height in meters';
COMMENT ON COLUMN target_vehicles.weight IS 'Vehicle weight in tonnes';
COMMENT ON COLUMN target_vehicles.turning_radius_inner IS 'Inner turning radius in meters';
COMMENT ON COLUMN target_vehicles.turning_radius_outer IS 'Outer turning radius in meters';

-- ==============================================
-- SESSIONS TABLE
-- ==============================================
CREATE TABLE sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sensor_id UUID NOT NULL REFERENCES sensors(id) ON DELETE CASCADE,
    vehicle_id UUID NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE
);

CREATE INDEX idx_sessions_sensor_id ON sessions(sensor_id);
CREATE INDEX idx_sessions_vehicle_id ON sessions(vehicle_id);

-- ==============================================
-- RAW MEASUREMENTS TABLE
-- ==============================================
-- Stores raw sensor measurements
CREATE TABLE raw_measurements (
    id BIGSERIAL PRIMARY KEY,
    session_id UUID NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
    measured_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    latitude DOUBLE PRECISION NOT NULL CHECK (latitude BETWEEN -90 AND 90),
    longitude DOUBLE PRECISION NOT NULL CHECK (longitude BETWEEN -180 AND 180),
    distance_left FLOAT NOT NULL CHECK (distance_left >= 0),
    distance_right FLOAT NOT NULL CHECK (distance_right >= 0),
    is_valid BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for performance
CREATE INDEX idx_raw_measurements_session_id ON raw_measurements(session_id);
CREATE INDEX idx_raw_measurements_measured_at ON raw_measurements(measured_at DESC);
CREATE INDEX idx_raw_measurements_is_valid ON raw_measurements(is_valid);
CREATE INDEX idx_raw_measurements_location ON raw_measurements(latitude, longitude);

-- ==============================================
-- ROAD SEGMENTS TABLE
-- ==============================================
-- Represents road segments from OpenStreetMap
CREATE TABLE road_segments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    osm_id VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(255),
    road_type VARCHAR(50),
    geom GEOMETRY(LINESTRING, 4326) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Spatial index for geographic queries
CREATE INDEX idx_road_segments_geom ON road_segments USING GIST(geom);
CREATE INDEX idx_road_segments_osm_id ON road_segments(osm_id);
CREATE INDEX idx_road_segments_road_type ON road_segments(road_type);

-- ==============================================
-- CLUSTERS TABLE
-- ==============================================
CREATE TABLE clusters (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    road_segment_id UUID REFERENCES road_segments(id) ON DELETE SET NULL,
    avg_width FLOAT NOT NULL CHECK (avg_width > 0),
    min_width FLOAT NOT NULL CHECK (min_width > 0),
    max_width FLOAT NOT NULL CHECK (max_width > 0),
    geom GEOMETRY(POINT, 4326) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT width_range_valid CHECK (min_width <= avg_width AND avg_width <= max_width)
);

CREATE INDEX idx_clusters_geom ON clusters USING GIST(geom);
CREATE INDEX idx_clusters_road_segment ON clusters(road_segment_id);
CREATE INDEX idx_clusters_avg_width ON clusters(avg_width);

-- ==============================================
-- CLEANED MEASUREMENTS TABLE
-- ==============================================
CREATE TABLE cleaned_measurements (
    id BIGSERIAL PRIMARY KEY,
    raw_measurement_id BIGINT NOT NULL REFERENCES raw_measurements(id) ON DELETE CASCADE,
    cleaned_width FLOAT NOT NULL CHECK (cleaned_width > 0),
    quality_score FLOAT CHECK (quality_score BETWEEN 0 AND 1),
    cluster_id UUID REFERENCES clusters(id) ON DELETE SET NULL,
    geom GEOMETRY(POINT, 4326) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_cleaned_measurements_geom ON cleaned_measurements USING GIST(geom);
CREATE INDEX idx_cleaned_measurements_raw_id ON cleaned_measurements(raw_measurement_id);
CREATE INDEX idx_cleaned_measurements_quality ON cleaned_measurements(quality_score DESC);
CREATE INDEX idx_cleaned_measurements_cluster_id ON cleaned_measurements(cluster_id);

-- ==============================================
-- INVALID MEASUREMENTS TABLE
-- ==============================================
-- Stores rejected measurements for analysis
CREATE TABLE invalid_measurements (
    id BIGSERIAL PRIMARY KEY,
    raw_measurement_id BIGINT NOT NULL REFERENCES raw_measurements(id) ON DELETE CASCADE,
    rejection_reason TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Index for performance
CREATE INDEX idx_invalid_measurements_raw_id ON invalid_measurements(raw_measurement_id);

-- ==============================================
-- SEGMENT STATISTICS TABLE
-- ==============================================
-- Daily statistics for road segments
CREATE TABLE segment_statistics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    segment_id UUID NOT NULL REFERENCES road_segments(id) ON DELETE CASCADE,
    stat_date DATE NOT NULL,
    avg_width FLOAT CHECK (avg_width > 0),
    min_width FLOAT CHECK (min_width > 0),
    max_width FLOAT CHECK (max_width > 0),
    measurements_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_segment_date UNIQUE(segment_id, stat_date),
    CONSTRAINT stats_width_range_valid CHECK (min_width <= avg_width AND avg_width <= max_width)
);

-- Indexes for performance
CREATE INDEX idx_segment_statistics_segment_id ON segment_statistics(segment_id);
CREATE INDEX idx_segment_statistics_stat_date ON segment_statistics(stat_date DESC);
CREATE INDEX idx_segment_statistics_avg_width ON segment_statistics(avg_width);

-- ==============================================
-- VIEWS FOR ANALYTICS
-- ==============================================

-- Active sessions view
CREATE OR REPLACE VIEW active_sessions AS
SELECT 
    s.*,
    sen.description,
    v.vehicle_name,
    v.width as vehicle_width
FROM sessions s
JOIN sensors sen ON s.sensor_id = sen.id
JOIN vehicles v ON s.vehicle_id = v.id;

-- Recent measurements view (last 24 hours)
CREATE OR REPLACE VIEW recent_measurements AS
SELECT 
    rm.id,
    rm.session_id,
    rm.measured_at,
    rm.latitude,
    rm.longitude,
    rm.distance_left,
    rm.distance_right,
    rm.is_valid,
    s.sensor_id,
    s.vehicle_id,
    sen.description as sensor_description,
    v.vehicle_name,
    v.width as vehicle_width
FROM raw_measurements rm
JOIN sessions s ON rm.session_id = s.id
JOIN sensors sen ON s.sensor_id = sen.id
JOIN vehicles v ON s.vehicle_id = v.id
WHERE rm.measured_at > CURRENT_TIMESTAMP - INTERVAL '24 hours'
ORDER BY rm.measured_at DESC;

CREATE OR REPLACE VIEW road_segment_summary AS
SELECT 
    rs.id,
    rs.osm_id,
    rs.name,
    rs.road_type,
    COUNT(DISTINCT c.id) as cluster_count,
    AVG(c.avg_width) as overall_avg_width,
    MIN(c.min_width) as overall_min_width,
    MAX(c.max_width) as overall_max_width
FROM road_segments rs
LEFT JOIN clusters c ON rs.id = c.road_segment_id
GROUP BY rs.id, rs.osm_id, rs.name, rs.road_type;

-- ==============================================
-- FUNCTIONS
-- ==============================================

-- Note: Removed update_session_measurement_count function and trigger
-- as sessions table no longer has measurement_count column

-- Function to calculate road width from raw measurements
CREATE OR REPLACE FUNCTION calculate_road_width(
    distance_left FLOAT,
    distance_right FLOAT,
    vehicle_width FLOAT
)
RETURNS FLOAT AS $$
BEGIN
    RETURN distance_left + distance_right + vehicle_width;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Function to find nearby measurements
CREATE OR REPLACE FUNCTION find_nearby_measurements(
    lat DOUBLE PRECISION,
    lon DOUBLE PRECISION,
    radius_meters INTEGER DEFAULT 100
)
RETURNS TABLE (
    measurement_id BIGINT,
    distance_meters DOUBLE PRECISION,
    cleaned_width FLOAT,
    quality_score FLOAT,
    measured_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        cm.id,
        ST_Distance(
            cm.geom::geography,
            ST_SetSRID(ST_MakePoint(lon, lat), 4326)::geography
        ) as distance,
        cm.cleaned_width,
        cm.quality_score,
        rm.measured_at
    FROM cleaned_measurements cm
    JOIN raw_measurements rm ON cm.raw_measurement_id = rm.id
    WHERE ST_DWithin(
        cm.geom::geography,
        ST_SetSRID(ST_MakePoint(lon, lat), 4326)::geography,
        radius_meters
    )
    ORDER BY distance;
END;
$$ LANGUAGE plpgsql;

-- Function to get road segment statistics for date range
CREATE OR REPLACE FUNCTION get_segment_statistics(
    segment_uuid UUID,
    start_date DATE,
    end_date DATE
)
RETURNS TABLE (
    stat_date DATE,
    avg_width FLOAT,
    min_width FLOAT,
    max_width FLOAT,
    measurements_count INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ss.stat_date,
        ss.avg_width,
        ss.min_width,
        ss.max_width,
        ss.measurements_count
    FROM segment_statistics ss
    WHERE ss.segment_id = segment_uuid
        AND ss.stat_date BETWEEN start_date AND end_date
    ORDER BY ss.stat_date;
END;
$$ LANGUAGE plpgsql;

-- ==============================================
-- COMMENTS FOR DOCUMENTATION
-- ==============================================

COMMENT ON TABLE sensors IS 'Vehicle-mounted sensors collecting road width measurements';
COMMENT ON TABLE sessions IS 'Measurement collection sessions from sensors';
COMMENT ON TABLE raw_measurements IS 'Raw unprocessed sensor measurements';
COMMENT ON TABLE cleaned_measurements IS 'Validated and processed measurements';
COMMENT ON TABLE invalid_measurements IS 'Rejected measurements with reasons';
COMMENT ON TABLE road_segments IS 'Road segments from OpenStreetMap';
COMMENT ON TABLE clusters IS 'Aggregated measurements grouped by location';
COMMENT ON TABLE segment_statistics IS 'Daily statistics for road segments';

COMMENT ON COLUMN raw_measurements.distance_left IS 'Distance from sensor to left road edge (meters)';
COMMENT ON COLUMN raw_measurements.distance_right IS 'Distance from sensor to right road edge (meters)';
COMMENT ON COLUMN cleaned_measurements.quality_score IS 'Measurement quality score from 0 (low) to 1 (high)';
COMMENT ON COLUMN clusters.avg_width IS 'Average road width in cluster (meters)';

-- ==============================================
-- INITIAL SETUP COMPLETE
-- ==============================================

-- Grant permissions (adjust as needed for your application user)
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO clearway;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO clearway;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO clearway;
GRANT SELECT, INSERT, UPDATE, DELETE ON target_vehicles TO clearway;
