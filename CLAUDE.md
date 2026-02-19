# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

ClearWay Infrastructure is the shared database foundation for the ClearWay project — a system for analyzing and visualizing road passability/width data collected by vehicle-mounted sensors. This repo contains only the database layer (PostgreSQL + PostGIS) and its Docker environment; there are no application services here.

## Common Commands

All developer workflow is driven through `make`:

```bash
make up              # Start database container
make up-tools        # Start database + pgAdmin (port 5050)
make down            # Stop all containers
make restart         # Stop then start
make reset           # Wipe and rebuild the database (runs all init scripts fresh)
make clean           # Remove containers and Docker volumes entirely
make build           # Rebuild Docker images
make db-shell        # Open psql inside the container
make test-connection # Check if PostgreSQL is ready
make logs            # Tail container logs
```

**First-time setup:**
```bash
cp .env.example .env
make up
```

**Default dev connection string:**
```
postgresql://clearway:clearway_dev_password@localhost:5432/clearway
```

## Architecture

### Database Schema (PostgreSQL 16 + PostGIS 3.4)

The schema in `db/init/001_schema.sql` models a sensor-based road width measurement pipeline:

```
sensors → sessions ← vehicles
               ↓
        raw_measurements
               ↓
   ┌─────────────────────────┐
   │                         │
cleaned_measurements   invalid_measurements
        ↓
     clusters → road_segments (OSM geometry)
                     ↓
            segment_statistics
```

- **sensors** — physical sensors mounted on vehicles
- **vehicles** — vehicles with known width (used to calculate road width)
- **sessions** — links a sensor to a vehicle for a measurement run
- **raw_measurements** — GPS + ultrasonic distance readings (distance_left, distance_right); road width = `distance_left + distance_right + vehicle_width`
- **cleaned_measurements** — validated rows with PostGIS POINT geometry and quality_score (0–1)
- **invalid_measurements** — rejected rows with rejection reason
- **clusters** — spatially aggregated cleaned measurements (PostGIS POINT)
- **road_segments** — OSM road geometry (PostGIS LINESTRING, EPSG:4326)
- **segment_statistics** — daily aggregated stats per road segment

Key spatial indexes use GIST. All primary keys are UUIDs except `raw_measurements` and `cleaned_measurements` which use BIGSERIAL.

### Views

- `active_sessions` — sessions joined with sensor/vehicle info
- `recent_measurements` — raw measurements from the last 24 hours with joined metadata
- `road_segment_summary` — per-segment cluster counts and width aggregates

### Functions

- `calculate_road_width(distance_left, distance_right, vehicle_width)` — returns total road width
- `find_nearby_measurements(lat, lon, radius_meters)` — spatial search using ST_DWithin
- `get_segment_statistics(segment_uuid, start_date, end_date)` — date-range stats for a segment

### Init Script Execution Order

Scripts in `db/init/` run alphabetically on first container start (or after `make reset`):
- `001_schema.sql` — drops and recreates all tables, views, functions
- `002_sample_data.sql` — seed data for development
- `003_fill_cleaned_data.sql` — populates cleaned_measurements for frontend simulation

### Data Pipeline Scripts

- `scripts/convert_csv.py` — converts `data/dataset.csv` to bulk INSERT SQL at `sql/output.sql`. CSV columns GPS1→latitude, GPS2→longitude, A→distance_left, C→distance_right. Sets `is_valid=false` by default.

### Environments

| File | Purpose |
|---|---|
| `docker-compose.yml` | Local development (platform: linux/arm64) |
| `docker-compose.prod.yml` | Production on Hetzner with Traefik reverse proxy and external networks (`db_internal`, `web_proxy`) |

### CI/CD

`.github/workflows/deploy.yml` deploys to Hetzner on push to `main`: copies repo via SCP, then SSHes in to run `docker compose -f docker-compose.prod.yml up -d --build --remove-orphans`. Secrets: `HETZNER_HOST`, `HETZNER_USER`, `HETZNER_SSH_KEY`, plus DB/pgAdmin credentials.

### Schema Changes

**On a running database (no data loss):** write a migration file in `db/migrations/` following the `V{NNN}__{description}.sql` naming convention, then run `make migrate`. The migration script uses `CREATE TABLE IF NOT EXISTS` / `ALTER TABLE` so it is safe to re-run.

**Also update `db/init/001_schema.sql`** to keep fresh installs (`make reset`) in sync with the migrated state. Both places must be kept consistent.

Update `docs/db_schema.md` alongside any schema change.

### External Integration

Other ClearWay services connect via the `clearway-network` Docker bridge network (host: `db`, port: `5432`) or externally on `localhost:5432`.
