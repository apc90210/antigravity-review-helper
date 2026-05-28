# Strict Acceptance Audit Prompt

Before starting, read `AGENTS.md` and all referenced `.agents` instructions.
Also read `.agents/05_prompt_control_protocol.md`.

You are the Acceptance Agent.

## Branch under audit

```text
feature/<BRANCH_NAME>
```

## Expected final worker status

```text
<STAGE>_READY_FOR_REVIEW
```

## Expected scope

Allowed files/directories:

```text
<ALLOWED_FILES>
```

Forbidden files/directories/actions:

```text
<FORBIDDEN_FILES_AND_ACTIONS>
```

## Task

Perform an independent acceptance audit only.

Do not continue implementation.
Do not add features.
Do not refactor.
Do not merge.
Do not push develop.
Do not deploy.
Do not apply schema.
Do not write DB data.

## Required checks

### AUDIT CHECKPOINT 1 — Branch and Sync

Run:

```powershell
git fetch origin
git checkout feature/<BRANCH_NAME>
git branch --show-current
git status --short --untracked-files=all
git rev-parse HEAD
git rev-parse origin/feature/<BRANCH_NAME>
git rev-parse origin/develop
git rev-list --left-right --count origin/feature/<BRANCH_NAME>...HEAD
git rev-list --left-right --count origin/develop...HEAD
```

### AUDIT CHECKPOINT 2 — Diff Scope

Run:

```powershell
git diff --name-status origin/develop...HEAD
git diff --stat origin/develop...HEAD
```

Verify every changed file is allowed.

### AUDIT CHECKPOINT 3 — Forbidden Scan

Check for:

```text
- git add . usage in reports/logs
- secrets or raw env values
- production SSH/deploy commands
- schema apply commands
- DB write commands
- writes to serving.predictions
- writes to ops.export_queue
- unrelated generated files
- cache/debug/scratch files
```

### AUDIT CHECKPOINT 4 — Report Completeness

Verify:

```text
docs/v1_audit/branch_reports/<REPORT_NAME>.md exists
logs/YYYY-MM-DD.md updated
worker final status present
checkpoint results present
safety gates present
changed files listed
next step listed
```

### AUDIT CHECKPOINT 5 — Tests

Re-run or verify relevant tests:

```text
<TEST_COMMANDS>
```

### AUDIT CHECKPOINT 6 — Verdict

Choose exactly one:

```text
READY_FOR_MERGE
NEEDS_FIX
BLOCKED_UNSAFE
BLOCKED_SCOPE_VIOLATION
BLOCKED_INCOMPLETE_REPORT
```

## Output report

Create/update:

```text
docs/v1_audit/branch_reports/<REPORT_NAME>_acceptance_audit.md
```

## Final response format

```text
# Acceptance Audit — <TASK_NAME>

## Verdict
<READY_FOR_MERGE / NEEDS_FIX / BLOCKED_*>

## Branch
feature/<BRANCH_NAME>

## Diff Scope
PASS/FAIL

## Tests
PASS/FAIL

## Safety Gates
Production:
DB writes:
Schema apply:
serving.predictions:
ops.export_queue:
Secrets:
Public/Sandbox exposure:
Force push:

## Issues
<list or NONE>

## Required Fixes
<list or NONE>

## Next Step
<controlled merge or fix-only prompt>
```
