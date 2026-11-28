#!/usr/bin/env bash
# Wipe the demo back to a fresh, provisioned state on the latest image.
# Nightly from cron, e.g.:  0 4 * * * /path/to/examples/everything/demo/reset.sh
set -euo pipefail
cd "$(dirname "$0")/.."
dc() { docker compose --env-file demo/.env -f docker-compose.yml -f demo/compose.demo.yaml "$@"; }
dc pull --quiet --ignore-buildable
dc down -v --remove-orphans
dc up -d --build
