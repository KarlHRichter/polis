#!/bin/bash
set -e

echo "Restoring database from dump..."

pg_restore -U "$POSTGRES_USER" -d "$POSTGRES_DB" /docker-entrypoint-initdb.d/prodclone.dump
