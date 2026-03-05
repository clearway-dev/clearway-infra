-- V005: Unify target_vehicles dimensional columns from metres (FLOAT) to centimetres (INTEGER).
-- Affected columns: width, height, length, turning_diameter_track,
--                   turning_diameter_clearance, stabilization_width
-- weight stays as-is (tonnes, FLOAT).

ALTER TABLE target_vehicles
    ALTER COLUMN width                      TYPE INTEGER
        USING CASE WHEN width IS NOT NULL
                   THEN ROUND(width * 100)::INTEGER END,
    ALTER COLUMN height                     TYPE INTEGER
        USING CASE WHEN height IS NOT NULL
                   THEN ROUND(height * 100)::INTEGER END,
    ALTER COLUMN length                     TYPE INTEGER
        USING CASE WHEN length IS NOT NULL
                   THEN ROUND(length * 100)::INTEGER END,
    ALTER COLUMN turning_diameter_track     TYPE INTEGER
        USING CASE WHEN turning_diameter_track IS NOT NULL
                   THEN ROUND(turning_diameter_track * 100)::INTEGER END,
    ALTER COLUMN turning_diameter_clearance TYPE INTEGER
        USING CASE WHEN turning_diameter_clearance IS NOT NULL
                   THEN ROUND(turning_diameter_clearance * 100)::INTEGER END,
    ALTER COLUMN stabilization_width        TYPE INTEGER
        USING CASE WHEN stabilization_width IS NOT NULL
                   THEN ROUND(stabilization_width * 100)::INTEGER END;
