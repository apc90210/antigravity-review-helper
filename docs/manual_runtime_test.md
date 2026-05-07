# Manual Runtime Test Checklist

Use this checklist to validate the helper after installation. **Always test in Dry Run mode first.**

---

## Prerequisites

- [ ] Windows 10 or Windows 11
- [ ] AutoHotkey v2 installed — [download here](https://www.autohotkey.com/)
- [ ] Repository cloned or copied to `C:\antigravity-review-helper`
- [ ] `assets\buttons\` contains: `retry_button.png`, `copy_debug_info_button.png`, `accept_button.png`
- [ ] `assets\alerts\` contains: `limit_warning.png`

---

## Step 1 — Launch

- [ ] Run the helper:

```powershell
& "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe" "C:\antigravity-review-helper\scripts\antigravity_review_helper.ahk"
```

- [ ] **Safety Briefing dialog** appears — read it carefully
- [ ] Click **Yes** to proceed (or No to abort safely)

---

## Step 2 — GUI Validation

- [ ] Main GUI window opens titled **"Antigravity Review Helper v4"**
- [ ] **Dry Run Mode checkbox** is checked (ON) — blue status label at bottom
- [ ] Status label reads: `Helper: RUNNING | Dry Run: ON`
- [ ] Accept All Auto checkbox is **unchecked** (OFF)
- [ ] Copy Debug Info Auto checkbox is **unchecked** (OFF)
- [ ] Limits Alert Monitor checkbox is **checked** (ON)

---

## Step 3 — Monitoring Toggle (Ctrl+Alt+S)

- [ ] Press `Ctrl+Alt+S`
- [ ] Status label changes to: `Helper: PAUSED | Dry Run: ON`
- [ ] A tooltip shows: `Helper Monitoring: PAUSED`
- [ ] **Dry Run status does NOT change** — still shows `ON`
- [ ] Press `Ctrl+Alt+S` again
- [ ] Status label returns to: `Helper: RUNNING | Dry Run: ON`

---

## Step 4 — Emergency Exit (Ctrl+Alt+Esc)

- [ ] Press `Ctrl+Alt+Esc`
- [ ] Helper closes immediately with no dialog
- [ ] Relaunch to continue testing

---

## Step 5 — Window Targeting

- [ ] Click **Refresh List**
- [ ] Verify Antigravity, VS Code, or Cursor windows appear in the list
- [ ] Select a window row — per-window config checkboxes populate
- [ ] Confirm Accept All Auto is OFF for the selected window

---

## Step 6 — Retry Detection (Dry Run)

- [ ] Enable the selected window (check **Enabled**)
- [ ] Click **Start Selected**
- [ ] Navigate to Antigravity and trigger a Retry button appearance
- [ ] Verify in `logs\antigravity_review_helper.log`:
  - `RETRY_DETECTED` logged ✅
  - `DRY_RUN_Retry_DETECTED` logged ✅ (no real click)
- [ ] Confirm **no real click occurred** in the Antigravity window

---

## Step 7 — Copy Debug Info Detection (Dry Run)

- [ ] With Retry visible, enable **Copy Debug Info Auto** for the window
- [ ] Verify in logs:
  - `DRY_RUN_COPY_DEBUG_INFO_DETECTED` logged ✅
  - Debug Viewer shows: `COPY_DEBUG_INFO_BUTTON detected but not clicked (DRY RUN)`
- [ ] Confirm **no real click occurred**

---

## Step 8 — Accept All Detection (Dry Run)

- [ ] Trigger an Accept All button in Antigravity
- [ ] Verify in logs:
  - `ACCEPT_WAITING_MANUAL_APPROVAL` logged (Accept Auto is OFF)
  - Or if Accept Auto is ON (after confirmation): `DRY_RUN_ACCEPT_ALL_DETECTED` logged ✅
- [ ] Confirm **no real click occurred**

---

## Step 9 — LIMITS / Enable Overages Detection

- [ ] Trigger a LIMITS condition (usage limit phrase in Antigravity window text)
- [ ] Verify red **LIMITS popup** appears immediately
- [ ] Verify popup has **only an OK button** — no "Enable Overages" click
- [ ] Click OK to dismiss
- [ ] Verify in logs: `LIMIT_POPUP_OPENED` and `LIMIT_POPUP_CLOSED`
- [ ] Verify **Enable Overages was never clicked**

---

## Step 10 — Dry Run Confirmation

- [ ] Review the full log at `logs\antigravity_review_helper.log`
- [ ] Every click-type event should be prefixed with `DRY_RUN_`
- [ ] No event should show `CLICKED_` (which would indicate a real click)
- [ ] Confirm: **DRY_RUN_MODE remained ON throughout the entire test**

---

## Final Sign-Off

| Check | Result |
|---|---|
| Safety briefing appeared | ☐ Pass / ☐ Fail |
| GUI opened correctly | ☐ Pass / ☐ Fail |
| Dry Run ON by default | ☐ Pass / ☐ Fail |
| Ctrl+Alt+S toggles monitoring only | ☐ Pass / ☐ Fail |
| Ctrl+Alt+S did NOT change Dry Run | ☐ Pass / ☐ Fail |
| Ctrl+Alt+Esc exits cleanly | ☐ Pass / ☐ Fail |
| Retry detected in logs | ☐ Pass / ☐ Fail |
| No real Retry click occurred | ☐ Pass / ☐ Fail |
| LIMITS popup fired (OK only) | ☐ Pass / ☐ Fail |
| Enable Overages never clicked | ☐ Pass / ☐ Fail |
| All log events show DRY_RUN_ prefix | ☐ Pass / ☐ Fail |

> ✅ Only proceed to live mode after ALL checks pass with DRY_RUN_MODE ON.
