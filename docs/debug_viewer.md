# Debug Viewer Guide (v4)

The Debug Viewer is a diagnostic tool that automatically captures error messages and output logs when a "Retry" button is detected in a monitored window.

## Capture Methods

The helper uses a prioritized system to retrieve debug text:

### 1. "Copy debug info" Button (Primary)
In Antigravity, there is often a button labeled **Copy debug info**.
- **Automatic**: If **Copy Debug Info Auto** is enabled, the helper will find and click this button when a Retry occurs.
- **Manual**: Pressing **Ctrl + Alt + D** or clicking **Refresh Debug** will first look for this button.
- **Clipboard Handling**: The helper saves your existing clipboard, clicks the button, reads the new content, and restores your old clipboard.

### 2. UI Automation (Fallback)
If the button is not found, the helper attempts to read accessible text directly from the target window (panes like "Output", "Debug Console", etc.).

### 3. Clipboard Fallback
If both automated methods fail, the helper provides a manual fallback:
1. Select the error text in your IDE.
2. Copy it (`Ctrl+C`).
3. Click **OK** in the helper's confirmation dialog (triggered by manual capture).

## Security & Privacy (Redaction)
Debug logs often contain sensitive information. The helper automatically passes all captured text through a **Sanitizer** before it is displayed or saved.
- **Redacted Items**: Passwords, API Keys, Tokens, SSH Keys, Database URLs, and Authorization headers.
- **Redaction Marker**: Sensitive values are replaced with `[REDACTED]`.

## Snapshots
You can save a record of the debug text by clicking **Save Sanitized Debug Snapshot**.
- **Location**: `debug_snapshots/`.
- **Privacy**: Unsanitized debug text is **never** saved to disk or logged to the main system log.

## Why OCR is Not Used
Optical Character Recognition (OCR) is intentionally avoided to ensure data privacy and reduce system overhead. The helper relies on direct button interaction and text-based accessibility.
