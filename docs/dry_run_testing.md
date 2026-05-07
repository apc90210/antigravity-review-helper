# Dry-Run Testing Guide

Before allowing the helper to perform actual clicks, you must validate its detection logic using Dry-Run Mode.

## 1. Taking Button Screenshots
- Ensure your VS Code / Antigravity theme is the one you intend to use.
- Use a screenshot tool (like Snipping Tool) to capture the **Retry**, **Continue**, and **Accept** buttons.
- Save them as `retry_button.png`, `continue_button.png`, and `accept_button.png` in `assets/buttons/`.
- Crop the images tightly around the button text.

## 2. Starting the Script
- Run `scripts/antigravity_review_helper.ahk`.
- A **Safety Briefing** window will appear. Read it and click "Yes" to proceed.
- By default, `DRY_RUN_MODE` is enabled.

## 3. Enabling the Helper
- Open VS Code or Antigravity.
- Press `Ctrl + Alt + S`.
- You should see a tooltip saying `Helper ENABLED (DRY RUN)`.

## 4. Verifying Detection
- Trigger a situation where one of the buttons appears.
- The helper will detect the button and show a tooltip: `DRY RUN: Detected [Type] at [X,Y]`.
- **No actual click will occur.**

## 5. Reading Logs
- Open `logs/antigravity_review_helper.log`.
- Look for entries starting with `[DRY_RUN_DETECTED]`.
- Verify the coordinates and window titles match your expectations.

## 6. Switching to Live Mode
- Once you are confident that the buttons are detected correctly and no false positives occur in forbidden windows:
- Open `scripts/antigravity_review_helper.ahk` in a text editor.
- Change `global DRY_RUN_MODE := true` to `global DRY_RUN_MODE := false`.
- Reload the script.

## Why "Accept" is Manual-Only
Even when `DRY_RUN_MODE` is false, the "Accept" button will **never** be clicked automatically. The script will detect it and wait for you to press `Ctrl + Alt + A`. This is a critical safety measure to prevent the AI from accepting destructive or unreviewed changes.

## Diagnostics & Troubleshooting

### How to confirm the helper is running
- Check the Windows System Tray (near the clock). You should see a green icon with an "H".
- Right-click the icon to see options like "Reload Script" or "Exit".

### Confirming initial state
- By default, the helper starts **DISABLED**.
- When you first run the script, a **Safety Briefing** popup must appear. If it doesn't, check the logs.

### Confirming Dry-Run Mode
- Press `Ctrl + Alt + S` to enable the helper.
- A tooltip should appear: `Helper ENABLED (DRY RUN)`.
- If it doesn't say `(DRY RUN)`, stop immediately and check the `DRY_RUN_MODE` setting in the script.

### Finding the Log File
- All actions are logged to `logs/antigravity_review_helper.log`.
- Each entry includes a timestamp, action type, coordinates, and the active window title.

### Emergency Stop
- If the script behaves unexpectedly, press **Ctrl + Alt + Esc** to terminate it immediately.
