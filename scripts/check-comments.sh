#!/usr/bin/env bash
set -euo pipefail

BASE="${1:-main}"

ALLOW='@todo\((refactor|improve|change|discuss|attention)\)|@reviewed\(user\)|^#!|^# syntax=|^# yaml-language-server: \$schema=|^# -\*- coding:|^//go:build|<!-- [a-z]+:(start|end) -->'
SUPPRESS='noqa|type: *ignore|pyright: *ignore|@ts-ignore|@ts-expect-error|eslint-disable|shellcheck +disable|nolint'
LINT_CONFIG='(^|/)(pyproject\.toml|setup\.cfg|\.flake8|ruff\.toml|\.ruff\.toml|mypy\.ini|\.eslintrc[^/]*|eslint\.config\.[cm]?[jt]s|\.shellcheckrc|\.golangci\.ya?ml|tsconfig[^/]*\.json)$'

comment_regex() {
  case "$1" in
    *.py|*.sh|*.bash|*.yml|*.yaml|*.toml|*.cfg|*.ini|*Dockerfile*|*.conf|*.env.example) echo '^\s*#|\s#\s' ;;
    *.js|*.jsx|*.ts|*.tsx|*.mjs|*.cjs|*.go|*.c|*.h|*.cpp|*.java|*.kt|*.rs|*.css|*.scss) echo '^\s*(//|/\*|\*)|\s//\s|/\*' ;;
    *.sql) echo '^\s*--|\s--\s|/\*' ;;
    *.html|*.vue|*.svelte) echo '<!--|^\s*(//|/\*)' ;;
    *) echo '' ;;
  esac
}

fail=0

while IFS= read -r file; do
  if [[ "$file" =~ $LINT_CONFIG ]]; then
    echo "review: lint/type config changed: $file"
    fail=1
  fi

  regex="$(comment_regex "$file")"
  [[ -n "$regex" ]] || continue

  lineno=0
  while IFS= read -r line; do
    if [[ "$line" =~ ^@@\ -[0-9,]+\ \+([0-9]+) ]]; then
      lineno=$(( BASH_REMATCH[1] - 1 ))
      continue
    fi
    [[ "$line" == +* ]] || { [[ "$line" == -* ]] || lineno=$(( lineno + 1 )); continue; }
    lineno=$(( lineno + 1 ))
    content="${line:1}"
    if grep -Eq "$SUPPRESS" <<< "$content" && ! grep -Eq '@reviewed\(user\)' <<< "$content"; then
      echo "suppression: $file:$lineno"
      fail=1
    elif grep -Eq "$regex" <<< "$content" && ! grep -Eq "$ALLOW" <<< "$content"; then
      echo "comment: $file:$lineno"
      fail=1
    fi
  done < <(git diff --unified=0 "$BASE"...HEAD -- "$file"; git diff --unified=0 -- "$file")
done < <({ git diff --name-only --diff-filter=AM "$BASE"...HEAD; git diff --name-only --diff-filter=AM; } | sort -u)

exit "$fail"
