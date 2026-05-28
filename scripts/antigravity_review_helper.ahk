#Requires AutoHotkey v2.0
#SingleInstance Force

; ==============================================================================
; CONFIGURATION & SAFETY SETTINGS
; ==============================================================================

global DRY_RUN_MODE := false
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

; Event Counters State
global EventCounters := Map()
global CounterControls := Map() ; Map counter name -> Text control object
global EventLogLV := 0 ; Global reference for Live Log ListView

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

; Project Structure & Paths (Robust Resolution)
global PROJECT_ROOT := RegExReplace(A_ScriptDir, "\\[^\\]+$")
global ASSET_DIR := PROJECT_ROOT "\assets\buttons\"
global ALERT_DIR := PROJECT_ROOT "\assets\alerts\"
global LOG_DIR := PROJECT_ROOT "\logs"
global SNAPSHOT_DIR := PROJECT_ROOT "\debug_snapshots"

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
global ACCEPT_ALL_IMG := ASSET_DIR "accept_all_button.png"
global ACCEPT_FALLBACK_IMG := ASSET_DIR "accept_button.png"
global ACCEPT_HOVER_IMG := ASSET_DIR "accept_button_hover.png"
global ENABLE_OVERAGES_IMG := ASSET_DIR "enable_overages_button.png"
global LIMITS_FALLBACK_IMG := ALERT_DIR "limit_warning.png"

; Alert Window State
global AlertGuis := Map() ; hwnd -> Gui Object

; ==============================================================================
; INITIALIZATION & GUI
; ==============================================================================

if (SAFETY_CONFIRMATION_REQUIRED)
{
    msg := "Antigravity Review Helper v4 (Harden Selection) Safety Briefing:`n`n"
    msg .= "- UI is English-only.`n"
    msg .= "- Helper never monitors its own windows.`n"
    msg .= "- User must explicitly select and START a project window.`n"
    msg .= "- Debug text is SANITIZED (redacted) before display/save.`n"
    msg .= "- Limits Alert: Warning popup when usage limits detected.`n"
    msg .= "- No network access or external file reading.`n`n"
    msg .= "Proceed?"
    if (MsgBox(msg, "Safety Audit", "YesNo Iconi") = "No")
    {
        ExitApp()
    }
}

MyGui := Gui("+Resize", "Antigravity Review Helper v0.2.2-overlay")
MyGui.SetFont("s9", "Segoe UI")

; Initialize Counters
InitCounters()

; Window List (Left Side)
MyGui.Add("Text", "x10 y10", "Detected Antigravity Project Windows:")
; HWND | Status | Project | Title
global MainLV := MyGui.Add("ListView", "x10 y30 w550 h120", ["HWND", "Status", "Project", "Title"])
MainLV.ModifyCol(1, 70)
MainLV.ModifyCol(2, 100)
MainLV.ModifyCol(3, 160)
MainLV.ModifyCol(4, 200)
MainLV.OnEvent("Click", OnLVClick)

; Event Counters (Right Side)
MyGui.Add("GroupBox", "x570 y10 w410 h250", "Event Counters (Runtime Only)")
yPos := 30
AddCounterUI(MyGui, "TotalEvents", "Total Events:", 580, yPos)
yPos += 20
AddCounterUI(MyGui, "RetryDetected", "Retry Detected:", 580, yPos)
AddCounterUI(MyGui, "RetryClicked", "Retry Clicked:", 800, yPos)
yPos += 20
AddCounterUI(MyGui, "CopyDebugDetected", "Copy Debug Detected:", 580, yPos)
AddCounterUI(MyGui, "CopyDebugClicked", "Copy Debug Clicked:", 800, yPos)
yPos += 20
AddCounterUI(MyGui, "AcceptDetected", "Accept Detected:", 580, yPos)
AddCounterUI(MyGui, "AcceptClicked", "Accept Clicked:", 800, yPos)
yPos += 20
AddCounterUI(MyGui, "ContinueDetected", "Continue Detected:", 580, yPos)
AddCounterUI(MyGui, "ContinueClicked", "Continue Clicked:", 800, yPos)
yPos += 20
AddCounterUI(MyGui, "LimitsDetected", "LIMITS Detected:", 580, yPos)
AddCounterUI(MyGui, "LimitsPopupOpened", "LIMITS Popups:", 800, yPos)
yPos += 30
AddCounterUI(MyGui, "StartBlocked", "Start Blocked:", 580, yPos)
AddCounterUI(MyGui, "TargetWindowGone", "Target Gone:", 800, yPos)
yPos += 20
AddCounterUI(MyGui, "StaleWindowSkipped", "Stale Skipped:", 580, yPos)
AddCounterUI(MyGui, "CooldownSkipped", "Cooldown Skips:", 800, yPos)
yPos += 20
AddCounterUI(MyGui, "DryRunBlocked", "Blocked by Dry Run:", 580, yPos)

