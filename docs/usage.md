# Usage Guide (v3 Debug Viewer)

## Starting the Helper
1. Run `scripts/antigravity_review_helper.ahk`.
2. Accept the **Safety Briefing** (note the section on data sanitization).

## Using the Debug Viewer
The Debug Viewer panel displays information related to errors and logs in your target windows.

### Automatic Capture
- When the helper detects a **Retry** button, it automatically attempts to read the visible text from that window.
- If successful, the sanitized text appears in the text box.

### Manual Capture
If the automatic capture cannot read the text (common in Electron-based apps like VS Code):
1. Go to your IDE window.
2. Select the error/debug text and copy it (`Ctrl+C`).
3. Press **Ctrl + Alt + D** or click **Refresh Debug** in the helper.
4. The helper will import the clipboard content, redact any secrets, and display it.

### Sanitization and Copying
- All text shown in the GUI is already **Sanitized**.
- Click **Copy Sanitized** to put the safe version into your clipboard.
- Click **Save Sanitized Snapshot** to create a `.txt` file in the `debug_snapshots/` folder.

## Action Settings
- **Retry Auto**: Enable to auto-click "Retry". Capture happens before the click.
- **Continue Auto**: Enable to auto-click "Continue".
- **Accept Manual**: Use **Ctrl+Alt+A** to approve.
- **Accept All (Auto)**: Dangerous mode, requires confirmation.

## Emergency Exit
- Press **Ctrl + Alt + Esc** at any time to immediately kill the script.
