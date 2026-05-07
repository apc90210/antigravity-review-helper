# Antigravity Review Helper v2

A standalone Windows desktop utility to assist with repetitive UI review actions in Antigravity, VS Code, and Cursor.

## Features (v2)
- **Multi-Window GUI**: Monitor multiple IDE windows simultaneously with independent settings.
- **Per-Window Control**: Enable or disable specific actions (Retry, Continue, Accept) for each window.
- **Auto-Clicking**: Automatically clicks "Retry" and "Continue" buttons when enabled.
- **Dangerous Mode (Accept All)**: Optionally auto-accept changes (requires explicit confirmation).
- **Dry-Run Mode**: Test detection logic without performing any real clicks.
- **Safety Guards**: Click coordinate verification, rate limiting, and forbidden window detection.

## Project Structure
- `scripts/`: Contains the AutoHotkey v2 GUI script.
- `assets/buttons/`: Store button screenshots here for detection.
- `docs/`: Safety rules, usage, and window targeting documentation.
- `logs/`: Detailed operational logs.

## Quick Start
1. Install [AutoHotkey v2](https://www.autohotkey.com/).
2. Capture button screenshots (Retry, Continue, Accept) into `assets/buttons/`.
3. Run `scripts/antigravity_review_helper.ahk`.
4. Use **Refresh List** to detect your IDE windows.
5. Configure the selected window in the GUI and click **Start Selected** or enable **Always On**.

## Hotkeys
- **Ctrl + Alt + A**: Approve "Accept" click for the active IDE window.
- **Ctrl + Alt + Esc**: Emergency Exit (Stops everything).

## Documentation
- [Usage Guide](docs/usage.md)
- [Safety Rules](docs/safety_rules.md)
- [Window Targeting](docs/window_targeting.md)
- [Dry-Run Testing](docs/dry_run_testing.md)
