# Agents Context

Quick reference for agents working in `Supabase/CatatanPsikolog`.

## What This Repo Owns

- PostgreSQL schema, policies, triggers, and RPCs
- edge functions and shared helpers
- local restore, verify, mirror, and push workflows
- snapshot artifacts used for recovery and parity work

## Agent Directives

- read `KNOWLEDGE_BASELINE.md` before making architecture assumptions
- keep knowledge files aligned with current code
- use `make knowledge-language-check` after knowledge updates
- run `make guard-knowledge-sync` before push decisions or install the push hook with `make install-hooks`
- use `bash scripts/apply_migration.sh "name" "SQL"` for schema changes
- all `.md` files in this repository must be written in English without exception

## Current Repo Facts

- current migration set is one squashed baseline
- current function count is 23 edge functions
- current local ports are API `55321`, DB `55322`, Studio `55323`, Inbucket `55324`
