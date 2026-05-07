# Antigravity Review Helper v4

> **Current Status: `v0.1.0-source-only`**  
> Run with AutoHotkey v2 · EXE build deferred · `DRY_RUN_MODE` enabled by default · `Accept All Auto` OFF by default

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

## Current Distribution Mode

> **Source code only — no EXE is distributed.**

The project is currently distributed as **source code** and must be run directly with AutoHotkey v2.

- EXE compilation via Ahk2Exe was **intentionally deferred** after Windows Defender warned during installer download.
- **Do not disable Windows Defender** or add broad exclusions to build this.
- Ahk2Exe compilation may be revisited later in a clean VM, via GitHub Actions, or using verified official artifacts.
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