btnResetCounters := MyGui.Add("Button", "x580 y225 w120", "Reset Counters")
btnResetCounters.OnEvent("Click", (*) => ResetCounters())

; Configuration Pane
MyGui.Add("GroupBox", "x10 y160 w550 h100", "Selected Window Configuration")
chkEnabled := MyGui.Add("Checkbox", "x20 y180", "Enabled")
chkEnabled.OnEvent("Click", OnCheckboxClick)
chkAlwaysOn := MyGui.Add("Checkbox", "x100 y180", "Always On")
chkAlwaysOn.OnEvent("Click", OnCheckboxClick)
chkRetry := MyGui.Add("Checkbox", "x200 y180 Checked", "Retry Auto")
chkRetry.OnEvent("Click", OnCheckboxClick)
chkContinue := MyGui.Add("Checkbox", "x300 y180 Checked", "Continue Auto")
chkContinue.OnEvent("Click", OnCheckboxClick)
chkAcceptManual := MyGui.Add("Checkbox", "x420 y180 Checked", "Accept Manual (Prompt)")
chkAcceptManual.OnEvent("Click", OnCheckboxClick)
chkAcceptAuto := MyGui.Add("Checkbox", "x20 y205 cRed", "Accept All Auto (CAUTION)")
chkAcceptAuto.OnEvent("Click", OnAcceptAutoClick)

chkCopyDebugAuto := MyGui.Add("Checkbox", "x200 y205 Checked", "Copy Debug Info Auto")
chkCopyDebugAuto.OnEvent("Click", OnCheckboxClick)
chkLimitsMonitor := MyGui.Add("Checkbox", "x420 y205 Checked", "Limits Alert Monitor")
chkLimitsMonitor.OnEvent("Click", OnCheckboxClick)

; Debug Viewer Panel (Left)
MyGui.Add("GroupBox", "x10 y270 w550 h200", "Debug Viewer (Sanitized)")
editDebugText := MyGui.Add("Edit", "x20 y290 w530 h120 ReadOnly vDebugText", "")
txtCaptureStatus := MyGui.Add("Text", "x20 y420 w200", "Last Detection: None")
txtRedactionStatus := MyGui.Add("Text", "x250 y420 w280", "Redaction Status: Idle")
btnRefreshDebug := MyGui.Add("Button", "x20 y440 w100", "Refresh Debug")
btnRefreshDebug.OnEvent("Click", (*) => OnManualDebugCapture())
btnCopyDebug := MyGui.Add("Button", "x130 y440 w100", "Copy Sanitized")
btnCopyDebug.OnEvent("Click", OnCopySanitized)
btnClearDebug := MyGui.Add("Button", "x240 y440 w90", "Clear Debug")
btnClearDebug.OnEvent("Click", OnClearDebug)
btnSaveSnapshot := MyGui.Add("Button", "x340 y440 w150", "Save Sanitized Snapshot")
btnSaveSnapshot.OnEvent("Click", OnSaveSnapshot)

; Live Event Log (Right)
MyGui.Add("GroupBox", "x570 y270 w410 h270", "Live Event Log")
global EventLogLV := MyGui.Add("ListView", "x580 y290 w390 h210", ["Time", "Project", "Event", "Mode", "Note"])
EventLogLV.ModifyCol(1, 60)
EventLogLV.ModifyCol(2, 80)
EventLogLV.ModifyCol(3, 140)
EventLogLV.ModifyCol(4, 40)
EventLogLV.ModifyCol(5, 70)
btnClearEventLog := MyGui.Add("Button", "x580 y510 w120", "Clear Event Log")
btnClearEventLog.OnEvent("Click", (*) => EventLogLV.Delete())

