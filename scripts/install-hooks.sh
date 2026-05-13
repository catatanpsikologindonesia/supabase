#!/usr/bin/env bash
set -o errexit -o pipefail

# install-hooks.sh
# Installs the knowledge-sync guard as a pre-push git hook.
# Run from repo root:  bash ./scripts/install-hooks.sh

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOK_DIR="$REPO_ROOT/.git/hooks"
HOOK_FILE="$HOOK_DIR/pre-push"

if [[ ! -d "$HOOK_DIR" ]]; then
  echo "  [install-hooks] .git/hooks not found — is this a git repo?"
  exit 1
fi

if [[ -f "$HOOK_FILE" ]]; then
  echo "  [install-hooks] pre-push hook already exists at $HOOK_FILE"
  echo "  [install-hooks] delete it first if you want to reinstall"
  exit 0
fi

cat > "$HOOK_FILE" << 'HOOK'
#!/usr/bin/env bash
set -o errexit -o pipefail

# pre-push hook — guards knowledge sync before pushing
# Run via:  git push
# Bypass with:  SKIP_KNOWLEDGE_GUARD=1 git push

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

if [[ -n "$SKIP_KNOWLEDGE_GUARD" ]]; then
  echo "  [pre-push] SKIP_KNOWLEDGE_GUARD=1 — bypassing knowledge sync guard"
  exit 0
fi

if [[ -f "$REPO_ROOT/scripts/guard-knowledge-sync.sh" ]]; then
  bash "$REPO_ROOT/scripts/guard-knowledge-sync.sh"
else
  echo "  [pre-push] guard-knowledge-sync.sh not found — skipping"
fi
HOOK

chmod +x "$HOOK_FILE"
echo "  [install-hooks] pre-push hook installed at $HOOK_FILE"
echo "  [install-hooks] to bypass: SKIP_KNOWLEDGE_GUARD=1 git push"
