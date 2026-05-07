#Requires AutoHotkey v2.0
#SingleInstance Force

; ==============================================================================
; SCRIPT SELF-CHECK & QUICK REFERENCE
; ==============================================================================
; - DRY_RUN_MODE: true (Safety: Enabled by default)
; - SAFETY_CONFIRMATION_REQUIRED: true (Shows startup briefing)
; - ACCEPT ALL AUTO: OFF BY DEFAULT (Requires explicit confirmation)
; - DEBUG VIEWER: Triggered on Retry detection or Ctrl+Alt+D
; - LIMITS ALERT: Simple red warning popup (English-only)
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

; Tracking missing assets to log only once
global ContinueAssetMissingLogged := false

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

; Assets
global RETRY_IMG := ASSET_DIR "retry_button.png"
global CONTINUE_IMG := ASSET_DIR "continue_button.png"
global COPY_DEBUG_IMG := ASSET_DIR "copy_debug_info_button.png"

; Accept All Assets (Preferred -> Fallback)
global ACCEPT_ALL_IMG := ASSET_DIR "accept_all_button.png"
global ACCEPT_FALLBACK_IMG := ASSET_DIR "accept_button.png"

; Enable Overages / Limit Assets (Preferred -> Fallback)
global ENABLE_OVERAGES_IMG := ASSET_DIR "enable_overages_button.png"
global LIMITS_FALLBACK_IMG := ALERT_DIR "limit_warning.png"

global LOG_FILE := A_ScriptDir "\..\logs\antigravity_review_helper.log"
global SNAPSHOT_DIR := A_ScriptDir "\..\debug_snapshots\"

; Mouse tracking
global LastMouseX := 0, LastMouseY := 0
MouseGetPos(&LastMouseX, &LastMouseY)

; Alert Window State
global AlertGuis := Map() ; hwnd -> Gui Object

; ==============================================================================
; INITIALIZATION & GUI
; ==============================================================================

if (SAFETY_CONFIRMATION_REQUIRED)
{
    msg := "Antigravity Review Helper v4 (Limits Alert) Safety Briefing:`n`n"
    msg .= "- UI is English-only.`n"
    msg .= "- Debug text is SANITIZED (redacted) before display/save.`n"
    msg .= "- Retry detection can trigger 'Copy debug info' click.`n"
    msg .= "- Limits Alert: Warning popup when usage limits detected.`n"
    msg .= "- No network access or external file reading.`n`n"
    msg .= "Proceed?"
    if (MsgBox(msg, "Safety Audit", "YesNo Iconi") = "No")
    {
        ExitApp()
    }
}

MyGui := Gui("+Resize", "Antigravity Review Helper v4")
MyGui.SetFont("s9", "Segoe UI")

; Window List
MyGui.Add("Text", "x10 y10", "Detected Windows:")
global MainLV := MyGui.Add("ListView", "x10 y30 w600 h120", ["HWND", "Status", "Title"])
MainLV.OnEvent("Click", OnLVClick)

; Configuration Pane
MyGui.Add("GroupBox", "x10 y160 w600 h100", "Selected Window Configuration")
chkEnabled := MyGui.Add("Checkbox", "x20 y180", "Enabled")
chkAlwaysOn := MyGui.Add("Checkbox", "x100 y180", "Always On")
chkRetry := MyGui.Add("Checkbox", "x200 y180", "Retry Auto")
chkContinue := MyGui.Add("Checkbox", "x300 y180", "Continue Auto")
chkAcceptManual := MyGui.Add("Checkbox", "x420 y180", "Accept Manual (Prompt)")
chkAcceptAuto := MyGui.Add("Checkbox", "x20 y205 cRed", "Accept All Auto (CAUTION)")
chkAcceptAuto.OnEvent("Click", OnAcceptAutoClick)

chkCopyDebugAuto := MyGui.Add("Checkbox", "x200 y205", "Copy Debug Info Auto")
chkLimitsMonitor := MyGui.Add("Checkbox", "x420 y205 Checked", "Limits Alert Monitor")