; Global Controls
MyGui.Add("Button", "x10 y480 w100", "Refresh List").OnEvent("Click", RefreshWindowList)
MyGui.Add("Button", "x120 y480 w100", "Start Selected").OnEvent("Click", (*) => UpdateStatus("Running"))
MyGui.Add("Button", "x230 y480 w100", "Stop Selected").OnEvent("Click", (*) => UpdateStatus("Stopped"))
MyGui.Add("Button", "x340 y480 w100", "Stop All").OnEvent("Click", StopAll)
MyGui.Add("Button", "x450 y480 w100", "Clear Log").OnEvent("Click", OnClearLog)
MyGui.Add("Button", "x560 y480 w50", "Exit").OnEvent("Click", (*) => ExitApp())

chkDryRunGlobal := MyGui.Add("Checkbox", "x10 y505", "Global Dry Run Mode (Safety)")
chkDryRunGlobal.OnEvent("Click", OnDryRunToggle)

global txtGlobalStatus := MyGui.Add("Text", "x10 y525 w600 cBlue", "Helper: RUNNING | Dry Run: ON")
MyGui.Add("Text", "x450 y525 w160 cGray Right", "Emergency: Ctrl+Alt+Esc")

MyGui.Show("w1000 h550")
UpdateGlobalStatus()
RefreshWindowList()
; SetTimer(RefreshWindowList, 5000) ; DISABLED to prevent selection loss and stale HWND access

; ==============================================================================
; GUI EVENTS & HELPERS
; ==============================================================================

ExtractProjectName(title)
{
    if (InStr(title, "Antigravity Review Helper") or InStr(title, "v0.2.1-stale-hwnd-fix") or InStr(title, "Antigravity Review Helper - Warning"))
        return "SELF - DO NOT USE"
    
    if (InStr(title, " - Antigravity"))
    {
        parts := StrSplit(title, " - Antigravity")
        name := Trim(parts[1])
        return (name != "") ? name : "Unknown Project"
    }
    return "Unknown Project"
}

; --- Counter Functions ---

InitCounters() {
    global EventCounters, CounterControls
    counters := [
        "TotalEvents", "RetryDetected", "RetryClicked", "CopyDebugDetected", "CopyDebugClicked",
        "AcceptDetected", "AcceptClicked", "ContinueDetected", "ContinueClicked",
        "LimitsDetected", "LimitsPopupOpened", "StartBlocked", "TargetWindowGone",
        "StaleWindowSkipped", "CooldownSkipped", "DryRunBlocked"
    ]
    for c in counters
        EventCounters[c] := 0
}

AddCounterUI(guiObj, name, label, x, y) {
    global CounterControls
    guiObj.Add("Text", "x" x " y" y " w120", label)
    CounterControls[name] := guiObj.Add("Text", "x" (x+120) " y" y " w50 Right", "0")
}

