#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$(cd "${SCRIPT_DIR}/../agents" && pwd)"
HOOK_SRC="$(cd "${SCRIPT_DIR}/../hooks" && pwd)/judge-verbosity.sh"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
MODE="${1:-write}"

source "${SCRIPT_DIR}/lib/blocks.sh"

[[ "$MODE" == "write" || "$MODE" == "--check" ]] || { echo "usage: $(basename "$0") [write|--check]" >&2; exit 2; }
command -v jq >/dev/null || { echo "jq is required" >&2; exit 1; }

memory="${CLAUDE_DIR}/CLAUDE.md"
hook="${CLAUDE_DIR}/hooks/judge-verbosity.sh"
settings="${CLAUDE_DIR}/settings.json"
stale=0

mkdir -p "${CLAUDE_DIR}/hooks"
[[ -f "$memory" ]] || : > "$memory"
[[ -f "$settings" ]] || echo '{}' > "$settings"

rendered="$(render_file "$memory" "$SRC_DIR" judge)"
if ! cmp -s "$rendered" "$memory"; then
  if [[ "$MODE" == "--check" ]]; then echo "stale: $memory"; stale=1
  else cp "$rendered" "$memory"; echo "updated: $memory"; fi
fi
rm -f "$rendered"

if ! cmp -s "$HOOK_SRC" "$hook" 2>/dev/null; then
  if [[ "$MODE" == "--check" ]]; then echo "stale: $hook"; stale=1
  else install -m 0755 "$HOOK_SRC" "$hook"; echo "updated: $hook"; fi
fi

if ! jq -e --arg cmd "$hook" '[.hooks.Stop[]?.hooks[]?.command] | index($cmd)' "$settings" >/dev/null; then
  if [[ "$MODE" == "--check" ]]; then echo "missing Stop hook: $settings"; stale=1
  else
    [[ -f "${settings}.bak" ]] || cp "$settings" "${settings}.bak"
    tmp="$(mktemp)"
    jq --arg cmd "$hook" '.hooks.Stop += [{hooks: [{type: "command", command: $cmd}]}]' "$settings" > "$tmp"
    mv "$tmp" "$settings"
    echo "updated: $settings"
  fi
fi

exit "$stale"