; Debug Viewer Panel
MyGui.Add("GroupBox", "x10 y270 w600 h200", "Debug Viewer (Sanitized)")
editDebugText := MyGui.Add("Edit", "x20 y290 w580 h120 ReadOnly vDebugText", "")
txtCaptureStatus := MyGui.Add("Text", "x20 y420 w250", "Last Detection: None")
txtRedactionStatus := MyGui.Add("Text", "x300 y420 w300", "Redaction Status: Idle")
btnRefreshDebug := MyGui.Add("Button", "x20 y440 w100", "Refresh Debug")
btnRefreshDebug.OnEvent("Click", (*) => OnManualDebugCapture())
btnCopyDebug := MyGui.Add("Button", "x130 y440 w100", "Copy Sanitized")
btnCopyDebug.OnEvent("Click", OnCopySanitized)
btnClearDebug := MyGui.Add("Button", "x240 y440 w90", "Clear Debug")
btnClearDebug.OnEvent("Click", OnClearDebug)
btnSaveSnapshot := MyGui.Add("Button", "x340 y440 w150", "Save Sanitized Snapshot")
btnSaveSnapshot.OnEvent("Click", OnSaveSnapshot)

; Global Controls
MyGui.Add("Button", "x10 y480 w100", "Refresh List").OnEvent("Click", RefreshWindowList)
MyGui.Add("Button", "x120 y480 w100", "Start Selected").OnEvent("Click", (*) => UpdateStatus("Running"))
MyGui.Add("Button", "x230 y480 w100", "Stop Selected").OnEvent("Click", (*) => UpdateStatus("Stopped"))
MyGui.Add("Button", "x340 y480 w100", "Stop All").OnEvent("Click", StopAll)
MyGui.Add("Button", "x450 y480 w100", "Clear Log").OnEvent("Click", (*) => FileDelete(LOG_FILE))
MyGui.Add("Button", "x560 y480 w50", "Exit").OnEvent("Click", (*) => ExitApp())

MyGui.Show("w620 h520")
RefreshWindowList()

; ==============================================================================
; GUI EVENTS & HELPERS
; ==============================================================================

OnLVClick(targetLV, RowNumber)
{
    if (RowNumber = 0)
    {
        return
    }
    hwnd := targetLV.GetText(RowNumber, 1)
    if (!WindowConfigs.Has(hwnd))
    {
        return
    }
    config := WindowConfigs[hwnd]

    ; Update Checkboxes
    chkEnabled.Value := config.Enabled
    chkAlwaysOn.Value := config.AlwaysOn
    chkRetry.Value := config.RetryAuto
    chkContinue.Value := config.ContinueAuto
    chkAcceptManual.Value := config.AcceptManual
    chkAcceptAuto.Value := config.AcceptAuto
    chkCopyDebugAuto.Value := config.CopyDebugAuto
    chkLimitsMonitor.Value := config.LimitsMonitor

    ; Update Debug Viewer
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
    RowNumber := MainLV.GetNext()
    if (RowNumber = 0)
    {
        ctrl.Value := 0
        return
    }
    hwnd := MainLV.GetText(RowNumber, 1)
    config := WindowConfigs[hwnd]
    if (ctrl.Value = 1)
    {
        if (MsgBox("Accept All Auto can approve multiple changes automatically. Continue?", "DANGER", "YesNo Icon!") = "No")
        {
            ctrl.Value := 0
            config.AcceptAuto := 0
            LogAction(hwnd, "ACCEPT_ALL_CONFIRMATION_CANCELLED", 0, 0, "")
        }
        else
        {
            config.AcceptAuto := 1
            LogAction(hwnd, "ACCEPT_ALL_CONFIRMATION_ACCEPTED", 0, 0, "")
        }
    }
    else
    {
        config.AcceptAuto := 0
        LogAction(hwnd, "ACCEPT_ALL_AUTO_DISABLED", 0, 0, "")
    }
}

UpdateStatus(newStatus)
{
    RowNumber := MainLV.GetNext()
    if (RowNumber = 0)
    {
        return
    }
    hwnd := MainLV.GetText(RowNumber, 1)
    if (WindowConfigs.Has(hwnd))
    {
        WindowConfigs[hwnd].Status := newStatus
        MainLV.Modify(RowNumber, , , newStatus)
    }
}

StopAll(*)
{
    for hwnd, config in WindowConfigs
    {
        config.Status := "Stopped"
        if (config.AlertActive)
        {
            ClearAlert(hwnd)
        }
    }
    Loop MainLV.GetCount()
    {
        MainLV.Modify(A_Index, , , "Stopped")
    }
}

