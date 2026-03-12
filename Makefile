SHELL := /bin/bash

.DEFAULT_GOAL := help

.PHONY: help export-db export-storage export-config export-all restore verify verify-fast sync-all sync-all-verbose pull-snapshot start-local restore-local sync-auth sync-cron sync-storage verify-local-remote mirror-remote-to-local push-remote push-staging push-prod

help:
	@echo "Available targets:"
	@echo "  make export-db"
	@echo "  make export-storage"
	@echo "  make export-config"
	@echo "  make export-all"
	@echo "  make restore"
	@echo "  make verify"
	@echo "  make verify-fast"
	@echo "  make sync-all"
	@echo "  make sync-all-verbose"
	@echo "  make pull-snapshot"
	@echo "  make start-local"
	@echo "  make restore-local"
	@echo "  make sync-auth"
	@echo "  make sync-cron"
	@echo "  make sync-storage"
	@echo "  make verify-local-remote"
	@echo "  make mirror-remote-to-local"
	@echo "  make push-staging"
	@echo "  make push-prod"
	@echo "  make push-remote"

export-db: pull-snapshot

export-storage: sync-storage

export-config:
	@echo "Config export is covered by pull-snapshot for CatatanPsikolog."

export-all: pull-snapshot sync-storage

restore: restore-local

verify: verify-local-remote

verify-fast: verify-local-remote

sync-all: mirror-remote-to-local
	@echo "Sync complete. See snapshot/verification for reports."

sync-all-verbose:
	./scripts/full_mirror_remote_to_local.sh

pull-snapshot:
	./scripts/pull_remote_snapshot.sh

start-local:
	./scripts/start_local_stack.sh

restore-local:
	./scripts/restore_local_db.sh

sync-auth:
	./scripts/sync_auth_remote_to_local.sh

sync-cron:
	./scripts/sync_cron_remote_to_local.sh

sync-storage:
	./scripts/sync_storage_remote_to_local.sh

verify-local-remote:
	./scripts/verify_local_remote_diff.sh

mirror-remote-to-local:
	./scripts/full_mirror_remote_to_local.sh

push-staging:
	ENV_FILE="$(CURDIR)/.env.staging" EXPECTED_PROJECT_REF="ixwaaziifteubxkxtdwj" ./scripts/push_remote_changes.sh

push-prod:
	ENV_FILE="$(CURDIR)/.env.prod" ./scripts/push_remote_changes.sh

push-remote:
	$(MAKE) push-staging
