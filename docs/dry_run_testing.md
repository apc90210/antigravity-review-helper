# Dry-Run Testing Guide (v4)

Dry-Run Mode is essential for ensuring that your button screenshots, window coordinates, and debug capture logic are correctly configured.

## Testing "Copy debug info"
1. Ensure **DRY RUN MODE** is checked.
2. Check **Copy Debug Info Auto** for your window.
3. Trigger a "Retry" button appearance.
4. Verify:
   - Does the helper log `COPY_DEBUG_INFO_BUTTON_DETECTED`?
   - Does it show `DRY_RUN_COPY_DEBUG_INFO_DETECTED` in the logs?
   - In the Debug Viewer, it should say "detected but not clicked".

## Testing Limits Warning
1. Ensure **Limits Alert Monitor** is checked.
2. Simulate a limit warning (e.g., by typing "quota exhausted" in an open text file within the IDE).
3. Verify:
   - Does the red **LIMITS** popup appear?
   - Does the helper log `LIMIT_WARNING_DETECTED_UIA_TEXT`?
   - Try clicking **OK** and verify the popup closes.

## Testing Accept All Auto
1. Trigger an "Accept all" button appearance.
2. Verify:
   - Does the helper log `DRY_RUN_ACCEPT_ALL_DETECTED`?
   - It should NOT click the button.

## Testing Manual Capture (Ctrl+Alt+D)
1. Select the IDE window.
2. Press **Ctrl + Alt + D**.
3. If the "Copy debug info" button is visible, the helper should log its detection.
4. If not, it should fall back to UIA or clipboard capture.

## Switching to Live Mode
Only after you have verified consistent detection and sanitization:
1. Uncheck **Global Dry Run Mode (Safety)** in the GUI.
2. Accept the safety confirmation dialog ("DANGER: Turning Dry Run OFF allows real clicks").
3. Verify that the helper now performs real clicks.

## Monitoring Pause
- Use **Ctrl+Alt+S** at any time to pause the monitoring loop.
- This is useful if you need to perform manual actions without interference, while keeping the helper loaded.
- Status will show `Helper: PAUSED`.
