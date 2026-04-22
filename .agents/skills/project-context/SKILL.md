# Project Context Skill

## Mandatory Read Order
Before starting any significant task in this repository, agents must read the following files in this exact order:
1. `knowledge/PROJECT_SUMMARY.md`
2. `knowledge/CURRENT_STATE.md`
3. `knowledge/AGENTS.md`
4. `knowledge/architecture/SUPABASE_PRODUCT_CONTRACT.md`

## Startup Protocol
- **Branch Check:** Verify current working branch matches task scope.
- **Scope Definition:** Explicitly define the boundary of changes (e.g., "Updating edge function X" vs "Adding new table Y").
- **Local Validation:** Use `make start-local` and verify locally before deployment.

## Critical Rules
1. **NO Auto-Commit:** Never commit changes automatically after completing a task.
2. **Knowledge Sync:** Update `knowledge/CURRENT_STATE.md` if your task changes the system's operational state or capabilities.
3. **Language Policy:** All documentation must be strictly in English (en-US). Verify using `scripts/check_knowledge_language.sh`.

## Reference Paths
- `supabase/migrations/`: Database schema and migrations.
- `supabase/functions/`: Deno edge functions.
- `knowledge/`: Source of truth for documentation.
