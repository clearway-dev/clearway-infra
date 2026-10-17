FROM postgis/postgis:16-3.4

# bullseye už není na apt.postgresql.org, pgdg ho drží v archivu
RUN sed -i 's#apt.postgresql.org/pub/repos/apt#apt-archive.postgresql.org/pub/repos/apt#' /etc/apt/sources.list.d/pgdg.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends postgresql-16-pgrouting \
    && rm -rf /var/lib/apt/lists/*

# Set default environment variables (without sensitive data)
ENV POSTGRES_DB=clearway
ENV POSTGRES_USER=clearway
# Note: POSTGRES_PASSWORD is set via docker-compose.yml environment variables

# Copy initialization scripts
# These will be executed in alphabetical order on first container start
COPY init/*.sql /docker-entrypoint-initdb.d/

# Expose PostgreSQL port
EXPOSE 5432

# Health check
HEALTHCHECK --interval=10s --timeout=5s --retries=5 \
    CMD pg_isready -U $POSTGRES_USER -d $POSTGRES_DB
