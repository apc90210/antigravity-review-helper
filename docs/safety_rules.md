# Safety Rules

The Antigravity Review Helper is designed with several layers of protection to ensure it does not interfere with sensitive operations.

## 1. Restricted Window Titles
The helper will **NOT** click if the active window title contains any of the following:
- terminal
- powershell
- cmd
- password
- credentials
- ssh
- git
- browser
- chrome
- edge

## 2. Allowed Window Titles
The helper will **ONLY** operate if the active window title contains one of:
- Antigravity
- Visual Studio Code
- Cursor

## 3. Manual Intervention Guard
- **Mouse Movement**: If the user is currently moving the mouse manually, the script will skip auto-clicking to avoid "fighting" for control.
- **Emergency Stop**: Pressing `Ctrl + Alt + Esc` immediately terminates the script.

## 4. Rate Limiting
- Maximum **1 click per second**.
- Maximum **20 clicks per minute**.
- These limits prevent the script from getting into an infinite click loop.

## 5. Semi-Automatic "Accept"
- The "Accept" button is **never** clicked automatically.
- It requires a manual `Ctrl + Alt + A` hotkey after detection.

## 6. Region Locks
- The script only scans defined regions on Monitor 1 and Monitor 2.
- It will never click outside these pre-configured boundaries.
