#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$(cd "${SCRIPT_DIR}/../agents" && pwd)"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
MODE="${1:-write}"

source "${SCRIPT_DIR}/lib/blocks.sh"

[[ "$MODE" == "write" || "$MODE" == "--check" ]] || { echo "usage: $(basename "$0") [write|--check]" >&2; exit 2; }

memory="${CLAUDE_DIR}/CLAUDE.md"
stale=0

[[ -f "$memory" ]] || : > "$memory"

rendered="$(render_file "$memory" "$SRC_DIR" judge)"
if ! cmp -s "$rendered" "$memory"; then
  if [[ "$MODE" == "--check" ]]; then echo "stale: $memory"; stale=1
  else cp "$rendered" "$memory"; echo "updated: $memory"; fi
fi
rm -f "$rendered"

exit "$stale"
