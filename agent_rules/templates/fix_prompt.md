# Fix Prompt Template

You are the Fix Agent.

Before starting, read `AGENTS.md` and all referenced `.agents` instructions.

## Branch

feature/<BRANCH_NAME>

## Acceptance issues to fix

```text
<ISSUES>
```

## Task

Fix only the listed issues.

Do not add new features.
Do not expand scope.
Do not merge.
Do not deploy.
Do not apply schema unless explicitly allowed.
Do not write DB data unless explicitly allowed.

## Required checks

After fixes:

```powershell
git diff --name-status origin/develop...HEAD
git status --short --untracked-files=all
```

Run targeted tests:

```text
<TEST_COMMANDS>
```

Update report and daily log.

Commit explicit files only.
Push feature branch only.

## Final status

```text
FIX_READY_FOR_RE_ACCEPTANCE
```
