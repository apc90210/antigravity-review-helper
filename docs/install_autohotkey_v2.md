# AutoHotkey v2 Installation Guide

This utility requires **AutoHotkey v2** to run.

## Requirements
- **OS**: Windows 10 or later.
- **AutoHotkey**: Version 2.0 or higher.

## Installation Steps
1. Visit the [AutoHotkey Download Page](https://www.autohotkey.com/).
2. Download and install the **v2** version.
3. Verify installation by running `AutoHotkey64.exe` or by right-clicking on an `.ahk` script and selecting "Run script".

## Important Notes for Developers
- This script is currently being tested in a environment where AutoHotkey v2 is not natively available for shell execution.
- **Runtime testing cannot be performed without a local installation of AutoHotkey v2.**
- When running the script for the first time after installation:
    - Ensure **DRY_RUN_MODE** is checked (enabled by default).
    - Verify that the helper correctly identifies your IDE windows.
    - Test the **LIMITS** warning popup by triggering one of the detection phrases (e.g. typing "quota exhausted" in a test file).

## Safety First
Always perform your first tests in **Dry Run Mode** to verify that button detection and sanitization are working as expected for your specific screen resolution and scaling settings.
