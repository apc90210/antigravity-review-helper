# Manual Antigravity Button Testing

This document outlines the steps for manually validating the Antigravity Review Helper's automation logic against real Antigravity windows.

## Safety First
- **Dry Run Mode** is enabled by default. Always verify detection in Dry Run first.
- **Accept All Auto** is extremely powerful and should be used with extreme caution.
- **Enable Overages** is NEVER clicked automatically; the helper only provides an alert.

## Testing Steps

### 1. Launch and Initialize
1. Run the helper (via source AHK or TEST EXE).
2. Confirm the **Safety Briefing**.
3. Verify that **Global Dry Run Mode** is CHECKED.

### 2. Window Selection
1. Click **Refresh List**.
2. Identify your target Antigravity project in the list.
   - Confirm the **Project/Workspace** column shows the correct folder name.
   - Confirm the **Title** matches the expected window.
3. Select the row. The helper will NOT monitor unselected windows.

### 3. Dry Run Validation (Recommended)
1. Enable the desired action (e.g., **Retry Auto**).
2. Click **Start Selected**.
3. Perform an action in Antigravity that triggers the button (e.g., cause a failure to show Retry).
4. Wait for the helper to detect the button.
5. Check `logs\antigravity_review_helper.log`. You should see a `DRY_RUN_RETRY_DETECTED` (or similar) entry.
6. Verify that **NO REAL CLICK** occurred.

### 4. Live Testing
1. If Dry Run detection was successful, you may choose to test live clicks.
2. Uncheck **Global Dry Run Mode**.
3. Confirm the **DANGER** dialog. The status bar will turn RED.
4. Ensure only the specific action you want to test is enabled.
5. Click **Start Selected**.
6. The helper will now perform real clicks inside the selected window only.
7. **Immediately** click **Stop Selected** or use **Ctrl+Alt+S** to pause after the test.

### 5. Limits Detection
1. To test Limits detection, cause a limit reached state or use a fixture.
2. The helper should display a full-screen-width **RED ALERT** with the text **LIMITS**.
3. Click **OK** to dismiss the alert and resume monitoring.

## Emergency Controls
- **Ctrl+Alt+Esc**: Immediately terminates the helper.
- **Ctrl+Alt+S**: Toggles Pause/Resume for monitoring.
- **Stop All**: Stops monitoring for all windows.

## Warning
- **Live Mode** performs real mouse clicks. Ensure your cursor is not obstructed.
- Do not use the computer for other tasks while live automation is active in a foreground window.

## Troubleshooting

### Error: Target window not found
**Cause**: The target Antigravity window was closed or reloaded, and the helper is trying to access an old window handle (HWND).

**Fix**:
1. Ensure you are running version **v0.2.1-stale-hwnd-fix** or newer (check the window title).
2. If this error appears in an older version, the helper may crash.
3. In v0.2.1+, the helper will show a friendly message instead of crashing.
4. Click **Stop Selected** or **Stop All** in the helper.
5. Click **Refresh List** to detect the new window handles.
6. Select the correct project/window from the list again.
7. Click **Start Selected**.

### "Accept All" visible but not detected
If the button is visible in Antigravity but not logged in the helper:
1. Verify the correct row is selected in the window list.
2. Wait for a detection entry in the log while monitoring is active.
3. Ensure the window is not minimized or partially obscured.
4. If detection fails consistently, recapture `accept_button.png` from your screen at 100% scale and replace the file in `assets/buttons/`.

### Manual Testing Recommendations
- **First Live Test**: It is recommended to test **Retry Auto** as your first live action.
- **Accept All**: Only enable live Accept All after you have seen `DRY_RUN_ACCEPT_ALL_DETECTED` multiple times in the logs and understand the operational risk.

### Helper Status shows "Stopped" automatically
**Cause**: The helper detected that the monitored window is no longer available and automatically stopped monitoring to prevent a crash.

**Fix**: Same as "Target window not found" above.