RefreshWindowList(*)
{
    MainLV.Delete()
    oldConfigs := WindowConfigs.Clone()
    WindowConfigs.Clear()
    for hwnd in WinGetList()
    {
        title := WinGetTitle(hwnd)
        isMatch := false
        for pattern in ALLOWED_TITLES
        {
            if (InStr(title, pattern))
            {
                isMatch := true
                break
            }
        }
        if (isMatch)
        {
            config := {Enabled: 0, AlwaysOn: 0, RetryAuto: 0, ContinueAuto: 0, AcceptManual: 1, AcceptAuto: 0, CopyDebugAuto: 0, LimitsMonitor: 1, Status: "Stopped", LastAcceptX: 0, LastAcceptY: 0, LastRetryTime: "", LastCaptureStatus: "Idle", CapturedText: "", AlertActive: false, LastLimitLog: 0}
            if (oldConfigs.Has("" hwnd))
            {
                config := oldConfigs["" hwnd]
            }
            
            WindowConfigs["" hwnd] := config
            MainLV.Add(, hwnd, config.Status, title)
        }
    }
}

OnAcceptOnceClick(*)
{
    RowNumber := MainLV.GetNext()
    if (RowNumber = 0)
    {
        return
    }
    hwnd := MainLV.GetText(RowNumber, 1)
    config := WindowConfigs["" hwnd]
    
    if (config.AlertActive)
    {
        MsgBox("Actions paused due to active LIMITS warning.")
        return
    }

    if (config.LastAcceptX > 0)
    {
        DoClick(hwnd, config.LastAcceptX, config.LastAcceptY, "AcceptAllOnce")
        config.LastAcceptX := 0
        config.LastAcceptY := 0
    }
    else
    {
        MsgBox("No Accept All button detected recently.")
    }
}

; ==============================================================================
; DEBUG CAPTURE LOGIC
; ==============================================================================

OnManualDebugCapture()
{
    RowNumber := MainLV.GetNext()
    if (RowNumber = 0)
    {
        return
    }
    hwnd := MainLV.GetText(RowNumber, 1)
    CaptureDebugForWindow(hwnd, "MANUAL")
}

CaptureDebugForWindow(hwnd, triggerType)
{
    ; Part 1: Primary Method - "Copy debug info" button
    WinGetPos(&x, &y, &w, &h, "ahk_id " hwnd)
    if (ScanForButton(COPY_DEBUG_IMG, x, y, x+w, y+h, &foundX, &foundY))
    {
        CaptureDebugViaCopyButton(hwnd, foundX, foundY, triggerType)
        return
    }

    ; Fallback to existing methods
    LogAction(hwnd, "DEBUG_COPY_BUTTON_NOT_FOUND", 0, 0, triggerType)
    UpdateDebugViewer(hwnd, "COPY_DEBUG_INFO_BUTTON not found. Manual intervention required.", "NONE")
}

CaptureDebugViaCopyButton(hwnd, foundX, foundY, triggerType)
{
    config := WindowConfigs["" hwnd]
    if (DRY_RUN_MODE)
    {
        LogAction(hwnd, "DRY_RUN_COPY_DEBUG_INFO_DETECTED", foundX, foundY, triggerType)
        UpdateDebugViewer(hwnd, "COPY_DEBUG_INFO_BUTTON detected but not clicked (DRY RUN).", "DRY_RUN")
        return
    }

    oldClip := A_Clipboard
    A_Clipboard := ""
    CoordMode "Mouse", "Screen"
    Click(foundX, foundY)
    
    if (ClipWait(3))
    {
        debugText := A_Clipboard
        LogAction(hwnd, "DEBUG_CLIPBOARD_READ", 0, 0, "Length: " StrLen(debugText))
        UpdateDebugViewer(hwnd, debugText, "COPY_BUTTON")
    }
    else
    {
        LogAction(hwnd, "DEBUG_CLIPBOARD_EMPTY", 0, 0, "")
        UpdateDebugViewer(hwnd, "DEBUG_CLIPBOARD_EMPTY after button click.", "NONE")
    }
    
    A_Clipboard := oldClip
}

