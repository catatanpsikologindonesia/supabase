#!/usr/bin/env bash
set -euo pipefail

WORKDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$WORKDIR"

mkdir -p snapshot/verification

RUN_ID="$(date +%Y%m%d_%H%M%S)"
LOG_FILE="snapshot/verification/sync_all_verbose_${RUN_ID}.log"
LATEST_LOG="snapshot/verification/sync_all_verbose_latest.log"

timestamp() {
  date "+%Y-%m-%d %H:%M:%S %z"
}

log_line() {
  local message="$1"
  printf "[%s] %s\n" "$(timestamp)" "$message" | tee -a "$LOG_FILE"
}

run_step() {
  local step_name="$1"
  shift

  local start_epoch
  start_epoch="$(date +%s)"
  log_line "START  ${step_name}"

  if "$@" >>"$LOG_FILE" 2>&1; then
    local end_epoch
    end_epoch="$(date +%s)"
    local duration=$((end_epoch - start_epoch))
    log_line "DONE   ${step_name} (${duration}s)"
  else
    local exit_code=$?
    local end_epoch
    end_epoch="$(date +%s)"
    local duration=$((end_epoch - start_epoch))
    log_line "FAILED ${step_name} (${duration}s) exit=${exit_code}"
    return "$exit_code"
  fi
}

log_line "SYNC ALL VERBOSE STARTED"
run_step "export_remote_database_snapshot" ./scripts/export_remote_database_snapshot.sh
run_step "export_remote_storage_objects" ./scripts/export_remote_storage_objects.sh
run_step "export_remote_project_config" ./scripts/export_remote_project_config.sh
run_step "restore_snapshot_to_local" ./scripts/restore_snapshot_to_local.sh
run_step "verify_exact_counts" ./scripts/verify_exact_counts.sh
log_line "SYNC ALL VERBOSE COMPLETED"

cp "$LOG_FILE" "$LATEST_LOG"
log_line "LOG FILE: $LOG_FILE"
log_line "LATEST LOG: $LATEST_LOG"
