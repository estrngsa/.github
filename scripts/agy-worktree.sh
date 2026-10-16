#!/usr/bin/env bash
set -euo pipefail

[[ $# -eq 2 ]] || { echo "usage: $(basename "$0") <repo-path> <branch>" >&2; exit 2; }

repo="$(cd "$1" && pwd)"
branch="$2"
wt="$(dirname "$repo")/$(basename "$repo")-agy"

if [[ ! -d "$wt" ]]; then
  git -C "$repo" fetch -q origin
  git -C "$repo" worktree add -q --detach "$wt" origin/main
fi

dirty="$(git -C "$wt" status --porcelain)"
if [[ -n "$dirty" ]]; then
  echo "dirty worktree: $wt" >&2
  echo "$dirty" >&2
  exit 1
fi

git -C "$wt" fetch -q origin

if git -C "$wt" show-ref --verify --quiet "refs/heads/${branch}"; then
  ahead="$(git -C "$wt" rev-list --count "origin/main..${branch}")"
  if [[ "$ahead" -gt 0 ]]; then
    git -C "$wt" checkout -q "$branch"
  else
    git -C "$wt" checkout -q -B "$branch" origin/main
  fi
else
  git -C "$wt" checkout -q -b "$branch" origin/main
fi

lockfiles="$(git -C "$wt" ls-files -- '*pnpm-lock.yaml' '*poetry.lock' '*package-lock.json' '*uv.lock' | sort)"
hash="$(
  while IFS= read -r lock; do
    [[ -n "$lock" ]] && sha256sum "${wt}/${lock}"
  done <<<"$lockfiles" | sed "s#${wt}/##" | sha256sum | cut -d' ' -f1
)"

stamp="$(git -C "$wt" rev-parse --absolute-git-dir)/agy-deps.sha"
deps="reused"

if [[ ! -f "$stamp" || "$(cat "$stamp")" != "$hash" ]]; then
  while IFS= read -r lock; do
    [[ -n "$lock" ]] || continue
    dir="${wt}/$(dirname "$lock")"
    case "$(basename "$lock")" in
      pnpm-lock.yaml)
        (cd "$dir" && env "npm_config_//npm.pkg.github.com/:_authToken=${GITHUB_TOKEN_PACKAGE_REGISTRY:-}" pnpm install --frozen-lockfile >&2)
        ;;
      poetry.lock)
        (cd "$dir" && poetry install --no-interaction >&2)
        ;;
      package-lock.json)
        (cd "$dir" && npm ci >&2)
        ;;
      uv.lock)
        (cd "$dir" && uv sync --frozen >&2)
        ;;
    esac
  done <<<"$lockfiles"
  printf '%s\n' "$hash" >"$stamp"
  deps="reinstalled"
fi

echo "worktree=${wt} branch=${branch} deps: ${deps}"
