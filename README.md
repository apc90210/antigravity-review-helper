# Antigravity Review Helper v3

A standalone Windows desktop utility to assist with repetitive UI review actions in Antigravity, VS Code, and Cursor.

## Features (v3)
- **Multi-Window GUI**: Monitor multiple IDE windows simultaneously with independent settings.
- **Debug Viewer**: Automatically captures error logs and debug output when a "Retry" button is detected.
- **Sanitization**: Automatically redacts sensitive information (passwords, tokens, API keys) from captured debug text.
- **Per-Window Control**: Enable or disable specific actions (Retry, Continue, Accept) for each window.
- **Safety Guards**: Click coordinate verification, rate limiting, forbidden window detection, and dry-run mode.

## Project Structure
- `scripts/`: Contains the AutoHotkey v2 GUI script.
- `assets/buttons/`: Store button screenshots here for detection.
- `debug_snapshots/`: Sanitized debug logs saved by the user.
- `docs/`: Comprehensive documentation.
- `logs/`: Detailed operational logs.

## Quick Start
1. Install [AutoHotkey v2](https://www.autohotkey.com/).
2. Capture button screenshots into `assets/buttons/`.
3. Run `scripts/antigravity_review_helper.ahk`.
4. Use **Refresh List** to detect your IDE windows.
5. Configure your target window and observe the **Debug Viewer** during Retry events.

## Hotkeys
- **Ctrl + Alt + D**: Manually capture debug text for the selected window.
- **Ctrl + Alt + A**: Approve "Accept" click for the active IDE window.
- **Ctrl + Alt + Esc**: Emergency Exit (Stops everything).

## Documentation
- [Usage Guide](docs/usage.md)
- [Debug Viewer Guide](docs/debug_viewer.md)
- [Safety Rules](docs/safety_rules.md)
- [Window Targeting](docs/window_targeting.md)
- [Dry-Run Testing](docs/dry_run_testing.md)
