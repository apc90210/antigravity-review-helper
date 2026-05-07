# Antigravity Review Helper v4

> **Current Status: `v0.2.1-stale-hwnd-fix`**  
> Run with AutoHotkey v2 · Verified TEST EXE build · `DRY_RUN_MODE` enabled by default · Real Antigravity tests are manual only

A standalone Windows 10 desktop utility to assist with repetitive UI review actions in Antigravity, VS Code, and Cursor.

## Features (v4)
- **LIMITS Warning**: A simple red warning popup appears when usage limits or quotas are detected.
- **Accept All Auto**: Detection and automation for "Accept all" operations (Requires explicit confirmation).
- **Copy Debug Info**: Precise log capture using the official Antigravity debug button.
- **English-Only UI**: Strictly English interface and documentation.
- **Sanitization**: Automatic redaction of sensitive credentials from captured logs.
- **Safety Guards**: Dry-run mode by default, rate limiting, and emergency stop (Ctrl+Alt+Esc).
- **Monitoring Toggle**: `Ctrl+Alt+S` starts/pauses the helper without disabling safety.
- **Live Mode Guard**: Disabling Dry Run in GUI requires an explicit safety confirmation.

## Asset Normalization
The helper uses standardized assets with fallbacks:
- **Accept All**: `accept_all_button.png` (Preferred) or `accept_button.png` (Fallback).
- **Enable Overages / Limits**: `enable_overages_button.png` (Preferred) or `limit_warning.png` (Fallback).

## Manual Testing Status
- **Version**: `v0.2.1-stale-hwnd-fix`
- **Release Strategy**: Source and optional TEST EXE package.
- **Manual Delegation**: Real Antigravity automation tests are performed manually by the user to ensure safety.
- **Dry Run**: `DRY_RUN_MODE` is ON by default and must be verified before live testing.

## Current Distribution Mode

> **Official build provided in `dist_test/`.**

The project is currently distributed as **source code** and must be run directly with AutoHotkey v2.

- **TEST EXE is available** in the `dist_test/` folder for manual validation.
- **Do not disable Windows Defender**. The build is verified to work with standard protection.
- Ahk2Exe compilation was performed locally using a verified compiler.
- **Keep `DRY_RUN_MODE = true`** until local dry-run behavior is fully validated on your machine.

### How to Run

```powershell
& "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe" "C:\antigravity-review-helper\scripts\antigravity_review_helper.ahk"
```

Or right-click `scripts\antigravity_review_helper.ahk` → **Run script** (if `.ahk` files are associated with AutoHotkey v2).

## Requirements
- **Windows 10**
- **AutoHotkey v2** ([Installation Guide](docs/install_autohotkey_v2.md))

## Documentation
- [Usage Guide](docs/usage.md)
- [Debug Viewer Guide](docs/debug_viewer.md)
- [Limits Alert Guide](docs/limits_alert.md)
- [Safety Rules](docs/safety_rules.md)
- [Window Targeting](docs/window_targeting.md)
- [Dry-Run Testing](docs/dry_run_testing.md)

