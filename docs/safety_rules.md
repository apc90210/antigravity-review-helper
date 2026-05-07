# Safety Rules (v4)

The helper includes multiple layers of protection to ensure data privacy and operational safety.

## 1. Data Privacy & Sanitization
The **Debug Viewer** captures text from target windows.
- **Redaction**: A built-in sanitizer scans for patterns like `password=`, `token:`, `Bearer`, etc.
- **Local Only**: No data is ever sent over the network or uploaded to any service.
- **Clipboard Safety**: Original clipboard content is saved before automated captures and restored immediately after reading.
- **Sanitized Storage**: Snapshots and logs only contain redacted text.

## 2. Limits Alert Protection
To prevent unnecessary actions when the target system is overwhelmed or limited:
- **Auto-Detection**: Scans for "quota exhausted", "rate limit", and similar warnings.
- **Blinking Alert**: Visually warns the user and **pauses all automatic clicks** for the affected window.
- **Manual Override**: Requires user interaction to clear the alert and resume automation.

## 3. Boundary & Title Enforcement
- **Window Boundaries**: Clicks are strictly confined to the bounding box of the selected IDE window.
- **Title Blocklist**: Windows with sensitive titles (e.g., "password", "browser", "ssh") are automatically ignored.

## 4. Language & UI Safety
- **English Only**: All UI elements are in English to ensure clear communication and avoid confusion.
- **Safety Briefing**: Requires user confirmation before the script starts.
- **Dry Run by Default**: Real clicks are disabled on startup.

## 5. Operational Guards
- **Rate Limits**: 1 click/sec, 20 clicks/min.
- **Emergency Stop**: **Ctrl + Alt + Esc** kills the process immediately.
- **Log Audit**: Every action, detection, and alert is recorded in `logs/antigravity_review_helper.log`.
