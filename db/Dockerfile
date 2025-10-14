FROM postgis/postgis:16-3.4-alpine

# Set default environment variables
ENV POSTGRES_DB=clearway
ENV POSTGRES_USER=clearway
ENV POSTGRES_PASSWORD=clearway_dev_password

# Copy initialization scripts
# These will be executed in alphabetical order on first container start
COPY init/*.sql /docker-entrypoint-initdb.d/

# Expose PostgreSQL port
EXPOSE 5432

# Health check
HEALTHCHECK --interval=10s --timeout=5s --retries=5 \
    CMD pg_isready -U $POSTGRES_USER -d $POSTGRES_DB
