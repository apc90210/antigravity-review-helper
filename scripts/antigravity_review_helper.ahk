#Requires AutoHotkey v2.0
#SingleInstance Force

; ==============================================================================
; SCRIPT SELF-CHECK & QUICK REFERENCE
; ==============================================================================
; - DRY_RUN_MODE: true (Safety: Enabled by default)
; - SAFETY_CONFIRMATION_REQUIRED: true (Shows startup briefing)
; - ACCEPT BUTTON: MANUAL ONLY BY DEFAULT
; - DEBUG VIEWER: Triggered on Retry detection or Ctrl+Alt+D
; - LIMITS ALERT: Blinking red alert for usage/quota warnings
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

; Limit Detection Phrases
global LIMIT_PHRASES := [
    "limit", "limits", "usage limit", "limit reached", "reached your limit",
    "quota", "quota exhausted", "rate limit", "maximum usage",
    "try again later", "daily limit", "monthly limit", "exhausted",
    "out of credits", "no credits", "too many requests"
]

; Redaction Patterns
global REDACT_PATTERNS := [
    "i)(password|passwd|pwd|token|api_key|apikey|secret|private_key|ssh|bearer|authorization|cookie|session|DATABASE_URL|POSTGRES_PASSWORD|DJANGO_SECRET_KEY|OPENAI_API_KEY|ANTHROPIC_API_KEY|GOOGLE_API_KEY)(\s*[:=]\s*)([^\s\r\n]+)",
    "i)(Authorization:\s+Bearer\s+)([^\s\r\n]+)"
]

; Asset Paths
global ASSET_DIR := A_ScriptDir "\..\assets\buttons\"
global ALERT_DIR := A_ScriptDir "\..\assets\alerts\"
global RETRY_IMG := ASSET_DIR "retry_button.png"
global CONTINUE_IMG := ASSET_DIR "continue_button.png"
global ACCEPT_IMG := ASSET_DIR "accept_button.png"
global COPY_DEBUG_IMG := ASSET_DIR "copy_debug_info_button.png"
global LIMIT_WARNING_IMG := ALERT_DIR "limit_warning.png"
global LOG_FILE := A_ScriptDir "\..\logs\antigravity_review_helper.log"
global SNAPSHOT_DIR := A_ScriptDir "\..\debug_snapshots\"

; Mouse tracking
global LastMouseX := 0, LastMouseY := 0
MouseGetPos(&LastMouseX, &LastMouseY)

; Alert Window State
global AlertGuis := Map() ; hwnd -> Gui Object
global AlertBlinkState := false

; ==============================================================================
; INITIALIZATION & GUI
; ==============================================================================

if (SAFETY_CONFIRMATION_REQUIRED)
{
    msg := "Antigravity Review Helper v4 (Limits Alert) Safety Briefing:`n`n"
    msg .= "- UI is English-only.`n"
    msg .= "- Debug text is SANITIZED (redacted) before display/save.`n"
    msg .= "- Retry detection can trigger 'Copy debug info' click.`n"
    msg .= "- Limits Alert: Blinking window when usage limits detected.`n"
    msg .= "- No network access or external file reading.`n`n"
    msg .= "Proceed?"
    if (MsgBox(msg, "Safety Audit", "YesNo Iconi") = "No")
        ExitApp()
}

MyGui := Gui("+Resize", "Antigravity Review Helper v4")
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
chkCopyDebugAuto := MyGui.Add("Checkbox", "x220 y210 vCopyDebugAuto", "Copy Debug Info Auto")
chkLimitsMonitor := MyGui.Add("Checkbox", "x420 y210 vLimitsMonitor", "Limits Alert Monitor")

btnStart := MyGui.Add("Button", "x20 y235 w90", "Start")
btnStart.OnEvent("Click", (*) => SetWindowStatus("Running"))
btnStop := MyGui.Add("Button", "x120 y235 w90", "Stop")
btnStop.OnEvent("Click", (*) => SetWindowStatus("Stopped"))
btnAcceptOnce := MyGui.Add("Button", "x220 y235 w120", "Accept Once")
btnAcceptOnce.OnEvent("Click", OnAcceptOnceClick)

