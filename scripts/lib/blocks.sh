#!/usr/bin/env bash

render_block() {
  local file="$1" name="$2" src="$3" out="$4"
  local start="<!-- ${name}:start -->" end="<!-- ${name}:end -->"
  if grep -qF "$start" "$file"; then
    awk -v s="$start" -v e="$end" -v src="$src" '
      $0 == s { print; while ((getline line < src) > 0) print line; close(src); skip = 1; next }
      $0 == e { skip = 0 }
      !skip { print }
    ' "$file" > "$out"
  else
    { cat "$file"; [[ -s "$file" ]] && printf '\n'; printf '%s\n' "$start"; cat "$src"; printf '%s\n' "$end"; } > "$out"
  fi
}

render_file() {
  local file="$1" src_dir="$2"; shift 2
  local tmp block
  tmp="$(mktemp)"
  cp "$file" "$tmp"
  for block in "$@"; do
    render_block "$tmp" "$block" "${src_dir}/${block}.md" "${tmp}.next"
    mv "${tmp}.next" "$tmp"
  done
  echo "$tmp"
}
