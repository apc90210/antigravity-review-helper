# Window Targeting Guide (v4)

The Antigravity Review Helper allows you to precisely control which windows are monitored and what actions are allowed for each.

## English-Only UI
The helper and its configuration interface are strictly in **English**. This ensures consistency across all monitored environments.

## Window Detection
The helper automatically scans for windows with titles containing:
- **Antigravity**
- **Visual Studio Code**
- **Cursor**

Click **Refresh List** in the GUI to update the list of detected windows.

## Per-Window Configuration
For every detected window, you can configure the following options:

### 1. Enabled
- Master switch for the specific window.

### 2. Always On
- If checked, the helper scans the window continuously.

### 3. Retry Auto
- Automatically clicks the "Retry" button when detected.

### 4. Copy Debug Info Auto
- **OFF by default**.
- If enabled, the helper will automatically find and click the "Copy debug info" button when a Retry is detected to capture precise logs.

### 5. Limits Alert Monitor
- **ON by default**.
- Monitors the window for usage limits and quota warnings.

### 6. Continue Auto
- Automatically clicks the "Continue" button when detected.

### 7. Accept Manual / Accept Auto
- Handles "Accept" button detection and automated approvals.

## Limits Alert Safety
If a limit warning is detected in a window, all automatic actions (Retry, Copy Debug, etc.) are **paused** for that window until the alert is cleared by the user.

## Click Constraints
- The target window must be **visible** and **not minimized**.
- The click coordinates must be **inside the bounding box** of the specific window.
- The window title must not contain forbidden terms (e.g., "password").