; Debug Viewer Panel
MyGui.Add("GroupBox", "x10 y270 w600 h260", "Debug Viewer")
txtDebugInfo := MyGui.Add("Text", "x20 y290 w580", "No window selected.")
txtCaptureStatus := MyGui.Add("Text", "x20 y310 w280", "Capture Status: Idle")
txtRedactionStatus := MyGui.Add("Text", "x310 y310 w280", "Redaction Status: N/A")
editDebugText := MyGui.Add("Edit", "x20 y330 w580 h150 ReadOnly Multi", "")
btnRefreshDebug := MyGui.Add("Button", "x20 y490 w100", "Refresh Debug")
btnRefreshDebug.OnEvent("Click", (*) => OnManualDebugCapture())
btnCopyDebug := MyGui.Add("Button", "x130 y490 w120", "Copy Sanitized")
btnCopyDebug.OnEvent("Click", OnCopySanitized)
btnClearDebug := MyGui.Add("Button", "x260 y490 w100", "Clear Debug")
btnClearDebug.OnEvent("Click", OnClearDebug)
btnSaveSnapshot := MyGui.Add("Button", "x370 y490 w150", "Save Sanitized Snapshot")
btnSaveSnapshot.OnEvent("Click", OnSaveSnapshot)

; Global Controls
MyGui.Add("GroupBox", "x10 y540 w600 h60", "Global Controls")
btnRefresh := MyGui.Add("Button", "x20 y560 w100", "Refresh List")
btnRefresh.OnEvent("Click", RefreshWindowList)
chkDryRun := MyGui.Add("Checkbox", "x130 y565 vDryRunChecked", "DRY RUN MODE")
chkDryRun.Value := DRY_RUN_MODE
chkDryRun.OnEvent("Click", (ctrl, *) => (global DRY_RUN_MODE := ctrl.Value))
btnStopAll := MyGui.Add("Button", "x250 y560 w100", "Stop All")
btnStopAll.OnEvent("Click", StopAll)

MyGui.Add("Text", "x10 y610 cGray", "Emergency: Ctrl+Alt+Esc | Debug Capture: Ctrl+Alt+D")
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
    chkCopyDebugAuto.Value := config.CopyDebugAuto
    chkLimitsMonitor.Value := config.LimitsMonitor
    
    title := WinGetTitle("ahk_id " hwnd)
    txtDebugInfo.Value := "Target: " title " (HWND: " hwnd ")"
    txtCaptureStatus.Value := "Last Detection: " (config.LastRetryTime ? config.LastRetryTime : "None")
    txtRedactionStatus.Value := "Redaction Status: " (config.LastCaptureStatus ? config.LastCaptureStatus : "Idle")
    editDebugText.Value := config.CapturedText ? config.CapturedText : ""

    ; Re-bind events to current config
    chkEnabled.OnEvent("Click", (ctrl, *) => (config.Enabled := ctrl.Value))
    chkAlwaysOn.OnEvent("Click", (ctrl, *) => (config.AlwaysOn := ctrl.Value))
    chkRetry.OnEvent("Click", (ctrl, *) => (config.RetryAuto := ctrl.Value))
    chkContinue.OnEvent("Click", (ctrl, *) => (config.ContinueAuto := ctrl.Value))
    chkAcceptManual.OnEvent("Click", (ctrl, *) => (config.AcceptManual := ctrl.Value))
    chkCopyDebugAuto.OnEvent("Click", (ctrl, *) => (config.CopyDebugAuto := ctrl.Value))
    chkLimitsMonitor.OnEvent("Click", (ctrl, *) => (config.LimitsMonitor := ctrl.Value))
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
    for hwnd, config in WindowConfigs {
        config.Status := "Stopped"
        if (config.AlertActive) ClearAlert(hwnd)
    }
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
            config := {Enabled: 0, AlwaysOn: 0, RetryAuto: 0, ContinueAuto: 0, AcceptManual: 1, AcceptAuto: 0, CopyDebugAuto: 0, LimitsMonitor: 1, Status: "Stopped", LastAcceptX: 0, LastAcceptY: 0, LastRetryTime: "", LastCaptureStatus: "Idle", CapturedText: "", AlertActive: false, LastLimitLog: 0}
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
    if (config.AlertActive) {
        MsgBox("Actions paused due to active Limits Alert.")
        return
    }
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

