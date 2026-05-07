#Requires AutoHotkey v2.0
#SingleInstance Force

; ==============================================================================
; SCRIPT SELF-CHECK & QUICK REFERENCE
; ==============================================================================
; - DRY_RUN_MODE: true (Safety: Enabled by default)
; - SAFETY_CONFIRMATION_REQUIRED: true (Shows startup briefing)
; - ACCEPT BUTTON: MANUAL ONLY BY DEFAULT
; - DEBUG VIEWER: Triggered on Retry detection or Ctrl+Alt+D
; - EMERGENCY EXIT: Ctrl+Alt+Esc
; ==============================================================================

; ==============================================================================
; CONFIGURATION & SAFETY SETTINGS
; ==============================================================================

global DRY_RUN_MODE := true
global SAFETY_CONFIRMATION_REQUIRED := true

; Global state
global WindowConfigs := Map() ; hwnd -> Object
global ClickTimestamps := []
global MAX_CLICKS_PER_SEC := 1
global MAX_CLICKS_PER_MIN := 20
global ALLOWED_TITLES := ["Antigravity", "Visual Studio Code", "Cursor"]
global FORBIDDEN_TITLES := ["terminal", "powershell", "cmd", "password", "credentials", "ssh", "git", "browser", "chrome", "edge"]

; Redaction Patterns
global REDACT_PATTERNS := [
    "i)(password|passwd|pwd)[:=\s]+[^\s]+",
    "i)(token|api_key|apikey|secret|private_key|ssh|bearer|authorization|cookie|session)[:=\s]+[^\s]+",
    "i)(DATABASE_URL|POSTGRES_PASSWORD|DJANGO_SECRET_KEY|OPENAI_API_KEY|ANTHROPIC_API_KEY|GOOGLE_API_KEY)[:=\s]+[^\s]+"
]

; Asset Paths
global ASSET_DIR := A_ScriptDir "\..\assets\buttons\"
global RETRY_IMG := ASSET_DIR "retry_button.png"
global CONTINUE_IMG := ASSET_DIR "continue_button.png"
global ACCEPT_IMG := ASSET_DIR "accept_button.png"
global LOG_FILE := A_ScriptDir "\..\logs\antigravity_review_helper.log"
global SNAPSHOT_DIR := A_ScriptDir "\..\debug_snapshots\"

; Mouse tracking
global LastMouseX := 0, LastMouseY := 0
MouseGetPos(&LastMouseX, &LastMouseY)

; ==============================================================================
; INITIALIZATION & GUI
; ==============================================================================

if (SAFETY_CONFIRMATION_REQUIRED)
{
    msg := "Antigravity Review Helper v3 (Debug Viewer) Safety Briefing:`n`n"
    msg .= "- Debug text is SANITIZED (redacted) before display/save.`n"
    msg .= "- No network access or external file reading.`n"
    msg .= "- Retry detection triggers auto debug capture.`n"
    msg .= "- Ctrl+Alt+D: Manual debug capture.`n`n"
    msg .= "Proceed?"
    if (MsgBox(msg, "Safety Audit", "YesNo Iconi") = "No")
        ExitApp()
}

MyGui := Gui("+Resize", "Antigravity Review Helper v3")
MyGui.SetFont("s9", "Segoe UI")

; Window List
MyGui.Add("Text", "x10 y10", "Detected Windows:")
LV := MyGui.Add("ListView", "x10 y30 w600 h120", ["HWND", "Status", "Title"])
LV.OnEvent("Click", OnLVClick)

; Configuration Pane
MyGui.Add("GroupBox", "x10 y160 w600 h100", "Selected Window Configuration")
chkEnabled := MyGui.Add("Checkbox", "x20 y180 vEnabled", "Enabled")
chkAlwaysOn := MyGui.Add("Checkbox", "x120 y180 vAlwaysOn", "Always On")
chkRetry := MyGui.Add("Checkbox", "x220 y180 vRetryAuto", "Retry Auto")
chkContinue := MyGui.Add("Checkbox", "x320 y180 vContinueAuto", "Continue Auto")
chkAcceptManual := MyGui.Add("Checkbox", "x420 y180 vAcceptManual", "Accept Manual")
chkAcceptAuto := MyGui.Add("Checkbox", "x20 y210 vAcceptAuto", "Accept All (Auto)")
chkAcceptAuto.OnEvent("Click", OnAcceptAutoClick)

btnStart := MyGui.Add("Button", "x20 y230 w90", "Start")
btnStart.OnEvent("Click", (*) => SetWindowStatus("Running"))
btnStop := MyGui.Add("Button", "x120 y230 w90", "Stop")
btnStop.OnEvent("Click", (*) => SetWindowStatus("Stopped"))
btnAcceptOnce := MyGui.Add("Button", "x220 y230 w120", "Accept Once")
btnAcceptOnce.OnEvent("Click", OnAcceptOnceClick)

