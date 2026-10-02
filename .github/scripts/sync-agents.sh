#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$(cd "${SCRIPT_DIR}/../agents" && pwd)"
WORKSPACE="$(cd "${SRC_DIR}/../.." && pwd)"
MODE="${1:-write}"

source "${SCRIPT_DIR}/lib/blocks.sh"

[[ "$MODE" == "write" || "$MODE" == "--check" ]] || { echo "usage: $(basename "$0") [write|--check]" >&2; exit 2; }

stale=0
for repo in "$WORKSPACE"/*/; do
  agents="${repo}AGENTS.md"
  claude="${repo}CLAUDE.md"
  [[ -f "$agents" ]] || continue

  if [[ -f "$claude" ]] && ! grep -qx '@AGENTS.md' "$claude"; then
    echo "missing @AGENTS.md import: ${claude#"$WORKSPACE"/}"
    stale=1
  fi

  rendered="$(render_file "$agents" "$SRC_DIR" core executor)"
  if ! cmp -s "$rendered" "$agents"; then
    if [[ "$MODE" == "--check" ]]; then
      echo "stale: ${agents#"$WORKSPACE"/}"
      stale=1
    else
      cp "$rendered" "$agents"
      echo "updated: ${agents#"$WORKSPACE"/}"
    fi
  fi
  rm -f "$rendered"
done

exit "$stale"
