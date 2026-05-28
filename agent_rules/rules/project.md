---
trigger: always_on
---

Project context:

- Windows environment (PowerShell)
- Python execution via "py"
- Structured project layout (src/, data/, models/, output/)
- Use existing pipelines and do not break them

Data:
- Preserve datasets integrity
- Do not overwrite critical data without reason

Models:
- Integrate into existing pipeline
- Do not duplicate logic

Database:
- Prefer safe updates over destructive operations

Goal:
- Build production-grade sports analytics system
- Focus on actionable outputs (predictions, ROI, signals)