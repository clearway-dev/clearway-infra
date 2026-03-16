#!/usr/bin/env python3
"""
Seeds OSM road segments into the road_segments table.

Usage:
    python scripts/seed_roads.py [place_name]

Defaults to "Plzeň, Czechia". All inserts use ON CONFLICT DO NOTHING
so the script is safe to re-run.

Reads DB connection from .env in the repo root (same variables used by
docker-compose.yml): POSTGRES_USER, POSTGRES_PASSWORD, POSTGRES_DB, DB_PORT.
"""

import sys
import os
import psycopg2
import osmnx as ox
from dotenv import load_dotenv

# Load .env from repo root (clearway-infra/)
env_path = os.path.join(os.path.dirname(__file__), "..", ".env")
load_dotenv(env_path)

DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = os.getenv("DB_PORT", "5432")
DB_NAME = os.getenv("POSTGRES_DB", "clearway")
DB_USER = os.getenv("POSTGRES_USER", "clearway")
DB_PASSWORD = os.getenv("POSTGRES_PASSWORD", "clearway_dev_password")


def seed_roads(place_name: str = "Plzeň, Czechia"):
    print(f"Downloading OSM road network for: {place_name}")
    G = ox.graph_from_place(place_name, network_type="drive")
    _, gdf_edges = ox.graph_to_gdfs(G)
    gdf_edges = gdf_edges.reset_index()
    print(f"Fetched {len(gdf_edges)} edges from OSM")

    conn = psycopg2.connect(
        host=DB_HOST,
        port=DB_PORT,
        dbname=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD,
    )

    try:
        with conn:
            with conn.cursor() as cur:
                count = 0
                for _, row in gdf_edges.iterrows():
                    name = row.get("name")
                    if isinstance(name, list):
                        name = name[0]

                    road_type = row.get("highway")
                    if isinstance(road_type, list):
                        road_type = road_type[0]

                    osm_id = f"{row['u']}-{row['v']}-{row['key']}"
                    geom_wkt = row["geometry"].wkt

                    cur.execute(
                        """
                        INSERT INTO road_segments (osm_id, name, road_type, geom)
                        VALUES (%s, %s, %s, ST_GeomFromText(%s, 4326))
                        ON CONFLICT (osm_id) DO NOTHING
                        """,
                        (osm_id, str(name) if name else "Unknown", str(road_type), geom_wkt),
                    )
                    count += 1

                    if count % 1000 == 0:
                        conn.commit()
                        print(f"  Committed {count} segments...")

        print(f"Done. Total segments processed: {count}")
    finally:
        conn.close()


if __name__ == "__main__":
    place = sys.argv[1] if len(sys.argv) > 1 else "Plzeň, Czechia"
    seed_roads(place)
