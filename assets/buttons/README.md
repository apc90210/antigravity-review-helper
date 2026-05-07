# Button Screenshot Instructions

For the helper to detect buttons, you must provide clear screenshots of them.

## File Requirements
Save images in this folder with these exact names:
- `retry_button.png`
- `continue_button.png`
- `accept_button.png`

## Best Practices for Screenshots
1. **Resolution**: Take screenshots on the same monitor resolution where they will be used.
2. **Crop Tight**: Crop the image so it contains only the button text/background. Avoid including extra surrounding UI elements.
3. **Format**: Must be 24-bit or 32-bit PNG.
4. **Consistency**: Use the default VS Code / Antigravity theme if possible, as changes in background color (due to themes) may break ImageSearch.

## Troubleshooting
If a button is not being detected:
- Ensure the screenshot doesn't have transparency.
- Check if the button has a hover effect that changes its color; try taking the screenshot of the button in its "normal" (non-hovered) state.
