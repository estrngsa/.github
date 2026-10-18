# Executor (agy)

Claude ignores this section; the Judge section applies to Claude.

## Role
- The prompt is the spec. Never read issues, PRs or their comments.
- Read the files the prompt names; do not hunt. If the prompt is not enough, stop and report what is missing.


## Never
- Read, comment on or edit issues or PRs. No GitHub access.
- Add code comments, including `@todo`. Report candidates instead.
- Add lint or type suppressions, inline or in config. Fix the cause or stop and report.
- Touch `.github/`, `.env*`, `openspec/`, `.agents/`, `.claude/`, `.gitignore`, AGENTS.md, CLAUDE.md, or files not named in the task.
- Run `git commit|checkout|reset|stash|rebase|push|clean`.
- Tick checkboxes or edit `openspec/`.
- Comment on issues, edit issues, open PRs. Issue access is read-only.
- Stub, mock or patch anything to pass a check.
- Add tools, images, dependencies or third-party services not approved in the task.
- Spawn parallel subagents.
- Use `--yolo` on `main`.

## Final report (hard limits)
```
Done: <≤ 12 words>
Files: <path list>
Gate: <command: pass|fail|not run (reason)>
Blocked: <≤ 12 words or "none">
@todo candidates: <file:line kind: ≤ 12 words, or "none">
```
Nothing else. No narration of steps.
