# 03 — Safety Gates

These safety gates protect Betsline / Bookmaker from accidental production, prediction, export, and database side effects.

## 1. Production safety

Forbidden unless explicitly approved:

```text
- SSH to production
- deployment
- docker compose up on production
- production migrations
- production database writes
- production secret inspection
```

Production deployment requires an explicit owner token in the prompt:

```text
OWNER_APPROVED_MVP_V1_PRODUCTION_DEPLOY=true
```

Without that token, production deploy is blocked.

## 2. Prediction / export safety

These must not be written during audits, planning, UI cleanup, schema draft, diagnostics, or local tests:

```text
serving.predictions
ops.export_queue
```

If tables exist, verify no unintended writes.

If tables do not exist locally, report:

```text
serving.predictions: unavailable locally / not touched
ops.export_queue: unavailable locally / not touched
```

## 3. Database safety

Default mode:

```text
read-only
```

DB writes are forbidden unless the task explicitly says:

```text
LOCAL TEST DB WRITES ALLOWED
```

Schema apply is forbidden unless the task explicitly says:

```text
SCHEMA APPLY ALLOWED
```

Production DB writes require separate explicit approval and are never implied.

## 4. SQL safety

Allowed by default:

```text
- SQL draft in docs
- read-only SELECT diagnostics
```

Forbidden by default:

```text
- CREATE TABLE
- ALTER TABLE
- DROP
- DELETE
- UPDATE
- INSERT
- TRUNCATE
- migration execution
```

## 5. Public / Sandbox safety

Do not expose unapproved prediction outputs publicly.

Do not show research-only, candidate, watchlist, or unapproved models in user-facing pages.

Sandbox may use only approved/demo-safe data as explicitly allowed by the task.

## 6. Odds timing safety

For odds / prematch work, use these timing classes:

```text
STRICT_PREMATCH:
captured_at <= kickoff - 60 seconds

CLOSING_ONLY:
kickoff - 60 seconds < captured_at <= kickoff

UNSAFE_IN_PLAY:
captured_at > kickoff

UNKNOWN_TIMING:
missing or untrusted captured_at / kickoff / source metadata
```

Do not treat UNKNOWN_TIMING as safe prematch.

## 7. Owner approval safety

Manual owner approval is required for:

```text
- model bundle promotion
- Sandbox approved model output
- public approved model output
- production deploy
- production DB changes
- any automatic promotion path
```

Automatic promotion is forbidden.
