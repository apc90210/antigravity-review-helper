# Dry-Run Testing Guide (v2)

Dry-Run Mode is essential for ensuring that your button screenshots and window coordinates are correctly configured before allowing real clicks.

## How to Test
1. Ensure **DRY RUN MODE** is checked in the GUI (top right).
2. Select your IDE window and check **Enabled** and **Retry Auto** (or other actions).
3. Click **Start Selected**.
4. Observe the tooltips and logs:
   - Tooltips will show: `DRY RUN: Detected [Action] at [X,Y]`.
   - Logs will record: `DRY_RUN_[ACTION]_DETECTED`.

## Verification Checklist
- [ ] Is the button detected within the correct window boundaries?
- [ ] Are coordinates (X, Y) centered on the button?
- [ ] Does the helper correctly skip minimized windows?
- [ ] Does it stop detecting when you move the mouse?
- [ ] Does it skip windows with "Terminal" or "Password" in the title?

## Switching to Live Mode
Only after you have verified consistent detection without false positives:
1. Uncheck **DRY RUN MODE** in the GUI.
2. Note that `DRY_RUN_MODE` in the script file is still `true` by default; you can change this in the `.ahk` file permanently once fully validated.
