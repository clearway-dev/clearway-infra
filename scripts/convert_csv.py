import pandas as pd
import sys
from datetime import datetime

# CONFIGURATION
# ==========================================
INPUT_FILE = '../data/dataset.csv'      # Your source file
OUTPUT_FILE = '../sql/output.sql'   # The file to run in PgAdmin
SESSION_ID = '00000000-0000-0000-0000-000000000000' # Matches the SQL above
DATE_OF_MEASUREMENT = '2025-11-18' # Set the actual date of the drive here
# ==========================================

def generate_sql(): 
    try:
        # Read the CSV
        print(f"Reading {INPUT_FILE}...")
        df = pd.read_csv(INPUT_FILE)
        
        # Rename columns to match database schema
        # CSV: time, GPS1, GPS2, A, B, C
        df = df.rename(columns={
            'GPS1': 'latitude',
            'GPS2': 'longitude',
            'A': 'distance_left',
            'C': 'distance_right'
        })
        
        # Create timestamp column
        # The CSV only has time (HH:MM:SS), so we attach the date
        df['measured_at'] = pd.to_datetime(
            DATE_OF_MEASUREMENT + ' ' + df['time'], 
            format='%Y-%m-%d %H:%M:%S'
        )
        
        # Add required constant columns
        df['session_id'] = SESSION_ID
        df['is_valid'] = False  # As requested
        
        # Select and reorder columns
        cols = ['session_id', 'measured_at', 'latitude', 'longitude', 'distance_left', 'distance_right', 'is_valid']
        
        # Generate SQL file
        print(f"Generating SQL for {len(df)} rows...")
        with open(OUTPUT_FILE, 'w') as f:
            f.write("-- Bulk Insert for ClearWay\n")
            f.write("BEGIN;\n") # Start transaction for speed
            
            for _, row in df.iterrows():
                sql = (
                    "INSERT INTO raw_measurements "
                    "(session_id, measured_at, latitude, longitude, distance_left, distance_right, is_valid) "
                    "VALUES "
                    f"('{row['session_id']}', '{row['measured_at']}', {row['latitude']}, {row['longitude']}, "
                    f"{row['distance_left']}, {row['distance_right']}, {row['is_valid']});\n"
                )
                f.write(sql)
                
            f.write("COMMIT;\n")
            
        print(f"Success! Run '{OUTPUT_FILE}' in your database query tool.")

    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    generate_sql()