#!/usr/bin/env bash
set -euo pipefail

MAX_WORDS="${JUDGE_MAX_WORDS:-120}"

input="$(cat)"
[[ "$(jq -r '.stop_hook_active // false' <<< "$input")" == "true" ]] && exit 0

transcript="$(jq -r '.transcript_path' <<< "$input")"
[[ -f "$transcript" ]] || exit 0

last_text="$(jq -rs '
  [ .[] | select(.type == "assistant") | .message.content[]? | select(.type == "text") | .text ] | last // ""
' "$transcript")"

words="$(awk '/^```/ { fence = !fence; next } !fence' <<< "$last_text" | wc -w)"

if (( words > MAX_WORDS )); then
  jq -n --arg r "Reply has ${words} words outside code blocks (limit ${MAX_WORDS}). Rewrite it within the Judge chat limits. Skip only if the user asked for this deliverable." \
    '{decision: "block", reason: $r}'
fi
