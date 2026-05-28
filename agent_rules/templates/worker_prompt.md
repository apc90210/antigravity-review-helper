# Worker Prompt Template

You are the Worker Agent.

Before starting, read `AGENTS.md` and all referenced `.agents` instructions.

## Task name

<TASK_NAME>

## Branch

feature/<BRANCH_NAME>

## Base

origin/develop

## Workstream lock

Allowed:

```text
<ALLOWED_FILES>
```

Forbidden:

```text
<FORBIDDEN_FILES_AND_ACTIONS>
```

## Initial conditions

<INITIAL_CONDITIONS>

## Implementation steps

1. Fetch origin.
2. Verify clean state.
3. Create feature branch from fresh origin/develop.
4. Implement only this task.
5. Run checks.
6. Create/update branch report.
7. Update daily log.
8. Commit explicit files only.
9. Push feature branch only.
10. Produce final report.

## Global prohibitions

```text
- Do not use git add .
- Do not merge into develop.
- Do not push develop.
- Do not deploy.
- Do not SSH to production.
- Do not write production DB.
- Do not apply schema unless explicitly allowed.
- Do not print secrets.
```

## Expected result

<EXPECTED_RESULT>

## Required final status

```text
<STATUS_LABEL_READY_FOR_REVIEW>
```
