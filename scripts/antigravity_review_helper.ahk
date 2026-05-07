#Requires AutoHotkey v2.0
#SingleInstance Force

; ==============================================================================
; CONFIGURATION & SAFETY SETTINGS
; ==============================================================================

global DRY_RUN_MODE := true
global IS_PAUSED := false
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

; Project Structure & Paths (Using absolute relative paths)
global ASSET_DIR := A_ScriptDir "\..\assets\buttons\"
global ALERT_DIR := A_ScriptDir "\..\assets\alerts\"
global LOG_DIR := A_ScriptDir "\..\logs"
global SNAPSHOT_DIR := A_ScriptDir "\..\debug_snapshots"

; Ensure Directories Exist
if (!DirExist(LOG_DIR))
    DirCreate(LOG_DIR)
if (!DirExist(SNAPSHOT_DIR))
    DirCreate(SNAPSHOT_DIR)

global LOG_FILE := LOG_DIR "\antigravity_review_helper.log"

; Debug start log
try {
    FileAppend("--- SCRIPT START " A_Now " ---`n", LOG_FILE)
} catch {
}

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
MyGui.Add("Button", "x450 y480 w100", "Clear Log").OnEvent("Click", OnClearLog)
MyGui.Add("Button", "x560 y480 w50", "Exit").OnEvent("Click", (*) => ExitApp())

chkDryRunGlobal := MyGui.Add("Checkbox", "x10 y505 Checked", "Global Dry Run Mode (Safety)")
chkDryRunGlobal.OnEvent("Click", OnDryRunToggle)

global txtGlobalStatus := MyGui.Add("Text", "x10 y525 w600 cBlue", "Helper: RUNNING | Dry Run: ON")
MyGui.Add("Text", "x450 y525 w160 cGray Right", "Emergency: Ctrl+Alt+Esc")

MyGui.Show("w620 h550")
RefreshWindowList()

; ==============================================================================
; GUI EVENTS & HELPERS
; ==============================================================================

OnClearLog(*) {
    try {
        FileDelete(LOG_FILE)
    } catch {
    }
}

OnLVClick(targetLV, RowNumber)
{
    if (RowNumber = 0)
        return
    hwnd := targetLV.GetText(RowNumber, 1)
    if (!WindowConfigs.Has(hwnd))
        return
    config := WindowConfigs[hwnd]
    chkEnabled.Value := config.Enabled
    chkAlwaysOn.Value := config.AlwaysOn
    chkRetry.Value := config.RetryAuto
    chkContinue.Value := config.ContinueAuto
    chkAcceptManual.Value := config.AcceptManual
    chkAcceptAuto.Value := config.AcceptAuto
    chkCopyDebugAuto.Value := config.CopyDebugAuto
    chkLimitsMonitor.Value := config.LimitsMonitor
    txtCaptureStatus.Value := "Last Detection: " (config.LastRetryTime ? config.LastRetryTime : "None")
    txtRedactionStatus.Value := "Redaction Status: " (config.LastCaptureStatus ? config.LastCaptureStatus : "Idle")
    editDebugText.Value := config.CapturedText ? config.CapturedText : ""
    
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
        return
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
            ClearAlert(hwnd)
    }
    Loop MainLV.GetCount()
        MainLV.Modify(A_Index, , , "Stopped")
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
                config := oldConfigs["" hwnd]
            WindowConfigs["" hwnd] := config
            MainLV.Add(, hwnd, config.Status, title)
        }
    }
}

OnDryRunToggle(ctrl, *)
{
    if (ctrl.Value = 0)
    {
        if (MsgBox("Turning Dry Run OFF allows real clicks. Continue?", "DANGER", "YesNo Icon!") = "No")
        {
            ctrl.Value := 1
            global DRY_RUN_MODE := true
        }
        else
        {
            global DRY_RUN_MODE := false
            LogAction(0, "DR_LIVE_DANGER", 0, 0, "DANGER: LIVE CLICKS ENABLED")
        }
    }
    else
    {
        global DRY_RUN_MODE := true
        LogAction(0, "DR_SAFETY_RESTORED", 0, 0, "Safety restored")
    }
    UpdateGlobalStatus()
}

