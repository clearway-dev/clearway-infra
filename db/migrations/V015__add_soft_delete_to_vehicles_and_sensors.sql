-- Add soft delete support to vehicles and sensors.
-- Rows are never hard-deleted; set deleted_at to mark as removed.

ALTER TABLE vehicles ADD COLUMN deleted_at TIMESTAMP WITH TIME ZONE DEFAULT NULL;
ALTER TABLE sensors  ADD COLUMN deleted_at TIMESTAMP WITH TIME ZONE DEFAULT NULL;

CREATE INDEX idx_vehicles_deleted_at ON vehicles(deleted_at);
CREATE INDEX idx_sensors_deleted_at  ON sensors(deleted_at);

-- Prevent hard-deleting a vehicle or sensor that has sessions (safety net for soft-delete approach).
ALTER TABLE sessions DROP CONSTRAINT sessions_vehicle_id_fkey;
ALTER TABLE sessions ADD CONSTRAINT sessions_vehicle_id_fkey
    FOREIGN KEY (vehicle_id) REFERENCES vehicles(id) ON DELETE RESTRICT;

ALTER TABLE sessions DROP CONSTRAINT sessions_sensor_id_fkey;
ALTER TABLE sessions ADD CONSTRAINT sessions_sensor_id_fkey
    FOREIGN KEY (sensor_id) REFERENCES sensors(id) ON DELETE RESTRICT;