IncrementCounter(eventName) {
    global EventCounters, CounterControls, DRY_RUN_MODE

    ; Noise events — do NOT increment TotalEvents or any counter
    static noiseEvents := ["REFRESH_WINDOW_LIST", "STATUS_CHANGED", "STOP_ALL_COMMAND",
        "COUNTERS_RESET", "DR_LIVE_DANGER", "DR_SAFETY_RESTORED",
        "ACCEPT_SCAN_BEGIN", "RETRY_SCAN_BEGIN", "COPY_DEBUG_SCAN_BEGIN",
        "CONTINUE_ASSET_MISSING", "DEBUG_CLEARED", "DEBUG_SNAPSHOT_SAVED",
        "DEBUG_COPY_BUTTON_NOT_FOUND", "ACCEPT_ALL_CONFIRMATION_CANCELLED",
        "ACCEPT_ALL_CONFIRMATION_ACCEPTED", "ACCEPT_ALL_AUTO_DISABLED",
        "ACCEPT_LIVE_COOLDOWN_SKIP", "RETRY_LIVE_COOLDOWN_SKIP",
        "LIMIT_POPUP_CLOSED", "SCRIPT_START"]
    for noise in noiseEvents {
        if (eventName = noise)
            return
    }

    ; 1. Total Events increments for real events only
    EventCounters["TotalEvents"] += 1
    if (CounterControls.Has("TotalEvents"))
        CounterControls["TotalEvents"].Value := EventCounters["TotalEvents"]

    ; 2. Primary Mapping Chain
    counter := ""

    ; Detection Mappings
    if (InStr(eventName, "RETRY_DETECTED"))
        counter := "RetryDetected"
    else if (InStr(eventName, "COPY_DEBUG_INFO_DETECTED"))
        counter := "CopyDebugDetected"
    else if (InStr(eventName, "ACCEPT_ALL_DETECTED") or InStr(eventName, "ACCEPT_MANUAL_DETECTED"))
        counter := "AcceptDetected"
    else if (InStr(eventName, "CONTINUE_DETECTED"))
        counter := "ContinueDetected"
    else if (InStr(eventName, "LIMIT_WARNING_DETECTED") or InStr(eventName, "ENABLE_OVERAGES_DETECTED"))
        counter := "LimitsDetected"

    ; Click/Action Mappings
    else if (InStr(eventName, "CLICKED_RETRY"))
        counter := "RetryClicked"
    else if (InStr(eventName, "CLICKED_COPY_DEBUG") or InStr(eventName, "COPY_DEBUG_INFO_CLICKED"))
        counter := "CopyDebugClicked"
    else if (InStr(eventName, "CLICKED_ACCEPT_MANUAL") or InStr(eventName, "CLICKED_ACCEPT_ALL_AUTO"))
        counter := "AcceptClicked"
    else if (InStr(eventName, "CLICKED_CONTINUE"))
        counter := "ContinueClicked"
    else if (InStr(eventName, "LIMIT_POPUP_OPENED"))
        counter := "LimitsPopupOpened"

    ; Blocked/Safety Mappings
    else if (InStr(eventName, "START_BLOCKED"))
        counter := "StartBlocked"
    else if (InStr(eventName, "TARGET_WINDOW_GONE"))
        counter := "TargetWindowGone"
    else if (InStr(eventName, "SKIPPED_STALE_WINDOW") or InStr(eventName, "STALE_WINDOW") or InStr(eventName, "STALE_HWND"))
        counter := "StaleWindowSkipped"
    else if (InStr(eventName, "COOLDOWN_SKIP"))
        counter := "CooldownSkipped"
    else if (InStr(eventName, "DRY_RUN_CLICK_BLOCKED") or InStr(eventName, "CLICK_BLOCKED_DRY_RUN"))
        counter := "DryRunBlocked"

    ; Increment specific counter if mapped
    if (counter != "" and EventCounters.Has(counter)) {
        EventCounters[counter] += 1
        if (CounterControls.Has(counter))
            CounterControls[counter].Value := EventCounters[counter]
    }
}

ResetCounters() {
    global EventCounters, CounterControls
    for name, val in EventCounters
        EventCounters[name] := 0
    for name, ctrl in CounterControls
        ctrl.Value := "0"
    LogAction(0, "COUNTERS_RESET", 0, 0, "All counters set to 0")
}

SafeWinExists(hwnd) {
    if (!hwnd)
        return false
    try {
        return WinExist("ahk_id " hwnd) != 0
    } catch {
        return false
    }
}

SafeWinGetTitle(hwnd, fallback := "UNKNOWN_WINDOW") {
    if (!SafeWinExists(hwnd))
        return fallback
    try {
        return WinGetTitle("ahk_id " hwnd)
    } catch {
        return fallback
    }
}

SafeWinGetText(hwnd, fallback := "") {
    if (!SafeWinExists(hwnd))
        return fallback
    try {
        return WinGetText("ahk_id " hwnd)
    } catch {
        return fallback
    }
}

SafeWinGetMinMax(hwnd) {
    if (!SafeWinExists(hwnd))
        return -1
    try {
        return WinGetMinMax("ahk_id " hwnd)
    } catch {
        return -1
    }
}

