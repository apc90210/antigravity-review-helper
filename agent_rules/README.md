# .agents — Antigravity Agent Instructions

This directory contains permanent operating instructions for Antigravity / coding agents.

Use it as a project-level behavior model.

Recommended placement:

```powershell
C:\bookmaker-modhub\.agents\
C:\bookmaker-modhub\AGENTS.md
```

Every new agent prompt should include:

```text
Before starting, read AGENTS.md and all referenced .agents instructions.
Follow them strictly.
If this task conflicts with AGENTS.md, stop and report the conflict.
```

Main workflow:

1. Split / Dispatch
2. Worker implementation
3. Acceptance audit
4. Controlled integration
5. Post-merge verification

Default rule:

```text
Do not merge. Do not deploy. Do not write to production. Do not use git add .
```
