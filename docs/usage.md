# Usage Guide (v2 GUI)

## Starting the Helper
1. Run `scripts/antigravity_review_helper.ahk`.
2. Accept the **Safety Briefing**.
3. The main window will appear. By default, **DRY RUN MODE** is checked.

## Window Management
1. Click **Refresh List** to see all Antigravity/VS Code/Cursor windows.
2. Select a window from the list to view its current configuration.
3. **Check "Enabled"** to allow the helper to process that window.
4. Use **Start Selected** to begin monitoring, or check **Always On** for continuous detection.

## Action Settings
- **Retry Auto**: Enable to auto-click "Retry" in the selected window.
- **Continue Auto**: Enable to auto-click "Continue" in the selected window.
- **Accept Manual**: Detects "Accept" buttons. You can click them via:
  - **Ctrl+Alt+A** (when the window is active)
  - The **Accept Once** button in the GUI.
- **Accept All (Auto)**: 
  - **Warning**: This will automatically click "Accept" buttons.
  - Requires confirmation to enable.
  - Useful for bulk reviews in trusted windows.

## Log Management
- View detection results and clicks in `logs/antigravity_review_helper.log`.
- Use **Clear Log** to reset the file.
- Use **Save Log As...** to export a copy for review.

## Emergency Exit
- Press **Ctrl + Alt + Esc** at any time to immediately kill the script.
