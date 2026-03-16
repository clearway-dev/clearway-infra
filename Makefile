.PHONY: help up down restart logs ps reset clean build db-shell test-connection up-tools migrate seed-roads setup-routing

# Default target
help:
	@echo "ClearWay Infrastructure Management"
	@echo "===================================="
	@echo ""
	@echo "Available commands:"
	@echo "  make up              - Start all containers"
	@echo "  make up-tools        - Start all containers including pgAdmin"
	@echo "  make down            - Stop all containers"
	@echo "  make restart         - Restart all containers"
	@echo "  make logs            - View container logs"
	@echo "  make ps              - List running containers"
	@echo "  make reset           - Reset database (rebuild and recreate)"
	@echo "  make clean           - Remove all containers and volumes"
	@echo "  make build           - Rebuild containers"
	@echo "  make db-shell        - Connect to PostgreSQL shell"
	@echo "  make migrate         - Apply pending migrations from db/migrations/"
	@echo "  make seed-roads      - Download OSM roads and insert into road_segments"
	@echo "  make setup-routing   - Build pgRouting topology (run after seed-roads)"
	@echo "  make test-connection - Test database connection"
	@echo ""

# Start containers
up:
	@echo "🚀 Starting ClearWay infrastructure..."
	docker-compose up -d
	@echo "✅ Infrastructure started!"
	@echo "📊 Database available at: localhost:5432"

# Start containers including tools (pgAdmin)
up-tools:
	@echo "🚀 Starting ClearWay infrastructure with tools..."
	docker-compose --profile tools up -d
	@echo "✅ Infrastructure started with tools!"
	@echo "📊 Database available at: localhost:5432"
	@echo "🔧 pgAdmin available at: http://localhost:5050"

# Stop containers
down:
	@echo "🛑 Stopping ClearWay infrastructure..."
	docker-compose down --remove-orphans
	@echo "🔌 Forcefully stopping and removing containers..."
	docker ps -a -q --filter "network=clearway-network" | xargs -r docker rm -f 2>/dev/null || true
	docker network rm clearway-network 2>/dev/null || true
	@echo "✅ Infrastructure stopped!"

# Restart containers
restart: down up
	@echo "🔄 Infrastructure restarted!"

# View logs
logs:
	docker-compose logs -f

# List running containers
ps:
	docker-compose ps

# Reset database (rebuild and recreate)
reset:
	@echo "🔄 Resetting ClearWay database..."
	docker-compose down -v
	docker-compose build --no-cache db
	docker-compose up -d
	@echo "✅ Database reset complete!"

# Remove all containers and volumes
clean:
	@echo "🧹 Cleaning up ClearWay infrastructure..."
	docker-compose down -v --remove-orphans
	docker volume rm clearway_postgres_data clearway_pgadmin_data 2>/dev/null || true
	@echo "✅ Cleanup complete!"

# Rebuild containers
build:
	@echo "🔨 Building ClearWay containers..."
	docker-compose build
	@echo "✅ Build complete!"

# Connect to PostgreSQL shell
db-shell:
	@echo "🔌 Connecting to PostgreSQL..."
	docker-compose exec db psql -U clearway -d clearway

# Apply all pending migrations from db/migrations/ in order
migrate:
	@echo "🔄 Applying migrations..."
	@for f in $$(ls db/migrations/V*.sql 2>/dev/null | sort); do \
		echo "  → $$f"; \
		docker-compose exec -T db psql -U $${POSTGRES_USER:-clearway} -d $${POSTGRES_DB:-clearway} -f - < $$f; \
	done
	@echo "✅ Migrations applied!"

# Test database connection
test-connection:
	@echo "🔍 Testing database connection..."
	docker-compose exec db pg_isready -U clearway && \
	echo "✅ Database is ready!" || \
	echo "❌ Database is not ready!"

# Download OSM road data and seed into road_segments table
seed-roads:
	@echo "🗺️  Installing Python dependencies..."
	pip install -q -r scripts/requirements.txt
	@echo "🗺️  Seeding OSM road segments..."
	python scripts/seed_roads.py
	@echo "✅ Roads seeded!"

# Build pgRouting topology (run after seed-roads)
setup-routing:
	@echo "🔀 Building pgRouting topology..."
	docker-compose exec -T db psql -U $${POSTGRES_USER:-clearway} -d $${POSTGRES_DB:-clearway} -f - < scripts/setup_routing.sql
	@echo "✅ Routing topology built!"
