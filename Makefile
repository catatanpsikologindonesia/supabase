SHELL := /bin/bash

.DEFAULT_GOAL := help

.PHONY: help export-db export-storage export-config export-all restore verify verify-fast sync-all sync-all-verbose

help:
	@echo "Targets:"
	@echo "  make export-db       # Export remote database snapshot"
	@echo "  make export-storage  # Export remote storage objects (binary files)"
	@echo "  make export-config   # Export remote project config"
	@echo "  make export-all      # Run all export steps"
	@echo "  make restore         # Restore snapshot into local Supabase"
	@echo "  make verify          # Exact count verification (remote vs local)"
	@echo "  make verify-fast     # Row estimate + checksum verification"
	@echo "  make sync-all        # Export + restore + verify end-to-end"
	@echo "  make sync-all-verbose # Same as sync-all with timestamped audit log"

export-db:
	./scripts/export_remote_database_snapshot.sh

export-storage:
	./scripts/export_remote_storage_objects.sh

export-config:
	./scripts/export_remote_project_config.sh

export-all: export-db export-storage export-config

restore:
	./scripts/restore_snapshot_to_local.sh

verify:
	./scripts/verify_exact_counts.sh

verify-fast:
	./scripts/verify_snapshot_vs_local.sh

sync-all: export-all restore verify
	@echo "Sync complete. See snapshot/verification for reports."

sync-all-verbose:
	./scripts/sync_all_verbose.sh
