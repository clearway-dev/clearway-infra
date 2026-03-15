-- V008: Remove CHECK constraints from speed and accuracy_gps in raw_measurements
-- Bronze layer should accept any value including negatives from faulty sensors;
-- validation happens downstream in the pipeline.

ALTER TABLE raw_measurements
    DROP CONSTRAINT IF EXISTS raw_measurements_speed_check,
    DROP CONSTRAINT IF EXISTS raw_measurements_accuracy_gps_check;
