# Release Notes

---

## v0.2.0-test-ready

**Date:** 2026-05-07  
**Distribution:** Source and optional TEST EXE package  
**Platform:** Windows 10 / Windows 11  
**Runtime:** AutoHotkey v2

---

### Overview

Release **v0.2.0-test-ready** hardens window selection and prepares the helper for manual real-world validation. This version introduces project/workspace name targeting and self-window exclusion to ensure the helper only interacts with intended targets.

### Changes

- **Project/Workspace Targeting**: The window list now explicitly shows the project folder name extracted from the window title.
- **Self-Window Exclusion**: The helper now identifies its own window and prevents monitoring it, avoiding infinite loops or self-clicking.
- **Robust Selection**: `Start Selected` now requires an explicit row selection and validates the target window before starting.
- **Manual Test Focus**: Real Antigravity automation tests are delegated to the user. All automated button clicks are disabled by default.
- **Test EXE Package**: Optional compilation for manual testing environments where AHK is not pre-installed.
- **Deterministic Fixtures**: Validated against static image fixtures to ensure consistent detection across different environments.

### Safety Defaults

```
DRY_RUN_MODE          = true   (ON by default)
ACCEPT_ALL_AUTO       = false  (OFF by default)
COPY_DEBUG_INFO_AUTO  = false  (OFF by default)
SELF_EXCLUSION        = active
PROJECT_COLUMN        = visible
```

---


**Date:** 2026-05-07  
**Distribution:** Source code only — no compiled EXE  
**Platform:** Windows 10 / Windows 11  
**Runtime:** [AutoHotkey v2](https://www.autohotkey.com/)

---

### Overview

First public source release of **Antigravity Review Helper** — a local Windows desktop utility for assisting with repetitive UI review actions in the Antigravity AI code review interface, VS Code, and Cursor.

This release is **source-only**. The EXE build was intentionally deferred after Windows Defender issued a warning during the Ahk2Exe compiler installation. No Defender bypass or exclusion was performed.

---

### Features

| Feature | Status |
|---|---|
| GUI window list with per-window configuration | ✅ Included |
| Retry button detection (image-based) | ✅ Included |
| Copy Debug Info button detection | ✅ Included |
| Debug Viewer with sanitized text display | ✅ Included |
| Accept All detection with manual/auto guardrails | ✅ Included |
| Simple red LIMITS popup (OK only) | ✅ Included |
| Enable Overages / Limits phrase detection | ✅ Included |
| Dry Run mode (ON by default) | ✅ Included |
| Emergency exit hotkey (Ctrl+Alt+Esc) | ✅ Included |
| Monitoring toggle (Ctrl+Alt+S) — no Dry Run change | ✅ Included |
| Manual debug capture (Ctrl+Alt+D) | ✅ Included |
| Credential redaction in debug output | ✅ Included |
| Rate limiting (1 click/sec, 20 clicks/min) | ✅ Included |
| Window allowlist / blocklist enforcement | ✅ Included |
| Continue button support | ⏳ Optional asset not bundled |
| EXE build | ⏳ Deferred (Defender warning) |
| Signed release artifact | ⏳ Deferred |

---

### Safety Defaults

```
DRY_RUN_MODE          = true   (ON by default — no real clicks)
ACCEPT_ALL_AUTO       = false  (OFF — requires explicit confirmation)
COPY_DEBUG_INFO_AUTO  = false  (OFF — manual or Retry-triggered only)
ENABLE_OVERAGES       = never  (never clicked automatically)
LIMITS popup          = OK only (no overages click)
```

---

### How to Run

```powershell
& "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe" "C:\antigravity-review-helper\scripts\antigravity_review_helper.ahk"
```

---

### Known Limitations

- Continue button auto-click requires adding `assets\buttons\continue_button.png` manually.
- Accept All uses `accept_button.png` as fallback if `accept_all_button.png` is not present.
- Enable Overages image detection requires `assets\buttons\enable_overages_button.png`.
- No EXE is distributed — AutoHotkey v2 must be installed on the target machine.

---

### Files Changed Since Initial Commit

- `scripts/antigravity_review_helper.ahk` — main source script (AHK v2)
- `assets/buttons/` — button detection images
- `assets/alerts/limit_warning.png` — fallback limits detection image
- `docs/` — full documentation suite
- `README.md` — project overview and run instructions
- `SECURITY.md` — security policy
- `ROADMAP.md` — future plans
- `.gitignore` — hardened to block binaries, logs, secrets, dist