OnClearDebug(*) {
    RowNumber := LV.GetNext()
    if (RowNumber = 0) return
    hwnd := LV.GetText(RowNumber, 1)
    config := WindowConfigs["" hwnd]
    config.CapturedText := ""
    config.LastCaptureStatus := "Cleared"
    editDebugText.Value := ""
    txtRedactionStatus.Value := "Redaction Status: Cleared"
    LogAction(hwnd, "DEBUG_CLEARED", 0, 0, "")
}

OnSaveSnapshot(*) {
    RowNumber := LV.GetNext()
    if (RowNumber = 0 or editDebugText.Value = "") return
    hwnd := LV.GetText(RowNumber, 1)
    timestamp := FormatTime(, "yyyyMMdd_HHmmss")
    filename := SNAPSHOT_DIR timestamp "_" hwnd "_retry_debug.txt"
    try {
        if (!DirExist(SNAPSHOT_DIR)) DirCreate(SNAPSHOT_DIR)
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
    if (RowNumber = 0) {
        hwnd := WinActive("A")
        if (!WindowConfigs.Has("" hwnd)) {
            MsgBox("Please select a target window in the list first.")
            return
        }
    } else {
        hwnd := LV.GetText(RowNumber, 1)
    }
    CaptureDebugForWindow(hwnd, "MANUAL")
}

CaptureDebugForWindow(hwnd, triggerType := "AUTO")
{
    LogAction(hwnd, "DEBUG_CAPTURE_ATTEMPTED", 0, 0, triggerType)
    config := WindowConfigs["" hwnd]
    
    ; Part 1: Primary Method - "Copy debug info" button
    x := 0, y := 0, w := 0, h := 0
    WinGetPos(&x, &y, &w, &h, "ahk_id " hwnd)
    if (ScanForButton(COPY_DEBUG_IMG, x, y, x+w, y+h, &foundX, &foundY)) {
        LogAction(hwnd, "COPY_DEBUG_INFO_BUTTON_DETECTED", foundX, foundY, triggerType)
        CaptureDebugViaCopyButton(hwnd, foundX, foundY, triggerType)
        return
    }

    ; Fallback to existing methods
    debugText := ""
    method := "NONE"

    try {
        debugText := WinGetText("ahk_id " hwnd)
        controls := WinGetControls("ahk_id " hwnd)
        for ctrl in controls {
            if (RegExMatch(ctrl, "i)Debug|Output|Error|Console|Logs|Problems|Terminal")) {
                ctrlText := ControlGetText(ctrl, "ahk_id " hwnd)
                if (ctrlText != "" and !InStr(debugText, ctrlText)) {
                    debugText .= "`n--- Control: " ctrl " ---`n" ctrlText
                }
            }
        }
        if (StrLen(debugText) > 20) method := "UIA_LITE"
    }

    if (method = "NONE" and triggerType = "MANUAL")
    {
        oldClip := ClipboardAll()
        A_Clipboard := ""
        msg := "Debug text is not accessible automatically.`n`nSelect/copy the debug text in the target window, then click OK to import."
        if (MsgBox(msg, "Manual Capture", "Iconi OkCancel") = "OK")
        {
            if (ClipWait(2)) {
                debugText := A_Clipboard
                method := "CLIPBOARD"
                if (MsgBox("Confirm this text came from the selected window?`n`n" SubStr(debugText, 1, 100) "...", "Confirm Source", "YesNo") = "No") {
                    debugText := ""
                    method := "NONE"
                }
            }
        }
        A_Clipboard := oldClip
    }

    UpdateDebugViewer(hwnd, debugText, method)
}

CaptureDebugViaCopyButton(hwnd, foundX, foundY, triggerType)
{
    config := WindowConfigs["" hwnd]
    if (DRY_RUN_MODE) {
        LogAction(hwnd, "DRY_RUN_COPY_DEBUG_INFO_DETECTED", foundX, foundY, triggerType)
        UpdateDebugViewer(hwnd, "COPY_DEBUG_INFO_BUTTON detected but not clicked (DRY RUN).", "DRY_RUN")
        return
    }

    oldClip := ClipboardAll()
    A_Clipboard := ""
    
    LogAction(hwnd, "COPY_DEBUG_INFO_CLICKED", foundX, foundY, triggerType)
    CoordMode "Mouse", "Screen"
    Click(foundX, foundY)
    
    if (ClipWait(3)) {
        debugText := A_Clipboard
        LogAction(hwnd, "DEBUG_CLIPBOARD_READ", 0, 0, "Length: " StrLen(debugText))
        UpdateDebugViewer(hwnd, debugText, "COPY_BUTTON")
    } else {
        LogAction(hwnd, "DEBUG_CLIPBOARD_EMPTY", 0, 0, "")
        UpdateDebugViewer(hwnd, "DEBUG_CLIPBOARD_EMPTY after button click.", "NONE")
    }
    
    A_Clipboard := oldClip
}

UpdateDebugViewer(hwnd, text, method)
{
    config := WindowConfigs["" hwnd]
    if (method != "NONE") {
        sanitized := SanitizeDebug(text)
        config.CapturedText := sanitized
        config.LastCaptureStatus := "Sanitized (" method ")"
        config.LastRetryTime := FormatTime(, "yyyy-MM-dd HH:mm:ss")
        LogAction(hwnd, "DEBUG_CAPTURED_" method, 0, 0, "Length: " StrLen(sanitized))
    } else {
        config.LastCaptureStatus := "DEBUG_CAPTURE_NOT_AVAILABLE"
        config.CapturedText := "DEBUG_CAPTURE_NOT_AVAILABLE"
        LogAction(hwnd, "DEBUG_CAPTURE_NOT_AVAILABLE", 0, 0, "")
    }
    
    ; Update UI if selected
    RowNumber := LV.GetNext()
    if (RowNumber > 0 && LV.GetText(RowNumber, 1) = "" hwnd) {
        editDebugText.Value := config.CapturedText
        txtCaptureStatus.Value := "Last Capture: " config.LastRetryTime
        txtRedactionStatus.Value := "Redaction Status: " config.LastCaptureStatus
    }
}

SanitizeDebug(text)
{
    for pattern in REDACT_PATTERNS
        text := RegExReplace(text, pattern, "$1$2[REDACTED]")
    return text
}

; ==============================================================================
; LIMITS ALERT LOGIC
; ==============================================================================

ScanForLimits(hwnd)
{
    config := WindowConfigs["" hwnd]
    if (!config.LimitsMonitor) return false

    method := "NONE"
    matchInfo := ""

    ; Method A: UIA Text Scan
    try {
        text := WinGetText("ahk_id " hwnd)
        for phrase in LIMIT_PHRASES {
            if (InStr(text, phrase)) {
                method := "UIA_TEXT"
                matchInfo := phrase
                break
            }
        }
    }

    ; Method B: Image Detection Fallback
    if (method = "NONE" and FileExist(LIMIT_WARNING_IMG)) {
        WinGetPos(&x, &y, &w, &h, "ahk_id " hwnd)
        if (ScanForButton(LIMIT_WARNING_IMG, x, y, x+w, y+h, &fX, &fY)) {
            method := "IMAGE"
        }
    }

    if (method != "NONE") {
        if (!config.AlertActive) {
            config.AlertActive := true
            LogAction(hwnd, "LIMIT_WARNING_DETECTED_" method, 0, 0, matchInfo)
            OpenAlertWindow(hwnd, method, matchInfo)
        } else if (A_TickCount - config.LastLimitLog > 10000) {
            config.LastLimitLog := A_TickCount
            LogAction(hwnd, "LIMIT_WARNING_STILL_ACTIVE", 0, 0, matchInfo)
        }
        return true
    }
    return false
}

OpenAlertWindow(targetHwnd, method, matchInfo)
{
    title := WinGetTitle("ahk_id " targetHwnd)
    
    AlertGui := Gui("+AlwaysOnTop -MinimizeBox +Owner" MyGui.Hwnd, "Antigravity Review Helper - Limits Alert")
    AlertGui.BackColor := "Red"
    AlertGui.SetFont("s24 w700", "Segoe UI")
    AlertGui.Add("Text", "Center w400 cWhite", "LIMITS")
    AlertGui.SetFont("s10 w400", "Segoe UI")
    AlertGui.Add("Text", "Center w400 cWhite", "Target: " title "`nMethod: " method (matchInfo ? " (" matchInfo ")" : ""))
    
    btnStopThis := AlertGui.Add("Button", "w100 h30 x20", "Stop This")
    btnStopThis.OnEvent("Click", (*) => (StopThisWindow(targetHwnd), AlertGui.Destroy()))
    
    btnStopAll := AlertGui.Add("Button", "w100 h30 x130 yp", "Stop All")
    btnStopAll.OnEvent("Click", (*) => (StopAll(), AlertGui.Destroy()))
    
    btnClear := AlertGui.Add("Button", "w100 h30 x240 yp", "Clear Alert")
    btnClear.OnEvent("Click", (*) => (ClearAlert(targetHwnd), AlertGui.Destroy()))
    
    btnOpenMain := AlertGui.Add("Button", "w100 h30 x350 yp", "Main UI")
    btnOpenMain.OnEvent("Click", (*) => MyGui.Show())

    AlertGuis["" targetHwnd] := AlertGui
    AlertGui.Show("w450 h200")
    SoundBeep(750, 500)
    
    LogAction(targetHwnd, "LIMIT_ALERT_OPENED", 0, 0, method)
}

StopThisWindow(hwnd) {
    if (WindowConfigs.Has("" hwnd)) {
        WindowConfigs["" hwnd].Status := "Stopped"
        ClearAlert(hwnd)
        RefreshWindowList() ; Update LV
        LogAction(hwnd, "LIMIT_ALERT_STOP_THIS_WINDOW", 0, 0, "")
    }
}

ClearAlert(hwnd) {
    if (WindowConfigs.Has("" hwnd)) {
        WindowConfigs["" hwnd].AlertActive := false
        if (AlertGuis.Has("" hwnd)) {
            try AlertGuis["" hwnd].Destroy()
            AlertGuis.Delete("" hwnd)
        }
        LogAction(hwnd, "LIMIT_ALERT_CLEARED", 0, 0, "")
    }
}

; Blinking Timer
SetTimer(BlinkAlerts, 500)
BlinkAlerts() {
    global AlertBlinkState
    AlertBlinkState := !AlertBlinkState
    for hwnd, alertGui in AlertGuis {
        try alertGui.BackColor := AlertBlinkState ? "Red" : "Maroon"
    }
}

; Periodic Beep Timer
SetTimer(AlertBeep, 10000)
AlertBeep() {
    if (AlertGuis.Count > 0) SoundBeep(500, 200)
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
        if (config.AlertActive) return
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

        ; Global pause for active alerts on this window
        if (config.AlertActive) continue

        ; Check for Limits
        if (ScanForLimits(hwnd)) {
            continue ; Stop processing this window if limit detected
        }

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
            
            ; Auto Capture Logic
            if (config.CopyDebugAuto) {
                CaptureDebugForWindow(hwnd, "AUTO")
            } else {
                LogAction(hwnd, "DEBUG_AUTO_CAPTURE_DISABLED", 0, 0, "")
            }

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
    config := WindowConfigs["" hwnd]
    if (config.AlertActive) {
        LogAction(hwnd, "SKIPPED_LIMIT_ALERT_ACTIVE", clickX, clickY, type)
        return
    }

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
