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

## Testing Limits Alert
1. Ensure **Limits Alert Monitor** is checked.
2. Simulate a limit warning (e.g., by typing "quota exhausted" in an open text file within the IDE).
3. Verify:
   - Does the red blinking **LIMITS** window appear?
   - Does the helper log `LIMIT_WARNING_DETECTED_UIA_TEXT`?
   - Does the alert window correctly identify the target window?
   - Try the **Clear Alert** and **Stop This Window** buttons.

## Testing Manual Capture (Ctrl+Alt+D)
1. Select the IDE window.
2. Press **Ctrl + Alt + D**.
3. If the "Copy debug info" button is visible, the helper should log its detection.
4. If not, it should fall back to UIA or clipboard capture.

## Switching to Live Mode
Only after you have verified consistent detection and sanitization:
1. Uncheck **DRY RUN MODE** in the GUI.
2. Verify that the helper now performs real clicks on "Copy debug info" (and "Retry"/"Continue") while maintaining sanitization.
