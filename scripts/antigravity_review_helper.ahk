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

; Event Counters State
global EventCounters := Map()
global CounterControls := Map() ; Map counter name -> Text control object
global EventLogLV := 0 ; Global reference for Live Log ListView
global CurrentSelectedHwnd := 0
global IsLoadingConfigIntoControls := false

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
chkRetry := MyGui.Add("Checkbox", "x200 y180", "Retry Auto")
chkRetry.OnEvent("Click", OnCheckboxClick)
chkContinue := MyGui.Add("Checkbox", "x300 y180", "Continue Auto")
chkContinue.OnEvent("Click", OnCheckboxClick)
chkAcceptManual := MyGui.Add("Checkbox", "x420 y180", "Accept Manual (Prompt)")
chkAcceptManual.OnEvent("Click", OnCheckboxClick)
chkAcceptAuto := MyGui.Add("Checkbox", "x20 y205 cRed", "Accept All Auto (CAUTION)")
chkAcceptAuto.OnEvent("Click", OnAcceptAutoClick)

chkCopyDebugAuto := MyGui.Add("Checkbox", "x200 y205", "Copy Debug Info Auto")
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

chkDryRunGlobal := MyGui.Add("Checkbox", "x10 y505 Checked", "Global Dry Run Mode (Safety)")
chkDryRunGlobal.OnEvent("Click", OnDryRunToggle)

global txtGlobalStatus := MyGui.Add("Text", "x10 y525 w600 cBlue", "Helper: RUNNING | Dry Run: ON")
MyGui.Add("Text", "x450 y525 w160 cGray Right", "Emergency: Ctrl+Alt+Esc")

MyGui.Show("w1000 h550")
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

SaveCurrentSelectionConfig() {
    global CurrentSelectedHwnd, WindowConfigs
    global chkEnabled, chkAlwaysOn, chkRetry, chkContinue, chkCopyDebugAuto, chkAcceptManual, chkLimitsMonitor

    hwndStr := "" CurrentSelectedHwnd
    if (!CurrentSelectedHwnd or !WindowConfigs.Has(hwndStr))
        return false

    config := WindowConfigs[hwndStr]
    config.Enabled := chkEnabled.Value
    config.AlwaysOn := chkAlwaysOn.Value
    config.RetryAuto := chkRetry.Value
    config.ContinueAuto := chkContinue.Value
    config.CopyDebugAuto := chkCopyDebugAuto.Value
    config.AcceptManual := chkAcceptManual.Value
    config.LimitsMonitor := chkLimitsMonitor.Value

    WindowConfigs[hwndStr] := config
    LogAction(CurrentSelectedHwnd, "WINDOW_CONFIG_SAVED", 0, 0, "from GUI controls")
    return true
}

LoadConfigIntoControls(hwnd) {
    global WindowConfigs, IsLoadingConfigIntoControls
    global chkEnabled, chkAlwaysOn, chkRetry, chkContinue, chkCopyDebugAuto, chkAcceptManual, chkLimitsMonitor
    global txtCaptureStatus, txtRedactionStatus, editDebugText

    hwndStr := "" hwnd
    if (!WindowConfigs.Has(hwndStr))
        return

    config := WindowConfigs[hwndStr]
    IsLoadingConfigIntoControls := true
    
    chkEnabled.Value := config.Enabled ? 1 : 0
    chkAlwaysOn.Value := config.AlwaysOn ? 1 : 0
    chkRetry.Value := config.RetryAuto ? 1 : 0
    chkContinue.Value := config.ContinueAuto ? 1 : 0
    chkCopyDebugAuto.Value := config.CopyDebugAuto ? 1 : 0
    chkAcceptManual.Value := config.AcceptManual ? 1 : 0
    chkAcceptAuto.Value := config.AcceptAuto ? 1 : 0
    chkLimitsMonitor.Value := config.LimitsMonitor ? 1 : 0
    
    txtCaptureStatus.Value := "Last Detection: " (config.LastRetryTime ? config.LastRetryTime : "None")
    txtRedactionStatus.Value := "Redaction Status: " (config.LastCaptureStatus ? config.LastCaptureStatus : "Idle")
    editDebugText.Value := config.CapturedText ? config.CapturedText : ""
    
    IsLoadingConfigIntoControls := false
    LogAction(hwnd, "WINDOW_CONFIG_LOADED", 0, 0, "to GUI controls")
}

