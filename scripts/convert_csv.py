"""
convert_csv.py — Import a CSV measurement file into the ClearWay database.

Creates a Session → Batch → RawMeasurements chain matching the current schema.

Usage:
    python convert_csv.py --date 2026-03-31 --sensor-id <uuid> --vehicle-id <uuid>
    python convert_csv.py --date 2026-03-31  # uses defaults below

CSV format expected: time,GPS1,GPS2,A,B,C
    time   — HH:MM:SS
    GPS1   — latitude
    GPS2   — longitude
    A      — distance_left (cm)
    C      — distance_right (cm)
    B      — unused
"""

import argparse
import os
import sys
import uuid
from datetime import datetime

import pandas as pd
import psycopg2
from psycopg2.extras import execute_values

# ── Defaults (override via CLI args) ─────────────────────────────────────────
DEFAULT_INPUT_FILE = "../data/dataset.csv"
DEFAULT_SENSOR_ID  = "22222222-2222-2222-2222-222222222222"
DEFAULT_VEHICLE_ID = "11111111-1111-1111-1111-111111111111"  # ClearWay Test Vehicle (208 cm)
# ─────────────────────────────────────────────────────────────────────────────

DATABASE_URL = os.environ.get(
    "DATABASE_URL",
    "postgresql://clearway:clearway_dev_password@localhost:5432/clearway_db",
)


def main() -> None:
    parser = argparse.ArgumentParser(description="Import CSV dataset into ClearWay DB.")
    parser.add_argument("--date",       required=True, metavar="YYYY-MM-DD", help="Date of measurement")
    parser.add_argument("--input",      default=DEFAULT_INPUT_FILE,          help="Path to CSV file")
    parser.add_argument("--sensor-id",  default=DEFAULT_SENSOR_ID,           help="Sensor UUID")
    parser.add_argument("--vehicle-id", default=DEFAULT_VEHICLE_ID,          help="Vehicle UUID")
    args = parser.parse_args()

    measurement_date = args.date

    # -- Load CSV -------------------------------------------------------------
    print(f"Reading {args.input}...")
    df = pd.read_csv(args.input)
    df = df.rename(columns={"GPS1": "latitude", "GPS2": "longitude",
                             "A": "distance_left", "C": "distance_right"})

    df["measured_at"] = pd.to_datetime(
        measurement_date + " " + df["time"], format="%Y-%m-%d %H:%M:%S"
    )

    print(f"Loaded {len(df)} rows for {measurement_date}.")

    # -- Insert into DB -------------------------------------------------------
    conn = psycopg2.connect(DATABASE_URL)
    try:
        with conn:
            with conn.cursor() as cur:
                # 1. Create Session
                session_id = str(uuid.uuid4())
                cur.execute(
                    "INSERT INTO sessions (id, sensor_id, vehicle_id) VALUES (%s, %s, %s)",
                    (session_id, args.sensor_id, args.vehicle_id),
                )
                print(f"Created session: {session_id}")

                # 2. Create Batch
                batch_id = str(uuid.uuid4())
                cur.execute(
                    "INSERT INTO batches (id, session_id, status) VALUES (%s, %s, 'completed')",
                    (batch_id, session_id),
                )
                print(f"Created batch:   {batch_id}")

                # 3. Insert RawMeasurements
                rows = [
                    (
                        batch_id,
                        row["measured_at"].to_pydatetime(),
                        row["latitude"],
                        row["longitude"],
                        row["distance_left"],
                        row["distance_right"],
                    )
                    for _, row in df.iterrows()
                ]

                execute_values(
                    cur,
                    """
                    INSERT INTO raw_measurements
                        (batch_id, measured_at, latitude, longitude, distance_left, distance_right)
                    VALUES %s
                    """,
                    rows,
                )
                print(f"Inserted {len(rows)} raw measurements.")

    finally:
        conn.close()

    print("Done. Run calculate_stats.py to process the new data.")


if __name__ == "__main__":
    main()
