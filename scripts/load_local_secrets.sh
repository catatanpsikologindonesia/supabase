#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="${ENV_FILE:-${ROOT_DIR}/.env.local}"
ENV_LABEL="$(basename "$ENV_FILE")"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing ${ENV_FILE}" >&2
  exit 1
fi

# shellcheck disable=SC1090
source "$ENV_FILE"

if [[ -z "${SUPABASE_PAT_FILE:-}" || ! -f "${SUPABASE_PAT_FILE}" ]]; then
  echo "SUPABASE_PAT_FILE is missing or invalid in ${ENV_LABEL}" >&2
  exit 1
fi

export SUPABASE_ACCESS_TOKEN
SUPABASE_ACCESS_TOKEN="$(tr -d '\r\n' < "${SUPABASE_PAT_FILE}")"

if [[ -z "${SUPABASE_DB_PASSWORD:-}" ]]; then
  echo "SUPABASE_DB_PASSWORD missing in ${ENV_LABEL}" >&2
  exit 1
fi

if [[ -z "${SUPABASE_PROJECT_REF:-}" ]]; then
  echo "SUPABASE_PROJECT_REF missing in ${ENV_LABEL}" >&2
  exit 1
fi

export SUPABASE_DB_PASSWORD SUPABASE_PROJECT_REF

echo "Loaded local secrets for project ${SUPABASE_PROJECT_REF}."
