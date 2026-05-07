# Antigravity Review Helper v4

A standalone Windows desktop utility to assist with repetitive UI review actions in Antigravity, VS Code, and Cursor.

## Features (v4)
- **Limits Alert**: Automatically detects usage limits and quotas, displaying a red blinking alert window and pausing all actions.
- **Copy Debug Info**: Integrates with the Antigravity "Copy debug info" button for precise log capture.
- **Debug Viewer**: Displays sanitized error logs and debug output.
- **Sanitization**: Automatically redacts sensitive information (passwords, tokens, API keys) from captured debug text.
- **English-Only UI**: The entire application and documentation are in English.
- **Per-Window Control**: Enable or disable specific actions (Retry, Continue, Accept, Debug Capture, Limits Monitor) for each window.
- **Safety Guards**: Click coordinate verification, rate limiting, and dry-run mode.

## Project Structure
- `scripts/`: Contains the AutoHotkey v2 GUI script.
- `assets/buttons/`: Store button screenshots here for detection.
- `assets/alerts/`: Store limit warning screenshots here (optional fallback).
- `debug_snapshots/`: Sanitized debug logs saved by the user.
- `docs/`: Comprehensive documentation.
- `logs/`: Detailed operational logs.

## Quick Start
1. Install [AutoHotkey v2](https://www.autohotkey.com/).
2. Capture button screenshots into `assets/buttons/` (see `README.md` in that folder).
3. Run `scripts/antigravity_review_helper.ahk`.
4. Use **Refresh List** to detect your IDE windows.
5. Configure your target window. Note: **Copy Debug Info Auto** is OFF by default.

## Hotkeys
- **Ctrl + Alt + D**: Manually capture debug text (prioritizes "Copy debug info" button).
- **Ctrl + Alt + A**: Approve "Accept" click for the active IDE window.
- **Ctrl + Alt + Esc**: Emergency Exit (Stops everything).

## Documentation
- [Usage Guide](docs/usage.md)
- [Debug Viewer Guide](docs/debug_viewer.md)
- [Limits Alert Guide](docs/limits_alert.md)
- [Safety Rules](docs/safety_rules.md)
- [Window Targeting](docs/window_targeting.md)
- [Dry-Run Testing](docs/dry_run_testing.md)
