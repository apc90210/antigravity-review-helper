# Safety Rules (v3)

The helper includes multiple layers of protection to ensure data privacy and operational safety.

## 1. Data Privacy & Sanitization
The **Debug Viewer** captures text from target windows. To protect sensitive information:
- **Redaction**: A built-in sanitizer scans for patterns like `password=`, `token:`, `Bearer`, etc.
- **Redaction List**: Includes standard secrets and project-specific keys (OpenAI, Anthropic, etc.).
- **Local Only**: No data is ever sent over the network or uploaded to any service.
- **Sanitized Storage**: Snapshots and logs only contain redacted text. Unsanitized data is never written to disk.

## 2. Boundary Enforcement
The helper will **never** click outside the bounding box of the selected IDE window. Even if a button image is found elsewhere on the screen, the click is blocked if it doesn't fall within the window's current rectangle.

## 3. Window Content Safety
The helper will skip any window if its title contains:
- terminal, powershell, cmd (except as a child pane of an IDE)
- password, credentials
- ssh, git
- browser, chrome, edge

## 4. Operational Guards
- **Mouse Movement**: Detection pauses if the user is moving the mouse.
- **Minimized Windows**: The helper ignores windows that are minimized.
- **Rate Limits**: 1 click/sec, 20 clicks/min.
- **Emergency Stop**: **Ctrl + Alt + Esc** kills the process immediately.

## 5. Deployment Safety
- **Dry Run by Default**: Real clicks are disabled when the script starts.
- **Log Audit**: Every detection, click, and debug capture attempt is logged.
