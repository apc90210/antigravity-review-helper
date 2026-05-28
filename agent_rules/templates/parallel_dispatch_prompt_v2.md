# Parallel Dispatch Prompt v2

Before starting, read `AGENTS.md` and all referenced `.agents` instructions.
Also read `.agents/05_prompt_control_protocol.md`.

You are the Dispatch Agent.

## Stage

<STAGE_NAME>

## Goal

<GOAL>

## Current project context

<PROJECT_CONTEXT>

## Known constraints

<CONSTRAINTS>

## Task

Do not implement anything.
Do not modify files.
Do not create a branch.
Do not commit.
Do not push.

Create a parallel execution map for this stage.

Split the stage into independent workstreams.

For each workstream, define:

```text
- Workstream ID
- Name
- Branch name
- Goal
- Scope lock
- Allowed files/directories
- Forbidden files/actions
- Dependencies
- Can run in parallel: yes/no
- Risk level: low/medium/high
- Expected final status
- Required self-checks
- Acceptance criteria
- Recommended tests
- Merge order
```

## Required matrix

Return a table:

| ID | Branch | Scope | Parallel-safe | Depends on | Risk | Final status |
|---|---|---|---:|---|---|---|

## Required output sections

```text
1. Dispatch Summary
2. Parallel Workstream Matrix
3. Workstream Details
4. Sequential-Only Tasks
5. Merge Order
6. Risks
7. Recommended Next Prompts
8. Final Status
```

## Final status

```text
DISPATCH_PLAN_READY_FOR_OWNER_REVIEW
```
