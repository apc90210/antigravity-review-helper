# Safety Rules (v2)

The helper includes multiple layers of protection to prevent accidental or destructive actions.

## 1. Boundary Enforcement
The helper will **never** click outside the bounding box of the selected IDE window. Even if a button image is found elsewhere on the screen, the click is blocked if it doesn't fall within the window's current rectangle.

## 2. Window Content Safety
The helper will skip any window if its title contains:
- terminal, powershell, cmd
- password, credentials
- ssh, git
- browser, chrome, edge

## 3. Accept All Safeguards
- **OFF by default**: Auto-accepting changes is a high-risk operation.
- **Manual Confirmation**: Enabling this mode triggers a warning dialog.
- **Dry Run Priority**: Even if enabled, "Accept All" will only log detections if Dry Run mode is active.

## 4. Operational Guards
- **Mouse Movement**: Detection pauses if the user is moving the mouse.
- **Minimized Windows**: The helper ignores windows that are minimized.
- **Rate Limits**: 1 click/sec, 20 clicks/min.
- **Emergency Stop**: **Ctrl + Alt + Esc** kills the process immediately.

## 5. Deployment Safety
- **Dry Run by Default**: Real clicks are disabled when the script starts.
- **Log Audit**: Every detection, click, and skipped action is logged with high precision (timestamp, HWND, window title, event type).