UpdateDebugViewer(hwnd, text, method)
{
    config := WindowConfigs["" hwnd]
    if (method != "NONE")
    {
        sanitized := SanitizeDebug(text)
        config.CapturedText := sanitized
        config.LastCaptureStatus := "Sanitized (" method ")"
        config.LastRetryTime := FormatTime(, "yyyy-MM-dd HH:mm:ss")
        LogAction(hwnd, "DEBUG_CAPTURED_" method, 0, 0, "Length: " StrLen(sanitized))
    }
    else
    {
        config.LastCaptureStatus := "DEBUG_CAPTURE_NOT_AVAILABLE"
        config.CapturedText := "DEBUG_CAPTURE_NOT_AVAILABLE"
        LogAction(hwnd, "DEBUG_CAPTURE_NOT_AVAILABLE", 0, 0, "")
    }
    
    ; Update UI if selected
    RowNumber := MainLV.GetNext()
    if (RowNumber > 0 && MainLV.GetText(RowNumber, 1) = "" hwnd)
    {
        editDebugText.Value := config.CapturedText
        txtCaptureStatus.Value := "Last Capture: " config.LastRetryTime
        txtRedactionStatus.Value := "Redaction Status: " config.LastCaptureStatus
    }
}

SanitizeDebug(text)
{
    for pattern in REDACT_PATTERNS
    {
        text := RegExReplace(text, pattern, "$1$2[REDACTED]")
    }
    return text
}

OnCopySanitized(*)
{
    if (editDebugText.Value != "")
    {
        A_Clipboard := editDebugText.Value
        ToolTip("Sanitized debug copied to clipboard.")
        SetTimer(() => ToolTip(), -2000)
    }
}

OnClearDebug(*)
{
    RowNumber := MainLV.GetNext()
    if (RowNumber = 0)
    {
        return
    }
    hwnd := MainLV.GetText(RowNumber, 1)
    config := WindowConfigs[hwnd]
    config.CapturedText := ""
    config.LastCaptureStatus := "Cleared"
    editDebugText.Value := ""
    txtRedactionStatus.Value := "Redaction Status: Cleared"
    LogAction(hwnd, "DEBUG_CLEARED", 0, 0, "")
}

OnSaveSnapshot(*)
{
    RowNumber := MainLV.GetNext()
    if (RowNumber = 0 or editDebugText.Value = "")
    {
        return
    }
    hwnd := MainLV.GetText(RowNumber, 1)
    timestamp := FormatTime(, "yyyyMMdd_HHmmss")
    filename := SNAPSHOT_DIR timestamp "_" hwnd "_retry_debug.txt"
    try
    {
        if (!DirExist(SNAPSHOT_DIR))
        {
            DirCreate(SNAPSHOT_DIR)
        }
        FileAppend(editDebugText.Value, filename)
        LogAction(hwnd, "DEBUG_SNAPSHOT_SAVED", 0, 0, filename)
        MsgBox("Snapshot saved: " filename)
    }
    catch
    {
        MsgBox("Failed to save snapshot.")
    }
}

; ==============================================================================
; LIMITS ALERT LOGIC
; ==============================================================================

ScanForLimits(hwnd)
{
    config := WindowConfigs["" hwnd]
    if (!config.LimitsMonitor)
    {
        return false
    }

    method := "NONE"
    matchInfo := ""

    ; Method A: UIA Text Scan
    try
    {
        text := WinGetText("ahk_id " hwnd)
        for phrase in LIMIT_PHRASES
        {
            if (InStr(text, phrase))
            {
                method := "UIA_TEXT"
                matchInfo := phrase
                break
            }
        }
    }

    ; Method B: Image Detection Fallback (Enable Overages)
    if (method = "NONE")
    {
        WinGetPos(&x, &y, &w, &h, "ahk_id " hwnd)
        ; Try preferred, then fallback
        if (ScanForButton(ENABLE_OVERAGES_IMG, x, y, x+w, y+h, &fX, &fY))
        {
            method := "IMAGE_PREFERRED"
        }
        else if (ScanForButton(LIMITS_FALLBACK_IMG, x, y, x+w, y+h, &fX, &fY))
        {
            method := "IMAGE_FALLBACK"
        }
    }

    if (method != "NONE")
    {
        if (!config.AlertActive)
        {
            config.AlertActive := true
            LogAction(hwnd, "ENABLE_OVERAGES_DETECTED", 0, 0, method)
            LogAction(hwnd, "LIMIT_WARNING_DETECTED_IMAGE", 0, 0, matchInfo)
            OpenAlertWindow(hwnd, method, matchInfo)
        }
        else if (A_TickCount - config.LastLimitLog > 10000)
        {
            config.LastLimitLog := A_TickCount
            LogAction(hwnd, "LIMIT_WARNING_STILL_ACTIVE", 0, 0, matchInfo)
        }
        return true
    }
    return false
}

