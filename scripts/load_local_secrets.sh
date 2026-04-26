#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
ENV_FILE="${ENV_FILE:-${ROOT_DIR}/.env.local}"
ENV_LABEL="$(basename "$ENV_FILE")"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing ${ENV_FILE}" >&2
  exit 1
fi

# shellcheck disable=SC1090
source "$ENV_FILE"

resolve_pat_file() {
  local candidate
  if [[ -n "${SUPABASE_PAT_FILE:-}" && -f "${SUPABASE_PAT_FILE}" ]]; then
    printf '%s\n' "${SUPABASE_PAT_FILE}"
    return 0
  fi

  for candidate in \
    "${ROOT_DIR}/../../../PAT/supabase_pat.txt" \
    "${ROOT_DIR}/../../PAT/supabase_pat.txt" \
    "${HOME}/PAT/supabase_pat.txt" \
    "${HOME}/.supabase/pat.txt"
  do
    if [[ -f "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  return 1
}

SUPABASE_PAT_FILE="$(resolve_pat_file || true)"
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

export SUPABASE_DB_PASSWORD SUPABASE_PROJECT_REF SUPABASE_PAT_FILE

echo "Loaded local secrets for project ${SUPABASE_PROJECT_REF}."
