# Antigravity Review Helper v4

A standalone Windows 10 desktop utility to assist with repetitive UI review actions in Antigravity, VS Code, and Cursor.

## Features (v4)
- **LIMITS Warning**: A simple red warning popup appears when usage limits or quotas are detected.
- **Accept All Auto**: Detection and automation for "Accept all" operations (Requires explicit confirmation).
- **Copy Debug Info**: Precise log capture using the official Antigravity debug button.
- **English-Only UI**: Strictly English interface and documentation.
- **Sanitization**: Automatic redaction of sensitive credentials from captured logs.
- **Safety Guards**: Dry-run mode by default, rate limiting, and emergency stop (Ctrl+Alt+Esc).

## Asset Normalization
The helper uses standardized assets with fallbacks:
- **Accept All**: `accept_all_button.png` (Preferred) or `accept_button.png` (Fallback).
- **Enable Overages / Limits**: `enable_overages_button.png` (Preferred) or `limit_warning.png` (Fallback).

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
