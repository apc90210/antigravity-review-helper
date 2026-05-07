# Usage Guide (v4)

## Language Setting
The entire Antigravity Review Helper application is in **English**.

## Limits Warning
If the helper detects an "Enable Overages" button or a usage limit warning:
1. A red **LIMITS** warning popup will appear.
2. The popup is topmost and has only one button: **OK**.
3. All automatic actions for that window are paused while the popup is open.
4. Click **OK** to close the popup and resume monitoring.

## Accept All Auto
- The helper searches for an **Accept all** button using `accept_all_button.png` or `accept_button.png`.
- **Manual Mode**: If detected, it saves the location. Press **Ctrl+Alt+A** or click **Accept All Once** to click it.
- **Auto Mode**: Requires explicit confirmation to enable. Once enabled, it will click the button automatically when detected.

## Action Settings
- **Retry Auto**: Enable to auto-click "Retry".
- **Copy Debug Info Auto**: Enable to allow auto-clicking "Copy debug info" during Retry events (OFF by default).
- **Limits Alert Monitor**: Enable to scan for usage limits (ON by default).
- **Accept All Auto**: Dangerous mode, requires confirmation.

## Continue Auto (Optional)
- Detection for the "Continue" button is skipped if `continue_button.png` is missing.
- The helper logs `CONTINUE_ASSET_MISSING` once if the feature is enabled but the asset is not found.

## Hotkeys
- **Ctrl+Alt+S**: Toggle Monitoring (START/PAUSE). **Does NOT disable Dry Run**. It only pauses or resumes the monitoring logic.
- **Ctrl+Alt+A**: Manual Accept/Accept All (when a button was detected but auto-mode is OFF).
- **Ctrl+Alt+D**: Manual Debug Capture (triggers "Copy debug info" scan).
- **Ctrl+Alt+Esc**: Emergency Exit (instantly closes the application).

## Dry Run Safety
- **Global Dry Run Mode (Safety)**: When checked (default), the helper will log detections but **never** click real buttons.
- To enable live clicks, uncheck the box and accept the **DANGER** confirmation.
- The status bar will turn **RED** and show **LIVE CLICKS ENABLED** when Dry Run is OFF.

