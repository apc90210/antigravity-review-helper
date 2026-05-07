# Usage Guide (v4 Limits Alert)

## Language Setting
The entire Antigravity Review Helper application is in **English**. All labels, buttons, and alerts are designed for English-speaking users.

## Starting the Helper
1. Run `scripts/antigravity_review_helper.ahk`.
2. Accept the **Safety Briefing**.

## Using the Debug Viewer
The Debug Viewer panel displays information related to errors and logs in your target windows.

### "Copy debug info" Integration
- If **Copy Debug Info Auto** is ON, the helper will search for the "Copy debug info" button when a Retry is detected.
- If found, it will click the button, read the clipboard, sanitize the text, and display it.
- **Manual Capture (Ctrl+Alt+D)** also prioritizes the "Copy debug info" button.

### Fallback Capture
If the button is not found:
1. The helper attempts to read text via UI Automation (accessible text).
2. If that fails, it prompts for a manual clipboard import (select text -> `Ctrl+C` -> confirm in helper).

## Limits Alert
If the helper detects a usage limit warning (e.g., "reached your limit" or "quota exhausted"):
1. A red blinking **LIMITS** window will open.
2. All automatic actions for that window are paused.
3. You must click **Clear Alert** in the alert window to resume monitoring, or **Stop This Window** to disable it.

## Action Settings
- **Retry Auto**: Enable to auto-click "Retry".
- **Copy Debug Info Auto**: Enable to allow auto-clicking "Copy debug info" during Retry events (OFF by default).
- **Limits Alert Monitor**: Enable to scan for usage limits (ON by default).
- **Accept All (Auto)**: Dangerous mode, requires confirmation.

## Emergency Exit
- Press **Ctrl + Alt + Esc** at any time to immediately kill the script.
