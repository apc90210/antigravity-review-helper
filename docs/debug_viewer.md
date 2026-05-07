# Debug Viewer Guide

The Debug Viewer is a diagnostic tool that automatically captures error messages and output logs when a "Retry" button is detected in a monitored window.

## How it Works

### 1. Automatic Capture
When the helper detects a "Retry" button in an enabled target window, it immediately attempts to capture the debug information associated with that failure.
- **Log Entry**: `RETRY_DETECTED` followed by `DEBUG_CAPTURE_ATTEMPTED`.
- **Display**: The captured text is displayed in the **Debug Viewer** panel of the helper GUI.

### 2. Capture Methods
The helper uses a prioritized system to retrieve debug text:
- **Method A (UI Automation)**: Attempts to read accessible text directly from the target window (panes like "Output", "Debug Console", etc.). 
  - *Note*: This method may be limited depending on the IDE's accessibility support.
- **Method B (Clipboard Fallback)**: If automatic capture fails, you can manually select the error text in your IDE, copy it (`Ctrl+C`), and then press **Ctrl+Alt+D** in the helper.

### 3. Manual Refresh
You can trigger a debug capture at any time for the selected window by:
- Pressing **Ctrl + Alt + D**.
- Clicking the **Refresh Debug** button in the Debug Viewer panel.

## Security & Privacy (Redaction)
Debug logs often contain sensitive information. The helper automatically passes all captured text through a **Sanitizer** before it is displayed or saved.
- **Redacted Items**: Passwords, API Keys, Tokens, SSH Keys, Database URLs, and Authorization headers.
- **Redaction Marker**: Sensitive values are replaced with `[REDACTED]`.

## Snapshots
You can save a permanent record of the debug text by clicking **Save Sanitized Debug Snapshot**.
- **Location**: `debug_snapshots/`.
- **Format**: Sanitized plain text file.
- **Privacy**: Unsanitized debug text is **never** saved to disk or logged to the main system log.

## Why OCR is Not Used
Optical Character Recognition (OCR) is intentionally avoided in this version to ensure data privacy and reduce system overhead. The helper relies on text-based accessibility and user-confirmed clipboard data.
