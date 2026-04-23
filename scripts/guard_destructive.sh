#!/usr/bin/env bash
set -euo pipefail

# Destructive command guard for Catatan Psikolog
# Rationale: Prevent accidental 'db reset' from wiping Master Data.

echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo "!!! WARNING: YOU ARE ABOUT TO RUN A DESTRUCTIVE COMMAND      !!!"
echo "!!! THIS MAY WIPE LOCAL MASTER DATA AND USERS                !!!"
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo ""
echo "Command context: ${1:-Unknown destructive operation}"
echo ""

if [[ -n "${FORCE_DESTRUCTIVE_SYNC:-}" ]]; then
    echo "FORCE_DESTRUCTIVE_SYNC is set. Proceeding..."
    exit 0
fi

read -p "Type 'CONFIRM' to proceed, or any other key to abort: " confirm_input

if [[ "$confirm_input" == "CONFIRM" ]]; then
    echo "Confirmed. Proceeding..."
    exit 0
else
    echo "Aborted by user."
    exit 1
fi
