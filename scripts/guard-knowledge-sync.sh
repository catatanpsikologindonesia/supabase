#!/usr/bin/env bash
set -o errexit -o pipefail

# guard-knowledge-sync.sh
# Fails if code files changed but no knowledge/ doc was updated.
#
# Usage:
#   bash ./scripts/guard-knowledge-sync.sh          # check staged + unstaged
#   bash ./scripts/guard-knowledge-sync.sh --since HEAD~1   # check since a ref
#   bash ./scripts/guard-knowledge-sync.sh --staged         # staged only (pre-commit)
#
# Exit codes:
#   0  - docs are up to date (or only docs changed)
#   1  - code changed without a matching doc update
#   2  - knowledge language check failed
# 255  - usage error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# ---- helpers ----
is_knowledge_file() {
  local f="$1"
  # knowledge/ dir
  [[ "$f" == knowledge/* ]] && return 0
  # repo-root .md files (README, etc.)
  [[ "$f" == *.md && "$f" != knowledge/* && "$f" != node_modules/* && "$f" != .github/* ]] && return 0
  # CLAUDE.md, AGENTS.md at repo root
  [[ "$f" == CLAUDE.md || "$f" == AGENTS.md ]] && return 0
  return 1
}

is_doc_file() {
  local f="$1"
  is_knowledge_file "$f" && return 0
  [[ "$f" == *.md ]] && return 0
  return 1
}

is_code_file() {
  local f="$1"
  # skip common non-code paths
  [[ "$f" == node_modules/* ]] && return 1
  [[ "$f" == .git/* ]] && return 1
  [[ "$f" == out/* ]] && return 1      # build output
  [[ "$f" == dist/* ]] && return 1
  [[ "$f" == .next/* ]] && return 1
  is_doc_file "$f" && return 1          # docs are not code
  # everything else is code
  [[ -n "$f" ]] && return 0
  return 1
}

# ---- main ----
REV_RANGE=""
SCOPE_LABEL="working tree"

if [[ "$1" == "--since" ]]; then
  REV_RANGE="$2..HEAD"
  SCOPE_LABEL="changes since $2"
  shift 2
elif [[ "$1" == "--staged" ]]; then
  SCOPE_LABEL="staged changes"
fi

ALL_FILES=""
if [[ -n "$REV_RANGE" ]]; then
  ALL_FILES=$(git -C "$REPO_ROOT" diff --name-only "$REV_RANGE" 2>/dev/null || true)
elif [[ "$1" == "--staged" ]]; then
  ALL_FILES=$(git -C "$REPO_ROOT" diff --cached --name-only 2>/dev/null || true)
else
  # staged + unstaged
  ALL_FILES=$(git -C "$REPO_ROOT" diff --name-only 2>/dev/null || true)
  ALL_FILES="$ALL_FILES"$'\n'"$(git -C "$REPO_ROOT" diff --cached --name-only 2>/dev/null || true)"
fi

# de-dup and filter
ALL_FILES=$(echo "$ALL_FILES" | sort -u | grep -v '^$' || true)

if [[ -z "$ALL_FILES" ]]; then
  echo "  [guard] no changed files — skipping"
  exit 0
fi

CODE_FILES=()
DOC_FILES=()
KNOWLEDGE_FILES=()

while IFS= read -r f; do
  if is_code_file "$f"; then
    CODE_FILES+=("$f")
  fi
  if is_doc_file "$f"; then
    DOC_FILES+=("$f")
  fi
  if is_knowledge_file "$f"; then
    KNOWLEDGE_FILES+=("$f")
  fi
done <<< "$ALL_FILES"

# 1) If only docs changed — always pass
if [[ ${#CODE_FILES[@]} -eq 0 ]]; then
  echo "  [guard] only documentation files changed — OK"
  exit 0
fi

# 2) If code changed but NO knowledge file was updated — warn/fail
if [[ ${#KNOWLEDGE_FILES[@]} -eq 0 ]]; then
  echo ""
  echo "  !!  KNOWLEDGE SYNC REQUIRED  !!"
  echo ""
  echo "  Code files changed, but no knowledge/*.md was updated."
  echo "  Update at least one file under knowledge/ to reflect the change,"
  echo "  or run with SKIP_KNOWLEDGE_GUARD=1 to bypass."
  echo ""
  echo "  Changed code files (${#CODE_FILES[@]}):"
  printf '    - %s\n' "${CODE_FILES[@]:0:10}"
  if [[ ${#CODE_FILES[@]} -gt 10 ]]; then
    echo "    ... and $((${#CODE_FILES[@]} - 10)) more"
  fi
  echo ""
  if [[ -n "$SKIP_KNOWLEDGE_GUARD" ]]; then
    echo "  [guard] SKIP_KNOWLEDGE_GUARD=1 — bypassing"
    exit 0
  fi
  exit 1
fi

# 3) Code changed AND knowledge files were updated — check language
echo "  [guard] code changed, knowledge files updated: ${#KNOWLEDGE_FILES[@]} new/changed doc(s)"
echo "  [guard] knowledge files:"
printf '    - %s\n' "${KNOWLEDGE_FILES[@]}"

# delegate to language check if it exists
LANG_SCRIPT="$REPO_ROOT/scripts/check_knowledge_language.sh"
if [[ -x "$LANG_SCRIPT" ]]; then
  echo "  [guard] running knowledge language check..."
  if bash "$LANG_SCRIPT" --changed 2>/dev/null; then
    echo "  [guard] language check passed"
  else
    echo "  [guard] language check FAILED — fix language issues in knowledge files"
    exit 2
  fi
fi

echo "  [guard] all checks passed"
exit 0
