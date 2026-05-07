# Antigravity Review Helper

A standalone Windows desktop utility to assist with repetitive UI review actions in Antigravity, VS Code, and Cursor.

## Features
- **Auto-Clicking**: Automatically clicks "Retry" and "Continue" buttons when detected.
- **Assisted Accept**: Detects "Accept" buttons and waits for manual hotkey confirmation.
- **Dual Monitor Support**: Scans the full virtual desktop.
- **Safety Guards**: Prevents clicking in sensitive windows (Terminals, Password dialogs) and stops if manual mouse movement is detected.
- **Rate Limiting**: Limits click frequency to prevent unintended behavior.

## Project Structure
- `scripts/`: Contains the AutoHotkey v2 script.
- `assets/buttons/`: Store button screenshots here for detection.
- `docs/`: Safety rules and usage documentation.
- `logs/`: Operational logs.

## Setup Instructions
1. Install [AutoHotkey v2](https://www.autohotkey.com/).
2. Take screenshots of the buttons (Retry, Continue, Accept) and save them in `assets/buttons/`.
   - See `assets/buttons/README.md` for specific instructions.
3. Edit `scripts/antigravity_review_helper.ahk` to adjust screen regions if necessary.
4. Run `scripts/antigravity_review_helper.ahk`.

## Hotkeys
- **Ctrl + Alt + S**: Toggle Helper Enable/Disable.
- **Ctrl + Alt + A**: Approve "Accept" click (when button is detected).
- **Ctrl + Alt + Esc**: Emergency Exit (Stops script).

## Safety and Logs
- Logs are saved in `logs/antigravity_review_helper.log`.
- Review `docs/safety_rules.md` for details on protection mechanisms.
