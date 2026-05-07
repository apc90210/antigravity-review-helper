# Window Targeting Guide

The Antigravity Review Helper allows you to precisely control which windows are monitored and what actions are allowed for each.

## Window Detection
The helper automatically scans for windows with titles containing:
- **Antigravity**
- **Visual Studio Code**
- **Cursor**

Click **Refresh Windows** in the GUI to update the list of detected windows.

## Per-Window Configuration
For every detected window, you can configure the following options:

### 1. Enabled
- If unchecked, the helper completely ignores this window.
- This is the primary master switch for a specific window.

### 2. Always On
- If checked, the helper will continuously scan this window as long as the helper is running.
- If unchecked, the window must be manually "Started" using the **Start Selected** button.

### 3. Retry Auto
- Automatically clicks the "Retry" button when detected in this window.
- Requires `DRY_RUN_MODE` to be off for real clicks.

### 4. Continue Auto
- Automatically clicks the "Continue" button when detected in this window.
- Requires `DRY_RUN_MODE` to be off for real clicks.

### 5. Accept Manual
- Detects the "Accept" button and saves its coordinates.
- Allows you to click it by pressing **Ctrl+Alt+A** or the **Accept Once** button in the GUI.

### 6. Accept All / Auto Accept
- **DANGEROUS**: Automatically clicks "Accept" buttons as soon as they are detected.
- This mode is **OFF by default** and requires explicit confirmation.
- Use this only in windows where you are certain all proposed changes are safe.

## Click Constraints
To ensure safety, the helper checks the following before clicking:
- The target window must be **visible** and **not minimized**.
- The click coordinates must be **inside the bounding box** of the specific window.
- The window title must not contain any forbidden terms (e.g., Terminal, Password).

## Handling Multiple Windows
If you have multiple Antigravity or VS Code windows open, they will appear as separate rows in the list. You can enable "Retry Auto" for one window while keeping it "Manual" for another.
