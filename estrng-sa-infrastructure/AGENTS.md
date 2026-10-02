# AGENTS.md

`estrngsa/estrng-sa-infrastructure`: IaC (Compose, GitHub Actions, Bash, SQL). Repo rules first; blocks inside the markers are synced from `.github/agents/`, never edit them here.

## Boundaries
- Orchestration ceiling is Compose + Tailscale (`docs/adr/adr-001-compose-tailscale.md`). No Swarm or Kubernetes manifests.
- Read the relevant ADR in `docs/adr/` before touching its area. `docs/platform/architecture.md` wins on conflict.
- Do not edit `.agents/`, `.claude/`, `.github/prompts/`, `.github/skills/` unless the task says so.
- Never in git: `.env`, `/opt/estrngsa/...`, `init_backup.sql`, `tools.yaml`.
- `scripts/provision-vps.sh` messages stay pt-BR unless asked.
- `main` receives bot commits from `update-docker-image-version.yml`.

## Compose rules
- Project `name:` per node (`estrngsa-core`, `estrngsa-edge`). No `container_name`.
- Core networks: `estrngsa_apps`, `estrngsa_db`. DB only on `estrngsa_db`.
- `TZ: America/Sao_Paulo`. All config via `${VAR}`; keep `.env.example` in sync.
- Ports: internal = no `ports:`; tailnet = `${TS_IP}:port:port`; public = edge proxy 80/443 only. Postgres on `127.0.0.1:5432` until the single-Postgres issue.
- Images: registry, pinned tag, no `build:`, no `:latest`. First-party: required `${<NAME>_TAG:?}`. Third-party: literal tag (Umami: required var).
- Persistent volumes: explicit `name:`.
- Long-running services: Docker healthcheck, else an external probe listed in the node README.
- No `docker.sock` mounts, `privileged`, new published ports or relaxed SSH/UFW without asking. GPU reservations only where needed.

## Known drift (flag, do not widen)
- Default passwords in `scripts/create_db_users.sql` and `setup_db_users.sh`. Pending move to env.
- CI workflow edits the removed `infra/docker-compose/estrngsa-dev/docker-compose.base.yml`; its sed misses `${<NAME>_TAG}` vars (#21).
- Touching one: say so before working around it.

## Gate
From a clean tree, run what applies:
```
for n in core edge; do
  docker compose --env-file nodes/$n/.env.example -f nodes/$n/compose.yml config -q
done
bash -n scripts/*.sh nodes/core/scripts/*.sh
shellcheck scripts/*.sh nodes/core/scripts/*.sh
find nodes infra scripts -type f -empty
../.github/scripts/check-comments.sh main
../.github/scripts/sync-agents.sh --check
```
- Baseline 2026-10-02: all clean. `shellcheck` not installed locally.
- Bar: no new warnings or errors. Say which checks did not run.
- Never `docker compose up/down`, `provision-vps.sh`, or anything touching a real host or local Docker state.
- No test suite; do not invent one for config.

## Workflow
- Structural or multi-file (new node, secrets strategy, platform convention): OpenSpec (`/opsx:explore`, `/opsx:propose`, `openspec validate <name> --strict`, `/opsx:apply`, `/opsx:sync`, `/opsx:archive`).
- Small fixes, docs, image bumps: branch + commit.
- Branches from `main`, PRs to `main`. Ignore `dev`.
- Clean tree before each agy call.
- Codebase-memory MCP (`estrng-sa-infra`) is weak on YAML/shell: read named files, grep literals.

## Verification
- Shell: `set -euo pipefail`, idempotent, quoted vars, no interactive prompts unless intended.
- SQL: re-runnable, transactional where possible, least-privilege grants. AI read-only user never gets write.
- Compose: port classes and placement kept, `depends_on` and health signals coherent.

<!-- core:start -->
<!-- core:end -->

<!-- executor:start -->
<!-- executor:end -->
