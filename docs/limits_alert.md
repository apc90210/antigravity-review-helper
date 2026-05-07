# Limits Warning Guide

The Limits Warning feature protects your Antigravity usage by detecting when you are close to or have reached your usage limits.

## Detection Methods

1.  **"Enable Overages" Indicator**:
    The helper searches for the "Enable Overages" button (used as a limit indicator) using:
    - `enable_overages_button.png` (Preferred)
    - `limit_warning.png` (Fallback)
    
    **Note**: The helper will **never** click this button automatically.

2.  **UI Automation (Text Scan)**:
    Searches for phrases like `limit reached`, `quota exhausted`, or `rate limit`.

## Warning Popup

When a limit is detected:
- A red topmost popup window appears with the text **LIMITS**.
- **Actions Paused**: All automatic actions for the affected window are paused while the popup is active.
- **English Only**: The popup and all instructions are in English.

## How to Clear
- The popup has only one button: **OK**.
- Clicking **OK** closes the popup and clears the alert state, allowing the helper to resume monitoring.
- If the limit indicator is still visible, the popup may reappear after the next scan.

## Event Logs
- `ENABLE_OVERAGES_DETECTED`: The limit indicator image was found.
- `LIMIT_POPUP_OPENED`: The warning popup was displayed.
- `LIMIT_POPUP_CLOSED`: The user clicked OK.
- `SKIPPED_LIMIT_ALERT_ACTIVE`: An action was skipped because the popup was open.
