# Database Migrations

This directory is reserved for versioned database migrations.

## Migration Strategy

### Current Setup
Currently, the database schema is initialized using scripts in `/db/init/`:
- `001_schema.sql` - Full database schema
- `002_sample_data.sql` - Sample/test data

These scripts run automatically when the PostgreSQL container is first created.

## Future Migration Tools

When the project moves beyond initial development, consider using a migration tool:

### Option 1: Flyway (Recommended for Java-based projects)
```
db/migrations/
  ├── V001__initial_schema.sql
  ├── V002__add_verification_system.sql
  ├── V003__add_weather_data.sql
  └── V004__optimize_indexes.sql
```

### Option 2: Alembic (Recommended for Python-based projects)
```
db/migrations/
  ├── env.py
  ├── script.py.mako
  └── versions/
      ├── 001_initial_schema.py
      ├── 002_add_verification.py
      └── 003_add_weather.py
```

### Option 3: Atlas (Modern, declarative)
```
db/migrations/
  ├── atlas.hcl
  └── versions/
      ├── 20250101_initial.sql
      └── 20250201_updates.sql
```

## Naming Convention

For manual SQL migrations:
```
V{version}__{description}.sql

Examples:
- V001__initial_schema.sql
- V002__add_user_preferences.sql
- V003__optimize_spatial_indexes.sql
```

## Best Practices

1. **Never modify applied migrations** - Always create new ones
2. **Make migrations reversible** when possible
3. **Test migrations** on development data before production
4. **Include rollback scripts** for critical changes
5. **Version control all migrations**
6. **Document breaking changes** clearly

## Applying Migrations

### Development Reset (Current Method)
```bash
# This drops and recreates everything
make reset
```

### Future Production Approach
```bash
# Using migration tool (example with Flyway)
flyway migrate -url=jdbc:postgresql://localhost:5432/clearway
```

## Migration Checklist

Before applying to production:
- [ ] Tested on development database
- [ ] Tested on staging database
- [ ] Backup created
- [ ] Rollback plan documented
- [ ] Team notified of schema changes
- [ ] Dependent services updated
- [ ] Performance impact assessed

## See Also

- [Flyway Documentation](https://flywaydb.org/documentation/)
- [Alembic Documentation](https://alembic.sqlalchemy.org/)
- [Atlas Documentation](https://atlasgo.io/)
