# 05 — Strict Prompt Control Protocol

This protocol defines how large Antigravity tasks must be executed.

## 1. Core model

Every large task must be handled as a controlled sequence:

```text
1. DISPATCH / SPLIT
2. BIG WORKER PROMPT
3. SELF-CHECK INSIDE WORKER PROMPT
4. FINAL REPORT
5. INDEPENDENT ACCEPTANCE AUDIT
6. FIX-ONLY CORRECTION IF NEEDED
7. CONTROLLED MERGE
```

The worker must not be trusted as final approval.

A separate acceptance prompt must verify the result.

## 2. Big prompt structure

A big worker prompt must contain:

```text
- Project context
- Current stage
- Branch name
- Base branch
- Scope lock
- Allowed files
- Forbidden files/actions
- Initial repository checks
- Step-by-step implementation plan
- Built-in self-control checkpoints
- Testing plan
- Safety gates
- Report contract
- Final status label
- Explicit "do not merge" instruction
```

## 3. Self-control checkpoints

The worker prompt must force the agent to pause internally at checkpoints:

```text
CHECKPOINT 1 — Repository State
CHECKPOINT 2 — Scope Confirmation
CHECKPOINT 3 — Implementation Diff Review
CHECKPOINT 4 — Safety Gate Review
CHECKPOINT 5 — Test Review
CHECKPOINT 6 — Final Report Completeness
```

The agent must include checkpoint results in the final report.

## 4. Forbidden by default

The following remain forbidden unless the prompt explicitly allows them:

```text
- git add .
- merge into develop
- push develop
- production SSH
- deploy
- schema apply
- migrations
- DB writes
- destructive SQL
- writes to serving.predictions
- writes to ops.export_queue
- printing secrets
- broad cleanup
- unrelated refactors
```

## 5. Scope expansion rule

If the task cannot be completed inside the allowed scope, the worker must stop and report:

```text
BLOCKED_SCOPE_EXPANSION_REQUIRED
```

The worker must not silently expand scope.

## 6. Audit prompt rule

After every big worker prompt, run a separate audit prompt.

The audit prompt must:

```text
- not implement new features
- not merge
- not deploy
- verify diff scope
- verify branch status
- verify tests
- verify safety gates
- verify reports/logs
- produce READY_FOR_MERGE or NEEDS_FIX
```

## 7. Fix-only rule

If audit finds problems, the next prompt must be fix-only:

```text
Fix only the acceptance issues.
Do not add features.
Do not expand scope.
Do not merge.
```

## 8. Parallel work rule

Parallel work requires a dispatch plan first.

Parallel-safe workstreams usually include:

```text
- docs-only plans
- read-only audits
- SQL drafts without apply
- UI cosmetic changes limited to templates/static
- isolated diagnostics
```

Sequential-only workstreams:

```text
- DB schema apply
- migrations
- model promotion
- Sandbox backend changes that share files with another branch
- develop merge
- production deploy
```

## 9. Final report status labels

Every worker must finish with one exact status label:

```text
<STAGE>_READY_FOR_REVIEW
<STAGE>_BLOCKED_SCOPE_EXPANSION_REQUIRED
<STAGE>_BLOCKED_SAFETY_CONFLICT
```

Every audit must finish with one exact verdict:

```text
READY_FOR_MERGE
NEEDS_FIX
BLOCKED_UNSAFE
BLOCKED_SCOPE_VIOLATION
```

Every merge must finish with:

```text
<STAGE>_MERGED_TO_DEVELOP
```
