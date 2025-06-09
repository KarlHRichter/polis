#!/bin/bash

# Script to create a portable PostgreSQL dump file
# This dump can be restored on any PostgreSQL instance without user/password dependencies

set -e  # Exit on any error

# Load environment variables from .env file if it exists
if [ -f .env ]; then
    echo "Loading environment variables from .env file..."
    source .env
fi

# Set default values if environment variables are not set
POSTGRES_DB=${POSTGRES_DB:-polis-dev}
POSTGRES_USER=${POSTGRES_USER:-postgres}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-oiPorg3Nrz0yqDLE}
POSTGRES_HOST=${POSTGRES_HOST:-localhost}
POSTGRES_PORT=${POSTGRES_PORT:-5432}

# Output file with timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
DUMP_FILE="polis_anonymized_dump_${TIMESTAMP}.sql"

echo "Creating portable PostgreSQL dump..."
echo "Database: $POSTGRES_DB"
echo "Host: $POSTGRES_HOST:$POSTGRES_PORT"
echo "User: $POSTGRES_USER"
echo "Output file: $DUMP_FILE"

# Check if we're running with Docker
if command -v docker-compose >/dev/null 2>&1 && [ -f docker-compose.yml ]; then
    echo "Docker Compose detected. Creating dump from Docker container..."
    
    # Try to create dump using docker-compose exec
    if docker-compose ps postgres | grep -q "Up"; then
        echo "PostgreSQL container is running. Creating portable dump..."
        docker-compose exec -T postgres pg_dump \
            --host=localhost \
            --port=5432 \
            --username="$POSTGRES_USER" \
            --dbname="$POSTGRES_DB" \
            --no-owner \
            --no-privileges \
            --clean \
            --if-exists \
            --create \
            --encoding=UTF8 \
            --verbose \
            > "$DUMP_FILE"
    else
        echo "PostgreSQL container is not running. Please start it with:"
        echo "docker-compose --profile postgres up -d"
        exit 1
    fi
else
    # Direct connection to PostgreSQL (not using Docker)
    echo "Connecting directly to PostgreSQL..."
    
    # Export password to avoid prompt
    export PGPASSWORD="$POSTGRES_PASSWORD"
    
    # Create portable dump
    pg_dump \
        --host="$POSTGRES_HOST" \
        --port="$POSTGRES_PORT" \
        --username="$POSTGRES_USER" \
        --dbname="$POSTGRES_DB" \
        --no-owner \
        --no-privileges \
        --clean \
        --if-exists \
        --create \
        --encoding=UTF8 \
        --verbose \
        > "$DUMP_FILE"
    
    # Unset password
    unset PGPASSWORD
fi

if [ -f "$DUMP_FILE" ] && [ -s "$DUMP_FILE" ]; then
    echo "✅ Portable dump successfully created: $DUMP_FILE"
    echo "File size: $(du -h "$DUMP_FILE" | cut -f1)"
    echo ""
    echo "This dump file can be restored on any PostgreSQL instance using:"
    echo "  psql -h <host> -p <port> -U <any_user> -d postgres < $DUMP_FILE"
    echo ""
    echo "Or using Docker:"
    echo "  docker exec -i <postgres_container> psql -U <any_user> -d postgres < $DUMP_FILE"
    echo ""
    echo "The dump includes:"
    echo "  ✓ Complete database structure (tables, indexes, constraints)"
    echo "  ✓ All anonymized data"
    echo "  ✓ No user ownership dependencies (--no-owner)"
    echo "  ✓ No privilege grants (--no-privileges)"
    echo "  ✓ Database creation statements (--create)"
    echo "  ✓ Clean statements for safe re-imports (--clean --if-exists)"
else
    echo "❌ Failed to create dump or file is empty"
    exit 1
fi 