SafeWinGetPos(hwnd, &x, &y, &w, &h) {
    x := 0, y := 0, w := 0, h := 0
    if (!SafeWinExists(hwnd))
        return false
    try {
        WinGetPos(&x, &y, &w, &h, "ahk_id " hwnd)
        return true
    } catch {
        return false
    }
}

GetWindowSearchRect(hwnd, &left, &top, &right, &bottom, &width, &height) {
    left := 0, top := 0, right := 0, bottom := 0, width := 0, height := 0
    if (!SafeWinGetPos(hwnd, &x, &y, &w, &h))
        return false
    
    if (w <= 0 or h <= 0)
        return false

    left := x
    top := y
    width := w
    height := h
    right := x + w
    bottom := y + h
    return true
}

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
}

OnCheckboxClick(ctrl, *)
{
    Row := MainLV.GetNext()
    if (!Row)
        return
    hwnd := MainLV.GetText(Row, 1)
    if (!WindowConfigs.Has(hwnd))
        return
    config := WindowConfigs[hwnd]
    
    if (ctrl = chkEnabled) {
        config.Enabled := ctrl.Value
    } else if (ctrl = chkAlwaysOn) {
        config.AlwaysOn := ctrl.Value
    } else if (ctrl = chkRetry) {
        config.RetryAuto := ctrl.Value
    } else if (ctrl = chkContinue) {
        config.ContinueAuto := ctrl.Value
    } else if (ctrl = chkAcceptManual) {
        config.AcceptManual := ctrl.Value
    } else if (ctrl = chkCopyDebugAuto) {
        config.CopyDebugAuto := ctrl.Value
    } else if (ctrl = chkLimitsMonitor) {
        config.LimitsMonitor := ctrl.Value
    }
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
        LogAction(0, "START_BLOCKED_NO_SELECTION", 0, 0, "")
        MsgBox("No window selected.", "Selection Required", "Icon!")
        return
    }
    hwnd := MainLV.GetText(RowNumber, 1)
    if (!SafeWinExists(hwnd))
    {
        MsgBox("Selected window no longer exists. Click Refresh List and select the project again.", "Window Not Found", "Icon!")
        LogAction(0, "START_BLOCKED_WINDOW_NOT_FOUND", 0, 0, "stale hwnd: " hwnd)
        RefreshWindowList()
        return
    }
    
    ; Refresh metadata from real window if it exists
    title := SafeWinGetTitle(hwnd)
    project := ExtractProjectName(title)
    
    if (project = "SELF - DO NOT USE")
    {
        LogAction(hwnd, "START_BLOCKED_SELF_WINDOW", 0, 0, "")
        MsgBox("Cannot monitor the helper itself.")
        return
    }
    if (SafeWinGetMinMax(hwnd) = -1)
    {
        LogAction(hwnd, "START_BLOCKED_MINIMIZED", 0, 0, "")
        MsgBox("Target window is minimized.")
        return
    }
    
    for pattern in FORBIDDEN_TITLES
    {
        if (InStr(title, pattern))
        {
            LogAction(hwnd, "START_BLOCKED_FORBIDDEN_TITLE", 0, 0, pattern)
            MsgBox("Window title contains forbidden word: " pattern)
            return
        }
    }

    if (WindowConfigs.Has(hwnd))
    {
        WindowConfigs[hwnd].Status := newStatus
        MainLV.Modify(RowNumber, , , newStatus)
        LogAction(hwnd, "STATUS_CHANGED", 0, 0, newStatus)
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
    LogAction(0, "STOP_ALL_COMMAND", 0, 0, "")
}

