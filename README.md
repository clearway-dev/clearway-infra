# 🚗 ClearWay Infrastructure

**Shared infrastructure foundation for the ClearWay project** — a system for analyzing and visualizing road passability data.

This repository provides:
- 🗄️ PostgreSQL database with PostGIS for spatial data
- 🐳 Docker Compose environment for local development
- 📊 Database schema and sample data
- 📚 Architecture documentation and diagrams
- 🛠️ Developer workflow automation

---

## 📋 Table of Contents

- [Quick Start](#-quick-start)
- [Prerequisites](#-prerequisites)
- [Installation](#-installation)
- [Usage](#-usage)
- [Database Access](#-database-access)
- [Project Structure](#-project-structure)
- [Documentation](#-documentation)
- [Integration](#-integration)
- [Troubleshooting](#-troubleshooting)
- [Contributing](#-contributing)

---

## 🚀 Quick Start

```bash
# Clone the repository
git clone https://github.com/clearway-dev/clearway-infra.git
cd clearway-infra

# Copy environment template
cp .env.example .env

# Start the infrastructure
make up

# Verify database is running
make test-connection
```

The database will be available at `localhost:5432` with sample data loaded automatically.

---

## 📦 Prerequisites

- **Docker** (20.10+) - [Install Docker](https://docs.docker.com/get-docker/)
- **Docker Compose** (2.0+) - Usually included with Docker Desktop
- **Make** - Command automation (pre-installed on macOS/Linux)
- **Git** - Version control

### Verify Installation
```bash
docker --version
docker-compose --version
make --version
```

---

## 📥 Installation

### 1. Clone the Repository
```bash
git clone https://github.com/clearway-dev/clearway-infra.git
cd clearway-infra
```

### 2. Configure Environment
```bash
# Copy environment template
cp .env.example .env

# Edit .env if you need to change default ports or credentials
nano .env  # or use your preferred editor
```

### 3. Start Services
```bash
# Start database only
make up

# OR start with pgAdmin management tool
make up-tools
```

### 4. Verify Installation
```bash
# Check running containers
make ps

# Test database connection
make test-connection

# View logs
make logs
```

---

## 🎯 Usage

### Common Commands

```bash
# Start infrastructure
make up

# Stop infrastructure
make down

# Restart services
make restart

# View real-time logs
make logs

# Reset database (WARNING: deletes all data)
make reset

# Clean up everything (containers + volumes)
make clean

# Rebuild containers
make build

# Open PostgreSQL shell
make db-shell
```

### Starting with pgAdmin

```bash
# Start all services including pgAdmin
make up-tools
```

Access pgAdmin at: http://localhost:5050
- Email: `admin@clearway.local`
- Password: `admin`

### Connecting to PostgreSQL

**From Host Machine:**
```bash
psql -h localhost -p 5432 -U clearway -d clearway
# Password: clearway_dev_password
```

**From Docker Shell:**
```bash
make db-shell
```

**Connection String:**
```
postgresql://clearway:clearway_dev_password@localhost:5432/clearway
```

---

## 🗄️ Database Access

### Using psql (Command Line)

```bash
# Interactive shell via Make
make db-shell

# Or directly with psql
psql -h localhost -U clearway -d clearway
```

### Using pgAdmin (Web Interface)

1. Start with tools: `make up-tools`
2. Open http://localhost:5050
3. Login with credentials from `.env`
4. Add server:
   - **Name**: ClearWay Local
   - **Host**: `db` (Docker network) or `host.docker.internal` (from host)
   - **Port**: `5432`
   - **Username**: `clearway`
   - **Password**: `clearway_dev_password`

### Using Database Clients

**DBeaver, TablePlus, DataGrip, etc.**:
- Host: `localhost`
- Port: `5432`
- Database: `clearway`
- Username: `clearway`
- Password: `clearway_dev_password`

---

## 📁 Project Structure

```
clearway-infra/
│
├── docker-compose.yml          # Service orchestration
├── Makefile                    # Developer commands
├── .env.example                # Environment template
├── .gitignore                  # Git ignore rules
├── README.md                   # This file
│
├── db/                         # Database configuration
│   ├── Dockerfile              # PostgreSQL + PostGIS image
│   └── init/                   # Initialization scripts (run on first start)
│       ├── 001_schema.sql      # Database schema
│       └── 002_sample_data.sql # Sample data
│
└── docs/                       # Documentation
    ├── C4_architecture.md      # System architecture (C4 diagrams)
    └── db_schema.md            # Database schema documentation
```

---

## 📚 Documentation

### Architecture
- **[C4 Architecture Diagrams](docs/C4_architecture.md)** - System context, containers, components
- **[Database Schema](docs/db_schema.md)** - Tables, relationships, queries

### Database Schema Overview

**Tables:**
- `users` - Mobile app users
- `road_segments` - Physical road segments with geometry
- `road_reports` - User-submitted condition reports

**Key Features:**
- PostGIS spatial queries
- Automatic report counting
- Nearby reports search function
- Pre-built analytics views

### Sample Queries

```sql
-- Get recent critical reports
SELECT * FROM recent_reports 
WHERE severity IN ('high', 'critical') 
LIMIT 10;

-- Find reports near a location
SELECT * FROM find_nearby_reports(37.7749, -122.4194, 5000);

-- Road segment statistics
SELECT * FROM road_segment_stats 
ORDER BY avg_passability ASC;
```

---

## 🔗 Integration

### Using with Other ClearWay Repositories

**clearway-data (Mobile App)**:
```typescript
// Configure database connection
const DATABASE_URL = 'postgresql://clearway:clearway_dev_password@localhost:5432/clearway';
```

**clearway-analytics (Dashboard)**:
```javascript
// In your .env file
DATABASE_HOST=localhost
DATABASE_PORT=5432
DATABASE_NAME=clearway
DATABASE_USER=clearway
DATABASE_PASSWORD=clearway_dev_password
```

### Docker Network

Other services can connect using Docker network:
```yaml
# In your docker-compose.yml
services:
  your-service:
    networks:
      - clearway-network

networks:
  clearway-network:
    external: true
    name: clearway-network
```

---

## 🔧 Troubleshooting

### Port Already in Use

**Error**: `Bind for 0.0.0.0:5432 failed: port is already allocated`

**Solution**:
```bash
# Check what's using port 5432
lsof -i :5432

# Change port in .env
DB_PORT=5433

# Restart
make restart
```

### Database Won't Start

```bash
# View detailed logs
docker-compose logs db

# Remove volumes and rebuild
make clean
make up
```

### Can't Connect to Database

```bash
# Check container is running
make ps

# Test connection
make test-connection

# Verify credentials in .env match your client
cat .env
```

### Permission Denied

```bash
# On Linux, ensure Docker permissions
sudo usermod -aG docker $USER
# Log out and back in

# Or run with sudo
sudo make up
```

### Reset Everything

```bash
# Nuclear option - removes everything
make clean
rm .env
cp .env.example .env
make up
```

---

## 🤝 Contributing

### Adding New Migrations

1. Create new SQL file: `db/init/003_your_migration.sql`
2. Scripts run in alphabetical order
3. Test with: `make reset`

### Modifying Schema

1. Edit `db/init/001_schema.sql`
2. Reset database: `make reset`
3. Update documentation: `docs/db_schema.md`

### Adding Sample Data

1. Edit `db/init/002_sample_data.sql`
2. Reset to load new data: `make reset`

---

## 📊 Database Statistics

**Current Schema Includes:**
- 3 main tables (users, road_segments, road_reports)
- 2 views (recent_reports, road_segment_stats)
- 8 indexes (including spatial indexes)
- 2 functions (report counting, nearby search)
- PostGIS spatial support

**Sample Data Includes:**
- 5 test users
- 5 road segments with real geometries
- 7 road reports (various conditions)
- Photo URLs and device metadata examples

---

## 🔐 Security Notes

### Development vs Production

**This configuration is for DEVELOPMENT ONLY.**

**For Production:**
- ✅ Change all default passwords
- ✅ Use environment-specific `.env` files
- ✅ Enable SSL/TLS for database connections
- ✅ Implement proper backup strategies
- ✅ Use secrets management (AWS Secrets Manager, HashiCorp Vault)
- ✅ Restrict database access by IP
- ✅ Enable database audit logging

---

## 📝 License

[Add your license information here]

---

## 🙏 Acknowledgments

Built with:
- [PostgreSQL](https://www.postgresql.org/) - Database
- [PostGIS](https://postgis.net/) - Spatial extensions
- [Docker](https://www.docker.com/) - Containerization
- [pgAdmin](https://www.pgadmin.org/) - Database management

---

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/clearway-dev/clearway-infra/issues)
- **Documentation**: [docs/](docs/)
- **Architecture**: [docs/C4_architecture.md](docs/C4_architecture.md)
- **Database**: [docs/db_schema.md](docs/db_schema.md)

---

## 🧪 Development Status

**Current Version**: 0.1.0 (Initial Setup)

**Features**:
- ✅ PostgreSQL with PostGIS
- ✅ Docker Compose environment
- ✅ Complete database schema
- ✅ Sample data
- ✅ Documentation
- ✅ Makefile automation

**Coming Soon**:
- 🔄 Database migrations system
- 🔄 Backup automation scripts
- 🔄 CI/CD integration
- 🔄 Production deployment templates
- 🔄 Performance monitoring

---

**Made with ❤️ for the ClearWay project**
