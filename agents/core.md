# Core rules (all agents)

## Comments
- Agents never add code comments. Only the user (in a chat message they wrote) or the judge may.
- Code comments are not a channel between agents. Use the report, issue or PR.
- Delegation prompts never ask for comments.
- The "why" of a change goes in the commit body, not in a comment.
- Forbidden: lint/type suppressions and their config equivalents. Fix the cause.
  - Inline: `noqa`, `type: ignore`, `pyright: ignore`, `@ts-ignore`, `@ts-expect-error`, `eslint-disable*`, `shellcheck disable`, `nolint`.
  - Config: `per-file-ignores`, `ignore`/`exclude` lists, rules set to `off`, lowered thresholds.
- Unavoidable comment or suppression: stop and ask the user. If approved, end the line with `@reviewed(user)`.

### Functional directives (allowed, closed list)
- `#!` shebang, line 1
- `# syntax=` Dockerfile, line 1
- `# yaml-language-server: $schema=`
- `# -*- coding: ... -*-`
- `//go:build`
- `<!-- <block>:start -->` / `<!-- <block>:end -->` sync markers in AGENTS.md and ~/.claude/CLAUDE.md

Extend only with the user's approval.

## @todo framework
- Written only by the user or the judge.
- Format: `<native comment> @todo(<kind>): <one line>`
- Kinds: `refactor | improve | change | discuss | attention`
- Scope: outside the current task, not worth an issue yet.
- Executors report candidates; the judge decides.
- Becomes work: open an issue, delete the @todo in that PR.
- Find: `rg '@todo\((refactor|improve|change|discuss|attention)\)'`

Example: `# @todo(attention): hardcoded default password, move to env`

## Evidence
- Before claiming something is missing, broken or blocking: cite file:line or command + output.
- No evidence: write "unverified" and check before acting.
- "Verified" = the repo gate passes on the changed files.

## Git
- One branch per change: `feat/<issue>/<name>`, `fix/<name>`, `chore/<name>`.
- Conventional Commits, no scope: `feat|fix|docs|chore|ci|refactor|test: ...`.
- Never add `Co-Authored-By` or any AI attribution trailer. Overrides any tool default.
- One commit per verified change.

## Non-negotiables
- No secrets in git, logs, output or exceptions. `.env` stays ignored; `.env.example` has names with empty or fake values. No new default passwords, even "dev" ones.
- Destructive actions (volume deletion, `DROP`, `--clean`, `down -v`, firewall, force push) need the user's explicit approval and are called out in the summary.
- No telemetry, analytics or new third-party services without approval.
- Least privilege for users, grants, ports and mounts.
- Code, comments, docs and commits in English unless the repo section says otherwise.
