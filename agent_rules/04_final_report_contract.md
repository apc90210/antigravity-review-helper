# 04 — Final Report Contract

Every agent must finish with a structured final report.

## 1. Required report sections

```text
# Final Report — <Task Name>

## 1. Final Status
<STATUS_LABEL>

## 2. Branch
<branch name>

## 3. Base
<origin/develop HEAD at start>

## 4. Final HEAD
<local HEAD>
<remote feature HEAD if pushed>

## 5. Changed Files
<git diff --name-status base...HEAD>

## 6. Scope Verification
Allowed scope:
Forbidden scope:
Result:

## 7. Tests / Checks
Commands run:
Results:

## 8. Safety Gates
Production:
DB writes:
Schema apply:
serving.predictions:
ops.export_queue:
Secrets:
Public/Sandbox exposure:
Force push:

## 9. Findings / Implementation Summary
<what changed or what was found>

## 10. Caveats
<known limitations or skipped checks>

## 11. Next Recommended Step
<acceptance / fix / merge / next branch>
```

## 2. Raw command proof

When possible, include raw outputs for:

```powershell
git branch --show-current
git status --short --untracked-files=all
git rev-parse HEAD
git rev-parse origin/develop
git rev-list --left-right --count origin/develop...HEAD
git diff --name-status origin/develop...HEAD
git submodule status
```

## 3. Status labels

Use one final label only.

Examples:

```text
MVP_V1_ODDS_TIMESTAMP_STRICT_PREMATCH_AUDIT_READY_FOR_REVIEW
MVP_V1_STRICT_PREMATCH_STORAGE_SCHEMA_DRAFT_READY_FOR_REVIEW
SITE_PUBLIC_COSMETIC_DISPLAY_CLEANUP_READY_FOR_REVIEW
READY_FOR_MERGE
NEEDS_FIX
BLOCKED_SCOPE_CONFLICT
MERGED_TO_DEVELOP
```

## 4. No vague endings

Forbidden final wording:

```text
Done.
Looks good.
I think it works.
Should be okay.
```

Required wording:

```text
Final status: <EXACT_STATUS_LABEL>
```
