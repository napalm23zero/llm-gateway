#!/usr/bin/env bash
set -euo pipefail

# keep the reference on root
cd "$(dirname "$0")"

# checking if docke ris running first, just in case
if ! docker info >/dev/null 2>&1; then
  echo "Docker is not running. Start Docker Desktop and try again." >&2
  exit 1
fi

exec docker compose \
  -f .docker/docker-compose.yml \
  -f .docker/docker-compose.dev.yml \
  up --build
