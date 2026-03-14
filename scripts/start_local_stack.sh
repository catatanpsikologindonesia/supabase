#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

mkdir -p "$HOME/.docker/run"
ln -sf "$HOME/.colima/default/docker.sock" "$HOME/.docker/run/docker.sock"
export DOCKER_HOST="unix://$HOME/.docker/run/docker.sock"

supabase start

export PATH="/opt/homebrew/opt/libpq/bin:$PATH"
psql "postgresql://postgres:postgres@127.0.0.1:55322/postgres" -v ON_ERROR_STOP=1 -c \
  "CREATE SCHEMA IF NOT EXISTS graphql_public;"
psql "postgresql://postgres:postgres@127.0.0.1:55322/postgres" -v ON_ERROR_STOP=1 -c \
  "CREATE SCHEMA IF NOT EXISTS extensions;"
psql "postgresql://postgres:postgres@127.0.0.1:55322/postgres" -v ON_ERROR_STOP=1 -c \
  "GRANT USAGE ON SCHEMA public TO postgres, anon, authenticated, service_role;"
psql "postgresql://postgres:postgres@127.0.0.1:55322/postgres" -v ON_ERROR_STOP=1 -c \
  "GRANT USAGE ON SCHEMA graphql_public TO postgres, anon, authenticated, service_role;"
psql "postgresql://postgres:postgres@127.0.0.1:55322/postgres" -v ON_ERROR_STOP=1 -c \
  "GRANT USAGE ON SCHEMA extensions TO postgres, anon, authenticated, service_role;"
