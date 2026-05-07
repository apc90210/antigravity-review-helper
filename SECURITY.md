# Security Policy

## Project Security Rules

This project is a **local Windows 10 desktop utility**. The following rules are mandatory and must never be bypassed.

---

### Windows Defender

- **Do not disable Windows Defender** to build or run this project.
- **Do not add broad Defender exclusions** for this project or its directories.
- If Defender warns about any file in this project, **stop and investigate** before proceeding.
- The EXE build was intentionally deferred after Defender warned during Ahk2Exe installation.

---

### Source Repository Safety

- **Do not commit `dist/`** — build artifacts are gitignored.
- **Do not commit EXE, DLL, ZIP, MSI, or any binary** to this repository.
- **Do not commit `logs/*.log`** — log files are gitignored.
- **Do not commit `debug_snapshots/`** — snapshot files are gitignored.
- **Do not commit `.env`, `*.pem`, `*.key`, or any credential file**.
- **Do not commit tokens, SSH keys, or browser cookies**.

The `.gitignore` in this repository enforces all of the above.

---

### Runtime Safety

- **Dry Run is ON by default** (`DRY_RUN_MODE := true`) — the helper logs detections but performs **no real mouse clicks** until explicitly disabled by the user.
- **Accept All Auto is OFF by default** — enabling it requires an explicit confirmation dialog per window. It is a dangerous setting and should only be enabled after dry-run validation.
- **Copy Debug Info Auto is OFF by default** — debug capture is triggered manually or via Retry detection only.
- **Enable Overages is never clicked automatically** — detecting an "Enable Overages" or LIMITS state opens a red warning popup (OK only). No click is ever performed on overages controls.
- **Debug content is sanitized** before display or saving — all passwords, tokens, API keys, and other credentials are redacted using regex patterns.
- **Rate limiting** is enforced: max 1 click/second, max 20 clicks/minute.
- **Window allowlist** — the helper only interacts with windows titled "Antigravity", "Visual Studio Code", or "Cursor".
- **Window blocklist** — the helper refuses to interact with any window titled: terminal, powershell, cmd, password, credentials, ssh, git, browser, chrome, or edge.

---

### Emergency Controls

| Hotkey | Action |
|---|---|
| `Ctrl+Alt+Esc` | Immediately exits the helper |
| `Ctrl+Alt+S` | Pauses/resumes monitoring only — does NOT change Dry Run |

---

### Reporting Issues

This is a private local utility. If you find a safety issue, do not publish it publicly. Review the source code at `scripts\antigravity_review_helper.ahk` directly.
