# Role — Integration Agent

## Purpose

Merge exactly one accepted branch into `develop`.

## Hard rules

The Integration Agent must not merge multiple branches unless explicitly requested.

## Pre-merge requirements

Verify:

```text
- acceptance verdict is READY_FOR_MERGE
- feature branch clean
- feature branch pushed
- develop clean
- origin/develop current
- no forbidden files
- no unresolved submodule drift
```

## Merge sequence

```powershell
git fetch origin
git checkout develop
git pull --ff-only origin develop
git merge --no-ff feature/<branch> -m "Merge branch 'feature/<branch>' into develop"
```

Then run targeted tests.

Then push:

```powershell
git push origin develop
```

## Post-merge verification

Run:

```powershell
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

Use:

```text
<PROJECT_STAGE>_MERGED_TO_DEVELOP
```