; Debug Viewer Panel
MyGui.Add("GroupBox", "x10 y270 w600 h220", "Debug Viewer")
txtDebugInfo := MyGui.Add("Text", "x20 y290 w580", "No window selected.")
editDebugText := MyGui.Add("Edit", "x20 y310 w580 h130 ReadOnly Multi", "")
btnRefreshDebug := MyGui.Add("Button", "x20 y450 w100", "Refresh Debug")
btnRefreshDebug.OnEvent("Click", (*) => OnManualDebugCapture())
btnCopyDebug := MyGui.Add("Button", "x130 y450 w120", "Copy Sanitized")
btnCopyDebug.OnEvent("Click", OnCopySanitized)
btnClearDebug := MyGui.Add("Button", "x260 y450 w100", "Clear Debug")
btnClearDebug.OnEvent("Click", (*) => (editDebugText.Value := "", txtDebugInfo.Value := "Debug cleared."))
btnSaveSnapshot := MyGui.Add("Button", "x370 y450 w150", "Save Sanitized Snapshot")
btnSaveSnapshot.OnEvent("Click", OnSaveSnapshot)

; Global Controls
MyGui.Add("GroupBox", "x10 y500 w600 h60", "Global Controls")
btnRefresh := MyGui.Add("Button", "x20 y520 w100", "Refresh List")
btnRefresh.OnEvent("Click", RefreshWindowList)
chkDryRun := MyGui.Add("Checkbox", "x130 y525 vDryRunChecked", "DRY RUN MODE")
chkDryRun.Value := DRY_RUN_MODE
chkDryRun.OnEvent("Click", (ctrl, *) => (global DRY_RUN_MODE := ctrl.Value))
btnStopAll := MyGui.Add("Button", "x250 y520 w100", "Stop All")
btnStopAll.OnEvent("Click", StopAll)

MyGui.Add("Text", "x10 y570 cGray", "Emergency: Ctrl+Alt+Esc | Debug Capture: Ctrl+Alt+D")
MyGui.Show()

RefreshWindowList()

; ==============================================================================
; GUI EVENTS & HELPERS
; ==============================================================================

OnLVClick(LV, RowNumber)
{
    if (RowNumber = 0) return
    hwnd := LV.GetText(RowNumber, 1)
    if (!WindowConfigs.Has(hwnd)) return
    
    config := WindowConfigs[hwnd]
    chkEnabled.Value := config.Enabled
    chkAlwaysOn.Value := config.AlwaysOn
    chkRetry.Value := config.RetryAuto
    chkContinue.Value := config.ContinueAuto
    chkAcceptManual.Value := config.AcceptManual
    chkAcceptAuto.Value := config.AcceptAuto
    
    title := WinGetTitle("ahk_id " hwnd)
    txtDebugInfo.Value := "Target: " title " (HWND: " hwnd ")"

    ; Re-bind events to current config
    chkEnabled.OnEvent("Click", (ctrl, *) => (config.Enabled := ctrl.Value))
    chkAlwaysOn.OnEvent("Click", (ctrl, *) => (config.AlwaysOn := ctrl.Value))
    chkRetry.OnEvent("Click", (ctrl, *) => (config.RetryAuto := ctrl.Value))
    chkContinue.OnEvent("Click", (ctrl, *) => (config.ContinueAuto := ctrl.Value))
    chkAcceptManual.OnEvent("Click", (ctrl, *) => (config.AcceptManual := ctrl.Value))
}

OnAcceptAutoClick(ctrl, *)
{
    RowNumber := LV.GetNext()
    if (RowNumber = 0) { ctrl.Value := 0; return }
    hwnd := LV.GetText(RowNumber, 1)
    config := WindowConfigs[hwnd]
    if (ctrl.Value = 1) {
        if (MsgBox("Accept All can approve changes automatically. Continue?", "DANGER", "YesNo Icon!") = "No") {
            ctrl.Value := 0; config.AcceptAuto := 0
        } else config.AcceptAuto := 1
    } else config.AcceptAuto := 0
}

SetWindowStatus(newStatus) {
    RowNumber := LV.GetNext()
    if (RowNumber = 0) return
    hwnd := LV.GetText(RowNumber, 1)
    if (WindowConfigs.Has(hwnd)) {
        WindowConfigs[hwnd].Status := newStatus
        LV.Modify(RowNumber, , , newStatus)
    }
}

StopAll(*) {
    for hwnd, config in WindowConfigs
        config.Status := "Stopped"
    Loop LV.GetCount()
        LV.Modify(A_Index, , , "Stopped")
}

