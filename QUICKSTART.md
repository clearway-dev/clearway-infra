# ClearWay Infrastructure - Quick Reference

## 🚀 Essential Commands

```bash
# Start everything
make up

# Stop everything
make down

# Reset database (WARNING: deletes data)
make reset

# View logs
make logs

# Database shell
make db-shell

# Check status
make ps

# Get help
make help
```

## 🔌 Connection Details

**Database:**
- Host: `localhost`
- Port: `5432`
- Database: `clearway`
- Username: `clearway`
- Password: `clearway_dev_password`

**Connection String:**
```
postgresql://clearway:clearway_dev_password@localhost:5432/clearway
```

**pgAdmin (when started with `make up-tools`):**
- URL: http://localhost:5050
- Email: `admin@clearway.local`
- Password: `admin`

## 📊 Quick SQL Queries

### View Recent Reports
```sql
SELECT * FROM recent_reports LIMIT 10;
```

### Find Nearby Reports
```sql
-- Find reports within 2km of coordinates
SELECT * FROM find_nearby_reports(37.7749, -122.4194, 2000);
```

### Check User Activity
```sql
SELECT username, total_reports, last_active 
FROM users 
ORDER BY total_reports DESC;
```

### Road Segment Stats
```sql
SELECT * FROM road_segment_stats 
ORDER BY total_reports DESC;
```

### Critical Conditions
```sql
SELECT 
    name as road_name,
    condition_type,
    severity,
    passability_score,
    reported_at
FROM recent_reports
WHERE severity IN ('high', 'critical')
ORDER BY reported_at DESC;
```

## 🗺️ Sample Locations (from test data)

- **Main Street**: Downtown Central
- **Highway 101**: Bay Area North
- **Mountain Pass Road**: Highland Mountain
- **Oak Avenue**: Midtown Central
- **Coastal Highway**: Coastside West

## 🔧 Troubleshooting One-Liners

```bash
# Check if Docker is running
docker ps

# Check if port 5432 is available
lsof -i :5432

# View PostgreSQL logs
docker-compose logs db --tail=50

# Restart just the database
docker-compose restart db

# Clean everything and start fresh
make clean && make up

# Check database size
make db-shell
# Then in psql:
\l+
```

## 📝 Environment Variables

Edit `.env` to customize:

```env
# Database
POSTGRES_DB=clearway
POSTGRES_USER=clearway
POSTGRES_PASSWORD=your_secure_password
DB_PORT=5432

# pgAdmin
PGADMIN_EMAIL=your_email@example.com
PGADMIN_PASSWORD=your_password
PGADMIN_PORT=5050
```

## 🔐 Security Reminders

- ⚠️ **Development only** - Not for production use
- 🔒 Change default passwords in production
- 📝 Never commit `.env` file
- 🚫 Don't expose ports publicly
- ✅ Use SSL/TLS in production

## 📚 Documentation Links

- [Full README](../README.md)
- [Architecture Diagrams](docs/C4_architecture.md)
- [Database Schema](docs/db_schema.md)
- [Migration Guide](db/migrations/README.md)

## 🧪 Testing the Setup

```bash
# 1. Start services
make up

# 2. Wait for database to be ready
sleep 5

# 3. Test connection
make test-connection

# 4. Verify data loaded
make db-shell
# Then in psql:
SELECT COUNT(*) FROM users;        -- Should return 5
SELECT COUNT(*) FROM road_reports; -- Should return 7
\q

# 5. Check logs for errors
make logs

# Success! 🎉
```

## 🐛 Common Issues

### "Port already in use"
```bash
# Change port in .env
DB_PORT=5433
make restart
```

### "Connection refused"
```bash
# Wait for startup (can take 10-20 seconds)
make logs
# Look for: "database system is ready to accept connections"
```

### "Permission denied"
```bash
# On Linux, add user to docker group
sudo usermod -aG docker $USER
# Then log out and back in
```

### "Volume issues"
```bash
# Nuclear option
make clean
make up
```

## 🎯 Next Steps

1. ✅ Setup complete - Database running
2. 🔜 Integrate with `clearway-data` (mobile app)
3. 🔜 Integrate with `clearway-analytics` (dashboard)
4. 🔜 Add real geographic data for your region
5. 🔜 Implement API service layer

## 💡 Pro Tips

- Use `make up-tools` to start pgAdmin for visual database management
- Run `make reset` after changing init scripts
- Check `make logs` if anything seems wrong
- Use `\dt` in psql to list tables
- Use `\d table_name` to see table structure

---

**Happy Coding! 🚗💨**
