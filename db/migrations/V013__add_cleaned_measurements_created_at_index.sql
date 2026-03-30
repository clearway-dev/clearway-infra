-- Add index on cleaned_measurements.created_at for efficient date-range filtering.
-- DATE(created_at) is not IMMUTABLE so a functional index cannot be created;
-- a plain B-tree index on the column itself is used instead and queries must
-- use range conditions (>= date AND < date + INTERVAL '1 day').

CREATE INDEX IF NOT EXISTS idx_cleaned_measurements_created_at
    ON cleaned_measurements(created_at);
