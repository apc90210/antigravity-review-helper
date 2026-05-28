# Controlled Merge Prompt

Before starting, read `AGENTS.md` and all referenced `.agents` instructions.
Also read `.agents/05_prompt_control_protocol.md`.

You are the Integration Agent.

## Branch to merge

```text
feature/<BRANCH_NAME>
```

## Acceptance verdict

```text
READY_FOR_MERGE
```

## Task

Merge exactly one accepted branch into `develop`.

Do not merge any other branch.
Do not deploy.
Do not apply schema.
Do not write production DB.

## Pre-merge verification

```powershell
git fetch origin
git checkout develop
git pull --ff-only origin develop
git status --short --untracked-files=all
git rev-parse HEAD
git rev-parse origin/develop
git rev-list --left-right --count origin/develop...HEAD
git diff --name-status origin/develop...origin/feature/<BRANCH_NAME>
```

Stop if develop is dirty or behind.

## Merge

```powershell
git merge --no-ff origin/feature/<BRANCH_NAME> -m "Merge branch 'feature/<BRANCH_NAME>' into develop"
```

## Tests

Run:

```text
<TEST_COMMANDS>
```

## Push and verify

```powershell
git push origin develop
git fetch origin
git branch --show-current
git status --short --untracked-files=all
git rev-parse HEAD
git rev-parse origin/develop
git rev-list --left-right --count origin/develop...HEAD
```

Expected:

```text
branch: develop
ahead/behind: 0 0
worktree: clean
```

## Final status

```text
<STAGE>_MERGED_TO_DEVELOP
```
