#!/usr/bin/env sh
set -eu

mkdir -p backups
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
docker compose exec -T postgres pg_dump \
  -U "${POSTGRES_USER}" \
  -d "${POSTGRES_DB}" \
  --format=custom > "backups/tenantforge_${TIMESTAMP}.dump"

echo "Backup created: backups/tenantforge_${TIMESTAMP}.dump"
