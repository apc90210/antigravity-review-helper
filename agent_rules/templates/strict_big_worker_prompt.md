# Strict Big Worker Prompt

Before starting, read `AGENTS.md` and all referenced `.agents` instructions.
Also read `.agents/05_prompt_control_protocol.md`.

You are the Worker Agent.

## Task name

<TASK_NAME>

## Required final status

```text
<STAGE>_READY_FOR_REVIEW
```

## Repository

```text
C:\bookmaker-modhub
```

## Base branch

```text
origin/develop
```

## Feature branch

```text
feature/<BRANCH_NAME>
```

## Project context

<PROJECT_CONTEXT>

## Goal

<GOAL>

## Scope lock

Allowed files/directories:

```text
<ALLOWED_FILES>
```

Forbidden files/directories/actions:

```text
<FORBIDDEN_FILES_AND_ACTIONS>
```

## Hard prohibitions

```text
- Do not use git add .
- Do not merge into develop.
- Do not push develop.
- Do not deploy.
- Do not SSH to production.
- Do not run migrations.
- Do not apply schema.
- Do not write production DB.
- Do not write serving.predictions.
- Do not write ops.export_queue.
- Do not print secrets, tokens, passwords, DSNs, or .env values.
- Do not perform unrelated refactors.
```

## Required execution flow

### CHECKPOINT 1 — Repository State

Run and record:

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

If the repo is dirty before starting, stop and report.

### CHECKPOINT 2 — Branch Creation

Create the feature branch from fresh `origin/develop`.

```powershell
git checkout develop
git pull --ff-only origin develop
git checkout -b feature/<BRANCH_NAME>
```

### CHECKPOINT 3 — Scope Confirmation

Before editing, list the files you expect to touch.

If the task requires files outside the allowed scope, stop and report:

```text
BLOCKED_SCOPE_EXPANSION_REQUIRED
```

### CHECKPOINT 4 — Implementation

Implement only the requested task.

Required implementation steps:

```text
<IMPLEMENTATION_STEPS>
```

### CHECKPOINT 5 — Diff Self-Review

Run:

```powershell
git diff --name-status
git diff --stat
git status --short --untracked-files=all
```

Verify:

```text
- all changed files are allowed
- no forbidden files changed
- no generated junk files
- no secrets
- no unrelated refactors
```

### CHECKPOINT 6 — Tests and Safety Gates

Run:

```text
<TEST_COMMANDS>
```

Verify safety gates:

```text
- production: not touched
- DB writes: none unless explicitly allowed
- schema apply: none unless explicitly allowed
- serving.predictions: not written
- ops.export_queue: not written
- public exposure: none unless explicitly allowed
- Sandbox behavior: unchanged unless explicitly allowed
- secrets: not printed
```

### CHECKPOINT 7 — Report and Log

Create/update:

```text
docs/v1_audit/branch_reports/<REPORT_NAME>.md
logs/YYYY-MM-DD.md
```

The report must include:

```text
- final status
- branch
- base
- final HEAD
- changed files
- implementation summary
- tests
- safety gates
- checkpoint results
- caveats
- next recommended step
```

### CHECKPOINT 8 — Commit and Push

Use explicit `git add` only.

Forbidden:

```powershell
git add .
```

Required:

```powershell
git diff --cached --name-status
git commit -m "<COMMIT_MESSAGE>"
git push origin feature/<BRANCH_NAME>
```

### CHECKPOINT 9 — Final Verification

Run:

```powershell
git fetch origin
git branch --show-current
git status --short --untracked-files=all
git rev-parse HEAD
git rev-parse origin/feature/<BRANCH_NAME>
git rev-list --left-right --count origin/feature/<BRANCH_NAME>...HEAD
git diff --name-status origin/develop...HEAD
```

## Final response format

```text
# Final Report — <TASK_NAME>

## Final Status
<STAGE>_READY_FOR_REVIEW

## Branch
feature/<BRANCH_NAME>

## Base
origin/develop <hash>

## Final HEAD
<hash>

## Changed Files
<name-status list>

## Checkpoints
CHECKPOINT 1:
CHECKPOINT 2:
CHECKPOINT 3:
CHECKPOINT 4:
CHECKPOINT 5:
CHECKPOINT 6:
CHECKPOINT 7:
CHECKPOINT 8:
CHECKPOINT 9:

## Tests
<commands and results>

## Safety Gates
Production:
DB writes:
Schema apply:
serving.predictions:
ops.export_queue:
Secrets:
Public/Sandbox exposure:
Force push:

## Caveats
<if any>

## Next Recommended Step
Run independent acceptance audit prompt.
```