UpdateGlobalStatus()
{
    statusText := "Helper: " (IS_PAUSED ? "PAUSED" : "RUNNING")
    statusText .= " | Dry Run: " (DRY_RUN_MODE ? "ON" : "OFF")
    if (!DRY_RUN_MODE)
    {
        statusText .= " - LIVE CLICKS ENABLED"
        txtGlobalStatus.SetFont("cRed w700")
    }
    else
        txtGlobalStatus.SetFont("cBlue w400")
    txtGlobalStatus.Value := statusText
}

OnManualDebugCapture()
{
    RowNumber := MainLV.GetNext()
    if (RowNumber = 0)
        return
    hwnd := MainLV.GetText(RowNumber, 1)
    CaptureDebugForWindow(hwnd, "MANUAL")
}

CaptureDebugForWindow(hwnd, triggerType)
{
    WinGetPos(&x, &y, &w, &h, "ahk_id " hwnd)
    if (ScanForButton(COPY_DEBUG_IMG, x, y, x+w, y+h, &foundX, &foundY))
    {
        CaptureDebugViaCopyButton(hwnd, foundX, foundY, triggerType)
        return
    }
    LogAction(hwnd, "DEBUG_COPY_BUTTON_NOT_FOUND", 0, 0, triggerType)
}

CaptureDebugViaCopyButton(hwnd, foundX, foundY, triggerType)
{
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
        UpdateDebugViewer(hwnd, A_Clipboard, "COPY_BUTTON")
    else
        LogAction(hwnd, "DEBUG_CLIPBOARD_EMPTY", 0, 0, "")
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
        text := RegExReplace(text, pattern, "$1$2[REDACTED]")
    return text
}

OnCopySanitized(*)
{
    if (editDebugText.Value != "")
    {
        A_Clipboard := editDebugText.Value
        ToolTip("Copied.")
        SetTimer(() => ToolTip(), -2000)
    }
}

OnClearDebug(*)
{
    RowNumber := MainLV.GetNext()
    if (RowNumber = 0)
        return
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
        return
    hwnd := MainLV.GetText(RowNumber, 1)
    timestamp := FormatTime(, "yyyyMMdd_HHmmss")
    filename := SNAPSHOT_DIR "\" timestamp "_" hwnd "_retry_debug.txt"
    try {
        if (!DirExist(SNAPSHOT_DIR))
            DirCreate(SNAPSHOT_DIR)
        FileAppend(editDebugText.Value, filename)
        LogAction(hwnd, "DEBUG_SNAPSHOT_SAVED", 0, 0, filename)
        MsgBox("Saved: " filename)
    } catch {
        MsgBox("Failed save.")
    }
}

ScanForLimits(hwnd)
{
    config := WindowConfigs["" hwnd]
    if (!config.LimitsMonitor)
        return false
    method := "NONE", matchInfo := ""
    try {
        text := WinGetText("ahk_id " hwnd)
        for phrase in LIMIT_PHRASES
            if (InStr(text, phrase))
            {
                method := "UIA_TEXT"
                matchInfo := phrase
                break
            }
    } catch {
    }
    if (method = "NONE") {
        WinGetPos(&x, &y, &w, &h, "ahk_id " hwnd)
        if (ScanForButton(ENABLE_OVERAGES_IMG, x, y, x+w, y+h, &fX, &fY))
            method := "IMAGE_PREFERRED"
        else if (ScanForButton(LIMITS_FALLBACK_IMG, x, y, x+w, y+h, &fX, &fY))
            method := "IMAGE_FALLBACK"
    }
    if (method != "NONE") {
        if (!config.AlertActive) {
            config.AlertActive := true
            LogAction(hwnd, "ENABLE_OVERAGES_DETECTED", 0, 0, method)
            LogAction(hwnd, "LIMIT_WARNING_DETECTED_IMAGE", 0, 0, matchInfo)
            OpenAlertWindow(hwnd, method, matchInfo)
        }
        return true
    }
    return false
}

