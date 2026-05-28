# Split / Dispatch Prompt Template

You are the Split / Dispatch Agent.

Before starting, read `AGENTS.md` and all referenced `.agents` instructions.

## Stage

<STAGE_NAME>

## Goal

<GOAL>

## Current known context

<CONTEXT>

## Constraints

<CONSTRAINTS>

## Task

Do not implement anything.

Create an execution map that splits this stage into independent workstreams.

For each workstream, specify:

- workstream ID
- branch name
- goal
- allowed files/directories
- forbidden files/actions
- dependency
- can run in parallel: yes/no
- risk level: low/medium/high
- expected final status label
- acceptance criteria
- recommended tests/checks

## Required output format

```text
DISPATCH PLAN

GLOBAL SAFETY RULES

WORKSTREAM MATRIX

WORKSTREAM A
...

WORKSTREAM B
...

SEQUENTIAL-ONLY TASKS

RECOMMENDED LAUNCH ORDER

FINAL STATUS:
DISPATCH_PLAN_READY_FOR_OWNER_REVIEW
```