RefreshWindowList(*) {
    LV.Delete()
    oldConfigs := WindowConfigs.Clone()
    WindowConfigs.Clear()
    for hwnd in WinGetList() {
        title := WinGetTitle(hwnd)
        isMatch := false
        for pattern in ALLOWED_TITLES {
            if (InStr(title, pattern)) { isMatch := true; break }
        }
        if (isMatch) {
            config := {Enabled: 0, AlwaysOn: 0, RetryAuto: 0, ContinueAuto: 0, AcceptManual: 1, AcceptAuto: 0, Status: "Stopped", LastAcceptX: 0, LastAcceptY: 0, LastRetryTime: ""}
            if (oldConfigs.Has("" hwnd)) config := oldConfigs["" hwnd]
            WindowConfigs["" hwnd] := config
            LV.Add("", hwnd, config.Status, title)
        }
    }
}

OnAcceptOnceClick(*) {
    RowNumber := LV.GetNext()
    if (RowNumber = 0) return
    hwnd := LV.GetText(RowNumber, 1)
    config := WindowConfigs["" hwnd]
    if (config.LastAcceptX > 0) {
        DoClick(hwnd, config.LastAcceptX, config.LastAcceptY, "AcceptOnce")
        config.LastAcceptX := 0; config.LastAcceptY := 0
    } else MsgBox("No Accept button detected recently.")
}

OnCopySanitized(*) {
    if (editDebugText.Value != "") {
        A_Clipboard := editDebugText.Value
        ToolTip("Sanitized debug copied to clipboard.")
        SetTimer () => ToolTip(), -2000
    }
}

OnSaveSnapshot(*) {
    RowNumber := LV.GetNext()
    if (RowNumber = 0 or editDebugText.Value = "") return
    hwnd := LV.GetText(RowNumber, 1)
    timestamp := FormatTime(, "yyyyMMdd_HHmmss")
    filename := SNAPSHOT_DIR timestamp "_" hwnd "_retry_debug.txt"
    try {
        FileAppend(editDebugText.Value, filename)
        LogAction(hwnd, "DEBUG_SNAPSHOT_SAVED", 0, 0, filename)
        MsgBox("Snapshot saved: " filename)
    } catch {
        MsgBox("Failed to save snapshot.")
    }
}

; ==============================================================================
; DEBUG CAPTURE LOGIC
; ==============================================================================

OnManualDebugCapture()
{
    RowNumber := LV.GetNext()
    if (RowNumber = 0) return
    hwnd := LV.GetText(RowNumber, 1)
    CaptureDebugForWindow(hwnd, "MANUAL")
}

CaptureDebugForWindow(hwnd, triggerType := "AUTO")
{
    LogAction(hwnd, "DEBUG_CAPTURE_ATTEMPTED", 0, 0, triggerType)
    debugText := ""
    method := "NONE"

    ; Method A: Basic Accessible Text (UIA Lite)
    ; In many standard Windows apps, this works. For Electron, it's limited.
    try {
        debugText := WinGetText("ahk_id " hwnd)
        if (StrLen(debugText) > 50) method := "UIA_LITE"
    }

    ; Method B: Clipboard Fallback (If manual or if auto failed)
    if (method = "NONE" and triggerType = "MANUAL")
    {
        msg := "Debug text is not accessible automatically.`n`nPlease select/copy the debug text in the target window, then click OK to import."
        if (MsgBox(msg, "Manual Capture", "Iconi OkCancel") = "OK")
        {
            debugText := A_Clipboard
            method := "CLIPBOARD"
        }
    }

    if (method != "NONE")
    {
        sanitized := SanitizeDebug(debugText)
        editDebugText.Value := sanitized
        txtDebugInfo.Value := "Last Capture: " FormatTime(, "HH:mm:ss") " | Method: " method
        LogAction(hwnd, "DEBUG_CAPTURED_" method, 0, 0, "Length: " StrLen(sanitized))
    }
    else
    {
        editDebugText.Value := "DEBUG_CAPTURE_NOT_AVAILABLE`nMethod A failed. Use Ctrl+Alt+D for manual clipboard fallback."
        LogAction(hwnd, "DEBUG_CAPTURE_NOT_AVAILABLE", 0, 0, "")
    }
}

SanitizeDebug(text)
{
    for pattern in REDACT_PATTERNS
    {
        text := RegExReplace(text, pattern, "$1=[REDACTED]")
    }
    return text
}

; ==============================================================================
; HOTKEYS
; ==============================================================================

^!esc:: ExitApp()

^!d:: OnManualDebugCapture()

