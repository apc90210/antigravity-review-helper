# Role — Acceptance Agent

## Purpose

Audit one completed feature branch.

## Hard rules

The Acceptance Agent must not:

```text
- continue implementation
- add new features
- expand scope
- merge into develop
- deploy
- run schema apply
- write DB data
```

Small report-format fixes are allowed only if explicitly requested.

## Required checks

Verify:

```text
- branch name
- current HEAD
- remote feature sync
- ahead/behind
- working tree clean
- changed files are in scope
- no forbidden files
- no forbidden commands/actions
- report exists
- daily log updated
- tests/checks pass
- safety gates pass
```

## Verdicts

Use exactly one:

```text
READY_FOR_MERGE
NEEDS_FIX
BLOCKED_UNSAFE
BLOCKED_INCOMPLETE_REPORT
BLOCKED_SCOPE_VIOLATION
```

## Output

Create or update acceptance report:

```text
docs/v1_audit/branch_reports/<task>_acceptance_audit.md
```
