# Integration Prompt Template

You are the Integration Agent.

Before starting, read `AGENTS.md` and all referenced `.agents` instructions.

## Accepted branch

feature/<BRANCH_NAME>

## Acceptance verdict

READY_FOR_MERGE

## Task

Perform controlled merge of exactly one accepted branch into `develop`.

Do not merge any other branch.
Do not deploy.
Do not apply schema.
Do not write production DB.

## Pre-merge checks

```powershell
git fetch origin
git checkout develop
git pull --ff-only origin develop
git status --short --untracked-files=all
git rev-parse HEAD
git rev-parse origin/develop
git rev-list --left-right --count origin/develop...HEAD
git diff --name-status origin/develop...feature/<BRANCH_NAME>
```

## Merge

```powershell
git merge --no-ff feature/<BRANCH_NAME> -m "Merge branch 'feature/<BRANCH_NAME>' into develop"
```

## Post-merge checks

Run targeted tests:

```text
<TEST_COMMANDS>
```

Then:

```powershell
git status --short --untracked-files=all
git push origin develop
git fetch origin
git rev-parse HEAD
git rev-parse origin/develop
git rev-list --left-right --count origin/develop...HEAD
```

## Expected result

```text
branch: develop
ahead/behind: 0 0
worktree: clean
```

## Final status

```text
<STAGE_NAME>_MERGED_TO_DEVELOP
```
