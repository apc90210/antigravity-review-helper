# Antigravity Review Helper — Roadmap

## Current Status

| Item | State |
|---|---|
| Version | `v0.1.0-source-only` |
| Distribution | Source code only (AutoHotkey v2 `.ahk` script) |
| Run mode | `AutoHotkey64.exe` → `scripts\antigravity_review_helper.ahk` |
| EXE build | **Deferred** — Windows Defender warned during Ahk2Exe installation |
| Default safety | `DRY_RUN_MODE = true` — no real clicks by default |

---

## Why EXE Build Is Deferred

Windows Defender issued a warning during the download of the **Ahk2Exe** compiler.  
To avoid any security risk:

- No Defender exclusions were added.
- No Defender bypass was performed.
- The EXE build was intentionally skipped for this release.

The project is fully functional as a source-only script run directly via AutoHotkey v2.

---

## How to Run Now

```powershell
& "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe" "C:\antigravity-review-helper\scripts\antigravity_review_helper.ahk"
```

Or right-click `scripts\antigravity_review_helper.ahk` → **Run script**.

---

## v1.0 Goals

### Safety Validation
- [ ] Complete repeated dry-run tests with real Antigravity windows
- [ ] Confirm `Ctrl+Alt+S` pauses/resumes monitoring only (no Dry Run change)
- [ ] Confirm `Ctrl+Alt+Esc` exits cleanly
- [ ] Confirm LIMITS popup fires correctly for all detection phrases
- [ ] Confirm debug text is always sanitized before display/save

### Asset Completion
- [ ] Add optional `continue_button.png` asset for Continue Auto support
- [ ] Capture `accept_all_button.png` from live Antigravity session

### Live Mode
- [ ] Validate Retry Auto in live mode (after dry-run is fully verified)
- [ ] Validate Accept All Auto with explicit user confirmation per window
- [ ] Rate-limit verification (max 1 click/sec, max 20 clicks/min)

### EXE Build (Future)
- [ ] Revisit Ahk2Exe build in a **clean virtual machine**
- [ ] Alternatively build via **GitHub Actions** using verified official Ahk2Exe release
- [ ] Sign or verify the resulting EXE before distribution
- [ ] Release as a ZIP archive (EXE + assets) only after full validation

### v1.0 Release
- [ ] All dry-run tests passing
- [ ] Optional EXE built and verified
- [ ] Release ZIP published on GitHub Releases
- [ ] RELEASE_NOTES.md updated

---

*This roadmap is a living document and will be updated as the project matures.*
