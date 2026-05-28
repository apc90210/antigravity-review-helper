# Acceptance Prompt Template

You are the Acceptance Agent.

Before starting, read `AGENTS.md` and all referenced `.agents` instructions.

## Branch to audit

feature/<BRANCH_NAME>

## Expected scope

Allowed:

```text
<ALLOWED_FILES>
```

Forbidden:

```text
<FORBIDDEN_FILES_AND_ACTIONS>
```

## Task

Perform acceptance audit only.

Do not continue implementation.
Do not add new features.
Do not merge.
Do not deploy.
Do not apply schema.
Do not write DB data.

## Required checks

Run or verify:

```powershell
git fetch origin
git branch --show-current
git status --short --untracked-files=all
git rev-parse HEAD
git rev-parse origin/develop
git rev-list --left-right --count origin/develop...HEAD
git diff --name-status origin/develop...HEAD
git submodule status
git -C betsline status --short --untracked-files=all
```

Verify:

- changed files are in scope
- report exists
- daily log updated
- tests/checks pass
- no forbidden actions
- no production access
- no DB writes unless explicitly allowed
- no schema apply unless explicitly allowed
- no secrets printed
- feature branch pushed

## Output

Create/update:

```text
docs/v1_audit/branch_reports/<task>_acceptance_audit.md
```

## Verdict

Use exactly one:

```text
READY_FOR_MERGE
NEEDS_FIX
BLOCKED_UNSAFE
BLOCKED_SCOPE_VIOLATION
BLOCKED_INCOMPLETE_REPORT
```
