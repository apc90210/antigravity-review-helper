# 00 — Global Agent Rules

These rules apply to every agent and every task.

## 1. Operating principle

One agent must work on one clearly defined scope only.

```text
One agent = one branch = one scope = one final status.
```

The agent must not combine unrelated responsibilities such as audit, implementation, schema apply, deployment, merge, and production verification in a single task unless explicitly requested.

## 2. Mandatory first actions

Before doing any work, the agent must:

1. Identify current repository root.
2. Verify current branch.
3. Fetch remote.
4. Verify working tree status.
5. Verify nested repositories/submodules if present.
6. Read the task scope and compare it with these instructions.
7. Stop if the task is ambiguous or unsafe.

Recommended commands:

```powershell
git fetch origin
git branch --show-current
git status --short --untracked-files=all
git rev-parse HEAD
git rev-parse origin/develop
git rev-list --left-right --count origin/develop...HEAD
git submodule status
git -C betsline status --short --untracked-files=all
```

If `betsline/` does not exist, report that nested repository check is not applicable.

## 3. Forbidden by default

The following actions are forbidden unless the prompt explicitly authorizes them:

```text
- git add .
- git clean -fd
- git reset --hard
- force push
- merge into develop
- push develop
- production SSH
- production deploy
- docker production deploy
- database schema apply
- migrations
- destructive SQL
- writes to production
- writes to serving.predictions
- writes to ops.export_queue
- public prediction exposure
- Sandbox recommendation behavior changes
- credential dumping
- printing secrets, tokens, passwords, DSNs, env files
```

## 4. Git add policy

Never use:

```powershell
git add .
```

Use explicit file adds only:

```powershell
git add docs/plans/example.md
git add docs/v1_audit/branch_reports/example_report.md
git add logs/2026-05-20.md
```

Before commit, show:

```powershell
git diff --cached --name-status
```

## 5. Secrets policy

Never print secrets.

Forbidden examples:

```powershell
docker inspect ... Env
cat .env
type .env
Get-Content .env
cat docker-compose.yml
```

If an environment or compose file must be inspected, use sanitized output only and redact values.

Allowed pattern:

```text
POSTGRES_PASSWORD=<REDACTED>
SECRET_KEY=<REDACTED>
TOKEN=<REDACTED>
```

## 6. Logging policy

Every task must update the daily log:

```text
logs/YYYY-MM-DD.md
```

Log entry must include:

- task name
- branch
- files changed
- tests/checks
- safety gates
- final status
- next recommended step

## 7. Report policy

Every non-trivial task must create or update a report:

```text
docs/v1_audit/branch_reports/<task_name>.md
```

Planning documents go to:

```text
docs/plans/
```

## 8. Final status label

Each task must finish with exactly one clear status label, for example:

```text
READY_FOR_REVIEW
READY_FOR_MERGE
NEEDS_FIX
MERGED_TO_DEVELOP
BLOCKED
```

Use project-specific prefixes where appropriate:

```text
MVP_V1_ODDS_TIMESTAMP_STRICT_PREMATCH_AUDIT_READY_FOR_REVIEW
```