OpenAlertWindow(targetHwnd, method, matchInfo)
{
    ; Prevent duplicate popup spam
    if (AlertGuis.Has("" targetHwnd))
    {
        try
        {
            AlertGuis["" targetHwnd].Show()
        }
        return
    }

    title := WinGetTitle("ahk_id " targetHwnd)
    
    AlertGui := Gui("+AlwaysOnTop -MinimizeBox +Owner" MyGui.Hwnd, "Antigravity Review Helper - Warning")
    AlertGui.BackColor := "Red"
    AlertGui.SetFont("s48 w700", "Segoe UI")
    AlertGui.Add("Text", "Center w400 cWhite", "LIMITS")
    AlertGui.SetFont("s10 w400", "Segoe UI")
    
    btnOk := AlertGui.Add("Button", "w100 h30 x150 y150", "OK")
    btnOk.OnEvent("Click", (*) => OnAlertOk(targetHwnd))

    AlertGuis["" targetHwnd] := AlertGui
    AlertGui.Show("w400 h200")
    LogAction(targetHwnd, "LIMIT_POPUP_OPENED", 0, 0, method)
}

OnAlertOk(hwnd)
{
    ClearAlert(hwnd)
    LogAction(hwnd, "LIMIT_POPUP_CLOSED", 0, 0, "")
}

ClearAlert(hwnd)
{
    if (WindowConfigs.Has("" hwnd))
    {
        WindowConfigs["" hwnd].AlertActive := false
        if (AlertGuis.Has("" hwnd))
        {
            try
            {
                AlertGuis["" hwnd].Destroy()
            }
            AlertGuis.Delete("" hwnd)
        }
    }
}

; ==============================================================================
; HOTKEYS
; ==============================================================================

^!esc:: ExitApp()

^!d:: OnManualDebugCapture()

^!s::
{
    global DRY_RUN_MODE := !DRY_RUN_MODE
    ToolTip("DRY_RUN_MODE: " (DRY_RUN_MODE ? "ON" : "OFF"))
    SetTimer(() => ToolTip(), -2000)
}

