# Dry-Run Testing Guide (v3)

Dry-Run Mode is essential for ensuring that your button screenshots, window coordinates, and debug capture logic are correctly configured.

## How to Test Debug Capture
1. Ensure **DRY RUN MODE** is checked.
2. Select your IDE window and enable it.
3. Trigger a "Retry" button appearance in the IDE.
4. Verify:
   - Does the helper log `RETRY_DETECTED`?
   - Does the **Debug Viewer** update its text?
   - Is the text correctly **Sanitized** (look for `[REDACTED]`)?
   - Does the GUI show the correct HWND and capture method?

## How to Test Clicks (Dry)
1. Trigger a "Continue" or "Retry" button.
2. Observe the tooltips and logs:
   - Tooltips will show: `DRY RUN: Detected [Action] at [X,Y]`.
   - Logs will record: `DRY_RUN_[ACTION]_DETECTED`.
3. **No real click should happen.**

## Manual Capture Test
1. Select text in any window.
2. Press **Ctrl + Alt + D**.
3. Verify that the sanitized text appears in the Debug Viewer.

## Switching to Live Mode
Only after you have verified consistent detection and sanitization:
1. Uncheck **DRY RUN MODE** in the GUI.
2. Verify that the helper now performs real clicks (preceded by debug capture for Retry events).
