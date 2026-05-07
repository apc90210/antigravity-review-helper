# Limits Alert Guide

The Limits Alert feature protects your Antigravity usage and prevents unnecessary clicks when rate limits or quotas are reached.

## How it Works

The helper continuously scans selected target windows for limit-related warnings.

### Detection Methods

1.  **UI Automation (Text Scan)**:
    The helper searches for specific phrases in the window text, such as:
    - `limit`, `usage limit`, `limit reached`
    - `quota`, `quota exhausted`
    - `rate limit`, `too many requests`
    - `out of credits`, `no credits`

2.  **Image Detection (Fallback)**:
    If text-based detection fails, the helper looks for `assets/alerts/limit_warning.png`. This is an optional screenshot of the warning area.

## Alert Behavior

When a limit warning is detected:

- **Blinking Alert**: A red blinking topmost window appears with the text **LIMITS**.
- **Auto-Clicking Paused**: All automatic actions (Retry, Continue, Accept) are immediately stopped for the affected window.
- **Audible Beep**: The helper emits a beep every 10 seconds to notify the user.
- **Logging**: The event is recorded as `LIMIT_WARNING_DETECTED`.

## User Actions

The alert window provides several options:

- **Stop This Window**: Sets the target window status to "Stopped" and closes the alert.
- **Stop All**: Stops all monitored windows and closes the alert.
- **Clear Alert**: Acknowledges the warning and resumes monitoring (if detection phrases are still present, the alert may reappear).
- **Main UI**: Brings the main helper window to the front.

## Safety interaction

While a Limits Alert is active, the helper will log `SKIPPED_LIMIT_ALERT_ACTIVE` if it attempts to perform any action on that window. This ensures no clicks are wasted while the system is in a limited state.
