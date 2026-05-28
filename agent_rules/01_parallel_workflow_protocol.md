# 01 — Parallel Workflow Protocol

This project supports parallel agent work only when scopes are isolated.

## 1. Workflow layers

Every major stage should be split into:

```text
1. SPLIT / DISPATCH
2. WORKER
3. ACCEPTANCE
4. INTEGRATION
5. POST-MERGE VERIFICATION
```

No worker agent may perform acceptance of its own work unless explicitly requested.

No worker agent may merge to develop.

No split/dispatch agent may implement code.

No acceptance agent may expand scope.

No integration agent may merge more than one branch unless explicitly requested.

## 2. Parallel-safe task types

Usually safe to run in parallel:

```text
- docs-only planning
- read-only audit
- read-only diagnostics
- SQL draft without apply
- UI cosmetic branch limited to templates/static
- test-only branch with isolated files
```

Usually not safe to run in parallel:

```text
- schema apply
- migrations
- database writes
- Sandbox backend behavior changes
- ModelHub runner changes
- parser persistence changes
- production deploy
- develop merge
```

## 3. Workstream lock

Every worker task must declare a workstream lock:

```text
WORKSTREAM LOCK:
Allowed:
- exact directories/files

Forbidden:
- exact directories/files/actions
```

The agent must not modify files outside the allowed list.

If implementation requires files outside the lock, the agent must stop and report:

```text
SCOPE_EXPANSION_REQUIRED
```

## 4. Parallel execution matrix

Before launching parallel workers, create a table:

| Workstream | Branch | Scope | Parallel-safe | Depends on | Risk |
|---|---|---|---:|---|---|
| A | feature/... | docs only | yes | none | low |
| B | feature/... | templates/static | yes | none | medium |
| C | feature/... | schema apply | no | A+B accepted | high |

## 5. Integration rule

Even if workers run in parallel, merges must be sequential.

```text
One accepted branch at a time.
```

After each merge:

1. Run targeted tests.
2. Verify safety gates.
3. Push develop.
4. Confirm ahead/behind = 0/0.
5. Only then start the next merge.

## 6. Conflict handling

If branches conflict:

1. Do not auto-resolve broadly.
2. Report the conflict.
3. Resolve only files within the branch scope.
4. Re-run relevant tests.
5. Update the acceptance report.

## 7. Current Betsline / Bookmaker branch safety examples

Low-risk parallel:

```text
feature/mvp-v1-odds-timestamp-strict-prematch-audit
feature/mvp-v1-strict-prematch-storage-schema-draft
feature/site-public-cosmetic-display-cleanup
```

Sequential only:

```text
feature/mvp-v1-strict-prematch-storage-local-apply
feature/mvp-v1-production-deploy
```