RefreshWindowList(*)
{
    MainLV.Delete()
    oldConfigs := WindowConfigs.Clone()
    WindowConfigs.Clear()
    for hwnd in WinGetList()
    {
        title := SafeWinGetTitle(hwnd)
        project := ExtractProjectName(title)
        
        ; Explicitly exclude self
        if (project = "SELF - DO NOT USE")
            continue
            
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
            config := {Enabled: 0, AlwaysOn: 0, RetryAuto: 1, ContinueAuto: 1, AcceptManual: 1, AcceptAuto: 0, CopyDebugAuto: 1, LimitsMonitor: 1, Status: "Stopped", LastAcceptX: 0, LastAcceptY: 0, LastRetryTime: "", LastCaptureStatus: "Idle", CapturedText: "", AlertActive: false, LastLimitLog: 0, LastScanLogTime: 0, LastAcceptClickTime: 0, LastRetryClickTime: 0}
            if (oldConfigs.Has("" hwnd))
                config := oldConfigs["" hwnd]
            
            WindowConfigs["" hwnd] := config
            MainLV.Add(, hwnd, config.Status, project, title)
        }
    }
    LogAction(0, "REFRESH_WINDOW_LIST", 0, 0, "Count: " MainLV.GetCount())
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
    if (!GetWindowSearchRect(hwnd, &left, &top, &right, &bottom, &w, &h))
    {
        LogAction(hwnd, "DEBUG_TARGET_WINDOW_GONE", 0, 0, triggerType)
        UpdateDebugViewer(hwnd, "DEBUG_TARGET_WINDOW_GONE", "NONE")
        return
    }
    if (ScanForButton(COPY_DEBUG_IMG, left, top, right, bottom, &foundX, &foundY))
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
    if (SafeWinExists(hwnd))
        RestoreMouseClick(hwnd, foundX, foundY)
    if (ClipWait(3))
        UpdateDebugViewer(hwnd, A_Clipboard, "COPY_BUTTON")
    else
        LogAction(hwnd, "DEBUG_CLIPBOARD_EMPTY", 0, 0, "")
    A_Clipboard := oldClip
}

