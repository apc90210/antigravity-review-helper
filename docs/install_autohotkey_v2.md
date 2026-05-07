# AutoHotkey v2 Installation Instructions

The Antigravity Review Helper requires AutoHotkey v2.0 or higher. Since it is not currently detected on this system, please follow these steps to install it manually.

## 1. Download
Visit the official AutoHotkey website:
[https://www.autohotkey.com/](https://www.autohotkey.com/)
Download the **v2.0** installer (e.g., `AutoHotkey_2.0.x_setup.exe`).

## 2. Installation
1. Run the downloaded installer.
2. Choose the default installation options.
3. Ensure that `.ahk` files are associated with AutoHotkey v2.

## 3. Verification
Once installed, you can verify the installation by running this command in PowerShell:
```powershell
where.exe AutoHotkeyUX.exe
```
Or simply double-click the script in `scripts/antigravity_review_helper.ahk`.

## Note on Runtime Testing
The script has been developed and syntax-verified against AutoHotkey v2 standards, but it **cannot be runtime-tested** until the interpreter is installed. Once installed, follow the `docs/dry_run_testing.md` guide to validate the logic.