^!a::
{
    hwnd := WinActive("A")
    if (WindowConfigs.Has("" hwnd)) {
        config := WindowConfigs["" hwnd]
        if (config.LastAcceptX > 0) {
            DoClick(hwnd, config.LastAcceptX, config.LastAcceptY, "AcceptHotkey")
            config.LastAcceptX := 0; config.LastAcceptY := 0
        }
    }
}

; ==============================================================================
; MAIN SCAN LOOP
; ==============================================================================

SetTimer(MainLoop, 1000)

MainLoop()
{
    for hwndStr, config in WindowConfigs
    {
        hwnd := Number(hwndStr)
        if (!config.Enabled or (config.Status != "Running" and !config.AlwaysOn)) continue
        if (!WinExist("ahk_id " hwnd)) { config.Status := "Not Found"; continue }
        if (WinGetMinMax("ahk_id " hwnd) = -1) continue

        title := WinGetTitle("ahk_id " hwnd)
        isForbidden := false
        for f in FORBIDDEN_TITLES {
            if (InStr(title, f)) { isForbidden := true; break }
        }
        if (isForbidden) continue

        global LastMouseX, LastMouseY
        currX := 0, currY := 0
        MouseGetPos(&currX, &currY)
        if (currX != LastMouseX or currY != LastMouseY) {
            LastMouseX := currX, LastMouseY := currY
            continue
        }

        x := 0, y := 0, w := 0, h := 0
        WinGetPos(&x, &y, &w, &h, "ahk_id " hwnd)

        ; Prioritize Accept
        if (ScanForButton(ACCEPT_IMG, x, y, x+w, y+h, &foundX, &foundY)) {
            config.LastAcceptX := foundX, config.LastAcceptY := foundY
            if (config.AcceptAuto) DoClick(hwnd, foundX, foundY, "AcceptAuto")
            else if (config.AcceptManual) LogAction(hwnd, "ACCEPT_WAITING_MANUAL_APPROVAL", foundX, foundY, "")
            continue
        }

        ; Retry -> Trigger Debug Capture
        if (ScanForButton(RETRY_IMG, x, y, x+w, y+h, &foundX, &foundY)) {
            LogAction(hwnd, "RETRY_DETECTED", foundX, foundY, "")
            CaptureDebugForWindow(hwnd, "AUTO")
            if (config.RetryAuto) DoClick(hwnd, foundX, foundY, "Retry")
            continue
        }

        ; Continue
        if (config.ContinueAuto and ScanForButton(CONTINUE_IMG, x, y, x+w, y+h, &foundX, &foundY)) {
            DoClick(hwnd, foundX, foundY, "Continue")
        }
    }
}

ScanForButton(imgPath, x1, y1, x2, y2, &foundX, &foundY)
{
    if (!FileExist(imgPath)) return false
    CoordMode "Pixel", "Screen"
    if ImageSearch(&foundX, &foundY, x1, y1, x2, y2, "*50 " imgPath) {
        foundX += 10; foundY += 10; return true
    }
    return false
}

DoClick(hwnd, clickX, clickY, type)
{
    WinGetPos(&winX, &winY, &winW, &winH, "ahk_id " hwnd)
    if (clickX < winX or clickX > winX+winW or clickY < winY or clickY > winY+winH) {
        LogAction(hwnd, "SKIPPED_OUTSIDE_WINDOW", clickX, clickY, type); return
    }
    if (!CheckRateLimit(hwnd)) return
    if (DRY_RUN_MODE) {
        LogAction(hwnd, "DRY_RUN_" type "_DETECTED", clickX, clickY, "Dry Run"); return
    }
    CoordMode "Mouse", "Screen"
    Click(clickX, clickY)
    LogAction(hwnd, "CLICKED_" type, clickX, clickY, "Live")
}

CheckRateLimit(hwnd) {
    global ClickTimestamps
    now := A_TickCount
    newTimestamps := []
    for ts in ClickTimestamps {
        if (now - ts < 60000) newTimestamps.Push(ts)
    }
    ClickTimestamps := newTimestamps
    if (ClickTimestamps.Length > 0 and now - ClickTimestamps[ClickTimestamps.Length] < 1000) return false
    if (ClickTimestamps.Length >= MAX_CLICKS_PER_MIN) return false
    ClickTimestamps.Push(now); return true
}

LogAction(hwnd, event, x, y, actionNote) {
    global LOG_FILE
    timestamp := FormatTime(, "yyyy-MM-dd HH:mm:ss")
    title := WinGetTitle("ahk_id " hwnd)
    logLine := timestamp " | " hwnd " | " title " | " event " | " (DRY_RUN_MODE ? "DRY" : "LIVE") " | " x "," y " | " actionNote "`n"
    try { FileAppend(logLine, LOG_FILE) } catch {}
}