^!a::
{
    hwnd := WinActive("A")
    if (WindowConfigs.Has("" hwnd))
    {
        config := WindowConfigs["" hwnd]
        if (config.AlertActive)
        {
            return
        }
        if (config.LastAcceptX > 0)
        {
            DoClick(hwnd, config.LastAcceptX, config.LastAcceptY, "AcceptAllHotkey")
            config.LastAcceptX := 0
            config.LastAcceptY := 0
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
        if (!config.Enabled or (config.Status != "Running" and !config.AlwaysOn))
        {
            continue
        }
        
        if (!WinExist("ahk_id " hwnd))
        {
            config.Status := "Not Found"
            continue
        }
        
        if (WinGetMinMax("ahk_id " hwnd) = -1)
        {
            continue
        }

        title := WinGetTitle(hwnd)
        isForbidden := false
        for f in FORBIDDEN_TITLES
        {
            if (InStr(title, f))
            {
                isForbidden := true
                break
            }
        }
        if (isForbidden)
        {
            continue
        }

        ; Global pause for active alerts on this window
        if (config.AlertActive)
        {
            continue
        }

        ; Check for Limits
        if (ScanForLimits(hwnd))
        {
            continue ; Stop processing this window if limit detected
        }

        global LastMouseX, LastMouseY
        currX := 0
        currY := 0
        MouseGetPos(&currX, &currY)
        if (currX != LastMouseX or currY != LastMouseY)
        {
            LastMouseX := currX
            LastMouseY := currY
            continue
        }

        x := 0
        y := 0
        w := 0
        h := 0
        WinGetPos(&x, &y, &w, &h, hwnd)

        ; Prioritize Accept All
        foundAccept := false
        if (ScanForButton(ACCEPT_ALL_IMG, x, y, x+w, y+h, &foundX, &foundY))
        {
            foundAccept := true
        }
        else if (ScanForButton(ACCEPT_FALLBACK_IMG, x, y, x+w, y+h, &foundX, &foundY))
        {
            foundAccept := true
        }

        if (foundAccept)
        {
            config.LastAcceptX := foundX
            config.LastAcceptY := foundY
            if (config.AcceptAuto)
            {
                DoClick(hwnd, foundX, foundY, "AcceptAllAuto")
            }
            else if (config.AcceptManual)
            {
                LogAction(hwnd, "ACCEPT_WAITING_MANUAL_APPROVAL", foundX, foundY, "")
            }
            continue
        }

        ; Retry -> Trigger Debug Capture
        if (ScanForButton(RETRY_IMG, x, y, x+w, y+h, &foundX, &foundY))
        {
            LogAction(hwnd, "RETRY_DETECTED", foundX, foundY, "")
            
            ; Auto Capture Logic
            if (config.CopyDebugAuto)
            {
                CaptureDebugForWindow(hwnd, "AUTO")
            }
            else
            {
                LogAction(hwnd, "DEBUG_AUTO_CAPTURE_DISABLED", 0, 0, "")
            }

            if (config.RetryAuto)
            {
                DoClick(hwnd, foundX, foundY, "Retry")
            }
            continue
        }

        ; Continue (Optional Asset)
        if (config.ContinueAuto)
        {
            if (!FileExist(CONTINUE_IMG))
            {
                global ContinueAssetMissingLogged
                if (!ContinueAssetMissingLogged)
                {
                    LogAction(hwnd, "CONTINUE_ASSET_MISSING", 0, 0, "")
                    ContinueAssetMissingLogged := true
                }
            }
            else if (ScanForButton(CONTINUE_IMG, x, y, x+w, y+h, &foundX, &foundY))
            {
                DoClick(hwnd, foundX, foundY, "Continue")
            }
        }
    }
}

ScanForButton(imgPath, x1, y1, x2, y2, &foundX, &foundY)
{
    if (!FileExist(imgPath))
    {
        return false
    }
    CoordMode "Pixel", "Screen"
    if ImageSearch(&foundX, &foundY, x1, y1, x2, y2, "*50 " imgPath)
    {
        foundX += 10
        foundY += 10
        return true
    }
    return false
}

DoClick(hwnd, clickX, clickY, type)
{
    config := WindowConfigs["" hwnd]
    if (config.AlertActive)
    {
        LogAction(hwnd, "SKIPPED_LIMIT_ALERT_ACTIVE", clickX, clickY, type)
        return
    }

    WinGetPos(&winX, &winY, &winW, &winH, hwnd)
    if (clickX < winX or clickX > winX+winW or clickY < winY or clickY > winY+winH)
    {
        LogAction(hwnd, "SKIPPED_OUTSIDE_WINDOW", clickX, clickY, type)
        return
    }
    if (!CheckRateLimit(hwnd))
    {
        return
    }
    
    if (DRY_RUN_MODE)
    {
        event := "DRY_RUN_" type "_DETECTED"
        if (type = "AcceptAllAuto")
        {
            event := "DRY_RUN_ACCEPT_ALL_DETECTED"
        }
        LogAction(hwnd, event, clickX, clickY, "Dry Run")
        return
    }
    
    CoordMode "Mouse", "Screen"
    Click(clickX, clickY)
    
    event := "CLICKED_" type
    if (type = "AcceptAllAuto")
    {
        event := "CLICKED_ACCEPT_ALL_AUTO"
    }
    LogAction(hwnd, event, clickX, clickY, "Live")
}

CheckRateLimit(hwnd)
{
    global ClickTimestamps
    now := A_TickCount
    newTimestamps := []
    for ts in ClickTimestamps
    {
        if (now - ts < 60000)
        {
            newTimestamps.Push(ts)
        }
    }
    ClickTimestamps := newTimestamps
    if (ClickTimestamps.Length > 0 and now - ClickTimestamps[ClickTimestamps.Length] < 1000)
    {
        return false
    }
    if (ClickTimestamps.Length >= MAX_CLICKS_PER_MIN)
    {
        return false
    }
    ClickTimestamps.Push(now)
    return true
}

LogAction(hwnd, event, x, y, actionNote)
{
    global LOG_FILE
    timestamp := FormatTime(, "yyyy-MM-dd HH:mm:ss")
    title := WinGetTitle(hwnd)
    logLine := timestamp " | " hwnd " | " title " | " event " | " (DRY_RUN_MODE ? "DRY" : "LIVE") " | " x "," y " | " actionNote "`n"
    try
    {
        FileAppend(logLine, LOG_FILE)
    }
    catch
    {
    }
}