OpenAlertWindow(targetHwnd, method, matchInfo)
{
    if (AlertGuis.Has("" targetHwnd)) { 
        try {
            AlertGuis["" targetHwnd].Show()
        }
        catch
        {
        }
        return
    }
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

OnAlertOk(hwnd) {
    ClearAlert(hwnd)
    LogAction(hwnd, "LIMIT_POPUP_CLOSED", 0, 0, "")
}

ClearAlert(hwnd) {
    if (WindowConfigs.Has("" hwnd)) {
        WindowConfigs["" hwnd].AlertActive := false
        if (AlertGuis.Has("" hwnd)) { 
            try {
                AlertGuis["" hwnd].Destroy()
            } 
            catch
            {
            }
            AlertGuis.Delete("" hwnd) 
        }
    }
}

^!esc:: ExitApp()
^!d:: OnManualDebugCapture()
^!s:: { 
    global IS_PAUSED := !IS_PAUSED
    UpdateGlobalStatus()
}

SetTimer(MainLoop, 1000)

MainLoop()
{
    if (IS_PAUSED)
        return
    for hwndStr, config in WindowConfigs
    {
        hwnd := Number(hwndStr)
        if (!config.Enabled or (config.Status != "Running" and !config.AlwaysOn))
            continue
        if (!WinExist("ahk_id " hwnd) or WinGetMinMax("ahk_id " hwnd) = -1)
            continue
        if (config.AlertActive)
            continue
        if (ScanForLimits(hwnd))
            continue
        WinGetPos(&x, &y, &w, &h, hwnd)
        
        global ContinueAssetMissingLogged
        if (!ContinueAssetMissingLogged and !FileExist(CONTINUE_IMG)) {
            LogAction(hwnd, "CONTINUE_ASSET_MISSING", 0, 0, "MISSING_OK")
            ContinueAssetMissingLogged := true
        }

        fX := 0, fY := 0, foundAccept := false
        if (ScanForButton(ACCEPT_ALL_IMG, x, y, x+w, y+h, &fX, &fY))
            foundAccept := true
        else if (ScanForButton(ACCEPT_FALLBACK_IMG, x, y, x+w, y+h, &fX, &fY))
            foundAccept := true

        if (foundAccept) {
            config.LastAcceptX := fX, config.LastAcceptY := fY
            if (DRY_RUN_MODE)
                LogAction(hwnd, "DRY_RUN_ACCEPT_ALL_DETECTED", fX, fY, "Dry Run")
            if (config.AcceptAuto)
                DoClick(hwnd, fX, fY, "AcceptAllAuto")
            continue
        }

        if (ScanForButton(RETRY_IMG, x, y, x+w, y+h, &fX, &fY)) {
            LogAction(hwnd, "RETRY_DETECTED", fX, fY, "")
            if (DRY_RUN_MODE)
                LogAction(hwnd, "DRY_RUN_RETRY_DETECTED", fX, fY, "Dry Run")
            if (DRY_RUN_MODE) {
                if (ScanForButton(COPY_DEBUG_IMG, x, y, x+w, y+h, &cX, &cY))
                    LogAction(hwnd, "DRY_RUN_COPY_DEBUG_INFO_DETECTED", cX, cY, "Dry Run")
            } else if (config.CopyDebugAuto)
                CaptureDebugForWindow(hwnd, "AUTO")
            if (config.RetryAuto)
                DoClick(hwnd, fX, fY, "Retry")
            continue
        }
    }
}

ScanForButton(imgPath, x1, y1, x2, y2, &fX, &fY) {
    if (!FileExist(imgPath))
        return false
    CoordMode "Pixel", "Screen"
    if ImageSearch(&fX, &fY, x1, y1, x2, y2, "*50 " imgPath)
    {
        fX += 10
        fY += 10
        return true
    }
    return false
}

DoClick(hwnd, clickX, clickY, type) {
    if (DRY_RUN_MODE) {
        upperType := StrUpper(type)
        LogAction(hwnd, "DRY_RUN_" upperType "_DETECTED", clickX, clickY, "Dry Run")
        return
    }
    CoordMode "Mouse", "Screen"
    Click(clickX, clickY)
    LogAction(hwnd, "CLICKED_" StrUpper(type), clickX, clickY, "Live")
}

LogAction(hwnd, event, x, y, actionNote) {
    global LOG_FILE
    static logErrorShown := false
    timestamp := FormatTime(, "yyyy-MM-dd HH:mm:ss")
    title := WinGetTitle(hwnd)
    logLine := timestamp " | " hwnd " | " title " | " event " | " (DRY_RUN_MODE ? "DRY" : "LIVE") " | " x "," y " | " actionNote "`n"
    try {
        FileAppend(logLine, LOG_FILE)
    } catch as e {
        if (!logErrorShown) {
            MsgBox("Critical: Failed to write to log file.`n`nError: " e.Message)
            logErrorShown := true
        }
    }
}
