# Button Screenshot Instructions

For the helper to detect buttons, you must provide clear screenshots of them.

## File Requirements (English UI)
All buttons must be captured from an **English** interface. Save images in this folder with these exact names:

1.  `retry_button.png`: The "Retry" button.
2.  `accept_all_button.png` (Preferred) or `accept_button.png`: The "Accept all" button.
3.  `continue_button.png`: The "Continue" button (Optional).
4.  `copy_debug_info_button.png`: The "Copy debug info" button.
5.  `enable_overages_button.png` (Preferred): The "Enable Overages" button (used as a limit indicator).

## Best Practices for Screenshots
1. **Source**: Take the exact screenshots from **Antigravity** / **VS Code**.
2. **Resolution**: Take screenshots on the same monitor resolution where they will be used.
3. **Crop Tight**: Crop the image so it contains ONLY the button text/background. Avoid extra borders, white space, or surrounding UI elements.
4. **No Effects**: Do not capture the button while hovering over it with the mouse, as this often changes its color.
5. **Format**: Must be 24-bit or 32-bit PNG.
6. **Maintenance**: If you change your Windows Display Scaling (e.g., from 100% to 125%) or your VS Code theme, you will likely need to retake these screenshots.

## Current Requirements Status
- [x] `retry_button.png`
- [x] `accept_button.png` (Treated as "Accept all" fallback)
- [x] `copy_debug_info_button.png`
- [ ] `continue_button.png` (Optional)
- [ ] `accept_all_button.png` (Preferred for Accept All)
- [ ] `enable_overages_button.png` (Preferred for Limits)