UpdateDebugViewer(hwnd, text, method)
{
    if (!WindowConfigs.Has("" hwnd))
        return
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
    if (!WindowConfigs.Has("" hwnd))
        return false
    config := WindowConfigs["" hwnd]
    if (!config.LimitsMonitor)
        return false
    method := "NONE", matchInfo := ""
    try {
        text := SafeWinGetText(hwnd)
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
        if (GetWindowSearchRect(hwnd, &left, &top, &right, &bottom, &w, &h)) {
            if (ScanForButton(ENABLE_OVERAGES_IMG, left, top, right, bottom, &fX, &fY))
                method := "IMAGE_PREFERRED"
            else if (ScanForButton(LIMITS_FALLBACK_IMG, left, top, right, bottom, &fX, &fY))
                method := "IMAGE_FALLBACK"
        }
    }
    if (method != "NONE") {
        if (!config.AlertActive) {
            config.AlertActive := true
            LogAction(hwnd, "LIMIT_WARNING_DETECTED", 0, 0, method " | " matchInfo)
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
        ; Gate: scan only if Status=Running AND (Enabled OR AlwaysOn)
        if (config.Status != "Running")
            continue
        if (!config.Enabled and !config.AlwaysOn)
            continue

        if (!SafeWinExists(hwnd)) {
            config.Status := "Stopped"
            config.Enabled := 0
            LogAction(hwnd, "TARGET_WINDOW_GONE", 0, 0, "")
            Loop MainLV.GetCount() {
                if (MainLV.GetText(A_Index, 1) = hwndStr) {
                    MainLV.Modify(A_Index, , , "Stopped")
                    break
                }
            }
            continue
        }

        if (SafeWinGetMinMax(hwnd) = -1)
            continue

        if (config.AlertActive)
            continue

        title := SafeWinGetTitle(hwnd)
        if (ExtractProjectName(title) = "SELF - DO NOT USE")
            continue

        ; === PRIORITY 1: Limits ===
        if (ScanForLimits(hwnd))
            continue

        if (!GetWindowSearchRect(hwnd, &left, &top, &right, &bottom, &width, &height))
            continue


        fX := 0, fY := 0

        ; === PRIORITY 2: Retry ===
        if (ScanForButton(RETRY_IMG, left, top, right, bottom, &fX, &fY, 80)) {
            if (DRY_RUN_MODE) {
                LogAction(hwnd, "DRY_RUN_RETRY_DETECTED", fX, fY, "Dry Run")
            } else {
                LogAction(hwnd, "RETRY_DETECTED", fX, fY, "Live")
                if (config.RetryAuto) {
                    now := A_TickCount
                    if (now - config.LastRetryClickTime > 10000) {
                        DoClick(hwnd, fX, fY, "RETRY")
                        config.LastRetryClickTime := now
                    } else {
                        LogAction(hwnd, "RETRY_LIVE_COOLDOWN_SKIP", 0, 0, "Cooldown")
                    }
                }
            }
            ; In Dry Run also check Copy Debug as a companion scan
            if (DRY_RUN_MODE and config.CopyDebugAuto) {
                cX := 0, cY := 0
                if (ScanForButton(COPY_DEBUG_IMG, left, top, right, bottom, &cX, &cY)) {
                    LogAction(hwnd, "DRY_RUN_COPY_DEBUG_INFO_DETECTED", cX, cY, "Dry Run")
                }
            }
            continue
        }

        ; === PRIORITY 3: Accept ===
        if (config.AcceptManual or config.AcceptAuto) {
            foundAccept := false
            acceptType := "" ; "all", "manual_normal", "manual_hover"

            if (config.AcceptAuto) {
                if (ScanForButton(ACCEPT_ALL_IMG, left, top, right, bottom, &fX, &fY, 80)
                    or ScanForButton(ACCEPT_FALLBACK_IMG, left, top, right, bottom, &fX, &fY, 80)) {
                    foundAccept := true
                    acceptType := "all"
                }
            } else if (config.AcceptManual) {
                if (ScanForButton(ACCEPT_ALL_IMG, left, top, right, bottom, &fX, &fY, 80)) {
                    foundAccept := true
                    acceptType := "manual_normal"
                } else {
                    acceptVariant := ScanForAcceptButton(left, top, right, bottom, &fX, &fY)
                    if (acceptVariant != "") {
                        foundAccept := true
                        acceptType := "manual_" acceptVariant
                    }
                }
            }

            if (foundAccept) {
                config.LastAcceptX := fX
                config.LastAcceptY := fY
                if (acceptType = "all") {
                    if (DRY_RUN_MODE) {
                        LogAction(hwnd, "DRY_RUN_ACCEPT_ALL_DETECTED", fX, fY, "Dry Run")
                    } else {
                        LogAction(hwnd, "ACCEPT_ALL_DETECTED", fX, fY, "Live")
                        now := A_TickCount
                        if (now - config.LastAcceptClickTime > 10000) {
                            DoClick(hwnd, fX, fY, "ACCEPT_ALL_AUTO")
                            config.LastAcceptClickTime := now
                        } else {
                            LogAction(hwnd, "ACCEPT_LIVE_COOLDOWN_SKIP", 0, 0, "Cooldown")
                        }
                    }
                } else {
                    ; AcceptManual: detect and log; live click requires user to confirm per-session
                    variantNote := (acceptType = "manual_hover") ? "variant=hover" : "variant=normal"
                    if (DRY_RUN_MODE) {
                        LogAction(hwnd, "DRY_RUN_ACCEPT_MANUAL_DETECTED", fX, fY, variantNote)
                    } else {
                        LogAction(hwnd, "ACCEPT_MANUAL_DETECTED", fX, fY, variantNote)
                        now := A_TickCount
                        if (now - config.LastAcceptClickTime > 10000) {
                            DoClick(hwnd, fX, fY, "ACCEPT_MANUAL")
                            config.LastAcceptClickTime := now
                        } else {
                            LogAction(hwnd, "ACCEPT_LIVE_COOLDOWN_SKIP", 0, 0, "Cooldown")
                        }
                    }
                }
                continue
            }
        }

        ; === PRIORITY 4: Copy Debug Info ===
        if (config.CopyDebugAuto) {
            if (ScanForButton(COPY_DEBUG_IMG, left, top, right, bottom, &fX, &fY)) {
                if (DRY_RUN_MODE) {
                    LogAction(hwnd, "DRY_RUN_COPY_DEBUG_INFO_DETECTED", fX, fY, "Dry Run")
                } else {
                    CaptureDebugForWindow(hwnd, "AUTO")
                }
                continue
            }
        }
    }
}

ScanForAcceptButton(left, top, right, bottom, &foundX, &foundY) {
    if (ScanForButton(ACCEPT_FALLBACK_IMG, left, top, right, bottom, &foundX, &foundY, 80)) {
        return "normal"
    }

    if (FileExist(ACCEPT_HOVER_IMG)) {
        if (ScanForButton(ACCEPT_HOVER_IMG, left, top, right, bottom, &foundX, &foundY, 80)) {
            return "hover"
        }
    }

    return ""
}

ScanForButton(imgPath, x1, y1, x2, y2, &fX, &fY, tolerance := 50) {
    CoordMode "Pixel", "Screen"
    fX := 0
    fY := 0

    if (!FileExist(imgPath)) {
        return false
    }

    if (x1 = "" or y1 = "" or x2 = "" or y2 = "") {
        return false
    }

    if (x2 <= x1 or y2 <= y1) {
        return false
    }

    try {
        if ImageSearch(&fX, &fY, x1, y1, x2, y2, "*" tolerance " " imgPath) {
            fX += 10
            fY += 10
            return true
        }
    } catch as err {
        ; Do not crash timer/MainLoop on transient ImageSearch failures.
        return false
    }
    return false
}

RestoreMouseClick(hwnd, clickX, clickY, &origX := 0, &origY := 0) {
    CoordMode "Mouse", "Screen"
    MouseGetPos(&origX, &origY)
    MouseClick("Left", clickX, clickY, 1, 0)
    Sleep(80)
    MouseMove(origX, origY, 0)
}

DoClick(hwnd, clickX, clickY, type) {
    if (!GetWindowSearchRect(hwnd, &left, &top, &right, &bottom, &width, &height)) {
        LogAction(hwnd, "CLICK_SKIPPED_STALE_WINDOW", clickX, clickY, type)
        return
    }

    ; Boundary validation
    if (clickX < left or clickX > right or clickY < top or clickY > bottom) {
        LogAction(hwnd, "CLICK_BLOCKED_OUT_OF_BOUNDS", clickX, clickY, "L=" left " T=" top " R=" right " B=" bottom)
        return
    }

    if (DRY_RUN_MODE) {
        upperType := StrUpper(type)
        LogAction(hwnd, "DRY_RUN_CLICK_BLOCKED", clickX, clickY, "Type: " upperType)
        return
    }
    CoordMode "Mouse", "Screen"
    if (SafeWinExists(hwnd)) {
        origX := 0, origY := 0
        RestoreMouseClick(hwnd, clickX, clickY, &origX, &origY)
        LogAction(hwnd, "CLICKED_" StrUpper(type), clickX, clickY, "Live | mouse_restore=YES original=" origX "," origY " target=" clickX "," clickY)
    } else {
        LogAction(hwnd, "CLICK_SKIPPED_STALE_WINDOW", clickX, clickY, type)
    }
}

LogAction(hwnd, event, x := 0, y := 0, actionNote := "") {
    global LOG_FILE, DRY_RUN_MODE, EventLogLV
    static logErrorShown := false

    timestamp := FormatTime(, "yyyy-MM-dd HH:mm:ss")
    timeShort := FormatTime(, "HH:mm:ss")

    if (hwnd = 0) {
        title := "SYSTEM"
        project := "SYSTEM"
    } else if (!SafeWinExists(hwnd)) {
        title := "STALE_WINDOW"
        project := "STALE"
    } else {
        title := SafeWinGetTitle(hwnd, "STALE_WINDOW")
        project := ExtractProjectName(title)
    }

    mode := DRY_RUN_MODE ? "DRY" : "LIVE"
    logLine := timestamp " | " hwnd " | " title " | " event " | " mode " | " x "," y " | " actionNote "`n"

    ; 1. Increment Counters
    IncrementCounter(event)

    ; 2. Update Live Log Panel
    if (EventLogLV != 0) {
        try {
            EventLogLV.Insert(1, , timeShort, project, event, mode, actionNote)
            if (EventLogLV.GetCount() > 500)
                EventLogLV.Delete(501)
        }
    }

    ; 3. Write to File Log
    try {
        FileAppend(logLine, LOG_FILE)
    } catch as e {
        if (!logErrorShown) {
            MsgBox("Failed to write helper log. The helper will continue running.", "Log Warning", "Icon!")
            logErrorShown := true
        }
    }
}