OnCheckboxClick(*) {
    global IsLoadingConfigIntoControls
    if (IsLoadingConfigIntoControls)
        return
    SaveCurrentSelectionConfig()
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
    
    ; 1. Total Events always increments
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
    
    ; Specific Dry Run Blocked mapping (Defensive check)
    if (DRY_RUN_MODE) {
        if (InStr(eventName, "DRY_RUN_CLICK_BLOCKED") or InStr(eventName, "CLICK_BLOCKED_DRY_RUN")) {
            counter := "DryRunBlocked"
        }
    }

    ; Increment if we found a valid mapping
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

OnClearLog(*) {
    try {
        FileDelete(LOG_FILE)
    } catch {
    }
}

OnLVClick(targetLV, RowNumber)
{
    global CurrentSelectedHwnd
    if (RowNumber = 0)
        return
    
    ; 1. Save config for previous window
    SaveCurrentSelectionConfig()
    
    ; 2. Update selection
    hwnd := targetLV.GetText(RowNumber, 1)
    CurrentSelectedHwnd := Number(hwnd)
    
    ; 3. Load config for new window
    LogAction(CurrentSelectedHwnd, "WINDOW_SELECTION_CHANGED", 0, 0, "")
    LoadConfigIntoControls(CurrentSelectedHwnd)
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
    global CurrentSelectedHwnd
    RowNumber := MainLV.GetNext()
    if (RowNumber = 0)
    {
        LogAction(0, "START_BLOCKED_NO_SELECTION", 0, 0, "")
        MsgBox("No window selected.", "Selection Required", "Icon!")
        return
    }
    hwndStr := MainLV.GetText(RowNumber, 1)
    hwnd := Number(hwndStr)
    
    ; 1. Sync CurrentSelectedHwnd
    CurrentSelectedHwnd := hwnd
    
    ; 2. Save current GUI config to WindowConfigs before starting
    SaveCurrentSelectionConfig()

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

    if (WindowConfigs.Has(hwndStr))
    {
        config := WindowConfigs[hwndStr]
        config.Status := newStatus
        MainLV.Modify(RowNumber, , , newStatus)
        LogAction(hwnd, "STATUS_CHANGED", 0, 0, newStatus)
        
        ; Log detailed runtime state for debugging
        stateNote := "Enabled=" config.Enabled " Retry=" config.RetryAuto " Accept=" config.AcceptAuto " Limits=" config.LimitsMonitor " Status=" config.Status
        LogAction(hwnd, "WINDOW_CONFIG_RUNTIME_STATE", 0, 0, stateNote)
    }
}

StopAll(*)
{
    ; Save current selection config before stopping all
    SaveCurrentSelectionConfig()
    
    for hwndStr, config in WindowConfigs
    {
        config.Status := "Stopped"
        if (config.AlertActive)
            ClearAlert(Number(hwndStr))
    }
    Loop MainLV.GetCount()
        MainLV.Modify(A_Index, , , "Stopped")
    LogAction(0, "STOP_ALL_COMMAND", 0, 0, "")
}

RefreshWindowList(*)
{
    global CurrentSelectedHwnd
    
    ; 1. Save current config before refresh
    SaveCurrentSelectionConfig()

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
            hwndStr := "" hwnd
            config := {Enabled: 0, AlwaysOn: 0, RetryAuto: 0, ContinueAuto: 0, AcceptManual: 1, AcceptAuto: 0, CopyDebugAuto: 0, LimitsMonitor: 1, Status: "Stopped", LastAcceptX: 0, LastAcceptY: 0, LastRetryTime: "", LastCaptureStatus: "Idle", CapturedText: "", AlertActive: false, LastLimitLog: 0, LastScanLogTime: 0}
            
            if (oldConfigs.Has(hwndStr)) {
                config := oldConfigs[hwndStr]
                LogAction(hwnd, "WINDOW_CONFIG_PRESERVED", 0, 0, "")
            } else {
                LogAction(hwnd, "WINDOW_CONFIG_CREATED", 0, 0, "")
            }
            
            WindowConfigs[hwndStr] := config
            MainLV.Add(, hwndStr, config.Status, project, title)
        }
    }
    
    ; 2. Reload config into controls if the selected window still exists
    if (CurrentSelectedHwnd and WindowConfigs.Has("" CurrentSelectedHwnd)) {
        LoadConfigIntoControls(CurrentSelectedHwnd)
        
        ; Re-select in ListView if possible
        Loop MainLV.GetCount() {
            if (MainLV.GetText(A_Index, 1) = "" CurrentSelectedHwnd) {
                MainLV.Modify(A_Index, "Select Focus")
                break
            }
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
    if (!SafeWinGetPos(hwnd, &x, &y, &w, &h))
    {
        LogAction(hwnd, "DEBUG_TARGET_WINDOW_GONE", 0, 0, triggerType)
        UpdateDebugViewer(hwnd, "DEBUG_TARGET_WINDOW_GONE", "NONE")
        return
    }
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
    if (SafeWinExists(hwnd))
        Click(foundX, foundY)
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
        if (SafeWinGetPos(hwnd, &x, &y, &w, &h)) {
            if (ScanForButton(ENABLE_OVERAGES_IMG, x, y, x+w, y+h, &fX, &fY))
                method := "IMAGE_PREFERRED"
            else if (ScanForButton(LIMITS_FALLBACK_IMG, x, y, x+w, y+h, &fX, &fY))
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
        x := 0, y := 0, w := 0, h := 0, fX := 0, fY := 0, cX := 0, cY := 0
        
        ; Rate-limited diagnostic log for running windows (every 10s)
        now := A_TickCount
        if (config.Status = "Running" and now - config.LastScanLogTime > 10000) {
            stateNote := "Enabled=" config.Enabled " Status=" config.Status " Retry=" config.RetryAuto " Accept=" config.AcceptAuto " Limits=" config.LimitsMonitor " Dry=" (DRY_RUN_MODE ? "ON" : "OFF")
            LogAction(hwnd, "MAINLOOP_CONFIG_STATE", 0, 0, stateNote)
            config.LastScanLogTime := now
        }

        ; Hardened check: only Running or AlwaysOn
        if (!config.Enabled or (config.Status != "Running" and !config.AlwaysOn))
            continue
        
        if (!SafeWinExists(hwnd)) {
            config.Status := "Stopped"
            config.Enabled := 0
            LogAction(hwnd, "TARGET_WINDOW_GONE", 0, 0, "")
            ; Attempt to find row in LV to update status
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
        
        ; Double check project name
        title := SafeWinGetTitle(hwnd)
        if (ExtractProjectName(title) = "SELF - DO NOT USE")
            continue

        if (ScanForLimits(hwnd))
            continue
            
        if (!SafeWinGetPos(hwnd, &x, &y, &w, &h))
            continue
        
        global ContinueAssetMissingLogged
        if (!ContinueAssetMissingLogged and !FileExist(CONTINUE_IMG)) {
            LogAction(hwnd, "CONTINUE_ASSET_MISSING", 0, 0, "MISSING_OK")
            ContinueAssetMissingLogged := true
        }

        fX := 0, fY := 0, cX := 0, cY := 0, foundAccept := false
        if (ScanForButton(ACCEPT_ALL_IMG, x, y, x+w, y+h, &fX, &fY, 80))
            foundAccept := true
        else if (ScanForButton(ACCEPT_FALLBACK_IMG, x, y, x+w, y+h, &fX, &fY, 80))
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

ScanForButton(imgPath, x1, y1, x2, y2, &fX, &fY, tolerance := 50) {
    if (!FileExist(imgPath))
        return false
    CoordMode "Pixel", "Screen"
    if ImageSearch(&fX, &fY, x1, y1, x2, y2, "*" tolerance " " imgPath)
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
        LogAction(hwnd, "DRY_RUN_CLICK_BLOCKED", clickX, clickY, "Type: " upperType)
        return
    }
    CoordMode "Mouse", "Screen"
    if (SafeWinExists(hwnd)) {
        Click(clickX, clickY)
        LogAction(hwnd, "CLICKED_" StrUpper(type), clickX, clickY, "Live")
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
