# Usage Guide

## Running the Helper
1. Ensure AutoHotkey v2 is installed.
2. Double-click `scripts/antigravity_review_helper.ahk`.
3. Check the tray icon to ensure the script is running.

## Enabling/Disabling
- The helper starts in a **Disabled** state by default.
- Press `Ctrl + Alt + S` to enable it.
- A tooltip will appear near the mouse cursor indicating the current state.

## Button Detection
- The script looks for `.png` images in `assets/buttons/`.
- `retry_button.png` -> Auto-clicked.
- `continue_button.png` -> Auto-clicked.
- `accept_button.png` -> Detected, then requires `Ctrl + Alt + A`.

## Handling "Accept"
1. When the helper detects an "Accept" button, it will display a tooltip with the button's coordinates.
2. If you want to click it, press `Ctrl + Alt + A`.
3. The helper will click the button once and clear the detection state.

## Configuration
Open `scripts/antigravity_review_helper.ahk` in a text editor to:
- Adjust the `ALLOWED_REGIONS` coordinates.
- Modify the `RATE_LIMITS`.
- Change the `SCAN_INTERVAL`.
