#!/bin/sh
set -e

# Do NOT create or modify .env here to avoid changing it on builds/runs.
# Expect a persistent .env to be mounted into the container (or provided externally).
# Export KEY into environment for the process if .env exists, otherwise warn.
if [ -f ".env" ]; then
  export KEY=$(grep '^KEY=' .env | cut -d'=' -f2-)
else
  echo ".env not found; continuing without KEY (encryption disabled)"
fi

# Run DB migrations (if any) before starting server
if [ -f "migrate_db.py" ]; then
  echo "Running DB migration script"
  # run with the same python environment
  python migrate_db.py || echo "Migration script failed (continuing)"
fi

# Exec the given command (default: python server.py)
exec "$@"
