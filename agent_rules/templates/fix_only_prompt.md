# Fix-Only Prompt

Before starting, read `AGENTS.md` and all referenced `.agents` instructions.
Also read `.agents/05_prompt_control_protocol.md`.

You are the Fix Agent.

## Branch

```text
feature/<BRANCH_NAME>
```

## Acceptance verdict

```text
NEEDS_FIX
```

## Issues to fix

```text
<EXACT_ISSUES_FROM_ACCEPTANCE_AUDIT>
```

## Task

Fix only the listed issues.

Do not add new features.
Do not expand scope.
Do not merge.
Do not deploy.
Do not apply schema.
Do not write DB data unless explicitly allowed.
Do not use git add .

## Required flow

1. Checkout the same feature branch.
2. Verify status.
3. Fix only listed issues.
4. Re-run relevant checks.
5. Update branch report and daily log.
6. Commit explicit files only.
7. Push feature branch only.

## Final status

```text
FIX_READY_FOR_RE_ACCEPTANCE
```
